`timescale 1ns/1ps   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
// 修改记录 2026-10-11：TC-F16真实MIG/Clock Converter与颗粒模型子场景。
module tb_real_mig_recovery;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 `include "rtds_random.svh"   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 logic clk=0;always #2 clk=~clk;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 rtds_backend_real_env B(clk);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 logic[63:0] data[0:3];   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 task automatic await_ready;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(int n=0;n<500000;n++) begin @(negedge clk);if(B.ready)return;end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   $fatal(1,"REAL_MIG/CALIB_TIMEOUT calib=%b ready=%b",B.calib,B.ready);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 endtask   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 task automatic write4(input int address,input int id);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   @(negedge clk);B.awaddr=address;B.awid=id;B.awlen=3;B.awvalid=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   do @(posedge clk);while(!B.awready);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   @(negedge clk);B.awvalid=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(int k=0;k<4;k++) begin   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     repeat(phase2_pick(0,7)) @(negedge clk);B.wdata=data[k];B.wlast=k==3;B.wvalid=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     do @(posedge clk);while(!B.wready);@(negedge clk);B.wvalid=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   repeat(phase2_pick(4,20)) @(negedge clk);B.bready=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   do @(posedge clk);while(!B.bvalid);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   if(B.bid!=id || B.bresp!=0) $fatal(1,"REAL_MIG/WRITE_RESP");   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   @(negedge clk);B.bready=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 endtask   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 task automatic read4(input int address,input int id);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   @(negedge clk);B.araddr=address;B.arid=id;B.arlen=3;B.arvalid=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   do @(posedge clk);while(!B.arready);@(negedge clk);B.arvalid=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(int k=0;k<4;k++) begin   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     repeat(phase2_pick(0,7)) @(negedge clk);B.rready=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     do @(posedge clk);while(!B.rvalid);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     if(B.rid!=id || B.rresp!=0 || B.rlast!=(k==3) || B.rdata!==data[k]) $fatal(1,"REAL_MIG/READ_DATA beat=%0d got=%h expected=%h",k,B.rdata,data[k]);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     @(negedge clk);B.rready=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 endtask   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 initial begin   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   B.ddr_rst_n=0;repeat(100) @(negedge clk);B.rst_n=1;B.ddr_rst_n=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   await_ready();$display("REAL_MIG_CALIB time=%0t",$time);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(int k=0;k<4;k++) data[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   write4('h8000,3);read4('h8000,7);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   @(negedge clk);B.araddr='h8000;B.arid=11;B.arlen=3;B.arvalid=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   do @(posedge clk);while(!B.arready);@(negedge clk);B.arvalid=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   wait(B.rvalid);repeat(phase2_pick(4,30)) @(negedge clk);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   B.ddr_rst_n=0;wait(!B.U_DDR.storage_ready);repeat(100) @(negedge clk);B.ddr_rst_n=1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(int k=0;k<4;k++) begin   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     @(negedge clk);B.rready=1;do @(posedge clk);while(!B.rvalid);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     if(B.rid!=11 || B.rlast!=(k==3) || B.rresp!=(k==0?0:2)) $fatal(1,"REAL_MIG/ABORT_RESPONSE beat=%0d id=%d resp=%d",k,B.rid,B.rresp);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     @(negedge clk);B.rready=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   await_ready();   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(int k=0;k<4;k++) data[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   write4('h9000,17);read4('h9000,23);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   $display("TEST PASS tb_real_mig_recovery old_read=4 fresh_write_read=4 DDR4_REAL=1");$finish;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 initial begin #5000000;$fatal(1,"REAL_MIG/WATCHDOG");end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
endmodule   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
