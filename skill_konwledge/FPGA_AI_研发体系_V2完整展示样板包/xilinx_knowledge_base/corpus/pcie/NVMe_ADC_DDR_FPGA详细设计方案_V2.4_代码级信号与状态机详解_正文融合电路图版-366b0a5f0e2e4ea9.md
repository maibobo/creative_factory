# NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解_正文融合电路图版

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解_正文融合电路图版.docx`
- SHA-256: `366b0a5f0e2e4ea944e968331d4bb6c5d9a93dae3ed25cf94262a988dc7620ae`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

内部代码级设计说明

NVMe–DDR–ADC FPGA
详细设计方案

正式Vitis兼容通路｜电路架构图、数据流、I/O接口、高低电平时序与状态机

| 项目项 | 内容 |

| 目标器件/工具 | XCKU040-FFVA1156-2-I｜Vivado 2020.2 |

| 文档版本 | V2.4｜代码级信号与状态机详解｜2026-08-10 |

| 设计预设 | compact_reference_guide｜memo_masthead |

| 事实源 | 当前正式通路实际例化的11个RTL/SV模块 |

| 本版动作 | 只补充中文语义注释；Packer组合块改为always @* |

| 验证边界 | 不重建Vitis、不回归、不综合；只做源码不变量和OOXML结构检查 |


# 图形化阅读导引

本节先从工程外部边界说明总体架构和数据流。原Word表格式图完整保留，并在其后增加电路框图/Visio风格重绘图。重绘图采用模块边界、I/O端口、正交连接器和方向箭头；箭头只表示数据、控制或完成事件的因果方向，不把项目自定义接口误写成AXI、NVMe或NoPHAE标准协议。

图 1A  正式Vitis兼容通路总体顶层架构图（原Word表格式，保留）

| 软件控制/所有权通道 | ADC采集与DDR缓存通道 | NoPHAE/SSD持久化通道 |

| MicroBlaze / Vitis 软件 AXI4-Lite FDMA寄存器访问 | ADC CH0/CH1 adc_valid + 12 bit×2 | PCIe / NVMe SSD NoPHAE实际命令执行 |

| ↓ 写配置、START/STOP ↑ 读状态与计数 | ↓ 无反压采样源 | ↑↓ PCIe事务 |

| fdma_vitis_compat_regs 任务寄存器与软件兼容层 | adc_capture_limit_controller 跨域启动、定长停止 | nophae_dma_backend NoPHAE寄存器微引擎 |

| ↓ Capture上下文 ↑ 本地/最终完成 | ↓ capture_start/stop | ↑↓ 抽象请求/Completion |

| nvme_adc_vitis_compat_top 正式Vitis兼容顶层 | adc_channel_packer 256 bit打包与尾字排空 | nvme_request_scheduler Payload/Flush/Commit顺序 |

| ↔ 状态和诊断汇总 | ↓ 329 bit CDC条目 | ↔ ready描述符/commit上下文 |

| segment_buffer_manager DDR槽位所有权与描述符表 | axis_async_fifo → Writer DDR AXI写入与Commit页 | DDR中的Payload/Commit页 作为NoPHAE DMA源 |


图 1B  正式Vitis兼容通路总体顶层架构图（电路/Visio风格重绘）

### 图 1A/1B 详细文字说明

顶层架构图按控制、采集缓存、存储请求三条纵向通道阅读。左列是软件可见的任务控制和Manager所有权管理，中列是从ADC采样到DDR落盘前缓存的真实数据通路，右列是从抽象请求到NoPHAE、PCIe和SSD的持久化通路。

横向关联不是额外总线标准：Capture Controller把FDMA的START/STOP及配置跨到adc_clk；Writer通过alloc/fill项目内握手与Manager交换槽位所有权和描述符；Scheduler再把Manager的READY描述符转换成NoPHAE抽象请求。

DDR同时承担两个角色：Writer的AXI写目标，以及NoPHAE执行NVMe WRITE时的DMA源。图中的Manager不读写DDR数据，也不是AXI Master；它只决定哪个固定Segment槽位可分配、可提交或可回收。

最终capture_done不等于ADC停止。ADC停止并排空只形成local_capture_done；还必须完成全部Payload WRITE、Flush1、Commit WRITE和Flush2，Scheduler才发出最终完成脉冲。

图 2A  一次Capture的端到端数据流图（原Word表格式，保留）

| 顺序 | 数据所在阶段 | 本阶段内容与流向 |

| 1 | ADC采样 | adc_valid携带CH0/CH1；源端不能因下游ready拉低而停顿 |

| 2 | Packer 256 bit数据字 | 按锁存的单双通道格式扩展为16 bit样点并打包，附带valid_bytes和EOC |

| 3 | 329 bit CDC条目 | {capture_id, mode, EOC, valid_bytes, tdata}从adc_clk跨到sys_clk |

| 4 | Writer与Beat FIFO | 取得Segment槽位后累计CRC/字节数，按4 KiB补零并生成AXI Burst |

| 5 | DDR Payload/Commit页 | Payload位于8个1 MiB槽位，Commit页位于默认0xC0800000 |

| 6 | Manager READY描述符 | DDR最终B响应成功后，fill握手把槽位从FILLING推进到READY |

| 7 | Scheduler请求序列 | Payload WRITE → Flush1 → Commit WRITE → Flush2，任一时刻只允许一个请求在途 |

| 8 | NoPHAE / PCIe / SSD | Backend编程NoPHAE控制寄存器并把Completion返回Scheduler |


图 2B  一次Capture的端到端数据流图（Visio正交连接器重绘）

### 图 2A/2B 详细文字说明

数据流图中的序号是一次Capture的因果顺序，不表示各模块只有串行工作。Packer、CDC FIFO、Writer和Manager可以流水并行；Scheduler仍保持单项目请求在途。

步骤2到步骤4使用ready/valid反压。若valid=1且ready=0，即发生stall，发送方必须保持数据和所有伴随字段不变。ADC物理输入不支持反压，因此反压只能由Packer两级缓存和CDC FIFO短时吸收，耗尽后会记录丢样。

步骤5到步骤8把易失DDR内容持久化到SSD。Payload的真实字节数用于CRC和元数据，DMA字节数则向4 KiB对齐；两者不能混用。

Commit页不是普通Payload Segment。它是Capture结束标志和汇总元数据，必须在所有Payload已经写入并完成第一次Flush之后提交。

表 1  正式顶层接口信号分组导航

| 接口组 | 顶层前缀/代表信号 | 连接对象与用途 |

| ADC输入 | adc_clk、adc_valid、adc_ch0/1 | 连接ADC接收逻辑；样点源不可反压 |

| FDMA AXI-Lite | s_axi_fdma_* | 连接MicroBlaze现有Vitis软件寄存器访问 |

| DDR AXI写 | m_axi_ddr_aw*/w*/b* | Writer写Payload及Commit页到DDR |

| NoPHAE AXI-Lite | m_axi_nophae_* | Backend编程NoPHAE控制寄存器 |

| 运行前提 | ddr_init_done、nvme_init_done、pcie_link_up | 阻止未初始化链路启动数据搬运 |

| 完成/错误 | local_capture_done、capture_done、fatal_error | 区分ADC本地排空、SSD最终持久化和失败 |

| 计数/诊断 | accepted/dropped、submitted/completed | 软件定位丢样、请求停顿和完成缺口 |


表1只用于先按接口族定位；第3节中就地展开的nvme_adc_vitis_compat_top接口信号列表按RTL模块头逐项列出每个实际端口、I/O、位宽、时钟域和中文语义。

版本：V2.4

日期：2026-08-10

事实源：当前正式 Vitis 兼容通路的 11 个 RTL/SV 模块

阅读对象：掌握基础 Verilog/SystemVerilog，但不了解本项目术语的设计、验证和软件人员

验证边界：本轮只补注释并把 Packer 的 always_comb 改为 always @*；不重建 Vitis 软件，不运行 RTL 回归，不综合，不实现，不生成 bitstream。

# 1. 文档目的与事实边界

本文从现有代码出发，说明一次 ADC 数据时刻如何变成 256 bit 数据字，如何跨越 ADC/系统时钟域，如何获得 DDR Segment 所有权，如何经 AXI4 写入 DDR，最后如何由调度器和 NoPHAE 控制寄存器序列写入 SSD。文中所说的 Descriptor、alloc 和 Manager 都是本项目自定义概念，不是 AXI、NoPHAE 或 NVMe 标准对象。

正式通路的 11 个事实源如下：

| 序号 | 模块 | 文件 | 主要职责 |

| 1 | Vitis 兼容顶层 | nvme_adc_vitis_compat_top.sv | 连接 FDMA ABI、Capture 控制、Pipeline 和 NoPHAE Backend |

| 2 | FDMA 兼容寄存器 | fdma_vitis_compat_regs.sv | 复现现有 ELF 的 0x90000000 寄存器 ABI |

| 3 | Capture Controller | adc_capture_limit_controller.sv | START/STOP Toggle CDC 和定长停止 |

| 4 | Pipeline Top | nvme_adc_pipeline_top.sv | 连接 Packer、FIFO、Writer、Manager、Scheduler |

| 5 | Packer | adc_channel_packer.sv | 通道选择、16 bit 扩展、256 bit 组包和尾字排空 |

| 6 | ADC CDC FIFO | axis_async_fifo.sv | 329 bit 原子跨时钟域和短时缓存 |

| 7 | Segment Writer | adc_ddr_segment_writer.sv | 分段、CRC、补零、Commit 页和 DDR AXI 写 |

| 8 | Beat FIFO | sync_fifo.sv | 缓存 Writer 生成的 256 bit DDR 数据拍 |

| 9 | Segment Manager | segment_buffer_manager.sv | 管理 DDR 槽位所有权和描述符表 |

| 10 | Scheduler | nvme_request_scheduler.sv | 顺序提交 Payload、Flush、Commit、Flush |

| 11 | NoPHAE Backend | nophae_dma_backend.sv | 把项目请求转换为 NoPHAE AXI4-Lite 寄存器序列 |


Stub、未使用 Mailbox 和尚未取得的真实 NoPHAE 内部 RTL 不属于逐信号正文。现有软件事实和安全使用方法继续以 NoPHAE Vitis 现有软件使用与验证指南 为准；V2.3 修复背景见 NoPHAE Vitis 源码实证与现有 RTL 修复方案。

# 2. 术语表

| 术语 | 本项目中的准确含义 | 容易混淆的对象 |

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


# 3. 系统全链路

一次正式 Vitis 兼容 Capture 的控制和数据方向如下：

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

## 3.1 控制面与数据面分离

| 路径 | 传递内容 | 实际搬运数据的模块 |

| FDMA 控制面 | SIZE、START、STOP、模式、Capture ID、SLBA | 不搬运 ADC Payload |

| Packer/CDC 数据面 | ADC Payload、有效字节数、EOC、原子上下文 | Packer 和 FIFO |

| DDR 写数据面 | 256 bit AXI WDATA、AW 地址、B 响应 | Segment Writer |

| Segment 所有权面 | alloc、fill、ready、completion 描述符 | Manager 只改状态表 |

| SSD 请求面 | opcode、DDR 地址、DMA 字节数、SLBA、Tag | Scheduler 和 Backend |

| NoPHAE 内部数据面 | DDR 与 PCIe/NVMe 间的数据流 | 真实 NoPHAE IP，内部 RTL 尚未取得 |


## 3.2 完成事件不是同一个时间点

| 事件 | 含义 | 软件可见结果 |

| local_capture_done_pulse | Packer 已停止接收并让 EOC 离开 ADC 域 | WDATA_DONE 置位 |

| fill_valid 且 fill_ready | 一个 Payload Segment 的 DDR 写和 B 响应已结束 | Manager 进入 READY 或 ERROR_HOLD |

| capture_done | 所有 Payload、Flush1、Commit Write、Flush2 均成功 | NVME_SEND_DONE 置位，任务结束 |


## 3.3 总体顶层架构图

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

图 3-1 的详细说明如下：

三个框表示职责分区，不表示三个模块或三个时钟域。控制/所有权通道保存任务配置和 DDR 槽位状态，采集/缓存通道实际搬运 ADC Payload，持久化通道把 DDR 内容写入 SSD。

Capture Controller 是 FDMA 与 Packer 之间的跨域控制桥。它用 toggle 同步单拍事件，并让多位目标字节数、模式和 Capture ID 稳定穿越 sys_clk/adc_clk 边界。

Manager 与 Writer 之间的 alloc/fill 是项目内所有权握手；Manager 与 Scheduler 之间传递 READY 描述符。Manager 既不是 AXI Master，也不读取 256 bit 数据。

DDR 位于两条数据路径的交点：Writer通过AXI写入DDR，NoPHAE随后把同一DDR区域作为NVMe WRITE的DMA源。不得把“写DDR完成”当成“写SSD完成”。

顶层 nvme_adc_vitis_compat_top 负责实例化和连线，真正的数据变换、槽位生命周期和请求顺序分别在 Packer/Writer、Manager 和 Scheduler 中实现。

## 3.4 一次 Capture 的数据流图

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

图 3-2 的详细说明如下：

图中的纵向顺序是因果关系，不表示所有硬件串行停等。Packer、异步 FIFO、Writer、Manager 可以形成流水；Scheduler为了适配现有 NoPHAE 寄存器流程，仍保持单个项目请求在途。

329 bit 必须原子跨域。若把 tdata、valid_bytes、EOC、模式或 Capture ID 分开同步，不同字段可能在 sys_clk 域对应到不同数据字。

valid=1 && ready=0 是 stall。Packer、FIFO、Writer、Scheduler 和 Backend 的发送端都要在 stall 期间保持数据和伴随字段，直到握手。

ADC物理源不能因下游反压停止。短时stall由Packer输出级、pack_full_pending和异步FIFO吸收；全部空间耗尽后只能丢样，并通过dropped计数和overflow sticky暴露。

真实Payload字节参与CRC和元数据；DMA字节按4 KiB对齐，用于DDR/NVMe传输和SLBA推进。二者相等只是一种情况，不是统一概念。

Commit页只在全部Payload完成并经过Flush1后写入。Flush2成功才证明Commit标志也进入最终持久化边界，随后才能产生capture_done。

## 3.5 顶层接口信号列表与正文图表索引

| 接口组 | 顶层信号/前缀 | I/O | 对端 | 设计含义 |

| ADC 输入 | adc_clk、adc_rst_n、adc_valid、adc_ch0/1 | I | ADC 接收逻辑 | 提供不可反压的采样时刻和两路 12 bit 数据 |

| FDMA AXI-Lite | s_axi_fdma_* | I/O | MicroBlaze | 兼容现有 Vitis 软件的配置、START/STOP和状态读取 |

| DDR AXI 写 | m_axi_ddr_aw*、m_axi_ddr_w*、m_axi_ddr_b* | I/O | MIG/DDR | 写入Payload Segment和Commit页 |

| NoPHAE AXI-Lite | m_axi_nophae_* | I/O | NoPHAE s_axi_ctrl | Backend执行寄存器读写和状态轮询 |

| 运行前提 | ddr_init_done、nvme_init_done、pcie_link_up、ecqe_error_* | I | MIG/NoPHAE | 阻止未初始化启动，并接收链路/错误状态 |

| Capture状态 | capture_controller_busy、capture_active/ready、local_capture_done_pulse、capture_done | O | 软件/ILA | 区分控制忙、ADC排空和SSD最终持久化 |

| 诊断 | fatal_error、accepted/dropped、submitted/completed、last status/error | O | 软件/ILA | 定位采样丢失、请求缺口和最终错误 |


DOCX不再设置独立模块图册附录。以下三项固定内容分别就地放入对应模块的正文设计章节：

原Word表格式顶层架构图保持不变，并新增电路框图/Visio风格重绘图；

从对应 rtl/<module>.sv 模块头直接提取逐端口接口信号列表，接口方向统一用I、O或I/O表示；

代表性握手/状态时序图使用对齐的高低电平波形，不再用逻辑0、1字符表示电平，并继续说明stall保持、完成边界和异常分支。

正文图表覆盖 nvme_adc_vitis_compat_top、fdma_vitis_compat_regs、adc_capture_limit_controller、nvme_adc_pipeline_top、adc_channel_packer、axis_async_fifo、adc_ddr_segment_writer、sync_fifo、segment_buffer_manager、nvme_request_scheduler 和 nophae_dma_backend。Stub、未使用 Mailbox 和尚未取得的 NoPHAE 内部 RTL 不进入逐模块图表。

### nvme_adc_vitis_compat_top 架构、接口与时序

源码：rtl/nvme_adc_vitis_compat_top.sv。模块定位：正式Vitis兼容集成顶层，把软件FDMA寄存器、跨域Capture控制、ADC到DDR/NVMe流水线和NoPHAE后端连接为完整工程边界。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 3-3A  nvme_adc_vitis_compat_top 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| ADC CH0/CH1 MicroBlaze AXI4-Lite DDR/NoPHAE返回通道 | FDMA寄存器 → Capture Controller ↓ Pipeline Top ↔ Backend ↓ 状态/诊断汇总 | DDR AXI Master NoPHAE AXI-Lite Master 软件可读任务状态 |


图 3-3B  nvme_adc_vitis_compat_top 顶层架构图（电路/Visio风格重绘）

### 图 3-3A/3-3B 详细文字说明

从左到右读图：外部输入先分别进入控制面和数据面。FDMA寄存器产生transfer_start_pulse，Capture Controller在时钟域间传递上下文，Pipeline完成打包、缓存、DDR写和请求调度，Backend再驱动NoPHAE寄存器接口。

顶层没有新增数据缓存或协议状态机，主要责任是实例化和连线。定位故障时，应先按端口前缀分为s_axi_fdma、m_axi_ddr、m_axi_nophae和诊断四组，再下钻对应子模块。

fatal_error是Pipeline和Backend错误的汇总边界；local_capture_done_pulse只表示ADC侧排空，capture_done才表示第二次Flush完成，软件不得混用。

表 3-3  nvme_adc_vitis_compat_top 接口信号列表（80项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| ADC数据/诊断 | adc_clk | I | 1 | adc_clk/写侧 | ADC采样时钟 |

| ADC数据/诊断 | adc_rst_n | I | 1 | adc_clk/写侧 | ADC域低有效异步复位 |

| ADC数据/诊断 | adc_valid | I | 1 | adc_clk/跨域 | 当前ADC数据时刻有效 |

| ADC数据/诊断 | adc_ch0 | I | 11:0 | adc_clk/跨域 | ADC通道0采样值 |

| ADC数据/诊断 | adc_ch1 | I | 11:0 | adc_clk/跨域 | ADC通道1采样值 |

| 时钟/复位/使能 | sys_clk | I | 1 | sys_clk/读侧 | 控制、DDR和NoPHAE系统时钟 |

| 时钟/复位/使能 | sys_rst_n | I | 1 | clk对应域 | 系统域低有效同步复位 |

| 运行状态 | ddr_init_done | I | 1 | sys_clk | MIG初始化/校准完成 |

| 运行状态 | nvme_init_done | I | 1 | sys_clk | NoPHAE初始化完成 |

| 运行状态 | pcie_link_up | I | 1 | sys_clk | PCIe链路可用 |

| 运行状态 | ecqe_error_valid | I | 1 | sys_clk | NoPHAE错误完成事件有效 |

| 运行状态 | ecqe_error_status | I | 15:0 | sys_clk | NoPHAE错误完成状态 |

| DDR AXI写 | m_axi_ddr_awaddr | O | AXI_ADDR_WIDTH-1:0 | sys_clk | ADC Writer写地址 |

| DDR AXI写 | m_axi_ddr_awlen | O | 7:0 | sys_clk | ADC Writer Burst长度减1 |

| DDR AXI写 | m_axi_ddr_awsize | O | 2:0 | sys_clk | ADC Writer每拍字节数log2 |

| DDR AXI写 | m_axi_ddr_awburst | O | 1:0 | sys_clk | ADC Writer Burst类型 |

| DDR AXI写 | m_axi_ddr_awvalid | O | 1 | sys_clk | ADC Writer写地址有效 |

| DDR AXI写 | m_axi_ddr_awready | I | 1 | sys_clk | DDR互连接受写地址 |

| DDR AXI写 | m_axi_ddr_wdata | O | AXI_DATA_WIDTH-1:0 | sys_clk | ADC Writer写数据 |

| DDR AXI写 | m_axi_ddr_wstrb | O | AXI_DATA_WIDTH/8-1:0 | sys_clk | ADC Writer字节写使能 |

| DDR AXI写 | m_axi_ddr_wlast | O | 1 | sys_clk | ADC Writer Burst末拍 |

| DDR AXI写 | m_axi_ddr_wvalid | O | 1 | sys_clk | ADC Writer写数据有效 |

| DDR AXI写 | m_axi_ddr_wready | I | 1 | sys_clk | DDR互连接受写数据 |

| DDR AXI写 | m_axi_ddr_bresp | I | 1:0 | sys_clk | DDR写响应 |

| DDR AXI写 | m_axi_ddr_bvalid | I | 1 | sys_clk | DDR写响应有效 |

| DDR AXI写 | m_axi_ddr_bready | O | 1 | sys_clk | ADC Writer等待写响应 |

| 软件AXI-Lite | s_axi_fdma_awaddr | I | CTRL_ADDR_WIDTH-1:0 | sys_clk | FDMA写地址 |

| 软件AXI-Lite | s_axi_fdma_awprot | I | 2:0 | sys_clk | FDMA写保护属性，当前未参与寄存器判定 |

| 软件AXI-Lite | s_axi_fdma_awvalid | I | 1 | sys_clk | FDMA写地址有效 |

| 软件AXI-Lite | s_axi_fdma_awready | O | 1 | sys_clk | FDMA寄存器可接收写地址 |

| 软件AXI-Lite | s_axi_fdma_wdata | I | 31:0 | sys_clk | FDMA写数据 |

| 软件AXI-Lite | s_axi_fdma_wstrb | I | 3:0 | sys_clk | FDMA写字节使能 |

| 软件AXI-Lite | s_axi_fdma_wvalid | I | 1 | sys_clk | FDMA写数据有效 |

| 软件AXI-Lite | s_axi_fdma_wready | O | 1 | sys_clk | FDMA寄存器可接收写数据 |

| 软件AXI-Lite | s_axi_fdma_bresp | O | 1:0 | sys_clk | FDMA写响应 |

| 软件AXI-Lite | s_axi_fdma_bvalid | O | 1 | sys_clk | FDMA写响应有效 |

| 软件AXI-Lite | s_axi_fdma_bready | I | 1 | sys_clk | MicroBlaze接受FDMA写响应 |

| 软件AXI-Lite | s_axi_fdma_araddr | I | CTRL_ADDR_WIDTH-1:0 | sys_clk | FDMA读地址 |

| 软件AXI-Lite | s_axi_fdma_arprot | I | 2:0 | sys_clk | FDMA读保护属性，当前未参与寄存器判定 |

| 软件AXI-Lite | s_axi_fdma_arvalid | I | 1 | sys_clk | FDMA读地址有效 |

| 软件AXI-Lite | s_axi_fdma_arready | O | 1 | sys_clk | FDMA寄存器可接收读地址 |

| 软件AXI-Lite | s_axi_fdma_rdata | O | 31:0 | sys_clk | FDMA读数据 |

| 软件AXI-Lite | s_axi_fdma_rresp | O | 1:0 | sys_clk | FDMA读响应 |

| 软件AXI-Lite | s_axi_fdma_rvalid | O | 1 | sys_clk | FDMA读数据有效 |

| 软件AXI-Lite | s_axi_fdma_rready | I | 1 | sys_clk | MicroBlaze接受FDMA读数据 |

| NoPHAE AXI-Lite | m_axi_nophae_awaddr | O | CTRL_ADDR_WIDTH-1:0 | sys_clk | NoPHAE控制寄存器写地址 |

| NoPHAE AXI-Lite | m_axi_nophae_awprot | O | 2:0 | sys_clk | 固定普通非安全数据访问属性 |

| NoPHAE AXI-Lite | m_axi_nophae_awvalid | O | 1 | sys_clk | NoPHAE写地址有效 |

| NoPHAE AXI-Lite | m_axi_nophae_awready | I | 1 | sys_clk | NoPHAE接受写地址 |

| NoPHAE AXI-Lite | m_axi_nophae_wdata | O | 31:0 | sys_clk | NoPHAE寄存器写数据 |

| NoPHAE AXI-Lite | m_axi_nophae_wstrb | O | 3:0 | sys_clk | NoPHAE寄存器写字节使能 |

| NoPHAE AXI-Lite | m_axi_nophae_wvalid | O | 1 | sys_clk | NoPHAE写数据有效 |

| NoPHAE AXI-Lite | m_axi_nophae_wready | I | 1 | sys_clk | NoPHAE接受写数据 |

| NoPHAE AXI-Lite | m_axi_nophae_bresp | I | 1:0 | sys_clk | NoPHAE AXI-Lite写响应 |

| NoPHAE AXI-Lite | m_axi_nophae_bvalid | I | 1 | sys_clk | NoPHAE写响应有效 |

| NoPHAE AXI-Lite | m_axi_nophae_bready | O | 1 | sys_clk | Backend接受NoPHAE写响应 |

| NoPHAE AXI-Lite | m_axi_nophae_araddr | O | CTRL_ADDR_WIDTH-1:0 | sys_clk | NoPHAE控制寄存器读地址 |

| NoPHAE AXI-Lite | m_axi_nophae_arprot | O | 2:0 | sys_clk | 固定普通非安全数据访问属性 |

| NoPHAE AXI-Lite | m_axi_nophae_arvalid | O | 1 | sys_clk | NoPHAE读地址有效 |

| NoPHAE AXI-Lite | m_axi_nophae_arready | I | 1 | sys_clk | NoPHAE接受读地址 |

| NoPHAE AXI-Lite | m_axi_nophae_rdata | I | 31:0 | sys_clk | NoPHAE寄存器读数据 |

| NoPHAE AXI-Lite | m_axi_nophae_rresp | I | 1:0 | sys_clk | NoPHAE AXI-Lite读响应 |

| NoPHAE AXI-Lite | m_axi_nophae_rvalid | I | 1 | sys_clk | NoPHAE读数据有效 |

| NoPHAE AXI-Lite | m_axi_nophae_rready | O | 1 | sys_clk | Backend接受NoPHAE读数据 |

| 状态/诊断 | fdma_transfer_active | O | 1 | sys_clk | Vitis兼容FDMA任务处于活动期 |

| Capture控制 | capture_controller_busy | O | 1 | sys_clk | 跨域Capture控制器忙 |

| Capture控制 | capture_active | O | 1 | adc_clk/跨域 | Packer处于采样或尾字排空期 |

| Capture控制 | capture_ready | O | 1 | adc_clk/跨域 | Packer可接受下一次Capture |

| 状态/诊断 | local_capture_done_pulse | O | 1 | sys_clk | ADC侧停止并排空的本地完成脉冲 |

| Capture控制 | capture_cancelled_pulse | O | 1 | sys_clk | 未实际启采即取消的脉冲 |

| Capture控制 | capture_done | O | 1 | sys_clk | SSD第二次Flush后的最终完成脉冲 |

| 状态/诊断 | last_capture_id | O | 63:0 | sys_clk | 最近成功持久化的Capture编号 |

| 状态/诊断 | backend_busy | O | 1 | sys_clk | NoPHAE Backend正在执行寄存器序列 |

| 状态/诊断 | backend_last_status | O | 15:0 | sys_clk | Backend最近一条完成状态 |

| 状态/诊断 | fdma_last_error | O | 15:0 | sys_clk | FDMA兼容寄存器锁存的最近错误 |

| 状态/诊断 | fatal_error | O | 1 | sys_clk | Pipeline或Backend致命错误汇总 |

| ADC数据/诊断 | adc_accepted_sample_times | O | 63:0 | adc_clk/跨域 | Packer接受的数据时刻数 |

| ADC数据/诊断 | adc_dropped_sample_times | O | 63:0 | adc_clk/跨域 | Packer丢弃的数据时刻数 |

| 状态/诊断 | submitted_requests | O | 31:0 | sys_clk | Scheduler已提交项目请求数 |

| 状态/诊断 | completed_requests | O | 31:0 | sys_clk | Scheduler已完成项目请求数 |


接口表读法：按RTL模块头顺序列出，共80项；接口分组为ADC数据/诊断7项、时钟/复位/使能2项、运行状态5项、DDR AXI写14项、软件AXI-Lite19项、NoPHAE AXI-Lite19项、状态/诊断9项、Capture控制5项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 3-3C  nvme_adc_vitis_compat_top 关键时序图（高/低电平对齐）

| 信号 / 时间 → | T0 | T1 | T2 | T3 | T4 | T5 | T6 | T7 |

| FDMA_START写握手 | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| transfer_start_pulse | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| capture_start_adc | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| local_capture_done | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ |

| 存储阶段 | 空闲 | 启动 | 采集 | 采集 | DATA | F1 | COMMIT | F2 |

| capture_done | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ |


### 图 3-3C 详细文字说明

C1的START写被FDMA寄存器校验通过后只产生一个sys_clk脉冲；跨域控制器不会组合传递该脉冲，而是用toggle事件和两级同步把它安全送到adc_clk。

图中CDC等待和Cn/Cm为示意间隔，不能用固定周期替代实际握手。local_capture_done出现后仍有DDR和NVMe尾部工作，capture_done必须晚于Flush2 Completion。

若fatal_error在中途置位，正常序列可进入错误保持，软件应读fdma_last_error/backend_last_status，不应等待一个不会到来的正常capture_done。

# 4. 默认参数、地址布局和容量推导

## 4.1 数据粒度

| 项目 | 公式 | 默认值 |

| AXI beat | AXI_DATA_WIDTH / 8 | 256 / 8 = 32 Byte |

| AXI Burst | BURST_BEATS × BEAT_BYTES | 16 × 32 = 512 Byte |

| Segment beat 数 | SEGMENT_BYTES / 32 | 1 MiB / 32 = 32768 beat |

| Segment Burst 数 | 32768 / 16 | 2048 Burst |

| Beat FIFO 深度 | 2^BEAT_FIFO_AW | 2^7 = 128 beat = 4 KiB |

| Commit 页 | 4096 / 32 | 128 beat = 8 Burst |

| Segment 环容量 | 8 × 1 MiB | 8 MiB |


## 4.2 DDR 默认地址图

| 地址范围 | 用途 | 大小 |

| 0xC0000000～0xC00FFFFF | Segment 0 | 1 MiB |

| 0xC0100000～0xC01FFFFF | Segment 1 | 1 MiB |

| 0xC0200000～0xC02FFFFF | Segment 2 | 1 MiB |

| 0xC0300000～0xC03FFFFF | Segment 3 | 1 MiB |

| 0xC0400000～0xC04FFFFF | Segment 4 | 1 MiB |

| 0xC0500000～0xC05FFFFF | Segment 5 | 1 MiB |

| 0xC0600000～0xC06FFFFF | Segment 6 | 1 MiB |

| 0xC0700000～0xC07FFFFF | Segment 7 | 1 MiB |

| 0xC0800000～0xC0800FFF | 固定 Commit 页 | 4 KiB |


## 4.3 250 MSPS 下的格式、数据率和缓存时间

| 模式 | 每数据时刻字节数 | 每个 256 bit 字的数据时刻数 | 数据率 | 1024 项 ADC FIFO | 单 Segment | 8 Segment 环 |

| 双通道 | 4 Byte | 8 | 1 GB/s | 32.768 µs | 1.048576 ms | 8.388608 ms |

| 单通道 CH0 | 2 Byte | 16 | 500 MB/s | 65.536 µs | 2.097152 ms | 16.777216 ms |

| 单通道 CH1 | 2 Byte | 16 | 500 MB/s | 65.536 µs | 2.097152 ms | 16.777216 ms |


上述时间是理想连续数据率下的容量换算，不包含控制延迟，也不能替代对 SSD 持续写带宽和最坏尾延迟的实测。

# 5. adc_channel_packer 详细设计

## 5.1 三个状态

| 状态 | 进入条件 | 状态内动作 | 退出条件 |

| ST_IDLE | 复位或上一 EOC 完成握手 | 等待 capture_start 且 capture_ready；锁存配置；清本次诊断计数 | 合法 START 后进入 ST_ACTIVE |

| ST_ACTIVE | 新 Capture 配置已锁存 | 接收 adc_valid，按 2/4 Byte 追加；管理输出寄存器与 pack_data | capture_stop 优先进入 ST_DRAIN |

| ST_DRAIN | 停止条件出现 | 把剩余字节或零字节 EOC 装入输出寄存器；不再接收 ADC | EOC 完成 ready/valid 握手后进入 ST_IDLE |


capture_active 等于 state 不为 ST_IDLE，因此尾字没有真正离开模块前仍属于当前 Capture。capture_ready 还要求输出寄存器为空且下游 ready，避免新 Capture 的第一字与旧 EOC 混叠。

## 5.2 配置锁存

配置只在以下分支锁存：

if (capture_start && capture_ready) begin
    active_two_channel           <= cfg_two_channel;
    active_single_channel_select <= cfg_single_channel_select;
    active_capture_id            <= cfg_capture_id;
end

运行过程中格式不能改变，因为同一 256 bit 字内的采样粒度、valid_bytes 到 sample-time 的换算、后续 CRC 和描述符均依赖同一模式。活动期外部配置变化只置 config_change_sticky，不会改变锁存值。

## 5.3 两级弹性缓存

| 信号 | 语义 | 何时改变 |

| m_axis_tdata/tvalid | 第一级输出寄存器 | 有完整字、尾字或 EOC 可发送且 output_free=1 时装载 |

| pack_data | 第二级正在组装的字 | 每次接受样本后追加；转入输出寄存器后清零 |

| pack_byte_count | pack_data 已占用字节数 | 双通道每拍加 4，单通道每拍加 2 |

| pack_full_pending | 第二级已经完整 32 Byte，但第一级正受反压 | 第一级腾空后转移并清零 |

| output_take | m_axis_tvalid 且 m_axis_tready | 表示本拍下游实际取走输出 |

| output_free | 输出寄存器为空或本拍将被取走 | 允许同一沿完成旧字取走和新字装载 |

| eoc_loaded | DRAIN 已经生成一次 EOC | EOC 反压期间防止重复生成 |


pack_with_sample 是组合预览：先复制 pack_data，再把本拍选中样本写入 pack_byte_count×8 对应位置。双通道选择 {ch1_ext,ch0_ext}，单通道只追加所选通道的低 16 bit。

## 5.4 ST_DRAIN 和 pack_full_pending 不能删除

没有 ST_DRAIN 时，capture_stop 可能让状态立即回到 IDLE：未满 256 bit 的尾字没有消费者，或零字节 EOC 尚未握手就允许下一次 START，两个 Capture 会失去清晰边界。

没有 pack_full_pending 时，若第一级输出寄存器 stall，而 pack_data 又刚好凑满第二个字，后续样本会覆盖完整第二字的末尾或被无记录地丢弃。当前实现最多缓存“一个正在输出的字 + 一个完整 pending 字”；两级都满后继续出现 adc_valid 才进入明确丢数边界。

## 5.5 诊断计数与 sticky

| 信号 | 单位 | 清除条件 | 含义 |

| accepted_sample_times | 数据时刻 | 复位或合法新 Capture | 成功纳入组包的数据时刻数；双通道同拍两路仍计 1 |

| dropped_sample_times | 数据时刻 | 复位或合法新 Capture | 两级缓存均占用时仍到达的 adc_valid 数 |

| overflow_sticky | 位 | 复位或合法新 Capture | 丢数或 Packer 未 ready 时过早 START 曾发生 |

| config_change_sticky | 位 | 复位或合法新 Capture | 活动期模式或 Capture ID 与锁存值不一致 |


### adc_channel_packer 架构、接口与时序

源码：rtl/adc_channel_packer.sv。模块定位：把不可反压的12 bit ADC样点按锁存配置扩展为16 bit并装入256 bit字，利用输出寄存器和pending寄存器吸收短时stall。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 5-1A  adc_channel_packer 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| capture_start/stop与配置 adc_valid + CH0/CH1 | 配置锁存/样点选择与符号扩展 pack_data装填 output寄存器 + pack_full_pending IDLE/ACTIVE/DRAIN | 256 bit + valid_bytes + EOC active/ready accepted/dropped/sticky诊断 |


图 5-1B  adc_channel_packer 顶层架构图（电路/Visio风格重绘）

### 图 5-1A/5-1B 详细文字说明

Capture START只在IDLE且capture_ready时锁存配置。双通道每个数据时刻写入4 Byte，单通道写入2 Byte；运行期间外部配置变化只置config_change_sticky，不改变本次数据格式。

output寄存器是标准ready/valid发送级；pack_full_pending是第二级弹性缓存。当output因stall占用而pack_data又装满时，完整字先进入pending，避免立即丢失。

ST_DRAIN在STOP后禁止接收新ADC样点，但继续把部分尾字和EOC送出。没有DRAIN会过早回到IDLE，没有pending会在连续满字遇到下游stall时覆盖数据。

表 5-1  adc_channel_packer 接口信号列表（24项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| ADC数据/诊断 | adc_clk | I | 1 | adc_clk/写侧 | ADC采样时钟，采样接收和打包状态机均在此域运行 |

| ADC数据/诊断 | adc_rst_n | I | 1 | adc_clk/写侧 | ADC域低有效异步复位 |

| Capture控制 | capture_start | I | 1 | adc_clk | 新Capture启动脉冲，仅在capture_ready=1时接受 |

| Capture控制 | capture_stop | I | 1 | adc_clk | 当前Capture停止请求，优先于同拍adc_valid |

| Capture配置 | cfg_two_channel | I | 1 | adc_clk | 待锁存模式：1=双通道，0=单通道 |

| Capture配置 | cfg_single_channel_select | I | 1 | adc_clk | 单通道模式选择：0=CH0，1=CH1 |

| Capture配置 | cfg_capture_id | I | 63:0 | adc_clk | 软件分配的Capture编号，随START锁存 |

| ADC数据/诊断 | adc_valid | I | 1 | adc_clk | 本拍两路ADC输入有效；源端不能接受反压 |

| ADC数据/诊断 | adc_ch0 | I | 11:0 | adc_clk | 通道0原始12 bit采样值 |

| ADC数据/诊断 | adc_ch1 | I | 11:0 | adc_clk | 通道1原始12 bit采样值 |

| 输出流 | m_axis_tdata | O | 255:0 | adc_clk | 打包后的256 bit数据，低位字节先写 |

| 输出流 | m_axis_valid_bytes | O | 5:0 | adc_clk | 本传输真实字节数，取值0～32 |

| 输出流 | m_axis_end_of_capture | O | 1 | adc_clk | 本传输是Capture末尾标记 |

| 输出流 | m_axis_tvalid | O | 1 | adc_clk | 输出寄存器内容有效 |

| 输出流 | m_axis_tready | I | 1 | adc_clk | 下游CDC FIFO可接收；与tvalid共同完成握手 |

| Capture控制 | capture_active | O | 1 | adc_clk | 非IDLE即为1，表示Capture尚未完全排空 |

| Capture控制 | capture_ready | O | 1 | adc_clk | 可以无歧义接受下一次START |

| Capture配置 | active_two_channel | O | 1 | adc_clk | 本次Capture已锁存的单双通道模式 |

| Capture配置 | active_single_channel_select | O | 1 | adc_clk | 本次Capture已锁存的单通道选择 |

| Capture配置 | active_capture_id | O | 63:0 | adc_clk | 本次Capture已锁存的编号 |

| 状态/诊断 | overflow_sticky | O | 1 | adc_clk | 溢出粘滞位：置1后保持到复位或下一次Capture清除 |

| 状态/诊断 | config_change_sticky | O | 1 | adc_clk | 运行中配置变化粘滞位 |

| 状态/诊断 | accepted_sample_times | O | 63:0 | adc_clk | 已成功纳入打包的数据时刻数 |

| 状态/诊断 | dropped_sample_times | O | 63:0 | adc_clk | 因两级缓存均占用而丢弃的数据时刻数 |


接口表读法：按RTL模块头顺序列出，共24项；接口分组为ADC数据/诊断5项、Capture控制4项、Capture配置6项、输出流5项、状态/诊断4项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 5-1C  adc_channel_packer 关键时序图（高/低电平对齐）

| 信号 / 时间 → | A0 | A1 | A2 | A3 | A4 | A5 |

| m_axis_tvalid | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |

| m_axis_tready | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| output_take | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |

| pack字装满 | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| pack_full_pending | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| capture_stop | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ |

| 状态 | ACTIVE | ACTIVE | DRAIN | DRAIN | IDLE | IDLE |


### 图 5-1C 详细文字说明

A1到A2满足tvalid=1且tready=0，构成stall。输出寄存器的tdata、valid_bytes和EOC必须保持不变；同时新装满的数据字进入pack_full_pending并保持。

A3下游恢复后，原输出字完成握手，pending字被提升到输出级。capture_stop已使状态进入DRAIN，但不会丢弃缓存数据。

A4最后一个带EOC的输出字握手后才能回IDLE并拉高capture_ready。accepted计数记录被纳入打包的数据时刻，dropped只在两级缓存均无法接收而adc_valid仍到来时增加。

# 6. adc_capture_limit_controller 详细设计

## 6.1 Toggle CDC 和多位上下文

START/STOP 是系统域单拍脉冲。若直接两级同步，一个窄脉冲可能完全落在 ADC 时钟采样间隙。Toggle 方法把每个事件编码成电平翻转：源域每来一次脉冲翻转一次，目的域比较 sync 与 seen，不同即代表一个未消费事件。

| 方向 | 事件/电平 | 第一级 | 第二级 | 已消费记忆 |

| sys→adc | START Toggle | start_meta_adc | start_sync_adc | start_seen_adc |

| sys→adc | STOP Toggle | stop_meta_adc | stop_sync_adc | stop_seen_adc |

| adc→sys | Done Toggle | done_meta_sys | done_sync_sys | done_seen_sys |

| adc→sys | Cancel Toggle | cancel_meta_sys | cancel_sync_sys | cancel_seen_sys |

| adc→sys | Busy 电平 | busy_meta_sys | busy_sync_sys | 不需要 seen |


target_bytes_sys、模式和 Capture ID 是多位上下文，分别经过 meta/sync 两级采样。控制器检测到 START Toggle 后先进入 ST_CONTEXT，额外等待一拍再锁存这些多位值。前提是 FDMA 寄存器在请求处理期间保持上下文稳定；这不是任意异步多位总线的通用 CDC 方案。

## 6.2 五个状态

| 状态 | 意义 | 主要转移 |

| ST_IDLE | 无活动请求，等待 START | START 新值→ST_CONTEXT；若有 cancel_next_start_adc 则直接回送取消完成 |

| ST_CONTEXT | 给多位同步值额外稳定一拍 | 锁存模式、ID，计算目标数据时刻数→ST_WAIT_READY |

| ST_WAIT_READY | 等 Packer 输出和 CDC FIFO 均可开始 | packer_capture_ready→发一拍 START→ST_RUNNING |

| ST_RUNNING | 监视定长条件和手动 STOP | 计数达到目标或 STOP→ST_WAIT_IDLE |

| ST_WAIT_IDLE | Packer 正在排空尾字/EOC | packer_capture_active=0→翻转 Done→ST_IDLE |


## 6.3 START/STOP 乱序和提前取消

STOP 处理位于状态 case 之前，优先级高于普通状态推进：

| STOP 到达时状态 | 处理 |

| ST_CONTEXT/ST_WAIT_READY | Capture 尚未真正开始，直接产生 Done + Cancel，返回 IDLE |

| ST_RUNNING | 产生 manual_stop_adc，让 Packer 进入 DRAIN |

| ST_IDLE 且 START 已可见 | 同拍消费 START，并报告取消 |

| ST_IDLE 且 START 尚不可见 | 置 cancel_next_start_adc，拦截稍后到达的 START |


## 6.4 定长停止为何优先于同拍 adc_valid

双通道目标数据时刻数为 target_bytes / 4，单通道为 target_bytes / 2。capture_stop_adc 的定长条件是 ST_RUNNING、目标非零且 accepted 计数不小于目标。Packer 在 ST_ACTIVE 中先判断 capture_stop，再判断 adc_valid。因此达到目标后的下一采样沿会先停止，不会多收一拍。若 adc_valid 优先，Payload 会比软件 SIZE 多 2 或 4 Byte。

### adc_capture_limit_controller 架构、接口与时序

源码：rtl/adc_capture_limit_controller.sv。模块定位：跨sys_clk/adc_clk传递Capture上下文，并在ADC域实现等待Packer就绪、运行、定长停止、排空完成和提前取消。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 6-1A  adc_capture_limit_controller 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| sys_clk START/STOP target_bytes/模式/ID | 事件toggle与两级同步 多位上下文两级同步+额外等待 ST_IDLE/CONTEXT/WAIT_READY/RUN/WAIT_DRAIN | adc_clk capture_start/stop 锁存配置 local_done/cancelled/busy |


图 6-1B  adc_capture_limit_controller 顶层架构图（电路/Visio风格重绘）

### 图 6-1A/6-1B 详细文字说明

单拍START不能直接跨域，因此系统域先翻转start_toggle，ADC域用两级同步后检测异或变化。target_bytes、模式和capture_id是多位上下文，需先稳定，再经过两级同步，并在ST_CONTEXT额外等待一拍后统一锁存。

ST_WAIT_READY保证Packer真正可以接受新Capture后才发capture_start_adc；ST_RUN比较Packer已接受样点数与目标字节数，手动STOP或定长条件满足时拉高capture_stop_adc；ST_WAIT_DRAIN等Packer回到非活动状态。

停止判定优先于同拍adc_valid，避免超过目标长度一个数据时刻。若STOP早于实际启采，则走cancelled_pulse_sys，不伪造local_done。

表 6-1  adc_capture_limit_controller 接口信号列表（21项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | sys_clk | I | 1 | sys_clk/读侧 | FDMA寄存器所在系统时钟域 |

| 时钟/复位/使能 | sys_rst_n | I | 1 | clk对应域 | 系统域低有效同步复位 |

| 状态/诊断 | start_pulse_sys | I | 1 | sys_clk | 软件START写命令形成的单拍脉冲 |

| 状态/诊断 | stop_pulse_sys | I | 1 | sys_clk | 软件STOP写命令形成的单拍脉冲 |

| 状态/诊断 | target_bytes_sys | I | 63:0 | sys_clk | 本次Capture期望保存的Payload字节数 |

| 状态/诊断 | two_channel_sys | I | 1 | sys_clk | 软件配置的双通道模式 |

| 状态/诊断 | single_select_sys | I | 1 | sys_clk | 单通道模式下的通道选择 |

| Capture控制 | capture_id_sys | I | 63:0 | sys_clk | 软件配置的Capture编号 |

| 状态/诊断 | local_done_pulse_sys | O | 1 | sys_clk | ADC侧完整排空后返回系统域的单拍完成脉冲 |

| 状态/诊断 | cancelled_pulse_sys | O | 1 | sys_clk | 尚未启采即被STOP取消的单拍指示 |

| 状态/诊断 | controller_busy_sys | O | 1 | sys_clk | 同步到系统域的Capture控制忙状态 |

| ADC数据/诊断 | adc_clk | I | 1 | adc_clk/写侧 | Packer所在ADC采样时钟域 |

| ADC数据/诊断 | adc_rst_n | I | 1 | adc_clk/写侧 | ADC域低有效异步复位 |

| 状态/诊断 | packer_capture_ready | I | 1 | adc_clk | Packer可以接受新Capture |

| 状态/诊断 | packer_capture_active | I | 1 | adc_clk | Packer仍在采样或排空尾字 |

| 状态/诊断 | packer_accepted_sample_times | I | 63:0 | adc_clk | Packer实际接受的数据时刻数 |

| Capture控制 | capture_start_adc | O | 1 | adc_clk | 送Packer的单拍START |

| Capture控制 | capture_stop_adc | O | 1 | adc_clk | 手动或定长条件形成的停止电平 |

| Capture配置 | cfg_two_channel_adc | O | 1 | adc_clk | 已在ADC域锁存的单双通道配置 |

| Capture配置 | cfg_single_select_adc | O | 1 | adc_clk | 已在ADC域锁存的单通道选择 |

| Capture配置 | cfg_capture_id_adc | O | 63:0 | adc_clk | 已在ADC域锁存的Capture编号 |


接口表读法：按RTL模块头顺序列出，共21项；接口分组为时钟/复位/使能2项、状态/诊断11项、Capture控制3项、ADC数据/诊断2项、Capture配置3项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 6-1C  adc_capture_limit_controller 关键时序图（高/低电平对齐）

| 信号 / 时间 → | A0 | A1 | A2 | A3 | A4 | A5 | A6 |

| start_toggle变化 | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| 控制状态 | IDLE | CTX | CTX | WAIT | RUN | RUN | DRAIN |

| 上下文同步有效 | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| capture_start_adc | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| stop条件 | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ |

| packer_active | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |

| local_done事件 | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ |


### 图 6-1C 详细文字说明

A1检测到toggle事件后进入ST_CONTEXT，但不立即使用多位配置；到同步数据稳定并额外等待后，才进入WAIT并在Packer ready时产生单拍START。

A5的stop条件可能来自软件STOP或定长计数。capture_stop_adc维持到Packer完成尾字排空，不能只给单拍，否则Packer可能在反压时漏掉停止请求。

local_done_sys是ADC域完成事件再次通过toggle同步回系统域形成的脉冲，其延迟不固定，图中只描述因果关系。

# 7. 329 bit CDC FIFO 与反压链

## 7.1 位域

| 位段 | 宽度 | 含义 |

| [328] | 1 | EOC |

| [327:322] | 6 | valid_bytes，范围 0～32 |

| [321] | 1 | 已锁存双通道模式 |

| [320] | 1 | 已锁存单通道选择 |

| [319:256] | 64 | 已锁存 Capture ID |

| [255:0] | 256 | ADC Payload 数据字 |


把 66 bit 上下文与数据放在同一个 FIFO 表项中，是为了保证首字不会先于模式和 Capture ID 到达系统域。旧的“数据走 FIFO、上下文单独两级同步”会在 Capture 边界存在竞态。

## 7.2 三层 ready/valid

| 层 | valid 来源 | ready 来源 | stall 时必须保持的内容 |

| Packer 输出寄存器 | m_axis_tvalid | 异步 FIFO s_axis_tready | data、valid_bytes、EOC |

| 异步 FIFO 读侧 | 非empty且非rd_rst_busy | ddr_init_done 且 writer_stream_ready | FWFT 队首 329 bit 条目 |

| Writer 输入 | CDC FIFO m_axis_tvalid | Writer s_axis_tready | 队首条目由 XPM 保持 |


异步 FIFO 的写侧 ready 为非full且非wr_rst_busy。短时停顿先由 Beat FIFO、Segment 环和 ADC CDC FIFO吸收。ADC 源本身不能被反压：当 Packer 的输出寄存器和 pack_data 都占用时，继续到来的 adc_valid 只能计入 dropped。FIFO 容量只能延长允许停顿时间，不能把不可反压数据源变成无损无限缓存。

### axis_async_fifo 架构、接口与时序

源码：rtl/axis_async_fifo.sv。模块定位：基于XPM异步FIFO把329 bit复合条目从adc_clk安全传到sys_clk，并用ready/valid包装复位忙、满和空条件。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 7-1A  axis_async_fifo 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| s_clk域329 bit tdata s_valid/s_ready | XPM async FIFO 写指针/读指针跨域同步 FWFT读出 full/prog_full/used_count | m_clk域329 bit tdata m_valid/m_ready 水位诊断 |


图 7-1B  axis_async_fifo 顶层架构图（电路/Visio风格重绘）

### 图 7-1A/7-1B 详细文字说明

写侧只有s_axis_tvalid与s_axis_tready同时为1才写FIFO；s_ready由非full且写复位不忙共同决定。读侧采用FWFT，非empty且读复位不忙时直接给出m_axis_tvalid。

329 bit是一个不可拆分条目，包含256 bit数据、6 bit有效字节数、EOC、模式、Capture ID等伴随信息。所有字段必须通过同一个FIFO跨域，不能分别同步后再拼接。

prog_full是提前水位告警，不直接阻止写入；full才使s_ready拉低。由于ADC源不能反压，持续full最终会在Packer侧形成丢样。

表 7-1  axis_async_fifo 接口信号列表（15项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 状态/诊断 | s_clk | I | 1 | adc_clk/写侧 | 写侧时钟，本项目中为adc_clk |

| 状态/诊断 | s_rst_n | I | 1 | adc_clk/写侧 | 写侧低有效复位 |

| 输入流 | s_axis_tdata | I | DATA_WIDTH-1:0 | s_clk | 写侧待跨域条目 |

| 输入流 | s_axis_tvalid | I | 1 | s_clk | 写侧条目有效 |

| 输入流 | s_axis_tready | O | 1 | s_clk | FIFO写侧可接受，含复位忙门控 |

| 状态/诊断 | m_clk | I | 1 | sys_clk/读侧 | 读侧时钟，本项目中为sys_clk |

| 状态/诊断 | m_rst_n | I | 1 | sys_clk/读侧 | 读侧低有效复位 |

| 输出流 | m_axis_tdata | O | DATA_WIDTH-1:0 | m_clk | FWFT模式下的队首条目 |

| 输出流 | m_axis_tvalid | O | 1 | m_clk | 队首有效且读侧不在复位忙 |

| 输出流 | m_axis_tready | I | 1 | m_clk | 下游已准备接收队首条目 |

| 状态/诊断 | full | O | 1 | s_clk | 写时钟域满标志 |

| 状态/诊断 | empty | O | 1 | m_clk | 读时钟域空标志 |

| 状态/诊断 | prog_full | O | 1 | s_clk | 距满16项时提前告警 |

| 状态/诊断 | wr_used_count | O | ADDR_WIDTH:0 | s_clk | 写侧观察到的占用条目数 |

| 状态/诊断 | rd_used_count | O | ADDR_WIDTH:0 | m_clk | 读侧观察到的占用条目数 |


接口表读法：按RTL模块头顺序列出，共15项；接口分组为状态/诊断9项、输入流3项、输出流3项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 7-1C  axis_async_fifo 关键时序图（高/低电平对齐）

| 信号 / 时间 → | T0 | T1 | T2 | T3 | T4 | T5 |

| s_axis_tvalid | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| s_axis_tready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| FIFO写入 | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| m_axis_tvalid | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |

| m_axis_tready | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| m_axis_tdata | 空 | 同步 | D0 | D0 | D1 | 空 |

| FIFO读出 | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |


### 图 7-1C 详细文字说明

写侧W0/W1接受D0和D1后，读指针域要经过异步FIFO内部同步延迟才在R2看到m_valid，延迟不是固定一拍。

R2发生stall，FWFT队首D0必须稳定。R3握手后队首推进为D1；伴随字段与tdata作为同一329 bit字一起保持和推进。

跨域used_count是各自时钟域对占用量的近似同步观察，适合诊断水位，不应用作跨域精确事件计数。

# 8. adc_ddr_segment_writer 详细设计

## 8.1 Writer 八状态

| 状态 | 进入条件 | 主要输出/动作 | 退出条件 |

| WR_IDLE | 复位、非尾段描述符完成或 Commit 描述符完成 | 非空首字请求 alloc；零字节 EOC 直接启动 Commit job | alloc 握手→WR_FILL；空 Capture→WR_COMMIT_FILL |

| WR_FILL | 已获得 Segment | 接收真实流字，累计 Payload、样本数和 CRC | Segment 满或 EOC→WR_PAD |

| WR_PAD | 最终真实字已接受 | 向 Beat FIFO 推零直到目标 DMA beat 数 | queued_beats等于job_target_beats→WR_WAIT_JOB |

| WR_WAIT_JOB | 生产端已结束 | 等 AXI job 最终 B 响应 | job_done_pulse→WR_DESC |

| WR_DESC | Payload job 完成 | 保持 fill 描述符 | Manager 握手；尾段→Commit，非尾段→IDLE |

| WR_COMMIT_FILL | 空 Capture 或尾段描述符已交付 | 依次生成 128 个 Commit beat | 全部入 FIFO→WR_COMMIT_WAIT |

| WR_COMMIT_WAIT | Commit 页生产结束 | 等 Commit job 最终 B 响应 | job_done_pulse→WR_COMMIT_DESC |

| WR_COMMIT_DESC | Commit 页 DDR 写完成 | 保持 commit 上下文 | Scheduler 握手→清 Capture 上下文→IDLE |


## 8.2 AXI 四状态

| 状态 | 意义 | 输出 | 转移 |

| AXI_IDLE | 等至少一个完整 Burst | 无 AW/W | job_active且enough_for_burst→AXI_AW |

| AXI_AW | 保持当前 Burst 地址 | AWVALID=1 | AWREADY→AXI_W |

| AXI_W | 从 Beat FIFO 发送 16 拍 | WVALID、全 WSTRB、末拍 WLAST | 每拍 W 握手；末拍→AXI_B |

| AXI_B | 等唯一写响应 | BREADY=1 | BVALID 后记录错误并回 IDLE |


当前实现严格一次只有一个 Burst 在途。只有 FIFO 至少存有 BURST_BEATS 个 beat 才发 AW，避免 W 通道开始后因生产端暂时无数据而饿死。

## 8.3 alloc 是项目内所有权握手

assign alloc_valid = (writer_state == WR_IDLE) && s_axis_tvalid &&
                     stream_format_valid && (s_axis_valid_bytes != 0);

Writer 是申请方，Manager 是分配方。alloc_valid 与 alloc_ready 同拍为 1 时，Writer 锁存 segment_id/tag/ddr_addr，Manager 同拍把槽位从 FREE 改成 FILLING。非空首字在 WR_IDLE 期间 s_axis_tready=0，因此不会在 alloc 之前被消费；FIFO 会保持队首。握手后的下一拍 Writer 已进入 WR_FILL，该首字才可能完成流握手。

这不是 AXI Master/Slave：没有 AW、W、B，也没有标准总线地址相位。它只是一组项目自定义的 ready/valid 信号。

## 8.4 s_axis_tready 逐条件解释

assign s_axis_tready =
    ((writer_state == WR_IDLE) && s_axis_tvalid &&
     stream_format_valid && (s_axis_valid_bytes == 0) &&
     s_axis_end_of_capture) ||
    ((writer_state == WR_FILL) && !beat_fifo_full &&
     stream_format_valid &&
     ((segment_payload_count + s_axis_valid_bytes) <= SEGMENT_BYTES));

| 门控 | 设计目的 | 删除后的具体错误 |

| WR_IDLE 只接受零字节 EOC | 空 Capture 无需浪费 Payload Segment | 若普通数据在 IDLE ready，首字会在 alloc 前出队，数据丢失 |

| WR_FILL | 只有已持有 Segment 时才能接收 Payload | 其他状态接收会让计数、CRC、FIFO和描述符生命周期脱节 |

| 非beat_fifo_full | Beat FIFO 必须有空间 | 满时继续接收会让 XPM 抑制写入，但计数/CRC仍前进，DDR少数据 |

| stream_format_valid | 中间字必须32 Byte；尾字0～32 Byte；满足2/4 Byte粒度 | 删除后 WSTRB 全1仍写32 Byte，地址推进与真实字节计数不一致 |

| 累计不超过SEGMENT_BYTES | 当前字不能跨越固定Segment边界 | 删除后写入下一个槽位地址区，但所有权仍属于当前槽位 |

| 零字节必须EOC | 只允许有语义的空结束条目 | 删除后零字节普通条目可能让状态机无数据推进 |


## 8.5 流格式、CRC 和补零

真实输入规则：非末字必须是 32 Byte；末字允许 0～32 Byte；双通道字节数为 4 的倍数，单通道为 2 的倍数。格式错误置 stream_format_error_sticky，该信号当前只在复位时清除。

CRC32C 使用反射多项式 0x82F63B78，初值全 1，最终取反。函数只遍历 valid_bytes 个低位字节，因此短尾字高位和 4 KiB 对齐零拍不进入 CRC。

align_4k 产生 DMA 字节数。Beat FIFO 中补入的零拍使 WSTRB 可以始终全 1，同时保证 DDR 中尾部是确定的 0。payload_bytes 保持真实长度，dma_bytes 表示写入长度。

## 8.6 queued_beats、job_target_beats 和最终 B 响应

queued_beats 是当前 job 自开始以来推入 Beat FIFO 的累计拍数，不是 FIFO 当前占用量。job_target_beats 是最终要求写入 DDR 的拍数。AXI 引擎用 job_beats_written 统计 W 握手数。

即使最后一个 W beat 已握手，也不能立即产生描述符，因为 AXI Slave 仍可能返回错误 B 响应。只有 job_finalized=1、job_beats_written等于job_target_beats且最后一个 BVALID 到达时，job_done_pulse 才出现。删除 B 等待会把实际失败的 DDR 数据误标成 READY 并提交 SSD。

### sync_fifo 架构、接口与时序

源码：rtl/sync_fifo.sv。模块定位：Writer内部同一sys_clk域的256 bit Beat FIFO，解耦复合流整理/补零与AXI Burst发送。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 8-1A  sync_fifo 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| Writer生成的Payload/零填充Beat wr_en | XPM同步FIFO（FWFT） 满/空门控 used_count | AXI W通道队首dout rd_en 排队beat数量 |


图 8-1B  sync_fifo 顶层架构图（电路/Visio风格重绘）

### 图 8-1A/8-1B 详细文字说明

该FIFO不是CDC，读写都在Writer的clk域。上游每生成一个完整256 bit beat并且非full时写入，AXI引擎在W握手时读取。

FWFT使dout在非empty时直接呈现队首，适合保持m_axi_wdata。AXI W发生stall时rd_en必须为0，队首不推进，wdata与wlast保持稳定。

used_count参与queued_beats计算，帮助Writer判断已经生成但尚未完成发送的数据量；它不是Payload真实字节计数。

表 8-1  sync_fifo 接口信号列表（9项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | clk | I | 1 | clk | FIFO读写共用时钟 |

| 时钟/复位/使能 | rst_n | I | 1 | clk对应域 | 低有效复位 |

| 状态/诊断 | din | I | DATA_WIDTH-1:0 | clk | 写入条目 |

| 状态/诊断 | wr_en | I | 1 | clk | 写请求，满时由包装器抑制 |

| 状态/诊断 | rd_en | I | 1 | clk | 读请求，空时由包装器抑制 |

| 状态/诊断 | dout | O | DATA_WIDTH-1:0 | clk | FWFT队首数据 |

| 状态/诊断 | full | O | 1 | clk | FIFO无空闲条目 |

| 状态/诊断 | empty | O | 1 | clk | FIFO没有可读条目 |

| 状态/诊断 | used_count | O | ADDR_WIDTH:0 | clk | 当前占用条目数，供Writer计算排队beat |


接口表读法：按RTL模块头顺序列出，共9项；接口分组为时钟/复位/使能2项、状态/诊断7项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 8-1C  sync_fifo 关键时序图（高/低电平对齐）

| 信号 / 时间 → | C0 | C1 | C2 | C3 | C4 |

| wr_en | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| din | B0 | B1 | 空 | 空 | 空 |

| empty | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ |

| dout | B0 | B0 | B0 | B1 | 空 |

| rd_en | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |

| 水位 | 一拍 | 两拍 | 一拍 | 空 | 空 |


### 图 8-1C 详细文字说明

C0写入B0后FIFO进入非空，FWFT队首直接为B0。C1继续写B1，但读侧未握手，dout仍保持B0。

C2的rd_en对应AXI W握手，队首在下一观察点推进B1；C3再次读取后empty置1。满时包装器会抑制写使能，上游Writer必须通过tready/状态门控停住。

图中的used_count以当前实现的同步FIFO观察语义为准，用于相对水位和排队计算，不应与外部CDC FIFO水位混淆。

## 8.7 fill 描述符字段

| 字段 | 来源 | 单位/编码 | 有效期 | 消费者 |

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

### adc_ddr_segment_writer 架构、接口与时序

源码：rtl/adc_ddr_segment_writer.sv。模块定位：为每个Payload Segment申请DDR槽位，接收复合流、计算CRC和元数据、4 KiB补零，驱动AXI写Burst并生成fill及Commit上下文。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 8-2A  adc_ddr_segment_writer 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| 329 bit复合流 Manager alloc返回 DDR B响应 | Writer八状态 CRC/字节/样点/序号累计 补零与Commit页生成 Beat FIFO AXI AW/W/B四状态 | Manager fill描述符 Scheduler commit上下文 DDR AXI Master 错误与计数 |


图 8-2B  adc_ddr_segment_writer 顶层架构图（电路/Visio风格重绘）

### 图 8-2A/8-2B 详细文字说明

首个非空Payload字只触发alloc_valid，不能在分配前被消费。alloc握手取得segment_id、generation Tag和DDR基地址后，Writer进入WR_FILL，s_axis_tready才允许真实数据入队。

Writer主状态机负责Segment边界、格式、CRC、补零和描述符；AXI子状态机负责把Beat FIFO转成最多16拍的Burst并等待B响应。两者通过queued_beats、job_target_beats和最终B响应协同。

fill_payload_bytes是真实ADC字节数，fill_dma_bytes是向4 KiB对齐后的传输长度。fill_valid只有最终B响应已经覆盖全部目标beat后才成立；Commit页复用同一AXI写引擎，但不经过Manager槽位。

表 8-2  adc_ddr_segment_writer 接口信号列表（55项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | clk | I | 1 | clk | Writer、FIFO和AXI写引擎的系统时钟 |

| 时钟/复位/使能 | rst_n | I | 1 | clk对应域 | 低有效同步复位 |

| 输入流 | s_axis_tdata | I | 255:0 | clk | Packer输出的数据字，低位字节有效 |

| 输入流 | s_axis_valid_bytes | I | 5:0 | clk | 当前字真实字节数0～32 |

| 输入流 | s_axis_end_of_capture | I | 1 | clk | 当前字结束本次Capture |

| 输入流 | s_axis_tvalid | I | 1 | clk | 输入复合流有效 |

| 输入流 | s_axis_tready | O | 1 | clk | Writer当前可以无损接收该输入字 |

| Capture配置 | cfg_two_channel | I | 1 | clk | 本次Capture锁存的单双通道模式 |

| Capture配置 | cfg_single_channel_select | I | 1 | clk | 本次Capture锁存的单通道选择 |

| Capture配置 | cfg_capture_id | I | 63:0 | clk | 本次Capture编号 |

| alloc握手 | alloc_valid | O | 1 | clk | Writer有首个非空数据字，需要FREE槽位 |

| alloc握手 | alloc_ready | I | 1 | clk | Manager已有可分配槽位 |

| alloc握手 | alloc_segment_id | I | $clog2(SEGMENT_COUNT)-1:0 | clk | Manager返回的槽位编号 |

| alloc握手 | alloc_tag | I | 15:0 | clk | Manager返回的{generation,segment_id} |

| alloc握手 | alloc_ddr_addr | I | AXI_ADDR_WIDTH-1:0 | clk | Manager返回的槽位DDR基地址 |

| fill描述符 | fill_valid | O | 1 | clk | 项目内Segment描述符有效 |

| fill描述符 | fill_ready | I | 1 | clk | Manager可以接收描述符 |

| fill描述符 | fill_segment_id | O | $clog2(SEGMENT_COUNT)-1:0 | clk | 本描述符对应的槽位编号 |

| fill描述符 | fill_tag | O | 15:0 | clk | 分配时取得的代数Tag |

| fill描述符 | fill_error | O | 1 | clk | 本Segment任一DDR写响应失败 |

| fill描述符 | fill_payload_bytes | O | 63:0 | clk | 真实ADC Payload字节数 |

| fill描述符 | fill_dma_bytes | O | 31:0 | clk | 补零后的4 KiB对齐传输字节数 |

| fill描述符 | fill_sequence | O | 63:0 | clk | Capture内递增的Segment序号 |

| fill描述符 | fill_crc32c | O | 31:0 | clk | 真实Payload CRC32C |

| fill描述符 | fill_capture_id | O | 63:0 | clk | Segment所属Capture编号 |

| fill描述符 | fill_sample_count | O | 63:0 | clk | Segment内数据时刻数 |

| fill描述符 | fill_two_channel | O | 1 | clk | Segment使用的单双通道格式 |

| fill描述符 | fill_single_channel_select | O | 1 | clk | Segment单通道选择 |

| fill描述符 | fill_capture_last | O | 1 | clk | Segment是否为Capture最后一段 |

| Commit | commit_valid | O | 1 | clk | Commit页及其汇总上下文已准备好 |

| Commit | commit_ready | I | 1 | clk | Scheduler已锁存Commit上下文 |

| Commit | commit_ddr_addr | O | AXI_ADDR_WIDTH-1:0 | clk | Commit页固定DDR地址 |

| Commit | commit_dma_bytes | O | 31:0 | clk | Commit页固定传输长度4 KiB |

| Commit | commit_capture_id | O | 63:0 | clk | Commit页所属Capture编号 |

| Commit | commit_sample_count | O | 63:0 | clk | Capture累计数据时刻数 |

| Commit | commit_payload_bytes | O | 63:0 | clk | Capture累计真实Payload字节数 |

| Commit | commit_error | O | 1 | clk | Commit页DDR写失败指示 |

| AXI主接口 | m_axi_awaddr | O | AXI_ADDR_WIDTH-1:0 | clk | 当前Burst起始DDR地址 |

| AXI主接口 | m_axi_awlen | O | 7:0 | clk | Burst拍数减1 |

| AXI主接口 | m_axi_awsize | O | 2:0 | clk | 每拍字节数的log2 |

| AXI主接口 | m_axi_awburst | O | 1:0 | clk | 固定INCR Burst |

| AXI主接口 | m_axi_awvalid | O | 1 | clk | 写地址通道有效 |

| AXI主接口 | m_axi_awready | I | 1 | clk | DDR互连接受写地址 |

| AXI主接口 | m_axi_wdata | O | AXI_DATA_WIDTH-1:0 | clk | Beat FIFO队首数据 |

| AXI主接口 | m_axi_wstrb | O | AXI_DATA_WIDTH/8-1:0 | clk | 全字节写使能，尾部靠数据补零 |

| AXI主接口 | m_axi_wlast | O | 1 | clk | 固定Burst最后一拍 |

| AXI主接口 | m_axi_wvalid | O | 1 | clk | 写数据通道有效 |

| AXI主接口 | m_axi_wready | I | 1 | clk | DDR互连接受写数据 |

| AXI主接口 | m_axi_bresp | I | 1:0 | clk | AXI写响应，00为OKAY |

| AXI主接口 | m_axi_bvalid | I | 1 | clk | 写响应有效 |

| AXI主接口 | m_axi_bready | O | 1 | clk | Writer正在等待写响应 |

| 状态/诊断 | axi_error_sticky | O | 1 | clk | 任一非OKAY写响应的粘滞位 |

| 状态/诊断 | stream_format_error_sticky | O | 1 | clk | 非法复合流格式粘滞位 |

| 状态/诊断 | accepted_sample_times | O | 63:0 | clk | 当前Capture累计接收的数据时刻数 |

| 状态/诊断 | sequence_counter | O | 63:0 | clk | 已向Manager提交的Segment序号计数 |


接口表读法：按RTL模块头顺序列出，共55项；接口分组为时钟/复位/使能2项、输入流5项、Capture配置3项、alloc握手5项、fill描述符14项、Commit8项、AXI主接口14项、状态/诊断4项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 8-2C  adc_ddr_segment_writer 关键时序图（高/低电平对齐）

| 信号 / 时间 → | S0 | S1 | S2 | S3 | S4 | S5 | S6 |

| s_axis_tvalid | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| Writer状态 | WAIT | ALLOC | FILL | FILL | PAD | AXI_B | DESC |

| alloc_valid | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| alloc_ready | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| s_axis_tready | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| 输入首字握手 | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| AXI最终B响应 | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ |

| fill握手 | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ |


### 图 8-2C 详细文字说明

S0首个非空字已经有效，但没有槽位时tready必须为0，发送方保持整个复合条目。S1完成alloc后仍不在同拍消费首字，S2进入WR_FILL才握手，避免地址和Tag尚未锁存就写数据。

中间省略真实数据、4 KiB补零和多个AXI Burst。只有最后一个Burst的B响应成功，job完成计数才覆盖所有目标beat，随后才能进入描述符状态。

若FIFO满、复合格式非法、输入越过Segment边界或Writer不在接收状态，s_axis_tready都必须拉低。B响应错误置axi_error_sticky并在描述符中携带fill_error。

# 9. segment_buffer_manager 详细设计

## 9.1 它管理什么，不管理什么

Manager 管理的是 8 个固定 DDR 槽位的所有权、代数和描述符表。它不产生 AXI 地址通道，不发送 WDATA，不读取 DDR，也不创建 NVMe SQE。实际写 DDR 的是 Writer；实际提交 SSD 请求的是 Scheduler/Backend。

## 9.2 生命周期

| 状态 | 所有者/含义 | 正常下一状态 | 异常下一状态 |

| SEG_FREE | 无人持有，可分配 | alloc→SEG_FILLING | 非法 Completion 可置 sticky |

| SEG_FILLING | Writer 正在填充 | 合法 fill→SEG_READY | fill错误/Tag错→SEG_ERROR_HOLD |

| SEG_READY | 数据完整，等待Scheduler | ready握手→SEG_INFLIGHT | 非法Completion→SEG_ERROR_HOLD |

| SEG_INFLIGHT | SSD请求在途，DDR不可覆盖 | 成功Completion→SEG_FREE | 失败Completion→SEG_ERROR_HOLD |

| SEG_ERROR_HOLD | 数据/状态不可信，隔离 | 仅复位→SEG_FREE | 保持 |


FREE 和 READY 均从索引 0 向上扫描，选择最低编号。该策略确定、易验证，但不是时间公平或优先级调度。

## 9.3 Tag 与 generation

默认 8 个 Segment 时 SEGMENT_ID_W=3，GEN_W=13：

Tag[15:3] = generation
Tag[2:0]  = segment_id

每次 alloc 使用“当前 generation + 1”产生 Tag，并在握手时把新 generation 写回表项。旧代 Completion 即使 segment_id 相同，也不能与新代 Tag 相等，因而不能释放已经重新分配的数据。

当前代码对迟到 Completion 有两种结果：

| 情况 | 现有处理 |

| Tag 与所有 tag_table 都不匹配 | 只置 state_error_sticky；由于无法可靠定位槽位，不猜测并修改某一状态 |

| Tag 命中表项，但表项不是 INFLIGHT | 置 state_error_sticky，命中槽位进入 ERROR_HOLD |

| Tag 命中 INFLIGHT，status=0 | 槽位回到 FREE |

| Tag 命中 INFLIGHT，status非0 | 槽位进入 ERROR_HOLD |


## 9.4 四组接口握手

| 接口 | 发起方→接收方 | 握手时的状态变化 |

| alloc | Writer→Manager | 最低编号 FREE→FILLING；代数加1；写 Tag |

| fill | Writer→Manager | 合法 FILLING→READY并写描述符；错误→ERROR_HOLD |

| ready | Manager→Scheduler | Scheduler请求真正被后端接受时 READY→INFLIGHT |

| completion | Scheduler→Manager | 成功 INFLIGHT→FREE；失败→ERROR_HOLD |


## 9.5 代码映射

| 位置 | 相关代码 |

| Writer | alloc_valid/ready/id/tag/ddr_addr；fill_valid/ready及所有字段 |

| Manager | first_free、first_ready、state数组、generation数组、十组描述符表 |

| Scheduler | ready_valid/ready_accept；manager_completion信号组 |

| Pipeline Top | u_segment_writer、u_segment_manager、u_nvme_scheduler 之间的同名 wires |


### segment_buffer_manager 架构、接口与时序

源码：rtl/segment_buffer_manager.sv。模块定位：管理固定DDR Segment槽位的所有权、generation Tag和描述符表，在Writer与Scheduler之间执行FREE→FILLING→READY→INFLIGHT→FREE生命周期。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 9-1A  segment_buffer_manager 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| Writer alloc/fill Scheduler completion | 槽位状态数组 generation数组 描述符RAM/寄存器阵列 最低编号FREE/READY扫描 Tag与状态检查 | Writer alloc返回 Scheduler ready描述符 segment_states/free_count state_error_sticky |


图 9-1B  segment_buffer_manager 顶层架构图（电路/Visio风格重绘）

### 图 9-1A/9-1B 详细文字说明

Manager不是AXI Master，也不搬运Payload。它保存每个固定DDR槽位的状态和描述符，alloc时把最低编号FREE槽位置为FILLING，fill成功后置READY，Scheduler接受后置INFLIGHT，匹配Completion后才回FREE。

Tag由generation和segment_id组成。每次重新分配同一槽位先递增generation，再返回新Tag；迟到Completion即使segment_id相同，只要generation不匹配也不能释放当前槽位。

fill_error或非法状态/Tag会使槽位进入ERROR_HOLD或置state_error_sticky，避免错误槽位被静默复用。free_count和segment_states只用于资源/诊断观察。

表 9-1  segment_buffer_manager 接口信号列表（41项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | clk | I | 1 | clk | Manager状态表所在系统时钟域 |

| 时钟/复位/使能 | rst_n | I | 1 | clk对应域 | 低有效同步复位 |

| alloc握手 | alloc_valid | I | 1 | clk | Writer申请一个FREE槽位 |

| alloc握手 | alloc_ready | O | 1 | clk | 至少存在一个FREE槽位 |

| alloc握手 | alloc_segment_id | O | $clog2(SEGMENT_COUNT)-1:0 | clk | 最低编号FREE槽位 |

| alloc握手 | alloc_tag | O | 15:0 | clk | 下一代{generation,segment_id} |

| alloc握手 | alloc_ddr_addr | O | AXI_ADDR_WIDTH-1:0 | clk | 所分配槽位的DDR物理起始地址 |

| fill描述符 | fill_valid | I | 1 | clk | Writer提交写完后的项目内描述符 |

| fill描述符 | fill_ready | O | 1 | clk | Manager当前可检查并接收描述符 |

| fill描述符 | fill_segment_id | I | $clog2(SEGMENT_COUNT)-1:0 | clk | 描述符对应的DDR槽位编号 |

| fill描述符 | fill_tag | I | 15:0 | clk | 分配时取得的代数Tag |

| fill描述符 | fill_error | I | 1 | clk | DDR写响应或格式处理发生错误 |

| fill描述符 | fill_payload_bytes | I | 63:0 | clk | ADC真实Payload字节数，不含补零 |

| fill描述符 | fill_dma_bytes | I | 31:0 | clk | 4 KiB对齐后的DDR/NVMe传输字节数 |

| fill描述符 | fill_sequence | I | 63:0 | clk | 本次Capture内的Segment顺序号 |

| fill描述符 | fill_crc32c | I | 31:0 | clk | 真实Payload的CRC32C结果 |

| fill描述符 | fill_capture_id | I | 63:0 | clk | 描述符所属Capture编号 |

| fill描述符 | fill_sample_count | I | 63:0 | clk | 本段累计的数据时刻数 |

| fill描述符 | fill_two_channel | I | 1 | clk | 本段采用双通道格式 |

| fill描述符 | fill_single_channel_select | I | 1 | clk | 单通道格式所选通道 |

| fill描述符 | fill_capture_last | I | 1 | clk | 本段是Capture最后一个Payload Segment |

| ready描述符 | ready_valid | O | 1 | clk | 至少存在一个READY描述符 |

| ready描述符 | ready_accept | I | 1 | clk | Scheduler已接收本描述符并提交其请求 |

| ready描述符 | ready_segment_id | O | $clog2(SEGMENT_COUNT)-1:0 | clk | 最低编号READY槽位 |

| ready描述符 | ready_tag | O | 15:0 | clk | 当前READY槽位Tag |

| ready描述符 | ready_ddr_addr | O | AXI_ADDR_WIDTH-1:0 | clk | 当前READY槽位DDR地址 |

| ready描述符 | ready_payload_bytes | O | 63:0 | clk | 当前READY真实Payload字节数 |

| ready描述符 | ready_dma_bytes | O | 31:0 | clk | 当前READY对齐DMA字节数 |

| ready描述符 | ready_sequence | O | 63:0 | clk | 当前READY Segment顺序号 |

| ready描述符 | ready_crc32c | O | 31:0 | clk | 当前READY Payload CRC32C |

| ready描述符 | ready_capture_id | O | 63:0 | clk | 当前READY所属Capture编号 |

| ready描述符 | ready_sample_count | O | 63:0 | clk | 当前READY内的数据时刻数 |

| ready描述符 | ready_two_channel | O | 1 | clk | 当前READY的单双通道格式 |

| ready描述符 | ready_single_channel_select | O | 1 | clk | 当前READY的单通道选择 |

| ready描述符 | ready_capture_last | O | 1 | clk | 当前READY是否为Capture尾段 |

| Completion | completion_valid | I | 1 | clk | Scheduler返回一个Payload完成 |

| Completion | completion_tag | I | 15:0 | clk | 完成所携带的应用层Tag |

| Completion | completion_status | I | 15:0 | clk | 0=成功，非0=错误 |

| 状态/诊断 | segment_states | O | SEGMENT_COUNT*3-1:0 | clk | 每槽3 bit状态的展平诊断总线 |

| 状态/诊断 | free_count | O | $clog2(SEGMENT_COUNT+1)-1:0 | clk | 当前FREE槽位数量 |

| 状态/诊断 | state_error_sticky | O | 1 | clk | 状态/Tag错误粘滞位，复位前保持为1 |


接口表读法：按RTL模块头顺序列出，共41项；接口分组为时钟/复位/使能2项、alloc握手5项、fill描述符14项、ready描述符14项、Completion3项、状态/诊断3项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 9-1C  segment_buffer_manager 关键时序图（高/低电平对齐）

| 信号 / 时间 → | M0 | M1 | M2 | M3 | M4 |

| 槽位k状态 | FREE | FILLING | READY | INFLIGHT | FREE |

| alloc_valid | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| alloc_ready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| fill握手 | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| ready握手 | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ |

| completion_valid | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ |

| Tag | G+1:k | 保持 | 保持 | 匹配 | 释放 |


### 图 9-1C 详细文字说明

M0的alloc握手同时确定槽位、DDR地址和新一代Tag，Writer必须保存这三个字段。M1的fill只有在segment_id、Tag和FILLING状态全部匹配时才接受。

M2 ready_accept表示Scheduler已经接受并提交该Payload请求，不等于SSD已经完成；槽位进入INFLIGHT后仍不可重新分配。M3匹配成功Completion才释放。

若M3到来旧generation的迟到Completion，Manager保持当前状态并置错误；若fill_error为1，槽位进入ERROR_HOLD，不走READY。

# 10. Commit 页设计

## 10.1 定位

Commit 页是“本次 Capture 可以被解释为完整任务”的汇总元数据和完成标志，不是普通 Payload Segment。它固定占用 DDR 0xC0800000 起始的 4 KiB，Writer 不向 Manager 申请 Segment，也不进入普通槽位状态表。

## 10.2 ADCCOMM1 字段表

| Beat | bit | 内存字节偏移 | 宽度 | 字段 | 当前值/来源 |

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


## 10.3 生命周期与复用条件

Writer 在尾 Segment 的 fill 描述符被 Manager 接受后生成 Commit 页。Commit 页全部写入 DDR并等到最终 B 响应后，才对 Scheduler 拉高 commit_valid。Scheduler锁存地址、长度和ID后先做 Flush1，再发 Commit Write。

正式 Vitis 兼容通路中，fdma_transfer_active 要等第二次 Flush 成功才清除，活动期间重复 START 被拒绝。因此固定 Commit 页不会被下一任务提前覆盖。若绕开 FDMA 顶层直接驱动 Pipeline，调用方也必须遵守“capture_done 前不得开始下一 Capture”的条件；commit_ready 只表示 Scheduler 已锁存上下文，不表示共享页已经被 SSD DMA 读取完。

## 10.4 两次 Flush 的掉电一致性目的

所有 Payload Write 完成
→ Flush1：确保 Payload 先持久化
→ Commit Write：写入完整任务标志和汇总
→ Flush2：确保 Commit 标志本身持久化
→ capture_done

删除 Flush1，掉电后可能看到 Commit 已落盘而部分 Payload 仍在易失缓存；删除 Flush2，系统可能已报告完成，但掉电后 Commit 标志丢失。该顺序改善任务级可判定性，但不是完整事务文件系统。

## 10.5 当前限制

当前 Commit 页只有 Capture 级汇总，没有逐 Segment 地址、Payload 长度、DMA 长度、sequence 或 CRC 列表。Manager 虽保存逐段 CRC 和描述符，但 Pipeline Top 当前没有把这些字段送入 Scheduler 或 Commit 页。离线恢复只能知道 Capture 总量，不能仅凭当前 Commit 页逐段校验或重建任意乱序布局。

# 11. Scheduler、NoPHAE Backend 与两个顶层

## 11.1 Scheduler 的单请求在途约束

Scheduler 在 SEND 状态保持请求字段，直到 nvme_req_valid 与 nvme_req_ready 同拍为1；进入 WAIT 后只接收对应 Completion。普通 Payload 被后端接受的同拍，ready_accept 拉高，Manager 才把槽位从 READY 改为 INFLIGHT。

data_payload_bytes 在入口合法性检查后被锁存，但当前未参与后续请求或 LBA 决策，作为遗留诊断上下文保留。真正的 DMA 请求长度与 LBA 推进使用 data_dma_bytes。

## 11.2 SLBA 推进

Payload 或 Commit WRITE 被后端接受时：

next_slba = next_slba + dma_bytes / LBA_BYTES

默认 LBA_BYTES=512，因此 4 KiB 尾段或 Commit 页推进 8 个 LBA。Flush 不推进 LBA。新 FDMA Capture 的 session_start 会装载软件配置的 session_base_slba。

## 11.3 NoPHAE 地址域转换

NoPHAE Vitis 接口把 dma_srcaddr/dma_dstaddr 解释为相对 DDR 窗口的 32 bit Offset，而 Writer 和 Manager 使用 AXI 物理地址。Backend执行：

ddr_offset = physical_ddr_addr - DDR_AXI_BASE_ADDR
lba_count  = byte_len / LBA_BYTES

请求必须完全落在 DDR_AXI_BASE_ADDR 开始的 DDR_WINDOW_BYTES 窗口内，减法结果高 32 bit 必须为 0，SLBA 高 32 bit 也必须为 0。这样可防止物理地址与 NoPHAE Offset 混写。

## 11.4 DATA 与 FLUSH 寄存器序列

| 流程 | NoPHAE 寄存器步骤 |

| DATA | 轮询 DMA_READY；写 DMA_SRC；写 DMA_DST；写 LBA 数量；写方向/启动；轮询 DMA_DONE |

| FLUSH | 读 CMD_CCNT；DEBUG_LOCK=2；写原生命令字段；CMD_WR=1；DEBUG_LOCK=0；轮询 CMD_CCNT 变化 |


Backend 是外部适配器，不是 NoPHAE 内部实现。它复现 E:\NVME_PRO\vitis_classic\nvme\src\func.c 中 test_seq 和 flush 的寄存器访问顺序。

### nophae_dma_backend 架构、接口与时序

源码：rtl/nophae_dma_backend.sv。模块定位：把Scheduler的抽象WRITE/FLUSH请求转换为NoPHAE AXI-Lite寄存器访问序列，轮询DMA状态并返回项目级Completion。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 11-1A  nophae_dma_backend 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| Scheduler req_valid/opcode DDR物理地址/长度/SLBA NoPHAE AXI-Lite返回 | 请求合法性与上下文锁存 物理地址→Offset 高层命令FSM AXI-Lite读写微引擎 超时/状态译码 | NoPHAE AXI-Lite Master Scheduler cpl_valid/status busy/last_status/sticky |


图 11-1B  nophae_dma_backend 顶层架构图（电路/Visio风格重绘）

### 图 11-1A/11-1B 详细文字说明

Backend不是NoPHAE内部RTL，而是项目侧适配器。它检查请求长度、对齐和DDR地址范围，将物理地址减去DMA窗口基址形成Offset，再按用户指南约定写NoPHAE寄存器。

高层FSM决定先轮询DMA_READY、再写Offset/SLBA/长度/命令并轮询DMA_DONE；底层AXI-Lite微引擎负责AW/W独立握手、B响应以及AR/R握手。二者通过一次微事务完成事件解耦。

cpl_valid一旦置1必须保持Tag和status到Scheduler的cpl_ready握手。enable撤销、非法请求、AXI响应错误或轮询超时都形成非零状态，并置error_sticky或timeout_sticky。

表 11-1  nophae_dma_backend 接口信号列表（38项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | clk | I | 1 | clk | Backend和AXI-Lite微引擎时钟 |

| 时钟/复位/使能 | rst_n | I | 1 | clk对应域 | 低有效同步复位 |

| 时钟/复位/使能 | enable | I | 1 | clk | FDMA任务活动期允许执行请求 |

| 状态/诊断 | req_valid | I | 1 | clk | Scheduler抽象请求有效 |

| 状态/诊断 | req_ready | O | 1 | clk | Backend无流程和Completion占用 |

| 状态/诊断 | req_opcode | I | 1:0 | clk | WRITE/READ/FLUSH抽象操作码 |

| 状态/诊断 | req_ddr_addr | I | AXI_ADDR_WIDTH-1:0 | clk | DDR物理地址 |

| 状态/诊断 | req_byte_len | I | 31:0 | clk | DMA字节数 |

| 状态/诊断 | req_slba | I | 63:0 | clk | SSD起始LBA |

| 状态/诊断 | req_user_tag | I | 15:0 | clk | 项目应用层Tag |

| NVMe完成 | cpl_valid | O | 1 | clk | Backend Completion有效 |

| NVMe完成 | cpl_ready | I | 1 | clk | Scheduler接受Completion |

| NVMe完成 | cpl_user_tag | O | 15:0 | clk | 原样回送的请求Tag |

| NVMe完成 | cpl_status | O | 15:0 | clk | 0=成功，非0=Backend本地错误 |

| AXI主接口 | m_axi_awaddr | O | CTRL_ADDR_WIDTH-1:0 | clk | NoPHAE寄存器写地址 |

| AXI主接口 | m_axi_awprot | O | 2:0 | clk | 固定普通非安全数据访问 |

| AXI主接口 | m_axi_awvalid | O | 1 | clk | AXI-Lite写地址有效 |

| AXI主接口 | m_axi_awready | I | 1 | clk | NoPHAE接受写地址 |

| AXI主接口 | m_axi_wdata | O | 31:0 | clk | NoPHAE寄存器写数据 |

| AXI主接口 | m_axi_wstrb | O | 3:0 | clk | 固定全字节写使能 |

| AXI主接口 | m_axi_wvalid | O | 1 | clk | AXI-Lite写数据有效 |

| AXI主接口 | m_axi_wready | I | 1 | clk | NoPHAE接受写数据 |

| AXI主接口 | m_axi_bresp | I | 1:0 | clk | AXI-Lite写响应 |

| AXI主接口 | m_axi_bvalid | I | 1 | clk | AXI-Lite写响应有效 |

| AXI主接口 | m_axi_bready | O | 1 | clk | 微引擎等待写响应 |

| AXI主接口 | m_axi_araddr | O | CTRL_ADDR_WIDTH-1:0 | clk | NoPHAE寄存器读地址 |

| AXI主接口 | m_axi_arprot | O | 2:0 | clk | 固定普通非安全数据访问 |

| AXI主接口 | m_axi_arvalid | O | 1 | clk | AXI-Lite读地址有效 |

| AXI主接口 | m_axi_arready | I | 1 | clk | NoPHAE接受读地址 |

| AXI主接口 | m_axi_rdata | I | 31:0 | clk | NoPHAE寄存器读数据 |

| AXI主接口 | m_axi_rresp | I | 1:0 | clk | AXI-Lite读响应 |

| AXI主接口 | m_axi_rvalid | I | 1 | clk | AXI-Lite读数据有效 |

| AXI主接口 | m_axi_rready | O | 1 | clk | 微引擎等待读数据 |

| 状态/诊断 | busy | O | 1 | clk | 高层流程、微事务或待取Completion占用 |

| 状态/诊断 | error_sticky | O | 1 | clk | 任一请求错误粘滞位，复位前保持 |

| 状态/诊断 | timeout_sticky | O | 1 | clk | 高层或AXI-Lite超时粘滞位 |

| 状态/诊断 | last_status | O | 15:0 | clk | 最近请求完成状态 |

| 状态/诊断 | completed_command_count | O | 31:0 | clk | 成功完成的高层请求数 |


接口表读法：按RTL模块头顺序列出，共38项；接口分组为时钟/复位/使能3项、状态/诊断12项、NVMe完成4项、AXI主接口19项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 11-1C  nophae_dma_backend 关键时序图（高/低电平对齐）

| 信号 / 时间 → | B0 | B1 | B2 | B3 | B4 | B5 |

| req_valid | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| req_ready | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| 高层动作 | 锁存 | 读READY | 写参数 | 读DONE | 形成CPL | 等待取走 |

| AXIL读事务 | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ |

| AXIL写事务 | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| cpl_valid | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ |

| cpl_ready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁╱ | ╱▔▔▔ |

| busy | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |


### 图 11-1C 详细文字说明

B0只在req_valid与req_ready同时为1时锁存请求。后续NoPHAE寄存器访问可能经历任意AXI-Lite stall，Backend不得再次接受新请求。

B1/B3的轮询可能重复多次，直到READY/DONE满足或watchdog超时；图中的单列代表阶段而非一个时钟周期。WRITE需要参数和命令寄存器序列，FLUSH使用相应控制序列。

B4即使Scheduler暂未ready，cpl_valid、cpl_user_tag和cpl_status也保持；B5握手后才清空Completion并重新允许下一请求。

## 11.5 为什么 Capture 只能在第二次 Flush 后完成

local_capture_done_pulse 只说明 ADC 已停并排出 EOC；此时数据可能仍在 CDC FIFO、Beat FIFO、DDR、NoPHAE 或 SSD 缓存中。只有 Scheduler 的 ST_WAIT_FLUSH2 收到 Tag 和 status 都正确的 Completion，才产生 capture_done 并更新 last_capture_id。

### nvme_request_scheduler 架构、接口与时序

源码：rtl/nvme_request_scheduler.sv。模块定位：把READY Payload和Commit上下文排成单请求在途的持久化序列，推进SLBA、匹配Completion并在第二次Flush后完成Capture。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 11-2A  nvme_request_scheduler 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| Manager READY描述符 Writer Commit上下文 链路/初始化/错误 Backend Completion | 单请求FSM与请求寄存器 Tag/状态匹配 SLBA推进 watchdog Payload→F1→Commit→F2 | Backend抽象请求 Manager completion commit_ready capture_done/fatal/sticky |


图 11-2B  nvme_request_scheduler 顶层架构图（电路/Visio风格重绘）

### 图 11-2A/11-2B 详细文字说明

Scheduler一次只保持一个nvme_req_valid并等待对应Completion，避免软件式NoPHAE寄存器接口出现多个未决命令。Payload请求来自Manager READY描述符，Commit请求来自Writer独立上下文。

Payload成功后按ready_dma_bytes/512推进SLBA；真实payload_bytes只用于入口一致性检查。DDR物理地址由Backend转换为NoPHAE Offset，Scheduler仍保存物理地址。

最后一个Payload完成后先发Flush1，再写Commit页，再发Flush2。只有Flush2成功才产生capture_done并更新last_capture_id；超时、链路下降、Tag/状态错误进入fatal路径并锁存sticky。

表 11-2  nvme_request_scheduler 接口信号列表（42项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | clk | I | 1 | clk | Scheduler系统时钟 |

| 时钟/复位/使能 | rst_n | I | 1 | clk对应域 | 低有效同步复位 |

| 运行状态 | nvme_init_done | I | 1 | clk | NoPHAE初始化完成 |

| 运行状态 | pcie_link_up | I | 1 | clk | PCIe链路可用 |

| 运行状态 | ecqe_error_valid | I | 1 | clk | NoPHAE错误完成事件有效 |

| 运行状态 | ecqe_error_status | I | 15:0 | clk | NoPHAE错误完成状态 |

| 状态/诊断 | external_fatal_error | I | 1 | clk | 上游格式、FIFO或Manager致命错误汇总 |

| Capture控制 | session_start | I | 1 | clk | 新Capture会话起点装载脉冲 |

| Capture控制 | session_base_slba | I | 63:0 | clk | 本次Capture的Raw起始LBA |

| ready描述符 | ready_valid | I | 1 | clk | Manager已有READY Payload描述符 |

| ready描述符 | ready_accept | O | 1 | clk | Payload请求已被NoPHAE接受的单拍确认 |

| ready描述符 | ready_tag | I | 15:0 | clk | Payload应用层Tag |

| ready描述符 | ready_ddr_addr | I | AXI_ADDR_WIDTH-1:0 | clk | Payload所在DDR物理地址 |

| ready描述符 | ready_payload_bytes | I | 63:0 | clk | 真实Payload长度，用于入口合法性检查 |

| ready描述符 | ready_dma_bytes | I | 31:0 | clk | 对齐后的DMA长度，用于请求及SLBA推进 |

| Completion | manager_completion_valid | O | 1 | clk | 返回Manager的Payload完成单拍 |

| Completion | manager_completion_tag | O | 15:0 | clk | 返回的Payload Tag |

| Completion | manager_completion_status | O | 15:0 | clk | 0=成功，非0=错误 |

| Commit | commit_valid | I | 1 | clk | Writer已准备好Capture Commit页 |

| Commit | commit_ready | O | 1 | clk | Scheduler锁存Commit上下文的单拍握手 |

| Commit | commit_ddr_addr | I | AXI_ADDR_WIDTH-1:0 | clk | 固定4 KiB Commit页DDR地址 |

| Commit | commit_dma_bytes | I | 31:0 | clk | Commit页DMA字节数 |

| Commit | commit_capture_id | I | 63:0 | clk | Commit页所属Capture编号 |

| Commit | commit_error | I | 1 | clk | Writer汇总的Capture写入错误 |

| NVMe请求 | nvme_req_valid | O | 1 | clk | 当前抽象NoPHAE请求有效 |

| NVMe请求 | nvme_req_ready | I | 1 | clk | 后端可以接受当前请求 |

| NVMe请求 | nvme_req_opcode | O | 1:0 | clk | WRITE/READ/FLUSH抽象操作码 |

| NVMe请求 | nvme_req_ddr_addr | O | AXI_ADDR_WIDTH-1:0 | clk | DMA DDR地址，FLUSH时为0 |

| NVMe请求 | nvme_req_byte_len | O | 31:0 | clk | DMA字节数，FLUSH时为0 |

| NVMe请求 | nvme_req_slba | O | 63:0 | clk | 当前SSD起始LBA |

| NVMe请求 | nvme_req_user_tag | O | 15:0 | clk | Completion匹配用应用层Tag |

| NVMe完成 | nvme_cpl_valid | I | 1 | clk | 后端Completion有效 |

| NVMe完成 | nvme_cpl_ready | O | 1 | clk | Scheduler正等待一个Completion |

| NVMe完成 | nvme_cpl_user_tag | I | 15:0 | clk | 后端返回的应用层Tag |

| NVMe完成 | nvme_cpl_status | I | 15:0 | clk | 0=成功，非0=失败 |

| Capture控制 | capture_done | O | 1 | clk | 第二次Flush成功后的单拍Capture完成 |

| 状态/诊断 | last_capture_id | O | 63:0 | clk | 最近成功持久化的Capture编号 |

| 状态/诊断 | fatal_error | O | 1 | clk | 致命错误锁存，进入HALT后保持 |

| 状态/诊断 | timeout_sticky | O | 1 | clk | 请求超时粘滞位 |

| 状态/诊断 | link_down_sticky | O | 1 | clk | 运行期间PCIe掉线粘滞位 |

| 状态/诊断 | submitted_requests | O | 31:0 | clk | 已被后端接受的项目级请求数 |

| 状态/诊断 | completed_requests | O | 31:0 | clk | 已收到Completion的项目级请求数 |


接口表读法：按RTL模块头顺序列出，共42项；接口分组为时钟/复位/使能2项、运行状态4项、状态/诊断7项、Capture控制3项、ready描述符6项、Completion3项、Commit6项、NVMe请求7项、NVMe完成4项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 11-2C  nvme_request_scheduler 关键时序图（高/低电平对齐）

| 信号 / 时间 → | Q0 | Q1 | Q2 | Q3 | Q4 | Q5 | Q6 | Q7 |

| 请求类型 | DATA | 等待 | F1 | 等待 | COMMIT | 等待 | F2 | 等待 |

| req_valid | ▔▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁▁ |

| req_ready | ▔▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁▁ |

| cpl_valid | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔╲ | ╲▁▁╱ | ╱▔▔▔ |

| cpl_ready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| Manager完成 | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| commit_ready | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| capture_done | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ |


### 图 11-2C 详细文字说明

Q0请求握手后req_valid可以撤销，但Scheduler保持等待状态，直到Q1收到Tag和状态匹配的Completion。Manager槽位在Q1才通过manager_completion_valid回收。

图从最后一个Payload开始。Flush1成功后才能接受Commit上下文，Commit WRITE成功后还不能报告完成，必须继续Flush2。

任一wait阶段若Completion错误、超时或链路掉线，capture_done不产生，fatal_error及相应sticky保持，避免软件把部分持久化误判为成功。

## 11.6 两个顶层的分工

| 顶层 | 分工 | 不包含 |

| nvme_adc_pipeline_top | 纯数据通路集成；329 bit CDC；Writer/Manager/Scheduler连接；错误汇总 | FDMA软件ABI、NoPHAE寄存器访问 |

| nvme_adc_vitis_compat_top | 正式入口；增加FDMA寄存器、Capture CDC控制和NoPHAE Backend | MIG、SmartConnect和真实NoPHAE内部RTL |


### nvme_adc_pipeline_top 架构、接口与时序

源码：rtl/nvme_adc_pipeline_top.sv。模块定位：ADC到DDR和NVMe请求的流水线集成层，例化Packer、CDC FIFO、Writer、Manager和Scheduler并汇总诊断。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 11-3A  nvme_adc_pipeline_top 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| ADC样点/Capture控制 DDR与NVMe返回 初始化/链路状态 | Packer → 329 bit异步FIFO → Writer Writer ↔ Manager → Scheduler 错误、FIFO水位和计数汇总 | DDR AXI写通道 抽象NVMe请求/Completion capture_done与诊断 |


图 11-3B  nvme_adc_pipeline_top 顶层架构图（电路/Visio风格重绘）

### 图 11-3A/11-3B 详细文字说明

主数据路径严格从Packer流向异步FIFO，再由Writer写DDR。Manager旁挂在Writer和Scheduler之间，只接收alloc/fill/ready/completion控制与描述符，不接触256 bit Payload。

系统域只有在ddr_init_done后才允许消费CDC FIFO，避免MIG尚未可用时Writer提前启动。外部fatal条件会汇入Scheduler，使后续存储请求停止并锁存错误。

顶层同时输出ADC域和系统域诊断。adc_fifo_max_used_count是历史水位，用于判断短时反压是否接近耗尽，但不等于丢样；丢样以Packer的dropped_sample_times和overflow_sticky为准。

表 11-3  nvme_adc_pipeline_top 接口信号列表（64项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| ADC数据/诊断 | adc_clk | I | 1 | adc_clk/写侧 | ADC采样时钟 |

| ADC数据/诊断 | adc_rst_n | I | 1 | adc_clk/写侧 | ADC域低有效异步复位 |

| Capture控制 | capture_start | I | 1 | adc_clk/跨域 | 启动并锁存一次Capture的单拍脉冲 |

| Capture控制 | capture_stop | I | 1 | adc_clk/跨域 | 停止当前Capture并排空尾字 |

| Capture配置 | cfg_two_channel | I | 1 | adc_clk/跨域 | 待锁存单双通道模式 |

| Capture配置 | cfg_single_channel_select | I | 1 | adc_clk/跨域 | 待锁存单通道选择 |

| Capture配置 | cfg_capture_id | I | 63:0 | adc_clk/跨域 | 待锁存Capture编号 |

| ADC数据/诊断 | adc_valid | I | 1 | adc_clk/跨域 | 当前ADC输入数据时刻有效 |

| ADC数据/诊断 | adc_ch0 | I | 11:0 | adc_clk/跨域 | ADC通道0采样 |

| ADC数据/诊断 | adc_ch1 | I | 11:0 | adc_clk/跨域 | ADC通道1采样 |

| 时钟/复位/使能 | sys_clk | I | 1 | sys_clk/读侧 | DDR、Manager、Scheduler系统时钟 |

| 时钟/复位/使能 | sys_rst_n | I | 1 | clk对应域 | 系统域低有效同步复位 |

| 运行状态 | ddr_init_done | I | 1 | sys_clk | MIG校准完成，允许CDC FIFO出队 |

| 运行状态 | nvme_init_done | I | 1 | sys_clk | NoPHAE初始化完成 |

| 运行状态 | pcie_link_up | I | 1 | sys_clk | PCIe链路可用 |

| 运行状态 | ecqe_error_valid | I | 1 | sys_clk | NoPHAE错误完成事件有效 |

| 运行状态 | ecqe_error_status | I | 15:0 | sys_clk | NoPHAE错误完成状态 |

| Capture控制 | session_start | I | 1 | sys_clk | 新Capture装载Raw起始LBA的单拍脉冲 |

| Capture控制 | session_base_slba | I | 63:0 | sys_clk | 本次Capture的Raw起始LBA |

| DDR AXI写 | m_axi_ddr_awaddr | O | AXI_ADDR_WIDTH-1:0 | sys_clk | Writer AXI写地址 |

| DDR AXI写 | m_axi_ddr_awlen | O | 7:0 | sys_clk | Writer Burst长度减1 |

| DDR AXI写 | m_axi_ddr_awsize | O | 2:0 | sys_clk | Writer每拍字节数log2 |

| DDR AXI写 | m_axi_ddr_awburst | O | 1:0 | sys_clk | Writer Burst类型 |

| DDR AXI写 | m_axi_ddr_awvalid | O | 1 | sys_clk | Writer写地址有效 |

| DDR AXI写 | m_axi_ddr_awready | I | 1 | sys_clk | DDR互连接受写地址 |

| DDR AXI写 | m_axi_ddr_wdata | O | AXI_DATA_WIDTH-1:0 | sys_clk | Writer写数据 |

| DDR AXI写 | m_axi_ddr_wstrb | O | AXI_DATA_WIDTH/8-1:0 | sys_clk | Writer字节写使能 |

| DDR AXI写 | m_axi_ddr_wlast | O | 1 | sys_clk | Writer Burst末拍 |

| DDR AXI写 | m_axi_ddr_wvalid | O | 1 | sys_clk | Writer写数据有效 |

| DDR AXI写 | m_axi_ddr_wready | I | 1 | sys_clk | DDR互连接受写数据 |

| DDR AXI写 | m_axi_ddr_bresp | I | 1:0 | sys_clk | DDR写响应 |

| DDR AXI写 | m_axi_ddr_bvalid | I | 1 | sys_clk | DDR写响应有效 |

| DDR AXI写 | m_axi_ddr_bready | O | 1 | sys_clk | Writer等待写响应 |

| NVMe请求 | nvme_req_valid | O | 1 | sys_clk | Scheduler抽象请求有效 |

| NVMe请求 | nvme_req_ready | I | 1 | sys_clk | 后端接受抽象请求 |

| NVMe请求 | nvme_req_opcode | O | 1:0 | sys_clk | WRITE/READ/FLUSH抽象操作码 |

| NVMe请求 | nvme_req_ddr_addr | O | AXI_ADDR_WIDTH-1:0 | sys_clk | 请求DMA DDR地址 |

| NVMe请求 | nvme_req_byte_len | O | 31:0 | sys_clk | 请求DMA字节数 |

| NVMe请求 | nvme_req_slba | O | 63:0 | sys_clk | 请求SSD起始LBA |

| NVMe请求 | nvme_req_user_tag | O | 15:0 | sys_clk | 请求应用层Tag |

| NVMe完成 | nvme_cpl_valid | I | 1 | sys_clk | 后端Completion有效 |

| NVMe完成 | nvme_cpl_ready | O | 1 | sys_clk | Scheduler可接收Completion |

| NVMe完成 | nvme_cpl_user_tag | I | 15:0 | sys_clk | Completion应用层Tag |

| NVMe完成 | nvme_cpl_status | I | 15:0 | sys_clk | Completion状态 |

| Capture控制 | capture_active | O | 1 | adc_clk/跨域 | Packer处于采样或尾字排空期 |

| Capture控制 | capture_ready | O | 1 | adc_clk/跨域 | Packer可接受新Capture |

| Capture控制 | capture_done | O | 1 | adc_clk/跨域 | 第二次Flush成功的单拍完成 |

| 状态/诊断 | last_capture_id | O | 63:0 | sys_clk | 最近成功持久化的Capture编号 |

| ADC数据/诊断 | adc_overflow_sticky | O | 1 | adc_clk/跨域 | ADC无法反压导致的丢数粘滞位 |

| 状态/诊断 | config_change_sticky | O | 1 | sys_clk | Capture运行中配置变化粘滞位 |

| 状态/诊断 | stream_format_error_sticky | O | 1 | sys_clk | Writer输入格式错误粘滞位 |

| ADC数据/诊断 | adc_accepted_sample_times | O | 63:0 | adc_clk/跨域 | Packer接受的数据时刻数 |

| ADC数据/诊断 | adc_dropped_sample_times | O | 63:0 | adc_clk/跨域 | Packer丢弃的数据时刻数 |

| 状态/诊断 | ddr_axi_error_sticky | O | 1 | sys_clk | DDR非OKAY B响应粘滞位 |

| 状态/诊断 | timeout_sticky | O | 1 | sys_clk | NVMe请求超时粘滞位 |

| 状态/诊断 | link_down_sticky | O | 1 | sys_clk | 运行期PCIe掉线粘滞位 |

| 状态/诊断 | fatal_error | O | 1 | sys_clk | 全链路致命错误汇总 |

| 状态/诊断 | submitted_requests | O | 31:0 | sys_clk | 已提交项目级NVMe请求数 |

| 状态/诊断 | completed_requests | O | 31:0 | sys_clk | 已完成项目级NVMe请求数 |

| 状态/诊断 | segment_states | O | SEGMENT_COUNT*3-1:0 | sys_clk | Manager各槽位状态展平总线 |

| 状态/诊断 | segment_free_count | O | $clog2(SEGMENT_COUNT+1)-1:0 | sys_clk | Manager空闲槽位数 |

| ADC数据/诊断 | adc_fifo_full_sys | O | 1 | adc_clk/跨域 | 同步到系统域的FIFO满告警 |

| ADC数据/诊断 | adc_fifo_prog_full_sys | O | 1 | adc_clk/跨域 | 同步到系统域的FIFO预满告警 |

| ADC数据/诊断 | adc_fifo_max_used_count | O | ADC_FIFO_AW:0 | adc_clk/跨域 | ADC域历史最高FIFO占用 |


接口表读法：按RTL模块头顺序列出，共64项；接口分组为ADC数据/诊断11项、Capture控制7项、Capture配置3项、时钟/复位/使能2项、运行状态5项、DDR AXI写14项、NVMe请求7项、NVMe完成4项、状态/诊断11项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 11-3C  nvme_adc_pipeline_top 关键时序图（高/低电平对齐）

| 信号 / 时间 → | P0 | P1 | P2 | P3 | P4 | P5 |

| Packer_tvalid | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| AsyncFIFO_s_ready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| FIFO_m_valid | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ |

| Writer_tready | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| alloc_valid | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ | ▁▁▁▁ |

| alloc_ready | ▔▔▔▔ | ▔▔▔╲ | ╲▁▁╱ | ╱▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| fill握手 | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ |

| Manager_ready_valid | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ |


### 图 11-3C 详细文字说明

Packer条目跨异步FIFO后到达Writer。首个非空字出现时Writer先申请槽位，因此Writer tready在alloc握手前保持为0；alloc于P3完成后，数据才在后续WR_FILL周期消费。

fill握手必须晚于该Segment最后一个DDR B响应。Manager接受描述符后把槽位推进READY，Scheduler才可能看到ready_valid。

图省略多个实际DDR Burst周期，只表示模块间合同。任何ready拉低时，对应valid方都必须保持数据、Tag和描述符字段。

# 12. 若删除保护会怎样

| 保护 | 当前实现 | 删除后的失效模式 |

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


# 13. 软件使用指导

## 13.1 不重建的软件边界

本版不修改、不重建 Vitis Classic 工程和 ELF。核心源码位于 E:\NVME_PRO\vitis_classic\nvme\src，现有 ELF、bitstream 和 XSA 的启动方法仍使用原有脚本。V2.4 的 RTL 注释和文档不会自动进入现有 bitstream。

## 13.2 任务配置顺序

确认 PCIe Link、NoPHAE 初始化、DDR 初始化和 I/O Queue 已完成。

写 Capture 模式。双通道每数据时刻 4 Byte，单通道每数据时刻 2 Byte。

写 SIZE_L/SIZE_H。长度必须非零并满足当前样本粒度。

设置安全的 START_LBA 并使能 SLBA。默认 MIN_START_SLBA=1048576，即保护 SSD 前 512 MiB。

写 START=1。活动期重复 START 会返回 D001。

轮询 WDATA_DONE，它只代表 ADC 本地阶段完成。

继续轮询 NVME_SEND_DONE，它代表第二次 Flush 后最终完成。

读取 STATUS、LAST_ERROR、BACKEND_STS、accepted/dropped 和 FIFO 告警，不能只看 DONE。

## 13.3 常见错误码

| 范围/示例 | 来源 | 含义 |

| D001 | FDMA寄存器 | 活动期重复START |

| D002 | FDMA寄存器 | SIZE为0 |

| D003 | FDMA寄存器 | SIZE不满足2/4 Byte样本粒度 |

| D004 | FDMA寄存器 | SLBA落入保护区 |

| D005 | FDMA寄存器 | 启动前Pipeline已有fatal |

| D006 | Capture控制 | 尚未启采即被软件取消 |

| D100 | FDMA寄存器 | 活动期Pipeline fatal汇总 |

| E001～E008 | NoPHAE Backend | 操作码、长度、地址、AXI-Lite、超时或禁用错误 |


## 13.4 上板前必须确认

| 检查项 | 原因 |

| 0x90000000 FDMA寄存器已加入实际地址图 | 当前历史XSA没有该外设 |

| Commit/Segment地址与队列、PRP、软件测试区不重叠 | 防止DDR互相覆盖 |

| DDR_AXI_BASE_ADDR与NoPHAE真实窗口一致 | 地址减法错误会让DMA读错位置 |

| SSD LBA格式确为512 B或把参数改为Identify结果 | byte到LBA换算依赖该值 |

| 新RTL确实进入新bitstream | 修改源码文件不等于硬件已更新 |

| 任务期间不启动下一Capture | 固定Commit页直到Flush2才安全复用 |


### fdma_vitis_compat_regs 架构、接口与时序

源码：rtl/fdma_vitis_compat_regs.sv。模块定位：软件兼容寄存器块，接受AXI4-Lite访问，校验并锁存一次传输配置，产生START/STOP脉冲并汇总任务状态。本模块图表就地放在相关正文设计章节，不再集中放入独立附录。

图 13-1A  fdma_vitis_compat_regs 顶层架构图（原Word表格式，保留）

| I / 上游 → | 模块内部结构 | → O / 下游 |

| AXI-Lite AW/W/AR 完成、取消、错误与计数 | AW/W独立缓存与配对 寄存器文件/字节写使能 START合法性检查 sticky状态锁存 | transfer_start/stop_pulse Capture配置与base SLBA 读响应/写响应/last_error |


图 13-1B  fdma_vitis_compat_regs 顶层架构图（电路/Visio风格重绘）

### 图 13-1A/13-1B 详细文字说明

AXI-Lite写地址AW和写数据W可以在不同周期到达，模块分别缓存，二者齐备后才执行一次寄存器写并返回B响应。图中的配对逻辑用于兼容合法AXI-Lite时序，不能假定AW/W同拍。

START写入不是简单透传。模块检查任务是否空闲、长度和地址配置是否有效，再锁存transfer_size_bytes、capture_id和通道模式，最后生成单拍transfer_start_pulse。

任务活动期间收到本地完成只表示采集停止；transfer_active要保持到最终NVMe完成、取消或致命错误。错误码和诊断计数通过读通道提供给现有Vitis软件。

表 13-1  fdma_vitis_compat_regs 接口信号列表（40项）

| 接口组 | 信号 | I/O | 位宽 | 时钟域 | 语义 |

| 时钟/复位/使能 | clk | I | 1 | clk | AXI-Lite及Capture控制系统时钟 |

| 时钟/复位/使能 | rst_n | I | 1 | clk对应域 | 低有效同步复位 |

| 软件AXI-Lite | s_axi_awaddr | I | AXIL_ADDR_WIDTH-1:0 | clk | MicroBlaze写地址 |

| 软件AXI-Lite | s_axi_awprot | I | 2:0 | clk | 写保护属性，当前仅作未使用汇总 |

| 软件AXI-Lite | s_axi_awvalid | I | 1 | clk | 写地址有效 |

| 软件AXI-Lite | s_axi_awready | O | 1 | clk | 可缓存写地址 |

| 软件AXI-Lite | s_axi_wdata | I | 31:0 | clk | 写数据 |

| 软件AXI-Lite | s_axi_wstrb | I | 3:0 | clk | 写字节使能 |

| 软件AXI-Lite | s_axi_wvalid | I | 1 | clk | 写数据有效 |

| 软件AXI-Lite | s_axi_wready | O | 1 | clk | 可缓存写数据 |

| 软件AXI-Lite | s_axi_bresp | O | 1:0 | clk | 写响应，当前合法访问返回OKAY |

| 软件AXI-Lite | s_axi_bvalid | O | 1 | clk | 写响应有效 |

| 软件AXI-Lite | s_axi_bready | I | 1 | clk | MicroBlaze接受写响应 |

| 软件AXI-Lite | s_axi_araddr | I | AXIL_ADDR_WIDTH-1:0 | clk | MicroBlaze读地址 |

| 软件AXI-Lite | s_axi_arprot | I | 2:0 | clk | 读保护属性，当前仅作未使用汇总 |

| 软件AXI-Lite | s_axi_arvalid | I | 1 | clk | 读地址有效 |

| 软件AXI-Lite | s_axi_arready | O | 1 | clk | 可接受读地址 |

| 软件AXI-Lite | s_axi_rdata | O | 31:0 | clk | 寄存器读数据 |

| 软件AXI-Lite | s_axi_rresp | O | 1:0 | clk | 读响应，当前返回OKAY |

| 软件AXI-Lite | s_axi_rvalid | O | 1 | clk | 读数据有效 |

| 软件AXI-Lite | s_axi_rready | I | 1 | clk | MicroBlaze接受读数据 |

| 状态/诊断 | local_capture_done_pulse | I | 1 | clk | ADC侧停止并排空完成 |

| Capture控制 | capture_cancelled_pulse | I | 1 | clk | 未启采即取消 |

| 状态/诊断 | nvme_capture_done_pulse | I | 1 | clk | 第二次Flush完成 |

| 状态/诊断 | pipeline_fatal_error | I | 1 | clk | 全链路不可恢复错误 |

| ADC数据/诊断 | adc_fifo_full | I | 1 | clk | ADC CDC FIFO满诊断 |

| ADC数据/诊断 | adc_fifo_prog_full | I | 1 | clk | ADC CDC FIFO预满诊断 |

| 状态/诊断 | accepted_sample_times | I | 63:0 | clk | Packer已接受的数据时刻数 |

| 状态/诊断 | dropped_sample_times | I | 63:0 | clk | Packer已丢弃的数据时刻数 |

| 状态/诊断 | backend_last_status | I | 15:0 | clk | NoPHAE Backend最近状态 |

| 状态/诊断 | transfer_start_pulse | O | 1 | clk | 合法START写形成的单拍 |

| 状态/诊断 | transfer_stop_pulse | O | 1 | clk | 活动期写START=0形成的单拍 |

| 状态/诊断 | transfer_active | O | 1 | clk | 从合法START到最终完成/错误的任务活动位 |

| 状态/诊断 | backend_enable | O | 1 | clk | 任务活动期允许NoPHAE Backend运行 |

| 状态/诊断 | transfer_size_bytes | O | 63:0 | clk | START时锁存的目标字节数 |

| 状态/诊断 | transfer_capture_id | O | 63:0 | clk | START时分配的Capture编号 |

| Capture配置 | cfg_two_channel | O | 1 | clk | 软件配置的单双通道模式 |

| Capture配置 | cfg_single_channel_select | O | 1 | clk | 软件配置的单通道选择 |

| Capture控制 | session_base_slba | O | 63:0 | clk | SLBA使能后零扩展的Raw起始LBA |

| 状态/诊断 | last_error | O | 15:0 | clk | 最近一次任务或启动校验错误 |


接口表读法：按RTL模块头顺序列出，共40项；接口分组为时钟/复位/使能2项、软件AXI-Lite19项、状态/诊断13项、Capture控制2项、ADC数据/诊断2项、Capture配置2项。I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。

握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。

图 13-1C  fdma_vitis_compat_regs 关键时序图（高/低电平对齐）

| 信号 / 时间 → | T0 | T1 | T2 | T3 | T4 | T5 |

| s_axi_awvalid | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| s_axi_awready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| s_axi_wvalid | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| s_axi_wready | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ | ▔▔▔▔ |

| AW/W齐备 | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| transfer_start_pulse | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔╲ | ╲▁▁▁ | ▁▁▁▁ | ▁▁▁▁ |

| s_axi_bvalid | ▁▁▁▁ | ▁▁▁▁ | ▁▁▁╱ | ╱▔▔▔ | ▔▔▔╲ | ╲▁▁▁ |


### 图 13-1C 详细文字说明

示例故意让AW先于W一拍到达。C1只缓存地址，C2缓存数据并执行配对后的START寄存器写；这说明START副作用只能发生一次。

若B通道被软件stall，s_axi_bvalid和s_axi_bresp必须保持到bready握手，不能重复生成START。WSTRB只更新被选中的字节。

读通道AR/R遵循同样的valid保持原则，但没有AW/W配对；读地址被接受后，rdata/rresp保持到rready。

# 14. 本轮验证和变更约束

## 14.1 实际执行

本轮按最新要求没有启动 Vivado/XSim 回归，也没有新增第六项测试，不调用综合。验证集中在源码不变量和文档结构：

| 检查 | 结果标准 |

| RTL去注释摘要 | 11个文件逐一等于修改前基线；Packer基线预先允许always_comb→always @* |

| 组合逻辑形式 | Packer原有过程组合块为always @*；其他现有组合逻辑不改 |

| 旧位宽注释 | 正式RTL不得把当前ADC FIFO写成263 bit |

| 文档链接 | 本Markdown内相对链接均能解析 |

| DOCX | ZIP/CRC、OOXML必需部件、标题层级、编号、固定DXA表格、核心属性、关键术语和内容规模 |

| 渲染 | 按工作区要求不生成PDF/PNG、不做页面渲染 |


## 14.2 不宣称的结论

本轮不把历史 5 PASS 写成本次回归结果，也不宣称 6 PASS / 0 FAIL。没有执行综合、时序分析、实现、bitstream生成、JTAG下载、真实DDR写入或SSD回读。代码注释通过不等于功能验证升级。

# 附录 A：11 个正式模块的代码级字典

## A.1 adc_channel_packer

| 类别 | 名称 | 语义 |

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


## A.2 adc_capture_limit_controller

| 类别 | 名称 | 语义 |

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


## A.3 axis_async_fifo

| 类别 | 名称 | 语义 |

| 参数 | DATA_WIDTH、ADDR_WIDTH、DEPTH | 条目位宽、地址位宽和深度 |

| 写侧 | s_clk、s_rst_n、s_axis_tdata、s_axis_tvalid、s_axis_tready | ADC域ready/valid入口 |

| 读侧 | m_clk、m_rst_n、m_axis_tdata、m_axis_tvalid、m_axis_tready | 系统域FWFT出口 |

| 状态 | full、empty、prog_full、wr_used_count、rd_used_count | XPM两侧容量诊断 |

| 中间量 | fifo_reset、fifo_read、wr_rst_busy、rd_rst_busy | 合并复位、读握手和XPM复位忙 |


## A.4 sync_fifo

| 类别 | 名称 | 语义 |

| 参数 | DATA_WIDTH、ADDR_WIDTH、DEPTH | Beat条目位宽与FIFO深度 |

| 端口 | clk、rst_n、din、wr_en、rd_en、dout、full、empty、used_count | 单时钟FWFT读写和容量状态 |

| 内部行为 | wr_en且非full、rd_en且非empty | 包装器抑制非法满写和空读 |


## A.5 adc_ddr_segment_writer

| 类别 | 名称 | 语义 |

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


## A.6 segment_buffer_manager

| 类别 | 名称 | 语义 |

| 参数 | AXI_ADDR_WIDTH、SEGMENT_BYTES、SEGMENT_COUNT、DDR_BASE_ADDR、SEGMENT_ID_W、GEN_W | 地址布局和Tag切分 |

| 状态 | SEG_FREE、SEG_FILLING、SEG_READY、SEG_INFLIGHT、SEG_ERROR_HOLD、state数组 | 每槽所有权生命周期 |

| 代数 | generation数组、tag_table | 防止迟到Completion释放新代槽位 |

| 描述符表 | payload_table、dma_table、sequence_table、crc_table、capture_id_table、sample_count_table、two_channel_table、single_select_table、capture_last_table | READY/INFLIGHT期间保持的逐段元数据 |

| 扫描 | first_free、first_ready、free_found、ready_found、free_count | 最低编号优先分配和READY输出 |

| Completion | completion_match_found、completion_valid、completion_tag、completion_status | 乱序Tag搜索和状态检查 |

| 接口 | alloc信号组、fill信号组、ready信号组、completion信号组 | Writer、Scheduler与Manager的四组握手 |

| 诊断 | segment_states、state_error_sticky | 展平状态和粘滞错误 |

| 循环变量 | i、k、j | 组合扫描、Tag扫描和时序表更新 |


## A.7 nvme_request_scheduler

| 类别 | 名称 | 语义 |

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


## A.8 nophae_dma_backend

| 类别 | 名称 | 语义 |

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


## A.9 fdma_vitis_compat_regs

| 类别 | 名称 | 语义 |

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


## A.10 nvme_adc_pipeline_top

| 类别 | 名称 | 语义 |

| 参数 | AXI_ADDR_WIDTH、AXI_DATA_WIDTH、SEGMENT_BYTES、SEGMENT_COUNT、BURST_BEATS、ADC_FIFO_AW、COMMAND_TIMEOUT_CYCLES、LBA_BYTES、DDR_BASE_ADDR、COMMIT_DDR_ADDR、BASE_SLBA | 数据面结构和默认布局 |

| Packer连线 | adc_packed_data、adc_packed_valid_bytes、adc_packed_eoc、adc_packed_valid、adc_packed_ready、active_two_channel_adc、active_single_select_adc、active_capture_id_adc | ADC域输出和锁存上下文 |

| CDC连线 | adc_fifo_sdata、adc_fifo_mdata、adc_fifo_mvalid、adc_fifo_mready、adc_fifo_full、adc_fifo_empty、adc_fifo_prog_full、adc_fifo_wr_count、adc_fifo_rd_count | 329 bit原子CDC和容量诊断 |

| CDC同步 | adc_integrity_meta、adc_integrity_sys、adc_fifo_full_meta_sys、adc_fifo_full_sync_sys、adc_fifo_prog_full_meta_sys、adc_fifo_prog_full_sync_sys | 单bit错误/告警进入系统域的两级同步 |

| Writer/Manager | 全部alloc信号、全部fill信号、writer_stream_ready、全部commit信号 | 槽位申请、描述符和Commit上下文 |

| Manager/Scheduler | manager_ready_valid、manager_ready_accept、manager_ready_segment_id、manager_ready_tag、manager_ready_addr、manager_ready_payload、manager_ready_dma、manager_completion_valid、manager_completion_tag、manager_completion_status、manager_state_error | Payload请求生命周期 |

| Scheduler | scheduler_fatal | 调度器fatal并入顶层错误 |

| 当前未用诊断 | adc_fifo_empty、adc_fifo_rd_count、manager_ready_segment_id、commit_sample_count、commit_payload_bytes | 已连接但不参与当前决策，按接口演进保留 |


## A.11 nvme_adc_vitis_compat_top

| 类别 | 名称 | 语义 |

| 参数 | Pipeline全部结构参数、CTRL_ADDR_WIDTH、AXIL_TIMEOUT_CYCLES、CAPTURE_DDR_BASE_ADDR、COMMIT_DDR_ADDR、DDR_AXI_BASE_ADDR、DDR_WINDOW_BYTES、NOPHAE_CTRL_BASE_ADDR、FDMA_CTRL_BASE_ADDR、MIN_START_SLBA | 正式板级集成契约 |

| FDMA到控制器 | fdma_start_pulse、fdma_stop_pulse、backend_enable、transfer_size_bytes、transfer_capture_id、cfg_two_channel_sys、cfg_single_select_sys、session_base_slba | 软件任务上下文 |

| 控制器到Packer | capture_start_adc、capture_stop_adc、cfg_two_channel_adc、cfg_single_select_adc、cfg_capture_id_adc | 跨域后固定Capture控制 |

| Scheduler到Backend | nvme_req_valid、nvme_req_ready、nvme_req_opcode、nvme_req_ddr_addr、nvme_req_byte_len、nvme_req_slba、nvme_req_user_tag | 项目抽象请求 |

| Backend到Scheduler | nvme_cpl_valid、nvme_cpl_ready、nvme_cpl_user_tag、nvme_cpl_status | 项目抽象Completion |

| 错误汇总 | pipeline_fatal_error、backend_error_sticky、backend_timeout_sticky、adc_overflow_sticky、config_change_sticky、stream_format_error_sticky、ddr_axi_error_sticky、scheduler_timeout_sticky、link_down_sticky | fatal_error和FDMA STATUS来源 |

| FIFO诊断 | adc_fifo_full_sys、adc_fifo_prog_full_sys、adc_fifo_max_used_count | Vitis兼容状态寄存器输入 |

| unused_diagnostics | 诊断线归约汇总 | 仅消除未单独导出的lint告警，不参与功能决策 |


# 附录 B：关键代码摘录

## B.1 Packer 同拍换字

assign output_take = m_axis_tvalid && m_axis_tready;
assign output_free = !m_axis_tvalid || output_take;

## B.2 Manager 下一代 Tag

assign alloc_tag = {generation[first_free] + 1'b1, first_free};

## B.3 最终 B 响应才完成 job

if (job_finalized &&
    (job_beats_written == job_target_beats))
    job_done_pulse <= 1'b1;

## B.4 第二次 Flush 后完成 Capture

last_capture_id <= commit_id_latched;
capture_done    <= 1'b1;
state           <= ST_IDLE;

# 附录 C：变更记录

| 版本 | 日期 | 说明 |

| V2.1 | 历史 | 修改要点与初步代码验证说明，保留 |

| V2.3 | 2026-07-31 | Vitis源码实证、ABI兼容和既有RTL修复，保留 |

| V2.4 | 2026-08-10 | 新增代码级术语、状态机和全部中间信号字典；总体与11模块架构/接口/时序内容就地融入正文，原Word图保留并增加电路/Visio风格重绘，接口方向使用I/O，时序使用对齐高低电平波形；RTL只补注释并将Packer组合块改为always @* |


# 文档结构验证声明

本文只进行DOCX ZIP/CRC、OOXML必需部件、核心属性、真实标题与编号样式、固定DXA表格几何、关键术语和内容规模检查。按照工作区规则未渲染PDF/PNG，因此不把结构检查表述为页面视觉验收。
