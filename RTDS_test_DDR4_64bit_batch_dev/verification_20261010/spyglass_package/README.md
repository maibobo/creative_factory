# RTDS 当前代码的 SpyGlass 静态检查包

源工程：Win11 `C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev`。
整理日期：2026-10-10（Asia/Shanghai）。虚拟机：`autumn@bogon`，当前 DHCP 地址 `192.168.56.133`。
目标工具：SpyGlass `Q-2020.03-SP2-3`，CentOS 7；不要求 Linux Vivado。

## 范围与模型

`full.f` 是 Linux 相对路径文件清单，`projects/top.prj` 检查实际 `TOP` 层次，`projects/one_g.prj` 用于独立检查新 1G 发送模块。

| 内容 | 处理方式 | 可以检查的范围 |
| --- | --- | --- |
| TOP、PCIe、Adapter、INFO_EXCH、CONV_DMA、RX writer/FIFO、1G 发送、节拍及复位逻辑 | 当前源文件原样复制 | 自写 RTL 的连接、状态和跨域结构 |
| BD design_1 与两项自写模块的 generated wrapper | 保留实际连接及 INFO_EXCH/CONV_DMA 实现 | 业务逻辑及裸 IRQ 与 XDMA 端口的边界 |
| XPM CDC single/gray/handshake/reset | 复制 Vivado 2020.2 的实际 `xpm_cdc.sv` | 同步级、Gray 编码和握手结构，未用直连替代 |
| XDMA、MIG、AXI clock converter、BD xbar、Clock Wizard、SysMon、ILA | 当前生成的 stub | 边界端口宽度和外部连接；不检查 IP 内部 |
| Aurora 10G/1G 的物理设计 wrapper | 从当前模块头提取同名、同参数、同端口黑盒 | 检查业务模块到 wrapper 的接口；wrapper 内初始化、LL/AXIS 转换和 GT/IP 内部不在本包覆盖内 |
| XPM async FIFO | 从 2020.2 XPM 定义提取参数化黑盒 | 各侧业务及端口时钟契约；不能用本包证明 FIFO 内部指针和数据存储跨域安全 |
| IBUFDS | O=I 的连接模型 | 单端时钟连通；不模拟差分电气特性 |
| BUFGCE_DIV | 专用时钟宏黑盒，25 MHz 输出在 SGDC 单独声明 | 下游初始化 RTL；不模拟分频器内部 |

`manifest/blackboxes.txt` 列出全部黑盒；`source_manifest.json` 记录源文件和包文件 SHA-256。
`DDR4_REAL` 保留真实后端分支，避免行为 RAM 替代 MIG UI/AXI converter 后掩盖跨域边界。
`ONESPIN` 选用 XPM 文件已有的静态分析分支，排除 `glbl` / `force` / `release` 仿真初始化处理；不修改同步器电路。启用 `enableSV09` 以兼容该版本 XPM 的 SystemVerilog 语法。

## 运行

在虚拟机中：

```bash
cd /home/autumn/projects/pcie_cpu_spyglass_20261010
python3 scripts/verify_package.py
bash scripts/run_spyglass.sh top lint/lint_rtl
bash scripts/run_spyglass.sh top cdc/cdc_setup_check
bash scripts/run_spyglass.sh top cdc/cdc_verify_struct
bash scripts/run_spyglass.sh one_g cdc/cdc_verify_struct
```

依赖原有 Synopsys 环境中的 `SPYGLASS_HOME` 和许可证服务。此次虚拟机启动后服务未运行，已按原有 `Synopsys.dat` 启动已有 `lmgrd`，没有修改许可证文件或安装工具。
许可证启动记录在 `logs/license_start.log`。重启虚拟机后若再次发生 license failure，应先确认原服务状态，避免重复启动服务。

## CDC 结论的边界

`constraints/top.sgdc` 明确业务 250 MHz、XDMA 250 MHz、MIG UI 约 300 MHz、Aurora 10G 156.25 MHz、1G 31.25 MHz及辅助时钟。相同频率不自动合并为同域；当前采用保守的独立时钟设置。Clock Wizard 输出的实际相位和同源关系应在后续约束收敛时结合 IP 参数及 Vivado 时钟报告复核。

`abstract_port` 表示黑盒接口所属时钟和复位，是本包的检查假设。SpyGlass 会把已约束到用户时钟的黑盒复位输出视为对该域安全；这不代表已经验证 IP 内部，必须复核 Aurora/MIG 的复位解除语义。MIG 校准/状态、异步复位传播、GT 初始化控制以及物理串行输入仍需要进一步审查边界契约。没有加入覆盖所有跨域路径的 `false_path` 或 CDC waiver。

检查可以实际运行、读入无 Fatal，与 lint/CDC 全部收敛是两件事。应继续审查 `moresimple.rpt`、`CDC-report.rpt` 和每项告警，尤其保持型 IRQ 到 XDMA 的时钟契约、参数握手数据、异步 FIFO 黑盒边界以及复位汇合。最终 TOP 结构检查为 66 Error / 46 Warning、63 条未同步跨域和 8 项汇合；独立 1G 为 0 Error / 11 Warning。详细结果见本目录内的《回归与SpyGlass整理报告_20261010.md》和 `results/spyglass_summary.json`。

## 是否安装 Linux Vivado 2020.2

为本次 lint/结构 CDC，不需要先安装：所需可读业务 RTL、BD wrapper 和 IP stub 已能由 Win11 的现有 Vivado 2020.2 取得，安装 Linux 版本也不能自动解决 IP 的抽象时钟/复位契约或解除加密。

如果后续希望在虚拟机执行真实 XDMA/MIG/GT 的 VCS 动态仿真，再考虑 Linux Vivado 2020.2，用 `compile_simlib -simulator vcs_mx` 生成与当前 VCS 匹配的 Xilinx 仿真库，或从兼容 Linux 环境复制已编译库。此需求不同于静态 CDC：Windows 的仿真二进制不能直接作为 Linux VCS 库使用。

官方参考：[AMD IP 第三方工具 stub 流程](https://docs.amd.com/r/2023.2-English/ug896-vivado-ip/Third-Party-Synthesis-Flow)、[Vivado 2020.2 compile_simlib](https://docs.amd.com/r/2020.2-English/ug835-vivado-tcl-commands/compile_simlib)、[Synopsys CDC 约束检查](https://www.synopsys.com/webinars/constraints-driven-cdc-and-rdc-verification.html)。
