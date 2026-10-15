# aurora_64b66b_0_example_ll_to_axi

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\design\rtl\aurora_64b66b_0_example_ll_to_axi.v`
- SHA-256: `ebf435ccce5d8d1a461294bbdd65fb97556831770045cda9e7ae7354c1fd6ea3`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
`default_nettype none

// LocalLink-to-AXI4-Stream compatibility shim used by the archived design.
module aurora_64b66b_0_EXAMPLE_LL_TO_AXI #(
    parameter DATA_WIDTH = 64,
    parameter STRB_WIDTH = 8,
    parameter USE_4_NFC  = 0,
    parameter BC         = 8,
    parameter REM_WIDTH  = 3
) (
    input  wire [0:DATA_WIDTH-1] LL_IP_DATA,
    input  wire                  LL_IP_SOF_N,
    input  wire                  LL_IP_EOF_N,
    input  wire [0:REM_WIDTH-1]  LL_IP_REM,
    input  wire                  LL_IP_SRC_RDY_N,
    output wire                  LL_OP_DST_RDY_N,
    output wire                  AXI4_S_OP_TVALID,
    output wire [0:DATA_WIDTH-1] AXI4_S_OP_TDATA,
    output wire [0:STRB_WIDTH-1] AXI4_S_OP_TKEEP,
    output wire                  AXI4_S_OP_TLAST,
    input  wire                  AXI4_S_IP_TREADY,
    input  wire                  USER_CLK,
    input  wire                  RESET
);

    assign AXI4_S_OP_TDATA  = LL_IP_DATA;
    assign AXI4_S_OP_TVALID = !LL_IP_SRC_RDY_N;
    assign AXI4_S_OP_TLAST  = !LL_IP_EOF_N;
    assign AXI4_S_OP_TKEEP  = (LL_IP_REM == {REM_WIDTH{1'b1}})
                            ? {STRB_WIDTH{1'b1}}
                            : ~({STRB_WIDTH{1'b1}} >> (LL_IP_REM + 1'b1));
    assign LL_OP_DST_RDY_N  = !AXI4_S_IP_TREADY;

endmodule

`default_nettype wire
```
