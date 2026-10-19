---
name: fpga-static-verification
description: 对 RTL 执行 Compile、Elaboration、Lint、CDC/RDC 和必要的 DRC 静态检查。
version: 1.0.0
language: zh-CN
stage: G3
---

# 静态验证 Skill

## 目标

在仿真前发现语法、Elaboration、未驱动信号、Latch、位宽、时钟复位、CDC/RDC、接口和综合可行性问题。

## 执行顺序

```text
确认工程/非工程模式
→ 确认器件和顶层
→ 更新编译顺序
→ Compile/Elaboration
→ Vivado RTL Lint
→ CDC/RDC
→ 必要的 DRC/接口检查
→ 解析报告并分类问题
```

## 工具规则

- 优先使用 Vivado Tcl/MCP 或项目既有脚本，不能默默切换工具或版本；
- Lint 只报告工具实际产生的消息；报告格式优先使用工具或官方解析器；
- 每条问题保存文件、行号、规则 ID、严重等级、原始消息和上下文；
- `INFO/WARNING` 不自动忽略，先判断是否影响 QoR、协议或可维护性；
- 需要修改时采用最小变更，修改后重新运行受影响的检查；
- 不把人工静态阅读写成 Lint/CDC PASS。

## 输出

```text
reports/compile/
reports/elaboration/
reports/lint/
reports/cdc/
reports/rdc/
docs/static_issue_list.md
G3_TOOL_EVIDENCE
```

## 完成条件

- 所有 Critical/Major 问题已修复、转入后续验证或批准接受；
- 报告带有工具版本、器件、顶层、输入基线和运行时间；
- 不能静态证明的问题明确标记 `NEEDS_SIMULATION` 或 `NEEDS_IMPLEMENTATION`。

