`timescale 1ns/1ps   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
// 修改记录 2026-10-11：TC-F15补充：四种就绪失效×六处边界全组合，随机中断位置、短断链及停止用户时钟；成功路径不复位。
module tb_recovery_cross_variants;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 `include "rtds_random.svh"   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 rtds_real_harness H();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 int iterations=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 task automatic wait_recovered;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int k=0;k<3000;k++) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge H.clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(!H.fdma_rbusy && !H.U_ADAPTER.tx_recovering && H.ddr_ready) return;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   $fatal(1,"ISOLATION/RECOVERY_TIMEOUT busy=%b recovering=%b ddr=%b",H.fdma_rbusy,H.U_ADAPTER.tx_recovering,H.ddr_ready);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 endtask   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 initial begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   H.reset();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int n=0;n<100;n++) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     int kind,stage,oldlen,newseed;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     bit paused,quiet_before;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     kind=(n/6)%4;stage=n%6;paused=(n%7==0);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     oldlen=(stage==5)?16:16*phase2_pick(1,4);newseed=phase2_pick(1,1048575);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.user_half_period=(n%2==0)?3.2:7.9;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.random_tx_ready=0;H.tx_ready=0;H.check_tx=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.prepare_tx('h8000,oldlen,newseed,1);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.hold_r=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.command('h8000,oldlen);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     case(stage)   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       0:wait(H.fdma_rareq || H.fdma_rbusy);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       1:wait(H.fdma_rbusy);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       2:wait(H.fdma_rbusy && H.b_rvalid);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       3:begin H.hold_r=0;wait(H.read_beats>=1);end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       4:begin H.hold_r=0;H.tx_ready=1;wait(H.tx_valid && H.tx_sof);@(posedge H.uclk);@(negedge H.uclk);H.tx_ready=0;end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       5:begin H.hold_r=0;H.tx_ready=1;wait(H.tx_valid && H.tx_eof);@(posedge H.uclk);@(negedge H.uclk);H.tx_ready=0;end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     endcase   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     @(negedge H.clk);quiet_before=H.U_ADAPTER.tx_user_quiet_fdma;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(paused) H.user_clock_enable=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     case(kind) 0:H.channel_up=0;1:H.pcie_up=0;2:H.ddr_reset_n=0;3:H.lane_up=0;endcase   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(phase2_pick(8,40)) @(negedge H.clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.check_reg('h20,0);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     // 保持读响应时提交的命令必须拒绝；不为此重置全局逻辑。
     if(H.fdma_rbusy || (paused && !quiet_before)) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       H.command('h9000,32);H.wait_end();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       if(H.U_ADAPTER.tx_active) $fatal(1,"ISOLATION/START_DURING_RECOVERY");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.hold_r=0;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     case(kind) 0:H.channel_up=1;1:H.pcie_up=1;2:H.ddr_reset_n=1;3:H.lane_up=1;endcase   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(paused && !quiet_before) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       repeat(32) @(negedge H.clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
       if(!H.U_ADAPTER.tx_recovering) $fatal(1,"ISOLATION/STOPPED_USER_CLOCK_ACCEPTED");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.user_clock_enable=1;H.random_tx_ready=1;H.tx_ready=1;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     wait_recovered();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.valid_tx('h9000,32,newseed^'h55aa,2);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(H.done_events!=1 || H.tx_beats!=4 || H.tx_frames!=2 || H.cfg_pulses!=2) $fatal(1,"ISOLATION/FRESH_COUNTS");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     iterations++;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     $display("ISOLATION_CHECK n=%0d kind=%0d stage=%0d old_bytes=%0d paused=%b fresh_beats=4 done=1",n,kind,stage,oldlen,paused);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   $display("TEST PASS tb_recovery_cross_variants iterations=%0d reset_free=100",iterations);$finish;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 initial begin #8000000;$fatal(1,"ISOLATION/WATCHDOG n=%0d",iterations);end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
endmodule   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
