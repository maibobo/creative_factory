`timescale 1ns / 1ps
// File: fdma_aurora_brg_tx.v
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/04/20 16:19:56
// Design Name:
// 模块名称: fdma_aurora_brg_tx
// Project Name:
// Target Devices:
// Tool Versions:
// 说明: FDMA 读主机 to Aurora LocalLink 发送端.
//              One 16-byte FDMA 突发 forms one default 16-byte LL 帧.
//              The asynchronous FIFO crosses fdma_clk into user_clk.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// fdma_aurora_brg_tx 模块入口；发送桥：从 FDMA 读通道取 64bit 数据，经异步 FIFO 进入 Aurora user_clk 域并封装成 LocalLink 帧。
module fdma_aurora_brg_tx #(
        // LocalLink 帧长度，单位为字节；默认 128B = 16 个 64 位数据字。
        // 定义单帧传输的字节数，128B 正好对应一个 16 个 64bit 字的 FDMA 突发。
        parameter integer FRAME_BYTES = 16,
        parameter integer MEM_WINDOW_BYTES = 4096
    )(

        input                               fdma_clk            ,
        input                               fdma_rstn           ,
        input                               user_clk            ,
        input                               user_rstn           ,

        // 控制与状态
        input                               channel_up          , // 来自 Aurora core
        input                               channel_up_fdma     , // 来自 Aurora core, 已同步到 fdma_clk 域

        // FDMA 读接口 (fdma_clk 域)
        input                [15: 0]        cfg_tx_burst_limit  ,

        output               [31: 0]        fdma_raddr          ,
        output reg                          fdma_rareq          ,
        input                               fdma_rbusy          ,
        input                [63: 0]        fdma_rdata          ,
        input                               fdma_rvalid         ,
        output                              fdma_rready         ,  // AXI-like: 用户授权FDMA传输数据

        // Aurora TX LL 接口 (user_clk 域)
        output reg           [63: 0]        tx_d                ,
        output reg                          tx_sof              ,
        output reg                          tx_eof              ,
        output reg           [ 2: 0]        tx_rem              ,
        output reg                          tx_src_rdy          ,
        input                               tx_dst_rdy          ,

        // 调试总线按各自原生时钟域分开保留。
        output               [37: 0]        dbg_fdma_bus        ,
        output               [38: 0]        dbg_user_bus        ,
        output                              tx_frame_done

    );

    // ======================== 参数定义 ========================
    // Address window for 128B bursts. The default keeps the original 4KB behavior.
    localparam TEST_MEM_SIZE   = MEM_WINDOW_BYTES;
    // FDMA一次读取一个配置帧；当前16Byte，对应两个64bit数据拍。
    localparam FDMA_BURST_LEN  = FRAME_BYTES;             // 字节/突发，与FRAME_BYTES一致
    // 将配置帧字节数换算为64bit突发拍数。
    localparam BURST_WORDS     = FDMA_BURST_LEN / 8;  // 当前16/8=2拍
    // 把单帧字节数换算成 64bit 字数量，供突发长度、SOF/EOF 和地址推进使用。
    localparam FRAME_WORDS     = FRAME_BYTES / 8;
    // 每次启动读请求前预留完整突发容量；至少留8拍，满足2020.2 XPM阈值上限507。
    // 16Byte业务帧对应2拍，阈值504；较大帧仍按完整突发拍数预留。
    localparam TX_FIFO_RESERVE_WORDS = (BURST_WORDS > 8) ? BURST_WORDS : 8;
    localparam TX_PROG_FULL_THRESH = 512 - TX_FIFO_RESERVE_WORDS;
    // 参数检查只用于前仿；生产默认参数同时受XPM自身综合DRC约束。
    // synthesis translate_off
    initial begin : check_tx_fifo_parameters
        if ((FRAME_BYTES < 16) || ((FRAME_BYTES % 8) != 0) ||
            (TX_PROG_FULL_THRESH < 7) || (TX_PROG_FULL_THRESH > 507)) begin
            $error("TX_FIFO/PARAMETER: invalid frame size or programmable-full threshold");
            $finish;
        end
    end
    // synthesis translate_on


    // ======================== FDMA 读引擎状态机 ========================
    // FDMA 读状态机空闲编码。
    localparam RD_IDLE  = 2'd0;
    // FDMA 读状态机请求编码。
    localparam RD_REQ   = 2'd1;
    // FDMA 读状态机数据传输编码。
    localparam RD_DATA  = 2'd2;
    // 设置 RD_WAIT 的等待周期上限，防止异常场景下仿真无限挂起。
    localparam RD_WAIT  = 2'd3;

    reg [1:0]  rd_state;
    reg [1:0]  rd_state_nxt;
    reg [31:0] rd_addr;
    reg [6:0]  rd_word_cnt;          // - 然后连续提供 rvalid 数据（共 BURST_WORDS 拍）
    wire rd_burst_done;

    // ======================== Aurora 发送引擎状态机 ========================
    // Aurora TX 状态机空闲编码。
    localparam TX_IDLE = 2'd0;
    // Aurora TX 状态机帧首编码。
    localparam TX_SOF  = 2'd1;
    // Aurora TX 状态机帧内数据编码。
    localparam TX_DATA = 2'd2;

    reg [1:0] tx_state;
    reg [1:0] tx_state_nxt;
    reg [7:0] tx_word_cnt;      // 0~15（128Byte 帧内字序号）
    wire      wr_burst_done;
    //reg       tx_frame_done;
    reg [15:0] frame_cnt;       // 发送帧计数
    reg [15:0] burst_cnt;       // 发送 突发 计数

    // ======================== 异步 FIFO 控制信号 ========================
    wire        fifo_wr_en;
    wire        fifo_rd_en;
    wire        wr_en;
    wire        rd_en;
    wire        fifo_rst;
    wire        fifo_full;
    wire        fifo_empty;
    wire [63:0] fifo_wdata;
    wire [63:0] fifo_rdata;
    wire        fifo_overflow;
    wire        fifo_underflow;
    wire [9:0]  fifo_wr_cnt;
    wire [9:0]  fifo_rd_cnt;
    wire        fifo_almost_full;
    wire        fifo_almost_empty;
    wire        wr_rst_busy;
    wire        rd_rst_busy;
    wire        wr_clk;
    wire        rd_clk;

    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign wr_clk = fdma_clk;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign rd_clk = user_clk;
    // 异步 FIFO 有空间时接收读数据。
    wire tx_burst_allowed;
    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign tx_burst_allowed = (cfg_tx_burst_limit == 16'd0) ||
                             (burst_cnt < cfg_tx_burst_limit);

    // FIFO 写使能
    // 类 AXI 握手: rvalid && rready 时数据传输
    wire rd_data_phase;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rd_data_phase = (rd_state == RD_DATA) ||
                         ((rd_state == RD_REQ) && fdma_rbusy);
    wire fifo_write_ready;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign fifo_write_ready = (~wr_rst_busy) && (~fifo_almost_full);
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign fdma_rready = rd_data_phase && fifo_write_ready;  // 数据阶段且 FIFO 写端可接收时授权 FDMA 传输数据

    // modify:2026.6.15 fifo_wr_en might 使能 when rd_状态 is RD_REQ, and when rd_状态 is RD_REQ and rd_突发_done both 有效 the fifo_wr_en is also 关闭
    // 一次 FIFO 写入严格对应一个已接受的 FDMA 读数据字。
    // RD_REQ 同拍看到 rbusy 时，FDMA 从机可能已经给出首个 rvalid 数据字；
    // 末字仍用当前 RD_DATA 状态捕获，避免 rd_state_nxt 造成尾字丢失。
    wire rd_data_hs;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign rd_data_hs = rd_data_phase && fdma_rvalid && fdma_rready;

    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign fifo_wr_en = rd_data_hs;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign fifo_wdata = fdma_rdata;

    // 复位忙期间，禁止读写（避免无效操作）
    assign wr_en = fifo_wr_en && (~wr_rst_busy);
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rd_en = fifo_rd_en && (~rd_rst_busy);

    // FIFO 相关组合控制，决定跨时钟缓存的读写、复位或数据通路。
    assign fifo_rst = (~fdma_rstn);

    // FDMA rd_状态
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            rd_state <= RD_IDLE;
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else
            rd_state <= rd_state_nxt;
    end

    // 组合 always 块计算下一状态/输出，注意不要引入锁存器。

    always @(*) begin
        rd_state_nxt = rd_state;
        // 根据 rd_state 选择对应状态的输出赋值和下一拍转移。
        case (rd_state)
            // RD_IDLE 等待读请求和链路就绪，未满足时不发起 FIFO 读出。
            RD_IDLE:
                // Aurora 链路置位后才允许 FDMA 和 LocalLink 数据通路继续推进。
                if(channel_up_fdma && fifo_write_ready && tx_burst_allowed) // 施加反压，防止 FIFO 溢出
                    rd_state_nxt=RD_REQ;
            // RD_REQ 发出读请求并等待 FDMA 侧接受当前突发。
            RD_REQ :
                // FDMA 读侧接受请求后进入读数据接收阶段。
                if(fdma_rbusy)
                    rd_state_nxt=RD_DATA;
            // RD_DATA 在有效读数据到达时写入 TX FIFO，并按真实握手推进字计数。
            RD_DATA:
                // 读突发完成后累计已发起的 FDMA 读突发数量。
                if(rd_burst_done)
                    rd_state_nxt=RD_WAIT;
            // RD_WAIT 等待读侧 busy 撤销，保证下一个突发不会提前启动。
            RD_WAIT: // 保持等待 fdma_rbusy，以满足 FDMA 协议。
                // FDMA 读侧释放 busy 后，本次读事务收尾并回到空闲。
                if(~fdma_rbusy)
                    rd_state_nxt=RD_IDLE;
            // 未列出的编码回到安全取值，避免状态机停留在非法状态。
            default: begin
                rd_state_nxt = RD_IDLE;
            end
        endcase
    end

    // 当不在 RD_DATA 状态时，如其他状态下 fdma_rvalid 毛刺也可能意外成立
    assign  rd_burst_done = rd_data_hs && (rd_word_cnt == BURST_WORDS - 1);

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn) begin
            rd_word_cnt   <= 7'd0;
        end
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else begin
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if (rd_data_hs) begin
                // 读突发最后一个字完成后清零突发内字计数。
                if (rd_word_cnt == BURST_WORDS-1)
                    rd_word_cnt <= 7'd0;
                // 当前读突发尚未到尾字时，继续累加读侧字计数。
                else
                    rd_word_cnt <= rd_word_cnt + 7'd1;
            end
        end
    end

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn) begin
            rd_addr  <= 32'd0;
        end
        // 读侧 busy 已释放时，本次读突发完成并可以推进读地址。
        else if ((rd_state == RD_WAIT) && (~fdma_rbusy)) begin
            // 读地址加上本次突发长度越过 4KB 窗口时回绕到起始地址。
            if (rd_addr + FDMA_BURST_LEN >= TEST_MEM_SIZE)
                rd_addr <= 32'd0;
            // 读地址仍在 4KB 窗口内时，按一个 FDMA 突发长度继续递增。
            else
                rd_addr <= rd_addr + FDMA_BURST_LEN;
        end
    end

    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign fdma_raddr = rd_addr;

    // FDMA 读接口输出
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    //always @(posedge fdma_clk or negedge fdma_rstn) begin
    //    if (!fdma_rstn)
    //        fdma_rareq <= 0;
    //    else if (rd_状态 == RD_REQ)
    //        fdma_rareq <= 1;
    //    else if (rd_状态 == RD_DATA && rd_状态_nxt == RD_WAIT)
    //        fdma_rareq <= 0;
    //end
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            fdma_rareq <= 1'b0;
        // 读侧尚未接受请求时保持 fdma_rareq 拉高。
        else if((rd_state == RD_REQ) && (~fdma_rbusy))
            fdma_rareq <= 1'b1;
        // 读请求已被 rbusy 接受后撤销 fdma_rareq，避免重复发起同一突发。
        else if(fdma_rareq && fdma_rbusy)
            fdma_rareq <= 1'b0;
    end




    // Aurora  tx_状态
    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。

    always @(posedge user_clk or negedge user_rstn) begin
        if (~user_rstn)
            tx_state <= TX_IDLE;
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else
            tx_state <= tx_state_nxt;
    end

    // 就绪/有效 握手控制，用于表达当前模块是否可接收或发送数据。
    wire tx_hs;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign tx_hs = tx_src_rdy && tx_dst_rdy;
    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign wr_burst_done = tx_hs && (tx_word_cnt == FRAME_WORDS-1);
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign tx_frame_done = wr_burst_done;

    // 组合 always 块计算下一状态/输出，注意不要引入锁存器。

    always @(*) begin
        tx_state_nxt = tx_state;
        // 根据 tx_state 选择对应状态的输出赋值和下一拍转移。
        case (tx_state)
            // TX_IDLE 保持接口空闲，等待启动条件满足。
            TX_IDLE:
                // Aurora 链路置位后才允许 FDMA 和 LocalLink 数据通路继续推进。
                if(channel_up && (~fifo_almost_empty))
                    tx_state_nxt=TX_SOF;
            // TX_SOF 发送帧首数据字，并在目的端就绪后进入连续数据阶段。
            TX_SOF :
                // LocalLink 的 src_rdy 与 dst_rdy 同拍有效时，当前 64bit 字完成一次链路传输。
                if(tx_hs)
                    tx_state_nxt=TX_DATA;
            // TX_DATA 搬运当前数据字，计数只随真实握手推进。
            TX_DATA:
                // 写突发完成后清零相关字计数，准备下一帧或下一突发。
                if(wr_burst_done)
                    tx_state_nxt=TX_IDLE;
            // 未列出的编码回到安全取值，避免状态机停留在非法状态。
            default: begin
                tx_state_nxt = TX_IDLE;
            end
        endcase
    end

    // CUSTOM-RTL-001 组合输出组例外：valid/data/SOF/EOF/REM共同描述同一拍，
    // 数据和边界均受同一FIFO有效条件约束。集中核对能避免边界与数据有效不一致；
    // 不包含寄存器或跨时钟生命周期。FIFO只在tx_hs时弹出，保证反压保持。

    always @(*) begin
        tx_src_rdy = (tx_state != TX_IDLE) && (~fifo_empty);
        tx_sof = (tx_state == TX_SOF) && tx_src_rdy;
        tx_eof = (tx_state == TX_DATA) && (tx_word_cnt == FRAME_WORDS-1) && tx_src_rdy;
        tx_rem = 3'b111;
        tx_d = tx_src_rdy ? fifo_rdata : 64'b0;
    end

    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。

    always @(posedge user_clk or negedge user_rstn) begin
        if (~user_rstn)
            tx_word_cnt     <= 8'd0;
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else begin
            if (tx_hs) begin
                if (tx_word_cnt == FRAME_WORDS-1)
                    tx_word_cnt <= 8'd0;
                else
                    tx_word_cnt <= tx_word_cnt + 8'd1;
            end
        end
    end


    // FIFO 相关组合控制，决定跨时钟缓存的读写、复位或数据通路。
    assign fifo_rd_en = tx_hs;

    // XPM FIFO
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

    // 该 函数 提供纯计算/格式化辅助，不直接消耗仿真时间。
    // DFX 函数
    // 帧计数和 突发 计数
    // 每发送完一帧，可能对应多个 突发，突发_cnt 在 RD_DATA 完成时增加
    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。

    always @(posedge user_clk or negedge user_rstn) begin
        if (~user_rstn)
            frame_cnt <= 16'd0;
        // 写突发在数据发送阶段完成时累计已发送帧数。
        else if (wr_burst_done && (tx_state==TX_DATA))
            frame_cnt <= frame_cnt + 16'd1;
    end

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            burst_cnt <= 16'd0;
        // 读突发完成后累计已发起的 FDMA 读突发数量。
        else if (rd_burst_done)
            burst_cnt <= burst_cnt + 16'd1;
    end

    // MSB -> LSB；不要把 overflow/underflow 合成一个跨时钟域编码。
    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign dbg_fdma_bus = {
        rd_state,           // [37:36] tx_dbg_rd_state
        fifo_wr_cnt,        // [35:26] tx_dbg_fifo_wr_cnt
        burst_cnt,          // [25:10] tx_dbg_burst_cnt
        rd_word_cnt,        // [9:3]   tx_rd_word_cnt
        rd_burst_done,      // [2]     tx_rd_burst_done
        fifo_wr_en,         // [1]     tx_fifo_wr_en
        fifo_overflow       // [0]     tx_err_fifo_overflow
    };

    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign dbg_user_bus = {
        tx_state,           // [38:37] tx_dbg_tx_state
        fifo_rd_cnt,        // [36:27] tx_dbg_fifo_rd_cnt
        frame_cnt,          // [26:11] tx_dbg_frame_cnt
        tx_word_cnt,        // [10:3]  tx_word_cnt
        wr_burst_done,      // [2]     tx_wr_burst_done
        fifo_rd_en,         // [1]     tx_fifo_rd_en
        fifo_underflow      // [0]     tx_err_fifo_underflow
    };

endmodule
