//------------------------------------------------------------------------------
//  (c) Copyright 2013-2015 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES.
//------------------------------------------------------------------------------

// ***************************
// * DO NOT MODIFY THIS FILE *
// ***************************

`timescale 1ps/1ps

module gtwizard_ultrascale_v1_7_9_gtye3_channel #(


  // -------------------------------------------------------------------------------------------------------------------
  // Parameters controlling primitive wrapper HDL generation
  // -------------------------------------------------------------------------------------------------------------------
  parameter         NUM_CHANNELS = 4,


  // -------------------------------------------------------------------------------------------------------------------
  // Parameters relating to GTYE3_CHANNEL primitive
  // -------------------------------------------------------------------------------------------------------------------

  // primitive wrapper parameters which override corresponding GTYE3_CHANNEL primitive parameters
  parameter   [0:0] GTYE3_CHANNEL_ACJTAG_DEBUG_MODE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ACJTAG_MODE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ACJTAG_RESET = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_ADAPT_CFG0 = 16'h9200,
  parameter  [15:0] GTYE3_CHANNEL_ADAPT_CFG1 = 16'h801C,
  parameter  [15:0] GTYE3_CHANNEL_ADAPT_CFG2 = 16'b0000000000000000,
  parameter         GTYE3_CHANNEL_ALIGN_COMMA_DOUBLE = "FALSE",
  parameter   [9:0] GTYE3_CHANNEL_ALIGN_COMMA_ENABLE = 10'b0001111111,
  parameter integer GTYE3_CHANNEL_ALIGN_COMMA_WORD = 1,
  parameter         GTYE3_CHANNEL_ALIGN_MCOMMA_DET = "TRUE",
  parameter   [9:0] GTYE3_CHANNEL_ALIGN_MCOMMA_VALUE = 10'b1010000011,
  parameter         GTYE3_CHANNEL_ALIGN_PCOMMA_DET = "TRUE",
  parameter   [9:0] GTYE3_CHANNEL_ALIGN_PCOMMA_VALUE = 10'b0101111100,
  parameter   [0:0] GTYE3_CHANNEL_AUTO_BW_SEL_BYPASS = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_A_RXOSCALRESET = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_A_RXPROGDIVRESET = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_A_TXDIFFCTRL = 5'b01100,
  parameter   [0:0] GTYE3_CHANNEL_A_TXPROGDIVRESET = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CAPBYPASS_FORCE = 1'b0,
  parameter         GTYE3_CHANNEL_CBCC_DATA_SOURCE_SEL = "DECODED",
  parameter   [0:0] GTYE3_CHANNEL_CDR_SWAP_MODE_EN = 1'b0,
  parameter         GTYE3_CHANNEL_CHAN_BOND_KEEP_ALIGN = "FALSE",
  parameter integer GTYE3_CHANNEL_CHAN_BOND_MAX_SKEW = 7,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_1_1 = 10'b0101111100,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_1_2 = 10'b0000000000,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_1_3 = 10'b0000000000,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_1_4 = 10'b0000000000,
  parameter   [3:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_1_ENABLE = 4'b1111,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_2_1 = 10'b0100000000,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_2_2 = 10'b0100000000,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_2_3 = 10'b0100000000,
  parameter   [9:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_2_4 = 10'b0100000000,
  parameter   [3:0] GTYE3_CHANNEL_CHAN_BOND_SEQ_2_ENABLE = 4'b1111,
  parameter         GTYE3_CHANNEL_CHAN_BOND_SEQ_2_USE = "FALSE",
  parameter integer GTYE3_CHANNEL_CHAN_BOND_SEQ_LEN = 2,
  parameter  [15:0] GTYE3_CHANNEL_CH_HSPMUX = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL1_CFG_0 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL1_CFG_1 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL1_CFG_2 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL1_CFG_3 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL2_CFG_0 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL2_CFG_1 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL2_CFG_2 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL2_CFG_3 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL2_CFG_4 = 16'b0000000000000000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL_RSVD0 = 16'h4000,
  parameter  [15:0] GTYE3_CHANNEL_CKCAL_RSVD1 = 16'h0000,
  parameter         GTYE3_CHANNEL_CLK_CORRECT_USE = "TRUE",
  parameter         GTYE3_CHANNEL_CLK_COR_KEEP_IDLE = "FALSE",
  parameter integer GTYE3_CHANNEL_CLK_COR_MAX_LAT = 20,
  parameter integer GTYE3_CHANNEL_CLK_COR_MIN_LAT = 18,
  parameter         GTYE3_CHANNEL_CLK_COR_PRECEDENCE = "TRUE",
  parameter integer GTYE3_CHANNEL_CLK_COR_REPEAT_WAIT = 0,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_1_1 = 10'b0100011100,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_1_2 = 10'b0000000000,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_1_3 = 10'b0000000000,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_1_4 = 10'b0000000000,
  parameter   [3:0] GTYE3_CHANNEL_CLK_COR_SEQ_1_ENABLE = 4'b1111,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_2_1 = 10'b0100000000,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_2_2 = 10'b0100000000,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_2_3 = 10'b0100000000,
  parameter   [9:0] GTYE3_CHANNEL_CLK_COR_SEQ_2_4 = 10'b0100000000,
  parameter   [3:0] GTYE3_CHANNEL_CLK_COR_SEQ_2_ENABLE = 4'b1111,
  parameter         GTYE3_CHANNEL_CLK_COR_SEQ_2_USE = "FALSE",
  parameter integer GTYE3_CHANNEL_CLK_COR_SEQ_LEN = 2,
  parameter  [15:0] GTYE3_CHANNEL_CPLL_CFG0 = 16'h20FA,
  parameter  [15:0] GTYE3_CHANNEL_CPLL_CFG1 = 16'h24AA,
  parameter  [15:0] GTYE3_CHANNEL_CPLL_CFG2 = 16'hF007,
  parameter   [5:0] GTYE3_CHANNEL_CPLL_CFG3 = 6'h00,
  parameter integer GTYE3_CHANNEL_CPLL_FBDIV = 4,
  parameter integer GTYE3_CHANNEL_CPLL_FBDIV_45 = 4,
  parameter  [15:0] GTYE3_CHANNEL_CPLL_INIT_CFG0 = 16'h001E,
  parameter   [7:0] GTYE3_CHANNEL_CPLL_INIT_CFG1 = 8'h00,
  parameter  [15:0] GTYE3_CHANNEL_CPLL_LOCK_CFG = 16'h01E8,
  parameter integer GTYE3_CHANNEL_CPLL_REFCLK_DIV = 1,
  parameter   [2:0] GTYE3_CHANNEL_CTLE3_OCAP_EXT_CTRL = 3'b000,
  parameter   [0:0] GTYE3_CHANNEL_CTLE3_OCAP_EXT_EN = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_DDI_CTRL = 2'b00,
  parameter integer GTYE3_CHANNEL_DDI_REALIGN_WAIT = 15,
  parameter         GTYE3_CHANNEL_DEC_MCOMMA_DETECT = "TRUE",
  parameter         GTYE3_CHANNEL_DEC_PCOMMA_DETECT = "TRUE",
  parameter         GTYE3_CHANNEL_DEC_VALID_COMMA_ONLY = "TRUE",
  parameter   [0:0] GTYE3_CHANNEL_DFE_D_X_REL_POS = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DFE_VCM_COMP_EN = 1'b0,
  parameter   [9:0] GTYE3_CHANNEL_DMONITOR_CFG0 = 10'h000,
  parameter   [7:0] GTYE3_CHANNEL_DMONITOR_CFG1 = 8'h00,
  parameter   [0:0] GTYE3_CHANNEL_ES_CLK_PHASE_SEL = 1'b0,
  parameter   [5:0] GTYE3_CHANNEL_ES_CONTROL = 6'b000000,
  parameter         GTYE3_CHANNEL_ES_ERRDET_EN = "FALSE",
  parameter         GTYE3_CHANNEL_ES_EYE_SCAN_EN = "FALSE",
  parameter  [11:0] GTYE3_CHANNEL_ES_HORZ_OFFSET = 12'h000,
  parameter   [9:0] GTYE3_CHANNEL_ES_PMA_CFG = 10'b0000000000,
  parameter   [4:0] GTYE3_CHANNEL_ES_PRESCALE = 5'b00000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER1 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER2 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER4 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER5 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER6 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER7 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER8 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUALIFIER9 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK1 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK2 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK4 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK5 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK6 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK7 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK8 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_QUAL_MASK9 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK1 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK2 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK4 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK5 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK6 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK7 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK8 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_ES_SDATA_MASK9 = 16'h0000,
  parameter  [10:0] GTYE3_CHANNEL_EVODD_PHI_CFG = 11'b00000000000,
  parameter   [0:0] GTYE3_CHANNEL_EYE_SCAN_SWAP_EN = 1'b0,
  parameter   [3:0] GTYE3_CHANNEL_FTS_DESKEW_SEQ_ENABLE = 4'b1111,
  parameter   [3:0] GTYE3_CHANNEL_FTS_LANE_DESKEW_CFG = 4'b1111,
  parameter         GTYE3_CHANNEL_FTS_LANE_DESKEW_EN = "FALSE",
  parameter   [4:0] GTYE3_CHANNEL_GEARBOX_MODE = 5'b00000,
  parameter   [0:0] GTYE3_CHANNEL_GM_BIAS_SELECT = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ISCAN_CK_PH_SEL2 = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_LOCAL_MASTER = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_LOOP0_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP10_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP11_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP12_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP13_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP1_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP2_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP3_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP4_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP5_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP6_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP7_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP8_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_LOOP9_CFG = 16'h0000,
  parameter   [2:0] GTYE3_CHANNEL_LPBK_BIAS_CTRL = 3'b000,
  parameter   [0:0] GTYE3_CHANNEL_LPBK_EN_RCAL_B = 1'b0,
  parameter   [3:0] GTYE3_CHANNEL_LPBK_EXT_RCAL = 4'b0000,
  parameter   [3:0] GTYE3_CHANNEL_LPBK_RG_CTRL = 4'b0000,
  parameter   [1:0] GTYE3_CHANNEL_OOBDIVCTL = 2'b00,
  parameter   [0:0] GTYE3_CHANNEL_OOB_PWRUP = 1'b0,
  parameter         GTYE3_CHANNEL_PCI3_AUTO_REALIGN = "FRST_SMPL",
  parameter   [0:0] GTYE3_CHANNEL_PCI3_PIPE_RX_ELECIDLE = 1'b1,
  parameter   [1:0] GTYE3_CHANNEL_PCI3_RX_ASYNC_EBUF_BYPASS = 2'b00,
  parameter   [0:0] GTYE3_CHANNEL_PCI3_RX_ELECIDLE_EI2_ENABLE = 1'b0,
  parameter   [5:0] GTYE3_CHANNEL_PCI3_RX_ELECIDLE_H2L_COUNT = 6'b000000,
  parameter   [2:0] GTYE3_CHANNEL_PCI3_RX_ELECIDLE_H2L_DISABLE = 3'b000,
  parameter   [5:0] GTYE3_CHANNEL_PCI3_RX_ELECIDLE_HI_COUNT = 6'b000000,
  parameter   [0:0] GTYE3_CHANNEL_PCI3_RX_ELECIDLE_LP4_DISABLE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCI3_RX_FIFO_DISABLE = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_PCIE_BUFG_DIV_CTRL = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_PCIE_RXPCS_CFG_GEN3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_PCIE_RXPMA_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_PCIE_TXPCS_CFG_GEN3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_PCIE_TXPMA_CFG = 16'h0000,
  parameter         GTYE3_CHANNEL_PCS_PCIE_EN = "FALSE",
  parameter  [15:0] GTYE3_CHANNEL_PCS_RSVD0 = 16'b0000000000000000,
  parameter   [2:0] GTYE3_CHANNEL_PCS_RSVD1 = 3'b000,
  parameter  [11:0] GTYE3_CHANNEL_PD_TRANS_TIME_FROM_P2 = 12'h03C,
  parameter   [7:0] GTYE3_CHANNEL_PD_TRANS_TIME_NONE_P2 = 8'h19,
  parameter   [7:0] GTYE3_CHANNEL_PD_TRANS_TIME_TO_P2 = 8'h64,
  parameter   [1:0] GTYE3_CHANNEL_PLL_SEL_MODE_GEN12 = 2'h0,
  parameter   [1:0] GTYE3_CHANNEL_PLL_SEL_MODE_GEN3 = 2'h0,
  parameter  [15:0] GTYE3_CHANNEL_PMA_RSV0 = 16'h00E0,
  parameter  [15:0] GTYE3_CHANNEL_PMA_RSV1 = 16'h000A,
  parameter integer GTYE3_CHANNEL_PREIQ_FREQ_BST = 0,
  parameter   [2:0] GTYE3_CHANNEL_PROCESS_PAR = 3'b010,
  parameter   [0:0] GTYE3_CHANNEL_RATE_SW_USE_DRP = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RESET_POWERSAVE_DISABLE = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_RXBUFRESET_TIME = 5'b00001,
  parameter         GTYE3_CHANNEL_RXBUF_ADDR_MODE = "FULL",
  parameter   [3:0] GTYE3_CHANNEL_RXBUF_EIDLE_HI_CNT = 4'b1000,
  parameter   [3:0] GTYE3_CHANNEL_RXBUF_EIDLE_LO_CNT = 4'b0000,
  parameter         GTYE3_CHANNEL_RXBUF_EN = "TRUE",
  parameter         GTYE3_CHANNEL_RXBUF_RESET_ON_CB_CHANGE = "TRUE",
  parameter         GTYE3_CHANNEL_RXBUF_RESET_ON_COMMAALIGN = "FALSE",
  parameter         GTYE3_CHANNEL_RXBUF_RESET_ON_EIDLE = "FALSE",
  parameter         GTYE3_CHANNEL_RXBUF_RESET_ON_RATE_CHANGE = "TRUE",
  parameter integer GTYE3_CHANNEL_RXBUF_THRESH_OVFLW = 0,
  parameter         GTYE3_CHANNEL_RXBUF_THRESH_OVRD = "FALSE",
  parameter integer GTYE3_CHANNEL_RXBUF_THRESH_UNDFLW = 4,
  parameter   [4:0] GTYE3_CHANNEL_RXCDRFREQRESET_TIME = 5'b00001,
  parameter   [4:0] GTYE3_CHANNEL_RXCDRPHRESET_TIME = 5'b00001,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG0_GEN3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG1 = 16'h0300,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG1_GEN3 = 16'h0300,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG2 = 16'h0060,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG2_GEN3 = 16'h0060,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG3_GEN3 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG4 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG4_GEN3 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG5 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_CFG5_GEN3 = 16'h0000,
  parameter   [0:0] GTYE3_CHANNEL_RXCDR_FR_RESET_ON_EIDLE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDR_HOLD_DURING_EIDLE = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_LOCK_CFG0 = 16'h0001,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_LOCK_CFG1 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_LOCK_CFG2 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXCDR_LOCK_CFG3 = 16'h0000,
  parameter   [0:0] GTYE3_CHANNEL_RXCDR_PH_RESET_ON_EIDLE = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RXCFOKDONE_SRC = 2'b00,
  parameter  [15:0] GTYE3_CHANNEL_RXCFOK_CFG0 = 16'h3E00,
  parameter  [15:0] GTYE3_CHANNEL_RXCFOK_CFG1 = 16'h0042,
  parameter  [15:0] GTYE3_CHANNEL_RXCFOK_CFG2 = 16'h002D,
  parameter   [6:0] GTYE3_CHANNEL_RXDFELPMRESET_TIME = 7'b0001111,
  parameter  [15:0] GTYE3_CHANNEL_RXDFELPM_KL_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFELPM_KL_CFG1 = 16'h0022,
  parameter  [15:0] GTYE3_CHANNEL_RXDFELPM_KL_CFG2 = 16'h0100,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_CFG0 = 16'h4C00,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_CFG1 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_GC_CFG0 = 16'h1E00,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_GC_CFG1 = 16'h1900,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_GC_CFG2 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H2_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H2_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H3_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H3_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H4_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H4_CFG1 = 16'h0003,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H5_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H5_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H6_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H6_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H7_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H7_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H8_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H8_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H9_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_H9_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HA_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HA_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HB_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HB_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HC_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HC_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HD_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HD_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HE_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HE_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HF_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_HF_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_OS_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_OS_CFG1 = 16'h0200,
  parameter   [0:0] GTYE3_CHANNEL_RXDFE_PWR_SAVING = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_UT_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_UT_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_VP_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXDFE_VP_CFG1 = 16'h0022,
  parameter  [15:0] GTYE3_CHANNEL_RXDLY_CFG = 16'h001F,
  parameter  [15:0] GTYE3_CHANNEL_RXDLY_LCFG = 16'h0030,
  parameter         GTYE3_CHANNEL_RXELECIDLE_CFG = "SIGCFG_4",
  parameter integer GTYE3_CHANNEL_RXGBOX_FIFO_INIT_RD_ADDR = 4,
  parameter         GTYE3_CHANNEL_RXGEARBOX_EN = "FALSE",
  parameter   [4:0] GTYE3_CHANNEL_RXISCANRESET_TIME = 5'b00001,
  parameter  [15:0] GTYE3_CHANNEL_RXLPM_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXLPM_GC_CFG = 16'h0200,
  parameter  [15:0] GTYE3_CHANNEL_RXLPM_KH_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXLPM_KH_CFG1 = 16'h0002,
  parameter  [15:0] GTYE3_CHANNEL_RXLPM_OS_CFG0 = 16'h0400,
  parameter  [15:0] GTYE3_CHANNEL_RXLPM_OS_CFG1 = 16'h0000,
  parameter   [8:0] GTYE3_CHANNEL_RXOOB_CFG = 9'b000000110,
  parameter         GTYE3_CHANNEL_RXOOB_CLK_CFG = "PMA",
  parameter   [4:0] GTYE3_CHANNEL_RXOSCALRESET_TIME = 5'b00011,
  parameter integer GTYE3_CHANNEL_RXOUT_DIV = 4,
  parameter   [4:0] GTYE3_CHANNEL_RXPCSRESET_TIME = 5'b00001,
  parameter  [15:0] GTYE3_CHANNEL_RXPHBEACON_CFG = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_RXPHDLY_CFG = 16'h2020,
  parameter  [15:0] GTYE3_CHANNEL_RXPHSAMP_CFG = 16'h2100,
  parameter  [15:0] GTYE3_CHANNEL_RXPHSLIP_CFG = 16'h9933,
  parameter   [4:0] GTYE3_CHANNEL_RXPH_MONITOR_SEL = 5'b00000,
  parameter   [0:0] GTYE3_CHANNEL_RXPI_AUTO_BW_SEL_BYPASS = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_RXPI_CFG = 16'h0100,
  parameter   [0:0] GTYE3_CHANNEL_RXPI_LPM = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_RXPI_RSV0 = 16'h0000,
  parameter   [1:0] GTYE3_CHANNEL_RXPI_SEL_LC = 2'b00,
  parameter   [1:0] GTYE3_CHANNEL_RXPI_STARTCODE = 2'b00,
  parameter   [0:0] GTYE3_CHANNEL_RXPI_VREFSEL = 1'b0,
  parameter         GTYE3_CHANNEL_RXPMACLK_SEL = "DATA",
  parameter   [4:0] GTYE3_CHANNEL_RXPMARESET_TIME = 5'b00001,
  parameter   [0:0] GTYE3_CHANNEL_RXPRBS_ERR_LOOPBACK = 1'b0,
  parameter integer GTYE3_CHANNEL_RXPRBS_LINKACQ_CNT = 15,
  parameter integer GTYE3_CHANNEL_RXSLIDE_AUTO_WAIT = 7,
  parameter         GTYE3_CHANNEL_RXSLIDE_MODE = "OFF",
  parameter   [0:0] GTYE3_CHANNEL_RXSYNC_MULTILANE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNC_OVRD = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNC_SKIP_DA = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX_AFE_CM_EN = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_RX_BIAS_CFG0 = 16'h1534,
  parameter   [5:0] GTYE3_CHANNEL_RX_BUFFER_CFG = 6'b000000,
  parameter   [0:0] GTYE3_CHANNEL_RX_CAPFF_SARC_ENB = 1'b0,
  parameter integer GTYE3_CHANNEL_RX_CLK25_DIV = 8,
  parameter   [0:0] GTYE3_CHANNEL_RX_CLKMUX_EN = 1'b1,
  parameter   [4:0] GTYE3_CHANNEL_RX_CLK_SLIP_OVRD = 5'b00000,
  parameter   [3:0] GTYE3_CHANNEL_RX_CM_BUF_CFG = 4'b1010,
  parameter   [0:0] GTYE3_CHANNEL_RX_CM_BUF_PD = 1'b0,
  parameter integer GTYE3_CHANNEL_RX_CM_SEL = 3,
  parameter integer GTYE3_CHANNEL_RX_CM_TRIM = 10,
  parameter   [0:0] GTYE3_CHANNEL_RX_CTLE1_KHKL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX_CTLE2_KHKL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX_CTLE3_AGC = 1'b0,
  parameter integer GTYE3_CHANNEL_RX_DATA_WIDTH = 20,
  parameter   [5:0] GTYE3_CHANNEL_RX_DDI_SEL = 6'b000000,
  parameter         GTYE3_CHANNEL_RX_DEFER_RESET_BUF_EN = "TRUE",
  parameter         GTYE3_CHANNEL_RX_DEGEN_CTRL = 3'b011,
  parameter integer GTYE3_CHANNEL_RX_DFELPM_CFG0 = 0,
  parameter   [0:0] GTYE3_CHANNEL_RX_DFELPM_CFG1 = 1'b1,
  parameter   [0:0] GTYE3_CHANNEL_RX_DFELPM_KLKH_AGC_STUP_EN = 1'b1,
  parameter   [1:0] GTYE3_CHANNEL_RX_DFE_AGC_CFG0 = 2'b00,
  parameter integer GTYE3_CHANNEL_RX_DFE_AGC_CFG1 = 2,
  parameter integer GTYE3_CHANNEL_RX_DFE_KL_LPM_KH_CFG0 = 1,
  parameter integer GTYE3_CHANNEL_RX_DFE_KL_LPM_KH_CFG1 = 2,
  parameter   [1:0] GTYE3_CHANNEL_RX_DFE_KL_LPM_KL_CFG0 = 2'b01,
  parameter   [2:0] GTYE3_CHANNEL_RX_DFE_KL_LPM_KL_CFG1 = 3'b010,
  parameter   [0:0] GTYE3_CHANNEL_RX_DFE_LPM_HOLD_DURING_EIDLE = 1'b0,
  parameter         GTYE3_CHANNEL_RX_DISPERR_SEQ_MATCH = "TRUE",
  parameter   [0:0] GTYE3_CHANNEL_RX_DIV2_MODE_B = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_RX_DIVRESET_TIME = 5'b00001,
  parameter   [0:0] GTYE3_CHANNEL_RX_EN_CTLE_RCAL_B = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX_EN_HI_LR = 1'b0,
  parameter   [8:0] GTYE3_CHANNEL_RX_EXT_RL_CTRL = 9'b000000000,
  parameter   [6:0] GTYE3_CHANNEL_RX_EYESCAN_VS_CODE = 7'b0000000,
  parameter   [0:0] GTYE3_CHANNEL_RX_EYESCAN_VS_NEG_DIR = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RX_EYESCAN_VS_RANGE = 2'b00,
  parameter   [0:0] GTYE3_CHANNEL_RX_EYESCAN_VS_UT_SIGN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX_FABINT_USRCLK_FLOP = 1'b0,
  parameter integer GTYE3_CHANNEL_RX_INT_DATAWIDTH = 1,
  parameter   [0:0] GTYE3_CHANNEL_RX_PMA_POWER_SAVE = 1'b0,
  parameter    real GTYE3_CHANNEL_RX_PROGDIV_CFG = 0.0,
  parameter  [15:0] GTYE3_CHANNEL_RX_PROGDIV_RATE = 16'h0001,
  parameter   [3:0] GTYE3_CHANNEL_RX_RESLOAD_CTRL = 4'b0000,
  parameter   [0:0] GTYE3_CHANNEL_RX_RESLOAD_OVRD = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_RX_SAMPLE_PERIOD = 3'b101,
  parameter integer GTYE3_CHANNEL_RX_SIG_VALID_DLY = 11,
  parameter   [0:0] GTYE3_CHANNEL_RX_SUM_DFETAPREP_EN = 1'b0,
  parameter   [3:0] GTYE3_CHANNEL_RX_SUM_IREF_TUNE = 4'b0000,
  parameter   [3:0] GTYE3_CHANNEL_RX_SUM_VCMTUNE = 4'b1000,
  parameter   [0:0] GTYE3_CHANNEL_RX_SUM_VCM_OVWR = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_RX_SUM_VREF_TUNE = 3'b100,
  parameter   [1:0] GTYE3_CHANNEL_RX_TUNE_AFE_OS = 2'b00,
  parameter   [2:0] GTYE3_CHANNEL_RX_VREG_CTRL = 3'b101,
  parameter   [0:0] GTYE3_CHANNEL_RX_VREG_PDB = 1'b1,
  parameter   [1:0] GTYE3_CHANNEL_RX_WIDEMODE_CDR = 2'b01,
  parameter         GTYE3_CHANNEL_RX_XCLK_SEL = "RXDES",
  parameter   [0:0] GTYE3_CHANNEL_RX_XMODE_SEL = 1'b0,
  parameter integer GTYE3_CHANNEL_SAS_MAX_COM = 64,
  parameter integer GTYE3_CHANNEL_SAS_MIN_COM = 36,
  parameter   [3:0] GTYE3_CHANNEL_SATA_BURST_SEQ_LEN = 4'b1111,
  parameter   [2:0] GTYE3_CHANNEL_SATA_BURST_VAL = 3'b100,
  parameter         GTYE3_CHANNEL_SATA_CPLL_CFG = "VCO_3000MHZ",
  parameter   [2:0] GTYE3_CHANNEL_SATA_EIDLE_VAL = 3'b100,
  parameter integer GTYE3_CHANNEL_SATA_MAX_BURST = 8,
  parameter integer GTYE3_CHANNEL_SATA_MAX_INIT = 21,
  parameter integer GTYE3_CHANNEL_SATA_MAX_WAKE = 7,
  parameter integer GTYE3_CHANNEL_SATA_MIN_BURST = 4,
  parameter integer GTYE3_CHANNEL_SATA_MIN_INIT = 12,
  parameter integer GTYE3_CHANNEL_SATA_MIN_WAKE = 4,
  parameter         GTYE3_CHANNEL_SHOW_REALIGN_COMMA = "TRUE",
  parameter         GTYE3_CHANNEL_SIM_MODE = "FAST",
  parameter         GTYE3_CHANNEL_SIM_RECEIVER_DETECT_PASS = "TRUE",
  parameter         GTYE3_CHANNEL_SIM_RESET_SPEEDUP = "TRUE",
  parameter   [0:0] GTYE3_CHANNEL_SIM_TX_EIDLE_DRIVE_LEVEL = 1'b0,
  parameter integer GTYE3_CHANNEL_SIM_VERSION = 2,
  parameter   [1:0] GTYE3_CHANNEL_TAPDLY_SET_TX = 2'h0,
  parameter   [3:0] GTYE3_CHANNEL_TEMPERATURE_PAR = 4'b0010,
  parameter  [14:0] GTYE3_CHANNEL_TERM_RCAL_CFG = 15'b100001000010000,
  parameter   [2:0] GTYE3_CHANNEL_TERM_RCAL_OVRD = 3'b000,
  parameter   [7:0] GTYE3_CHANNEL_TRANS_TIME_RATE = 8'h0E,
  parameter   [7:0] GTYE3_CHANNEL_TST_RSV0 = 8'h00,
  parameter   [7:0] GTYE3_CHANNEL_TST_RSV1 = 8'h00,
  parameter         GTYE3_CHANNEL_TXBUF_EN = "TRUE",
  parameter         GTYE3_CHANNEL_TXBUF_RESET_ON_RATE_CHANGE = "FALSE",
  parameter  [15:0] GTYE3_CHANNEL_TXDLY_CFG = 16'h001F,
  parameter  [15:0] GTYE3_CHANNEL_TXDLY_LCFG = 16'h0030,
  parameter         GTYE3_CHANNEL_TXFIFO_ADDR_CFG = "LOW",
  parameter integer GTYE3_CHANNEL_TXGBOX_FIFO_INIT_RD_ADDR = 4,
  parameter         GTYE3_CHANNEL_TXGEARBOX_EN = "FALSE",
  parameter integer GTYE3_CHANNEL_TXOUT_DIV = 4,
  parameter   [4:0] GTYE3_CHANNEL_TXPCSRESET_TIME = 5'b00001,
  parameter  [15:0] GTYE3_CHANNEL_TXPHDLY_CFG0 = 16'h2020,
  parameter  [15:0] GTYE3_CHANNEL_TXPHDLY_CFG1 = 16'h0001,
  parameter  [15:0] GTYE3_CHANNEL_TXPH_CFG = 16'h0123,
  parameter  [15:0] GTYE3_CHANNEL_TXPH_CFG2 = 16'h0000,
  parameter   [4:0] GTYE3_CHANNEL_TXPH_MONITOR_SEL = 5'b00000,
  parameter   [1:0] GTYE3_CHANNEL_TXPI_CFG0 = 2'b00,
  parameter   [1:0] GTYE3_CHANNEL_TXPI_CFG1 = 2'b00,
  parameter   [1:0] GTYE3_CHANNEL_TXPI_CFG2 = 2'b00,
  parameter   [0:0] GTYE3_CHANNEL_TXPI_CFG3 = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPI_CFG4 = 1'b1,
  parameter   [2:0] GTYE3_CHANNEL_TXPI_CFG5 = 3'b000,
  parameter   [0:0] GTYE3_CHANNEL_TXPI_GRAY_SEL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPI_INVSTROBE_SEL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPI_LPM = 1'b0,
  parameter         GTYE3_CHANNEL_TXPI_PPMCLK_SEL = "TXUSRCLK2",
  parameter   [7:0] GTYE3_CHANNEL_TXPI_PPM_CFG = 8'b00000000,
  parameter  [15:0] GTYE3_CHANNEL_TXPI_RSV0 = 16'h0000,
  parameter   [2:0] GTYE3_CHANNEL_TXPI_SYNFREQ_PPM = 3'b000,
  parameter   [0:0] GTYE3_CHANNEL_TXPI_VREFSEL = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_TXPMARESET_TIME = 5'b00001,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNC_MULTILANE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNC_OVRD = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNC_SKIP_DA = 1'b0,
  parameter integer GTYE3_CHANNEL_TX_CLK25_DIV = 8,
  parameter   [0:0] GTYE3_CHANNEL_TX_CLKMUX_EN = 1'b1,
  parameter   [0:0] GTYE3_CHANNEL_TX_CLKREG_PDB = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_TX_CLKREG_SET = 3'b000,
  parameter integer GTYE3_CHANNEL_TX_DATA_WIDTH = 20,
  parameter   [5:0] GTYE3_CHANNEL_TX_DCD_CFG = 6'b000010,
  parameter   [0:0] GTYE3_CHANNEL_TX_DCD_EN = 1'b0,
  parameter   [5:0] GTYE3_CHANNEL_TX_DEEMPH0 = 6'b000000,
  parameter   [5:0] GTYE3_CHANNEL_TX_DEEMPH1 = 6'b000000,
  parameter   [4:0] GTYE3_CHANNEL_TX_DIVRESET_TIME = 5'b00001,
  parameter         GTYE3_CHANNEL_TX_DRIVE_MODE = "DIRECT",
  parameter integer GTYE3_CHANNEL_TX_DRVMUX_CTRL = 2,
  parameter   [2:0] GTYE3_CHANNEL_TX_EIDLE_ASSERT_DELAY = 3'b110,
  parameter   [2:0] GTYE3_CHANNEL_TX_EIDLE_DEASSERT_DELAY = 3'b100,
  parameter   [0:0] GTYE3_CHANNEL_TX_EML_PHI_TUNE = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_FABINT_USRCLK_FLOP = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_FIFO_BYP_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_IDLE_DATA_ZERO = 1'b0,
  parameter integer GTYE3_CHANNEL_TX_INT_DATAWIDTH = 1,
  parameter         GTYE3_CHANNEL_TX_LOOPBACK_DRIVE_HIZ = "FALSE",
  parameter   [0:0] GTYE3_CHANNEL_TX_MAINCURSOR_SEL = 1'b0,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_FULL_0 = 7'b1001110,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_FULL_1 = 7'b1001001,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_FULL_2 = 7'b1000101,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_FULL_3 = 7'b1000010,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_FULL_4 = 7'b1000000,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_LOW_0 = 7'b1000110,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_LOW_1 = 7'b1000100,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_LOW_2 = 7'b1000010,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_LOW_3 = 7'b1000000,
  parameter   [6:0] GTYE3_CHANNEL_TX_MARGIN_LOW_4 = 7'b1000000,
  parameter   [2:0] GTYE3_CHANNEL_TX_MODE_SEL = 3'b000,
  parameter  [15:0] GTYE3_CHANNEL_TX_PHICAL_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_TX_PHICAL_CFG1 = 16'h7E00,
  parameter  [15:0] GTYE3_CHANNEL_TX_PHICAL_CFG2 = 16'h0000,
  parameter integer GTYE3_CHANNEL_TX_PI_BIASSET = 0,
  parameter  [15:0] GTYE3_CHANNEL_TX_PI_CFG0 = 16'h0000,
  parameter  [15:0] GTYE3_CHANNEL_TX_PI_CFG1 = 16'h0000,
  parameter   [0:0] GTYE3_CHANNEL_TX_PI_DIV2_MODE_B = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_PI_SEL_QPLL0 = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_PI_SEL_QPLL1 = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_PMADATA_OPT = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX_PMA_POWER_SAVE = 1'b0,
  parameter integer GTYE3_CHANNEL_TX_PREDRV_CTRL = 2,
  parameter         GTYE3_CHANNEL_TX_PROGCLK_SEL = "POSTPI",
  parameter    real GTYE3_CHANNEL_TX_PROGDIV_CFG = 0.0,
  parameter  [15:0] GTYE3_CHANNEL_TX_PROGDIV_RATE = 16'h0001,
  parameter  [13:0] GTYE3_CHANNEL_TX_RXDETECT_CFG = 14'h0032,
  parameter integer GTYE3_CHANNEL_TX_RXDETECT_REF = 3,
  parameter   [2:0] GTYE3_CHANNEL_TX_SAMPLE_PERIOD = 3'b101,
  parameter   [0:0] GTYE3_CHANNEL_TX_SARC_LPBK_ENB = 1'b0,
  parameter         GTYE3_CHANNEL_TX_XCLK_SEL = "TXOUT",
  parameter   [0:0] GTYE3_CHANNEL_USE_PCS_CLK_PHASE_SEL = 1'b0,

  // primitive wrapper parameters which specify GTYE3_CHANNEL primitive input port default driver values
  parameter   [0:0] GTYE3_CHANNEL_CDRSTEPDIR_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CDRSTEPSQ_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CDRSTEPSX_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CFGRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CLKRSVD0_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CLKRSVD1_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLLOCKDETCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLLOCKEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLPD_VAL = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_CPLLREFCLKSEL_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DMONFIFORESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DMONITORCLK_VAL = 1'b0,
  parameter   [9:0] GTYE3_CHANNEL_DRPADDR_VAL = 10'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPCLK_VAL = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_DRPDI_VAL = 16'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPWE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ELPCALDVORWREN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ELPCALPAORWREN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHICALDONE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHICALSTART_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIDRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIDWREN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIXRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIXWREN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EYESCANMODE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EYESCANRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EYESCANTRIGGER_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTGREFCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTNORTHREFCLK0_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTNORTHREFCLK1_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTREFCLK0_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTREFCLK1_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTRESETSEL_VAL = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_GTRSVD_VAL = 16'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTRXRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTSOUTHREFCLK0_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTSOUTHREFCLK1_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTTXRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTYRXN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTYRXP_VAL = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_LOOPBACK_VAL = 3'b0,
  parameter  [15:0] GTYE3_CHANNEL_LOOPRSVD_VAL = 16'b0,
  parameter   [0:0] GTYE3_CHANNEL_LPBKRXTXSEREN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_LPBKTXRXSEREN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIERSTIDLE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIERSTTXSYNCSTART_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIEUSERRATEDONE_VAL = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_PCSRSVDIN_VAL = 16'b0,
  parameter   [4:0] GTYE3_CHANNEL_PCSRSVDIN2_VAL = 5'b0,
  parameter   [4:0] GTYE3_CHANNEL_PMARSVDIN_VAL = 5'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL0CLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL0REFCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL1CLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL1REFCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RESETOVRD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RSTCLKENTX_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX8B10BEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXBUFRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRFREQRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDROVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRRESETRSV_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDEN_VAL = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_RXCHBONDI_VAL = 5'b0,
  parameter   [2:0] GTYE3_CHANNEL_RXCHBONDLEVEL_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDMASTER_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDSLAVE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCKCALRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCOMMADETEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDCCFORCESTART_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEAGCHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEAGCOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFELFHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFELFOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFELPMRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP10HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP10OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP11HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP11OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP12HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP12OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP13HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP13OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP14HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP14OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP15HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP15OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP2HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP2OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP3HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP3OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP4HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP4OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP5HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP5OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP6HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP6OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP7HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP7OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP8HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP8OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP9HOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP9OVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEUTHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEUTOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEVPHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEVPOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEVSEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEXYDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYBYPASS_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYSRESET_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RXELECIDLEMODE_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXGEARBOXSLIP_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLATCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMGCHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMGCOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMHFHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMHFOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMLFHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMLFKLOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMOSHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMOSOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXMCOMMAALIGNEN_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RXMONITORSEL_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOOBRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSCALRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSHOLD_VAL = 1'b0,
  parameter   [3:0] GTYE3_CHANNEL_RXOSINTCFG_VAL = 4'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTSTROBE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTTESTOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSOVRDEN_VAL = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_RXOUTCLKSEL_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPCOMMAALIGNEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPCSRESET_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RXPD_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHALIGN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHALIGNEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHDLYPD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHDLYRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHOVRDEN_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RXPLLCLKSEL_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPMARESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPOLARITY_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPRBSCNTRESET_VAL = 1'b0,
  parameter   [3:0] GTYE3_CHANNEL_RXPRBSSEL_VAL = 4'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPROGDIVRESET_VAL = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_RXRATE_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXRATEMODE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSLIDE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSLIPOUTCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSLIPPMA_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNCALLIN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNCIN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNCMODE_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_RXSYSCLKSEL_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXUSERRDY_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXUSRCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXUSRCLK2_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_SIGVALIDCLK_VAL = 1'b0,
  parameter  [19:0] GTYE3_CHANNEL_TSTIN_VAL = 20'b0,
  parameter   [7:0] GTYE3_CHANNEL_TX8B10BBYPASS_VAL = 8'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX8B10BEN_VAL = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_TXBUFDIFFCTRL_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCOMINIT_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCOMSAS_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCOMWAKE_VAL = 1'b0,
  parameter  [15:0] GTYE3_CHANNEL_TXCTRL0_VAL = 16'b0,
  parameter  [15:0] GTYE3_CHANNEL_TXCTRL1_VAL = 16'b0,
  parameter   [7:0] GTYE3_CHANNEL_TXCTRL2_VAL = 8'b0,
  parameter [127:0] GTYE3_CHANNEL_TXDATA_VAL = 128'b0,
  parameter   [7:0] GTYE3_CHANNEL_TXDATAEXTENDRSVD_VAL = 8'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDCCFORCESTART_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDCCRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDEEMPH_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDETECTRX_VAL = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_TXDIFFCTRL_VAL = 5'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDIFFPD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYBYPASS_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYHOLD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYSRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYUPDOWN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXELECIDLE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXELFORCESTART_VAL = 1'b0,
  parameter   [5:0] GTYE3_CHANNEL_TXHEADER_VAL = 6'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXINHIBIT_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXLATCLK_VAL = 1'b0,
  parameter   [6:0] GTYE3_CHANNEL_TXMAINCURSOR_VAL = 7'b0,
  parameter   [2:0] GTYE3_CHANNEL_TXMARGIN_VAL = 3'b0,
  parameter   [2:0] GTYE3_CHANNEL_TXOUTCLKSEL_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPCSRESET_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_TXPD_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPDELECIDLEMODE_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHALIGN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHALIGNEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHDLYPD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHDLYRESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHDLYTSTCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHINIT_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMOVRDEN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMPD_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMSEL_VAL = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_TXPIPPMSTEPSIZE_VAL = 5'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPISOPD_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_TXPLLCLKSEL_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPMARESET_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPOLARITY_VAL = 1'b0,
  parameter   [4:0] GTYE3_CHANNEL_TXPOSTCURSOR_VAL = 5'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPRBSFORCEERR_VAL = 1'b0,
  parameter   [3:0] GTYE3_CHANNEL_TXPRBSSEL_VAL = 4'b0,
  parameter   [4:0] GTYE3_CHANNEL_TXPRECURSOR_VAL = 5'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPROGDIVRESET_VAL = 1'b0,
  parameter   [2:0] GTYE3_CHANNEL_TXRATE_VAL = 3'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXRATEMODE_VAL = 1'b0,
  parameter   [6:0] GTYE3_CHANNEL_TXSEQUENCE_VAL = 7'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSWING_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNCALLIN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNCIN_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNCMODE_VAL = 1'b0,
  parameter   [1:0] GTYE3_CHANNEL_TXSYSCLKSEL_VAL = 2'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXUSERRDY_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXUSRCLK_VAL = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXUSRCLK2_VAL = 1'b0,

  // primitive wrapper parameters which control GTYE3_CHANNEL primitive input port tie-off enablement
  parameter   [0:0] GTYE3_CHANNEL_CDRSTEPDIR_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CDRSTEPSQ_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CDRSTEPSX_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CFGRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CLKRSVD0_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CLKRSVD1_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLLOCKDETCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLLOCKEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLREFCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_CPLLRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DMONFIFORESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DMONITORCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPADDR_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPDI_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_DRPWE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ELPCALDVORWREN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_ELPCALPAORWREN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHICALDONE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHICALSTART_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIDRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIDWREN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIXRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EVODDPHIXWREN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EYESCANMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EYESCANRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_EYESCANTRIGGER_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTGREFCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTNORTHREFCLK0_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTNORTHREFCLK1_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTREFCLK0_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTREFCLK1_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTRESETSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTRSVD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTRXRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTSOUTHREFCLK0_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTSOUTHREFCLK1_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTTXRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTYRXN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_GTYRXP_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_LOOPBACK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_LOOPRSVD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_LPBKRXTXSEREN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_LPBKTXRXSEREN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIERSTIDLE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIERSTTXSYNCSTART_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCIEUSERRATEDONE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCSRSVDIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PCSRSVDIN2_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_PMARSVDIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL0CLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL0REFCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL1CLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_QPLL1REFCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RESETOVRD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RSTCLKENTX_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RX8B10BEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXBUFRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRFREQRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDROVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCDRRESETRSV_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDI_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDLEVEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDMASTER_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCHBONDSLAVE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCKCALRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXCOMMADETEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDCCFORCESTART_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEAGCHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEAGCOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFELFHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFELFOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFELPMRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP10HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP10OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP11HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP11OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP12HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP12OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP13HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP13OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP14HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP14OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP15HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP15OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP2HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP2OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP3HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP3OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP4HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP4OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP5HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP5OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP6HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP6OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP7HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP7OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP8HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP8OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP9HOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFETAP9OVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEUTHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEUTOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEVPHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEVPOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEVSEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDFEXYDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYBYPASS_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXDLYSRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXELECIDLEMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXGEARBOXSLIP_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLATCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMGCHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMGCOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMHFHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMHFOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMLFHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMLFKLOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMOSHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXLPMOSOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXMCOMMAALIGNEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXMONITORSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOOBRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSCALRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTCFG_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTSTROBE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSINTTESTOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOSOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXOUTCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPCOMMAALIGNEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPCSRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHALIGN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHALIGNEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHDLYPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHDLYRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPHOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPLLCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPMARESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPOLARITY_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPRBSCNTRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPRBSSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXPROGDIVRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXRATE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXRATEMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSLIDE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSLIPOUTCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSLIPPMA_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNCALLIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNCIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYNCMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXSYSCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXUSERRDY_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXUSRCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_RXUSRCLK2_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_SIGVALIDCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TSTIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX8B10BBYPASS_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TX8B10BEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXBUFDIFFCTRL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCOMINIT_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCOMSAS_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCOMWAKE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCTRL0_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCTRL1_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXCTRL2_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDATA_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDATAEXTENDRSVD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDCCFORCESTART_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDCCRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDEEMPH_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDETECTRX_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDIFFCTRL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDIFFPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYBYPASS_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYHOLD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYSRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXDLYUPDOWN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXELECIDLE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXELFORCESTART_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXHEADER_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXINHIBIT_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXLATCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXMAINCURSOR_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXMARGIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXOUTCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPCSRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPDELECIDLEMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHALIGN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHALIGNEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHDLYPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHDLYRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHDLYTSTCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHINIT_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPHOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMOVRDEN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPIPPMSTEPSIZE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPISOPD_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPLLCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPMARESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPOLARITY_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPOSTCURSOR_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPRBSFORCEERR_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPRBSSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPRECURSOR_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXPROGDIVRESET_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXRATE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXRATEMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSEQUENCE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSWING_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNCALLIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNCIN_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYNCMODE_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXSYSCLKSEL_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXUSERRDY_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXUSRCLK_TIE_EN = 1'b0,
  parameter   [0:0] GTYE3_CHANNEL_TXUSRCLK2_TIE_EN = 1'b0

)(


  // -------------------------------------------------------------------------------------------------------------------
  // Ports relating to GTYE3_CHANNEL primitive
  // -------------------------------------------------------------------------------------------------------------------

  // primitive wrapper input ports which can drive corresponding GTYE3_CHANNEL primitive input ports
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CDRSTEPDIR,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CDRSTEPSQ,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CDRSTEPSX,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CFGRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CLKRSVD0,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CLKRSVD1,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLLOCKDETCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLLOCKEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLPD,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_CPLLREFCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DMONFIFORESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DMONITORCLK,
  input  wire [(NUM_CHANNELS* 10)-1:0] GTYE3_CHANNEL_DRPADDR,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPCLK,
  input  wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_DRPDI,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPWE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_ELPCALDVORWREN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_ELPCALPAORWREN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHICALDONE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHICALSTART,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIDRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIDWREN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIXRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIXWREN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANMODE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANTRIGGER,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTGREFCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTNORTHREFCLK0,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTNORTHREFCLK1,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTREFCLK0,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTREFCLK1,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTRESETSEL,
  input  wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_GTRSVD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTRXRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTSOUTHREFCLK0,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTSOUTHREFCLK1,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTTXRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTYRXN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTYRXP,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_LOOPBACK,
  input  wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_LOOPRSVD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_LPBKRXTXSEREN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_LPBKTXRXSEREN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIERSTIDLE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIERSTTXSYNCSTART,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEUSERRATEDONE,
  input  wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_PCSRSVDIN,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_PCSRSVDIN2,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_PMARSVDIN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL0CLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL0REFCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL1CLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL1REFCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RESETOVRD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RSTCLKENTX,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RX8B10BEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXBUFRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRFREQRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDROVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRRESETRSV,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHBONDEN,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_RXCHBONDI,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXCHBONDLEVEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHBONDMASTER,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHBONDSLAVE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCKCALRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCOMMADETEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDCCFORCESTART,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEAGCHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEAGCOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFELFHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFELFOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFELPMRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP10HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP10OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP11HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP11OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP12HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP12OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP13HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP13OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP14HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP14OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP15HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP15OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP2HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP2OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP3HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP3OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP4HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP4OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP5HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP5OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP6HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP6OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP7HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP7OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP8HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP8OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP9HOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP9OVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEUTHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEUTOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEVPHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEVPOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEVSEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEXYDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYBYPASS,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYSRESET,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXELECIDLEMODE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXGEARBOXSLIP,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLATCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMGCHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMGCOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMHFHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMHFOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMLFHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMLFKLOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMOSHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMOSOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXMCOMMAALIGNEN,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXMONITORSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOOBRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSCALRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSHOLD,
  input  wire [(NUM_CHANNELS*  4)-1:0] GTYE3_CHANNEL_RXOSINTCFG,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTSTROBE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTTESTOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSOVRDEN,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXOUTCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPCOMMAALIGNEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPCSRESET,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXPD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHALIGN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHALIGNEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHDLYPD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHDLYRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHOVRDEN,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXPLLCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPMARESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPOLARITY,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPRBSCNTRESET,
  input  wire [(NUM_CHANNELS*  4)-1:0] GTYE3_CHANNEL_RXPRBSSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPROGDIVRESET,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXRATE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXRATEMODE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIDE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPOUTCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPPMA,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCALLIN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCIN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCMODE,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXSYSCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXUSERRDY,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXUSRCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXUSRCLK2,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_SIGVALIDCLK,
  input  wire [(NUM_CHANNELS* 20)-1:0] GTYE3_CHANNEL_TSTIN,
  input  wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_TX8B10BBYPASS,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TX8B10BEN,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXBUFDIFFCTRL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMINIT,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMSAS,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMWAKE,
  input  wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_TXCTRL0,
  input  wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_TXCTRL1,
  input  wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_TXCTRL2,
  input  wire [(NUM_CHANNELS*128)-1:0] GTYE3_CHANNEL_TXDATA,
  input  wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_TXDATAEXTENDRSVD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDCCFORCESTART,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDCCRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDEEMPH,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDETECTRX,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXDIFFCTRL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDIFFPD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYBYPASS,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYHOLD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYSRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYUPDOWN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXELECIDLE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXELFORCESTART,
  input  wire [(NUM_CHANNELS*  6)-1:0] GTYE3_CHANNEL_TXHEADER,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXINHIBIT,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXLATCLK,
  input  wire [(NUM_CHANNELS*  7)-1:0] GTYE3_CHANNEL_TXMAINCURSOR,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXMARGIN,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXOUTCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPCSRESET,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXPD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPDELECIDLEMODE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHALIGN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHALIGNEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHDLYPD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHDLYRESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHDLYTSTCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHINIT,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMOVRDEN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMPD,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMSEL,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXPIPPMSTEPSIZE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPISOPD,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXPLLCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPMARESET,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPOLARITY,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXPOSTCURSOR,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPRBSFORCEERR,
  input  wire [(NUM_CHANNELS*  4)-1:0] GTYE3_CHANNEL_TXPRBSSEL,
  input  wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXPRECURSOR,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPROGDIVRESET,
  input  wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXRATE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXRATEMODE,
  input  wire [(NUM_CHANNELS*  7)-1:0] GTYE3_CHANNEL_TXSEQUENCE,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSWING,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCALLIN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCIN,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCMODE,
  input  wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXSYSCLKSEL,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXUSERRDY,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXUSRCLK,
  input  wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXUSRCLK2,

  // primitive wrapper output ports which are driven by corresponding GTYE3_CHANNEL primitive output ports
  output wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_BUFGTCE,
  output wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_BUFGTCEMASK,
  output wire [(NUM_CHANNELS*  9)-1:0] GTYE3_CHANNEL_BUFGTDIV,
  output wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_BUFGTRESET,
  output wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_BUFGTRSTMASK,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLFBCLKLOST,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLLOCK,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLREFCLKLOST,
  output wire [(NUM_CHANNELS* 17)-1:0] GTYE3_CHANNEL_DMONITOROUT,
  output wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_DRPDO,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPRDY,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANDATAERROR,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTPOWERGOOD,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTREFCLKMONITOR,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTYTXN,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTYTXP,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIERATEGEN3,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIERATEIDLE,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_PCIERATEQPLLPD,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_PCIERATEQPLLRESET,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIESYNCTXSYNCDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEUSERGEN3RDY,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEUSERPHYSTATUSRST,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEUSERRATESTART,
  output wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_PCSRSVDOUT,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PHYSTATUS,
  output wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_PINRSRVDAS,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RESETEXCEPTION,
  output wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXBUFSTATUS,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXBYTEISALIGNED,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXBYTEREALIGN,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRLOCK,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRPHDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHANBONDSEQ,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHANISALIGNED,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHANREALIGN,
  output wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_RXCHBONDO,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCKCALDONE,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXCLKCORCNT,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCOMINITDET,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCOMMADET,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCOMSASDET,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCOMWAKEDET,
  output wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_RXCTRL0,
  output wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_RXCTRL1,
  output wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_RXCTRL2,
  output wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_RXCTRL3,
  output wire [(NUM_CHANNELS*128)-1:0] GTYE3_CHANNEL_RXDATA,
  output wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_RXDATAEXTENDRSVD,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXDATAVALID,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYSRESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXELECIDLE,
  output wire [(NUM_CHANNELS*  6)-1:0] GTYE3_CHANNEL_RXHEADER,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXHEADERVALID,
  output wire [(NUM_CHANNELS*  7)-1:0] GTYE3_CHANNEL_RXMONITOROUT,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTSTARTED,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTSTROBEDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTSTROBESTARTED,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOUTCLK,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOUTCLKFABRIC,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOUTCLKPCS,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHALIGNDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHALIGNERR,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPMARESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPRBSERR,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPRBSLOCKED,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPRGDIVRESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXRATEDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXRECCLKOUT,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXRESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIDERDY,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPOUTCLKRDY,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPPMARDY,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXSTARTOFSEQ,
  output wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXSTATUS,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCOUT,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXVALID,
  output wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXBUFSTATUS,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMFINISH,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDCCDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYSRESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXOUTCLK,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXOUTCLKFABRIC,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXOUTCLKPCS,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHALIGNDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHINITDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPMARESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPRGDIVRESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXRATEDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXRESETDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCDONE,
  output wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCOUT

);


  // -------------------------------------------------------------------------------------------------------------------
  // HDL generation of wiring and instances relating to GTYE3_CHANNEL primitive
  // -------------------------------------------------------------------------------------------------------------------

  generate if (NUM_CHANNELS > 0) begin : gtye3_channel_gen

    // for each GTYE3_CHANNEL primitive input port, declare a vector scaled to drive all generated instances
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CDRSTEPDIR_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CDRSTEPSQ_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CDRSTEPSX_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CFGRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CLKRSVD0_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CLKRSVD1_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLLOCKDETCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLLOCKEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLPD_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_CPLLREFCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_CPLLRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DMONFIFORESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DMONITORCLK_int;
    wire [(NUM_CHANNELS* 10)-1:0] GTYE3_CHANNEL_DRPADDR_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPCLK_int;
    wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_DRPDI_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_DRPWE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_ELPCALDVORWREN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_ELPCALPAORWREN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHICALDONE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHICALSTART_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIDRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIDWREN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIXRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EVODDPHIXWREN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANMODE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_EYESCANTRIGGER_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTGREFCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTNORTHREFCLK0_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTNORTHREFCLK1_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTREFCLK0_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTREFCLK1_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTRESETSEL_int;
    wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_GTRSVD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTRXRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTSOUTHREFCLK0_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTSOUTHREFCLK1_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTTXRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTYRXN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_GTYRXP_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_LOOPBACK_int;
    wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_LOOPRSVD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_LPBKRXTXSEREN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_LPBKTXRXSEREN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIERSTIDLE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIERSTTXSYNCSTART_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_PCIEUSERRATEDONE_int;
    wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_PCSRSVDIN_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_PCSRSVDIN2_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_PMARSVDIN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL0CLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL0REFCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL1CLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_QPLL1REFCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RESETOVRD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RSTCLKENTX_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RX8B10BEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXBUFRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRFREQRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDROVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCDRRESETRSV_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHBONDEN_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_RXCHBONDI_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXCHBONDLEVEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHBONDMASTER_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCHBONDSLAVE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCKCALRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXCOMMADETEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDCCFORCESTART_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEAGCHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEAGCOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFELFHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFELFOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFELPMRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP10HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP10OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP11HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP11OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP12HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP12OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP13HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP13OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP14HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP14OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP15HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP15OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP2HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP2OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP3HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP3OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP4HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP4OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP5HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP5OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP6HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP6OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP7HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP7OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP8HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP8OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP9HOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFETAP9OVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEUTHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEUTOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEVPHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEVPOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEVSEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDFEXYDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYBYPASS_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXDLYSRESET_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXELECIDLEMODE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXGEARBOXSLIP_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLATCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMGCHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMGCOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMHFHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMHFOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMLFHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMLFKLOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMOSHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXLPMOSOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXMCOMMAALIGNEN_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXMONITORSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOOBRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSCALRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSHOLD_int;
    wire [(NUM_CHANNELS*  4)-1:0] GTYE3_CHANNEL_RXOSINTCFG_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTSTROBE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSINTTESTOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXOSOVRDEN_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXOUTCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPCOMMAALIGNEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPCSRESET_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXPD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHALIGN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHALIGNEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHDLYPD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHDLYRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPHOVRDEN_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXPLLCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPMARESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPOLARITY_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPRBSCNTRESET_int;
    wire [(NUM_CHANNELS*  4)-1:0] GTYE3_CHANNEL_RXPRBSSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXPROGDIVRESET_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_RXRATE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXRATEMODE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIDE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPOUTCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSLIPPMA_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCALLIN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCIN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXSYNCMODE_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_RXSYSCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXUSERRDY_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXUSRCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_RXUSRCLK2_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_SIGVALIDCLK_int;
    wire [(NUM_CHANNELS* 20)-1:0] GTYE3_CHANNEL_TSTIN_int;
    wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_TX8B10BBYPASS_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TX8B10BEN_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXBUFDIFFCTRL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMINIT_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMSAS_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXCOMWAKE_int;
    wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_TXCTRL0_int;
    wire [(NUM_CHANNELS* 16)-1:0] GTYE3_CHANNEL_TXCTRL1_int;
    wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_TXCTRL2_int;
    wire [(NUM_CHANNELS*128)-1:0] GTYE3_CHANNEL_TXDATA_int;
    wire [(NUM_CHANNELS*  8)-1:0] GTYE3_CHANNEL_TXDATAEXTENDRSVD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDCCFORCESTART_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDCCRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDEEMPH_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDETECTRX_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXDIFFCTRL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDIFFPD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYBYPASS_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYHOLD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYSRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXDLYUPDOWN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXELECIDLE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXELFORCESTART_int;
    wire [(NUM_CHANNELS*  6)-1:0] GTYE3_CHANNEL_TXHEADER_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXINHIBIT_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXLATCLK_int;
    wire [(NUM_CHANNELS*  7)-1:0] GTYE3_CHANNEL_TXMAINCURSOR_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXMARGIN_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXOUTCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPCSRESET_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXPD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPDELECIDLEMODE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHALIGN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHALIGNEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHDLYPD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHDLYRESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHDLYTSTCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHINIT_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPHOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMOVRDEN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMPD_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPIPPMSEL_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXPIPPMSTEPSIZE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPISOPD_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXPLLCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPMARESET_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPOLARITY_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXPOSTCURSOR_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPRBSFORCEERR_int;
    wire [(NUM_CHANNELS*  4)-1:0] GTYE3_CHANNEL_TXPRBSSEL_int;
    wire [(NUM_CHANNELS*  5)-1:0] GTYE3_CHANNEL_TXPRECURSOR_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXPROGDIVRESET_int;
    wire [(NUM_CHANNELS*  3)-1:0] GTYE3_CHANNEL_TXRATE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXRATEMODE_int;
    wire [(NUM_CHANNELS*  7)-1:0] GTYE3_CHANNEL_TXSEQUENCE_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSWING_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCALLIN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCIN_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXSYNCMODE_int;
    wire [(NUM_CHANNELS*  2)-1:0] GTYE3_CHANNEL_TXSYSCLKSEL_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXUSERRDY_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXUSRCLK_int;
    wire [(NUM_CHANNELS*  1)-1:0] GTYE3_CHANNEL_TXUSRCLK2_int;

    // assign each vector either the corresponding tie-off value or the corresponding input port, scaled appropriately
    if (GTYE3_CHANNEL_CDRSTEPDIR_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CDRSTEPDIR_int = {NUM_CHANNELS{GTYE3_CHANNEL_CDRSTEPDIR_VAL}};
    else
      assign GTYE3_CHANNEL_CDRSTEPDIR_int = {NUM_CHANNELS{GTYE3_CHANNEL_CDRSTEPDIR}};

    if (GTYE3_CHANNEL_CDRSTEPSQ_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CDRSTEPSQ_int = {NUM_CHANNELS{GTYE3_CHANNEL_CDRSTEPSQ_VAL}};
    else
      assign GTYE3_CHANNEL_CDRSTEPSQ_int = {NUM_CHANNELS{GTYE3_CHANNEL_CDRSTEPSQ}};

    if (GTYE3_CHANNEL_CDRSTEPSX_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CDRSTEPSX_int = {NUM_CHANNELS{GTYE3_CHANNEL_CDRSTEPSX_VAL}};
    else
      assign GTYE3_CHANNEL_CDRSTEPSX_int = {NUM_CHANNELS{GTYE3_CHANNEL_CDRSTEPSX}};

    if (GTYE3_CHANNEL_CFGRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CFGRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_CFGRESET_VAL}};
    else
      assign GTYE3_CHANNEL_CFGRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_CFGRESET}};

    if (GTYE3_CHANNEL_CLKRSVD0_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CLKRSVD0_int = {NUM_CHANNELS{GTYE3_CHANNEL_CLKRSVD0_VAL}};
    else
      assign GTYE3_CHANNEL_CLKRSVD0_int = {NUM_CHANNELS{GTYE3_CHANNEL_CLKRSVD0}};

    if (GTYE3_CHANNEL_CLKRSVD1_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CLKRSVD1_int = {NUM_CHANNELS{GTYE3_CHANNEL_CLKRSVD1_VAL}};
    else
      assign GTYE3_CHANNEL_CLKRSVD1_int = {NUM_CHANNELS{GTYE3_CHANNEL_CLKRSVD1}};

    if (GTYE3_CHANNEL_CPLLLOCKDETCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CPLLLOCKDETCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLLOCKDETCLK_VAL}};
    else
      assign GTYE3_CHANNEL_CPLLLOCKDETCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLLOCKDETCLK}};

    if (GTYE3_CHANNEL_CPLLLOCKEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CPLLLOCKEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLLOCKEN_VAL}};
    else
      assign GTYE3_CHANNEL_CPLLLOCKEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLLOCKEN}};

    if (GTYE3_CHANNEL_CPLLPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CPLLPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLPD_VAL}};
    else
      assign GTYE3_CHANNEL_CPLLPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLPD}};

    if (GTYE3_CHANNEL_CPLLREFCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CPLLREFCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLREFCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_CPLLREFCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLREFCLKSEL}};

    if (GTYE3_CHANNEL_CPLLRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_CPLLRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLRESET_VAL}};
    else
      assign GTYE3_CHANNEL_CPLLRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_CPLLRESET}};

    if (GTYE3_CHANNEL_DMONFIFORESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DMONFIFORESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_DMONFIFORESET_VAL}};
    else
      assign GTYE3_CHANNEL_DMONFIFORESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_DMONFIFORESET}};

    if (GTYE3_CHANNEL_DMONITORCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DMONITORCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_DMONITORCLK_VAL}};
    else
      assign GTYE3_CHANNEL_DMONITORCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_DMONITORCLK}};

    if (GTYE3_CHANNEL_DRPADDR_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DRPADDR_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPADDR_VAL}};
    else
      assign GTYE3_CHANNEL_DRPADDR_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPADDR}};

    if (GTYE3_CHANNEL_DRPCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DRPCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPCLK_VAL}};
    else
      assign GTYE3_CHANNEL_DRPCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPCLK}};

    if (GTYE3_CHANNEL_DRPDI_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DRPDI_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPDI_VAL}};
    else
      assign GTYE3_CHANNEL_DRPDI_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPDI}};

    if (GTYE3_CHANNEL_DRPEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DRPEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPEN_VAL}};
    else
      assign GTYE3_CHANNEL_DRPEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPEN}};

    if (GTYE3_CHANNEL_DRPWE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_DRPWE_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPWE_VAL}};
    else
      assign GTYE3_CHANNEL_DRPWE_int = {NUM_CHANNELS{GTYE3_CHANNEL_DRPWE}};

    if (GTYE3_CHANNEL_ELPCALDVORWREN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_ELPCALDVORWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_ELPCALDVORWREN_VAL}};
    else
      assign GTYE3_CHANNEL_ELPCALDVORWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_ELPCALDVORWREN}};

    if (GTYE3_CHANNEL_ELPCALPAORWREN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_ELPCALPAORWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_ELPCALPAORWREN_VAL}};
    else
      assign GTYE3_CHANNEL_ELPCALPAORWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_ELPCALPAORWREN}};

    if (GTYE3_CHANNEL_EVODDPHICALDONE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EVODDPHICALDONE_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHICALDONE_VAL}};
    else
      assign GTYE3_CHANNEL_EVODDPHICALDONE_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHICALDONE}};

    if (GTYE3_CHANNEL_EVODDPHICALSTART_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EVODDPHICALSTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHICALSTART_VAL}};
    else
      assign GTYE3_CHANNEL_EVODDPHICALSTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHICALSTART}};

    if (GTYE3_CHANNEL_EVODDPHIDRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EVODDPHIDRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIDRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_EVODDPHIDRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIDRDEN}};

    if (GTYE3_CHANNEL_EVODDPHIDWREN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EVODDPHIDWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIDWREN_VAL}};
    else
      assign GTYE3_CHANNEL_EVODDPHIDWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIDWREN}};

    if (GTYE3_CHANNEL_EVODDPHIXRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EVODDPHIXRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIXRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_EVODDPHIXRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIXRDEN}};

    if (GTYE3_CHANNEL_EVODDPHIXWREN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EVODDPHIXWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIXWREN_VAL}};
    else
      assign GTYE3_CHANNEL_EVODDPHIXWREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_EVODDPHIXWREN}};

    if (GTYE3_CHANNEL_EYESCANMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EYESCANMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_EYESCANMODE_VAL}};
    else
      assign GTYE3_CHANNEL_EYESCANMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_EYESCANMODE}};

    if (GTYE3_CHANNEL_EYESCANRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EYESCANRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_EYESCANRESET_VAL}};
    else
      assign GTYE3_CHANNEL_EYESCANRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_EYESCANRESET}};

    if (GTYE3_CHANNEL_EYESCANTRIGGER_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_EYESCANTRIGGER_int = {NUM_CHANNELS{GTYE3_CHANNEL_EYESCANTRIGGER_VAL}};
    else
      assign GTYE3_CHANNEL_EYESCANTRIGGER_int = {NUM_CHANNELS{GTYE3_CHANNEL_EYESCANTRIGGER}};

    if (GTYE3_CHANNEL_GTGREFCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTGREFCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTGREFCLK_VAL}};
    else
      assign GTYE3_CHANNEL_GTGREFCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTGREFCLK}};

    if (GTYE3_CHANNEL_GTNORTHREFCLK0_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTNORTHREFCLK0_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTNORTHREFCLK0_VAL}};
    else
      assign GTYE3_CHANNEL_GTNORTHREFCLK0_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTNORTHREFCLK0}};

    if (GTYE3_CHANNEL_GTNORTHREFCLK1_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTNORTHREFCLK1_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTNORTHREFCLK1_VAL}};
    else
      assign GTYE3_CHANNEL_GTNORTHREFCLK1_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTNORTHREFCLK1}};

    if (GTYE3_CHANNEL_GTREFCLK0_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTREFCLK0_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTREFCLK0_VAL}};
    else
      assign GTYE3_CHANNEL_GTREFCLK0_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTREFCLK0}};

    if (GTYE3_CHANNEL_GTREFCLK1_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTREFCLK1_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTREFCLK1_VAL}};
    else
      assign GTYE3_CHANNEL_GTREFCLK1_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTREFCLK1}};

    if (GTYE3_CHANNEL_GTRESETSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTRESETSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTRESETSEL_VAL}};
    else
      assign GTYE3_CHANNEL_GTRESETSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTRESETSEL}};

    if (GTYE3_CHANNEL_GTRSVD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTRSVD_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTRSVD_VAL}};
    else
      assign GTYE3_CHANNEL_GTRSVD_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTRSVD}};

    if (GTYE3_CHANNEL_GTRXRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTRXRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTRXRESET_VAL}};
    else
      assign GTYE3_CHANNEL_GTRXRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTRXRESET}};

    if (GTYE3_CHANNEL_GTSOUTHREFCLK0_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTSOUTHREFCLK0_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTSOUTHREFCLK0_VAL}};
    else
      assign GTYE3_CHANNEL_GTSOUTHREFCLK0_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTSOUTHREFCLK0}};

    if (GTYE3_CHANNEL_GTSOUTHREFCLK1_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTSOUTHREFCLK1_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTSOUTHREFCLK1_VAL}};
    else
      assign GTYE3_CHANNEL_GTSOUTHREFCLK1_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTSOUTHREFCLK1}};

    if (GTYE3_CHANNEL_GTTXRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTTXRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTTXRESET_VAL}};
    else
      assign GTYE3_CHANNEL_GTTXRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTTXRESET}};

    if (GTYE3_CHANNEL_GTYRXN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTYRXN_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTYRXN_VAL}};
    else
      assign GTYE3_CHANNEL_GTYRXN_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTYRXN}};

    if (GTYE3_CHANNEL_GTYRXP_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_GTYRXP_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTYRXP_VAL}};
    else
      assign GTYE3_CHANNEL_GTYRXP_int = {NUM_CHANNELS{GTYE3_CHANNEL_GTYRXP}};

    if (GTYE3_CHANNEL_LOOPBACK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_LOOPBACK_int = {NUM_CHANNELS{GTYE3_CHANNEL_LOOPBACK_VAL}};
    else
      assign GTYE3_CHANNEL_LOOPBACK_int = {NUM_CHANNELS{GTYE3_CHANNEL_LOOPBACK}};

    if (GTYE3_CHANNEL_LOOPRSVD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_LOOPRSVD_int = {NUM_CHANNELS{GTYE3_CHANNEL_LOOPRSVD_VAL}};
    else
      assign GTYE3_CHANNEL_LOOPRSVD_int = {NUM_CHANNELS{GTYE3_CHANNEL_LOOPRSVD}};

    if (GTYE3_CHANNEL_LPBKRXTXSEREN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_LPBKRXTXSEREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_LPBKRXTXSEREN_VAL}};
    else
      assign GTYE3_CHANNEL_LPBKRXTXSEREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_LPBKRXTXSEREN}};

    if (GTYE3_CHANNEL_LPBKTXRXSEREN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_LPBKTXRXSEREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_LPBKTXRXSEREN_VAL}};
    else
      assign GTYE3_CHANNEL_LPBKTXRXSEREN_int = {NUM_CHANNELS{GTYE3_CHANNEL_LPBKTXRXSEREN}};

    if (GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_VAL}};
    else
      assign GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE}};

    if (GTYE3_CHANNEL_PCIERSTIDLE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PCIERSTIDLE_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIERSTIDLE_VAL}};
    else
      assign GTYE3_CHANNEL_PCIERSTIDLE_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIERSTIDLE}};

    if (GTYE3_CHANNEL_PCIERSTTXSYNCSTART_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PCIERSTTXSYNCSTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIERSTTXSYNCSTART_VAL}};
    else
      assign GTYE3_CHANNEL_PCIERSTTXSYNCSTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIERSTTXSYNCSTART}};

    if (GTYE3_CHANNEL_PCIEUSERRATEDONE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PCIEUSERRATEDONE_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIEUSERRATEDONE_VAL}};
    else
      assign GTYE3_CHANNEL_PCIEUSERRATEDONE_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCIEUSERRATEDONE}};

    if (GTYE3_CHANNEL_PCSRSVDIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PCSRSVDIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCSRSVDIN_VAL}};
    else
      assign GTYE3_CHANNEL_PCSRSVDIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCSRSVDIN}};

    if (GTYE3_CHANNEL_PCSRSVDIN2_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PCSRSVDIN2_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCSRSVDIN2_VAL}};
    else
      assign GTYE3_CHANNEL_PCSRSVDIN2_int = {NUM_CHANNELS{GTYE3_CHANNEL_PCSRSVDIN2}};

    if (GTYE3_CHANNEL_PMARSVDIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_PMARSVDIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_PMARSVDIN_VAL}};
    else
      assign GTYE3_CHANNEL_PMARSVDIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_PMARSVDIN}};

    if (GTYE3_CHANNEL_QPLL0CLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_QPLL0CLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL0CLK_VAL}};
    else
      assign GTYE3_CHANNEL_QPLL0CLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL0CLK}};

    if (GTYE3_CHANNEL_QPLL0REFCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_QPLL0REFCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL0REFCLK_VAL}};
    else
      assign GTYE3_CHANNEL_QPLL0REFCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL0REFCLK}};

    if (GTYE3_CHANNEL_QPLL1CLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_QPLL1CLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL1CLK_VAL}};
    else
      assign GTYE3_CHANNEL_QPLL1CLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL1CLK}};

    if (GTYE3_CHANNEL_QPLL1REFCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_QPLL1REFCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL1REFCLK_VAL}};
    else
      assign GTYE3_CHANNEL_QPLL1REFCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_QPLL1REFCLK}};

    if (GTYE3_CHANNEL_RESETOVRD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RESETOVRD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RESETOVRD_VAL}};
    else
      assign GTYE3_CHANNEL_RESETOVRD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RESETOVRD}};

    if (GTYE3_CHANNEL_RSTCLKENTX_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RSTCLKENTX_int = {NUM_CHANNELS{GTYE3_CHANNEL_RSTCLKENTX_VAL}};
    else
      assign GTYE3_CHANNEL_RSTCLKENTX_int = {NUM_CHANNELS{GTYE3_CHANNEL_RSTCLKENTX}};

    if (GTYE3_CHANNEL_RX8B10BEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RX8B10BEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RX8B10BEN_VAL}};
    else
      assign GTYE3_CHANNEL_RX8B10BEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RX8B10BEN}};

    if (GTYE3_CHANNEL_RXBUFRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXBUFRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXBUFRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXBUFRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXBUFRESET}};

    if (GTYE3_CHANNEL_RXCDRFREQRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCDRFREQRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRFREQRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXCDRFREQRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRFREQRESET}};

    if (GTYE3_CHANNEL_RXCDRHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCDRHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXCDRHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRHOLD}};

    if (GTYE3_CHANNEL_RXCDROVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCDROVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDROVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXCDROVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDROVRDEN}};

    if (GTYE3_CHANNEL_RXCDRRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCDRRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXCDRRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRRESET}};

    if (GTYE3_CHANNEL_RXCDRRESETRSV_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCDRRESETRSV_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRRESETRSV_VAL}};
    else
      assign GTYE3_CHANNEL_RXCDRRESETRSV_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCDRRESETRSV}};

    if (GTYE3_CHANNEL_RXCHBONDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCHBONDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXCHBONDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDEN}};

    if (GTYE3_CHANNEL_RXCHBONDI_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCHBONDI_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDI_VAL}};
    else
      assign GTYE3_CHANNEL_RXCHBONDI_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDI}};

    if (GTYE3_CHANNEL_RXCHBONDLEVEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCHBONDLEVEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDLEVEL_VAL}};
    else
      assign GTYE3_CHANNEL_RXCHBONDLEVEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDLEVEL}};

    if (GTYE3_CHANNEL_RXCHBONDMASTER_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCHBONDMASTER_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDMASTER_VAL}};
    else
      assign GTYE3_CHANNEL_RXCHBONDMASTER_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDMASTER}};

    if (GTYE3_CHANNEL_RXCHBONDSLAVE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCHBONDSLAVE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDSLAVE_VAL}};
    else
      assign GTYE3_CHANNEL_RXCHBONDSLAVE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCHBONDSLAVE}};

    if (GTYE3_CHANNEL_RXCKCALRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCKCALRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCKCALRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXCKCALRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCKCALRESET}};

    if (GTYE3_CHANNEL_RXCOMMADETEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXCOMMADETEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCOMMADETEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXCOMMADETEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXCOMMADETEN}};

    if (GTYE3_CHANNEL_RXDCCFORCESTART_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDCCFORCESTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDCCFORCESTART_VAL}};
    else
      assign GTYE3_CHANNEL_RXDCCFORCESTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDCCFORCESTART}};

    if (GTYE3_CHANNEL_RXDFEAGCHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEAGCHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEAGCHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEAGCHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEAGCHOLD}};

    if (GTYE3_CHANNEL_RXDFEAGCOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEAGCOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEAGCOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEAGCOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEAGCOVRDEN}};

    if (GTYE3_CHANNEL_RXDFELFHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFELFHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFELFHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFELFHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFELFHOLD}};

    if (GTYE3_CHANNEL_RXDFELFOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFELFOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFELFOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFELFOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFELFOVRDEN}};

    if (GTYE3_CHANNEL_RXDFELPMRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFELPMRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFELPMRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFELPMRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFELPMRESET}};

    if (GTYE3_CHANNEL_RXDFETAP10HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP10HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP10HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP10HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP10HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP10OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP10OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP10OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP10OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP10OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP11HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP11HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP11HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP11HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP11HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP11OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP11OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP11OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP11OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP11OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP12HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP12HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP12HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP12HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP12HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP12OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP12OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP12OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP12OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP12OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP13HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP13HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP13HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP13HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP13HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP13OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP13OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP13OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP13OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP13OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP14HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP14HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP14HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP14HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP14HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP14OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP14OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP14OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP14OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP14OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP15HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP15HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP15HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP15HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP15HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP15OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP15OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP15OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP15OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP15OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP2HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP2HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP2HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP2HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP2HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP2OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP2OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP2OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP2OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP2OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP3HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP3HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP3HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP3HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP3HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP3OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP3OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP3OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP3OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP3OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP4HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP4HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP4HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP4HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP4HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP4OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP4OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP4OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP4OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP4OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP5HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP5HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP5HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP5HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP5HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP5OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP5OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP5OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP5OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP5OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP6HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP6HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP6HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP6HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP6HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP6OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP6OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP6OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP6OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP6OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP7HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP7HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP7HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP7HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP7HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP7OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP7OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP7OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP7OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP7OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP8HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP8HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP8HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP8HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP8HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP8OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP8OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP8OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP8OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP8OVRDEN}};

    if (GTYE3_CHANNEL_RXDFETAP9HOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP9HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP9HOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP9HOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP9HOLD}};

    if (GTYE3_CHANNEL_RXDFETAP9OVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFETAP9OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP9OVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFETAP9OVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFETAP9OVRDEN}};

    if (GTYE3_CHANNEL_RXDFEUTHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEUTHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEUTHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEUTHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEUTHOLD}};

    if (GTYE3_CHANNEL_RXDFEUTOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEUTOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEUTOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEUTOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEUTOVRDEN}};

    if (GTYE3_CHANNEL_RXDFEVPHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEVPHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEVPHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEVPHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEVPHOLD}};

    if (GTYE3_CHANNEL_RXDFEVPOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEVPOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEVPOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEVPOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEVPOVRDEN}};

    if (GTYE3_CHANNEL_RXDFEVSEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEVSEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEVSEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEVSEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEVSEN}};

    if (GTYE3_CHANNEL_RXDFEXYDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDFEXYDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEXYDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDFEXYDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDFEXYDEN}};

    if (GTYE3_CHANNEL_RXDLYBYPASS_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDLYBYPASS_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYBYPASS_VAL}};
    else
      assign GTYE3_CHANNEL_RXDLYBYPASS_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYBYPASS}};

    if (GTYE3_CHANNEL_RXDLYEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDLYEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDLYEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYEN}};

    if (GTYE3_CHANNEL_RXDLYOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDLYOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXDLYOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYOVRDEN}};

    if (GTYE3_CHANNEL_RXDLYSRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXDLYSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYSRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXDLYSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXDLYSRESET}};

    if (GTYE3_CHANNEL_RXELECIDLEMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXELECIDLEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXELECIDLEMODE_VAL}};
    else
      assign GTYE3_CHANNEL_RXELECIDLEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXELECIDLEMODE}};

    if (GTYE3_CHANNEL_RXGEARBOXSLIP_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXGEARBOXSLIP_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXGEARBOXSLIP_VAL}};
    else
      assign GTYE3_CHANNEL_RXGEARBOXSLIP_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXGEARBOXSLIP}};

    if (GTYE3_CHANNEL_RXLATCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLATCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLATCLK_VAL}};
    else
      assign GTYE3_CHANNEL_RXLATCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLATCLK}};

    if (GTYE3_CHANNEL_RXLPMEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMEN}};

    if (GTYE3_CHANNEL_RXLPMGCHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMGCHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMGCHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMGCHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMGCHOLD}};

    if (GTYE3_CHANNEL_RXLPMGCOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMGCOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMGCOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMGCOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMGCOVRDEN}};

    if (GTYE3_CHANNEL_RXLPMHFHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMHFHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMHFHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMHFHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMHFHOLD}};

    if (GTYE3_CHANNEL_RXLPMHFOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMHFOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMHFOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMHFOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMHFOVRDEN}};

    if (GTYE3_CHANNEL_RXLPMLFHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMLFHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMLFHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMLFHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMLFHOLD}};

    if (GTYE3_CHANNEL_RXLPMLFKLOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMLFKLOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMLFKLOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMLFKLOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMLFKLOVRDEN}};

    if (GTYE3_CHANNEL_RXLPMOSHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMOSHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMOSHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMOSHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMOSHOLD}};

    if (GTYE3_CHANNEL_RXLPMOSOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXLPMOSOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMOSOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXLPMOSOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXLPMOSOVRDEN}};

    if (GTYE3_CHANNEL_RXMCOMMAALIGNEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXMCOMMAALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXMCOMMAALIGNEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXMCOMMAALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXMCOMMAALIGNEN}};

    if (GTYE3_CHANNEL_RXMONITORSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXMONITORSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXMONITORSEL_VAL}};
    else
      assign GTYE3_CHANNEL_RXMONITORSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXMONITORSEL}};

    if (GTYE3_CHANNEL_RXOOBRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOOBRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOOBRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXOOBRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOOBRESET}};

    if (GTYE3_CHANNEL_RXOSCALRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSCALRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSCALRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSCALRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSCALRESET}};

    if (GTYE3_CHANNEL_RXOSHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSHOLD}};

    if (GTYE3_CHANNEL_RXOSINTCFG_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSINTCFG_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTCFG_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSINTCFG_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTCFG}};

    if (GTYE3_CHANNEL_RXOSINTEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSINTEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSINTEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTEN}};

    if (GTYE3_CHANNEL_RXOSINTHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSINTHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSINTHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTHOLD}};

    if (GTYE3_CHANNEL_RXOSINTOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSINTOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSINTOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTOVRDEN}};

    if (GTYE3_CHANNEL_RXOSINTSTROBE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSINTSTROBE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTSTROBE_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSINTSTROBE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTSTROBE}};

    if (GTYE3_CHANNEL_RXOSINTTESTOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSINTTESTOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTTESTOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSINTTESTOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSINTTESTOVRDEN}};

    if (GTYE3_CHANNEL_RXOSOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOSOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXOSOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOSOVRDEN}};

    if (GTYE3_CHANNEL_RXOUTCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXOUTCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOUTCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_RXOUTCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXOUTCLKSEL}};

    if (GTYE3_CHANNEL_RXPCOMMAALIGNEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPCOMMAALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPCOMMAALIGNEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXPCOMMAALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPCOMMAALIGNEN}};

    if (GTYE3_CHANNEL_RXPCSRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPCSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPCSRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXPCSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPCSRESET}};

    if (GTYE3_CHANNEL_RXPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPD_VAL}};
    else
      assign GTYE3_CHANNEL_RXPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPD}};

    if (GTYE3_CHANNEL_RXPHALIGN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPHALIGN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHALIGN_VAL}};
    else
      assign GTYE3_CHANNEL_RXPHALIGN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHALIGN}};

    if (GTYE3_CHANNEL_RXPHALIGNEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPHALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHALIGNEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXPHALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHALIGNEN}};

    if (GTYE3_CHANNEL_RXPHDLYPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPHDLYPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHDLYPD_VAL}};
    else
      assign GTYE3_CHANNEL_RXPHDLYPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHDLYPD}};

    if (GTYE3_CHANNEL_RXPHDLYRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPHDLYRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHDLYRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXPHDLYRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHDLYRESET}};

    if (GTYE3_CHANNEL_RXPHOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPHOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_RXPHOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPHOVRDEN}};

    if (GTYE3_CHANNEL_RXPLLCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPLLCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPLLCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_RXPLLCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPLLCLKSEL}};

    if (GTYE3_CHANNEL_RXPMARESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPMARESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPMARESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXPMARESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPMARESET}};

    if (GTYE3_CHANNEL_RXPOLARITY_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPOLARITY_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPOLARITY_VAL}};
    else
      assign GTYE3_CHANNEL_RXPOLARITY_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPOLARITY}};

    if (GTYE3_CHANNEL_RXPRBSCNTRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPRBSCNTRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPRBSCNTRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXPRBSCNTRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPRBSCNTRESET}};

    if (GTYE3_CHANNEL_RXPRBSSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPRBSSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPRBSSEL_VAL}};
    else
      assign GTYE3_CHANNEL_RXPRBSSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPRBSSEL}};

    if (GTYE3_CHANNEL_RXPROGDIVRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXPROGDIVRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPROGDIVRESET_VAL}};
    else
      assign GTYE3_CHANNEL_RXPROGDIVRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXPROGDIVRESET}};

    if (GTYE3_CHANNEL_RXRATE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXRATE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXRATE_VAL}};
    else
      assign GTYE3_CHANNEL_RXRATE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXRATE}};

    if (GTYE3_CHANNEL_RXRATEMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXRATEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXRATEMODE_VAL}};
    else
      assign GTYE3_CHANNEL_RXRATEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXRATEMODE}};

    if (GTYE3_CHANNEL_RXSLIDE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSLIDE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSLIDE_VAL}};
    else
      assign GTYE3_CHANNEL_RXSLIDE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSLIDE}};

    if (GTYE3_CHANNEL_RXSLIPOUTCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSLIPOUTCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSLIPOUTCLK_VAL}};
    else
      assign GTYE3_CHANNEL_RXSLIPOUTCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSLIPOUTCLK}};

    if (GTYE3_CHANNEL_RXSLIPPMA_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSLIPPMA_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSLIPPMA_VAL}};
    else
      assign GTYE3_CHANNEL_RXSLIPPMA_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSLIPPMA}};

    if (GTYE3_CHANNEL_RXSYNCALLIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSYNCALLIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYNCALLIN_VAL}};
    else
      assign GTYE3_CHANNEL_RXSYNCALLIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYNCALLIN}};

    if (GTYE3_CHANNEL_RXSYNCIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSYNCIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYNCIN_VAL}};
    else
      assign GTYE3_CHANNEL_RXSYNCIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYNCIN}};

    if (GTYE3_CHANNEL_RXSYNCMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSYNCMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYNCMODE_VAL}};
    else
      assign GTYE3_CHANNEL_RXSYNCMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYNCMODE}};

    if (GTYE3_CHANNEL_RXSYSCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXSYSCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYSCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_RXSYSCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXSYSCLKSEL}};

    if (GTYE3_CHANNEL_RXUSERRDY_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXUSERRDY_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXUSERRDY_VAL}};
    else
      assign GTYE3_CHANNEL_RXUSERRDY_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXUSERRDY}};

    if (GTYE3_CHANNEL_RXUSRCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXUSRCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXUSRCLK_VAL}};
    else
      assign GTYE3_CHANNEL_RXUSRCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXUSRCLK}};

    if (GTYE3_CHANNEL_RXUSRCLK2_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_RXUSRCLK2_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXUSRCLK2_VAL}};
    else
      assign GTYE3_CHANNEL_RXUSRCLK2_int = {NUM_CHANNELS{GTYE3_CHANNEL_RXUSRCLK2}};

    if (GTYE3_CHANNEL_SIGVALIDCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_SIGVALIDCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_SIGVALIDCLK_VAL}};
    else
      assign GTYE3_CHANNEL_SIGVALIDCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_SIGVALIDCLK}};

    if (GTYE3_CHANNEL_TSTIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TSTIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TSTIN_VAL}};
    else
      assign GTYE3_CHANNEL_TSTIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TSTIN}};

    if (GTYE3_CHANNEL_TX8B10BBYPASS_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TX8B10BBYPASS_int = {NUM_CHANNELS{GTYE3_CHANNEL_TX8B10BBYPASS_VAL}};
    else
      assign GTYE3_CHANNEL_TX8B10BBYPASS_int = {NUM_CHANNELS{GTYE3_CHANNEL_TX8B10BBYPASS}};

    if (GTYE3_CHANNEL_TX8B10BEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TX8B10BEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TX8B10BEN_VAL}};
    else
      assign GTYE3_CHANNEL_TX8B10BEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TX8B10BEN}};

    if (GTYE3_CHANNEL_TXBUFDIFFCTRL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXBUFDIFFCTRL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXBUFDIFFCTRL_VAL}};
    else
      assign GTYE3_CHANNEL_TXBUFDIFFCTRL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXBUFDIFFCTRL}};

    if (GTYE3_CHANNEL_TXCOMINIT_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXCOMINIT_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCOMINIT_VAL}};
    else
      assign GTYE3_CHANNEL_TXCOMINIT_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCOMINIT}};

    if (GTYE3_CHANNEL_TXCOMSAS_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXCOMSAS_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCOMSAS_VAL}};
    else
      assign GTYE3_CHANNEL_TXCOMSAS_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCOMSAS}};

    if (GTYE3_CHANNEL_TXCOMWAKE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXCOMWAKE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCOMWAKE_VAL}};
    else
      assign GTYE3_CHANNEL_TXCOMWAKE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCOMWAKE}};

    if (GTYE3_CHANNEL_TXCTRL0_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXCTRL0_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCTRL0_VAL}};
    else
      assign GTYE3_CHANNEL_TXCTRL0_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCTRL0}};

    if (GTYE3_CHANNEL_TXCTRL1_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXCTRL1_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCTRL1_VAL}};
    else
      assign GTYE3_CHANNEL_TXCTRL1_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCTRL1}};

    if (GTYE3_CHANNEL_TXCTRL2_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXCTRL2_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCTRL2_VAL}};
    else
      assign GTYE3_CHANNEL_TXCTRL2_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXCTRL2}};

    if (GTYE3_CHANNEL_TXDATA_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDATA_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDATA_VAL}};
    else
      assign GTYE3_CHANNEL_TXDATA_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDATA}};

    if (GTYE3_CHANNEL_TXDATAEXTENDRSVD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDATAEXTENDRSVD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDATAEXTENDRSVD_VAL}};
    else
      assign GTYE3_CHANNEL_TXDATAEXTENDRSVD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDATAEXTENDRSVD}};

    if (GTYE3_CHANNEL_TXDCCFORCESTART_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDCCFORCESTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDCCFORCESTART_VAL}};
    else
      assign GTYE3_CHANNEL_TXDCCFORCESTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDCCFORCESTART}};

    if (GTYE3_CHANNEL_TXDCCRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDCCRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDCCRESET_VAL}};
    else
      assign GTYE3_CHANNEL_TXDCCRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDCCRESET}};

    if (GTYE3_CHANNEL_TXDEEMPH_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDEEMPH_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDEEMPH_VAL}};
    else
      assign GTYE3_CHANNEL_TXDEEMPH_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDEEMPH}};

    if (GTYE3_CHANNEL_TXDETECTRX_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDETECTRX_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDETECTRX_VAL}};
    else
      assign GTYE3_CHANNEL_TXDETECTRX_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDETECTRX}};

    if (GTYE3_CHANNEL_TXDIFFCTRL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDIFFCTRL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDIFFCTRL_VAL}};
    else
      assign GTYE3_CHANNEL_TXDIFFCTRL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDIFFCTRL}};

    if (GTYE3_CHANNEL_TXDIFFPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDIFFPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDIFFPD_VAL}};
    else
      assign GTYE3_CHANNEL_TXDIFFPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDIFFPD}};

    if (GTYE3_CHANNEL_TXDLYBYPASS_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDLYBYPASS_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYBYPASS_VAL}};
    else
      assign GTYE3_CHANNEL_TXDLYBYPASS_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYBYPASS}};

    if (GTYE3_CHANNEL_TXDLYEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDLYEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYEN_VAL}};
    else
      assign GTYE3_CHANNEL_TXDLYEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYEN}};

    if (GTYE3_CHANNEL_TXDLYHOLD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDLYHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYHOLD_VAL}};
    else
      assign GTYE3_CHANNEL_TXDLYHOLD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYHOLD}};

    if (GTYE3_CHANNEL_TXDLYOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDLYOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_TXDLYOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYOVRDEN}};

    if (GTYE3_CHANNEL_TXDLYSRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDLYSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYSRESET_VAL}};
    else
      assign GTYE3_CHANNEL_TXDLYSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYSRESET}};

    if (GTYE3_CHANNEL_TXDLYUPDOWN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXDLYUPDOWN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYUPDOWN_VAL}};
    else
      assign GTYE3_CHANNEL_TXDLYUPDOWN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXDLYUPDOWN}};

    if (GTYE3_CHANNEL_TXELECIDLE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXELECIDLE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXELECIDLE_VAL}};
    else
      assign GTYE3_CHANNEL_TXELECIDLE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXELECIDLE}};

    if (GTYE3_CHANNEL_TXELFORCESTART_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXELFORCESTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXELFORCESTART_VAL}};
    else
      assign GTYE3_CHANNEL_TXELFORCESTART_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXELFORCESTART}};

    if (GTYE3_CHANNEL_TXHEADER_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXHEADER_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXHEADER_VAL}};
    else
      assign GTYE3_CHANNEL_TXHEADER_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXHEADER}};

    if (GTYE3_CHANNEL_TXINHIBIT_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXINHIBIT_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXINHIBIT_VAL}};
    else
      assign GTYE3_CHANNEL_TXINHIBIT_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXINHIBIT}};

    if (GTYE3_CHANNEL_TXLATCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXLATCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXLATCLK_VAL}};
    else
      assign GTYE3_CHANNEL_TXLATCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXLATCLK}};

    if (GTYE3_CHANNEL_TXMAINCURSOR_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXMAINCURSOR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXMAINCURSOR_VAL}};
    else
      assign GTYE3_CHANNEL_TXMAINCURSOR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXMAINCURSOR}};

    if (GTYE3_CHANNEL_TXMARGIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXMARGIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXMARGIN_VAL}};
    else
      assign GTYE3_CHANNEL_TXMARGIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXMARGIN}};

    if (GTYE3_CHANNEL_TXOUTCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXOUTCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXOUTCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_TXOUTCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXOUTCLKSEL}};

    if (GTYE3_CHANNEL_TXPCSRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPCSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPCSRESET_VAL}};
    else
      assign GTYE3_CHANNEL_TXPCSRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPCSRESET}};

    if (GTYE3_CHANNEL_TXPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPD_VAL}};
    else
      assign GTYE3_CHANNEL_TXPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPD}};

    if (GTYE3_CHANNEL_TXPDELECIDLEMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPDELECIDLEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPDELECIDLEMODE_VAL}};
    else
      assign GTYE3_CHANNEL_TXPDELECIDLEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPDELECIDLEMODE}};

    if (GTYE3_CHANNEL_TXPHALIGN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHALIGN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHALIGN_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHALIGN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHALIGN}};

    if (GTYE3_CHANNEL_TXPHALIGNEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHALIGNEN_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHALIGNEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHALIGNEN}};

    if (GTYE3_CHANNEL_TXPHDLYPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHDLYPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHDLYPD_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHDLYPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHDLYPD}};

    if (GTYE3_CHANNEL_TXPHDLYRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHDLYRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHDLYRESET_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHDLYRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHDLYRESET}};

    if (GTYE3_CHANNEL_TXPHDLYTSTCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHDLYTSTCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHDLYTSTCLK_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHDLYTSTCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHDLYTSTCLK}};

    if (GTYE3_CHANNEL_TXPHINIT_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHINIT_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHINIT_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHINIT_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHINIT}};

    if (GTYE3_CHANNEL_TXPHOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPHOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_TXPHOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPHOVRDEN}};

    if (GTYE3_CHANNEL_TXPIPPMEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPIPPMEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMEN_VAL}};
    else
      assign GTYE3_CHANNEL_TXPIPPMEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMEN}};

    if (GTYE3_CHANNEL_TXPIPPMOVRDEN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPIPPMOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMOVRDEN_VAL}};
    else
      assign GTYE3_CHANNEL_TXPIPPMOVRDEN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMOVRDEN}};

    if (GTYE3_CHANNEL_TXPIPPMPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPIPPMPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMPD_VAL}};
    else
      assign GTYE3_CHANNEL_TXPIPPMPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMPD}};

    if (GTYE3_CHANNEL_TXPIPPMSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPIPPMSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMSEL_VAL}};
    else
      assign GTYE3_CHANNEL_TXPIPPMSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMSEL}};

    if (GTYE3_CHANNEL_TXPIPPMSTEPSIZE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPIPPMSTEPSIZE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMSTEPSIZE_VAL}};
    else
      assign GTYE3_CHANNEL_TXPIPPMSTEPSIZE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPIPPMSTEPSIZE}};

    if (GTYE3_CHANNEL_TXPISOPD_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPISOPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPISOPD_VAL}};
    else
      assign GTYE3_CHANNEL_TXPISOPD_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPISOPD}};

    if (GTYE3_CHANNEL_TXPLLCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPLLCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPLLCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_TXPLLCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPLLCLKSEL}};

    if (GTYE3_CHANNEL_TXPMARESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPMARESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPMARESET_VAL}};
    else
      assign GTYE3_CHANNEL_TXPMARESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPMARESET}};

    if (GTYE3_CHANNEL_TXPOLARITY_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPOLARITY_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPOLARITY_VAL}};
    else
      assign GTYE3_CHANNEL_TXPOLARITY_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPOLARITY}};

    if (GTYE3_CHANNEL_TXPOSTCURSOR_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPOSTCURSOR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPOSTCURSOR_VAL}};
    else
      assign GTYE3_CHANNEL_TXPOSTCURSOR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPOSTCURSOR}};

    if (GTYE3_CHANNEL_TXPRBSFORCEERR_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPRBSFORCEERR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPRBSFORCEERR_VAL}};
    else
      assign GTYE3_CHANNEL_TXPRBSFORCEERR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPRBSFORCEERR}};

    if (GTYE3_CHANNEL_TXPRBSSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPRBSSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPRBSSEL_VAL}};
    else
      assign GTYE3_CHANNEL_TXPRBSSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPRBSSEL}};

    if (GTYE3_CHANNEL_TXPRECURSOR_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPRECURSOR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPRECURSOR_VAL}};
    else
      assign GTYE3_CHANNEL_TXPRECURSOR_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPRECURSOR}};

    if (GTYE3_CHANNEL_TXPROGDIVRESET_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXPROGDIVRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPROGDIVRESET_VAL}};
    else
      assign GTYE3_CHANNEL_TXPROGDIVRESET_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXPROGDIVRESET}};

    if (GTYE3_CHANNEL_TXRATE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXRATE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXRATE_VAL}};
    else
      assign GTYE3_CHANNEL_TXRATE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXRATE}};

    if (GTYE3_CHANNEL_TXRATEMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXRATEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXRATEMODE_VAL}};
    else
      assign GTYE3_CHANNEL_TXRATEMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXRATEMODE}};

    if (GTYE3_CHANNEL_TXSEQUENCE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXSEQUENCE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSEQUENCE_VAL}};
    else
      assign GTYE3_CHANNEL_TXSEQUENCE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSEQUENCE}};

    if (GTYE3_CHANNEL_TXSWING_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXSWING_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSWING_VAL}};
    else
      assign GTYE3_CHANNEL_TXSWING_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSWING}};

    if (GTYE3_CHANNEL_TXSYNCALLIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXSYNCALLIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYNCALLIN_VAL}};
    else
      assign GTYE3_CHANNEL_TXSYNCALLIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYNCALLIN}};

    if (GTYE3_CHANNEL_TXSYNCIN_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXSYNCIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYNCIN_VAL}};
    else
      assign GTYE3_CHANNEL_TXSYNCIN_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYNCIN}};

    if (GTYE3_CHANNEL_TXSYNCMODE_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXSYNCMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYNCMODE_VAL}};
    else
      assign GTYE3_CHANNEL_TXSYNCMODE_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYNCMODE}};

    if (GTYE3_CHANNEL_TXSYSCLKSEL_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXSYSCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYSCLKSEL_VAL}};
    else
      assign GTYE3_CHANNEL_TXSYSCLKSEL_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXSYSCLKSEL}};

    if (GTYE3_CHANNEL_TXUSERRDY_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXUSERRDY_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXUSERRDY_VAL}};
    else
      assign GTYE3_CHANNEL_TXUSERRDY_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXUSERRDY}};

    if (GTYE3_CHANNEL_TXUSRCLK_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXUSRCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXUSRCLK_VAL}};
    else
      assign GTYE3_CHANNEL_TXUSRCLK_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXUSRCLK}};

    if (GTYE3_CHANNEL_TXUSRCLK2_TIE_EN == 1'b1)
      assign GTYE3_CHANNEL_TXUSRCLK2_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXUSRCLK2_VAL}};
    else
      assign GTYE3_CHANNEL_TXUSRCLK2_int = {NUM_CHANNELS{GTYE3_CHANNEL_TXUSRCLK2}};

    // generate the appropriate number of GTYE3_CHANNEL primitive instances, mapping parameters and ports
    genvar ch;
    for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin : gen_gtye3_channel_inst

      GTYE3_CHANNEL #(
        .ACJTAG_DEBUG_MODE            (GTYE3_CHANNEL_ACJTAG_DEBUG_MODE           ),
        .ACJTAG_MODE                  (GTYE3_CHANNEL_ACJTAG_MODE                 ),
        .ACJTAG_RESET                 (GTYE3_CHANNEL_ACJTAG_RESET                ),
        .ADAPT_CFG0                   (GTYE3_CHANNEL_ADAPT_CFG0                  ),
        .ADAPT_CFG1                   (GTYE3_CHANNEL_ADAPT_CFG1                  ),
        .ADAPT_CFG2                   (GTYE3_CHANNEL_ADAPT_CFG2                  ),
        .ALIGN_COMMA_DOUBLE           (GTYE3_CHANNEL_ALIGN_COMMA_DOUBLE          ),
        .ALIGN_COMMA_ENABLE           (GTYE3_CHANNEL_ALIGN_COMMA_ENABLE          ),
        .ALIGN_COMMA_WORD             (GTYE3_CHANNEL_ALIGN_COMMA_WORD            ),
        .ALIGN_MCOMMA_DET             (GTYE3_CHANNEL_ALIGN_MCOMMA_DET            ),
        .ALIGN_MCOMMA_VALUE           (GTYE3_CHANNEL_ALIGN_MCOMMA_VALUE          ),
        .ALIGN_PCOMMA_DET             (GTYE3_CHANNEL_ALIGN_PCOMMA_DET            ),
        .ALIGN_PCOMMA_VALUE           (GTYE3_CHANNEL_ALIGN_PCOMMA_VALUE          ),
        .AUTO_BW_SEL_BYPASS           (GTYE3_CHANNEL_AUTO_BW_SEL_BYPASS          ),
        .A_RXOSCALRESET               (GTYE3_CHANNEL_A_RXOSCALRESET              ),
        .A_RXPROGDIVRESET             (GTYE3_CHANNEL_A_RXPROGDIVRESET            ),
        .A_TXDIFFCTRL                 (GTYE3_CHANNEL_A_TXDIFFCTRL                ),
        .A_TXPROGDIVRESET             (GTYE3_CHANNEL_A_TXPROGDIVRESET            ),
        .CAPBYPASS_FORCE              (GTYE3_CHANNEL_CAPBYPASS_FORCE             ),
        .CBCC_DATA_SOURCE_SEL         (GTYE3_CHANNEL_CBCC_DATA_SOURCE_SEL        ),
        .CDR_SWAP_MODE_EN             (GTYE3_CHANNEL_CDR_SWAP_MODE_EN            ),
        .CHAN_BOND_KEEP_ALIGN         (GTYE3_CHANNEL_CHAN_BOND_KEEP_ALIGN        ),
        .CHAN_BOND_MAX_SKEW           (GTYE3_CHANNEL_CHAN_BOND_MAX_SKEW          ),
        .CHAN_BOND_SEQ_1_1            (GTYE3_CHANNEL_CHAN_BOND_SEQ_1_1           ),
        .CHAN_BOND_SEQ_1_2            (GTYE3_CHANNEL_CHAN_BOND_SEQ_1_2           ),
        .CHAN_BOND_SEQ_1_3            (GTYE3_CHANNEL_CHAN_BOND_SEQ_1_3           ),
        .CHAN_BOND_SEQ_1_4            (GTYE3_CHANNEL_CHAN_BOND_SEQ_1_4           ),
        .CHAN_BOND_SEQ_1_ENABLE       (GTYE3_CHANNEL_CHAN_BOND_SEQ_1_ENABLE      ),
        .CHAN_BOND_SEQ_2_1            (GTYE3_CHANNEL_CHAN_BOND_SEQ_2_1           ),
        .CHAN_BOND_SEQ_2_2            (GTYE3_CHANNEL_CHAN_BOND_SEQ_2_2           ),
        .CHAN_BOND_SEQ_2_3            (GTYE3_CHANNEL_CHAN_BOND_SEQ_2_3           ),
        .CHAN_BOND_SEQ_2_4            (GTYE3_CHANNEL_CHAN_BOND_SEQ_2_4           ),
        .CHAN_BOND_SEQ_2_ENABLE       (GTYE3_CHANNEL_CHAN_BOND_SEQ_2_ENABLE      ),
        .CHAN_BOND_SEQ_2_USE          (GTYE3_CHANNEL_CHAN_BOND_SEQ_2_USE         ),
        .CHAN_BOND_SEQ_LEN            (GTYE3_CHANNEL_CHAN_BOND_SEQ_LEN           ),
        .CH_HSPMUX                    (GTYE3_CHANNEL_CH_HSPMUX                   ),
        .CKCAL1_CFG_0                 (GTYE3_CHANNEL_CKCAL1_CFG_0                ),
        .CKCAL1_CFG_1                 (GTYE3_CHANNEL_CKCAL1_CFG_1                ),
        .CKCAL1_CFG_2                 (GTYE3_CHANNEL_CKCAL1_CFG_2                ),
        .CKCAL1_CFG_3                 (GTYE3_CHANNEL_CKCAL1_CFG_3                ),
        .CKCAL2_CFG_0                 (GTYE3_CHANNEL_CKCAL2_CFG_0                ),
        .CKCAL2_CFG_1                 (GTYE3_CHANNEL_CKCAL2_CFG_1                ),
        .CKCAL2_CFG_2                 (GTYE3_CHANNEL_CKCAL2_CFG_2                ),
        .CKCAL2_CFG_3                 (GTYE3_CHANNEL_CKCAL2_CFG_3                ),
        .CKCAL2_CFG_4                 (GTYE3_CHANNEL_CKCAL2_CFG_4                ),
        .CKCAL_RSVD0                  (GTYE3_CHANNEL_CKCAL_RSVD0                 ),
        .CKCAL_RSVD1                  (GTYE3_CHANNEL_CKCAL_RSVD1                 ),
        .CLK_CORRECT_USE              (GTYE3_CHANNEL_CLK_CORRECT_USE             ),
        .CLK_COR_KEEP_IDLE            (GTYE3_CHANNEL_CLK_COR_KEEP_IDLE           ),
        .CLK_COR_MAX_LAT              (GTYE3_CHANNEL_CLK_COR_MAX_LAT             ),
        .CLK_COR_MIN_LAT              (GTYE3_CHANNEL_CLK_COR_MIN_LAT             ),
        .CLK_COR_PRECEDENCE           (GTYE3_CHANNEL_CLK_COR_PRECEDENCE          ),
        .CLK_COR_REPEAT_WAIT          (GTYE3_CHANNEL_CLK_COR_REPEAT_WAIT         ),
        .CLK_COR_SEQ_1_1              (GTYE3_CHANNEL_CLK_COR_SEQ_1_1             ),
        .CLK_COR_SEQ_1_2              (GTYE3_CHANNEL_CLK_COR_SEQ_1_2             ),
        .CLK_COR_SEQ_1_3              (GTYE3_CHANNEL_CLK_COR_SEQ_1_3             ),
        .CLK_COR_SEQ_1_4              (GTYE3_CHANNEL_CLK_COR_SEQ_1_4             ),
        .CLK_COR_SEQ_1_ENABLE         (GTYE3_CHANNEL_CLK_COR_SEQ_1_ENABLE        ),
        .CLK_COR_SEQ_2_1              (GTYE3_CHANNEL_CLK_COR_SEQ_2_1             ),
        .CLK_COR_SEQ_2_2              (GTYE3_CHANNEL_CLK_COR_SEQ_2_2             ),
        .CLK_COR_SEQ_2_3              (GTYE3_CHANNEL_CLK_COR_SEQ_2_3             ),
        .CLK_COR_SEQ_2_4              (GTYE3_CHANNEL_CLK_COR_SEQ_2_4             ),
        .CLK_COR_SEQ_2_ENABLE         (GTYE3_CHANNEL_CLK_COR_SEQ_2_ENABLE        ),
        .CLK_COR_SEQ_2_USE            (GTYE3_CHANNEL_CLK_COR_SEQ_2_USE           ),
        .CLK_COR_SEQ_LEN              (GTYE3_CHANNEL_CLK_COR_SEQ_LEN             ),
        .CPLL_CFG0                    (GTYE3_CHANNEL_CPLL_CFG0                   ),
        .CPLL_CFG1                    (GTYE3_CHANNEL_CPLL_CFG1                   ),
        .CPLL_CFG2                    (GTYE3_CHANNEL_CPLL_CFG2                   ),
        .CPLL_CFG3                    (GTYE3_CHANNEL_CPLL_CFG3                   ),
        .CPLL_FBDIV                   (GTYE3_CHANNEL_CPLL_FBDIV                  ),
        .CPLL_FBDIV_45                (GTYE3_CHANNEL_CPLL_FBDIV_45               ),
        .CPLL_INIT_CFG0               (GTYE3_CHANNEL_CPLL_INIT_CFG0              ),
        .CPLL_INIT_CFG1               (GTYE3_CHANNEL_CPLL_INIT_CFG1              ),
        .CPLL_LOCK_CFG                (GTYE3_CHANNEL_CPLL_LOCK_CFG               ),
        .CPLL_REFCLK_DIV              (GTYE3_CHANNEL_CPLL_REFCLK_DIV             ),
        .CTLE3_OCAP_EXT_CTRL          (GTYE3_CHANNEL_CTLE3_OCAP_EXT_CTRL         ),
        .CTLE3_OCAP_EXT_EN            (GTYE3_CHANNEL_CTLE3_OCAP_EXT_EN           ),
        .DDI_CTRL                     (GTYE3_CHANNEL_DDI_CTRL                    ),
        .DDI_REALIGN_WAIT             (GTYE3_CHANNEL_DDI_REALIGN_WAIT            ),
        .DEC_MCOMMA_DETECT            (GTYE3_CHANNEL_DEC_MCOMMA_DETECT           ),
        .DEC_PCOMMA_DETECT            (GTYE3_CHANNEL_DEC_PCOMMA_DETECT           ),
        .DEC_VALID_COMMA_ONLY         (GTYE3_CHANNEL_DEC_VALID_COMMA_ONLY        ),
        .DFE_D_X_REL_POS              (GTYE3_CHANNEL_DFE_D_X_REL_POS             ),
        .DFE_VCM_COMP_EN              (GTYE3_CHANNEL_DFE_VCM_COMP_EN             ),
        .DMONITOR_CFG0                (GTYE3_CHANNEL_DMONITOR_CFG0               ),
        .DMONITOR_CFG1                (GTYE3_CHANNEL_DMONITOR_CFG1               ),
        .ES_CLK_PHASE_SEL             (GTYE3_CHANNEL_ES_CLK_PHASE_SEL            ),
        .ES_CONTROL                   (GTYE3_CHANNEL_ES_CONTROL                  ),
        .ES_ERRDET_EN                 (GTYE3_CHANNEL_ES_ERRDET_EN                ),
        .ES_EYE_SCAN_EN               (GTYE3_CHANNEL_ES_EYE_SCAN_EN              ),
        .ES_HORZ_OFFSET               (GTYE3_CHANNEL_ES_HORZ_OFFSET              ),
        .ES_PMA_CFG                   (GTYE3_CHANNEL_ES_PMA_CFG                  ),
        .ES_PRESCALE                  (GTYE3_CHANNEL_ES_PRESCALE                 ),
        .ES_QUALIFIER0                (GTYE3_CHANNEL_ES_QUALIFIER0               ),
        .ES_QUALIFIER1                (GTYE3_CHANNEL_ES_QUALIFIER1               ),
        .ES_QUALIFIER2                (GTYE3_CHANNEL_ES_QUALIFIER2               ),
        .ES_QUALIFIER3                (GTYE3_CHANNEL_ES_QUALIFIER3               ),
        .ES_QUALIFIER4                (GTYE3_CHANNEL_ES_QUALIFIER4               ),
        .ES_QUALIFIER5                (GTYE3_CHANNEL_ES_QUALIFIER5               ),
        .ES_QUALIFIER6                (GTYE3_CHANNEL_ES_QUALIFIER6               ),
        .ES_QUALIFIER7                (GTYE3_CHANNEL_ES_QUALIFIER7               ),
        .ES_QUALIFIER8                (GTYE3_CHANNEL_ES_QUALIFIER8               ),
        .ES_QUALIFIER9                (GTYE3_CHANNEL_ES_QUALIFIER9               ),
        .ES_QUAL_MASK0                (GTYE3_CHANNEL_ES_QUAL_MASK0               ),
        .ES_QUAL_MASK1                (GTYE3_CHANNEL_ES_QUAL_MASK1               ),
        .ES_QUAL_MASK2                (GTYE3_CHANNEL_ES_QUAL_MASK2               ),
        .ES_QUAL_MASK3                (GTYE3_CHANNEL_ES_QUAL_MASK3               ),
        .ES_QUAL_MASK4                (GTYE3_CHANNEL_ES_QUAL_MASK4               ),
        .ES_QUAL_MASK5                (GTYE3_CHANNEL_ES_QUAL_MASK5               ),
        .ES_QUAL_MASK6                (GTYE3_CHANNEL_ES_QUAL_MASK6               ),
        .ES_QUAL_MASK7                (GTYE3_CHANNEL_ES_QUAL_MASK7               ),
        .ES_QUAL_MASK8                (GTYE3_CHANNEL_ES_QUAL_MASK8               ),
        .ES_QUAL_MASK9                (GTYE3_CHANNEL_ES_QUAL_MASK9               ),
        .ES_SDATA_MASK0               (GTYE3_CHANNEL_ES_SDATA_MASK0              ),
        .ES_SDATA_MASK1               (GTYE3_CHANNEL_ES_SDATA_MASK1              ),
        .ES_SDATA_MASK2               (GTYE3_CHANNEL_ES_SDATA_MASK2              ),
        .ES_SDATA_MASK3               (GTYE3_CHANNEL_ES_SDATA_MASK3              ),
        .ES_SDATA_MASK4               (GTYE3_CHANNEL_ES_SDATA_MASK4              ),
        .ES_SDATA_MASK5               (GTYE3_CHANNEL_ES_SDATA_MASK5              ),
        .ES_SDATA_MASK6               (GTYE3_CHANNEL_ES_SDATA_MASK6              ),
        .ES_SDATA_MASK7               (GTYE3_CHANNEL_ES_SDATA_MASK7              ),
        .ES_SDATA_MASK8               (GTYE3_CHANNEL_ES_SDATA_MASK8              ),
        .ES_SDATA_MASK9               (GTYE3_CHANNEL_ES_SDATA_MASK9              ),
        .EVODD_PHI_CFG                (GTYE3_CHANNEL_EVODD_PHI_CFG               ),
        .EYE_SCAN_SWAP_EN             (GTYE3_CHANNEL_EYE_SCAN_SWAP_EN            ),
        .FTS_DESKEW_SEQ_ENABLE        (GTYE3_CHANNEL_FTS_DESKEW_SEQ_ENABLE       ),
        .FTS_LANE_DESKEW_CFG          (GTYE3_CHANNEL_FTS_LANE_DESKEW_CFG         ),
        .FTS_LANE_DESKEW_EN           (GTYE3_CHANNEL_FTS_LANE_DESKEW_EN          ),
        .GEARBOX_MODE                 (GTYE3_CHANNEL_GEARBOX_MODE                ),
        .GM_BIAS_SELECT               (GTYE3_CHANNEL_GM_BIAS_SELECT              ),
        .ISCAN_CK_PH_SEL2             (GTYE3_CHANNEL_ISCAN_CK_PH_SEL2            ),
        .LOCAL_MASTER                 (GTYE3_CHANNEL_LOCAL_MASTER                ),
        .LOOP0_CFG                    (GTYE3_CHANNEL_LOOP0_CFG                   ),
        .LOOP10_CFG                   (GTYE3_CHANNEL_LOOP10_CFG                  ),
        .LOOP11_CFG                   (GTYE3_CHANNEL_LOOP11_CFG                  ),
        .LOOP12_CFG                   (GTYE3_CHANNEL_LOOP12_CFG                  ),
        .LOOP13_CFG                   (GTYE3_CHANNEL_LOOP13_CFG                  ),
        .LOOP1_CFG                    (GTYE3_CHANNEL_LOOP1_CFG                   ),
        .LOOP2_CFG                    (GTYE3_CHANNEL_LOOP2_CFG                   ),
        .LOOP3_CFG                    (GTYE3_CHANNEL_LOOP3_CFG                   ),
        .LOOP4_CFG                    (GTYE3_CHANNEL_LOOP4_CFG                   ),
        .LOOP5_CFG                    (GTYE3_CHANNEL_LOOP5_CFG                   ),
        .LOOP6_CFG                    (GTYE3_CHANNEL_LOOP6_CFG                   ),
        .LOOP7_CFG                    (GTYE3_CHANNEL_LOOP7_CFG                   ),
        .LOOP8_CFG                    (GTYE3_CHANNEL_LOOP8_CFG                   ),
        .LOOP9_CFG                    (GTYE3_CHANNEL_LOOP9_CFG                   ),
        .LPBK_BIAS_CTRL               (GTYE3_CHANNEL_LPBK_BIAS_CTRL              ),
        .LPBK_EN_RCAL_B               (GTYE3_CHANNEL_LPBK_EN_RCAL_B              ),
        .LPBK_EXT_RCAL                (GTYE3_CHANNEL_LPBK_EXT_RCAL               ),
        .LPBK_RG_CTRL                 (GTYE3_CHANNEL_LPBK_RG_CTRL                ),
        .OOBDIVCTL                    (GTYE3_CHANNEL_OOBDIVCTL                   ),
        .OOB_PWRUP                    (GTYE3_CHANNEL_OOB_PWRUP                   ),
        .PCI3_AUTO_REALIGN            (GTYE3_CHANNEL_PCI3_AUTO_REALIGN           ),
        .PCI3_PIPE_RX_ELECIDLE        (GTYE3_CHANNEL_PCI3_PIPE_RX_ELECIDLE       ),
        .PCI3_RX_ASYNC_EBUF_BYPASS    (GTYE3_CHANNEL_PCI3_RX_ASYNC_EBUF_BYPASS   ),
        .PCI3_RX_ELECIDLE_EI2_ENABLE  (GTYE3_CHANNEL_PCI3_RX_ELECIDLE_EI2_ENABLE ),
        .PCI3_RX_ELECIDLE_H2L_COUNT   (GTYE3_CHANNEL_PCI3_RX_ELECIDLE_H2L_COUNT  ),
        .PCI3_RX_ELECIDLE_H2L_DISABLE (GTYE3_CHANNEL_PCI3_RX_ELECIDLE_H2L_DISABLE),
        .PCI3_RX_ELECIDLE_HI_COUNT    (GTYE3_CHANNEL_PCI3_RX_ELECIDLE_HI_COUNT   ),
        .PCI3_RX_ELECIDLE_LP4_DISABLE (GTYE3_CHANNEL_PCI3_RX_ELECIDLE_LP4_DISABLE),
        .PCI3_RX_FIFO_DISABLE         (GTYE3_CHANNEL_PCI3_RX_FIFO_DISABLE        ),
        .PCIE_BUFG_DIV_CTRL           (GTYE3_CHANNEL_PCIE_BUFG_DIV_CTRL          ),
        .PCIE_RXPCS_CFG_GEN3          (GTYE3_CHANNEL_PCIE_RXPCS_CFG_GEN3         ),
        .PCIE_RXPMA_CFG               (GTYE3_CHANNEL_PCIE_RXPMA_CFG              ),
        .PCIE_TXPCS_CFG_GEN3          (GTYE3_CHANNEL_PCIE_TXPCS_CFG_GEN3         ),
        .PCIE_TXPMA_CFG               (GTYE3_CHANNEL_PCIE_TXPMA_CFG              ),
        .PCS_PCIE_EN                  (GTYE3_CHANNEL_PCS_PCIE_EN                 ),
        .PCS_RSVD0                    (GTYE3_CHANNEL_PCS_RSVD0                   ),
        .PCS_RSVD1                    (GTYE3_CHANNEL_PCS_RSVD1                   ),
        .PD_TRANS_TIME_FROM_P2        (GTYE3_CHANNEL_PD_TRANS_TIME_FROM_P2       ),
        .PD_TRANS_TIME_NONE_P2        (GTYE3_CHANNEL_PD_TRANS_TIME_NONE_P2       ),
        .PD_TRANS_TIME_TO_P2          (GTYE3_CHANNEL_PD_TRANS_TIME_TO_P2         ),
        .PLL_SEL_MODE_GEN12           (GTYE3_CHANNEL_PLL_SEL_MODE_GEN12          ),
        .PLL_SEL_MODE_GEN3            (GTYE3_CHANNEL_PLL_SEL_MODE_GEN3           ),
        .PMA_RSV0                     (GTYE3_CHANNEL_PMA_RSV0                    ),
        .PMA_RSV1                     (GTYE3_CHANNEL_PMA_RSV1                    ),
        .PREIQ_FREQ_BST               (GTYE3_CHANNEL_PREIQ_FREQ_BST              ),
        .PROCESS_PAR                  (GTYE3_CHANNEL_PROCESS_PAR                 ),
        .RATE_SW_USE_DRP              (GTYE3_CHANNEL_RATE_SW_USE_DRP             ),
        .RESET_POWERSAVE_DISABLE      (GTYE3_CHANNEL_RESET_POWERSAVE_DISABLE     ),
        .RXBUFRESET_TIME              (GTYE3_CHANNEL_RXBUFRESET_TIME             ),
        .RXBUF_ADDR_MODE              (GTYE3_CHANNEL_RXBUF_ADDR_MODE             ),
        .RXBUF_EIDLE_HI_CNT           (GTYE3_CHANNEL_RXBUF_EIDLE_HI_CNT          ),
        .RXBUF_EIDLE_LO_CNT           (GTYE3_CHANNEL_RXBUF_EIDLE_LO_CNT          ),
        .RXBUF_EN                     (GTYE3_CHANNEL_RXBUF_EN                    ),
        .RXBUF_RESET_ON_CB_CHANGE     (GTYE3_CHANNEL_RXBUF_RESET_ON_CB_CHANGE    ),
        .RXBUF_RESET_ON_COMMAALIGN    (GTYE3_CHANNEL_RXBUF_RESET_ON_COMMAALIGN   ),
        .RXBUF_RESET_ON_EIDLE         (GTYE3_CHANNEL_RXBUF_RESET_ON_EIDLE        ),
        .RXBUF_RESET_ON_RATE_CHANGE   (GTYE3_CHANNEL_RXBUF_RESET_ON_RATE_CHANGE  ),
        .RXBUF_THRESH_OVFLW           (GTYE3_CHANNEL_RXBUF_THRESH_OVFLW          ),
        .RXBUF_THRESH_OVRD            (GTYE3_CHANNEL_RXBUF_THRESH_OVRD           ),
        .RXBUF_THRESH_UNDFLW          (GTYE3_CHANNEL_RXBUF_THRESH_UNDFLW         ),
        .RXCDRFREQRESET_TIME          (GTYE3_CHANNEL_RXCDRFREQRESET_TIME         ),
        .RXCDRPHRESET_TIME            (GTYE3_CHANNEL_RXCDRPHRESET_TIME           ),
        .RXCDR_CFG0                   (GTYE3_CHANNEL_RXCDR_CFG0                  ),
        .RXCDR_CFG0_GEN3              (GTYE3_CHANNEL_RXCDR_CFG0_GEN3             ),
        .RXCDR_CFG1                   (GTYE3_CHANNEL_RXCDR_CFG1                  ),
        .RXCDR_CFG1_GEN3              (GTYE3_CHANNEL_RXCDR_CFG1_GEN3             ),
        .RXCDR_CFG2                   (GTYE3_CHANNEL_RXCDR_CFG2                  ),
        .RXCDR_CFG2_GEN3              (GTYE3_CHANNEL_RXCDR_CFG2_GEN3             ),
        .RXCDR_CFG3                   (GTYE3_CHANNEL_RXCDR_CFG3                  ),
        .RXCDR_CFG3_GEN3              (GTYE3_CHANNEL_RXCDR_CFG3_GEN3             ),
        .RXCDR_CFG4                   (GTYE3_CHANNEL_RXCDR_CFG4                  ),
        .RXCDR_CFG4_GEN3              (GTYE3_CHANNEL_RXCDR_CFG4_GEN3             ),
        .RXCDR_CFG5                   (GTYE3_CHANNEL_RXCDR_CFG5                  ),
        .RXCDR_CFG5_GEN3              (GTYE3_CHANNEL_RXCDR_CFG5_GEN3             ),
        .RXCDR_FR_RESET_ON_EIDLE      (GTYE3_CHANNEL_RXCDR_FR_RESET_ON_EIDLE     ),
        .RXCDR_HOLD_DURING_EIDLE      (GTYE3_CHANNEL_RXCDR_HOLD_DURING_EIDLE     ),
        .RXCDR_LOCK_CFG0              (GTYE3_CHANNEL_RXCDR_LOCK_CFG0             ),
        .RXCDR_LOCK_CFG1              (GTYE3_CHANNEL_RXCDR_LOCK_CFG1             ),
        .RXCDR_LOCK_CFG2              (GTYE3_CHANNEL_RXCDR_LOCK_CFG2             ),
        .RXCDR_LOCK_CFG3              (GTYE3_CHANNEL_RXCDR_LOCK_CFG3             ),
        .RXCDR_PH_RESET_ON_EIDLE      (GTYE3_CHANNEL_RXCDR_PH_RESET_ON_EIDLE     ),
        .RXCFOKDONE_SRC               (GTYE3_CHANNEL_RXCFOKDONE_SRC              ),
        .RXCFOK_CFG0                  (GTYE3_CHANNEL_RXCFOK_CFG0                 ),
        .RXCFOK_CFG1                  (GTYE3_CHANNEL_RXCFOK_CFG1                 ),
        .RXCFOK_CFG2                  (GTYE3_CHANNEL_RXCFOK_CFG2                 ),
        .RXDFELPMRESET_TIME           (GTYE3_CHANNEL_RXDFELPMRESET_TIME          ),
        .RXDFELPM_KL_CFG0             (GTYE3_CHANNEL_RXDFELPM_KL_CFG0            ),
        .RXDFELPM_KL_CFG1             (GTYE3_CHANNEL_RXDFELPM_KL_CFG1            ),
        .RXDFELPM_KL_CFG2             (GTYE3_CHANNEL_RXDFELPM_KL_CFG2            ),
        .RXDFE_CFG0                   (GTYE3_CHANNEL_RXDFE_CFG0                  ),
        .RXDFE_CFG1                   (GTYE3_CHANNEL_RXDFE_CFG1                  ),
        .RXDFE_GC_CFG0                (GTYE3_CHANNEL_RXDFE_GC_CFG0               ),
        .RXDFE_GC_CFG1                (GTYE3_CHANNEL_RXDFE_GC_CFG1               ),
        .RXDFE_GC_CFG2                (GTYE3_CHANNEL_RXDFE_GC_CFG2               ),
        .RXDFE_H2_CFG0                (GTYE3_CHANNEL_RXDFE_H2_CFG0               ),
        .RXDFE_H2_CFG1                (GTYE3_CHANNEL_RXDFE_H2_CFG1               ),
        .RXDFE_H3_CFG0                (GTYE3_CHANNEL_RXDFE_H3_CFG0               ),
        .RXDFE_H3_CFG1                (GTYE3_CHANNEL_RXDFE_H3_CFG1               ),
        .RXDFE_H4_CFG0                (GTYE3_CHANNEL_RXDFE_H4_CFG0               ),
        .RXDFE_H4_CFG1                (GTYE3_CHANNEL_RXDFE_H4_CFG1               ),
        .RXDFE_H5_CFG0                (GTYE3_CHANNEL_RXDFE_H5_CFG0               ),
        .RXDFE_H5_CFG1                (GTYE3_CHANNEL_RXDFE_H5_CFG1               ),
        .RXDFE_H6_CFG0                (GTYE3_CHANNEL_RXDFE_H6_CFG0               ),
        .RXDFE_H6_CFG1                (GTYE3_CHANNEL_RXDFE_H6_CFG1               ),
        .RXDFE_H7_CFG0                (GTYE3_CHANNEL_RXDFE_H7_CFG0               ),
        .RXDFE_H7_CFG1                (GTYE3_CHANNEL_RXDFE_H7_CFG1               ),
        .RXDFE_H8_CFG0                (GTYE3_CHANNEL_RXDFE_H8_CFG0               ),
        .RXDFE_H8_CFG1                (GTYE3_CHANNEL_RXDFE_H8_CFG1               ),
        .RXDFE_H9_CFG0                (GTYE3_CHANNEL_RXDFE_H9_CFG0               ),
        .RXDFE_H9_CFG1                (GTYE3_CHANNEL_RXDFE_H9_CFG1               ),
        .RXDFE_HA_CFG0                (GTYE3_CHANNEL_RXDFE_HA_CFG0               ),
        .RXDFE_HA_CFG1                (GTYE3_CHANNEL_RXDFE_HA_CFG1               ),
        .RXDFE_HB_CFG0                (GTYE3_CHANNEL_RXDFE_HB_CFG0               ),
        .RXDFE_HB_CFG1                (GTYE3_CHANNEL_RXDFE_HB_CFG1               ),
        .RXDFE_HC_CFG0                (GTYE3_CHANNEL_RXDFE_HC_CFG0               ),
        .RXDFE_HC_CFG1                (GTYE3_CHANNEL_RXDFE_HC_CFG1               ),
        .RXDFE_HD_CFG0                (GTYE3_CHANNEL_RXDFE_HD_CFG0               ),
        .RXDFE_HD_CFG1                (GTYE3_CHANNEL_RXDFE_HD_CFG1               ),
        .RXDFE_HE_CFG0                (GTYE3_CHANNEL_RXDFE_HE_CFG0               ),
        .RXDFE_HE_CFG1                (GTYE3_CHANNEL_RXDFE_HE_CFG1               ),
        .RXDFE_HF_CFG0                (GTYE3_CHANNEL_RXDFE_HF_CFG0               ),
        .RXDFE_HF_CFG1                (GTYE3_CHANNEL_RXDFE_HF_CFG1               ),
        .RXDFE_OS_CFG0                (GTYE3_CHANNEL_RXDFE_OS_CFG0               ),
        .RXDFE_OS_CFG1                (GTYE3_CHANNEL_RXDFE_OS_CFG1               ),
        .RXDFE_PWR_SAVING             (GTYE3_CHANNEL_RXDFE_PWR_SAVING            ),
        .RXDFE_UT_CFG0                (GTYE3_CHANNEL_RXDFE_UT_CFG0               ),
        .RXDFE_UT_CFG1                (GTYE3_CHANNEL_RXDFE_UT_CFG1               ),
        .RXDFE_VP_CFG0                (GTYE3_CHANNEL_RXDFE_VP_CFG0               ),
        .RXDFE_VP_CFG1                (GTYE3_CHANNEL_RXDFE_VP_CFG1               ),
        .RXDLY_CFG                    (GTYE3_CHANNEL_RXDLY_CFG                   ),
        .RXDLY_LCFG                   (GTYE3_CHANNEL_RXDLY_LCFG                  ),
        .RXELECIDLE_CFG               (GTYE3_CHANNEL_RXELECIDLE_CFG              ),
        .RXGBOX_FIFO_INIT_RD_ADDR     (GTYE3_CHANNEL_RXGBOX_FIFO_INIT_RD_ADDR    ),
        .RXGEARBOX_EN                 (GTYE3_CHANNEL_RXGEARBOX_EN                ),
        .RXISCANRESET_TIME            (GTYE3_CHANNEL_RXISCANRESET_TIME           ),
        .RXLPM_CFG                    (GTYE3_CHANNEL_RXLPM_CFG                   ),
        .RXLPM_GC_CFG                 (GTYE3_CHANNEL_RXLPM_GC_CFG                ),
        .RXLPM_KH_CFG0                (GTYE3_CHANNEL_RXLPM_KH_CFG0               ),
        .RXLPM_KH_CFG1                (GTYE3_CHANNEL_RXLPM_KH_CFG1               ),
        .RXLPM_OS_CFG0                (GTYE3_CHANNEL_RXLPM_OS_CFG0               ),
        .RXLPM_OS_CFG1                (GTYE3_CHANNEL_RXLPM_OS_CFG1               ),
        .RXOOB_CFG                    (GTYE3_CHANNEL_RXOOB_CFG                   ),
        .RXOOB_CLK_CFG                (GTYE3_CHANNEL_RXOOB_CLK_CFG               ),
        .RXOSCALRESET_TIME            (GTYE3_CHANNEL_RXOSCALRESET_TIME           ),
        .RXOUT_DIV                    (GTYE3_CHANNEL_RXOUT_DIV                   ),
        .RXPCSRESET_TIME              (GTYE3_CHANNEL_RXPCSRESET_TIME             ),
        .RXPHBEACON_CFG               (GTYE3_CHANNEL_RXPHBEACON_CFG              ),
        .RXPHDLY_CFG                  (GTYE3_CHANNEL_RXPHDLY_CFG                 ),
        .RXPHSAMP_CFG                 (GTYE3_CHANNEL_RXPHSAMP_CFG                ),
        .RXPHSLIP_CFG                 (GTYE3_CHANNEL_RXPHSLIP_CFG                ),
        .RXPH_MONITOR_SEL             (GTYE3_CHANNEL_RXPH_MONITOR_SEL            ),
        .RXPI_AUTO_BW_SEL_BYPASS      (GTYE3_CHANNEL_RXPI_AUTO_BW_SEL_BYPASS     ),
        .RXPI_CFG                     (GTYE3_CHANNEL_RXPI_CFG                    ),
        .RXPI_LPM                     (GTYE3_CHANNEL_RXPI_LPM                    ),
        .RXPI_RSV0                    (GTYE3_CHANNEL_RXPI_RSV0                   ),
        .RXPI_SEL_LC                  (GTYE3_CHANNEL_RXPI_SEL_LC                 ),
        .RXPI_STARTCODE               (GTYE3_CHANNEL_RXPI_STARTCODE              ),
        .RXPI_VREFSEL                 (GTYE3_CHANNEL_RXPI_VREFSEL                ),
        .RXPMACLK_SEL                 (GTYE3_CHANNEL_RXPMACLK_SEL                ),
        .RXPMARESET_TIME              (GTYE3_CHANNEL_RXPMARESET_TIME             ),
        .RXPRBS_ERR_LOOPBACK          (GTYE3_CHANNEL_RXPRBS_ERR_LOOPBACK         ),
        .RXPRBS_LINKACQ_CNT           (GTYE3_CHANNEL_RXPRBS_LINKACQ_CNT          ),
        .RXSLIDE_AUTO_WAIT            (GTYE3_CHANNEL_RXSLIDE_AUTO_WAIT           ),
        .RXSLIDE_MODE                 (GTYE3_CHANNEL_RXSLIDE_MODE                ),
        .RXSYNC_MULTILANE             (GTYE3_CHANNEL_RXSYNC_MULTILANE            ),
        .RXSYNC_OVRD                  (GTYE3_CHANNEL_RXSYNC_OVRD                 ),
        .RXSYNC_SKIP_DA               (GTYE3_CHANNEL_RXSYNC_SKIP_DA              ),
        .RX_AFE_CM_EN                 (GTYE3_CHANNEL_RX_AFE_CM_EN                ),
        .RX_BIAS_CFG0                 (GTYE3_CHANNEL_RX_BIAS_CFG0                ),
        .RX_BUFFER_CFG                (GTYE3_CHANNEL_RX_BUFFER_CFG               ),
        .RX_CAPFF_SARC_ENB            (GTYE3_CHANNEL_RX_CAPFF_SARC_ENB           ),
        .RX_CLK25_DIV                 (GTYE3_CHANNEL_RX_CLK25_DIV                ),
        .RX_CLKMUX_EN                 (GTYE3_CHANNEL_RX_CLKMUX_EN                ),
        .RX_CLK_SLIP_OVRD             (GTYE3_CHANNEL_RX_CLK_SLIP_OVRD            ),
        .RX_CM_BUF_CFG                (GTYE3_CHANNEL_RX_CM_BUF_CFG               ),
        .RX_CM_BUF_PD                 (GTYE3_CHANNEL_RX_CM_BUF_PD                ),
        .RX_CM_SEL                    (GTYE3_CHANNEL_RX_CM_SEL                   ),
        .RX_CM_TRIM                   (GTYE3_CHANNEL_RX_CM_TRIM                  ),
        .RX_CTLE1_KHKL                (GTYE3_CHANNEL_RX_CTLE1_KHKL               ),
        .RX_CTLE2_KHKL                (GTYE3_CHANNEL_RX_CTLE2_KHKL               ),
        .RX_CTLE3_AGC                 (GTYE3_CHANNEL_RX_CTLE3_AGC                ),
        .RX_DATA_WIDTH                (GTYE3_CHANNEL_RX_DATA_WIDTH               ),
        .RX_DDI_SEL                   (GTYE3_CHANNEL_RX_DDI_SEL                  ),
        .RX_DEFER_RESET_BUF_EN        (GTYE3_CHANNEL_RX_DEFER_RESET_BUF_EN       ),
        .RX_DEGEN_CTRL                (GTYE3_CHANNEL_RX_DEGEN_CTRL               ),
        .RX_DFELPM_CFG0               (GTYE3_CHANNEL_RX_DFELPM_CFG0              ),
        .RX_DFELPM_CFG1               (GTYE3_CHANNEL_RX_DFELPM_CFG1              ),
        .RX_DFELPM_KLKH_AGC_STUP_EN   (GTYE3_CHANNEL_RX_DFELPM_KLKH_AGC_STUP_EN  ),
        .RX_DFE_AGC_CFG0              (GTYE3_CHANNEL_RX_DFE_AGC_CFG0             ),
        .RX_DFE_AGC_CFG1              (GTYE3_CHANNEL_RX_DFE_AGC_CFG1             ),
        .RX_DFE_KL_LPM_KH_CFG0        (GTYE3_CHANNEL_RX_DFE_KL_LPM_KH_CFG0       ),
        .RX_DFE_KL_LPM_KH_CFG1        (GTYE3_CHANNEL_RX_DFE_KL_LPM_KH_CFG1       ),
        .RX_DFE_KL_LPM_KL_CFG0        (GTYE3_CHANNEL_RX_DFE_KL_LPM_KL_CFG0       ),
        .RX_DFE_KL_LPM_KL_CFG1        (GTYE3_CHANNEL_RX_DFE_KL_LPM_KL_CFG1       ),
        .RX_DFE_LPM_HOLD_DURING_EIDLE (GTYE3_CHANNEL_RX_DFE_LPM_HOLD_DURING_EIDLE),
        .RX_DISPERR_SEQ_MATCH         (GTYE3_CHANNEL_RX_DISPERR_SEQ_MATCH        ),
        .RX_DIV2_MODE_B               (GTYE3_CHANNEL_RX_DIV2_MODE_B              ),
        .RX_DIVRESET_TIME             (GTYE3_CHANNEL_RX_DIVRESET_TIME            ),
        .RX_EN_CTLE_RCAL_B            (GTYE3_CHANNEL_RX_EN_CTLE_RCAL_B           ),
        .RX_EN_HI_LR                  (GTYE3_CHANNEL_RX_EN_HI_LR                 ),
        .RX_EXT_RL_CTRL               (GTYE3_CHANNEL_RX_EXT_RL_CTRL              ),
        .RX_EYESCAN_VS_CODE           (GTYE3_CHANNEL_RX_EYESCAN_VS_CODE          ),
        .RX_EYESCAN_VS_NEG_DIR        (GTYE3_CHANNEL_RX_EYESCAN_VS_NEG_DIR       ),
        .RX_EYESCAN_VS_RANGE          (GTYE3_CHANNEL_RX_EYESCAN_VS_RANGE         ),
        .RX_EYESCAN_VS_UT_SIGN        (GTYE3_CHANNEL_RX_EYESCAN_VS_UT_SIGN       ),
        .RX_FABINT_USRCLK_FLOP        (GTYE3_CHANNEL_RX_FABINT_USRCLK_FLOP       ),
        .RX_INT_DATAWIDTH             (GTYE3_CHANNEL_RX_INT_DATAWIDTH            ),
        .RX_PMA_POWER_SAVE            (GTYE3_CHANNEL_RX_PMA_POWER_SAVE           ),
        .RX_PROGDIV_CFG               (GTYE3_CHANNEL_RX_PROGDIV_CFG              ),
        .RX_PROGDIV_RATE              (GTYE3_CHANNEL_RX_PROGDIV_RATE             ),
        .RX_RESLOAD_CTRL              (GTYE3_CHANNEL_RX_RESLOAD_CTRL             ),
        .RX_RESLOAD_OVRD              (GTYE3_CHANNEL_RX_RESLOAD_OVRD             ),
        .RX_SAMPLE_PERIOD             (GTYE3_CHANNEL_RX_SAMPLE_PERIOD            ),
        .RX_SIG_VALID_DLY             (GTYE3_CHANNEL_RX_SIG_VALID_DLY            ),
        .RX_SUM_DFETAPREP_EN          (GTYE3_CHANNEL_RX_SUM_DFETAPREP_EN         ),
        .RX_SUM_IREF_TUNE             (GTYE3_CHANNEL_RX_SUM_IREF_TUNE            ),
        .RX_SUM_VCMTUNE               (GTYE3_CHANNEL_RX_SUM_VCMTUNE              ),
        .RX_SUM_VCM_OVWR              (GTYE3_CHANNEL_RX_SUM_VCM_OVWR             ),
        .RX_SUM_VREF_TUNE             (GTYE3_CHANNEL_RX_SUM_VREF_TUNE            ),
        .RX_TUNE_AFE_OS               (GTYE3_CHANNEL_RX_TUNE_AFE_OS              ),
        .RX_VREG_CTRL                 (GTYE3_CHANNEL_RX_VREG_CTRL                ),
        .RX_VREG_PDB                  (GTYE3_CHANNEL_RX_VREG_PDB                 ),
        .RX_WIDEMODE_CDR              (GTYE3_CHANNEL_RX_WIDEMODE_CDR             ),
        .RX_XCLK_SEL                  (GTYE3_CHANNEL_RX_XCLK_SEL                 ),
        .RX_XMODE_SEL                 (GTYE3_CHANNEL_RX_XMODE_SEL                ),
        .SAS_MAX_COM                  (GTYE3_CHANNEL_SAS_MAX_COM                 ),
        .SAS_MIN_COM                  (GTYE3_CHANNEL_SAS_MIN_COM                 ),
        .SATA_BURST_SEQ_LEN           (GTYE3_CHANNEL_SATA_BURST_SEQ_LEN          ),
        .SATA_BURST_VAL               (GTYE3_CHANNEL_SATA_BURST_VAL              ),
        .SATA_CPLL_CFG                (GTYE3_CHANNEL_SATA_CPLL_CFG               ),
        .SATA_EIDLE_VAL               (GTYE3_CHANNEL_SATA_EIDLE_VAL              ),
        .SATA_MAX_BURST               (GTYE3_CHANNEL_SATA_MAX_BURST              ),
        .SATA_MAX_INIT                (GTYE3_CHANNEL_SATA_MAX_INIT               ),
        .SATA_MAX_WAKE                (GTYE3_CHANNEL_SATA_MAX_WAKE               ),
        .SATA_MIN_BURST               (GTYE3_CHANNEL_SATA_MIN_BURST              ),
        .SATA_MIN_INIT                (GTYE3_CHANNEL_SATA_MIN_INIT               ),
        .SATA_MIN_WAKE                (GTYE3_CHANNEL_SATA_MIN_WAKE               ),
        .SHOW_REALIGN_COMMA           (GTYE3_CHANNEL_SHOW_REALIGN_COMMA          ),
        .SIM_MODE                     (GTYE3_CHANNEL_SIM_MODE                    ),
        .SIM_RECEIVER_DETECT_PASS     (GTYE3_CHANNEL_SIM_RECEIVER_DETECT_PASS    ),
        .SIM_RESET_SPEEDUP            (GTYE3_CHANNEL_SIM_RESET_SPEEDUP           ),
        .SIM_TX_EIDLE_DRIVE_LEVEL     (GTYE3_CHANNEL_SIM_TX_EIDLE_DRIVE_LEVEL    ),
        .SIM_VERSION                  (GTYE3_CHANNEL_SIM_VERSION                 ),
        .TAPDLY_SET_TX                (GTYE3_CHANNEL_TAPDLY_SET_TX               ),
        .TEMPERATURE_PAR              (GTYE3_CHANNEL_TEMPERATURE_PAR             ),
        .TERM_RCAL_CFG                (GTYE3_CHANNEL_TERM_RCAL_CFG               ),
        .TERM_RCAL_OVRD               (GTYE3_CHANNEL_TERM_RCAL_OVRD              ),
        .TRANS_TIME_RATE              (GTYE3_CHANNEL_TRANS_TIME_RATE             ),
        .TST_RSV0                     (GTYE3_CHANNEL_TST_RSV0                    ),
        .TST_RSV1                     (GTYE3_CHANNEL_TST_RSV1                    ),
        .TXBUF_EN                     (GTYE3_CHANNEL_TXBUF_EN                    ),
        .TXBUF_RESET_ON_RATE_CHANGE   (GTYE3_CHANNEL_TXBUF_RESET_ON_RATE_CHANGE  ),
        .TXDLY_CFG                    (GTYE3_CHANNEL_TXDLY_CFG                   ),
        .TXDLY_LCFG                   (GTYE3_CHANNEL_TXDLY_LCFG                  ),
        .TXFIFO_ADDR_CFG              (GTYE3_CHANNEL_TXFIFO_ADDR_CFG             ),
        .TXGBOX_FIFO_INIT_RD_ADDR     (GTYE3_CHANNEL_TXGBOX_FIFO_INIT_RD_ADDR    ),
        .TXGEARBOX_EN                 (GTYE3_CHANNEL_TXGEARBOX_EN                ),
        .TXOUT_DIV                    (GTYE3_CHANNEL_TXOUT_DIV                   ),
        .TXPCSRESET_TIME              (GTYE3_CHANNEL_TXPCSRESET_TIME             ),
        .TXPHDLY_CFG0                 (GTYE3_CHANNEL_TXPHDLY_CFG0                ),
        .TXPHDLY_CFG1                 (GTYE3_CHANNEL_TXPHDLY_CFG1                ),
        .TXPH_CFG                     (GTYE3_CHANNEL_TXPH_CFG                    ),
        .TXPH_CFG2                    (GTYE3_CHANNEL_TXPH_CFG2                   ),
        .TXPH_MONITOR_SEL             (GTYE3_CHANNEL_TXPH_MONITOR_SEL            ),
        .TXPI_CFG0                    (GTYE3_CHANNEL_TXPI_CFG0                   ),
        .TXPI_CFG1                    (GTYE3_CHANNEL_TXPI_CFG1                   ),
        .TXPI_CFG2                    (GTYE3_CHANNEL_TXPI_CFG2                   ),
        .TXPI_CFG3                    (GTYE3_CHANNEL_TXPI_CFG3                   ),
        .TXPI_CFG4                    (GTYE3_CHANNEL_TXPI_CFG4                   ),
        .TXPI_CFG5                    (GTYE3_CHANNEL_TXPI_CFG5                   ),
        .TXPI_GRAY_SEL                (GTYE3_CHANNEL_TXPI_GRAY_SEL               ),
        .TXPI_INVSTROBE_SEL           (GTYE3_CHANNEL_TXPI_INVSTROBE_SEL          ),
        .TXPI_LPM                     (GTYE3_CHANNEL_TXPI_LPM                    ),
        .TXPI_PPMCLK_SEL              (GTYE3_CHANNEL_TXPI_PPMCLK_SEL             ),
        .TXPI_PPM_CFG                 (GTYE3_CHANNEL_TXPI_PPM_CFG                ),
        .TXPI_RSV0                    (GTYE3_CHANNEL_TXPI_RSV0                   ),
        .TXPI_SYNFREQ_PPM             (GTYE3_CHANNEL_TXPI_SYNFREQ_PPM            ),
        .TXPI_VREFSEL                 (GTYE3_CHANNEL_TXPI_VREFSEL                ),
        .TXPMARESET_TIME              (GTYE3_CHANNEL_TXPMARESET_TIME             ),
        .TXSYNC_MULTILANE             (GTYE3_CHANNEL_TXSYNC_MULTILANE            ),
        .TXSYNC_OVRD                  (GTYE3_CHANNEL_TXSYNC_OVRD                 ),
        .TXSYNC_SKIP_DA               (GTYE3_CHANNEL_TXSYNC_SKIP_DA              ),
        .TX_CLK25_DIV                 (GTYE3_CHANNEL_TX_CLK25_DIV                ),
        .TX_CLKMUX_EN                 (GTYE3_CHANNEL_TX_CLKMUX_EN                ),
        .TX_CLKREG_PDB                (GTYE3_CHANNEL_TX_CLKREG_PDB               ),
        .TX_CLKREG_SET                (GTYE3_CHANNEL_TX_CLKREG_SET               ),
        .TX_DATA_WIDTH                (GTYE3_CHANNEL_TX_DATA_WIDTH               ),
        .TX_DCD_CFG                   (GTYE3_CHANNEL_TX_DCD_CFG                  ),
        .TX_DCD_EN                    (GTYE3_CHANNEL_TX_DCD_EN                   ),
        .TX_DEEMPH0                   (GTYE3_CHANNEL_TX_DEEMPH0                  ),
        .TX_DEEMPH1                   (GTYE3_CHANNEL_TX_DEEMPH1                  ),
        .TX_DIVRESET_TIME             (GTYE3_CHANNEL_TX_DIVRESET_TIME            ),
        .TX_DRIVE_MODE                (GTYE3_CHANNEL_TX_DRIVE_MODE               ),
        .TX_DRVMUX_CTRL               (GTYE3_CHANNEL_TX_DRVMUX_CTRL              ),
        .TX_EIDLE_ASSERT_DELAY        (GTYE3_CHANNEL_TX_EIDLE_ASSERT_DELAY       ),
        .TX_EIDLE_DEASSERT_DELAY      (GTYE3_CHANNEL_TX_EIDLE_DEASSERT_DELAY     ),
        .TX_EML_PHI_TUNE              (GTYE3_CHANNEL_TX_EML_PHI_TUNE             ),
        .TX_FABINT_USRCLK_FLOP        (GTYE3_CHANNEL_TX_FABINT_USRCLK_FLOP       ),
        .TX_FIFO_BYP_EN               (GTYE3_CHANNEL_TX_FIFO_BYP_EN              ),
        .TX_IDLE_DATA_ZERO            (GTYE3_CHANNEL_TX_IDLE_DATA_ZERO           ),
        .TX_INT_DATAWIDTH             (GTYE3_CHANNEL_TX_INT_DATAWIDTH            ),
        .TX_LOOPBACK_DRIVE_HIZ        (GTYE3_CHANNEL_TX_LOOPBACK_DRIVE_HIZ       ),
        .TX_MAINCURSOR_SEL            (GTYE3_CHANNEL_TX_MAINCURSOR_SEL           ),
        .TX_MARGIN_FULL_0             (GTYE3_CHANNEL_TX_MARGIN_FULL_0            ),
        .TX_MARGIN_FULL_1             (GTYE3_CHANNEL_TX_MARGIN_FULL_1            ),
        .TX_MARGIN_FULL_2             (GTYE3_CHANNEL_TX_MARGIN_FULL_2            ),
        .TX_MARGIN_FULL_3             (GTYE3_CHANNEL_TX_MARGIN_FULL_3            ),
        .TX_MARGIN_FULL_4             (GTYE3_CHANNEL_TX_MARGIN_FULL_4            ),
        .TX_MARGIN_LOW_0              (GTYE3_CHANNEL_TX_MARGIN_LOW_0             ),
        .TX_MARGIN_LOW_1              (GTYE3_CHANNEL_TX_MARGIN_LOW_1             ),
        .TX_MARGIN_LOW_2              (GTYE3_CHANNEL_TX_MARGIN_LOW_2             ),
        .TX_MARGIN_LOW_3              (GTYE3_CHANNEL_TX_MARGIN_LOW_3             ),
        .TX_MARGIN_LOW_4              (GTYE3_CHANNEL_TX_MARGIN_LOW_4             ),
        .TX_MODE_SEL                  (GTYE3_CHANNEL_TX_MODE_SEL                 ),
        .TX_PHICAL_CFG0               (GTYE3_CHANNEL_TX_PHICAL_CFG0              ),
        .TX_PHICAL_CFG1               (GTYE3_CHANNEL_TX_PHICAL_CFG1              ),
        .TX_PHICAL_CFG2               (GTYE3_CHANNEL_TX_PHICAL_CFG2              ),
        .TX_PI_BIASSET                (GTYE3_CHANNEL_TX_PI_BIASSET               ),
        .TX_PI_CFG0                   (GTYE3_CHANNEL_TX_PI_CFG0                  ),
        .TX_PI_CFG1                   (GTYE3_CHANNEL_TX_PI_CFG1                  ),
        .TX_PI_DIV2_MODE_B            (GTYE3_CHANNEL_TX_PI_DIV2_MODE_B           ),
        .TX_PI_SEL_QPLL0              (GTYE3_CHANNEL_TX_PI_SEL_QPLL0             ),
        .TX_PI_SEL_QPLL1              (GTYE3_CHANNEL_TX_PI_SEL_QPLL1             ),
        .TX_PMADATA_OPT               (GTYE3_CHANNEL_TX_PMADATA_OPT              ),
        .TX_PMA_POWER_SAVE            (GTYE3_CHANNEL_TX_PMA_POWER_SAVE           ),
        .TX_PREDRV_CTRL               (GTYE3_CHANNEL_TX_PREDRV_CTRL              ),
        .TX_PROGCLK_SEL               (GTYE3_CHANNEL_TX_PROGCLK_SEL              ),
        .TX_PROGDIV_CFG               (GTYE3_CHANNEL_TX_PROGDIV_CFG              ),
        .TX_PROGDIV_RATE              (GTYE3_CHANNEL_TX_PROGDIV_RATE             ),
        .TX_RXDETECT_CFG              (GTYE3_CHANNEL_TX_RXDETECT_CFG             ),
        .TX_RXDETECT_REF              (GTYE3_CHANNEL_TX_RXDETECT_REF             ),
        .TX_SAMPLE_PERIOD             (GTYE3_CHANNEL_TX_SAMPLE_PERIOD            ),
        .TX_SARC_LPBK_ENB             (GTYE3_CHANNEL_TX_SARC_LPBK_ENB            ),
        .TX_XCLK_SEL                  (GTYE3_CHANNEL_TX_XCLK_SEL                 ),
        .USE_PCS_CLK_PHASE_SEL        (GTYE3_CHANNEL_USE_PCS_CLK_PHASE_SEL       )
      ) GTYE3_CHANNEL_PRIM_INST (
        .CDRSTEPDIR                   (GTYE3_CHANNEL_CDRSTEPDIR_int          [((ch+1)*  1)-1:(ch*  1)]),
        .CDRSTEPSQ                    (GTYE3_CHANNEL_CDRSTEPSQ_int           [((ch+1)*  1)-1:(ch*  1)]),
        .CDRSTEPSX                    (GTYE3_CHANNEL_CDRSTEPSX_int           [((ch+1)*  1)-1:(ch*  1)]),
        .CFGRESET                     (GTYE3_CHANNEL_CFGRESET_int            [((ch+1)*  1)-1:(ch*  1)]),
        .CLKRSVD0                     (GTYE3_CHANNEL_CLKRSVD0_int            [((ch+1)*  1)-1:(ch*  1)]),
        .CLKRSVD1                     (GTYE3_CHANNEL_CLKRSVD1_int            [((ch+1)*  1)-1:(ch*  1)]),
        .CPLLLOCKDETCLK               (GTYE3_CHANNEL_CPLLLOCKDETCLK_int      [((ch+1)*  1)-1:(ch*  1)]),
        .CPLLLOCKEN                   (GTYE3_CHANNEL_CPLLLOCKEN_int          [((ch+1)*  1)-1:(ch*  1)]),
        .CPLLPD                       (GTYE3_CHANNEL_CPLLPD_int              [((ch+1)*  1)-1:(ch*  1)]),
        .CPLLREFCLKSEL                (GTYE3_CHANNEL_CPLLREFCLKSEL_int       [((ch+1)*  3)-1:(ch*  3)]),
        .CPLLRESET                    (GTYE3_CHANNEL_CPLLRESET_int           [((ch+1)*  1)-1:(ch*  1)]),
        .DMONFIFORESET                (GTYE3_CHANNEL_DMONFIFORESET_int       [((ch+1)*  1)-1:(ch*  1)]),
        .DMONITORCLK                  (GTYE3_CHANNEL_DMONITORCLK_int         [((ch+1)*  1)-1:(ch*  1)]),
        .DRPADDR                      (GTYE3_CHANNEL_DRPADDR_int             [((ch+1)* 10)-1:(ch* 10)]),
        .DRPCLK                       (GTYE3_CHANNEL_DRPCLK_int              [((ch+1)*  1)-1:(ch*  1)]),
        .DRPDI                        (GTYE3_CHANNEL_DRPDI_int               [((ch+1)* 16)-1:(ch* 16)]),
        .DRPEN                        (GTYE3_CHANNEL_DRPEN_int               [((ch+1)*  1)-1:(ch*  1)]),
        .DRPWE                        (GTYE3_CHANNEL_DRPWE_int               [((ch+1)*  1)-1:(ch*  1)]),
        .ELPCALDVORWREN               (GTYE3_CHANNEL_ELPCALDVORWREN_int      [((ch+1)*  1)-1:(ch*  1)]),
        .ELPCALPAORWREN               (GTYE3_CHANNEL_ELPCALPAORWREN_int      [((ch+1)*  1)-1:(ch*  1)]),
        .EVODDPHICALDONE              (GTYE3_CHANNEL_EVODDPHICALDONE_int     [((ch+1)*  1)-1:(ch*  1)]),
        .EVODDPHICALSTART             (GTYE3_CHANNEL_EVODDPHICALSTART_int    [((ch+1)*  1)-1:(ch*  1)]),
        .EVODDPHIDRDEN                (GTYE3_CHANNEL_EVODDPHIDRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .EVODDPHIDWREN                (GTYE3_CHANNEL_EVODDPHIDWREN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .EVODDPHIXRDEN                (GTYE3_CHANNEL_EVODDPHIXRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .EVODDPHIXWREN                (GTYE3_CHANNEL_EVODDPHIXWREN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .EYESCANMODE                  (GTYE3_CHANNEL_EYESCANMODE_int         [((ch+1)*  1)-1:(ch*  1)]),
        .EYESCANRESET                 (GTYE3_CHANNEL_EYESCANRESET_int        [((ch+1)*  1)-1:(ch*  1)]),
        .EYESCANTRIGGER               (GTYE3_CHANNEL_EYESCANTRIGGER_int      [((ch+1)*  1)-1:(ch*  1)]),
        .GTGREFCLK                    (GTYE3_CHANNEL_GTGREFCLK_int           [((ch+1)*  1)-1:(ch*  1)]),
        .GTNORTHREFCLK0               (GTYE3_CHANNEL_GTNORTHREFCLK0_int      [((ch+1)*  1)-1:(ch*  1)]),
        .GTNORTHREFCLK1               (GTYE3_CHANNEL_GTNORTHREFCLK1_int      [((ch+1)*  1)-1:(ch*  1)]),
        .GTREFCLK0                    (GTYE3_CHANNEL_GTREFCLK0_int           [((ch+1)*  1)-1:(ch*  1)]),
        .GTREFCLK1                    (GTYE3_CHANNEL_GTREFCLK1_int           [((ch+1)*  1)-1:(ch*  1)]),
        .GTRESETSEL                   (GTYE3_CHANNEL_GTRESETSEL_int          [((ch+1)*  1)-1:(ch*  1)]),
        .GTRSVD                       (GTYE3_CHANNEL_GTRSVD_int              [((ch+1)* 16)-1:(ch* 16)]),
        .GTRXRESET                    (GTYE3_CHANNEL_GTRXRESET_int           [((ch+1)*  1)-1:(ch*  1)]),
        .GTSOUTHREFCLK0               (GTYE3_CHANNEL_GTSOUTHREFCLK0_int      [((ch+1)*  1)-1:(ch*  1)]),
        .GTSOUTHREFCLK1               (GTYE3_CHANNEL_GTSOUTHREFCLK1_int      [((ch+1)*  1)-1:(ch*  1)]),
        .GTTXRESET                    (GTYE3_CHANNEL_GTTXRESET_int           [((ch+1)*  1)-1:(ch*  1)]),
        .GTYRXN                       (GTYE3_CHANNEL_GTYRXN_int              [((ch+1)*  1)-1:(ch*  1)]),
        .GTYRXP                       (GTYE3_CHANNEL_GTYRXP_int              [((ch+1)*  1)-1:(ch*  1)]),
        .LOOPBACK                     (GTYE3_CHANNEL_LOOPBACK_int            [((ch+1)*  3)-1:(ch*  3)]),
        .LOOPRSVD                     (GTYE3_CHANNEL_LOOPRSVD_int            [((ch+1)* 16)-1:(ch* 16)]),
        .LPBKRXTXSEREN                (GTYE3_CHANNEL_LPBKRXTXSEREN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .LPBKTXRXSEREN                (GTYE3_CHANNEL_LPBKTXRXSEREN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .PCIEEQRXEQADAPTDONE          (GTYE3_CHANNEL_PCIEEQRXEQADAPTDONE_int [((ch+1)*  1)-1:(ch*  1)]),
        .PCIERSTIDLE                  (GTYE3_CHANNEL_PCIERSTIDLE_int         [((ch+1)*  1)-1:(ch*  1)]),
        .PCIERSTTXSYNCSTART           (GTYE3_CHANNEL_PCIERSTTXSYNCSTART_int  [((ch+1)*  1)-1:(ch*  1)]),
        .PCIEUSERRATEDONE             (GTYE3_CHANNEL_PCIEUSERRATEDONE_int    [((ch+1)*  1)-1:(ch*  1)]),
        .PCSRSVDIN                    (GTYE3_CHANNEL_PCSRSVDIN_int           [((ch+1)* 16)-1:(ch* 16)]),
        .PCSRSVDIN2                   (GTYE3_CHANNEL_PCSRSVDIN2_int          [((ch+1)*  5)-1:(ch*  5)]),
        .PMARSVDIN                    (GTYE3_CHANNEL_PMARSVDIN_int           [((ch+1)*  5)-1:(ch*  5)]),
        .QPLL0CLK                     (GTYE3_CHANNEL_QPLL0CLK_int            [((ch+1)*  1)-1:(ch*  1)]),
        .QPLL0REFCLK                  (GTYE3_CHANNEL_QPLL0REFCLK_int         [((ch+1)*  1)-1:(ch*  1)]),
        .QPLL1CLK                     (GTYE3_CHANNEL_QPLL1CLK_int            [((ch+1)*  1)-1:(ch*  1)]),
        .QPLL1REFCLK                  (GTYE3_CHANNEL_QPLL1REFCLK_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RESETOVRD                    (GTYE3_CHANNEL_RESETOVRD_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RSTCLKENTX                   (GTYE3_CHANNEL_RSTCLKENTX_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RX8B10BEN                    (GTYE3_CHANNEL_RX8B10BEN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXBUFRESET                   (GTYE3_CHANNEL_RXBUFRESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDRFREQRESET               (GTYE3_CHANNEL_RXCDRFREQRESET_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDRHOLD                    (GTYE3_CHANNEL_RXCDRHOLD_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDROVRDEN                  (GTYE3_CHANNEL_RXCDROVRDEN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDRRESET                   (GTYE3_CHANNEL_RXCDRRESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDRRESETRSV                (GTYE3_CHANNEL_RXCDRRESETRSV_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHBONDEN                   (GTYE3_CHANNEL_RXCHBONDEN_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHBONDI                    (GTYE3_CHANNEL_RXCHBONDI_int           [((ch+1)*  5)-1:(ch*  5)]),
        .RXCHBONDLEVEL                (GTYE3_CHANNEL_RXCHBONDLEVEL_int       [((ch+1)*  3)-1:(ch*  3)]),
        .RXCHBONDMASTER               (GTYE3_CHANNEL_RXCHBONDMASTER_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHBONDSLAVE                (GTYE3_CHANNEL_RXCHBONDSLAVE_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXCKCALRESET                 (GTYE3_CHANNEL_RXCKCALRESET_int        [((ch+1)*  1)-1:(ch*  1)]),
        .RXCOMMADETEN                 (GTYE3_CHANNEL_RXCOMMADETEN_int        [((ch+1)*  1)-1:(ch*  1)]),
        .RXDCCFORCESTART              (GTYE3_CHANNEL_RXDCCFORCESTART_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEAGCHOLD                 (GTYE3_CHANNEL_RXDFEAGCHOLD_int        [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEAGCOVRDEN               (GTYE3_CHANNEL_RXDFEAGCOVRDEN_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFELFHOLD                  (GTYE3_CHANNEL_RXDFELFHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFELFOVRDEN                (GTYE3_CHANNEL_RXDFELFOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFELPMRESET                (GTYE3_CHANNEL_RXDFELPMRESET_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP10HOLD               (GTYE3_CHANNEL_RXDFETAP10HOLD_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP10OVRDEN             (GTYE3_CHANNEL_RXDFETAP10OVRDEN_int    [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP11HOLD               (GTYE3_CHANNEL_RXDFETAP11HOLD_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP11OVRDEN             (GTYE3_CHANNEL_RXDFETAP11OVRDEN_int    [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP12HOLD               (GTYE3_CHANNEL_RXDFETAP12HOLD_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP12OVRDEN             (GTYE3_CHANNEL_RXDFETAP12OVRDEN_int    [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP13HOLD               (GTYE3_CHANNEL_RXDFETAP13HOLD_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP13OVRDEN             (GTYE3_CHANNEL_RXDFETAP13OVRDEN_int    [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP14HOLD               (GTYE3_CHANNEL_RXDFETAP14HOLD_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP14OVRDEN             (GTYE3_CHANNEL_RXDFETAP14OVRDEN_int    [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP15HOLD               (GTYE3_CHANNEL_RXDFETAP15HOLD_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP15OVRDEN             (GTYE3_CHANNEL_RXDFETAP15OVRDEN_int    [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP2HOLD                (GTYE3_CHANNEL_RXDFETAP2HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP2OVRDEN              (GTYE3_CHANNEL_RXDFETAP2OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP3HOLD                (GTYE3_CHANNEL_RXDFETAP3HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP3OVRDEN              (GTYE3_CHANNEL_RXDFETAP3OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP4HOLD                (GTYE3_CHANNEL_RXDFETAP4HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP4OVRDEN              (GTYE3_CHANNEL_RXDFETAP4OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP5HOLD                (GTYE3_CHANNEL_RXDFETAP5HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP5OVRDEN              (GTYE3_CHANNEL_RXDFETAP5OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP6HOLD                (GTYE3_CHANNEL_RXDFETAP6HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP6OVRDEN              (GTYE3_CHANNEL_RXDFETAP6OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP7HOLD                (GTYE3_CHANNEL_RXDFETAP7HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP7OVRDEN              (GTYE3_CHANNEL_RXDFETAP7OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP8HOLD                (GTYE3_CHANNEL_RXDFETAP8HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP8OVRDEN              (GTYE3_CHANNEL_RXDFETAP8OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP9HOLD                (GTYE3_CHANNEL_RXDFETAP9HOLD_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFETAP9OVRDEN              (GTYE3_CHANNEL_RXDFETAP9OVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEUTHOLD                  (GTYE3_CHANNEL_RXDFEUTHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEUTOVRDEN                (GTYE3_CHANNEL_RXDFEUTOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEVPHOLD                  (GTYE3_CHANNEL_RXDFEVPHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEVPOVRDEN                (GTYE3_CHANNEL_RXDFEVPOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEVSEN                    (GTYE3_CHANNEL_RXDFEVSEN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXDFEXYDEN                   (GTYE3_CHANNEL_RXDFEXYDEN_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXDLYBYPASS                  (GTYE3_CHANNEL_RXDLYBYPASS_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXDLYEN                      (GTYE3_CHANNEL_RXDLYEN_int             [((ch+1)*  1)-1:(ch*  1)]),
        .RXDLYOVRDEN                  (GTYE3_CHANNEL_RXDLYOVRDEN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXDLYSRESET                  (GTYE3_CHANNEL_RXDLYSRESET_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXELECIDLEMODE               (GTYE3_CHANNEL_RXELECIDLEMODE_int      [((ch+1)*  2)-1:(ch*  2)]),
        .RXGEARBOXSLIP                (GTYE3_CHANNEL_RXGEARBOXSLIP_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXLATCLK                     (GTYE3_CHANNEL_RXLATCLK_int            [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMEN                      (GTYE3_CHANNEL_RXLPMEN_int             [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMGCHOLD                  (GTYE3_CHANNEL_RXLPMGCHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMGCOVRDEN                (GTYE3_CHANNEL_RXLPMGCOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMHFHOLD                  (GTYE3_CHANNEL_RXLPMHFHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMHFOVRDEN                (GTYE3_CHANNEL_RXLPMHFOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMLFHOLD                  (GTYE3_CHANNEL_RXLPMLFHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMLFKLOVRDEN              (GTYE3_CHANNEL_RXLPMLFKLOVRDEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMOSHOLD                  (GTYE3_CHANNEL_RXLPMOSHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXLPMOSOVRDEN                (GTYE3_CHANNEL_RXLPMOSOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXMCOMMAALIGNEN              (GTYE3_CHANNEL_RXMCOMMAALIGNEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXMONITORSEL                 (GTYE3_CHANNEL_RXMONITORSEL_int        [((ch+1)*  2)-1:(ch*  2)]),
        .RXOOBRESET                   (GTYE3_CHANNEL_RXOOBRESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSCALRESET                 (GTYE3_CHANNEL_RXOSCALRESET_int        [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSHOLD                     (GTYE3_CHANNEL_RXOSHOLD_int            [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTCFG                   (GTYE3_CHANNEL_RXOSINTCFG_int          [((ch+1)*  4)-1:(ch*  4)]),
        .RXOSINTEN                    (GTYE3_CHANNEL_RXOSINTEN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTHOLD                  (GTYE3_CHANNEL_RXOSINTHOLD_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTOVRDEN                (GTYE3_CHANNEL_RXOSINTOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTSTROBE                (GTYE3_CHANNEL_RXOSINTSTROBE_int       [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTTESTOVRDEN            (GTYE3_CHANNEL_RXOSINTTESTOVRDEN_int   [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSOVRDEN                   (GTYE3_CHANNEL_RXOSOVRDEN_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXOUTCLKSEL                  (GTYE3_CHANNEL_RXOUTCLKSEL_int         [((ch+1)*  3)-1:(ch*  3)]),
        .RXPCOMMAALIGNEN              (GTYE3_CHANNEL_RXPCOMMAALIGNEN_int     [((ch+1)*  1)-1:(ch*  1)]),
        .RXPCSRESET                   (GTYE3_CHANNEL_RXPCSRESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXPD                         (GTYE3_CHANNEL_RXPD_int                [((ch+1)*  2)-1:(ch*  2)]),
        .RXPHALIGN                    (GTYE3_CHANNEL_RXPHALIGN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXPHALIGNEN                  (GTYE3_CHANNEL_RXPHALIGNEN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXPHDLYPD                    (GTYE3_CHANNEL_RXPHDLYPD_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXPHDLYRESET                 (GTYE3_CHANNEL_RXPHDLYRESET_int        [((ch+1)*  1)-1:(ch*  1)]),
        .RXPHOVRDEN                   (GTYE3_CHANNEL_RXPHOVRDEN_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXPLLCLKSEL                  (GTYE3_CHANNEL_RXPLLCLKSEL_int         [((ch+1)*  2)-1:(ch*  2)]),
        .RXPMARESET                   (GTYE3_CHANNEL_RXPMARESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXPOLARITY                   (GTYE3_CHANNEL_RXPOLARITY_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXPRBSCNTRESET               (GTYE3_CHANNEL_RXPRBSCNTRESET_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXPRBSSEL                    (GTYE3_CHANNEL_RXPRBSSEL_int           [((ch+1)*  4)-1:(ch*  4)]),
        .RXPROGDIVRESET               (GTYE3_CHANNEL_RXPROGDIVRESET_int      [((ch+1)*  1)-1:(ch*  1)]),
        .RXRATE                       (GTYE3_CHANNEL_RXRATE_int              [((ch+1)*  3)-1:(ch*  3)]),
        .RXRATEMODE                   (GTYE3_CHANNEL_RXRATEMODE_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIDE                      (GTYE3_CHANNEL_RXSLIDE_int             [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIPOUTCLK                 (GTYE3_CHANNEL_RXSLIPOUTCLK_int        [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIPPMA                    (GTYE3_CHANNEL_RXSLIPPMA_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXSYNCALLIN                  (GTYE3_CHANNEL_RXSYNCALLIN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .RXSYNCIN                     (GTYE3_CHANNEL_RXSYNCIN_int            [((ch+1)*  1)-1:(ch*  1)]),
        .RXSYNCMODE                   (GTYE3_CHANNEL_RXSYNCMODE_int          [((ch+1)*  1)-1:(ch*  1)]),
        .RXSYSCLKSEL                  (GTYE3_CHANNEL_RXSYSCLKSEL_int         [((ch+1)*  2)-1:(ch*  2)]),
        .RXUSERRDY                    (GTYE3_CHANNEL_RXUSERRDY_int           [((ch+1)*  1)-1:(ch*  1)]),
        .RXUSRCLK                     (GTYE3_CHANNEL_RXUSRCLK_int            [((ch+1)*  1)-1:(ch*  1)]),
        .RXUSRCLK2                    (GTYE3_CHANNEL_RXUSRCLK2_int           [((ch+1)*  1)-1:(ch*  1)]),
        .SIGVALIDCLK                  (GTYE3_CHANNEL_SIGVALIDCLK_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TSTIN                        (GTYE3_CHANNEL_TSTIN_int               [((ch+1)* 20)-1:(ch* 20)]),
        .TX8B10BBYPASS                (GTYE3_CHANNEL_TX8B10BBYPASS_int       [((ch+1)*  8)-1:(ch*  8)]),
        .TX8B10BEN                    (GTYE3_CHANNEL_TX8B10BEN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXBUFDIFFCTRL                (GTYE3_CHANNEL_TXBUFDIFFCTRL_int       [((ch+1)*  3)-1:(ch*  3)]),
        .TXCOMINIT                    (GTYE3_CHANNEL_TXCOMINIT_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXCOMSAS                     (GTYE3_CHANNEL_TXCOMSAS_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXCOMWAKE                    (GTYE3_CHANNEL_TXCOMWAKE_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXCTRL0                      (GTYE3_CHANNEL_TXCTRL0_int             [((ch+1)* 16)-1:(ch* 16)]),
        .TXCTRL1                      (GTYE3_CHANNEL_TXCTRL1_int             [((ch+1)* 16)-1:(ch* 16)]),
        .TXCTRL2                      (GTYE3_CHANNEL_TXCTRL2_int             [((ch+1)*  8)-1:(ch*  8)]),
        .TXDATA                       (GTYE3_CHANNEL_TXDATA_int              [((ch+1)*128)-1:(ch*128)]),
        .TXDATAEXTENDRSVD             (GTYE3_CHANNEL_TXDATAEXTENDRSVD_int    [((ch+1)*  8)-1:(ch*  8)]),
        .TXDCCFORCESTART              (GTYE3_CHANNEL_TXDCCFORCESTART_int     [((ch+1)*  1)-1:(ch*  1)]),
        .TXDCCRESET                   (GTYE3_CHANNEL_TXDCCRESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXDEEMPH                     (GTYE3_CHANNEL_TXDEEMPH_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXDETECTRX                   (GTYE3_CHANNEL_TXDETECTRX_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXDIFFCTRL                   (GTYE3_CHANNEL_TXDIFFCTRL_int          [((ch+1)*  5)-1:(ch*  5)]),
        .TXDIFFPD                     (GTYE3_CHANNEL_TXDIFFPD_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYBYPASS                  (GTYE3_CHANNEL_TXDLYBYPASS_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYEN                      (GTYE3_CHANNEL_TXDLYEN_int             [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYHOLD                    (GTYE3_CHANNEL_TXDLYHOLD_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYOVRDEN                  (GTYE3_CHANNEL_TXDLYOVRDEN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYSRESET                  (GTYE3_CHANNEL_TXDLYSRESET_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYUPDOWN                  (GTYE3_CHANNEL_TXDLYUPDOWN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TXELECIDLE                   (GTYE3_CHANNEL_TXELECIDLE_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXELFORCESTART               (GTYE3_CHANNEL_TXELFORCESTART_int      [((ch+1)*  1)-1:(ch*  1)]),
        .TXHEADER                     (GTYE3_CHANNEL_TXHEADER_int            [((ch+1)*  6)-1:(ch*  6)]),
        .TXINHIBIT                    (GTYE3_CHANNEL_TXINHIBIT_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXLATCLK                     (GTYE3_CHANNEL_TXLATCLK_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXMAINCURSOR                 (GTYE3_CHANNEL_TXMAINCURSOR_int        [((ch+1)*  7)-1:(ch*  7)]),
        .TXMARGIN                     (GTYE3_CHANNEL_TXMARGIN_int            [((ch+1)*  3)-1:(ch*  3)]),
        .TXOUTCLKSEL                  (GTYE3_CHANNEL_TXOUTCLKSEL_int         [((ch+1)*  3)-1:(ch*  3)]),
        .TXPCSRESET                   (GTYE3_CHANNEL_TXPCSRESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXPD                         (GTYE3_CHANNEL_TXPD_int                [((ch+1)*  2)-1:(ch*  2)]),
        .TXPDELECIDLEMODE             (GTYE3_CHANNEL_TXPDELECIDLEMODE_int    [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHALIGN                    (GTYE3_CHANNEL_TXPHALIGN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHALIGNEN                  (GTYE3_CHANNEL_TXPHALIGNEN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHDLYPD                    (GTYE3_CHANNEL_TXPHDLYPD_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHDLYRESET                 (GTYE3_CHANNEL_TXPHDLYRESET_int        [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHDLYTSTCLK                (GTYE3_CHANNEL_TXPHDLYTSTCLK_int       [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHINIT                     (GTYE3_CHANNEL_TXPHINIT_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHOVRDEN                   (GTYE3_CHANNEL_TXPHOVRDEN_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXPIPPMEN                    (GTYE3_CHANNEL_TXPIPPMEN_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXPIPPMOVRDEN                (GTYE3_CHANNEL_TXPIPPMOVRDEN_int       [((ch+1)*  1)-1:(ch*  1)]),
        .TXPIPPMPD                    (GTYE3_CHANNEL_TXPIPPMPD_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXPIPPMSEL                   (GTYE3_CHANNEL_TXPIPPMSEL_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXPIPPMSTEPSIZE              (GTYE3_CHANNEL_TXPIPPMSTEPSIZE_int     [((ch+1)*  5)-1:(ch*  5)]),
        .TXPISOPD                     (GTYE3_CHANNEL_TXPISOPD_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXPLLCLKSEL                  (GTYE3_CHANNEL_TXPLLCLKSEL_int         [((ch+1)*  2)-1:(ch*  2)]),
        .TXPMARESET                   (GTYE3_CHANNEL_TXPMARESET_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXPOLARITY                   (GTYE3_CHANNEL_TXPOLARITY_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXPOSTCURSOR                 (GTYE3_CHANNEL_TXPOSTCURSOR_int        [((ch+1)*  5)-1:(ch*  5)]),
        .TXPRBSFORCEERR               (GTYE3_CHANNEL_TXPRBSFORCEERR_int      [((ch+1)*  1)-1:(ch*  1)]),
        .TXPRBSSEL                    (GTYE3_CHANNEL_TXPRBSSEL_int           [((ch+1)*  4)-1:(ch*  4)]),
        .TXPRECURSOR                  (GTYE3_CHANNEL_TXPRECURSOR_int         [((ch+1)*  5)-1:(ch*  5)]),
        .TXPROGDIVRESET               (GTYE3_CHANNEL_TXPROGDIVRESET_int      [((ch+1)*  1)-1:(ch*  1)]),
        .TXRATE                       (GTYE3_CHANNEL_TXRATE_int              [((ch+1)*  3)-1:(ch*  3)]),
        .TXRATEMODE                   (GTYE3_CHANNEL_TXRATEMODE_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXSEQUENCE                   (GTYE3_CHANNEL_TXSEQUENCE_int          [((ch+1)*  7)-1:(ch*  7)]),
        .TXSWING                      (GTYE3_CHANNEL_TXSWING_int             [((ch+1)*  1)-1:(ch*  1)]),
        .TXSYNCALLIN                  (GTYE3_CHANNEL_TXSYNCALLIN_int         [((ch+1)*  1)-1:(ch*  1)]),
        .TXSYNCIN                     (GTYE3_CHANNEL_TXSYNCIN_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXSYNCMODE                   (GTYE3_CHANNEL_TXSYNCMODE_int          [((ch+1)*  1)-1:(ch*  1)]),
        .TXSYSCLKSEL                  (GTYE3_CHANNEL_TXSYSCLKSEL_int         [((ch+1)*  2)-1:(ch*  2)]),
        .TXUSERRDY                    (GTYE3_CHANNEL_TXUSERRDY_int           [((ch+1)*  1)-1:(ch*  1)]),
        .TXUSRCLK                     (GTYE3_CHANNEL_TXUSRCLK_int            [((ch+1)*  1)-1:(ch*  1)]),
        .TXUSRCLK2                    (GTYE3_CHANNEL_TXUSRCLK2_int           [((ch+1)*  1)-1:(ch*  1)]),

        .BUFGTCE                      (GTYE3_CHANNEL_BUFGTCE                 [((ch+1)*  3)-1:(ch*  3)]),
        .BUFGTCEMASK                  (GTYE3_CHANNEL_BUFGTCEMASK             [((ch+1)*  3)-1:(ch*  3)]),
        .BUFGTDIV                     (GTYE3_CHANNEL_BUFGTDIV                [((ch+1)*  9)-1:(ch*  9)]),
        .BUFGTRESET                   (GTYE3_CHANNEL_BUFGTRESET              [((ch+1)*  3)-1:(ch*  3)]),
        .BUFGTRSTMASK                 (GTYE3_CHANNEL_BUFGTRSTMASK            [((ch+1)*  3)-1:(ch*  3)]),
        .CPLLFBCLKLOST                (GTYE3_CHANNEL_CPLLFBCLKLOST           [((ch+1)*  1)-1:(ch*  1)]),
        .CPLLLOCK                     (GTYE3_CHANNEL_CPLLLOCK                [((ch+1)*  1)-1:(ch*  1)]),
        .CPLLREFCLKLOST               (GTYE3_CHANNEL_CPLLREFCLKLOST          [((ch+1)*  1)-1:(ch*  1)]),
        .DMONITOROUT                  (GTYE3_CHANNEL_DMONITOROUT             [((ch+1)* 17)-1:(ch* 17)]),
        .DRPDO                        (GTYE3_CHANNEL_DRPDO                   [((ch+1)* 16)-1:(ch* 16)]),
        .DRPRDY                       (GTYE3_CHANNEL_DRPRDY                  [((ch+1)*  1)-1:(ch*  1)]),
        .EYESCANDATAERROR             (GTYE3_CHANNEL_EYESCANDATAERROR        [((ch+1)*  1)-1:(ch*  1)]),
        .GTPOWERGOOD                  (GTYE3_CHANNEL_GTPOWERGOOD             [((ch+1)*  1)-1:(ch*  1)]),
        .GTREFCLKMONITOR              (GTYE3_CHANNEL_GTREFCLKMONITOR         [((ch+1)*  1)-1:(ch*  1)]),
        .GTYTXN                       (GTYE3_CHANNEL_GTYTXN                  [((ch+1)*  1)-1:(ch*  1)]),
        .GTYTXP                       (GTYE3_CHANNEL_GTYTXP                  [((ch+1)*  1)-1:(ch*  1)]),
        .PCIERATEGEN3                 (GTYE3_CHANNEL_PCIERATEGEN3            [((ch+1)*  1)-1:(ch*  1)]),
        .PCIERATEIDLE                 (GTYE3_CHANNEL_PCIERATEIDLE            [((ch+1)*  1)-1:(ch*  1)]),
        .PCIERATEQPLLPD               (GTYE3_CHANNEL_PCIERATEQPLLPD          [((ch+1)*  2)-1:(ch*  2)]),
        .PCIERATEQPLLRESET            (GTYE3_CHANNEL_PCIERATEQPLLRESET       [((ch+1)*  2)-1:(ch*  2)]),
        .PCIESYNCTXSYNCDONE           (GTYE3_CHANNEL_PCIESYNCTXSYNCDONE      [((ch+1)*  1)-1:(ch*  1)]),
        .PCIEUSERGEN3RDY              (GTYE3_CHANNEL_PCIEUSERGEN3RDY         [((ch+1)*  1)-1:(ch*  1)]),
        .PCIEUSERPHYSTATUSRST         (GTYE3_CHANNEL_PCIEUSERPHYSTATUSRST    [((ch+1)*  1)-1:(ch*  1)]),
        .PCIEUSERRATESTART            (GTYE3_CHANNEL_PCIEUSERRATESTART       [((ch+1)*  1)-1:(ch*  1)]),
        .PCSRSVDOUT                   (GTYE3_CHANNEL_PCSRSVDOUT              [((ch+1)* 16)-1:(ch* 16)]),
        .PHYSTATUS                    (GTYE3_CHANNEL_PHYSTATUS               [((ch+1)*  1)-1:(ch*  1)]),
        .PINRSRVDAS                   (GTYE3_CHANNEL_PINRSRVDAS              [((ch+1)*  8)-1:(ch*  8)]),
        .RESETEXCEPTION               (GTYE3_CHANNEL_RESETEXCEPTION          [((ch+1)*  1)-1:(ch*  1)]),
        .RXBUFSTATUS                  (GTYE3_CHANNEL_RXBUFSTATUS             [((ch+1)*  3)-1:(ch*  3)]),
        .RXBYTEISALIGNED              (GTYE3_CHANNEL_RXBYTEISALIGNED         [((ch+1)*  1)-1:(ch*  1)]),
        .RXBYTEREALIGN                (GTYE3_CHANNEL_RXBYTEREALIGN           [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDRLOCK                    (GTYE3_CHANNEL_RXCDRLOCK               [((ch+1)*  1)-1:(ch*  1)]),
        .RXCDRPHDONE                  (GTYE3_CHANNEL_RXCDRPHDONE             [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHANBONDSEQ                (GTYE3_CHANNEL_RXCHANBONDSEQ           [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHANISALIGNED              (GTYE3_CHANNEL_RXCHANISALIGNED         [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHANREALIGN                (GTYE3_CHANNEL_RXCHANREALIGN           [((ch+1)*  1)-1:(ch*  1)]),
        .RXCHBONDO                    (GTYE3_CHANNEL_RXCHBONDO               [((ch+1)*  5)-1:(ch*  5)]),
        .RXCKCALDONE                  (GTYE3_CHANNEL_RXCKCALDONE             [((ch+1)*  1)-1:(ch*  1)]),
        .RXCLKCORCNT                  (GTYE3_CHANNEL_RXCLKCORCNT             [((ch+1)*  2)-1:(ch*  2)]),
        .RXCOMINITDET                 (GTYE3_CHANNEL_RXCOMINITDET            [((ch+1)*  1)-1:(ch*  1)]),
        .RXCOMMADET                   (GTYE3_CHANNEL_RXCOMMADET              [((ch+1)*  1)-1:(ch*  1)]),
        .RXCOMSASDET                  (GTYE3_CHANNEL_RXCOMSASDET             [((ch+1)*  1)-1:(ch*  1)]),
        .RXCOMWAKEDET                 (GTYE3_CHANNEL_RXCOMWAKEDET            [((ch+1)*  1)-1:(ch*  1)]),
        .RXCTRL0                      (GTYE3_CHANNEL_RXCTRL0                 [((ch+1)* 16)-1:(ch* 16)]),
        .RXCTRL1                      (GTYE3_CHANNEL_RXCTRL1                 [((ch+1)* 16)-1:(ch* 16)]),
        .RXCTRL2                      (GTYE3_CHANNEL_RXCTRL2                 [((ch+1)*  8)-1:(ch*  8)]),
        .RXCTRL3                      (GTYE3_CHANNEL_RXCTRL3                 [((ch+1)*  8)-1:(ch*  8)]),
        .RXDATA                       (GTYE3_CHANNEL_RXDATA                  [((ch+1)*128)-1:(ch*128)]),
        .RXDATAEXTENDRSVD             (GTYE3_CHANNEL_RXDATAEXTENDRSVD        [((ch+1)*  8)-1:(ch*  8)]),
        .RXDATAVALID                  (GTYE3_CHANNEL_RXDATAVALID             [((ch+1)*  2)-1:(ch*  2)]),
        .RXDLYSRESETDONE              (GTYE3_CHANNEL_RXDLYSRESETDONE         [((ch+1)*  1)-1:(ch*  1)]),
        .RXELECIDLE                   (GTYE3_CHANNEL_RXELECIDLE              [((ch+1)*  1)-1:(ch*  1)]),
        .RXHEADER                     (GTYE3_CHANNEL_RXHEADER                [((ch+1)*  6)-1:(ch*  6)]),
        .RXHEADERVALID                (GTYE3_CHANNEL_RXHEADERVALID           [((ch+1)*  2)-1:(ch*  2)]),
        .RXMONITOROUT                 (GTYE3_CHANNEL_RXMONITOROUT            [((ch+1)*  7)-1:(ch*  7)]),
        .RXOSINTDONE                  (GTYE3_CHANNEL_RXOSINTDONE             [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTSTARTED               (GTYE3_CHANNEL_RXOSINTSTARTED          [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTSTROBEDONE            (GTYE3_CHANNEL_RXOSINTSTROBEDONE       [((ch+1)*  1)-1:(ch*  1)]),
        .RXOSINTSTROBESTARTED         (GTYE3_CHANNEL_RXOSINTSTROBESTARTED    [((ch+1)*  1)-1:(ch*  1)]),
        .RXOUTCLK                     (GTYE3_CHANNEL_RXOUTCLK                [((ch+1)*  1)-1:(ch*  1)]),
        .RXOUTCLKFABRIC               (GTYE3_CHANNEL_RXOUTCLKFABRIC          [((ch+1)*  1)-1:(ch*  1)]),
        .RXOUTCLKPCS                  (GTYE3_CHANNEL_RXOUTCLKPCS             [((ch+1)*  1)-1:(ch*  1)]),
        .RXPHALIGNDONE                (GTYE3_CHANNEL_RXPHALIGNDONE           [((ch+1)*  1)-1:(ch*  1)]),
        .RXPHALIGNERR                 (GTYE3_CHANNEL_RXPHALIGNERR            [((ch+1)*  1)-1:(ch*  1)]),
        .RXPMARESETDONE               (GTYE3_CHANNEL_RXPMARESETDONE          [((ch+1)*  1)-1:(ch*  1)]),
        .RXPRBSERR                    (GTYE3_CHANNEL_RXPRBSERR               [((ch+1)*  1)-1:(ch*  1)]),
        .RXPRBSLOCKED                 (GTYE3_CHANNEL_RXPRBSLOCKED            [((ch+1)*  1)-1:(ch*  1)]),
        .RXPRGDIVRESETDONE            (GTYE3_CHANNEL_RXPRGDIVRESETDONE       [((ch+1)*  1)-1:(ch*  1)]),
        .RXRATEDONE                   (GTYE3_CHANNEL_RXRATEDONE              [((ch+1)*  1)-1:(ch*  1)]),
        .RXRECCLKOUT                  (GTYE3_CHANNEL_RXRECCLKOUT             [((ch+1)*  1)-1:(ch*  1)]),
        .RXRESETDONE                  (GTYE3_CHANNEL_RXRESETDONE             [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIDERDY                   (GTYE3_CHANNEL_RXSLIDERDY              [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIPDONE                   (GTYE3_CHANNEL_RXSLIPDONE              [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIPOUTCLKRDY              (GTYE3_CHANNEL_RXSLIPOUTCLKRDY         [((ch+1)*  1)-1:(ch*  1)]),
        .RXSLIPPMARDY                 (GTYE3_CHANNEL_RXSLIPPMARDY            [((ch+1)*  1)-1:(ch*  1)]),
        .RXSTARTOFSEQ                 (GTYE3_CHANNEL_RXSTARTOFSEQ            [((ch+1)*  2)-1:(ch*  2)]),
        .RXSTATUS                     (GTYE3_CHANNEL_RXSTATUS                [((ch+1)*  3)-1:(ch*  3)]),
        .RXSYNCDONE                   (GTYE3_CHANNEL_RXSYNCDONE              [((ch+1)*  1)-1:(ch*  1)]),
        .RXSYNCOUT                    (GTYE3_CHANNEL_RXSYNCOUT               [((ch+1)*  1)-1:(ch*  1)]),
        .RXVALID                      (GTYE3_CHANNEL_RXVALID                 [((ch+1)*  1)-1:(ch*  1)]),
        .TXBUFSTATUS                  (GTYE3_CHANNEL_TXBUFSTATUS             [((ch+1)*  2)-1:(ch*  2)]),
        .TXCOMFINISH                  (GTYE3_CHANNEL_TXCOMFINISH             [((ch+1)*  1)-1:(ch*  1)]),
        .TXDCCDONE                    (GTYE3_CHANNEL_TXDCCDONE               [((ch+1)*  1)-1:(ch*  1)]),
        .TXDLYSRESETDONE              (GTYE3_CHANNEL_TXDLYSRESETDONE         [((ch+1)*  1)-1:(ch*  1)]),
        .TXOUTCLK                     (GTYE3_CHANNEL_TXOUTCLK                [((ch+1)*  1)-1:(ch*  1)]),
        .TXOUTCLKFABRIC               (GTYE3_CHANNEL_TXOUTCLKFABRIC          [((ch+1)*  1)-1:(ch*  1)]),
        .TXOUTCLKPCS                  (GTYE3_CHANNEL_TXOUTCLKPCS             [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHALIGNDONE                (GTYE3_CHANNEL_TXPHALIGNDONE           [((ch+1)*  1)-1:(ch*  1)]),
        .TXPHINITDONE                 (GTYE3_CHANNEL_TXPHINITDONE            [((ch+1)*  1)-1:(ch*  1)]),
        .TXPMARESETDONE               (GTYE3_CHANNEL_TXPMARESETDONE          [((ch+1)*  1)-1:(ch*  1)]),
        .TXPRGDIVRESETDONE            (GTYE3_CHANNEL_TXPRGDIVRESETDONE       [((ch+1)*  1)-1:(ch*  1)]),
        .TXRATEDONE                   (GTYE3_CHANNEL_TXRATEDONE              [((ch+1)*  1)-1:(ch*  1)]),
        .TXRESETDONE                  (GTYE3_CHANNEL_TXRESETDONE             [((ch+1)*  1)-1:(ch*  1)]),
        .TXSYNCDONE                   (GTYE3_CHANNEL_TXSYNCDONE              [((ch+1)*  1)-1:(ch*  1)]),
        .TXSYNCOUT                    (GTYE3_CHANNEL_TXSYNCOUT               [((ch+1)*  1)-1:(ch*  1)])
      );
    end

  end
  endgenerate


endmodule
