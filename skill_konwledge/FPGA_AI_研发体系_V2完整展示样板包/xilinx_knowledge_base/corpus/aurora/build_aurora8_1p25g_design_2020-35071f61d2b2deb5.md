# build_aurora8_1p25g_design_2020

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\scripts\build_aurora8_1p25g_design_2020.tcl`
- SHA-256: `35071f61d2b2deb59cb2fd9151e4bd66930cc66f87491abba731ab8d41766b01`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, automation, tcl, verified, vivado-2020.2`
- Duplicate sources:
  - E:\aurora_proc\scripts\build_aurora8_1p25g_design_2020.tcl

```tcl
set output_root [file normalize [lindex $argv 0]]
set run_synthesis [lindex $argv 1]
if {$run_synthesis eq ""} {
    set run_synthesis 1
}
set design_root [file join $output_root design]
set project_dir [file join $design_root project]
set rtl_dir [file join $design_root rtl]
set constraint_dir [file join $design_root constraints]
set report_dir [file join $design_root reports]

set example_root [file join $output_root verification aurora_8b10b_1p25g_ex]
set example_imports [file join $example_root imports]
set source_xci [file join $output_root ip_source aurora_8b10b_1p25g_ip.srcs \
    sources_1 ip aurora_8b10b_1p25g aurora_8b10b_1p25g.xci]

file mkdir $project_dir
file mkdir $rtl_dir
file mkdir $constraint_dir
file mkdir $report_dir

foreach shim {
    aurora_8b10b_1p25g_ll_to_axi_exdes.v
    aurora_8b10b_1p25g_axi_to_ll_exdes.v
} {
    file copy -force [file join $example_imports $shim] [file join $rtl_dir $shim]
}

create_project aurora_8b10b_1p25g_design $project_dir \
    -part xcku040-ffva1156-2-i -force

add_files -norecurse [list \
    [file join $rtl_dir aurora_8b10b_1p25g_design.v] \
    [file join $rtl_dir aurora_8b10b_1p25g_ll_to_axi_exdes.v] \
    [file join $rtl_dir aurora_8b10b_1p25g_axi_to_ll_exdes.v] \
]
import_ip -files $source_xci -name aurora_8b10b_1p25g
add_files -fileset constrs_1 -norecurse \
    [file join $constraint_dir aurora_8b10b_1p25g_design.xdc]

set_property top aurora_8b10b_1p25g_design [current_fileset]
update_compile_order -fileset sources_1

set imported_xci [get_files -of_objects [get_filesets sources_1] \
    -filter {FILE_TYPE == "IP-XACT"}]
generate_target all $imported_xci
export_ip_user_files -of_objects \
    $imported_xci \
    -no_script -sync -force -quiet

set synth_status "Not run (run_synthesis=$run_synthesis)"
if {$run_synthesis} {
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    set synth_status [get_property STATUS [get_runs synth_1]]
    if {[string match "*Complete*" $synth_status]} {
        open_run synth_1
        report_utilization -file [file join $report_dir post_synth_utilization.rpt]
        report_timing_summary -file [file join $report_dir post_synth_timing_summary.rpt]
        report_drc -file [file join $report_dir post_synth_drc.rpt]
    }
}

set source_names [lsort [get_property NAME [get_files -of_objects [get_filesets sources_1]]]]
set fp [open [file join $report_dir build_summary.txt] w]
puts $fp "Vivado: [version -short]"
puts $fp "Part: [get_property PART [current_project]]"
puts $fp "Top: [get_property TOP [current_fileset]]"
puts $fp "Synthesis: $synth_status"
puts $fp "Sources:"
foreach source_name $source_names {
    puts $fp "  $source_name"
}
close $fp

close_project
exit
```
