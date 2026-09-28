##################################################################################
##
## Project:  Aurora 64B/66B
## Company:  Xilinx
##
##
##
## (c) Copyright 2008 - 2018 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
###################################################################################################
##
##  aurora_64b66b_0_exdes
##
##  Description: This is the example design constraints file for a 1 lane Aurora
##               core.
##               This is example design xdc.
##               Note: User need to set proper IO standards for the LOC's mentioned below.
###################################################################################################

# create clock constraints for init_clk
#create_clock -name init_clk_in -period 5	 [get_ports clk]   // already defined in ip/clk_wiz_0/clk_wiz_0.xdc":56
#set_clock_groups -asynchronous -group [get_clocks init_clk_in -include_generated_clocks]  // already defined in ip/clk_wiz_0/clk_wiz_0.xdc":56

# Reference clock contraint for GTX
#create_clock -period 5.000 -name gt_refclk1_in [get_ports GTHQ0_P]
#set_clock_groups -asynchronous -group [get_clocks gt_refclk1_in -include_generated_clocks]

# false path constrints for example design paths
#set_false_path -to [get_pins -hier *aurora_64b66b_0_cdc_to*/D]
# Reference clock location

set_property PACKAGE_PIN AK17 [get_ports clk_p]
set_property IOSTANDARD DIFF_HSTL_I_12 [get_ports clk_p]

set_property PACKAGE_PIN T5 [get_ports GTHQ0_N]
set_property PACKAGE_PIN T6 [get_ports GTHQ0_P]
set_property PACKAGE_PIN AA4 [get_ports TXP]

#set_property PACKAGE_PIN T22 [get_ports pl_led]
#set_property IOSTANDARD LVCMOS18 [get_ports pl_led]

set_property PACKAGE_PIN H26 [get_ports sfp_tx_disable]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_disable]
set_property PACKAGE_PIN G26 [get_ports sfp_rs0]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_rs0]
set_property PACKAGE_PIN H27 [get_ports sfp_rs1]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_rs1]

################################################################################

#####################################################################################################
##Note: User should add LOC based upon the board
#       Below LOC's are place holders and need to be changed as per the device and board
#set_property LOC D17 [get_ports INIT_CLK_P]
#set_property LOC D18 [get_ports INIT_CLK_N]
#set_property LOC G19 [get_ports RESET]
#set_property LOC K18 [get_ports PMA_INIT]

#set_property LOC A20 [get_ports CHANNEL_UP]
#set_property LOC A17 [get_ports LANE_UP]
#set_property LOC Y15 [get_ports HARD_ERR]
#set_property LOC AH10 [get_ports SOFT_ERR]
#set_property LOC AD16 [get_ports DATA_ERR_COUNT[0]]
#set_property LOC Y19 [get_ports DATA_ERR_COUNT[1]]
#set_property LOC Y18 [get_ports DATA_ERR_COUNT[2]]
#set_property LOC AA18 [get_ports DATA_ERR_COUNT[3]]
#set_property LOC AB18 [get_ports DATA_ERR_COUNT[4]]
#set_property LOC AB19 [get_ports DATA_ERR_COUNT[5]]
#set_property LOC AC19 [get_ports DATA_ERR_COUNT[6]]
#set_property LOC AB17 [get_ports DATA_ERR_COUNT[7]]


#set_property LOC AG15 [get_ports CRC_PASS_FAIL_N]
#set_property LOC AH15 [get_ports CRC_VALID]
##Note: User should add IOSTANDARD based upon the board
#       Below IOSTANDARD's are place holders and need to be changed as per the device and board
#set_property IOSTANDARD LVDS_25 [get_ports INIT_CLK_P]
#set_property IOSTANDARD LVDS_25 [get_ports INIT_CLK_N]
#set_property IOSTANDARD LVCMOS18 [get_ports RESET]
#set_property IOSTANDARD LVCMOS18 [get_ports PMA_INIT]

#set_property IOSTANDARD LVCMOS18 [get_ports CHANNEL_UP]
#set_property IOSTANDARD LVCMOS18 [get_ports LANE_UP]
#set_property IOSTANDARD LVCMOS18 [get_ports HARD_ERR]
#set_property IOSTANDARD LVCMOS18 [get_ports SOFT_ERR]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[0]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[1]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[2]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[3]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[4]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[5]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[6]]
#set_property IOSTANDARD LVCMOS18 [get_ports DATA_ERR_COUNT[7]]


#set_property IOSTANDARD LVCMOS18 [get_ports CRC_PASS_FAIL_N]
#set_property IOSTANDARD LVCMOS18 [get_ports CRC_VALID]












#create_debug_core u_ila_1 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
#set_property port_width 1 [get_debug_ports u_ila_1/clk]
#connect_debug_port u_ila_1/clk [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/inst/clock_module_i/ultrascale_tx_userclk_1/sync_clk_out]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
#set_property port_width 1 [get_debug_ports u_ila_1/probe0]
#connect_debug_port u_ila_1/probe0 [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/gt_refclk1_out]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
#set_property port_width 1 [get_debug_ports u_ila_1/probe1]
#connect_debug_port u_ila_1/probe1 [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/n_0_0]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
#set_property port_width 1 [get_debug_ports u_ila_1/probe2]
#connect_debug_port u_ila_1/probe2 [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/n_0_2]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
#set_property port_width 1 [get_debug_ports u_ila_1/probe3]
#connect_debug_port u_ila_1/probe3 [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/n_0_3]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
#set_property port_width 1 [get_debug_ports u_ila_1/probe4]
#connect_debug_port u_ila_1/probe4 [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/n_0_4]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
#set_property port_width 1 [get_debug_ports u_ila_1/probe5]
#connect_debug_port u_ila_1/probe5 [get_nets [list aurora_64b66b_0_exdes_inst/aurora_64b66b_0_block_i/sync_clk_out]]

#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
#set_property port_width 1 [get_debug_ports u_ila_1/probe0]
#connect_debug_port u_ila_1/probe0 [get_nets [list aurora_64b66b_0_exdes_inst/core_traffic.frame_gen_i/USER_CLK]]


#set_property CLOCK_DOMAINS COMMON [get_cells -hierarchical -filter {NAME =~ *aurora_64b66b_0_exdes_inst/ila_aurora_exdes_ini_inst/inst/ila_core_inst/ila_trace_memory_inst/SUBCORE_RAM_BLK_MEM_1.trace_block_memory/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_8SERIES.NO_BMM_INFO.SDP.SIMPLE_PRIM18.ram}]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk_init]
