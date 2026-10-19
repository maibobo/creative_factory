---
name: vivado-simulate-rtl
description: 执行和诊断 RTL 仿真，生成日志、波形、Coverage 和可复核的功能结论。
version: 1.0.0
language: zh-CN
stage: G7
---

# RTL 仿真执行 Skill

## 目标

验证 G5 定义的测试契约，而不是只验证“仿真器退出”。可支持 XSim 和已配置的第三方仿真器；后仿真和 Timing Simulation 必须有对应的实现输入。

## Preflight

确认：工程或非工程源列表、Simulation Set、Top、器件、语言、编译顺序、宏/include、仿真器、库、License、模式和有限运行时间。不能发现的环境依赖标记 `BLOCKED`，不能猜测路径。

## 执行流程

```text
发现工程和仿真契约
→ 运行有限时长仿真
→ 读取完整 Transcript
→ 定位第一个因果错误
→ 检查 Checker/Assertion/Timeout/Seed
→ 保存日志、波形、Coverage
→ 分类结果
→ 修复后重跑受影响测试和回归
```

## PASS 必须同时满足

- 编译和 Elaboration 成功；
- 仿真正常终止；
- 有明确的终端 PASS 或测试框架成功结果；
- 所有要求的 Test 完成，无 Unexpected Error/Fatal/Timeout；
- Assertion 和 Coverage 满足计划；
- 随机失败可用同一 Seed 复现；
- Timing Simulation 已确认 SDF 成功标注，不能把跳过 SDF 当作 Timing PASS。

## 失败分类

`design`、`testbench`、`environment`、`timeout`、`tool_defect`。环境或工具失败也要继续检查版本、库、已知问题和最小复现，不得直接结束在“仿真器报错”。

## 输出

```text
reports/simulation/<run-id>/transcript.log
reports/simulation/<run-id>/waveform.wdb|vcd
reports/simulation/<run-id>/coverage/
reports/simulation/<run-id>/run_manifest.yaml
docs/simulation_result.md
SIMULATION_EVIDENCE
```

该 Skill 可以辅助生成自检查 TB，但不能替代 G5 的测试设计或 G6 的 Test ID 交付。

