---
name: fpga-rtl-verilog-development
description: 按设计基线实现可综合、可仿真、可审查的 Verilog RTL。
version: 1.0.0
language: zh-CN
stage: G2
---

# RTL 开发 Skill

## 目标

将 `DESIGN_BASELINE` 转换为 RTL、IP Wrapper、约束和变更记录。设计方案决定行为，RTL 不得擅自改变接口、协议、数据格式或架构。

## 开发前检查

- 读取设计方案、接口、寄存器、时钟复位、FSM、FIFO/Buffer、性能和已有 RTL；
- 建立模块树、Clock/Reset Map、Interface Map、数据通路和控制流程；
- 确认目标器件、Vivado 版本、Verilog/SystemVerilog 语言边界；
- 标记 `BLOCKING ISSUE`、`ASSUMPTION`、`TBD` 和 `DESIGN DEVIATION`。

## 编码基线

- 默认 Verilog-2001；无明确批准不得升级语言；
- 显式声明端口、位宽、符号、常量和状态；禁止隐式 Net、多驱动、组合环路和不可综合语句；
- 时序逻辑使用非阻塞赋值，组合逻辑完整赋值，避免 Latch；
- 明确定义 Reset、FSM default、Counter 边界、FIFO 满空保护和 BRAM 读延迟；
- Ready/Valid 在等待和背压期间保持协议要求的数据与控制稳定；
- CDC 使用适合信号类型的同步器、握手、异步 FIFO 或 Gray Code；
- 顶层优先负责例化、连接、参数和时钟复位分发，复杂逻辑下沉到子模块；
- 官方 IP 使用 Wrapper，记录 IP 版本、配置和仿真模型。

## 工作流

```text
读取输入 → 建立设计摘要 → 建立模块树/接口图
→ 实现骨架 → 实现控制与数据路径 → 处理 CDC/IP
→ Compile 自检 → 输出 Candidate RTL 与偏差清单
```

## 输出

```text
rtl/
ip/
constraints/
docs/RTL_README.md
docs/RTL_CHANGE_LOG.md
docs/RTL_OPEN_ISSUES.md
docs/RTL_DESIGN_DEVIATION.md
RTL_CANDIDATE
```

## 禁止事项

- 不为了让仿真通过而修改 Expected；
- 不在没有批准的情况下优化架构、改接口或更换 IP；
- 不把推测的 Timing/Resource 结果写成真实结果；
- 发现设计问题时记录并返回 G1/G4，而不是隐藏问题。

