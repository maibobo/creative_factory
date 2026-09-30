`timescale 1ns / 1ps
// File: ila_brg_loop.v

// FDMA/Aurora 环回的集中 ILA 封装；四组桥接调试总线
// 在这里展开，便于区分命名相近的 TX/RX 信号。
// ila_brg_loop 模块入口；调试观测封装：将 FDMA 域、Aurora user 域和硬件自测状态接入 ILA probe。
module ila_brg_loop (
    input          fdma_clk,
    input          fdma_rstn,
    input          user_clk,
    input          user_rstn,
    input          channel_up_fdma,
    input          channel_up,
    input          lane_up,

    input  [31:0]  fdma_raddr,
    input          fdma_rareq,
    input          fdma_rbusy,
    input  [63:0]  fdma_rdata,
    input          fdma_rvalid,
    input          fdma_rready,

    input  [31:0]  fdma_waddr,
    input          fdma_wareq,
    input          fdma_wbusy,
    input  [63:0]  fdma_wdata,
    input          fdma_wvalid,
    input  [15:0]  fdma_wsize,
    input          fdma_wready,

    input  [63:0]  ll_tx_d,
    input          ll_tx_sof,
    input          ll_tx_eof,
    input  [2:0]   ll_tx_rem,
    input          ll_tx_src_rdy,
    input          ll_tx_dst_rdy,

    input  [63:0]  ll_rx_d,
    input          ll_rx_sof,
    input          ll_rx_eof,
    input  [2:0]   ll_rx_rem,
    input          ll_rx_src_rdy,
    input          ll_rx_dst_rdy,

    input  [37:0]  tx_fdma_dbg_bus,
    input  [38:0]  tx_user_dbg_bus,
    input  [105:0] rx_fdma_dbg_bus,
    input  [28:0]  rx_user_dbg_bus,
    input  [256:0] hw_test_dbg_bus,
    input  [187:0] hw_test_status_bus
);

    // 硬件测试引擎：fdma_clk 时钟域。
    wire [31:0] hw_rd_word_total         = hw_test_dbg_bus[256:225];
    wire [31:0] hw_wr_word_total         = hw_test_dbg_bus[224:193];
    wire [15:0] hw_rd_burst_count        = hw_test_dbg_bus[192:177];
    wire [15:0] hw_wr_burst_count        = hw_test_dbg_bus[176:161];
    wire [31:0] hw_error_count           = hw_test_dbg_bus[160:129];
    wire        hw_error_sticky          = hw_test_dbg_bus[128];
    wire [63:0] hw_first_error_expected  = hw_test_dbg_bus[127:64];
    wire [63:0] hw_first_error_actual    = hw_test_dbg_bus[63:0];

    wire        hw_test_running          = hw_test_status_bus[187];
    wire        hw_test_done             = hw_test_status_bus[186];
    wire        hw_test_pass             = hw_test_status_bus[185];
    wire [2:0]  hw_result_code           = hw_test_status_bus[184:182];
    wire        hw_test_start_level      = hw_test_status_bus[165];
    wire        hw_first_error_pulse     = hw_test_status_bus[164];
    wire [31:0] hw_first_error_index     = hw_test_status_bus[163:132];
    wire [1:0]  hw_first_error_class     = hw_test_status_bus[131:130];
    wire        hw_test_timeout          = hw_test_status_bus[1];
    wire        hw_test_link_down        = hw_test_status_bus[0];

    // TX 桥：fdma_clk 时钟域
    wire [1:0]  tx_dbg_rd_state       = tx_fdma_dbg_bus[37:36];
    wire [9:0]  tx_dbg_fifo_wr_cnt    = tx_fdma_dbg_bus[35:26];
    wire [15:0] tx_dbg_burst_cnt      = tx_fdma_dbg_bus[25:10];
    wire [6:0]  tx_rd_word_cnt        = tx_fdma_dbg_bus[9:3];
    wire        tx_rd_burst_done      = tx_fdma_dbg_bus[2];
    wire        tx_fifo_wr_en         = tx_fdma_dbg_bus[1];
    wire        tx_err_fifo_overflow  = tx_fdma_dbg_bus[0];

    // TX 桥：user_clk 时钟域
    wire [1:0]  tx_dbg_tx_state       = tx_user_dbg_bus[38:37];
    wire [9:0]  tx_dbg_fifo_rd_cnt    = tx_user_dbg_bus[36:27];
    wire [15:0] tx_dbg_frame_cnt      = tx_user_dbg_bus[26:11];
    wire [7:0]  tx_word_cnt           = tx_user_dbg_bus[10:3];
    wire        tx_wr_burst_done      = tx_user_dbg_bus[2];
    wire        tx_fifo_rd_en         = tx_user_dbg_bus[1];
    wire        tx_err_fifo_underflow = tx_user_dbg_bus[0];

    // RX 桥：user_clk 时钟域
    wire [10:0] rx_dbg_fifo_wr_cnt    = rx_user_dbg_bus[28:18];
    wire [15:0] rx_dbg_frame_cnt      = rx_user_dbg_bus[17:2];
    wire        rx_fifo_wr_en         = rx_user_dbg_bus[1];
    wire        rx_err_fifo_overflow  = rx_user_dbg_bus[0];

    // RX 桥：fdma_clk 时钟域
    wire [63:0] rx_wdata_hold         = rx_fdma_dbg_bus[105:42];
    wire [1:0]  rx_dbg_wr_state       = rx_fdma_dbg_bus[41:40];
    wire [10:0] rx_dbg_fifo_rd_cnt    = rx_fdma_dbg_bus[39:29];
    wire [15:0] rx_dbg_burst_cnt      = rx_fdma_dbg_bus[28:13];
    wire [6:0]  rx_wr_word_cnt        = rx_fdma_dbg_bus[12:6];
    wire        rx_wdata_hold_valid   = rx_fdma_dbg_bus[5];
    wire        rx_w_hs               = rx_fdma_dbg_bus[4];
    wire        rx_w_last_hs          = rx_fdma_dbg_bus[3];
    wire        rx_wr_burst_done      = rx_fdma_dbg_bus[2];
    wire        rx_fifo_rd_en         = rx_fdma_dbg_bus[1];
    wire        rx_err_fifo_underflow = rx_fdma_dbg_bus[0];

    // 分阶段累计值可定位丢失的数据字，无需抓取完整运行过程。
    reg [31:0] tx_fifo_wr_total;
    reg [31:0] rx_fifo_rd_total;
    reg [31:0] tx_ll_hs_total;
    reg [31:0] rx_ll_hs_total;
    reg [31:0] rx_fifo_wr_total;
    reg        test_start_fdma_d;
    (* ASYNC_REG = "TRUE" *) reg [1:0] test_start_user_sync;
    reg        test_start_user_d;
    wire test_start_fdma_rise = hw_test_start_level && !test_start_fdma_d;
    wire test_start_user_rise = test_start_user_sync[1] && !test_start_user_d;

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!fdma_rstn) begin
            test_start_fdma_d <= 1'b0;
            tx_fifo_wr_total <= 32'd0;
            rx_fifo_rd_total <= 32'd0;
        end else begin
            test_start_fdma_d <= hw_test_start_level;
            // FDMA 时钟域捕获到测试启动上升沿时清零读写统计。
            if (test_start_fdma_rise) begin
                tx_fifo_wr_total <= 32'd0;
                rx_fifo_rd_total <= 32'd0;
            end else begin
                // TX FIFO 写入监测有效时累计写入总数。
                if (tx_fifo_wr_en && tx_fifo_wr_total != 32'hffff_ffff)
                    tx_fifo_wr_total <= tx_fifo_wr_total + 1'b1;
                // RX FIFO 读出监测有效时累计读出总数。
                if (rx_fifo_rd_en && rx_fifo_rd_total != 32'hffff_ffff)
                    rx_fifo_rd_total <= rx_fifo_rd_total + 1'b1;
            end
        end
    end

    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。
    always @(posedge user_clk or negedge user_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!user_rstn) begin
            test_start_user_sync <= 2'b00;
            test_start_user_d <= 1'b0;
            tx_ll_hs_total <= 32'd0;
            rx_ll_hs_total <= 32'd0;
            rx_fifo_wr_total <= 32'd0;
        end else begin
            test_start_user_sync <= {test_start_user_sync[0], hw_test_start_level};
            test_start_user_d <= test_start_user_sync[1];
            // 用户时钟域捕获到测试启动上升沿时清零链路侧统计。
            if (test_start_user_rise) begin
                tx_ll_hs_total <= 32'd0;
                rx_ll_hs_total <= 32'd0;
                rx_fifo_wr_total <= 32'd0;
            end else begin
                // LocalLink 的 src_rdy 与 dst_rdy 同拍有效时，当前 64bit 字完成一次链路传输。
                if (ll_tx_src_rdy && ll_tx_dst_rdy && tx_ll_hs_total != 32'hffff_ffff)
                    tx_ll_hs_total <= tx_ll_hs_total + 1'b1;
                // LocalLink 的 src_rdy 与 dst_rdy 同拍有效时，当前 64bit 字完成一次链路传输。
                if (ll_rx_src_rdy && ll_rx_dst_rdy && rx_ll_hs_total != 32'hffff_ffff)
                    rx_ll_hs_total <= rx_ll_hs_total + 1'b1;
                // RX FIFO 写入监测有效时累计写入总数。
                if (rx_fifo_wr_en && rx_fifo_wr_total != 32'hffff_ffff)
                    rx_fifo_wr_total <= rx_fifo_wr_total + 1'b1;
            end
        end
    end

    // 硬件顶层通过 DEBUG_ENABLE=1 使能该封装。
    // Vivado ILA IP：52 个 probe，1024 个采样点，1 级输入流水。
    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    ila_fdma_hw u_ila_fdma (
        .clk     (fdma_clk),              // 1 位；硬件顶层内部 采样时钟
        .probe0  (fdma_rstn),             // 1 位；硬件顶层内部 复位
        .probe1  (channel_up_fdma),       // 1 位；内部同步状态
        .probe2  (fdma_raddr),            // 32 位；HW-顶层 内部, IT-DUT 输出
        .probe3  (fdma_rareq),            // 1 位；HW-顶层 内部, IT-DUT 输出
        .probe4  (fdma_rbusy),            // 1 位；HW-顶层 内部, IT-DUT 输入
        .probe5  (fdma_rdata),            // 64 位；HW-顶层 内部, IT-DUT 输入
        .probe6  (fdma_rvalid),           // 1 位；HW-顶层 内部, IT-DUT 输入
        .probe7  (fdma_rready),           // 1 位；HW-顶层 内部, IT-DUT 输出
        .probe8  (fdma_waddr),            // 32 位；HW-顶层 内部, IT-DUT 输出
        .probe9  (fdma_wareq),            // 1 位；HW-顶层 内部, IT-DUT 输出
        .probe10 (fdma_wbusy),            // 1 位；HW-顶层 内部, IT-DUT 输入
        .probe11 (fdma_wdata),            // 64 位；HW-顶层 内部, IT-DUT 输出
        .probe12 (fdma_wvalid),           // 1 位；HW-顶层 内部, IT-DUT 输出
        .probe13 (fdma_wsize),            // 16 位；HW-顶层 内部, IT-DUT 输出
        .probe14 (fdma_wready),           // 1 位；HW-顶层 内部, IT-DUT 输入
        .probe15 (tx_fifo_wr_en),         // 1 位；内部 TX 桥信号
        .probe16 (tx_rd_burst_done),      // 1 位；内部 TX 桥信号
        .probe17 (tx_rd_word_cnt),        // 7 位；内部 TX 桥信号
        .probe18 (tx_dbg_rd_state),       // 2 位；内部 TX 桥信号
        .probe19 (tx_dbg_fifo_wr_cnt),    // 10 位；内部 TX 桥信号
        .probe20 (tx_dbg_burst_cnt),      // 16 位；内部 TX 桥信号
        .probe21 (tx_err_fifo_overflow),  // 1 位；内部 TX 桥信号
        .probe22 (rx_fifo_rd_en),         // 1 位；内部 RX 桥信号
        .probe23 (rx_wr_burst_done),      // 1 位；内部 RX 桥信号
        .probe24 (rx_wr_word_cnt),        // 7 位；内部 RX 桥信号
        .probe25 (rx_wdata_hold),         // 64 位；内部 RX 桥信号
        .probe26 (rx_wdata_hold_valid),   // 1 位；内部 RX 桥信号
        .probe27 (rx_w_hs),               // 1 位；内部 RX 桥信号
        .probe28 (rx_w_last_hs),          // 1 位；内部 RX 桥信号
        .probe29 (rx_dbg_wr_state),       // 2 位；内部 RX 桥信号
        .probe30 (rx_dbg_fifo_rd_cnt),    // 11 位；内部 RX 桥信号
        .probe31 (rx_dbg_burst_cnt),      // 16 位；内部 RX 桥信号
        .probe32 (rx_err_fifo_underflow), // 1 位；内部 RX 桥信号
        .probe33 (hw_rd_word_total),      // 32 位；HW-顶层 内部 测试计数器
        .probe34 (hw_wr_word_total),      // 32 位；HW-顶层 内部 测试计数器
        .probe35 (hw_rd_burst_count),     // 16 位；HW-顶层 内部 测试计数器
        .probe36 (hw_wr_burst_count),     // 16 位；HW-顶层 内部 测试计数器
        .probe37 (hw_error_count),        // 32 位；HW-顶层 内部 错误计数器
        .probe38 (hw_error_sticky),       // 1 位；HW-顶层 内部错误标志
        .probe39 (hw_first_error_expected),// 64 位；HW-顶层 内部 首次期望值
        .probe40 (hw_first_error_actual), // 64 位；HW-顶层 内部 首次实际值
        .probe41 (hw_test_running),       // 1 位；有界测试运行中
        .probe42 (hw_test_done),          // 1 位；有界测试完成
        .probe43 (hw_test_pass),          // 1 位；持久通过结果
        .probe44 (hw_result_code),        // 3 位；运行结果码
        .probe45 (hw_test_start_level),   // 1 位；展宽后的启动触发
        .probe46 (hw_first_error_pulse),  // 1 位；首次不匹配 触发
        .probe47 (hw_first_error_index),  // 32 位；首次不匹配 数据字 索引
        .probe48 (hw_first_error_class),  // 2 位；跳过/重复/其他
        .probe49 (tx_fifo_wr_total),      // 32 位；TX FIFO 已接受 数据字s
        .probe50 (rx_fifo_rd_total),      // 32 位；RX FIFO delivered 数据字s
        .probe51 ({hw_test_timeout, hw_test_link_down}) // 2 位；终止标志
    );

    // Vivado ILA IP：29 个 probe，由 Aurora user_clk 采样。
    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    ila_user_hw u_ila_user (
        .clk     (user_clk),              // 1 位；硬件顶层内部 采样时钟
        .probe0  (user_rstn),             // 1 位；硬件顶层内部 状态
        .probe1  (channel_up),            // 1 位；硬件顶层内部 状态
        .probe2  (lane_up),               // 1 位；硬件顶层内部 状态
        .probe3  (ll_tx_d),               // 64 位；内部 LocalLink TX 信号
        .probe4  (ll_tx_sof),             // 1 位；内部 LocalLink TX 信号
        .probe5  (ll_tx_eof),             // 1 位；内部 LocalLink TX 信号
        .probe6  (ll_tx_rem),             // 3 位；内部 LocalLink TX 信号
        .probe7  (ll_tx_src_rdy),         // 1 位；内部 LocalLink TX 信号
        .probe8  (ll_tx_dst_rdy),         // 1 位；内部 LocalLink TX 信号
        .probe9  (ll_rx_d),               // 64 位；内部 LocalLink RX 信号
        .probe10 (ll_rx_sof),             // 1 位；内部 LocalLink RX 信号
        .probe11 (ll_rx_eof),             // 1 位；内部 LocalLink RX 信号
        .probe12 (ll_rx_rem),             // 3 位；内部 LocalLink RX 信号
        .probe13 (ll_rx_src_rdy),         // 1 位；内部 LocalLink RX 信号
        .probe14 (ll_rx_dst_rdy),         // 1 位；内部 LocalLink RX 信号
        .probe15 (tx_fifo_rd_en),         // 1 位；内部 TX 桥信号
        .probe16 (tx_wr_burst_done),      // 1 位；内部 TX 桥信号
        .probe17 (tx_word_cnt),           // 8 位；内部 TX 桥信号
        .probe18 (tx_dbg_tx_state),       // 2 位；内部 TX 桥信号
        .probe19 (tx_dbg_fifo_rd_cnt),    // 10 位；内部 TX 桥信号
        .probe20 (tx_dbg_frame_cnt),      // 16 位；内部 TX 桥信号
        .probe21 (tx_err_fifo_underflow), // 1 位；内部 TX 桥信号
        .probe22 (rx_fifo_wr_en),         // 1 位；内部 RX 桥信号
        .probe23 (rx_dbg_fifo_wr_cnt),    // 11 位；内部 RX 桥信号
        .probe24 (rx_dbg_frame_cnt),      // 16 位；内部 RX 桥信号
        .probe25 (rx_err_fifo_overflow),  // 1 位；内部 RX 桥信号
        .probe26 (tx_ll_hs_total),        // 32 位；LocalLink TX 传输计数
        .probe27 (rx_ll_hs_total),        // 32 位；LocalLink RX 传输计数
        .probe28 (rx_fifo_wr_total)       // 32 位；RX FIFO 已接受 数据字s
    );
endmodule