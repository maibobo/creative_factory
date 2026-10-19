# Skill 调用编排

本文件默认调用本目录 `skills/` 下的独立 Skill。外部 Ross Skill 只有在需要更深的工具适配、HLS、Vitis AI 或 Versal 专项能力时才作为可选扩展。

## 1. 调用原则

- 阶段 Skill 负责决策和交付物；工具 Skill 负责真实执行和证据。
- 先调用信息收集/报告 Skill，再调用修改 Skill。
- 同一 Vivado 会话内避免并发执行互相影响的命令。
- 工具 Skill 未执行时，阶段 Skill 只能输出 `NOT_RUN`、`NEEDS_TOOL` 或 `BLOCKED`。
- 每次修复后只修改一个可归因的主题，并重新执行受影响的检查。
- 只把实际工具输出写入报告，不根据经验补造 PASS、Coverage 或 Timing 数字。

## 2. 主流程调用

### G0：入项与环境

```text
project_manifest
  → vivado-revision-control（需要工程盘点、工程导出或可重建交付时）
```

检查项目模式、器件、顶层、工具版本、源文件、IP、约束和输出目录。

### G1：设计方案

```text
fpga-design-solution
  → 人工/产品确认
  → DESIGN_BASELINE
```

该阶段不应调用仿真执行 Skill，也不应根据 RTL 反推未确认需求。

### G2：RTL 与 IP

```text
fpga-rtl-verilog-development
  → vivado-ip-configurator（需要配置/修改 Vivado IP 时）
  → RTL_CANDIDATE
```

HLS 设计不走该 RTL 编码链，应转入 `branches/` 中的 HLS 分支。

### G3：静态工具验证

```text
vivado-rtl-elaboration-analysis
  → vivado-rtl-lint
  → CDC/RDC/DRC 工具（工程已配置时）
  → 静态问题整改
  → 重新运行受影响工具
```

Lint 报告只报告工具实际产生的消息；人工 Review 不能伪装成 Lint 结果。

### G4：独立 Review

```text
fpga-rtl-verilog-code-review
  ├── 读取 DESIGN_BASELINE
  ├── 读取 RTL_CANDIDATE
  ├── 读取 G3 工具报告
  └── 输出 Review Report / Issue List / RTL_STABLE
```

Review 问题中无法由静态证据关闭的项目，转交 G5 Test ID 或 G8 实现验证。

### G5：验证方案

```text
fpga-simulation-verification-plan
  ├── 读取 DESIGN_BASELINE
  ├── 读取 RTL_STABLE
  ├── 读取 Review Issue List
  └── 输出 P0/P1/P2 Test Plan
```

每个 Review 风险必须映射到 `Test ID`、Checker 或工具验证项；真实结果留到 G7。

### G6：TB 实现

```text
fpga-verilog-tb-development
  ├── 读取 Test Plan
  ├── 读取 RTL_STABLE
  ├── 读取 IP 仿真模型 / Golden Data
  └── 输出 TB + TB说明 + Test ID映射
```

当前 SOP 默认保留“一 Test ID 一 TB”的规则。复杂项目如需公共 Driver/Monitor/Scoreboard，必须在项目清单中声明例外，并保持 Test ID 可独立追溯。

### G7：仿真执行与诊断

```text
vivado-simulate-rtl
  ├── preflight 工程/仿真器/License/库
  ├── run bounded simulation
  ├── 读取首个因果错误
  ├── 保存 log/waveform/coverage/seed
  ├── 分类 design/testbench/environment/timeout/tool_defect
  └── 回归或生成诊断报告
```

该 Skill 可以生成自检查 TB，但在本 SOP 中只能作为 G6 的实现辅助，不能替代 G5 的测试设计和 G6 的 Test ID 交付。

### G8：综合、实现与时序

```text
Vivado synthesis/implementation
  → vivado-timing-methodology-checks
  → 分组处理 violation
  → 每组修改后重新 report_methodology
  → Timing/Methodology Gate
```

若为 HLS 项目，使用 `hls-run-flow`、`hls-synth-report`、`hls-cosim-report` 和 `hls-impl-report`，不要把 HLS 报告误当作 RTL 综合报告。

### G9：硬件调试

```text
hw-ila-debug / hw-vio-debug
  → 读取硬件证据
  → 与仿真/实现版本核对
  → 硬件问题闭环
```

## 3. Skill 选择表

| 用户任务 | 首选 Skill | 配套 Skill |
|---|---|---|
| 写设计方案 | `fpga-design-solution` | — |
| 写 Verilog RTL | `fpga-rtl-verilog-development` | `vivado-ip-configurator` |
| 查 RTL 语法/Elaboration | `vivado-rtl-elaboration-analysis` | `vivado-rtl-lint` |
| 做独立 RTL Review | `fpga-rtl-verilog-code-review` | G3 工具报告 |
| 设计测试项 | `fpga-simulation-verification-plan` | Review Issue List |
| 编写 TB | `fpga-verilog-tb-development` | `vivado-simulate-rtl`（需要执行时） |
| 跑仿真/查仿真失败 | `vivado-simulate-rtl` | 相关 simulator reference |
| 查时序方法学问题 | `vivado-timing-methodology-checks` | 综合/实现报告 |
| 导出工程/重建工程 | `vivado-revision-control` | — |
| ILA/VIO 调试 | `hw-ila-debug` / `hw-vio-debug` | bitstream/PDI 基线 |
| HLS 架构/优化 | `hls-architect` / `hls-optimize` | `hls-run-flow`、报告 Skill |
| Vitis AI/NPU | `vai-quantization-guide` 等 | 按 orchestrator 自动选择 |

## 4. 本地 Skill 映射

下表中的阶段 Skill 名称是 SOP 中使用的角色名，右侧给出本独立包里的实际文件。

| SOP 角色名 | 当前文件 |
|---|---|
| `fpga-design-solution` | `skills/01_设计方案/SKILL.md` |
| `fpga-rtl-verilog-development` | `skills/02_RTL开发/SKILL.md` |
| `fpga-static-verification` | `skills/03_静态验证/SKILL.md` |
| `fpga-rtl-verilog-code-review` | `skills/04_RTL审查/SKILL.md` |
| `fpga-simulation-verification-plan` | `skills/05_验证方案/SKILL.md` |
| `fpga-verilog-tb-development` | `skills/06_TB开发/SKILL.md` |
| `vivado-simulate-rtl` | `skills/07_仿真执行/SKILL.md` |
| `fpga-implementation-timing` | `skills/08_实现时序/SKILL.md` |
| `fpga-hardware-debug` | `skills/09_硬件调试/SKILL.md` |
| `fpga-release-revision-control` | `skills/10_发布交付/SKILL.md` |

外部 Ross Skill 可按需挂载为适配器，但必须把工具版本、输入基线和输出证据回写到本 SOP 的统一格式中。

