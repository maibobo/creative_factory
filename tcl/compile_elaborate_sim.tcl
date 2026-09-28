set root_dir [file normalize "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit"]
open_project [file join $root_dir RTDS_test_DDR4_64bit.xpr]
set_property verilog_define {DDR4_SIM_RAM} [get_filesets sources_1]
if {[llength [get_filesets -quiet sim_top_compile]] == 0} {
  create_fileset -simset sim_top_compile
}
set fs [get_filesets sim_top_compile]
set_property SOURCE_SET sources_1 $fs
set_property top TOP $fs
set_property top_lib xil_defaultlib $fs
set_property verilog_define {DDR4_SIM_RAM} $fs
set stub_file [file join $root_dir sim top_compile design_1_util_ds_buf_0_sim_stub.v]
if {[llength [get_files -quiet $stub_file]] == 0} {
  add_files -fileset $fs -norecurse $stub_file
}
set vendor_files [glob -nocomplain -types f [file join $root_dir sim vendor_compat gtwizard_ultrascale_v1_7 *.v]]
foreach vf $vendor_files {
  if {[llength [get_files -quiet $vf]] == 0} {
    add_files -fileset $fs -norecurse $vf
  }
}
set_property USED_IN_SYNTHESIS false [get_files $stub_file]
set_property USED_IN_SIMULATION true [get_files $stub_file]
if {[llength $vendor_files] > 0} {
  set_property USED_IN_SYNTHESIS false [get_files $vendor_files]
  set_property USED_IN_SIMULATION true [get_files $vendor_files]
}
set bd_sim_src [file join $root_dir RTDS_test_DDR4_64bit.srcs sources_1 bd design_1 sim design_1.v]
set bd_sim_dst [file join $root_dir RTDS_test_DDR4_64bit.ip_user_files bd design_1 sim design_1.v]
file copy -force $bd_sim_src $bd_sim_dst
set util_xci [get_files -quiet */design_1_util_ds_buf_0.xci]
set_property USED_IN_SIMULATION false $util_xci
update_compile_order -fileset sources_1
update_compile_order -fileset $fs
set sim_rc [catch {launch_simulation -simset sim_top_compile -mode behavioral} sim_msg]
set_property USED_IN_SIMULATION true $util_xci
if {$sim_rc} {
  close_project
  error $sim_msg
}
puts "RTDS_TOP_XSIM_COMPILE_ELABORATE_PASS"
close_sim
close_project