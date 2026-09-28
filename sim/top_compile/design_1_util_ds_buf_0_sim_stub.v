`timescale 1ns/1ps
// Compile/elaborate-only model for the generated util_ds_buf wrapper.
// The Vivado 2020.2 mixed-language model incorrectly exposes Versal-only
// primitive ports even though this project targets KU040. Production uses
// the unchanged XCI/DCP and the real IBUFDS_GTE3 primitive.
module design_1_util_ds_buf_0(
    input  wire [0:0] IBUF_DS_P,
    input  wire [0:0] IBUF_DS_N,
    output wire [0:0] IBUF_OUT,
    output wire [0:0] IBUF_DS_ODIV2
);
    assign IBUF_OUT      = IBUF_DS_P;
    assign IBUF_DS_ODIV2 = IBUF_DS_P;
endmodule