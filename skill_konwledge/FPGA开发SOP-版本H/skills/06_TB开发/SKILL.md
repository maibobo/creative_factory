---
name: fpga-verilog-tb-development
description: 将验证计划中的 Test ID 实现为可执行、自检查、可复现的 Verilog Testbench。
version: 1.0.0
language: zh-CN
stage: G6
---

# Testbench 开发 Skill

## 输入

- G5 验证方案和全部 Test ID；
- `RTL_STABLE`；
- 接口、参数、IP 仿真模型、Golden Vector 和运行约束。

## 默认结构

默认一个 Test ID 对应一个独立 TB；每个 TB 自己包含 Clock、Reset、DUT、Stimulus、Checker、Timeout 和 `$finish`。复杂项目如需共享 Driver/Monitor/Scoreboard，必须保持 Test ID 和证据独立可追溯。

## 必须实现

- 根据 G5 的 Expected 建立 Checker，不根据 DUT 当前输出临时改 Expected；
- 显式检查 Unexpected Output、Missing Output、Duplicate、Reorder、X/Z、Timeout 和错误恢复；
- P2 使用可修改且启动时打印的 Seed；随机输入只能来自设计合法空间；
- 文件、IP 模型、Golden Vector 打开失败必须明确 FAIL 或 BLOCKED；
- 关键数据比较输出 Expected、Actual、Index、Cycle/Time；
- 发现 RTL Bug、设计问题或验证计划问题时分别标记 `RTL ISSUE`、`DESIGN CLARIFICATION REQUIRED`、`VERIFICATION PLAN ISSUE`。

## 状态边界

`IMPLEMENTED` 只表示 TB 已生成。没有 G7 的真实执行证据，不得写 `PASS`。

## 输出

```text
tb/P0/
tb/P1/
tb/P2/
docs/tb_readme.md
docs/test_id_to_tb.csv
TB_IMPLEMENTATION_STATUS
```

