# 海思风格数字 IC 代码规范包

版本：1.0.0  
发布日期：2026-09-02

本规范包将 ASIC Verilog RTL 与 SystemVerilog/UVM 验证代码分开管理。ASIC RTL 只采用可综合 Verilog-2001 子集；验证代码以当前 VCS Q-2020.03-SP2-7、UVM 1.2 为可执行基线，并给出向 IEEE 1800-2023、IEEE 1800.2-2020 对齐的规则。

## 文档导航

| 文件 | 用途 |
|---|---|
| [01_ASIC_Verilog_RTL代码规范.md](01_ASIC_Verilog_RTL代码规范.md) | ASIC 设计 RTL 的强制规则和推荐实践 |
| [02_SystemVerilog_UVM验证代码规范.md](02_SystemVerilog_UVM验证代码规范.md) | 独立的 SystemVerilog/UVM 验证规范 |
| [03_用户自定义规则.md](03_用户自定义规则.md) | 四条自定义规则的正式定义、例外和示例 |
| [04_代码评审检查表.md](04_代码评审检查表.md) | RTL 与验证代码评审、签核清单 |
| [05_来源与冲突裁决.md](05_来源与冲突裁决.md) | 本地资料、联网来源和冲突裁决记录 |
| [06_验证记录.md](06_验证记录.md) | 本次结构、语法和待执行验证状态 |
| [07_AI协作任务下达与审查补充.md](07_AI协作任务下达与审查补充.md) | 任务下达模板、可信资料规则、AI 生成代码专项审查、成本控制与协作记录 |
| [config/custom_rules.json](config/custom_rules.json) | 用户自定义规则的唯一数据源 |
| [config/approved_cells.json](config/approved_cells.json) | 项目批准单元/IP/包装器登记表 |
| [config/trusted_sources.json](config/trusted_sources.json) | AI 任务可信资料登记表（芯片手册/TRM/SDK 等，人工提供） |
| [tools/validate_package.py](tools/validate_package.py) | Python 3.6+ 包级一致性检查 |
| [examples/rtl/asic_rtl_template.v](examples/rtl/asic_rtl_template.v) | 纯 Verilog-2001 RTL 示例 |
| [examples/sv_uvm_minimal/README.md](examples/sv_uvm_minimal/README.md) | 最小 UVM 工程说明 |

## 规则级别

- **M1（Mandatory 1）**：必须遵守。发现问题必须修复后才能合入或签核。
- **M2（Mandatory 2）**：原则上必须遵守。不能遵守时必须有明确技术理由、影响分析和批准的豁免单。
- **R（Recommended）**：推荐实践。偏离不阻断签核，但评审者可要求说明。

规则优先级从高到低为：项目正式豁免/签核决定、用户自定义规则、本文新增的项目规则、《海思 ASIC 工程师手册》2.1、《海思 Verilog 编程规范》、数字 IC 学习资料。语言标准决定语法语义，不能被内部文档覆盖。

## 使用方式

1. RTL 作者阅读 `01` 和 `03`，并按 `04` 的 RTL 部分自检。
2. 验证作者只把 `02` 作为 SystemVerilog/UVM 编码依据；不得把其中的 `logic`、class、interface 等语法带入 ASIC RTL。
3. 评审者记录每个 M1/M2 问题的规则编号。例外必须关联豁免单，而不是只写在评审聊天中。
4. 项目管理员补齐 `approved_cells.json` 后，才可在 ASIC 签核配置中使用对应单元。
5. AI 协作任务按 `07` 下达和审查；任务引用的手册/SDK/环境必须先登记进 `trusted_sources.json` 并达到 `approved` 状态。

## 修改自定义规则

只修改 `config/custom_rules.json`，不要直接编辑文档内带 `GENERATED` 标记的区块。修改后执行：

```text
python tools/sync_custom_rules.py --write
python tools/sync_custom_rules.py --check
```

`--write` 更新 `01`、`03`、`04` 中的受控内容；`--check` 在内容过期、规则编号重复、字段缺失或级别非法时返回非零退出码。受控区块之外的人工补充不会被工具覆盖。

提交或交付前执行完整结构检查：

```text
python tools/validate_package.py
```

该工具兼容本机 Python 3.6，检查 UTF-8 JSON、规则引用、受控区块、本地 Markdown 链接、批准单元分类、RTL 禁用语法、UVM 禁用写法和 filelist 完整性；它不代替真实 EDA 编译。

## 批准单元登记

`config/approved_cells.json` 中初始条目均为 `pending_user_input`。用户后续应填写实际模块/IP 名称、统一包装器、路径、版本、负责人、适用配置和签核证据，并将状态改为 `approved`。任何 `TBD` 或非 `approved` 条目都不能作为 ASIC 签核依据。

## 明确不在范围内的内容

- 文件头模板、作者/日期/修订历史等文件头规则。
- 对注释比例、语言、对齐列数或逐行注释的通用格式要求。
- 模拟器、综合器、CDC/STA 工具的完整命令行和项目签核流程。
- 具体工艺库、标准单元、第三方 IP 的真实名称；这些由项目登记表补齐。

保留的注释要求只有“按语义段解释意图、约束、时序和例外”，详见 `CUSTOM-RTL-004`。
