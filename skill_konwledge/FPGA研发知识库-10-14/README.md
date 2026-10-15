# FPGA研发知识库

四个Skill组织设计验证流程，技术资料库按功能提供内容，模板统一交付格式。向Agent提供本目录和任务即可从这里选择入口。

| 任务 | Skill | 主要交付 |
|---|---|---|
| 设计规格与方案 | [fpga-design-spec](skills/fpga-design-spec/SKILL.md) | 设计方案、规格Excel |
| RTL开发与审查 | [fpga-rtl-development-review](skills/fpga-rtl-development-review/SKILL.md) | RTL、语法编译/代码检视/综合检查结果 |
| 测试点、用例与验证方案 | [fpga-verification-planning](skills/fpga-verification-planning/SKILL.md) | 测试表、验证方案 |
| 验证代码、仿真与回归 | [fpga-simulation-regression](skills/fpga-simulation-regression/SKILL.md) | 验证代码、回归、报告、implement及时序结果 |

## 调用顺序

**本页 → 对应Skill → 当前功能的技术主题和模板 → 项目输入及运行检查。**

Agent根据当前任务和已有交付件选择阶段，按相关功能读取资料。设计输入为工程师完成的系统需求分解和关键参数初值；各阶段交付交人工确认，已确认的内容继续有效，实质变更返回相关阶段。

可直接使用的指令：

> 读取本目录，按我提供的设计规格和验证方案进入验证实施阶段。选择相关Skill，生成验证代码和用例入口，按测试表顺序运行并整理结果。

## 知识与模板

| 主题 | 主要内容 |
|---|---|
| [工程基础](技术资料库/README.md#工程基础) | 架构、编码、CDC、FIFO和总线 |
| [验证与实现](技术资料库/README.md#验证与实现) | 测试分解、环境、仿真回归、实现及时序 |
| [IP与集成](技术资料库/README.md#ip与集成) | Aurora、PCIe/DMA、DDR/MIG、以太网和跨IP |
| [工程案例](技术资料库/README.md#工程案例) | 接口映射、观察模型、初始化、采样及故障判据 |

[使用方法](使用方法.md) · [技术资料库](技术资料库/README.md) · [模板目录](templates/README.md) · [执行工具](scripts/README.md) · [安全检查](技术资料库/安全检查.md)

## 示例

- [DDR批缓存](examples/DDR批缓存/示例说明.md)：Markdown与Excel展示功能、测试分解和验证环境。
- [总线桥](examples/总线桥/示例说明.md)：Word与Excel展示完整的设计、验证和结果填写结构。
- [演示计划](演示计划.md)：按两个实例串起输入、检查、交付和指标。

[验证组织方式评价](验证组织方式评价.md)按实例比较维护与检查方式；[交互界面方案](交互界面方案.md)说明本地阅读工作台的用途与验收。
