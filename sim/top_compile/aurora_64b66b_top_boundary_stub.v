`timescale 1ns/1ps
// Compile/elaborate boundary model. Production uses the unchanged Aurora core.
module aurora_64b66b_top #(
    parameter SIMULATION = 0,
    parameter integer INIT_CLK_FREQ_HZ = 100_000_000,
    parameter integer PMA_HOLD_TIME_MS = 1_600,
    parameter integer RESET_GAP_TIME_MS = 20
)(
    input wire clk_init,
    input wire sys_rst,
    input wire GTHQ0_P,
    input wire GTHQ0_N,
    input wire RXP,
    input wire RXN,
    output wire TXP,
    output wire TXN,
    output wire sfp_tx_disable,
    output wire sfp_rs0,
    output wire sfp_rs1,
    input wire [63:0] tx_d,
    input wire tx_sof,
    input wire tx_eof,
    input wire [2:0] tx_rem,
    input wire tx_src_vld,
    output wire tx_dst_rdy,
    output wire [63:0] rx_d,
    output wire rx_sof,
    output wire rx_eof,
    output wire [2:0] rx_rem,
    output wire rx_src_vld,
    input wire rx_dst_rdy,
    output wire user_clk,
    output wire channel_up,
    output wire lane_up,
    output wire user_rstn
);
    assign TXP = 1'b0;
    assign TXN = 1'b1;
    assign sfp_tx_disable = 1'b0;
    assign sfp_rs0 = 1'b0;
    assign sfp_rs1 = 1'b0;
    assign tx_dst_rdy = !sys_rst;
    assign rx_d = 64'd0;
    assign rx_sof = 1'b0;
    assign rx_eof = 1'b0;
    assign rx_rem = 3'd0;
    assign rx_src_vld = 1'b0;
    assign user_clk = clk_init;
    assign channel_up = !sys_rst;
    assign lane_up = !sys_rst;
    assign user_rstn = !sys_rst;
endmodule
