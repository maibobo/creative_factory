# ARM Linux 设计指南输入资料包（2026-10-19）

此目录供后续网页端编写当前 Linux 设计指南使用，不是已经完成的 Linux 产品工程。已复制必要应用源码、联动脚本、当前手册、选定历史文档、FPGA 软件接口参考源码和18项实测证据。没有提交或推送 GitHub。

## 推荐阅读顺序

1. [编写任务与事实边界](guide_input/01_网页端编写任务与事实边界.md)
2. [驱动、应用与依赖关系](guide_input/02_驱动应用代码与依赖关系.md)
3. [近期讨论要点](guide_input/03_近期讨论与DMA证据摘要.md)
4. [当前源码说明](hardware_joint_lab_20261016/docs/RTDS_ARM测试程序源码说明_20261019.md)
5. [板内实测记录](hardware_joint_lab_20261016/docs/RTDS_板内联动实测记录_20261019.md)
6. [ILA/VIO波形附册](hardware_joint_lab_20261016/docs/RTDS_ILA_VIO实测波形判读附册_20261019.md)
7. [历史上下行步骤](history_docs/RTDS_驱动与主机单机联调_上下行完整操作步骤_20261013.md)
8. `fpga_reference/new/INFO_EXCH.v`、`PCIe.v`及上行writer/adapter，核对寄存器与数据路径。

## 上传范围

上传本资料包目录及其全部内容即可。MD便于网页读取，DOCX保留原手册及插图；CSV/JSON保留可复核证据；.bin仅为16Byte实验载荷。现有同仓库的完整FPGA工程可作为扩展参考，本包FPGA片段不构成可独立重建bit的工程。

不要把上级目录中的 MobaXterm.ini、MobaXterm backup、会话密码/密钥、MobaXterm程序、插件、Vivado缓存和全部历史压缩包当成Linux设计依赖。本次没有复制这些文件。注意上级仓库原本已经跟踪了MobaXterm.ini及其备份；本次未修改或删除它们，也未清理Git历史。

`manifest.json`记录本包各文件原始位置及SHA256；`package_validation.json`记录复制校验与DOCX结构检查。历史版本、原部署文件均保留，此次采用新增目录快照，不覆盖旧版。

## 当前不能提供的内容

ARM当前实际XDMA驱动源码、精确版本、内核构建配置与补丁尚未取得；详见依赖说明的“缺失输入”。不能把参考官方源码说成板端已核对源码，也不能把用户态rtds_dma.c说成内核驱动。

本上传副本已按本地词表检查，两处主机名文字替换为REDACTED；实验数据与程序未改。检查说明见keyword_screening.json。
