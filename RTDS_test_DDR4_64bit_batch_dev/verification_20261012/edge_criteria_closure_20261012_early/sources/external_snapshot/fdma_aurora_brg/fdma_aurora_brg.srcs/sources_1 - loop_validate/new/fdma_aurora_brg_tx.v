// 将FDMA返回数据写入64bit异步FIFO，再按16Byte帧送到Aurora 10G。
// fdma_clk负责读请求和FIFO写入，user_clk负责两拍帧发送与帧完成计数。
// FIFO接近满时停止预取；发送只在有效与接收许可同拍成立时取走当前拍。
// 首拍SOF、末拍EOF、REM=7；链路或本地复位清在途发送状态。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module fdma_aurora_brg_tx #(


        parameter integer                             FRAME_BYTES = 16,               // 单帧字节数，当前16Byte
        parameter integer                             MEM_WINDOW_BYTES = 4096         // 发送所使用的存储字节范围
    )(

        input                                      fdma_clk            ,              // 对应接口时钟，使用域由连接关系确定
        input                                      fdma_rstn           ,              // FDMA域低有效复位
        input                                      user_clk            ,              // 对应接口时钟，使用域由连接关系确定
        input                                      user_rstn           ,              // 用户域低有效复位


        input                                      channel_up          ,              // 来自 Aurora core
        input                                      channel_up_fdma     ,              // 来自 Aurora core, 已同步到 fdma_clk 域


        input         [15: 0]                      cfg_tx_burst_limit  ,              // 高有效复位或同步复位状态

        output        [31: 0]                      fdma_raddr          ,              // 读起始字节地址
        output reg                                 fdma_rareq          ,              // 读请求，保持到busy接受
        input                                      fdma_rbusy          ,              // 读请求仍在处理
        input         [63: 0]                      fdma_rdata          ,              // 当前读数据
        input                                      fdma_rvalid         ,              // 读数据已接受事件
        output                                     fdma_rready         ,              // AXI-like: 用户授权FDMA传输数据


        output reg    [63: 0]                      tx_d                ,              // 发送当前数据拍
        output reg                                 tx_sof              ,              // 当前帧首拍标志，与有效/接受共同使用
        output reg                                 tx_eof              ,              // 当前帧末拍标志，与有效/接受共同使用
        output reg    [ 2: 0]                      tx_rem              ,              // 当前拍有效字节数减1
        output reg                                 tx_src_rdy          ,              // 当前数据/事件有效
        input                                      tx_dst_rdy          ,              // 当前通道可接受数据或业务


        output        [37: 0]                      dbg_fdma_bus        ,              // 发送桥FDMA域读状态、计数和FIFO状态集合
        output        [38: 0]                      dbg_user_bus        ,              // 发送桥用户域帧状态、计数和FIFO状态集合
        output                                     tx_frame_done                      // 用户域帧尾实际接受后的完成事件

    );


    localparam                                 TEST_MEM_SIZE   = MEM_WINDOW_BYTES                         ;    // 本模块TEST_MEM_SIZE固定配置/状态编码

    localparam                                 FDMA_BURST_LEN  = FRAME_BYTES                              ;    // 字节/突发，与FRAME_BYTES一致

    localparam                                 BURST_WORDS     = FDMA_BURST_LEN / 8                       ;    // 当前16/8=2拍

    localparam                                 FRAME_WORDS     = FRAME_BYTES / 8                          ;    // 本模块FRAME_WORDS固定配置/状态编码


    localparam                                 TX_FIFO_RESERVE_WORDS = (BURST_WORDS > 8) ? BURST_WORDS : 8;    // 本模块TX_FIFO_RESERVE_WORDS固定配置/状态编码
    localparam                                 TX_PROG_FULL_THRESH = 512 - TX_FIFO_RESERVE_WORDS          ;    // FIFO当前已满

    // synthesis translate_off
    initial begin : check_tx_fifo_parameters
        if ((FRAME_BYTES < 16) || ((FRAME_BYTES % 8) != 0) ||
            (TX_PROG_FULL_THRESH < 7) || (TX_PROG_FULL_THRESH > 507)) begin
            $error("TX_FIFO/PARAMETER: invalid frame size or programmable-full threshold");
            $finish;
        end
    end
    // synthesis translate_on


    localparam                                 RD_IDLE  = 2'd0                                            ;    // 本模块RD_IDLE固定配置/状态编码

    localparam                                 RD_REQ   = 2'd1                                            ;    // 本模块RD_REQ固定配置/状态编码

    localparam                                 RD_DATA  = 2'd2                                            ;    // 本模块RD_DATA固定配置/状态编码

    localparam                                 RD_WAIT  = 2'd3                                            ;    // 本模块RD_WAIT固定配置/状态编码

    reg           [1:0]                        rd_state                                                   ;    // 读请求状态机当前状态
    reg           [1:0]                        rd_state_nxt                                               ;    // 组合计算的下一读状态
    reg           [31:0]                       rd_addr                                                    ;    // 发送桥相对读地址
    reg           [6:0]                        rd_word_cnt                                                ;    // 当前读突发的实际接受拍位置
    wire                                       rd_burst_done                                              ;    // 当前FDMA读突发完成


    localparam                                 TX_IDLE = 2'd0                                             ;    // 本模块TX_IDLE固定配置/状态编码

    localparam                                 TX_SOF  = 2'd1                                             ;    // 当前帧首拍标志，与有效/接受共同使用

    localparam                                 TX_DATA = 2'd2                                             ;    // 发送当前数据拍

    reg           [1:0]                        tx_state                                                   ;    // LocalLink发送当前状态
    reg           [1:0]                        tx_state_nxt                                               ;    // 组合计算的下一发送状态
    reg           [7:0]                        tx_word_cnt                                                ;    // 当前发送帧内拍位置
    wire                                       wr_burst_done                                              ;    // 当前帧最后数据拍已经发送

    reg           [15:0]                       frame_cnt                                                  ;    // 用户域已发送完整帧数量
    reg           [15:0]                       burst_cnt                                                  ;    // FDMA域已结束读突发数量


    wire                                       fifo_wr_en                                                 ;    // 读数据实际接受时写异步FIFO
    wire                                       fifo_rd_en                                                 ;    // LocalLink发送握手时取走FIFO当前拍
    wire                                       wr_en                                                      ;    // 异步FIFO写使能
    wire                                       rd_en                                                      ;    // 异步FIFO读使能
    wire                                       fifo_rst                                                   ;    // 高有效复位或同步复位状态
    wire                                       fifo_full                                                  ;    // FIFO当前已满
    wire                                       fifo_empty                                                 ;    // FIFO当前为空
    wire          [63:0]                       fifo_wdata                                                 ;    // 异步FIFO写入的64bit读数据
    wire          [63:0]                       fifo_rdata                                                 ;    // 异步FIFO当前64bit输出拍
    wire                                       fifo_overflow                                              ;    // 对应FIFO不能保存新输入的溢出状态
    wire                                       fifo_underflow                                             ;    // 对应FIFO读侧无数据的错误状态
    wire          [9:0]                        fifo_wr_cnt                                                ;    // FDMA域观察的FIFO存储拍数
    wire          [9:0]                        fifo_rd_cnt                                                ;    // 用户域观察的FIFO存储拍数
    wire                                       fifo_almost_full                                           ;    // FIFO接近满，需暂停继续输入
    wire                                       fifo_almost_empty                                          ;    // FIFO剩余数据接近空
    wire                                       wr_rst_busy                                                ;    // 高有效复位或同步复位状态
    wire                                       rd_rst_busy                                                ;    // 高有效复位或同步复位状态
    wire                                       wr_clk                                                     ;    // 对应接口时钟，使用域由连接关系确定
    wire                                       rd_clk                                                     ;    // 对应接口时钟，使用域由连接关系确定


    assign wr_clk = fdma_clk                                                                              ;    // 对应接口时钟，使用域由连接关系确定

    assign rd_clk = user_clk                                                                              ;    // 对应接口时钟，使用域由连接关系确定

    wire                                       tx_burst_allowed                                           ;    // 高有效复位或同步复位状态

    assign tx_burst_allowed = (cfg_tx_burst_limit == 16'd0) ||
                             (burst_cnt < cfg_tx_burst_limit)                                             ;    // 高有效复位或同步复位状态


    wire                                       rd_data_phase                                              ;    // 当前读数据阶段，包含请求刚被busy接受的周期

    assign rd_data_phase = (rd_state == RD_DATA) ||
                         ((rd_state == RD_REQ) && fdma_rbusy)                                             ;    // 当前读数据阶段，包含请求刚被busy接受的周期
    wire                                       fifo_write_ready                                           ;    // 当前通道可接受数据或业务

    assign fifo_write_ready = (~wr_rst_busy) && (~fifo_almost_full)                                       ;    // 当前通道可接受数据或业务

    assign fdma_rready = rd_data_phase && fifo_write_ready                                                ;    // AXI-like: 用户授权FDMA传输数据


    wire                                       rd_data_hs                                                 ;    // FDMA有效读拍实际接受

    assign rd_data_hs = rd_data_phase && fdma_rvalid && fdma_rready                                       ;    // FDMA有效读拍实际接受


    assign fifo_wr_en = rd_data_hs                                                                        ;    // 读数据实际接受时写异步FIFO

    assign fifo_wdata = fdma_rdata                                                                        ;    // 异步FIFO写入的64bit读数据


    assign wr_en = fifo_wr_en && (~wr_rst_busy)                                                           ;    // 异步FIFO写使能

    assign rd_en = fifo_rd_en && (~rd_rst_busy)                                                           ;    // 异步FIFO读使能


    assign fifo_rst = (~fdma_rstn)                                                                        ;    // 高有效复位或同步复位状态


    // fdma_clk沿保存读状态，低有效复位回RD_IDLE。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            rd_state <= RD_IDLE;

        else
            rd_state <= rd_state_nxt;
    end


    // 计算读次态：链路允许、FIFO可写且批量未结束才请求；busy接受后等该次读结束。
    always @(*) begin
        rd_state_nxt = rd_state;

        case (rd_state)

            RD_IDLE:

                if(channel_up_fdma && fifo_write_ready && tx_burst_allowed)
                    rd_state_nxt=RD_REQ;

            RD_REQ :

                if(fdma_rbusy)
                    rd_state_nxt=RD_DATA;

            RD_DATA:

                if(rd_burst_done)
                    rd_state_nxt=RD_WAIT;

            RD_WAIT:

                if(~fdma_rbusy)
                    rd_state_nxt=RD_IDLE;

            default: begin
                rd_state_nxt = RD_IDLE;
            end
        endcase
    end


    assign  rd_burst_done = rd_data_hs && (rd_word_cnt == BURST_WORDS - 1)                                ;    // 当前FDMA读突发完成


    // 只在rd_data_hs成立时统计当前读拍，达到突发末拍后回零。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn) begin
            rd_word_cnt   <= 7'd0;
        end

        else begin

            if (rd_data_hs) begin

                if (rd_word_cnt == BURST_WORDS-1)
                    rd_word_cnt <= 7'd0;

                else
                    rd_word_cnt <= rd_word_cnt + 7'd1;
            end
        end
    end


    // 读busy释放后移动下一帧地址，地址超过配置范围时从0重新开始。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn) begin
            rd_addr  <= 32'd0;
        end

        else if ((rd_state == RD_WAIT) && (~fdma_rbusy)) begin

            if (rd_addr + FDMA_BURST_LEN >= TEST_MEM_SIZE)
                rd_addr <= 32'd0;

            else
                rd_addr <= rd_addr + FDMA_BURST_LEN;
        end
    end


    assign fdma_raddr = rd_addr                                                                           ;    // 读起始字节地址


    // 请求状态保持fdma_rareq，CONV_DMA置busy接受后撤销，避免重复请求。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            fdma_rareq <= 1'b0;

        else if((rd_state == RD_REQ) && (~fdma_rbusy))
            fdma_rareq <= 1'b1;

        else if(fdma_rareq && fdma_rbusy)
            fdma_rareq <= 1'b0;
    end


    // user_clk沿保存发送状态，低有效复位回TX_IDLE。
    always @(posedge user_clk or negedge user_rstn) begin
        if (~user_rstn)
            tx_state <= TX_IDLE;

        else
            tx_state <= tx_state_nxt;
    end


    wire                                       tx_hs                                                      ;    // 用户域发送valid/ready实际握手

    assign tx_hs = tx_src_rdy && tx_dst_rdy                                                               ;    // 用户域发送valid/ready实际握手

    assign wr_burst_done = tx_hs && (tx_word_cnt == FRAME_WORDS-1)                                        ;    // 当前帧最后数据拍已经发送

    assign tx_frame_done = wr_burst_done                                                                  ;    // 用户域帧尾实际接受后的完成事件


    // 计算发送次态：有完整帧数据才开始，SOF及后续数据状态仅随tx_hs推进。
    always @(*) begin
        tx_state_nxt = tx_state;

        case (tx_state)

            TX_IDLE:

                if(channel_up && (~fifo_almost_empty))
                    tx_state_nxt=TX_SOF;

            TX_SOF :

                if(tx_hs)
                    tx_state_nxt=TX_DATA;

            TX_DATA:

                if(wr_burst_done)
                    tx_state_nxt=TX_IDLE;

            default: begin
                tx_state_nxt = TX_IDLE;
            end
        endcase
    end


    // 组合输出当前FIFO数据和帧标记；REM固定7，反压期间不改变当前FIFO读位置。
    always @(*) begin
        tx_src_rdy = (tx_state != TX_IDLE) && (~fifo_empty);
        tx_sof = (tx_state == TX_SOF) && tx_src_rdy;
        tx_eof = (tx_state == TX_DATA) && (tx_word_cnt == FRAME_WORDS-1) && tx_src_rdy;
        tx_rem = 3'b111;
        tx_d = tx_src_rdy ? fifo_rdata : 64'b0;
    end


    // 只在LocalLink实际接受时增加帧内拍位置，帧末归零。
    always @(posedge user_clk or negedge user_rstn) begin
        if (~user_rstn)
            tx_word_cnt     <= 8'd0;

        else begin
            if (tx_hs) begin
                if (tx_word_cnt == FRAME_WORDS-1)
                    tx_word_cnt <= 8'd0;
                else
                    tx_word_cnt <= tx_word_cnt + 8'd1;
            end
        end
    end


    assign fifo_rd_en = tx_hs                                                                             ;    // LocalLink发送握手时取走FIFO当前拍


    xpm_fifo_async #(
                       .CDC_SYNC_STAGES(2),
        .DOUT_RESET_VALUE("0"),
        .ECC_MODE("no_ecc"),
        .FIFO_MEMORY_TYPE("auto"),
        .FIFO_READ_LATENCY(0),
        .FIFO_WRITE_DEPTH(512),
        .FULL_RESET_VALUE(0),
        .PROG_EMPTY_THRESH(10),
        .PROG_FULL_THRESH(TX_PROG_FULL_THRESH),
        .RD_DATA_COUNT_WIDTH(10),
        .READ_DATA_WIDTH(64),
        .READ_MODE("fwft"),
        .RELATED_CLOCKS(0),
        .SIM_ASSERT_CHK(0),
        .USE_ADV_FEATURES("1f1f"),
        .WAKEUP_TIME(0),
        .WRITE_DATA_WIDTH(64),
        .WR_DATA_COUNT_WIDTH(10)
                   )
                   xpm_fifo_async_inst (
                       .almost_empty(fifo_almost_empty),
        .almost_full(),
        .data_valid(),
        .dbiterr(),
        .dout(fifo_rdata),
        .empty(fifo_empty),
        .full(fifo_full),
        .overflow(fifo_overflow),
        .prog_empty(),
        .prog_full(fifo_almost_full),
        .rd_data_count(fifo_rd_cnt),
        .rd_rst_busy(rd_rst_busy),
        .sbiterr(),
        .underflow(fifo_underflow),
        .wr_ack(),
        .wr_data_count(fifo_wr_cnt),
        .wr_rst_busy(wr_rst_busy),
        .din(fifo_wdata),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .rst(fifo_rst),
        .sleep(1'b0),
        .wr_clk(wr_clk),
        .wr_en(wr_en)
                   );


    // 在用户域每发送完整一帧增加frame_cnt，复位清零。
    always @(posedge user_clk or negedge user_rstn) begin
        if (~user_rstn)
            frame_cnt <= 16'd0;

        else if (wr_burst_done && (tx_state==TX_DATA))
            frame_cnt <= frame_cnt + 16'd1;
    end


    // 在FDMA域每结束一次读突发增加burst_cnt，复位清零。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            burst_cnt <= 16'd0;

        else if (rd_burst_done)
            burst_cnt <= burst_cnt + 16'd1;
    end


    assign dbg_fdma_bus = {
        rd_state,
        fifo_wr_cnt,
        burst_cnt,
        rd_word_cnt,
        rd_burst_done,
        fifo_wr_en,
        fifo_overflow
    }                                                                                                     ;    // 发送桥FDMA域读状态、计数和FIFO状态集合


    assign dbg_user_bus = {
        tx_state,
        fifo_rd_cnt,
        frame_cnt,
        tx_word_cnt,
        wr_burst_done,
        fifo_rd_en,
        fifo_underflow
    }                                                                                                     ;    // 发送桥用户域帧状态、计数和FIFO状态集合

endmodule
