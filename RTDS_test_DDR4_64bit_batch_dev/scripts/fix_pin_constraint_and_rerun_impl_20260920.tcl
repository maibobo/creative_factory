# Add the board pin constraint file to constrs_1 and rerun implementation only.
set script_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $script_dir ..]]
set xpr [file join $root RTDS_test_DDR4_64bit.xpr]
set pin_xdc [file join $root RTDS_test_DDR4_64bit.srcs constrs_1 new PIN.xdc]
set ddr4_pin_xdc [file join $root RTDS_test_DDR4_64bit.srcs constrs_1 new DDR4_PIN.xdc]
set report_dir [file join $root reports impl_after_pin_constraint_fix_20260920]
file mkdir $report_dir

open_project $xpr
set legacy_pin_file [get_files -quiet -all $pin_xdc]
if {[llength $legacy_pin_file] == 1} {
    remove_files -fileset constrs_1 $legacy_pin_file
}
set ddr4_pin_file [get_files -quiet -all $ddr4_pin_xdc]
if {[llength $ddr4_pin_file] != 1} {
    error "RTDS_DDR4_PIN_XDC_COUNT_ERROR: expected 1, got [llength $ddr4_pin_file]"
}
set_property USED_IN_SYNTHESIS true $ddr4_pin_file
set_property USED_IN_IMPLEMENTATION true $ddr4_pin_file
set_property TARGET_CONSTRS_FILE $ddr4_pin_xdc [get_filesets constrs_1]
puts "RTDS_DDR4_PIN_XDC_ACTIVE=[get_property NAME $ddr4_pin_file]"
puts "RTDS_LEGACY_PIN_XDC_REMOVED=[expr {[llength [get_files -quiet -all $pin_xdc]] == 0}]"

reset_run impl_1
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
puts "RTDS_IMPL_ALL_OK"
close_project
exit 0
