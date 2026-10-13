// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Tue Sep 15 08:53:39 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/RTDS_test_DDR4_64bit.srcs/sources_1/ip/ila_FDMA/ila_FDMA_stub.v
// Design      : ila_FDMA
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2020.1" *)
module ila_FDMA(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[31:0],probe1[0:0],probe2[0:0],probe3[63:0],probe4[15:0],probe5[0:0],probe6[31:0],probe7[0:0],probe8[0:0],probe9[63:0],probe10[15:0],probe11[0:0],probe12[3:0],probe13[3:0]" */;
  input clk;
  input [31:0]probe0;
  input [0:0]probe1;
  input [0:0]probe2;
  input [63:0]probe3;
  input [15:0]probe4;
  input [0:0]probe5;
  input [31:0]probe6;
  input [0:0]probe7;
  input [0:0]probe8;
  input [63:0]probe9;
  input [15:0]probe10;
  input [0:0]probe11;
  input [3:0]probe12;
  input [3:0]probe13;
endmodule
