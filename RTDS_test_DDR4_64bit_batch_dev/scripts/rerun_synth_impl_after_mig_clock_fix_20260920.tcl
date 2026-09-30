# Re-run synthesis and implementation after correcting the MIG input clock path.
set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ..]]
set report_dir [file join $root reports impl_after_mig_clock_fix_20260920]
file mkdir $report_dir

open_project [file join $root RTDS_test_DDR4_64bit.xpr]
set_property verilog_define {DDR4_REAL} [get_filesets sources_1]

# 本地临时副本只包含 Aurora 1G 的 XCI；每次重跑前补齐输出产物和 OOC DCP，
# 避免综合阶段因 aurora_8b10b_1p25g 模块未生成而提前退出。
set aurora1g_xci [get_files -all */aurora_8b10b_1p25g.xci]
if {[llength $aurora1g_xci] != 1} {
    error "RTDS_AURORA1G_XCI_COUNT_ERROR: expected 1, got [llength $aurora1g_xci]"
}
puts "RTDS_AURORA1G_GENERATE=[lindex $aurora1g_xci 0]"
generate_target all $aurora1g_xci
export_ip_user_files -of_objects $aurora1g_xci -no_script -sync -force -quiet
set aurora1g_ip [get_ips -all aurora_8b10b_1p25g]
if {[llength $aurora1g_ip] != 1} {
    error "RTDS_AURORA1G_IP_COUNT_ERROR: expected 1, got [llength $aurora1g_ip]"
}
synth_ip $aurora1g_ip

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

if {![catch {open_run impl_1} open_error]} {
    report_timing_summary -delay_type min_max -report_unconstrained \
        -check_timing_verbose -max_paths 200 \
        -file [file join $report_dir timing_summary_min_max.rpt]
    report_clock_interaction -delay_type min_max \
        -file [file join $report_dir clock_interaction.rpt]
    report_drc -file [file join $report_dir drc.rpt]
    report_route_status -file [file join $report_dir route_status.rpt]
    report_utilization -hierarchical \
        -file [file join $report_dir utilization_hierarchical.rpt]
} else {
    puts "RTDS_IMPL_OPEN_FAILED=$open_error"
}

if {$impl_progress ne "100%" || ![string match "*Complete*" $impl_status]} {
    error "RTDS_IMPL_FAILED: $impl_status"
}
puts "RTDS_SYNTH_IMPL_ALL_OK"
close_project
exit 0
