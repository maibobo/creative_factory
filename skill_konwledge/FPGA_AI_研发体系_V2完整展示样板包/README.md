# FPGA AI研发体系 V2完整展示样板包

版本：2.0.0-demo｜制作日期：2026-09-08｜用途：内部评审与演示准备

本包围绕“借AI规范FPGA前端设计验证流程”组织，展示知识如何成为工程任务的输入、验收依据和团队可复用资产。试点目标为同类任务周期缩短30%，当前未形成达成实测。主入口为[主方案与案例分析](../FPGA_AI_知识库结构与案例分析_v2.md)。

当前交付是可浏览的文档、结构化对象和校验工具。案例描述来源于已有工程资料；本轮没有重新执行历史仿真。示例Skill未安装，检索后端、Agent调度与EDA启动器未接通。所有未来试验的运行结果保持空值。

## 从哪里开始

第一次使用，先看[接地气使用指南](接地气使用指南.md)：有领导怎么听、同事怎么做、可以直接复制的指令，以及30%目标怎样测量。

| 使用者 | 阅读路线 | 能得到什么 |
|---|---|---|
| 管理层 | [管理层视图](00_管理层视图.md) → CASE-001全流程 → CASE-002片段 → 主方案页纲 | 看到完整流程、阶段交付件与试点目标 |
| 工程师 | [工程实现视图](01_工程实现视图.md) → 规则卡 → 任务包 → 门禁 | 看到下一个任务需要准备什么 |
| 任意岗位 | [通用使用方法](02_通用使用方法.md) | 领域无关的人机协同闭环、可信资料规则、案例写法 |
| 维护者 | 治理 → 对象登记 → 回灌 → 校验 | 看到哪些内容可以更新、如何保留出处 |
| 材料制作者 | 主方案第8章 → 案例卡 → [来源索引](index/evidence_path_index.local.json) | 按证据编号制作PPT或Word，按状态筛选内容 |

## 全部形态与文件导航

| 组成 | 文件 | 实填内容 |
|---|---|---|
| 通用方法 | [通用使用方法](02_通用使用方法.md) | 人机协同三前提、五环节闭环、领域映射、可信资料与成本控制 |
| 职责和状态 | [治理规则](governance/治理_证据与状态规则.md) | 数据边界、证据等级、签核与回灌 |
| 企业规则 | [规则卡](rules/企业规则卡与适用范围.md) | 4条现有自定义规则的引用和配置选择 |
| 文档规范 | [五类模板与填写示例](document_rules/文档模板与填写示例.md) | 设计、验证、测试点、问题、验收 |
| 批准输出 | [候选与差异记录](approved_examples/批准输出候选与差异分析.md) | AUR-002历史修复及规则提炼 |
| 对象接口 | [字段合同](objects/object_contract.schema.json)、[对象样例](objects/knowledge_objects.example.json) | 规则、验收、输出候选、证据、案例关联 |
| 任务包 | [字段说明](task_pack/README.md)、[AUR复盘](task_pack/TASK-AUR-001.json)、[留出任务](task_pack/TASK-HO-001.json) | 一个可准备的历史复盘、一个待决策新任务 |
| Skill | [执行合同](skill/fpga-rnd-closure-demo/SKILL.md) | 任务检查、证据检索、有限执行、停止升级 |
| 验收 | [门禁与分类](eda_gates/门禁判定与故障分类.md)、[门禁目录](eda_gates/gate_catalog.json)、[运行模板](eda_gates/run_manifest.example.json) | 必需检查、失败分类、空运行记录 |
| 案例 | [全流程](cases/CASE-001.md)、[接口映射](cases/CASE-002.md)、[参数审查](cases/CASE-003.md)、[工具纠错](cases/CASE-004.md)、[回归可信度](cases/CASE-005.md)、[DMA观察模型](cases/CASE-006.md)、[规范工程化](cases/CASE-007.md)、[留出试验](cases/CASE-008.md) | 八张独立案例卡 |
| 评测 | [试验设计](evaluation/EVAL-001.md)、[空结果矩阵](evaluation/evaluation_matrix.example.json) | 三组对照、答案隔离与人工介入记录 |
| 回灌 | [审核流程](feedback/回灌审核与发布流程.md)、[候选卡](feedback/feedback_card.example.json) | 从人工修改提炼范围明确的规则 |
| 索引 | [资产索引](index/asset_registry.example.json)、[追踪矩阵](index/traceability_matrix.example.json)、[本地证据索引](index/evidence_path_index.local.json) | ID与来源、需求与测试的映射 |
| 校验 | [只读校验脚本](tools/validate_sample.py)、[交付检查记录](交付检查记录.md) | 文档结构、JSON、引用、状态和源文件保护 |

## 证据使用

正文里的 SRC 编号在本地证据索引中解析。该索引含原始绝对路径，标记为 LOCAL_ONLY_DO_NOT_EXPORT。任何“可展示”的内容目前均为待脱敏审核，不能从“已经生成”推断为“允许公开”。

原Xilinx知识库及代码规范包通过路径与哈希引用，不迁移、不复制、不重建。样板采用Markdown导航；不包含网页、交互搜索或数据库管理界面。

## 本地检查

在本目录执行：

```text
python tools/validate_sample.py
```

RESULT PASS仅代表展示包的结构和约束检查通过。实际工程的编译、仿真、覆盖率、时序和上板结果必须另有运行证据。
