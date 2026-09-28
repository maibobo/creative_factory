# 批处理仿真入口：先经过 2020.2 TESTNAME 兼容层选择用例，
# 再建立语义化波形，最后运行到用例主动 $finish 或 2 ms 看门狗。
# 输入：已展开的 WaveMode board snapshot。
# 输出：rtds_minimum.wdb/wcfg、功能日志和用例结果。
# 失败定位：0 ns 的 create/save WCFG 错误属于运行脚本；进入 run all 后按
# board milestone、断言和 scoreboard 定位 DUT/验证问题。
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir select_rtds_minimum.tcl]

# ---------- 语义段 0：批处理模式显式建立波形配置 ----------
# XSim batch 通过 -wdb 打开数据库时不会自动创建 GUI wave configuration。
# 若先执行 add_wave，2020.2 会报“no current wave configuration”，而原先
# waves.tcl 的兼容 catch 会把这个问题隐藏，最终 save_wave_config 才失败。
if {[catch {create_wave_config} wave_create_error]} {
    puts "RTDS_WCFG_CREATE_ERROR: $wave_create_error"
    error $wave_create_error
}
puts "RTDS_WCFG_CREATED"

source [file join $script_dir waves.tcl]

# ---------- 语义段 1：保存可独立恢复分组的 WCFG ----------
set log_dir [file normalize [file join $script_dir .. logs]]
file mkdir $log_dir
set wcfg_path [file join $log_dir rtds_minimum.wcfg]
if {[catch {save_wave_config $wcfg_path} wcfg_error]} {
    puts "RTDS_WCFG_SAVE_ERROR: $wcfg_error"
    error $wcfg_error
}
puts "RTDS_WCFG_SAVED: $wcfg_path"

run all
quit
