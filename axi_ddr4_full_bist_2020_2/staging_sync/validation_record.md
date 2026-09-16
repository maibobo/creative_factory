# KU040 DDR4 全空间复核与验证记录

更新时间：2026-09-15

## 1. 验证对象与结论边界

目标板是同一块组内自研 KU040 单板，FPGA 为 `xcku040-ffva1156-2-i`，板上包含四颗 GDQ3BFAM-WJ、PCIe、Aurora 和以太网。本工程只验证 DDR4，未并入 PCIe/Aurora/以太网，避免接口问题干扰 DDR 定位。

原工程 `C:\project\RTDS\DDR\axi_ddr4_min_2020_2` 保持不变。新工程位于 `C:\project\RTDS\DDR\axi_ddr4_full_bist_2020_2`，采用 AXI4 64-bit 接口，便于后续移植到 PCIe/Aurora 数据通路。

工程已经完成工程生成、RTL Elaborate、行为冒烟和两轮 compat 实现诊断。第二轮结构优化后的 RTL 已再次通过行为回归，但本次综合被按用户要求暂停，尚无新的实现结果。因此当前结论仍不是“可直接下载上板”：已有 bitstream 来自负 WNS 的实现，只能作为失败产物留档，不能作为正式测试版本。

## 2. 参考工程差异

| 项目 | 第32章 Demo | 原 AXI 最小工程 | 新全空间工程 |
|---|---|---|---|
| 用户接口 | MIG Native APP | AXI4 64-bit | AXI4 64-bit |
| 地址宽度 | Demo 内部存在截断风险 | AXI 32-bit，但只测 32 KiB | AXI 32-bit，内部 33-bit 结束判定 |
| 访问形式 | Demo 自带流量 | 单拍 | 16-beat INCR |
| 颗粒配置 | Micron 别名 | Micron 别名 | 兼容版 + GD2400 正式参数版 |
| 控制/观测 | LED/原 Demo 调试 | LED | LED + VIO + ILA |
| 目标 | Demo 功能复现 | 32 KiB 冒烟 | 定向测试、全 4 GB、长稳测试 |

原最小工程已有 bitstream 可用于原 32 KiB 冒烟，但它不能证明 GD 正式时序、16-beat AXI、全 4 GB 地址覆盖或长稳可靠性。

## 3. 颗粒和 MIG 参数

四颗 GDQ3BFAM-WJ 每颗为 8 Gb、x16，合计 x64、32 Gb，即 4 GB。新工程配置为：

- FPGA：`xcku040-ffva1156-2-i`。
- MIG DDR4 v2.2，物理数据 64 bit。
- AXI 地址/数据/ID：32/64/4 bit。
- DDR 周期 833 ps，输入参考时钟 9996 ps，PHY 4:1，ECC 关闭。
- GD2400：CL17、CWL12，`tRCD/tRP=14.16 ns`，`tRFC=350 ns`，`tFAW=30 ns`，`tRRD_S=5.3 ns`，`tRRD_L=6.4 ns`，`tRAS=32 ns`，`tREFI=7.8 us`，`tXPR=360 ns`。
- 兼容版仍使用 `MT40A512M16HA-083E`、CL16/CWL12，只用于复现 Demo 条件。
- 2133 fallback 已准备为故障隔离选项，本轮 GD2400 CSV 已被 Vivado 2020.2 接受，因此未生成 2133 XPR。

GD2400 XCI 中 CustomParts 已写成工程内相对路径 `../../../../../../ip/gd_q3bfam_wj_2400.csv`，工程不依赖新目录外的源文件。

## 4. BIST 设计

BIST 使用 16-beat INCR，`AWSIZE/ARSIZE=3`，每个 burst 为 128 B。AW 与 W 独立握手，检查 BID/RID、BRESP/RRESP 和 RLAST；超时、响应错误和读数据错误会记录计数及首错现场。所有发生器地址均按 128 B 对齐，因此不会跨越 4 KiB 边界。

全空间结束条件使用 33-bit 地址：最后一个 burst 基址为 `0xFFFF_FF80`，末 beat 地址为 `0xFFFF_FFF8`，下一地址为 `0x1_0000_0000`，不会被 32-bit 回绕误判。

| test_mode | 用途 | 正式硬件范围 |
|---:|---|---|
| 0 | 地址相关数据快速冒烟 | 32 KiB |
| 1 | 00/FF/AA/55、Walking-1、Walking-0 | 132 组模式，每组 1 burst |
| 2 | 8 个 WSTRB 字节通道和未写字节保持 | 1 burst，逐 lane 累积 |
| 3 | 地址线幂次偏移与高地址别名 | 26 个稀疏 burst |
| 4 | 128 B、2 KiB、4 KiB、行/Bank候选、末地址边界 | 6 个定向 burst |
| 5 | 地址相关数据正向/反向写读 | 完整 4 GB |
| 6 | March 类 W0/R0、W1/R1、W0/R0 | 完整 4 GB，多遍 |
| 7 | 地址确定性 PRBS、保持和循环压力 | 默认压力区；repeat 可连续运行 |

模式 7 的默认保持计数为 180,000,000,000 个 `ui_clk` 周期，按约 300 MHz 预期为 10 分钟；正式上板应以实现后实际 `ui_clk` 报告换算确认。

## 5. 已执行验证

### 工程与 Elaborate

- `PROJECT_CREATE_PASS profile=compat`。
- `PROJECT_CREATE_PASS profile=gd2400`。
- `RTL_ELABORATE_PASS profile=compat`。
- `RTL_ELABORATE_PASS profile=gd2400`。

Elaborate 日志各有一条 `[Synth 8-4446]`：in-memory Elaborate 使用 VIO 仿真壳，壳的输出没有功能模型，逻辑可能被移除。该提示不等于正式 XPR 中 VIO IP 未连接；正式 XPR 引用生成的 VIO XCI。没有 Error 或 Critical Warning。

### 行为仿真

| 用例 | 写 burst | 读 burst | 结果 |
|---|---:|---:|---|
| 32-word 随机背压冒烟 | 2 | 2 | PASS |
| 数据线模式 | 132 | 132 | PASS |
| WSTRB | 9 | 9 | PASS |
| 地址线别名 | 26 | 26 | PASS |
| 定向边界 | 6 | 6 | PASS |
| 缩小空间正反向 | 1024 | 1024 | PASS |
| 缩小空间 March 类 | 1536 | 1536 | PASS |
| PRBS/缩短保持 | 32 | 32 | PASS |
| 读数据注错 | 2 | 2 | 预期 FAIL 被检出 |
| BRESP 注错 | 2 | 2 | 预期 FAIL 被检出 |
| 协议超时 | 0 | 0 | 预期 FAIL 被检出 |
| 4096-word/32 KiB 冒烟 | 256 | 256 | PASS |

权威结束标记为：

```text
AXI_DDR_FULL_BIST_SIM_PASS smoke_bursts=2
AXI_DDR_FULL_BIST_SIM_PASS smoke_bursts=256
BEHAVIOR_REGRESSION_PASS
```

MIG 器件模型不遍历 4 GB；全空间覆盖必须在板上运行。行为仿真的 mode 5/6 使用缩小的 64 KiB 上界，用于验证状态切换、正反向、末地址和 33-bit 结束逻辑。

2026-09-15 第二轮时序结构优化后，在远程机再次执行相同回归，结果仍为：8 个正向模式 PASS，读数据注错、BRESP 注错及协议超时均按预期检出，32-word 与 4096-word 冒烟均 PASS。日志为 `logs/behavior_after_terminal_fix_remote.log`。

### 综合、实现与时序诊断

| 阶段 | WNS | TNS | Setup 失败端点 | 结论 |
|---|---:|---:|---:|---|
| 原始 routed 基线 | -1.330 ns | -953.849 ns | 3079/61452 | FAIL |
| 读检查流水化后手动实现 | -0.895 ns | -362.841 ns | 1131/61930 | FAIL，但明显改善 |
| 末突发判断寄存化后手动实现 | -0.919 ns | -87.275 ns | 721/62012 | FAIL；TNS/失败端点继续改善，WNS 未改善 |
| 末突发纯序号判断优化后 | -0.071（上一版实现） | -0.409（上一版实现） | 11/61941（上一版实现） | 纯序号判断已收敛；WDATA 仍有11条 |
| WDATA 预取/phase预译码后 | 尚无结果 | 尚无结果 | 尚无结果 | 远端2-burst冒烟 PASS，等待用户重新综合/实现 |

原始 worst-100 全部位于 `U_AXI_DDR_FULL_BIST`。原关键路径由 `beat_index_reg[2]` 经过期望数据、比较和错误组合逻辑，直接驱动 `first_expected_data/first_actual_data` 的 CE；最差路径 13 级逻辑、数据路径约 4.364 ns。第一次修复在 AXI R 握手后增加独立 `BIST_READ_CHECK` 周期，把 RDATA、期望值、地址、响应和末拍标志先寄存再比较。代价是每个读 beat 增加一个检查周期，但保留测试覆盖，并将 WNS 从 -1.330 ns 改善到 -0.895 ns。

第一轮后的最差路径转移到 `burst_count_reg[0]/C` 至 `burst_index/current_addr_ext` 等寄存器 CE。其本质是 32-bit `burst_count-1`/阶段末突发比较结果直接控制大量状态分支，最差约8级逻辑、数据路径约4.029 ns，其中布线约2.590 ns，属于高扇出状态控制路径，不是 MIG 跨时钟路径。第二次 RTL 修复将其扇出切断后，失败端点从1131降到721，但新实现揭示寄存器 D 端仍包含模式选择、地址生成、33-bit 加法和终点比较：`burst_index_reg[3]_replica -> current_burst_is_last_reg/D` 达13级、数据路径4.190 ns，WNS=-0.919 ns，说明只是移动终点、没有拆掉逻辑锥。

同一实现的第二大路径族为 `phase_reg[4]_replica -> m_axi_wdata_reg[*]/D`，典型12～13级、约3.70～3.76 ns，来源是 mode/phase 解码、地址相关数据函数和 WDATA 选择在一个周期内完成。另有少量约 -0.52 ns 路径位于 MIG 校准内部，逻辑仅2级但布线占比约92%；不得修改生成的 MIG RTL，应在用户逻辑收敛后通过官方建议的实现策略、布局复跑和 IP 配置复核处理。

第三次 RTL 优化已经把阶段末判断等价化为纯 `burst_index == burst_count-1`：4 GiB上界仍用33 bit保存，右移7可精确得到33,554,432个burst，因此不会牺牲 `0xFFFF_FFF8` 覆盖或回绕保护。第四次 RTL 优化已对 WDATA 实施预取和 phase 预译码，将“阶段/模式预译码与地址准备”和“beat 数据生成/AXI发送”分离；远端2-burst冒烟通过，新的实现时序等待用户执行。

Vivado GUI 默认只展开每个路径组少量最差路径，常见值为10；这只是报告显示上限，不是一次只检查10条。Timing Summary 已同时统计全部721个失败端点。GUI 中将 `Report Timing` 的 `Number of paths/Max paths` 与 `Number of worst paths per endpoint/NWorst` 调大；Tcl 可使用：

```tcl
report_timing -delay_type max -max_paths 1000 -nworst 100 \
  -slack_lesser_than 0 -file timing_setup_violations_1000.rpt
```

分析时应按共享起点、共享终点层次和逻辑锥归类，而不是修完前10条再看下10条。

第二、三次 RTL 修复包括：

- 将 `current_burst_is_last` 提前寄存，避免终点比较直接驱动大量 CE。
- 将末突发判断简化为纯 burst 序号/计数比较，去除模式、地址和33-bit加法组合锥。
- 将固定项数模式的进度乘法改成常量查表，避免在 300 MHz 状态通路推断组合乘法器。
- 保留当前 16-beat AXI 协议、33-bit 结束检测和全部测试模式语义。

Clock Interaction 报告显示唯一负裕量组为 `mmcm_clkout0 -> mmcm_clkout0`，即 MIG `ui_clk` 约 300 MHz 域内部路径；跨时钟路径均为已满足或由 MIG/debug IP 约束忽略。Bus Skew 报告全部满足，实际 skew 约 0.6 ns、典型裕量约 12.7 ns，不是根因。Methodology 的主要设计相关项是大量 setup 警告和一处组合乘法；其余多位于 MIG/debug IP，另有顶层异步控制/LED 端口缺少 I/O delay，需按实际板级接口属性解释，不能用虚假 set_input_delay/set_output_delay 消警告。

完整诊断文件位于 `reports/timing_baseline_20260915/`、`reports/timing_after_pipeline_manual/` 和 `reports/timing_diagnosis_20260915/`。Vivado GUI 查看入口为 `Open Implemented Design -> Reports -> Timing -> Report Timing Summary`；worst-100 使用 `Report Timing` 将 Max paths/NWorst 设为100；Clock Interaction、Methodology 和 Bus Skew 分别使用相应 Report 菜单。命令行由 `tcl/diagnose_impl_compat.tcl` 生成只读报告。

## 6. XDC 与可移植性审计

- Demo、原最小工程和新工程均有 111 条 PACKAGE_PIN、120 条 IOSTANDARD。
- Demo 与原最小工程 PACKAGE_PIN 差异为 0。
- 原最小工程与新工程 XDC 全文件 SHA-256 完全相同：`66010B1516817B5EA2ED90CB781499E5A3A387A9D7EDCAC86AAA0CA9ED361DEA`。
- Demo 额外手写一条 `create_clock`；新工程不复制，避免与 MIG 自动约束重复。
- XPR 的 RTL/XDC/CSV 使用 `$PPRDIR` 相对路径，XCI 使用 `$PSRCDIR`，没有引用目标目录外的源文件。

完整对照见 `docs/KU040_DDR4管脚对照与XDC审计.md`。

## 7. 代码规范审计

设计 RTL 遵循 `E:\centOS\代码规则建立\代码规范输出`：

- 设计文件使用 Verilog-2001，验证文件单独使用 SystemVerilog。
- 一个设计模块一个文件，模块名大写，实例和端口全部具名。
- `wire` 声明与 `assign` 分离，无声明时赋值、`initial`、`casex/casez`、延时或嵌套三目表达式。
- 位宽显式，AXI 常量显式；语义注释覆盖复位、握手、边界和测试阶段。
- BIST 状态相关寄存器共享一个状态转移过程，已用 `CUSTOM-RTL-001` 注释记录“状态组集中更新”例外及原因。

## 8. 未执行与限制

- 原始 compat 综合/实现：已运行，但 setup timing FAIL，不构成验收。
- 第一轮流水修复后的 compat 综合/实现：已运行，WNS=-0.895 ns，仍不构成验收。
- 第二轮末突发寄存化：RTL 编译、Elaborate、行为回归和手动实现已完成；WNS=-0.919 ns，仍然 FAIL。
- 第三轮纯序号末突发判断：远端 RTL 编译、Elaborate、8个正向模式、3个负向注错及32/4096-word冒烟全部PASS；对应实现 WNS=-0.071 ns，仍不可上板。
- 第四轮 WDATA 预取/phase 预译码：远端 RTL 编译、Elaborate、2-burst随机背压冒烟 PASS；日志为 `logs/smoke_after_wdata_prefetch_remote.log`，等待用户重新综合/实现。
- gd2400 正式配置的综合、实现、DRC、时序和 bitstream：NOT RUN。
- GD2400 32 KiB 上板、全 4 GB、复位循环、保持和 PRBS：NOT RUN。
- 电源、VREF、DDR CK 和复位时序的示波器/万用表测量：NOT RUN。

Vivado 默认可在负 WNS 的情况下继续生成 bitstream，因此“存在 `.bit` 文件”不等于时序通过。后续构建必须以 `WNS>=0`、无 hold 失败、无 Error/Critical Warning、无未约束内部路径和无路由错误为发布门槛；`tcl/run_timing_fix_compat.tcl` 已加入 WNS 负值时拒绝发布 bitstream 的硬门槛。

时序优化迭代默认只运行 `tcl/run_smoke_only.tcl` 的2-burst/32-word随机背压冒烟，以 `AXI_DDR_FULL_BIST_SIM_PASS smoke_bursts=2` 和 `SMOKE_ONLY_PASS` 为门槛。完整8模式、负向注错和4096-word回归仅在状态机/接口语义改动或最终签核时运行，避免每次注释或等价逻辑调整重复耗时。
