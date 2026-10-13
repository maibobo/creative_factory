`timescale 1ns/1ps
// TC-F12: five blocks through actual FIFO/writer/DDR; actual INFO_EXCH AXI-Lite.
// CPU reads through a modeled AXI C2H master into the real DDR_SIM_RAM backend.
module tb_regs_multiblock;
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 rtds_real_harness H();
 integer phase2_base=phase2_pick(1,1048575);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 logic[31:0] value;logic[63:0] data;
 task automatic wait_count(input int count);
   for(int i=0;i<5000;i++) begin @(negedge H.clk);if(H.ready_blocks==count)return;end
   $fatal(1,"MULTI/COUNT target=%0d got=%0d",count,H.ready_blocks);
 endtask
 initial begin
   H.reset();
   for(int n=0;n<5;n++) begin
     for(int w=0;w<n+1;w++) H.send_rx(phase2_base+n*16+w);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
     wait_count(n+1);
   end
   H.check_reg('h30,5);
   for(int n=0;n<5;n++) begin
     H.check_reg('h18,'h100000+n*'h40000);H.check_reg('h1c,(n+1)*4);H.check_reg('h34,n);
     H.rd('h10,value);repeat(100) @(negedge H.clk);
     H.check_reg('h30,5-n);H.check_reg('h18,'h100000+n*'h40000);H.check_reg('h1c,(n+1)*4);H.check_reg('h34,n);
     for(int w=0;w<n+1;w+=2) begin
       H.cpu_read64('h100000+n*'h40000+w*4,data);
       if(data[31:0]!==32'(phase2_base+n*16+w)) $fatal(1,"MULTI/C2H_LOW");   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
       if(w+1<n+1 && data[63:32]!==32'(phase2_base+n*16+w+1)) $fatal(1,"MULTI/C2H_HIGH");   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
     end
     // No ack is sent until every useful byte has been compared.
     H.wr('h14,1);H.check_reg('h14,0);wait_count(4-n);H.check_reg('h30,4-n);
     if(n<4) begin H.check_reg('h18,'h100000+(n+1)*'h40000);H.check_reg('h34,n+1);end
     $display("MULTIBLOCK_CHECK seq=%0d address=%h bytes=%0d remaining=%0d",n,'h100000+n*'h40000,(n+1)*4,4-n);
   end
   H.check_reg('h18,0);H.check_reg('h1c,0);H.check_reg('h34,0);
   if(H.acks!=5 || H.dropped_words!=0) $fatal(1,"MULTI/ACK_COUNT");
   $display("TEST PASS tb_regs_multiblock blocks=5 ack_pulses=5 bytes_compared=60 read_clear_does_not_pop=1");$finish;
 end
 initial begin #1000000;$fatal(1,"MULTI/WATCHDOG");end
endmodule
