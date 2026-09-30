
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2020.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# CONV_DMA, INFO_EXCH

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcku040-ffva1156-2-i
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set M_AXI_MEM [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MEM ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {16} \
   CONFIG.NUM_WRITE_OUTSTANDING {16} \
   CONFIG.PROTOCOL {AXI4} \
   ] $M_AXI_MEM

  set pcie_7x_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_7x_mgt ]

  set pcie_diff_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_diff_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_diff_clock


  # Create ports
  set CPU_REC_STATE_W_0 [ create_bd_port -dir I -from 0 -to 0 CPU_REC_STATE_W_0 ]
  set CPU_WR_DONE_EVENT [ create_bd_port -dir I CPU_WR_DONE_EVENT ]
  set CPU_WR_DONE_resp_0 [ create_bd_port -dir I -from 0 -to 0 CPU_WR_DONE_resp_0 ]
  set DDR_STATUS_W [ create_bd_port -dir I -from 31 -to 0 DDR_STATUS_W ]
  set FPGA_CPU_LEN_0 [ create_bd_port -dir I -from 31 -to 0 FPGA_CPU_LEN_0 ]
  set FPGA_CPU_START_ADDR_0 [ create_bd_port -dir I -from 31 -to 0 FPGA_CPU_START_ADDR_0 ]
  set FPGA_CPU_irq_req [ create_bd_port -dir I -from 0 -to 0 FPGA_CPU_irq_req ]
  set FPGA_TEMP_W_0 [ create_bd_port -dir I -from 31 -to 0 FPGA_TEMP_W_0 ]
  set INT_STATE_W_0 [ create_bd_port -dir I -from 0 -to 0 INT_STATE_W_0 ]
  set RX_DROPPED_FRAMES [ create_bd_port -dir I -from 31 -to 0 RX_DROPPED_FRAMES ]
  set RX_HEAD_SEQ [ create_bd_port -dir I -from 31 -to 0 RX_HEAD_SEQ ]
  set RX_READY_BLOCKS [ create_bd_port -dir I -from 31 -to 0 RX_READY_BLOCKS ]
  set fdma_raddr_0 [ create_bd_port -dir I -from 63 -to 0 fdma_raddr_0 ]
  set fdma_rareq_0 [ create_bd_port -dir I fdma_rareq_0 ]
  set fdma_rbusy_0 [ create_bd_port -dir O fdma_rbusy_0 ]
  set fdma_rdata_0 [ create_bd_port -dir O -from 63 -to 0 fdma_rdata_0 ]
  set fdma_rready_0 [ create_bd_port -dir I fdma_rready_0 ]
  set fdma_rsize_0 [ create_bd_port -dir I -from 15 -to 0 fdma_rsize_0 ]
  set fdma_rvalid_0 [ create_bd_port -dir O fdma_rvalid_0 ]
  set fdma_waddr_0 [ create_bd_port -dir I -from 63 -to 0 fdma_waddr_0 ]
  set fdma_wareq_0 [ create_bd_port -dir I fdma_wareq_0 ]
  set fdma_wbusy_0 [ create_bd_port -dir O fdma_wbusy_0 ]
  set fdma_wdata_0 [ create_bd_port -dir I -from 63 -to 0 fdma_wdata_0 ]
  set fdma_wdone_0 [ create_bd_port -dir O fdma_wdone_0 ]
  set fdma_werror_0 [ create_bd_port -dir O fdma_werror_0 ]
  set fdma_wready_0 [ create_bd_port -dir I fdma_wready_0 ]
  set fdma_wsize_0 [ create_bd_port -dir I -from 15 -to 0 fdma_wsize_0 ]
  set fdma_wstrb_0 [ create_bd_port -dir I -from 7 -to 0 fdma_wstrb_0 ]
  set fdma_wvalid_0 [ create_bd_port -dir O fdma_wvalid_0 ]
  set pcie_rst_n [ create_bd_port -dir I -type rst pcie_rst_n ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_rst_n
  set r_CLEAR_INTER_0 [ create_bd_port -dir O r_CLEAR_INTER_0 ]
  set r_CPU_FPGA_LEN_0 [ create_bd_port -dir O -from 31 -to 0 r_CPU_FPGA_LEN_0 ]
  set r_CPU_FPGA_START_ADDR_0 [ create_bd_port -dir O -from 31 -to 0 r_CPU_FPGA_START_ADDR_0 ]
  set r_CPU_REC_STATE_0 [ create_bd_port -dir O r_CPU_REC_STATE_0 ]
  set r_INT_STATE_0 [ create_bd_port -dir O r_INT_STATE_0 ]
  set r_RD_START_0 [ create_bd_port -dir O r_RD_START_0 ]
  set sys_clk [ create_bd_port -dir I -type clk -freq_hz 250000000 sys_clk ]
  set sys_rst_n [ create_bd_port -dir I -type rst sys_rst_n ]
  set user_lnk_up [ create_bd_port -dir O user_lnk_up ]

  # Create instance: CONV_DMA_0, and set properties
  set block_name CONV_DMA
  set block_cell_name CONV_DMA_0
  if { [catch {set CONV_DMA_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $CONV_DMA_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.M_AXI_DATA_WIDTH {64} \
 ] $CONV_DMA_0

  # Create instance: INFO_EXCH_0, and set properties
  set block_name INFO_EXCH
  set block_cell_name INFO_EXCH_0
  if { [catch {set INFO_EXCH_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $INFO_EXCH_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
   CONFIG.CH_BUF_LEN {0x00040000} \
   CONFIG.PROG_TIME {0x20260914} \
   CONFIG.VERSION {0x00002001} \
 ] $INFO_EXCH_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $axi_interconnect_1

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $util_ds_buf

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0 ]
  set_property -dict [ list \
   CONFIG.PF0_DEVICE_ID_mqdma {9032} \
   CONFIG.PF2_DEVICE_ID_mqdma {9032} \
   CONFIG.PF3_DEVICE_ID_mqdma {9032} \
   CONFIG.axi_data_width {64_bit} \
   CONFIG.axilite_master_en {true} \
   CONFIG.axisten_freq {250} \
   CONFIG.cfg_mgmt_if {false} \
   CONFIG.coreclk_freq {500} \
   CONFIG.dedicate_perst {false} \
   CONFIG.disable_gt_loc {true} \
   CONFIG.en_gt_selection {true} \
   CONFIG.pciebar2axibar_axil_master {0x40000000} \
   CONFIG.pciebar2axibar_axist_bypass {0x0000000000000000} \
   CONFIG.pf0_device_id {8032} \
   CONFIG.pf0_interrupt_pin {NONE} \
   CONFIG.pf0_msix_cap_pba_bir {BAR_1} \
   CONFIG.pf0_msix_cap_table_bir {BAR_1} \
   CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
   CONFIG.pl_link_cap_max_link_width {X2} \
   CONFIG.plltype {QPLL1} \
   CONFIG.select_quad {GTH_Quad_224} \
   CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
   CONFIG.xdma_num_usr_irq {1} \
   CONFIG.xdma_rnum_chnl {1} \
   CONFIG.xdma_wnum_chnl {1} \
 ] $xdma_0

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins CONV_DMA_0/M_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_2 [get_bd_intf_pins axi_interconnect_1/S00_AXI] [get_bd_intf_pins xdma_0/M_AXI_LITE]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins xdma_0/M_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_ports M_AXI_MEM] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  set_property SIM_ATTRIBUTE.MARK_SIM "true" [get_bd_intf_nets /axi_interconnect_0_M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins INFO_EXCH_0/S_AXI] [get_bd_intf_pins axi_interconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net diff_clock_rtl_0_1 [get_bd_intf_ports pcie_diff_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pcie_7x_mgt] [get_bd_intf_pins xdma_0/pcie_mgt]

  # Create port connections
  connect_bd_net -net CONV_DMA_0_fdma_rbusy [get_bd_ports fdma_rbusy_0] [get_bd_pins CONV_DMA_0/fdma_rbusy]
  connect_bd_net -net CONV_DMA_0_fdma_rdata [get_bd_ports fdma_rdata_0] [get_bd_pins CONV_DMA_0/fdma_rdata]
  connect_bd_net -net CONV_DMA_0_fdma_rvalid [get_bd_ports fdma_rvalid_0] [get_bd_pins CONV_DMA_0/fdma_rvalid]
  connect_bd_net -net CONV_DMA_0_fdma_wbusy [get_bd_ports fdma_wbusy_0] [get_bd_pins CONV_DMA_0/fdma_wbusy]
  connect_bd_net -net CONV_DMA_0_fdma_wvalid [get_bd_ports fdma_wvalid_0] [get_bd_pins CONV_DMA_0/fdma_wvalid]
  connect_bd_net -net CPU_REC_STATE_W_0_1 [get_bd_ports CPU_REC_STATE_W_0] [get_bd_pins INFO_EXCH_0/CPU_REC_STATE_W]
  connect_bd_net -net CPU_WR_DONE_EVENT_1 [get_bd_ports CPU_WR_DONE_EVENT] [get_bd_pins INFO_EXCH_0/CPU_WR_DONE_EVENT]
  connect_bd_net -net CPU_WR_DONE_resp_0_1 [get_bd_ports CPU_WR_DONE_resp_0] [get_bd_pins INFO_EXCH_0/CPU_WR_DONE_resp]
  connect_bd_net -net DDR_STATUS_W_1 [get_bd_ports DDR_STATUS_W] [get_bd_pins INFO_EXCH_0/DDR_STATUS_W]
  connect_bd_net -net FPGA_CPU_LEN_0_1 [get_bd_ports FPGA_CPU_LEN_0] [get_bd_pins INFO_EXCH_0/FPGA_CPU_LEN]
  connect_bd_net -net FPGA_CPU_START_ADDR_0_1 [get_bd_ports FPGA_CPU_START_ADDR_0] [get_bd_pins INFO_EXCH_0/FPGA_CPU_START_ADDR]
  connect_bd_net -net FPGA_CPU_irq_req_1 [get_bd_ports FPGA_CPU_irq_req] [get_bd_pins xdma_0/usr_irq_req]
  connect_bd_net -net FPGA_TEMP_W_0_1 [get_bd_ports FPGA_TEMP_W_0] [get_bd_pins INFO_EXCH_0/FPGA_TEMP_W]
  connect_bd_net -net INFO_EXCH_0_r_CLEAR_INTER [get_bd_ports r_CLEAR_INTER_0] [get_bd_pins INFO_EXCH_0/r_CLEAR_INTER]
  connect_bd_net -net INFO_EXCH_0_r_CPU_FPGA_LEN [get_bd_ports r_CPU_FPGA_LEN_0] [get_bd_pins INFO_EXCH_0/r_CPU_FPGA_LEN]
  connect_bd_net -net INFO_EXCH_0_r_CPU_FPGA_START_ADDR [get_bd_ports r_CPU_FPGA_START_ADDR_0] [get_bd_pins INFO_EXCH_0/r_CPU_FPGA_START_ADDR]
  connect_bd_net -net INFO_EXCH_0_r_CPU_REC_STATE [get_bd_ports r_CPU_REC_STATE_0] [get_bd_pins INFO_EXCH_0/r_CPU_REC_STATE]
  connect_bd_net -net INFO_EXCH_0_r_INT_STATE [get_bd_ports r_INT_STATE_0] [get_bd_pins INFO_EXCH_0/r_INT_STATE]
  connect_bd_net -net INFO_EXCH_0_r_RD_START [get_bd_ports r_RD_START_0] [get_bd_pins INFO_EXCH_0/r_RD_START]
  connect_bd_net -net INT_STATE_W_0_1 [get_bd_ports INT_STATE_W_0] [get_bd_pins INFO_EXCH_0/INT_STATE_W]
  connect_bd_net -net M_AXI_ACLK_0_1 [get_bd_ports sys_clk] [get_bd_pins CONV_DMA_0/M_AXI_ACLK] [get_bd_pins INFO_EXCH_0/S_AXI_ACLK] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK]
  connect_bd_net -net M_AXI_ARESETN_0_1 [get_bd_ports sys_rst_n] [get_bd_pins CONV_DMA_0/M_AXI_ARESETN] [get_bd_pins INFO_EXCH_0/S_AXI_ARESETN] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN]
  connect_bd_net -net RX_DROPPED_FRAMES_net [get_bd_ports RX_DROPPED_FRAMES] [get_bd_pins INFO_EXCH_0/RX_DROPPED_FRAMES]
  connect_bd_net -net RX_HEAD_SEQ_net [get_bd_ports RX_HEAD_SEQ] [get_bd_pins INFO_EXCH_0/RX_HEAD_SEQ]
  connect_bd_net -net RX_READY_BLOCKS_net [get_bd_ports RX_READY_BLOCKS] [get_bd_pins INFO_EXCH_0/RX_READY_BLOCKS]
  connect_bd_net -net fdma_raddr_0_1 [get_bd_ports fdma_raddr_0] [get_bd_pins CONV_DMA_0/fdma_raddr]
  connect_bd_net -net fdma_rareq_0_1 [get_bd_ports fdma_rareq_0] [get_bd_pins CONV_DMA_0/fdma_rareq]
  connect_bd_net -net fdma_rready_0_1 [get_bd_ports fdma_rready_0] [get_bd_pins CONV_DMA_0/fdma_rready]
  connect_bd_net -net fdma_rsize_0_1 [get_bd_ports fdma_rsize_0] [get_bd_pins CONV_DMA_0/fdma_rsize]
  connect_bd_net -net fdma_waddr_0_1 [get_bd_ports fdma_waddr_0] [get_bd_pins CONV_DMA_0/fdma_waddr]
  connect_bd_net -net fdma_wareq_0_1 [get_bd_ports fdma_wareq_0] [get_bd_pins CONV_DMA_0/fdma_wareq]
  connect_bd_net -net fdma_wdata_0_1 [get_bd_ports fdma_wdata_0] [get_bd_pins CONV_DMA_0/fdma_wdata]
  connect_bd_net -net fdma_wdone_0_net [get_bd_ports fdma_wdone_0] [get_bd_pins CONV_DMA_0/fdma_wdone]
  connect_bd_net -net fdma_werror_0_net [get_bd_ports fdma_werror_0] [get_bd_pins CONV_DMA_0/fdma_werror]
  connect_bd_net -net fdma_wready_0_1 [get_bd_ports fdma_wready_0] [get_bd_pins CONV_DMA_0/fdma_wready]
  connect_bd_net -net fdma_wsize_0_1 [get_bd_ports fdma_wsize_0] [get_bd_pins CONV_DMA_0/fdma_wsize]
  connect_bd_net -net fdma_wstrb_0_1 [get_bd_ports fdma_wstrb_0] [get_bd_pins CONV_DMA_0/fdma_wstrb]
  connect_bd_net -net reset_rtl_0_1 [get_bd_ports pcie_rst_n] [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2 [get_bd_pins util_ds_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net xdma_0_axi_aclk [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins xdma_0/axi_aclk]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins xdma_0/axi_aresetn]
  connect_bd_net -net xdma_0_user_lnk_up [get_bd_ports user_lnk_up] [get_bd_pins xdma_0/user_lnk_up]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00400000 -target_address_space [get_bd_addr_spaces CONV_DMA_0/M_AXI] [get_bd_addr_segs M_AXI_MEM/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs INFO_EXCH_0/S_AXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x00400000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs M_AXI_MEM/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


