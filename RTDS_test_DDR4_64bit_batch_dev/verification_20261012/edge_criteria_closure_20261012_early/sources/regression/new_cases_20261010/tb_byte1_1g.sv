`timescale 1ns/1ps
// TC-F09: DDR Byte1 -> actual adapter -> actual 1G CDC/LUT/four-beat output.
module tb_byte1_1g;
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 rtds_real_harness H();
 int duty,voltage,beat=0,frames=0;logic[47:0] expected_cfg;
 logic[31:0] expected_data;
 always @(posedge H.gclk) begin
   if(!H.rst_n) beat=0;
   else if(H.gvalid) begin
     case(beat)
       0: expected_data={expected_cfg[7:0],expected_cfg[15:8],expected_cfg[23:16],expected_cfg[31:24]};
       1: expected_data={expected_cfg[39:32],expected_cfg[47:40],8'hf0,8'h00};
       2,3:expected_data=0;
     endcase
     if(H.gdata!==expected_data || H.grem!=3 || H.gsof!=(beat==0) || H.geof!=(beat==3))
       $fatal(1,"BYTE1/FRAME beat=%0d data=%h expected=%h",beat,H.gdata,expected_data);
     if(beat==3) begin beat=0;frames++;end else beat++;
   end
 end
 task automatic more_frames(input int target);
   for(int i=0;i<10000;i++) begin @(negedge H.gclk);if(frames>=target)return;end
   $fatal(1,"BYTE1/NO_FRAME");
 endtask
 initial begin
   for(int id=1;id<=10;id++) begin
     int base;H.reset();base=frames;
     voltage=id<=3?5:(id<=7?12:24);
     case(id) 1,5,8:duty=3000;2,6,9:duty=5000;3,7,10:duty=8000;4:duty=2000;endcase
     expected_cfg=(48'(voltage*1048576)<<16)|48'(duty);
     H.valid_tx('h8000,16,'h100000,0);H.valid_tx('h8010,16,'h200000,11);
     repeat(200) @(negedge H.gclk);
     if(H.configured || frames!=base) $fatal(1,"BYTE1/INVALID_STARTED");
     H.valid_tx('h8020,16,'h300000,8'(id));more_frames(base+2);
     if(!H.configured || H.configured_id!=id || H.U_1G.cfg_user!==expected_cfg) $fatal(1,"BYTE1/LUT");
     H.valid_tx('h8030,16,'h400000,8'(id==10?1:10));more_frames(base+4);
     if(H.configured_id!=id || H.U_1G.cfg_user!==expected_cfg) $fatal(1,"BYTE1/LOCK");
     $display("BYTE1_CHECK id=%0d duty=%0d voltage=%0d cfg=%h frames=%0d",id,duty,voltage,expected_cfg,frames-base);
   end
   $display("TEST PASS tb_byte1_1g ids=10 illegal=0,11 four_beats=4 Byte6=F0 lock=checked");$finish;
 end
 initial begin #2000000;$fatal(1,"BYTE1/WATCHDOG");end
endmodule
