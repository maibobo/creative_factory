-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
-- Date        : Sun Sep 20 15:47:07 2026
-- Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
-- Design      : design_1_INFO_EXCH_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku040-ffva1156-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity design_1_INFO_EXCH_0_0 is
  Port ( 
    CPU_WR_DONE_EVENT : in STD_LOGIC;
    FPGA_TEMP_W : in STD_LOGIC_VECTOR ( 31 downto 0 );
    INT_STATE_W : in STD_LOGIC_VECTOR ( 0 to 0 );
    CPU_REC_STATE_W : in STD_LOGIC_VECTOR ( 0 to 0 );
    FPGA_CPU_START_ADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    FPGA_CPU_LEN : in STD_LOGIC_VECTOR ( 31 downto 0 );
    CPU_WR_DONE_resp : in STD_LOGIC_VECTOR ( 0 to 0 );
    DDR_STATUS_W : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RX_READY_BLOCKS : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RX_HEAD_SEQ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RX_DROPPED_FRAMES : in STD_LOGIC_VECTOR ( 31 downto 0 );
    r_INT_STATE : out STD_LOGIC;
    r_CLEAR_INTER : out STD_LOGIC;
    r_CPU_REC_STATE : out STD_LOGIC;
    r_RD_START : out STD_LOGIC;
    r_CPU_FPGA_START_ADDR : out STD_LOGIC_VECTOR ( 31 downto 0 );
    r_CPU_FPGA_LEN : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_ACLK : in STD_LOGIC;
    S_AXI_ARESETN : in STD_LOGIC;
    S_AXI_AWADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_AWPROT : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_AWVALID : in STD_LOGIC;
    S_AXI_AWREADY : out STD_LOGIC;
    S_AXI_WDATA : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_WSTRB : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_WVALID : in STD_LOGIC;
    S_AXI_WREADY : out STD_LOGIC;
    S_AXI_BRESP : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_BVALID : out STD_LOGIC;
    S_AXI_BREADY : in STD_LOGIC;
    S_AXI_ARADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_ARPROT : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_ARVALID : in STD_LOGIC;
    S_AXI_ARREADY : out STD_LOGIC;
    S_AXI_RDATA : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_RRESP : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_RVALID : out STD_LOGIC;
    S_AXI_RREADY : in STD_LOGIC
  );

end design_1_INFO_EXCH_0_0;

architecture stub of design_1_INFO_EXCH_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "CPU_WR_DONE_EVENT,FPGA_TEMP_W[31:0],INT_STATE_W[0:0],CPU_REC_STATE_W[0:0],FPGA_CPU_START_ADDR[31:0],FPGA_CPU_LEN[31:0],CPU_WR_DONE_resp[0:0],DDR_STATUS_W[31:0],RX_READY_BLOCKS[31:0],RX_HEAD_SEQ[31:0],RX_DROPPED_FRAMES[31:0],r_INT_STATE,r_CLEAR_INTER,r_CPU_REC_STATE,r_RD_START,r_CPU_FPGA_START_ADDR[31:0],r_CPU_FPGA_LEN[31:0],S_AXI_ACLK,S_AXI_ARESETN,S_AXI_AWADDR[31:0],S_AXI_AWPROT[2:0],S_AXI_AWVALID,S_AXI_AWREADY,S_AXI_WDATA[31:0],S_AXI_WSTRB[3:0],S_AXI_WVALID,S_AXI_WREADY,S_AXI_BRESP[1:0],S_AXI_BVALID,S_AXI_BREADY,S_AXI_ARADDR[31:0],S_AXI_ARPROT[2:0],S_AXI_ARVALID,S_AXI_ARREADY,S_AXI_RDATA[31:0],S_AXI_RRESP[1:0],S_AXI_RVALID,S_AXI_RREADY";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "INFO_EXCH,Vivado 2020.2";
begin
end;
