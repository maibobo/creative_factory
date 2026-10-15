# run_aurora8_1p25g_verification_2020

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\scripts\run_aurora8_1p25g_verification_2020.tcl`
- SHA-256: `b69b1ad4b129cbc57a53995e1b0737392bb7cc96e5452f85373e2845777f4953`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, automation, tcl, verified, vivado-2020.2`
- Duplicate sources:
  - E:\aurora_proc\scripts\run_aurora8_1p25g_verification_2020.tcl

```tcl
set project_file [file normalize [lindex $argv 0]]
set report_file [file normalize [lindex $argv 1]]

open_project $project_file
set_property xsim.simulate.runtime {10 ms} [get_filesets sim_1]
launch_simulation
run all

set fp [open $report_file w]
puts $fp "Vivado: [version -short]"
puts $fp "Project: $project_file"
puts $fp "Simulation completed: yes"
puts $fp "Simulation time: [current_time]"
close $fp

close_sim
close_project
exit
```
