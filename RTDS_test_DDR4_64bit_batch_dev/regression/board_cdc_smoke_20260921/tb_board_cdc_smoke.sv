`timescale 1ns/1ps
// One short simulation: actual adapter TX, asynchronous link drop and 1G config.
// This is a simulation-only file, never added to the hardware sources.
module tb_board_cdc_smoke;
  reg clk=0, usr=0, init_src=0;
  always #2 clk=~clk;
  always #3.1 usr=~usr;
  always #5 init_src=~init_src;
  reg rstn=0, link=0, start=0, busy=0, rv=0;
  reg [63:0] rd=0;
  wire req, ready, valid, sof, eof, done;
  wire [63:0] td, addr;
  wire [2:0] rem;
  wire [7:0] cfg;
  wire cfgv, configured;
  wire init_clk, core_reset, gt_reset;
  integer received=0;
  localparam [63:0] WORD0=64'h123456789ABC0100;
  localparam [63:0] WORD1=64'hFEDCBA9876543210;
  pcie_fdma_aurora_brg_adapter #(.RX_PERIOD_CYCLES(1000)) dut (
    .fdma_clk(clk),.fdma_rstn(rstn),.aurora_user_clk(usr),.aurora_user_rstn(rstn),
    .pcie_link_up(link),.ddr_ready(1'b1),.aurora_channel_up(1'b1),.aurora_lane_up(1'b1),
    .aurora_tx_d(td),.aurora_tx_sof(sof),.aurora_tx_eof(eof),.aurora_tx_rem(rem),
    .aurora_tx_src_rdy(valid),.aurora_tx_dst_rdy(1'b1),
    .aurora_rx_d(64'd0),.aurora_rx_sof(1'b0),.aurora_rx_eof(1'b0),
    .aurora_rx_rem(3'd0),.aurora_rx_src_rdy(1'b0),
    .rd_start(start),.cpu_fpga_start_addr(32'h8000),.cpu_fpga_len(32'd16),
    .cpu_wr_done_event(done),.int_state_clear(1'b0),.clear_inter(1'b0),.cpu_rec_state_r(1'b0),
    .fdma_raddr(addr),.fdma_rareq(req),.fdma_rbusy(busy),.fdma_rdata(rd),
    .fdma_rvalid(rv),.fdma_rready(ready),.fdma_wbusy(1'b0),
    .fdma_wdone(1'b0),.fdma_werror(1'b0),.fdma_wready(1'b0),.cfg_byte(cfg),.cfg_byte_valid(cfgv)
  );
  RTDS_1G_PERIODIC_TX #(.PERIOD_CYCLES(63)) cfg_dut (
    .clk_250m(clk),.rst_n(rstn),.cfg_byte(cfg),.cfg_byte_valid(cfgv),
    .user_clk(usr),.user_reset(!rstn),.channel_up(1'b1),.tx_ready(1'b1),.configured(configured)
  );
  RTDS_FPGA_1G_INIT init_dut (
    .clk_100m(init_src),.rst(!rstn),.init_clk(init_clk),.core_reset(core_reset),.gt_reset(gt_reset)
  );
  always @(posedge usr) if(rstn && valid) begin
    if (received==0 && (td!==WORD0 || !sof || eof)) $fatal(1,"bad TX first beat");
    if (received==1 && (td!==WORD1 || sof || !eof)) $fatal(1,"bad TX last beat");
    if (received>1 || rem!==3'd7) $fatal(1,"extra beat or bad REM");
    received=received+1;
  end
  task send_word(input [63:0] word_value);
    begin
      @(negedge clk); rd=word_value;rv=1;
      do @(posedge clk); while(!ready);
    end
  endtask
  initial begin
    repeat(8) @(negedge clk); rstn=1;
    #1 link=1;
    #0.1 if(dut.pcie_link_up_fdma!==0) $fatal(1,"raw link bypasses synchronizer");
    repeat(30) @(negedge clk);
    if(!dut.link_up_fdma) $fatal(1,"link did not synchronize");
    start=1; @(negedge clk); start=0;
    wait(req); if(addr!==64'h8000) $fatal(1,"wrong TX address");
    @(negedge clk); busy=1;
    send_word(WORD0); send_word(WORD1);
    @(negedge clk);rv=0;busy=0;
    wait(received==2); wait(!dut.tx_active); wait(configured);
    repeat(12) @(negedge clk);
    // Interrupt another transaction before responding, away from either clock edge.
    start=1; @(negedge clk);start=0;
    wait(req); @(negedge clk); #0.7 link=0;
    #0.1 if(!dut.pcie_link_up_fdma || !dut.tx_fdma_rstn) $fatal(1,"raw link asynchronously reset bridge");
    repeat(20) @(negedge clk);
    if(dut.tx_active || dut.tx_fdma_rstn || dut.rx_store_enable) $fatal(1,"link loss not handled");
    wait(!core_reset);
    if(gt_reset) $fatal(1,"GT reset outlasted core reset");
    $display("BOARD_CDC_SMOKE_PASS tx_frame=1 link_drop=1 config_ack=1 init_reset=1");
    $finish;
  end
  initial begin #50000; $fatal(1,"smoke timeout"); end
endmodule
