# check_license_2020_2

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\tcl\check_license_2020_2.tcl`
- SHA-256: `957f33e2aeb5080f80304ecca9a908d813327bb7d20891d5effcb1ad21097be8`
- Extractor: `text`
- Tags: `ddr4, mig, tcl`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\tcl\check_license_2020_2.tcl

```tcl
set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]

create_project -in_memory -part xcku040-ffva1156-2-i
read_verilog [file join $root_dir rtl axi_ddr_bist.v]
synth_design -top axi_ddr_bist -mode out_of_context

puts "LICENSE_SYNTH_RESULT=PASS"
puts "LICENSE_SYNTH_PART=[get_property PART [current_project]]"
puts "LICENSE_SYNTH_TOP=[get_property TOP [current_design]]"
```
