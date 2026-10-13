// Static-check boundary only. No functional behavior is implemented.
(* syn_black_box = 1 *)
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

    output wire        user_clk_out,
    output wire        system_reset_out,
    output wire        channel_up,
    output wire        rx_crc_error
);
endmodule
