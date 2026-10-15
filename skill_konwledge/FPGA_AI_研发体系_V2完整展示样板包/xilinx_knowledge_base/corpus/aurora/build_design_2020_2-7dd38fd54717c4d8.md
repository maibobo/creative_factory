# build_design_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\build_design_2020_2.tcl`
- SHA-256: `7dd38fd54717c4d80dbe000c3c708104b605afbaff242a84398d1a6cedbeb5e2`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```tcl
if {$argc != 2} {
    error "usage: build_design_2020_2.tcl <10g|1g> <archive-root>"
}

set flavor [lindex $argv 0]
set root [file normalize [lindex $argv 1]]
set design_dir [file join $root design]
set rtl_dir [file join $design_dir rtl]
set constraint_dir [file join $design_dir constraints]
set report_dir [file join $root reports]
file mkdir $rtl_dir
file mkdir $constraint_dir
file mkdir $report_dir

if {$flavor eq "10g"} {
    set project_name aurora_64b66b_10p3125g_design
    set top_name aurora_64b66b_10p3125g_design
    set sources [list \
        [file join $rtl_dir aurora_64b66b_10p3125g_design.v] \
        [file join $rtl_dir aurora_64b66b_0_exdes.v] \
        [file join $rtl_dir aurora_64b66b_0_example_ll_to_axi.v] \
        [file join $rtl_dir aurora_64b66b_0_example_axi_to_ll.v] \
        [file join $rtl_dir aurora_64b66b_0_cdc_sync_exdes.v]]
    # The archived adapters are plain RTL, so the design project only needs
    # the Aurora core itself.  Debug/register-slice IP remains in verification.
    set xcis [list \
        [file join $design_dir aurora_64b66b_10p3125g_design.srcs sources_1 ip aurora_64b66b_0 aurora_64b66b_0.xci]]
    set xdc [file join $constraint_dir aurora_64b66b_10p3125g_design.xdc]
} elseif {$flavor eq "1g"} {
    set project_name aurora_8b10b_1p25g_design
    set top_name aurora_8b10b_1p25g_design
    set sources [list \
        [file join $rtl_dir aurora_8b10b_1p25g_design.v] \
        [file join $rtl_dir aurora_8b10b_1p25g_ll_to_axi_exdes.v] \
        [file join $rtl_dir aurora_8b10b_1p25g_axi_to_ll_exdes.v]]
    set xcis [list [file join $design_dir project aurora_8b10b_1p25g_design.srcs sources_1 ip aurora_8b10b_1p25g aurora_8b10b_1p25g.xci]]
    set xdc [file join $constraint_dir aurora_8b10b_1p25g_design.xdc]
} else {
    error "unknown flavor: $flavor"
}

foreach path [concat $sources $xcis [list $xdc]] {
    if {![file exists $path]} { error "missing input: $path" }
}

create_project $project_name $design_dir -part xcku040-ffva1156-2-i -force
add_files -norecurse $sources
foreach xci $xcis { import_ip -files $xci }
add_files -fileset constrs_1 -norecurse $xdc
if {$flavor eq "1g"} {
    set xdc_obj [get_files -quiet $xdc]
    set_property USED_IN_SYNTHESIS false $xdc_obj
    set_property USED_IN_IMPLEMENTATION false $xdc_obj
}
set_property top $top_name [current_fileset]
update_compile_order -fileset sources_1

set ips [get_ips]
generate_target all $ips
export_ip_user_files -of_objects $ips -no_script -sync -force -quiet
foreach ip $ips { create_ip_run $ip }

set fp [open [file join $report_dir ${flavor}_design_configuration.txt] w]
puts $fp "Vivado: [version -short]"
puts $fp "Part: [get_property PART [current_project]]"
puts $fp "Top: [get_property TOP [current_fileset]]"
puts $fp "IP: [lsort [get_property NAME $ips]]"
puts $fp "Sources:"
foreach f [lsort [get_files -of_objects [get_filesets sources_1]]] { puts $fp "  $f" }
close $fp

close_project
exit
```
