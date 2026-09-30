// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Sun Sep 20 15:47:07 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
// Design      : design_1_INFO_EXCH_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "INFO_EXCH,Vivado 2020.2" *)
module design_1_INFO_EXCH_0_0(CPU_WR_DONE_EVENT, FPGA_TEMP_W, INT_STATE_W, 
  CPU_REC_STATE_W, FPGA_CPU_START_ADDR, FPGA_CPU_LEN, CPU_WR_DONE_resp, DDR_STATUS_W, 
  RX_READY_BLOCKS, RX_HEAD_SEQ, RX_DROPPED_FRAMES, r_INT_STATE, r_CLEAR_INTER, 
  r_CPU_REC_STATE, r_RD_START, r_CPU_FPGA_START_ADDR, r_CPU_FPGA_LEN, S_AXI_ACLK, 
  S_AXI_ARESETN, S_AXI_AWADDR, S_AXI_AWPROT, S_AXI_AWVALID, S_AXI_AWREADY, S_AXI_WDATA, 
  S_AXI_WSTRB, S_AXI_WVALID, S_AXI_WREADY, S_AXI_BRESP, S_AXI_BVALID, S_AXI_BREADY, 
  S_AXI_ARADDR, S_AXI_ARPROT, S_AXI_ARVALID, S_AXI_ARREADY, S_AXI_RDATA, S_AXI_RRESP, 
  S_AXI_RVALID, S_AXI_RREADY)
/* synthesis syn_black_box black_box_pad_pin="CPU_WR_DONE_EVENT,FPGA_TEMP_W[31:0],INT_STATE_W[0:0],CPU_REC_STATE_W[0:0],FPGA_CPU_START_ADDR[31:0],FPGA_CPU_LEN[31:0],CPU_WR_DONE_resp[0:0],DDR_STATUS_W[31:0],RX_READY_BLOCKS[31:0],RX_HEAD_SEQ[31:0],RX_DROPPED_FRAMES[31:0],r_INT_STATE,r_CLEAR_INTER,r_CPU_REC_STATE,r_RD_START,r_CPU_FPGA_START_ADDR[31:0],r_CPU_FPGA_LEN[31:0],S_AXI_ACLK,S_AXI_ARESETN,S_AXI_AWADDR[31:0],S_AXI_AWPROT[2:0],S_AXI_AWVALID,S_AXI_AWREADY,S_AXI_WDATA[31:0],S_AXI_WSTRB[3:0],S_AXI_WVALID,S_AXI_WREADY,S_AXI_BRESP[1:0],S_AXI_BVALID,S_AXI_BREADY,S_AXI_ARADDR[31:0],S_AXI_ARPROT[2:0],S_AXI_ARVALID,S_AXI_ARREADY,S_AXI_RDATA[31:0],S_AXI_RRESP[1:0],S_AXI_RVALID,S_AXI_RREADY" */;
  input CPU_WR_DONE_EVENT;
  input [31:0]FPGA_TEMP_W;
  input [0:0]INT_STATE_W;
  input [0:0]CPU_REC_STATE_W;
  input [31:0]FPGA_CPU_START_ADDR;
  input [31:0]FPGA_CPU_LEN;
  input [0:0]CPU_WR_DONE_resp;
  input [31:0]DDR_STATUS_W;
  input [31:0]RX_READY_BLOCKS;
  input [31:0]RX_HEAD_SEQ;
  input [31:0]RX_DROPPED_FRAMES;
  output r_INT_STATE;
  output r_CLEAR_INTER;
  output r_CPU_REC_STATE;
  output r_RD_START;
  output [31:0]r_CPU_FPGA_START_ADDR;
  output [31:0]r_CPU_FPGA_LEN;
  input S_AXI_ACLK;
  input S_AXI_ARESETN;
  input [31:0]S_AXI_AWADDR;
  input [2:0]S_AXI_AWPROT;
  input S_AXI_AWVALID;
  output S_AXI_AWREADY;
  input [31:0]S_AXI_WDATA;
  input [3:0]S_AXI_WSTRB;
  input S_AXI_WVALID;
  output S_AXI_WREADY;
  output [1:0]S_AXI_BRESP;
  output S_AXI_BVALID;
  input S_AXI_BREADY;
  input [31:0]S_AXI_ARADDR;
  input [2:0]S_AXI_ARPROT;
  input S_AXI_ARVALID;
  output S_AXI_ARREADY;
  output [31:0]S_AXI_RDATA;
  output [1:0]S_AXI_RRESP;
  output S_AXI_RVALID;
  input S_AXI_RREADY;
endmodule
