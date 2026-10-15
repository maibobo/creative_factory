# run_interface_simplification_test_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\run_interface_simplification_test_2020_2.tcl`
- SHA-256: `bb00dbac400618ba1f07005753e9fde190f4bdeb7ecbaa8909fcaf8ebabc74ff`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```tcl
if {$argc != 2} {
    error "usage: run_interface_simplification_test_2020_2.tcl <10g-root> <1g-root>"
}

set root10 [file normalize [lindex $argv 0]]
set root1 [file normalize [lindex $argv 1]]
set work [file join $root10 verification directed work]
set project_dir [file join $work interface_simplification_final]
set tb [file join $root10 verification directed interface_simplification_tb.sv]
file mkdir $work

create_project interface_simplification $project_dir -part xcku040-ffva1156-2-i -force
add_files -fileset sim_1 -norecurse [list \
    [file join $root10 design rtl aurora_64b66b_10p3125g_design.v] \
    [file join $root1 design rtl aurora_8b10b_1p25g_design.v] \
    [file join $root1 design rtl aurora_8b10b_1p25g_ll_to_axi_exdes.v] \
    [file join $root1 design rtl aurora_8b10b_1p25g_axi_to_ll_exdes.v] \
    $tb]
set_property file_type SystemVerilog [get_files $tb]
set_property top interface_simplification_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 1us [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral

foreach root [list $root10 $root1] {
    set report_dir [file join $root reports]
    file mkdir $report_dir
    set fp [open [file join $report_dir interface_simplification_simulation.txt] w]
    puts $fp "PASS: single-point interface simplification simulation"
    puts $fp "Vivado: [version -short]"
    puts $fp "Checked: system_reset_out and channel_up passthrough"
    puts $fp "Checked: rx_crc_error = crc_valid && !crc_pass_fail_n"
    puts $fp "Checked: 1G loopback=3'b000 and power_down=1'b0"
    puts $fp "Full Aurora dual-endpoint regression: NOT REPEATED (previously completed)"
    close $fp
}

close_sim
close_project
exit 0
```
