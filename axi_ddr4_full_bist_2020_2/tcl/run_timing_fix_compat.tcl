set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set project_file [file join $project_root prj compat axi_ddr4_full_bist_compat.xpr]
set report_dir [file join $project_root reports timing_fix2_compat]
set bit_dir [file join $project_root bitstreams timing_fix2_compat]

file mkdir $report_dir
file mkdir $bit_dir
open_project $project_file

# RTL 已变更，必须同时重跑综合和实现，不能复用旧 routed checkpoint。
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Synthesis did not complete successfully"
}

launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1
open_run impl_1

report_timing_summary -delay_type min_max -max_paths 100 -report_unconstrained \
    -file [file join $report_dir timing_summary_routed.rpt]
report_timing -delay_type max -max_paths 100 -nworst 100 \
    -file [file join $report_dir timing_worst100.rpt]
report_clock_interaction -delay_type min_max \
    -file [file join $report_dir clock_interaction.rpt]
report_methodology -file [file join $report_dir methodology.rpt]
report_bus_skew -file [file join $report_dir bus_skew.rpt]
report_drc -file [file join $report_dir drc_routed.rpt]

set worst_path [get_timing_paths -delay_type max -max_paths 1]
set worst_slack [get_property SLACK $worst_path]
puts [format "TIMING_FIX2_COMPAT_WNS=%.3f" $worst_slack]

# Vivado 默认可能在负时序下继续 write_bitstream。本脚本把 WNS 作为硬门槛，
# 只有 setup timing 真正收敛后才生成并发布可上板 bitstream。
if {$worst_slack < 0.0} {
    error [format "Timing failed: WNS %.3f ns; bitstream intentionally not generated" $worst_slack]
}

write_bitstream -force [file join $bit_dir TOP_AXI_DDR4_FULL_BIST.bit]
write_debug_probes -force [file join $bit_dir TOP_AXI_DDR4_FULL_BIST.ltx]
puts "TIMING_FIX2_COMPAT_BITSTREAM_PASS"
close_project
