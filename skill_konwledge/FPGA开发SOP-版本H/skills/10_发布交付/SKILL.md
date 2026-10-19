---
name: fpga-release-revision-control
description: 固化 Vivado 工程、源文件、IP、约束、脚本、报告和重建验证结果。
version: 1.0.0
language: zh-CN
stage: G10
---

# 发布与版本控制 Skill

## 交付盘点

- RTL、仿真源、TB、include 和生成脚本；
- XDC/SDC、IP/XCI、Block Design、器件和版本信息；
- 综合/实现配置、bitstream/PDI 和软件寄存器依赖；
- 设计、Review、验证、仿真、时序和硬件报告；
- 已知问题、接受风险、变更记录和 `project_manifest.yaml`。

## 推荐流程

```text
识别工程类型
→ 分析源文件和生成物
→ 导出必要源文件/IP/BD
→ 捕获工程设置
→ 生成可重建脚本
→ 在独立目录重建
→ 比较源清单、IP 数量、器件、约束和关键结果
→ 生成 Release Package
```

## 交付要求

- 不依赖个人绝对路径、临时目录或未说明的环境变量；
- 生成物和缓存是否交付必须明确，不默认全部纳入版本库；
- 发布包包含工具版本、目标器件、基线版本和构建入口；
- 重建失败时状态为 `BLOCKED` 或 `FAIL`，不能发布为 PASS；
- 版本冻结后任何变更都要更新变更记录并重新评估受影响 Gate。

## 输出

```text
release/<project>-<version>/
├── sources/
├── ip/
├── constraints/
├── scripts/
├── reports/
├── evidence/
├── project_manifest.yaml
├── BUILD.md
└── RELEASE_NOTES.md
```

