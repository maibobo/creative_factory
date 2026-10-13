`timescale 1ns/1ps   // 2026-10-11：补同拍故障/握手、重复故障及读写并行中断
// 修改记录 2026-10-11：在外部DDR复位端口施加故障，不强制DUT内部状态。
// 修改记录 2026-10-12：仅修改测试台；按SIM_RAM同步撤销ready的边界区分已展示成功拍和未展示错误拍。
// EDGE_PHASE=-1/0/1：DDR复位断言分别位于第二R接受前一拍/同一采样拍/后一拍。
// 不删除用例，不允许响应码二选一；每个模式均使用确定的数据、ID、LAST、响应码和接受数量判据。
module tb_backend_edge_recovery;   // 2026-10-11：补充TC-F13/F14边界
 `include "rtds_random.svh"   // 2026-10-11：实际载荷及空拍由种子决定
 logic clk=0;always #2 clk=~clk;   // 2026-10-11：生产业务时钟250MHz
 rtds_backend_test_if B(clk);   // 2026-10-11：使用真实后端和既有稳定性监视器
 // 2026-10-12：模式只改变故障位置；数据和空拍仍由既有SEED生成。
 integer edge_phase=0;
 integer third_resp=0;
 integer ar_accepts=0,aw_accepts=0,r_accepts=0,w_accepts=0,b_accepts=0;
 integer r_okay=0,r_error=0,b_okay=0,b_error=0;
 // 2026-10-12：仅由公开AXI握手统计参考数量，不读取DUT剩余计数生成预期。
 always @(posedge clk) begin
   if(B.rst_n) begin
     if(B.arvalid && B.arready) ar_accepts=ar_accepts+1;
     if(B.awvalid && B.awready) aw_accepts=aw_accepts+1;
     if(B.wvalid && B.wready) w_accepts=w_accepts+1;
     if(B.rvalid && B.rready) begin
       r_accepts=r_accepts+1;
       if(B.rresp==0) r_okay=r_okay+1;
       else if(B.rresp==2) r_error=r_error+1;
       else $fatal(1,"EDGE/UNEXPECTED_RRESP code=%0d",B.rresp);
     end
     if(B.bvalid && B.bready) begin
       b_accepts=b_accepts+1;
       if(B.bresp==0) b_okay=b_okay+1;
       else if(B.bresp==2) b_error=b_error+1;
       else $fatal(1,"EDGE/UNEXPECTED_BRESP code=%0d",B.bresp);
     end
   end
 end
 logic[63:0] words[0:3];   // 2026-10-11：读写参考载荷
 task automatic address_read(input int n,input int id,input int addr);   // 2026-10-11：保持AR至真实握手
   @(negedge clk);B.arvalid=1;B.arlen=n-1;B.arid=id;B.araddr=addr;   // 2026-10-11：配置突发
   do @(posedge clk);while(!B.arready);@(negedge clk);B.arvalid=0;   // 2026-10-11：只发送一次AR
 endtask   // 2026-10-11：读地址驱动结束
 task automatic address_write(input int n,input int id,input int addr);   // 2026-10-11：保持AW至真实握手
   @(negedge clk);B.awvalid=1;B.awlen=n-1;B.awid=id;B.awaddr=addr;   // 2026-10-11：配置突发
   do @(posedge clk);while(!B.awready);@(negedge clk);B.awvalid=0;   // 2026-10-11：只发送一次AW
 endtask   // 2026-10-11：写地址驱动结束
 task automatic write_word(input int k,input int last);   // 2026-10-11：W独立于AW并带随机空拍
   repeat(phase2_pick(0,5)) @(negedge clk);B.wvalid=1;B.wdata=words[k];B.wlast=last;   // 2026-10-11：设置并保持数据
   do @(posedge clk);while(!B.wready);@(negedge clk);B.wvalid=0;   // 2026-10-11：接受后撤销valid
 endtask   // 2026-10-11：写拍驱动结束
 task automatic read_word(input int k,input int id,input int last,input int resp);   // 2026-10-11：独立参考检查R数据与字段
   repeat(phase2_pick(0,5)) @(negedge clk);B.rready=1;   // 2026-10-11：改变反压间隔
   do @(posedge clk);while(!B.rvalid);   // 2026-10-11：仅检查接受拍
   if(B.rid!=id || B.rlast!=last || B.rresp!=resp || B.rdata!==(resp==0?words[k]:64'd0)) $fatal(1,"EDGE/R phase=%0d k=%0d actual_id=%0d actual_resp=%0d actual_last=%b actual_data=%h expected_id=%0d expected_resp=%0d expected_last=%0d expected_data=%h",edge_phase,k,B.rid,B.rresp,B.rlast,B.rdata,id,resp,last,(resp==0?words[k]:64'd0));   // 2026-10-11：守恒、数据及错误填充值均验收
   @(negedge clk);B.rready=0;   // 2026-10-11：下一拍可再次反压
 endtask   // 2026-10-11：读拍验收结束
 task automatic response_write(input int id,input int resp);   // 2026-10-11：等待B且保持400拍
   wait(B.bvalid);repeat(400) @(negedge clk);B.bready=1;   // 2026-10-11：稳定性监视器持续检查已展示响应
   do @(posedge clk);while(!B.bvalid);   // 2026-10-11：只接受一次B
   if(B.bid!=id || B.bresp!=resp) $fatal(1,"EDGE/B id=%0d resp=%0d",B.bid,B.bresp);   // 2026-10-11：检查原ID及正确响应码
   @(negedge clk);B.bready=0;   // 2026-10-11：防重复接受
 endtask   // 2026-10-11：B验收结束
 initial begin   // 2026-10-11：读写同时在途、中断两次、无全局复位恢复
   // 2026-10-12：默认保留原同拍场景，新增两个独立运行的相邻拍边界。
   if($value$plusargs("EDGE_PHASE=%d",edge_phase)) begin end
   if(edge_phase < -1 || edge_phase > 1) $fatal(1,"EDGE/INVALID_PHASE %0d",edge_phase);
   third_resp=(edge_phase==-1)?2:0;
   $display("EDGE/CONFIG phase=%0d third_expected_resp=%0d model=DDR4_SIM_RAM clk_ns=4 timeout_cycles=64 hold_cycles=400",edge_phase,third_resp);
   repeat(20) @(negedge clk);B.rst_n=1;repeat(20) @(negedge clk);   // 2026-10-11：只在初始阶段做全局复位
   for(int k=0;k<4;k++) begin words[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};B.U_DDR.u_sim_ram.mem['h8000/8+k]=words[k];end   // 2026-10-11：模型预装仅作为输入，预期结果由参考数组保存
   fork address_read(4,1,'h8000);address_write(4,31,'ha000);join   // 2026-10-11：独立ID的读写并行
   write_word(0,0);read_word(0,1,0,0);wait(B.rvalid);   // 2026-10-11：准备已展示第二R及部分W
   // 2026-10-12：先在下降沿改变激励，避免与上升沿DUT采样竞争。
   @(negedge clk);
   if(edge_phase==-1) begin
     B.rready=0;B.ddr_rst_n=0;
     @(posedge clk);
     if(!B.U_DDR.storage_ready) $fatal(1,"EDGE/MODEL_READY_TOO_EARLY");
     #0.001;
     if(B.U_DDR.storage_ready) $fatal(1,"EDGE/MODEL_READY_NOT_DROPPED");
     @(negedge clk);B.rready=1;
   end else begin
     B.rready=1;
     if(edge_phase==0) B.ddr_rst_n=0;
   end
   @(posedge clk);
   // 2026-10-12：第二R已展示，不论DDR失效是否生效，接受时必须保持原成功数据。
   if(!B.rvalid || B.rid!=1 || B.rresp!=0 || B.rlast || B.rdata!==words[1]) $fatal(1,"EDGE/FAULT_HANDSHAKE");
   if(B.U_DDR.storage_ready !== (edge_phase==-1 ? 1'b0 : 1'b1)) $fatal(1,"EDGE/FAULT_EFFECTIVE_BOUNDARY phase=%0d ready=%b",edge_phase,B.U_DDR.storage_ready);
   $display("EDGE/SECOND_ACCEPT time_ns=%0t phase=%0d sampled_storage_ready=%b third_expected_resp=%0d",$time,edge_phase,B.U_DDR.storage_ready,third_resp);
   #0.001;
   if(!B.rvalid || B.rid!=1 || B.rresp!=third_resp || B.rlast || B.rdata!==(third_resp==0?words[2]:64'd0)) $fatal(1,"EDGE/THIRD_PRESENTED phase=%0d resp=%0d data=%h",edge_phase,B.rresp,B.rdata);
   @(negedge clk);B.rready=0;
   if(edge_phase==1) begin
     B.ddr_rst_n=0;
     @(posedge clk);#0.001;
     if(B.U_DDR.storage_ready) $fatal(1,"EDGE/LATE_READY_NOT_DROPPED");
     @(negedge clk);
   end
   wait(!B.U_DDR.storage_ready);
   // 2026-10-12：同拍/后一拍模式的第三R已经是成功保持拍，失效不得将其改成错误。
   if(!B.rvalid || B.rresp!=third_resp || B.rdata!==(third_resp==0?words[2]:64'd0)) $fatal(1,"EDGE/THIRD_CHANGED_AT_FAULT");
   $display("EDGE/FAULT_EFFECTIVE time_ns=%0t phase=%0d held_third_resp=%0d",$time,edge_phase,B.rresp);
   repeat(64) @(negedge clk);B.ddr_rst_n=1;wait(B.U_DDR.storage_ready);   // 2026-10-11：旧事务尚未收尾就恢复物理模型
   @(negedge clk);B.arvalid=1;B.awvalid=1;B.araddr='h9000;B.awaddr='hb000;   // 2026-10-11：故意提交新地址验证阻塞
   repeat(16) begin @(posedge clk);if(B.arready || B.awready || B.ready) $fatal(1,"EDGE/EARLY_REOPEN");end   // 2026-10-11：恢复校准不能绕过旧错误事务
   @(negedge clk);B.arvalid=0;B.awvalid=0;B.ddr_rst_n=0;   // 2026-10-11：旧R/B等待期间再次中断
   wait(!B.U_DDR.storage_ready);repeat(8) @(negedge clk);B.ddr_rst_n=1;   // 2026-10-11：第二次恢复不清业务收尾记录
   repeat(400) @(negedge clk);   // 2026-10-11：错误R展示后长反压保持
   fork   // 2026-10-11：同时排空错误读和剩余写
     begin read_word(2,1,0,third_resp);read_word(3,1,1,2);end   // 2026-10-12：第三R由确定的故障位置决定，第四R始终零数据SLVERR且LAST=1
     begin for(int k=1;k<4;k++) begin write_word(k,k==3);if(B.U_DDR.mem_wvalid) $fatal(1,"EDGE/REPLAY_OLD_W");end response_write(31,2);end   // 2026-10-11：丢弃剩余W后才给一次错误B
   join   // 2026-10-11：两个方向收尾完成
   repeat(20) @(negedge clk);if(!B.ready || B.rvalid || B.bvalid) $fatal(1,"EDGE/RECOVERY_NOT_DONE");   // 2026-10-11：不能残留旧响应
   words[0]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};   // 2026-10-11：新任务用不同数据
   address_write(1,17,'h9000);write_word(0,1);response_write(17,0);   // 2026-10-11：无全局复位新写成功
   address_read(1,23,'h9000);read_word(0,23,1,0);   // 2026-10-11：无全局复位新读匹配
   repeat(16) @(posedge clk);if(B.rvalid || B.bvalid) $fatal(1,"EDGE/EXTRA_RESPONSE");   // 2026-10-11：排除重复完成
   // 2026-10-12：旧4拍读/写和新1拍读/写必须守恒，防止遗漏、重复或错误码被放宽。
   #0.001;
   if(ar_accepts!=2 || aw_accepts!=2 || r_accepts!=5 || w_accepts!=5 || b_accepts!=2 || b_okay!=1 || b_error!=1 || r_okay!=(edge_phase==-1?3:4) || r_error!=(edge_phase==-1?2:1))
     $fatal(1,"EDGE/COUNTS phase=%0d AR=%0d AW=%0d R=%0d W=%0d B=%0d R_OKAY=%0d R_ERROR=%0d B_OKAY=%0d B_ERROR=%0d",edge_phase,ar_accepts,aw_accepts,r_accepts,w_accepts,b_accepts,r_okay,r_error,b_okay,b_error);
   $display("EDGE/COUNTS phase=%0d AR=%0d AW=%0d R=%0d W=%0d B=%0d R_OKAY=%0d R_ERROR=%0d B_OKAY=%0d B_ERROR=%0d",edge_phase,ar_accepts,aw_accepts,r_accepts,w_accepts,b_accepts,r_okay,r_error,b_okay,b_error);
   $display("TEST PASS tb_backend_edge_recovery phase=%0d repeated_fault=2 parallel_abort=1 hold=400 third_resp=%0d",edge_phase,third_resp);$finish;   // 2026-10-11：独立场景总结
 end   // 2026-10-11：主测试结束
 initial begin #2000000;$fatal(1,"EDGE/WATCHDOG");end   // 2026-10-11：故障须显式失败
endmodule   // 2026-10-11：边界测试顶层结束
