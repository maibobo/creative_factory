set root_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root_dir RTDS_test_DDR4_64bit.xpr]
open_bd_design [file join $root_dir RTDS_test_DDR4_64bit.srcs sources_1 bd design_1 design_1.bd]
set mem_port [get_bd_intf_ports M_AXI_MEM]
set_property -dict [list \
  CONFIG.PROTOCOL {AXI4} \
  CONFIG.ADDR_WIDTH {32} \
  CONFIG.DATA_WIDTH {64} \
  CONFIG.ID_WIDTH {5} \
  CONFIG.FREQ_HZ {250000000} \
  CONFIG.HAS_BURST {1} \
  CONFIG.HAS_LOCK {1} \
  CONFIG.HAS_PROT {1} \
  CONFIG.HAS_CACHE {1} \
  CONFIG.HAS_QOS {1} \
  CONFIG.HAS_REGION {0} \
  CONFIG.NUM_READ_OUTSTANDING {16} \
  CONFIG.NUM_WRITE_OUTSTANDING {16} \
  CONFIG.MAX_BURST_LENGTH {256}] $mem_port
set slave_seg [get_bd_addr_segs M_AXI_MEM/Reg]
if {![llength [get_bd_addr_segs -quiet CONV_DMA_0/M_AXI/SEG_M_AXI_MEM_Reg]]} {
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces CONV_DMA_0/M_AXI] $slave_seg SEG_M_AXI_MEM_Reg
}
if {![llength [get_bd_addr_segs -quiet xdma_0/M_AXI/SEG_M_AXI_MEM_Reg]]} {
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces xdma_0/M_AXI] $slave_seg SEG_M_AXI_MEM_Reg
}
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
make_wrapper -files [get_files design_1.bd] -top -force
update_compile_order -fileset sources_1
close_project
puts "BD_INTERFACE_PASS"