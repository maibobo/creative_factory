# run_adapter_10g_test_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\run_adapter_10g_test_2020_2.tcl`
- SHA-256: `8af9f720edb057c11c53d17df9441fdab2f76b572823d476932d3ac547598327`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```tcl
if {$argc != 1} { error "usage: <archive-root>" }
set root [file normalize [lindex $argv 0]]
set work [file join $root verification directed work]
file mkdir $work
create_project adapter_10g_directed $work -part xcku040-ffva1156-2-i -force
add_files -fileset sim_1 -norecurse [list \
  [file join $root design rtl aurora_64b66b_0_example_ll_to_axi.v] \
  [file join $root design rtl aurora_64b66b_0_example_axi_to_ll.v] \
  [file join $root verification directed adapter_10g_tb.sv]]
set_property top adapter_10g_tb [get_filesets sim_1]
set_property xsim.simulate.runtime 20us [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
close_sim
close_project
exit 0
```
