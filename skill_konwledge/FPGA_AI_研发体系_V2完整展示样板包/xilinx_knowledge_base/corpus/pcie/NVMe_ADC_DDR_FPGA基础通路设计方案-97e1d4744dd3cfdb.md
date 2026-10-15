# NVMe_ADC_DDR_FPGA基础通路设计方案

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案.docx`
- SHA-256: `97e1d4744dd3cfdbbc68b041db36b61eeb28a0e663091e762e62f38707aa73af`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案.docx

内部设计说明

NVMe–DDR–ADC FPGA
基础通路设计方案

面向 UltraScale KU040｜Vivado 2020.2｜原始 LBA 连续采集

| 项目项 | 内容 |

| 目标数据源 | 1 片 ADC、2 通道、250 MSPS、12 bit，按 16 bit/通道存储 |

| 持续输入带宽 | 1,000,000,000 Byte/s，约 953.7 MiB/s |

| 数据落盘方式 | 原始 LBA＋512 B 采集元数据＋分块序号＋CRC32C；无文件系统 |

| 目标器件/工具 | Xilinx UltraScale KU040，Vivado 2020.2 |

| 文档版本 | V0.9 基础工程版｜2026-07-24 |


| 结论 该架构可以作为 NVMe–DDR 数据流打通的基础工程。ADC→DDR 写通路、分段管理、NVMe 命令调度和 AXI-Lite 占位适配已经形成可仿真的纯 RTL 骨架。最终接板前，必须用厂商正式的数据面接口、寄存器表和初始化时序替换仿真桩；这一步不能由“AXI 接口”四个字推断。 |


# 1. 范围、假设与交付边界

本方案解决连续 ADC 数据从采样时钟域进入 DDR，再由 NVMe Host Controller 经 PCIe 写入 SSD 的基础数据通路。设计不包含 FAT、EXT4、NTFS 等文件系统，也不要求 MicroBlaze 参与实时采集。电脑端通过后续导出工具按固定 LBA 和元数据恢复文件。

| 范围内 | 范围外/待接口确认 |

| 两路 12 bit ADC 样本的 16 bit 存储格式 | KU040 板级 ADC 引脚约束与 IDELAY 校准 |

| ADC 到系统时钟域的 XPM 异步 FIFO | 厂商 NVMe IP 的内部协议实现 |

| 256 bit AXI4 DDR Burst 写入 | SSD 文件系统与操作系统块设备驱动 |

| DDR 多分段状态管理 | PC 导出工具的正式实现 |

| 原始 LBA、分块序号和 CRC32C | 厂商真实寄存器地址、DMA 端口方向 |

| Vivado 2020.2 行为仿真和 KU040 OOC 检查 | 板级 SI、PCIe Equalization 和 SSD 热降速 |


# 2. 输入数据与带宽预算

2 通道 × 250,000,000 sample/s × 16 bit ÷ 8 = 1,000,000,000 Byte/s

每个 ADC 采样周期形成一个 32 bit 样本对。DDR 数据面采用 256 bit，即每个 AXI beat 容纳 8 个样本对。100 MHz 时理论单向带宽为 3.2 GB/s，200 MHz 时为 6.4 GB/s。由于 DDR 同时承担约 1 GB/s 的采集写入和约 1 GB/s 的 NVMe 读出，验收时应要求 DDR 有效双向总吞吐不低于 3 GB/s，并观察最差仲裁延迟。

| 项目 | 数值 | 设计含义 |

| 单样本对 | 4 Byte | ch0 16 bit＋ch1 16 bit |

| 持续输入 | 1.0 GB/s | 不能依赖平均速率掩盖短时停顿 |

| 256 bit AXI beat | 32 Byte | 8 个样本对 |

| 推荐起始分块 | 1 MiB | 约 1.049 ms 采集数据 |

| 8 × 1 MiB 环形缓存 | 8 MiB | 只提供约 8.39 ms 缓冲 |

| LBA 大小假设 | 512 Byte | 最终须读取 Identify Namespace 核对 |


| 缓存判断 DDR 只能吸收瞬时抖动，不能弥补 SSD 长期写速率低于 1 GB/s。若 SSD 实际持续写入只有 800 MB/s，缓存仍会以约 200 MB/s 的速度被吃满。连续采集时间必须和 SSD 稳态写速率、温度降速以及可用 DDR 容量一起确定。 |


# 3. 参考工程与 ADC 数据格式

ADC 逻辑格式参考远端 RTDS/BUFR_RPT201-1，而不是照搬其器件原语。参考工程的 AD_LVDS.sv 使用 ADC DCO 的双沿采样产生 adc_cha[11:0] 和 adc_chb[11:0]；DATA_TRS.v 只把 A 路符号扩展为 16 bit，B 路没有进入最终数据流。本工程保留两路。

ch0_16 = {{4{adc_ch0[11]}}, adc_ch0};
ch1_16 = {{4{adc_ch1[11]}}, adc_ch1};
sample_pair[31:0] = {ch1_16, ch0_16};

| 参考项 | 采用方式 | 说明 |

| AD_LVDS.sv | 采用双沿后两路 12 bit 的逻辑含义 | 新顶层输入从解串后的 adc_ch0/adc_ch1 开始 |

| DATA_TRS.v | 采用 12→16 bit 符号扩展 | 改为 A/B 两路都保留 |

| IBUFDS/BUFR/IDELAYE2/IDDR | 不直接复制 | 属于 7 系列原语，不适合 UltraScale |

| KU040 ADC PHY | 板级适配器另建 | 用 UltraScale 对应原语并按实际引脚、时钟校准 |


# 4. 总体架构与数据流

ADC PHY → adc_pair_to_axis → XPM async FIFO → 32→256 bit packer
        → AXI4 burst writer → DDR segment ring → NVMe DMA read
        → PCIe Root Complex → NVMe SSD Endpoint

segment descriptor → scheduler → vendor command adapter → NVMe Host IP

ADC 物理层在 adc_clk 域输出两路 12 bit 样本和 adc_valid。

adc_pair_to_axis 对两路符号扩展，组成 32 bit AXI-Stream 数据。

XPM 异步 FIFO 完成 adc_clk 到 sys_clk 的跨时钟传输。

打包器把 8 个样本对组成一个 256 bit beat，并计算 CRC32C。

AXI4 Writer 以固定 INCR Burst 写入当前 DDR 分段。

分段完成且最后一个 B 响应返回后，生成地址、长度、序号和 CRC 描述符。

调度器分配 SLBA/NLB，并通过厂商适配层提交 NVMe 写命令。

NVMe IP 从 DDR 读取负载，经 PCIe RC 写入作为 EP 的 SSD。

收到 NVMe 完成状态后，对应 DDR 分段才重新标记为 FREE。

# 5. RTL 模块划分

| 模块 | 职责 | 是否可直接保留 |

| adc_pair_to_axis.sv | 两路符号扩展、32 bit 打包、丢样计数 | 是 |

| axis_async_fifo.sv | XPM BRAM 异步 FIFO，隔离 ADC/系统时钟 | 是 |

| adc_ddr_segment_writer.sv | 256 bit 打包、CRC32C、AXI Burst、描述符 | 是 |

| nvme_segment_scheduler.sv | 分段队列、FREE 掩码、LBA 分配、完成回收 | 是 |

| nvme_axil_cmd_bridge.sv | 把内部命令映射到占位 AXI-Lite 寄存器 | 需按厂商手册修改 |

| axi_ddr_mem_stub.sv | 行为级 DDR 写模型 | 仅仿真 |

| nvme_axil_stub.sv | 行为级 NVMe 命令完成模型 | 仅仿真 |

| nvme_adc_pipeline_top.sv | 连接数据面、控制面和状态输出 | 接口调整后保留 |


# 6. 时钟、复位与流控

| 时钟域 | 主要逻辑 | 复位/启动要求 |

| adc_clk | ADC 格式化、XPM FIFO 写端 | adc_rst_n 释放后等待 wr_rst_busy 清零 |

| sys_clk | FIFO 读端、DDR Writer、调度器、NVMe 命令桥 | sys_rst_n 释放后等待 DDR/NVMe init_done |

| PCIe/NVMe IP 内部 | LTSSM、Admin/I/O Queue、DMA | 以厂商 IP 时钟复位规范为准 |


ADC 本身不能接受 ready 回压，因此 m_axis_tready 变低时只能报警和计数，不能“暂停 ADC”。正式系统应只在 DDR 初始化完成、FIFO 复位忙结束、至少一个分段可用后拉高 capture_enable。采集中任何 dropped_sample_pairs 非零都应判定该次采集无效。

# 7. DDR 分段与状态机

FREE → FILLING → READY → NVME_INFLIGHT → DONE → FREE

实现中 FILLING 由 Writer 隐式持有；最后一个 AXI B 响应成功后生成 READY 描述符；调度器接收描述符时清除 free_mask，对应 NVMe 完成成功后重新置位。错误完成不会释放分段，避免坏数据被下一轮覆盖。当前基线一次只允许一个 NVMe 命令在途，便于先打通；获得厂商队列深度和 Tag 规则后可扩展为多 outstanding。

| 参数 | 当前默认 | 建议现场扫描 |

| AXI_DATA_WIDTH | 256 bit | 与 MIG/SmartConnect 数据宽度一致 |

| BURST_BEATS | 16 | 16/32/64；不超过 AXI4 256 beats |

| SEGMENT_BYTES | 1 MiB | 64 KiB、256 KiB、1 MiB；受 MDTS 约束 |

| SEGMENT_COUNT | 8 | 按 DDR 容量和最差 SSD 延迟增加 |

| BASE_SLBA | 2048 | 避开盘头保护区；由测试盘布局决定 |


# 8. 原始 LBA 与采集元数据格式

建议每个采集块占用“1 个元数据 LBA＋若干数据 LBA”。电脑端扫描 magic 和 sequence，按 payload_bytes 读取负载并校验 payload_crc32c。这样既不依赖文件系统，也能在掉电、中途停止或坏块后重新定位有效数据。

| 偏移 | 长度 | 字段 | 定义 |

| 0x000 | 8 | magic | ASCII "ADCSTRM1" |

| 0x008 | 2 | version | 格式版本，初始为 1 |

| 0x00A | 2 | header_bytes | 固定 512 |

| 0x00C | 4 | flags | 有效、截断、溢出等标志 |

| 0x010 | 8 | sequence | 单调递增分块序号 |

| 0x018 | 8 | sample_index_start | 本块第一个样本对序号 |

| 0x020 | 8 | timestamp_ns | 可为 0，接入时间源后启用 |

| 0x028 | 4 | sample_rate_hz | 250000000 |

| 0x02C | 2 | channel_count | 2 |

| 0x02E | 2 | stored_bits | 16 |

| 0x030 | 2 | valid_bits | 12 |

| 0x032 | 2 | sample_format | 1＝signed little-endian |

| 0x034 | 4 | payload_bytes | 本块 ADC 数据字节数 |

| 0x038 | 4 | payload_crc32c | 对负载计算，初值全 1、最终取反 |

| 0x03C | 4 | header_crc32c | 对头部指定范围计算 |

| 0x040 | 448 | reserved | 清零，供未来扩展 |


| 当前代码状态 现有 Writer 已计算 sequence 和 payload_crc32c，并随描述符送到 NVMe 命令桥；仿真也检查这两个值。为了保持第一版通路简单，512 B 元数据尚未作为 DDR 负载写入。接厂商 IP 时，增加一个 metadata composer，把元数据头与 payload 组成连续 DMA 区域，或先发 1 个头部命令再发 payload 命令。前者更便于一次命令落盘。 |


# 9. NVMe、PCIe RC 与“无需软件”

NVMe SSD 是 PCIe Endpoint。FPGA 上的 NVMe Host Controller 承担主机角色，因此 PCIe 底层必须是 Root Complex；厂商只提供 RC 形式源码，方向上是正确的。若把 FPGA 配成 EP，它只能被另一台主机枚举，不能直接把同一块 SSD 当作下游设备管理。

“无需软件”不等于“不需要寄存器和 doorbell”。NVMe 仍然存在控制器初始化、Admin Queue、I/O Submission Queue、Completion Queue 和 SQ/CQ doorbell。差别只在于这些动作由厂商RTL 状态机/IP 内部完成，而不是 CPU 驱动完成。调试用软核可以读取状态、打印日志或下发测试参数，但不应位于 1 GB/s 实时数据面。

# 10. 厂商 IP 接口替换清单

| 必须确认 | 为什么必须确认 | 接入动作 |

| NVMe 数据面 AXI 是 Master 还是 Slave | 决定谁从 DDR 发起读事务 | 连接 SmartConnect 并做地址映射 |

| 命令提交接口及寄存器表 | 当前 AXI-Lite 地址只是占位 | 重写 nvme_axil_cmd_bridge |

| IP 是否内部初始化 Admin/I/O Queue | 决定是否真的不需要 CPU | 核对复位到 ready 的状态序列 |

| DMA 地址宽度和地址含义 | 物理地址、窗口地址可能不同 | 统一 DDR_BASE 和 Address Editor |

| LBA 大小与 MDTS | 决定 NLB、分块上限 | Identify 后锁定参数 |

| 完成状态、Tag 和最大 outstanding | 决定何时回收 DDR 分段 | 扩展调度器队列 |

| PCIe 代际、lane 数和硬核配置 | 决定链路吞吐上限 | 至少验证 Gen3 x4 及实际 payload 吞吐 |

| 缓存一致性要求 | 纯 FPGA 一般无 CPU cache，但 IP 可能有窗口 | 按厂商手册处理 barrier/flush |


# 11. 占位 AXI-Lite 寄存器协议

下表仅用于本工程的 NVMe 仿真桩，不是厂商 IP 事实。它让调度器、命令握手和完成回收可以在没有正式 IP 时先行验证。接入时允许整体替换。

| 地址 | 名称 | 方向 | 定义 |

| 0x004 | DDR_ADDR_LO | W | DMA 源地址低 32 bit |

| 0x008 | DDR_ADDR_HI | W | DMA 源地址高 32 bit |

| 0x00C | SLBA_LO | W | 起始 LBA 低 32 bit |

| 0x010 | SLBA_HI | W | 起始 LBA 高 32 bit |

| 0x014 | NLB | W | NVMe 0-based block count |

| 0x018 | TAG | W | 分段/命令标签 |

| 0x01C | SEQUENCE | W | 分块序号 |

| 0x020 | EXPECTED_CRC | W | 负载 CRC32C |

| 0x024 | CTRL | W | bit0 start；bit1 completion ack |

| 0x028 | STATUS | R | ready/busy/done/error、状态码和 tag |


# 12. 验证结果与验收计划

| 检查项 | 当前结果 | 证据/判定 |

| Vivado 2020.2 编译与展开 | 通过 | KU040 目标器件；SystemVerilog＋XPM |

| 行为仿真 | 通过 | 4096 个样本对、4 个 4096 B 分段 |

| ADC 丢样 | 0 | accepted=4096，dropped=0 |

| DDR 内容 | 通过 | 逐 32 bit 样本比对两路符号扩展数据 |

| NVMe 命令 | 通过（仿真桩） | 4 次提交/完成，最后 SLBA=2072，NLB=7 |

| CRC32C | 通过 | 最后分段的 RTL/测试平台计算一致 |

| KU040 OOC 综合 | 通过 | 0 errors/0 critical warnings；仅有未加板级 XDC 的时钟告警 |


OOC 综合资源结果：1125 个 CLB LUT、1274 个寄存器、5 个 RAMB36E2、0 个 DSP。该数字只覆盖本基础 RTL，不含 DDR MIG、PCIe/NVMe IP、UltraScale ADC PHY 和 ILA。由于当前没有板级 XDC，timing_ooc.rpt 的时钟/IO 未约束告警属于预期，不能用该报告判断最终时序收敛。

## 12.1 板级递进验收

只接 DDR：固定模式写入、读回，比对地址边界和 Burst 响应。

只接 NVMe：沿用厂商自测流程，确认 RC 枚举、Identify 和原始 LBA 写读。

DDR→NVMe：预置递增数据，写入指定 LBA，电脑导出后逐字节比对。

ADC→DDR：以内部计数模式替代 ADC，确认 1 GB/s 等效流量下无 overflow。

ADC→DDR→NVMe：短时采集，检查 magic、sequence、CRC 和 LBA 连续性。

长稳测试：覆盖计划采集时长，记录 FIFO 水位、SSD 温度、PCIe 重训和错误计数。

## 12.2 最低通过条件

整个采集区间 dropped_sample_pairs 恒为 0，AXI B/R 响应无错误。

电脑导出的 sequence 连续，无重复、倒退或缺块。

每个 payload 的 CRC32C 一致；末块允许通过 flags 标记截断。

NVMe 完成状态全部成功后才释放 DDR 分段。

SSD 在目标温度和容量区间内的稳态写速率高于 1 GB/s，并保留工程裕量。

# 13. 工程目录与使用方法

nvme_adc_axi_pipeline/
  rtl/                 # 可综合数据面和控制面
  rtl/stubs/           # 仅行为仿真
  sim/                 # 端到端自检测试平台
  scripts/             # Vivado 2020.2 仿真/综合 Tcl
  docs/                # 本设计方案

& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_sim.tcl

& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_synth.tcl

# 14. 下一步实施顺序

向厂商索取接口手册、完整 example design、寄存器表、时钟复位要求和 MDTS 说明。

确定 KU040 板卡、PCIe lane/速率、DDR MIG 数据宽度和 Address Editor 地址图。

完成 UltraScale ADC PHY 适配，先以 ILA 验证两路 12 bit 样本顺序。

用真实 MIG 替换 DDR stub，完成 DDR 固定模式写读和并发带宽测试。

按厂商接口重写 NVMe adapter，先写固定 DDR 模式到测试盘原始 LBA。

增加 512 B metadata composer，再接通 ADC 短采、导出和 CRC 校验。

最后提高分块大小和 outstanding 数，做长稳、温度和异常断链测试。

# 附录 A：本次参考路径

远端 ADC：C:\project\RTDS\BUFR_RPT201-1\idelay_2018\RPT201

远端 DDR：C:\project\RTDS\DDR\26_top_ddr4_rw

本地基础工程：E:\NVME_PRO\nvme_adc_axi_pipeline

厂商自测材料：E:\NVME_PRO\NVMe_Host_Controller_自测报告.docx

按用户要求，不以《NVMe协议研究报告.docx》作为设计依据。
