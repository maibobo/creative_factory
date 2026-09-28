`timescale 1ns / 1ps
// File: fdma_aurora_brg_rx.v
//////////////////////////////////////////////////////////////////////////////////
// 模块名称: fdma_aurora_brg_rx
// 功能:
//   接收 Aurora RX 本地链路数据，写入异步 FIFO 后在 fdma_clk 时钟域发起
//   FDMA 写事务，把环回数据写回测试空间。
//////////////////////////////////////////////////////////////////////////////////

// fdma_aurora_brg_rx 模块入口；接收桥：接收 Aurora LocalLink 数据，经异步 FIFO 回到 FDMA 时钟域，并按 突发 写回测试地址空间。
module fdma_aurora_brg_rx #(
        parameter integer MEM_WINDOW_BYTES = 4096
    )(
        input               fdma_clk,
        input               fdma_rstn,
        input               user_clk,
        input               user_rstn,

        // 控制与状态
        input               channel_up_fdma,      // Aurora 链路已建立，并同步到 fdma_clk 域

        // FDMA 写接口，fdma_clk 时钟域
        output [31:0]       fdma_waddr,
        output reg          fdma_wareq,
        input               fdma_wbusy,
        output [63:0]       fdma_wdata,
        output              fdma_wvalid,
        output [15:0]       fdma_wsize,
        input               fdma_wready,    // 写从机准备好接收数据

        // Aurora RX 本地链路接口，user_clk 时钟域
        input  [63:0]       rx_d,
        input               rx_sof,
        input               rx_eof,
        input  [2:0]        rx_rem,
        input               rx_src_rdy,
        output [28:0]       dbg_user_bus,
        output [105:0]      dbg_fdma_bus,
        output              rx_fifo_almost_full,
        output              rx_fifo_full,
        output              rx_fifo_overflow,
        output              rx_dst_rdy,  // 反压信号
        output              rx_burst_done

    );


    // ======================== 参数定义 ========================
    // Address window for 512B bursts. The default keeps the original 4KB behavior.
    localparam TEST_MEM_SIZE   = MEM_WINDOW_BYTES;
    // 固定 FDMA 单次突发长度为 512B，与一帧 64 个 64bit 字保持一致。
    localparam FDMA_BURST_LEN  = 16'd512;         // 512 字节/突发
    // 固定单次 FDMA 突发包含的 64bit 字数，和 512B 帧长度保持一致。
    //localparam FRAME_BYTES     = 16'd1024;        // 1024 字节/帧，128 个 64 位字
    // 固定单次 FDMA 突发包含的 64bit 字数，和 512B 帧长度保持一致。
    localparam BURST_WORDS     = FDMA_BURST_LEN / 8;  // 512 字节对应 64 个 64 位字
    // FDMA 写状态机空闲编码。
    //localparam FRAME_WORDS     = FRAME_BYTES / 8;     // 1024 字节对应 128 个 64 位字

    // ======================== FDMA 写引擎状态机 ========================
    // FDMA 写状态机空闲编码。
    localparam WR_IDLE  = 2'd0;
    // FDMA 写状态机请求编码。
    localparam WR_REQ   = 2'd1;
    // FDMA 写状态机数据传输编码。
    localparam WR_DATA  = 2'd2;
    // 设置 WR_WAIT 的等待周期上限，防止异常场景下仿真无限挂起。
    localparam WR_WAIT  = 2'd3;



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
    wire [10:0] fifo_wr_cnt;
    wire [10:0] fifo_rd_cnt;
    wire        fifo_almost_full;
    wire        fifo_almost_empty;
    wire        wr_rst_busy;
    wire        rd_rst_busy;

    reg [1:0]  wr_state;
    reg [1:0]  wr_state_nxt;
    reg [31:0] wr_addr;
    reg [6:0]  wr_word_cnt;          // - 然后连续提供 rvalid 数据（共 BURST_WORDS 拍）
    wire       wr_burst_done;
    wire       wr_clk;
    wire       rd_clk;

    // FIFO 读写使能
    assign wr_clk = user_clk;
    assign rd_clk = fdma_clk;
    // 本桥接中 Aurora RX LocalLink 侧始终就绪。
    // 就绪/有效 握手控制，用于表达当前模块是否可接收或发送数据。
    // 复位忙期间禁止实际读写 FIFO。

    // Aurora SERDES RX 数据侧不允许下游反压，桥接端必须始终声明可接收。
    // 就绪/有效 握手控制，用于表达当前模块是否可接收或发送数据。
    // LocalLink data is accepted only when the asynchronous FIFO can store it.
    // The Aurora example shim cannot always propagate this back to the serial
    // core, so overflow remains observable as a sticky integration error.
    assign rx_dst_rdy = user_rstn && !wr_rst_busy && !fifo_full;

    // ======================== FDMA 写数据通路 ========================
    // wdata_hold 是写数据输出寄存器。
    // 当寄存器为空时，从 RX FIFO 装载一个数据字。
    // 当当前数据字被 FDMA 接收且不是突发最后一个字时，同一拍从 RX FIFO 补入下一个数据字。
    // wready 拉低时保持当前 wdata/wvalid，不推进 RX FIFO。

    reg [63:0] wdata_hold;
    reg        wdata_hold_valid;

    wire w_hs      = fdma_wvalid && fdma_wready;
    wire w_last_hs = w_hs && (wr_word_cnt == BURST_WORDS-1);

    // 非最后一个字完成握手时允许同拍补货，稳态下可以每个 fdma_clk 完成一个写数据握手。
    // FIFO 相关组合控制，决定跨时钟缓存的读写、复位或数据通路。
    assign fifo_rd_en = (wr_state == WR_DATA) && fdma_wbusy && !fifo_empty && !rd_rst_busy &&
                        (!wdata_hold_valid || (w_hs && !w_last_hs));

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn) begin
            wdata_hold_valid <= 1'b0;
            wdata_hold       <= 64'd0;
        end else begin
            // 离开写数据阶段时清除 wdata 保持寄存器，避免旧数据被误复用。
            if (wr_state != WR_DATA) begin
                wdata_hold_valid <= 1'b0;
                wdata_hold       <= 64'd0;
            end else if (fifo_rd_en) begin
                // 寄存器为空，或当前数据字已被接收且允许补入下一个数据字。
                wdata_hold       <= fifo_rdata;
                wdata_hold_valid <= 1'b1;
            end else if (w_hs) begin
                // 突发最后一个字完成后不跨突发预取，保持寄存器清空。
                wdata_hold_valid <= 1'b0;
                wdata_hold       <= 64'd0;
            end
        end
    end

    // FDMA 写接口输出。wvalid 只表示输出寄存器中已有稳定数据。
    assign fdma_wvalid = wdata_hold_valid && (wr_state == WR_DATA) && fdma_wbusy;
    assign fdma_wdata  = wdata_hold;

    // FIFO 写入保护: 当 FIFO 满时丢弃数据（避免 overflow）
    assign fifo_wr_en = rx_src_rdy && rx_dst_rdy;
    assign wr_en = fifo_wr_en && !wr_rst_busy;
    assign rd_en = fifo_rd_en;

    assign fifo_wdata = rx_d;
    assign fifo_rst = ~user_rstn;
    assign rx_fifo_almost_full = fifo_almost_full;
    assign rx_fifo_full = fifo_full;
    assign rx_fifo_overflow = fifo_overflow;

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            wr_state <= WR_IDLE;
        else
            wr_state <= wr_state_nxt;
    end

    // 组合 always 块计算下一状态/输出，注意不要引入锁存器。
    always @(*) begin
        wr_state_nxt = wr_state;
        // 根据 wr_state 选择对应状态的输出赋值和下一拍转移。
        case (wr_state)
            // WR_IDLE 等待 RX FIFO 中出现可写回的数据，并保持写请求空闲。
            WR_IDLE:
                // Aurora 链路置位后才允许 FDMA 和 LocalLink 数据通路继续推进。
                if(channel_up_fdma && (~fifo_empty))
                    wr_state_nxt=WR_REQ;
            // WR_REQ 向 FDMA 写侧发起写请求，等待写通道接受当前突发。
            WR_REQ :
                // FDMA 写侧接受请求后进入写数据传输阶段。
                if (fdma_wbusy)
                    wr_state_nxt = WR_DATA;
            // WR_DATA 在写通道 ready 时送出 RX FIFO 数据，并保持末字节控制稳定。
            WR_DATA:
                // 写突发完成后清零相关字计数，准备下一帧或下一突发。
                if(wr_burst_done)
                    wr_state_nxt=WR_WAIT;
            // WR_WAIT 等待写侧 busy 撤销，再允许下一次写回突发。
            WR_WAIT: // 等待写从机撤销 wbusy，完成本次 FDMA 写事务收尾
                // FDMA 写侧释放 busy 后，本次写事务收尾并回到空闲。
                if(~fdma_wbusy)
                    wr_state_nxt=WR_IDLE;
            // 未列出的编码回到安全取值，避免状态机停留在非法状态。
            default:
                wr_state_nxt=wr_state;
        endcase
    end

    assign wr_burst_done = (wr_state == WR_DATA) && w_hs && (wr_word_cnt == BURST_WORDS-1);
    assign rx_burst_done = wr_burst_done;

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn) begin
            wr_word_cnt   <= 7'd0;
        end
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else begin
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if (wr_state == WR_DATA && w_hs) begin
                // 写突发最后一个字完成后清零突发内字计数。
                if (wr_word_cnt == BURST_WORDS-1)
                    wr_word_cnt <= 7'd0;
                // 当前写突发尚未到尾字时，继续累加写侧字计数。
                else
                    wr_word_cnt <= wr_word_cnt + 1;
            end
        end
    end

    // 地址更新，仅在一个突发完成后推进。
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            wr_addr <= 32'd0;
        // 写侧 busy 已释放时，本次写突发完成并可以推进写地址。
        else if ((wr_state == WR_WAIT) && (~fdma_wbusy)) begin
            // 写地址加上本次突发长度越过 4KB 窗口时回绕到起始地址。
            if (wr_addr + FDMA_BURST_LEN >= TEST_MEM_SIZE)
                wr_addr <= 32'd0;
            // 写地址仍在 4KB 窗口内时，按一个 FDMA 突发长度继续递增。
            else
                wr_addr <= wr_addr + FDMA_BURST_LEN;
        end
    end

    assign fdma_waddr = wr_addr;
    assign fdma_wsize = FDMA_BURST_LEN;

    // FDMA 写请求输出
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (~fdma_rstn)
            fdma_wareq <= 1'b0;
        // 写侧尚未接受请求时保持 fdma_wareq 拉高。
        else if(wr_state == WR_REQ && (~fdma_wbusy))
            fdma_wareq <= 1'b1;
        // 写请求已被 wbusy 接受后撤销 fdma_wareq，避免重复发起同一突发。
        else if(fdma_wareq && fdma_wbusy)
            fdma_wareq <= 1'b0;
    end


    // XPM FIFO
    xpm_fifo_async #(
                       .CDC_SYNC_STAGES(2),
                       .DOUT_RESET_VALUE("0"),
                       .ECC_MODE("no_ecc"),
                       .FIFO_MEMORY_TYPE("auto"),
                       .FIFO_READ_LATENCY(0),
                       .FIFO_WRITE_DEPTH(2048),
                       .FULL_RESET_VALUE(0),
                       .PROG_EMPTY_THRESH(10),
                       .PROG_FULL_THRESH(2048-16),
                       .RD_DATA_COUNT_WIDTH(11),
                       .READ_DATA_WIDTH(64),
                       .READ_MODE("fwft"),
                       .RELATED_CLOCKS(0),
                       .SIM_ASSERT_CHK(0),
                       .USE_ADV_FEATURES("1f1f"),
                       .WAKEUP_TIME(0),
                       .WRITE_DATA_WIDTH(64),
                       .WR_DATA_COUNT_WIDTH(11)
                   )
                   u_rx_fifo (
                       .almost_empty(),
                       .almost_full(fifo_almost_full),
                       .data_valid(),
                       .dbiterr(),
                       .dout(fifo_rdata),
                       .empty(fifo_empty),
                       .full(fifo_full),
                       .overflow(fifo_overflow),
                       .prog_empty(),
                       .prog_full(),
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
    // 调试信号
    // 帧计数和突发计数
    reg [15:0] frame_cnt, burst_cnt;
    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。
    always @(posedge user_clk or negedge user_rstn) begin
        if (!user_rstn)
            frame_cnt <= 0;
        // 当前通道完成有效握手时才推进数据、计数器或队列指针。
        else if (rx_eof && rx_src_rdy && rx_dst_rdy)
            frame_cnt <= frame_cnt + 1;
    end
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn)
            burst_cnt <= 0;
        // 写突发完成后清零相关字计数，准备下一帧或下一突发。
        else if (wr_burst_done)
            burst_cnt <= burst_cnt + 1;
    end

    // 调试总线打包（MSB -> LSB），按原生时钟域拆分。
    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign dbg_user_bus = {
        fifo_wr_cnt,        // [28:18] rx_dbg_fifo_wr_cnt
        frame_cnt,          // [17:2]  rx_dbg_frame_cnt
        fifo_wr_en,         // [1]     rx_fifo_wr_en
        fifo_overflow       // [0]     rx_err_fifo_overflow
    };

    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign dbg_fdma_bus = {
        wdata_hold,         // [105:42] rx_wdata_hold
        wr_state,           // [41:40]  rx_dbg_wr_state
        fifo_rd_cnt,        // [39:29]  rx_dbg_fifo_rd_cnt
        burst_cnt,          // [28:13]  rx_dbg_burst_cnt
        wr_word_cnt,        // [12:6]   rx_wr_word_cnt
        wdata_hold_valid,   // [5]      rx_wdata_hold_valid
        w_hs,               // [4]      rx_w_hs
        w_last_hs,          // [3]      rx_w_last_hs
        wr_burst_done,      // [2]      rx_wr_burst_done
        fifo_rd_en,         // [1]      rx_fifo_rd_en
        fifo_underflow      // [0]      rx_err_fifo_underflow
    };

    // FIFO 读写累计计数
    reg [31:0] wr_total_cnt;
    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。
    always @(posedge user_clk or negedge user_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if(!user_rstn)
            wr_total_cnt <= 0;
        // RX FIFO 实际写入成功时累计写入字数。
        else if(wr_en && !fifo_full)
            wr_total_cnt <= wr_total_cnt + 1'b1;
    end

    reg [31:0] rd_total_cnt;
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if(!fdma_rstn)
            rd_total_cnt <= 0;
        // RX FIFO 被读出一个数据字时累计读出字数。
        else if(rd_en)
            rd_total_cnt <= rd_total_cnt + 1'b1;
    end


endmodule
