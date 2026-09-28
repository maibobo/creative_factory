# XSim GUI 初始化脚本。
# 输入：已展开 board snapshot；输出：选择 rtds_minimum、加载精选波形并停在运行前。
# 作用：允许用户检查分组后手工 Run All；不会自动改 DUT 或开始仿真。
# 失败定位：source 失败分别检查 select_rtds_minimum.tcl 和 waves.tcl。
# ---------- 语义段 1：XSim GUI 初始化，不自动开始运行 ----------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir select_rtds_minimum.tcl]
source [file join $script_dir waves.tcl]
puts "RTDS_GUI_READY: 已选择 rtds_minimum 并加载波形，请在 GUI 中点击 Run All"
