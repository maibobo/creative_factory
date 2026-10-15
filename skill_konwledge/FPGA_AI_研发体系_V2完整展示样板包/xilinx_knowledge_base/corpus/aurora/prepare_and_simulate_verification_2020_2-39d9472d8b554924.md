# prepare_and_simulate_verification_2020_2

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\prepare_and_simulate_verification_2020_2.tcl`
- SHA-256: `39d9472d8b55492410871fc2cfdc4c9f30a3c55b0f5ace39984c351cb8781751`
- Extractor: `text`
- Tags: `1.25g, 10.3125g, 64b66b, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - R:\aurora_8b10b_1p25g_2020_2_verified\scripts\prepare_and_simulate_verification_2020_2.tcl

```tcl
if {$argc != 2} {
  puts "ERROR: usage: vivado -mode batch -source prepare_and_simulate_verification_2020_2.tcl -tclargs <project.xpr> <report_dir>"
  exit 2
}

set project_xpr [file normalize [lindex $argv 0]]
set report_dir [file normalize [lindex $argv 1]]
file mkdir $report_dir

open_project $project_xpr
set ips [get_ips -quiet *]
if {[llength $ips] == 0} {
  puts "ERROR: no IP found in $project_xpr"
  exit 3
}

generate_target all $ips
export_ip_user_files -of_objects $ips -no_script -sync -force -quiet

set hash_file [open [file join $report_dir verification_ip_properties.txt] w]
foreach ip $ips {
  puts $hash_file "IP=[get_property NAME $ip]"
  foreach property {VLNV IP_FILE CONFIG.Component_Name CONFIG.C_AURORA_LANES CONFIG.C_LINE_RATE CONFIG.C_REFCLK_FREQUENCY CONFIG.C_INTERFACE_MODE CONFIG.C_DATA_FLOW_CONFIG CONFIG.C_CRC_MODE CONFIG.C_USE_BYTESWAP CONFIG.C_USER_K CONFIG.C_USER_DATA_WIDTH} {
    set value [get_property -quiet $property $ip]
    if {$value ne ""} { puts $hash_file "$property=$value" }
  }
}
close $hash_file

set simset [get_filesets sim_1]
set sim_top [get_property TOP $simset]
puts "INFO: launching behavioral simulation top=$sim_top"
set_property xsim.simulate.runtime 100us $simset
launch_simulation -simset sim_1 -mode behavioral
close_sim
close_project
exit 0
```
