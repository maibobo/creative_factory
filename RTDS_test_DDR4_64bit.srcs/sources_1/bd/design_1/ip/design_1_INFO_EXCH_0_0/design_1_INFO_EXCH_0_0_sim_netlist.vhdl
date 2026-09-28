-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
-- Date        : Sun Sep 20 15:47:07 2026
-- Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode funcsim
--               c:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/RTDS_test_DDR4_64bit.srcs/sources_1/bd/design_1/ip/design_1_INFO_EXCH_0_0/design_1_INFO_EXCH_0_0_sim_netlist.vhdl
-- Design      : design_1_INFO_EXCH_0_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xcku040-ffva1156-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_INFO_EXCH_0_0_INFO_EXCH is
  port (
    S_AXI_ARREADY : out STD_LOGIC;
    r_CLEAR_INTER : out STD_LOGIC;
    S_AXI_AWREADY : out STD_LOGIC;
    S_AXI_WREADY : out STD_LOGIC;
    r_CPU_REC_STATE : out STD_LOGIC;
    r_CPU_FPGA_START_ADDR : out STD_LOGIC_VECTOR ( 31 downto 0 );
    r_CPU_FPGA_LEN : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_RDATA : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_RVALID : out STD_LOGIC;
    r_RD_START : out STD_LOGIC;
    S_AXI_BVALID : out STD_LOGIC;
    S_AXI_ACLK : in STD_LOGIC;
    S_AXI_AWADDR : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXI_WDATA : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_ARADDR : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXI_ARVALID : in STD_LOGIC;
    S_AXI_WSTRB : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_WVALID : in STD_LOGIC;
    S_AXI_AWVALID : in STD_LOGIC;
    DDR_STATUS_W : in STD_LOGIC_VECTOR ( 31 downto 0 );
    FPGA_TEMP_W : in STD_LOGIC_VECTOR ( 31 downto 0 );
    FPGA_CPU_LEN : in STD_LOGIC_VECTOR ( 31 downto 0 );
    INT_STATE_W : in STD_LOGIC_VECTOR ( 0 to 0 );
    FPGA_CPU_START_ADDR : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RX_READY_BLOCKS : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RX_DROPPED_FRAMES : in STD_LOGIC_VECTOR ( 31 downto 0 );
    RX_HEAD_SEQ : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_ARESETN : in STD_LOGIC;
    CPU_WR_DONE_EVENT : in STD_LOGIC;
    S_AXI_BREADY : in STD_LOGIC;
    S_AXI_RREADY : in STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of design_1_INFO_EXCH_0_0_INFO_EXCH : entity is "INFO_EXCH";
end design_1_INFO_EXCH_0_0_INFO_EXCH;

architecture STRUCTURE of design_1_INFO_EXCH_0_0_INFO_EXCH is
  signal \CPU_FPGA_LEN[15]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_LEN[23]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_LEN[31]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_LEN[31]_i_2_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_LEN[31]_i_3_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_LEN[7]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[15]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[23]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[31]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[31]_i_2_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[31]_i_3_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[31]_i_4_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[31]_i_5_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[31]_i_6_n_0\ : STD_LOGIC;
  signal \CPU_FPGA_START_ADDR[7]_i_1_n_0\ : STD_LOGIC;
  signal CPU_REC_STATE2 : STD_LOGIC;
  signal \CPU_REC_STATE[0]_i_2_n_0\ : STD_LOGIC;
  signal \CPU_REC_STATE[0]_i_4_n_0\ : STD_LOGIC;
  signal \CPU_REC_STATE[0]_i_5_n_0\ : STD_LOGIC;
  signal \CPU_REC_STATE[0]_i_6_n_0\ : STD_LOGIC;
  signal \CPU_WR_DONE[0]_i_1_n_0\ : STD_LOGIC;
  signal \CPU_WR_DONE[0]_i_3_n_0\ : STD_LOGIC;
  signal \CPU_WR_DONE[0]_i_4_n_0\ : STD_LOGIC;
  signal CPU_WR_DONE_d : STD_LOGIC;
  signal \CPU_WR_DONE_reg_n_0_[0]\ : STD_LOGIC;
  signal INT_STATE_R0 : STD_LOGIC;
  signal \INT_STATE_R[0]_i_1_n_0\ : STD_LOGIC;
  signal \INT_STATE_R[0]_i_3_n_0\ : STD_LOGIC;
  signal \INT_STATE_R[0]_i_4_n_0\ : STD_LOGIC;
  signal \INT_STATE_R[0]_i_5_n_0\ : STD_LOGIC;
  signal \^s_axi_arready\ : STD_LOGIC;
  signal \^s_axi_awready\ : STD_LOGIC;
  signal \^s_axi_bvalid\ : STD_LOGIC;
  signal \^s_axi_rvalid\ : STD_LOGIC;
  signal \^s_axi_wready\ : STD_LOGIC;
  signal aw_en_i_1_n_0 : STD_LOGIC;
  signal aw_en_reg_n_0 : STD_LOGIC;
  signal axi_araddr : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal axi_arready0 : STD_LOGIC;
  signal axi_awaddr : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal axi_awready0 : STD_LOGIC;
  signal axi_bvalid_i_1_n_0 : STD_LOGIC;
  signal \axi_rdata[0]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[0]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[0]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[0]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[0]_i_5_n_0\ : STD_LOGIC;
  signal \axi_rdata[10]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[10]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[10]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[10]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[11]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[11]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[11]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[11]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[12]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[12]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[12]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[12]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[13]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[13]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[13]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[13]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[14]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[14]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[14]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[14]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[15]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[15]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[15]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[15]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[16]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[16]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[16]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[16]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[17]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[17]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[17]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[17]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[18]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[18]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[18]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[18]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[19]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[19]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[19]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[19]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[1]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[1]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[1]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[1]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[20]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[20]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[20]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[20]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[21]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[21]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[21]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[21]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[22]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[22]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[22]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[22]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[23]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[23]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[23]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[23]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[24]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[24]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[24]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[24]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[25]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[25]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[25]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[25]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[26]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[26]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[26]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[26]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[27]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[27]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[27]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[27]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[28]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[28]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[28]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[28]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[29]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[29]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[29]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[29]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[2]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[2]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[2]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[2]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[30]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[30]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[30]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[30]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_5_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_6_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_7_n_0\ : STD_LOGIC;
  signal \axi_rdata[31]_i_8_n_0\ : STD_LOGIC;
  signal \axi_rdata[3]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[3]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[3]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[3]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[4]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[4]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[4]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[4]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[5]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[5]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[5]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[5]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[6]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[6]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[6]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[6]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[7]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[7]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[7]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[7]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[8]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[8]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[8]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[8]_i_4_n_0\ : STD_LOGIC;
  signal \axi_rdata[9]_i_1_n_0\ : STD_LOGIC;
  signal \axi_rdata[9]_i_2_n_0\ : STD_LOGIC;
  signal \axi_rdata[9]_i_3_n_0\ : STD_LOGIC;
  signal \axi_rdata[9]_i_4_n_0\ : STD_LOGIC;
  signal axi_rvalid_i_1_n_0 : STD_LOGIC;
  signal axi_wready0 : STD_LOGIC;
  signal p_7_in : STD_LOGIC;
  signal p_8_in : STD_LOGIC;
  signal \^r_cpu_fpga_len\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \^r_cpu_fpga_start_addr\ : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal \^r_cpu_rec_state\ : STD_LOGIC;
  signal slv_reg_rden : STD_LOGIC;
  attribute SOFT_HLUTNM : string;
  attribute SOFT_HLUTNM of \CPU_FPGA_LEN[31]_i_3\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \CPU_FPGA_START_ADDR[31]_i_3\ : label is "soft_lutpair2";
  attribute SOFT_HLUTNM of \CPU_REC_STATE[0]_i_3\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \CPU_REC_STATE[0]_i_4\ : label is "soft_lutpair1";
  attribute SOFT_HLUTNM of \CPU_WR_DONE[0]_i_2\ : label is "soft_lutpair0";
  attribute SOFT_HLUTNM of \CPU_WR_DONE[0]_i_3\ : label is "soft_lutpair1";
begin
  S_AXI_ARREADY <= \^s_axi_arready\;
  S_AXI_AWREADY <= \^s_axi_awready\;
  S_AXI_BVALID <= \^s_axi_bvalid\;
  S_AXI_RVALID <= \^s_axi_rvalid\;
  S_AXI_WREADY <= \^s_axi_wready\;
  r_CPU_FPGA_LEN(31 downto 0) <= \^r_cpu_fpga_len\(31 downto 0);
  r_CPU_FPGA_START_ADDR(31 downto 0) <= \^r_cpu_fpga_start_addr\(31 downto 0);
  r_CPU_REC_STATE <= \^r_cpu_rec_state\;
\CPU_FPGA_LEN[15]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_LEN[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(1),
      O => \CPU_FPGA_LEN[15]_i_1_n_0\
    );
\CPU_FPGA_LEN[23]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_LEN[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(2),
      O => \CPU_FPGA_LEN[23]_i_1_n_0\
    );
\CPU_FPGA_LEN[31]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_LEN[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(3),
      O => \CPU_FPGA_LEN[31]_i_1_n_0\
    );
\CPU_FPGA_LEN[31]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0008000000000000"
    )
        port map (
      I0 => \CPU_FPGA_LEN[31]_i_3_n_0\,
      I1 => \CPU_REC_STATE[0]_i_4_n_0\,
      I2 => \CPU_FPGA_START_ADDR[31]_i_4_n_0\,
      I3 => \CPU_FPGA_START_ADDR[31]_i_5_n_0\,
      I4 => \CPU_FPGA_START_ADDR[31]_i_6_n_0\,
      I5 => p_7_in,
      O => \CPU_FPGA_LEN[31]_i_2_n_0\
    );
\CPU_FPGA_LEN[31]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => axi_awaddr(4),
      I1 => axi_awaddr(3),
      I2 => axi_awaddr(2),
      O => \CPU_FPGA_LEN[31]_i_3_n_0\
    );
\CPU_FPGA_LEN[7]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_LEN[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(0),
      O => \CPU_FPGA_LEN[7]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(0),
      Q => \^r_cpu_fpga_len\(0),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(10),
      Q => \^r_cpu_fpga_len\(10),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(11),
      Q => \^r_cpu_fpga_len\(11),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(12),
      Q => \^r_cpu_fpga_len\(12),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(13),
      Q => \^r_cpu_fpga_len\(13),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(14),
      Q => \^r_cpu_fpga_len\(14),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[15]\: unisim.vcomponents.FDSE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(15),
      Q => \^r_cpu_fpga_len\(15),
      S => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(16),
      Q => \^r_cpu_fpga_len\(16),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(17),
      Q => \^r_cpu_fpga_len\(17),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(18),
      Q => \^r_cpu_fpga_len\(18),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(19),
      Q => \^r_cpu_fpga_len\(19),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(1),
      Q => \^r_cpu_fpga_len\(1),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(20),
      Q => \^r_cpu_fpga_len\(20),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(21),
      Q => \^r_cpu_fpga_len\(21),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(22),
      Q => \^r_cpu_fpga_len\(22),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[23]_i_1_n_0\,
      D => S_AXI_WDATA(23),
      Q => \^r_cpu_fpga_len\(23),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(24),
      Q => \^r_cpu_fpga_len\(24),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(25),
      Q => \^r_cpu_fpga_len\(25),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(26),
      Q => \^r_cpu_fpga_len\(26),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(27),
      Q => \^r_cpu_fpga_len\(27),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(28),
      Q => \^r_cpu_fpga_len\(28),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(29),
      Q => \^r_cpu_fpga_len\(29),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(2),
      Q => \^r_cpu_fpga_len\(2),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(30),
      Q => \^r_cpu_fpga_len\(30),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[31]_i_1_n_0\,
      D => S_AXI_WDATA(31),
      Q => \^r_cpu_fpga_len\(31),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(3),
      Q => \^r_cpu_fpga_len\(3),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(4),
      Q => \^r_cpu_fpga_len\(4),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(5),
      Q => \^r_cpu_fpga_len\(5),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(6),
      Q => \^r_cpu_fpga_len\(6),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[7]_i_1_n_0\,
      D => S_AXI_WDATA(7),
      Q => \^r_cpu_fpga_len\(7),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(8),
      Q => \^r_cpu_fpga_len\(8),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_LEN_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_LEN[15]_i_1_n_0\,
      D => S_AXI_WDATA(9),
      Q => \^r_cpu_fpga_len\(9),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR[15]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_START_ADDR[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(1),
      O => \CPU_FPGA_START_ADDR[15]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR[23]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_START_ADDR[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(2),
      O => \CPU_FPGA_START_ADDR[23]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR[31]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_START_ADDR[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(3),
      O => \CPU_FPGA_START_ADDR[31]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR[31]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0008000000000000"
    )
        port map (
      I0 => \CPU_FPGA_START_ADDR[31]_i_3_n_0\,
      I1 => \CPU_REC_STATE[0]_i_4_n_0\,
      I2 => \CPU_FPGA_START_ADDR[31]_i_4_n_0\,
      I3 => \CPU_FPGA_START_ADDR[31]_i_5_n_0\,
      I4 => \CPU_FPGA_START_ADDR[31]_i_6_n_0\,
      I5 => p_7_in,
      O => \CPU_FPGA_START_ADDR[31]_i_2_n_0\
    );
\CPU_FPGA_START_ADDR[31]_i_3\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"04"
    )
        port map (
      I0 => axi_awaddr(4),
      I1 => axi_awaddr(2),
      I2 => axi_awaddr(3),
      O => \CPU_FPGA_START_ADDR[31]_i_3_n_0\
    );
\CPU_FPGA_START_ADDR[31]_i_4\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => axi_awaddr(10),
      I1 => axi_awaddr(11),
      I2 => axi_awaddr(12),
      I3 => axi_awaddr(13),
      O => \CPU_FPGA_START_ADDR[31]_i_4_n_0\
    );
\CPU_FPGA_START_ADDR[31]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => axi_awaddr(7),
      I1 => axi_awaddr(6),
      I2 => axi_awaddr(15),
      I3 => axi_awaddr(14),
      I4 => axi_awaddr(8),
      I5 => axi_awaddr(9),
      O => \CPU_FPGA_START_ADDR[31]_i_5_n_0\
    );
\CPU_FPGA_START_ADDR[31]_i_6\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"F4"
    )
        port map (
      I0 => axi_awaddr(0),
      I1 => axi_awaddr(5),
      I2 => axi_awaddr(1),
      O => \CPU_FPGA_START_ADDR[31]_i_6_n_0\
    );
\CPU_FPGA_START_ADDR[7]_i_1\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"8"
    )
        port map (
      I0 => \CPU_FPGA_START_ADDR[31]_i_2_n_0\,
      I1 => S_AXI_WSTRB(0),
      O => \CPU_FPGA_START_ADDR[7]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(0),
      Q => \^r_cpu_fpga_start_addr\(0),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(10),
      Q => \^r_cpu_fpga_start_addr\(10),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(11),
      Q => \^r_cpu_fpga_start_addr\(11),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(12),
      Q => \^r_cpu_fpga_start_addr\(12),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(13),
      Q => \^r_cpu_fpga_start_addr\(13),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(14),
      Q => \^r_cpu_fpga_start_addr\(14),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[15]\: unisim.vcomponents.FDSE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(15),
      Q => \^r_cpu_fpga_start_addr\(15),
      S => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(16),
      Q => \^r_cpu_fpga_start_addr\(16),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(17),
      Q => \^r_cpu_fpga_start_addr\(17),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(18),
      Q => \^r_cpu_fpga_start_addr\(18),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(19),
      Q => \^r_cpu_fpga_start_addr\(19),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(1),
      Q => \^r_cpu_fpga_start_addr\(1),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(20),
      Q => \^r_cpu_fpga_start_addr\(20),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(21),
      Q => \^r_cpu_fpga_start_addr\(21),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(22),
      Q => \^r_cpu_fpga_start_addr\(22),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[23]_i_1_n_0\,
      D => S_AXI_WDATA(23),
      Q => \^r_cpu_fpga_start_addr\(23),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(24),
      Q => \^r_cpu_fpga_start_addr\(24),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(25),
      Q => \^r_cpu_fpga_start_addr\(25),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(26),
      Q => \^r_cpu_fpga_start_addr\(26),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(27),
      Q => \^r_cpu_fpga_start_addr\(27),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(28),
      Q => \^r_cpu_fpga_start_addr\(28),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(29),
      Q => \^r_cpu_fpga_start_addr\(29),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(2),
      Q => \^r_cpu_fpga_start_addr\(2),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(30),
      Q => \^r_cpu_fpga_start_addr\(30),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[31]_i_1_n_0\,
      D => S_AXI_WDATA(31),
      Q => \^r_cpu_fpga_start_addr\(31),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(3),
      Q => \^r_cpu_fpga_start_addr\(3),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(4),
      Q => \^r_cpu_fpga_start_addr\(4),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(5),
      Q => \^r_cpu_fpga_start_addr\(5),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(6),
      Q => \^r_cpu_fpga_start_addr\(6),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[7]_i_1_n_0\,
      D => S_AXI_WDATA(7),
      Q => \^r_cpu_fpga_start_addr\(7),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(8),
      Q => \^r_cpu_fpga_start_addr\(8),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_FPGA_START_ADDR_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => \CPU_FPGA_START_ADDR[15]_i_1_n_0\,
      D => S_AXI_WDATA(9),
      Q => \^r_cpu_fpga_start_addr\(9),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_REC_STATE[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000800000"
    )
        port map (
      I0 => \CPU_REC_STATE[0]_i_2_n_0\,
      I1 => p_8_in,
      I2 => axi_awaddr(2),
      I3 => axi_awaddr(3),
      I4 => \CPU_REC_STATE[0]_i_4_n_0\,
      I5 => \CPU_REC_STATE[0]_i_5_n_0\,
      O => CPU_REC_STATE2
    );
\CPU_REC_STATE[0]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000002000"
    )
        port map (
      I0 => axi_awaddr(4),
      I1 => axi_awaddr(5),
      I2 => S_AXI_WDATA(0),
      I3 => S_AXI_WSTRB(0),
      I4 => axi_awaddr(6),
      I5 => axi_awaddr(7),
      O => \CPU_REC_STATE[0]_i_2_n_0\
    );
\CPU_REC_STATE[0]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"8000"
    )
        port map (
      I0 => \^s_axi_wready\,
      I1 => \^s_axi_awready\,
      I2 => S_AXI_AWVALID,
      I3 => S_AXI_WVALID,
      O => p_8_in
    );
\CPU_REC_STATE[0]_i_4\: unisim.vcomponents.LUT2
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => axi_awaddr(0),
      I1 => axi_awaddr(1),
      O => \CPU_REC_STATE[0]_i_4_n_0\
    );
\CPU_REC_STATE[0]_i_5\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"FFFFFFFE"
    )
        port map (
      I0 => axi_awaddr(11),
      I1 => axi_awaddr(10),
      I2 => axi_awaddr(9),
      I3 => axi_awaddr(8),
      I4 => \CPU_REC_STATE[0]_i_6_n_0\,
      O => \CPU_REC_STATE[0]_i_5_n_0\
    );
\CPU_REC_STATE[0]_i_6\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => axi_awaddr(12),
      I1 => axi_awaddr(13),
      I2 => axi_awaddr(15),
      I3 => axi_awaddr(14),
      O => \CPU_REC_STATE[0]_i_6_n_0\
    );
\CPU_REC_STATE_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => CPU_REC_STATE2,
      Q => \^r_cpu_rec_state\,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_WR_DONE[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000000BAAA0000"
    )
        port map (
      I0 => \CPU_WR_DONE_reg_n_0_[0]\,
      I1 => \CPU_REC_STATE[0]_i_5_n_0\,
      I2 => p_7_in,
      I3 => \CPU_WR_DONE[0]_i_3_n_0\,
      I4 => S_AXI_ARESETN,
      I5 => CPU_WR_DONE_EVENT,
      O => \CPU_WR_DONE[0]_i_1_n_0\
    );
\CPU_WR_DONE[0]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00008000"
    )
        port map (
      I0 => S_AXI_WVALID,
      I1 => S_AXI_AWVALID,
      I2 => \^s_axi_awready\,
      I3 => \^s_axi_wready\,
      I4 => \CPU_WR_DONE_reg_n_0_[0]\,
      O => p_7_in
    );
\CPU_WR_DONE[0]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00000002"
    )
        port map (
      I0 => \CPU_WR_DONE[0]_i_4_n_0\,
      I1 => axi_awaddr(2),
      I2 => axi_awaddr(3),
      I3 => axi_awaddr(0),
      I4 => axi_awaddr(1),
      O => \CPU_WR_DONE[0]_i_3_n_0\
    );
\CPU_WR_DONE[0]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000002000"
    )
        port map (
      I0 => axi_awaddr(5),
      I1 => axi_awaddr(4),
      I2 => S_AXI_WDATA(0),
      I3 => S_AXI_WSTRB(0),
      I4 => axi_awaddr(6),
      I5 => axi_awaddr(7),
      O => \CPU_WR_DONE[0]_i_4_n_0\
    );
CPU_WR_DONE_d_reg: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => \CPU_WR_DONE_reg_n_0_[0]\,
      Q => CPU_WR_DONE_d,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\CPU_WR_DONE_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => \CPU_WR_DONE[0]_i_1_n_0\,
      Q => \CPU_WR_DONE_reg_n_0_[0]\,
      R => '0'
    );
\INT_STATE_R[0]_i_1\: unisim.vcomponents.LUT1
    generic map(
      INIT => X"1"
    )
        port map (
      I0 => S_AXI_ARESETN,
      O => \INT_STATE_R[0]_i_1_n_0\
    );
\INT_STATE_R[0]_i_2\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"80"
    )
        port map (
      I0 => \INT_STATE_R[0]_i_3_n_0\,
      I1 => \INT_STATE_R[0]_i_4_n_0\,
      I2 => \INT_STATE_R[0]_i_5_n_0\,
      O => INT_STATE_R0
    );
\INT_STATE_R[0]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000000000001"
    )
        port map (
      I0 => S_AXI_ARADDR(8),
      I1 => S_AXI_ARADDR(9),
      I2 => S_AXI_ARADDR(6),
      I3 => S_AXI_ARADDR(7),
      I4 => S_AXI_ARADDR(11),
      I5 => S_AXI_ARADDR(10),
      O => \INT_STATE_R[0]_i_3_n_0\
    );
\INT_STATE_R[0]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0001000000000000"
    )
        port map (
      I0 => S_AXI_ARADDR(14),
      I1 => S_AXI_ARADDR(15),
      I2 => S_AXI_ARADDR(12),
      I3 => S_AXI_ARADDR(13),
      I4 => \^s_axi_arready\,
      I5 => S_AXI_ARVALID,
      O => \INT_STATE_R[0]_i_4_n_0\
    );
\INT_STATE_R[0]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000000100000000"
    )
        port map (
      I0 => S_AXI_ARADDR(2),
      I1 => S_AXI_ARADDR(3),
      I2 => S_AXI_ARADDR(0),
      I3 => S_AXI_ARADDR(1),
      I4 => S_AXI_ARADDR(5),
      I5 => S_AXI_ARADDR(4),
      O => \INT_STATE_R[0]_i_5_n_0\
    );
\INT_STATE_R_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => INT_STATE_R0,
      Q => r_CLEAR_INTER,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
aw_en_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FF7FF070F070F070"
    )
        port map (
      I0 => S_AXI_WVALID,
      I1 => S_AXI_AWVALID,
      I2 => aw_en_reg_n_0,
      I3 => \^s_axi_awready\,
      I4 => S_AXI_BREADY,
      I5 => \^s_axi_bvalid\,
      O => aw_en_i_1_n_0
    );
aw_en_reg: unisim.vcomponents.FDSE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => aw_en_i_1_n_0,
      Q => aw_en_reg_n_0,
      S => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(0),
      Q => axi_araddr(0),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(10),
      Q => axi_araddr(10),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(11),
      Q => axi_araddr(11),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(12),
      Q => axi_araddr(12),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(13),
      Q => axi_araddr(13),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(14),
      Q => axi_araddr(14),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(15),
      Q => axi_araddr(15),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(1),
      Q => axi_araddr(1),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(2),
      Q => axi_araddr(2),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(3),
      Q => axi_araddr(3),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(4),
      Q => axi_araddr(4),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(5),
      Q => axi_araddr(5),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(6),
      Q => axi_araddr(6),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(7),
      Q => axi_araddr(7),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(8),
      Q => axi_araddr(8),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_araddr_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_arready0,
      D => S_AXI_ARADDR(9),
      Q => axi_araddr(9),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
axi_arready_i_1: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => S_AXI_ARVALID,
      I1 => \^s_axi_arready\,
      O => axi_arready0
    );
axi_arready_reg: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => axi_arready0,
      Q => \^s_axi_arready\,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(0),
      Q => axi_awaddr(0),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(10),
      Q => axi_awaddr(10),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(11),
      Q => axi_awaddr(11),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(12),
      Q => axi_awaddr(12),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(13),
      Q => axi_awaddr(13),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(14),
      Q => axi_awaddr(14),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(15),
      Q => axi_awaddr(15),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(1),
      Q => axi_awaddr(1),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(2),
      Q => axi_awaddr(2),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(3),
      Q => axi_awaddr(3),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(4),
      Q => axi_awaddr(4),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(5),
      Q => axi_awaddr(5),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(6),
      Q => axi_awaddr(6),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(7),
      Q => axi_awaddr(7),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(8),
      Q => axi_awaddr(8),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_awaddr_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => axi_awready0,
      D => S_AXI_AWADDR(9),
      Q => axi_awaddr(9),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
axi_awready_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"4000"
    )
        port map (
      I0 => \^s_axi_awready\,
      I1 => aw_en_reg_n_0,
      I2 => S_AXI_AWVALID,
      I3 => S_AXI_WVALID,
      O => axi_awready0
    );
axi_awready_reg: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => axi_awready0,
      Q => \^s_axi_awready\,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
axi_bvalid_i_1: unisim.vcomponents.LUT6
    generic map(
      INIT => X"0000FFFF80008000"
    )
        port map (
      I0 => S_AXI_WVALID,
      I1 => S_AXI_AWVALID,
      I2 => \^s_axi_wready\,
      I3 => \^s_axi_awready\,
      I4 => S_AXI_BREADY,
      I5 => \^s_axi_bvalid\,
      O => axi_bvalid_i_1_n_0
    );
axi_bvalid_reg: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => axi_bvalid_i_1_n_0,
      Q => \^s_axi_bvalid\,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata[0]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AAAAAAAAA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[0]_i_2_n_0\,
      I4 => \axi_rdata[0]_i_3_n_0\,
      I5 => \axi_rdata[0]_i_4_n_0\,
      O => \axi_rdata[0]_i_1_n_0\
    );
\axi_rdata[0]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(0),
      I1 => RX_DROPPED_FRAMES(0),
      I2 => RX_HEAD_SEQ(0),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[0]_i_2_n_0\
    );
\axi_rdata[0]_i_3\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CFAFCFA0C0AFC0A0"
    )
        port map (
      I0 => \^r_cpu_fpga_start_addr\(0),
      I1 => DDR_STATUS_W(0),
      I2 => axi_araddr(2),
      I3 => axi_araddr(3),
      I4 => \CPU_WR_DONE_reg_n_0_[0]\,
      I5 => \^r_cpu_fpga_len\(0),
      O => \axi_rdata[0]_i_3_n_0\
    );
\axi_rdata[0]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"00000000B88888BB"
    )
        port map (
      I0 => \axi_rdata[0]_i_5_n_0\,
      I1 => axi_araddr(4),
      I2 => FPGA_TEMP_W(0),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      I5 => axi_araddr(5),
      O => \axi_rdata[0]_i_4_n_0\
    );
\axi_rdata[0]_i_5\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CFAFCFA0C0AFC0A0"
    )
        port map (
      I0 => \^r_cpu_rec_state\,
      I1 => FPGA_CPU_LEN(0),
      I2 => axi_araddr(2),
      I3 => axi_araddr(3),
      I4 => INT_STATE_W(0),
      I5 => FPGA_CPU_START_ADDR(0),
      O => \axi_rdata[0]_i_5_n_0\
    );
\axi_rdata[10]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[10]_i_2_n_0\,
      I4 => \axi_rdata[10]_i_3_n_0\,
      I5 => \axi_rdata[10]_i_4_n_0\,
      O => \axi_rdata[10]_i_1_n_0\
    );
\axi_rdata[10]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(10),
      I1 => RX_DROPPED_FRAMES(10),
      I2 => RX_HEAD_SEQ(10),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[10]_i_2_n_0\
    );
\axi_rdata[10]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(10),
      I1 => \^r_cpu_fpga_start_addr\(10),
      I2 => DDR_STATUS_W(10),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[10]_i_3_n_0\
    );
\axi_rdata[10]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(10),
      I1 => FPGA_TEMP_W(10),
      I2 => FPGA_CPU_LEN(10),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[10]_i_4_n_0\
    );
\axi_rdata[11]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[11]_i_2_n_0\,
      I4 => \axi_rdata[11]_i_3_n_0\,
      I5 => \axi_rdata[11]_i_4_n_0\,
      O => \axi_rdata[11]_i_1_n_0\
    );
\axi_rdata[11]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(11),
      I1 => RX_DROPPED_FRAMES(11),
      I2 => RX_HEAD_SEQ(11),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[11]_i_2_n_0\
    );
\axi_rdata[11]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(11),
      I1 => \^r_cpu_fpga_start_addr\(11),
      I2 => DDR_STATUS_W(11),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[11]_i_3_n_0\
    );
\axi_rdata[11]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(11),
      I1 => FPGA_CPU_LEN(11),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(11),
      O => \axi_rdata[11]_i_4_n_0\
    );
\axi_rdata[12]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[12]_i_2_n_0\,
      I4 => \axi_rdata[12]_i_3_n_0\,
      I5 => \axi_rdata[12]_i_4_n_0\,
      O => \axi_rdata[12]_i_1_n_0\
    );
\axi_rdata[12]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(12),
      I1 => RX_DROPPED_FRAMES(12),
      I2 => RX_HEAD_SEQ(12),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[12]_i_2_n_0\
    );
\axi_rdata[12]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(12),
      I1 => \^r_cpu_fpga_start_addr\(12),
      I2 => DDR_STATUS_W(12),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[12]_i_3_n_0\
    );
\axi_rdata[12]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(12),
      I1 => FPGA_TEMP_W(12),
      I2 => FPGA_CPU_LEN(12),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[12]_i_4_n_0\
    );
\axi_rdata[13]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[13]_i_2_n_0\,
      I4 => \axi_rdata[13]_i_3_n_0\,
      I5 => \axi_rdata[13]_i_4_n_0\,
      O => \axi_rdata[13]_i_1_n_0\
    );
\axi_rdata[13]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(13),
      I1 => RX_DROPPED_FRAMES(13),
      I2 => RX_HEAD_SEQ(13),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[13]_i_2_n_0\
    );
\axi_rdata[13]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(13),
      I1 => \^r_cpu_fpga_start_addr\(13),
      I2 => DDR_STATUS_W(13),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[13]_i_3_n_0\
    );
\axi_rdata[13]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"CF00A00FC000A00F"
    )
        port map (
      I0 => FPGA_TEMP_W(13),
      I1 => FPGA_CPU_LEN(13),
      I2 => axi_araddr(2),
      I3 => axi_araddr(3),
      I4 => axi_araddr(4),
      I5 => FPGA_CPU_START_ADDR(13),
      O => \axi_rdata[13]_i_4_n_0\
    );
\axi_rdata[14]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[14]_i_2_n_0\,
      I4 => \axi_rdata[14]_i_3_n_0\,
      I5 => \axi_rdata[14]_i_4_n_0\,
      O => \axi_rdata[14]_i_1_n_0\
    );
\axi_rdata[14]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(14),
      I1 => RX_DROPPED_FRAMES(14),
      I2 => RX_HEAD_SEQ(14),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[14]_i_2_n_0\
    );
\axi_rdata[14]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(14),
      I1 => \^r_cpu_fpga_start_addr\(14),
      I2 => DDR_STATUS_W(14),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[14]_i_3_n_0\
    );
\axi_rdata[14]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(14),
      I1 => FPGA_TEMP_W(14),
      I2 => FPGA_CPU_LEN(14),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[14]_i_4_n_0\
    );
\axi_rdata[15]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[15]_i_2_n_0\,
      I4 => \axi_rdata[15]_i_3_n_0\,
      I5 => \axi_rdata[15]_i_4_n_0\,
      O => \axi_rdata[15]_i_1_n_0\
    );
\axi_rdata[15]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(15),
      I1 => RX_DROPPED_FRAMES(15),
      I2 => RX_HEAD_SEQ(15),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[15]_i_2_n_0\
    );
\axi_rdata[15]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(15),
      I1 => \^r_cpu_fpga_start_addr\(15),
      I2 => DDR_STATUS_W(15),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[15]_i_3_n_0\
    );
\axi_rdata[15]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(15),
      I1 => FPGA_TEMP_W(15),
      I2 => FPGA_CPU_LEN(15),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[15]_i_4_n_0\
    );
\axi_rdata[16]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[16]_i_2_n_0\,
      I4 => \axi_rdata[16]_i_3_n_0\,
      I5 => \axi_rdata[16]_i_4_n_0\,
      O => \axi_rdata[16]_i_1_n_0\
    );
\axi_rdata[16]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(16),
      I1 => RX_DROPPED_FRAMES(16),
      I2 => RX_HEAD_SEQ(16),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[16]_i_2_n_0\
    );
\axi_rdata[16]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(16),
      I1 => \^r_cpu_fpga_start_addr\(16),
      I2 => DDR_STATUS_W(16),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[16]_i_3_n_0\
    );
\axi_rdata[16]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(16),
      I1 => FPGA_TEMP_W(16),
      I2 => FPGA_CPU_LEN(16),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[16]_i_4_n_0\
    );
\axi_rdata[17]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[17]_i_2_n_0\,
      I4 => \axi_rdata[17]_i_3_n_0\,
      I5 => \axi_rdata[17]_i_4_n_0\,
      O => \axi_rdata[17]_i_1_n_0\
    );
\axi_rdata[17]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(17),
      I1 => RX_DROPPED_FRAMES(17),
      I2 => RX_HEAD_SEQ(17),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[17]_i_2_n_0\
    );
\axi_rdata[17]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(17),
      I1 => \^r_cpu_fpga_start_addr\(17),
      I2 => DDR_STATUS_W(17),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[17]_i_3_n_0\
    );
\axi_rdata[17]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(17),
      I1 => FPGA_CPU_LEN(17),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(17),
      O => \axi_rdata[17]_i_4_n_0\
    );
\axi_rdata[18]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[18]_i_2_n_0\,
      I4 => \axi_rdata[18]_i_3_n_0\,
      I5 => \axi_rdata[18]_i_4_n_0\,
      O => \axi_rdata[18]_i_1_n_0\
    );
\axi_rdata[18]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(18),
      I1 => RX_DROPPED_FRAMES(18),
      I2 => RX_HEAD_SEQ(18),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[18]_i_2_n_0\
    );
\axi_rdata[18]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(18),
      I1 => \^r_cpu_fpga_start_addr\(18),
      I2 => DDR_STATUS_W(18),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[18]_i_3_n_0\
    );
\axi_rdata[18]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0CC0000AAFFFF00"
    )
        port map (
      I0 => FPGA_TEMP_W(18),
      I1 => FPGA_CPU_START_ADDR(18),
      I2 => FPGA_CPU_LEN(18),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[18]_i_4_n_0\
    );
\axi_rdata[19]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[19]_i_2_n_0\,
      I4 => \axi_rdata[19]_i_3_n_0\,
      I5 => \axi_rdata[19]_i_4_n_0\,
      O => \axi_rdata[19]_i_1_n_0\
    );
\axi_rdata[19]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(19),
      I1 => RX_DROPPED_FRAMES(19),
      I2 => RX_HEAD_SEQ(19),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[19]_i_2_n_0\
    );
\axi_rdata[19]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(19),
      I1 => \^r_cpu_fpga_start_addr\(19),
      I2 => DDR_STATUS_W(19),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[19]_i_3_n_0\
    );
\axi_rdata[19]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(19),
      I1 => FPGA_TEMP_W(19),
      I2 => FPGA_CPU_LEN(19),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[19]_i_4_n_0\
    );
\axi_rdata[1]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[1]_i_2_n_0\,
      I4 => \axi_rdata[1]_i_3_n_0\,
      I5 => \axi_rdata[1]_i_4_n_0\,
      O => \axi_rdata[1]_i_1_n_0\
    );
\axi_rdata[1]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(1),
      I1 => RX_DROPPED_FRAMES(1),
      I2 => RX_HEAD_SEQ(1),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[1]_i_2_n_0\
    );
\axi_rdata[1]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(1),
      I1 => \^r_cpu_fpga_start_addr\(1),
      I2 => DDR_STATUS_W(1),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[1]_i_3_n_0\
    );
\axi_rdata[1]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(1),
      I1 => FPGA_TEMP_W(1),
      I2 => FPGA_CPU_LEN(1),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[1]_i_4_n_0\
    );
\axi_rdata[20]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[20]_i_2_n_0\,
      I4 => \axi_rdata[20]_i_3_n_0\,
      I5 => \axi_rdata[20]_i_4_n_0\,
      O => \axi_rdata[20]_i_1_n_0\
    );
\axi_rdata[20]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(20),
      I1 => RX_DROPPED_FRAMES(20),
      I2 => RX_HEAD_SEQ(20),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[20]_i_2_n_0\
    );
\axi_rdata[20]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(20),
      I1 => \^r_cpu_fpga_start_addr\(20),
      I2 => DDR_STATUS_W(20),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[20]_i_3_n_0\
    );
\axi_rdata[20]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(20),
      I1 => FPGA_TEMP_W(20),
      I2 => FPGA_CPU_LEN(20),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[20]_i_4_n_0\
    );
\axi_rdata[21]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[21]_i_2_n_0\,
      I4 => \axi_rdata[21]_i_3_n_0\,
      I5 => \axi_rdata[21]_i_4_n_0\,
      O => \axi_rdata[21]_i_1_n_0\
    );
\axi_rdata[21]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(21),
      I1 => RX_DROPPED_FRAMES(21),
      I2 => RX_HEAD_SEQ(21),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[21]_i_2_n_0\
    );
\axi_rdata[21]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(21),
      I1 => \^r_cpu_fpga_start_addr\(21),
      I2 => DDR_STATUS_W(21),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[21]_i_3_n_0\
    );
\axi_rdata[21]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(21),
      I1 => FPGA_CPU_LEN(21),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(21),
      O => \axi_rdata[21]_i_4_n_0\
    );
\axi_rdata[22]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[22]_i_2_n_0\,
      I4 => \axi_rdata[22]_i_3_n_0\,
      I5 => \axi_rdata[22]_i_4_n_0\,
      O => \axi_rdata[22]_i_1_n_0\
    );
\axi_rdata[22]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(22),
      I1 => RX_DROPPED_FRAMES(22),
      I2 => RX_HEAD_SEQ(22),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[22]_i_2_n_0\
    );
\axi_rdata[22]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(22),
      I1 => \^r_cpu_fpga_start_addr\(22),
      I2 => DDR_STATUS_W(22),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[22]_i_3_n_0\
    );
\axi_rdata[22]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(22),
      I1 => FPGA_TEMP_W(22),
      I2 => FPGA_CPU_LEN(22),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[22]_i_4_n_0\
    );
\axi_rdata[23]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[23]_i_2_n_0\,
      I4 => \axi_rdata[23]_i_3_n_0\,
      I5 => \axi_rdata[23]_i_4_n_0\,
      O => \axi_rdata[23]_i_1_n_0\
    );
\axi_rdata[23]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(23),
      I1 => RX_DROPPED_FRAMES(23),
      I2 => RX_HEAD_SEQ(23),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[23]_i_2_n_0\
    );
\axi_rdata[23]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(23),
      I1 => \^r_cpu_fpga_start_addr\(23),
      I2 => DDR_STATUS_W(23),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[23]_i_3_n_0\
    );
\axi_rdata[23]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(23),
      I1 => FPGA_TEMP_W(23),
      I2 => FPGA_CPU_LEN(23),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[23]_i_4_n_0\
    );
\axi_rdata[24]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[24]_i_2_n_0\,
      I4 => \axi_rdata[24]_i_3_n_0\,
      I5 => \axi_rdata[24]_i_4_n_0\,
      O => \axi_rdata[24]_i_1_n_0\
    );
\axi_rdata[24]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(24),
      I1 => RX_DROPPED_FRAMES(24),
      I2 => RX_HEAD_SEQ(24),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[24]_i_2_n_0\
    );
\axi_rdata[24]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(24),
      I1 => \^r_cpu_fpga_start_addr\(24),
      I2 => DDR_STATUS_W(24),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[24]_i_3_n_0\
    );
\axi_rdata[24]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(24),
      I1 => FPGA_TEMP_W(24),
      I2 => FPGA_CPU_LEN(24),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[24]_i_4_n_0\
    );
\axi_rdata[25]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[25]_i_2_n_0\,
      I4 => \axi_rdata[25]_i_3_n_0\,
      I5 => \axi_rdata[25]_i_4_n_0\,
      O => \axi_rdata[25]_i_1_n_0\
    );
\axi_rdata[25]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(25),
      I1 => RX_DROPPED_FRAMES(25),
      I2 => RX_HEAD_SEQ(25),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[25]_i_2_n_0\
    );
\axi_rdata[25]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(25),
      I1 => \^r_cpu_fpga_start_addr\(25),
      I2 => DDR_STATUS_W(25),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[25]_i_3_n_0\
    );
\axi_rdata[25]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(25),
      I1 => FPGA_TEMP_W(25),
      I2 => FPGA_CPU_LEN(25),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[25]_i_4_n_0\
    );
\axi_rdata[26]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[26]_i_2_n_0\,
      I4 => \axi_rdata[26]_i_3_n_0\,
      I5 => \axi_rdata[26]_i_4_n_0\,
      O => \axi_rdata[26]_i_1_n_0\
    );
\axi_rdata[26]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(26),
      I1 => RX_DROPPED_FRAMES(26),
      I2 => RX_HEAD_SEQ(26),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[26]_i_2_n_0\
    );
\axi_rdata[26]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(26),
      I1 => \^r_cpu_fpga_start_addr\(26),
      I2 => DDR_STATUS_W(26),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[26]_i_3_n_0\
    );
\axi_rdata[26]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(26),
      I1 => FPGA_TEMP_W(26),
      I2 => FPGA_CPU_LEN(26),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[26]_i_4_n_0\
    );
\axi_rdata[27]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[27]_i_2_n_0\,
      I4 => \axi_rdata[27]_i_3_n_0\,
      I5 => \axi_rdata[27]_i_4_n_0\,
      O => \axi_rdata[27]_i_1_n_0\
    );
\axi_rdata[27]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(27),
      I1 => RX_DROPPED_FRAMES(27),
      I2 => RX_HEAD_SEQ(27),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[27]_i_2_n_0\
    );
\axi_rdata[27]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(27),
      I1 => \^r_cpu_fpga_start_addr\(27),
      I2 => DDR_STATUS_W(27),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[27]_i_3_n_0\
    );
\axi_rdata[27]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(27),
      I1 => FPGA_TEMP_W(27),
      I2 => FPGA_CPU_LEN(27),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[27]_i_4_n_0\
    );
\axi_rdata[28]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[28]_i_2_n_0\,
      I4 => \axi_rdata[28]_i_3_n_0\,
      I5 => \axi_rdata[28]_i_4_n_0\,
      O => \axi_rdata[28]_i_1_n_0\
    );
\axi_rdata[28]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(28),
      I1 => RX_DROPPED_FRAMES(28),
      I2 => RX_HEAD_SEQ(28),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[28]_i_2_n_0\
    );
\axi_rdata[28]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(28),
      I1 => \^r_cpu_fpga_start_addr\(28),
      I2 => DDR_STATUS_W(28),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[28]_i_3_n_0\
    );
\axi_rdata[28]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(28),
      I1 => FPGA_TEMP_W(28),
      I2 => FPGA_CPU_LEN(28),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[28]_i_4_n_0\
    );
\axi_rdata[29]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[29]_i_2_n_0\,
      I4 => \axi_rdata[29]_i_3_n_0\,
      I5 => \axi_rdata[29]_i_4_n_0\,
      O => \axi_rdata[29]_i_1_n_0\
    );
\axi_rdata[29]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(29),
      I1 => RX_DROPPED_FRAMES(29),
      I2 => RX_HEAD_SEQ(29),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[29]_i_2_n_0\
    );
\axi_rdata[29]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(29),
      I1 => \^r_cpu_fpga_start_addr\(29),
      I2 => DDR_STATUS_W(29),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[29]_i_3_n_0\
    );
\axi_rdata[29]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(29),
      I1 => FPGA_CPU_LEN(29),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(29),
      O => \axi_rdata[29]_i_4_n_0\
    );
\axi_rdata[2]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[2]_i_2_n_0\,
      I4 => \axi_rdata[2]_i_3_n_0\,
      I5 => \axi_rdata[2]_i_4_n_0\,
      O => \axi_rdata[2]_i_1_n_0\
    );
\axi_rdata[2]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(2),
      I1 => RX_DROPPED_FRAMES(2),
      I2 => RX_HEAD_SEQ(2),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[2]_i_2_n_0\
    );
\axi_rdata[2]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(2),
      I1 => \^r_cpu_fpga_start_addr\(2),
      I2 => DDR_STATUS_W(2),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[2]_i_3_n_0\
    );
\axi_rdata[2]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(2),
      I1 => FPGA_CPU_LEN(2),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(2),
      O => \axi_rdata[2]_i_4_n_0\
    );
\axi_rdata[30]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[30]_i_2_n_0\,
      I4 => \axi_rdata[30]_i_3_n_0\,
      I5 => \axi_rdata[30]_i_4_n_0\,
      O => \axi_rdata[30]_i_1_n_0\
    );
\axi_rdata[30]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(30),
      I1 => RX_DROPPED_FRAMES(30),
      I2 => RX_HEAD_SEQ(30),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[30]_i_2_n_0\
    );
\axi_rdata[30]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(30),
      I1 => \^r_cpu_fpga_start_addr\(30),
      I2 => DDR_STATUS_W(30),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[30]_i_3_n_0\
    );
\axi_rdata[30]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(30),
      I1 => FPGA_TEMP_W(30),
      I2 => FPGA_CPU_LEN(30),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[30]_i_4_n_0\
    );
\axi_rdata[31]_i_1\: unisim.vcomponents.LUT3
    generic map(
      INIT => X"08"
    )
        port map (
      I0 => \^s_axi_arready\,
      I1 => S_AXI_ARVALID,
      I2 => \^s_axi_rvalid\,
      O => slv_reg_rden
    );
\axi_rdata[31]_i_2\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[31]_i_4_n_0\,
      I4 => \axi_rdata[31]_i_5_n_0\,
      I5 => \axi_rdata[31]_i_6_n_0\,
      O => \axi_rdata[31]_i_2_n_0\
    );
\axi_rdata[31]_i_3\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"0001"
    )
        port map (
      I0 => axi_araddr(0),
      I1 => \axi_rdata[31]_i_7_n_0\,
      I2 => \axi_rdata[31]_i_8_n_0\,
      I3 => axi_araddr(1),
      O => \axi_rdata[31]_i_3_n_0\
    );
\axi_rdata[31]_i_4\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(31),
      I1 => RX_DROPPED_FRAMES(31),
      I2 => RX_HEAD_SEQ(31),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[31]_i_4_n_0\
    );
\axi_rdata[31]_i_5\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(31),
      I1 => \^r_cpu_fpga_start_addr\(31),
      I2 => DDR_STATUS_W(31),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[31]_i_5_n_0\
    );
\axi_rdata[31]_i_6\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(31),
      I1 => FPGA_TEMP_W(31),
      I2 => FPGA_CPU_LEN(31),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[31]_i_6_n_0\
    );
\axi_rdata[31]_i_7\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"FFFFFFFFFFFFFFFE"
    )
        port map (
      I0 => axi_araddr(15),
      I1 => axi_araddr(14),
      I2 => axi_araddr(13),
      I3 => axi_araddr(12),
      I4 => axi_araddr(6),
      I5 => axi_araddr(7),
      O => \axi_rdata[31]_i_7_n_0\
    );
\axi_rdata[31]_i_8\: unisim.vcomponents.LUT4
    generic map(
      INIT => X"FFFE"
    )
        port map (
      I0 => axi_araddr(8),
      I1 => axi_araddr(9),
      I2 => axi_araddr(10),
      I3 => axi_araddr(11),
      O => \axi_rdata[31]_i_8_n_0\
    );
\axi_rdata[3]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[3]_i_2_n_0\,
      I4 => \axi_rdata[3]_i_3_n_0\,
      I5 => \axi_rdata[3]_i_4_n_0\,
      O => \axi_rdata[3]_i_1_n_0\
    );
\axi_rdata[3]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(3),
      I1 => RX_DROPPED_FRAMES(3),
      I2 => RX_HEAD_SEQ(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[3]_i_2_n_0\
    );
\axi_rdata[3]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(3),
      I1 => \^r_cpu_fpga_start_addr\(3),
      I2 => DDR_STATUS_W(3),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[3]_i_3_n_0\
    );
\axi_rdata[3]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(3),
      I1 => FPGA_TEMP_W(3),
      I2 => FPGA_CPU_LEN(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[3]_i_4_n_0\
    );
\axi_rdata[4]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[4]_i_2_n_0\,
      I4 => \axi_rdata[4]_i_3_n_0\,
      I5 => \axi_rdata[4]_i_4_n_0\,
      O => \axi_rdata[4]_i_1_n_0\
    );
\axi_rdata[4]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(4),
      I1 => RX_DROPPED_FRAMES(4),
      I2 => RX_HEAD_SEQ(4),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[4]_i_2_n_0\
    );
\axi_rdata[4]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(4),
      I1 => \^r_cpu_fpga_start_addr\(4),
      I2 => DDR_STATUS_W(4),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[4]_i_3_n_0\
    );
\axi_rdata[4]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(4),
      I1 => FPGA_CPU_LEN(4),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(4),
      O => \axi_rdata[4]_i_4_n_0\
    );
\axi_rdata[5]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[5]_i_2_n_0\,
      I4 => \axi_rdata[5]_i_3_n_0\,
      I5 => \axi_rdata[5]_i_4_n_0\,
      O => \axi_rdata[5]_i_1_n_0\
    );
\axi_rdata[5]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(5),
      I1 => RX_DROPPED_FRAMES(5),
      I2 => RX_HEAD_SEQ(5),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[5]_i_2_n_0\
    );
\axi_rdata[5]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(5),
      I1 => \^r_cpu_fpga_start_addr\(5),
      I2 => DDR_STATUS_W(5),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[5]_i_3_n_0\
    );
\axi_rdata[5]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(5),
      I1 => FPGA_TEMP_W(5),
      I2 => FPGA_CPU_LEN(5),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[5]_i_4_n_0\
    );
\axi_rdata[6]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[6]_i_2_n_0\,
      I4 => \axi_rdata[6]_i_3_n_0\,
      I5 => \axi_rdata[6]_i_4_n_0\,
      O => \axi_rdata[6]_i_1_n_0\
    );
\axi_rdata[6]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(6),
      I1 => RX_DROPPED_FRAMES(6),
      I2 => RX_HEAD_SEQ(6),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[6]_i_2_n_0\
    );
\axi_rdata[6]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(6),
      I1 => \^r_cpu_fpga_start_addr\(6),
      I2 => DDR_STATUS_W(6),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[6]_i_3_n_0\
    );
\axi_rdata[6]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(6),
      I1 => FPGA_TEMP_W(6),
      I2 => FPGA_CPU_LEN(6),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[6]_i_4_n_0\
    );
\axi_rdata[7]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[7]_i_2_n_0\,
      I4 => \axi_rdata[7]_i_3_n_0\,
      I5 => \axi_rdata[7]_i_4_n_0\,
      O => \axi_rdata[7]_i_1_n_0\
    );
\axi_rdata[7]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(7),
      I1 => RX_DROPPED_FRAMES(7),
      I2 => RX_HEAD_SEQ(7),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[7]_i_2_n_0\
    );
\axi_rdata[7]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(7),
      I1 => \^r_cpu_fpga_start_addr\(7),
      I2 => DDR_STATUS_W(7),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[7]_i_3_n_0\
    );
\axi_rdata[7]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(7),
      I1 => FPGA_TEMP_W(7),
      I2 => FPGA_CPU_LEN(7),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[7]_i_4_n_0\
    );
\axi_rdata[8]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[8]_i_2_n_0\,
      I4 => \axi_rdata[8]_i_3_n_0\,
      I5 => \axi_rdata[8]_i_4_n_0\,
      O => \axi_rdata[8]_i_1_n_0\
    );
\axi_rdata[8]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(8),
      I1 => RX_DROPPED_FRAMES(8),
      I2 => RX_HEAD_SEQ(8),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[8]_i_2_n_0\
    );
\axi_rdata[8]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(8),
      I1 => \^r_cpu_fpga_start_addr\(8),
      I2 => DDR_STATUS_W(8),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[8]_i_3_n_0\
    );
\axi_rdata[8]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"C0A0FF00C0A00F00"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(8),
      I1 => FPGA_CPU_LEN(8),
      I2 => axi_araddr(3),
      I3 => axi_araddr(2),
      I4 => axi_araddr(4),
      I5 => FPGA_TEMP_W(8),
      O => \axi_rdata[8]_i_4_n_0\
    );
\axi_rdata[9]_i_1\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"AA2A8A0AA0208000"
    )
        port map (
      I0 => \axi_rdata[31]_i_3_n_0\,
      I1 => axi_araddr(4),
      I2 => axi_araddr(5),
      I3 => \axi_rdata[9]_i_2_n_0\,
      I4 => \axi_rdata[9]_i_3_n_0\,
      I5 => \axi_rdata[9]_i_4_n_0\,
      O => \axi_rdata[9]_i_1_n_0\
    );
\axi_rdata[9]_i_2\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"00CCF0AA"
    )
        port map (
      I0 => RX_READY_BLOCKS(9),
      I1 => RX_DROPPED_FRAMES(9),
      I2 => RX_HEAD_SEQ(9),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      O => \axi_rdata[9]_i_2_n_0\
    );
\axi_rdata[9]_i_3\: unisim.vcomponents.LUT5
    generic map(
      INIT => X"F0CCAA00"
    )
        port map (
      I0 => \^r_cpu_fpga_len\(9),
      I1 => \^r_cpu_fpga_start_addr\(9),
      I2 => DDR_STATUS_W(9),
      I3 => axi_araddr(3),
      I4 => axi_araddr(2),
      O => \axi_rdata[9]_i_3_n_0\
    );
\axi_rdata[9]_i_4\: unisim.vcomponents.LUT6
    generic map(
      INIT => X"F0AA0000CC000000"
    )
        port map (
      I0 => FPGA_CPU_START_ADDR(9),
      I1 => FPGA_TEMP_W(9),
      I2 => FPGA_CPU_LEN(9),
      I3 => axi_araddr(2),
      I4 => axi_araddr(3),
      I5 => axi_araddr(4),
      O => \axi_rdata[9]_i_4_n_0\
    );
\axi_rdata_reg[0]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[0]_i_1_n_0\,
      Q => S_AXI_RDATA(0),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[10]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[10]_i_1_n_0\,
      Q => S_AXI_RDATA(10),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[11]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[11]_i_1_n_0\,
      Q => S_AXI_RDATA(11),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[12]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[12]_i_1_n_0\,
      Q => S_AXI_RDATA(12),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[13]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[13]_i_1_n_0\,
      Q => S_AXI_RDATA(13),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[14]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[14]_i_1_n_0\,
      Q => S_AXI_RDATA(14),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[15]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[15]_i_1_n_0\,
      Q => S_AXI_RDATA(15),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[16]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[16]_i_1_n_0\,
      Q => S_AXI_RDATA(16),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[17]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[17]_i_1_n_0\,
      Q => S_AXI_RDATA(17),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[18]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[18]_i_1_n_0\,
      Q => S_AXI_RDATA(18),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[19]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[19]_i_1_n_0\,
      Q => S_AXI_RDATA(19),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[1]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[1]_i_1_n_0\,
      Q => S_AXI_RDATA(1),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[20]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[20]_i_1_n_0\,
      Q => S_AXI_RDATA(20),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[21]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[21]_i_1_n_0\,
      Q => S_AXI_RDATA(21),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[22]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[22]_i_1_n_0\,
      Q => S_AXI_RDATA(22),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[23]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[23]_i_1_n_0\,
      Q => S_AXI_RDATA(23),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[24]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[24]_i_1_n_0\,
      Q => S_AXI_RDATA(24),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[25]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[25]_i_1_n_0\,
      Q => S_AXI_RDATA(25),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[26]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[26]_i_1_n_0\,
      Q => S_AXI_RDATA(26),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[27]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[27]_i_1_n_0\,
      Q => S_AXI_RDATA(27),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[28]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[28]_i_1_n_0\,
      Q => S_AXI_RDATA(28),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[29]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[29]_i_1_n_0\,
      Q => S_AXI_RDATA(29),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[2]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[2]_i_1_n_0\,
      Q => S_AXI_RDATA(2),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[30]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[30]_i_1_n_0\,
      Q => S_AXI_RDATA(30),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[31]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[31]_i_2_n_0\,
      Q => S_AXI_RDATA(31),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[3]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[3]_i_1_n_0\,
      Q => S_AXI_RDATA(3),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[4]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[4]_i_1_n_0\,
      Q => S_AXI_RDATA(4),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[5]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[5]_i_1_n_0\,
      Q => S_AXI_RDATA(5),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[6]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[6]_i_1_n_0\,
      Q => S_AXI_RDATA(6),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[7]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[7]_i_1_n_0\,
      Q => S_AXI_RDATA(7),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[8]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[8]_i_1_n_0\,
      Q => S_AXI_RDATA(8),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
\axi_rdata_reg[9]\: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => slv_reg_rden,
      D => \axi_rdata[9]_i_1_n_0\,
      Q => S_AXI_RDATA(9),
      R => \INT_STATE_R[0]_i_1_n_0\
    );
axi_rvalid_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"7444"
    )
        port map (
      I0 => S_AXI_RREADY,
      I1 => \^s_axi_rvalid\,
      I2 => S_AXI_ARVALID,
      I3 => \^s_axi_arready\,
      O => axi_rvalid_i_1_n_0
    );
axi_rvalid_reg: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => axi_rvalid_i_1_n_0,
      Q => \^s_axi_rvalid\,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
axi_wready_i_1: unisim.vcomponents.LUT4
    generic map(
      INIT => X"4000"
    )
        port map (
      I0 => \^s_axi_wready\,
      I1 => aw_en_reg_n_0,
      I2 => S_AXI_AWVALID,
      I3 => S_AXI_WVALID,
      O => axi_wready0
    );
axi_wready_reg: unisim.vcomponents.FDRE
     port map (
      C => S_AXI_ACLK,
      CE => '1',
      D => axi_wready0,
      Q => \^s_axi_wready\,
      R => \INT_STATE_R[0]_i_1_n_0\
    );
r_RD_START_INST_0: unisim.vcomponents.LUT2
    generic map(
      INIT => X"2"
    )
        port map (
      I0 => \CPU_WR_DONE_reg_n_0_[0]\,
      I1 => CPU_WR_DONE_d,
      O => r_RD_START
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_INFO_EXCH_0_0 is
  port (
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
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of design_1_INFO_EXCH_0_0 : entity is true;
  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of design_1_INFO_EXCH_0_0 : entity is "design_1_INFO_EXCH_0_0,INFO_EXCH,{}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of design_1_INFO_EXCH_0_0 : entity is "yes";
  attribute IP_DEFINITION_SOURCE : string;
  attribute IP_DEFINITION_SOURCE of design_1_INFO_EXCH_0_0 : entity is "module_ref";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of design_1_INFO_EXCH_0_0 : entity is "INFO_EXCH,Vivado 2020.2";
end design_1_INFO_EXCH_0_0;

architecture STRUCTURE of design_1_INFO_EXCH_0_0 is
  signal \<const0>\ : STD_LOGIC;
  signal \^r_clear_inter\ : STD_LOGIC;
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of S_AXI_ACLK : signal is "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of S_AXI_ACLK : signal is "XIL_INTERFACENAME S_AXI_ACLK, ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET S_AXI_ARESETN, FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of S_AXI_ARESETN : signal is "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST";
  attribute X_INTERFACE_PARAMETER of S_AXI_ARESETN : signal is "XIL_INTERFACENAME S_AXI_ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of S_AXI_ARREADY : signal is "xilinx.com:interface:aximm:1.0 S_AXI ARREADY";
  attribute X_INTERFACE_INFO of S_AXI_ARVALID : signal is "xilinx.com:interface:aximm:1.0 S_AXI ARVALID";
  attribute X_INTERFACE_INFO of S_AXI_AWREADY : signal is "xilinx.com:interface:aximm:1.0 S_AXI AWREADY";
  attribute X_INTERFACE_INFO of S_AXI_AWVALID : signal is "xilinx.com:interface:aximm:1.0 S_AXI AWVALID";
  attribute X_INTERFACE_INFO of S_AXI_BREADY : signal is "xilinx.com:interface:aximm:1.0 S_AXI BREADY";
  attribute X_INTERFACE_INFO of S_AXI_BVALID : signal is "xilinx.com:interface:aximm:1.0 S_AXI BVALID";
  attribute X_INTERFACE_INFO of S_AXI_RREADY : signal is "xilinx.com:interface:aximm:1.0 S_AXI RREADY";
  attribute X_INTERFACE_PARAMETER of S_AXI_RREADY : signal is "XIL_INTERFACENAME S_AXI, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 250000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of S_AXI_RVALID : signal is "xilinx.com:interface:aximm:1.0 S_AXI RVALID";
  attribute X_INTERFACE_INFO of S_AXI_WREADY : signal is "xilinx.com:interface:aximm:1.0 S_AXI WREADY";
  attribute X_INTERFACE_INFO of S_AXI_WVALID : signal is "xilinx.com:interface:aximm:1.0 S_AXI WVALID";
  attribute X_INTERFACE_INFO of S_AXI_ARADDR : signal is "xilinx.com:interface:aximm:1.0 S_AXI ARADDR";
  attribute X_INTERFACE_INFO of S_AXI_ARPROT : signal is "xilinx.com:interface:aximm:1.0 S_AXI ARPROT";
  attribute X_INTERFACE_INFO of S_AXI_AWADDR : signal is "xilinx.com:interface:aximm:1.0 S_AXI AWADDR";
  attribute X_INTERFACE_INFO of S_AXI_AWPROT : signal is "xilinx.com:interface:aximm:1.0 S_AXI AWPROT";
  attribute X_INTERFACE_INFO of S_AXI_BRESP : signal is "xilinx.com:interface:aximm:1.0 S_AXI BRESP";
  attribute X_INTERFACE_INFO of S_AXI_RDATA : signal is "xilinx.com:interface:aximm:1.0 S_AXI RDATA";
  attribute X_INTERFACE_INFO of S_AXI_RRESP : signal is "xilinx.com:interface:aximm:1.0 S_AXI RRESP";
  attribute X_INTERFACE_INFO of S_AXI_WDATA : signal is "xilinx.com:interface:aximm:1.0 S_AXI WDATA";
  attribute X_INTERFACE_INFO of S_AXI_WSTRB : signal is "xilinx.com:interface:aximm:1.0 S_AXI WSTRB";
begin
  S_AXI_BRESP(1) <= \<const0>\;
  S_AXI_BRESP(0) <= \<const0>\;
  S_AXI_RRESP(1) <= \<const0>\;
  S_AXI_RRESP(0) <= \<const0>\;
  r_CLEAR_INTER <= \^r_clear_inter\;
  r_INT_STATE <= \^r_clear_inter\;
GND: unisim.vcomponents.GND
     port map (
      G => \<const0>\
    );
inst: entity work.design_1_INFO_EXCH_0_0_INFO_EXCH
     port map (
      CPU_WR_DONE_EVENT => CPU_WR_DONE_EVENT,
      DDR_STATUS_W(31 downto 0) => DDR_STATUS_W(31 downto 0),
      FPGA_CPU_LEN(31 downto 0) => FPGA_CPU_LEN(31 downto 0),
      FPGA_CPU_START_ADDR(31 downto 0) => FPGA_CPU_START_ADDR(31 downto 0),
      FPGA_TEMP_W(31 downto 0) => FPGA_TEMP_W(31 downto 0),
      INT_STATE_W(0) => INT_STATE_W(0),
      RX_DROPPED_FRAMES(31 downto 0) => RX_DROPPED_FRAMES(31 downto 0),
      RX_HEAD_SEQ(31 downto 0) => RX_HEAD_SEQ(31 downto 0),
      RX_READY_BLOCKS(31 downto 0) => RX_READY_BLOCKS(31 downto 0),
      S_AXI_ACLK => S_AXI_ACLK,
      S_AXI_ARADDR(15 downto 0) => S_AXI_ARADDR(15 downto 0),
      S_AXI_ARESETN => S_AXI_ARESETN,
      S_AXI_ARREADY => S_AXI_ARREADY,
      S_AXI_ARVALID => S_AXI_ARVALID,
      S_AXI_AWADDR(15 downto 0) => S_AXI_AWADDR(15 downto 0),
      S_AXI_AWREADY => S_AXI_AWREADY,
      S_AXI_AWVALID => S_AXI_AWVALID,
      S_AXI_BREADY => S_AXI_BREADY,
      S_AXI_BVALID => S_AXI_BVALID,
      S_AXI_RDATA(31 downto 0) => S_AXI_RDATA(31 downto 0),
      S_AXI_RREADY => S_AXI_RREADY,
      S_AXI_RVALID => S_AXI_RVALID,
      S_AXI_WDATA(31 downto 0) => S_AXI_WDATA(31 downto 0),
      S_AXI_WREADY => S_AXI_WREADY,
      S_AXI_WSTRB(3 downto 0) => S_AXI_WSTRB(3 downto 0),
      S_AXI_WVALID => S_AXI_WVALID,
      r_CLEAR_INTER => \^r_clear_inter\,
      r_CPU_FPGA_LEN(31 downto 0) => r_CPU_FPGA_LEN(31 downto 0),
      r_CPU_FPGA_START_ADDR(31 downto 0) => r_CPU_FPGA_START_ADDR(31 downto 0),
      r_CPU_REC_STATE => r_CPU_REC_STATE,
      r_RD_START => r_RD_START
    );
end STRUCTURE;
