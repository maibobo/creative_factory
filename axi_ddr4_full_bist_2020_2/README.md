# KU040 自研板 AXI DDR4 全空间 BIST

本目录是从 `axi_ddr4_min_2020_2` 派生的独立工程，用于同一块 KU040 自研板上四颗 GDQ3BFAM-WJ（x16×4、物理 64 bit、总容量 4 GB）的 DDR4 验证。原最小工程、第 32 章 Native APP Demo 和板上 PCIe/Aurora/以太网工程均未修改。

当前交付范围固定为工程生成、RTL 编译、Elaborate 和行为级基本冒烟。没有完成综合、实现、时序、DRC、bitstream 或上板测试，`bitstreams` 目录应为空。

## 目录

- `rtl`：可综合 Verilog-2001 顶层和 AXI BIST。
- `sim`：SystemVerilog AXI RAM 模型与自检 testbench。
- `constr`：与已上板 Demo/原最小工程一致的 XDC。
- `ip`：GD 自定义颗粒 CSV、保守 2133 fallback 和兼容配置来源 XCI。
- `tcl`：工程重建、Elaborate、行为仿真脚本；`future_*_NOT_RUN.tcl` 只供以后明确授权时使用。
- `prj/compat`：Micron 别名兼容工程 XPR。
- `prj/gd2400`：GD DDR4-2400 正式参数工程 XPR。
- `reports`、`logs`：本轮编译、Elaborate 和仿真证据。
- `docs`：管脚审计、验证记录和上板操作指南。
- `manifest`：关键文件 SHA-256 清单。

## 已执行命令

远端 Vivado 固定为 `C:\Xilinx\Vivado\2020.2\bin\vivado.bat`。

```powershell
vivado.bat -mode batch -source tcl\create_project.tcl -tclargs compat
vivado.bat -mode batch -source tcl\create_project.tcl -tclargs gd2400
vivado.bat -mode batch -source tcl\elaborate_project.tcl -tclargs compat
vivado.bat -mode batch -source tcl\elaborate_project.tcl -tclargs gd2400
vivado.bat -mode batch -source tcl\run_behavior_sim.tcl
```

这里的 Elaborate 使用 `synth_design -rtl` 只建立 RTL elaborated design，不运行项目 `synth_1`，不生成综合网表。

## 打开工程

安装 Vivado 2020.2 后可直接打开：

- `prj\compat\axi_ddr4_full_bist_compat.xpr`
- `prj\gd2400\axi_ddr4_full_bist_gd2400.xpr`

轻量本机备份不带 `.runs`、`.cache` 和完整 `.gen` 时，XPR 仍可打开，但 Vivado 会提示部分 IP output products 不存在。执行 Generate Output Products 即可按 XCI/Tcl 重建；这属于轻量备份的预期提示，不代表源文件损坏。

## 当前结果

- `compat` 工程生成：PASS。
- `gd2400` 自定义颗粒工程生成：PASS。
- 两个 profile RTL Elaborate：PASS。
- 32-word、4096-word 和缩小地址空间的 8 模式行为回归：PASS。
- 响应错误、数据注错和超时负例：均被正确检出。
- 综合/实现/bitstream/上板：NOT RUN。

详细证据见 `docs/KU040_DDR4全空间复核与验证记录.md`。
