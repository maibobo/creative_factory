# RTDS_test_XDMA_RootPort中文语义注释覆盖清单

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort中文语义注释覆盖清单.md`
- SHA-256: `0052e1a840585599cc6495c34a7130dab96bcb918945bbfc045b0fe46b886f6d`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test XDMA Root Port 中文语义注释覆盖清单

更新日期：2026-07-28
适用工程：`RTDS_test-1ch`
适用仿真：`RTDS_test-1ch/regression/sim_xdma_rootport`
工具版本：Vivado 2020.2

## 1. 注释目标和阅读方法

本轮注释不是逐行翻译 HDL，而是按可调试的逻辑阶段解释：

- **输入**：本阶段消费哪些命令、状态、数据或握手。
- **输出**：本阶段产生哪些请求、数据、状态或验证证据。
- **作用**：本阶段在完整 PCIe、FDMA、Aurora 数据流中的职责。
- **失败定位**：出现超时、数据错、中断不清或握手停滞时，先观察哪些信号、再进入哪个模块。

阅读时先从 `PCIe.v` 看系统连接，再进入
`pcie_fdma_aurora_brg_adapter.v` 看双向数据和状态控制，寄存器行为进入
`INFO_EXCH.v`。验证侧从 `tb/board.sv` 看测试平台总装，从
`tb/tests.vh` 看测试顺序，再按 monitor、BFM、assertion 定位证据来源。

## 2. 重点生产设计

### 2.1 `pcie_fdma_aurora_brg_adapter.v`

路径：
`RTDS_test-1ch/RTDS_test.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v`

已按以下十个语义阶段解释：

1. 静态参数和地址窗口自检。
2. PCIe、Aurora 链路状态跨时钟域。
3. CPU→Aurora 命令、地址和长度校验。
4. FDMA read 到 Aurora TX LocalLink。
5. TX 帧完成跨域及 `CPU_WR_DONE_resp`。
6. 无 FPGA 侧反压能力的 Aurora RX 到 FDMA write。
7. RX 缓冲区所有权、INFO_EXCH 状态及用户 IRQ。
8. read-to-clear 命令跨域。
9. Aurora 域协议检查及 sticky 状态。
10. FDMA 域 sticky 汇总、clear hold 和 watchdog。

特别注明：Aurora→FPGA 方向不能依靠 FPGA 对串行源实施反压。
`rx_dst_rdy_n` 的下降应视为容量规划或协议失败证据，验证环境不会把
“等待 ready 后再发送”当作合法行为。

### 2.2 `PCIe.v`

路径：`RTDS_test-1ch/RTDS_test.srcs/sources_1/new/PCIe.v`

已解释固定参数和地址窗口、BD/Adapter 语义网络、Adapter 实例、ILA
观测和真实 `design_1_wrapper` 五个阶段。注释明确区分：

- ILA 只增加硬件可观测性，不参与数据或控制闭环。
- 枚举、BAR、AXI 问题进入 XDMA/BD 排查。
- LL、FDMA、IRQ 状态转换问题进入 Adapter 对应阶段排查。

### 2.3 `INFO_EXCH.v`

路径：`RTDS_test-1ch/RTDS_test.srcs/sources_1/new/INFO_EXCH.v`

已按 AXI-Lite 的 AW/W、B、AR、R 通道和寄存器语义拆分为十一个阶段，
并单独解释：

- `0x10` 的真实读握手产生 read-to-clear。
- `0x20` 的 `0→1` 边沿产生 `RD_START`，连续写 1 不会重复触发。
- `0x14/0x20/0x24/0x28` 的软件写和 `WSTRB` 字节使能。
- 内部寄存器偏移与 BD 绝对地址的区别。

## 3. 自研验证文件覆盖

以下 29 个文件均具有中文文件头或模块头，并至少包含一个明确的
“语义段”、输入/输出说明和失败定位。Xilinx 官方文件、BD/IP 自动生成
文件、编译产物、WDB 和日志不在本表内。

### 3.1 Testbench、BFM、monitor 和 assertion

| 文件 | 主要职责 | 首要失败定位 |
|---|---|---|
| `tb/board.sv` | RP、真实 Endpoint、LL BFM、monitor、assertion 和 test 总装 | 先按 link、BAR、DMA、LL、IRQ 里程碑缩小阶段 |
| `tb/tests.vh` | `rtds_minimum` 用例流程和最终 PASS 判定 | 看最后一个成功里程碑及阶段 timeout |
| `tb/rtds_rootport_pkg.sv` | 地址、长度、结果统计和公共常量 | 常量与设计地址不一致 |
| `tb/rtds_pcie_ep_sim_wrapper.sv` | 真实 `PCIe` Endpoint 的仿真适配 | RP 串行端口或时钟复位映射 |
| `tb/aurora_ll_peer_bfm.sv` | 消费 TX、无反压注入 RX、记录字节流 | LL SOF/EOF、rem、字节计数或非法 ready |
| `tb/pcie_cq_host_memory_monitor.sv` | 捕获 Endpoint 发出的 C2H Memory Write TLP | CQ SOP、byte enable、地址或 payload |
| `tb/xdma_axi_activity_monitor.sv` | 观察 XDMA 本地 AXI 活动以替代高频 PCIe 轮询 | descriptor 已启动但无本地 AXI 事件 |
| `tb/conv_dma_axi_monitor.sv` | 观察 CONV_DMA 侧事务 | FDMA 请求存在但 AXI 无活动 |
| `tb/xdma_irq_monitor.sv` | bind 观察 `usr_irq_req/ack` 和 MSI enable | 请求、使能、ack 三者证据链中断 |
| `tb/rtds_rootport_assertions.sv` | LL、FDMA、X/Z、状态和超时断言 | 以 assertion 名和触发阶段直接回溯 |

### 3.2 仿真准备、运行和波形 Tcl

| 文件 | 主要职责 |
|---|---|
| `scripts/audit_and_prepare.tcl` | 审计 1ch、Gen3 x2、AXI、BAR 和 IP target |
| `scripts/prepare_rootport_sim.tcl` | 在内存 fileset 组装真实 DUT、官方 RP 和自研 TB |
| `scripts/select_rtds_minimum.tcl` | 注入 `TESTNAME=rtds_minimum` |
| `scripts/run.tcl` | 标准 WaveMode 运行入口 |
| `scripts/run_fast.tcl` | FastMode 运行入口 |
| `scripts/waves.tcl` | 精选波形分组和 WCFG 保存 |
| `scripts/gui_init.tcl` | XSim GUI 初始化 |
| `scripts/open_final_wdb.tcl` | 只读打开最终 WDB/WCFG |

### 3.3 日志门禁和最终归档

| 文件 | 主要职责 |
|---|---|
| `scripts/compare_logs.ps1` | 语义里程碑、错误和 warning 白名单门禁 |
| `scripts/finalize_wave_run.ps1` | 验收 WDB/WCFG/summary 并生成 SHA-256 归档 |

### 3.4 本地和远端运行入口

| 文件 | 主要职责 |
|---|---|
| `run_xsim.ps1` | Vivado 2020.2 编译、展开、运行和超时控制主入口 |
| `run_xsim_detached.ps1` | 启动可断开 SSH 的工作器并维护状态文件 |
| `remote_run_worker.ps1` | 远端实际执行与 detached 状态落盘 |
| `launch_breakaway.ps1` | 用 `CREATE_BREAKAWAY_FROM_JOB` 脱离 SSH Job |
| `start_remote_run.ps1` | 远端运行启动封装 |
| `run_remote_foreground.ps1` | 前台调试入口 |
| `rtds_rootport_task.ps1` | 状态检查、任务控制和摘要 |
| `open_xsim_gui.ps1` | 打开现有 snapshot 的调试 GUI |
| `open_final_wdb.ps1` | 只读打开最终验收波形，不重跑仿真 |

### 3.5 配置和来源清单

| 文件 | 注释方式和职责 |
|---|---|
| `config/warning_whitelist.txt` | `#` 中文语义段；解释日志输入、精确正则输出、门禁作用和新增 warning 的失败定位 |
| `VENDOR_MANIFEST.md` | 解释官方来源输入、固定文件/哈希输出、编译顺序和哈希异常定位 |

## 4. 明确不批量加注释的范围

以下文件不做中文批量修改：

- `vendor/xdma_rp_2020_2` 中的 Xilinx Root Port、TPI/USRAPP 和公共模型。
- `RTDS_test.srcs/sources_1/bd` 下的 Block Design/IP 自动生成 RTL。
- Xilinx FIFO、XDMA、GT、AXI 基础库和 simulation model。
- `work`、`.Xil`、`logs`、WDB、WCFG 和其他生成物。
- 与本次 Root Port 大仿真无关、且没有被后续集成修改的历史 RTL。

原因不是这些文件不重要，而是批量改动会破坏官方来源哈希、升级可比性、
重新生成能力和日志基线。需要解释其行为时，应在自研 wrapper、兼容层、
验证 monitor 或文档中说明。

## 5. 核验结果

2026-07-28 使用固定工具
`D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat` 完成以下检查：

- PowerShell 语法检查：11 个脚本通过。
- Tcl 语法检查：Vivado 2020.2 报告 `TCL_SYNTAX_PASS`。
- 注释覆盖审计：29 个自研验证文件全部包含语义段、输入、输出和失败定位。
- HDL 只编译检查：使用实际 `vlog.prj`、工程 include 和
  `XILINX_SIMULATOR` 宏，`xvlog` 退出码为 0；`INFO_EXCH`、`PCIe`、
  Adapter 和所有自研 TB 模块均成功分析。

本轮只增加注释和本清单，没有修改接口、组合逻辑、时序逻辑、参数值、
用例动作或运行选项。因此不重复执行耗时 Root Port 全流程；功能基线仍以
2026-07-23 FastMode PASS 和 2026-07-24 WaveMode PASS 为准。

## 6. 维护规则

后续修改 Adapter 或验证环境时，至少同时更新：

1. 受影响逻辑前的语义段注释。
2. 输入、输出和失败定位。
3. 对应 assertion、monitor 或 scoreboard 证据。
4. `RTDS_test_XDMA_RootPort问题发现与处理台账.md` 的问题状态。
5. 若文件范围发生变化，更新本覆盖清单。
