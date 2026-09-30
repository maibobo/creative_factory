`timescale 1ns / 1ps
// File: fdma_aurora_brg_aurora_loop_hw.v

// 仅硬件使用的顶层；将宏定义保留在本文件内，避免生成的运行 Tcl 漏掉它。
`define HARDWARE_DEBUG

`ifdef HARDWARE_DEBUG
// fdma_aurora_brg_aurora_loop_hw 模块入口；硬件运行顶层：加入板级差分时钟、MMCM、VIO 控制、硬件测试引擎和 ILA 观测。
module fdma_aurora_brg_aurora_loop_hw #(
    // 定义单帧传输的字节数，512B 正好对应一个 64 个 64bit 字的 FDMA 突发。
    parameter integer FRAME_BYTES = 512,
    // 固定 BURST_BYTES 的传输规模，保证读写两侧按同一长度收尾。
    parameter integer BURST_BYTES = 512
)(
    input  wire clk_p,
    input  wire clk_n,
    input  wire GTHQ0_P,
    input  wire GTHQ0_N,
    input  wire RXP,
    input  wire RXN,
    output wire TXP,
    output wire TXN,
    output wire sfp_tx_disable,
    output wire sfp_rs0,
    output wire sfp_rs1
);

    wire clk_init;
    wire fdma_clk;
    wire locked;
    wire sys_rst;

    // MMCM 失锁会异步拉起复位；复位释放会同步到
    // 250 MHz FDMA 时钟，避免功能复位恢复时序违规。
    (* ASYNC_REG = "TRUE" *) reg [1:0] fdma_reset_sync;
    wire fdma_rstn = fdma_reset_sync[1];

    wire [31:0] fdma_raddr;
    wire        fdma_rareq;
    wire        fdma_rbusy;
    wire [63:0] fdma_rdata;
    wire        fdma_rvalid;
    wire        fdma_rready;
    wire [31:0] fdma_waddr;
    wire        fdma_wareq;
    wire        fdma_wbusy;
    wire [63:0] fdma_wdata;
    wire        fdma_wvalid;
    wire [15:0] fdma_wsize;
    wire        fdma_wready;

    wire channel_up;
    wire lane_up;
    wire user_clk;
    wire user_rstn;
    wire [256:0] hw_test_dbg_bus;
    wire [187:0] hw_test_status_bus;

    wire        vio_start;
    wire        vio_clear;
    wire        vio_auto_enable;
    wire [15:0] vio_frame_limit;

    wire        test_running       = hw_test_status_bus[187];
    wire        test_done          = hw_test_status_bus[186];
    wire        test_pass          = hw_test_status_bus[185];
    wire [2:0]  test_result_code   = hw_test_status_bus[184:182];
    wire [15:0] test_target_frames = hw_test_status_bus[181:166];
    wire [31:0] first_error_index  = hw_test_status_bus[163:132];
    wire [1:0]  first_error_class  = hw_test_status_bus[131:130];
    wire        test_timeout       = hw_test_status_bus[1];
    wire        test_link_down     = hw_test_status_bus[0];
    wire [31:0] hw_rd_word_total   = hw_test_dbg_bus[256:225];
    wire [31:0] hw_wr_word_total   = hw_test_dbg_bus[224:193];
    wire [15:0] hw_rd_burst_count  = hw_test_dbg_bus[192:177];
    wire [15:0] hw_wr_burst_count  = hw_test_dbg_bus[176:161];
    wire [31:0] hw_error_count     = hw_test_dbg_bus[160:129];
    wire        hw_error_sticky    = hw_test_dbg_bus[128];
    wire [63:0] first_error_expected = hw_test_dbg_bus[127:64];
    wire [63:0] first_error_actual   = hw_test_dbg_bus[63:0];

    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    clk_wiz_1 u_clk_wiz_1 (
        .clk_out1 (clk_init), // 50 MHz Aurora initialization 时钟
        .clk_out2 (fdma_clk), // 250 MHz bridge/test-engine 时钟
        .locked   (locked),
        .clk_in1_p(clk_p),
        .clk_in1_n(clk_n)
    );

    assign sys_rst = ~locked;

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge locked) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!locked)
            fdma_reset_sync <= 2'b00;
        // 未命中前面的互斥路径时，保持当前阶段的正常推进。
        else
            fdma_reset_sync <= {fdma_reset_sync[0], 1'b1};
    end

    fdma_hw_test_engine #(
        .FRAME_BYTES(FRAME_BYTES),
        .BURST_BYTES(BURST_BYTES)
    ) u_fdma_hw_test_engine (
        .fdma_clk   (fdma_clk),
        .fdma_rstn  (fdma_rstn),
        .channel_up (channel_up),
        .test_start (vio_start),
        .test_clear (vio_clear),
        .auto_enable(vio_auto_enable),
        .frame_limit(vio_frame_limit),
        .fdma_raddr (fdma_raddr),
        .fdma_rareq (fdma_rareq),
        .fdma_rbusy (fdma_rbusy),
        .fdma_rdata (fdma_rdata),
        .fdma_rvalid(fdma_rvalid),
        .fdma_rready(fdma_rready),
        .fdma_waddr (fdma_waddr),
        .fdma_wareq (fdma_wareq),
        .fdma_wbusy (fdma_wbusy),
        .fdma_wdata (fdma_wdata),
        .fdma_wvalid(fdma_wvalid),
        .fdma_wsize (fdma_wsize),
        .fdma_wready(fdma_wready),
        .dbg_bus    (hw_test_dbg_bus),
        .status_dbg_bus(hw_test_status_bus)
    );

    // JTAG 控制运行控制；所有 VIO probe 都属于 fdma_clk 时钟域。
    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    vio_hw_ctrl u_vio_hw_ctrl (
        .clk       (fdma_clk),
        .probe_in0 (test_running),
        .probe_in1 (test_done),
        .probe_in2 (test_pass),
        .probe_in3 (test_result_code),
        .probe_in4 (test_target_frames),
        .probe_in5 (hw_rd_burst_count),
        .probe_in6 (hw_wr_burst_count),
        .probe_in7 (hw_rd_word_total),
        .probe_in8 (hw_wr_word_total),
        .probe_in9 (hw_error_count),
        .probe_in10(hw_error_sticky),
        .probe_in11(first_error_index),
        .probe_in12(first_error_expected),
        .probe_in13(first_error_actual),
        .probe_in14(first_error_class),
        .probe_in15({test_timeout, test_link_down}),
        .probe_out0(vio_start),
        .probe_out1(vio_clear),
        .probe_out2(vio_auto_enable),
        .probe_out3(vio_frame_limit)
    );

    fdma_aurora_brg_aurora_loop #(
        .SIMULATION  (0),
        .FRAME_BYTES (FRAME_BYTES),
        .DEBUG_ENABLE(1)
    ) u_fdma_aurora_brg_aurora_loop (
        .clk_init       (clk_init),
        .sys_rst        (sys_rst),
        .GTHQ0_P        (GTHQ0_P),
        .GTHQ0_N        (GTHQ0_N),
        .RXP            (RXP),
        .RXN            (RXN),
        .TXP            (TXP),
        .TXN            (TXN),
        .sfp_tx_disable (sfp_tx_disable),
        .sfp_rs0        (sfp_rs0),
        .sfp_rs1        (sfp_rs1),
        .fdma_clk       (fdma_clk),
        .fdma_rstn      (fdma_rstn),
        .cfg_tx_burst_limit(test_target_frames),
        .fdma_raddr     (fdma_raddr),
        .fdma_rareq     (fdma_rareq),
        .fdma_rbusy     (fdma_rbusy),
        .fdma_rdata     (fdma_rdata),
        .fdma_rvalid    (fdma_rvalid),
        .fdma_rready    (fdma_rready),
        .fdma_waddr     (fdma_waddr),
        .fdma_wareq     (fdma_wareq),
        .fdma_wbusy     (fdma_wbusy),
        .fdma_wdata     (fdma_wdata),
        .fdma_wvalid    (fdma_wvalid),
        .fdma_wsize     (fdma_wsize),
        .fdma_wready    (fdma_wready),
        .hw_test_dbg_bus(hw_test_dbg_bus),
        .hw_test_status_bus(hw_test_status_bus),
        .channel_up     (channel_up),
        .lane_up        (lane_up),
        .user_clk       (user_clk),
        .user_rstn      (user_rstn)
    );
endmodule
`endif
