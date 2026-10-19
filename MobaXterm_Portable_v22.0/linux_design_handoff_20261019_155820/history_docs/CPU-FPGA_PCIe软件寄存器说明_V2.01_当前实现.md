# CPU-FPGA PCIe软件寄存器说明 V2.01（当前实现）

## 1. 文档用途

本文只描述当前生产工程已经实现的软件接口，供主机驱动和测试程序访问当前 bitstream。寄存器定义以 `INFO_EXCH.v`、`PCIe.v`、`pcie_fdma_aurora_brg_adapter.v`、`rtds_rx_block_writer.v` 和当前 Block Design 参数为准。

本文不定义未来扩展寄存器。软件不得访问 `0x3C` 及以上偏移，也不得假设当前硬件具有事务结果码、IRQ mask或带序号的ACK接口。

## 2. 接口基本约定

- 寄存器接口为32bit AXI-Lite，小端格式。
- 表内偏移均相对于 INFO_EXCH 所在用户AXI-Lite BAR地址空间。
- 软件以32bit MMIO读写寄存器；可写寄存器支持AXI `WSTRB`字节使能。
- 未实现的读地址返回0。
- 当前BD参数为：`VERSION=0x00002001`、`PROG_TIME=0x20260914`、`CH_BUF_LEN=0x00040000`。

## 3. 当前寄存器表

| 偏移 | 名称 | 属性 | 复位值/固定值 | 当前RTL语义 |
|---:|---|---|---:|---|
| `0x00` | `VERSION` | RO | `0x00002001` | 当前业务接口版本V2.01 |
| `0x04` | `PROG_TIME` | RO | `0x20260914` | 当前BD配置的源码版本日期 |
| `0x08` | `BUF_LEN_MAX` | RO | `0x00040000` | 上行单块容量，256KiB |
| `0x0C` | `FPGA_TEMP` | RO | 外部输入 | 返回当前温度接口原始值；本模块不换算单位 |
| `0x10` | `INT_STATE` | RC（读后清除） | 外部输入 | 返回当前中断状态；本次读地址握手同时产生单周期清除脉冲 |
| `0x14` | `CPU_REC_STATE` | W1P（写1脉冲）/RO | `0x00000000` | 写bit0=1产生一个时钟周期的上行读取完成确认；写0无效；读回通常为0 |
| `0x18` | `FPGA_CPU_START_ADDR` | RO | `0x00000000` | 最老待取上行块的DDR字节地址；队列为空时为0 |
| `0x1C` | `FPGA_CPU_LEN` | RO | `0x00000000` | 最老待取上行块的有效字节数；队列为空时为0，非零值为4Byte整数倍 |
| `0x20` | `CPU_WR_DONE` | 写1启动/RO忙状态 | `0x00000000` | 空闲时写bit0=1启动一次下行任务；执行期间读回1；任务结束、参数不合法或链路中止后由硬件清0 |
| `0x24` | `CPU_FPGA_START_ADDR` | RW | `0x00008000` | 下行DDR起始地址；`0x20.bit0=1`期间写入被忽略 |
| `0x28` | `CPU_FPGA_LEN` | RW | `0x00008000` | 下行总字节数；`0x20.bit0=1`期间写入被忽略 |
| `0x2C` | `DDR_STATUS` | RO | 当前值/保持至清除 | DDR当前工作条件以及已经发生的接收溢出、响应错误和超时事件，位定义见第4节 |
| `0x30` | `UP_READY_BLOCK_CNT` | RO | `0x00000000` | 已完成且尚未由CPU确认的上行数据块数，范围0～8 |
| `0x34` | `UP_BLOCK_SEQ` | RO | `0x00000000` | 当前最早一块待读数据的批次编号；每完成一个非空块递增，32bit自然回绕；队列为空时为0 |
| `0x38` | `UP_DROP_WORD_CNT` | RO | `0x00000000` | 累计丢失的32bit有效数据字数，达到 `0xFFFFFFFF` 后饱和 |

属性说明：`RO`为只读，`RW`为读写，`RC`为读取后触发清除，`W1P`为写1产生一个时钟周期的内部脉冲。`0x20`同时包含写入启动功能和只读忙状态，其行为已在表中直接说明。

## 4. DDR_STATUS位定义

`DDR_STATUS`由当前 `PCIe.v` 直接组合生成。

| 位 | 名称 | 类型 | 含义 |
|---:|---|---|---|
| 0 | `DDR_READY` | 当前状态 | 1表示DDR后端允许业务访问 |
| 1 | `INIT_CALIB_COMPLETE` | 当前状态 | 1表示MIG初始化和校准完成 |
| 2 | `DDR_AXI_RESPONSE_ERROR` | 事件标志（保持至清除） | DDR AXI读写响应曾出现错误 |
| 3 | `RX_OVERFLOW` | 事件标志（保持至清除） | 上行接收或缓存曾发生溢出/丢字事件 |
| 4 | `TIMEOUT` | 事件标志（保持至清除） | DDR AXI或FDMA事务曾发生超时 |
| 31:5 | `RESERVED` | — | 当前固定为0 |

读取 `0x10 INT_STATE` 会产生清除脉冲，同时清除中断通知及上述事件标志。`DDR_READY`和`INIT_CALIB_COMPLETE`反映读取时的当前条件，不受该清除脉冲影响。因此处理中断时应先读取并保存 `DDR_STATUS`，再读取 `INT_STATE`。

## 5. DDR数据窗口和有效参数

### 5.1 CPU到FPGA/Aurora下行窗口

- 有效DDR地址范围：`0x00008000～0x0000FFFF`，共32KiB。
- 起始地址必须16Byte对齐。
- 长度必须非0、为16Byte整数倍且不大于32KiB。
- `起始地址 + 长度`不得超过 `0x00010000`，也不得发生32bit地址溢出。
- 每16Byte作为一帧送往10G Aurora。
- 非法参数、提交时Aurora链路未就绪或任务无法启动时，硬件不发起有效下行搬运，并清除 `CPU_WR_DONE`。当前接口没有单独的成功/失败结果码。

### 5.2 FPGA/Aurora到CPU上行窗口

- 有效DDR地址范围：`0x00100000～0x002FFFFF`。
- 共8个块，每块 `0x00040000` Byte（256KiB）。
- 第k块基址为 `0x00100000 + k × 0x00040000`，其中k为0～7。
- 每个有效64bit Aurora接收拍只保存低32bit；DDR内按接收顺序形成连续的小端32bit字数组。
- `FPGA_CPU_LEN`为实际有效字节数，粒度为4Byte。
- 当前最早待取块的地址、长度和批次编号在软件确认前保持稳定；读 `INT_STATE`只清除中断通知，不改变待取数据块。

## 6. 软件操作流程

### 6.1 初始化

1. 映射用户AXI-Lite BAR，以32bit小端方式访问寄存器。
2. 读取 `VERSION`，确认值为 `0x00002001`。
3. 读取 `PROG_TIME`和 `BUF_LEN_MAX`，确认分别为 `0x20260914`和 `0x00040000`。
4. 轮询 `DDR_STATUS`，等待bit0和bit1均为1。
5. 若 `DDR_STATUS[4:2]`非0，先保存状态，再读取 `INT_STATE`完成清除。

### 6.2 CPU到FPGA/Aurora下行

1. 轮询 `CPU_WR_DONE.bit0`，等待其为0。
2. 使用H2C DMA把待发送数据写入下行DDR窗口。
3. 等待H2C DMA完成，并使用驱动提供的顺序保证，确保DDR数据写入完成后才操作下行提交寄存器。
4. 写 `CPU_FPGA_START_ADDR`和 `CPU_FPGA_LEN`。
5. 写 `CPU_WR_DONE.bit0=1`提交任务；无需先写0。
6. 轮询 `CPU_WR_DONE.bit0`，等待硬件清0。

`CPU_WR_DONE`清0只表示硬件已经结束本次请求，可能是正常完成、参数不合法或链路中止；当前寄存器不能区分这几种结果。

### 6.3 FPGA/Aurora到CPU上行

1. 收到中断后，先读取并保存 `DDR_STATUS`，再读取 `INT_STATE`清除通知。
2. 读取 `UP_READY_BLOCK_CNT`；值为0时没有可取块。
3. 依次读取 `FPGA_CPU_START_ADDR`、`FPGA_CPU_LEN`和 `UP_BLOCK_SEQ`，取得同一个最早待取块的地址、长度和批次编号。
4. 使用C2H DMA读取该地址和长度的数据，并等待DMA完成。
5. 写 `CPU_REC_STATE.bit0=1`，表示最早待取块已经读取完成，允许FPGA后续复用该块。
6. 若 `UP_READY_BLOCK_CNT`仍非0，继续处理下一块；硬件也会重新产生通知。

## 7. 软件必须遵守的限制

- 同一时刻只允许一条软件流程处理上行数据。读取最早待取块的信息、执行C2H和写完成确认必须按顺序完成。
- 完成C2H DMA前不得写 `CPU_REC_STATE`，否则DDR块可能被后续数据复用。
- 下行忙期间不得依赖对 `0x24/0x28` 的写入；RTL会直接忽略这些写操作。
- 下行必须先完成H2C数据写入，再向 `CPU_WR_DONE.bit0`写1启动任务。
- `UP_DROP_WORD_CNT`统计单位是32bit字，不是Aurora帧；计数饱和后保持 `0xFFFFFFFF`。
- 软件发现丢字计数增加时，只能确定发生过数据丢失，不能从DDR连续数组中定位具体缺口。
- DMA完成与MMIO控制寄存器写入之间必须使用操作系统或驱动提供的内存顺序保证。

## 8. 当前RTL依据

| 内容 | 当前来源 |
|---|---|
| 寄存器偏移、读写和复位行为 | `RTDS_test_DDR4_64bit.srcs/sources_1/new/INFO_EXCH.v` |
| `DDR_STATUS`位拼接及BD连接 | `RTDS_test_DDR4_64bit.srcs/sources_1/new/PCIe.v` |
| 下行窗口、16Byte校验及任务结束条件 | `RTDS_test_DDR4_64bit.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v` |
| 上行块地址、队列、序号和丢字计数 | `rtl/rtds_rx_block_writer.v` |
| 固定版本参数 | `RTDS_test_DDR4_64bit.srcs/sources_1/bd/design_1/design_1.bd` |
