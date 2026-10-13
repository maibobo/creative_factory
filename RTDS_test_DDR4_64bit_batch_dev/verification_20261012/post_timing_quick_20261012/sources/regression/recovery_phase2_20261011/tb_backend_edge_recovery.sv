`timescale 1ns/1ps   // 2026-10-11：补同拍故障/握手、重复故障及读写并行中断
// 修改记录 2026-10-11：在外部DDR复位端口施加故障，不强制DUT内部状态。
module tb_backend_edge_recovery;   // 2026-10-11：补充TC-F13/F14边界
 `include "rtds_random.svh"   // 2026-10-11：实际载荷及空拍由种子决定
 logic clk=0;always #2 clk=~clk;   // 2026-10-11：生产业务时钟250MHz
 rtds_backend_test_if B(clk);   // 2026-10-11：使用真实后端和既有稳定性监视器
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
   if(B.rid!=id || B.rlast!=last || B.rresp!=resp || B.rdata!==(resp==0?words[k]:64'd0)) $fatal(1,"EDGE/R k=%0d id=%0d resp=%0d last=%b data=%h",k,B.rid,B.rresp,B.rlast,B.rdata);   // 2026-10-11：守恒、数据及错误填充值均验收
   @(negedge clk);B.rready=0;   // 2026-10-11：下一拍可再次反压
 endtask   // 2026-10-11：读拍验收结束
 task automatic response_write(input int id,input int resp);   // 2026-10-11：等待B且保持400拍
   wait(B.bvalid);repeat(400) @(negedge clk);B.bready=1;   // 2026-10-11：稳定性监视器持续检查已展示响应
   do @(posedge clk);while(!B.bvalid);   // 2026-10-11：只接受一次B
   if(B.bid!=id || B.bresp!=resp) $fatal(1,"EDGE/B id=%0d resp=%0d",B.bid,B.bresp);   // 2026-10-11：检查原ID及正确响应码
   @(negedge clk);B.bready=0;   // 2026-10-11：防重复接受
 endtask   // 2026-10-11：B验收结束
 initial begin   // 2026-10-11：读写同时在途、中断两次、无全局复位恢复
   repeat(20) @(negedge clk);B.rst_n=1;repeat(20) @(negedge clk);   // 2026-10-11：只在初始阶段做全局复位
   for(int k=0;k<4;k++) begin words[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};B.U_DDR.u_sim_ram.mem['h8000/8+k]=words[k];end   // 2026-10-11：模型预装仅作为输入，预期结果由参考数组保存
   fork address_read(4,1,'h8000);address_write(4,31,'ha000);join   // 2026-10-11：独立ID的读写并行
   write_word(0,0);read_word(0,1,0,0);wait(B.rvalid);   // 2026-10-11：准备已展示第二R及部分W
   @(negedge clk);B.rready=1;B.ddr_rst_n=0;   // 2026-10-11：下一接受边沿同时观察故障与R握手
   @(posedge clk);if(!B.rvalid || B.rid!=1 || B.rresp!=0 || B.rlast || B.rdata!==words[1]) $fatal(1,"EDGE/FAULT_HANDSHAKE");   // 2026-10-11：已展示响应必须维持原值
   @(negedge clk);B.rready=0;wait(!B.U_DDR.storage_ready);   // 2026-10-11：确认后端实际进入存储不可用
   repeat(64) @(negedge clk);B.ddr_rst_n=1;wait(B.U_DDR.storage_ready);   // 2026-10-11：旧事务尚未收尾就恢复物理模型
   @(negedge clk);B.arvalid=1;B.awvalid=1;B.araddr='h9000;B.awaddr='hb000;   // 2026-10-11：故意提交新地址验证阻塞
   repeat(16) begin @(posedge clk);if(B.arready || B.awready || B.ready) $fatal(1,"EDGE/EARLY_REOPEN");end   // 2026-10-11：恢复校准不能绕过旧错误事务
   @(negedge clk);B.arvalid=0;B.awvalid=0;B.ddr_rst_n=0;   // 2026-10-11：旧R/B等待期间再次中断
   wait(!B.U_DDR.storage_ready);repeat(8) @(negedge clk);B.ddr_rst_n=1;   // 2026-10-11：第二次恢复不清业务收尾记录
   repeat(400) @(negedge clk);   // 2026-10-11：错误R展示后长反压保持
   fork   // 2026-10-11：同时排空错误读和剩余写
     begin read_word(2,1,0,2);read_word(3,1,1,2);end   // 2026-10-11：剩余两R为零数据SLVERR且仅末拍LAST
     begin for(int k=1;k<4;k++) begin write_word(k,k==3);if(B.U_DDR.mem_wvalid) $fatal(1,"EDGE/REPLAY_OLD_W");end response_write(31,2);end   // 2026-10-11：丢弃剩余W后才给一次错误B
   join   // 2026-10-11：两个方向收尾完成
   repeat(20) @(negedge clk);if(!B.ready || B.rvalid || B.bvalid) $fatal(1,"EDGE/RECOVERY_NOT_DONE");   // 2026-10-11：不能残留旧响应
   words[0]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};   // 2026-10-11：新任务用不同数据
   address_write(1,17,'h9000);write_word(0,1);response_write(17,0);   // 2026-10-11：无全局复位新写成功
   address_read(1,23,'h9000);read_word(0,23,1,0);   // 2026-10-11：无全局复位新读匹配
   repeat(16) @(posedge clk);if(B.rvalid || B.bvalid) $fatal(1,"EDGE/EXTRA_RESPONSE");   // 2026-10-11：排除重复完成
   $display("TEST PASS tb_backend_edge_recovery repeated_fault=2 fault_r_handshake=1 parallel_abort=1 hold=400");$finish;   // 2026-10-11：独立场景总结
 end   // 2026-10-11：主测试结束
 initial begin #2000000;$fatal(1,"EDGE/WATCHDOG");end   // 2026-10-11：故障须显式失败
endmodule   // 2026-10-11：边界测试顶层结束
