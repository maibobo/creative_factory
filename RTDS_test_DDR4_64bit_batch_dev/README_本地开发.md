# RTDS V2.02 开发工程

当前业务版本：**V2.02**。远程主工程：`C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\RTDS_test_DDR4_64bit.xpr`。

## 版本变更记录

| 项目 | 修改前（V2.01） | 修改后（V2.02） |
|---|---|---|
| `VERSION`，寄存器偏移 `0x00` | `0x00002001` | `0x00002002` |
| `PROG_TIME`，寄存器偏移 `0x04` | `0x20260914` | `0x20261029` |
| 1G同步字 | 第2拍内的 `0xF0` | 第4拍低16bit为 `16'hEB90` |
| `DDR_STATUS` 调试位 | Bit31:5保留 | Bit5～8增加四个Aurora状态位 |

V2.01版本的协议和寄存器说明保留作历史记录；当前请使用 [PCIe交互协议 V2.02](docs/PCIe交互协议_V2.02.md) 和 [软件寄存器说明 V2.02](docs/CPU-FPGA_PCIe软件寄存器说明_V2.02_当前实现.md)。

## 当前数据格式

### 10G下行

主机对原始16Byte帧保持原样转发，不做字节交换或整帧反转。发送桥将64bit `fdma_rdata`直接写入FIFO，再将FIFO输出直接连接Aurora `tx_d`，保持原始位位置。

### 1G周期发送

每个周期帧为4拍×32bit（16Byte），每拍4个字节有效，第一拍SOF、第四拍EOF：

| 拍序号 | `tx_data[31:0]` | 内容 |
|---|---|---|
| 第一拍 | `decoded_vin[31:0]` | 完整32bit Vin |
| 第二拍 | `{decoded_duty[15:0], 16'h0000}` | duty在[31:16] |
| 第三拍 | `32'h00000000` | 预留 |
| 第四拍 | `32'h0000EB90` | 低16bit同步字 `16'hEB90` |

### `0x2C DDR_STATUS`扩展

| 位 | 名称 | 含义 |
|---:|---|---|
| 0～4 | 原有DDR状态/错误 | 保持V2.01含义 |
| 5 | `AURORA10G_CHANNEL_UP` | 10G Aurora通道已建立 |
| 6 | `AURORA10G_LINK_DOWN` | 10G通道曾建链后断链的sticky记录 |
| 7 | `AURORA1G_CHANNEL_UP` | 1G Aurora通道已建立 |
| 8 | `AURORA1G_CONFIGURED` | 1G首次合法配置已完成 |
| 31:9 | 保留 | 读零 |

Bit6通过读取 `INT_STATE`（`0x10`）清除；如果通道在曾建链后仍保持down，会重新置位。两个 `channel_up` 状态均经两级同步后供寄存器读取。

## 工程边界与验证状态

- 上行仍保存10G每拍低32bit，紧凑写入100ms×8块DDR；CPU按实际字节数读取并确认。
- 已有PCIe、DDR、10G收发及上行队列逻辑保持原有业务行为，本次未改动10G原始帧数据通路。
- 本次只提交源码、BD/IP版本参数和文档变更；**尚未执行Vivado综合、实现、生成bit/bin或上板验证**。旧V2.01验证记录不能替代V2.02回归验证。
- TOP中的verified 1G封装来源和工程内快照保持不变。

重新生成BD使用 `scripts/refresh_batch_bd.tcl`；补齐引用使用 `scripts/repair_project_references.tcl`。不要运行历史64KiB映射脚本覆盖当前4MiB映射。
