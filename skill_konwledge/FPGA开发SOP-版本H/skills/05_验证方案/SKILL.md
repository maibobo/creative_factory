---
name: fpga-simulation-verification-plan
description: 从设计基线、Stable RTL 和 Review 风险生成 P0/P1/P2 仿真验证计划。
version: 1.0.0
language: zh-CN
stage: G5
---

# 仿真验证方案 Skill

## 目标

定义可执行、可判定、可追溯的测试项。该 Skill 不编写 TB，不执行仿真，不提前填写真实 PASS/FAIL、波形、日志或 Coverage。

## 输入分析

- 设计模块边界、接口、协议、时钟复位、数据格式和性能；
- `RTL_STABLE` 的模块、参数、FSM、分支、FIFO、Memory、CDC/RDC 和保护路径；
- Review Issue、Needs Simulation 清单和已有 Golden Data；
- 工程、IP 模型、仿真器和回归限制。

## 测试分层

### P0 基本主链路

覆盖复位、空闲、最小/典型事务、数据格式、基本握手、连续合法事务和状态统计。

### P1 定向验证

按实际 RTL 动态生成测试，至少考虑接口、FSM、参数/generate、FIFO/RAM、指针计数、位宽算术、背压、Reset、CDC/RDC、错误恢复、寄存器和 E2E。

### P2 随机回归

- `MODE=0`：合法随机，不主动注入未定义错误；
- `MODE=1`：长时间稳定，检查死锁、漂移、回绕、资源泄漏；
- `MODE=2`：只注入设计定义的错误并验证恢复。

## Test Case 必填字段

```text
Test ID
Test Name
Design/RTL Trace
Stimulus / Condition
Expected Result
Checker / Scoreboard
Timeout
Coverage Target
Result: 尚未执行
```

## 完成条件

- 设计项、Review 风险和测试项形成追溯矩阵；
- 每个 Expected 都可自动判定或明确说明人工判定方式；
- 运行环境、Seed、回归和 Coverage 准则已定义；
- 报告中的真实结果字段保持“尚未执行”，进入 G6。

