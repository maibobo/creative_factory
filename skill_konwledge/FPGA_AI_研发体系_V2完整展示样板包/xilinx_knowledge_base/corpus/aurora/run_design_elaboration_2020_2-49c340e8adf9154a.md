# run_design_elaboration_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\run_design_elaboration_2020_2.tcl`
- SHA-256: `49c340e8adf9154a58564f01405df35a14111dc24e974e621c14431f01adc90c`
- Extractor: `text`
- Tags: `1.25g, 10.3125g, 64b66b, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - R:\aurora_8b10b_1p25g_2020_2_verified\scripts\run_design_elaboration_2020_2.tcl

```tcl
if {$argc != 2} {
    error "usage: run_design_elaboration_2020_2.tcl <10g|1g> <verified-root>"
}

set flavor [lindex $argv 0]
set root [file normalize [lindex $argv 1]]
set report_dir [file join $root reports]
file mkdir $report_dir

if {$flavor eq "10g"} {
    set project [file join $root design aurora_64b66b_10p3125g_design.xpr]
    set top_name aurora_64b66b_10p3125g_design
} elseif {$flavor eq "1g"} {
    set project [file join $root design aurora_8b10b_1p25g_design.xpr]
    set top_name aurora_8b10b_1p25g_design
} else {
    error "unknown flavor: $flavor"
}

open_project $project
set simset [get_filesets sim_1]
set_property top $top_name $simset
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Generate simulation products only.  This does not launch an IP OOC
# synthesis run and ensures the XCI is self-contained in this design project.
set ips [get_ips -quiet *]
if {[llength $ips] > 0} {
    generate_target simulation $ips
}

# launch_simulation runs xvlog and xelab.  No synthesis or implementation run
# is launched by this script.
launch_simulation -simset sim_1 -mode behavioral

set fp [open [file join $report_dir ${flavor}_compile_elaboration.txt] w]
puts $fp "PASS: Vivado compile/elaboration"
puts $fp "Vivado: [version -short]"
puts $fp "Project: $project"
puts $fp "Top: $top_name"
puts $fp "Synthesis: NOT RUN (not required)"
puts $fp "Implementation/bitstream: NOT RUN (not required)"
close $fp

close_sim
close_project
exit 0
```
