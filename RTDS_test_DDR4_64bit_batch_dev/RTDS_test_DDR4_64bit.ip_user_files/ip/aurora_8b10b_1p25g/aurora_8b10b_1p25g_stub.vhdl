-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
-- Date        : Tue Sep 22 16:58:03 2026
-- Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/project/RTDS/DDR/aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g_stub.vhdl
-- Design      : aurora_8b10b_1p25g
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku040-ffva1156-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity aurora_8b10b_1p25g is
  Port ( 
    s_axi_tx_tdata : in STD_LOGIC_VECTOR ( 0 to 31 );
    s_axi_tx_tkeep : in STD_LOGIC_VECTOR ( 0 to 3 );
    s_axi_tx_tvalid : in STD_LOGIC;
    s_axi_tx_tlast : in STD_LOGIC;
    s_axi_tx_tready : out STD_LOGIC;
    m_axi_rx_tdata : out STD_LOGIC_VECTOR ( 0 to 31 );
    m_axi_rx_tkeep : out STD_LOGIC_VECTOR ( 0 to 3 );
    m_axi_rx_tvalid : out STD_LOGIC;
    m_axi_rx_tlast : out STD_LOGIC;
    rxp : in STD_LOGIC;
    rxn : in STD_LOGIC;
    txp : out STD_LOGIC;
    txn : out STD_LOGIC;
    gt_refclk1_p : in STD_LOGIC;
    gt_refclk1_n : in STD_LOGIC;
    gt_refclk1_out : out STD_LOGIC;
    frame_err : out STD_LOGIC;
    hard_err : out STD_LOGIC;
    soft_err : out STD_LOGIC;
    lane_up : out STD_LOGIC;
    channel_up : out STD_LOGIC;
    crc_pass_fail_n : out STD_LOGIC;
    crc_valid : out STD_LOGIC;
    user_clk_out : out STD_LOGIC;
    sync_clk_out : out STD_LOGIC;
    gt_reset : in STD_LOGIC;
    reset : in STD_LOGIC;
    sys_reset_out : out STD_LOGIC;
    gt_reset_out : out STD_LOGIC;
    power_down : in STD_LOGIC;
    loopback : in STD_LOGIC_VECTOR ( 2 downto 0 );
    tx_lock : out STD_LOGIC;
    init_clk_in : in STD_LOGIC;
    tx_resetdone_out : out STD_LOGIC;
    rx_resetdone_out : out STD_LOGIC;
    link_reset_out : out STD_LOGIC;
    gt0_drpaddr : in STD_LOGIC_VECTOR ( 8 downto 0 );
    gt0_drpdi : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_drpdo : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_drpen : in STD_LOGIC;
    gt0_drprdy : out STD_LOGIC;
    gt0_drpwe : in STD_LOGIC;
    gt_powergood : out STD_LOGIC_VECTOR ( 0 to 0 );
    pll_not_locked_out : out STD_LOGIC
  );

end aurora_8b10b_1p25g;

architecture stub of aurora_8b10b_1p25g is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "s_axi_tx_tdata[0:31],s_axi_tx_tkeep[0:3],s_axi_tx_tvalid,s_axi_tx_tlast,s_axi_tx_tready,m_axi_rx_tdata[0:31],m_axi_rx_tkeep[0:3],m_axi_rx_tvalid,m_axi_rx_tlast,rxp,rxn,txp,txn,gt_refclk1_p,gt_refclk1_n,gt_refclk1_out,frame_err,hard_err,soft_err,lane_up,channel_up,crc_pass_fail_n,crc_valid,user_clk_out,sync_clk_out,gt_reset,reset,sys_reset_out,gt_reset_out,power_down,loopback[2:0],tx_lock,init_clk_in,tx_resetdone_out,rx_resetdone_out,link_reset_out,gt0_drpaddr[8:0],gt0_drpdi[15:0],gt0_drpdo[15:0],gt0_drpen,gt0_drprdy,gt0_drpwe,gt_powergood[0:0],pll_not_locked_out";
begin
end;
