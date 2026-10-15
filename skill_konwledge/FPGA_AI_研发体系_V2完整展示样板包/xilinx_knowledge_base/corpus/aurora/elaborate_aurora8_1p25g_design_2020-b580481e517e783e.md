# elaborate_aurora8_1p25g_design_2020

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\scripts\elaborate_aurora8_1p25g_design_2020.tcl`
- SHA-256: `b580481e517e783e8dbb1fc64ce6aa5ac1f654b9bf9bf9c98f9bb586f0c25ec5`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, automation, tcl, verified, vivado-2020.2`
- Duplicate sources:
  - E:\aurora_proc\scripts\elaborate_aurora8_1p25g_design_2020.tcl

```tcl
set project_file [file normalize [lindex $argv 0]]
set report_file [file normalize [lindex $argv 1]]

open_project $project_file
set_property top aurora_8b10b_1p25g_design [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -mode behavioral
run 1 ns

set fp [open $report_file w]
puts $fp "Vivado: [version -short]"
puts $fp "Top: [get_property TOP [get_filesets sim_1]]"
puts $fp "Behavioral elaboration: PASS"
puts $fp "Simulation time: [current_time]"
close $fp

close_sim
close_project
exit
```
