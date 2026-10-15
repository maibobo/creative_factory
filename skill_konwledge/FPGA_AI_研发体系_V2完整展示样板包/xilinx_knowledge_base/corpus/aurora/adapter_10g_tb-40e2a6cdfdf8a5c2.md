# adapter_10g_tb

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\verification\directed\adapter_10g_tb.sv`
- SHA-256: `40e2a6cdfdf8a5c2435de931398f113c9de8bae07a552a386c3ef716124b4fe3`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps
`default_nettype none

module adapter_10g_tb;
  reg clk = 0;
  always #3.103 clk = ~clk;

  reg reset = 1;
  reg channel_up = 0;

  reg  [0:63] ll_tx_data;
  reg  [0:2]  ll_tx_rem;
  reg         ll_tx_sof_n;
  reg         ll_tx_eof_n;
  reg         ll_tx_src_rdy_n;
  wire        ll_tx_dst_rdy_n;
  wire        tx_tvalid;
  wire [0:63] tx_tdata;
  wire [0:7]  tx_tkeep;
  wire        tx_tlast;
  reg         tx_tready;

  reg         rx_tvalid;
  wire        rx_tready;
  reg  [0:63] rx_tdata;
  reg  [0:7]  rx_tkeep;
  reg         rx_tlast;
  wire [0:63] ll_rx_data;
  wire [0:2]  ll_rx_rem;
  wire        ll_rx_src_rdy_n;
  wire        ll_rx_sof_n;
  wire        ll_rx_eof_n;

  integer rem_value;
  integer byte_index;
  integer ones;

  task check_rx_rem(input [2:0] expected_rem, input [0:7] expected_keep);
    begin
      rx_tkeep = expected_keep;
      rx_tvalid = 1;
      rx_tlast = 1;
      #1;
      if (rx_tready !== 1 || ll_rx_src_rdy_n !== 0 ||
          ll_rx_eof_n !== 0 || ll_rx_rem !== expected_rem)
        $fatal(1, "RX REM/handshake mapping failed: keep=%b rem=%b expected=%b",
               rx_tkeep, ll_rx_rem, expected_rem);
      @(posedge clk);
      rx_tvalid = 0;
      @(posedge clk);
    end
  endtask

  aurora_64b66b_0_EXAMPLE_LL_TO_AXI tx_adapter (
    .LL_IP_DATA(ll_tx_data), .LL_IP_SOF_N(ll_tx_sof_n),
    .LL_IP_EOF_N(ll_tx_eof_n), .LL_IP_REM(ll_tx_rem),
    .LL_IP_SRC_RDY_N(ll_tx_src_rdy_n), .LL_OP_DST_RDY_N(ll_tx_dst_rdy_n),
    .AXI4_S_OP_TVALID(tx_tvalid), .AXI4_S_OP_TDATA(tx_tdata),
    .AXI4_S_OP_TKEEP(tx_tkeep), .AXI4_S_OP_TLAST(tx_tlast),
    .AXI4_S_IP_TREADY(tx_tready), .USER_CLK(clk), .RESET(reset)
  );

  aurora_64b66b_0_EXAMPLE_AXI_TO_LL rx_adapter (
    .AXI4_S_IP_TX_TVALID(rx_tvalid), .AXI4_S_IP_TX_TREADY(rx_tready),
    .AXI4_S_IP_TX_TDATA(rx_tdata), .AXI4_S_IP_TX_TKEEP(rx_tkeep),
    .AXI4_S_IP_TX_TLAST(rx_tlast), .LL_OP_DATA(ll_rx_data),
    .LL_OP_REM(ll_rx_rem), .LL_OP_SRC_RDY_N(ll_rx_src_rdy_n),
    .LL_OP_SOF_N(ll_rx_sof_n), .LL_OP_EOF_N(ll_rx_eof_n),
    .LL_IP_DST_RDY_N(1'b0), .USER_CLK(clk), .RESET(reset),
    .CHANNEL_UP(channel_up)
  );

  initial begin
    ll_tx_data = 64'h0123_4567_89ab_cdef;
    ll_tx_rem = 0;
    ll_tx_sof_n = 0;
    ll_tx_eof_n = 0;
    ll_tx_src_rdy_n = 0;
    tx_tready = 0;
    rx_tvalid = 0;
    rx_tdata = 64'hfedc_ba98_7654_3210;
    rx_tkeep = 0;
    rx_tlast = 0;

    repeat (3) @(posedge clk);
    reset = 0;
    channel_up = 1;
    @(posedge clk);

    if (ll_tx_dst_rdy_n !== 1 || tx_tvalid !== 1)
      $fatal(1, "TX backpressure/valid mapping failed");
    tx_tready = 1;
    #1;
    if (ll_tx_dst_rdy_n !== 0 || tx_tdata !== ll_tx_data || tx_tlast !== 1)
      $fatal(1, "TX handshake/data/EOF mapping failed");

    for (rem_value = 0; rem_value < 8; rem_value = rem_value + 1) begin
      ll_tx_rem = rem_value[2:0];
      #1;
      ones = 0;
      for (byte_index = 0; byte_index < 8; byte_index = byte_index + 1)
        ones = ones + tx_tkeep[byte_index];
      if (ones != rem_value + 1)
        $fatal(1, "TX REM %0d produced %0d valid bytes", rem_value, ones);
    end

    check_rx_rem(3'd0, 8'b1000_0000);
    check_rx_rem(3'd1, 8'b1100_0000);
    check_rx_rem(3'd2, 8'b1110_0000);
    check_rx_rem(3'd3, 8'b1111_0000);
    check_rx_rem(3'd4, 8'b1111_1000);
    check_rx_rem(3'd5, 8'b1111_1100);
    check_rx_rem(3'd6, 8'b1111_1110);
    check_rx_rem(3'd7, 8'b1111_1111);

    @(negedge clk);
    rx_tkeep = 8'hff;
    rx_tvalid = 1;
    rx_tlast = 0;
    #1;
    $display("SOF check: sof_n=%b valid=%b last=%b in_frame=%b channel=%b reset=%b",
             ll_rx_sof_n, rx_tvalid, rx_tlast, rx_adapter.in_frame, channel_up, reset);
    if (ll_rx_sof_n !== 0) $fatal(1, "first beat SOF missing");
    @(posedge clk);
    #1;
    if (ll_rx_sof_n !== 1) $fatal(1, "middle beat incorrectly marked SOF");
    rx_tlast = 1;
    @(posedge clk);
    rx_tvalid = 0;

    $display("ADAPTER_10G_TEST_PASS: all REM values, bit mapping and ready/valid checked");
    $finish;
  end
endmodule

`default_nettype wire
```
