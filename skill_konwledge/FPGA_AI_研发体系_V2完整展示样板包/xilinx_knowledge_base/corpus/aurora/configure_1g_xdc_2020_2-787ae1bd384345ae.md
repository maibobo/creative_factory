# configure_1g_xdc_2020_2

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\scripts\configure_1g_xdc_2020_2.tcl`
- SHA-256: `787ae1bd384345aec494766e038d7dd295030bf9ed41d422f3bdece9b7427134`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```tcl
if {$argc != 1} {
    error "usage: configure_1g_xdc_2020_2.tcl <1g-verified-root>"
}

set root [file normalize [lindex $argv 0]]
set report_dir [file join $root reports]
set design_xdc [file join $root design constraints aurora_8b10b_1_exdes.xdc]
set verification_xdc [file join $root verification imports aurora_8b10b_1_exdes.xdc]
file mkdir $report_dir

foreach path [list $design_xdc $verification_xdc] {
    if {![file exists $path]} { error "missing XDC: $path" }
}

set entries [list \
    [list [file join $root design aurora_8b10b_1p25g_design.xpr] $design_xdc 0] \
    [list [file join $root verification aurora_8b10b_1p25g_verification.xpr] $verification_xdc 1]]

set fp [open [file join $report_dir 1g_xdc_import.txt] w]
puts $fp "Authoritative source: C:/project/RTDS/aurora_8b10b_1_ex/imports/aurora_8b10b_1_exdes.xdc"

foreach entry $entries {
    lassign $entry project xdc active_board_top
    open_project $project
    foreach f [get_files -quiet -of_objects [get_filesets constrs_1]] {
        if {[file tail $f] in {aurora_8b10b_1p25g_design.xdc aurora_8b10b_1p25g_exdes.xdc aurora_8b10b_1_exdes.xdc}} {
            remove_files -fileset constrs_1 $f
        }
    }
    add_files -fileset constrs_1 -norecurse $xdc
    set xdc_obj [get_files -quiet $xdc]
    if {$active_board_top} {
        set_property USED_IN_SYNTHESIS true $xdc_obj
        set_property USED_IN_IMPLEMENTATION true $xdc_obj
        puts $fp "Verification: $xdc (active for official exdes board top)"
    } else {
        # The reusable design top uses lowercase, already-buffered clock ports;
        # retain the authoritative board XDC in the project without applying
        # official exdes port constraints to that different top-level shape.
        set_property USED_IN_SYNTHESIS false $xdc_obj
        set_property USED_IN_IMPLEMENTATION false $xdc_obj
        puts $fp "Design: $xdc (imported reference; disabled for reusable top)"
    }
    close_project
}

close $fp
exit 0
```
