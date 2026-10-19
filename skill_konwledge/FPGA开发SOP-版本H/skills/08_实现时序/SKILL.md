---
name: fpga-implementation-timing
description: 执行综合、实现、Timing 和 Vivado Methodology 检查，并闭环处理约束与实现风险。
version: 1.0.0
language: zh-CN
stage: G8
---

# 综合、实现与时序 Skill

## 输入

`RTL_STABLE`、XDC/SDC、IP 配置、器件、综合/实现配置、G7 仿真结果和目标性能。

## 检查内容

- 综合成功、层级和黑盒状态；
- LUT/FF/BRAM/URAM/DSP/IO/Clock 资源；
- Clock 定义、Generated Clock、输入输出延迟和例外约束；
- WNS/TNS、最差路径、拥塞、扇出和关键层级；
- DRC 和 Timing Methodology 规则；
- 约束是否覆盖真实时钟和接口；
- 结果是否来自当前 RTL、约束、器件和实现版本。

## Methodology 闭环

```text
report_methodology
→ 解析 Rule ID 和实例
→ 按共同根因分组并排序
→ 选择 RTL/XDC/配置修复
→ 重新执行 report_methodology
→ 对比前后结果
→ 直到关闭、接受或阻塞
```

每组修改后必须重跑对应报告。不能只改报告文字、批量跳过检查或把不支持的规则当作已解决。

## 结论边界

功能仿真不能证明 Fmax；Timing Methodology 通过不能替代完整功能回归；资源满足不能证明硬件可运行。

## 输出

```text
reports/synthesis/
reports/implementation/
reports/timing/
reports/methodology/
docs/timing_resolution_report.md
IMPLEMENTATION_EVIDENCE
```

