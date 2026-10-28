# RTDS 联调演示归档（2026-10-27）

此目录是从 RTDS 工程 debug\hardware_joint_demo_20261027 复制的资料快照，供 MobaXterm 便携包旁查阅。运行时以 C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\debug\hardware_joint_demo_20261027 为准，因为 Vivado Tcl 和 GUI jobs 使用该工程路径。

包含 ARM/Linux 监视程序、Windows Python 控制与提示窗、Vivado Tcl、说明文档、实时事件、板级运行日志，以及 ILA/VIO 采样。为避免误用过期握手状态，未打包 jobs 会话目录；新会话由 open_demo.tcl 创建。Python 缓存和文档旧稿备份也未纳入。

操作顺序和命令见上级目录 RTDS_上板联调操作说明_20261028.md。旧版 ARM C DMA 源码仍在上级 linux_design_handoff_20261019_155820\hardware_joint_lab_20261016\arm\rtds_dma.c。

另附 Word 版双日志解读与上板验证计划，文件位于 docs\RTDS双日志详细解读与上板验证计划_20261027.docx。
