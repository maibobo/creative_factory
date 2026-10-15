# CASE-002 历史技术摘录

> 摘自原展示案例的技术部分；本轮未复跑，SRC编号的来源身份见[历史来源定位](../历史来源定位.md)。

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

