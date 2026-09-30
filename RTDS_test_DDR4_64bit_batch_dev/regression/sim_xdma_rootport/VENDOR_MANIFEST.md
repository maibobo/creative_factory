# XDMA 2020.2 Root Port 仿真源文件清单

这些文件逐字节复制自 `E:/PCIE-CPU/xdma_0_ex/imports`。该例程是当前 1ch H2C/C2H 配置的官方 XDMA example；这里仅固化 Root Port/TPI 侧代码，不包含示例 Endpoint、`xilinx_dma_pcie_ep.sv`、`xdma_app.v` 或原始 `board.v`。

Vivado 版本：2020.2。

## 清单语义

- 输入：`xdma_0_ex/imports` 中已验证的 Vivado 2020.2 官方 example 源文件。
- 输出：本目录固定的 RP/TPI 文件集合、逐文件大小、SHA-256 和编译顺序。
- 作用：让自研 testbench 可复用真实官方 Root Port，同时保证来源可追溯。
- 失败定位：文件缺失或哈希变化时先核对复制来源和 Vivado 版本；编译顺序错误
  时按本文顺序恢复。不得通过直接修改 vendor 文件绕过自研兼容层问题。

| 文件 | 字节数 | SHA-256 |
|---|---:|---|
| `board_common.vh` | 3817 | `B20103AEF2A42195290A5EBC589950D39C2A9301E52EB1DD67CEF99402C90B09` |
| `pci_exp_expect_tasks.vh` | 55058 | `84B064050F89D7C9C356142ABCA266F4922B85C3BFD5667B17502ABCDA3A5CEC` |
| `pci_exp_usrapp_cfg.v` | 18484 | `913F9EE533DE84E2D57B4E76F1B267B86FB6A81027F7D0450A41A5391C3A6E42` |
| `pci_exp_usrapp_com.v` | 23457 | `118780E5252DB66E4EC9665BB2E0BE5A7F65800331816A0186C2EF3D6EE361F4` |
| `pci_exp_usrapp_rx.v` | 32515 | `51431FC653C1C7164B5214107A472016798AD2309FD13145827DD1F3A99798A9` |
| `pci_exp_usrapp_tx.v` | 308307 | `E34FBE7B8000B674074151E58B90CB54A0521389E38E3B40AB54504232F595FB` |
| `pcie3_uscale_rp_core_top.v` | 1939146 | `339735923F9F39661C31B1449AD4F6322FF682AE4D500EFF439A81279C5FEF1F` |
| `pcie3_uscale_rp_top.v` | 40067 | `B36E52231D47D49A116FA6D8EAB17B5075BD7735F343994A8672365A3D720D4F` |
| `sys_clk_gen_ds.v` | 3044 | `BC1E17C2FD083E30B30C194F183FEAD35B050B9902106CE7A042D5B5CC048DB2` |
| `sys_clk_gen.v` | 2906 | `7FAD6E89C90DAC7F39A08494B5AA4DD100C38D3FA9A7DDFC1C7002FAE6268A44` |
| `xilinx_pcie_uscale_rp.v` | 32536 | `1457E963F428471B0D9F64D9327DFA3B3E46B8CCBAB3407FE079DB7F8C3817BE` |

## 官方编译顺序

1. `pci_exp_usrapp_cfg.v`
2. `pci_exp_usrapp_com.v`
3. `pci_exp_usrapp_rx.v`
4. `pci_exp_usrapp_tx.v`
5. `pcie3_uscale_rp_core_top.v`
6. `pcie3_uscale_rp_top.v`
7. `sys_clk_gen.v`
8. `sys_clk_gen_ds.v`
9. `xilinx_pcie_uscale_rp.v`

`board_common.vh`、`pci_exp_expect_tasks.vh` 和本目录上层自定义的 `tests.vh` 通过 include 路径参与编译。
