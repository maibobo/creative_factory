---
name: fpga-design-solution
description: 将 FPGA 需求整理为可确认、可实现、可验证的设计方案基线。
version: 1.0.0
language: zh-CN
stage: G1
---

# 设计方案 Skill

## 目标

把原始需求、协议、寄存器、IP 和器件资料转换为 `DESIGN_BASELINE`。本 Skill 不写 RTL，不根据已有 RTL 反向猜测未确认需求。

## 必须读取

- 原始需求和功能边界；
- 目标器件、工具版本和 RTL 语言；
- 模块上下游关系和协议；
- 时钟、复位、接口、数据格式和寄存器表；
- 缓存/FIFO/RAM、IP 配置、性能和异常要求；
- 已有 RTL 只作为现状参考，不作为需求来源。

## 必须定义

1. 功能范围和不包含范围；
2. 系统位置、数据流和一次事务生命周期；
3. 参数、顶层接口、握手、帧边界和时钟域；
4. 时钟频率、复位极性/同步方式/释放策略；
5. 数据位域、端序、位宽转换、缓存深度和边界行为；
6. FSM、并发、仲裁、超时、中止和错误恢复；
7. 软件寄存器、IP 参数、约束和外部依赖；
8. 吞吐、延迟、最大规模、资源和可接受背压；
9. 验收条件和需要验证的风险。

## 缺失信息

- 影响接口、协议、时序、复位、数据格式或错误行为的缺失项标记为 `BLOCKING`；
- 不影响架构的细节可显式写成 `ASSUMPTION`；
- 冲突必须记录资料、影响、建议和当前处理，不能默选。

## 输出

```text
docs/design_spec.md
docs/interface_table.md
docs/clock_reset_map.md
docs/register_ip_list.md
docs/open_issues.md
DESIGN_BASELINE
```

## 完成条件

- 关键问题已确认或明确阻塞；
- 接口、时钟、复位、数据和性能可以指导 RTL；
- 每个重要设计项都有后续 Review 或 Test ID 追溯入口；
- 用户/责任人确认后才进入 G2。

