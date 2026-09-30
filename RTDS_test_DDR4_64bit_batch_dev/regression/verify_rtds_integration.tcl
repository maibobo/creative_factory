set script_dir   [file dirname [file normalize [info script]]]
set project_path [file normalize [file join $script_dir .. RTDS_test.xpr]]
set report_dir   [file normalize [file join $script_dir reports]]
file mkdir $report_dir

open_project $project_path
set_property top TOP [get_filesets sources_1]
set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

report_ip_status -file [file join $report_dir ip_status.txt]

set bd_path [file normalize [file join $script_dir .. RTDS_test.srcs sources_1 bd design_1 design_1.bd]]
open_bd_design $bd_path
validate_bd_design

set bram_cell [get_bd_cells /blk_mem_gen_0]
if {[get_property CONFIG.Write_Depth_A $bram_cell] != 8192} {
  error "BRAM depth is not 8192 words"
}
foreach address_space_name [list /CONV_DMA_0/M_AXI /xdma_0/M_AXI] {
  set address_space [get_bd_addr_spaces $address_space_name]
  set mapped_segment [get_bd_addr_segs -of_objects $address_space \
    -filter {NAME =~ *SEG_axi_bram_ctrl_0_Mem0}]
  if {[get_property OFFSET $mapped_segment] != 0} {
    error "$address_space_name BRAM offset is not zero"
  }
  if {[get_property RANGE $mapped_segment] != 65536} {
    error "$address_space_name BRAM range is not 64 KiB"
  }
}

set axil_space [get_bd_addr_spaces /xdma_0/M_AXI_LITE]
set axil_segment [get_bd_addr_segs -of_objects $axil_space \
  -filter {NAME =~ *SEG_INFO_EXCH_0_reg0}]
if {[get_property OFFSET $axil_segment] != 0x40000000 ||
    [get_property RANGE $axil_segment] != 4096} {
  error "INFO_EXCH AXI-Lite segment changed unexpectedly"
}

close_bd_design [get_bd_designs design_1]

# RTL elaboration catches top-level port, module, parameter and XPM CDC
# integration errors without waiting for a full implementation run.
synth_design -rtl -name rtl_check -top TOP -part xcku040-ffva1156-2-i
report_utilization -file [file join $report_dir rtl_utilization.txt]
report_cdc -details -file [file join $report_dir rtl_cdc.txt]
report_methodology -file [file join $report_dir rtl_methodology.txt]

puts "RTDS_INTEGRATION_VERIFY_PASS"
close_project
