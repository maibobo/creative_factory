# CPU-FPGA PCIe 软件寄存器方案（未来可增强版）

规划版本：V3.00 Draft  
日期：2026-09-21  
适用工程：`RTDS_test_DDR4_64bit_batch_dev`  
状态：软件/RTL 联调接口建议，尚未在当前 RTL 中实现

## 1. 设计目标

本方案以《CPU-FPGA PCIe交互方案V1.0》的寄存器交互框架为基础，结合当前 V2.01 工程的实际数据通路重新定义软件接口。

V1.0 假设每 100us 交换 1KiB 数据，使用单缓冲和简单状态电平；当前工程已经变为：

- CPU 下行数据先通过 XDMA H2C 写入 FPGA DDR，再提交给 Aurora 10G；下行帧长为 16Byte，单批不超过 32KiB。
- Aurora 10G 上行每个有效 64bit 拍只保存低 32bit，按连续小端 32bit 字流写入 DDR。
- 上行采用 8 个 256KiB 块，约每 100ms 封存一个非空块；CPU 完成 C2H 后显式确认释放。
- Aurora 1G 的 6Byte 参数来自首个合法配置帧，仅用于独立周期发送。

新版接口的目标是：

1. 保留 V2.01 的 `0x00～0x38` 偏移，现有软件可继续运行。
2. 区分“提交、忙、完成、成功和失败”，不再把门铃清零解释为成功。
3. 中断采用粘滞状态、掩码和 W1C 清除，读寄存器不产生破坏性副作用。
4. 上行确认携带块序号，避免延迟或重复 ACK 释放错误块。
5. 软件启动时可读取能力、地址窗口、长度粒度和块数量，不依赖硬编码。
6. 定义 MMIO 与 DMA 的顺序要求、快照规则和并发限制。

## 2. 总体约定

| 项目 | 约定 |
|---|---|
| BAR | XDMA AXI-Lite 用户 BAR；BAR 号和主机物理地址由 PCIe 枚举决定 |
| 偏移 | 本文均为相对于用户 BAR 基址的字节偏移 |
| 数据宽度 | 32bit |
| 字节序 | 小端 |
| 对齐 | 所有寄存器按 4Byte 对齐；禁止非对齐访问 |
| 访问粒度 | 软件默认使用完整 32bit 访问；命令寄存器至少要求低字节 WSTRB 有效 |
| 保留位 | 软件写 0；读取时忽略，禁止据此推断能力 |
| RO | 只读，软件写入无效 |
| RW | 可读写 |
| WO/W1P | 写 1 产生一次命令脉冲；读回 0 |
| W1C | 写 1 清除对应粘滞状态位；写 0 不影响 |
| RC-Legacy | 读取后清除，仅为旧软件兼容，新软件不使用 |
| 复位值 | 除固定标识、能力和地址窗口外均为 0 |

所有地址和长度均以 Byte 为单位。当前 FPGA DDR 对 CPU 暴露的有效低地址空间为 4MiB。

## 3. DDR 地址规划

| 区域 | 起始地址 | 结束地址 | 容量 | 用途 |
|---|---:|---:|---:|---|
| 保留区 | `0x00000000` | `0x00007FFF` | 32KiB | 保留，不作为 V3.00 业务缓冲 |
| 下行窗口 | `0x00008000` | `0x0000FFFF` | 32KiB | CPU H2C 写入，FPGA 读取并发送到 10G |
| 保留区 | `0x00010000` | `0x000FFFFF` | 960KiB | 后续扩展 |
| 上行块 0～7 | `0x00100000` | `0x002FFFFF` | 8 × 256KiB | 10G 接收数据，CPU C2H 读取 |
| 保留区 | `0x00300000` | `0x003FFFFF` | 1MiB | 后续扩展 |

上行块 `k` 的基址为：

```text
UP_BLOCK_ADDR(k) = 0x00100000 + k * 0x00040000,  k = 0..7
```

## 4. 寄存器总表

### 4.1 V2.01 兼容区

这一段保持现有偏移。V3.00 软件可以读取这些寄存器，但新事务优先使用第 4.2 节扩展接口。

| 偏移 | 名称 | 属性 | 复位/固定值 | V3.00 语义 |
|---:|---|---|---:|---|
| `0x00` | `VERSION` | RO | `0x00003000` | 协议版本；低 16bit 按 `0xMmrr` 编码，`M` 为主版本、`m` 为次版本、`rr` 为修订号；高 16bit 保留为 0 |
| `0x04` | `BUILD_DATE` | RO | 构建日期 | BCD/十六进制显示格式 `0xYYYYMMDD` |
| `0x08` | `UP_BLOCK_BYTES` | RO | `0x00040000` | 单个上行块容量 256KiB |
| `0x0C` | `FPGA_TEMP` | RO | 0 | bit15:0 温度原始值；bit16 busy；其余保留 |
| `0x10` | `LEGACY_INT_STATE` | RC-Legacy | 0 | bit0 队头可读通知；旧软件读取清除，不释放块 |
| `0x14` | `LEGACY_UP_ACK` | WO/W1P | 0 | 写 bit0=1 释放当前队头；仅兼容旧软件，无序号保护 |
| `0x18` | `UP_HEAD_ADDR` | RO | 0 | 最老待取块地址；队列空时为 0 |
| `0x1C` | `UP_HEAD_LEN` | RO | 0 | 队头实际有效字节数；4Byte 整数倍；队列空时为 0 |
| `0x20` | `LEGACY_DOWN_BUSY` | RW-Legacy | 0 | 旧接口写 bit0=1 提交；读 bit0=1 表示忙，完成/拒绝后清 0 |
| `0x24` | `DOWN_ADDR` | RW | `0x00008000` | 下行 DDR 起始地址；提交时锁存 |
| `0x28` | `DOWN_LEN` | RW | 0 | 下行字节长度；提交时锁存 |
| `0x2C` | `DEVICE_STATUS` | RO | 0 | 设备实时状态，见第 5.1 节 |
| `0x30` | `UP_READY_COUNT` | RO | 0 | 待取块数，范围 0～8 |
| `0x34` | `UP_HEAD_SEQ` | RO | 0 | 当前队头发布序号；队头稳定期间保持不变 |
| `0x38` | `UP_DROP_WORD_COUNT` | RO | 0 | 累计丢失的 32bit 有效字数，饱和到 `0xFFFFFFFF` |

### 4.2 V3.00 扩展区

| 偏移 | 名称 | 属性 | 复位/固定值 | 说明 |
|---:|---|---|---:|---|
| `0x3C` | `REG_MAGIC` | RO | `0x52544453` | ASCII `RTDS`；用于识别扩展寄存器存在 |
| `0x40` | `CAPABILITY0` | RO | 见第 5.2 节 | 接口能力与固定参数 |
| `0x44` | `IRQ_STATUS` | RO/W1C | 0 | 粘滞中断原因；写 1 清除对应位 |
| `0x48` | `IRQ_MASK` | RW | 0 | 中断使能；`IRQ_STATUS & IRQ_MASK != 0` 时请求中断 |
| `0x4C` | `ERROR_STATUS` | RO/W1C | 0 | 粘滞错误分类，见第 5.4 节 |
| `0x50` | `DOWN_COMMAND` | WO/W1P | 0 | bit0 `SUBMIT`；其余保留 |
| `0x54` | `DOWN_STATUS` | RO | 0 | 下行忙、完成与结果码，见第 5.5 节 |
| `0x58` | `DOWN_SW_TAG` | RW | 0 | 软件事务标签；提交时与地址、长度一起锁存 |
| `0x5C` | `DOWN_DONE_TAG` | RO | 0 | 最近一次完成事务的软件标签 |
| `0x60` | `DOWN_BYTES_DONE` | RO | 0 | 最近一次事务已从 DDR 消费并交给 10G 的字节数 |
| `0x64` | `DOWN_ERROR_INFO` | RO | 0 | 错误现场；格式见第 5.6 节 |
| `0x68` | `UP_ACK_SEQ` | WO | 0 | 写当前 `UP_HEAD_SEQ` 以确认并释放一个队头 |
| `0x6C` | `UP_HEAD_FLAGS` | RO | 0 | 队头快照状态，见第 5.7 节 |
| `0x70` | `UP_PUBLISHED_COUNT` | RO | 0 | 累计发布的非空块数，32bit 自然回绕 |
| `0x74` | `UP_ACKED_COUNT` | RO | 0 | 累计成功确认释放的块数，32bit 自然回绕 |
| `0x78` | `UP_ACK_ERROR_COUNT` | RO | 0 | 空队列 ACK 或序号不匹配次数，饱和计数 |
| `0x7C` | `CONTROL` | RW/W1P | 0 | 诊断控制与计数清除，见第 5.8 节 |
| `0x80` | `DOWN_WINDOW_BASE` | RO | `0x00008000` | 下行窗口基址 |
| `0x84` | `DOWN_WINDOW_BYTES` | RO | `0x00008000` | 下行窗口容量 32KiB |
| `0x88` | `UP_WINDOW_BASE` | RO | `0x00100000` | 上行窗口基址 |
| `0x8C` | `UP_WINDOW_BYTES` | RO | `0x00200000` | 上行总容量 2MiB |
| `0x90` | `TRANSFER_GRANULE` | RO | `0x00040010` | bit31:16 上行长度粒度 4Byte；bit15:0 下行对齐/长度粒度 16Byte |

`0x94～0xFF` 保留。软件不得根据保留区当前读值推断硬件能力。

## 5. 位定义

### 5.1 `DEVICE_STATUS`（0x2C，RO）

| 位 | 名称 | 含义 |
|---:|---|---|
| 0 | `DDR_READY` | DDR 后端可以接受事务 |
| 1 | `DDR_CAL_DONE` | MIG 校准完成；行为仿真时表示模型就绪 |
| 2 | `DDR_RESP_ERR` | DDR/AXI 响应错误曾发生，粘滞 |
| 3 | `UP_OVERFLOW` | 上行 FIFO 或块缓存溢出曾发生，粘滞 |
| 4 | `DMA_TIMEOUT` | DDR/FDMA 等待超时曾发生，粘滞 |
| 5 | `PCIE_LINK_UP` | PCIe 链路已建立并同步到寄存器域 |
| 6 | `AURORA10G_CHANNEL_UP` | 10G channel up 已同步到寄存器域 |
| 7 | `AURORA10G_LANE_UP` | 10G lane up 已同步到寄存器域 |
| 8 | `AURORA1G_CHANNEL_UP` | 1G channel up 已同步到寄存器域 |
| 9 | `UP_QUEUE_FULL` | 8 个上行块均等待软件确认 |
| 10 | `DOWN_BUSY` | 下行事务正在执行 |
| 11 | `UP_HEAD_VALID` | `0x18/0x1C/0x34/0x6C` 为有效队头快照 |
| 31:12 | — | 保留 |

位 0～4 与当前 V2.01 已实现位保持一致；新增状态位需要 RTL 实现后才有效。

### 5.2 `CAPABILITY0`（0x40，RO）

| 位 | 名称 | 固定值/含义 |
|---:|---|---|
| 3:0 | `UP_BLOCK_COUNT_MINUS1` | 7，表示 8 块 |
| 7:4 | `DOWN_ALIGN_LOG2` | 4，表示 16Byte |
| 11:8 | `UP_GRANULE_LOG2` | 2，表示 4Byte |
| 12 | `CAP_IRQ_W1C` | 1，支持非破坏性 W1C 中断 |
| 13 | `CAP_DOWN_RESULT` | 1，支持下行结果码和标签 |
| 14 | `CAP_UP_SEQ_ACK` | 1，支持带序号 ACK |
| 15 | `CAP_ADDR_DISCOVERY` | 1，支持地址窗口发现寄存器 |
| 31:16 | — | 保留 |

建议固定值为 `0x0000F247`。

### 5.3 `IRQ_STATUS` / `IRQ_MASK`（0x44 / 0x48）

| 位 | 中断原因 | 置位条件 |
|---:|---|---|
| 0 | `UP_HEAD_READY` | 队列由空变非空，或确认后仍有下一队头 |
| 1 | `DOWN_DONE` | 下行事务成功完成 |
| 2 | `DOWN_ERROR` | 下行事务被拒绝或执行失败 |
| 3 | `UP_DROP` | 上行丢失计数增加 |
| 4 | `DDR_ERROR` | DDR 响应错误或超时首次置位 |
| 5 | `LINK_CHANGE` | PCIe/10G/1G 链路状态变化 |
| 31:6 | — | 保留 |

`IRQ_STATUS` 是粘滞状态，读取不清除。软件处理完相应原因后写 1 清除。硬件在 W1C 与同拍新事件冲突时必须保留新事件，即“置位优先于清除”。

建议软件初始只使能 bit0、bit1、bit2、bit4。高频 `UP_DROP` 和 `LINK_CHANGE` 可由诊断程序按需使能。

### 5.4 `ERROR_STATUS`（0x4C，RO/W1C）

| 位 | 名称 | 含义 |
|---:|---|---|
| 0 | `DOWN_ZERO_LEN` | 下行长度为 0 |
| 1 | `DOWN_ALIGN_ERR` | 下行地址或长度不是 16Byte 对齐 |
| 2 | `DOWN_RANGE_ERR` | 下行范围越过 `0x8000～0xFFFF` 或 32bit 地址回绕 |
| 3 | `DOWN_BUSY_REJECT` | 忙期间收到新的提交 |
| 4 | `DOWN_LINK_ABORT` | 事务期间 PCIe/DDR/10G 链路失效 |
| 5 | `DOWN_DMA_ERROR` | DDR 读或 FDMA 事务错误 |
| 6 | `DOWN_TIMEOUT` | 下行等待超时 |
| 7 | `UP_FIFO_OVERFLOW` | 上行接收 FIFO 无法保存新字 |
| 8 | `UP_QUEUE_FULL` | 无可写块导致数据丢失 |
| 9 | `UP_DDR_ERROR` | 上行 DDR 写响应错误 |
| 10 | `UP_ACK_MISMATCH` | `UP_ACK_SEQ` 与当前队头序号不一致 |
| 11 | `UP_ACK_EMPTY` | 空队列时收到 ACK |
| 31:12 | — | 保留 |

错误状态用于诊断，不替代 `DOWN_STATUS.RESULT_CODE` 的单事务结果。

### 5.5 `DOWN_STATUS`（0x54，RO）

| 位 | 名称 | 含义 |
|---:|---|---|
| 0 | `BUSY` | 有下行事务正在执行 |
| 1 | `DONE` | 至少有一次事务结果尚未被软件确认；读取不清除 |
| 2 | `SUCCESS` | 最近一次结果为成功 |
| 3 | `ERROR` | 最近一次结果为失败 |
| 7:4 | `RESULT_CODE` | 结果码，见下表 |
| 31:8 | — | 保留 |

| 结果码 | 名称 | 说明 |
|---:|---|---|
| 0 | `OK` | 全部字节已经被 10G 发送接口握手接受 |
| 1 | `ZERO_LEN` | 长度为 0，未访问 DDR |
| 2 | `ALIGN_ERR` | 地址或长度不满足 16Byte 粒度 |
| 3 | `RANGE_ERR` | 地址范围非法或加法回绕 |
| 4 | `BUSY_REJECT` | 前一事务未结束，新提交被拒绝 |
| 5 | `LINK_ABORT` | 执行中链路失效 |
| 6 | `DMA_ERROR` | DDR/FDMA 读错误 |
| 7 | `TIMEOUT` | 等待超过硬件阈值 |
| 8～15 | — | 保留 |

`DONE` 由软件写 `IRQ_STATUS.DOWN_DONE` 或 `DOWN_ERROR` 对应位清除；硬件必须避免在清除旧结果的同拍丢失新结果。V3.00 仍只允许一个在途下行事务，不定义命令队列。

### 5.6 `DOWN_ERROR_INFO`（0x64，RO）

| 位 | 含义 |
|---:|---|
| 15:0 | 失败发生时的 16Byte 帧索引，第一帧为 0 |
| 23:16 | 最近一次 AXI/FDMA 响应或内部子状态码 |
| 31:24 | 保留 |

无错误时为 0。该寄存器与 `DOWN_DONE_TAG`、`DOWN_BYTES_DONE` 一起在完成时更新，并保持到下一次事务完成。

### 5.7 `UP_HEAD_FLAGS`（0x6C，RO）

| 位 | 名称 | 含义 |
|---:|---|---|
| 0 | `VALID` | 当前存在稳定队头 |
| 1 | `PARTIAL_WORD` | 有效长度为 4Byte 但不是 8Byte 整数倍，末拍只使用低 4Byte |
| 2 | `DROP_OCCURRED` | 该块封存期间 `UP_DROP_WORD_COUNT` 曾增加 |
| 3 | `DDR_ERROR_SEEN` | 该块写入期间发生 DDR 写响应错误 |
| 6:4 | `BLOCK_INDEX` | 物理块号 0～7 |
| 31:7 | — | 保留 |

`UP_HEAD_ADDR`、`UP_HEAD_LEN`、`UP_HEAD_SEQ` 和 `UP_HEAD_FLAGS` 构成一个快照。只要 `VALID=1` 且软件尚未成功 ACK，这四个寄存器以及对应 DDR 内容必须保持稳定。

### 5.8 `CONTROL`（0x7C，RW/W1P）

| 位 | 名称 | 属性 | 含义 |
|---:|---|---|---|
| 0 | `CLEAR_DIAG` | W1P | 清除可清诊断计数和粘滞错误；不释放上行块，不中止下行事务 |
| 1 | `LEGACY_ENABLE` | RW | 1：允许 0x10/0x14/0x20 旧语义；0：旧命令写入不产生动作 |
| 31:2 | — | — | 保留 |

为保证旧驱动可启动，硬件复位后 `LEGACY_ENABLE` 建议为 1。新版驱动确认 `REG_MAGIC` 和版本后可清 0，避免新旧两个控制入口被不同线程同时使用。

## 6. 软件操作流程

### 6.1 初始化

1. 映射用户 BAR，使用 32bit 小端 MMIO 访问。
2. 读取 `VERSION`。取 `(VERSION >> 12) & 0xF` 作为主版本；若小于 3，退回 V2.01 兼容流程。
3. 读取 `REG_MAGIC`，必须等于 `0x52544453`；否则不得访问扩展区。
4. 读取 `CAPABILITY0`、地址窗口和传输粒度，核对驱动支持能力。
5. 写 `IRQ_STATUS=0xFFFFFFFF`、`ERROR_STATUS=0xFFFFFFFF` 清除上电遗留状态。
6. 设置 `IRQ_MASK`，最后读取 `DEVICE_STATUS` 确认 DDR 和所需链路就绪。
7. 新驱动独占设备后可将 `CONTROL.LEGACY_ENABLE` 清 0。

### 6.2 下行：CPU → DDR → Aurora 10G

1. 等待 `DOWN_STATUS.BUSY=0`。
2. 校验 `addr` 和 `len`：均为 16Byte 对齐，`len>0`，且完整落在下行窗口。
3. 通过 XDMA H2C 把数据写入 FPGA DDR。
4. 等待 H2C DMA 完成；执行驱动/平台要求的 DMA 与 MMIO 写屏障。
5. 写 `DOWN_ADDR`、`DOWN_LEN`、`DOWN_SW_TAG`。
6. 最后写 `DOWN_COMMAND.SUBMIT=1`。门铃必须是最后一个 MMIO 写。
7. 等待中断或轮询 `DOWN_STATUS.DONE=1`。
8. 读取 `DOWN_STATUS`、`DOWN_DONE_TAG`、`DOWN_BYTES_DONE`；失败时再读 `DOWN_ERROR_INFO` 和 `ERROR_STATUS`。
9. 检查完成标签与提交标签一致，再对 `IRQ_STATUS` 的 `DOWN_DONE/DOWN_ERROR` 写 1 清除。

`DOWN_STATUS.SUCCESS` 只表示 FPGA 已把全部数据交给 10G 发送接口，不表示远端子机已经处理。若需要端到端执行确认，应由业务协议定义远端回执。

### 6.3 上行：Aurora 10G → DDR → CPU

1. 收到 `UP_HEAD_READY` 中断，或轮询 `UP_READY_COUNT>0`。
2. 读取 `UP_HEAD_FLAGS`，确认 `VALID=1`。
3. 依次读取 `UP_HEAD_SEQ`、`UP_HEAD_ADDR`、`UP_HEAD_LEN`、`UP_HEAD_FLAGS`，再次确认 `VALID=1` 且序号未变化。按当前硬件规则队头本应稳定，双读用于发现驱动或设备异常。
4. 校验地址属于上行窗口，长度不超过 256KiB 且为 4Byte 整数倍。
5. 通过 XDMA C2H 读取 `UP_HEAD_LEN` 字节。
6. 等待 C2H DMA 完成并完成 CPU 可见性同步。
7. 写 `UP_ACK_SEQ=本次读取的 UP_HEAD_SEQ`。
8. 若队列仍非空，硬件置位 `UP_HEAD_READY` 并展示下一队头；软件继续处理。

序号不匹配或空队列 ACK 不释放任何块，只增加 `UP_ACK_ERROR_COUNT`、置位对应错误。一个设备实例只能有一个上行队列消费者。

### 6.4 轮询模式

软件可以把 `IRQ_MASK` 清 0 后轮询，但仍应使用 `IRQ_STATUS` 的 W1C 语义维护事件状态。轮询间隔不得用来推断 100ms 块边界；空窗口不会发布，上行块间隔可能大于 100ms。

## 7. 顺序、一致性与并发

- H2C 必须先完成，之后才能提交下行门铃；禁止用普通 CPU 内存屏障代替 DMA 完成通知。
- C2H 必须完成后才能 ACK 上行块；ACK 后该 DDR 块可立即被硬件复用。
- 软件写 `DOWN_ADDR/LEN/TAG` 后需执行 MMIO 写屏障，再写 `SUBMIT`。
- 软件不得缓存 RO 状态寄存器；每次事务重新读取。
- 同一设备只允许一个下行提交者和一个上行消费者。多线程访问必须由驱动串行化。
- V3.00 新接口与 Legacy 命令不能由两个软件组件同时使用。
- 32bit 计数器允许自然回绕；比较累计值使用无符号模 2^32 差值。
- `UP_DROP_WORD_COUNT` 饱和，不回绕。计数变化只说明出现丢失，不提供数据流中的缺口位置。

## 8. 兼容策略

### 8.1 旧软件访问 V3.00 硬件

硬件复位时 `LEGACY_ENABLE=1`，保留以下行为：

- 读取 0x10 清旧通知，但不释放块。
- 写 0x14 bit0=1 释放一个当前队头。
- 写 0x20 bit0=1 使用 0x24/0x28 提交，读 0x20 得到忙状态。

旧软件无法获得精确错误结果，仍可能把拒绝后的清零误判为成功。V3.00 驱动不应使用该流程。

### 8.2 新软件访问 V2.01 硬件

若 `(VERSION >> 12) & 0xF` 为 2，或 `REG_MAGIC` 不匹配，驱动只访问 `0x00～0x38`，遵循 V2.01 流程：

- 下行以 0x20 清零作为“请求已被消费”，不得宣称远端成功。
- 上行使用 0x14 写 1，无序号保护；驱动必须保证单消费者和严格顺序。
- 中断仍使用 0x10 读清。

## 9. RTL 实现要求

本文是软件接口定义；实现时至少满足：

1. 所有跨时钟状态先同步或使用握手/FIFO，再进入寄存器域；不得直接把链路状态作为另一时钟域状态机异步复位或组合使能。
2. 下行提交时原子锁存地址、长度和标签；忙期间寄存器写入不得改变在途事务。
3. 结果寄存器在事务完成时原子更新；先写内容，随后置位完成事件。
4. W1C 与新事件同拍时新事件优先，不能丢中断。
5. 带序号 ACK 只有在队列非空且序号匹配时才释放一个块。
6. 队头发布后，地址、长度、序号、flags 和 DDR 内容保持到有效 ACK。
7. 非法下行请求不访问 DDR；结果码必须对应唯一拒绝原因，优先级建议为 busy、zero length、alignment、range、link。
8. 所有新增状态和计数均定义明确复位值，保留位读 0。

## 10. 建议的软件数据结构

```c
struct rtds_caps {
    uint32_t version;
    uint32_t capability0;
    uint32_t down_base;
    uint32_t down_bytes;
    uint32_t up_base;
    uint32_t up_bytes;
    uint32_t transfer_granule;
};

struct rtds_up_head {
    uint32_t seq;
    uint32_t addr;
    uint32_t len;
    uint32_t flags;
};

struct rtds_down_result {
    uint32_t status;
    uint32_t tag;
    uint32_t bytes_done;
    uint32_t error_info;
};
```

驱动 API 建议提供 `query_caps`、`submit_down`、`wait_down`、`peek_up_head`、`read_up_block`、`ack_up_seq` 和 `get_errors`，应用层不直接拼接门铃时序。

## 11. 相对 V1.0 和 V2.01 的主要变化

| 项目 | V1.0 | V2.01 当前实现 | V3.00 建议 |
|---|---|---|---|
| 上行缓存 | 单次地址/长度 | 8×256KiB 队列 | 保持八块，新增序号 ACK 和队头 flags |
| 下行提交 | 状态电平 | 自动清零门铃 | 独立命令、忙、结果码、标签和完成字节数 |
| 中断 | 读清单一状态 | 读清通知 | 粘滞 W1C 状态 + 掩码，保留旧读清接口 |
| 错误报告 | 无 | 若干粘滞状态，无事务结果 | 分类错误、单事务结果和错误现场 |
| 能力发现 | 固定 BUF_LEN_MAX | 多数由软件硬编码 | magic、capability、窗口和粒度寄存器 |
| 软件并发 | 未定义 | 要求单消费者 | 明确单提交者/单消费者及标签匹配 |
| 完成含义 | 容易混淆 | 门铃清零仅表示消费结束 | 明确 FPGA 接口完成，不代表远端执行成功 |

## 12. 迁移建议

建议分两阶段实施：

1. 先增加 `0x3C～0x90` 扩展区，保留现有 `0x00～0x38` 行为并更新软件驱动；使用现有寄存器测试补充 W1C、结果码、标签和序号 ACK 用例。
2. 新驱动稳定后关闭 `LEGACY_ENABLE`，只保留旧偏移的只读兼容信息。是否在后续主版本删除 Legacy 命令，由软硬件联合评审决定。

本方案不改变当前 DDR 地址分区、16Byte 下行帧、上行低 32bit 压缩、8 块容量和 100ms 封存规则。
