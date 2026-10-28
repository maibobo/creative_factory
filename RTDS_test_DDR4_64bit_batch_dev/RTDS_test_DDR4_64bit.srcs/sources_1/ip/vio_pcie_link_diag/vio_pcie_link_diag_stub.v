// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Wed Oct 14 11:21:40 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/RTDS_test_DDR4_64bit.srcs/sources_1/ip/vio_pcie_link_diag/vio_pcie_link_diag_stub.v
// Design      : vio_pcie_link_diag
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2020.2" *)
module vio_pcie_link_diag(clk, probe_in0, probe_in1, probe_in2, probe_in3, 
  probe_in4, probe_in5, probe_in6, probe_in7, probe_in8, probe_in9, probe_in10, probe_in11, 
  probe_in12, probe_in13, probe_in14, probe_in15, probe_out0, probe_out1)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[15:0],probe_in1[3:0],probe_in2[15:0],probe_in3[15:0],probe_in4[15:0],probe_in5[15:0],probe_in6[31:0],probe_in7[31:0],probe_in8[63:0],probe_in9[127:0],probe_in10[111:0],probe_in11[15:0],probe_in12[31:0],probe_in13[31:0],probe_in14[31:0],probe_in15[15:0],probe_out0[0:0],probe_out1[0:0]" */;
  input clk;
  input [15:0]probe_in0;
  input [3:0]probe_in1;
  input [15:0]probe_in2;
  input [15:0]probe_in3;
  input [15:0]probe_in4;
  input [15:0]probe_in5;
  input [31:0]probe_in6;
  input [31:0]probe_in7;
  input [63:0]probe_in8;
  input [127:0]probe_in9;
  input [111:0]probe_in10;
  input [15:0]probe_in11;
  input [31:0]probe_in12;
  input [31:0]probe_in13;
  input [31:0]probe_in14;
  input [15:0]probe_in15;
  output [0:0]probe_out0;
  output [0:0]probe_out1;
endmodule
