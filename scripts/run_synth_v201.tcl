# V2.01 综合复跑：TX FIFO 阈值修复(504)后验证整工程综合。
# 清理过 runs 残留后重置 synth_1 并运行；结束时输出进度标记。
set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root RTDS_test_DDR4_64bit.xpr]

reset_runs synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set pro [get_property PROGRESS [get_runs synth_1]]
set needs [get_property NEEDS_REFRESH [get_runs synth_1]]
puts "V201_SYNTH_PROGRESS=$pro NEEDS_REFRESH=$needs"
if {$pro ne "100%"} {
    close_project
    error "V201_SYNTH_FAILED progress=$pro"
}
close_project
puts "V201_SYNTH_OK"
