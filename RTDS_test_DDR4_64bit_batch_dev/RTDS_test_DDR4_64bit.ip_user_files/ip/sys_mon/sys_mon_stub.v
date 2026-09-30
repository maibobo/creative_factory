// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Sat Sep 12 09:57:39 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
// Design      : sys_mon
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module sys_mon(daddr_in, dclk_in, den_in, di_in, dwe_in, reset_in, 
  busy_out, channel_out, do_out, drdy_out, eoc_out, eos_out, alarm_out)
/* synthesis syn_black_box black_box_pad_pin="daddr_in[7:0],dclk_in,den_in,di_in[15:0],dwe_in,reset_in,busy_out,channel_out[5:0],do_out[15:0],drdy_out,eoc_out,eos_out,alarm_out" */;
  input [7:0]daddr_in;
  input dclk_in;
  input den_in;
  input [15:0]di_in;
  input dwe_in;
  input reset_in;
  output busy_out;
  output [5:0]channel_out;
  output [15:0]do_out;
  output drdy_out;
  output eoc_out;
  output eos_out;
  output alarm_out;
endmodule
