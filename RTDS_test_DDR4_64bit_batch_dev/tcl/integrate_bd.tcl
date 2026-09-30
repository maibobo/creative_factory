set root_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root_dir RTDS_test.xpr]

set cw [get_ips -quiet clk_wiz_0]
if {[llength $cw] != 1} { error "clk_wiz_0 not found" }
set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] $cw
generate_target all [get_files clk_wiz_0.xci]

set bd_file [file join $root_dir RTDS_test.srcs sources_1 bd design_1 design_1.bd]
open_bd_design $bd_file
update_module_reference [get_ips -quiet *INFO_EXCH*]

if {[llength [get_bd_cells -quiet axi_bram_ctrl_0]]} {
    delete_bd_objs [get_bd_cells axi_bram_ctrl_0]
}
if {[llength [get_bd_cells -quiet blk_mem_gen_0]]} {
    delete_bd_objs [get_bd_cells blk_mem_gen_0]
}

if {![llength [get_bd_intf_ports -quiet M_AXI_MEM]]} {
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MEM
    connect_bd_intf_net [get_bd_intf_ports M_AXI_MEM] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
}

if {![llength [get_bd_ports -quiet DDR_STATUS_W]]} {
    create_bd_port -dir I -from 31 -to 0 DDR_STATUS_W
}
if {![llength [get_bd_nets -quiet DDR_STATUS_W_1]]} {
    connect_bd_net -net DDR_STATUS_W_1 [get_bd_ports DDR_STATUS_W] [get_bd_pins INFO_EXCH_0/DDR_STATUS_W]
}

validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
set wrapper [make_wrapper -files [get_files design_1.bd] -top -force]
if {[llength $wrapper] && ![llength [get_files -quiet */design_1_wrapper.v]]} {
    add_files -norecurse $wrapper
}
update_compile_order -fileset sources_1
save_project_as RTDS_test_DDR4_64bit $root_dir -force
close_project
puts "BD_INTEGRATION_PASS"