# 导出全套脚本以初始化Vivado 2020.2仿真状态，再应用仅仿真兼容补丁。
set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root RTDS_test_DDR4_64bit.xpr]
export_ip_user_files -of_objects [get_files design_1.bd] -no_script -sync -force
current_fileset -simset [get_filesets sim_xdma_rootport]
set_property xsim.elaborate.debug_level off [get_filesets sim_xdma_rootport]
# 仅关闭交互调试数据库；SV监视器、断言和计分板仍参与编译与判定。
set_property xsim.simulate.runtime all [get_filesets sim_xdma_rootport]
launch_simulation -simset sim_xdma_rootport -mode behavioral -scripts_only
source [file join $root scripts patch_util_ds_buf_sim_2020_2.tcl]
set work [file join $root RTDS_test_DDR4_64bit.sim sim_xdma_rootport behav xsim]
cd $work
foreach step {compile elaborate simulate} {
 puts "V201_STEP_BEGIN $step"
 set failed [catch {exec cmd /c ${step}.bat 2>@1} output]
 puts $output
 if {$failed || [regexp -nocase {ERROR:|FATAL:|RTDS_ROOTPORT_FAIL} $output]} {error "V201 $step failed; inspect output"}
}
close_project
