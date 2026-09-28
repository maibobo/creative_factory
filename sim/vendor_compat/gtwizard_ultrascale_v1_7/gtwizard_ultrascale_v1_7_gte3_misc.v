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

module gtwizard_ultrascale_v1_7_9_gte3_misc #(


  // -------------------------------------------------------------------------------------------------------------------
  // Parameters relating to IBUFDS_GTE3 primitive
  // -------------------------------------------------------------------------------------------------------------------

  // primitive wrapper parameters which override corresponding IBUFDS_GTE3 primitive parameters
  parameter [0:0] GTE3_IBUFDS_REFCLK_EN_TX_PATH   = 1'b0,
  parameter [1:0] GTE3_IBUFDS_REFCLK_HROW_CK_SEL  = 2'b00,
  parameter [1:0] GTE3_IBUFDS_REFCLK_ICNTL_RX     = 2'b00,

  // primitive wrapper parameters which specify IBUFDS_GTE3 primitive input port default driver values
  parameter [0:0] GTE3_IBUFDS_CEB_VAL = 1'b0,
  parameter [0:0] GTE3_IBUFDS_I_VAL   = 1'b0,
  parameter [0:0] GTE3_IBUFDS_IB_VAL  = 1'b0,

  // primitive wrapper parameters which control IBUFDS_GTE3 primitive input port tie-off enablement
  parameter [0:0] GTE3_IBUFDS_CEB_TIE_EN = 1'b0,
  parameter [0:0] GTE3_IBUFDS_I_TIE_EN   = 1'b0,
  parameter [0:0] GTE3_IBUFDS_IB_TIE_EN  = 1'b0,


  // -------------------------------------------------------------------------------------------------------------------
  // Parameters relating to OBUFDS_GTE3 primitive
  // -------------------------------------------------------------------------------------------------------------------

  // primitive wrapper parameters which override corresponding OBUFDS_GTE3 primitive parameters
  parameter [0:0] GTE3_OBUFDS_REFCLK_EN_TX_PATH = 1'b0,
  parameter [4:0] GTE3_OBUFDS_REFCLK_ICNTL_TX   = 5'b00000,

  // primitive wrapper parameters which specify OBUFDS_GTE3 primitive input port default driver values
  parameter [0:0] GTE3_OBUFDS_CEB_VAL = 1'b0,
  parameter [0:0] GTE3_OBUFDS_I_VAL   = 1'b0,

  // primitive wrapper parameters which control OBUFDS_GTE3 primitive input port tie-off enablement
  parameter [0:0] GTE3_OBUFDS_CEB_TIE_EN = 1'b0,
  parameter [0:0] GTE3_OBUFDS_I_TIE_EN   = 1'b0,


  // -------------------------------------------------------------------------------------------------------------------
  // Parameters relating to CHANNEL primitive but which do not apply directly to it
  // -------------------------------------------------------------------------------------------------------------------

  // parameter which is used to control the divide value of primary BUFG_GT driven by TXOUTCLK
  parameter integer GTE3_CHANNEL_TX_OUTCLK_BUFG_GT_DIV = 1,

  // parameter which is used to control the divide value of primary BUFG_GT driven by RXOUTCLK
  parameter integer GTE3_CHANNEL_RX_OUTCLK_BUFG_GT_DIV = 1,

  // parameter which is used to capture the VCO frequency of the CPLL
  parameter real GTE3_CHANNEL_CPLL_VCO_FREQUENCY = 5156.25

)();


endmodule
