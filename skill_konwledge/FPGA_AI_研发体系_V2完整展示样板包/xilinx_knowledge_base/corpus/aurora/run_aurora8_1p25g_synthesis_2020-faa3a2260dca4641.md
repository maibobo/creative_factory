# run_aurora8_1p25g_synthesis_2020

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\scripts\run_aurora8_1p25g_synthesis_2020.tcl`
- SHA-256: `faa3a2260dca46410c6a36aedbe48c560d6edf0bac5e76b147bcf64618c9dea7`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, automation, tcl, verified, vivado-2020.2`
- Duplicate sources:
  - E:\aurora_proc\scripts\run_aurora8_1p25g_synthesis_2020.tcl

```tcl
set project_file [file normalize [lindex $argv 0]]
set report_dir [file normalize [lindex $argv 1]]
file mkdir $report_dir

open_project $project_file
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
set fp [open [file join $report_dir synthesis_summary.txt] w]
puts $fp "Vivado: [version -short]"
puts $fp "Project: $project_file"
puts $fp "Synthesis: $synth_status"
close $fp

if {![string match "*Complete*" $synth_status]} {
    error "Synthesis did not complete: $synth_status"
}

open_run synth_1
report_utilization -file [file join $report_dir post_synth_utilization.rpt]
report_timing_summary -file [file join $report_dir post_synth_timing_summary.rpt]
report_drc -file [file join $report_dir post_synth_drc.rpt]

close_project
exit
```
