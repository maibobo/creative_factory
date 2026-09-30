# RTDS V2.01 开发工程

当前业务版本为 `0x00002001`。远程主工程：`C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\RTDS_test_DDR4_64bit.xpr`。

- 协议以 [PCIe交互协议 V2.01](docs/PCIe交互协议_V2.01.md) 为准。
- 下行16Byte帧原样送10G；单个32bit Aurora 1G首次配置后每63个用户时钟产生一次6Byte发送机会。
- 上行仅保存10G每拍低32bit，紧凑写入100ms×8块DDR，CPU按实际字节数读取并确认。
- TOP已加入一个verified 1G封装实例。其来源为远程 `C:\project\RTDS\aurora_8b10b_1p25g_2020_2_verified`，工程内快照为 `external_snapshot/aurora1g_verified`。
- 本轮模块前仿已执行；完整覆盖状态见实际验证报告。旧日志和备份说明不能作为V2.01验收依据。
- 本轮不执行综合、实现或上板。保留原工程与原本机备份。

重新生成BD使用 `scripts/refresh_batch_bd.tcl`；补齐引用使用 `scripts/repair_project_references.tcl`。不要运行历史64KiB映射脚本覆盖当前4MiB映射。
