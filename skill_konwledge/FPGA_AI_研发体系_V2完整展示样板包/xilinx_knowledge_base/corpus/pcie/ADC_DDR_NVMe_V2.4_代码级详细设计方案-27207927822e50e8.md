# ADC_DDR_NVMe_V2.4_代码级详细设计方案

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe_V2.4_代码级详细设计方案.md`
- SHA-256: `27207927822e50e8821c3992b7cfb9240dba6f4a90a1f5bc10fec2102b2accc8`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe_V2.4_代码级详细设计方案.md

# ADC DDR NoPHAE NVMe V2.4 代码级详细设计方案

> 版本：V2.4
> 日期：2026-08-10
> 事实源：当前正式 Vitis 兼容通路的 11 个 RTL/SV 模块
> 阅读对象：掌握基础 Verilog/SystemVerilog，但不了解本项目术语的设计、验证和软件人员
> 验证边界：本轮只补注释并把 Packer 的 always_comb 改为 always @*；不重建 Vitis 软件，不运行 RTL 回归，不综合，不实现，不生成 bitstream。

## 1. 文档目的与事实边界

本文从现有代码出发，说明一次 ADC 数据时刻如何变成 256 bit 数据字，如何跨越 ADC/系统时钟域，如何获得 DDR Segment 所有权，如何经 AXI4 写入 DDR，最后如何由调度器和 NoPHAE 控制寄存器序列写入 SSD。文中所说的 Descriptor、alloc 和 Manager 都是本项目自定义概念，不是 AXI、NoPHAE 或 NVMe 标准对象。

正式通路的 11 个事实源如下：

| 序号 | 模块 | 文件 | 主要职责 |
|---:|---|---|---|
| 1 | Vitis 兼容顶层 | [nvme_adc_vitis_compat_top.sv](../rtl/nvme_adc_vitis_compat_top.sv) | 连接 FDMA ABI、Capture 控制、Pipeline 和 NoPHAE Backend |
| 2 | FDMA 兼容寄存器 | [fdma_vitis_compat_regs.sv](../rtl/fdma_vitis_compat_regs.sv) | 复现现有 ELF 的 0x90000000 寄存器 ABI |
| 3 | Capture Controller | [adc_capture_limit_controller.sv](../rtl/adc_capture_limit_controller.sv) | START/STOP Toggle CDC 和定长停止 |
| 4 | Pipeline Top | [nvme_adc_pipeline_top.sv](../rtl/nvme_adc_pipeline_top.sv) | 连接 Packer、FIFO、Writer、Manager、Scheduler |
| 5 | Packer | [adc_channel_packer.sv](../rtl/adc_channel_packer.sv) | 通道选择、16 bit 扩展、256 bit 组包和尾字排空 |
| 6 | ADC CDC FIFO | [axis_async_fifo.sv](../rtl/axis_async_fifo.sv) | 329 bit 原子跨时钟域和短时缓存 |
| 7 | Segment Writer | [adc_ddr_segment_writer.sv](../rtl/adc_ddr_segment_writer.sv) | 分段、CRC、补零、Commit 页和 DDR AXI 写 |
| 8 | Beat FIFO | [sync_fifo.sv](../rtl/sync_fifo.sv) | 缓存 Writer 生成的 256 bit DDR 数据拍 |
| 9 | Segment Manager | [segment_buffer_manager.sv](../rtl/segment_buffer_manager.sv) | 管理 DDR 槽位所有权和描述符表 |
| 10 | Scheduler | [nvme_request_scheduler.sv](../rtl/nvme_request_scheduler.sv) | 顺序提交 Payload、Flush、Commit、Flush |
| 11 | NoPHAE Backend | [nophae_dma_backend.sv](../rtl/nophae_dma_backend.sv) | 把项目请求转换为 NoPHAE AXI4-Lite 寄存器序列 |

Stub、未使用 Mailbox 和尚未取得的真实 NoPHAE 内部 RTL 不属于逐信号正文。现有软件事实和安全使用方法继续以 [NoPHAE Vitis 现有软件使用与验证指南](NoPHAE_Vitis现有软件使用与验证指南_V1.0.md) 为准；V2.3 修复背景见 [NoPHAE Vitis 源码实证与现有 RTL 修复方案](NoPHAE_Vitis源码实证与现有RTL修复方案_V2.3.md)。

## 2. 术语表

| 术语 | 本项目中的准确含义 | 容易混淆的对象 |
|---|---|---|
| Capture | 从软件写 START、锁存配置、采集若干数据时刻、形成一个或多个 Segment、写 Commit 页，直到第二次 Flush 完成的一次完整采集任务。它不是某个 SV 类型。 | 不是一个 AXI 事务，也不等于一个 Segment |
| Segment | DDR 中固定大小的 Payload 槽位。默认每槽 1 MiB，共 8 槽。 | 不是 NVMe Namespace 或 SQE |
| 描述符 Descriptor | Writer 与 Manager/Scheduler 之间传递的项目内并行元数据集合，例如 Tag、地址、真实字节数、DMA 字节数和 CRC。 | 不是 AXI Descriptor，也不是 NoPHAE 标准结构 |
| Manager | segment_buffer_manager，只维护 DDR 槽位所有权和描述符表，不搬运数据，不是 AXI Master。 | 不等于 DMA Engine |
| alloc | Writer 向 Manager 申请 FREE Segment 的项目内 ready/valid 握手。 | 不是 AXI 主从协议 |
| ready/valid | 当且仅当同一拍 valid=1 且 ready=1 时传输发生。发送方在 valid=1 且 ready=0 时保持内容。 | 不能只看 valid 或 ready 单边判断传输 |
| beat | AXI 数据总线一次数据传输。当前 256 bit，即 32 Byte。 | 不等于 Burst |
| burst | 一次 AW 对应的一组连续 W beat。当前固定 16 beat，即 512 Byte。 | 不等于 Segment |
| stall | valid=1 且 ready=0 的反压停顿。stall 期间当前地址、数据、长度和边界标志必须保持不变。 | 不是错误本身 |
| sticky | 瞬时事件一旦出现便保持为 1，直到复位；部分 Packer 诊断还会在下一次合法 Capture 时清除。 | 不是单拍脉冲 |
| EOC | end_of_capture，标记 Capture 输入流结束。可附着在短尾字上，也可作为 valid_bytes=0 的独立结束条目。 | 不等于 AXI WLAST |
| Payload | 来自 ADC 的真实有效字节，不包含 4 KiB 对齐补零。 | 不等于 DMA bytes |
| DMA bytes | 写 DDR/SSD 的对齐后字节数。尾 Segment 向上取整到 4 KiB。 | 可能大于 Payload bytes |
| Commit 页 | Capture 完成标志和汇总元数据页，固定 4 KiB。 | 不是普通 Payload Segment |
| Tag | 16 bit 项目应用层标识。普通 Segment Tag 为 {generation, segment_id}；Flush/Commit 使用保留值。 | NoPHAE 高层 DMA 本身没有用户 Tag 字段 |

## 3. 系统全链路

<!-- MODULE_VISUAL: nvme_adc_vitis_compat_top -->

一次正式 Vitis 兼容 Capture 的控制和数据方向如下：

~~~text
MicroBlaze 现有 ELF
  │ AXI4-Lite 写 START/SIZE/LBA @ 0x90000000
  ▼
fdma_vitis_compat_regs
  │ START Toggle + 稳定的目标字节数/模式/Capture ID
  ▼
adc_capture_limit_controller
  │ adc_clk 域 capture_start/capture_stop
  ▼
adc_channel_packer
  │ 256 bit data + valid_bytes + EOC + 模式 + Capture ID
  ▼
axis_async_fifo（329 bit 原子 CDC）
  ▼
adc_ddr_segment_writer ──AXI4 Write──► MIG/DDR
  │ alloc/fill 项目内描述符
  ▼
segment_buffer_manager
  │ READY Payload 描述符
  ▼
nvme_request_scheduler
  │ Payload Write → Flush1 → Commit Write → Flush2
  ▼
nophae_dma_backend ──AXI4-Lite──► NoPHAE s_axi_ctrl
  │                              │ NoPHAE m_axi 读取 DDR
  └──────── Completion ◄─────────┴──────────────► PCIe/NVMe SSD
~~~

### 3.1 控制面与数据面分离

| 路径 | 传递内容 | 实际搬运数据的模块 |
|---|---|---|
| FDMA 控制面 | SIZE、START、STOP、模式、Capture ID、SLBA | 不搬运 ADC Payload |
| Packer/CDC 数据面 | ADC Payload、有效字节数、EOC、原子上下文 | Packer 和 FIFO |
| DDR 写数据面 | 256 bit AXI WDATA、AW 地址、B 响应 | Segment Writer |
| Segment 所有权面 | alloc、fill、ready、completion 描述符 | Manager 只改状态表 |
| SSD 请求面 | opcode、DDR 地址、DMA 字节数、SLBA、Tag | Scheduler 和 Backend |
| NoPHAE 内部数据面 | DDR 与 PCIe/NVMe 间的数据流 | 真实 NoPHAE IP，内部 RTL 尚未取得 |

### 3.2 完成事件不是同一个时间点

| 事件 | 含义 | 软件可见结果 |
|---|---|---|
| local_capture_done_pulse | Packer 已停止接收并让 EOC 离开 ADC 域 | WDATA_DONE 置位 |
| fill_valid 且 fill_ready | 一个 Payload Segment 的 DDR 写和 B 响应已结束 | Manager 进入 READY 或 ERROR_HOLD |
| capture_done | 所有 Payload、Flush1、Commit Write、Flush2 均成功 | NVME_SEND_DONE 置位，任务结束 |

### 3.3 总体顶层架构图

~~~text
┌────────────────────软件控制/所有权通道────────────────────┐
│ MicroBlaze/Vitis ELF                                      │
│      │ AXI4-Lite                                          │
│      ▼                                                    │
│ fdma_vitis_compat_regs ──Capture上下文──┐                  │
│      ▲ 本地/最终完成与诊断              │                  │
│ segment_buffer_manager ◄─alloc/fill─────┼──────────────┐   │
└─────────────────────────────────────────┼──────────────┼───┘
                                          │              │
┌────────────────────ADC采集与DDR缓存通道─┼──────────────┼───┐
│ ADC CH0/CH1                             ▼              │   │
│      │ adc_valid         adc_capture_limit_controller  │   │
│      ▼                                   │ START/STOP  │   │
│ adc_channel_packer                       ▼             │   │
│      │ 329 bit复合条目    axis_async_fifo               │   │
│      └─────────────────────────► adc_ddr_segment_writer ┘   │
│                                      │ AXI4 Write           │
│                                      ▼                      │
│                                 MIG / DDR                   │
└──────────────────────────────────────┼───────────────────────┘
                                       │ NoPHAE DMA源
┌────────────────────NoPHAE/SSD持久化通道────────────────────┐
│ nvme_request_scheduler ─► nophae_dma_backend               │
│      ▲ Completion              │ AXI4-Lite                  │
│      └─────────────────────────NoPHAE IP ─► PCIe/NVMe SSD   │
└─────────────────────────────────────────────────────────────┘
~~~

图 3-1 的详细说明如下：

- 三个框表示职责分区，不表示三个模块或三个时钟域。控制/所有权通道保存任务配置和 DDR 槽位状态，采集/缓存通道实际搬运 ADC Payload，持久化通道把 DDR 内容写入 SSD。
- Capture Controller 是 FDMA 与 Packer 之间的跨域控制桥。它用 toggle 同步单拍事件，并让多位目标字节数、模式和 Capture ID 稳定穿越 sys_clk/adc_clk 边界。
- Manager 与 Writer 之间的 alloc/fill 是项目内所有权握手；Manager 与 Scheduler 之间传递 READY 描述符。Manager 既不是 AXI Master，也不读取 256 bit 数据。
- DDR 位于两条数据路径的交点：Writer通过AXI写入DDR，NoPHAE随后把同一DDR区域作为NVMe WRITE的DMA源。不得把“写DDR完成”当成“写SSD完成”。
- 顶层 `nvme_adc_vitis_compat_top` 负责实例化和连线，真正的数据变换、槽位生命周期和请求顺序分别在 Packer/Writer、Manager 和 Scheduler 中实现。

### 3.4 一次 Capture 的数据流图

~~~text
ADC 12 bit×2
  │ adc_valid，源端不可反压
  ▼
16 bit样点格式化与256 bit打包
  │ tdata[255:0] + valid_bytes[5:0] + EOC + 模式 + Capture ID
  ▼
329 bit异步FIFO（adc_clk → sys_clk）
  │ ready/valid；stall时完整条目保持
  ▼
Writer取得Segment槽位 → CRC32C → 4 KiB补零 → AXI Burst
  │ Payload bytes与DMA bytes分别计数
  ▼
DDR Payload槽位 / 固定4 KiB Commit页
  │ fill描述符或commit上下文
  ▼
Manager READY → Scheduler单请求在途
  │ 最后一个Payload后：Payload WRITE → Flush1 → Commit WRITE → Flush2
  ▼
Backend编程NoPHAE → PCIe/NVMe SSD → Completion
~~~

图 3-2 的详细说明如下：

- 图中的纵向顺序是因果关系，不表示所有硬件串行停等。Packer、异步 FIFO、Writer、Manager 可以形成流水；Scheduler为了适配现有 NoPHAE 寄存器流程，仍保持单个项目请求在途。
- 329 bit 必须原子跨域。若把 `tdata`、`valid_bytes`、`EOC`、模式或 Capture ID 分开同步，不同字段可能在 sys_clk 域对应到不同数据字。
- `valid=1 && ready=0` 是 stall。Packer、FIFO、Writer、Scheduler 和 Backend 的发送端都要在 stall 期间保持数据和伴随字段，直到握手。
- ADC物理源不能因下游反压停止。短时stall由Packer输出级、`pack_full_pending`和异步FIFO吸收；全部空间耗尽后只能丢样，并通过dropped计数和overflow sticky暴露。
- 真实Payload字节参与CRC和元数据；DMA字节按4 KiB对齐，用于DDR/NVMe传输和SLBA推进。二者相等只是一种情况，不是统一概念。
- Commit页只在全部Payload完成并经过Flush1后写入。Flush2成功才证明Commit标志也进入最终持久化边界，随后才能产生`capture_done`。

### 3.5 顶层接口信号列表与正文图表索引

| 接口组 | 顶层信号/前缀 | I/O | 对端 | 设计含义 |
|---|---|---|---|---|
| ADC 输入 | `adc_clk`、`adc_rst_n`、`adc_valid`、`adc_ch0/1` | I | ADC 接收逻辑 | 提供不可反压的采样时刻和两路 12 bit 数据 |
| FDMA AXI-Lite | `s_axi_fdma_*` | I/O | MicroBlaze | 兼容现有 Vitis 软件的配置、START/STOP和状态读取 |
| DDR AXI 写 | `m_axi_ddr_aw*`、`m_axi_ddr_w*`、`m_axi_ddr_b*` | I/O | MIG/DDR | 写入Payload Segment和Commit页 |
| NoPHAE AXI-Lite | `m_axi_nophae_*` | I/O | NoPHAE `s_axi_ctrl` | Backend执行寄存器读写和状态轮询 |
| 运行前提 | `ddr_init_done`、`nvme_init_done`、`pcie_link_up`、`ecqe_error_*` | I | MIG/NoPHAE | 阻止未初始化启动，并接收链路/错误状态 |
| Capture状态 | `capture_controller_busy`、`capture_active/ready`、`local_capture_done_pulse`、`capture_done` | O | 软件/ILA | 区分控制忙、ADC排空和SSD最终持久化 |
| 诊断 | `fatal_error`、accepted/dropped、submitted/completed、last status/error | O | 软件/ILA | 定位采样丢失、请求缺口和最终错误 |

DOCX不再设置独立模块图册附录。以下三项固定内容分别放在对应模块正文设计章节的最开头，先给出接口和时序全貌，再进入状态机与行为说明：

1. 原Word表格式顶层架构图保持不变，并新增电路框图/Visio风格重绘图；
2. 从对应 `rtl/<module>.sv` 模块头直接提取逐端口接口信号列表，接口方向统一用I、O或I/O表示；
3. 代表性握手/状态时序图把全部周期拼成连续波形，周期边界只用垂直虚线分隔；相邻周期共用同一个上升沿或下降沿，不再重复画边沿，也不再用逻辑0、1字符表示电平。

正文图表覆盖 `nvme_adc_vitis_compat_top`、`fdma_vitis_compat_regs`、`adc_capture_limit_controller`、`nvme_adc_pipeline_top`、`adc_channel_packer`、`axis_async_fifo`、`adc_ddr_segment_writer`、`sync_fifo`、`segment_buffer_manager`、`nvme_request_scheduler` 和 `nophae_dma_backend`。Stub、未使用 Mailbox 和尚未取得的 NoPHAE 内部 RTL 不进入逐模块图表。

## 4. 默认参数、地址布局和容量推导

### 4.1 数据粒度

| 项目 | 公式 | 默认值 |
|---|---|---:|
| AXI beat | AXI_DATA_WIDTH / 8 | 256 / 8 = 32 Byte |
| AXI Burst | BURST_BEATS × BEAT_BYTES | 16 × 32 = 512 Byte |
| Segment beat 数 | SEGMENT_BYTES / 32 | 1 MiB / 32 = 32768 beat |
| Segment Burst 数 | 32768 / 16 | 2048 Burst |
| Beat FIFO 深度 | 2^BEAT_FIFO_AW | 2^7 = 128 beat = 4 KiB |
| Commit 页 | 4096 / 32 | 128 beat = 8 Burst |
| Segment 环容量 | 8 × 1 MiB | 8 MiB |

### 4.2 DDR 默认地址图

| 地址范围 | 用途 | 大小 |
|---|---|---:|
| 0xC0000000～0xC00FFFFF | Segment 0 | 1 MiB |
| 0xC0100000～0xC01FFFFF | Segment 1 | 1 MiB |
| 0xC0200000～0xC02FFFFF | Segment 2 | 1 MiB |
| 0xC0300000～0xC03FFFFF | Segment 3 | 1 MiB |
| 0xC0400000～0xC04FFFFF | Segment 4 | 1 MiB |
| 0xC0500000～0xC05FFFFF | Segment 5 | 1 MiB |
| 0xC0600000～0xC06FFFFF | Segment 6 | 1 MiB |
| 0xC0700000～0xC07FFFFF | Segment 7 | 1 MiB |
| 0xC0800000～0xC0800FFF | 固定 Commit 页 | 4 KiB |

### 4.3 250 MSPS 下的格式、数据率和缓存时间

| 模式 | 每数据时刻字节数 | 每个 256 bit 字的数据时刻数 | 数据率 | 1024 项 ADC FIFO | 单 Segment | 8 Segment 环 |
|---|---:|---:|---:|---:|---:|---:|
| 双通道 | 4 Byte | 8 | 1 GB/s | 32.768 µs | 1.048576 ms | 8.388608 ms |
| 单通道 CH0 | 2 Byte | 16 | 500 MB/s | 65.536 µs | 2.097152 ms | 16.777216 ms |
| 单通道 CH1 | 2 Byte | 16 | 500 MB/s | 65.536 µs | 2.097152 ms | 16.777216 ms |

上述时间是理想连续数据率下的容量换算，不包含控制延迟，也不能替代对 SSD 持续写带宽和最坏尾延迟的实测。

## 5. adc_channel_packer 详细设计

<!-- MODULE_VISUAL: adc_channel_packer -->

### 5.1 三个状态

| 状态 | 进入条件 | 状态内动作 | 退出条件 |
|---|---|---|---|
| ST_IDLE | 复位或上一 EOC 完成握手 | 等待 capture_start 且 capture_ready；锁存配置；清本次诊断计数 | 合法 START 后进入 ST_ACTIVE |
| ST_ACTIVE | 新 Capture 配置已锁存 | 接收 adc_valid，按 2/4 Byte 追加；管理输出寄存器与 pack_data | capture_stop 优先进入 ST_DRAIN |
| ST_DRAIN | 停止条件出现 | 把剩余字节或零字节 EOC 装入输出寄存器；不再接收 ADC | EOC 完成 ready/valid 握手后进入 ST_IDLE |

capture_active 等于 state 不为 ST_IDLE，因此尾字没有真正离开模块前仍属于当前 Capture。capture_ready 还要求输出寄存器为空且下游 ready，避免新 Capture 的第一字与旧 EOC 混叠。

### 5.2 配置锁存

配置只在以下分支锁存：

~~~systemverilog
if (capture_start && capture_ready) begin
    active_two_channel           <= cfg_two_channel;
    active_single_channel_select <= cfg_single_channel_select;
    active_capture_id            <= cfg_capture_id;
end
~~~

运行过程中格式不能改变，因为同一 256 bit 字内的采样粒度、valid_bytes 到 sample-time 的换算、后续 CRC 和描述符均依赖同一模式。活动期外部配置变化只置 config_change_sticky，不会改变锁存值。

### 5.3 两级弹性缓存

| 信号 | 语义 | 何时改变 |
|---|---|---|
| m_axis_tdata/tvalid | 第一级输出寄存器 | 有完整字、尾字或 EOC 可发送且 output_free=1 时装载 |
| pack_data | 第二级正在组装的字 | 每次接受样本后追加；转入输出寄存器后清零 |
| pack_byte_count | pack_data 已占用字节数 | 双通道每拍加 4，单通道每拍加 2 |
| pack_full_pending | 第二级已经完整 32 Byte，但第一级正受反压 | 第一级腾空后转移并清零 |
| output_take | m_axis_tvalid 且 m_axis_tready | 表示本拍下游实际取走输出 |
| output_free | 输出寄存器为空或本拍将被取走 | 允许同一沿完成旧字取走和新字装载 |
| eoc_loaded | DRAIN 已经生成一次 EOC | EOC 反压期间防止重复生成 |

pack_with_sample 是组合预览：先复制 pack_data，再把本拍选中样本写入 pack_byte_count×8 对应位置。双通道选择 {ch1_ext,ch0_ext}，单通道只追加所选通道的低 16 bit。

### 5.4 ST_DRAIN 和 pack_full_pending 不能删除

没有 ST_DRAIN 时，capture_stop 可能让状态立即回到 IDLE：未满 256 bit 的尾字没有消费者，或零字节 EOC 尚未握手就允许下一次 START，两个 Capture 会失去清晰边界。

没有 pack_full_pending 时，若第一级输出寄存器 stall，而 pack_data 又刚好凑满第二个字，后续样本会覆盖完整第二字的末尾或被无记录地丢弃。当前实现最多缓存“一个正在输出的字 + 一个完整 pending 字”；两级都满后继续出现 adc_valid 才进入明确丢数边界。

### 5.5 诊断计数与 sticky

| 信号 | 单位 | 清除条件 | 含义 |
|---|---:|---|---|
| accepted_sample_times | 数据时刻 | 复位或合法新 Capture | 成功纳入组包的数据时刻数；双通道同拍两路仍计 1 |
| dropped_sample_times | 数据时刻 | 复位或合法新 Capture | 两级缓存均占用时仍到达的 adc_valid 数 |
| overflow_sticky | 位 | 复位或合法新 Capture | 丢数或 Packer 未 ready 时过早 START 曾发生 |
| config_change_sticky | 位 | 复位或合法新 Capture | 活动期模式或 Capture ID 与锁存值不一致 |

## 6. adc_capture_limit_controller 详细设计

<!-- MODULE_VISUAL: adc_capture_limit_controller -->

### 6.1 Toggle CDC 和多位上下文

START/STOP 是系统域单拍脉冲。若直接两级同步，一个窄脉冲可能完全落在 ADC 时钟采样间隙。Toggle 方法把每个事件编码成电平翻转：源域每来一次脉冲翻转一次，目的域比较 sync 与 seen，不同即代表一个未消费事件。

| 方向 | 事件/电平 | 第一级 | 第二级 | 已消费记忆 |
|---|---|---|---|---|
| sys→adc | START Toggle | start_meta_adc | start_sync_adc | start_seen_adc |
| sys→adc | STOP Toggle | stop_meta_adc | stop_sync_adc | stop_seen_adc |
| adc→sys | Done Toggle | done_meta_sys | done_sync_sys | done_seen_sys |
| adc→sys | Cancel Toggle | cancel_meta_sys | cancel_sync_sys | cancel_seen_sys |
| adc→sys | Busy 电平 | busy_meta_sys | busy_sync_sys | 不需要 seen |

target_bytes_sys、模式和 Capture ID 是多位上下文，分别经过 meta/sync 两级采样。控制器检测到 START Toggle 后先进入 ST_CONTEXT，额外等待一拍再锁存这些多位值。前提是 FDMA 寄存器在请求处理期间保持上下文稳定；这不是任意异步多位总线的通用 CDC 方案。

### 6.2 五个状态

| 状态 | 意义 | 主要转移 |
|---|---|---|
| ST_IDLE | 无活动请求，等待 START | START 新值→ST_CONTEXT；若有 cancel_next_start_adc 则直接回送取消完成 |
| ST_CONTEXT | 给多位同步值额外稳定一拍 | 锁存模式、ID，计算目标数据时刻数→ST_WAIT_READY |
| ST_WAIT_READY | 等 Packer 输出和 CDC FIFO 均可开始 | packer_capture_ready→发一拍 START→ST_RUNNING |
| ST_RUNNING | 监视定长条件和手动 STOP | 计数达到目标或 STOP→ST_WAIT_IDLE |
| ST_WAIT_IDLE | Packer 正在排空尾字/EOC | packer_capture_active=0→翻转 Done→ST_IDLE |

### 6.3 START/STOP 乱序和提前取消

STOP 处理位于状态 case 之前，优先级高于普通状态推进：

| STOP 到达时状态 | 处理 |
|---|---|
| ST_CONTEXT/ST_WAIT_READY | Capture 尚未真正开始，直接产生 Done + Cancel，返回 IDLE |
| ST_RUNNING | 产生 manual_stop_adc，让 Packer 进入 DRAIN |
| ST_IDLE 且 START 已可见 | 同拍消费 START，并报告取消 |
| ST_IDLE 且 START 尚不可见 | 置 cancel_next_start_adc，拦截稍后到达的 START |

### 6.4 定长停止为何优先于同拍 adc_valid

双通道目标数据时刻数为 target_bytes / 4，单通道为 target_bytes / 2。capture_stop_adc 的定长条件是 ST_RUNNING、目标非零且 accepted 计数不小于目标。Packer 在 ST_ACTIVE 中先判断 capture_stop，再判断 adc_valid。因此达到目标后的下一采样沿会先停止，不会多收一拍。若 adc_valid 优先，Payload 会比软件 SIZE 多 2 或 4 Byte。

## 7. 329 bit CDC FIFO 与反压链

<!-- MODULE_VISUAL: axis_async_fifo -->

### 7.1 位域

| 位段 | 宽度 | 含义 |
|---|---:|---|
| [328] | 1 | EOC |
| [327:322] | 6 | valid_bytes，范围 0～32 |
| [321] | 1 | 已锁存双通道模式 |
| [320] | 1 | 已锁存单通道选择 |
| [319:256] | 64 | 已锁存 Capture ID |
| [255:0] | 256 | ADC Payload 数据字 |

把 66 bit 上下文与数据放在同一个 FIFO 表项中，是为了保证首字不会先于模式和 Capture ID 到达系统域。旧的“数据走 FIFO、上下文单独两级同步”会在 Capture 边界存在竞态。

### 7.2 三层 ready/valid

| 层 | valid 来源 | ready 来源 | stall 时必须保持的内容 |
|---|---|---|---|
| Packer 输出寄存器 | m_axis_tvalid | 异步 FIFO s_axis_tready | data、valid_bytes、EOC |
| 异步 FIFO 读侧 | 非empty且非rd_rst_busy | ddr_init_done 且 writer_stream_ready | FWFT 队首 329 bit 条目 |
| Writer 输入 | CDC FIFO m_axis_tvalid | Writer s_axis_tready | 队首条目由 XPM 保持 |

异步 FIFO 的写侧 ready 为非full且非wr_rst_busy。短时停顿先由 Beat FIFO、Segment 环和 ADC CDC FIFO吸收。ADC 源本身不能被反压：当 Packer 的输出寄存器和 pack_data 都占用时，继续到来的 adc_valid 只能计入 dropped。FIFO 容量只能延长允许停顿时间，不能把不可反压数据源变成无损无限缓存。

## 8. adc_ddr_segment_writer 详细设计

<!-- MODULE_VISUAL: adc_ddr_segment_writer -->

<!-- MODULE_VISUAL: sync_fifo -->

### 8.1 Writer 八状态

| 状态 | 进入条件 | 主要输出/动作 | 退出条件 |
|---|---|---|---|
| WR_IDLE | 复位、非尾段描述符完成或 Commit 描述符完成 | 非空首字请求 alloc；零字节 EOC 直接启动 Commit job | alloc 握手→WR_FILL；空 Capture→WR_COMMIT_FILL |
| WR_FILL | 已获得 Segment | 接收真实流字，累计 Payload、样本数和 CRC | Segment 满或 EOC→WR_PAD |
| WR_PAD | 最终真实字已接受 | 向 Beat FIFO 推零直到目标 DMA beat 数 | queued_beats等于job_target_beats→WR_WAIT_JOB |
| WR_WAIT_JOB | 生产端已结束 | 等 AXI job 最终 B 响应 | job_done_pulse→WR_DESC |
| WR_DESC | Payload job 完成 | 保持 fill 描述符 | Manager 握手；尾段→Commit，非尾段→IDLE |
| WR_COMMIT_FILL | 空 Capture 或尾段描述符已交付 | 依次生成 128 个 Commit beat | 全部入 FIFO→WR_COMMIT_WAIT |
| WR_COMMIT_WAIT | Commit 页生产结束 | 等 Commit job 最终 B 响应 | job_done_pulse→WR_COMMIT_DESC |
| WR_COMMIT_DESC | Commit 页 DDR 写完成 | 保持 commit 上下文 | Scheduler 握手→清 Capture 上下文→IDLE |

### 8.2 AXI 四状态

| 状态 | 意义 | 输出 | 转移 |
|---|---|---|---|
| AXI_IDLE | 等至少一个完整 Burst | 无 AW/W | job_active且enough_for_burst→AXI_AW |
| AXI_AW | 保持当前 Burst 地址 | AWVALID=1 | AWREADY→AXI_W |
| AXI_W | 从 Beat FIFO 发送 16 拍 | WVALID、全 WSTRB、末拍 WLAST | 每拍 W 握手；末拍→AXI_B |
| AXI_B | 等唯一写响应 | BREADY=1 | BVALID 后记录错误并回 IDLE |

当前实现严格一次只有一个 Burst 在途。只有 FIFO 至少存有 BURST_BEATS 个 beat 才发 AW，避免 W 通道开始后因生产端暂时无数据而饿死。

### 8.3 alloc 是项目内所有权握手

~~~systemverilog
assign alloc_valid = (writer_state == WR_IDLE) && s_axis_tvalid &&
                     stream_format_valid && (s_axis_valid_bytes != 0);
~~~

Writer 是申请方，Manager 是分配方。alloc_valid 与 alloc_ready 同拍为 1 时，Writer 锁存 segment_id/tag/ddr_addr，Manager 同拍把槽位从 FREE 改成 FILLING。非空首字在 WR_IDLE 期间 s_axis_tready=0，因此不会在 alloc 之前被消费；FIFO 会保持队首。握手后的下一拍 Writer 已进入 WR_FILL，该首字才可能完成流握手。

这不是 AXI Master/Slave：没有 AW、W、B，也没有标准总线地址相位。它只是一组项目自定义的 ready/valid 信号。

### 8.4 s_axis_tready 逐条件解释

~~~systemverilog
assign s_axis_tready =
    ((writer_state == WR_IDLE) && s_axis_tvalid &&
     stream_format_valid && (s_axis_valid_bytes == 0) &&
     s_axis_end_of_capture) ||
    ((writer_state == WR_FILL) && !beat_fifo_full &&
     stream_format_valid &&
     ((segment_payload_count + s_axis_valid_bytes) <= SEGMENT_BYTES));
~~~

| 门控 | 设计目的 | 删除后的具体错误 |
|---|---|---|
| WR_IDLE 只接受零字节 EOC | 空 Capture 无需浪费 Payload Segment | 若普通数据在 IDLE ready，首字会在 alloc 前出队，数据丢失 |
| WR_FILL | 只有已持有 Segment 时才能接收 Payload | 其他状态接收会让计数、CRC、FIFO和描述符生命周期脱节 |
| 非beat_fifo_full | Beat FIFO 必须有空间 | 满时继续接收会让 XPM 抑制写入，但计数/CRC仍前进，DDR少数据 |
| stream_format_valid | 中间字必须32 Byte；尾字0～32 Byte；满足2/4 Byte粒度 | 删除后 WSTRB 全1仍写32 Byte，地址推进与真实字节计数不一致 |
| 累计不超过SEGMENT_BYTES | 当前字不能跨越固定Segment边界 | 删除后写入下一个槽位地址区，但所有权仍属于当前槽位 |
| 零字节必须EOC | 只允许有语义的空结束条目 | 删除后零字节普通条目可能让状态机无数据推进 |

### 8.5 流格式、CRC 和补零

真实输入规则：非末字必须是 32 Byte；末字允许 0～32 Byte；双通道字节数为 4 的倍数，单通道为 2 的倍数。格式错误置 stream_format_error_sticky，该信号当前只在复位时清除。

CRC32C 使用反射多项式 0x82F63B78，初值全 1，最终取反。函数只遍历 valid_bytes 个低位字节，因此短尾字高位和 4 KiB 对齐零拍不进入 CRC。

align_4k 产生 DMA 字节数。Beat FIFO 中补入的零拍使 WSTRB 可以始终全 1，同时保证 DDR 中尾部是确定的 0。payload_bytes 保持真实长度，dma_bytes 表示写入长度。

### 8.6 queued_beats、job_target_beats 和最终 B 响应

queued_beats 是当前 job 自开始以来推入 Beat FIFO 的累计拍数，不是 FIFO 当前占用量。job_target_beats 是最终要求写入 DDR 的拍数。AXI 引擎用 job_beats_written 统计 W 握手数。

即使最后一个 W beat 已握手，也不能立即产生描述符，因为 AXI Slave 仍可能返回错误 B 响应。只有 job_finalized=1、job_beats_written等于job_target_beats且最后一个 BVALID 到达时，job_done_pulse 才出现。删除 B 等待会把实际失败的 DDR 数据误标成 READY 并提交 SSD。

### 8.7 fill 描述符字段

| 字段 | 来源 | 单位/编码 | 有效期 | 消费者 |
|---|---|---|---|---|
| fill_segment_id | alloc 握手锁存 | 槽位编号 | WR_DESC 全程稳定 | Manager 索引状态表 |
| fill_tag | alloc 握手锁存 | {generation,segment_id} | 同上 | Manager 校验同代对象 |
| fill_error | segment_job_error | 1=任一 B 响应失败 | 同上 | Manager 转 ERROR_HOLD |
| fill_payload_bytes | segment_payload_count | Byte，不含补零 | 同上 | Manager 描述符表、Scheduler入口检查 |
| fill_dma_bytes | align_4k | Byte，4 KiB 对齐 | 同上 | Scheduler/Backend DMA 长度 |
| fill_sequence | sequence_counter | 从 0 递增 | 同上 | Manager表；当前顶层未送Scheduler |
| fill_crc32c | 最终取反 CRC | 32 bit CRC32C | 同上 | Manager表；当前顶层未送Scheduler/Commit页 |
| fill_capture_id | Capture 首段锁存 | 64 bit | 同上 | Manager表；当前顶层未送Scheduler |
| fill_sample_count | 本段样本时刻累计 | 数据时刻 | 同上 | Manager表；当前顶层未送Scheduler |
| fill_two_channel | Capture 首段锁存 | 1=双通道 | 同上 | Manager表 |
| fill_single_channel_select | Capture 首段锁存 | 0=CH0，1=CH1 | 同上 | Manager表 |
| fill_capture_last | 最终输入条目的 EOC | 1=Capture尾段 | 同上 | Manager表；Writer据此启动Commit页 |

current_ddr_addr 和 job_is_commit 当前只被赋值、没有被后续决策读取，属于遗留诊断上下文，按本轮“只补注释”边界保留。

## 9. segment_buffer_manager 详细设计

<!-- MODULE_VISUAL: segment_buffer_manager -->

### 9.1 它管理什么，不管理什么

Manager 管理的是 8 个固定 DDR 槽位的所有权、代数和描述符表。它不产生 AXI 地址通道，不发送 WDATA，不读取 DDR，也不创建 NVMe SQE。实际写 DDR 的是 Writer；实际提交 SSD 请求的是 Scheduler/Backend。

### 9.2 生命周期

| 状态 | 所有者/含义 | 正常下一状态 | 异常下一状态 |
|---|---|---|---|
| SEG_FREE | 无人持有，可分配 | alloc→SEG_FILLING | 非法 Completion 可置 sticky |
| SEG_FILLING | Writer 正在填充 | 合法 fill→SEG_READY | fill错误/Tag错→SEG_ERROR_HOLD |
| SEG_READY | 数据完整，等待Scheduler | ready握手→SEG_INFLIGHT | 非法Completion→SEG_ERROR_HOLD |
| SEG_INFLIGHT | SSD请求在途，DDR不可覆盖 | 成功Completion→SEG_FREE | 失败Completion→SEG_ERROR_HOLD |
| SEG_ERROR_HOLD | 数据/状态不可信，隔离 | 仅复位→SEG_FREE | 保持 |

FREE 和 READY 均从索引 0 向上扫描，选择最低编号。该策略确定、易验证，但不是时间公平或优先级调度。

### 9.3 Tag 与 generation

默认 8 个 Segment 时 SEGMENT_ID_W=3，GEN_W=13：

~~~text
Tag[15:3] = generation
Tag[2:0]  = segment_id
~~~

每次 alloc 使用“当前 generation + 1”产生 Tag，并在握手时把新 generation 写回表项。旧代 Completion 即使 segment_id 相同，也不能与新代 Tag 相等，因而不能释放已经重新分配的数据。

当前代码对迟到 Completion 有两种结果：

| 情况 | 现有处理 |
|---|---|
| Tag 与所有 tag_table 都不匹配 | 只置 state_error_sticky；由于无法可靠定位槽位，不猜测并修改某一状态 |
| Tag 命中表项，但表项不是 INFLIGHT | 置 state_error_sticky，命中槽位进入 ERROR_HOLD |
| Tag 命中 INFLIGHT，status=0 | 槽位回到 FREE |
| Tag 命中 INFLIGHT，status非0 | 槽位进入 ERROR_HOLD |

### 9.4 四组接口握手

| 接口 | 发起方→接收方 | 握手时的状态变化 |
|---|---|---|
| alloc | Writer→Manager | 最低编号 FREE→FILLING；代数加1；写 Tag |
| fill | Writer→Manager | 合法 FILLING→READY并写描述符；错误→ERROR_HOLD |
| ready | Manager→Scheduler | Scheduler请求真正被后端接受时 READY→INFLIGHT |
| completion | Scheduler→Manager | 成功 INFLIGHT→FREE；失败→ERROR_HOLD |

### 9.5 代码映射

| 位置 | 相关代码 |
|---|---|
| Writer | alloc_valid/ready/id/tag/ddr_addr；fill_valid/ready及所有字段 |
| Manager | first_free、first_ready、state数组、generation数组、十组描述符表 |
| Scheduler | ready_valid/ready_accept；manager_completion信号组 |
| Pipeline Top | u_segment_writer、u_segment_manager、u_nvme_scheduler 之间的同名 wires |

## 10. Commit 页设计

### 10.1 定位

Commit 页是“本次 Capture 可以被解释为完整任务”的汇总元数据和完成标志，不是普通 Payload Segment。它固定占用 DDR 0xC0800000 起始的 4 KiB，Writer 不向 Manager 申请 Segment，也不进入普通槽位状态表。

### 10.2 ADCCOMM1 字段表

| Beat | bit | 内存字节偏移 | 宽度 | 字段 | 当前值/来源 |
|---:|---|---|---:|---|---|
| 0 | [63:0] | 0x000～0x007 | 8 Byte | Magic | 64'h314D_4D4F_4343_4441，小端内存显示 ADCCOMM1 |
| 0 | [79:64] | 0x008～0x009 | 2 Byte | Version | 1 |
| 0 | [95:80] | 0x00A～0x00B | 2 Byte | Flags | bit0=two_channel，bit1=single_select，其余0 |
| 0 | [127:96] | 0x00C～0x00F | 4 Byte | Page bytes | 4096 |
| 0 | [191:128] | 0x010～0x017 | 8 Byte | Capture ID | capture_id_latched |
| 0 | [255:192] | 0x018～0x01F | 8 Byte | Sample times | capture_sample_total |
| 1 | [63:0] | 0x020～0x027 | 8 Byte | Payload bytes | capture_payload_total |
| 1 | [95:64] | 0x028～0x02B | 4 Byte | Segment count | capture_segment_total |
| 1 | [255:96] | 0x02C～0x03F | 20 Byte | Reserved | 0 |
| 2～127 | 全部 | 0x040～0xFFF | 4032 Byte | Reserved | 0 |

### 10.3 生命周期与复用条件

Writer 在尾 Segment 的 fill 描述符被 Manager 接受后生成 Commit 页。Commit 页全部写入 DDR并等到最终 B 响应后，才对 Scheduler 拉高 commit_valid。Scheduler锁存地址、长度和ID后先做 Flush1，再发 Commit Write。

正式 Vitis 兼容通路中，fdma_transfer_active 要等第二次 Flush 成功才清除，活动期间重复 START 被拒绝。因此固定 Commit 页不会被下一任务提前覆盖。若绕开 FDMA 顶层直接驱动 Pipeline，调用方也必须遵守“capture_done 前不得开始下一 Capture”的条件；commit_ready 只表示 Scheduler 已锁存上下文，不表示共享页已经被 SSD DMA 读取完。

### 10.4 两次 Flush 的掉电一致性目的

~~~text
所有 Payload Write 完成
→ Flush1：确保 Payload 先持久化
→ Commit Write：写入完整任务标志和汇总
→ Flush2：确保 Commit 标志本身持久化
→ capture_done
~~~

删除 Flush1，掉电后可能看到 Commit 已落盘而部分 Payload 仍在易失缓存；删除 Flush2，系统可能已报告完成，但掉电后 Commit 标志丢失。该顺序改善任务级可判定性，但不是完整事务文件系统。

### 10.5 当前限制

当前 Commit 页只有 Capture 级汇总，没有逐 Segment 地址、Payload 长度、DMA 长度、sequence 或 CRC 列表。Manager 虽保存逐段 CRC 和描述符，但 Pipeline Top 当前没有把这些字段送入 Scheduler 或 Commit 页。离线恢复只能知道 Capture 总量，不能仅凭当前 Commit 页逐段校验或重建任意乱序布局。

## 11. Scheduler、NoPHAE Backend 与两个顶层

<!-- MODULE_VISUAL: nvme_request_scheduler -->

<!-- MODULE_VISUAL: nophae_dma_backend -->

<!-- MODULE_VISUAL: nvme_adc_pipeline_top -->

### 11.1 Scheduler 的单请求在途约束

Scheduler 在 SEND 状态保持请求字段，直到 nvme_req_valid 与 nvme_req_ready 同拍为1；进入 WAIT 后只接收对应 Completion。普通 Payload 被后端接受的同拍，ready_accept 拉高，Manager 才把槽位从 READY 改为 INFLIGHT。

data_payload_bytes 在入口合法性检查后被锁存，但当前未参与后续请求或 LBA 决策，作为遗留诊断上下文保留。真正的 DMA 请求长度与 LBA 推进使用 data_dma_bytes。

### 11.2 SLBA 推进

Payload 或 Commit WRITE 被后端接受时：

~~~text
next_slba = next_slba + dma_bytes / LBA_BYTES
~~~

默认 LBA_BYTES=512，因此 4 KiB 尾段或 Commit 页推进 8 个 LBA。Flush 不推进 LBA。新 FDMA Capture 的 session_start 会装载软件配置的 session_base_slba。

### 11.3 NoPHAE 地址域转换

NoPHAE Vitis 接口把 dma_srcaddr/dma_dstaddr 解释为相对 DDR 窗口的 32 bit Offset，而 Writer 和 Manager 使用 AXI 物理地址。Backend执行：

~~~text
ddr_offset = physical_ddr_addr - DDR_AXI_BASE_ADDR
lba_count  = byte_len / LBA_BYTES
~~~

请求必须完全落在 DDR_AXI_BASE_ADDR 开始的 DDR_WINDOW_BYTES 窗口内，减法结果高 32 bit 必须为 0，SLBA 高 32 bit 也必须为 0。这样可防止物理地址与 NoPHAE Offset 混写。

### 11.4 DATA 与 FLUSH 寄存器序列

| 流程 | NoPHAE 寄存器步骤 |
|---|---|
| DATA | 轮询 DMA_READY；写 DMA_SRC；写 DMA_DST；写 LBA 数量；写方向/启动；轮询 DMA_DONE |
| FLUSH | 读 CMD_CCNT；DEBUG_LOCK=2；写原生命令字段；CMD_WR=1；DEBUG_LOCK=0；轮询 CMD_CCNT 变化 |

Backend 是外部适配器，不是 NoPHAE 内部实现。它复现 `E:\NVME_PRO\vitis_classic\nvme\src\func.c` 中 test_seq 和 flush 的寄存器访问顺序。

### 11.5 为什么 Capture 只能在第二次 Flush 后完成

local_capture_done_pulse 只说明 ADC 已停并排出 EOC；此时数据可能仍在 CDC FIFO、Beat FIFO、DDR、NoPHAE 或 SSD 缓存中。只有 Scheduler 的 ST_WAIT_FLUSH2 收到 Tag 和 status 都正确的 Completion，才产生 capture_done 并更新 last_capture_id。

### 11.6 两个顶层的分工

| 顶层 | 分工 | 不包含 |
|---|---|---|
| nvme_adc_pipeline_top | 纯数据通路集成；329 bit CDC；Writer/Manager/Scheduler连接；错误汇总 | FDMA软件ABI、NoPHAE寄存器访问 |
| nvme_adc_vitis_compat_top | 正式入口；增加FDMA寄存器、Capture CDC控制和NoPHAE Backend | MIG、SmartConnect和真实NoPHAE内部RTL |

## 12. 若删除保护会怎样

| 保护 | 当前实现 | 删除后的失效模式 |
|---|---|---|
| Packer ST_DRAIN | EOC握手前Capture保持active | 尾字丢失、EOC丢失或新旧Capture混合 |
| Packer pack_full_pending | 两级缓存中的完整第二字保持 | stall恢复前第二字末尾被覆盖 |
| 输出 stall 稳定性 | valid且not ready时保持Payload | 下游最终接收的数据与先前看到的控制字段不一致 |
| Capture配置锁存 | 只在合法START锁存 | 同一Capture内字节粒度和通道解释变化 |
| STOP优先于adc_valid | 达到目标后不再多收一拍 | Payload超出软件SIZE 2或4 Byte |
| 329 bit原子CDC | 数据和上下文同条目 | 首字可能使用上一Capture模式或ID |
| Writer状态门控 | alloc前首字不出队 | 首个Payload字丢失 |
| FIFO Full门控 | 计数/CRC只在FIFO实际可写时推进 | DDR数据少于描述符长度，CRC也与DDR不符 |
| 格式门控 | 全WSTRB写策略与真实计数一致 | 短中间字制造DDR空洞和地址错位 |
| Segment边界门控 | Writer不越过已分配槽位 | 覆盖相邻、可能属于INFLIGHT的Segment |
| 等待最终B响应 | 描述符反映DDR真实写结果 | DDR失败仍被Manager标为READY |
| Manager generation | 迟到Completion不能释放新代数据 | 旧请求完成释放并覆盖新Capture槽位 |
| ERROR_HOLD | 可疑槽位不再分配 | 部分写入或SSD失败数据被静默复用 |
| Scheduler Tag检查 | Completion必须属于当前请求 | 乱序/错误Completion推进错误状态 |
| Flush1 | Payload先于Commit持久化 | Commit可见但Payload不完整 |
| Flush2 | Commit持久化后才报告完成 | 已报告完成但掉电后Commit消失 |
| sticky错误锁存 | 瞬时错误可被软件/ILA观察 | 软件采样寄存器时错误脉冲可能已消失 |

## 13. 软件使用指导

<!-- MODULE_VISUAL: fdma_vitis_compat_regs -->

### 13.1 不重建的软件边界

本版不修改、不重建 Vitis Classic 工程和 ELF。核心源码位于 E:\NVME_PRO\vitis_classic\nvme\src，现有 ELF、bitstream 和 XSA 的启动方法仍使用原有脚本。V2.4 的 RTL 注释和文档不会自动进入现有 bitstream。

### 13.2 任务配置顺序

1. 确认 PCIe Link、NoPHAE 初始化、DDR 初始化和 I/O Queue 已完成。
2. 写 Capture 模式。双通道每数据时刻 4 Byte，单通道每数据时刻 2 Byte。
3. 写 SIZE_L/SIZE_H。长度必须非零并满足当前样本粒度。
4. 设置安全的 START_LBA 并使能 SLBA。默认 MIN_START_SLBA=1048576，即保护 SSD 前 512 MiB。
5. 写 START=1。活动期重复 START 会返回 D001。
6. 轮询 WDATA_DONE，它只代表 ADC 本地阶段完成。
7. 继续轮询 NVME_SEND_DONE，它代表第二次 Flush 后最终完成。
8. 读取 STATUS、LAST_ERROR、BACKEND_STS、accepted/dropped 和 FIFO 告警，不能只看 DONE。

### 13.3 常见错误码

| 范围/示例 | 来源 | 含义 |
|---|---|---|
| D001 | FDMA寄存器 | 活动期重复START |
| D002 | FDMA寄存器 | SIZE为0 |
| D003 | FDMA寄存器 | SIZE不满足2/4 Byte样本粒度 |
| D004 | FDMA寄存器 | SLBA落入保护区 |
| D005 | FDMA寄存器 | 启动前Pipeline已有fatal |
| D006 | Capture控制 | 尚未启采即被软件取消 |
| D100 | FDMA寄存器 | 活动期Pipeline fatal汇总 |
| E001～E008 | NoPHAE Backend | 操作码、长度、地址、AXI-Lite、超时或禁用错误 |

### 13.4 上板前必须确认

| 检查项 | 原因 |
|---|---|
| 0x90000000 FDMA寄存器已加入实际地址图 | 当前历史XSA没有该外设 |
| Commit/Segment地址与队列、PRP、软件测试区不重叠 | 防止DDR互相覆盖 |
| DDR_AXI_BASE_ADDR与NoPHAE真实窗口一致 | 地址减法错误会让DMA读错位置 |
| SSD LBA格式确为512 B或把参数改为Identify结果 | byte到LBA换算依赖该值 |
| 新RTL确实进入新bitstream | 修改源码文件不等于硬件已更新 |
| 任务期间不启动下一Capture | 固定Commit页直到Flush2才安全复用 |

## 14. 本轮验证和变更约束

### 14.1 实际执行

本轮按最新要求没有启动 Vivado/XSim 回归，也没有新增第六项测试，不调用综合。验证集中在源码不变量和文档结构：

| 检查 | 结果标准 |
|---|---|
| RTL去注释摘要 | 11个文件逐一等于修改前基线；Packer基线预先允许always_comb→always @* |
| 组合逻辑形式 | Packer原有过程组合块为always @*；其他现有组合逻辑不改 |
| 旧位宽注释 | 正式RTL不得把当前ADC FIFO写成263 bit |
| 文档链接 | 本Markdown内相对链接均能解析 |
| DOCX | ZIP/CRC、OOXML必需部件、标题层级、编号、固定DXA表格、核心属性、关键术语和内容规模 |
| 渲染 | 按工作区要求不生成PDF/PNG、不做页面渲染 |

### 14.2 不宣称的结论

本轮不把历史 5 PASS 写成本次回归结果，也不宣称 6 PASS / 0 FAIL。没有执行综合、时序分析、实现、bitstream生成、JTAG下载、真实DDR写入或SSD回读。代码注释通过不等于功能验证升级。

## 附录 A：11 个正式模块的代码级字典

### A.1 adc_channel_packer

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | SIGN_EXTEND | 12 bit ADC值扩展方式 |
| 控制端口 | capture_start、capture_stop、capture_ready、capture_active | Capture启停与Packer生命周期 |
| 配置端口 | cfg_two_channel、cfg_single_channel_select、cfg_capture_id | 待锁存配置 |
| 已锁存配置 | active_two_channel、active_single_channel_select、active_capture_id | 当前Capture固定解释 |
| ADC端口 | adc_valid、adc_ch0、adc_ch1 | 不可反压的输入数据时刻 |
| 流端口 | m_axis_tdata、m_axis_valid_bytes、m_axis_end_of_capture、m_axis_tvalid、m_axis_tready | 送CDC FIFO的复合流 |
| 状态 | ST_IDLE、ST_ACTIVE、ST_DRAIN、state | 等待、收样、尾字排空 |
| 组包寄存器 | pack_data、pack_byte_count、pack_full_pending、eoc_loaded | 第二级弹性缓存及EOC一次性生成 |
| 组合中间量 | ch0_ext、ch1_ext、selected_word、selected_bytes、pack_with_sample、next_byte_count | 扩展、通道选择和追加预览 |
| 握手中间量 | output_take、output_free | 输出消费和同拍换字条件 |
| 诊断 | overflow_sticky、config_change_sticky、accepted_sample_times、dropped_sample_times | 丢数、配置变化及数据时刻计数 |

### A.2 adc_capture_limit_controller

| 类别 | 名称 | 语义 |
|---|---|---|
| 系统域端口 | start_pulse_sys、stop_pulse_sys、target_bytes_sys、two_channel_sys、single_select_sys、capture_id_sys | 软件任务上下文 |
| 返回端口 | local_done_pulse_sys、cancelled_pulse_sys、controller_busy_sys | 本地完成、取消和忙 |
| ADC域端口 | packer_capture_ready、packer_capture_active、packer_accepted_sample_times、capture_start_adc、capture_stop_adc | 控制Packer并观察实际计数 |
| sys源Toggle | start_toggle_sys、stop_toggle_sys | 单拍事件跨域编码 |
| adc返回Toggle | done_toggle_adc、cancel_toggle_adc | 完成/取消跨域编码 |
| 返回同步 | done_meta_sys、done_sync_sys、done_seen_sys、cancel_meta_sys、cancel_sync_sys、cancel_seen_sys、busy_meta_sys、busy_sync_sys | 两级同步与事件消费记忆 |
| 请求同步 | start_meta_adc、start_sync_adc、start_seen_adc、stop_meta_adc、stop_sync_adc、stop_seen_adc | START/STOP两级同步与事件消费记忆 |
| 上下文同步 | bytes_meta_adc、bytes_sync_adc、two_meta_adc、two_sync_adc、select_meta_adc、select_sync_adc、id_meta_adc、id_sync_adc | 多位上下文两级采样 |
| 状态 | ST_IDLE、ST_CONTEXT、ST_WAIT_READY、ST_RUNNING、ST_WAIT_IDLE、state | Capture跨域控制流程 |
| 派生/记忆 | target_sample_times、cancel_next_start_adc、manual_stop_adc、busy_adc | 定长目标、乱序取消和ADC域忙 |
| ADC配置输出 | cfg_two_channel_adc、cfg_single_select_adc、cfg_capture_id_adc | ST_CONTEXT锁存后送Packer |

### A.3 axis_async_fifo

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | DATA_WIDTH、ADDR_WIDTH、DEPTH | 条目位宽、地址位宽和深度 |
| 写侧 | s_clk、s_rst_n、s_axis_tdata、s_axis_tvalid、s_axis_tready | ADC域ready/valid入口 |
| 读侧 | m_clk、m_rst_n、m_axis_tdata、m_axis_tvalid、m_axis_tready | 系统域FWFT出口 |
| 状态 | full、empty、prog_full、wr_used_count、rd_used_count | XPM两侧容量诊断 |
| 中间量 | fifo_reset、fifo_read、wr_rst_busy、rd_rst_busy | 合并复位、读握手和XPM复位忙 |

### A.4 sync_fifo

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | DATA_WIDTH、ADDR_WIDTH、DEPTH | Beat条目位宽与FIFO深度 |
| 端口 | clk、rst_n、din、wr_en、rd_en、dout、full、empty、used_count | 单时钟FWFT读写和容量状态 |
| 内部行为 | wr_en且非full、rd_en且非empty | 包装器抑制非法满写和空读 |

### A.5 adc_ddr_segment_writer

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | AXI_ADDR_WIDTH、AXI_DATA_WIDTH、SEGMENT_BYTES、SEGMENT_COUNT、BURST_BEATS、BEAT_FIFO_AW、DDR_BASE_ADDR、COMMIT_DDR_ADDR | DDR形态、分段、Burst、FIFO和地址布局 |
| 推导参数 | SEGMENT_ID_W、BEAT_BYTES、SEGMENT_BEATS、COMMIT_BYTES、COMMIT_BEATS、BURST_COUNT_W、BURST_BYTES、BEAT_FIFO_DEPTH | 所有计数和结构检查的物理粒度 |
| 输入流 | s_axis_tdata、s_axis_valid_bytes、s_axis_end_of_capture、s_axis_tvalid、s_axis_tready | CDC FIFO到Writer的复合条目 |
| Capture配置 | cfg_two_channel、cfg_single_channel_select、cfg_capture_id | 首段锁存的Capture上下文 |
| Writer状态 | WR_IDLE、WR_FILL、WR_PAD、WR_WAIT_JOB、WR_DESC、WR_COMMIT_FILL、WR_COMMIT_WAIT、WR_COMMIT_DESC、writer_state | 输入、补零、描述符和Commit流程 |
| Segment上下文 | current_segment_id、current_tag、current_ddr_addr、segment_payload_count、segment_sample_count、segment_crc_state、segment_crc_complete、segment_dma_count、segment_capture_last、segment_job_error、queued_beats | 当前Payload Segment的身份、计数、CRC和job结果 |
| Capture上下文 | capture_context_valid、capture_two_channel、capture_single_select、capture_id_latched、capture_payload_total、capture_sample_total、capture_segment_total | 跨多个Segment保持到Commit交付 |
| Beat FIFO | beat_fifo_din、beat_fifo_push、beat_fifo_dout、beat_fifo_full、beat_fifo_empty、beat_fifo_count、beat_fifo_pop | 真实数据、补零、Commit统一生产和AXI消费 |
| job引擎 | job_active、job_start_pulse、job_finalized、job_is_commit、job_base_addr、job_target_beats、job_beats_written、job_done_pulse、job_error | 一段连续DDR写的生命周期 |
| AXI状态 | AXI_IDLE、AXI_AW、AXI_W、AXI_B、axi_state、burst_beat_index、enough_for_burst | 单Burst在途写引擎 |
| Commit生成 | commit_beat_index、commit_beat_data | 128拍固定页内容 |
| 流派生 | stream_take、stream_sample_times、payload_after_take、segment_full_after_take、finalize_after_take | 输入握手后的计数和结束判定 |
| 格式派生 | stream_mode_two_channel、stream_byte_granularity_ok、stream_format_valid | 0～32 Byte、EOC及样本粒度检查 |
| alloc接口 | alloc_valid、alloc_ready、alloc_segment_id、alloc_tag、alloc_ddr_addr | Writer向Manager申请FREE槽位 |
| fill接口 | fill_valid、fill_ready以及全部fill字段 | Writer向Manager提交项目描述符 |
| commit接口 | commit_valid、commit_ready、commit_ddr_addr、commit_dma_bytes、commit_capture_id、commit_sample_count、commit_payload_bytes、commit_error | Writer向Scheduler提交Capture收尾 |
| AXI写口 | m_axi_awaddr/len/size/burst/valid/ready、m_axi_wdata/strb/last/valid/ready、m_axi_bresp/valid/ready | Writer到DDR的AXI4写通道 |
| 诊断 | axi_error_sticky、stream_format_error_sticky、accepted_sample_times、sequence_counter | DDR/格式错误和统计 |

### A.6 segment_buffer_manager

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | AXI_ADDR_WIDTH、SEGMENT_BYTES、SEGMENT_COUNT、DDR_BASE_ADDR、SEGMENT_ID_W、GEN_W | 地址布局和Tag切分 |
| 状态 | SEG_FREE、SEG_FILLING、SEG_READY、SEG_INFLIGHT、SEG_ERROR_HOLD、state数组 | 每槽所有权生命周期 |
| 代数 | generation数组、tag_table | 防止迟到Completion释放新代槽位 |
| 描述符表 | payload_table、dma_table、sequence_table、crc_table、capture_id_table、sample_count_table、two_channel_table、single_select_table、capture_last_table | READY/INFLIGHT期间保持的逐段元数据 |
| 扫描 | first_free、first_ready、free_found、ready_found、free_count | 最低编号优先分配和READY输出 |
| Completion | completion_match_found、completion_valid、completion_tag、completion_status | 乱序Tag搜索和状态检查 |
| 接口 | alloc信号组、fill信号组、ready信号组、completion信号组 | Writer、Scheduler与Manager的四组握手 |
| 诊断 | segment_states、state_error_sticky | 展平状态和粘滞错误 |
| 循环变量 | i、k、j | 组合扫描、Tag扫描和时序表更新 |

### A.7 nvme_request_scheduler

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | AXI_ADDR_WIDTH、LBA_BYTES、COMMAND_TIMEOUT_CYCLES、BASE_SLBA | 地址、LBA和watchdog |
| 操作码/Tag | NVME_OP_WRITE、NVME_OP_READ、NVME_OP_FLUSH、TAG_FLUSH1、TAG_COMMIT、TAG_FLUSH2 | 项目抽象请求和收尾保留Tag |
| 状态 | ST_IDLE、DATA/FLUSH1/COMMIT/FLUSH2的SEND/WAIT、ST_HALT、state | 单请求在途和Capture持久化顺序 |
| Payload快照 | data_tag、data_addr、data_dma_bytes、data_payload_bytes | 当前READY Segment请求上下文 |
| Commit快照 | commit_addr_latched、commit_bytes_latched、commit_id_latched | Commit握手后跨两次Flush保持 |
| 进度 | next_slba、command_age、submitted_requests、completed_requests | LBA指针、watchdog和请求统计 |
| 组合分类 | send_state、wait_state、completion_handshake、abort_event、timeout_event、abort_status | 请求有效、完成和异常优先级 |
| Manager接口 | ready信号组、manager_completion信号组 | READY→INFLIGHT→FREE/ERROR_HOLD |
| Backend接口 | nvme_req信号组、nvme_cpl信号组 | 项目请求和Completion |
| 诊断 | capture_done、fatal_error、timeout_sticky、link_down_sticky、last_capture_id | HALT原因和最近成功Capture |

### A.8 nophae_dma_backend

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | AXI_ADDR_WIDTH、CTRL_ADDR_WIDTH、CTRL_BASE_ADDR、DDR_AXI_BASE_ADDR、DDR_WINDOW_BYTES、LBA_BYTES、COMMAND_TIMEOUT_CYCLES、AXIL_TIMEOUT_CYCLES | NoPHAE控制和DMA地址契约 |
| 寄存器常量 | REG_DEBUG_LOCK、REG_DMA_TYPE、REG_DMA_LEN、REG_DMA_SRC、REG_DMA_DST、REG_DMA_READY、REG_DMA_DONE、REG_CMD_CODE、REG_CMD_PRP1_L、REG_CMD_PRP2_L、REG_CMD_DW10、REG_CMD_DW11、REG_CMD_DW12、REG_CMD_DW13、REG_CMD_WR、REG_CMD_CCNT | 现有Vitis实际使用的NoPHAE偏移 |
| 错误状态 | STS_BAD_OPCODE、STS_BAD_LENGTH、STS_BAD_DDR_RANGE、STS_BAD_LBA_RANGE、STS_AXIL_RESPONSE、STS_AXIL_TIMEOUT、STS_CMD_TIMEOUT、STS_DISABLED | Backend本地Completion状态 |
| 流程状态 | FLOW_NONE、FLOW_DATA、FLOW_FLUSH、flow | 当前高层请求类型 |
| 序列状态 | SEQ_IDLE、SEQ_ISSUE、SEQ_WAIT、seq_state、seq_step | 当前寄存器微事务步骤 |
| 活动上下文 | command_age、active_tag、active_is_write、active_ddr_offset、active_lba、active_lba_count、flush_count_before | 单项目请求在途信息 |
| Completion | cpl_pending、cpl_tag_reg、cpl_status_reg | 无Tag的NoPHAE流程完成后回送项目Tag |
| 地址派生 | req_ddr_addr_64、req_ddr_end_64、ddr_window_end_64、req_ddr_offset_64 | 窗口、溢出和Offset检查 |
| 微命令 | bus_cmd_valid、bus_cmd_write、bus_cmd_addr、bus_cmd_wdata、bus_cmd_ready | 高层序列器发给AXI-Lite微引擎的事务 |
| 微响应 | bus_rsp_valid、bus_rsp_ready、bus_rsp_error、bus_rsp_timeout、bus_rsp_rdata、abort_bus | 微引擎返回和异常终止 |
| AXI-Lite寄存器 | bus_busy_reg、bus_write_reg、bus_addr_reg、bus_wdata_reg、awvalid_reg、wvalid_reg、arvalid_reg、bus_age、bus_rsp_valid_reg、bus_rsp_error_reg、bus_rsp_timeout_reg、bus_rsp_rdata_reg | 独立AW/W握手、读写响应和单事务超时 |
| 诊断 | busy、error_sticky、timeout_sticky、last_status、completed_command_count | Backend运行和结果统计 |

### A.9 fdma_vitis_compat_regs

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | AXIL_ADDR_WIDTH、AXIL_BASE_ADDR、FDMA_DATA_WIDTH、MIN_START_SLBA | 软件ABI形态和SSD保护线 |
| 旧ABI偏移 | OFS_START、OFS_BURST_LEN、OFS_WTRANS_TIME、OFS_RTRANS_TIME、OFS_PATTERN、OFS_MEM_SIZE、OFS_DATA_WIDTH、OFS_SIZE_L、OFS_SIZE_H、OFS_WDATA_DONE、OFS_TIME_L、OFS_TIME_H、OFS_START_LBA、OFS_FIFO_FULL、OFS_NVME_DONE、OFS_SLBA_ENABLE | 0x00～0x3C既有ELF访问区 |
| 扩展偏移 | OFS_CAPTURE_CFG、OFS_CAPTURE_ID_L、OFS_CAPTURE_ID_H、OFS_STATUS、OFS_ACCEPTED_L、OFS_ACCEPTED_H、OFS_DROPPED_L、OFS_DROPPED_H、OFS_LAST_ERROR、OFS_BACKEND_STS | 0x40以后诊断区 |
| 错误常量 | ERR_START_WHILE_ACTIVE、ERR_ZERO_SIZE、ERR_SIZE_ALIGNMENT、ERR_PROTECTED_LBA、ERR_PIPELINE_NOT_CLEAN、ERR_CANCELLED_BY_SOFTWARE、ERR_PIPELINE_FATAL | FDMA兼容任务状态码 |
| 兼容镜像 | burst_len_reg、pattern_start_reg、mem_size_reg | 旧软件可读写，但当前不控制Writer |
| 任务配置 | size_low_reg、size_high_reg、start_lba_reg、slba_enable_reg、capture_id_counter、cfg_two_channel、cfg_single_channel_select | 下次START使用的上下文 |
| 任务状态 | transfer_active、wdata_done_reg、nvme_done_reg、local_phase_done、last_error | 软件轮询与终态 |
| 时间统计 | wtrans_time_reg、rtrans_time_reg、time_count_reg、active_cycle_count、local_done_cycle | 本地/最终完成周期统计 |
| AXI写配对 | aw_hold_valid、aw_hold_addr、w_hold_valid、w_hold_data、w_hold_strb、aw_fire、w_fire、have_aw、have_w、write_commit、write_addr、write_data、write_strb、write_offset | 支持AW和W独立到达 |
| 启动检查 | requested_size、sample_bytes、requested_size_aligned、start_lba_allowed | SIZE与LBA安全校验 |

### A.10 nvme_adc_pipeline_top

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | AXI_ADDR_WIDTH、AXI_DATA_WIDTH、SEGMENT_BYTES、SEGMENT_COUNT、BURST_BEATS、ADC_FIFO_AW、COMMAND_TIMEOUT_CYCLES、LBA_BYTES、DDR_BASE_ADDR、COMMIT_DDR_ADDR、BASE_SLBA | 数据面结构和默认布局 |
| Packer连线 | adc_packed_data、adc_packed_valid_bytes、adc_packed_eoc、adc_packed_valid、adc_packed_ready、active_two_channel_adc、active_single_select_adc、active_capture_id_adc | ADC域输出和锁存上下文 |
| CDC连线 | adc_fifo_sdata、adc_fifo_mdata、adc_fifo_mvalid、adc_fifo_mready、adc_fifo_full、adc_fifo_empty、adc_fifo_prog_full、adc_fifo_wr_count、adc_fifo_rd_count | 329 bit原子CDC和容量诊断 |
| CDC同步 | adc_integrity_meta、adc_integrity_sys、adc_fifo_full_meta_sys、adc_fifo_full_sync_sys、adc_fifo_prog_full_meta_sys、adc_fifo_prog_full_sync_sys | 单bit错误/告警进入系统域的两级同步 |
| Writer/Manager | 全部alloc信号、全部fill信号、writer_stream_ready、全部commit信号 | 槽位申请、描述符和Commit上下文 |
| Manager/Scheduler | manager_ready_valid、manager_ready_accept、manager_ready_segment_id、manager_ready_tag、manager_ready_addr、manager_ready_payload、manager_ready_dma、manager_completion_valid、manager_completion_tag、manager_completion_status、manager_state_error | Payload请求生命周期 |
| Scheduler | scheduler_fatal | 调度器fatal并入顶层错误 |
| 当前未用诊断 | adc_fifo_empty、adc_fifo_rd_count、manager_ready_segment_id、commit_sample_count、commit_payload_bytes | 已连接但不参与当前决策，按接口演进保留 |

### A.11 nvme_adc_vitis_compat_top

| 类别 | 名称 | 语义 |
|---|---|---|
| 参数 | Pipeline全部结构参数、CTRL_ADDR_WIDTH、AXIL_TIMEOUT_CYCLES、CAPTURE_DDR_BASE_ADDR、COMMIT_DDR_ADDR、DDR_AXI_BASE_ADDR、DDR_WINDOW_BYTES、NOPHAE_CTRL_BASE_ADDR、FDMA_CTRL_BASE_ADDR、MIN_START_SLBA | 正式板级集成契约 |
| FDMA到控制器 | fdma_start_pulse、fdma_stop_pulse、backend_enable、transfer_size_bytes、transfer_capture_id、cfg_two_channel_sys、cfg_single_select_sys、session_base_slba | 软件任务上下文 |
| 控制器到Packer | capture_start_adc、capture_stop_adc、cfg_two_channel_adc、cfg_single_select_adc、cfg_capture_id_adc | 跨域后固定Capture控制 |
| Scheduler到Backend | nvme_req_valid、nvme_req_ready、nvme_req_opcode、nvme_req_ddr_addr、nvme_req_byte_len、nvme_req_slba、nvme_req_user_tag | 项目抽象请求 |
| Backend到Scheduler | nvme_cpl_valid、nvme_cpl_ready、nvme_cpl_user_tag、nvme_cpl_status | 项目抽象Completion |
| 错误汇总 | pipeline_fatal_error、backend_error_sticky、backend_timeout_sticky、adc_overflow_sticky、config_change_sticky、stream_format_error_sticky、ddr_axi_error_sticky、scheduler_timeout_sticky、link_down_sticky | fatal_error和FDMA STATUS来源 |
| FIFO诊断 | adc_fifo_full_sys、adc_fifo_prog_full_sys、adc_fifo_max_used_count | Vitis兼容状态寄存器输入 |
| unused_diagnostics | 诊断线归约汇总 | 仅消除未单独导出的lint告警，不参与功能决策 |

## 附录 B：关键代码摘录

### B.1 Packer 同拍换字

~~~systemverilog
assign output_take = m_axis_tvalid && m_axis_tready;
assign output_free = !m_axis_tvalid || output_take;
~~~

### B.2 Manager 下一代 Tag

~~~systemverilog
assign alloc_tag = {generation[first_free] + 1'b1, first_free};
~~~

### B.3 最终 B 响应才完成 job

~~~systemverilog
if (job_finalized &&
    (job_beats_written == job_target_beats))
    job_done_pulse <= 1'b1;
~~~

### B.4 第二次 Flush 后完成 Capture

~~~systemverilog
last_capture_id <= commit_id_latched;
capture_done    <= 1'b1;
state           <= ST_IDLE;
~~~

## 附录 C：变更记录

| 版本 | 日期 | 说明 |
|---|---|---|
| V2.1 | 历史 | 修改要点与初步代码验证说明，保留 |
| V2.3 | 2026-07-31 | Vitis源码实证、ABI兼容和既有RTL修复，保留 |
| V2.4 | 2026-08-10 | 新增代码级术语、状态机和全部中间信号字典；总体与11模块架构/接口/时序放在对应章节最开头，原Word图保留并增加模块框图，接口方向使用I/O，时序采用周期虚线分隔的连续波形且边沿只画一次；RTL只补注释并将Packer组合块改为always @* |
