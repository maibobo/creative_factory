# check_project_2020_2

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\tcl\check_project_2020_2.tcl`
- SHA-256: `6da99800abfb11617f4e639a10f4f3f1330e565d2655c0d044516daf782eae75`
- Extractor: `text`
- Tags: `ddr4, mig, tcl`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\tcl\check_project_2020_2.tcl

```tcl
set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set prj_file   [file join $root_dir prj axi_ddr4_min_2020_2.xpr]
set report_dir [file join $root_dir reports]

file mkdir $report_dir
open_project $prj_file

set ip [get_ips ddr4_axi_0]
puts "VIVADO_VERSION=[version -short]"
puts "PART=[get_property PART [current_project]]"
puts "TOP=[get_property TOP [current_fileset]]"
puts "IP_LOCKED=[get_property IS_LOCKED $ip]"
puts "IP_GENERATE_SYNTH_CHECKPOINT=[get_property GENERATE_SYNTH_CHECKPOINT [get_files ddr4_axi_0.xci]]"
puts "DDR4_INTERFACE_AXI=[get_property CONFIG.C0.DDR4_AxiSelection $ip]"
puts "DDR4_AXI_DATA_WIDTH=[get_property CONFIG.C0.DDR4_AxiDataWidth $ip]"
puts "DDR4_AXI_ADDR_WIDTH=[get_property CONFIG.C0.DDR4_AxiAddressWidth $ip]"
puts "DDR4_MEMORY_PART=[get_property CONFIG.C0.DDR4_MemoryPart $ip]"
puts "DDR4_PHY_DATA_WIDTH=[get_property CONFIG.C0.DDR4_DataWidth $ip]"
foreach run [get_runs] {
    puts "RUN_STATUS=[get_property NAME $run]:[get_property STATUS $run]"
}

report_ip_status -name ip_status -file [file join $report_dir ip_status.rpt]
update_compile_order -fileset sources_1
check_syntax -fileset sources_1

close_project
puts "PROJECT_CHECK_RESULT=PASS"
```
