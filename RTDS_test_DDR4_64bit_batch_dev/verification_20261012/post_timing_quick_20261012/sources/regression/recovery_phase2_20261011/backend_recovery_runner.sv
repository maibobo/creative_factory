`timescale 1ns/1ps   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
// 修改记录 2026-10-11：TC-F13/F14独立记分板，边界全遍历并加随机停顿和数据。
module backend_recovery_runner #(parameter integer KIND=0);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 `include "rtds_random.svh"   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 logic clk=0; always #2 clk=~clk;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 rtds_backend_test_if B(clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 integer checks=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 logic[63:0] expected[0:255];   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic init_bus;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.rst_n=0;B.ddr_rst_n=1;B.awvalid=0;B.wvalid=0;B.arvalid=0;B.rready=0;B.bready=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   repeat(20) @(negedge clk);B.rst_n=1;repeat(20) @(negedge clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic ar(input int n,input int id,input int addr);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.arlen=8'(n-1);B.arid=5'(id);B.araddr=addr;B.arvalid=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   do @(posedge clk);while(!B.arready);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.arvalid=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic aw(input int n,input int id,input int addr);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.awlen=8'(n-1);B.awid=5'(id);B.awaddr=addr;B.awvalid=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   do @(posedge clk);while(!B.awready);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.awvalid=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic write_beat(input int k,input int n);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   repeat(phase2_pick(0,5)) @(negedge clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   B.wdata=expected[k];B.wlast=(k==n-1);B.wvalid=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   do @(posedge clk);while(!B.wready);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.wvalid=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic read_beat(input int k,input int n,input int id,input int fault_start);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.rready=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   repeat(phase2_pick(0,9)) @(negedge clk);B.rready=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   do @(posedge clk);while(!B.rvalid);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(B.rid!=5'(id) || B.rlast!=(k==n-1)) $fatal(1,"BACKEND/R_ID_LAST k=%0d n=%0d id=%0d got=%0d last=%b",k,n,id,B.rid,B.rlast);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(k<fault_start) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(B.rresp!=0 || B.rdata!==expected[k]) $fatal(1,"BACKEND/R_NORMAL k=%0d got=%h expected=%h resp=%0d",k,B.rdata,expected[k],B.rresp);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end else if(B.rresp!=2 || B.rdata!=0) $fatal(1,"BACKEND/R_ABORT k=%0d resp=%0d data=%h",k,B.rresp,B.rdata);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.rready=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic read_case(input int n,input int stage,input int id);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   int consumed,boundary,addr;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   init_bus();addr='h8000;consumed=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int k=0;k<n;k++) begin expected[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};B.U_DDR.u_sim_ram.mem[addr/8+k]=expected[k];end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(stage==0) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     B.ddr_rst_n=0;repeat(8) @(negedge clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     B.arvalid=1;B.arlen=n-1;B.arid=id;B.araddr=addr;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(16) begin @(posedge clk);if(B.arready || B.rvalid) $fatal(1,"BACKEND/READ_UNREADY_ACCEPT");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.arvalid=0;B.ddr_rst_n=1;repeat(20) @(negedge clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     ar(n,id,addr);for(int k=0;k<n;k++) read_beat(k,n,id,n);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end else begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     ar(n,id,addr);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(stage==2 || stage==4) wait(B.rvalid);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(stage==3 && n>1) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       consumed=n/2;for(int k=0;k<consumed;k++) read_beat(k,n,id,n);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(stage==4 && n>1) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       consumed=n-1;for(int k=0;k<consumed;k++) read_beat(k,n,id,n);wait(B.rvalid);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.ddr_rst_n=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     wait(!B.U_DDR.storage_ready);#0.1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     boundary=consumed+(B.rvalid?1:0);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat((checks%3==0)?8:((checks%3==1)?64:400)) @(negedge clk);   // 2026-10-11：显式覆盖8、64、400拍保持，其他数据与间隔仍按种子变化
     B.ddr_rst_n=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     B.arvalid=1;B.arid=5'(31-id);B.araddr='h9000;B.arlen=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(16) begin @(posedge clk);if(B.arready) $fatal(1,"BACKEND/NEW_AR_BEFORE_OLD_RLAST");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.arvalid=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     for(int k=consumed;k<n;k++) read_beat(k,n,id,boundary);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   repeat(10) @(negedge clk);if(!B.ready || B.rvalid || B.U_DDR.recovery_read_pending) $fatal(1,"BACKEND/READ_NOT_RECOVERED");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   expected[0]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};B.U_DDR.u_sim_ram.mem['h9000/8]=expected[0];   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   ar(1,31-id,'h9000);read_beat(0,1,31-id,1);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   repeat(8) @(posedge clk);if(B.rvalid) $fatal(1,"BACKEND/EXTRA_R");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   checks++;$display("READ_RECOVERY_CHECK n=%0d stage=%0d id=%0d reset_free_fresh=1",n,stage,id);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic b_accept(input int id,input int resp);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   wait(B.bvalid);repeat((checks%3==0)?8:((checks%3==1)?64:400)) @(negedge clk);B.bready=1;   // 2026-10-11：写响应显式覆盖8、64、400拍反压保持
   do @(posedge clk);while(!B.bvalid);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(B.bid!=5'(id) || B.bresp!=2'(resp)) $fatal(1,"BACKEND/B_RESULT got_id=%0d expected_id=%0d got_resp=%0d expected_resp=%0d",B.bid,id,B.bresp,resp);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   @(negedge clk);B.bready=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic write_case(input int n,input int stage,input int id);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   int consumed,resp,physical_after;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   init_bus();consumed=0;resp=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int k=0;k<n;k++) expected[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(stage==0) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     B.ddr_rst_n=0;repeat(8) @(negedge clk);B.awvalid=1;B.awid=id;B.awaddr='h8000;B.awlen=n-1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(16) begin @(posedge clk);if(B.awready || B.bvalid) $fatal(1,"BACKEND/WRITE_UNREADY_ACCEPT");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.awvalid=0;B.ddr_rst_n=1;repeat(20) @(negedge clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     // W可以先于AW展示；在地址接受前必须保持反压。
     B.wdata=expected[0];B.wlast=(n==1);B.wvalid=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(phase2_pick(2,8)) begin @(posedge clk);if(B.wready) $fatal(1,"BACKEND/W_BEFORE_AW_ACCEPT");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     aw(n,id,'h8000);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     do @(posedge clk);while(!B.wready);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.wvalid=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     for(int k=1;k<n;k++) write_beat(k,n);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end else begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     aw(n,id,'h8000);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(stage==2 && n>1) consumed=n/2;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(stage==3 || stage==4) consumed=n;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     for(int k=0;k<consumed;k++) write_beat(k,n);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(stage==4) wait(B.bvalid);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.ddr_rst_n=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     wait(!B.U_DDR.storage_ready);#0.1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     resp=B.bvalid?int'(B.bresp):2;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(phase2_pick(8,80)) @(negedge clk);B.ddr_rst_n=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     B.awvalid=1;B.awid=31-id;B.awaddr='h9000;B.awlen=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(16) begin @(posedge clk);if(B.awready) $fatal(1,"BACKEND/NEW_AW_BEFORE_OLD_B");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge clk);B.awvalid=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     for(int k=consumed;k<n;k++) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       write_beat(k,n);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       if(B.U_DDR.mem_wvalid) $fatal(1,"BACKEND/ABORTED_W_REPLAY");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   b_accept(id,resp);repeat(10) @(negedge clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(!B.ready || B.bvalid || B.U_DDR.recovery_write_pending) $fatal(1,"BACKEND/WRITE_NOT_RECOVERED");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   expected[0]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   aw(1,31-id,'h9000);write_beat(0,1);b_accept(31-id,0);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(B.U_DDR.u_sim_ram.mem['h9000/8]!==expected[0]) $fatal(1,"BACKEND/FRESH_WRITE_DATA");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   repeat(8) @(posedge clk);if(B.bvalid) $fatal(1,"BACKEND/EXTRA_B");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   checks++;$display("WRITE_RECOVERY_CHECK n=%0d stage=%0d id=%0d response=%0d reset_free_fresh=1",n,stage,id,resp);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic parallel_case;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   init_bus();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int k=0;k<8;k++) begin expected[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};B.U_DDR.u_sim_ram.mem['h8000/8+k]=expected[k];end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   fork   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     begin ar(8,2,'h8000);for(int k=0;k<8;k++) read_beat(k,8,2,8);end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     begin aw(8,17,'ha000);for(int k=0;k<8;k++) write_beat(k,8);b_accept(17,0);end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   join   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int k=0;k<8;k++) if(B.U_DDR.u_sim_ram.mem['ha000/8+k]!==expected[k]) $fatal(1,"BACKEND/PARALLEL_WRITE");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   checks++;$display("BACKEND_PARALLEL_CHECK read_id=2 write_id=17 beats=8");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 initial begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int size=0;size<3;size++) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     int n;n=(size==0)?1:((size==1)?2:256);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     for(int stage=0;stage<5;stage++) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       int id;id=(stage==0)?0:((stage==1)?1:((stage==4)?31:phase2_pick(1,30)));   // 2026-10-11：确保覆盖ID=0、1、31，同时保留随机其他ID
       if(KIND==0) read_case(n,stage,id);else write_case(n,stage,id);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   parallel_case();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   if(KIND==0) $display("TEST PASS tb_backend_read checks=%0d",checks);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   else $display("TEST PASS tb_backend_write checks=%0d",checks);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   $finish;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 initial begin #2000000;$fatal(1,"BACKEND/WATCHDOG KIND=%0d checks=%0d",KIND,checks);end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
endmodule   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
module tb_backend_read; backend_recovery_runner #(.KIND(0)) T(); endmodule   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
module tb_backend_write; backend_recovery_runner #(.KIND(1)) T(); endmodule   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
