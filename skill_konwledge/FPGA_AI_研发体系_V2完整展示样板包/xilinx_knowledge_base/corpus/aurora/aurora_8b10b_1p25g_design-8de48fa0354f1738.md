# aurora_8b10b_1p25g_design

- Category: `aurora`
- Source: `E:\aurora_proc\rtl\aurora_8b10b_1p25g_design.v`
- SHA-256: `8de48fa0354f1738a413ac3ba641799f15fe836e153c83bb330162aca4b44a5d`
- Extractor: `text`
- Tags: `aurora, rtl`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
`default_nettype none

// Aurora 8B/10B, 1.25 Gb/s, single-lane reusable design wrapper.
//
// All external LocalLink-style controls are active high.  tx_rem/rx_rem are
// the number of valid bytes minus one on an EOF beat; they are ignored on all
// other beats.  The receive path is intentionally always ready because the
// Aurora RX AXI4-Stream interface has no TREADY signal.
module aurora_8b10b_1p25g_design (
    input  wire        reset,
    input  wire        gt_reset,
    input  wire        init_clk_in,
    input  wire        gt_refclk_p,
    input  wire        gt_refclk_n,

    input  wire        rxp,
    input  wire        rxn,
    output wire        txp,
    output wire        txn,

    input  wire [31:0] tx_data,
    input  wire [1:0]  tx_rem,
    input  wire        tx_sof,
    input  wire        tx_eof,
    input  wire        tx_valid,
    output wire        tx_ready,

    output wire [31:0] rx_data,
    output wire [1:0]  rx_rem,
    output wire        rx_sof,
    output wire        rx_eof,
    output wire        rx_valid,

    input  wire [2:0]  loopback,
    input  wire        power_down,

    output wire        user_clk_out,
    output wire        system_reset_out,
    output wire        hard_err,
    output wire        soft_err,
    output wire        frame_err,
    output wire        crc_pass_fail_n,
    output wire        crc_valid,
    output wire        lane_up,
    output wire        channel_up,
    output wire        tx_lock,
    output wire        pll_not_locked,
    output wire        tx_resetdone,
    output wire        rx_resetdone
);

    wire [0:31] tx_ll_data;
    wire [0:1]  tx_ll_rem;
    wire        tx_ll_dst_rdy_n;

    wire [0:31] rx_ll_data;
    wire [0:1]  rx_ll_rem;
    wire        rx_ll_sof_n;
    wire        rx_ll_eof_n;
    wire        rx_ll_src_rdy_n;

    wire [0:31] tx_axis_tdata;
    wire [0:3]  tx_axis_tkeep;
    wire        tx_axis_tvalid;
    wire        tx_axis_tlast;
    wire        tx_axis_tready;

    wire [0:31] rx_axis_tdata;
    wire [0:3]  rx_axis_tkeep;
    wire        rx_axis_tvalid;
    wire        rx_axis_tlast;

    wire        user_clk_i;
    wire        system_reset_i;
    wire        channel_up_i;
    reg         channel_up_d = 1'b0;

    wire        drp_ready_unused;
    wire [15:0] drp_data_unused;

    // Explicit descending-to-ascending range conversion.
    assign tx_ll_data = tx_data;
    assign tx_ll_rem[0] = tx_rem[1];
    assign tx_ll_rem[1] = tx_rem[0];
    assign tx_ready = !tx_ll_dst_rdy_n;

    assign rx_data = rx_ll_data;
    assign rx_rem = {rx_ll_rem[0], rx_ll_rem[1]};
    assign rx_sof = !rx_ll_sof_n;
    assign rx_eof = !rx_ll_eof_n;
    assign rx_valid = !rx_ll_src_rdy_n;

    assign user_clk_out = user_clk_i;
    assign system_reset_out = system_reset_i;
    assign channel_up = channel_up_i;

    always @(posedge user_clk_i) begin
        if (system_reset_i)
            channel_up_d <= 1'b0;
        else
            channel_up_d <= channel_up_i;
    end

    aurora_8b10b_1p25g_LL_TO_AXI_EXDES #(
        .DATA_WIDTH (32),
        .USE_4_NFC  (0),
        .STRB_WIDTH (4),
        .REM_WIDTH  (2)
    ) tx_ll_to_axis_i (
        .LL_IP_DATA        (tx_ll_data),
        .LL_IP_SOF_N       (!tx_sof),
        .LL_IP_EOF_N       (!tx_eof),
        .LL_IP_REM         (tx_ll_rem),
        .LL_IP_SRC_RDY_N   (!tx_valid),
        .LL_OP_DST_RDY_N   (tx_ll_dst_rdy_n),
        .AXI4_S_OP_TVALID  (tx_axis_tvalid),
        .AXI4_S_OP_TDATA   (tx_axis_tdata),
        .AXI4_S_OP_TKEEP   (tx_axis_tkeep),
        .AXI4_S_OP_TLAST   (tx_axis_tlast),
        .AXI4_S_IP_TREADY  (tx_axis_tready)
    );

    aurora_8b10b_1p25g_AXI_TO_LL_EXDES #(
        .DATA_WIDTH (32),
        .STRB_WIDTH (4),
        .REM_WIDTH  (2)
    ) rx_axis_to_ll_i (
        .AXI4_S_IP_TX_TVALID (rx_axis_tvalid),
        .AXI4_S_IP_TX_TREADY (),
        .AXI4_S_IP_TX_TDATA  (rx_axis_tdata),
        .AXI4_S_IP_TX_TKEEP  (rx_axis_tkeep),
        .AXI4_S_IP_TX_TLAST  (rx_axis_tlast),
        .LL_OP_DATA           (rx_ll_data),
        .LL_OP_SOF_N          (rx_ll_sof_n),
        .LL_OP_EOF_N          (rx_ll_eof_n),
        .LL_OP_REM            (rx_ll_rem),
        .LL_OP_SRC_RDY_N      (rx_ll_src_rdy_n),
        .LL_IP_DST_RDY_N      (1'b0),
        .USER_CLK             (user_clk_i),
        .RESET                (system_reset_i),
        .CHANNEL_UP           (channel_up_d)
    );

    aurora_8b10b_1p25g aurora_i (
        .s_axi_tx_tdata       (tx_axis_tdata),
        .s_axi_tx_tkeep       (tx_axis_tkeep),
        .s_axi_tx_tvalid      (tx_axis_tvalid),
        .s_axi_tx_tlast       (tx_axis_tlast),
        .s_axi_tx_tready      (tx_axis_tready),
        .m_axi_rx_tdata       (rx_axis_tdata),
        .m_axi_rx_tkeep       (rx_axis_tkeep),
        .m_axi_rx_tvalid      (rx_axis_tvalid),
        .m_axi_rx_tlast       (rx_axis_tlast),
        .rxp                  (rxp),
        .rxn                  (rxn),
        .txp                  (txp),
        .txn                  (txn),
        .gt_refclk1_p         (gt_refclk_p),
        .gt_refclk1_n         (gt_refclk_n),
        .hard_err             (hard_err),
        .soft_err             (soft_err),
        .frame_err            (frame_err),
        .crc_pass_fail_n      (crc_pass_fail_n),
        .crc_valid            (crc_valid),
        .channel_up           (channel_up_i),
        .lane_up              (lane_up),
        .user_clk_out         (user_clk_i),
        .reset                (reset),
        .sys_reset_out        (system_reset_i),
        .power_down           (power_down),
        .loopback             (loopback),
        .gt_reset             (gt_reset),
        .tx_lock              (tx_lock),
        .pll_not_locked_out   (pll_not_locked),
        .tx_resetdone_out     (tx_resetdone),
        .rx_resetdone_out     (rx_resetdone),
        .gt_powergood         (),
        .init_clk_in          (init_clk_in),
        .gt0_drpaddr          (9'h000),
        .gt0_drpen            (1'b0),
        .gt0_drpdi            (16'h0000),
        .gt0_drprdy           (drp_ready_unused),
        .gt0_drpdo            (drp_data_unused),
        .gt0_drpwe            (1'b0),
        .gt_reset_out         (),
        .sync_clk_out         (),
        .gt_refclk1_out       (),
        .link_reset_out       ()
    );

endmodule

`default_nettype wire
```
