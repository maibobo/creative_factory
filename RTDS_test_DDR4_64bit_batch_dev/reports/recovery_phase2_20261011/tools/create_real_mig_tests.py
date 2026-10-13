from pathlib import Path
import re
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');N=R/'regression/recovery_phase2_20261011'
s=(N/'rtds_backend_test_if.sv').read_text('utf-8').replace('rtds_backend_test_if','rtds_backend_real_env')
ports='''
 logic ref_clk=0;
 always #4.998 ref_clk=~ref_clk;
 wire act_n,reset_n;
 wire[16:0] adr;
 wire[1:0] ba;
 wire[0:0] bg,cke,odt,cs_n,ck_t,ck_c;
 wire[7:0] dm,dqs_t,dqs_c;
 wire[63:0] dq;
'''
s=s.replace(' rtds_ddr4_backend #',ports+' rtds_ddr4_backend #',1)
s=s.replace('.ddr_sys_clk_i(clk)', '.ddr_sys_clk_i(ref_clk)')
s=s.replace('.ddr_axi_response_error_sticky(response_error),.ddr_axi_timeout_sticky(timeout_error)', '''.ddr_axi_response_error_sticky(response_error),.ddr_axi_timeout_sticky(timeout_error),
 .c0_ddr4_act_n(act_n),.c0_ddr4_adr(adr),.c0_ddr4_ba(ba),.c0_ddr4_bg(bg),
 .c0_ddr4_cke(cke),.c0_ddr4_odt(odt),.c0_ddr4_cs_n(cs_n),.c0_ddr4_ck_t(ck_t),.c0_ddr4_ck_c(ck_c),
 .c0_ddr4_reset_n(reset_n),.c0_ddr4_dm_dbi_n(dm),.c0_ddr4_dq(dq),.c0_ddr4_dqs_t(dqs_t),.c0_ddr4_dqs_c(dqs_c)''')
s=s.replace('\nendmodule', '''
 rtds_ddr4_physical_peer MEM(.act_n(act_n),.adr(adr),.ba(ba),.bg(bg),.cke(cke),.odt(odt),.cs_n(cs_n),.ck_t(ck_t),.ck_c(ck_c),.reset_n(reset_n),.dq(dq),.dm(dm),.dqs_t(dqs_t),.dqs_c(dqs_c));
endmodule''',1)
def ann(s):
    out=[]
    for l in s.splitlines():
        if l.strip() and not l.lstrip().startswith('//'):
            a,_,b=l.partition('//');l=a.rstrip()+'   // 2026-10-11：'+(b.strip().removeprefix('2026-10-11：') if b else '真实MIG恢复验证，物理接线依据官方示例')
        out.append(l)
    return '\n'.join(out)+'\n'
(N/'rtds_backend_real_env.sv').write_text(ann(s),encoding='utf-8')
peer='''`timescale 1ns/1ps
// 2026-10-11：物理模型接线依据当前MIG官方示例sim_tb_top.sv的x16、单rank分支。
// 原厂颗粒模型保存在verification_20261011/mig_model_probe中，原文件及版权声明保持。
module rtds_ddr_short(in1,in1);
 inout in1;
endmodule
module rtds_ddr4_physical_peer(
 input wire act_n,input wire[16:0] adr,input wire[1:0] ba,input wire[0:0] bg,cke,odt,cs_n,ck_t,ck_c,input wire reset_n,
 inout wire[63:0] dq,inout wire[7:0] dm,dqs_t,dqs_c);
 import arch_package::*;
 DDR4_if #(.CONFIGURED_DQ_BITS(16)) P[0:3]();
 for(genvar i=0;i<4;i++) begin:G
   ddr4_model #(.CONFIGURED_DQ_BITS(16),.CONFIGURED_DENSITY(_8G)) M(.model_enable(1'b1),.iDDR4(P[i]));
   for(genvar k=0;k<16;k++) begin:DQ
     rtds_ddr_short S(P[i].DQ[k],dq[i*16+k]);
   end
   for(genvar k=0;k<2;k++) begin:DQS
     rtds_ddr_short ST(P[i].DQS_t[k],dqs_t[i*2+k]);
     rtds_ddr_short SC(P[i].DQS_c[k],dqs_c[i*2+k]);
     rtds_ddr_short SM(P[i].DM_n[k],dm[i*2+k]);
   end
   assign P[i].BG=bg;assign P[i].BA=ba;assign P[i].ADDR_17=0;assign P[i].ADDR=adr[13:0];
   assign P[i].RAS_n_A16=adr[16];assign P[i].CAS_n_A15=adr[15];assign P[i].WE_n_A14=adr[14];
   assign P[i].CK={ck_t[0],ck_c[0]};assign P[i].ACT_n=act_n;assign P[i].CKE=cke[0];assign P[i].ODT=odt[0];assign P[i].CS_n=cs_n[0];
   assign P[i].PARITY=0;assign P[i].TEN=0;assign P[i].ZQ=1;assign P[i].PWR=1;assign P[i].VREF_CA=1;assign P[i].VREF_DQ=1;assign P[i].RESET_n=reset_n;
 end
endmodule
'''
(N/'rtds_ddr4_physical_peer.sv').write_text(ann(peer),encoding='utf-8')
tb='''`timescale 1ns/1ps
// 修改记录 2026-10-11：TC-F16真实MIG/Clock Converter与颗粒模型子场景。
module tb_real_mig_recovery;
 `include "rtds_random.svh"
 logic clk=0;always #2 clk=~clk;
 rtds_backend_real_env B(clk);
 logic[63:0] data[0:3];
 task automatic await_ready;
   for(int n=0;n<500000;n++) begin @(negedge clk);if(B.ready)return;end
   $fatal(1,"REAL_MIG/CALIB_TIMEOUT calib=%b ready=%b",B.calib,B.ready);
 endtask
 task automatic write4(input int address,input int id);
   @(negedge clk);B.awaddr=address;B.awid=id;B.awlen=3;B.awvalid=1;
   do @(posedge clk);while(!B.awready);
   @(negedge clk);B.awvalid=0;
   for(int k=0;k<4;k++) begin
     repeat(phase2_pick(0,7)) @(negedge clk);B.wdata=data[k];B.wlast=k==3;B.wvalid=1;
     do @(posedge clk);while(!B.wready);@(negedge clk);B.wvalid=0;
   end
   repeat(phase2_pick(4,20)) @(negedge clk);B.bready=1;
   do @(posedge clk);while(!B.bvalid);
   if(B.bid!=id || B.bresp!=0) $fatal(1,"REAL_MIG/WRITE_RESP");
   @(negedge clk);B.bready=0;
 endtask
 task automatic read4(input int address,input int id);
   @(negedge clk);B.araddr=address;B.arid=id;B.arlen=3;B.arvalid=1;
   do @(posedge clk);while(!B.arready);@(negedge clk);B.arvalid=0;
   for(int k=0;k<4;k++) begin
     repeat(phase2_pick(0,7)) @(negedge clk);B.rready=1;
     do @(posedge clk);while(!B.rvalid);
     if(B.rid!=id || B.rresp!=0 || B.rlast!=(k==3) || B.rdata!==data[k]) $fatal(1,"REAL_MIG/READ_DATA beat=%0d got=%h expected=%h",k,B.rdata,data[k]);
     @(negedge clk);B.rready=0;
   end
 endtask
 initial begin
   B.ddr_rst_n=0;repeat(100) @(negedge clk);B.rst_n=1;B.ddr_rst_n=1;
   await_ready();$display("REAL_MIG_CALIB time=%0t",$time);
   for(int k=0;k<4;k++) data[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};
   write4('h8000,3);read4('h8000,7);
   @(negedge clk);B.araddr='h8000;B.arid=11;B.arlen=3;B.arvalid=1;
   do @(posedge clk);while(!B.arready);@(negedge clk);B.arvalid=0;
   wait(B.rvalid);repeat(phase2_pick(4,30)) @(negedge clk);
   B.ddr_rst_n=0;wait(!B.U_DDR.storage_ready);repeat(100) @(negedge clk);B.ddr_rst_n=1;
   for(int k=0;k<4;k++) begin
     @(negedge clk);B.rready=1;do @(posedge clk);while(!B.rvalid);
     if(B.rid!=11 || B.rlast!=(k==3) || B.rresp!=(k==0?0:2)) $fatal(1,"REAL_MIG/ABORT_RESPONSE beat=%0d id=%d resp=%d",k,B.rid,B.rresp);
     @(negedge clk);B.rready=0;
   end
   await_ready();
   for(int k=0;k<4;k++) data[k]={32'(phase2_pick(1,2147483647)),32'(phase2_pick(1,2147483647))};
   write4('h9000,17);read4('h9000,23);
   $display("TEST PASS tb_real_mig_recovery old_read=4 fresh_write_read=4 DDR4_REAL=1");$finish;
 end
 initial begin #5000000;$fatal(1,"REAL_MIG/WATCHDOG");end
endmodule
'''
(N/'tb_real_mig_recovery.sv').write_text(ann(tb),encoding='utf-8')
print('real MIG environment, physical peer and recovery test written')
