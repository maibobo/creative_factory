# Resume implementation from the successfully generated physical-optimization checkpoint.
set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ..]]
set run_dir [file join $root RTDS_test_DDR4_64bit.runs impl_1]
set input_dcp [file join $run_dir TOP_physopt.dcp]
set report_dir [file join $root reports route_resume_20260920]
file mkdir $report_dir

if {![file exists $input_dcp]} {
    error "RTDS_PHYSOPT_DCP_MISSING: $input_dcp"
}

# 单线程续跑用于降低8GB本地主机上的峰值内存，避免路由进程无诊断退出。
set_param general.maxThreads 1
open_checkpoint $input_dcp
route_design
write_checkpoint -force [file join $report_dir TOP_routed.dcp]
report_route_status -file [file join $report_dir route_status.rpt]
report_timing_summary -delay_type min_max -report_unconstrained \
    -check_timing_verbose -max_paths 200 \
    -file [file join $report_dir timing_summary_min_max.rpt]
report_clock_interaction -delay_type min_max \
    -file [file join $report_dir clock_interaction.rpt]
report_drc -file [file join $report_dir drc.rpt]
report_utilization -hierarchical \
    -file [file join $report_dir utilization_hierarchical.rpt]
puts "RTDS_ROUTE_RESUME_ALL_OK"
close_design
exit 0
