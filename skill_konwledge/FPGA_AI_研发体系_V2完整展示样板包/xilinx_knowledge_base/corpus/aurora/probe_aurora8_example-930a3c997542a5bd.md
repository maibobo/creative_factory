# probe_aurora8_example

- Category: `aurora`
- Source: `E:\aurora_proc\scripts\probe_aurora8_example.tcl`
- SHA-256: `930a3c997542a5bdb71cfd68013a8e384751db94fcc1a4616d75e7b4bb5b26b8`
- Extractor: `text`
- Tags: `aurora, automation, tcl`
- Duplicate sources:
  - none

```tcl
set work_dir [file normalize [lindex $argv 0]]
file mkdir $work_dir

create_project aurora8_probe [file join $work_dir ip_project] \
    -part xcku040-ffva1156-2-i -force

create_ip -name aurora_8b10b -vendor xilinx.com -library ip \
    -version 11.1 -module_name aurora_8b10b_0

set aurora_ip [get_ips aurora_8b10b_0]
set_property -dict [list \
    CONFIG.C_AURORA_LANES {1} \
    CONFIG.C_LANE_WIDTH {4} \
    CONFIG.C_LINE_RATE {1.25} \
    CONFIG.C_REFCLK_FREQUENCY {156.25} \
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
    CONFIG.C_START_QUAD {Quad_X0Y2} \
    CONFIG.C_START_LANE {X0Y8} \
    CONFIG.C_REFCLK_SOURCE {MGTREFCLK1 of Quad X0Y2} \
] $aurora_ip

generate_target all $aurora_ip
open_example_project -force -dir [file join $work_dir example] $aurora_ip
close_project
exit
```
