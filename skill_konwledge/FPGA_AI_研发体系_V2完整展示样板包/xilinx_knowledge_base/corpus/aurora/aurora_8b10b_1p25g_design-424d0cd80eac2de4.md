# aurora_8b10b_1p25g_design

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\design\constraints\aurora_8b10b_1p25g_design.xdc`
- SHA-256: `424d0cd80eac2de4fa1f0ebbcac273599c86ea460bd93eead7707279b336617b`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```tcl
create_clock -name init_clk -period 40.000 [get_ports init_clk_in]
create_clock -name gt_refclk -period 8.000 [get_ports gt_refclk_p]

# Board locations copied from the archived 1G design XDC.
set_property LOC AF6 [get_ports gt_refclk_p]
set_property LOC AF5 [get_ports gt_refclk_n]
```
