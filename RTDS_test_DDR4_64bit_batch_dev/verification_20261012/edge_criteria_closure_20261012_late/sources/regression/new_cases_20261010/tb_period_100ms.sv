`timescale 1ns/1ps
// TC-M09: actual 250MHz and 25,000,000 cycles. No counter force or time scaling.
// Only DUT outputs/event wires are recorded across the 400ms interval.
module tb_period_100ms;
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
  logic[31:0] phase2_words[0:4];   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
  initial for(int k=0;k<5;k++) phase2_words[k]=32'(phase2_pick(1,2147483647));   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
  logic clk=0; always #2 clk=~clk;
  rtds_ring_test_if bus(clk);
  RTDS_RX_BLOCK_WRITER #(.PERIOD_CYCLES(25000000)) U_DUT (
    .clk(clk),.rst_n(bus.rst_n),.enable(bus.enable),
    .frame_data(bus.frame_data),.frame_valid(bus.frame_valid),.frame_ready(bus.frame_ready),
    .cpu_ack(bus.cpu_ack),.irq_clear(bus.irq_clear),.head_addr(bus.head_addr),
    .head_len(bus.head_len),.head_seq(bus.head_seq),.ready_blocks(bus.ready_blocks),
    .dropped_frames(bus.dropped_frames),.irq(bus.irq),.fdma_wstrb(bus.fdma_wstrb),
    .fdma_waddr(bus.fdma_waddr),.fdma_wsize(bus.fdma_wsize),.fdma_wareq(bus.fdma_wareq),
    .fdma_wbusy(bus.fdma_wbusy),.fdma_wdata(bus.fdma_wdata),.fdma_wvalid(bus.fdma_wvalid),
    .fdma_waccept(bus.fdma_waccept),.fdma_wdone(bus.fdma_wdone),.fdma_werror(bus.fdma_werror),.dbg_state(bus.dbg_state));
  wire period_tick=U_DUT.tick;
  int ticks=0, writes=0, publications=0;
  time previous_tick=0;
  logic hold_response=0;
  logic [31:0] stored_words[0:5];
  always @(posedge clk) if(bus.rst_n && period_tick) begin
    if(ticks && $time-previous_tick!=100000000) $fatal(1,"PERIOD/INTERVAL %0t",$time-previous_tick);
    ticks=ticks+1; previous_tick=$time;
    $display("PERIOD_TICK n=%0d time_ns=%0d ready=%0d",ticks,$time,bus.ready_blocks);
  end
  initial begin : responder
    logic[63:0] addr,data; logic[7:0] strb;
    forever begin
      do @(bus.fdma_cb); while(!bus.fdma_cb.rst_n || !bus.fdma_cb.fdma_wareq);
      addr=bus.fdma_cb.fdma_waddr; bus.fdma_cb.fdma_wbusy<=1;
      do @(bus.fdma_cb); while(!bus.fdma_cb.fdma_wvalid);
      data=bus.fdma_cb.fdma_wdata; strb=bus.fdma_cb.fdma_wstrb;
      if(bus.fdma_cb.fdma_wsize!=1) $fatal(1,"PERIOD/SIZE");
      case(writes)
        0: if(addr!='h100000 || strb!=8'hff || data!=={phase2_words[1],phase2_words[0]}) $fatal(1,"PERIOD/EVEN");   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        1: if(addr!='h140000 || strb!=8'hff || data!=={phase2_words[3],phase2_words[2]}) $fatal(1,"PERIOD/PENDING");   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        2: if(addr!='h180000 || strb!=8'h0f || data!=={32'd0,phase2_words[4]}) $fatal(1,"PERIOD/ODD");   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        default: $fatal(1,"PERIOD/EXTRA_WRITE");
      endcase
      bus.fdma_cb.fdma_waccept<=1; @(bus.fdma_cb);bus.fdma_cb.fdma_waccept<=0;
      do @(bus.fdma_cb); while(hold_response);
      repeat(phase2_pick(3,12)) @(bus.fdma_cb);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
      bus.fdma_cb.fdma_wdone<=1;bus.fdma_cb.fdma_wbusy<=0;writes++;
      $display("WRITE_RESPONSE n=%0d time_ns=%0d addr=%h strb=%h",writes,$time,addr,strb);
      @(bus.fdma_cb);bus.fdma_cb.fdma_wdone<=0;
    end
  end
  task automatic send_word(input logic[31:0] v);
    @(bus.host_cb);bus.host_cb.frame_data<={32'habcdef00,v};bus.host_cb.frame_valid<=1;
    do @(bus.host_cb);while(!bus.host_cb.frame_ready);
    bus.host_cb.frame_valid<=0;
  endtask
  task automatic settle;
    repeat(30) @(bus.host_cb);
  endtask
  task automatic check_head(input int seq,input int len);
    if(bus.ready_blocks!=1 || bus.head_seq!=seq || bus.head_addr!='h100000+seq*'h40000 || bus.head_len!=len)
      $fatal(1,"PERIOD/HEAD seq=%0d ready=%0d addr=%h len=%0d",seq,bus.ready_blocks,bus.head_addr,bus.head_len);
    publications++;
    $display("BLOCK_READABLE seq=%0d time_ns=%0d length=%0d",seq,$time,bus.head_len);
    @(bus.host_cb);bus.host_cb.cpu_ack<=1;
    @(bus.host_cb);bus.host_cb.cpu_ack<=0;settle();
    if(bus.ready_blocks!=0) $fatal(1,"PERIOD/ACK");
  endtask
  initial begin
    repeat(8) @(bus.host_cb);bus.host_cb.rst_n<=1;bus.host_cb.enable<=1;
    wait(ticks==1);settle();
    if(bus.ready_blocks!=0 || bus.head_seq!=0 || writes!=0 || U_DUT.publish_seq!=0) $fatal(1,"PERIOD/EMPTY");
    send_word(phase2_words[0]);send_word(phase2_words[1]);settle();   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    if(writes!=1 || bus.ready_blocks!=0) $fatal(1,"PERIOD/EARLY");
    wait(ticks==2);settle();check_head(0,8);
    // Launch a transaction shortly before deadline, hold its response across the tick.
    #99999000;
    hold_response=1;send_word(phase2_words[2]);send_word(phase2_words[3]);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    wait(ticks==3);settle();
    if(bus.ready_blocks!=0 || writes!=1 || bus.dbg_state!=3) $fatal(1,"PERIOD/RESPONSE_EARLY");
    hold_response=0;settle();check_head(1,8);
    send_word(phase2_words[4]);settle();   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    if(writes!=2 || bus.ready_blocks!=0) $fatal(1,"PERIOD/TAIL_EARLY");
    hold_response=1;wait(ticks==4);settle();
    if(bus.ready_blocks!=0 || writes!=2 || bus.dbg_state!=3) $fatal(1,"PERIOD/TAIL_RESPONSE_EARLY");
    hold_response=0;settle();check_head(2,4);
    if(ticks!=4 || writes!=3 || publications!=3 || bus.dropped_frames!=0) $fatal(1,"PERIOD/COUNTS");
    $display("TEST PASS tb_period_100ms ticks=4 intervals=3 writes=3 blocks=3 PERIOD_CYCLES=25000000 clk_ns=4");$finish;
  end
  initial begin #410000000; $fatal(1,"PERIOD/WATCHDOG");end
endmodule
