// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
// Date        : Tue Apr 28 15:50:02 2026
// Host        : Lixy running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/Lixy/Desktop/RTDS/P2020.1/V12/RTDS_test/RTDS_test.srcs/sources_1/ip/fifo_cdc_pcie/fifo_cdc_pcie_stub.v
// Design      : fifo_cdc_pcie
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_5,Vivado 2020.1" *)
module fifo_cdc_pcie(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  empty)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[65:0],wr_en,rd_en,dout[65:0],full,empty" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [65:0]din;
  input wr_en;
  input rd_en;
  output [65:0]dout;
  output full;
  output empty;
endmodule
