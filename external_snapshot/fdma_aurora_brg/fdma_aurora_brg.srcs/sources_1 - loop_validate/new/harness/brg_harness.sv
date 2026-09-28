`timescale 1ns / 1ps
// File: brg_harness.sv

// 直连 bridge harness 用于可控的 LocalLink 与 FIFO 边界测试。
// 本模块只管理时钟、复位、DUT 接线、环回选择和观测信号。
module brg_harness #(
    parameter integer FRAME_BYTES = 512 // Forwarded to the bridge TX formatter.
);
    localparam real FDMA_CLK_PERIOD_NS = 4.0; // 250MHz FDMA 时钟。
    localparam real USER_CLK_PERIOD_NS = 6.4; // 156.25MHz LocalLink 时钟。

    logic fdma_clk;   // DUT FDMA-时钟域 时钟.
    logic user_clk;   // DUT LocalLink-时钟域 时钟.
    logic fdma_rstn;  // 低有效 FDMA 复位。
    logic user_rstn;  // 低有效 LocalLink 复位。
    logic channel_up; // Synthetic link-就绪 状态.

    // 独立的 FDMA 与 LocalLink 时钟用于覆盖两个异步 FIFO。
    initial fdma_clk = 1'b0;
    always #(FDMA_CLK_PERIOD_NS/2.0) fdma_clk = ~fdma_clk;

    initial user_clk = 1'b0;
    always #(USER_CLK_PERIOD_NS/2.0) user_clk = ~user_clk;

    // 无需等待 Aurora 核，直接拉起桥接链路。
    initial begin
        fdma_rstn = 1'b0;                    // Hold FDMA 状态机s in 复位.
        user_rstn = 1'b0;                    // 复位 FIFO user-时钟域 logic.
        channel_up = 1'b0;                   // Prevent 请求 before 复位 release.
        repeat (20) @(posedge fdma_clk);     // Provide a stable 复位 interval.
        fdma_rstn = 1'b1;                    // Release FDMA logic.
        user_rstn = 1'b1;                    // Release LocalLink/FIFO logic.
        repeat (4) @(posedge fdma_clk);      // Let synchronizers settle.
        channel_up = 1'b1;                   // Permit bridge traffic.
    end

    fdma_read_if  rd_if(fdma_clk, fdma_rstn);   // Read BFM/DUT 信号 bundle.
    fdma_write_if wr_if(fdma_clk, fdma_rstn);   // Write BFM/DUT 信号 bundle.
    ll_link_if    ll_if(user_clk, user_rstn);   // TX/RX LocalLink bundle.
    brg_ctrl_if   ctrl_if();                    // 直连-test 控制 bundle.
    brg_obs_if    obs_if(fdma_clk, user_clk);   // Read-only 内部 probe.

    initial begin
        ll_if.tx_dst_rdy = 1'b1;              // 直连 loopback accepts TX by default.
        ctrl_if.force_tx_almost_full = 1'b0; // Do not force rready low initially.
        ctrl_if.can_drive_tx_dst_rdy = 1'b1; // Testcases may 控制 直连 LL 就绪.
        ctrl_if.rx_loopback_enable = 1'b1;   // Select TX-to-RX loopback by default.
        ctrl_if.rx_drive_d = 64'd0;          // Idle 直连-注入 载荷.
        ctrl_if.cfg_tx_burst_limit = 16'd0;
        ctrl_if.rx_drive_sof = 1'b0;         // Idle 直连 SOF.
        ctrl_if.rx_drive_eof = 1'b0;         // Idle 直连 EOF.
        ctrl_if.rx_drive_rem = 3'b111;       // Full-width data if 注入 is 使能d.
        ctrl_if.rx_drive_src_rdy = 1'b0;     // 直连 injector starts in有效.
    end

    // DUT: protocol conversion bridge only.
    fdma_aurora_brg_top #(
        .FRAME_BYTES (FRAME_BYTES)
    ) dut (
        .fdma_clk          (fdma_clk),
        .fdma_rstn         (fdma_rstn),
        .user_clk          (user_clk),
        .user_rstn         (user_rstn),
        .channel_up        (channel_up),
        .cfg_tx_burst_limit(ctrl_if.cfg_tx_burst_limit),
        .fdma_raddr        (rd_if.raddr),
        .fdma_rareq        (rd_if.rareq),
        .fdma_rbusy        (rd_if.rbusy),
        .fdma_rdata        (rd_if.rdata),
        .fdma_rvalid       (rd_if.rvalid),
        .fdma_rready       (rd_if.rready),
        .fdma_waddr        (wr_if.waddr),
        .fdma_wareq        (wr_if.wareq),
        .fdma_wbusy        (wr_if.wbusy),
        .fdma_wdata        (wr_if.wdata),
        .fdma_wvalid       (wr_if.wvalid),
        .fdma_wsize        (wr_if.wsize),
        .fdma_wready       (wr_if.wready),
        .aurora_tx_d       (ll_if.tx_d),
        .aurora_tx_sof     (ll_if.tx_sof),
        .aurora_tx_eof     (ll_if.tx_eof),
        .aurora_tx_rem     (ll_if.tx_rem),
        .aurora_tx_src_rdy (ll_if.tx_src_rdy),
        .aurora_tx_dst_rdy (ll_if.tx_dst_rdy),
        .aurora_rx_d       (ll_if.rx_d),
        .aurora_rx_sof     (ll_if.rx_sof),
        .aurora_rx_eof     (ll_if.rx_eof),
        .aurora_rx_rem     (ll_if.rx_rem),
        .aurora_rx_src_rdy (ll_if.rx_src_rdy),
        .aurora_rx_dst_rdy (ll_if.rx_dst_rdy)
    );

    // 选择普通 TX 到 RX 环回，或由 testcase 控制 RX 注入。
    assign ll_if.rx_d = ctrl_if.rx_loopback_enable ? ll_if.tx_d : ctrl_if.rx_drive_d;
    assign ll_if.rx_sof = ctrl_if.rx_loopback_enable ? ll_if.tx_sof : ctrl_if.rx_drive_sof;
    assign ll_if.rx_eof = ctrl_if.rx_loopback_enable ? ll_if.tx_eof : ctrl_if.rx_drive_eof;
    assign ll_if.rx_rem = ctrl_if.rx_loopback_enable ? ll_if.tx_rem : ctrl_if.rx_drive_rem;
    assign ll_if.rx_src_rdy = ctrl_if.rx_loopback_enable ?
                              (ll_if.tx_src_rdy && ll_if.tx_dst_rdy) :
                              ctrl_if.rx_drive_src_rdy;

    // 仅验证使用的故障注入钩子，用于直连 rready 测试。
    always @(ctrl_if.force_tx_almost_full) begin
        if (ctrl_if.force_tx_almost_full)
            force dut.u_fdma_aurora_brg_tx.fifo_almost_full = 1'b1;
        else
            release dut.u_fdma_aurora_brg_tx.fifo_almost_full;
    end

    // testcase 类只读访问层级观测信号。
    assign obs_if.is_full_loop = 1'b0;
    assign obs_if.channel_up   = channel_up;
    assign obs_if.lane_up      = channel_up;
    assign obs_if.user_rstn    = user_rstn;

    assign obs_if.tx_rd_state       = dut.u_fdma_aurora_brg_tx.rd_state;
    assign obs_if.tx_state          = dut.u_fdma_aurora_brg_tx.tx_state;
    assign obs_if.tx_rd_word_cnt    = dut.u_fdma_aurora_brg_tx.rd_word_cnt;
    assign obs_if.tx_word_cnt       = dut.u_fdma_aurora_brg_tx.tx_word_cnt;
    assign obs_if.tx_fifo_wr_en     = dut.u_fdma_aurora_brg_tx.wr_en;
    assign obs_if.tx_fifo_rd_en     = dut.u_fdma_aurora_brg_tx.rd_en;
    assign obs_if.tx_fifo_wdata     = dut.u_fdma_aurora_brg_tx.fifo_wdata;
    assign obs_if.tx_fifo_rdata     = dut.u_fdma_aurora_brg_tx.fifo_rdata;
    assign obs_if.tx_fifo_wr_cnt    = dut.u_fdma_aurora_brg_tx.fifo_wr_cnt;
    assign obs_if.tx_fifo_rd_cnt    = dut.u_fdma_aurora_brg_tx.fifo_rd_cnt;
    assign obs_if.tx_fifo_overflow  = dut.u_fdma_aurora_brg_tx.fifo_overflow;
    assign obs_if.tx_fifo_underflow = dut.u_fdma_aurora_brg_tx.fifo_underflow;
    assign obs_if.tx_fifo_almost_full  = dut.u_fdma_aurora_brg_tx.fifo_almost_full;
    assign obs_if.tx_fifo_almost_empty = dut.u_fdma_aurora_brg_tx.fifo_almost_empty;
    assign obs_if.tx_fifo_full         = dut.u_fdma_aurora_brg_tx.fifo_full;
    assign obs_if.tx_fifo_empty        = dut.u_fdma_aurora_brg_tx.fifo_empty;

    assign obs_if.rx_wr_state        = dut.u_fdma_aurora_brg_rx.wr_state;
    assign obs_if.rx_wr_word_cnt     = dut.u_fdma_aurora_brg_rx.wr_word_cnt;
    assign obs_if.rx_wdata_hold_valid= dut.u_fdma_aurora_brg_rx.wdata_hold_valid;
    assign obs_if.rx_fifo_wr_en      = dut.u_fdma_aurora_brg_rx.wr_en;
    assign obs_if.rx_fifo_rd_en      = dut.u_fdma_aurora_brg_rx.rd_en;
    assign obs_if.rx_fifo_wdata      = dut.u_fdma_aurora_brg_rx.fifo_wdata;
    assign obs_if.rx_fifo_rdata      = dut.u_fdma_aurora_brg_rx.fifo_rdata;
    assign obs_if.rx_fifo_wr_cnt     = dut.u_fdma_aurora_brg_rx.fifo_wr_cnt;
    assign obs_if.rx_fifo_rd_cnt     = dut.u_fdma_aurora_brg_rx.fifo_rd_cnt;
    assign obs_if.rx_fifo_overflow   = dut.u_fdma_aurora_brg_rx.fifo_overflow;
    assign obs_if.rx_fifo_underflow  = dut.u_fdma_aurora_brg_rx.fifo_underflow;
    assign obs_if.rx_fifo_almost_full= dut.u_fdma_aurora_brg_rx.fifo_almost_full;
    assign obs_if.rx_fifo_full       = dut.u_fdma_aurora_brg_rx.fifo_full;
    assign obs_if.rx_fifo_empty      = dut.u_fdma_aurora_brg_rx.fifo_empty;
endmodule
