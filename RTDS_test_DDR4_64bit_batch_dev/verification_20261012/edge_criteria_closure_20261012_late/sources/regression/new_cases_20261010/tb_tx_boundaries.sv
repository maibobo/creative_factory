`timescale 1ns/1ps
// TC-F10: actual AXI-Lite register command, actual DDR/FDMA and LL data checker.
module tb_tx_boundaries;
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 rtds_real_harness H();
 task automatic reject(input int addr,input int len);
   H.rd('h10,H.expected_tx_base);repeat(100) @(negedge H.clk);
   H.read_beats=0;H.read_requests=0;H.tx_beats=0;H.done_events=0;
   H.command(addr,len);H.wait_end();
   if(!H.length_error || H.read_requests || H.read_beats || H.tx_beats || H.done_events!=1)
     $fatal(1,"BOUNDARY/REJECT addr=%h len=%0d req=%0d",addr,len,H.read_requests);
   H.check_reg('h20,0);$display("REJECT_CHECK addr=%h len=%0d no_DDR_access=1",addr,len);
 endtask
 initial begin
   H.reset();
   reject('h8000,0);reject('h8000,15);reject('h8000,17);reject('h8001,16);
   reject('h7ff0,16);reject('hfff0,32);reject('h8000,32784);
   H.valid_tx('h8000,16,'h110000,1);
   H.valid_tx('h8000,32768,'h220000,2);
   H.valid_tx('hfff0,16,'h330000,3);
   for(int n=0;n<8;n++) begin   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
     int len,addr;len=16*phase2_pick(1,128);addr='h8000+16*phase2_pick(0,2048-len/16);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
     H.valid_tx(addr,len,phase2_pick(1,1048575),8'(phase2_pick(1,10)));   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   end   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   $display("TEST PASS tb_tx_boundaries invalid=7 valid=3 max_bytes=32768 max_frames=2048 max_beats=4096");$finish;
 end
 initial begin #4000000;$fatal(1,"BOUNDARY/WATCHDOG");end
endmodule
