-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
-- Date        : Sun Sep 20 15:47:07 2026
-- Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
-- Design      : design_1_CONV_DMA_0_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xcku040-ffva1156-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_CONV_DMA_0_0_CONV_DMA is
  port (
    Q : out STD_LOGIC_VECTOR ( 63 downto 0 );
    \wa_reg[63]_0\ : out STD_LOGIC_VECTOR ( 63 downto 0 );
    fdma_wdone : out STD_LOGIC;
    fdma_werror : out STD_LOGIC;
    M_AXI_AWVALID : out STD_LOGIC;
    fdma_wvalid : out STD_LOGIC;
    M_AXI_WLAST : out STD_LOGIC;
    M_AXI_WVALID : out STD_LOGIC;
    M_AXI_AWLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_BREADY : out STD_LOGIC;
    fdma_wbusy : out STD_LOGIC;
    M_AXI_RVALID_0 : out STD_LOGIC;
    fdma_rbusy : out STD_LOGIC;
    M_AXI_ARVALID : out STD_LOGIC;
    M_AXI_ARLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_RREADY : out STD_LOGIC;
    fdma_rareq : in STD_LOGIC;
    M_AXI_ACLK : in STD_LOGIC;
    M_AXI_BVALID : in STD_LOGIC;
    fdma_wareq : in STD_LOGIC;
    fdma_waddr : in STD_LOGIC_VECTOR ( 63 downto 0 );
    fdma_wsize : in STD_LOGIC_VECTOR ( 15 downto 0 );
    fdma_wready : in STD_LOGIC;
    M_AXI_WREADY : in STD_LOGIC;
    M_AXI_BID : in STD_LOGIC_VECTOR ( 0 to 0 );
    M_AXI_BRESP : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_ARREADY : in STD_LOGIC;
    M_AXI_RVALID : in STD_LOGIC;
    fdma_rready : in STD_LOGIC;
    fdma_rsize : in STD_LOGIC_VECTOR ( 15 downto 0 );
    fdma_raddr : in STD_LOGIC_VECTOR ( 63 downto 0 );
    M_AXI_ARESETN : in STD_LOGIC;
    M_AXI_AWREADY : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of design_1_CONV_DMA_0_0_CONV_DMA : entity is "CONV_DMA";
end design_1_CONV_DMA_0_0_CONV_DMA;

architecture STRUCTURE of design_1_CONV_DMA_0_0_CONV_DMA is
  signal A : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \FSM_sequential_read_curr_st[0]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_sequential_read_curr_st[1]_i_2_n_0\ : STD_LOGIC;
  signal \FSM_sequential_write_curr_st[0]_i_1_n_0\ : STD_LOGIC;
  signal \FSM_sequential_write_curr_st[1]_i_2_n_0\ : STD_LOGIC;
  signal \FSM_sequential_write_curr_st[1]_i_3_n_0\ : STD_LOGIC;
  signal \M_AXI_ARLEN[7]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \M_AXI_AWLEN[7]_INST_0_i_1_n_0\ : STD_LOGIC;
  signal \^m_axi_rvalid_0\ : STD_LOGIC;
  signal \^m_axi_wlast\ : STD_LOGIC;
  signal M_AXI_WLAST_INST_0_i_1_n_0 : STD_LOGIC;
  signal M_AXI_WLAST_INST_0_i_2_n_0 : STD_LOGIC;
  signal M_AXI_WLAST_INST_0_i_3_n_0 : STD_LOGIC;
  signal M_AXI_WLAST_INST_0_i_4_n_0 : STD_LOGIC;
  signal M_AXI_WLAST_INST_0_i_5_n_0 : STD_LOGIC;
  signal M_AXI_WLAST_INST_0_i_6_n_0 : STD_LOGIC;
  signal \^m_axi_wvalid\ : STD_LOGIC;
  signal \^q\ : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal aw_pending_i_1_n_0 : STD_LOGIC;
  signal aw_pending_reg_n_0 : STD_LOGIC;
  signal fdma_wdone_i_10_n_0 : STD_LOGIC;
  signal fdma_wdone_i_11_n_0 : STD_LOGIC;
  signal fdma_wdone_i_12_n_0 : STD_LOGIC;
  signal fdma_wdone_i_13_n_0 : STD_LOGIC;
  signal fdma_wdone_i_1_n_0 : STD_LOGIC;
  signal fdma_wdone_i_2_n_0 : STD_LOGIC;
  signal fdma_wdone_i_4_n_0 : STD_LOGIC;
  signal fdma_wdone_i_5_n_0 : STD_LOGIC;
  signal fdma_wdone_i_6_n_0 : STD_LOGIC;
  signal fdma_wdone_i_7_n_0 : STD_LOGIC;
  signal fdma_wdone_i_8_n_0 : STD_LOGIC;
  signal fdma_wdone_i_9_n_0 : STD_LOGIC;
  signal \^fdma_werror\ : STD_LOGIC;
  signal fdma_werror_i_1_n_0 : STD_LOGIC;
  signal fdma_werror_i_2_n_0 : STD_LOGIC;
  signal in10 : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal in12 : STD_LOGIC_VECTOR ( 63 downto 2 );
  signal in14 : STD_LOGIC_VECTOR ( 63 downto 2 );
  signal p_4_in : STD_LOGIC;
  signal ra : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal \ra[17]_i_3_n_0\ : STD_LOGIC;
  signal \ra[17]_i_4_n_0\ : STD_LOGIC;
  signal \ra[63]_i_10_n_0\ : STD_LOGIC;
  signal \ra[63]_i_11_n_0\ : STD_LOGIC;
  signal \ra[63]_i_12_n_0\ : STD_LOGIC;
  signal \ra[63]_i_13_n_0\ : STD_LOGIC;
  signal \ra[63]_i_14_n_0\ : STD_LOGIC;
  signal \ra[63]_i_15_n_0\ : STD_LOGIC;
  signal \ra[63]_i_16_n_0\ : STD_LOGIC;
  signal \ra[63]_i_17_n_0\ : STD_LOGIC;
  signal \ra[63]_i_18_n_0\ : STD_LOGIC;
  signal \ra[63]_i_19_n_0\ : STD_LOGIC;
  signal \ra[63]_i_20_n_0\ : STD_LOGIC;
  signal \ra[63]_i_4_n_0\ : STD_LOGIC;
  signal \ra[63]_i_5_n_0\ : STD_LOGIC;
  signal \ra[63]_i_7_n_0\ : STD_LOGIC;
  signal \ra[63]_i_8_n_0\ : STD_LOGIC;
  signal \ra[63]_i_9_n_0\ : STD_LOGIC;
  signal \ra[9]_i_3_n_0\ : STD_LOGIC;
  signal \ra[9]_i_4_n_0\ : STD_LOGIC;
  signal \ra[9]_i_5_n_0\ : STD_LOGIC;
  signal \ra[9]_i_6_n_0\ : STD_LOGIC;
  signal \ra[9]_i_7_n_0\ : STD_LOGIC;
  signal \ra[9]_i_8_n_0\ : STD_LOGIC;
  signal \ra[9]_i_9_n_0\ : STD_LOGIC;
  signal ra_2 : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[17]_i_2_n_7\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[25]_i_2_n_7\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[33]_i_2_n_7\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[41]_i_2_n_7\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[49]_i_2_n_7\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[57]_i_2_n_7\ : STD_LOGIC;
  signal \ra_reg[63]_i_6_n_3\ : STD_LOGIC;
  signal \ra_reg[63]_i_6_n_4\ : STD_LOGIC;
  signal \ra_reg[63]_i_6_n_5\ : STD_LOGIC;
  signal \ra_reg[63]_i_6_n_6\ : STD_LOGIC;
  signal \ra_reg[63]_i_6_n_7\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_0\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_1\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_2\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_3\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_4\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_5\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_6\ : STD_LOGIC;
  signal \ra_reg[9]_i_2_n_7\ : STD_LOGIC;
  signal rb : STD_LOGIC;
  signal \rb[0]_i_1_n_0\ : STD_LOGIC;
  signal \rb[0]_i_2_n_0\ : STD_LOGIC;
  signal \rb[1]_i_1_n_0\ : STD_LOGIC;
  signal \rb[1]_i_2_n_0\ : STD_LOGIC;
  signal \rb[2]_i_1_n_0\ : STD_LOGIC;
  signal \rb[2]_i_2_n_0\ : STD_LOGIC;
  signal \rb[3]_i_1_n_0\ : STD_LOGIC;
  signal \rb[4]_i_1_n_0\ : STD_LOGIC;
  signal \rb[4]_i_2_n_0\ : STD_LOGIC;
  signal \rb[5]_i_1_n_0\ : STD_LOGIC;
  signal \rb[5]_i_2_n_0\ : STD_LOGIC;
  signal \rb[6]_i_1_n_0\ : STD_LOGIC;
  signal \rb[6]_i_2_n_0\ : STD_LOGIC;
  signal \rb[7]_i_1_n_0\ : STD_LOGIC;
  signal \rb[7]_i_2_n_0\ : STD_LOGIC;
  signal \rb[8]_i_2_n_0\ : STD_LOGIC;
  signal \rb[8]_i_3_n_0\ : STD_LOGIC;
  signal \rb[8]_i_4_n_0\ : STD_LOGIC;
  signal \rb[8]_i_5_n_0\ : STD_LOGIC;
  signal \rb[8]_i_6_n_0\ : STD_LOGIC;
  signal \rb[8]_i_7_n_0\ : STD_LOGIC;
  signal \rb[8]_i_8_n_0\ : STD_LOGIC;
  signal \rb_reg_n_0_[0]\ : STD_LOGIC;
  signal \rb_reg_n_0_[1]\ : STD_LOGIC;
  signal \rb_reg_n_0_[2]\ : STD_LOGIC;
  signal \rb_reg_n_0_[3]\ : STD_LOGIC;
  signal \rb_reg_n_0_[4]\ : STD_LOGIC;
  signal \rb_reg_n_0_[5]\ : STD_LOGIC;
  signal \rb_reg_n_0_[6]\ : STD_LOGIC;
  signal \rb_reg_n_0_[7]\ : STD_LOGIC;
  signal \rb_reg_n_0_[8]\ : STD_LOGIC;
  signal rbeat : STD_LOGIC_VECTOR ( 0 to 0 );
  signal \rbeat[1]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[2]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[3]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[4]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[5]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[5]_i_2_n_0\ : STD_LOGIC;
  signal \rbeat[6]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[7]_i_1_n_0\ : STD_LOGIC;
  signal \rbeat[8]_i_2_n_0\ : STD_LOGIC;
  signal \rbeat[8]_i_3_n_0\ : STD_LOGIC;
  signal rbeat_3 : STD_LOGIC;
  signal \rbeat_reg_n_0_[0]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[1]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[2]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[3]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[4]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[5]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[6]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[7]\ : STD_LOGIC;
  signal \rbeat_reg_n_0_[8]\ : STD_LOGIC;
  signal read_curr_st : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \read_curr_st[0]_i_1_n_0\ : STD_LOGIC;
  signal \read_curr_st[1]_i_1_n_0\ : STD_LOGIC;
  signal \read_curr_st__0\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal read_next_st : STD_LOGIC;
  signal \read_next_st0__16\ : STD_LOGIC;
  signal rleft : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal \rleft[15]_i_10_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_3_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_4_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_5_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_6_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_7_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_8_n_0\ : STD_LOGIC;
  signal \rleft[15]_i_9_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_10_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_3_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_4_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_5_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_6_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_7_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_8_n_0\ : STD_LOGIC;
  signal \rleft[7]_i_9_n_0\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_1\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_10\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_11\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_12\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_13\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_14\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_15\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_2\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_3\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_4\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_5\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_6\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_7\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_8\ : STD_LOGIC;
  signal \rleft_reg[15]_i_2_n_9\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_0\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_1\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_10\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_11\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_12\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_13\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_14\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_15\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_2\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_3\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_4\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_5\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_6\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_7\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_8\ : STD_LOGIC;
  signal \rleft_reg[7]_i_2_n_9\ : STD_LOGIC;
  signal \rleft_reg_n_0_[0]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[10]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[11]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[12]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[13]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[14]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[15]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[1]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[2]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[3]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[4]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[5]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[6]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[7]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[8]\ : STD_LOGIC;
  signal \rleft_reg_n_0_[9]\ : STD_LOGIC;
  signal \update_wb.available1\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_1\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_2\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_3\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_4\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_5\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_6\ : STD_LOGIC;
  signal \update_wb.available1_carry__0_n_7\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_10__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_10_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_11__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_11_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_12__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_12_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_13__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_13_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_14__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_14_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_15__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_15_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_16__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_16_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_17_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_1__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_1_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_2__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_2_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_3__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_3_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_4__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_4_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_5__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_5_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_6__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_6_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_7__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_7_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_8__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_8_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_9__0_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_i_9_n_0\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_1\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_2\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_3\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_4\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_5\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_6\ : STD_LOGIC;
  signal \update_wb.available1_carry_n_7\ : STD_LOGIC;
  signal \update_wb.available3\ : STD_LOGIC_VECTOR ( 10 downto 4 );
  signal w_pending_i_1_n_0 : STD_LOGIC;
  signal w_pending_reg_n_0 : STD_LOGIC;
  signal wa : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal \wa[17]_i_3_n_0\ : STD_LOGIC;
  signal \wa[17]_i_4_n_0\ : STD_LOGIC;
  signal \wa[63]_i_3_n_0\ : STD_LOGIC;
  signal \wa[9]_i_3_n_0\ : STD_LOGIC;
  signal \wa[9]_i_4_n_0\ : STD_LOGIC;
  signal \wa[9]_i_5_n_0\ : STD_LOGIC;
  signal \wa[9]_i_6_n_0\ : STD_LOGIC;
  signal \wa[9]_i_7_n_0\ : STD_LOGIC;
  signal \wa[9]_i_8_n_0\ : STD_LOGIC;
  signal \wa[9]_i_9_n_0\ : STD_LOGIC;
  signal wa_0 : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[17]_i_2_n_7\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[25]_i_2_n_7\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[33]_i_2_n_7\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[41]_i_2_n_7\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[49]_i_2_n_7\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[57]_i_2_n_7\ : STD_LOGIC;
  signal \^wa_reg[63]_0\ : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal \wa_reg[63]_i_4_n_3\ : STD_LOGIC;
  signal \wa_reg[63]_i_4_n_4\ : STD_LOGIC;
  signal \wa_reg[63]_i_4_n_5\ : STD_LOGIC;
  signal \wa_reg[63]_i_4_n_6\ : STD_LOGIC;
  signal \wa_reg[63]_i_4_n_7\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_0\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_1\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_2\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_3\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_4\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_5\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_6\ : STD_LOGIC;
  signal \wa_reg[9]_i_2_n_7\ : STD_LOGIC;
  signal wb : STD_LOGIC;
  signal \wb[0]_i_2_n_0\ : STD_LOGIC;
  signal \wb[2]_i_2_n_0\ : STD_LOGIC;
  signal \wb[4]_i_2_n_0\ : STD_LOGIC;
  signal \wb[6]_i_2_n_0\ : STD_LOGIC;
  signal \wb[8]_i_3_n_0\ : STD_LOGIC;
  signal \wb[8]_i_4_n_0\ : STD_LOGIC;
  signal \wb[8]_i_5_n_0\ : STD_LOGIC;
  signal \wb[8]_i_6_n_0\ : STD_LOGIC;
  signal \wb[8]_i_7_n_0\ : STD_LOGIC;
  signal \wb_reg_n_0_[0]\ : STD_LOGIC;
  signal \wb_reg_n_0_[1]\ : STD_LOGIC;
  signal \wb_reg_n_0_[2]\ : STD_LOGIC;
  signal \wb_reg_n_0_[3]\ : STD_LOGIC;
  signal \wb_reg_n_0_[4]\ : STD_LOGIC;
  signal \wb_reg_n_0_[5]\ : STD_LOGIC;
  signal \wb_reg_n_0_[6]\ : STD_LOGIC;
  signal \wb_reg_n_0_[7]\ : STD_LOGIC;
  signal \wb_reg_n_0_[8]\ : STD_LOGIC;
  signal wbeat : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal \wbeat[5]_i_2_n_0\ : STD_LOGIC;
  signal \wbeat[8]_i_3_n_0\ : STD_LOGIC;
  signal wbeat_1 : STD_LOGIC;
  signal \wbeat_reg_n_0_[0]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[1]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[2]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[3]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[4]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[5]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[6]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[7]\ : STD_LOGIC;
  signal \wbeat_reg_n_0_[8]\ : STD_LOGIC;
  signal wleft : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal \wleft[15]_i_10_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_3_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_4_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_5_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_6_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_7_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_8_n_0\ : STD_LOGIC;
  signal \wleft[15]_i_9_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_10_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_3_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_4_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_5_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_6_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_7_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_8_n_0\ : STD_LOGIC;
  signal \wleft[7]_i_9_n_0\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_1\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_2\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_3\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_4\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_5\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_6\ : STD_LOGIC;
  signal \wleft_reg[15]_i_2_n_7\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_0\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_1\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_2\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_3\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_4\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_5\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_6\ : STD_LOGIC;
  signal \wleft_reg[7]_i_2_n_7\ : STD_LOGIC;
  signal \wleft_reg_n_0_[0]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[10]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[11]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[12]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[13]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[14]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[15]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[1]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[2]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[3]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[4]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[5]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[6]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[7]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[8]\ : STD_LOGIC;
  signal \wleft_reg_n_0_[9]\ : STD_LOGIC;
  signal write_curr_st : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal \write_curr_st[0]_i_1_n_0\ : STD_LOGIC;
  signal \write_curr_st[1]_i_1_n_0\ : STD_LOGIC;
  signal \write_curr_st__0\ : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal write_next_st : STD_LOGIC;
  signal \write_next_st1__23\ : STD_LOGIC;
  signal \NLW_ra_reg[63]_i_6_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 5 );
  signal \NLW_ra_reg[63]_i_6_O_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 6 );
  signal \NLW_rleft_reg[15]_i_2_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 to 7 );
  signal \NLW_update_wb.available1_carry_O_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_update_wb.available1_carry__0_O_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal \NLW_wa_reg[63]_i_4_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 5 );
  signal \NLW_wa_reg[63]_i_4_O_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 downto 6 );
  signal \NLW_wleft_reg[15]_i_2_CO_UNCONNECTED\ : STD_LOGIC_VECTOR ( 7 to 7 );
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \FSM_sequential_read_curr_st[0]_i_1\ : label is "soft_lutpair72";
  attribute SOFT_HLUTNM of \FSM_sequential_read_curr_st[1]_i_2\ : label is "soft_lutpair72";
  attribute FSM_ENCODED_STATES : string;
  attribute FSM_ENCODED_STATES of \FSM_sequential_read_curr_st_reg[0]\ : label is "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01";
  attribute FSM_ENCODED_STATES of \FSM_sequential_read_curr_st_reg[1]\ : label is "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01";
  attribute SOFT_HLUTNM of \FSM_sequential_write_curr_st[0]_i_1\ : label is "soft_lutpair16";
  attribute SOFT_HLUTNM of \FSM_sequential_write_curr_st[1]_i_2\ : label is "soft_lutpair28";
  attribute SOFT_HLUTNM of \FSM_sequential_write_curr_st[1]_i_3\ : label is "soft_lutpair16";
  attribute FSM_ENCODED_STATES of \FSM_sequential_write_curr_st_reg[0]\ : label is "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01";
  attribute FSM_ENCODED_STATES of \FSM_sequential_write_curr_st_reg[1]\ : label is "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01";
  attribute SOFT_HLUTNM of \M_AXI_ARLEN[1]_INST_0\ : label is "soft_lutpair71";
  attribute SOFT_HLUTNM of \M_AXI_ARLEN[2]_INST_0\ : label is "soft_lutpair71";
  attribute SOFT_HLUTNM of \M_AXI_ARLEN[3]_INST_0\ : label is "soft_lutpair20";
  attribute SOFT_HLUTNM of \M_AXI_ARLEN[4]_INST_0\ : label is "soft_lutpair11";
  attribute SOFT_HLUTNM of \M_AXI_ARLEN[6]_INST_0\ : label is "soft_lutpair70";
  attribute SOFT_HLUTNM of \M_AXI_ARLEN[7]_INST_0\ : label is "soft_lutpair70";
  attribute SOFT_HLUTNM of M_AXI_ARVALID_INST_0 : label is "soft_lutpair113";
  attribute SOFT_HLUTNM of \M_AXI_AWLEN[1]_INST_0\ : label is "soft_lutpair25";
  attribute SOFT_HLUTNM of \M_AXI_AWLEN[2]_INST_0\ : label is "soft_lutpair15";
  attribute SOFT_HLUTNM of \M_AXI_AWLEN[3]_INST_0\ : label is "soft_lutpair15";
  attribute SOFT_HLUTNM of \M_AXI_AWLEN[4]_INST_0\ : label is "soft_lutpair5";
  attribute SOFT_HLUTNM of \M_AXI_AWLEN[7]_INST_0_i_1\ : label is "soft_lutpair25";
  attribute SOFT_HLUTNM of M_AXI_AWVALID_INST_0 : label is "soft_lutpair24";
  attribute SOFT_HLUTNM of M_AXI_BREADY_INST_0 : label is "soft_lutpair26";
  attribute SOFT_HLUTNM of M_AXI_RREADY_INST_0 : label is "soft_lutpair19";
  attribute SOFT_HLUTNM of M_AXI_WLAST_INST_0_i_2 : label is "soft_lutpair5";
  attribute SOFT_HLUTNM of M_AXI_WVALID_INST_0 : label is "soft_lutpair4";
  attribute SOFT_HLUTNM of fdma_rbusy_INST_0 : label is "soft_lutpair73";
  attribute SOFT_HLUTNM of fdma_rvalid_INST_0 : label is "soft_lutpair19";
  attribute SOFT_HLUTNM of fdma_werror_i_3 : label is "soft_lutpair27";
  attribute SOFT_HLUTNM of fdma_wvalid_INST_0 : label is "soft_lutpair4";
  attribute SOFT_HLUTNM of \ra[0]_i_1\ : label is "soft_lutpair23";
  attribute SOFT_HLUTNM of \ra[10]_i_1\ : label is "soft_lutpair86";
  attribute SOFT_HLUTNM of \ra[11]_i_1\ : label is "soft_lutpair87";
  attribute SOFT_HLUTNM of \ra[12]_i_1\ : label is "soft_lutpair87";
  attribute SOFT_HLUTNM of \ra[13]_i_1\ : label is "soft_lutpair88";
  attribute SOFT_HLUTNM of \ra[14]_i_1\ : label is "soft_lutpair88";
  attribute SOFT_HLUTNM of \ra[15]_i_1\ : label is "soft_lutpair89";
  attribute SOFT_HLUTNM of \ra[16]_i_1\ : label is "soft_lutpair89";
  attribute SOFT_HLUTNM of \ra[17]_i_1\ : label is "soft_lutpair90";
  attribute SOFT_HLUTNM of \ra[18]_i_1\ : label is "soft_lutpair90";
  attribute SOFT_HLUTNM of \ra[19]_i_1\ : label is "soft_lutpair91";
  attribute SOFT_HLUTNM of \ra[1]_i_1\ : label is "soft_lutpair82";
  attribute SOFT_HLUTNM of \ra[20]_i_1\ : label is "soft_lutpair91";
  attribute SOFT_HLUTNM of \ra[21]_i_1\ : label is "soft_lutpair92";
  attribute SOFT_HLUTNM of \ra[22]_i_1\ : label is "soft_lutpair92";
  attribute SOFT_HLUTNM of \ra[23]_i_1\ : label is "soft_lutpair93";
  attribute SOFT_HLUTNM of \ra[24]_i_1\ : label is "soft_lutpair93";
  attribute SOFT_HLUTNM of \ra[25]_i_1\ : label is "soft_lutpair94";
  attribute SOFT_HLUTNM of \ra[26]_i_1\ : label is "soft_lutpair94";
  attribute SOFT_HLUTNM of \ra[27]_i_1\ : label is "soft_lutpair95";
  attribute SOFT_HLUTNM of \ra[28]_i_1\ : label is "soft_lutpair95";
  attribute SOFT_HLUTNM of \ra[29]_i_1\ : label is "soft_lutpair96";
  attribute SOFT_HLUTNM of \ra[2]_i_1\ : label is "soft_lutpair82";
  attribute SOFT_HLUTNM of \ra[30]_i_1\ : label is "soft_lutpair96";
  attribute SOFT_HLUTNM of \ra[31]_i_1\ : label is "soft_lutpair97";
  attribute SOFT_HLUTNM of \ra[32]_i_1\ : label is "soft_lutpair97";
  attribute SOFT_HLUTNM of \ra[33]_i_1\ : label is "soft_lutpair98";
  attribute SOFT_HLUTNM of \ra[34]_i_1\ : label is "soft_lutpair98";
  attribute SOFT_HLUTNM of \ra[35]_i_1\ : label is "soft_lutpair99";
  attribute SOFT_HLUTNM of \ra[36]_i_1\ : label is "soft_lutpair99";
  attribute SOFT_HLUTNM of \ra[37]_i_1\ : label is "soft_lutpair100";
  attribute SOFT_HLUTNM of \ra[38]_i_1\ : label is "soft_lutpair100";
  attribute SOFT_HLUTNM of \ra[39]_i_1\ : label is "soft_lutpair101";
  attribute SOFT_HLUTNM of \ra[3]_i_1\ : label is "soft_lutpair83";
  attribute SOFT_HLUTNM of \ra[40]_i_1\ : label is "soft_lutpair101";
  attribute SOFT_HLUTNM of \ra[41]_i_1\ : label is "soft_lutpair102";
  attribute SOFT_HLUTNM of \ra[42]_i_1\ : label is "soft_lutpair102";
  attribute SOFT_HLUTNM of \ra[43]_i_1\ : label is "soft_lutpair103";
  attribute SOFT_HLUTNM of \ra[44]_i_1\ : label is "soft_lutpair103";
  attribute SOFT_HLUTNM of \ra[45]_i_1\ : label is "soft_lutpair104";
  attribute SOFT_HLUTNM of \ra[46]_i_1\ : label is "soft_lutpair104";
  attribute SOFT_HLUTNM of \ra[47]_i_1\ : label is "soft_lutpair105";
  attribute SOFT_HLUTNM of \ra[48]_i_1\ : label is "soft_lutpair105";
  attribute SOFT_HLUTNM of \ra[49]_i_1\ : label is "soft_lutpair106";
  attribute SOFT_HLUTNM of \ra[4]_i_1\ : label is "soft_lutpair83";
  attribute SOFT_HLUTNM of \ra[50]_i_1\ : label is "soft_lutpair106";
  attribute SOFT_HLUTNM of \ra[51]_i_1\ : label is "soft_lutpair107";
  attribute SOFT_HLUTNM of \ra[52]_i_1\ : label is "soft_lutpair107";
  attribute SOFT_HLUTNM of \ra[53]_i_1\ : label is "soft_lutpair108";
  attribute SOFT_HLUTNM of \ra[54]_i_1\ : label is "soft_lutpair108";
  attribute SOFT_HLUTNM of \ra[55]_i_1\ : label is "soft_lutpair109";
  attribute SOFT_HLUTNM of \ra[56]_i_1\ : label is "soft_lutpair109";
  attribute SOFT_HLUTNM of \ra[57]_i_1\ : label is "soft_lutpair110";
  attribute SOFT_HLUTNM of \ra[58]_i_1\ : label is "soft_lutpair110";
  attribute SOFT_HLUTNM of \ra[59]_i_1\ : label is "soft_lutpair111";
  attribute SOFT_HLUTNM of \ra[5]_i_1\ : label is "soft_lutpair84";
  attribute SOFT_HLUTNM of \ra[60]_i_1\ : label is "soft_lutpair111";
  attribute SOFT_HLUTNM of \ra[61]_i_1\ : label is "soft_lutpair112";
  attribute SOFT_HLUTNM of \ra[62]_i_1\ : label is "soft_lutpair112";
  attribute SOFT_HLUTNM of \ra[63]_i_15\ : label is "soft_lutpair20";
  attribute SOFT_HLUTNM of \ra[63]_i_17\ : label is "soft_lutpair11";
  attribute SOFT_HLUTNM of \ra[6]_i_1\ : label is "soft_lutpair84";
  attribute SOFT_HLUTNM of \ra[7]_i_1\ : label is "soft_lutpair85";
  attribute SOFT_HLUTNM of \ra[8]_i_1\ : label is "soft_lutpair85";
  attribute SOFT_HLUTNM of \ra[9]_i_1\ : label is "soft_lutpair86";
  attribute ADDER_THRESHOLD : integer;
  attribute ADDER_THRESHOLD of \ra_reg[17]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[25]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[33]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[41]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[49]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[57]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[63]_i_6\ : label is 35;
  attribute ADDER_THRESHOLD of \ra_reg[9]_i_2\ : label is 35;
  attribute SOFT_HLUTNM of \rb[0]_i_2\ : label is "soft_lutpair14";
  attribute SOFT_HLUTNM of \rb[1]_i_2\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \rb[3]_i_1\ : label is "soft_lutpair12";
  attribute SOFT_HLUTNM of \rb[5]_i_2\ : label is "soft_lutpair13";
  attribute SOFT_HLUTNM of \rb[6]_i_2\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \rb[8]_i_6\ : label is "soft_lutpair3";
  attribute SOFT_HLUTNM of \rb[8]_i_7\ : label is "soft_lutpair13";
  attribute SOFT_HLUTNM of \rb[8]_i_8\ : label is "soft_lutpair14";
  attribute SOFT_HLUTNM of \rbeat[0]_i_1\ : label is "soft_lutpair21";
  attribute SOFT_HLUTNM of \rbeat[1]_i_1\ : label is "soft_lutpair21";
  attribute SOFT_HLUTNM of \rbeat[2]_i_1\ : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \rbeat[3]_i_1\ : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \rbeat[5]_i_1\ : label is "soft_lutpair22";
  attribute SOFT_HLUTNM of \rbeat[6]_i_1\ : label is "soft_lutpair22";
  attribute SOFT_HLUTNM of \rbeat[7]_i_1\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \rbeat[8]_i_2\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \read_curr_st[0]_i_1\ : label is "soft_lutpair73";
  attribute SOFT_HLUTNM of \read_curr_st[1]_i_1\ : label is "soft_lutpair113";
  attribute SOFT_HLUTNM of \rleft[0]_i_1\ : label is "soft_lutpair74";
  attribute SOFT_HLUTNM of \rleft[10]_i_1\ : label is "soft_lutpair79";
  attribute SOFT_HLUTNM of \rleft[11]_i_1\ : label is "soft_lutpair79";
  attribute SOFT_HLUTNM of \rleft[12]_i_1\ : label is "soft_lutpair80";
  attribute SOFT_HLUTNM of \rleft[13]_i_1\ : label is "soft_lutpair80";
  attribute SOFT_HLUTNM of \rleft[14]_i_1\ : label is "soft_lutpair81";
  attribute SOFT_HLUTNM of \rleft[15]_i_1\ : label is "soft_lutpair81";
  attribute SOFT_HLUTNM of \rleft[1]_i_1\ : label is "soft_lutpair74";
  attribute SOFT_HLUTNM of \rleft[2]_i_1\ : label is "soft_lutpair75";
  attribute SOFT_HLUTNM of \rleft[3]_i_1\ : label is "soft_lutpair75";
  attribute SOFT_HLUTNM of \rleft[4]_i_1\ : label is "soft_lutpair76";
  attribute SOFT_HLUTNM of \rleft[5]_i_1\ : label is "soft_lutpair76";
  attribute SOFT_HLUTNM of \rleft[6]_i_1\ : label is "soft_lutpair77";
  attribute SOFT_HLUTNM of \rleft[7]_i_1\ : label is "soft_lutpair77";
  attribute SOFT_HLUTNM of \rleft[8]_i_1\ : label is "soft_lutpair78";
  attribute SOFT_HLUTNM of \rleft[9]_i_1\ : label is "soft_lutpair78";
  attribute ADDER_THRESHOLD of \rleft_reg[15]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \rleft_reg[7]_i_2\ : label is 35;
  attribute COMPARATOR_THRESHOLD : integer;
  attribute COMPARATOR_THRESHOLD of \update_wb.available1_carry\ : label is 11;
  attribute COMPARATOR_THRESHOLD of \update_wb.available1_carry__0\ : label is 11;
  attribute SOFT_HLUTNM of \update_wb.available1_carry_i_14\ : label is "soft_lutpair6";
  attribute SOFT_HLUTNM of \update_wb.available1_carry_i_15\ : label is "soft_lutpair8";
  attribute SOFT_HLUTNM of \update_wb.available1_carry_i_15__0\ : label is "soft_lutpair12";
  attribute SOFT_HLUTNM of \update_wb.available1_carry_i_16\ : label is "soft_lutpair17";
  attribute SOFT_HLUTNM of \update_wb.available1_carry_i_16__0\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \update_wb.available1_carry_i_17\ : label is "soft_lutpair23";
  attribute SOFT_HLUTNM of \wa[0]_i_1\ : label is "soft_lutpair68";
  attribute SOFT_HLUTNM of \wa[10]_i_1\ : label is "soft_lutpair63";
  attribute SOFT_HLUTNM of \wa[11]_i_1\ : label is "soft_lutpair62";
  attribute SOFT_HLUTNM of \wa[12]_i_1\ : label is "soft_lutpair62";
  attribute SOFT_HLUTNM of \wa[13]_i_1\ : label is "soft_lutpair61";
  attribute SOFT_HLUTNM of \wa[14]_i_1\ : label is "soft_lutpair61";
  attribute SOFT_HLUTNM of \wa[15]_i_1\ : label is "soft_lutpair60";
  attribute SOFT_HLUTNM of \wa[16]_i_1\ : label is "soft_lutpair60";
  attribute SOFT_HLUTNM of \wa[17]_i_1\ : label is "soft_lutpair59";
  attribute SOFT_HLUTNM of \wa[18]_i_1\ : label is "soft_lutpair59";
  attribute SOFT_HLUTNM of \wa[19]_i_1\ : label is "soft_lutpair58";
  attribute SOFT_HLUTNM of \wa[1]_i_1\ : label is "soft_lutpair67";
  attribute SOFT_HLUTNM of \wa[20]_i_1\ : label is "soft_lutpair58";
  attribute SOFT_HLUTNM of \wa[21]_i_1\ : label is "soft_lutpair57";
  attribute SOFT_HLUTNM of \wa[22]_i_1\ : label is "soft_lutpair57";
  attribute SOFT_HLUTNM of \wa[23]_i_1\ : label is "soft_lutpair56";
  attribute SOFT_HLUTNM of \wa[24]_i_1\ : label is "soft_lutpair56";
  attribute SOFT_HLUTNM of \wa[25]_i_1\ : label is "soft_lutpair55";
  attribute SOFT_HLUTNM of \wa[26]_i_1\ : label is "soft_lutpair55";
  attribute SOFT_HLUTNM of \wa[27]_i_1\ : label is "soft_lutpair54";
  attribute SOFT_HLUTNM of \wa[28]_i_1\ : label is "soft_lutpair54";
  attribute SOFT_HLUTNM of \wa[29]_i_1\ : label is "soft_lutpair53";
  attribute SOFT_HLUTNM of \wa[2]_i_1\ : label is "soft_lutpair67";
  attribute SOFT_HLUTNM of \wa[30]_i_1\ : label is "soft_lutpair53";
  attribute SOFT_HLUTNM of \wa[31]_i_1\ : label is "soft_lutpair52";
  attribute SOFT_HLUTNM of \wa[32]_i_1\ : label is "soft_lutpair52";
  attribute SOFT_HLUTNM of \wa[33]_i_1\ : label is "soft_lutpair51";
  attribute SOFT_HLUTNM of \wa[34]_i_1\ : label is "soft_lutpair51";
  attribute SOFT_HLUTNM of \wa[35]_i_1\ : label is "soft_lutpair50";
  attribute SOFT_HLUTNM of \wa[36]_i_1\ : label is "soft_lutpair50";
  attribute SOFT_HLUTNM of \wa[37]_i_1\ : label is "soft_lutpair49";
  attribute SOFT_HLUTNM of \wa[38]_i_1\ : label is "soft_lutpair49";
  attribute SOFT_HLUTNM of \wa[39]_i_1\ : label is "soft_lutpair48";
  attribute SOFT_HLUTNM of \wa[3]_i_1\ : label is "soft_lutpair66";
  attribute SOFT_HLUTNM of \wa[40]_i_1\ : label is "soft_lutpair48";
  attribute SOFT_HLUTNM of \wa[41]_i_1\ : label is "soft_lutpair47";
  attribute SOFT_HLUTNM of \wa[42]_i_1\ : label is "soft_lutpair47";
  attribute SOFT_HLUTNM of \wa[43]_i_1\ : label is "soft_lutpair46";
  attribute SOFT_HLUTNM of \wa[44]_i_1\ : label is "soft_lutpair46";
  attribute SOFT_HLUTNM of \wa[45]_i_1\ : label is "soft_lutpair45";
  attribute SOFT_HLUTNM of \wa[46]_i_1\ : label is "soft_lutpair45";
  attribute SOFT_HLUTNM of \wa[47]_i_1\ : label is "soft_lutpair44";
  attribute SOFT_HLUTNM of \wa[48]_i_1\ : label is "soft_lutpair44";
  attribute SOFT_HLUTNM of \wa[49]_i_1\ : label is "soft_lutpair43";
  attribute SOFT_HLUTNM of \wa[4]_i_1\ : label is "soft_lutpair66";
  attribute SOFT_HLUTNM of \wa[50]_i_1\ : label is "soft_lutpair43";
  attribute SOFT_HLUTNM of \wa[51]_i_1\ : label is "soft_lutpair42";
  attribute SOFT_HLUTNM of \wa[52]_i_1\ : label is "soft_lutpair42";
  attribute SOFT_HLUTNM of \wa[53]_i_1\ : label is "soft_lutpair41";
  attribute SOFT_HLUTNM of \wa[54]_i_1\ : label is "soft_lutpair41";
  attribute SOFT_HLUTNM of \wa[55]_i_1\ : label is "soft_lutpair40";
  attribute SOFT_HLUTNM of \wa[56]_i_1\ : label is "soft_lutpair40";
  attribute SOFT_HLUTNM of \wa[57]_i_1\ : label is "soft_lutpair39";
  attribute SOFT_HLUTNM of \wa[58]_i_1\ : label is "soft_lutpair39";
  attribute SOFT_HLUTNM of \wa[59]_i_1\ : label is "soft_lutpair38";
  attribute SOFT_HLUTNM of \wa[5]_i_1\ : label is "soft_lutpair65";
  attribute SOFT_HLUTNM of \wa[60]_i_1\ : label is "soft_lutpair38";
  attribute SOFT_HLUTNM of \wa[61]_i_1\ : label is "soft_lutpair37";
  attribute SOFT_HLUTNM of \wa[62]_i_1\ : label is "soft_lutpair37";
  attribute SOFT_HLUTNM of \wa[63]_i_2\ : label is "soft_lutpair36";
  attribute SOFT_HLUTNM of \wa[63]_i_3\ : label is "soft_lutpair26";
  attribute SOFT_HLUTNM of \wa[6]_i_1\ : label is "soft_lutpair65";
  attribute SOFT_HLUTNM of \wa[7]_i_1\ : label is "soft_lutpair64";
  attribute SOFT_HLUTNM of \wa[8]_i_1\ : label is "soft_lutpair64";
  attribute SOFT_HLUTNM of \wa[9]_i_1\ : label is "soft_lutpair63";
  attribute ADDER_THRESHOLD of \wa_reg[17]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[25]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[33]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[41]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[49]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[57]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[63]_i_4\ : label is 35;
  attribute ADDER_THRESHOLD of \wa_reg[9]_i_2\ : label is 35;
  attribute SOFT_HLUTNM of \wb[0]_i_2\ : label is "soft_lutpair17";
  attribute SOFT_HLUTNM of \wb[1]_i_2\ : label is "soft_lutpair8";
  attribute SOFT_HLUTNM of \wb[3]_i_1\ : label is "soft_lutpair6";
  attribute SOFT_HLUTNM of \wb[5]_i_2\ : label is "soft_lutpair18";
  attribute SOFT_HLUTNM of \wb[6]_i_2\ : label is "soft_lutpair7";
  attribute SOFT_HLUTNM of \wb[8]_i_5\ : label is "soft_lutpair18";
  attribute SOFT_HLUTNM of \wb[8]_i_6\ : label is "soft_lutpair7";
  attribute SOFT_HLUTNM of \wbeat[1]_i_1\ : label is "soft_lutpair69";
  attribute SOFT_HLUTNM of \wbeat[2]_i_1\ : label is "soft_lutpair9";
  attribute SOFT_HLUTNM of \wbeat[3]_i_1\ : label is "soft_lutpair9";
  attribute SOFT_HLUTNM of \wbeat[5]_i_1\ : label is "soft_lutpair68";
  attribute SOFT_HLUTNM of \wbeat[6]_i_1\ : label is "soft_lutpair69";
  attribute SOFT_HLUTNM of \wbeat[7]_i_1\ : label is "soft_lutpair10";
  attribute SOFT_HLUTNM of \wbeat[8]_i_2\ : label is "soft_lutpair10";
  attribute SOFT_HLUTNM of \wleft[0]_i_1\ : label is "soft_lutpair36";
  attribute SOFT_HLUTNM of \wleft[10]_i_1\ : label is "soft_lutpair31";
  attribute SOFT_HLUTNM of \wleft[11]_i_1\ : label is "soft_lutpair30";
  attribute SOFT_HLUTNM of \wleft[12]_i_1\ : label is "soft_lutpair30";
  attribute SOFT_HLUTNM of \wleft[13]_i_1\ : label is "soft_lutpair29";
  attribute SOFT_HLUTNM of \wleft[14]_i_1\ : label is "soft_lutpair29";
  attribute SOFT_HLUTNM of \wleft[15]_i_1\ : label is "soft_lutpair28";
  attribute SOFT_HLUTNM of \wleft[1]_i_1\ : label is "soft_lutpair35";
  attribute SOFT_HLUTNM of \wleft[2]_i_1\ : label is "soft_lutpair35";
  attribute SOFT_HLUTNM of \wleft[3]_i_1\ : label is "soft_lutpair34";
  attribute SOFT_HLUTNM of \wleft[4]_i_1\ : label is "soft_lutpair34";
  attribute SOFT_HLUTNM of \wleft[5]_i_1\ : label is "soft_lutpair33";
  attribute SOFT_HLUTNM of \wleft[6]_i_1\ : label is "soft_lutpair33";
  attribute SOFT_HLUTNM of \wleft[7]_i_1\ : label is "soft_lutpair32";
  attribute SOFT_HLUTNM of \wleft[8]_i_1\ : label is "soft_lutpair32";
  attribute SOFT_HLUTNM of \wleft[9]_i_1\ : label is "soft_lutpair31";
  attribute ADDER_THRESHOLD of \wleft_reg[15]_i_2\ : label is 35;
  attribute ADDER_THRESHOLD of \wleft_reg[7]_i_2\ : label is 35;
  attribute SOFT_HLUTNM of \write_curr_st[0]_i_1\ : label is "soft_lutpair27";
  attribute SOFT_HLUTNM of \write_curr_st[1]_i_1\ : label is "soft_lutpair24";
begin
  M_AXI_RVALID_0 <= \^m_axi_rvalid_0\;
  M_AXI_WLAST <= \^m_axi_wlast\;
  M_AXI_WVALID <= \^m_axi_wvalid\;
  Q(63 downto 0) <= \^q\(63 downto 0);
  fdma_werror <= \^fdma_werror\;
  \wa_reg[63]_0\(63 downto 0) <= \^wa_reg[63]_0\(63 downto 0);
\FSM_sequential_read_curr_st[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"5D"
    )
        port map (
      I0 => \read_curr_st__0\(0),
      I1 => \read_curr_st__0\(1),
      I2 => \ra[63]_i_4_n_0\,
      O => \FSM_sequential_read_curr_st[0]_i_1_n_0\
    );
\FSM_sequential_read_curr_st[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFEAAFEAAFEAAFEA"
    )
        port map (
      I0 => \ra[63]_i_5_n_0\,
      I1 => M_AXI_ARREADY,
      I2 => \read_curr_st__0\(1),
      I3 => \read_curr_st__0\(0),
      I4 => \^m_axi_rvalid_0\,
      I5 => \read_next_st0__16\,
      O => read_next_st
    );
\FSM_sequential_read_curr_st[1]_i_2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \read_curr_st__0\(0),
      I1 => \read_curr_st__0\(1),
      O => \FSM_sequential_read_curr_st[1]_i_2_n_0\
    );
\FSM_sequential_read_curr_st_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => read_next_st,
      D => \FSM_sequential_read_curr_st[0]_i_1_n_0\,
      Q => \read_curr_st__0\(0),
      R => fdma_wdone_i_1_n_0
    );
\FSM_sequential_read_curr_st_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => read_next_st,
      D => \FSM_sequential_read_curr_st[1]_i_2_n_0\,
      Q => \read_curr_st__0\(1),
      R => fdma_wdone_i_1_n_0
    );
\FSM_sequential_write_curr_st[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"4F"
    )
        port map (
      I0 => \write_next_st1__23\,
      I1 => \write_curr_st__0\(1),
      I2 => \write_curr_st__0\(0),
      O => \FSM_sequential_write_curr_st[0]_i_1_n_0\
    );
\FSM_sequential_write_curr_st[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFF040404"
    )
        port map (
      I0 => \write_curr_st__0\(1),
      I1 => fdma_wareq,
      I2 => fdma_wdone_i_4_n_0,
      I3 => \wa[63]_i_3_n_0\,
      I4 => \write_curr_st__0\(0),
      I5 => \FSM_sequential_write_curr_st[1]_i_3_n_0\,
      O => write_next_st
    );
\FSM_sequential_write_curr_st[1]_i_2\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \write_curr_st__0\(1),
      I1 => \write_curr_st__0\(0),
      O => \FSM_sequential_write_curr_st[1]_i_2_n_0\
    );
\FSM_sequential_write_curr_st[1]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0F10"
    )
        port map (
      I0 => w_pending_reg_n_0,
      I1 => aw_pending_reg_n_0,
      I2 => \write_curr_st__0\(1),
      I3 => \write_curr_st__0\(0),
      O => \FSM_sequential_write_curr_st[1]_i_3_n_0\
    );
\FSM_sequential_write_curr_st_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => write_next_st,
      D => \FSM_sequential_write_curr_st[0]_i_1_n_0\,
      Q => \write_curr_st__0\(0),
      R => fdma_wdone_i_1_n_0
    );
\FSM_sequential_write_curr_st_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => write_next_st,
      D => \FSM_sequential_write_curr_st[1]_i_2_n_0\,
      Q => \write_curr_st__0\(1),
      R => fdma_wdone_i_1_n_0
    );
\M_AXI_ARLEN[0]_INST_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rb_reg_n_0_[0]\,
      O => M_AXI_ARLEN(0)
    );
\M_AXI_ARLEN[1]_INST_0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rb_reg_n_0_[1]\,
      I1 => \rb_reg_n_0_[0]\,
      O => M_AXI_ARLEN(1)
    );
\M_AXI_ARLEN[2]_INST_0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A9"
    )
        port map (
      I0 => \rb_reg_n_0_[2]\,
      I1 => \rb_reg_n_0_[0]\,
      I2 => \rb_reg_n_0_[1]\,
      O => M_AXI_ARLEN(2)
    );
\M_AXI_ARLEN[3]_INST_0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AAA9"
    )
        port map (
      I0 => \rb_reg_n_0_[3]\,
      I1 => \rb_reg_n_0_[1]\,
      I2 => \rb_reg_n_0_[0]\,
      I3 => \rb_reg_n_0_[2]\,
      O => M_AXI_ARLEN(3)
    );
\M_AXI_ARLEN[4]_INST_0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAAAA9"
    )
        port map (
      I0 => \rb_reg_n_0_[4]\,
      I1 => \rb_reg_n_0_[2]\,
      I2 => \rb_reg_n_0_[0]\,
      I3 => \rb_reg_n_0_[1]\,
      I4 => \rb_reg_n_0_[3]\,
      O => M_AXI_ARLEN(4)
    );
\M_AXI_ARLEN[5]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAAAAAAAA9"
    )
        port map (
      I0 => \rb_reg_n_0_[5]\,
      I1 => \rb_reg_n_0_[3]\,
      I2 => \rb_reg_n_0_[1]\,
      I3 => \rb_reg_n_0_[0]\,
      I4 => \rb_reg_n_0_[2]\,
      I5 => \rb_reg_n_0_[4]\,
      O => M_AXI_ARLEN(5)
    );
\M_AXI_ARLEN[6]_INST_0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rb_reg_n_0_[6]\,
      I1 => \M_AXI_ARLEN[7]_INST_0_i_1_n_0\,
      O => M_AXI_ARLEN(6)
    );
\M_AXI_ARLEN[7]_INST_0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"A9"
    )
        port map (
      I0 => \rb_reg_n_0_[7]\,
      I1 => \M_AXI_ARLEN[7]_INST_0_i_1_n_0\,
      I2 => \rb_reg_n_0_[6]\,
      O => M_AXI_ARLEN(7)
    );
\M_AXI_ARLEN[7]_INST_0_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => \rb_reg_n_0_[4]\,
      I1 => \rb_reg_n_0_[2]\,
      I2 => \rb_reg_n_0_[0]\,
      I3 => \rb_reg_n_0_[1]\,
      I4 => \rb_reg_n_0_[3]\,
      I5 => \rb_reg_n_0_[5]\,
      O => \M_AXI_ARLEN[7]_INST_0_i_1_n_0\
    );
M_AXI_ARVALID_INST_0: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => read_curr_st(1),
      I1 => read_curr_st(0),
      O => M_AXI_ARVALID
    );
\M_AXI_AWLEN[0]_INST_0\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wb_reg_n_0_[0]\,
      O => M_AXI_AWLEN(0)
    );
\M_AXI_AWLEN[1]_INST_0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wb_reg_n_0_[0]\,
      I1 => \wb_reg_n_0_[1]\,
      O => M_AXI_AWLEN(1)
    );
\M_AXI_AWLEN[2]_INST_0\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"E1"
    )
        port map (
      I0 => \wb_reg_n_0_[1]\,
      I1 => \wb_reg_n_0_[0]\,
      I2 => \wb_reg_n_0_[2]\,
      O => M_AXI_AWLEN(2)
    );
\M_AXI_AWLEN[3]_INST_0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AAA9"
    )
        port map (
      I0 => \wb_reg_n_0_[3]\,
      I1 => \wb_reg_n_0_[1]\,
      I2 => \wb_reg_n_0_[0]\,
      I3 => \wb_reg_n_0_[2]\,
      O => M_AXI_AWLEN(3)
    );
\M_AXI_AWLEN[4]_INST_0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAAAA9"
    )
        port map (
      I0 => \wb_reg_n_0_[4]\,
      I1 => \wb_reg_n_0_[2]\,
      I2 => \wb_reg_n_0_[0]\,
      I3 => \wb_reg_n_0_[1]\,
      I4 => \wb_reg_n_0_[3]\,
      O => M_AXI_AWLEN(4)
    );
\M_AXI_AWLEN[5]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAAAAAAAA9"
    )
        port map (
      I0 => \wb_reg_n_0_[5]\,
      I1 => \wb_reg_n_0_[3]\,
      I2 => \wb_reg_n_0_[1]\,
      I3 => \wb_reg_n_0_[0]\,
      I4 => \wb_reg_n_0_[2]\,
      I5 => \wb_reg_n_0_[4]\,
      O => M_AXI_AWLEN(5)
    );
\M_AXI_AWLEN[6]_INST_0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFE0001"
    )
        port map (
      I0 => \wb_reg_n_0_[5]\,
      I1 => \wb_reg_n_0_[3]\,
      I2 => \M_AXI_AWLEN[7]_INST_0_i_1_n_0\,
      I3 => \wb_reg_n_0_[4]\,
      I4 => \wb_reg_n_0_[6]\,
      O => M_AXI_AWLEN(6)
    );
\M_AXI_AWLEN[7]_INST_0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFE00000001"
    )
        port map (
      I0 => \wb_reg_n_0_[6]\,
      I1 => \wb_reg_n_0_[4]\,
      I2 => \M_AXI_AWLEN[7]_INST_0_i_1_n_0\,
      I3 => \wb_reg_n_0_[3]\,
      I4 => \wb_reg_n_0_[5]\,
      I5 => \wb_reg_n_0_[7]\,
      O => M_AXI_AWLEN(7)
    );
\M_AXI_AWLEN[7]_INST_0_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"FE"
    )
        port map (
      I0 => \wb_reg_n_0_[1]\,
      I1 => \wb_reg_n_0_[0]\,
      I2 => \wb_reg_n_0_[2]\,
      O => \M_AXI_AWLEN[7]_INST_0_i_1_n_0\
    );
M_AXI_AWVALID_INST_0: unisim.vcomponents.LUT3
    generic map(
      INIT => X"40"
    )
        port map (
      I0 => write_curr_st(0),
      I1 => write_curr_st(1),
      I2 => aw_pending_reg_n_0,
      O => M_AXI_AWVALID
    );
M_AXI_BREADY_INST_0: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => write_curr_st(1),
      I1 => write_curr_st(0),
      O => M_AXI_BREADY
    );
M_AXI_RREADY_INST_0: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => read_curr_st(1),
      I1 => read_curr_st(0),
      I2 => fdma_rready,
      O => M_AXI_RREADY
    );
M_AXI_WLAST_INST_0: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8228000000000000"
    )
        port map (
      I0 => M_AXI_WLAST_INST_0_i_1_n_0,
      I1 => \wbeat_reg_n_0_[5]\,
      I2 => \wb_reg_n_0_[5]\,
      I3 => M_AXI_WLAST_INST_0_i_2_n_0,
      I4 => M_AXI_WLAST_INST_0_i_3_n_0,
      I5 => M_AXI_WLAST_INST_0_i_4_n_0,
      O => \^m_axi_wlast\
    );
M_AXI_WLAST_INST_0_i_1: unisim.vcomponents.LUT5
    generic map(
      INIT => X"90060990"
    )
        port map (
      I0 => \wbeat_reg_n_0_[4]\,
      I1 => \wb_reg_n_0_[4]\,
      I2 => \M_AXI_AWLEN[7]_INST_0_i_1_n_0\,
      I3 => \wb_reg_n_0_[3]\,
      I4 => \wbeat_reg_n_0_[3]\,
      O => M_AXI_WLAST_INST_0_i_1_n_0
    );
M_AXI_WLAST_INST_0_i_2: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => \wb_reg_n_0_[3]\,
      I1 => \wb_reg_n_0_[1]\,
      I2 => \wb_reg_n_0_[0]\,
      I3 => \wb_reg_n_0_[2]\,
      I4 => \wb_reg_n_0_[4]\,
      O => M_AXI_WLAST_INST_0_i_2_n_0
    );
M_AXI_WLAST_INST_0_i_3: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8020200808020280"
    )
        port map (
      I0 => M_AXI_WLAST_INST_0_i_5_n_0,
      I1 => \wbeat_reg_n_0_[6]\,
      I2 => \wbeat_reg_n_0_[7]\,
      I3 => \wb_reg_n_0_[6]\,
      I4 => M_AXI_WLAST_INST_0_i_6_n_0,
      I5 => \wb_reg_n_0_[7]\,
      O => M_AXI_WLAST_INST_0_i_3_n_0
    );
M_AXI_WLAST_INST_0_i_4: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAA95556"
    )
        port map (
      I0 => \wb_reg_n_0_[8]\,
      I1 => \wb_reg_n_0_[6]\,
      I2 => M_AXI_WLAST_INST_0_i_6_n_0,
      I3 => \wb_reg_n_0_[7]\,
      I4 => \wbeat_reg_n_0_[8]\,
      O => M_AXI_WLAST_INST_0_i_4_n_0
    );
M_AXI_WLAST_INST_0_i_5: unisim.vcomponents.LUT6
    generic map(
      INIT => X"4010200804010280"
    )
        port map (
      I0 => \wbeat_reg_n_0_[0]\,
      I1 => \wbeat_reg_n_0_[1]\,
      I2 => \wbeat_reg_n_0_[2]\,
      I3 => \wb_reg_n_0_[1]\,
      I4 => \wb_reg_n_0_[0]\,
      I5 => \wb_reg_n_0_[2]\,
      O => M_AXI_WLAST_INST_0_i_5_n_0
    );
M_AXI_WLAST_INST_0_i_6: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => \wb_reg_n_0_[4]\,
      I1 => \wb_reg_n_0_[2]\,
      I2 => \wb_reg_n_0_[0]\,
      I3 => \wb_reg_n_0_[1]\,
      I4 => \wb_reg_n_0_[3]\,
      I5 => \wb_reg_n_0_[5]\,
      O => M_AXI_WLAST_INST_0_i_6_n_0
    );
M_AXI_WVALID_INST_0: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0800"
    )
        port map (
      I0 => w_pending_reg_n_0,
      I1 => fdma_wready,
      I2 => write_curr_st(0),
      I3 => write_curr_st(1),
      O => \^m_axi_wvalid\
    );
aw_pending_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAFFFFA2AAAAAA"
    )
        port map (
      I0 => aw_pending_reg_n_0,
      I1 => M_AXI_AWREADY,
      I2 => write_curr_st(0),
      I3 => write_curr_st(1),
      I4 => \write_curr_st__0\(1),
      I5 => \write_curr_st__0\(0),
      O => aw_pending_i_1_n_0
    );
aw_pending_reg: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => '1',
      D => aw_pending_i_1_n_0,
      Q => aw_pending_reg_n_0,
      R => fdma_wdone_i_1_n_0
    );
fdma_rbusy_INST_0: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => read_curr_st(1),
      I1 => read_curr_st(0),
      O => fdma_rbusy
    );
fdma_rvalid_INST_0: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8000"
    )
        port map (
      I0 => M_AXI_RVALID,
      I1 => fdma_rready,
      I2 => read_curr_st(0),
      I3 => read_curr_st(1),
      O => \^m_axi_rvalid_0\
    );
fdma_wbusy_INST_0: unisim.vcomponents.LUT2
    generic map(
      INIT => X"E"
    )
        port map (
      I0 => write_curr_st(1),
      I1 => write_curr_st(0),
      O => fdma_wbusy
    );
fdma_wdone_i_1: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => M_AXI_ARESETN,
      O => fdma_wdone_i_1_n_0
    );
fdma_wdone_i_10: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6FF6"
    )
        port map (
      I0 => \wleft_reg_n_0_[4]\,
      I1 => \wb_reg_n_0_[4]\,
      I2 => \wleft_reg_n_0_[3]\,
      I3 => \wb_reg_n_0_[3]\,
      O => fdma_wdone_i_10_n_0
    );
fdma_wdone_i_11: unisim.vcomponents.LUT4
    generic map(
      INIT => X"6FF6"
    )
        port map (
      I0 => \wleft_reg_n_0_[5]\,
      I1 => \wb_reg_n_0_[5]\,
      I2 => \wleft_reg_n_0_[2]\,
      I3 => \wb_reg_n_0_[2]\,
      O => fdma_wdone_i_11_n_0
    );
fdma_wdone_i_12: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0001"
    )
        port map (
      I0 => fdma_wsize(11),
      I1 => fdma_wsize(10),
      I2 => fdma_wsize(9),
      I3 => fdma_wsize(8),
      O => fdma_wdone_i_12_n_0
    );
fdma_wdone_i_13: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0001"
    )
        port map (
      I0 => fdma_wsize(7),
      I1 => fdma_wsize(6),
      I2 => fdma_wsize(5),
      I3 => fdma_wsize(4),
      O => fdma_wdone_i_13_n_0
    );
fdma_wdone_i_2: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8800880000F00000"
    )
        port map (
      I0 => \write_next_st1__23\,
      I1 => M_AXI_BVALID,
      I2 => fdma_wdone_i_4_n_0,
      I3 => write_curr_st(1),
      I4 => fdma_wareq,
      I5 => write_curr_st(0),
      O => fdma_wdone_i_2_n_0
    );
fdma_wdone_i_3: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000001"
    )
        port map (
      I0 => fdma_wdone_i_5_n_0,
      I1 => \wleft_reg_n_0_[13]\,
      I2 => \wleft_reg_n_0_[12]\,
      I3 => \wleft_reg_n_0_[15]\,
      I4 => \wleft_reg_n_0_[14]\,
      I5 => fdma_wdone_i_6_n_0,
      O => \write_next_st1__23\
    );
fdma_wdone_i_4: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFEFEFE"
    )
        port map (
      I0 => fdma_waddr(1),
      I1 => fdma_waddr(0),
      I2 => fdma_waddr(2),
      I3 => fdma_wdone_i_7_n_0,
      I4 => fdma_wdone_i_8_n_0,
      O => fdma_wdone_i_4_n_0
    );
fdma_wdone_i_5: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BEFFFFBE"
    )
        port map (
      I0 => fdma_wdone_i_9_n_0,
      I1 => \wb_reg_n_0_[7]\,
      I2 => \wleft_reg_n_0_[7]\,
      I3 => \wb_reg_n_0_[8]\,
      I4 => \wleft_reg_n_0_[8]\,
      O => fdma_wdone_i_5_n_0
    );
fdma_wdone_i_6: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFBEFFFFBE"
    )
        port map (
      I0 => fdma_wdone_i_10_n_0,
      I1 => \wleft_reg_n_0_[1]\,
      I2 => \wb_reg_n_0_[1]\,
      I3 => \wleft_reg_n_0_[0]\,
      I4 => \wb_reg_n_0_[0]\,
      I5 => fdma_wdone_i_11_n_0,
      O => fdma_wdone_i_6_n_0
    );
fdma_wdone_i_7: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00010000"
    )
        port map (
      I0 => fdma_wsize(12),
      I1 => fdma_wsize(13),
      I2 => fdma_wsize(14),
      I3 => fdma_wsize(15),
      I4 => fdma_wdone_i_12_n_0,
      O => fdma_wdone_i_7_n_0
    );
fdma_wdone_i_8: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00010000"
    )
        port map (
      I0 => fdma_wsize(2),
      I1 => fdma_wsize(3),
      I2 => fdma_wsize(0),
      I3 => fdma_wsize(1),
      I4 => fdma_wdone_i_13_n_0,
      O => fdma_wdone_i_8_n_0
    );
fdma_wdone_i_9: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFBE"
    )
        port map (
      I0 => \wleft_reg_n_0_[11]\,
      I1 => \wb_reg_n_0_[6]\,
      I2 => \wleft_reg_n_0_[6]\,
      I3 => \wleft_reg_n_0_[9]\,
      I4 => \wleft_reg_n_0_[10]\,
      O => fdma_wdone_i_9_n_0
    );
fdma_wdone_reg: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => '1',
      D => fdma_wdone_i_2_n_0,
      Q => fdma_wdone,
      R => fdma_wdone_i_1_n_0
    );
fdma_werror_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFEFFFFF0020"
    )
        port map (
      I0 => fdma_wdone_i_4_n_0,
      I1 => write_curr_st(0),
      I2 => fdma_wareq,
      I3 => write_curr_st(1),
      I4 => fdma_werror_i_2_n_0,
      I5 => \^fdma_werror\,
      O => fdma_werror_i_1_n_0
    );
fdma_werror_i_2: unisim.vcomponents.LUT5
    generic map(
      INIT => X"44444440"
    )
        port map (
      I0 => p_4_in,
      I1 => \wa[63]_i_3_n_0\,
      I2 => M_AXI_BID(0),
      I3 => M_AXI_BRESP(0),
      I4 => M_AXI_BRESP(1),
      O => fdma_werror_i_2_n_0
    );
fdma_werror_i_3: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => write_curr_st(1),
      I1 => fdma_wareq,
      I2 => write_curr_st(0),
      O => p_4_in
    );
fdma_werror_reg: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => '1',
      D => fdma_werror_i_1_n_0,
      Q => \^fdma_werror\,
      R => fdma_wdone_i_1_n_0
    );
fdma_wvalid_INST_0: unisim.vcomponents.LUT5
    generic map(
      INIT => X"20000000"
    )
        port map (
      I0 => write_curr_st(1),
      I1 => write_curr_st(0),
      I2 => fdma_wready,
      I3 => w_pending_reg_n_0,
      I4 => M_AXI_WREADY,
      O => fdma_wvalid
    );
\ra[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \^q\(0),
      I1 => fdma_raddr(0),
      I2 => \read_curr_st__0\(1),
      O => ra(0)
    );
\ra[10]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(10),
      I1 => fdma_raddr(10),
      I2 => \read_curr_st__0\(1),
      O => ra(10)
    );
\ra[11]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(11),
      I1 => fdma_raddr(11),
      I2 => \read_curr_st__0\(1),
      O => ra(11)
    );
\ra[12]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(12),
      I1 => fdma_raddr(12),
      I2 => \read_curr_st__0\(1),
      O => ra(12)
    );
\ra[13]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(13),
      I1 => fdma_raddr(13),
      I2 => \read_curr_st__0\(1),
      O => ra(13)
    );
\ra[14]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(14),
      I1 => fdma_raddr(14),
      I2 => \read_curr_st__0\(1),
      O => ra(14)
    );
\ra[15]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(15),
      I1 => fdma_raddr(15),
      I2 => \read_curr_st__0\(1),
      O => ra(15)
    );
\ra[16]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(16),
      I1 => fdma_raddr(16),
      I2 => \read_curr_st__0\(1),
      O => ra(16)
    );
\ra[17]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(17),
      I1 => fdma_raddr(17),
      I2 => \read_curr_st__0\(1),
      O => ra(17)
    );
\ra[17]_i_3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(11),
      I1 => \rb_reg_n_0_[8]\,
      O => \ra[17]_i_3_n_0\
    );
\ra[17]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(10),
      I1 => \rb_reg_n_0_[7]\,
      O => \ra[17]_i_4_n_0\
    );
\ra[18]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(18),
      I1 => fdma_raddr(18),
      I2 => \read_curr_st__0\(1),
      O => ra(18)
    );
\ra[19]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(19),
      I1 => fdma_raddr(19),
      I2 => \read_curr_st__0\(1),
      O => ra(19)
    );
\ra[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \^q\(1),
      I1 => fdma_raddr(1),
      I2 => \read_curr_st__0\(1),
      O => ra(1)
    );
\ra[20]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(20),
      I1 => fdma_raddr(20),
      I2 => \read_curr_st__0\(1),
      O => ra(20)
    );
\ra[21]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(21),
      I1 => fdma_raddr(21),
      I2 => \read_curr_st__0\(1),
      O => ra(21)
    );
\ra[22]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(22),
      I1 => fdma_raddr(22),
      I2 => \read_curr_st__0\(1),
      O => ra(22)
    );
\ra[23]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(23),
      I1 => fdma_raddr(23),
      I2 => \read_curr_st__0\(1),
      O => ra(23)
    );
\ra[24]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(24),
      I1 => fdma_raddr(24),
      I2 => \read_curr_st__0\(1),
      O => ra(24)
    );
\ra[25]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(25),
      I1 => fdma_raddr(25),
      I2 => \read_curr_st__0\(1),
      O => ra(25)
    );
\ra[26]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(26),
      I1 => fdma_raddr(26),
      I2 => \read_curr_st__0\(1),
      O => ra(26)
    );
\ra[27]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(27),
      I1 => fdma_raddr(27),
      I2 => \read_curr_st__0\(1),
      O => ra(27)
    );
\ra[28]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(28),
      I1 => fdma_raddr(28),
      I2 => \read_curr_st__0\(1),
      O => ra(28)
    );
\ra[29]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(29),
      I1 => fdma_raddr(29),
      I2 => \read_curr_st__0\(1),
      O => ra(29)
    );
\ra[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(2),
      I1 => fdma_raddr(2),
      I2 => \read_curr_st__0\(1),
      O => ra(2)
    );
\ra[30]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(30),
      I1 => fdma_raddr(30),
      I2 => \read_curr_st__0\(1),
      O => ra(30)
    );
\ra[31]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(31),
      I1 => fdma_raddr(31),
      I2 => \read_curr_st__0\(1),
      O => ra(31)
    );
\ra[32]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(32),
      I1 => fdma_raddr(32),
      I2 => \read_curr_st__0\(1),
      O => ra(32)
    );
\ra[33]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(33),
      I1 => fdma_raddr(33),
      I2 => \read_curr_st__0\(1),
      O => ra(33)
    );
\ra[34]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(34),
      I1 => fdma_raddr(34),
      I2 => \read_curr_st__0\(1),
      O => ra(34)
    );
\ra[35]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(35),
      I1 => fdma_raddr(35),
      I2 => \read_curr_st__0\(1),
      O => ra(35)
    );
\ra[36]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(36),
      I1 => fdma_raddr(36),
      I2 => \read_curr_st__0\(1),
      O => ra(36)
    );
\ra[37]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(37),
      I1 => fdma_raddr(37),
      I2 => \read_curr_st__0\(1),
      O => ra(37)
    );
\ra[38]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(38),
      I1 => fdma_raddr(38),
      I2 => \read_curr_st__0\(1),
      O => ra(38)
    );
\ra[39]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(39),
      I1 => fdma_raddr(39),
      I2 => \read_curr_st__0\(1),
      O => ra(39)
    );
\ra[3]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(3),
      I1 => fdma_raddr(3),
      I2 => \read_curr_st__0\(1),
      O => ra(3)
    );
\ra[40]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(40),
      I1 => fdma_raddr(40),
      I2 => \read_curr_st__0\(1),
      O => ra(40)
    );
\ra[41]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(41),
      I1 => fdma_raddr(41),
      I2 => \read_curr_st__0\(1),
      O => ra(41)
    );
\ra[42]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(42),
      I1 => fdma_raddr(42),
      I2 => \read_curr_st__0\(1),
      O => ra(42)
    );
\ra[43]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(43),
      I1 => fdma_raddr(43),
      I2 => \read_curr_st__0\(1),
      O => ra(43)
    );
\ra[44]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(44),
      I1 => fdma_raddr(44),
      I2 => \read_curr_st__0\(1),
      O => ra(44)
    );
\ra[45]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(45),
      I1 => fdma_raddr(45),
      I2 => \read_curr_st__0\(1),
      O => ra(45)
    );
\ra[46]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(46),
      I1 => fdma_raddr(46),
      I2 => \read_curr_st__0\(1),
      O => ra(46)
    );
\ra[47]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(47),
      I1 => fdma_raddr(47),
      I2 => \read_curr_st__0\(1),
      O => ra(47)
    );
\ra[48]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(48),
      I1 => fdma_raddr(48),
      I2 => \read_curr_st__0\(1),
      O => ra(48)
    );
\ra[49]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(49),
      I1 => fdma_raddr(49),
      I2 => \read_curr_st__0\(1),
      O => ra(49)
    );
\ra[4]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(4),
      I1 => fdma_raddr(4),
      I2 => \read_curr_st__0\(1),
      O => ra(4)
    );
\ra[50]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(50),
      I1 => fdma_raddr(50),
      I2 => \read_curr_st__0\(1),
      O => ra(50)
    );
\ra[51]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(51),
      I1 => fdma_raddr(51),
      I2 => \read_curr_st__0\(1),
      O => ra(51)
    );
\ra[52]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(52),
      I1 => fdma_raddr(52),
      I2 => \read_curr_st__0\(1),
      O => ra(52)
    );
\ra[53]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(53),
      I1 => fdma_raddr(53),
      I2 => \read_curr_st__0\(1),
      O => ra(53)
    );
\ra[54]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(54),
      I1 => fdma_raddr(54),
      I2 => \read_curr_st__0\(1),
      O => ra(54)
    );
\ra[55]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(55),
      I1 => fdma_raddr(55),
      I2 => \read_curr_st__0\(1),
      O => ra(55)
    );
\ra[56]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(56),
      I1 => fdma_raddr(56),
      I2 => \read_curr_st__0\(1),
      O => ra(56)
    );
\ra[57]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(57),
      I1 => fdma_raddr(57),
      I2 => \read_curr_st__0\(1),
      O => ra(57)
    );
\ra[58]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(58),
      I1 => fdma_raddr(58),
      I2 => \read_curr_st__0\(1),
      O => ra(58)
    );
\ra[59]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(59),
      I1 => fdma_raddr(59),
      I2 => \read_curr_st__0\(1),
      O => ra(59)
    );
\ra[5]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(5),
      I1 => fdma_raddr(5),
      I2 => \read_curr_st__0\(1),
      O => ra(5)
    );
\ra[60]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(60),
      I1 => fdma_raddr(60),
      I2 => \read_curr_st__0\(1),
      O => ra(60)
    );
\ra[61]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(61),
      I1 => fdma_raddr(61),
      I2 => \read_curr_st__0\(1),
      O => ra(61)
    );
\ra[62]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(62),
      I1 => fdma_raddr(62),
      I2 => \read_curr_st__0\(1),
      O => ra(62)
    );
\ra[63]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0800FFFF08000000"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \read_next_st0__16\,
      I2 => \ra[63]_i_4_n_0\,
      I3 => \^m_axi_rvalid_0\,
      I4 => \read_curr_st__0\(0),
      I5 => \ra[63]_i_5_n_0\,
      O => ra_2
    );
\ra[63]_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000800000000"
    )
        port map (
      I0 => \ra[63]_i_18_n_0\,
      I1 => \ra[63]_i_19_n_0\,
      I2 => \rleft_reg_n_0_[11]\,
      I3 => \rleft_reg_n_0_[10]\,
      I4 => \rleft_reg_n_0_[9]\,
      I5 => \ra[63]_i_20_n_0\,
      O => \ra[63]_i_10_n_0\
    );
\ra[63]_i_11\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => fdma_rsize(10),
      I1 => fdma_rsize(11),
      I2 => fdma_rsize(8),
      I3 => fdma_rsize(9),
      O => \ra[63]_i_11_n_0\
    );
\ra[63]_i_12\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => fdma_rsize(15),
      I1 => fdma_rsize(14),
      I2 => fdma_rsize(12),
      I3 => fdma_rsize(13),
      O => \ra[63]_i_12_n_0\
    );
\ra[63]_i_13\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => fdma_rsize(2),
      I1 => fdma_rsize(3),
      I2 => fdma_rsize(0),
      I3 => fdma_rsize(1),
      O => \ra[63]_i_13_n_0\
    );
\ra[63]_i_14\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => fdma_rsize(6),
      I1 => fdma_rsize(7),
      I2 => fdma_rsize(4),
      I3 => fdma_rsize(5),
      O => \ra[63]_i_14_n_0\
    );
\ra[63]_i_15\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"01FE"
    )
        port map (
      I0 => \rb_reg_n_0_[2]\,
      I1 => \rb_reg_n_0_[0]\,
      I2 => \rb_reg_n_0_[1]\,
      I3 => \rb_reg_n_0_[3]\,
      O => \ra[63]_i_15_n_0\
    );
\ra[63]_i_16\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000001FFFFFFFE"
    )
        port map (
      I0 => \rb_reg_n_0_[4]\,
      I1 => \rb_reg_n_0_[2]\,
      I2 => \rb_reg_n_0_[0]\,
      I3 => \rb_reg_n_0_[1]\,
      I4 => \rb_reg_n_0_[3]\,
      I5 => \rb_reg_n_0_[5]\,
      O => \ra[63]_i_16_n_0\
    );
\ra[63]_i_17\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0001FFFE"
    )
        port map (
      I0 => \rb_reg_n_0_[3]\,
      I1 => \rb_reg_n_0_[1]\,
      I2 => \rb_reg_n_0_[0]\,
      I3 => \rb_reg_n_0_[2]\,
      I4 => \rb_reg_n_0_[4]\,
      O => \ra[63]_i_17_n_0\
    );
\ra[63]_i_18\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => \rleft_reg_n_0_[3]\,
      I1 => \rb_reg_n_0_[3]\,
      I2 => \rb_reg_n_0_[5]\,
      I3 => \rleft_reg_n_0_[5]\,
      I4 => \rb_reg_n_0_[4]\,
      I5 => \rleft_reg_n_0_[4]\,
      O => \ra[63]_i_18_n_0\
    );
\ra[63]_i_19\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => \rleft_reg_n_0_[0]\,
      I1 => \rb_reg_n_0_[0]\,
      I2 => \rb_reg_n_0_[2]\,
      I3 => \rleft_reg_n_0_[2]\,
      I4 => \rb_reg_n_0_[1]\,
      I5 => \rleft_reg_n_0_[1]\,
      O => \ra[63]_i_19_n_0\
    );
\ra[63]_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(63),
      I1 => fdma_raddr(63),
      I2 => \read_curr_st__0\(1),
      O => ra(63)
    );
\ra[63]_i_20\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"9009000000009009"
    )
        port map (
      I0 => \rleft_reg_n_0_[6]\,
      I1 => \rb_reg_n_0_[6]\,
      I2 => \rb_reg_n_0_[8]\,
      I3 => \rleft_reg_n_0_[8]\,
      I4 => \rb_reg_n_0_[7]\,
      I5 => \rleft_reg_n_0_[7]\,
      O => \ra[63]_i_20_n_0\
    );
\ra[63]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8228000000000000"
    )
        port map (
      I0 => \ra[63]_i_7_n_0\,
      I1 => \rbeat_reg_n_0_[6]\,
      I2 => \M_AXI_ARLEN[7]_INST_0_i_1_n_0\,
      I3 => \rb_reg_n_0_[6]\,
      I4 => \ra[63]_i_8_n_0\,
      I5 => \ra[63]_i_9_n_0\,
      O => \read_next_st0__16\
    );
\ra[63]_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00010000"
    )
        port map (
      I0 => \rleft_reg_n_0_[12]\,
      I1 => \rleft_reg_n_0_[13]\,
      I2 => \rleft_reg_n_0_[14]\,
      I3 => \rleft_reg_n_0_[15]\,
      I4 => \ra[63]_i_10_n_0\,
      O => \ra[63]_i_4_n_0\
    );
\ra[63]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000000FFFE0000"
    )
        port map (
      I0 => \ra[63]_i_11_n_0\,
      I1 => \ra[63]_i_12_n_0\,
      I2 => \ra[63]_i_13_n_0\,
      I3 => \ra[63]_i_14_n_0\,
      I4 => fdma_rareq,
      I5 => \read_curr_st__0\(1),
      O => \ra[63]_i_5_n_0\
    );
\ra[63]_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"4002100808400210"
    )
        port map (
      I0 => \rbeat_reg_n_0_[0]\,
      I1 => \rb_reg_n_0_[2]\,
      I2 => \rb_reg_n_0_[0]\,
      I3 => \rb_reg_n_0_[1]\,
      I4 => \rbeat_reg_n_0_[2]\,
      I5 => \rbeat_reg_n_0_[1]\,
      O => \ra[63]_i_7_n_0\
    );
\ra[63]_i_8\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8484844221212118"
    )
        port map (
      I0 => \rbeat_reg_n_0_[7]\,
      I1 => \rbeat_reg_n_0_[8]\,
      I2 => \rb_reg_n_0_[7]\,
      I3 => \M_AXI_ARLEN[7]_INST_0_i_1_n_0\,
      I4 => \rb_reg_n_0_[6]\,
      I5 => \rb_reg_n_0_[8]\,
      O => \ra[63]_i_8_n_0\
    );
\ra[63]_i_9\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000066006600000"
    )
        port map (
      I0 => \rbeat_reg_n_0_[3]\,
      I1 => \ra[63]_i_15_n_0\,
      I2 => \ra[63]_i_16_n_0\,
      I3 => \rbeat_reg_n_0_[5]\,
      I4 => \ra[63]_i_17_n_0\,
      I5 => \rbeat_reg_n_0_[4]\,
      O => \ra[63]_i_9_n_0\
    );
\ra[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(6),
      I1 => fdma_raddr(6),
      I2 => \read_curr_st__0\(1),
      O => ra(6)
    );
\ra[7]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(7),
      I1 => fdma_raddr(7),
      I2 => \read_curr_st__0\(1),
      O => ra(7)
    );
\ra[8]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(8),
      I1 => fdma_raddr(8),
      I2 => \read_curr_st__0\(1),
      O => ra(8)
    );
\ra[9]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => in12(9),
      I1 => fdma_raddr(9),
      I2 => \read_curr_st__0\(1),
      O => ra(9)
    );
\ra[9]_i_3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(9),
      I1 => \rb_reg_n_0_[6]\,
      O => \ra[9]_i_3_n_0\
    );
\ra[9]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(8),
      I1 => \rb_reg_n_0_[5]\,
      O => \ra[9]_i_4_n_0\
    );
\ra[9]_i_5\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(7),
      I1 => \rb_reg_n_0_[4]\,
      O => \ra[9]_i_5_n_0\
    );
\ra[9]_i_6\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(6),
      I1 => \rb_reg_n_0_[3]\,
      O => \ra[9]_i_6_n_0\
    );
\ra[9]_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(5),
      I1 => \rb_reg_n_0_[2]\,
      O => \ra[9]_i_7_n_0\
    );
\ra[9]_i_8\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(4),
      I1 => \rb_reg_n_0_[1]\,
      O => \ra[9]_i_8_n_0\
    );
\ra[9]_i_9\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^q\(3),
      I1 => \rb_reg_n_0_[0]\,
      O => \ra[9]_i_9_n_0\
    );
\ra_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(0),
      Q => \^q\(0),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(10),
      Q => \^q\(10),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(11),
      Q => \^q\(11),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(12),
      Q => \^q\(12),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(13),
      Q => \^q\(13),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(14),
      Q => \^q\(14),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(15),
      Q => \^q\(15),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(16),
      Q => \^q\(16),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(17),
      Q => \^q\(17),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[17]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[9]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \ra_reg[17]_i_2_n_0\,
      CO(6) => \ra_reg[17]_i_2_n_1\,
      CO(5) => \ra_reg[17]_i_2_n_2\,
      CO(4) => \ra_reg[17]_i_2_n_3\,
      CO(3) => \ra_reg[17]_i_2_n_4\,
      CO(2) => \ra_reg[17]_i_2_n_5\,
      CO(1) => \ra_reg[17]_i_2_n_6\,
      CO(0) => \ra_reg[17]_i_2_n_7\,
      DI(7 downto 2) => B"000000",
      DI(1 downto 0) => \^q\(11 downto 10),
      O(7 downto 0) => in12(17 downto 10),
      S(7 downto 2) => \^q\(17 downto 12),
      S(1) => \ra[17]_i_3_n_0\,
      S(0) => \ra[17]_i_4_n_0\
    );
\ra_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(18),
      Q => \^q\(18),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(19),
      Q => \^q\(19),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(1),
      Q => \^q\(1),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(20),
      Q => \^q\(20),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(21),
      Q => \^q\(21),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(22),
      Q => \^q\(22),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(23),
      Q => \^q\(23),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(24),
      Q => \^q\(24),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(25),
      Q => \^q\(25),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[25]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[17]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \ra_reg[25]_i_2_n_0\,
      CO(6) => \ra_reg[25]_i_2_n_1\,
      CO(5) => \ra_reg[25]_i_2_n_2\,
      CO(4) => \ra_reg[25]_i_2_n_3\,
      CO(3) => \ra_reg[25]_i_2_n_4\,
      CO(2) => \ra_reg[25]_i_2_n_5\,
      CO(1) => \ra_reg[25]_i_2_n_6\,
      CO(0) => \ra_reg[25]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in12(25 downto 18),
      S(7 downto 0) => \^q\(25 downto 18)
    );
\ra_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(26),
      Q => \^q\(26),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(27),
      Q => \^q\(27),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(28),
      Q => \^q\(28),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(29),
      Q => \^q\(29),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(2),
      Q => \^q\(2),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(30),
      Q => \^q\(30),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(31),
      Q => \^q\(31),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[32]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(32),
      Q => \^q\(32),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[33]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(33),
      Q => \^q\(33),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[33]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[25]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \ra_reg[33]_i_2_n_0\,
      CO(6) => \ra_reg[33]_i_2_n_1\,
      CO(5) => \ra_reg[33]_i_2_n_2\,
      CO(4) => \ra_reg[33]_i_2_n_3\,
      CO(3) => \ra_reg[33]_i_2_n_4\,
      CO(2) => \ra_reg[33]_i_2_n_5\,
      CO(1) => \ra_reg[33]_i_2_n_6\,
      CO(0) => \ra_reg[33]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in12(33 downto 26),
      S(7 downto 0) => \^q\(33 downto 26)
    );
\ra_reg[34]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(34),
      Q => \^q\(34),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[35]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(35),
      Q => \^q\(35),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[36]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(36),
      Q => \^q\(36),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[37]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(37),
      Q => \^q\(37),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[38]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(38),
      Q => \^q\(38),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[39]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(39),
      Q => \^q\(39),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(3),
      Q => \^q\(3),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[40]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(40),
      Q => \^q\(40),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[41]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(41),
      Q => \^q\(41),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[41]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[33]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \ra_reg[41]_i_2_n_0\,
      CO(6) => \ra_reg[41]_i_2_n_1\,
      CO(5) => \ra_reg[41]_i_2_n_2\,
      CO(4) => \ra_reg[41]_i_2_n_3\,
      CO(3) => \ra_reg[41]_i_2_n_4\,
      CO(2) => \ra_reg[41]_i_2_n_5\,
      CO(1) => \ra_reg[41]_i_2_n_6\,
      CO(0) => \ra_reg[41]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in12(41 downto 34),
      S(7 downto 0) => \^q\(41 downto 34)
    );
\ra_reg[42]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(42),
      Q => \^q\(42),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[43]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(43),
      Q => \^q\(43),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[44]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(44),
      Q => \^q\(44),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[45]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(45),
      Q => \^q\(45),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[46]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(46),
      Q => \^q\(46),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[47]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(47),
      Q => \^q\(47),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[48]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(48),
      Q => \^q\(48),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[49]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(49),
      Q => \^q\(49),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[49]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[41]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \ra_reg[49]_i_2_n_0\,
      CO(6) => \ra_reg[49]_i_2_n_1\,
      CO(5) => \ra_reg[49]_i_2_n_2\,
      CO(4) => \ra_reg[49]_i_2_n_3\,
      CO(3) => \ra_reg[49]_i_2_n_4\,
      CO(2) => \ra_reg[49]_i_2_n_5\,
      CO(1) => \ra_reg[49]_i_2_n_6\,
      CO(0) => \ra_reg[49]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in12(49 downto 42),
      S(7 downto 0) => \^q\(49 downto 42)
    );
\ra_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(4),
      Q => \^q\(4),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[50]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(50),
      Q => \^q\(50),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[51]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(51),
      Q => \^q\(51),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[52]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(52),
      Q => \^q\(52),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[53]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(53),
      Q => \^q\(53),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[54]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(54),
      Q => \^q\(54),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[55]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(55),
      Q => \^q\(55),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[56]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(56),
      Q => \^q\(56),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[57]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(57),
      Q => \^q\(57),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[57]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[49]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \ra_reg[57]_i_2_n_0\,
      CO(6) => \ra_reg[57]_i_2_n_1\,
      CO(5) => \ra_reg[57]_i_2_n_2\,
      CO(4) => \ra_reg[57]_i_2_n_3\,
      CO(3) => \ra_reg[57]_i_2_n_4\,
      CO(2) => \ra_reg[57]_i_2_n_5\,
      CO(1) => \ra_reg[57]_i_2_n_6\,
      CO(0) => \ra_reg[57]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in12(57 downto 50),
      S(7 downto 0) => \^q\(57 downto 50)
    );
\ra_reg[58]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(58),
      Q => \^q\(58),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[59]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(59),
      Q => \^q\(59),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(5),
      Q => \^q\(5),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[60]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(60),
      Q => \^q\(60),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[61]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(61),
      Q => \^q\(61),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[62]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(62),
      Q => \^q\(62),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[63]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(63),
      Q => \^q\(63),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[63]_i_6\: unisim.vcomponents.CARRY8
     port map (
      CI => \ra_reg[57]_i_2_n_0\,
      CI_TOP => '0',
      CO(7 downto 5) => \NLW_ra_reg[63]_i_6_CO_UNCONNECTED\(7 downto 5),
      CO(4) => \ra_reg[63]_i_6_n_3\,
      CO(3) => \ra_reg[63]_i_6_n_4\,
      CO(2) => \ra_reg[63]_i_6_n_5\,
      CO(1) => \ra_reg[63]_i_6_n_6\,
      CO(0) => \ra_reg[63]_i_6_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 6) => \NLW_ra_reg[63]_i_6_O_UNCONNECTED\(7 downto 6),
      O(5 downto 0) => in12(63 downto 58),
      S(7 downto 6) => B"00",
      S(5 downto 0) => \^q\(63 downto 58)
    );
\ra_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(6),
      Q => \^q\(6),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(7),
      Q => \^q\(7),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(8),
      Q => \^q\(8),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => ra(9),
      Q => \^q\(9),
      R => fdma_wdone_i_1_n_0
    );
\ra_reg[9]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => '0',
      CI_TOP => '0',
      CO(7) => \ra_reg[9]_i_2_n_0\,
      CO(6) => \ra_reg[9]_i_2_n_1\,
      CO(5) => \ra_reg[9]_i_2_n_2\,
      CO(4) => \ra_reg[9]_i_2_n_3\,
      CO(3) => \ra_reg[9]_i_2_n_4\,
      CO(2) => \ra_reg[9]_i_2_n_5\,
      CO(1) => \ra_reg[9]_i_2_n_6\,
      CO(0) => \ra_reg[9]_i_2_n_7\,
      DI(7 downto 1) => \^q\(9 downto 3),
      DI(0) => '0',
      O(7 downto 0) => in12(9 downto 2),
      S(7) => \ra[9]_i_3_n_0\,
      S(6) => \ra[9]_i_4_n_0\,
      S(5) => \ra[9]_i_5_n_0\,
      S(4) => \ra[9]_i_6_n_0\,
      S(3) => \ra[9]_i_7_n_0\,
      S(2) => \ra[9]_i_8_n_0\,
      S(1) => \ra[9]_i_9_n_0\,
      S(0) => \^q\(2)
    );
\rb[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA0C"
    )
        port map (
      I0 => \rleft_reg_n_0_[0]\,
      I1 => \rb[0]_i_2_n_0\,
      I2 => \rb[8]_i_4_n_0\,
      I3 => \update_wb.available1_carry__0_n_0\,
      O => \rb[0]_i_1_n_0\
    );
\rb[0]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"01FE"
    )
        port map (
      I0 => \^q\(2),
      I1 => \^q\(1),
      I2 => \^q\(0),
      I3 => \^q\(3),
      O => \rb[0]_i_2_n_0\
    );
\rb[1]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA0C"
    )
        port map (
      I0 => \rleft_reg_n_0_[1]\,
      I1 => \rb[1]_i_2_n_0\,
      I2 => \rb[8]_i_4_n_0\,
      I3 => \update_wb.available1_carry__0_n_0\,
      O => \rb[1]_i_1_n_0\
    );
\rb[1]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0001FFFE"
    )
        port map (
      I0 => \^q\(3),
      I1 => \^q\(0),
      I2 => \^q\(1),
      I3 => \^q\(2),
      I4 => \^q\(4),
      O => \rb[1]_i_2_n_0\
    );
\rb[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA0C"
    )
        port map (
      I0 => \rleft_reg_n_0_[2]\,
      I1 => \rb[2]_i_2_n_0\,
      I2 => \rb[8]_i_4_n_0\,
      I3 => \update_wb.available1_carry__0_n_0\,
      O => \rb[2]_i_1_n_0\
    );
\rb[2]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000001FFFFFFFE"
    )
        port map (
      I0 => \^q\(4),
      I1 => \^q\(2),
      I2 => \^q\(1),
      I3 => \^q\(0),
      I4 => \^q\(3),
      I5 => \^q\(5),
      O => \rb[2]_i_2_n_0\
    );
\rb[3]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAA00C3"
    )
        port map (
      I0 => \rleft_reg_n_0_[3]\,
      I1 => \^q\(6),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \rb[8]_i_4_n_0\,
      I4 => \update_wb.available1_carry__0_n_0\,
      O => \rb[3]_i_1_n_0\
    );
\rb[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAA000033C3"
    )
        port map (
      I0 => \rleft_reg_n_0_[4]\,
      I1 => \^q\(7),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \^q\(6),
      I4 => \rb[8]_i_4_n_0\,
      I5 => \update_wb.available1_carry__0_n_0\,
      O => \rb[4]_i_1_n_0\
    );
\rb[4]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000001"
    )
        port map (
      I0 => \^q\(4),
      I1 => \^q\(2),
      I2 => \^q\(1),
      I3 => \^q\(0),
      I4 => \^q\(3),
      I5 => \^q\(5),
      O => \rb[4]_i_2_n_0\
    );
\rb[5]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA0C"
    )
        port map (
      I0 => \rleft_reg_n_0_[5]\,
      I1 => \rb[5]_i_2_n_0\,
      I2 => \rb[8]_i_4_n_0\,
      I3 => \update_wb.available1_carry__0_n_0\,
      O => \rb[5]_i_1_n_0\
    );
\rb[5]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"04FB"
    )
        port map (
      I0 => \^q\(7),
      I1 => \rb[4]_i_2_n_0\,
      I2 => \^q\(6),
      I3 => \^q\(8),
      O => \rb[5]_i_2_n_0\
    );
\rb[6]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA0C"
    )
        port map (
      I0 => \rleft_reg_n_0_[6]\,
      I1 => \rb[6]_i_2_n_0\,
      I2 => \rb[8]_i_4_n_0\,
      I3 => \update_wb.available1_carry__0_n_0\,
      O => \rb[6]_i_1_n_0\
    );
\rb[6]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0010FFEF"
    )
        port map (
      I0 => \^q\(8),
      I1 => \^q\(6),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \^q\(7),
      I4 => \^q\(9),
      O => \rb[6]_i_2_n_0\
    );
\rb[7]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"AA0C"
    )
        port map (
      I0 => \rleft_reg_n_0_[7]\,
      I1 => \rb[7]_i_2_n_0\,
      I2 => \rb[8]_i_4_n_0\,
      I3 => \update_wb.available1_carry__0_n_0\,
      O => \rb[7]_i_1_n_0\
    );
\rb[7]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000010FFFFFFEF"
    )
        port map (
      I0 => \^q\(9),
      I1 => \^q\(7),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \^q\(6),
      I4 => \^q\(8),
      I5 => \^q\(10),
      O => \rb[7]_i_2_n_0\
    );
\rb[8]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \read_curr_st__0\(0),
      I1 => \read_curr_st__0\(1),
      O => rb
    );
\rb[8]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"AAAAFFC3"
    )
        port map (
      I0 => \rleft_reg_n_0_[8]\,
      I1 => \^q\(11),
      I2 => \rb[8]_i_3_n_0\,
      I3 => \rb[8]_i_4_n_0\,
      I4 => \update_wb.available1_carry__0_n_0\,
      O => \rb[8]_i_2_n_0\
    );
\rb[8]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000010"
    )
        port map (
      I0 => \^q\(9),
      I1 => \^q\(7),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \^q\(6),
      I4 => \^q\(8),
      I5 => \^q\(10),
      O => \rb[8]_i_3_n_0\
    );
\rb[8]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"30303020FFFFFFFB"
    )
        port map (
      I0 => \rb[8]_i_5_n_0\,
      I1 => \^q\(10),
      I2 => \rb[8]_i_6_n_0\,
      I3 => \rb[0]_i_2_n_0\,
      I4 => \rb[8]_i_7_n_0\,
      I5 => \^q\(11),
      O => \rb[8]_i_4_n_0\
    );
\rb[8]_i_5\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F7FFFFEF"
    )
        port map (
      I0 => \^q\(6),
      I1 => \^q\(4),
      I2 => \rb[8]_i_8_n_0\,
      I3 => \^q\(5),
      I4 => \^q\(7),
      O => \rb[8]_i_5_n_0\
    );
\rb[8]_i_6\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00000010"
    )
        port map (
      I0 => \^q\(8),
      I1 => \^q\(6),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \^q\(7),
      I4 => \^q\(9),
      O => \rb[8]_i_6_n_0\
    );
\rb[8]_i_7\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"5575FFEF"
    )
        port map (
      I0 => \^q\(9),
      I1 => \^q\(7),
      I2 => \rb[4]_i_2_n_0\,
      I3 => \^q\(6),
      I4 => \^q\(8),
      O => \rb[8]_i_7_n_0\
    );
\rb[8]_i_8\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0001"
    )
        port map (
      I0 => \^q\(2),
      I1 => \^q\(1),
      I2 => \^q\(0),
      I3 => \^q\(3),
      O => \rb[8]_i_8_n_0\
    );
\rb_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[0]_i_1_n_0\,
      Q => \rb_reg_n_0_[0]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[1]_i_1_n_0\,
      Q => \rb_reg_n_0_[1]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[2]_i_1_n_0\,
      Q => \rb_reg_n_0_[2]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[3]_i_1_n_0\,
      Q => \rb_reg_n_0_[3]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[4]_i_1_n_0\,
      Q => \rb_reg_n_0_[4]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[5]_i_1_n_0\,
      Q => \rb_reg_n_0_[5]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[6]_i_1_n_0\,
      Q => \rb_reg_n_0_[6]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[7]_i_1_n_0\,
      Q => \rb_reg_n_0_[7]\,
      R => fdma_wdone_i_1_n_0
    );
\rb_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rb,
      D => \rb[8]_i_2_n_0\,
      Q => \rb_reg_n_0_[8]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[0]\,
      O => rbeat(0)
    );
\rbeat[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"28"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[1]\,
      I2 => \rbeat_reg_n_0_[0]\,
      O => \rbeat[1]_i_1_n_0\
    );
\rbeat[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2888"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[2]\,
      I2 => \rbeat_reg_n_0_[1]\,
      I3 => \rbeat_reg_n_0_[0]\,
      O => \rbeat[2]_i_1_n_0\
    );
\rbeat[3]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"28888888"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[3]\,
      I2 => \rbeat_reg_n_0_[2]\,
      I3 => \rbeat_reg_n_0_[0]\,
      I4 => \rbeat_reg_n_0_[1]\,
      O => \rbeat[3]_i_1_n_0\
    );
\rbeat[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"2888888888888888"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[4]\,
      I2 => \rbeat_reg_n_0_[3]\,
      I3 => \rbeat_reg_n_0_[1]\,
      I4 => \rbeat_reg_n_0_[0]\,
      I5 => \rbeat_reg_n_0_[2]\,
      O => \rbeat[4]_i_1_n_0\
    );
\rbeat[5]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"28"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[5]\,
      I2 => \rbeat[5]_i_2_n_0\,
      O => \rbeat[5]_i_1_n_0\
    );
\rbeat[5]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \rbeat_reg_n_0_[4]\,
      I1 => \rbeat_reg_n_0_[2]\,
      I2 => \rbeat_reg_n_0_[0]\,
      I3 => \rbeat_reg_n_0_[1]\,
      I4 => \rbeat_reg_n_0_[3]\,
      O => \rbeat[5]_i_2_n_0\
    );
\rbeat[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"28"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[6]\,
      I2 => \rbeat[8]_i_3_n_0\,
      O => \rbeat[6]_i_1_n_0\
    );
\rbeat[7]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"2888"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[7]\,
      I2 => \rbeat_reg_n_0_[6]\,
      I3 => \rbeat[8]_i_3_n_0\,
      O => \rbeat[7]_i_1_n_0\
    );
\rbeat[8]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"22A2"
    )
        port map (
      I0 => \read_curr_st__0\(0),
      I1 => \read_curr_st__0\(1),
      I2 => \^m_axi_rvalid_0\,
      I3 => \read_next_st0__16\,
      O => rbeat_3
    );
\rbeat[8]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"28888888"
    )
        port map (
      I0 => \read_curr_st__0\(1),
      I1 => \rbeat_reg_n_0_[8]\,
      I2 => \rbeat_reg_n_0_[7]\,
      I3 => \rbeat[8]_i_3_n_0\,
      I4 => \rbeat_reg_n_0_[6]\,
      O => \rbeat[8]_i_2_n_0\
    );
\rbeat[8]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"8000000000000000"
    )
        port map (
      I0 => \rbeat_reg_n_0_[5]\,
      I1 => \rbeat_reg_n_0_[3]\,
      I2 => \rbeat_reg_n_0_[1]\,
      I3 => \rbeat_reg_n_0_[0]\,
      I4 => \rbeat_reg_n_0_[2]\,
      I5 => \rbeat_reg_n_0_[4]\,
      O => \rbeat[8]_i_3_n_0\
    );
\rbeat_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => rbeat(0),
      Q => \rbeat_reg_n_0_[0]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[1]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[1]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[2]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[2]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[3]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[3]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[4]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[4]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[5]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[5]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[6]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[6]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[7]_i_1_n_0\,
      Q => \rbeat_reg_n_0_[7]\,
      R => fdma_wdone_i_1_n_0
    );
\rbeat_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => rbeat_3,
      D => \rbeat[8]_i_2_n_0\,
      Q => \rbeat_reg_n_0_[8]\,
      R => fdma_wdone_i_1_n_0
    );
\read_curr_st[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"5D"
    )
        port map (
      I0 => read_curr_st(0),
      I1 => read_curr_st(1),
      I2 => \ra[63]_i_4_n_0\,
      O => \read_curr_st[0]_i_1_n_0\
    );
\read_curr_st[1]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => read_curr_st(0),
      I1 => read_curr_st(1),
      O => \read_curr_st[1]_i_1_n_0\
    );
\read_curr_st_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => read_next_st,
      D => \read_curr_st[0]_i_1_n_0\,
      Q => read_curr_st(0),
      R => fdma_wdone_i_1_n_0
    );
\read_curr_st_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => read_next_st,
      D => \read_curr_st[1]_i_1_n_0\,
      Q => read_curr_st(1),
      R => fdma_wdone_i_1_n_0
    );
\rleft[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_15\,
      I1 => fdma_rsize(0),
      I2 => \read_curr_st__0\(1),
      O => rleft(0)
    );
\rleft[10]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_13\,
      I1 => fdma_rsize(10),
      I2 => \read_curr_st__0\(1),
      O => rleft(10)
    );
\rleft[11]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_12\,
      I1 => fdma_rsize(11),
      I2 => \read_curr_st__0\(1),
      O => rleft(11)
    );
\rleft[12]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_11\,
      I1 => fdma_rsize(12),
      I2 => \read_curr_st__0\(1),
      O => rleft(12)
    );
\rleft[13]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_10\,
      I1 => fdma_rsize(13),
      I2 => \read_curr_st__0\(1),
      O => rleft(13)
    );
\rleft[14]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_9\,
      I1 => fdma_rsize(14),
      I2 => \read_curr_st__0\(1),
      O => rleft(14)
    );
\rleft[15]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_8\,
      I1 => fdma_rsize(15),
      I2 => \read_curr_st__0\(1),
      O => rleft(15)
    );
\rleft[15]_i_10\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[8]\,
      I1 => \rb_reg_n_0_[8]\,
      O => \rleft[15]_i_10_n_0\
    );
\rleft[15]_i_3\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[15]\,
      O => \rleft[15]_i_3_n_0\
    );
\rleft[15]_i_4\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[14]\,
      O => \rleft[15]_i_4_n_0\
    );
\rleft[15]_i_5\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[13]\,
      O => \rleft[15]_i_5_n_0\
    );
\rleft[15]_i_6\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[12]\,
      O => \rleft[15]_i_6_n_0\
    );
\rleft[15]_i_7\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[11]\,
      O => \rleft[15]_i_7_n_0\
    );
\rleft[15]_i_8\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[10]\,
      O => \rleft[15]_i_8_n_0\
    );
\rleft[15]_i_9\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[9]\,
      O => \rleft[15]_i_9_n_0\
    );
\rleft[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_14\,
      I1 => fdma_rsize(1),
      I2 => \read_curr_st__0\(1),
      O => rleft(1)
    );
\rleft[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_13\,
      I1 => fdma_rsize(2),
      I2 => \read_curr_st__0\(1),
      O => rleft(2)
    );
\rleft[3]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_12\,
      I1 => fdma_rsize(3),
      I2 => \read_curr_st__0\(1),
      O => rleft(3)
    );
\rleft[4]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_11\,
      I1 => fdma_rsize(4),
      I2 => \read_curr_st__0\(1),
      O => rleft(4)
    );
\rleft[5]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_10\,
      I1 => fdma_rsize(5),
      I2 => \read_curr_st__0\(1),
      O => rleft(5)
    );
\rleft[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_9\,
      I1 => fdma_rsize(6),
      I2 => \read_curr_st__0\(1),
      O => rleft(6)
    );
\rleft[7]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[7]_i_2_n_8\,
      I1 => fdma_rsize(7),
      I2 => \read_curr_st__0\(1),
      O => rleft(7)
    );
\rleft[7]_i_10\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[0]\,
      I1 => \rb_reg_n_0_[0]\,
      O => \rleft[7]_i_10_n_0\
    );
\rleft[7]_i_3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[7]\,
      I1 => \rb_reg_n_0_[7]\,
      O => \rleft[7]_i_3_n_0\
    );
\rleft[7]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[6]\,
      I1 => \rb_reg_n_0_[6]\,
      O => \rleft[7]_i_4_n_0\
    );
\rleft[7]_i_5\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[5]\,
      I1 => \rb_reg_n_0_[5]\,
      O => \rleft[7]_i_5_n_0\
    );
\rleft[7]_i_6\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[4]\,
      I1 => \rb_reg_n_0_[4]\,
      O => \rleft[7]_i_6_n_0\
    );
\rleft[7]_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[3]\,
      I1 => \rb_reg_n_0_[3]\,
      O => \rleft[7]_i_7_n_0\
    );
\rleft[7]_i_8\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[2]\,
      I1 => \rb_reg_n_0_[2]\,
      O => \rleft[7]_i_8_n_0\
    );
\rleft[7]_i_9\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \rleft_reg_n_0_[1]\,
      I1 => \rb_reg_n_0_[1]\,
      O => \rleft[7]_i_9_n_0\
    );
\rleft[8]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_15\,
      I1 => fdma_rsize(8),
      I2 => \read_curr_st__0\(1),
      O => rleft(8)
    );
\rleft[9]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"AC"
    )
        port map (
      I0 => \rleft_reg[15]_i_2_n_14\,
      I1 => fdma_rsize(9),
      I2 => \read_curr_st__0\(1),
      O => rleft(9)
    );
\rleft_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(0),
      Q => \rleft_reg_n_0_[0]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(10),
      Q => \rleft_reg_n_0_[10]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(11),
      Q => \rleft_reg_n_0_[11]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(12),
      Q => \rleft_reg_n_0_[12]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(13),
      Q => \rleft_reg_n_0_[13]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(14),
      Q => \rleft_reg_n_0_[14]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(15),
      Q => \rleft_reg_n_0_[15]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[15]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \rleft_reg[7]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \NLW_rleft_reg[15]_i_2_CO_UNCONNECTED\(7),
      CO(6) => \rleft_reg[15]_i_2_n_1\,
      CO(5) => \rleft_reg[15]_i_2_n_2\,
      CO(4) => \rleft_reg[15]_i_2_n_3\,
      CO(3) => \rleft_reg[15]_i_2_n_4\,
      CO(2) => \rleft_reg[15]_i_2_n_5\,
      CO(1) => \rleft_reg[15]_i_2_n_6\,
      CO(0) => \rleft_reg[15]_i_2_n_7\,
      DI(7) => '0',
      DI(6) => \rleft_reg_n_0_[14]\,
      DI(5) => \rleft_reg_n_0_[13]\,
      DI(4) => \rleft_reg_n_0_[12]\,
      DI(3) => \rleft_reg_n_0_[11]\,
      DI(2) => \rleft_reg_n_0_[10]\,
      DI(1) => \rleft_reg_n_0_[9]\,
      DI(0) => \rleft_reg_n_0_[8]\,
      O(7) => \rleft_reg[15]_i_2_n_8\,
      O(6) => \rleft_reg[15]_i_2_n_9\,
      O(5) => \rleft_reg[15]_i_2_n_10\,
      O(4) => \rleft_reg[15]_i_2_n_11\,
      O(3) => \rleft_reg[15]_i_2_n_12\,
      O(2) => \rleft_reg[15]_i_2_n_13\,
      O(1) => \rleft_reg[15]_i_2_n_14\,
      O(0) => \rleft_reg[15]_i_2_n_15\,
      S(7) => \rleft[15]_i_3_n_0\,
      S(6) => \rleft[15]_i_4_n_0\,
      S(5) => \rleft[15]_i_5_n_0\,
      S(4) => \rleft[15]_i_6_n_0\,
      S(3) => \rleft[15]_i_7_n_0\,
      S(2) => \rleft[15]_i_8_n_0\,
      S(1) => \rleft[15]_i_9_n_0\,
      S(0) => \rleft[15]_i_10_n_0\
    );
\rleft_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(1),
      Q => \rleft_reg_n_0_[1]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(2),
      Q => \rleft_reg_n_0_[2]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(3),
      Q => \rleft_reg_n_0_[3]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(4),
      Q => \rleft_reg_n_0_[4]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(5),
      Q => \rleft_reg_n_0_[5]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(6),
      Q => \rleft_reg_n_0_[6]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(7),
      Q => \rleft_reg_n_0_[7]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[7]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => '1',
      CI_TOP => '0',
      CO(7) => \rleft_reg[7]_i_2_n_0\,
      CO(6) => \rleft_reg[7]_i_2_n_1\,
      CO(5) => \rleft_reg[7]_i_2_n_2\,
      CO(4) => \rleft_reg[7]_i_2_n_3\,
      CO(3) => \rleft_reg[7]_i_2_n_4\,
      CO(2) => \rleft_reg[7]_i_2_n_5\,
      CO(1) => \rleft_reg[7]_i_2_n_6\,
      CO(0) => \rleft_reg[7]_i_2_n_7\,
      DI(7) => \rleft_reg_n_0_[7]\,
      DI(6) => \rleft_reg_n_0_[6]\,
      DI(5) => \rleft_reg_n_0_[5]\,
      DI(4) => \rleft_reg_n_0_[4]\,
      DI(3) => \rleft_reg_n_0_[3]\,
      DI(2) => \rleft_reg_n_0_[2]\,
      DI(1) => \rleft_reg_n_0_[1]\,
      DI(0) => \rleft_reg_n_0_[0]\,
      O(7) => \rleft_reg[7]_i_2_n_8\,
      O(6) => \rleft_reg[7]_i_2_n_9\,
      O(5) => \rleft_reg[7]_i_2_n_10\,
      O(4) => \rleft_reg[7]_i_2_n_11\,
      O(3) => \rleft_reg[7]_i_2_n_12\,
      O(2) => \rleft_reg[7]_i_2_n_13\,
      O(1) => \rleft_reg[7]_i_2_n_14\,
      O(0) => \rleft_reg[7]_i_2_n_15\,
      S(7) => \rleft[7]_i_3_n_0\,
      S(6) => \rleft[7]_i_4_n_0\,
      S(5) => \rleft[7]_i_5_n_0\,
      S(4) => \rleft[7]_i_6_n_0\,
      S(3) => \rleft[7]_i_7_n_0\,
      S(2) => \rleft[7]_i_8_n_0\,
      S(1) => \rleft[7]_i_9_n_0\,
      S(0) => \rleft[7]_i_10_n_0\
    );
\rleft_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(8),
      Q => \rleft_reg_n_0_[8]\,
      R => fdma_wdone_i_1_n_0
    );
\rleft_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => ra_2,
      D => rleft(9),
      Q => \rleft_reg_n_0_[9]\,
      R => fdma_wdone_i_1_n_0
    );
\update_wb.available1_carry\: unisim.vcomponents.CARRY8
     port map (
      CI => '0',
      CI_TOP => '0',
      CO(7) => \update_wb.available1\,
      CO(6) => \update_wb.available1_carry_n_1\,
      CO(5) => \update_wb.available1_carry_n_2\,
      CO(4) => \update_wb.available1_carry_n_3\,
      CO(3) => \update_wb.available1_carry_n_4\,
      CO(2) => \update_wb.available1_carry_n_5\,
      CO(1) => \update_wb.available1_carry_n_6\,
      CO(0) => \update_wb.available1_carry_n_7\,
      DI(7 downto 5) => B"000",
      DI(4) => \update_wb.available1_carry_i_1_n_0\,
      DI(3) => \update_wb.available1_carry_i_2_n_0\,
      DI(2) => \update_wb.available1_carry_i_3_n_0\,
      DI(1) => \update_wb.available1_carry_i_4_n_0\,
      DI(0) => \update_wb.available1_carry_i_5_n_0\,
      O(7 downto 0) => \NLW_update_wb.available1_carry_O_UNCONNECTED\(7 downto 0),
      S(7) => \update_wb.available1_carry_i_6_n_0\,
      S(6) => \update_wb.available1_carry_i_7_n_0\,
      S(5) => \update_wb.available1_carry_i_8_n_0\,
      S(4) => \update_wb.available1_carry_i_9_n_0\,
      S(3) => \update_wb.available1_carry_i_10_n_0\,
      S(2) => \update_wb.available1_carry_i_11_n_0\,
      S(1) => \update_wb.available1_carry_i_12_n_0\,
      S(0) => \update_wb.available1_carry_i_13_n_0\
    );
\update_wb.available1_carry__0\: unisim.vcomponents.CARRY8
     port map (
      CI => '0',
      CI_TOP => '0',
      CO(7) => \update_wb.available1_carry__0_n_0\,
      CO(6) => \update_wb.available1_carry__0_n_1\,
      CO(5) => \update_wb.available1_carry__0_n_2\,
      CO(4) => \update_wb.available1_carry__0_n_3\,
      CO(3) => \update_wb.available1_carry__0_n_4\,
      CO(2) => \update_wb.available1_carry__0_n_5\,
      CO(1) => \update_wb.available1_carry__0_n_6\,
      CO(0) => \update_wb.available1_carry__0_n_7\,
      DI(7 downto 5) => B"000",
      DI(4) => \update_wb.available1_carry_i_1__0_n_0\,
      DI(3) => \update_wb.available1_carry_i_2__0_n_0\,
      DI(2) => \update_wb.available1_carry_i_3__0_n_0\,
      DI(1) => \update_wb.available1_carry_i_4__0_n_0\,
      DI(0) => \update_wb.available1_carry_i_5__0_n_0\,
      O(7 downto 0) => \NLW_update_wb.available1_carry__0_O_UNCONNECTED\(7 downto 0),
      S(7) => \update_wb.available1_carry_i_6__0_n_0\,
      S(6) => \update_wb.available1_carry_i_7__0_n_0\,
      S(5) => \update_wb.available1_carry_i_8__0_n_0\,
      S(4) => \update_wb.available1_carry_i_9__0_n_0\,
      S(3) => \update_wb.available1_carry_i_10__0_n_0\,
      S(2) => \update_wb.available1_carry_i_11__0_n_0\,
      S(1) => \update_wb.available1_carry_i_12__0_n_0\,
      S(0) => \update_wb.available1_carry_i_13__0_n_0\
    );
\update_wb.available1_carry_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"000100F7"
    )
        port map (
      I0 => \^wa_reg[63]_0\(11),
      I1 => \wb[8]_i_3_n_0\,
      I2 => \wb[8]_i_4_n_0\,
      I3 => \wleft_reg_n_0_[9]\,
      I4 => \wleft_reg_n_0_[8]\,
      O => \update_wb.available1_carry_i_1_n_0\
    );
\update_wb.available1_carry_i_10\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000900900024FF42"
    )
        port map (
      I0 => \wb[6]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(9),
      I2 => \^wa_reg[63]_0\(10),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[7]\,
      I5 => \wleft_reg_n_0_[6]\,
      O => \update_wb.available1_carry_i_10_n_0\
    );
\update_wb.available1_carry_i_10__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000214255558418"
    )
        port map (
      I0 => \rleft_reg_n_0_[6]\,
      I1 => \^q\(10),
      I2 => \update_wb.available1_carry_i_14__0_n_0\,
      I3 => \^q\(9),
      I4 => \rb[8]_i_4_n_0\,
      I5 => \rleft_reg_n_0_[7]\,
      O => \update_wb.available1_carry_i_10__0_n_0\
    );
\update_wb.available1_carry_i_11\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000900900024FF42"
    )
        port map (
      I0 => \update_wb.available1_carry_i_14_n_0\,
      I1 => \^wa_reg[63]_0\(7),
      I2 => \^wa_reg[63]_0\(8),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[5]\,
      I5 => \wleft_reg_n_0_[4]\,
      O => \update_wb.available1_carry_i_11_n_0\
    );
\update_wb.available1_carry_i_11__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000214255558418"
    )
        port map (
      I0 => \rleft_reg_n_0_[4]\,
      I1 => \^q\(8),
      I2 => \update_wb.available1_carry_i_15__0_n_0\,
      I3 => \^q\(7),
      I4 => \rb[8]_i_4_n_0\,
      I5 => \rleft_reg_n_0_[5]\,
      O => \update_wb.available1_carry_i_11__0_n_0\
    );
\update_wb.available1_carry_i_12\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000900900024FF42"
    )
        port map (
      I0 => \update_wb.available1_carry_i_15_n_0\,
      I1 => \^wa_reg[63]_0\(5),
      I2 => \^wa_reg[63]_0\(6),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[3]\,
      I5 => \wleft_reg_n_0_[2]\,
      O => \update_wb.available1_carry_i_12_n_0\
    );
\update_wb.available1_carry_i_12__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000214255558418"
    )
        port map (
      I0 => \rleft_reg_n_0_[2]\,
      I1 => \^q\(6),
      I2 => \update_wb.available1_carry_i_16__0_n_0\,
      I3 => \^q\(5),
      I4 => \rb[8]_i_4_n_0\,
      I5 => \rleft_reg_n_0_[3]\,
      O => \update_wb.available1_carry_i_12__0_n_0\
    );
\update_wb.available1_carry_i_13\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"000900900024FF42"
    )
        port map (
      I0 => \update_wb.available1_carry_i_16_n_0\,
      I1 => \^wa_reg[63]_0\(3),
      I2 => \^wa_reg[63]_0\(4),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[1]\,
      I5 => \wleft_reg_n_0_[0]\,
      O => \update_wb.available1_carry_i_13_n_0\
    );
\update_wb.available1_carry_i_13__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000214255558418"
    )
        port map (
      I0 => \rleft_reg_n_0_[0]\,
      I1 => \^q\(4),
      I2 => \update_wb.available1_carry_i_17_n_0\,
      I3 => \^q\(3),
      I4 => \rb[8]_i_4_n_0\,
      I5 => \rleft_reg_n_0_[1]\,
      O => \update_wb.available1_carry_i_13__0_n_0\
    );
\update_wb.available1_carry_i_14\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wb[4]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(6),
      O => \update_wb.available1_carry_i_14_n_0\
    );
\update_wb.available1_carry_i_14__0\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0004"
    )
        port map (
      I0 => \^q\(7),
      I1 => \rb[4]_i_2_n_0\,
      I2 => \^q\(6),
      I3 => \^q\(8),
      O => \update_wb.available1_carry_i_14__0_n_0\
    );
\update_wb.available1_carry_i_15\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00000001"
    )
        port map (
      I0 => \^wa_reg[63]_0\(1),
      I1 => \^wa_reg[63]_0\(0),
      I2 => \^wa_reg[63]_0\(2),
      I3 => \^wa_reg[63]_0\(3),
      I4 => \^wa_reg[63]_0\(4),
      O => \update_wb.available1_carry_i_15_n_0\
    );
\update_wb.available1_carry_i_15__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \rb[4]_i_2_n_0\,
      I1 => \^q\(6),
      O => \update_wb.available1_carry_i_15__0_n_0\
    );
\update_wb.available1_carry_i_16\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"01"
    )
        port map (
      I0 => \^wa_reg[63]_0\(1),
      I1 => \^wa_reg[63]_0\(0),
      I2 => \^wa_reg[63]_0\(2),
      O => \update_wb.available1_carry_i_16_n_0\
    );
\update_wb.available1_carry_i_16__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00000001"
    )
        port map (
      I0 => \^q\(3),
      I1 => \^q\(0),
      I2 => \^q\(1),
      I3 => \^q\(2),
      I4 => \^q\(4),
      O => \update_wb.available1_carry_i_16__0_n_0\
    );
\update_wb.available1_carry_i_17\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"01"
    )
        port map (
      I0 => \^q\(0),
      I1 => \^q\(1),
      I2 => \^q\(2),
      O => \update_wb.available1_carry_i_17_n_0\
    );
\update_wb.available1_carry_i_1__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"11111301"
    )
        port map (
      I0 => \rleft_reg_n_0_[8]\,
      I1 => \rleft_reg_n_0_[9]\,
      I2 => \^q\(11),
      I3 => \rb[8]_i_3_n_0\,
      I4 => \rb[8]_i_4_n_0\,
      O => \update_wb.available1_carry_i_1__0_n_0\
    );
\update_wb.available1_carry_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002D000900BD"
    )
        port map (
      I0 => \wb[6]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(9),
      I2 => \^wa_reg[63]_0\(10),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[7]\,
      I5 => \wleft_reg_n_0_[6]\,
      O => \update_wb.available1_carry_i_2_n_0\
    );
\update_wb.available1_carry_i_2__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000017033017"
    )
        port map (
      I0 => \rleft_reg_n_0_[6]\,
      I1 => \rleft_reg_n_0_[7]\,
      I2 => \^q\(10),
      I3 => \update_wb.available1_carry_i_14__0_n_0\,
      I4 => \^q\(9),
      I5 => \rb[8]_i_4_n_0\,
      O => \update_wb.available1_carry_i_2__0_n_0\
    );
\update_wb.available1_carry_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002D000900BD"
    )
        port map (
      I0 => \update_wb.available1_carry_i_14_n_0\,
      I1 => \^wa_reg[63]_0\(7),
      I2 => \^wa_reg[63]_0\(8),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[5]\,
      I5 => \wleft_reg_n_0_[4]\,
      O => \update_wb.available1_carry_i_3_n_0\
    );
\update_wb.available1_carry_i_3__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000017033017"
    )
        port map (
      I0 => \rleft_reg_n_0_[4]\,
      I1 => \rleft_reg_n_0_[5]\,
      I2 => \^q\(8),
      I3 => \update_wb.available1_carry_i_15__0_n_0\,
      I4 => \^q\(7),
      I5 => \rb[8]_i_4_n_0\,
      O => \update_wb.available1_carry_i_3__0_n_0\
    );
\update_wb.available1_carry_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002D000900BD"
    )
        port map (
      I0 => \update_wb.available1_carry_i_15_n_0\,
      I1 => \^wa_reg[63]_0\(5),
      I2 => \^wa_reg[63]_0\(6),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[3]\,
      I5 => \wleft_reg_n_0_[2]\,
      O => \update_wb.available1_carry_i_4_n_0\
    );
\update_wb.available1_carry_i_4__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000017033017"
    )
        port map (
      I0 => \rleft_reg_n_0_[2]\,
      I1 => \rleft_reg_n_0_[3]\,
      I2 => \^q\(6),
      I3 => \update_wb.available1_carry_i_16__0_n_0\,
      I4 => \^q\(5),
      I5 => \rb[8]_i_4_n_0\,
      O => \update_wb.available1_carry_i_4__0_n_0\
    );
\update_wb.available1_carry_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000002D000900BD"
    )
        port map (
      I0 => \update_wb.available1_carry_i_16_n_0\,
      I1 => \^wa_reg[63]_0\(3),
      I2 => \^wa_reg[63]_0\(4),
      I3 => \wb[8]_i_4_n_0\,
      I4 => \wleft_reg_n_0_[1]\,
      I5 => \wleft_reg_n_0_[0]\,
      O => \update_wb.available1_carry_i_5_n_0\
    );
\update_wb.available1_carry_i_5__0\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000017033017"
    )
        port map (
      I0 => \rleft_reg_n_0_[0]\,
      I1 => \rleft_reg_n_0_[1]\,
      I2 => \^q\(4),
      I3 => \update_wb.available1_carry_i_17_n_0\,
      I4 => \^q\(3),
      I5 => \rb[8]_i_4_n_0\,
      O => \update_wb.available1_carry_i_5__0_n_0\
    );
\update_wb.available1_carry_i_6\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[15]\,
      I1 => \wleft_reg_n_0_[14]\,
      O => \update_wb.available1_carry_i_6_n_0\
    );
\update_wb.available1_carry_i_6__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[14]\,
      I1 => \rleft_reg_n_0_[15]\,
      O => \update_wb.available1_carry_i_6__0_n_0\
    );
\update_wb.available1_carry_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[13]\,
      I1 => \wleft_reg_n_0_[12]\,
      O => \update_wb.available1_carry_i_7_n_0\
    );
\update_wb.available1_carry_i_7__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[12]\,
      I1 => \rleft_reg_n_0_[13]\,
      O => \update_wb.available1_carry_i_7__0_n_0\
    );
\update_wb.available1_carry_i_8\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[11]\,
      I1 => \wleft_reg_n_0_[10]\,
      O => \update_wb.available1_carry_i_8_n_0\
    );
\update_wb.available1_carry_i_8__0\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \rleft_reg_n_0_[10]\,
      I1 => \rleft_reg_n_0_[11]\,
      O => \update_wb.available1_carry_i_8__0_n_0\
    );
\update_wb.available1_carry_i_9\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00F60108"
    )
        port map (
      I0 => \^wa_reg[63]_0\(11),
      I1 => \wb[8]_i_3_n_0\,
      I2 => \wb[8]_i_4_n_0\,
      I3 => \wleft_reg_n_0_[9]\,
      I4 => \wleft_reg_n_0_[8]\,
      O => \update_wb.available1_carry_i_9_n_0\
    );
\update_wb.available1_carry_i_9__0\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0010AA86"
    )
        port map (
      I0 => \rleft_reg_n_0_[8]\,
      I1 => \^q\(11),
      I2 => \rb[8]_i_3_n_0\,
      I3 => \rb[8]_i_4_n_0\,
      I4 => \rleft_reg_n_0_[9]\,
      O => \update_wb.available1_carry_i_9__0_n_0\
    );
w_pending_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFF7FFF00FF0000"
    )
        port map (
      I0 => \^m_axi_wlast\,
      I1 => M_AXI_WREADY,
      I2 => \^m_axi_wvalid\,
      I3 => \write_curr_st__0\(1),
      I4 => \write_curr_st__0\(0),
      I5 => w_pending_reg_n_0,
      O => w_pending_i_1_n_0
    );
w_pending_reg: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => '1',
      D => w_pending_i_1_n_0,
      Q => w_pending_reg_n_0,
      R => fdma_wdone_i_1_n_0
    );
\wa[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => \^wa_reg[63]_0\(0),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(0),
      O => wa(0)
    );
\wa[10]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(10),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(10),
      O => wa(10)
    );
\wa[11]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(11),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(11),
      O => wa(11)
    );
\wa[12]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(12),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(12),
      O => wa(12)
    );
\wa[13]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(13),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(13),
      O => wa(13)
    );
\wa[14]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(14),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(14),
      O => wa(14)
    );
\wa[15]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(15),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(15),
      O => wa(15)
    );
\wa[16]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(16),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(16),
      O => wa(16)
    );
\wa[17]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(17),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(17),
      O => wa(17)
    );
\wa[17]_i_3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(11),
      I1 => \wb_reg_n_0_[8]\,
      O => \wa[17]_i_3_n_0\
    );
\wa[17]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(10),
      I1 => \wb_reg_n_0_[7]\,
      O => \wa[17]_i_4_n_0\
    );
\wa[18]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(18),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(18),
      O => wa(18)
    );
\wa[19]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(19),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(19),
      O => wa(19)
    );
\wa[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => \^wa_reg[63]_0\(1),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(1),
      O => wa(1)
    );
\wa[20]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(20),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(20),
      O => wa(20)
    );
\wa[21]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(21),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(21),
      O => wa(21)
    );
\wa[22]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(22),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(22),
      O => wa(22)
    );
\wa[23]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(23),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(23),
      O => wa(23)
    );
\wa[24]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(24),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(24),
      O => wa(24)
    );
\wa[25]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(25),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(25),
      O => wa(25)
    );
\wa[26]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(26),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(26),
      O => wa(26)
    );
\wa[27]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(27),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(27),
      O => wa(27)
    );
\wa[28]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(28),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(28),
      O => wa(28)
    );
\wa[29]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(29),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(29),
      O => wa(29)
    );
\wa[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(2),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(2),
      O => wa(2)
    );
\wa[30]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(30),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(30),
      O => wa(30)
    );
\wa[31]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(31),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(31),
      O => wa(31)
    );
\wa[32]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(32),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(32),
      O => wa(32)
    );
\wa[33]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(33),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(33),
      O => wa(33)
    );
\wa[34]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(34),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(34),
      O => wa(34)
    );
\wa[35]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(35),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(35),
      O => wa(35)
    );
\wa[36]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(36),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(36),
      O => wa(36)
    );
\wa[37]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(37),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(37),
      O => wa(37)
    );
\wa[38]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(38),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(38),
      O => wa(38)
    );
\wa[39]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(39),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(39),
      O => wa(39)
    );
\wa[3]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(3),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(3),
      O => wa(3)
    );
\wa[40]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(40),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(40),
      O => wa(40)
    );
\wa[41]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(41),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(41),
      O => wa(41)
    );
\wa[42]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(42),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(42),
      O => wa(42)
    );
\wa[43]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(43),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(43),
      O => wa(43)
    );
\wa[44]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(44),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(44),
      O => wa(44)
    );
\wa[45]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(45),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(45),
      O => wa(45)
    );
\wa[46]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(46),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(46),
      O => wa(46)
    );
\wa[47]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(47),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(47),
      O => wa(47)
    );
\wa[48]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(48),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(48),
      O => wa(48)
    );
\wa[49]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(49),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(49),
      O => wa(49)
    );
\wa[4]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(4),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(4),
      O => wa(4)
    );
\wa[50]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(50),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(50),
      O => wa(50)
    );
\wa[51]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(51),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(51),
      O => wa(51)
    );
\wa[52]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(52),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(52),
      O => wa(52)
    );
\wa[53]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(53),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(53),
      O => wa(53)
    );
\wa[54]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(54),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(54),
      O => wa(54)
    );
\wa[55]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(55),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(55),
      O => wa(55)
    );
\wa[56]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(56),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(56),
      O => wa(56)
    );
\wa[57]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(57),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(57),
      O => wa(57)
    );
\wa[58]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(58),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(58),
      O => wa(58)
    );
\wa[59]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(59),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(59),
      O => wa(59)
    );
\wa[5]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(5),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(5),
      O => wa(5)
    );
\wa[60]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(60),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(60),
      O => wa(60)
    );
\wa[61]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(61),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(61),
      O => wa(61)
    );
\wa[62]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(62),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(62),
      O => wa(62)
    );
\wa[63]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"44004400000F0000"
    )
        port map (
      I0 => \write_next_st1__23\,
      I1 => \wa[63]_i_3_n_0\,
      I2 => fdma_wdone_i_4_n_0,
      I3 => \write_curr_st__0\(1),
      I4 => fdma_wareq,
      I5 => \write_curr_st__0\(0),
      O => wa_0
    );
\wa[63]_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(63),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(63),
      O => wa(63)
    );
\wa[63]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => write_curr_st(0),
      I1 => write_curr_st(1),
      I2 => M_AXI_BVALID,
      O => \wa[63]_i_3_n_0\
    );
\wa[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(6),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(6),
      O => wa(6)
    );
\wa[7]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(7),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(7),
      O => wa(7)
    );
\wa[8]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(8),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(8),
      O => wa(8)
    );
\wa[9]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in14(9),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_waddr(9),
      O => wa(9)
    );
\wa[9]_i_3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(9),
      I1 => \wb_reg_n_0_[6]\,
      O => \wa[9]_i_3_n_0\
    );
\wa[9]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(8),
      I1 => \wb_reg_n_0_[5]\,
      O => \wa[9]_i_4_n_0\
    );
\wa[9]_i_5\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(7),
      I1 => \wb_reg_n_0_[4]\,
      O => \wa[9]_i_5_n_0\
    );
\wa[9]_i_6\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(6),
      I1 => \wb_reg_n_0_[3]\,
      O => \wa[9]_i_6_n_0\
    );
\wa[9]_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(5),
      I1 => \wb_reg_n_0_[2]\,
      O => \wa[9]_i_7_n_0\
    );
\wa[9]_i_8\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(4),
      I1 => \wb_reg_n_0_[1]\,
      O => \wa[9]_i_8_n_0\
    );
\wa[9]_i_9\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => \^wa_reg[63]_0\(3),
      I1 => \wb_reg_n_0_[0]\,
      O => \wa[9]_i_9_n_0\
    );
\wa_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(0),
      Q => \^wa_reg[63]_0\(0),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(10),
      Q => \^wa_reg[63]_0\(10),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(11),
      Q => \^wa_reg[63]_0\(11),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(12),
      Q => \^wa_reg[63]_0\(12),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(13),
      Q => \^wa_reg[63]_0\(13),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(14),
      Q => \^wa_reg[63]_0\(14),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(15),
      Q => \^wa_reg[63]_0\(15),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(16),
      Q => \^wa_reg[63]_0\(16),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(17),
      Q => \^wa_reg[63]_0\(17),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[17]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[9]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \wa_reg[17]_i_2_n_0\,
      CO(6) => \wa_reg[17]_i_2_n_1\,
      CO(5) => \wa_reg[17]_i_2_n_2\,
      CO(4) => \wa_reg[17]_i_2_n_3\,
      CO(3) => \wa_reg[17]_i_2_n_4\,
      CO(2) => \wa_reg[17]_i_2_n_5\,
      CO(1) => \wa_reg[17]_i_2_n_6\,
      CO(0) => \wa_reg[17]_i_2_n_7\,
      DI(7 downto 2) => B"000000",
      DI(1 downto 0) => \^wa_reg[63]_0\(11 downto 10),
      O(7 downto 0) => in14(17 downto 10),
      S(7 downto 2) => \^wa_reg[63]_0\(17 downto 12),
      S(1) => \wa[17]_i_3_n_0\,
      S(0) => \wa[17]_i_4_n_0\
    );
\wa_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(18),
      Q => \^wa_reg[63]_0\(18),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(19),
      Q => \^wa_reg[63]_0\(19),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(1),
      Q => \^wa_reg[63]_0\(1),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(20),
      Q => \^wa_reg[63]_0\(20),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(21),
      Q => \^wa_reg[63]_0\(21),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(22),
      Q => \^wa_reg[63]_0\(22),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(23),
      Q => \^wa_reg[63]_0\(23),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(24),
      Q => \^wa_reg[63]_0\(24),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(25),
      Q => \^wa_reg[63]_0\(25),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[25]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[17]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \wa_reg[25]_i_2_n_0\,
      CO(6) => \wa_reg[25]_i_2_n_1\,
      CO(5) => \wa_reg[25]_i_2_n_2\,
      CO(4) => \wa_reg[25]_i_2_n_3\,
      CO(3) => \wa_reg[25]_i_2_n_4\,
      CO(2) => \wa_reg[25]_i_2_n_5\,
      CO(1) => \wa_reg[25]_i_2_n_6\,
      CO(0) => \wa_reg[25]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in14(25 downto 18),
      S(7 downto 0) => \^wa_reg[63]_0\(25 downto 18)
    );
\wa_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(26),
      Q => \^wa_reg[63]_0\(26),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(27),
      Q => \^wa_reg[63]_0\(27),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(28),
      Q => \^wa_reg[63]_0\(28),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(29),
      Q => \^wa_reg[63]_0\(29),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(2),
      Q => \^wa_reg[63]_0\(2),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(30),
      Q => \^wa_reg[63]_0\(30),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(31),
      Q => \^wa_reg[63]_0\(31),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[32]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(32),
      Q => \^wa_reg[63]_0\(32),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[33]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(33),
      Q => \^wa_reg[63]_0\(33),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[33]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[25]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \wa_reg[33]_i_2_n_0\,
      CO(6) => \wa_reg[33]_i_2_n_1\,
      CO(5) => \wa_reg[33]_i_2_n_2\,
      CO(4) => \wa_reg[33]_i_2_n_3\,
      CO(3) => \wa_reg[33]_i_2_n_4\,
      CO(2) => \wa_reg[33]_i_2_n_5\,
      CO(1) => \wa_reg[33]_i_2_n_6\,
      CO(0) => \wa_reg[33]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in14(33 downto 26),
      S(7 downto 0) => \^wa_reg[63]_0\(33 downto 26)
    );
\wa_reg[34]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(34),
      Q => \^wa_reg[63]_0\(34),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[35]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(35),
      Q => \^wa_reg[63]_0\(35),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[36]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(36),
      Q => \^wa_reg[63]_0\(36),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[37]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(37),
      Q => \^wa_reg[63]_0\(37),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[38]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(38),
      Q => \^wa_reg[63]_0\(38),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[39]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(39),
      Q => \^wa_reg[63]_0\(39),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(3),
      Q => \^wa_reg[63]_0\(3),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[40]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(40),
      Q => \^wa_reg[63]_0\(40),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[41]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(41),
      Q => \^wa_reg[63]_0\(41),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[41]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[33]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \wa_reg[41]_i_2_n_0\,
      CO(6) => \wa_reg[41]_i_2_n_1\,
      CO(5) => \wa_reg[41]_i_2_n_2\,
      CO(4) => \wa_reg[41]_i_2_n_3\,
      CO(3) => \wa_reg[41]_i_2_n_4\,
      CO(2) => \wa_reg[41]_i_2_n_5\,
      CO(1) => \wa_reg[41]_i_2_n_6\,
      CO(0) => \wa_reg[41]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in14(41 downto 34),
      S(7 downto 0) => \^wa_reg[63]_0\(41 downto 34)
    );
\wa_reg[42]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(42),
      Q => \^wa_reg[63]_0\(42),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[43]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(43),
      Q => \^wa_reg[63]_0\(43),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[44]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(44),
      Q => \^wa_reg[63]_0\(44),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[45]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(45),
      Q => \^wa_reg[63]_0\(45),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[46]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(46),
      Q => \^wa_reg[63]_0\(46),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[47]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(47),
      Q => \^wa_reg[63]_0\(47),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[48]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(48),
      Q => \^wa_reg[63]_0\(48),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[49]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(49),
      Q => \^wa_reg[63]_0\(49),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[49]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[41]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \wa_reg[49]_i_2_n_0\,
      CO(6) => \wa_reg[49]_i_2_n_1\,
      CO(5) => \wa_reg[49]_i_2_n_2\,
      CO(4) => \wa_reg[49]_i_2_n_3\,
      CO(3) => \wa_reg[49]_i_2_n_4\,
      CO(2) => \wa_reg[49]_i_2_n_5\,
      CO(1) => \wa_reg[49]_i_2_n_6\,
      CO(0) => \wa_reg[49]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in14(49 downto 42),
      S(7 downto 0) => \^wa_reg[63]_0\(49 downto 42)
    );
\wa_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(4),
      Q => \^wa_reg[63]_0\(4),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[50]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(50),
      Q => \^wa_reg[63]_0\(50),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[51]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(51),
      Q => \^wa_reg[63]_0\(51),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[52]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(52),
      Q => \^wa_reg[63]_0\(52),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[53]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(53),
      Q => \^wa_reg[63]_0\(53),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[54]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(54),
      Q => \^wa_reg[63]_0\(54),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[55]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(55),
      Q => \^wa_reg[63]_0\(55),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[56]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(56),
      Q => \^wa_reg[63]_0\(56),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[57]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(57),
      Q => \^wa_reg[63]_0\(57),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[57]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[49]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \wa_reg[57]_i_2_n_0\,
      CO(6) => \wa_reg[57]_i_2_n_1\,
      CO(5) => \wa_reg[57]_i_2_n_2\,
      CO(4) => \wa_reg[57]_i_2_n_3\,
      CO(3) => \wa_reg[57]_i_2_n_4\,
      CO(2) => \wa_reg[57]_i_2_n_5\,
      CO(1) => \wa_reg[57]_i_2_n_6\,
      CO(0) => \wa_reg[57]_i_2_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 0) => in14(57 downto 50),
      S(7 downto 0) => \^wa_reg[63]_0\(57 downto 50)
    );
\wa_reg[58]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(58),
      Q => \^wa_reg[63]_0\(58),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[59]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(59),
      Q => \^wa_reg[63]_0\(59),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(5),
      Q => \^wa_reg[63]_0\(5),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[60]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(60),
      Q => \^wa_reg[63]_0\(60),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[61]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(61),
      Q => \^wa_reg[63]_0\(61),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[62]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(62),
      Q => \^wa_reg[63]_0\(62),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[63]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(63),
      Q => \^wa_reg[63]_0\(63),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[63]_i_4\: unisim.vcomponents.CARRY8
     port map (
      CI => \wa_reg[57]_i_2_n_0\,
      CI_TOP => '0',
      CO(7 downto 5) => \NLW_wa_reg[63]_i_4_CO_UNCONNECTED\(7 downto 5),
      CO(4) => \wa_reg[63]_i_4_n_3\,
      CO(3) => \wa_reg[63]_i_4_n_4\,
      CO(2) => \wa_reg[63]_i_4_n_5\,
      CO(1) => \wa_reg[63]_i_4_n_6\,
      CO(0) => \wa_reg[63]_i_4_n_7\,
      DI(7 downto 0) => B"00000000",
      O(7 downto 6) => \NLW_wa_reg[63]_i_4_O_UNCONNECTED\(7 downto 6),
      O(5 downto 0) => in14(63 downto 58),
      S(7 downto 6) => B"00",
      S(5 downto 0) => \^wa_reg[63]_0\(63 downto 58)
    );
\wa_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(6),
      Q => \^wa_reg[63]_0\(6),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(7),
      Q => \^wa_reg[63]_0\(7),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(8),
      Q => \^wa_reg[63]_0\(8),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wa(9),
      Q => \^wa_reg[63]_0\(9),
      R => fdma_wdone_i_1_n_0
    );
\wa_reg[9]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => '0',
      CI_TOP => '0',
      CO(7) => \wa_reg[9]_i_2_n_0\,
      CO(6) => \wa_reg[9]_i_2_n_1\,
      CO(5) => \wa_reg[9]_i_2_n_2\,
      CO(4) => \wa_reg[9]_i_2_n_3\,
      CO(3) => \wa_reg[9]_i_2_n_4\,
      CO(2) => \wa_reg[9]_i_2_n_5\,
      CO(1) => \wa_reg[9]_i_2_n_6\,
      CO(0) => \wa_reg[9]_i_2_n_7\,
      DI(7 downto 1) => \^wa_reg[63]_0\(9 downto 3),
      DI(0) => '0',
      O(7 downto 0) => in14(9 downto 2),
      S(7) => \wa[9]_i_3_n_0\,
      S(6) => \wa[9]_i_4_n_0\,
      S(5) => \wa[9]_i_5_n_0\,
      S(4) => \wa[9]_i_6_n_0\,
      S(3) => \wa[9]_i_7_n_0\,
      S(2) => \wa[9]_i_8_n_0\,
      S(1) => \wa[9]_i_9_n_0\,
      S(0) => \^wa_reg[63]_0\(2)
    );
\wb[0]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"88B8"
    )
        port map (
      I0 => \wleft_reg_n_0_[0]\,
      I1 => \update_wb.available1\,
      I2 => \wb[0]_i_2_n_0\,
      I3 => \wb[8]_i_4_n_0\,
      O => A(0)
    );
\wb[0]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"01FE"
    )
        port map (
      I0 => \^wa_reg[63]_0\(2),
      I1 => \^wa_reg[63]_0\(0),
      I2 => \^wa_reg[63]_0\(1),
      I3 => \^wa_reg[63]_0\(3),
      O => \wb[0]_i_2_n_0\
    );
\wb[1]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"88B8"
    )
        port map (
      I0 => \wleft_reg_n_0_[1]\,
      I1 => \update_wb.available1\,
      I2 => \update_wb.available3\(4),
      I3 => \wb[8]_i_4_n_0\,
      O => A(1)
    );
\wb[1]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"0001FFFE"
    )
        port map (
      I0 => \^wa_reg[63]_0\(1),
      I1 => \^wa_reg[63]_0\(0),
      I2 => \^wa_reg[63]_0\(2),
      I3 => \^wa_reg[63]_0\(3),
      I4 => \^wa_reg[63]_0\(4),
      O => \update_wb.available3\(4)
    );
\wb[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"88B8"
    )
        port map (
      I0 => \wleft_reg_n_0_[2]\,
      I1 => \update_wb.available1\,
      I2 => \wb[2]_i_2_n_0\,
      I3 => \wb[8]_i_4_n_0\,
      O => A(2)
    );
\wb[2]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000001FFFFFFFE"
    )
        port map (
      I0 => \^wa_reg[63]_0\(4),
      I1 => \^wa_reg[63]_0\(3),
      I2 => \^wa_reg[63]_0\(2),
      I3 => \^wa_reg[63]_0\(0),
      I4 => \^wa_reg[63]_0\(1),
      I5 => \^wa_reg[63]_0\(5),
      O => \wb[2]_i_2_n_0\
    );
\wb[3]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"88888BB8"
    )
        port map (
      I0 => \wleft_reg_n_0_[3]\,
      I1 => \update_wb.available1\,
      I2 => \wb[4]_i_2_n_0\,
      I3 => \^wa_reg[63]_0\(6),
      I4 => \wb[8]_i_4_n_0\,
      O => A(3)
    );
\wb[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"888888888B8B8BB8"
    )
        port map (
      I0 => \wleft_reg_n_0_[4]\,
      I1 => \update_wb.available1\,
      I2 => \^wa_reg[63]_0\(7),
      I3 => \wb[4]_i_2_n_0\,
      I4 => \^wa_reg[63]_0\(6),
      I5 => \wb[8]_i_4_n_0\,
      O => A(4)
    );
\wb[4]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => \^wa_reg[63]_0\(5),
      I1 => \^wa_reg[63]_0\(4),
      I2 => \^wa_reg[63]_0\(3),
      I3 => \^wa_reg[63]_0\(2),
      I4 => \^wa_reg[63]_0\(0),
      I5 => \^wa_reg[63]_0\(1),
      O => \wb[4]_i_2_n_0\
    );
\wb[5]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"88B8"
    )
        port map (
      I0 => \wleft_reg_n_0_[5]\,
      I1 => \update_wb.available1\,
      I2 => \update_wb.available3\(8),
      I3 => \wb[8]_i_4_n_0\,
      O => A(5)
    );
\wb[5]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"01FE"
    )
        port map (
      I0 => \wb[4]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(6),
      I2 => \^wa_reg[63]_0\(7),
      I3 => \^wa_reg[63]_0\(8),
      O => \update_wb.available3\(8)
    );
\wb[6]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FF009090"
    )
        port map (
      I0 => \^wa_reg[63]_0\(9),
      I1 => \wb[6]_i_2_n_0\,
      I2 => \^wa_reg[63]_0\(11),
      I3 => \wleft_reg_n_0_[6]\,
      I4 => \update_wb.available1\,
      O => A(6)
    );
\wb[6]_i_2\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0001"
    )
        port map (
      I0 => \wb[4]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(6),
      I2 => \^wa_reg[63]_0\(7),
      I3 => \^wa_reg[63]_0\(8),
      O => \wb[6]_i_2_n_0\
    );
\wb[7]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"88B8"
    )
        port map (
      I0 => \wleft_reg_n_0_[7]\,
      I1 => \update_wb.available1\,
      I2 => \update_wb.available3\(10),
      I3 => \wb[8]_i_4_n_0\,
      O => A(7)
    );
\wb[7]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000001FFFFFFFE"
    )
        port map (
      I0 => \wb[4]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(6),
      I2 => \^wa_reg[63]_0\(7),
      I3 => \^wa_reg[63]_0\(8),
      I4 => \^wa_reg[63]_0\(9),
      I5 => \^wa_reg[63]_0\(10),
      O => \update_wb.available3\(10)
    );
\wb[8]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \write_curr_st__0\(0),
      I1 => \write_curr_st__0\(1),
      O => wb
    );
\wb[8]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BBBB8BB8"
    )
        port map (
      I0 => \wleft_reg_n_0_[8]\,
      I1 => \update_wb.available1\,
      I2 => \^wa_reg[63]_0\(11),
      I3 => \wb[8]_i_3_n_0\,
      I4 => \wb[8]_i_4_n_0\,
      O => A(8)
    );
\wb[8]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => \wb[4]_i_2_n_0\,
      I1 => \^wa_reg[63]_0\(6),
      I2 => \^wa_reg[63]_0\(7),
      I3 => \^wa_reg[63]_0\(8),
      I4 => \^wa_reg[63]_0\(9),
      I5 => \^wa_reg[63]_0\(10),
      O => \wb[8]_i_3_n_0\
    );
\wb[8]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"555D555D555D4555"
    )
        port map (
      I0 => \^wa_reg[63]_0\(11),
      I1 => \wb[6]_i_2_n_0\,
      I2 => \^wa_reg[63]_0\(9),
      I3 => \^wa_reg[63]_0\(10),
      I4 => \wb[8]_i_5_n_0\,
      I5 => \wb[8]_i_6_n_0\,
      O => \wb[8]_i_4_n_0\
    );
\wb[8]_i_5\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"1E"
    )
        port map (
      I0 => \^wa_reg[63]_0\(6),
      I1 => \wb[4]_i_2_n_0\,
      I2 => \^wa_reg[63]_0\(7),
      O => \wb[8]_i_5_n_0\
    );
\wb[8]_i_6\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"BBFFFFBE"
    )
        port map (
      I0 => \wb[8]_i_7_n_0\,
      I1 => \^wa_reg[63]_0\(8),
      I2 => \^wa_reg[63]_0\(7),
      I3 => \^wa_reg[63]_0\(6),
      I4 => \wb[4]_i_2_n_0\,
      O => \wb[8]_i_6_n_0\
    );
\wb[8]_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"5557FFFFFFFFFFFE"
    )
        port map (
      I0 => \^wa_reg[63]_0\(5),
      I1 => \^wa_reg[63]_0\(1),
      I2 => \^wa_reg[63]_0\(0),
      I3 => \^wa_reg[63]_0\(2),
      I4 => \^wa_reg[63]_0\(3),
      I5 => \^wa_reg[63]_0\(4),
      O => \wb[8]_i_7_n_0\
    );
\wb_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(0),
      Q => \wb_reg_n_0_[0]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(1),
      Q => \wb_reg_n_0_[1]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(2),
      Q => \wb_reg_n_0_[2]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(3),
      Q => \wb_reg_n_0_[3]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(4),
      Q => \wb_reg_n_0_[4]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(5),
      Q => \wb_reg_n_0_[5]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(6),
      Q => \wb_reg_n_0_[6]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(7),
      Q => \wb_reg_n_0_[7]\,
      R => fdma_wdone_i_1_n_0
    );
\wb_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wb,
      D => A(8),
      Q => \wb_reg_n_0_[8]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat[0]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \write_curr_st__0\(1),
      I1 => \wbeat_reg_n_0_[0]\,
      O => wbeat(0)
    );
\wbeat[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"48"
    )
        port map (
      I0 => \wbeat_reg_n_0_[0]\,
      I1 => \write_curr_st__0\(1),
      I2 => \wbeat_reg_n_0_[1]\,
      O => wbeat(1)
    );
\wbeat[2]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7080"
    )
        port map (
      I0 => \wbeat_reg_n_0_[0]\,
      I1 => \wbeat_reg_n_0_[1]\,
      I2 => \write_curr_st__0\(1),
      I3 => \wbeat_reg_n_0_[2]\,
      O => wbeat(2)
    );
\wbeat[3]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"7F008000"
    )
        port map (
      I0 => \wbeat_reg_n_0_[1]\,
      I1 => \wbeat_reg_n_0_[0]\,
      I2 => \wbeat_reg_n_0_[2]\,
      I3 => \write_curr_st__0\(1),
      I4 => \wbeat_reg_n_0_[3]\,
      O => wbeat(3)
    );
\wbeat[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFF000080000000"
    )
        port map (
      I0 => \wbeat_reg_n_0_[2]\,
      I1 => \wbeat_reg_n_0_[0]\,
      I2 => \wbeat_reg_n_0_[1]\,
      I3 => \wbeat_reg_n_0_[3]\,
      I4 => \write_curr_st__0\(1),
      I5 => \wbeat_reg_n_0_[4]\,
      O => wbeat(4)
    );
\wbeat[5]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"48"
    )
        port map (
      I0 => \wbeat[5]_i_2_n_0\,
      I1 => \write_curr_st__0\(1),
      I2 => \wbeat_reg_n_0_[5]\,
      O => wbeat(5)
    );
\wbeat[5]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"80000000"
    )
        port map (
      I0 => \wbeat_reg_n_0_[4]\,
      I1 => \wbeat_reg_n_0_[3]\,
      I2 => \wbeat_reg_n_0_[1]\,
      I3 => \wbeat_reg_n_0_[0]\,
      I4 => \wbeat_reg_n_0_[2]\,
      O => \wbeat[5]_i_2_n_0\
    );
\wbeat[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"84"
    )
        port map (
      I0 => \wbeat[8]_i_3_n_0\,
      I1 => \write_curr_st__0\(1),
      I2 => \wbeat_reg_n_0_[6]\,
      O => wbeat(6)
    );
\wbeat[7]_i_1\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"B040"
    )
        port map (
      I0 => \wbeat[8]_i_3_n_0\,
      I1 => \wbeat_reg_n_0_[6]\,
      I2 => \write_curr_st__0\(1),
      I3 => \wbeat_reg_n_0_[7]\,
      O => wbeat(7)
    );
\wbeat[8]_i_1\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00FF4000"
    )
        port map (
      I0 => \^m_axi_wlast\,
      I1 => M_AXI_WREADY,
      I2 => \^m_axi_wvalid\,
      I3 => \write_curr_st__0\(1),
      I4 => \write_curr_st__0\(0),
      O => wbeat_1
    );
\wbeat[8]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"DF002000"
    )
        port map (
      I0 => \wbeat_reg_n_0_[6]\,
      I1 => \wbeat[8]_i_3_n_0\,
      I2 => \wbeat_reg_n_0_[7]\,
      I3 => \write_curr_st__0\(1),
      I4 => \wbeat_reg_n_0_[8]\,
      O => wbeat(8)
    );
\wbeat[8]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"7FFFFFFFFFFFFFFF"
    )
        port map (
      I0 => \wbeat_reg_n_0_[2]\,
      I1 => \wbeat_reg_n_0_[0]\,
      I2 => \wbeat_reg_n_0_[1]\,
      I3 => \wbeat_reg_n_0_[3]\,
      I4 => \wbeat_reg_n_0_[4]\,
      I5 => \wbeat_reg_n_0_[5]\,
      O => \wbeat[8]_i_3_n_0\
    );
\wbeat_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(0),
      Q => \wbeat_reg_n_0_[0]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(1),
      Q => \wbeat_reg_n_0_[1]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(2),
      Q => \wbeat_reg_n_0_[2]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(3),
      Q => \wbeat_reg_n_0_[3]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(4),
      Q => \wbeat_reg_n_0_[4]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(5),
      Q => \wbeat_reg_n_0_[5]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(6),
      Q => \wbeat_reg_n_0_[6]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(7),
      Q => \wbeat_reg_n_0_[7]\,
      R => fdma_wdone_i_1_n_0
    );
\wbeat_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wbeat_1,
      D => wbeat(8),
      Q => \wbeat_reg_n_0_[8]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(0),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(0),
      O => wleft(0)
    );
\wleft[10]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(10),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(10),
      O => wleft(10)
    );
\wleft[11]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(11),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(11),
      O => wleft(11)
    );
\wleft[12]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(12),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(12),
      O => wleft(12)
    );
\wleft[13]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(13),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(13),
      O => wleft(13)
    );
\wleft[14]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(14),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(14),
      O => wleft(14)
    );
\wleft[15]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(15),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(15),
      O => wleft(15)
    );
\wleft[15]_i_10\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[8]\,
      I1 => \wb_reg_n_0_[8]\,
      O => \wleft[15]_i_10_n_0\
    );
\wleft[15]_i_3\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[15]\,
      O => \wleft[15]_i_3_n_0\
    );
\wleft[15]_i_4\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[14]\,
      O => \wleft[15]_i_4_n_0\
    );
\wleft[15]_i_5\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[13]\,
      O => \wleft[15]_i_5_n_0\
    );
\wleft[15]_i_6\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[12]\,
      O => \wleft[15]_i_6_n_0\
    );
\wleft[15]_i_7\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[11]\,
      O => \wleft[15]_i_7_n_0\
    );
\wleft[15]_i_8\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[10]\,
      O => \wleft[15]_i_8_n_0\
    );
\wleft[15]_i_9\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => \wleft_reg_n_0_[9]\,
      O => \wleft[15]_i_9_n_0\
    );
\wleft[1]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(1),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(1),
      O => wleft(1)
    );
\wleft[2]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(2),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(2),
      O => wleft(2)
    );
\wleft[3]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(3),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(3),
      O => wleft(3)
    );
\wleft[4]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(4),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(4),
      O => wleft(4)
    );
\wleft[5]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(5),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(5),
      O => wleft(5)
    );
\wleft[6]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(6),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(6),
      O => wleft(6)
    );
\wleft[7]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(7),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(7),
      O => wleft(7)
    );
\wleft[7]_i_10\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[0]\,
      I1 => \wb_reg_n_0_[0]\,
      O => \wleft[7]_i_10_n_0\
    );
\wleft[7]_i_3\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[7]\,
      I1 => \wb_reg_n_0_[7]\,
      O => \wleft[7]_i_3_n_0\
    );
\wleft[7]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[6]\,
      I1 => \wb_reg_n_0_[6]\,
      O => \wleft[7]_i_4_n_0\
    );
\wleft[7]_i_5\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[5]\,
      I1 => \wb_reg_n_0_[5]\,
      O => \wleft[7]_i_5_n_0\
    );
\wleft[7]_i_6\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[4]\,
      I1 => \wb_reg_n_0_[4]\,
      O => \wleft[7]_i_6_n_0\
    );
\wleft[7]_i_7\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[3]\,
      I1 => \wb_reg_n_0_[3]\,
      O => \wleft[7]_i_7_n_0\
    );
\wleft[7]_i_8\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[2]\,
      I1 => \wb_reg_n_0_[2]\,
      O => \wleft[7]_i_8_n_0\
    );
\wleft[7]_i_9\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"9"
    )
        port map (
      I0 => \wleft_reg_n_0_[1]\,
      I1 => \wb_reg_n_0_[1]\,
      O => \wleft[7]_i_9_n_0\
    );
\wleft[8]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(8),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(8),
      O => wleft(8)
    );
\wleft[9]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"B8"
    )
        port map (
      I0 => in10(9),
      I1 => \write_curr_st__0\(1),
      I2 => fdma_wsize(9),
      O => wleft(9)
    );
\wleft_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(0),
      Q => \wleft_reg_n_0_[0]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(10),
      Q => \wleft_reg_n_0_[10]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(11),
      Q => \wleft_reg_n_0_[11]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(12),
      Q => \wleft_reg_n_0_[12]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(13),
      Q => \wleft_reg_n_0_[13]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(14),
      Q => \wleft_reg_n_0_[14]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(15),
      Q => \wleft_reg_n_0_[15]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[15]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => \wleft_reg[7]_i_2_n_0\,
      CI_TOP => '0',
      CO(7) => \NLW_wleft_reg[15]_i_2_CO_UNCONNECTED\(7),
      CO(6) => \wleft_reg[15]_i_2_n_1\,
      CO(5) => \wleft_reg[15]_i_2_n_2\,
      CO(4) => \wleft_reg[15]_i_2_n_3\,
      CO(3) => \wleft_reg[15]_i_2_n_4\,
      CO(2) => \wleft_reg[15]_i_2_n_5\,
      CO(1) => \wleft_reg[15]_i_2_n_6\,
      CO(0) => \wleft_reg[15]_i_2_n_7\,
      DI(7) => '0',
      DI(6) => \wleft_reg_n_0_[14]\,
      DI(5) => \wleft_reg_n_0_[13]\,
      DI(4) => \wleft_reg_n_0_[12]\,
      DI(3) => \wleft_reg_n_0_[11]\,
      DI(2) => \wleft_reg_n_0_[10]\,
      DI(1) => \wleft_reg_n_0_[9]\,
      DI(0) => \wleft_reg_n_0_[8]\,
      O(7 downto 0) => in10(15 downto 8),
      S(7) => \wleft[15]_i_3_n_0\,
      S(6) => \wleft[15]_i_4_n_0\,
      S(5) => \wleft[15]_i_5_n_0\,
      S(4) => \wleft[15]_i_6_n_0\,
      S(3) => \wleft[15]_i_7_n_0\,
      S(2) => \wleft[15]_i_8_n_0\,
      S(1) => \wleft[15]_i_9_n_0\,
      S(0) => \wleft[15]_i_10_n_0\
    );
\wleft_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(1),
      Q => \wleft_reg_n_0_[1]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(2),
      Q => \wleft_reg_n_0_[2]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(3),
      Q => \wleft_reg_n_0_[3]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(4),
      Q => \wleft_reg_n_0_[4]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(5),
      Q => \wleft_reg_n_0_[5]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(6),
      Q => \wleft_reg_n_0_[6]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(7),
      Q => \wleft_reg_n_0_[7]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[7]_i_2\: unisim.vcomponents.CARRY8
     port map (
      CI => '1',
      CI_TOP => '0',
      CO(7) => \wleft_reg[7]_i_2_n_0\,
      CO(6) => \wleft_reg[7]_i_2_n_1\,
      CO(5) => \wleft_reg[7]_i_2_n_2\,
      CO(4) => \wleft_reg[7]_i_2_n_3\,
      CO(3) => \wleft_reg[7]_i_2_n_4\,
      CO(2) => \wleft_reg[7]_i_2_n_5\,
      CO(1) => \wleft_reg[7]_i_2_n_6\,
      CO(0) => \wleft_reg[7]_i_2_n_7\,
      DI(7) => \wleft_reg_n_0_[7]\,
      DI(6) => \wleft_reg_n_0_[6]\,
      DI(5) => \wleft_reg_n_0_[5]\,
      DI(4) => \wleft_reg_n_0_[4]\,
      DI(3) => \wleft_reg_n_0_[3]\,
      DI(2) => \wleft_reg_n_0_[2]\,
      DI(1) => \wleft_reg_n_0_[1]\,
      DI(0) => \wleft_reg_n_0_[0]\,
      O(7 downto 0) => in10(7 downto 0),
      S(7) => \wleft[7]_i_3_n_0\,
      S(6) => \wleft[7]_i_4_n_0\,
      S(5) => \wleft[7]_i_5_n_0\,
      S(4) => \wleft[7]_i_6_n_0\,
      S(3) => \wleft[7]_i_7_n_0\,
      S(2) => \wleft[7]_i_8_n_0\,
      S(1) => \wleft[7]_i_9_n_0\,
      S(0) => \wleft[7]_i_10_n_0\
    );
\wleft_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(8),
      Q => \wleft_reg_n_0_[8]\,
      R => fdma_wdone_i_1_n_0
    );
\wleft_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => wa_0,
      D => wleft(9),
      Q => \wleft_reg_n_0_[9]\,
      R => fdma_wdone_i_1_n_0
    );
\write_curr_st[0]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"4F"
    )
        port map (
      I0 => \write_next_st1__23\,
      I1 => write_curr_st(1),
      I2 => write_curr_st(0),
      O => \write_curr_st[0]_i_1_n_0\
    );
\write_curr_st[1]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"6"
    )
        port map (
      I0 => write_curr_st(0),
      I1 => write_curr_st(1),
      O => \write_curr_st[1]_i_1_n_0\
    );
\write_curr_st_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => write_next_st,
      D => \write_curr_st[0]_i_1_n_0\,
      Q => write_curr_st(0),
      R => fdma_wdone_i_1_n_0
    );
\write_curr_st_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => M_AXI_ACLK,
      CE => write_next_st,
      D => \write_curr_st[1]_i_1_n_0\,
      Q => write_curr_st(1),
      R => fdma_wdone_i_1_n_0
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_CONV_DMA_0_0 is
  port (
    fdma_wstrb : in STD_LOGIC_VECTOR ( 7 downto 0 );
    fdma_wdone : out STD_LOGIC;
    fdma_werror : out STD_LOGIC;
    fdma_waddr : in STD_LOGIC_VECTOR ( 63 downto 0 );
    fdma_wareq : in STD_LOGIC;
    fdma_wsize : in STD_LOGIC_VECTOR ( 15 downto 0 );
    fdma_wbusy : out STD_LOGIC;
    fdma_wdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    fdma_wvalid : out STD_LOGIC;
    fdma_wready : in STD_LOGIC;
    fdma_raddr : in STD_LOGIC_VECTOR ( 63 downto 0 );
    fdma_rareq : in STD_LOGIC;
    fdma_rsize : in STD_LOGIC_VECTOR ( 15 downto 0 );
    fdma_rbusy : out STD_LOGIC;
    fdma_rdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    fdma_rvalid : out STD_LOGIC;
    fdma_rready : in STD_LOGIC;
    M_AXI_ACLK : in STD_LOGIC;
    M_AXI_ARESETN : in STD_LOGIC;
    M_AXI_AWID : out STD_LOGIC_VECTOR ( 0 to 0 );
    M_AXI_AWADDR : out STD_LOGIC_VECTOR ( 63 downto 0 );
    M_AXI_AWLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_AWSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_AWBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_AWLOCK : out STD_LOGIC;
    M_AXI_AWCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_AWPROT : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_AWQOS : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_AWVALID : out STD_LOGIC;
    M_AXI_AWREADY : in STD_LOGIC;
    M_AXI_WID : out STD_LOGIC_VECTOR ( 0 to 0 );
    M_AXI_WDATA : out STD_LOGIC_VECTOR ( 63 downto 0 );
    M_AXI_WSTRB : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_WLAST : out STD_LOGIC;
    M_AXI_WVALID : out STD_LOGIC;
    M_AXI_WREADY : in STD_LOGIC;
    M_AXI_BID : in STD_LOGIC_VECTOR ( 0 to 0 );
    M_AXI_BRESP : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_BVALID : in STD_LOGIC;
    M_AXI_BREADY : out STD_LOGIC;
    M_AXI_ARID : out STD_LOGIC_VECTOR ( 0 to 0 );
    M_AXI_ARADDR : out STD_LOGIC_VECTOR ( 63 downto 0 );
    M_AXI_ARLEN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    M_AXI_ARSIZE : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_ARBURST : out STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_ARLOCK : out STD_LOGIC;
    M_AXI_ARCACHE : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_ARPROT : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_ARQOS : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_ARVALID : out STD_LOGIC;
    M_AXI_ARREADY : in STD_LOGIC;
    M_AXI_RID : in STD_LOGIC_VECTOR ( 0 to 0 );
    M_AXI_RDATA : in STD_LOGIC_VECTOR ( 63 downto 0 );
    M_AXI_RRESP : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_RLAST : in STD_LOGIC;
    M_AXI_RVALID : in STD_LOGIC;
    M_AXI_RREADY : out STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of design_1_CONV_DMA_0_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of design_1_CONV_DMA_0_0 : entity is "design_1_CONV_DMA_0_0,CONV_DMA,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of design_1_CONV_DMA_0_0 : entity is "yes";
  attribute IP_DEFINITION_SOURCE : string;
  attribute IP_DEFINITION_SOURCE of design_1_CONV_DMA_0_0 : entity is "module_ref";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of design_1_CONV_DMA_0_0 : entity is "CONV_DMA,Vivado 2020.2";
end design_1_CONV_DMA_0_0;

architecture STRUCTURE of design_1_CONV_DMA_0_0 is
  signal \<const0>\ : STD_LOGIC;
  signal \<const1>\ : STD_LOGIC;
  signal \^m_axi_rdata\ : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal \^fdma_wdata\ : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal \^fdma_wstrb\ : STD_LOGIC_VECTOR ( 7 downto 0 );
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of M_AXI_ACLK : signal is "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of M_AXI_ACLK : signal is "XIL_INTERFACENAME M_AXI_ACLK, ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESETN, FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of M_AXI_ARESETN : signal is "xilinx.com:signal:reset:1.0 M_AXI_ARESETN RST";
  attribute X_INTERFACE_PARAMETER of M_AXI_ARESETN : signal is "XIL_INTERFACENAME M_AXI_ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of M_AXI_ARLOCK : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARLOCK";
  attribute X_INTERFACE_INFO of M_AXI_ARREADY : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARREADY";
  attribute X_INTERFACE_INFO of M_AXI_ARVALID : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARVALID";
  attribute X_INTERFACE_INFO of M_AXI_AWLOCK : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWLOCK";
  attribute X_INTERFACE_INFO of M_AXI_AWREADY : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWREADY";
  attribute X_INTERFACE_INFO of M_AXI_AWVALID : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWVALID";
  attribute X_INTERFACE_INFO of M_AXI_BREADY : signal is "xilinx.com:interface:aximm:1.0 M_AXI BREADY";
  attribute X_INTERFACE_INFO of M_AXI_BVALID : signal is "xilinx.com:interface:aximm:1.0 M_AXI BVALID";
  attribute X_INTERFACE_INFO of M_AXI_RLAST : signal is "xilinx.com:interface:aximm:1.0 M_AXI RLAST";
  attribute X_INTERFACE_INFO of M_AXI_RREADY : signal is "xilinx.com:interface:aximm:1.0 M_AXI RREADY";
  attribute X_INTERFACE_PARAMETER of M_AXI_RREADY : signal is "XIL_INTERFACENAME M_AXI, DATA_WIDTH 64, PROTOCOL AXI4, FREQ_HZ 250000000, ID_WIDTH 1, ADDR_WIDTH 64, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 1, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of M_AXI_RVALID : signal is "xilinx.com:interface:aximm:1.0 M_AXI RVALID";
  attribute X_INTERFACE_INFO of M_AXI_WLAST : signal is "xilinx.com:interface:aximm:1.0 M_AXI WLAST";
  attribute X_INTERFACE_INFO of M_AXI_WREADY : signal is "xilinx.com:interface:aximm:1.0 M_AXI WREADY";
  attribute X_INTERFACE_INFO of M_AXI_WVALID : signal is "xilinx.com:interface:aximm:1.0 M_AXI WVALID";
  attribute X_INTERFACE_INFO of M_AXI_ARADDR : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARADDR";
  attribute X_INTERFACE_INFO of M_AXI_ARBURST : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARBURST";
  attribute X_INTERFACE_INFO of M_AXI_ARCACHE : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARCACHE";
  attribute X_INTERFACE_INFO of M_AXI_ARID : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARID";
  attribute X_INTERFACE_INFO of M_AXI_ARLEN : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARLEN";
  attribute X_INTERFACE_INFO of M_AXI_ARPROT : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARPROT";
  attribute X_INTERFACE_INFO of M_AXI_ARQOS : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARQOS";
  attribute X_INTERFACE_INFO of M_AXI_ARSIZE : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARSIZE";
  attribute X_INTERFACE_INFO of M_AXI_AWADDR : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWADDR";
  attribute X_INTERFACE_INFO of M_AXI_AWBURST : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWBURST";
  attribute X_INTERFACE_INFO of M_AXI_AWCACHE : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWCACHE";
  attribute X_INTERFACE_INFO of M_AXI_AWID : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWID";
  attribute X_INTERFACE_INFO of M_AXI_AWLEN : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWLEN";
  attribute X_INTERFACE_INFO of M_AXI_AWPROT : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWPROT";
  attribute X_INTERFACE_INFO of M_AXI_AWQOS : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWQOS";
  attribute X_INTERFACE_INFO of M_AXI_AWSIZE : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWSIZE";
  attribute X_INTERFACE_INFO of M_AXI_BID : signal is "xilinx.com:interface:aximm:1.0 M_AXI BID";
  attribute X_INTERFACE_INFO of M_AXI_BRESP : signal is "xilinx.com:interface:aximm:1.0 M_AXI BRESP";
  attribute X_INTERFACE_INFO of M_AXI_RDATA : signal is "xilinx.com:interface:aximm:1.0 M_AXI RDATA";
  attribute X_INTERFACE_INFO of M_AXI_RID : signal is "xilinx.com:interface:aximm:1.0 M_AXI RID";
  attribute X_INTERFACE_INFO of M_AXI_RRESP : signal is "xilinx.com:interface:aximm:1.0 M_AXI RRESP";
  attribute X_INTERFACE_INFO of M_AXI_WDATA : signal is "xilinx.com:interface:aximm:1.0 M_AXI WDATA";
  attribute X_INTERFACE_INFO of M_AXI_WID : signal is "xilinx.com:interface:aximm:1.0 M_AXI WID";
  attribute X_INTERFACE_INFO of M_AXI_WSTRB : signal is "xilinx.com:interface:aximm:1.0 M_AXI WSTRB";
begin
  M_AXI_ARBURST(1) <= \<const0>\;
  M_AXI_ARBURST(0) <= \<const1>\;
  M_AXI_ARCACHE(3) <= \<const0>\;
  M_AXI_ARCACHE(2) <= \<const0>\;
  M_AXI_ARCACHE(1) <= \<const1>\;
  M_AXI_ARCACHE(0) <= \<const0>\;
  M_AXI_ARID(0) <= \<const0>\;
  M_AXI_ARLOCK <= \<const0>\;
  M_AXI_ARPROT(2) <= \<const0>\;
  M_AXI_ARPROT(1) <= \<const0>\;
  M_AXI_ARPROT(0) <= \<const0>\;
  M_AXI_ARQOS(3) <= \<const0>\;
  M_AXI_ARQOS(2) <= \<const0>\;
  M_AXI_ARQOS(1) <= \<const0>\;
  M_AXI_ARQOS(0) <= \<const0>\;
  M_AXI_ARSIZE(2) <= \<const0>\;
  M_AXI_ARSIZE(1) <= \<const1>\;
  M_AXI_ARSIZE(0) <= \<const1>\;
  M_AXI_AWBURST(1) <= \<const0>\;
  M_AXI_AWBURST(0) <= \<const1>\;
  M_AXI_AWCACHE(3) <= \<const0>\;
  M_AXI_AWCACHE(2) <= \<const0>\;
  M_AXI_AWCACHE(1) <= \<const1>\;
  M_AXI_AWCACHE(0) <= \<const0>\;
  M_AXI_AWID(0) <= \<const0>\;
  M_AXI_AWLOCK <= \<const0>\;
  M_AXI_AWPROT(2) <= \<const0>\;
  M_AXI_AWPROT(1) <= \<const0>\;
  M_AXI_AWPROT(0) <= \<const0>\;
  M_AXI_AWQOS(3) <= \<const0>\;
  M_AXI_AWQOS(2) <= \<const0>\;
  M_AXI_AWQOS(1) <= \<const0>\;
  M_AXI_AWQOS(0) <= \<const0>\;
  M_AXI_AWSIZE(2) <= \<const0>\;
  M_AXI_AWSIZE(1) <= \<const1>\;
  M_AXI_AWSIZE(0) <= \<const1>\;
  M_AXI_WDATA(63 downto 0) <= \^fdma_wdata\(63 downto 0);
  M_AXI_WID(0) <= \<const0>\;
  M_AXI_WSTRB(7 downto 0) <= \^fdma_wstrb\(7 downto 0);
  \^fdma_wdata\(63 downto 0) <= fdma_wdata(63 downto 0);
  \^fdma_wstrb\(7 downto 0) <= fdma_wstrb(7 downto 0);
  \^m_axi_rdata\(63 downto 0) <= M_AXI_RDATA(63 downto 0);
  fdma_rdata(63 downto 0) <= \^m_axi_rdata\(63 downto 0);
GND: unisim.vcomponents.GND
     port map (
      G => \<const0>\
    );
VCC: unisim.vcomponents.VCC
     port map (
      P => \<const1>\
    );
inst: entity work.design_1_CONV_DMA_0_0_CONV_DMA
     port map (
      M_AXI_ACLK => M_AXI_ACLK,
      M_AXI_ARESETN => M_AXI_ARESETN,
      M_AXI_ARLEN(7 downto 0) => M_AXI_ARLEN(7 downto 0),
      M_AXI_ARREADY => M_AXI_ARREADY,
      M_AXI_ARVALID => M_AXI_ARVALID,
      M_AXI_AWLEN(7 downto 0) => M_AXI_AWLEN(7 downto 0),
      M_AXI_AWREADY => M_AXI_AWREADY,
      M_AXI_AWVALID => M_AXI_AWVALID,
      M_AXI_BID(0) => M_AXI_BID(0),
      M_AXI_BREADY => M_AXI_BREADY,
      M_AXI_BRESP(1 downto 0) => M_AXI_BRESP(1 downto 0),
      M_AXI_BVALID => M_AXI_BVALID,
      M_AXI_RREADY => M_AXI_RREADY,
      M_AXI_RVALID => M_AXI_RVALID,
      M_AXI_RVALID_0 => fdma_rvalid,
      M_AXI_WLAST => M_AXI_WLAST,
      M_AXI_WREADY => M_AXI_WREADY,
      M_AXI_WVALID => M_AXI_WVALID,
      Q(63 downto 0) => M_AXI_ARADDR(63 downto 0),
      fdma_raddr(63 downto 0) => fdma_raddr(63 downto 0),
      fdma_rareq => fdma_rareq,
      fdma_rbusy => fdma_rbusy,
      fdma_rready => fdma_rready,
      fdma_rsize(15 downto 0) => fdma_rsize(15 downto 0),
      fdma_waddr(63 downto 0) => fdma_waddr(63 downto 0),
      fdma_wareq => fdma_wareq,
      fdma_wbusy => fdma_wbusy,
      fdma_wdone => fdma_wdone,
      fdma_werror => fdma_werror,
      fdma_wready => fdma_wready,
      fdma_wsize(15 downto 0) => fdma_wsize(15 downto 0),
      fdma_wvalid => fdma_wvalid,
      \wa_reg[63]_0\(63 downto 0) => M_AXI_AWADDR(63 downto 0)
    );
end STRUCTURE;
