# run_design_checks_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\run_design_checks_2020_2.tcl`
- SHA-256: `2d9583272e8f9f38119496b79a159802db570d25194431656df485c26416fbc8`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```tcl
if {$argc != 3} {
    error "usage: run_design_checks_2020_2.tcl <10g|1g> <archive-root> <run-synthesis>"
}
set flavor [lindex $argv 0]
set root [file normalize [lindex $argv 1]]
set run_synthesis [lindex $argv 2]
set report_dir [file join $root reports]

if {$flavor eq "10g"} {
    set project [file join $root design aurora_64b66b_10p3125g_design.xpr]
} elseif {$flavor eq "1g"} {
    set project [file join $root design aurora_8b10b_1p25g_design.xpr]
} else {
    error "unknown flavor: $flavor"
}

open_project $project
set top_name [get_property TOP [current_fileset]]

# A generated OOC checkpoint is required for reliable RTL elaboration of the
# Aurora 64B/66B XCI in Vivado 2020.2.
set ip_runs [get_runs -filter {IS_SYNTHESIS == 1 && NAME != synth_1}]
foreach ip_run $ip_runs {
    if {![string match "*Complete*" [get_property STATUS $ip_run]]} {
        launch_runs $ip_run -jobs 4
        wait_on_run $ip_run
        if {![string match "*Complete*" [get_property STATUS $ip_run]]} {
            error "IP synthesis failed: [get_property NAME $ip_run]"
        }
    }
}

synth_design -rtl -name rtl_1 -top $top_name -part xcku040-ffva1156-2-i
report_clocks -file [file join $report_dir ${flavor}_rtl_clocks.rpt]
close_design

set fp [open [file join $report_dir ${flavor}_elaboration.txt] w]
puts $fp "PASS: RTL elaboration"
puts $fp "Vivado: [version -short]"
puts $fp "Top: $top_name"
close $fp

if {$run_synthesis} {
    reset_run synth_1
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    set status [get_property STATUS [get_runs synth_1]]
    set fp [open [file join $report_dir ${flavor}_synthesis_status.txt] w]
    puts $fp $status
    close $fp
    if {![string match "*Complete*" $status]} {
        error "synthesis failed: $status"
    }
    open_run synth_1
    report_utilization -file [file join $report_dir ${flavor}_post_synth_utilization.rpt]
    report_timing_summary -file [file join $report_dir ${flavor}_post_synth_timing_summary.rpt]
    report_drc -file [file join $report_dir ${flavor}_post_synth_drc.rpt]
}

close_project
exit
```
