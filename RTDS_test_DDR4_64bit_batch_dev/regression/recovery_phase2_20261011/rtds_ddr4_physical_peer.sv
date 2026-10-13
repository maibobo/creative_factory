`timescale 1ns/1ps   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
// 2026-10-11：物理模型接线依据当前MIG官方示例sim_tb_top.sv的x16、单rank分支。
// 原厂颗粒模型保存在verification_20261011/mig_model_probe中，原文件及版权声明保持。
module rtds_ddr_short(in1,in1);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 inout in1;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
endmodule   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
module rtds_ddr4_physical_peer(   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 input wire act_n,input wire[16:0] adr,input wire[1:0] ba,input wire[0:0] bg,cke,odt,cs_n,ck_t,ck_c,input wire reset_n,   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 inout wire[63:0] dq,inout wire[7:0] dm,dqs_t,dqs_c);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 import arch_package::*;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 tri model_enable=1'b1;   // 2026-10-11：按官方示例用可连接双向端口的tri网络使能颗粒模型
 DDR4_if #(.CONFIGURED_DQ_BITS(16)) P[0:3]();   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 for(genvar i=0;i<4;i++) begin:G   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   ddr4_model #(.CONFIGURED_DQ_BITS(16),.CONFIGURED_DENSITY(_8G)) M(.model_enable(model_enable),.iDDR4(P[i]));   // 2026-10-11：按官方示例将model_enable连接到tri网络
   for(genvar k=0;k<16;k++) begin:DQ   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     rtds_ddr_short S(P[i].DQ[k],dq[i*16+k]);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   for(genvar k=0;k<2;k++) begin:DQS   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     rtds_ddr_short ST(P[i].DQS_t[k],dqs_t[i*2+k]);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     rtds_ddr_short SC(P[i].DQS_c[k],dqs_c[i*2+k]);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
     rtds_ddr_short SM(P[i].DM_n[k],dm[i*2+k]);   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   assign P[i].BG=bg;assign P[i].BA=ba;assign P[i].ADDR_17=0;assign P[i].ADDR=adr[13:0];   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   assign P[i].RAS_n_A16=adr[16];assign P[i].CAS_n_A15=adr[15];assign P[i].WE_n_A14=adr[14];   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   assign P[i].CK={ck_t[0],ck_c[0]};assign P[i].ACT_n=act_n;assign P[i].CKE=cke[0];assign P[i].ODT=odt[0];assign P[i].CS_n=cs_n[0];   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
   assign P[i].PARITY=0;assign P[i].TEN=0;assign P[i].ZQ=1;assign P[i].PWR=1;assign P[i].VREF_CA=1;assign P[i].VREF_DQ=1;assign P[i].RESET_n=reset_n;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 end   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
endmodule   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
