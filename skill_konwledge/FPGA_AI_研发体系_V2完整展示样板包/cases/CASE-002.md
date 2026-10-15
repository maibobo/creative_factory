# CASE-002 AUR-002：历史端口语义与wrapper映射

案例状态：7月历史集成仿真通过；V2复盘not_run  
时间关系：pre_kb_historical  
验证层级：integration_sim  
展示范围：内部材料，脱敏与展示许可pending_review  
证据来源：SRC-PCIE第4.2、9.3节，真实路径见[本地证据索引](../index/evidence_path_index.local.json)。

## 摸排摘要

| 字段 | 内容 |
|---|---|
| 展示题目 | AUR-002：历史端口语义与wrapper映射 |
| 展示内容 | RX 64拍进入FIFO，但burst done和IRQ不出现；对照内部方向与已通过integration TB，定位wrapper语义映射。 |
| 展示手段 | 任务包 → 接口表 → 修改语义 → 数据/IRQ证据 → 规则候选。 |
| 展示目标（效果） | 证明在明确的修改边界内，AI可帮助定位问题并通过系统里程碑验收。 |
| 风险点 | 复制旧案例答案会夸大AI能力：标注受控复盘；现场网络失败时用历史证据并标日期。 |

## 输入与冻结范围

冻结已有512 B场景、Root Port/TPI、XDMA Endpoint和LocalLink peer BFM。改动白名单仅wrapper；保护FDMA、adapter和CONV_DMA。

## AI辅助动作

读取日志、追踪valid/ready的实际方向及赋值，比较已通过harness，提出语义明确的网名与映射，整理回归检查项。

## 人工决策

决定继续兼容历史接口还是全局改名；批准只改wrapper；判断原模块证据是否适用当前版本。

## 机器证据与来源等级

SRC-PCIE记录历史CONV_DMA output fdma_wvalid实际表示accept，input fdma_wready实际表示源valid；通过的integration TB已交叉映射。最终512 B、IRQ req/ack及C2H通过，原文结果包括RTDS_ROOTPORT_PASS与RTDS_LOG_COMPARE_PASS。

源资料中的PASS只表示原报告描述的历史结果。本轮没有为本案例生成新的EDA运行。文件可访问与哈希一致只证明引用身份；更强的复现结论需要原始日志、代码快照及实际重跑。

## 结果与知识库作用

历史修复集中在PCIe wrapper，未改FDMA、adapter、CONV_DMA本体。它证明局部修复和系统验收相互对应。

历史修复早于2026-08-20资料库快照。这些记录说明哪些经验值得组织起来；后续V2如何减少重复解释或返工，需要另有执行记录。

## 可复用资产与回灌

接口语义检查表、修改白名单、TASK-AUR-001、需求-里程碑映射、OUT-AUR-001候选。

回灌候选应保留来源、范围、反例和人工审核。已归档的历史答案不能作为新项目默认架构。

## 未覆盖边界

LocalLink peer BFM不是Aurora GT/真实板级链路；IRQ ack也不能独自证明操作系统ISR。通用规则不是valid/ready必须交叉，而是必须核对实际方向和协议。

## 展示准备清单

准备脱敏接口表、历史前后映射摘要、512 B与IRQ里程碑、完整原日志入口。恢复问题只能在后续获授权的隔离副本进行；当前不给生产工程注入故障。

每次演示共同准备：脱敏输入、批准范围、证据摘要、真实路径本地索引、网络降级材料和结果状态。若现场网络30秒无有效响应，使用历史材料并明确时间；不把静态回放称为现场运行。

## PPT讲述顺序

“数据进来了，完成信号为什么没来？”展示名字与实际含义的差别，最后打开验收矩阵。两到三页，领导版主案例。

[返回入口](../README.md)｜[完整设计阶段合同](../task_pack/README.md)

