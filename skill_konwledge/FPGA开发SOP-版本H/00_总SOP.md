# FPGA 开发总 SOP

## 1. 端到端流程

```text
G0 项目入项与环境基线
  ↓
G1 需求与设计方案基线
  ↓
G2 RTL 实现完成
  ↓
G3 编译 / Elaborate / Lint / CDC / RDC
  ↓
G4 独立 RTL Review，形成 Stable RTL
  ↓
G5 仿真验证方案
  ↓
G6 Testbench 实现
  ↓
G7 仿真执行、Coverage、Regression 与诊断
  ↓
G8 综合 / 实现 / Timing / Methodology
  ↓
G9 硬件上板与 ILA/VIO 调试
  ↓
G10 版本冻结、重建验证与交付
```

G5 负责定义“测什么”；G6 负责实现“如何测”；G7 负责确认“实际运行结果是否有证据”。

## 2. 阶段职责

| 阶段 | 主要责任 | 禁止越界 |
|---|---|---|
| G0 | 确认工程、器件、工具、许可证和目录 | 不在环境未知时直接改 RTL |
| G1 | 明确功能、接口、时钟、复位、数据、性能和异常 | 不把实现猜测写成需求 |
| G2 | 按批准方案实现 RTL、IP Wrapper 和约束 | 不擅自改变接口或架构 |
| G3 | 用工具验证语法、Elaboration、Lint、CDC/RDC | 不把人工检查当作工具 PASS |
| G4 | 独立审查设计一致性、编码、协议和风险 | Author 不替代 Reviewer |
| G5 | 设计 P0/P1/P2 测试项和通过标准 | 不填写未执行的结果 |
| G6 | 生成 TB、Checker、参考模型、Seed 和说明 | 不修改 Stable RTL 迎合测试 |
| G7 | 执行仿真、回归、Coverage 和失败诊断 | 不把编译成功当功能通过 |
| G8 | 综合、实现、时序和方法学闭环 | 不从功能仿真推断 Fmax |
| G9 | 通过 ILA/VIO 观察真实硬件行为 | 不把仿真结果当上板证据 |
| G10 | 冻结版本、验证工程可重建性并交付 | 不交付无法复现的工程 |

## 3. 角色与变更

- `Design Owner`：维护需求、设计方案和设计变更。
- `RTL Author`：实现 RTL，并记录假设、偏差和开放问题。
- `RTL Reviewer`：独立审查并决定是否形成 Stable RTL。
- `Verification Owner`：维护验证计划、TB、结果和回归记录。
- `Tool Executor`：执行 Vivado/Vitis 工具并保存原始证据。

设计方案是默认基线，但不是不可变文档。需求、接口或架构变更必须经过批准，更新设计版本，并重新评估受影响的质量门。

## 4. 推荐项目交付物

```text
project/
├── docs/
│   ├── design_spec.md
│   ├── rtl_review_report.md
│   ├── verification_plan.md
│   └── release_notes.md
├── rtl/
├── tb/
├── constraints/
├── ip/
├── scripts/
├── reports/
│   ├── lint/
│   ├── simulation/
│   ├── synthesis/
│   ├── implementation/
│   └── timing/
├── evidence/
├── project_manifest.yaml
└── traceability.csv
```

