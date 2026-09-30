# 上午任务被SSH会话中断后的独立重跑入口。
set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set report_dir [file join $project_root reports impl_20260920_retry]
file mkdir $report_dir

open_project [file join $project_root RTDS_test_DDR4_64bit.xpr]
set_property verilog_define {DDR4_REAL} [get_filesets sources_1]
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]
puts "RTDS_SYNTH_STATUS=$synth_status PROGRESS=$synth_progress"
if {$synth_progress ne "100%" || ![string match "*Complete*" $synth_status]} {
    error "RTDS_SYNTH_FAILED: $synth_status"
}

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]
puts "RTDS_IMPL_STATUS=$impl_status PROGRESS=$impl_progress"

# 实现数据库可打开时，无论bitstream是否通过DRC，都保存诊断报告。
if {[catch {open_run impl_1} open_error]} {
    puts "RTDS_IMPL_OPEN_FAILED=$open_error"
} else {
    report_timing_summary -delay_type min_max -report_unconstrained \
        -check_timing_verbose -max_paths 200 \
        -file [file join $report_dir timing_summary_min_max.rpt]
    report_clock_interaction -delay_type min_max \
        -file [file join $report_dir clock_interaction.rpt]
    report_utilization -hierarchical \
        -file [file join $report_dir utilization_hierarchical.rpt]
    report_drc -file [file join $report_dir drc.rpt]
    report_route_status -file [file join $report_dir route_status.rpt]

    set setup_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
    set hold_path [get_timing_paths -delay_type min -max_paths 1 -nworst 1]
    if {[llength $setup_path] > 0} {
        puts "RTDS_TIMING_SETUP_WNS=[get_property SLACK [lindex $setup_path 0]]"
    }
    if {[llength $hold_path] > 0} {
        puts "RTDS_TIMING_HOLD_WHS=[get_property SLACK [lindex $hold_path 0]]"
    }
}

if {$impl_progress ne "100%" || ![string match "*Complete*" $impl_status]} {
    error "RTDS_IMPL_FAILED: $impl_status"
}
puts "RTDS_SYNTH_IMPL_ALL_OK"
close_project
exit 0
