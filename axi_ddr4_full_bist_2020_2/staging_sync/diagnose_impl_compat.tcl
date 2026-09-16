# Read-only diagnostics for the existing compat implementation.
# This script does not launch synthesis or implementation and does not write a bitstream.

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set xpr_path [file join $project_root prj compat axi_ddr4_full_bist_compat.xpr]
set report_dir [file join $project_root reports timing_diagnosis_20260915]
file mkdir $report_dir

open_project $xpr_path
open_run impl_1

check_timing -verbose -file [file join $report_dir check_timing_verbose.rpt]
report_timing_summary -delay_type max -max_paths 50 \
    -file [file join $report_dir timing_summary_setup.rpt]
report_timing -delay_type max -max_paths 100 -nworst 10 -sort_by group \
    -file [file join $report_dir timing_worst100.rpt]
report_clock_interaction -file [file join $report_dir clock_interaction.rpt]
report_methodology -file [file join $report_dir methodology.rpt]
report_bus_skew -warn_on_violation -file [file join $report_dir bus_skew.rpt]

set port_report [open [file join $report_dir top_port_properties.rpt] w]
foreach port_obj [lsort [get_ports]] {
    puts $port_report "PORT $port_obj"
    foreach property_name {DIRECTION PACKAGE_PIN IOSTANDARD IS_CLOCK} {
        puts $port_report "  $property_name=[get_property $property_name $port_obj]"
    }
}
close $port_report

puts "TIMING_DIAGNOSIS_PASS report_dir=$report_dir"
close_design
close_project
