# fdma_aurora_brg IP设计_关键电路与连续时序补充版

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\fdma_aurora_brg IP设计_关键电路与连续时序补充版.docx`
- SHA-256: `193b1b884127eacc4b1fae0e1e4dacdff33e37645486ad3a16085f9037d61b33`
- Extractor: `python-docx+zip-structure-check`
- Tags: `aurora, bridge, design, fdma, pcie`
- Duplicate sources:
  - none

| 产品名称Product name | 密级Confidentiality level |

| RTDS |  |

| 产品版本Product version | Total 27 pages 共 27 页 |

| V1.0 | Total 27 pages 共 27 页 |


FDMA2LocalLink IP开发详细设计方案

| Prepared by 拟制 |  | Date 日期 | 2026-4-30 |

| Reviewed by 评审人 |  | Date 日期 |  |

| Approved by 批准 |  | Date 日期 |  |


Revision Record 修订记录

| Revision Version 修订版本 | Change Description 修改描述 | Author 作者 | Date 日期 |

| 1.0 | 完成初稿 |  | 26.4.30 |

| V1.1 | 增加关键电路、连续波形、读图规范和 RTL 对照分析 | 设计组 | 2026-08-13 |


目录

Revision Record 修订记录	2

目录	3

1 概述	3

1.1 设计背景	3

1.2 设计架构	4

1.3 接口列表	4

1.4 时钟和复位管理	7

1.4.1 时钟管理	7

1.4.2 复位管理	7

2 子模块设计	7

2.2 local link到FDMA接口转化模块设计	7

2.2.1 规格概述	7

2.2.2 接口列表	8

2.2.3 接口时序	8

2.2.4 功能设计	9

2.3 FDMA 到local link接口转化模块设计	11

2.3.1 规格概述	11

2.3.2 接口列表	11

2.3.3 接口时序	12

2.3.4 功能设计	12

3 UT测试	16

3.1 测试环境与用例	16

3.4 测试步骤与判定	19

1 概述

1.1 设计背景

在现代 FPGA 高速数据通信系统中，常常需要将片内存储器通过 DMA 接口（如 FDMA）与外部高速串行链路（如Aurora、PCIe）连接。这两者之间存在频率与协议差异，且需要实现可靠的数据缓冲与流控。鉴于此，本设计旨在实现连接两者的双向桥接模块，同时在两个方向上传输数据：

发送方向：将 FDMA 读操作获取的数据以连续帧的形式通过 Local Link 接口发送出去，可作为 Aurora 发送路径的前端桥接器。

接收方向：从Local Link接口以连续帧的形式发送数据，再通过FDMA写操作，写入存储器。

本设计中，FDMA 接口运行在250MHz的较高频率，数据总线是64位，可提供约16 Gbps 的带宽；Local Link 接口用于 Aurora 64B/66B 核的用户侧，运行在约161MHz的较低频率，数据总线是64位，带宽约10 Gbps。Local Link 接口即用户侧的带宽要求小于FDMA处带宽，因此可以满足系统设计。

1.2 设计架构

本设计实现FDMA接口到LL接口的双向转换。整体架构分为fdma_aurora_brg_tx、fdma_aurora_brg_rx两部分。

fdma_aurora_brg_tx将FDMA的读从机读出的数据写入AFIFO，再从AFIFO读出送到LL TX模块。fdma_aurora_brg_rx将LL RX模块接收的数据写入AFIFO，再从AFIFO读出送到FDMA的写从机。

图1 系统顶层设计框图

1.3 接口列表

| 信号 | 方向 | 方向 | 位宽 | 位宽 | 描述 |

| 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 |

| fdma_clk | I | 1 | 1 | FDMA 侧时钟 250 MHz | FDMA 侧时钟 250 MHz |

| fdma_rstn | I | 1 | 1 | FDMA 侧异步复位 | FDMA 侧异步复位 |

| user_clk | I | 1 | 1 | Local Link 侧时钟 约161MHz | Local Link 侧时钟 约161MHz |

| user_rstn | I | 1 | 1 | Local Link 侧异步复位 | Local Link 侧异步复位 |

| channel_up | I | 1 | 1 | Local Link 侧Aurora通道建立标志 | Local Link 侧Aurora通道建立标志 |

| FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） |

| fdma_raddr | O | 32 | 32 | FDMA 读接口的读地址 | FDMA 读接口的读地址 |

| fdma_rareq | O | 1 | 1 | FDMA 读接口的读请求 | FDMA 读接口的读请求 |

| fdma_rbusy | I | 1 | 1 | FDMA 读接口的读忙 | FDMA 读接口的读忙 |

| fdma_rdata | I | 64 | 64 | FDMA 读接口的读数据 | FDMA 读接口的读数据 |

| fdma_rvalid | I | 1 | 1 | FDMA 读接口的读数据有效 | FDMA 读接口的读数据有效 |

| FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） |

| fdma_waddr | O | 32 | 32 | FDMA 写接口的写地址 | FDMA 写接口的写地址 |

| fdma_wareq | O | 1 | 1 | FDMA 写接口的写请求 | FDMA 写接口的写请求 |

| fdma_wbusy | I | 1 | 1 | FDMA 写接口的写忙 | FDMA 写接口的写忙 |

| fdma_wdata | O | 64 | 64 | FDMA 写接口的写数据 | FDMA 写接口的写数据 |

| fdma_wvalid | O | 1 | 1 | FDMA 写接口的写数据有效 | FDMA 写接口的写数据有效 |

| fdma_wsize | O | 16 | 16 | FDMA 写接口的写突发长度（单位为字节） | FDMA 写接口的写突发长度（单位为字节） |

| Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） |

| aurora_tx_d | O | 64 | 64 | Local Link 发送接口的接收数据 | Local Link 发送接口的接收数据 |

| aurora_tx_rem | O | 3 | 3 | Local Link 发送接口的最后一拍有效字节数 | Local Link 发送接口的最后一拍有效字节数 |

| aurora_tx_sof | O | 1 | 1 | Local Link 发送接口的帧开始 | Local Link 发送接口的帧开始 |

| aurora_tx_eof | O | 1 | 1 | Local Link 发送接口的帧结束 | Local Link 发送接口的帧结束 |

| aurora_tx_src_rdy | O | 1 | 1 | Local Link 发送接口的源就绪 | Local Link 发送接口的源就绪 |

| aurora_tx_dst_rdy | I | 1 | 1 | Local Link 发送接口的目的就绪 | Local Link 发送接口的目的就绪 |

| Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） |

| aurora_rx_d | I | 64 | 64 | Local Link 接收接口的接收数据 | Local Link 接收接口的接收数据 |

| aurora_rx_rem | I | 3 | 3 | Local Link 接收接口的最后一拍有效字节数 | Local Link 接收接口的最后一拍有效字节数 |

| aurora_rx_sof | I | 1 | 1 | Local Link 接收接口的帧开始 | Local Link 接收接口的帧开始 |

| aurora_rx_eof | I | 1 | 1 | Local Link 接收接口的帧结束 | Local Link 接收接口的帧结束 |

| aurora_rx_src_rdy | I | 1 | 1 | Local Link 接收接口的源就绪 | Local Link 接收接口的源就绪 |

| aurora_rx_dst_rdy | O | 1 | 1 | Local Link 接收接口的目的就绪（恒为1，LL不支持反压；FIFO反压通过写使能fifo_almost_full实现） | Local Link 接收接口的目的就绪（恒为1，LL不支持反压；FIFO反压通过写使能fifo_almost_full实现） |


1.4 时钟和复位管理

1.4.1 时钟管理

两个时钟域独立，异步 FIFO 提供跨时钟域隔离。

1.4.2 复位管理

每个域使用异步复位、同步释放策略。FIFO复位分别为：TX侧fifo_rst=~fdma_rstn，RX侧fifo_rst=~user_rstn。复位忙期间(wr_rst_busy/rd_rst_busy)禁止FIFO读写操作。

fdma_rstn 和 user_rstn 分别作为两个时钟域的复位源。TX模块FIFO复位取~fdma_rstn，RX模块FIFO复位取~user_rstn。channel_up信号通过cdc_sync两级触发器同步到fdma_clk域。

2 子模块设计

2.2 local link到FDMA转化模块（RX）

2.2.1 规格概述

该模块将 LocalLink 接口转换为 FDMA 接口，主要任务包括：

从 Local Link 接收接口接收数据帧，写入异步 FIFO。

FDMA 写模块从 FIFO 中读取数据，以突发形式写入存储器。

每两个数据帧恰好组成 256 字（2×128=256），正好是 4 个 FDMA 突发。需要合理对齐地址和帧边界。

FDMA支持反压：FDMA 写侧受 fdma_wbusy 反压。

LL 不支持反压：LL 接收侧aurora_rx_dst_rdy恒为1，不接受下游模块反压。FIFO反压通过fifo_almost_full在写使能端实现，当FIFO接近满时停止写入。

2.2.2 接口列表

| 信号 | 方向 | 方向 | 位宽 | 位宽 | 描述 |

| 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 |

| fdma_clk | I | 1 | 1 | FDMA 侧时钟 250 MHz | FDMA 侧时钟 250 MHz |

| fdma_rstn | I | 1 | 1 | FDMA 侧异步复位 | FDMA 侧异步复位 |

| user_clk | I | 1 | 1 | Local Link 侧时钟 约161MHz | Local Link 侧时钟 约161MHz |

| user_rstn | I | 1 | 1 | Local Link 侧异步复位 | Local Link 侧异步复位 |

| channel_up | I | 1 | 1 | Local Link 侧Aurora通道建立标志 | Local Link 侧Aurora通道建立标志 |

| FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） | FDMA 写接口（接收方向） |

| fdma_waddr | O | 32 | 32 | FDMA 写接口的写地址 | FDMA 写接口的写地址 |

| fdma_wareq | O | 1 | 1 | FDMA 写接口的写请求 | FDMA 写接口的写请求 |

| fdma_wbusy | I | 1 | 1 | FDMA 写接口的写忙 | FDMA 写接口的写忙 |

| fdma_wdata | O | 64 | 64 | FDMA 写接口的写数据 | FDMA 写接口的写数据 |

| fdma_wvalid | O | 1 | 1 | FDMA 写接口的写数据有效 | FDMA 写接口的写数据有效 |

| fdma_wsize | O | 16 | 16 | FDMA 写接口的写突发长度（单位为字节） | FDMA 写接口的写突发长度（单位为字节） |

| Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） | Local Link 接收接口（接收方向） |

| aurora_rx_d | I | 64 | 64 | Local Link 接收接口的接收数据 | Local Link 接收接口的接收数据 |

| aurora_rx_rem | I | 3 | 3 | Local Link 接收接口的最后一拍有效字节数 | Local Link 接收接口的最后一拍有效字节数 |

| aurora_rx_sof | I | 1 | 1 | Local Link 接收接口的帧开始 | Local Link 接收接口的帧开始 |

| aurora_rx_eof | I | 1 | 1 | Local Link 接收接口的帧结束 | Local Link 接收接口的帧结束 |

| aurora_rx_src_rdy | I | 1 | 1 | Local Link 接收接口的源就绪 | Local Link 接收接口的源就绪 |

| aurora_rx_dst_rdy | O | 1 | 1 | Local Link 接收接口的目的就绪（恒为1，LL不支持反压；FIFO反压通过写使能fifo_almost_full实现） | Local Link 接收接口的目的就绪（恒为1，LL不支持反压；FIFO反压通过写使能fifo_almost_full实现） |


2.2.3 接口时序

模块接口的时序图如下：

图中可以看到。

图4  Aurora LL2AXIS模块时序

2.2.4 功能设计

2.2.4.1 FDMA写控制功能设计

FDMA 写控制模块负责从异步 FIFO 中读取数据，按照 Local Link 协议格式发送出去。

FIFO读使能管理

在状态机进入WR_DATA状态，且满足!fifo_empty && fdma_wbusy && !rd_rst_busy时产生读使能。

FDMA 写控制模块状态机使用 4 个状态，由 fdma_clk 驱动。

| 状态名 | 编码 | 描述 |

| WR_IDLE | 2'b00 | 空闲，等待启动条件 |

| WR_REQ | 2'b01 | 请求阶段，置 wareq |

| WR_DATA | 2'b10 | 数据接收阶段，计数接收的字数 |

| WR_WAIT | 2'b11 | 等待阶段，等待 wbusy 撤消 |


状态转移条件如图所示，其中wr_burst_done 表示发完一个burst中最后一个数据。启动条件：channel_up_fdma（同步后的通道标志）为高，且 FIFO非空（!fifo_empty）。

基于MIG IP UI接口的应用开发

开展的工作：命令生成器设计，命令与数据分离设计，实现读写状态机与仲裁，管理命令与数据的匹配

意义与价值：这种应用具有高性能与灵活性，能够得到精细的时序控制

基于MIG IP AXI接口的应用开发

开展的工作：系统架构设计，主设备的标准AXI接口设计，地址空间划分，仲裁策略配置，数据宽度与时钟域转换

意义与价值：这种应用具有标准化与可扩展性，可以解决多主设备竞争

基于MIG IP 的FIFO 封装研究

开展的工作：设计突发传输参数，实现数据缓存与组装逻辑，处理写命令与写数据时序，地址生成管理

意义与价值：在流式数据传输场景下有利于性能提升，极大简化了接口，降低了用户使用难度

2.2.4.2 Local Link接受控制功能设计

Local Link 接受控制模块负责发起对Aurora IP的读操作，并将读回的数据写入异步 FIFO。

写地址管理

地址以字节为单位，初始为0，每次突发完成后增加512，当超过地址边界 4KB时回绕到 0。

FIFO写使能管理

在写数据有效且FIFO未满（!fifo_almost_full）且复位忙结束（!wr_rst_busy）时产生写使能，支持FIFO反压保护。

FIFO参数选择

| 参数 | 值 | 理由 |

| FIFO_WRITE_DEPTH | 1024 | 见下文分析。 |

| WRITE_DATA_WIDTH | 64 | Local Link数据宽度 |

| READ_DATA_WIDTH | 64 | FDMA数据宽度 |

| READ_MODE | "fwft" | First-Word Fall-Through，减少读延迟，提高吞吐 |

| CDC_SYNC_STAGES | 2 | 跨时钟域同步级数 |

| USE_ADV_FEATURES | "1f1f" | 使能所有高级功能（溢出、下溢、数据计数等） |


FIFO深度选择

写入速率：161.13 MHz × 8 B = 1289 MB/s

读出速率：250 MHz × 8 B = 2000 MB/s

净消耗速率 = 2000 - 1289 = 711 MB/s（FIFO 倾向于变空）

由于RX无法反压，必须确保读端平均速率大于写端，且深度足够覆盖最大阻塞。读端速度（16 Gbps） > 写端（10.3125 Gbps），满足平均速率，所以 FIFO 倾向变空不会长期积累。

深度 1024的FIFO吸收能力有8KB，可理论满足 FDMA 写最大阻塞约 6.2μs的极限场景（6.2 μs × 1289 MB/s ≈ 8KB），所以1024的深度在当前场景需求下足够安全。

2.3 FDMA 到local link转化模块（TX）

2.3.1 规格概述

该模块将 FDMA 接口转换为 LocalLink 接口，使 Aurora IP 核的接收端能够连接到FDMA 接口。主要任务包括：

从 FDMA 读接口读取固定长度（512 字节）的数据突发，写入异步 FIFO。

Local Link 发送模块从 FIFO 中读取数据，以固定帧长（1024 字节）发送，每帧由 128 个 64 位字组成。

支持反压：FDMA 读侧受 fdma_rbusy 控制，LL 发送侧受 aurora_tx_dst_rdy_n 控制。

2.3.2 接口列表

| 信号 | 方向 | 方向 | 位宽 | 位宽 | 描述 |

| 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 | 时钟与复位 |

| fdma_clk | I | 1 | 1 | FDMA 侧时钟 250 MHz | FDMA 侧时钟 250 MHz |

| fdma_rstn | I | 1 | 1 | FDMA 侧异步复位 | FDMA 侧异步复位 |

| user_clk | I | 1 | 1 | Local Link 侧时钟 约161MHz | Local Link 侧时钟 约161MHz |

| user_rstn | I | 1 | 1 | Local Link 侧异步复位 | Local Link 侧异步复位 |

| channel_up | I | 1 | 1 | Local Link 侧Aurora通道建立标志 | Local Link 侧Aurora通道建立标志 |

| FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） | FDMA 读接口（发送方向） |

| fdma_raddr | O | 32 | 32 | FDMA 读接口的读地址 | FDMA 读接口的读地址 |

| fdma_rareq | O | 1 | 1 | FDMA 读接口的读请求 | FDMA 读接口的读请求 |

| fdma_rbusy | I | 1 | 1 | FDMA 读接口的读忙 | FDMA 读接口的读忙 |

| fdma_rdata | I | 64 | 64 | FDMA 读接口的读数据 | FDMA 读接口的读数据 |

| fdma_rvalid | I | 1 | 1 | FDMA 读接口的读数据有效 | FDMA 读接口的读数据有效 |

| Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） | Local Link 发送接口（发送方向） |

| aurora_tx_d | O | 64 | 64 | Local Link 发送接口的接收数据 | Local Link 发送接口的接收数据 |

| aurora_tx_rem | O | 3 | 3 | Local Link 发送接口的最后一拍有效字节数 | Local Link 发送接口的最后一拍有效字节数 |

| aurora_tx_sof | O | 1 | 1 | Local Link 发送接口的帧开始 | Local Link 发送接口的帧开始 |

| aurora_tx_eof | O | 1 | 1 | Local Link 发送接口的帧结束 | Local Link 发送接口的帧结束 |

| aurora_tx_src_rdy | O | 1 | 1 | Local Link 发送接口的源就绪 | Local Link 发送接口的源就绪 |

| aurora_tx_dst_rdy | I | 1 | 1 | Local Link 发送接口的目的就绪 | Local Link 发送接口的目的就绪 |


2.3.3 接口时序

模块接口的时序图如下：

图中可以看到AXI。

图5  Aurora AXIS2LL模块时序

2.3.4 功能设计

2.3.4.1 FDMA读控制功能设计

FDMA 读控制模块负责发起对系统存储器的突发读操作，并将读回的数据写入异步 FIFO。

FDMA 读控制状态机使用 4 个状态，由 fdma_clk 驱动。

| 状态名 | 编码 | 描述 |

| RD_IDLE | 2'b00 | 空闲，等待启动条件 |

| RD_REQ | 2'b01 | 请求阶段，置 rareq |

| RD_DATA | 2'b10 | 数据接收阶段，计数接收的字数 |

| RD_WAIT | 2'b11 | 等待阶段，等待 rbusy 撤消 |


状态转移条件如图所示，其中rd_burst_done 表示发完一次读burst的数据。启动条件：channel_up_fdma（同步后的通道标志）为高，且 FIFO 未满（!fifo_almost_full）

读地址管理

地址以字节为单位，初始为0，每次突发完成后增加512，当超过地址边界 4KB时回绕到 0。

FIFO参数选择

| 参数 | 值 | 理由 |

| FIFO_WRITE_DEPTH | 512 | 见下文分析 |

| WRITE_DATA_WIDTH | 64 | FDMA 数据宽度 |

| READ_DATA_WIDTH | 64 | Local Link 数据宽度 |

| READ_MODE | "fwft" | First-Word Fall-Through，减少读延迟，提高吞吐 |

| PROG_FULL_THRESH | 500 | 当写计数 >=500 时almost_full 有效，用于反压 FDMA 读请求 |

| PROG_EMPTY_THRESH | 10 | 当读计数 <=10 时almost_empty 有效，用于触发 Local Link 发送启动 |

| CDC_SYNC_STAGES | 2 | 跨时钟域同步级数 |

| USE_ADV_FEATURES | "1f1f" | 使能所有高级功能（溢出、下溢、数据计数等） |


FIFO深度设置

写入速率：250 MHz × 8 B = 2000 MB/s

读出速率：161.13 MHz × 8 B ≈ 1289 MB/s

净积累速率 = 2000 - 1289 = 711 MB/s

由于 Aurora TX 接口支持反压（tx_dst_rdy），当 FIFO 接近满时，DUT 会通过 tx_fifo_almost_full 信号暂停 FDMA 读请求，从而切断写数据流。因此，FIFO 深度只需覆盖从检测到满到写停止这段时间内可能写入的数据量。

从FIFO almost_full置位到FDMA读请求停止，需要几个时钟周期（状态机跳转+握手）。假设响应延迟为10个fdma_clk周期（约40ns），在此期间FIFO继续写入，积累数据量 = 5.6875Gbps * 40ns ≈ 227.5 bits ≈ 28.4B，约4个64bit字。原深度512字（4KB）可以满足需求。

FIFO写使能管理

在状态机预进入RD_DATA状态，且满足fdma_rvalid && !fifo_almost_full时产生写使能。

2.3.4.2 Local Link发送控制功能设计

Local Link 发送控制模块负责从 FIFO 中读取数据，按照 Local Link 协议格式发送出去。

Local Link 发送状态机使用 3个状态，由 user_clk 驱动。

| 状态名 | 编码 | 描述 |

| TX_IDLE | 2'b00 | 空闲，等待启动条件 |

| TX_SOF | 2'b01 | 发送 SOF 节拍 |

| TX_DATA | 2'b10 | 发送数据节拍（包括中间节拍和 EOF 节拍） |


状态转移条件如图所示，其中wr_burst_done 表示发完一个burst中最后一个数据字且接收端就绪。启动条件：channel_up 为高，且 FIFO 非空（!fifo_almost_empty）。

FIFO读使能管理

在状态机进入除TX_IDLE外的其他状态，且满足tx_dst_rdy && !fifo_empty时产生读使能。

3 UT测试

3.1 测试环境与用例

本测试平台用于验证 fdma_aurora_brg_top 桥接模块的功能正确性。该桥接模块位于 FDMA 总线与 Aurora 64B66B 高速串行链路之间，实现数据双向透明传输：

TX 方向：从 FDMA 读端口获取数据，经过异步 FIFO 跨时钟域后，打包成 Aurora LocalLink 帧发送出去。

RX 方向：从 Aurora LocalLink 接口接收帧，提取有效数据写入异步 FIFO，再通过 FDMA 写端口存入内存。

测试平台采用 SystemVerilog 编写，遵循 事务级建模、接口分离、配置化、自动比对 的设计原则，可在 Vivado 仿真器中直接运行。

测试环境

硬件结构：独立的 TX 和 RX 数据路径。

发送路径：接收路径：

时钟设置：

测试用例

测试用例名称：aurora_64b66b_0_tb.v

测试用例实现：首先进行双向链路同步建立。

激励构造：。

图6 A

4.3 测试用例设计

4.3.1 基本功能测试

测试步骤：

复位释放，等待 channel_up 置高。

观察 FDMA 读请求开始，FIFO 被填充。

Local Link 发送启动，连续发送帧。

仿真运行足够长时间，例如发送 20 帧。

预期结果：

所有发送的帧都能被接收端正确接收，数据匹配。

无 FIFO 溢出/下溢。

状态机正确转移。

4.3.2 反压测试

测试步骤：

在 Local Link 接收端模型中，随机产生 ll_dst_rdy_n 信号，低电平概率 70%，高电平概率 30%。

运行仿真，发送 50 帧。

预期结果：发送端能够正确暂停和恢复，不丢失数据。FIFO 水位动态变化，但不会溢出或下溢。所有帧数据正确。

4.3.3 边界条件测试

FIFO 几乎满：模拟 FDMA 写速度远大于 Local Link 读速度（例如将读时钟频率降低到 100MHz，或让接收端长时间反压）。观察 fifo_almost_full 拉高后，FDMA 读请求是否被阻塞。

验证 FIFO 不会溢出。

地址回绕：

发送足够多的帧，使得 FDMA 读地址超过 TEST_MEM_SIZE（4KB），观察地址是否正确回绕到 0。

检查回绕后的数据是否正确（内存模型应循环输出）。

空 FIFO 启动：

复位后立即拉高 channel_up，但 FIFO 为空，发送状态机应保持在 IDLE，直到 FIFO 非空。

然后 FDMA 读入数据，发送开始。

4.3.4 错误注入测试

FIFO 溢出模拟：

强制使 fifo_almost_full 失效（例如修改阈值），让 FDMA 继续写入，直到 FIFO 写满。

观察 fifo_overflow 是否被置位，并确认系统不会挂死（继续写入可能被忽略，但不应影响已存数据）。

FIFO 下溢模拟：

强制使 Local Link 发送模块在 FIFO 为空时读取（例如通过修改状态机条件），观察 fifo_underflow。

4.3.5 长时间稳定性测试

发送数千帧（例如 5000 帧），统计错误率。

使用自动脚本运行仿真，检查是否有数据不一致或错误标志。

3.4 测试步骤与判定

## 修订记录

| 版本 | 日期 | 作者 | 修改内容 |

| V1.0 | 2026/04/20 |  | 初版 |

| V1.1 | 2026/06/15 |  | 1. 添加 fdma_rready/fdma_wready 信号及 AXI-like 握手机制说明；2. RX桥写数据通路改为 wdata_hold_valid 保持寄存器方案，wvalid 独立于 wready；3. TX桥 fifo_wr_en 改为基于 rd_state_nxt==RD_DATA 门控，修复 burst 首拍数据丢失；4. 帧大小从 1024 字节改为 1536 字节（3 burst/帧）；5. 更新接口时序图 |


### AXI-like 握手机制说明

本设计在 FDMA 接口侧采用 AXI-like 握手机制，通过 ready/valid 信号对实现数据传输的流控。该机制允许从机在突发传输内插入反压，同时保证数据不丢失。

| 信号 | 方向 | 作用 | 控制者 |

| fdma_rready / fdma_wready | 用户→FDMA | 授权 FDMA 传输数据 | 用户逻辑 |

| fdma_rbusy / fdma_wbusy | FDMA→用户 | 告知用户 FDMA 正在传输 | FDMA 内核 |


TX桥侧：fdma_rready = ~fifo_almost_full，当 TX FIFO 不满时授权 FDMA 传入数据。读从机通过延迟 rvalid 实现突发内反压，等待 rvalid && rready 握手完成。

RX桥侧：fdma_wready 由 FDMA 写从机提供，当从机准备好接收时为高。RX桥通过 wdata_hold_valid 保持寄存器方案实现 wvalid 独立于 wready：wvalid 拉高后，若 wready=0 则数据暂存在 wdata_hold 中等待；wready=1 时完成握手，数据传输。

### RX桥写数据通路设计（wdata_hold_valid 方案）

RX桥在 WR_DATA 状态下，从 FIFO 预取数据到保持寄存器 wdata_hold，然后通过 wvalid/wready 握手将数据发送给 FDMA 写从机。

关键信号：

fifo_rd_en = (wr_state == WR_DATA) && fdma_wbusy && !wdata_hold_valid && !fifo_empty && !rd_rst_busy

fdma_wvalid = wdata_hold_valid && (wr_state == WR_DATA) && fdma_wbusy

fdma_wdata = wdata_hold

w_hs = fdma_wvalid && fdma_wready（握手完成）

wr_burst_done = (wr_state == WR_DATA) && w_hs && (wr_word_cnt == BURST_WORDS-1)

保持寄存器管理：

1. fifo_rd_en 时：从 FIFO 加载数据到 wdata_hold，wdata_hold_valid=1

2. w_hs 时：握手完成，wdata_hold_valid=0，允许下一次 FIFO 预取

3. wr_state != WR_DATA 时：wdata_hold_valid=0（复位）

注意：当前 wdata_hold_valid 方案在无反压时每个 word 至少需要 2 拍（1拍预取+1拍握手），带宽减半。后续可改为 Skid Buffer 方案实现满带宽传输。

### TX桥读数据通路设计

TX桥在 RD_DATA 状态下，通过 rvalid/rready 握手从 FDMA 读从机获取数据，写入 TX FIFO。

关键信号：

fdma_rready = ~fifo_almost_full（FIFO 不满时授权传输）

fifo_wr_en = (rd_state_nxt == RD_DATA) && fdma_rvalid && fdma_rready

rd_burst_done = (rd_state == RD_DATA) && fdma_rvalid && (rd_word_cnt == BURST_WORDS-1)

注意：fifo_wr_en 使用 rd_state_nxt（组合逻辑下一状态）而非 rd_state（寄存器当前状态），确保在 RD_REQ→RD_DATA 转换的同一拍即可写入 FIFO，避免 burst 首拍数据丢失。

# 4 关键电路与连续时序分析（RTL 对照补充）

本节以当前工程 sources_1 - loop_validate\new 目录中的 fdma_aurora_brg_top.v、fdma_aurora_brg_tx.v、fdma_aurora_brg_rx.v 和 cdc_sync.v 为准，补充关键电路、连续波形和逐周期判读方法。图中的时序是寄存器传输级的周期关系，不表示布局布线后的门延迟。

| 适用基线：默认 FRAME_BYTES=512，因此一个事务/帧包含 64 个 64-bit 数据字；FDMA 地址窗口为 4 KiB，每完成一个 512 B 突发后递增，越界时回绕到 0。若参数或接口语义发生变化，应同步更新本节波形。 |


| 对象 | RTL 实体/信号 | 本节采用的实现事实 |

| 顶层 | fdma_aurora_brg_top | TX 与 RX 各自使用一只异步 FIFO；channel_up 经 cdc_sync 进入 fdma_clk 域。 |

| TX/FDMA | rd_state、rd_data_hs | 512 B 读请求；仅握手拍写 FIFO；REQ+rbusy 可直接接收首字。 |

| TX/Aurora | tx_state、tx_hs | FWFT 队首直出；dst_rdy 背压时 data/SOF/EOF 均保持。 |

| RX/Aurora | rx_dst_rdy、fifo_wr_en | rx_dst_rdy 恒为 1；FIFO 满时本地停写但不能反压上游。 |

| RX/FDMA | wdata_hold_valid、w_hs | 保持级吸收 wready 背压；非末字握手时允许同拍补货。 |


## 4.1 连续时序图画法与读图约定

为避免把独立截图误读为连续行为，本节所有波形均以统一周期边界排列。读图时先确定时钟域，再找握手事件，最后检查状态、数据和计数器是否只在该事件上推进。

| 图形元素 | 含义 | 判读要求 |

| 灰色竖向虚/细线 | 采样周期边界 | 同一列表示同一时钟域中的一个完整周期；跨域信号必须另行说明。 |

| 蓝色水平线 | 信号在该区间保持高或低 | 连续水平线不是重复画线，而是强调背压/空拍期间没有变化。 |

| 边界处蓝色竖线 | 唯一的 0↔1 跳变 | 跳变只画在周期边界，不在周期中间制造伪事件。 |

| 圆角总线框 | 状态、计数或数据值 | 相邻同值框可合并；“…”仅省略重复稳态拍，不代表固定延迟。 |

| 绿色事件点 | 当拍 valid && ready 或明确完成事件 | 状态、指针和字计数是否推进，均以事件点为准。 |

| 橙/红背景 | 停顿窗口或风险窗口 | 检查 data/control 是否保持，以及该窗口是否造成丢数。 |


### 4.1.1 绘制步骤

只在一张图中使用一个主时钟域；若必须表现 CDC，应把源信号、同步级和目的域信号分行，并标明这是相位相关的示意延迟。

先画状态机和 valid/ready（或 req/busy），再由布尔关系生成 handshake 行，不能凭数据看起来变化就认定传输成功。

总线只在握手后切换到下一有效值；valid=1 且 ready=0 时，把 data、SOF、EOF 和相关计数连续画平。

至少覆盖首字、一个稳态区、一个停顿区和末字；长突发中间可用“…”压缩，但必须保留停顿前后的同一个数据编号。

周期说明应写出触发条件和结果，例如“W6：wready=0，因此 w_hs=0、fifo_rd_en=0，D2 保持”，避免只写“此处有背压”。

## 4.2 顶层数据通路与时钟域

图 4-1  FDMA–Aurora 桥总体关键电路与跨时钟边界

TX 与 RX 是方向相反、控制独立的流水线。TX FIFO 的写侧属于 fdma_clk，读侧属于 user_clk；RX FIFO 恰好相反。跨域传输由 xpm_fifo_async 的格雷指针/同步逻辑承担，业务逻辑不得直接比较两个时钟域中的瞬时计数值来做逐拍控制。

• TX FIFO：512×64 bit，READ_MODE="fwft"，prog_full 阈值为 448，用于在 FDMA 读请求前预留一个 64-word 突发空间。

• RX FIFO：2048×64 bit（16 KiB），READ_MODE="fwft"，prog_full 阈值为 2032；当前 RTL 没有用 prog_full 对 Aurora 入口反压。

• channel_up 先在 user_clk 域产生，再通过两级 cdc_sync 得到 channel_up_fdma；FDMA 状态机只使用同步后的版本。

• FIFO 复位忙信号 wr_rst_busy/rd_rst_busy 是实际读写使能的一部分；复位撤销不等于 FIFO 当拍即可使用。

## 4.3 TX：FDMA 读到 Aurora 发送

图 4-2  TX 请求、数据握手、异步 FIFO 与 LocalLink 保持电路

| 控制点 | RTL 关系 | 设计作用 |

| 读请求接受 | fdma_rareq && fdma_rbusy | rareq 在 RD_REQ 中保持；busy 置位后撤销，避免同一突发重复请求。 |

| 数据阶段 | rd_data_phase = RD_DATA \|\| (RD_REQ && fdma_rbusy) | 允许 busy 接受请求的同一周期接收首个 rvalid，消除首拍气泡。 |

| FIFO 写事件 | rd_data_hs = rd_data_phase && fdma_rvalid && fdma_rready | fifo_wr_en 与该事件相同，未握手不写 FIFO、不增加字计数。 |

| Aurora 消费事件 | tx_hs = tx_src_rdy && tx_dst_rdy | fifo_rd_en=tx_hs，SOF/EOF/数据在背压期间随 FWFT 队首保持。 |

| 末字判定 | tx_word_cnt == FRAME_WORDS-1 | 只有末字实际握手后返回 TX_IDLE，不能因 EOF 已拉高而提前结束。 |


RTL 锚点：fdma_aurora_brg_tx.v / RD_IDLE–RD_WAIT、rd_data_phase、rd_data_hs、TX_IDLE–TX_DATA、tx_hs、fifo_rd_en

### 4.3.1 FDMA 读请求与 64 字突发

图 4-3  TX/FDMA 读侧连续波形

• R1：进入 RD_REQ 后 rareq 拉高；rbusy 尚未置位，请求继续保持。

• R2：rbusy 与 rvalid 同时有效。虽然状态寄存器仍编码为 RD_REQ，rd_data_phase 已成立，D0 在该拍通过 rd_data_hs 写入 FIFO。

• R3–R5：rvalid/rready 连续握手，FIFO 每拍写入一个数据字，rd_word_cnt 按握手次数推进。

• R6：rvalid 空拍，rready 可以保持为 1，但 rd_data_hs=0；FIFO 写指针和字计数都停在 D3 之后。

• R9：示意第 64 字 D63 的有效握手；状态转入 RD_WAIT，计数清零。

• R10–R11：RD_WAIT 等待 rbusy 释放；只有释放后地址才按 512 B 递增或在 4 KiB 边界回绕。

### 4.3.2 Aurora 背压下的 SOF/EOF 保持

图 4-4  TX/Aurora LocalLink 背压连续波形

TX FIFO 使用 FWFT 模式，tx_d 直接取 fifo_rdata。这个结构只有在 fifo_rd_en 与 tx_hs 完全相同时才安全：背压期间不读 FIFO，队首数据自然保持；状态和 tx_word_cnt 也必须使用同一个 tx_hs 推进。

• T1：D0 与 SOF 已有效，但 dst_rdy=0，所以首字尚未消费；T2 握手后才离开 TX_SOF。

• T5–T6：中间数据 D3 在两拍背压中保持；没有 FIFO 出队，也没有计数加一。

• T9：末字 D63、EOF 和 src_rdy 同时保持；T10 dst_rdy 恢复后完成末字握手，状态才返回 IDLE。

| 实现检查：如果未来把 FIFO 改成非 FWFT 或增加输出寄存器，必须重新对齐 tx_d 与 SOF/EOF；不能只修改 FIFO 参数而保留现有组合输出。 |


## 4.4 RX：Aurora 接收到 FDMA 写回

图 4-5  RX 不可背压入口、异步 FIFO 与 wdata_hold 写数据保持级

| 控制点 | RTL 关系 | 设计作用/边界 |

| 入口接受 | rx_dst_rdy = 1'b1 | Aurora 侧永远看到可接收，无法用 LocalLink ready 抑制源端。 |

| FIFO 写入 | fifo_wr_en = rx_src_rdy && !fifo_full | full 时保护本地 FIFO 不被写，但该拍上游数据不会自动重发。 |

| 首次预取 | WR_DATA && wbusy && !empty && !hold_valid | 从 FWFT 队首装入 wdata_hold，下一拍对 FDMA 形成有效数据。 |

| 同拍补货 | w_hs && !w_last_hs | 当前字被接收时同时读取下一字，稳态可达到每拍一个 64-bit 字。 |

| 背压保持 | wvalid && !wready ⇒ fifo_rd_en=0 | wdata_hold 与 valid 均不变，FIFO 读指针不推进。 |

| 末字隔离 | w_last_hs 阻止 fifo_rd_en | 第 64 字后清空保持级，不把下一突发首字错误预取到当前事务。 |


RTL 锚点：fdma_aurora_brg_rx.v / rx_dst_rdy、fifo_wr_en、wdata_hold(_valid)、fifo_rd_en、w_hs、w_last_hs、WR_IDLE–WR_WAIT

### 4.4.1 FDMA 写侧首次预取、连续供数与背压

图 4-6  RX/FDMA 写侧连续波形

• W1–W2：wareq 保持到 wbusy 接受请求；WR_REQ 阶段不提前读 RX FIFO。

• W3：状态进入 WR_DATA，保持级为空，于是 fifo_rd_en 预取 D0；寄存器更新后 W4 才对外形成 wvalid。

• W4–W5：每个非末字 w_hs 都允许 fifo_rd_en 同拍有效，当前字完成的同时把下一字装入 wdata_hold，稳态无空拍。

• W6–W7：wready 拉低，w_hs=0，fifo_rd_en=0，D2 和 wvalid 连续保持。

• W8：wready 恢复后 D2 完成握手，并同拍补入后续数据。

• W10：D63 完成末字握手，w_last_hs 阻止再读 FIFO；状态进入 WR_WAIT，保持级清空。

### 4.4.2 Aurora 入口无背压时的满 FIFO 风险

图 4-7  RX/Aurora 入口满 FIFO 丢数窗口

| 关键限制：A5–A6 中 fifo_full=1，fifo_wr_en 被压低，但 rx_dst_rdy 仍为 1；因此 D4、D5 不进入 FIFO。这个行为不是 FDMA 写侧 wdata_hold 能修复的，后者只处理 FIFO 之后的背压。 |


当前实现依靠 16 KiB RX FIFO 和系统流量约束吸收瞬时速率差。若上游可能持续满速而 FDMA 写侧可长时间停顿，应在后续版本中至少采用一种增强措施：允许 LocalLink 反压、在上游做信用/帧级流控，或增加显式 drop_count 并把丢包升级为可见故障。

## 4.5 channel_up CDC 与复位放行

图 4-8  channel_up 两级同步与 FIFO 复位忙放行关系

channel_up_fdma 的有效/失效都晚于 user_clk 域源信号，延迟取决于两个时钟的相位。本图用相邻列展示先后关系，不应解读为固定两拍或固定纳秒值。FDMA FSM 的实际启动还受 FIFO empty/full 阈值和 wr_rst_busy/rd_rst_busy 约束。

• 同步器解决单比特状态的亚稳态传播概率问题，不承担多比特数据一致性；业务数据只能通过异步 FIFO 跨域。

• 链路失锁传播到 fdma_clk 域前，已开始的 FDMA 事务可能仍处于 DATA/WAIT；系统复位策略应明确是允许收尾还是立即清除。

• FIFO rst 当前由相应 user_rstn 驱动，读写两侧的 reset-busy 必须作为可用条件纳入仿真和 ILA 判据。

## 4.6 与当前工程接口的对应关系

| 数据方向 | 当前模块链路 | 关键边界 | 集成时必须保持的语义 |

| 主机/存储侧 → Aurora | FDMA r* → TX FIFO → tx_* | fdma_clk ↔ user_clk | rdata 只在 rvalid&&rready 时采样；LocalLink 只在 src_rdy&&dst_rdy 时消费。 |

| Aurora → 主机/存储侧 | rx_* → RX FIFO → wdata_hold → FDMA w* | user_clk ↔ fdma_clk | RX 入口当前不可反压；FDMA 写数据在 wready=0 时必须保持稳定。 |

| 链路状态 | channel_up → cdc_sync → channel_up_fdma | 单比特 CDC | FDMA 状态机不得直接使用未同步的 channel_up。 |

| 复位/可用 | user_rstn/fdma_rstn + FIFO reset-busy | 异步 FIFO 两端 | 复位撤销后等待 busy 清除，再允许读写使能。 |


若当前工程在 FDMA 与 PCIe/AXI 之间还有适配层，需要特别核对长度单位：本桥中 fdma_rsize/fdma_wsize 使用 512（字节）；适配层若把长度换算为 64-bit beat，应只在边界转换一次，不能让 512 被误解释为 512 个 beat。

## 4.7 ILA/仿真核对点

| 场景 | 建议同时观察的信号 | 通过判据 |

| TX 读首拍 | rd_state, rareq, rbusy, rvalid, rready, rd_data_hs | REQ+rbusy+rvalid 可在同拍产生首个 rd_data_hs，且仅写入一次 D0。 |

| TX Aurora 背压 | tx_state, src_rdy, dst_rdy, sof, eof, tx_d, fifo_rd_en | dst_rdy=0 时 tx_d/sof/eof 稳定，fifo_rd_en=0，计数不变。 |

| RX FDMA 背压 | wr_state, wvalid, wready, wdata, hold_valid, fifo_rd_en | wvalid&&!wready 时 wdata/valid 稳定且不读 FIFO；恢复后只消费一次。 |

| RX 末字 | wr_word_cnt, w_hs, w_last_hs, fifo_rd_en | word_cnt=63 的握手拍不预取下一突发，下一拍进入 WAIT/清空保持级。 |

| RX 满 FIFO | rx_src_rdy, rx_dst_rdy, fifo_full, fifo_wr_en, fifo_wr_cnt | 出现 src_rdy&&full 即视为业务丢数风险；系统测试应把它判为失败或记录 drop。 |

| 复位/重连 | channel_up, channel_up_fdma, rst_busy, 两侧 FSM | 同步与 busy 清除前不发生 FIFO 读写；重连后从合法 IDLE 状态重新启动。 |


## 4.8 设计结论

• TX 数据完整性的核心不变量是 fifo_wr_en=rd_data_hs、fifo_rd_en=tx_hs；两侧计数器与状态机使用各自握手事件推进。

• RX 的 wdata_hold_valid 方案正确覆盖了 FDMA 写背压，并通过非末字同拍补货保持稳态单拍吞吐。

• 当前最重要的系统级限制是 Aurora RX 不可反压：RX FIFO 满时会丢弃输入数据，必须由容量/流量约束或后续流控改造闭环。

• 跨时钟数据由异步 FIFO 承担，单比特链路状态由两级同步器承担；任何新增控制信号都应按相同 CDC 分类处理。
