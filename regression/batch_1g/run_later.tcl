# 显式运行入口，当前只交付脚本。先单独执行 scripts/refresh_batch_bd.tcl。
# 用法：vivado.bat -mode batch -source run_later.tcl -tclargs 1g|ring|axi|rx_fifo|fast|rootport
if {$argc != 1 || [lsearch -exact {1g ring axi rx_fifo fast rootport} [lindex $argv 0]] < 0} {
    error {必须显式选择 1g、ring、axi、rx_fifo、fast 或 rootport；不会默认运行长仿真}
}
set project_dir [file normalize [file join [file dirname [info script]] ../..]]
open_project [file join $project_dir RTDS_test_DDR4_64bit.xpr]
set selected [lindex $argv 0]
switch -- $selected {
    fast {set simset [get_filesets sim_1]}
    rootport {set simset [get_filesets sim_xdma_rootport]}
    default {set simset [get_filesets sim_batch_$selected]}
}
# 验证数据通路使用4MiB行为RAM；保留原Root Port需要的其他宏。
# 显式避免与真实MIG配置冲突，不改生产sources_1文件集的宏。
set sim_defines [get_property verilog_define $simset]
set kept_defines {}
foreach definition $sim_defines {
    if {![string match {DDR4_REAL*} $definition]} {lappend kept_defines $definition}
}
if {[lsearch -glob $kept_defines {DDR4_SIM_RAM*}] < 0} {lappend kept_defines DDR4_SIM_RAM}
set_property verilog_define $kept_defines $simset
current_fileset -simset $simset
update_compile_order -fileset $simset
launch_simulation -simset $simset -mode behavioral
run all
close_sim
close_project
