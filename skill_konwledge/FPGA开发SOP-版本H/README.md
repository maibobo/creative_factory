# FPGA 开发 SOP v2

这套独立 SOP 将两类能力组合为一个项目流程：

- 中文全流程 Skill：负责需求、设计基线、阶段交付物和质量门。
- AMD Ross Skill：负责 Vivado/Vitis 工具执行、报告证据和专项诊断。

运行本 SOP 不要求读取原来的两个目录；原始 Skill 只作为设计来源保留。当前目录已经包含可独立使用的阶段 Skill 卡片。

## 目录

```text
FPGA开发SOP-v2/
├── README.md                         # 使用说明和总原则
├── 00_总SOP.md                       # 端到端流程与角色边界
├── 01_质量门定义.md                  # G0-G10 入口、出口和证据要求
├── 02_阶段输入输出矩阵.md            # 各阶段输入、输出、调用 Skill
├── 03_Skill调用编排.md               # 多 Skill 的调用顺序和条件
├── 04_状态与证据规范.md              # 状态、基线、报告和问题闭环
├── skills/                            # 本地可调用的阶段 Skill
│   ├── 01_设计方案/SKILL.md
│   ├── 02_RTL开发/SKILL.md
│   ├── 03_静态验证/SKILL.md
│   ├── 04_RTL审查/SKILL.md
│   ├── 05_验证方案/SKILL.md
│   ├── 06_TB开发/SKILL.md
│   ├── 07_仿真执行/SKILL.md
│   ├── 08_实现时序/SKILL.md
│   ├── 09_硬件调试/SKILL.md
│   └── 10_发布交付/SKILL.md
├── templates/
│   ├── project_manifest.yaml          # 项目和工具基线模板
│   └── traceability.csv              # 需求-设计-RTL-测试追溯模板
└── branches/
    └── README.md                     # HLS、Vitis AI、Versal/DFX 分支说明
```

## 使用方式

1. 新项目从 `G0` 开始，先填写项目清单和环境基线。
2. 每个阶段先读取输入，再调用阶段 Skill；工具 Skill 只在需要真实工具证据时调用。
3. 未满足出口条件时不得进入下一质量门；允许以 `BLOCKED` 或 `ACCEPTED_RISK` 留痕后暂停。
4. 设计方案是默认 Golden Reference；任何需求或架构变化必须通过变更记录更新基线。
5. `IMPLEMENTED`、`TOOL_VERIFIED` 和 `PASS` 分开记录，不能互相替代。

## 核心原则

- 用户当前指令 > 已批准设计方案 > 正式接口/寄存器协议 > 已确认 RTL > 工具报告 > 历史资料 > 经验推断。
- 方案、RTL、验证计划和结果之间必须有可追溯关系。
- Review 可以发现问题，但不能把未运行的工具结果写成通过。
- 仿真通过不等于时序收敛；功能仿真、实现时序、CDC、形式验证和硬件调试分别判定。
- HLS、Vitis AI、Versal/DFX 是共享质量门下的并行分支，不强行套用 RTL 阶段。

## 设计来源

- [原 FPGA 五阶段总导航](<../FPGA设计全流程Skill/FPGA设计全流程Skill.md>)
- [AMD Ross Assistant](<../ross-ai-assistant-main/ross-ai-assistant-main/README.md>)

## 独立使用原则

优先调用 `skills/` 下的本地 Skill；外部 Ross Skill 只作为工具适配器或更深专项能力使用。没有 Vivado MCP 时，可按各 Skill 的命令/报告接口改用本地 Vivado GUI 或 Batch Flow，但必须保留相同的输入、输出和证据要求。

