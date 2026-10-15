# FPGA 设计全流程 Skill

> 导航页（MOC）。本组收录用户自研的 FPGA 前端开发 5 阶段 Skill 链，覆盖「方案设计 → RTL 编写 → 代码审查 → 仿真方案 → TB 开发」全流程。来源目录：`知识笔记/FPGA设计全流程Skill/AI Skill/`。

## 全流程总览

- 总表：[00 工作流程.docx](<AI Skill/00 工作流程.docx>) — 5 阶段输入 / 输出对照
- 配套模板：
  - [通用IP设计方案模板.docx](<AI Skill/01 设计方案/通用IP设计方案模板.docx>)
  - [通用FPGA仿真报告模板.docx](<AI Skill/04 仿真方案/通用FPGA仿真报告模板.docx>)

## 五阶段 Skill

| 阶段        | SKILL 页面                                    | 产出                         |
| --------- | ------------------------------------------- | -------------------------- |
| 01 方案设计   | [[FPGA_Design_Solution_Development_SKILL]]  | XX模块设计方案                   |
| 02 RTL 编写 | [[FPGA_RTL_Verilog_Development_SKILL]]      | RTL 代码 + IP 配置清单           |
| 03 代码审查   | [[FPGA_RTL_Verilog_Code_Review_SKILL]]      | Review 报告 + 整改清单 + RTL 稳定版 |
| 04 仿真方案   | [[FPGA_Simulation_Verification_Plan_SKILL]] | 仿真报告                       |
| 05 TB 开发  | [[FPGA_Verilog_TB_Development_SKILL]]       | TB 代码 + TB 说明文档            |

## 流水线关系（4 个通用机制）

1. **Golden Reference 单向流动**：设计方案是全程基准，下游 Skill 不得反向修改需求。
2. **职责分离**：Author（02 开发）与 Reviewer（03 审查）独立，避免自降审查标准。
3. **冲突优先级层级**：用户指令 > 设计方案 > 接口协议/寄存器表 > 设计变更/IP 配置 > RTL 现状 > 历史资料 > 经验推断。
4. **质量门（Gate）**：03 收敛至 RTL Stable 才能进 04；04 产出仿真报告才能进 05。

## 关联

- 上游衔接 [[IP核技术手册]]（RTL 阶段调用的 IP 原理）与 [[芯片器件资源]]（目标器件资源）。
- 返回 [[index]]。
