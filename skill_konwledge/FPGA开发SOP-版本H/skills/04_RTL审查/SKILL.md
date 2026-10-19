---
name: fpga-rtl-verilog-code-review
description: 以设计基线为 Golden Reference 独立审查 RTL，并形成 Stable RTL。
version: 1.0.0
language: zh-CN
stage: G4
---

# RTL Review Skill

## 审查输入

- `DESIGN_BASELINE`；
- `RTL_CANDIDATE`；
- IP/XCI、XDC、寄存器表和接口协议；
- G3 Compile/Elaboration/Lint/CDC/RDC 报告；
- 必要的综合、资源或时序风险信息。

## 审查顺序

```text
建立 Design Baseline
→ 建立 RTL Module Map
→ 顶层/接口/模块职责
→ Clock/Reset/CDC/RDC
→ FSM/协议/Ready-Valid
→ Width/Arithmetic/FIFO/Memory
→ Register/Error/Timeout
→ IP/Timing/Resource/Maintainability
→ 输出问题与 Gate 结论
```

## 证据等级

- `STATIC`：代码和设计资料判断；
- `TOOL_VERIFIED`：工具报告支持；
- `NEEDS_SIMULATION`：必须通过仿真确认；
- `NEEDS_IMPLEMENTATION`：必须综合/实现后确认。

## 问题格式

```text
Issue ID / Severity / Category
File / Line / Evidence
Expected / Observed / Impact
Recommended Fix / Verification Method
Status: OPEN | FIXED | VERIFIED | ACCEPTED_RISK | BLOCKED
```

严重等级：`CRITICAL`、`MAJOR`、`MINOR`、`SUGGESTION`。`FIXED` 不等于 `VERIFIED`。

## Gate 条件

- Critical 问题必须关闭或阻塞发布；
- Major 问题必须修复、转入明确的仿真/实现验证，或由责任人批准接受；
- 设计偏差必须有记录，不得通过修改 Review 结论掩盖；
- 形成 `RTL_STABLE` 后才能进入 G5。

## 输出

```text
docs/rtl_review_report.md
docs/rtl_issue_list.md
rtl_stable/
RTL_STABLE
```

