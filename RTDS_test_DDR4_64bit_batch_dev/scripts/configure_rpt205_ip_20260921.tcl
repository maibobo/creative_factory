# Board/IP configuration only. No synthesis, implementation or bitstream.
set root F:/RTDS_test_DDR4_64bit_batch_dev
open_project $root/RTDS_test_DDR4_64bit.xpr
open_bd_design $root/RTDS_test_DDR4_64bit.srcs/sources_1/bd/design_1/design_1.bd
set xdma [get_bd_cells /xdma_0]
puts "XDMA_CONFIG_BEFORE"
report_property $xdma
set_property -dict [list CONFIG.en_gt_selection true CONFIG.select_quad GTH_Quad_224 CONFIG.dedicate_perst false CONFIG.disable_gt_loc true] $xdma
# Physical-option callbacks can reset the AXI defaults. Restore the existing
# production data interface explicitly, then assert it after validation.
set_property -dict [list CONFIG.axi_data_width 64_bit CONFIG.axisten_freq 250] $xdma
set_property CONFIG.ID_WIDTH 5 [get_bd_intf_ports M_AXI_MEM]
puts "XDMA_CONFIG_AFTER"
foreach prop {CONFIG.en_gt_selection CONFIG.select_quad CONFIG.dedicate_perst CONFIG.pcie_blk_locn} {
    puts "$prop=[get_property $prop $xdma]"
}
validate_bd_design
if {[get_property CONFIG.axi_data_width $xdma] ne "64_bit" || [get_property CONFIG.axisten_freq $xdma] ne "250"} {
    error "Unexpected XDMA data width/clock change; preserve 64-bit/250MHz"
}
if {[get_property CONFIG.ID_WIDTH [get_bd_intf_ports M_AXI_MEM]] ne "5"} {
    error "Memory interface must retain its original five-bit AXI ID"
}
save_bd_design
set aurora [get_ips aurora_8b10b_1p25g]
puts "AURORA_CONFIG_BEFORE"
report_property $aurora
set_property -dict [list CONFIG.C_START_QUAD Quad_X0Y1 CONFIG.C_START_LANE X0Y4 CONFIG.C_REFCLK_SOURCE {MGTREFCLK0 of Quad X0Y1}] $aurora
puts "AURORA_CONFIG_AFTER"
foreach prop {CONFIG.C_START_QUAD CONFIG.C_START_LANE CONFIG.C_GT_LOC_1 CONFIG.C_GT_LOC_5 CONFIG.C_REFCLK_SOURCE} {
    puts "$prop=[get_property $prop $aurora]"
}
generate_target all [get_files $root/RTDS_test_DDR4_64bit.srcs/sources_1/bd/design_1/design_1.bd]
generate_target all $aurora
puts "RPT205_IP_CONFIG_COMPLETE_NO_RUNS_LAUNCHED"
close_project
exit 0
