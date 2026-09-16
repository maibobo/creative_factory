# KU040 DDR4 全空间 BIST 时序违例分析与修复方案

- 日期：2026-09-15
- 工程：`C:\project\RTDS\DDR\axi_ddr4_full_bist_2020_2`（compat 配置）
- 数据来源：`prj\compat\axi_ddr4_full_bist_compat.runs\impl_1\TOP_AXI_DDR4_FULL_BIST_timing_summary_routed.rpt`（2026-09-15 15:45:28）
- 关联文档：`KU040_DDR4全空间复核与验证记录.md`、`KU040_DDR4上板测试操作指南.md`

> 注意：`reports\timing_diagnosis_20260915\` 为基线 -1.330 报告，`reports\timing_fix2_compat\` 为上一轮 -0.919 报告，均非当前结果。本文分析对象为当前 impl_1 的 **WNS -0.071 / TNS -0.409**。

---

## 1. 当前时序现状

| 指标 | 数值 | 说明 |
|---|---|---|
| WNS | **-0.071 ns** | 建立违例，差 0.071 ns |
| TNS | **-0.409 ns** | 合计 |
| Setup 失败端点 | **11 / 61941** | 全部在 BIST 模块内 |
| WHS（Hold） | **+0.004 ns** | 已通过，但裕量极薄，重布线后必须复查 |
| 失败时钟域 | `mmcm_clkout0` **同域** | MIG `ui_clk`，300.12 MHz（周期 3.332 ns），非跨时钟问题 |
| 跨域 / Bus Skew / 脉宽 | 全部满足 | 无 CDC 违例、无 Bus Skew 违例 |

时钟域结论：违例全部为 `mmcm_clkout0 → mmcm_clkout0` 的**域内建立（Setup）违例**；时钟树结构本身（AK17 差分输入 → MMCM → BUFGCE → aclk，扇出 22762）正常，时钟偏斜 -0.12 ~ -0.16 ns、抖动 0.058 ns 均在合理范围。**无保持违例路径需要修复。**

---

## 2. 需要修复的关键时序路径清单（11 条，同一族）

所有失败路径终点均为 `U_AXI_DDR_FULL_BIST/m_axi_wdata_reg[*]/D`，即 **AXI W 通道写数据寄存器**；起点为 `phase_reg[3]`（测试阶段计数器）或 `burst_index_reg[6]`（burst 序号计数器）。时钟域全部为 `mmcm_clkout0`（300.12 MHz）同域，违例类型全部为 **Setup（建立）违例**。

| # | 起点 | 终点 | 时钟域 | 违例类型 | Slack (ns) | 逻辑级数 | 数据路径 (ns) |
|---|---|---|---|---|---|---|---|
| 1 | `phase_reg[3]/C` | `m_axi_wdata_reg[50]/D` | mmcm_clkout0 同域 | Setup | **-0.071** | 12（CARRY8×3） | 3.260 |
| 2 | `burst_index_reg[6]/C` | `m_axi_wdata_reg[56]/D` | 同上 | Setup | -0.067 | 8（CARRY8×2） | 3.239 |
| 3 | `burst_index_reg[6]/C` | `m_axi_wdata_reg[44]/D` | 同上 | Setup | -0.061 | 8（CARRY8×2） | 3.241 |
| 4 | `phase_reg[3]/C` | `m_axi_wdata_reg[51]/D` | 同上 | Setup | -0.048 | 12（CARRY8×3） | 3.247 |
| 5 | `burst_index_reg[6]/C` | `m_axi_wdata_reg[43]/D` | 同上 | Setup | -0.046 | 8（CARRY8×2） | 3.232 |
| 6 | `burst_index_reg[6]/C` | `m_axi_wdata_reg[30]/D` | 同上 | Setup | -0.027 | 8（CARRY8×2） | 3.203 |
| 7 | `phase_reg[3]/C` | `m_axi_wdata_reg[16]/D` | 同上 | Setup | -0.023 | 11（CARRY8×3） | 3.234 |
| 8 | `burst_index_reg[0]_replica/C` | `m_axi_wdata_reg[37]/D` | 同上 | Setup | -0.022 | 7（CARRY8×2） | 3.236 |
| 9 | `phase_reg[3]/C` | `m_axi_wdata_reg[54]/D` | 同上 | Setup | -0.020 | 11（CARRY8×3） | 3.228 |
| 10 | `burst_index_reg[6]/C` | `m_axi_wdata_reg[29]/D` | 同上 | Setup | -0.020 | 9（CARRY8×3） | 3.190 |
| 11 | 同族其余位 | `m_axi_wdata_reg[*]/D` | 同上 | Setup | > -0.020（未展开） | 同族 | ~3.2 |

路径共性：

- 数据路径约 3.19~3.26 ns（要求 3.332 ns），其中布线占 56~65%（1.8~2.1 ns），逻辑 1.1~1.4 ns。
- 组合链为：`burst_index/phase 寄存器 → 33-bit 地址加法（CARRY8 级联）→ active_burst_addr32 模式译码 → write_data() 数据族生成 → m_axi_wdata/D`。
- 最差路径（#1，12 级）含 3 级 CARRY8：33-bit beat 地址加法 + 数据族内部的进位运算；#9 经由 `m_axi_awaddr` 加法锥（`m_axi_awaddr_reg[29]_i_3`）进入 wdata LUT 链，说明 phase 同时驱动地址推进与数据生成的长锥。
- `burst_index_reg[0]_replica` 是工具自动复制寄存器，仍不够 300 MHz，说明扇出/锥深是结构性问题。

---

## 3. 与历史轮次演进对比

| 轮次 | WNS (ns) | TNS (ns) | 失败端点 | 关键路径族 | 报告位置 |
|---|---|---|---|---|---|
| 基线 | -1.330 | -953.849 | 3079 | `beat_index_reg[2] → first_actual_data/first_expected_data CE`（读错误判断 13 级长链） | `reports/timing_diagnosis_20260915/` |
| 第一轮修复后 | -0.919 | -87.275 | 721 | ① `burst_index_reg[3]_replica → current_burst_is_last/D`（末突发判断 13 级）；② `phase/burst_index → m_axi_wdata`（12~13 级）；③ MIG 内部校准路径（~ -0.52，布线 92%） | `reports/timing_fix2_compat/` |
| **当前（第二轮修复后）** | **-0.071** | **-0.409** | **11** | 仅剩 `phase/burst_index → m_axi_wdata` 一族（7~12 级） | `prj/.../impl_1/` |

已收敛项：

- `beat_index → 首错寄存器`：通过 BIST_READ_CHECK 采样流水（读数据/期望值先寄存一拍再比较）收敛。
- `burst_count → current_burst_is_last`：末突发判断寄存化 + 等价化为纯 `burst_index == burst_count-1` 比较，退出 300 MHz 通路后收敛。
- MIG 内部校准路径（~ -0.52）：随用户逻辑收敛、布线压力下降而自然收敛。

演进结论：TNS 从 -953.849 → -87.275 → -0.409，失败端点 3079 → 721 → 11，方向正确；剩余瓶颈即 WDATA 生成组合链，是本工程用户逻辑侧最后一条需要结构性处理的长路径。

---

## 4. 根因（RTL 语义定位）

`rtl/axi_ddr_full_bist.v` 的 W 通道数据生成是**单拍长组合链**，三处内联调用把"地址推进 + 模式译码 + 数据族生成"压在同一周期：

| 位置 | 语义 | 路径内容 |
|---|---|---|
| 行 686（phase 首拍） | 阶段开始发出第一个 W beat | `phase_start_address() + active_burst_addr32() + write_data()` 一拍完成 |
| 行 724（beat 推进） | burst 内每个 beat 握手后准备下一个数据 | `current_addr_ext + (beat_index+1)*8`（CARRY8）→ `write_data()` 一拍完成，**最差路径来源** |
| 行 797（次 burst 首拍） | 进入下一 burst 时准备首数据 | `current_addr_ext ± BURST_BYTES + active_burst_addr32() + write_data()` 一拍完成 |

`write_data()`（行 293）内部按 `active_mode/phase` 做 8 分支数据族选择（address_pattern / line_pattern / Walking / XOR 常数 / 取反 / 全 0 全 1 / PRBS），本身 5~6 级 LUT；再串上前置的 33-bit 地址加法（2~3 级 CARRY8）即达 7~12 级。源码注释（行 291-292）已预留优化方向："后续 300 MHz 优化应按'阶段预译码/beat 数据生成'分级，不能加假约束"。

---

## 5. 修复方法决策（四类）

### 方法 1：RTL WDATA 预取流水 —— 采纳（首选，结构性治本）

- W 通道握手当拍（`w_fire`）只更新 `beat_index` / `m_axi_wlast`；`m_axi_wdata` 打入**上一拍已预计算**的 `next_wdata`。
- 新增预计算寄存器级：`next_beat_addr = current_addr_ext + (beat_index+1)*8` 及对应 `write_data()` 结果；用 `w_fire` 作为预计算更新使能，保证 AXI stall（wvalid 高、wready 未回）期间 `m_axi_wdata` 保持稳定，符合 AXI 协议。
- burst 首拍数据（行 686/797）同样在边界状态提前一拍寄存。
- 可选进一步：phase 进入时预译码 `active_mode/phase → write_data` 数据族选择信号，与 beat 地址加法分级。预期关键路径降至 ≤6 级，裕量 >0.3 ns。
- 代价：地址/数据逻辑等价搬移一拍，面积基本持平；W 通道仍每拍一 beat，吞吐不变。

### 方法 2：实现策略加强 —— 采纳（工具兜底，-0.071 幅度小）

- impl Tcl 增加 `phys_opt_design -directive AggressiveExplore`（寄存器复制降 `burst_index/phase` 高扇出）与 `route_design -directive AggressiveExplore`。
- 保持现有"WNS<0 拒绝写 bitstream"硬门槛。

### 方法 3：时钟约束调整 —— 明确排除

- `ui_clk` 300.12 MHz 由 MIG 4:1 PHY 比与 DDR4-2400（833 ps）共同决定，不可降频。
- 禁止对 BIST 内部路径加 `set_false_path`/`set_max_delay` 假约束——这会使自检数据正确性失去时序保证，违背 BIST 语义（源码注释已明示）。
- XDC 无需新增时钟约束：100 MHz 输入时钟约束归 MIG 生成 XDC 所有。

### 方法 4：布局约束（Pblock）—— 明确排除

- 不给 `U_AXI_DDR_FULL_BIST` 加硬 Pblock：BIST 与 MIG PHY 校准路径共享布线资源，历史报告已证实 MIG 内部路径布线占比 92%，硬约束会挤占其布线并可能使已收敛路径反弹；仅靠方法 2 的指令级加强。

---

## 6. 执行与验证约束

1. RTL 修改后仅跑快速冒烟（32-word / 2-burst，`tcl/run_smoke_only.tcl`），不跑 8 模式完整回归与 4096-word 回归（既定规矩）。
2. 全部 Vivado 编译/仿真/综合/实现在远端执行。
3. 重新综合实现后复查 Hold（当前仅 +0.004 ns）；**WNS≥0 且 Hold 通过才允许 bitstream**。
4. 修复后更新 `KU040_DDR4全空间复核与验证记录.md`，并在 `KU040_DDR4上板测试操作指南.md` 中补充"WNS≥0 且 Hold 通过才可上板"判定说明。

---

## 7. 本轮已执行结果（数据预取流水）

根据本方案，`rtl/axi_ddr_full_bist.v` 已完成以下结构修改：

- 增加 `w_next_data`，在当前 W beat 发送期间预计算下一 beat 数据；`w_fire` 时只把预取寄存器转入 `m_axi_wdata`。
- `BIST_WRITE_FIRST` 负责 burst 首拍和 beat1 预取；后续 beat 在 `BIST_WRITE_DATA` 中保持 WVALID/WREADY 语义不变。
- 增加 `phase_pattern_data` 和 `phase_invert_data`，将 line/byte/March 等只依赖 phase 的数据族在 `BIST_PREPARE` 锁存，WDATA 发送级不再直接读取 9-bit phase。
- AXI stall 期间不更新 `m_axi_wdata`、`m_axi_wstrb` 或 `m_axi_wlast`；因此满足 VALID 保持规则。代价是每个 burst 增加首拍准备级，不改变 16-beat 覆盖。

远端快速冒烟已通过：

```text
CASE_PASS name=smoke_random_backpressure expected_pass=1 writes=2 reads=2 errors=0 cycles=115
AXI_DDR_FULL_BIST_SIM_PASS smoke_bursts=2
SMOKE_ONLY_PASS
```

日志：`C:\project\RTDS\DDR\axi_ddr4_full_bist_2020_2\logs\smoke_after_wdata_prefetch_remote.log`。

本轮仅证明 RTL 编译、Elaborate 和 2-burst 行为冒烟；尚未重新综合/实现。请在远端 GUI 中重新运行 `synth_1` 和 `impl_1`，再确认 WNS/WHS。若 WNS 仍略负，优先使用 `phys_opt_design -directive AggressiveExplore` 和 `route_design -directive AggressiveExplore`，随后重新导出 worst-100；禁止用 false path、放宽 max delay 或降低 ui_clk 约束掩盖问题。

## 8. Hardware Manager 崩溃后的工程恢复记录

2026-09-15 在 Hardware Manager Auto Connect 后远端电脑重启，随后 GUI 打开 XPR 触发：

```text
[Labtools 27-1429] XML character encoding not supported
...axi_ddr4_full_bist_compat.hw\axi_ddr4_full_bist_compat.lpr at line 1
```

检查发现该 `.lpr` 文件大小343 bytes、内容全为 `0x00`，属于 Hardware Manager 会话状态损坏；XPR XML 本身可正常解析，源文件、XCI、生成 IP 和 runs 未损坏。已先将原状态目录完整改名保留为：

```text
prj\compat\axi_ddr4_full_bist_compat.hw_recovered_20260915
```

之后 Vivado 重新打开工程并生成新的 `.hw` 状态目录。恢复后的 `.lpr` XML 解析通过，远端体检日志为：

```text
logs\project_recovery_check_final.log
```

关键结果：`PROJECT_OPEN_PASS`、器件 `xcku040-ffva1156-2-i`、`synth_1=synth_design Complete!`、`impl_1=write_bitstream Complete!`、`PROJECT_RECOVERY_CHECK_PASS`。下次遇到同类问题，先关闭 Vivado/Hardware Manager，再备份并改名对应 `.hw` 目录；不要删除 `.srcs`、`.gen`、`.runs` 或 XPR。
