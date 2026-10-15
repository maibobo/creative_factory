# generate_aurora8_1p25g_2020

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\scripts\generate_aurora8_1p25g_2020.tcl`
- SHA-256: `bef2e36c200cbce767a2baf1d32497d8e8c7d4e5d49bdef7aedc7451d52a8dce`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, automation, tcl, verified, vivado-2020.2`
- Duplicate sources:
  - E:\aurora_proc\scripts\generate_aurora8_1p25g_2020.tcl
  - E:\aurora_proc\scripts\generate_aurora8_1p25g_2024.tcl

```tcl
set output_root [file normalize [lindex $argv 0]]
set ip_project_dir [file join $output_root ip_source]
set example_dir [file join $output_root verification]

file mkdir $output_root

create_project aurora_8b10b_1p25g_ip $ip_project_dir \
    -part xcku040-ffva1156-2-i -force

create_ip -name aurora_8b10b -vendor xilinx.com -library ip \
    -version 11.1 -module_name aurora_8b10b_1p25g

set aurora_ip [get_ips aurora_8b10b_1p25g]
set_property -dict [list \
    CONFIG.C_AURORA_LANES {1} \
    CONFIG.C_LANE_WIDTH {4} \
    CONFIG.C_LINE_RATE {1.25} \
    CONFIG.C_REFCLK_FREQUENCY {125} \
    CONFIG.C_INIT_CLK {25.0} \
    CONFIG.Dataflow_Config {Duplex} \
    CONFIG.Interface_Mode {Framing} \
    CONFIG.Flow_Mode {None} \
    CONFIG.C_USE_CRC {true} \
    CONFIG.C_USE_SCRAMBLER {false} \
    CONFIG.C_USE_BYTESWAP {false} \
    CONFIG.SupportLevel {1} \
    CONFIG.SINGLEEND_INITCLK {true} \
    CONFIG.SINGLEEND_GTREFCLK {false} \
    CONFIG.C_START_QUAD {Quad_X0Y0} \
    CONFIG.C_START_LANE {X0Y0} \
    CONFIG.C_REFCLK_SOURCE {MGTREFCLK0 of Quad X0Y0} \
] $aurora_ip

validate_ip $aurora_ip
generate_target all $aurora_ip
open_example_project -force -dir $example_dir $aurora_ip
close_project
exit
```
