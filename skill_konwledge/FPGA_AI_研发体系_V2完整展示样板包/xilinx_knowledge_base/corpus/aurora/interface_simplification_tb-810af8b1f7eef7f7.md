# interface_simplification_tb

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\verification\directed\interface_simplification_tb.sv`
- SHA-256: `810af8b1f7eef7f7b26cb438bb437b0d45e2e2d4443f22a606eeea7a04cf3099`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps
`default_nettype none

module interface_simplification_tb;
    reg reset = 1'b1;
    reg gt_reset = 1'b1;
    reg init_clk_in = 1'b0;
    reg gt_refclk_p = 1'b0;
    reg gt_refclk_n = 1'b1;

    wire user_clk_10g;
    wire system_reset_10g;
    wire channel_up_10g;
    wire rx_crc_error_10g;
    wire user_clk_1g;
    wire system_reset_1g;
    wire channel_up_1g;
    wire rx_crc_error_1g;

    always #5 init_clk_in = ~init_clk_in;
    always #4 begin
        gt_refclk_p = ~gt_refclk_p;
        gt_refclk_n = ~gt_refclk_n;
    end

    aurora_64b66b_10p3125g_design dut10 (
        .reset(reset), .gt_reset(gt_reset), .init_clk_in(init_clk_in),
        .gt_refclk_p(gt_refclk_p), .gt_refclk_n(gt_refclk_n),
        .rxp(1'b0), .rxn(1'b1), .txp(), .txn(),
        .tx_data(64'h0), .tx_rem(3'd7), .tx_sof(1'b0), .tx_eof(1'b0),
        .tx_valid(1'b0), .tx_ready(),
        .rx_data(), .rx_rem(), .rx_sof(), .rx_eof(), .rx_valid(),
        .user_clk_out(user_clk_10g),
        .system_reset_out(system_reset_10g),
        .channel_up(channel_up_10g),
        .rx_crc_error(rx_crc_error_10g)
    );

    aurora_8b10b_1p25g_design dut1 (
        .reset(reset), .gt_reset(gt_reset), .init_clk_in(init_clk_in),
        .gt_refclk_p(gt_refclk_p), .gt_refclk_n(gt_refclk_n),
        .rxp(1'b0), .rxn(1'b1), .txp(), .txn(),
        .tx_data(32'h0), .tx_rem(2'd3), .tx_sof(1'b0), .tx_eof(1'b0),
        .tx_valid(1'b0), .tx_ready(),
        .rx_data(), .rx_rem(), .rx_sof(), .rx_eof(), .rx_valid(),
        .user_clk_out(user_clk_1g),
        .system_reset_out(system_reset_1g),
        .channel_up(channel_up_1g),
        .rx_crc_error(rx_crc_error_1g)
    );

    initial begin
        #2;
        if (system_reset_10g !== 1'b1 || system_reset_1g !== 1'b1)
            $fatal(1, "system_reset_out did not follow the core reset output");

        reset = 1'b0;
        gt_reset = 1'b0;
        #2;
        if (channel_up_10g !== 1'b1 || channel_up_1g !== 1'b1)
            $fatal(1, "channel_up was not exposed by both wrappers");
        if (dut1.aurora_i.loopback !== 3'b000)
            $fatal(1, "1G loopback is not tied to normal mode");
        if (dut1.aurora_i.power_down !== 1'b0)
            $fatal(1, "1G power_down is not tied low");

        force dut10.crc_valid_i = 1'b1;
        force dut10.crc_pass_fail_n_i = 1'b0;
        force dut1.crc_valid_i = 1'b1;
        force dut1.crc_pass_fail_n_i = 1'b0;
        #1;
        if (rx_crc_error_10g !== 1'b1 || rx_crc_error_1g !== 1'b1)
            $fatal(1, "CRC failure was not converted to rx_crc_error");

        force dut10.crc_pass_fail_n_i = 1'b1;
        force dut1.crc_pass_fail_n_i = 1'b1;
        #1;
        if (rx_crc_error_10g !== 1'b0 || rx_crc_error_1g !== 1'b0)
            $fatal(1, "CRC pass incorrectly asserted rx_crc_error");

        force dut10.crc_valid_i = 1'b0;
        force dut10.crc_pass_fail_n_i = 1'b0;
        force dut1.crc_valid_i = 1'b0;
        force dut1.crc_pass_fail_n_i = 1'b0;
        #1;
        if (rx_crc_error_10g !== 1'b0 || rx_crc_error_1g !== 1'b0)
            $fatal(1, "invalid CRC status incorrectly asserted rx_crc_error");

        release dut10.crc_valid_i;
        release dut10.crc_pass_fail_n_i;
        release dut1.crc_valid_i;
        release dut1.crc_pass_fail_n_i;
        $display("INTERFACE_SIM_PASS: reset/channel/CRC and fixed 1G GT controls");
        $finish;
    end
endmodule

module aurora_64b66b_0_exdes #(
    parameter USE_CORE_TRAFFIC = 1,
    parameter USR_CLK_PCOUNT = 9'd255,
    parameter EXAMPLE_SIMULATION = 0,
    parameter USE_LABTOOLS = 0
) (
    input wire PMA_INIT, INIT_CLK_IN, RESET,
    output wire LANE_UP, CHANNEL_UP,
    input wire GTHQ0_P, GTHQ0_N, RXP, RXN,
    output wire TXP, TXN,
    output wire HARD_ERR, SOFT_ERR, CRC_PASS_FAIL_N, CRC_VALID,
    input wire [63:0] tx_d,
    input wire tx_sof, tx_eof,
    input wire [2:0] tx_rem,
    input wire tx_src_vld,
    output wire tx_dst_rdy,
    output wire [63:0] rx_d,
    output wire rx_sof, rx_eof,
    output wire [2:0] rx_rem,
    output wire rx_src_vld,
    output wire USER_CLK_OUT,
    output wire SYSTEM_RESET_OUT
);
    assign LANE_UP = !RESET;
    assign CHANNEL_UP = !RESET;
    assign TXP = 1'b0;
    assign TXN = 1'b1;
    assign HARD_ERR = 1'b0;
    assign SOFT_ERR = 1'b0;
    assign CRC_PASS_FAIL_N = 1'b1;
    assign CRC_VALID = 1'b0;
    assign tx_dst_rdy = 1'b1;
    assign rx_d = 64'h0;
    assign rx_sof = 1'b0;
    assign rx_eof = 1'b0;
    assign rx_rem = 3'd0;
    assign rx_src_vld = 1'b0;
    assign USER_CLK_OUT = INIT_CLK_IN;
    assign SYSTEM_RESET_OUT = RESET;
endmodule

module aurora_8b10b_1p25g (
    input wire [0:31] s_axi_tx_tdata,
    input wire [0:3] s_axi_tx_tkeep,
    input wire s_axi_tx_tvalid, s_axi_tx_tlast,
    output wire s_axi_tx_tready,
    output wire [0:31] m_axi_rx_tdata,
    output wire [0:3] m_axi_rx_tkeep,
    output wire m_axi_rx_tvalid, m_axi_rx_tlast,
    input wire rxp, rxn,
    output wire txp, txn,
    input wire gt_refclk1_p, gt_refclk1_n,
    output wire hard_err, soft_err, frame_err,
    output wire crc_pass_fail_n, crc_valid,
    output wire channel_up, lane_up, user_clk_out,
    input wire reset,
    output wire sys_reset_out,
    input wire power_down,
    input wire [2:0] loopback,
    input wire gt_reset,
    output wire tx_lock, pll_not_locked_out,
    output wire tx_resetdone_out, rx_resetdone_out, gt_powergood,
    input wire init_clk_in,
    input wire [8:0] gt0_drpaddr,
    input wire gt0_drpen,
    input wire [15:0] gt0_drpdi,
    output wire gt0_drprdy,
    output wire [15:0] gt0_drpdo,
    input wire gt0_drpwe,
    output wire gt_reset_out, sync_clk_out, gt_refclk1_out, link_reset_out
);
    assign s_axi_tx_tready = 1'b1;
    assign m_axi_rx_tdata = 32'h0;
    assign m_axi_rx_tkeep = 4'h0;
    assign m_axi_rx_tvalid = 1'b0;
    assign m_axi_rx_tlast = 1'b0;
    assign txp = 1'b0;
    assign txn = 1'b1;
    assign hard_err = 1'b0;
    assign soft_err = 1'b0;
    assign frame_err = 1'b0;
    assign crc_pass_fail_n = 1'b1;
    assign crc_valid = 1'b0;
    assign channel_up = !reset;
    assign lane_up = !reset;
    assign user_clk_out = init_clk_in;
    assign sys_reset_out = reset;
    assign tx_lock = 1'b1;
    assign pll_not_locked_out = 1'b0;
    assign tx_resetdone_out = 1'b1;
    assign rx_resetdone_out = 1'b1;
    assign gt_powergood = 1'b1;
    assign gt0_drprdy = 1'b0;
    assign gt0_drpdo = 16'h0;
    assign gt_reset_out = gt_reset;
    assign sync_clk_out = init_clk_in;
    assign gt_refclk1_out = gt_refclk1_p;
    assign link_reset_out = 1'b0;
endmodule

`default_nettype wire
```
