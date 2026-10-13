`timescale 1ns/1ps   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
// 修改记录 2026-10-11：TC-F14集成子场景，双字/奇数尾字错误不形成可读块。
module tb_writer_error_recovery;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 `include "rtds_random.svh"   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 rtds_real_harness H();   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 initial begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   for(int words=1;words<=2;words++) begin   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     int a,b;H.reset();a=phase2_pick(1,1048575);b=phase2_pick(1,1048575);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.fault_write=1;H.send_rx(a);if(words==2) H.send_rx(b);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     repeat(3000) @(negedge H.clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(H.ready_blocks!=0 || H.dropped_words!=words || H.fdma_wbusy) $fatal(1,"WRITER/ERROR_COMMIT words=%0d drops=%0d blocks=%0d",words,H.dropped_words,H.ready_blocks);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.fault_write=0;H.send_rx(a);H.send_rx(b);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     wait(H.ready_blocks==1);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(H.head_len!=8 || H.head_seq!=0 || H.head_addr!='h100000) $fatal(1,"WRITER/FRESH_HEAD");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     begin logic[63:0] got;H.cpu_read64('h100000,got);if(got!=={32'(b),32'(a)}) $fatal(1,"WRITER/FRESH_DATA");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     H.wr('h14,1);repeat(100) @(negedge H.clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     if(H.ready_blocks!=0 || H.dropped_words!=words) $fatal(1,"WRITER/ACK_DROPS");   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
     $display("WRITER_ERROR_CHECK words=%0d dropped=%0d fresh_len=8",words,words);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
   $display("TEST PASS tb_writer_error_recovery odd=1 even=1");$finish;   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 initial begin #1000000;$fatal(1,"WRITER_ERROR/WATCHDOG");end   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
endmodule   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
