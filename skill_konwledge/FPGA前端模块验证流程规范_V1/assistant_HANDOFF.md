# Codex 实施交接说明

## 目标

基于 `00_research_sources/` 中两份已经完成的 Deep Research 结果，生产一套可直接落库、可维护的 FPGA 前端模块级验证规范。不要重新做 Deep Research。

## 目标目录

`skill_konwledge/FPGA前端模块验证流程规范_V1/`

## 输入

- `00_research_sources/DeepResearch_A_模块级验证流程规范与完整交付包.md`
- `00_research_sources/DeepResearch_B_深度研究结论与V1.0草案交付.md`
- 同仓库已有参考：
  - `skill_konwledge/kimi/`
  - `skill_konwledge/FPGA研发知识库_V2/`
  - `skill_konwledge/FPGA研发知识库-10-14/`

## 已确认的核心边界

- FPGA 单模块 RTL 动态功能仿真，默认模块级，不展开 UT/IT/TOP/ST。
- 不包含 Lint、CDC、Formal、综合实现、布局布线、静态时序、板级测试、Functional Coverage、Python/cocotb。
- 验证环境三档：基础 TB、轻量级 SystemVerilog、完整 SV / 轻量级 UVM。
- 主流程采用 Entry + V1~V6。
- Code Coverage 关注 Line、Condition、FSM；Toggle 可按需要；工具不支持的指标必须记录 N/A/能力限制，不伪造数字。
- Coverage 不设公司级统一硬门槛；必须做 Hole 分析与解释。
- Assertion 可选；启用后有效 Assertion Failure = Test Failure。
- 适用场景使用 constrained random；Seed 必须可复现。
- AI 允许起草、生成、分析和建议，但方案、代码、Coverage 解释、问题关闭和最终 Sign-off 都需要人工确认。

## 实施要求

1. 先比较两份 Deep Research，生成 `RESEARCH_DIFF_AND_DECISIONS.md`，列出一致项、差异项、采用结论。
2. 再按定稿结构生成完整 Markdown 规范、模板、Skills、Mermaid/图示素材和质量发布文件。
3. Office 模板（DOCX/XLSX）必须实际生成并可打开，不允许只写“已生成”的文字说明。
4. 所有相对链接必须可用；不得保留 TODO 占位。
5. 不直接修改或删除 `00_research_sources/`。
6. 完成后生成 `MANIFEST.md`，列出全部文件、用途、来源和校验状态。
7. 最终以 PR 方式提交，避免直接覆盖 main。

## 交付重点

三份核心项目交付物：
- 测试点/测试用例矩阵 Excel
- 验证方案 Word
- 最终仿真回归报告 Word（Coverage 纳入其中）

同时保留用于长期维护的 Markdown、SKILL.md、Mermaid 和质量检查文件。
