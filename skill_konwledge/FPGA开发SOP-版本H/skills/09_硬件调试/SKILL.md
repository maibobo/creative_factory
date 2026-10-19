---
name: fpga-hardware-debug
description: 使用 ILA/VIO 对已验证版本进行硬件观测、触发、采集和问题定位。
version: 1.0.0
language: zh-CN
stage: G9
---

# 硬件调试 Skill

## 前置条件

- 已记录 bitstream/PDI、RTL、实现和寄存器版本；
- 板卡、电源、时钟、复位、配置链路和通信接口正常；
- ILA/VIO 核存在且与当前下载版本匹配；
- 已有仿真 Expected、触发条件和观测点。

## ILA 流程

```text
发现 Debug Core
→ 确认 Probe/时钟
→ 配置触发条件和采集深度
→ Arm/Capture
→ 导出波形
→ 对照仿真和实现版本分析
```

## VIO 流程

```text
读取输入 Probe
→ 驱动受控输出
→ 观察状态变化
→ 记录操作顺序、版本和结果
```

禁止用 VIO 随意驱动超出设计定义的非法场景并把结果当作正式功能结论。所有硬件观测都要记录时间、版本、触发条件和原始采集文件。

## 输出

```text
evidence/hardware/<run-id>/ila_capture.csv|vcd
evidence/hardware/<run-id>/vio_actions.md
docs/hardware_debug_report.md
HW_EVIDENCE
```

