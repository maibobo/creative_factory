// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Tue Sep 22 16:58:03 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/project/RTDS/DDR/aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g_stub.v
// Design      : aurora_8b10b_1p25g
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module aurora_8b10b_1p25g(s_axi_tx_tdata, s_axi_tx_tkeep, 
  s_axi_tx_tvalid, s_axi_tx_tlast, s_axi_tx_tready, m_axi_rx_tdata, m_axi_rx_tkeep, 
  m_axi_rx_tvalid, m_axi_rx_tlast, rxp, rxn, txp, txn, gt_refclk1_p, gt_refclk1_n, gt_refclk1_out, 
  frame_err, hard_err, soft_err, lane_up, channel_up, crc_pass_fail_n, crc_valid, user_clk_out, 
  sync_clk_out, gt_reset, reset, sys_reset_out, gt_reset_out, power_down, loopback, tx_lock, 
  init_clk_in, tx_resetdone_out, rx_resetdone_out, link_reset_out, gt0_drpaddr, gt0_drpdi, 
  gt0_drpdo, gt0_drpen, gt0_drprdy, gt0_drpwe, gt_powergood, pll_not_locked_out)
/* synthesis syn_black_box black_box_pad_pin="s_axi_tx_tdata[0:31],s_axi_tx_tkeep[0:3],s_axi_tx_tvalid,s_axi_tx_tlast,s_axi_tx_tready,m_axi_rx_tdata[0:31],m_axi_rx_tkeep[0:3],m_axi_rx_tvalid,m_axi_rx_tlast,rxp,rxn,txp,txn,gt_refclk1_p,gt_refclk1_n,gt_refclk1_out,frame_err,hard_err,soft_err,lane_up,channel_up,crc_pass_fail_n,crc_valid,user_clk_out,sync_clk_out,gt_reset,reset,sys_reset_out,gt_reset_out,power_down,loopback[2:0],tx_lock,init_clk_in,tx_resetdone_out,rx_resetdone_out,link_reset_out,gt0_drpaddr[8:0],gt0_drpdi[15:0],gt0_drpdo[15:0],gt0_drpen,gt0_drprdy,gt0_drpwe,gt_powergood[0:0],pll_not_locked_out" */;
  input [0:31]s_axi_tx_tdata;
  input [0:3]s_axi_tx_tkeep;
  input s_axi_tx_tvalid;
  input s_axi_tx_tlast;
  output s_axi_tx_tready;
  output [0:31]m_axi_rx_tdata;
  output [0:3]m_axi_rx_tkeep;
  output m_axi_rx_tvalid;
  output m_axi_rx_tlast;
  input rxp;
  input rxn;
  output txp;
  output txn;
  input gt_refclk1_p;
  input gt_refclk1_n;
  output gt_refclk1_out;
  output frame_err;
  output hard_err;
  output soft_err;
  output lane_up;
  output channel_up;
  output crc_pass_fail_n;
  output crc_valid;
  output user_clk_out;
  output sync_clk_out;
  input gt_reset;
  input reset;
  output sys_reset_out;
  output gt_reset_out;
  input power_down;
  input [2:0]loopback;
  output tx_lock;
  input init_clk_in;
  output tx_resetdone_out;
  output rx_resetdone_out;
  output link_reset_out;
  input [8:0]gt0_drpaddr;
  input [15:0]gt0_drpdi;
  output [15:0]gt0_drpdo;
  input gt0_drpen;
  output gt0_drprdy;
  input gt0_drpwe;
  output [0:0]gt_powergood;
  output pll_not_locked_out;
endmodule
