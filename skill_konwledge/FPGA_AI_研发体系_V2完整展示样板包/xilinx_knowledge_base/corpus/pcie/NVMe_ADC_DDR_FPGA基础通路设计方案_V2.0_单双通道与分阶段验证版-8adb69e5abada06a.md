# NVMe_ADC_DDR_FPGA基础通路设计方案_V2.0_单双通道与分阶段验证版

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案_V2.0_单双通道与分阶段验证版.docx`
- SHA-256: `8adb69e5abada06a0098353e2f823702e8bf67d76715595890efbb883d23855e`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案_V2.0_单双通道与分阶段验证版.docx

内部设计说明

NVMe–DDR–ADC FPGA
基础通路设计方案

单/双通道运行配置｜真实 DDR 分阶段 Bring-up｜第三方 NVMe 可替换边界

| 项目项 | 内容 |

| 目标器件/工具 | XCKU040-FFVA1156-2-I｜Vivado 2020.2 |

| 文档版本 | V2.0｜单双通道与分阶段验证版｜2026-07-26 |

| 设计预设 | compact_reference_guide｜memo_masthead |

| 当前阶段 | RTL 骨架与自动化仿真已完成；真实 MIG/XDC、ADC PHY 和第三方 NVMe IP 未接入 |

| 固定存储方式 | 第一版使用 Raw LBA；文件系统由后续嵌入式软件实现 |


| 先看结论 现有工程已经从“只支持双通道的概念骨架”改成同一 bitstream 支持单 CH0、单 CH1 和双通道。ADC 数据在 ADC 时钟域先打包成 256 bit，再跨时钟写入 DDR。第三方 NVMe IP 仍由通用请求/完成接口隔离。当前没有板卡 DDR 参数、MIG 和 XDC，因此不能声称真实 DDR 或完整 SSD 通路已经完成。 |


# 1. 文档范围和状态口径

本文面向第一次接触 FPGA、DDR 和 NVMe 的读者。它先解释系统里每一段数据由谁产生、由谁保存、什么时候可以覆盖，再给出当前代码和后续板级工作的边界。V1.0 文档作为历史基线保留，V2.0 不覆盖旧文件。

| 状态词 | 准确含义 |

| 已实现 | 已有可综合 RTL 或可执行脚本，并经过当前级别的检查 |

| 仿真桩 | 只代替接口行为，不实现真实 DDR、PCIe 或 NVMe |

| 待真实集成 | 需要板卡参数、MIG/XDC、供应商 IP 或真实硬件 |

| 仿真通过 | 只证明测试平台覆盖的数字逻辑行为 |

| 完整 SSD 闭环通过 | 必须在真实 DDR、PCIe、NVMe IP 和 SSD 上写后读回一致 |


| 重要限制 下周供应商只允许测试，不交付 IP 文件。现场最多完成供应商 Demo 基线复现、参数测试或我方 DDR 数据接口预演。没有获得可复现 IP 工程前，结果不能标记为“我方工程集成通过”。 |


# 2. 三种运行配置

| 模式 | 配置 | 每个采样时刻的存储内容 | 数据率 |

| 单通道 CH0 | two_channel=0, select=0 | CH0 符号/零扩展后的 16 bit | 500 MB/s |

| 单通道 CH1 | two_channel=0, select=1 | CH1 符号/零扩展后的 16 bit | 500 MB/s |

| 双通道 | two_channel=1 | {CH1[15:0], CH0[15:0]} | 1 GB/s |


单通道是紧凑 16 bit 格式，不会在未使用通道的位置补 16 bit 的零。`sample_count` 在三种模式下都表示采样时刻数量，因此切换模式不会改变计数含义。

符号扩展：ch16 = {{4{adc_ch[11]}}, adc_ch[11:0]}
零扩展：  ch16 = {4'b0000, adc_ch[11:0]}
双通道内存字节序：CH0低字节、CH0高字节、CH1低字节、CH1高字节

## 2.1 配置何时生效

控制端等待 `capture_ready=1`。

给出 `capture_start`，RTL 在该握手时锁存通道模式、选择和 Capture ID。

采集期间修改外部配置不会改变当前数据格式。

检测到采集中配置变化时置位 `config_change_sticky`。

下一次 Capture 才可使用新的通道配置。

# 3. 总体数据通路

真实ADC PHY/内部数据发生器
          │ 2×12 bit @ 250 MHz
          ▼
adc_channel_packer（ADC时钟域）
          │ 256 bit + valid_bytes + EOC
          ▼
263 bit异步FIFO（ADC clk → DDR UI clk）
          ▼
adc_ddr_segment_writer → AXI4 Burst → SmartConnect → MIG → DDR
          │ READY描述符
          ▼
segment_buffer_manager → nvme_request_scheduler
          ▼
NVMe后端Stub / MicroBlaze Mailbox / 第三方NVMe Host IP
          ▼
PCIe Root Complex → NVMe SSD

| 模块 | 职责 | 当前状态 |

| adc_channel_packer | 模式锁存、12→16 bit、ADC域256 bit打包、尾拍 | 已实现/已仿真 |

| axis_async_fifo | 263 bit CDC 和微秒级短抖动缓存 | XPM FIFO，已仿真 |

| adc_ddr_segment_writer | AXI Burst、4 KiB补零、CRC、Commit页 | 已实现/接假DDR验证 |

| segment_buffer_manager | Segment所有权、generation Tag、错误保持 | 已实现/已仿真 |

| nvme_request_scheduler | WRITE/Flush/Commit顺序、超时和链路监控 | 已实现/接假NVMe验证 |

| MIG/SmartConnect | 真实DDR控制和多Master仲裁 | 待板卡参数 |

| 第三方NVMe Host IP | PRP、SQ/CQ、PCIe RC、SSD命令 | 待购买交付 |


# 4. ADC域打包与263 bit异步FIFO

V1.0 的思路是 32 bit 样本对先跨时钟，再在系统域累积成 256 bit。当系统域只有 125 MHz 时，32 bit×125 MHz 只有 500 MB/s，无法承载双通道1 GB/s。V2.0 改成 ADC 域先扩宽。

| 模式 | 组成一个256 bit字所需样本 | 平均输出频率 |

| 双通道 | 8个采样时刻 × 32 bit | 31.25 MHz |

| 单通道 | 16个样本 × 16 bit | 15.625 MHz |


| 信号 | 方向 | 宽度 | 时钟域 | 含义 |

| data[255:0] | 出 | 256 | ADC→SYS | 打包后的真实数据；未使用尾部补零 |

| valid_bytes[5:0] | 出 | 6 | ADC→SYS | 该字真实有效字节数，范围0～32 |

| end_of_capture | 出 | 1 | ADC→SYS | 最后一个数据字或零字节结束标记 |

| tvalid/tready | 双向 | 1 | ADC→SYS | 标准有效/就绪握手；停顿时Payload保持稳定 |


FIFO 默认深度为 1024×263 bit。双通道每个256 bit字代表32 Byte，所以可缓存1024×32 Byte÷1 GB/s≈32.8 µs；单通道输入减半，可缓存约65.5 µs。

| FIFO不是SSD缓存 FIFO只吸收 CDC 相位差、MIG 刷新和短时仲裁。毫秒级 SSD 停顿必须由外部 DDR Segment 承担。即使把 BRAM FIFO 做得很大，也不能弥补 SSD 长期平均速度不足。 |


# 5. Capture开始、停止和尾段

IDLE --capture_start&&capture_ready--> ACTIVE
ACTIVE --capture_stop--> DRAIN
DRAIN --最后一个EOC字被接收--> IDLE

不足 256 bit 的最后一拍在高位补零，`valid_bytes`记录真实字节数。

如果最后一拍正好是完整 256 bit，会追加一个 `valid_bytes=0` 的 EOC 标记。

DDR 中 Payload 后部补零到 4 KiB，`payload_bytes`保留真实长度。

CRC32C只覆盖真实 Payload，不覆盖补零区。

样本数、Capture ID、Sequence 和字节计数均为64 bit。

| 采集时长/样本数 | 双通道真实数据 | 单通道真实数据 |

| 10 µs / 2500 | 10,000 Byte | 5,000 Byte |

| 50 µs / 12,500 | 50,000 Byte | 25,000 Byte |

| 100 µs / 25,000 | 100,000 Byte | 50,000 Byte |

| 1 ms / 250,000 | 1,000,000 Byte | 500,000 Byte |


# 6. DDR分段为什么仍然需要

DDR分段只是把同一块 DDR 地址空间逻辑划成多个固定区域，不是要求多颗 DDR。它解决的是所有权：ADC 正在写哪个区域、NVMe 正在读哪个区域、哪个区域允许覆盖。

FREE → FILLING → READY → INFLIGHT → FREE
                    └─DDR/NVMe错误或超时→ ERROR_HOLD

| 状态 | 谁拥有 | 允许操作 |

| FREE | Buffer Manager | 可分配给ADC Writer |

| FILLING | ADC Writer | 只允许继续写入，不得提交NVMe |

| READY | 调度器待处理队列 | 可提交NVMe请求，不得覆盖 |

| INFLIGHT | NVMe请求 | 等待成功Completion，不得覆盖 |

| ERROR_HOLD | 故障诊断 | 冻结内容，系统复位/人工处理后再释放 |


Segment 在分配给 Writer 的同一拍立即离开 FREE；只有匹配 Tag 的成功 Completion 才能返回 FREE。当前参数化建议为：仿真4 KiB，DDR初联1 MiB×8，产品候选4 MiB×16。最终大小取决于 DDR 容量和 SSD 最长停顿。

## 6.1 Generation Tag

项目内部 Tag 使用 `{generation, segment_id}`。Segment 0 第一次使用和第二次使用的 Tag 不同。即使复位、超时后出现迟到 Completion，也不能把新一代Segment 误释放。Tag 不等于供应商 IP 内部每条 NVMe SQE 的 CID。

# 7. DDR Writer和Commit页

Writer从263 bit FIFO取得数据并写入同步Beat FIFO。

AXI4按固定 INCR Burst 写入当前Segment。

Capture尾段补零到4 KiB；完整Segment不额外补零。

收到最后一个B响应后才生成READY描述符。

Payload排空后，在保留DDR地址生成4 KiB Commit页。

| Commit字段 | 宽度 | 含义 |

| magic | 64 bit | 固定标识 ADCCOMM1 |

| version/mode | 32 bit内 | 格式版本、单/双通道和通道选择 |

| capture_id | 64 bit | 本次采集编号 |

| sample_count | 64 bit | 真实采样时刻数 |

| payload_bytes | 64 bit | 未补零的真实Payload总字节 |

| segment_count | 32 bit | 本次Capture使用的Payload Segment数 |


# 8. NVMe可替换边界

当前工程不再把项目命令转换成一套假定的供应商 AXI-Lite 寄存器。上层只认识下面的通用请求/完成字段。

| 信号 | 方向 | 宽度 | 时钟域 | 含义 |

| req_opcode | 出 | 2 | SYS | WRITE、READ或FLUSH |

| req_ddr_addr | 出 | 64 | SYS | Payload或Commit页在FPGA DDR中的地址 |

| req_byte_len | 出 | 32 | SYS | DMA长度；WRITE/READ按4KiB对齐 |

| req_slba | 出 | 64 | SYS | SSD目标逻辑块地址 |

| req_user_tag | 出 | 16 | SYS | 项目级请求关联Tag |

| cpl_user_tag | 入 | 16 | SYS | 完成返回的项目级Tag |

| cpl_status | 入 | 16 | SYS | 0表示成功，非0进入错误处理 |


| 后端 | 用途 | Payload是否复制 |

| nvme_req_cpl_stub | 行为仿真；固定延迟并可注入错误 | 不读取DDR |

| nvme_mailbox_backend | PL描述符交给MicroBlaze厂商API | 不复制 |

| 供应商IP Adapter | 购买后连接正式接口 | 应直接使用DDR地址 |


## 8.1 一个请求在途

项目层当前一次只提交一个大请求，收到完成后再提交下一个。供应商 IP 可以把这个大请求按 MDTS 拆成多条 SQE 并在内部流水。第一版不做应用层多 Outstanding，先降低 Tag、乱序完成、超时和错误恢复的集成复杂度。

# 9. Flush和Capture完成顺序

capture_stop
  → 排空所有Payload WRITE
  → FLUSH #1
  → Commit Metadata WRITE
  → FLUSH #2
  → capture_done

供应商资料显示支持 Flush、不支持 FUA，性能测试开启SSD写缓存且没有逐命令Flush。V2.0不会每个Segment都Flush，以免吞吐和尾延迟恶化；但Capture完成必须经过上述两次Flush。真实持久性仍取决于SSD写缓存和掉电保护。

# 10. 错误和冻结策略

| 事件 | 检测 | 第一版处理 |

| DDR BRESP错误 | Writer检查B通道 | Segment进入ERROR_HOLD，置位AXI错误 |

| NVMe完成错误 | cpl_status非0 | 当前Segment ERROR_HOLD，fatal_error |

| Tag错误 | 完成Tag不等于请求Tag | 状态FFFF，禁止释放Segment |

| 命令超时 | command_age达到阈值 | Segment ERROR_HOLD，timeout_sticky |

| PCIe Link Down | pcie_link_up失效 | 冻结采集/命令，link_down_sticky |

| ECQE错误 | ecqe_error_valid | 记录状态并进入fatal |

| Flush失败 | Flush完成非0 | Capture不得标记完成 |


| 不要自动覆盖 超时不等于命令一定没有访问DDR。第一版发生超时后保留INFLIGHT Segment，不猜测命令结果，也不让ADC覆盖。由MicroBlaze执行供应商定义的Reset/重初始化；如果无法可靠恢复，则走系统级复位。 |


# 11. 真实DDR为什么要先于NVMe

真实 ADC→DDR 验证不需要等待第三方 NVMe IP，而且有必要先做。这样可以把DDR颗粒、引脚、校准和带宽问题与PCIe/NVMe问题隔离。当前工作区没有MIG/XDC，因此只提供接口壳和输入清单，不生成猜测配置。

项目组提供DDR完整颗粒、原理图引脚、时钟、Rank、位宽和速率。

按真实参数生成UltraScale Memory IP/MIG。

先跑官方Example Design，确认init_calib_complete和多种Pattern读写。

接内部数据发生器，分别模拟500 MB/s和1 GB/s写入。

增加独立AXI Reader读回并计算CRC；ILA观察FIFO水位和AXI Stall。

DDR稳定后再接真实ADC PHY、DCO、IDELAY和解串。

## 11.1 SmartConnect放在哪里

ADC DDR Writer M_AXI ─┐
NVMe IP DDR M_AXI ────┼─ SmartConnect ─ MIG S_AXI ─ DDR
MicroBlaze M_AXI ─────┘

SmartConnect负责多个AXI Master的地址译码、仲裁和响应路由。它不是DDR控制器，也不是缓存。若NVMe读请求长期占用DDR，ADC Writer仍可能被背压，因此必须保留FIFO并用ILA实测最长停顿。

# 12. PCIe官方IP能做什么

| 能力 | AMD官方PCIe Root Port Example | 第三方NVMe Host |

| PCIe链路训练/Gen/Lane | 可以 | 应包含 |

| 配置空间/BAR/TLP | 可以 | 应包含或封装 |

| NVMe SQ/CQ/PRP/Doorbell | 不可以 | 必须提供 |

| Identify/Read/Write/Flush | 不可以 | 必须提供 |

| 写入商用NVMe SSD | 不能单独完成 | 目标能力 |


购买前可以建立独立PCIe Bring-up工程验证GT、Refclk、PERST#、链路宽度和基础TLP，但不要在拿到第三方IP前并入主工程。供应商通常不会交付“PCIe硬核源码”；应交付可复现的XCI/Tcl/DCP、Wrapper、约束和复位顺序。

# 13. 下周供应商现场测试

| 测试结论分级 固定Demo只能标记为供应商基线复现；允许调参数可标记为黑盒验收；允许我方先在DDR准备带CRC的数据并写后读回，才可标记为接口预演。没有IP交付，任何一级都不等于我方Vivado工程完成集成。 |


提前书面确认供应商携带bitstream、现场生成还是远程操作工程。

确认是否需要我方MIG/XDC；当前工作区没有这些参数。

记录SSD、PCIe速率/Lane、数据源、I/O大小、Cache和Flush设置。

可调时测试4 KiB、512 KiB、4 MiB、1 GiB Write/Read和Flush。

保存平均带宽、最低1秒带宽、最长停顿、温度和完整读回结果。

双通道验收建议平均持续写不低于1.2 GB/s，并覆盖SLC Cache之后的容量。

# 14. 项目组必须确认的输入

| 类别 | 必须提供 |

| FPGA/板卡 | 完整器件/封装/速度等级、PCB和原理图版本、Bank/GT位置 |

| DDR | 颗粒型号/数量、组织/位宽/Rank/速率、全部引脚、CK/VREF/ODT、可用容量 |

| ADC | 型号、码制、LVDS、DCO、单双沿、Lane位序/极性、触发和测试模式 |

| PCIe/SSD | 接口形式、Lane/GT、100MHz Refclk/SSC、PERST#、供电和散热 |

| 系统需求 | 最长采集、丢样策略、Raw LBA范围、Flush/掉电、读回和温度要求 |


完整可勾选清单位于项目根目录 `board_bringup_inputs.md`；供应商交付和现场测试问题位于 `vendor_ip_contract.md`。

# 15. 当前代码和报告

| 项目 | 当前结果 |

| 行为回归 | 三组测试：模式/边界、端到端骨架、NVMe异常；详见独立验证文档 |

| CDC压力 | 250 MHz ADC → 125 MHz SYS，随机AXI背压，无丢样 |

| OOC综合 | 2259 LUT、2377 Register、11×RAMB36E2、1×RAMB18E2、0 DSP |

| 综合状态 | 0 error、0 critical warning；无板级XDC，不能作为最终时序 |

| 真实硬件 | MIG、XDC、ADC PHY、PCIe、NVMe IP、SSD均待集成 |


# 附录A：主要RTL文件

| 文件 | 作用 |

| rtl/adc_channel_packer.sv | 单/双通道ADC域打包和Capture控制 |

| rtl/axis_async_fifo.sv | 263 bit XPM异步FIFO |

| rtl/adc_ddr_segment_writer.sv | DDR AXI写、补零、CRC和Commit页 |

| rtl/segment_buffer_manager.sv | Segment状态和generation Tag |

| rtl/nvme_request_scheduler.sv | 通用NVMe请求顺序和错误监控 |

| rtl/nvme_mailbox_backend.sv | PL到MicroBlaze描述符Mailbox边界 |

| rtl/stubs/*.sv | 只用于行为仿真的DDR/NVMe桩 |


| V2.0完成定义 V2.0的完成范围是：RTL骨架、自动化仿真、可替换NVMe边界和板级Bring-up输入清单。真实MIG/XDC、ADC PHY和供应商IP只有在对应资料到位并通过上板测试后，才能进入下一版状态。 |
