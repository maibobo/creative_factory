set root_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root_dir RTDS_test_DDR4_64bit.xpr]
set rtl_files [list \
  [file join $root_dir rtl ddr4 rtds_axi_ram_model.sv] \
  [file join $root_dir rtl ddr4 rtds_ddr4_backend.sv]]
foreach f $rtl_files {
  if {![llength [get_files -quiet $f]]} { add_files -norecurse $f }
  set_property file_type SystemVerilog [get_files $f]
}
set xdc [file join $root_dir RTDS_test_DDR4_64bit.srcs constrs_1 new DDR4_PIN.xdc]
if {![llength [get_files -quiet $xdc]]} { add_files -fileset constrs_1 -norecurse $xdc }
set smoke_tb [file join $root_dir sim ddr4_backend tb_rtds_ddr4_backend_smoke.sv]
if {![llength [get_files -quiet $smoke_tb]]} { add_files -fileset sim_1 -norecurse $smoke_tb }
set_property file_type SystemVerilog [get_files $smoke_tb]
set_property top TOP [get_filesets sources_1]
set_property verilog_define {DDR4_SIM_RAM} [get_filesets sources_1]
set_property verilog_define {DDR4_SIM_RAM} [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project
puts "PROJECT_FILE_INTEGRATION_PASS"