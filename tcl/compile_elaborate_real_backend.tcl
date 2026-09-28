set root_dir [file normalize "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit"]
set proj_file [file join $root_dir RTDS_test_DDR4_64bit.xpr]
open_project $proj_file
set old_src_defs [get_property verilog_define [get_filesets sources_1]]
set old_sim_defs [get_property verilog_define [get_filesets sim_1]]
set_property verilog_define {DDR4_REAL} [get_filesets sources_1]
update_compile_order -fileset sources_1
if {[catch {
  synth_design -rtl -top rtds_ddr4_backend -part xcku040-ffva1156-2-i -verilog_define DDR4_REAL
} emsg]} {
  set_property verilog_define $old_src_defs [get_filesets sources_1]
  set_property verilog_define $old_sim_defs [get_filesets sim_1]
  close_project
  error $emsg
}
puts "RTDS_DDR4_REAL_BACKEND_COMPILE_ELABORATE_PASS"
close_design
set_property verilog_define {DDR4_SIM_RAM} [get_filesets sources_1]
set_property verilog_define {DDR4_SIM_RAM} [get_filesets sim_1]
save_project
close_project