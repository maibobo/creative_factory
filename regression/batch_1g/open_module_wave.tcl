# 打开已完成的小仿真波形，并自动创建波形配置、加入全部已记录信号。
# 用法：vivado.bat -mode gui -source regression/batch_1g/open_module_wave.tcl -tclargs tx
set selected [lindex $argv 0]
set supported {1g ring axi axi_tail rx_fifo regs tx}
if {$selected ni $supported} {
    error "用例名必须是以下之一：$supported"
}

set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ../..]]
set project_file [file join $root regression v201_runs $selected project module_test.xpr]
set wave_dir [file join $root regression v201_runs $selected project module_test.sim sim_1 behav xsim]
set full_wave_file [file join $wave_dir tb_rtds_${selected}_behav_full.wdb]
set default_wave_file [file join $wave_dir tb_rtds_${selected}_behav.wdb]
set wave_config_file [file join $wave_dir tb_rtds_${selected}_all_signals.wcfg]
set top_scope /tb_rtds_${selected}

if {![file exists $project_file]} {
    error "找不到仿真工程：$project_file"
}
if {[file exists $full_wave_file]} {
    set wave_file $full_wave_file
} elseif {[file exists $default_wave_file]} {
    set wave_file $default_wave_file
} else {
    error "找不到波形数据库：$default_wave_file"
}

open_project $project_file
open_wave_database $wave_file

# WDB与WCFG是两个对象：打开WDB后仍需创建配置，GUI才会出现波形窗口。
if {[string length [current_wave_config]] == 0} {
    create_wave_config
}

# 递归加入当前WDB内可用的全部测试顶层及DUT信号。旧默认WDB只记录了
# 部分信号；open_module_full_wave.cmd会重新运行并生成包含完整层次的WDB。
if {[catch {add_wave -r ${top_scope}/*} add_error]} {
    puts "RTDS_WAVE_ADD_WARNING=$add_error"
    add_wave /
}
catch {file delete -force $wave_config_file}
if {[catch {save_wave_config $wave_config_file} save_error]} {
    puts "RTDS_WAVE_CONFIG_WARNING=$save_error"
}
puts "RTDS_WAVE_OPENED=$wave_file"
puts "RTDS_WAVE_CONFIG=$wave_config_file"
puts "RTDS_WAVE_NOTE=若需要全部内部信号，请运行 open_module_full_wave.cmd $selected"
