# gui_init

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\scripts\gui_init.tcl`
- SHA-256: `ab6666b7faae28b5da55fdbed2d10c66ddb24706fef5b91c3ba34c2905779d75`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```tcl
# ---------- 语义段 1：XSim GUI 初始化，不自动开始运行 ----------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir select_rtds_minimum.tcl]
source [file join $script_dir waves.tcl]
puts "RTDS_GUI_READY: 已选择 rtds_minimum 并加载波形，请在 GUI 中点击 Run All"
```
