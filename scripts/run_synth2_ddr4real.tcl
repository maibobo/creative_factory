# V2.01 综合复跑第2轮：设置生产宏 DDR4_REAL（排除 4MB 行为RAM，走真实 MIG）。
set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root RTDS_test_DDR4_64bit.xpr]

# 记录并设置综合 verilog 宏：DDR4_REAL=真实 MIG 路径。
# 原工程误带 DDR4_SIM_RAM（4MB 行为RAM→BRAM 超量 2056/1200），
# 两宏互斥，此处直接替换为仅 DDR4_REAL（生产综合配置）。
set cur_def [get_property verilog_define [current_fileset]]
puts "V201_OLD_VERILOG_DEFINE=<$cur_def>"
set_property verilog_define {DDR4_REAL} [current_fileset]
puts "V201_NEW_VERILOG_DEFINE=<[get_property verilog_define [current_fileset]]>"

reset_runs synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set pro [get_property PROGRESS [get_runs synth_1]]
puts "V201_SYNTH2_PROGRESS=$pro"
if {$pro ne "100%"} {
    close_project
    error "V201_SYNTH2_FAILED progress=$pro"
}
close_project
puts "V201_SYNTH2_OK"
