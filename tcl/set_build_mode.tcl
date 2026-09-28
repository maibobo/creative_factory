if {$argc < 1} {
  error "Usage: vivado -mode batch -source tcl/set_build_mode.tcl -tclargs DDR4_SIM_RAM|DDR4_REAL"
}
set mode [lindex $argv 0]
if {$mode ni {DDR4_SIM_RAM DDR4_REAL}} {
  error "Unsupported mode '$mode'; use DDR4_SIM_RAM or DDR4_REAL"
}
set root_dir [file normalize "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit"]
open_project [file join $root_dir RTDS_test_DDR4_64bit.xpr]
set_property verilog_define [list $mode] [get_filesets sources_1]
set_property verilog_define [list $mode] [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
save_project
puts "RTDS_BUILD_MODE=$mode"
close_project