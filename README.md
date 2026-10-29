# creative_factory

## RTDS PCIe/DDR主机工程

当前主机FPGA工程位于 [RTDS_test_DDR4_64bit_batch_dev](RTDS_test_DDR4_64bit_batch_dev/)。

**当前业务版本：V2.02**

| 项目 | 修改前（V2.01） | 修改后（V2.02） |
|---|---|---|
| VERSION（`0x00`） | `0x00002001` | `0x00002002` |
| PROG_TIME（`0x04`） | `0x20260914` | `0x20261029` |
| 1G同步字段 | 第2拍内 `0xF0` | 第4拍低16bit为 `16'hEB90` |
| `DDR_STATUS`（`0x2C`） | Bit31:5保留 | Bit5～8为Aurora调试状态 |

- [主机工程README与修改摘要](RTDS_test_DDR4_64bit_batch_dev/README_本地开发.md)
- [PCIe交互协议 V2.02](RTDS_test_DDR4_64bit_batch_dev/docs/PCIe交互协议_V2.02.md)
- [软件寄存器说明 V2.02](RTDS_test_DDR4_64bit_batch_dev/docs/CPU-FPGA_PCIe软件寄存器说明_V2.02_当前实现.md)

10G原始16Byte帧继续原样转发，不进行字节交换；1G改为Vin、duty高16位、预留拍和`16'hEB90`同步尾拍。V2.02代码尚未完成Vivado综合、实现或上板验证。
