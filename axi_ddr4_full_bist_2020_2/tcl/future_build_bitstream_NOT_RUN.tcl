# Future-only synthesis, implementation, and bitstream helper.
# This script is intentionally NOT part of the current compile/elaborate/smoke scope.
# To run it in a later authorized task, set ALLOW_SYNTH=1 explicitly.
# Usage: vivado -mode batch -source future_build_bitstream_NOT_RUN.tcl -tclargs compat|gd2400|gd2133

if {![info exists ::env(ALLOW_SYNTH)] || $::env(ALLOW_SYNTH) ne "1"} {
    error "Synthesis is disabled. Set ALLOW_SYNTH=1 only after explicit authorization."
}

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set profile_name [lindex $argv 0]
if {$profile_name eq ""} {
    error "Missing build profile"
}

set project_name "axi_ddr4_full_bist_${profile_name}"
set xpr_path [file join $project_root prj $profile_name $project_name.xpr]
if {![file exists $xpr_path]} {
    error "Project does not exist: $xpr_path"
}

open_project $xpr_path
set report_dir [file join $project_root reports $profile_name]
set bitstream_dir [file join $project_root bitstreams]
file mkdir $report_dir
file mkdir $bitstream_dir

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {![string match {*Complete*} [get_property STATUS [get_runs synth_1]]]} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
open_run synth_1
report_utilization -file [file join $report_dir post_synth_utilization.rpt]
report_drc -file [file join $report_dir post_synth_drc.rpt]
close_design

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {![string match {*Complete*} [get_property STATUS [get_runs impl_1]]]} {
    error "Implementation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose \
    -max_paths 20 -file [file join $report_dir timing_summary.rpt]
report_drc -file [file join $report_dir final_drc.rpt]
report_route_status -file [file join $report_dir route_status.rpt]
report_utilization -file [file join $report_dir implemented_utilization.rpt]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set worst_slack [get_property SLACK $worst_path]
if {$worst_slack < 0.0} {
    error "Negative setup slack: $worst_slack ns"
}

set output_bit [file join $bitstream_dir "TOP_AXI_DDR4_FULL_BIST_${profile_name}.bit"]
set output_ltx [file join $bitstream_dir "TOP_AXI_DDR4_FULL_BIST_${profile_name}.ltx"]
set run_dir [get_property DIRECTORY [get_runs impl_1]]
set run_bit [file join $run_dir TOP_AXI_DDR4_FULL_BIST.bit]
if {![file exists $run_bit]} {
    error "Expected bitstream not found: $run_bit"
}
file copy -force $run_bit $output_bit
set run_ltx [file join $run_dir debug_nets.ltx]
if {[file exists $run_ltx]} {
    file copy -force $run_ltx $output_ltx
}

puts "BITSTREAM_BUILD_PASS profile=$profile_name bit=$output_bit"
close_project
