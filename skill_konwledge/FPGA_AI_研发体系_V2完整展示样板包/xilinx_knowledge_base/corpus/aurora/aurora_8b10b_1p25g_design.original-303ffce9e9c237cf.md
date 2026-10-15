# aurora_8b10b_1p25g_design.original

- Category: `aurora`
- Source: `R:\aurora_8b10b_1p25g_2020_2_verified\design\constraints\aurora_8b10b_1p25g_design.original.xdc`
- SHA-256: `303ffce9e9c237cf6bbb802f64175de839c7c08ddad7ea5eb6f84485c5420aca`
- Extractor: `text`
- Tags: `1.25g, 8b10b, aurora, verified, vivado-2020.2, xdc`
- Duplicate sources:
  - E:\aurora_proc\constraints\aurora_8b10b_1p25g_design.xdc

```tcl
create_clock -name gt_refclk -period 8.000 [get_ports GT_REFCLK_P]
create_clock -name init_clk -period 40.000 [get_ports INIT_CLK_IN]

# Keep the same GTH reference-clock package pins as the existing official
# xcku040-ffva1156-2-i example project.
set_property LOC AF6 [get_ports GT_REFCLK_P]
set_property LOC AF5 [get_ports GT_REFCLK_N]
```
