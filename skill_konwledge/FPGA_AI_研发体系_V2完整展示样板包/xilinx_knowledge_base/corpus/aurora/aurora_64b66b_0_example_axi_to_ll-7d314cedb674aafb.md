# aurora_64b66b_0_example_axi_to_ll

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\design\rtl\aurora_64b66b_0_example_axi_to_ll.v`
- SHA-256: `7d314cedb674aafb370805dced38724110e4402034f0215d0854d0073103564a`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
`default_nettype none

// AXI4-Stream-to-LocalLink compatibility shim used by the archived design.
// RX is normally connected with LL_IP_DST_RDY_N tied low because Aurora has
// no receive-side TREADY signal.
module aurora_64b66b_0_EXAMPLE_AXI_TO_LL #(
    parameter DATA_WIDTH = 64,
    parameter STRB_WIDTH = 8,
    parameter BC         = 8,
    parameter ISUFC      = 0,
    parameter USE_4_NFC  = 0,
    parameter REM_WIDTH  = 3
) (
    input  wire                  AXI4_S_IP_TX_TVALID,
    output wire                  AXI4_S_IP_TX_TREADY,
    input  wire [0:DATA_WIDTH-1] AXI4_S_IP_TX_TDATA,
    input  wire [0:STRB_WIDTH-1] AXI4_S_IP_TX_TKEEP,
    input  wire                  AXI4_S_IP_TX_TLAST,
    output wire [0:DATA_WIDTH-1] LL_OP_DATA,
    output wire [0:REM_WIDTH-1]  LL_OP_REM,
    output wire                  LL_OP_SRC_RDY_N,
    output wire                  LL_OP_SOF_N,
    output wire                  LL_OP_EOF_N,
    input  wire                  LL_IP_DST_RDY_N,
    input  wire                  USER_CLK,
    input  wire                  RESET,
    input  wire                  CHANNEL_UP
);

    integer index;
    integer valid_count;
    reg [REM_WIDTH-1:0] valid_bytes_minus_one;
    reg in_frame = 1'b0;

    always @* begin
        valid_count = 0;
        for (index = 0; index < STRB_WIDTH; index = index + 1)
            if (AXI4_S_IP_TX_TKEEP[index])
                valid_count = valid_count + 1;
        if (valid_count == 0)
            valid_bytes_minus_one = {REM_WIDTH{1'b0}};
        else
            valid_bytes_minus_one = valid_count - 1;
    end

    always @(posedge USER_CLK) begin
        if (RESET || !CHANNEL_UP)
            in_frame <= 1'b0;
        else if (AXI4_S_IP_TX_TVALID && AXI4_S_IP_TX_TREADY)
            in_frame <= !AXI4_S_IP_TX_TLAST;
    end

    assign AXI4_S_IP_TX_TREADY = !LL_IP_DST_RDY_N;
    assign LL_OP_DATA = AXI4_S_IP_TX_TDATA;
    assign LL_OP_REM = valid_bytes_minus_one;
    assign LL_OP_SRC_RDY_N = !AXI4_S_IP_TX_TVALID;
    assign LL_OP_EOF_N = !AXI4_S_IP_TX_TLAST;
    assign LL_OP_SOF_N = !(AXI4_S_IP_TX_TVALID && !in_frame);

endmodule

`default_nettype wire
```
