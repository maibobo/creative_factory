`timescale 1ns / 1ps
// File: aurora_loop_harness.sv

// 完整集成 harness：包含桥接模块、Aurora 核和串行 GT 自环。
// 测试策略保留在 testcase 中，本模块只负责结构连接。
module aurora_loop_harness #(
    parameter integer FRAME_BYTES = 512 // Forwarded through the Aurora 封装.
);
    localparam real FDMA_CLK_PERIOD_NS = 4.0;    // 250MHz FDMA 时钟。
    localparam real INIT_CLK_PERIOD_NS = 20.0;   // 50MHz Aurora initialization 时钟。
    localparam real GT_REF_CLK_PERIOD_NS = 6.4;  // 156.25MHz GT reference 时钟。

    logic fdma_clk;     // 桥接 FDMA 时钟域时钟。
    logic init_clk;     // Aurora 初始化时钟。
    logic gt_ref_clk_n; // Negative side of generated differential reference.
    logic sys_rst;      // 高有效 Aurora 系统复位。
    logic fdma_rstn;    // 低有效桥接复位。

    wire gt_ref_clk_p = ~gt_ref_clk_n; // Positive side of the differential reference.
    wire channel_up;                    // Aurora 通道就绪状态。
    wire lane_up;                       // Aurora lane 就绪状态。
    wire user_clk;                      // Aurora 生成的 LocalLink 时钟。
    wire user_rstn;                     // Aurora 生成的低有效用户复位。
    wire txp;                           // Serial TX positive pin.
    wire txn;                           // Serial TX negative pin.
    wire rxp = txp;                     // Physical self-loop positive path.
    wire rxn = txn;                     // Physical self-loop negative path.

    // 生成 Aurora 示例设计需要的三路时钟。
    initial fdma_clk = 1'b0;
    always #(FDMA_CLK_PERIOD_NS/2.0) fdma_clk = ~fdma_clk;

    initial init_clk = 1'b0;
    always #(INIT_CLK_PERIOD_NS/2.0) init_clk = ~init_clk;

    initial gt_ref_clk_n = 1'b0;
    always #(GT_REF_CLK_PERIOD_NS/2.0) gt_ref_clk_n = ~gt_ref_clk_n;

    // 沿用 Aurora 示例工程的复位顺序，然后释放 FDMA 侧复位。
    initial begin
        sys_rst   = 1'b1;                    // 复位 Aurora/GT example design.
        fdma_rstn = 1'b0;                    // Keep bridge 复位 asserted.
        repeat (160) @(posedge init_clk);    // Satisfy Aurora 仿真 复位 time.
        sys_rst = 1'b0;                      // Start Aurora channel initialization.
        #60 fdma_rstn = 1'b1;                // Release bridge shortly afterward.
    end

    fdma_read_if  rd_if(fdma_clk, fdma_rstn); // Read BFM/DUT 信号 bundle.
    fdma_write_if wr_if(fdma_clk, fdma_rstn); // Write BFM/DUT 信号 bundle.
    ll_link_if    ll_if(user_clk, user_rstn); // 观测到 LocalLink boundary.
    brg_ctrl_if   ctrl_if();                  // Present for a uniform 类 constructor.
    brg_obs_if    obs_if(fdma_clk, user_clk); // 内部 bridge and FIFO probe.

    initial begin
        ctrl_if.force_tx_almost_full = 1'b0; // No verification force in full-loop mode.
        ctrl_if.can_drive_tx_dst_rdy = 1'b0; // tx_dst_rdy 由 Aurora 核控制。
        ctrl_if.rx_loopback_enable = 1'b1;   // Kept at default; GT provides real loopback.
        ctrl_if.rx_drive_d = 64'd0;          // Unused 直连-注入 载荷.
        ctrl_if.cfg_tx_burst_limit = 16'd0;
        ctrl_if.rx_drive_sof = 1'b0;         // Unused 直连 SOF.
        ctrl_if.rx_drive_eof = 1'b0;         // Unused 直连 EOF.
        ctrl_if.rx_drive_rem = 3'b111;       // Unused 直连 REM.
        ctrl_if.rx_drive_src_rdy = 1'b0;     // Disable 直连 injector.
    end

    // 包含 Aurora IP 示例封装的完整 DUT。
    fdma_aurora_brg_aurora_loop #(
        .SIMULATION  (1),
        .FRAME_BYTES (FRAME_BYTES)
    ) dut (
        .clk_init       (init_clk),
        .sys_rst        (sys_rst),
        .GTHQ0_P        (gt_ref_clk_p),
        .GTHQ0_N        (gt_ref_clk_n),
        .RXP            (rxp),
        .RXN            (rxn),
        .TXP            (txp),
        .TXN            (txn),
        .sfp_tx_disable (),
        .sfp_rs0        (),
        .sfp_rs1        (),
        .fdma_clk       (fdma_clk),
        .fdma_rstn      (fdma_rstn),
        .cfg_tx_burst_limit(ctrl_if.cfg_tx_burst_limit),
        .fdma_raddr     (rd_if.raddr),
        .fdma_rareq     (rd_if.rareq),
        .fdma_rbusy     (rd_if.rbusy),
        .fdma_rdata     (rd_if.rdata),
        .fdma_rvalid    (rd_if.rvalid),
        .fdma_rready    (rd_if.rready),
        .fdma_waddr     (wr_if.waddr),
        .fdma_wareq     (wr_if.wareq),
        .fdma_wbusy     (wr_if.wbusy),
        .fdma_wdata     (wr_if.wdata),
        .fdma_wvalid    (wr_if.wvalid),
        .fdma_wsize     (wr_if.wsize),
        .fdma_wready    (wr_if.wready),
        .hw_test_dbg_bus(257'd0),
        .hw_test_status_bus(188'd0),
        .channel_up     (channel_up),
        .lane_up        (lane_up),
        .user_clk       (user_clk),
        .user_rstn      (user_rstn)
    );

    assign ll_if.tx_d       = dut.ll_tx_d;
    assign ll_if.tx_sof     = dut.ll_tx_sof;
    assign ll_if.tx_eof     = dut.ll_tx_eof;
    assign ll_if.tx_rem     = dut.ll_tx_rem;
    assign ll_if.tx_src_rdy = dut.ll_tx_src_rdy;
    assign ll_if.tx_dst_rdy = dut.ll_tx_dst_rdy;
    assign ll_if.rx_d       = dut.ll_rx_d;
    assign ll_if.rx_sof     = dut.ll_rx_sof;
    assign ll_if.rx_eof     = dut.ll_rx_eof;
    assign ll_if.rx_rem     = dut.ll_rx_rem;
    assign ll_if.rx_src_rdy = dut.ll_rx_src_rdy;
    assign ll_if.rx_dst_rdy = dut.ll_rx_dst_rdy;

    // 层级观测信号送入公共 scoreboard 和诊断打印。
    assign obs_if.is_full_loop = 1'b1;
    assign obs_if.channel_up   = channel_up;
    assign obs_if.lane_up      = lane_up;
    assign obs_if.user_rstn    = user_rstn;

    assign obs_if.tx_rd_state       = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_state;
    assign obs_if.tx_state          = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.tx_state;
    assign obs_if.tx_rd_word_cnt    = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_word_cnt;
    assign obs_if.tx_word_cnt       = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.tx_word_cnt;
    assign obs_if.tx_fifo_wr_en     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.wr_en;
    assign obs_if.tx_fifo_rd_en     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_en;
    assign obs_if.tx_fifo_wdata     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_wdata;
    assign obs_if.tx_fifo_rdata     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_rdata;
    assign obs_if.tx_fifo_wr_cnt    = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_wr_cnt;
    assign obs_if.tx_fifo_rd_cnt    = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_rd_cnt;
    assign obs_if.tx_fifo_overflow  = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_overflow;
    assign obs_if.tx_fifo_underflow = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_underflow;
    assign obs_if.tx_fifo_almost_full  = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_almost_full;
    assign obs_if.tx_fifo_almost_empty = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_almost_empty;
    assign obs_if.tx_fifo_full         = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_full;
    assign obs_if.tx_fifo_empty        = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_empty;

    assign obs_if.rx_wr_state        = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_state;
    assign obs_if.rx_wr_word_cnt     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_word_cnt;
    assign obs_if.rx_wdata_hold_valid= dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wdata_hold_valid;
    assign obs_if.rx_fifo_wr_en      = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_en;
    assign obs_if.rx_fifo_rd_en      = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.rd_en;
    assign obs_if.rx_fifo_wdata      = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_wdata;
    assign obs_if.rx_fifo_rdata      = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_rdata;
    assign obs_if.rx_fifo_wr_cnt     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_wr_cnt;
    assign obs_if.rx_fifo_rd_cnt     = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_rd_cnt;
    assign obs_if.rx_fifo_overflow   = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_overflow;
    assign obs_if.rx_fifo_underflow  = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_underflow;
    assign obs_if.rx_fifo_almost_full= dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_almost_full;
    assign obs_if.rx_fifo_full       = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_full;
    assign obs_if.rx_fifo_empty      = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_empty;
endmodule
