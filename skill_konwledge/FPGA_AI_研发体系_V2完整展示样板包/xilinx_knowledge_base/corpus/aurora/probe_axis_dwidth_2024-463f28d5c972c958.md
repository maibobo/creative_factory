# probe_axis_dwidth_2024

- Category: `aurora`
- Source: `E:\aurora_proc\scripts\probe_axis_dwidth_2024.tcl`
- SHA-256: `463f28d5c972c958f245939ebda6fc277234d551c00e6c014da68f7373ce0366`
- Extractor: `text`
- Tags: `aurora, automation, tcl`
- Duplicate sources:
  - none

```tcl
set work_dir [file normalize [lindex $argv 0]]
file mkdir $work_dir
create_project axis_probe $work_dir \
    -part xcku040-ffva1156-2-i -force

create_ip -name axis_dwidth_converter -vendor xilinx.com -library ip \
    -module_name axis_dwidth_64_to_32
set ip [get_ips axis_dwidth_64_to_32]
puts "---DEFAULTS---"
foreach property [lsort [list_property $ip]] {
    if {[string match "CONFIG.*" $property]} {
        set value [get_property $property $ip]
        if {$value ne ""} {
            puts "$property=$value"
        }
    }
}
set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {8} \
    CONFIG.M_TDATA_NUM_BYTES {4} \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
] $ip
generate_target {instantiation_template} $ip
puts "---CONFIGURED---"
foreach property {
    CONFIG.S_TDATA_NUM_BYTES
    CONFIG.M_TDATA_NUM_BYTES
    CONFIG.HAS_TKEEP
    CONFIG.HAS_TLAST
} {
    puts "$property=[get_property $property $ip]"
}
exit
```
