# FPGA研发知识库 V2

四个Skill负责开发流程，模板负责交付格式，知识库提供技术内容。人工完成系统需求分解，给出功能边界、主要指标及关键参数的初步定值后，进入下表各阶段。

| 阶段 | 流程Skill | 技术入口 | 交付 |
|---|---|---|---|
| 1 | [设计规格与方案](skills/fpga-design-spec/SKILL.md) | [设计知识](knowledge/stages/01_设计规格与方案.md) | Word方案、Excel规格 |
| 2 | [代码编写与审查](skills/fpga-rtl-development-review/SKILL.md) | [代码知识](knowledge/stages/02_代码编写与审查.md) | RTL、编译/人工lint与CDC/功能检视/综合检查结果 |
| 3 | [测试点、用例与验证方案](skills/fpga-verification-planning/SKILL.md) | [验证策划知识](knowledge/stages/03_测试点用例与验证方案.md) | 测试点及用例Excel、验证方案Word |
| 4 | [验证代码、仿真与回归](skills/fpga-simulation-regression/SKILL.md) | [验证实施知识](knowledge/stages/04_验证代码仿真与回归.md) | 验证代码、每日回归、回填结果、仿真报告、implement及时序结果 |

各阶段输出交工程师确认；已有确认继续有效，实质变更返回相关阶段。第四阶段在功能仿真、回归基本完成后开展implement及时序收敛。

## 使用

告诉Agent当前阶段、模块功能和配置，以及本包位置。Agent先读对应Skill，再根据功能查阶段知识入口，读取相关主题；需要精确语义时回查随包来源。无需把全库一次性放进上下文。

示例指令：

> 使用本包fpga-verification-planning。按已确认的DDR读写规格分解测试点、用例及验证方案。先读阶段知识入口和DDR/AXI主题，核对当前burst与outstanding配置，按模板生成，保留规格和测试点反标，完成后提交确认。

内网GLM5.2和外网其他模型使用相同文件与调用顺序。当前包通过Agent读文件和文本搜索使用；不要求特定模型、联网或检索服务。更详细的准备见[使用与依赖](使用与依赖.md)。

## 模板与辅助入口

- [设计方案模板](templates/设计方案模板.docx)、[规格/测试点/用例模板](templates/设计规格_测试点_测试用例模板.xlsx)
- [验证方案模板](templates/验证方案模板.docx)、[仿真报告模板](templates/仿真报告模板.docx)
- [测试表填写说明](references/测试表填写说明.md)、[每日回归脚本使用](references/每日回归脚本使用.md)
- [全部技术主题](knowledge/知识目录.md)、[来源索引](sources/来源索引.md)、[内容缺口](knowledge/内容缺口.md)
- [反标示例](examples/反标关系示例.md)、[技术整理核对](knowledge/整理核对记录.md)、[检查记录](检查记录.md)
- [领导演示计划（待审核）](演示计划_初稿.md)：厂商风格流程与本行业务特色、公开方案对照、量化指标及试点安排
- [上传与发布安全检查](references/上传与发布安全检查.md)：上传前脱敏、发布时可选加密

本版资料整理日期为2026-10-13。历史工程通过结论均有范围说明，本轮交付验证的是文档内容与调用关系；未执行新的FPGA工程仿真、内网部署或GLM5.2效果测试。
