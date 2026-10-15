# fdma_aurora_brg IP设计

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\fdma_aurora_brg IP设计.docx`
- SHA-256: `40a7d6900d8be5a35a86854aea01e54c66347526ea1f7eaf62af7caa0237bf55`
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
