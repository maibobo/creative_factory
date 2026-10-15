# Aurora 64b66b IP设计方案

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\doc\Aurora 64b66b IP设计方案.docx`
- SHA-256: `4aa25e2057f6f0ca543ad79ec059dbb3cb0827d4a1d7863eeb48826272f7cc58`
- Extractor: `python-docx+zip-structure-check`
- Tags: `10.3125g, 64b66b, aurora, design, verified, vivado-2020.2`
- Duplicate sources:
  - R:\Aurora 64b66b IP设计方案.docx

| 产品名称Product name | 密级Confidentiality level |

| RTDS |  |

| 产品版本Product version | Total 26 pages 共 26 页 |

| V1.0 | Total 26 pages 共 26 页 |


Aurora 64b66b IP开发详细设计方案

| Prepared by 拟制 | 买博 | Date 日期 | 2026-3-23 |

| Reviewed by 评审人 |  | Date 日期 |  |

| Approved by 批准 |  | Date 日期 |  |


Revision Record 修订记录

| Revision Version 修订版本 | Change Description 修改描述 | Author 作者 | Date 日期 |

| 1.0 | 完成初稿 | 买博 | 26.3.23 |

| 1.1 | 架构图改为LL外部接口形式，补充测试环境章节 | 买博 | 26.4.6 |


目录

Revision Record 修订记录	2

目录	3

1 概述	4

1.1 设计背景	4

1.2 设计架构	4

1.3 接口列表	5

1.4 时钟和复位管理	7

1.4.1 时钟管理	7

1.4.2 复位管理	7

2 Aurora整体设计	8

2.1 Aurora架构设计	8

2.2 Aurora local link到axi stream接口转化模块设计	9

2.2.1 规格概述	9

2.2.2 接口列表	9

2.2.3 接口时序	10

2.2.4 功能设计	11

2.3 Aurora axi stream到local link接口转化模块设计	12

2.3.1 规格概述	12

2.3.2 接口列表	12

2.3.3 接口时序	13

2.3.4 功能设计	14

2.4 时钟与复位管理	15

3 Aurora测试	17

3.1 测试环境与用例	17

3.2 Aurora Frame Gen模块设计	19

3.2.1 规格概述	19

3.2.2 接口列表	19

3.2.3 接口时序	20

3.2.4 功能设计	21

3.3 Aurora Frame Check模块设计	22

2.5.1 规格概述	22

3.3.2 接口列表	23

3.3.3 接口时序	24

3.3.4 功能设计	24

3.4 测试步骤与判定	25

1 概述

1.1 设计背景

一方面，在同类型的 FPGA 专用 SerDes 互联协议中，Aurora 凭借其极简的链路层设计以及AXI4-Stream 接口的易用性，在性能与资源消耗之间取得了最佳平衡。另一方面，Aurora 64B/66B相比Aurora 8B/10B编码效率从80%提升至97%，有效带宽利用率更高，且资源占用极低，尤其适合板卡间高速通信。因此，本方案选用Aurora 64B/66B IP作为高速串行数据传输的研究基础。

当前，Aurora 64B/66B IP核已实现链路初始化、编码与错误检测等底层功能，但其仅提供AXI4-Stream接口，在某些应用场景下设计复杂度较高，且易引发时序问题。相较而言，Local Link协议接口更为简洁，通过协议转换模块实现物理隔离与数据缓冲，能够更有效地满足系统时序要求。基于此，本设计以Kintex UltraScale FPGA为平台，构建了AXI4-Stream与Local Link之间的适配模块，通过协议转换实现数据稳定高效传输，将底层协议复杂性封装起来，最终形成可复用、易集成的高速串行接口适配模块。

1.2 设计架构

本设计采用单 lane 配置，支持线速率 10.3125 Gbps，参考时钟 156.25 MHz，用户接口为 AXI4-Stream 协议（配置为Framing 模式）。系统顶层包含时钟生成单元、复位信号控制、ila和aurora_64b66b_0_exdes模块。aurora_64b66b_0_exdes模块的设计会在第二章中详细描述。

图1 系统顶层设计框图

1.3 接口列表

| 信号 | 方向 | 位宽 | 描述 |

| RESET | I | 1 | 外部全局复位按钮（异步，高有效），用于强制系统复位 |

| HARD_ERR | O | 1 | 硬错误指示，来自 Aurora IP 核，通常连接至 LED |

| SOFT_ERR | O | 1 | 软错误指示，来自 Aurora IP 核，连接至 LED |

| DATA_ERR_COUNT | O | 8 | 帧检查器统计的数据错误计数 |

| LANE_UP | O | 1 | 物理通道已对齐指示，连接至 LED |

| CHANNEL_UP | O | 1 | 通道已建立指示，连接至 LED |

| PMA_INIT | I | 1 | PMA 初始化触发脉冲（可选，通常由外部控制器或按键产生） |

| INIT_CLK_IN | I | 1 | 初始化时钟输入（10 MHz单端时钟），用于 GT 复位逻辑 |

| GTHQ0_P / GTHQ0_N | I | 1 | GT 参考时钟差分输入（156.25 MHz） |

| RXP / RXN | I | 1 | GT 串行接收差分对 |

| TXP / TXN | O | 1 | GT 串行发送差分对 |

| CRC_PASS_FAIL_N | O | 1 | CRC 校验结果（0：通过，1：失败），连接至 LED |

| CRC_VALID | O | 1 | CRC 结果有效指示，连接至 LED |


1.4 时钟和复位管理

1.4.1 时钟管理

外部提供两路时钟：INIT_CLK_IN（初始化时钟）和 GTHQ0_P/N（GT 参考时钟）。

INIT_CLK_IN 经过 BUFG 后驱动复位延迟链和 PMA 初始化状态机。

GT 参考时钟直接连接到 IP 核，用于 GT 的 PLL 和串行收发。

注意：

REFCLK 和 User Clock 的频率不相同，它们是两个独立但相关的时钟。

REFCLK：是输入到 GT 收发器的参考时钟，用于驱动 GT 内部的 PLL。它的频率由所选线速率和 GT PLL 的倍频/分频比共同决定，但通常有多种组合。例如，对于 10.3125 Gb/s 的线速率，可以使用 156.25 MHz 的 REFCLK（因为 156.25 × 66 = 10312.5），也可以使用 322.265625 MHz 等其他频率，只要 PLL 能够通过整数或半整数倍频得到精确的线速率。

User Clock：是 IP 核输出给用户逻辑的并行接口时钟。它的频率严格等于 线速率 ÷ 用户接口数据位宽。在 Aurora 64B/66B 的标准配置中，用户接口数据位宽通常是 64 位（当 AURORA_LANES=1 时），因此：

User Clock 频率 = 线速率 / 64

例如线速率 10.3125 Gb/s 时，User Clock = 10.3125 Gb/s ÷ 64 = 161.1328125 MHz。

结论：REFCLK 和 User Clock 的频率可以相同（如线速率 1.25 Gb/s 时，User Clock = 19.53125 MHz，REFCLK 也可以选 19.53125 MHz），但更多情况下它们不同，且没有固定的比例关系。User Clock 完全由线速率决定，而 REFCLK 可以灵活选择。

1.4.2 复位管理

根据xilinx官方IP手册的时序规范，进行以下设计：

置位顺序：先置位 reset_pb（RESET），并至少保持128个user_clk，再置位 pma_init（GT_RESET）。

释放顺序：先释放 pma_init（GT_RESET），后释放 reset_pb（RESET）。	pma_init 的宽度：持续高电平不低于1 s。

图2 Aurora 64B/66B正常运行复位操作流程

2 Aurora整体设计

2.1 Aurora架构设计

顶层模块内部例化了以下子模块，它们共同构成完整的数据通路和控制逻辑：

aurora_64b66b_0：Aurora IP 核，完成高速串行收发、编解码、通道对齐、CRC 校验等功能。

aurora_64b66b_0_EXAMPLE_LL_TO_AXI：LocalLink 到 AXI4-Stream 协议转换桥（发送方向）。

aurora_64b66b_0_EXAMPLE_AXI_TO_LL：AXI4-Stream 到 LocalLink 协议转换桥（接收方向）。

时钟与复位管理逻辑：包含 BUFG、复位同步器、PMA 初始化脉冲发生器、延迟链等。

整体设计由顶层模块 aurora_64b66b_0_exdes 将 Aurora IP 核与用户侧逻辑（帧生成器、帧检查器、协议转换桥）集成在一起。数据流如下：

发送路径：外部输入的LocalLink 格式的数据，经 LL→AXI 桥接模块转换为 AXI4-Stream 格式，送入 Aurora IP 核的发送接口。

接收路径：Aurora IP 核接收端输出 AXI4-Stream 数据，经 AXI→LL 桥接模块转换回 LocalLink 格式的数据，并输出到外部。

时钟与复位：所有用户逻辑均工作于 Aurora IP 核输出的 user_clk 域，复位逻辑包含 PMA 初始化脉冲生成和跨时钟域同步。

图3 Aurora架构设计框图

2.2 Aurora local link到axi stream接口转化模块设计

2.2.1 规格概述

该模块将 Legacy LocalLink 接口转换为 AXI4-Stream 接口，使帧生成器（LocalLink 输出）能够连接到 Aurora IP 核的 AXI4-Stream 发送端口。主要任务包括：

将 LocalLink 的 SOF_N/EOF_N/REM 映射为 AXI4-Stream 的 tlast 和 tkeep。

对生成的 AXI 信号进行流水线寄存，提升时序性能并处理反压。

2.2.2 接口列表

| 信号 | 方向 | 位宽 | 描述 |

| LL_IP_DATA | I | 64 | LocalLink 输入数据 |

| LL_IP_REM | I | 3 | LocalLink REM（有效字节数-1） |

| LL_IP_SOF_N | I | 1 | LocalLink 帧开始（低有效） |

| LL_IP_EOF_N | I | 1 | LocalLink 帧结束（低有效） |

| LL_IP_SRC_RDY_N | I | 1 | LocalLink 源就绪（低有效） |

| LL_OP_DST_RDY_N | O | 1 | LocalLink 目的就绪（低有效，背压指示） |

| AXI4_S_OP_TDATA | O | 64 | AXI4-Stream 发送数据 |

| AXI4_S_OP_TKEEP | O | 8 | AXI4-Stream 字节有效掩码 |

| AXI4_S_OP_TVALID | O | 1 | AXI4-Stream 数据有效 |

| AXI4_S_OP_TLAST | O | 1 | AXI4-Stream 帧结束 |

| AXI4_S_IP_TREADY | I | 1 | AXI4-Stream 接收就绪 |

| USER_CLK | I | 1 | 用户时钟 |

| RESET | I | 1 | 全局复位 |


2.2.3 接口时序

模块接口的时序图如下：

图中可以看到LL接口数据转换到AXIS接口的数据。REM的7对应TKEEP的FF，REM的3对应TKEEP的F0。由于经过一级的reg_slice，转换后的AXIS接口的数据相比转换前的LL接口数据延迟一拍输出。

图4  Aurora LL2AXIS模块时序

2.2.4 功能设计

组合逻辑转换规则：
tvalid：直接取反 LL_IP_SRC_RDY_N，即 AXI4_S_OP_TVALID_INT = !LL_IP_SRC_RDY_N。

tlast：直接取反 LL_IP_EOF_N，即 AXI4_S_OP_TLAST_INT = !LL_IP_EOF_N。

tdata：直接传递 LL_IP_DATA。

tkeep：根据 LL_IP_REM 计算。AXI4_S_OP_TKEEP_INT = ~(8'hFF >> (LL_IP_REM + 1))，只有最高n 位地址为 1（这里LL_IP_REM定义为大端模式）。

注：原代码可能存在 (LL_IP_REM == {REM_WIDTH{1'b0}}) 的错误条件，现已替换为基于 REM+1 的移位取反算法，在REM=0 时 tkeep 正确为 8'b0000_0001，更加通用且不易出错。

aurora_64b66b_0_reg_slice_0 模块端口映射如下：

s_axis_tdata 等为输入侧的 AXI 信号（来自LL接口信号）。

m_axis_tdata 等为输出侧的 AXI 信号（连接到 Aurora IP 核）。

s_axis_tready 用于产生 LL_OP_DST_RDY_N，输出到LL接口模块。

m_axis_tready 来自下游 Aurora IP 核的 tready。

2.3 Aurora axi stream到local link接口转化模块设计

2.3.1 规格概述

该模块将 AXI4-Stream 接口转换为 LocalLink 接口，使 Aurora IP 核的接收端能够连接到帧检查器（LocalLink 输入）。主要任务包括：

从 AXI 数据流中提取 tlast、tkeep，生成 LocalLink 的 EOF_N、REM。

检测新包的开始，生成 SOF_N。

同样使用寄存器切片进行流水线处理。

2.3.2 接口列表

| 信号 | 方向 | 位宽 | 描述 |

| AXI4_S_IP_TX_TDATA | I | 64 | AXI4-Stream 接收数据 |

| AXI4_S_IP_TX_TKEEP | I | 8 | AXI4-Stream 字节有效掩码 |

| AXI4_S_IP_TX_TVALID | I | 1 | AXI4-Stream 数据有效 |

| AXI4_S_IP_TX_TLAST | I | 1 | AXI4-Stream 帧结束 |

| AXI4_S_IP_TX_TREADY | O | 1 | AXI4-Stream 接收就绪 |

| LL_OP_DATA | O | 64 | LocalLink O数据 |

| LL_OP_REM | O | 3 | LocalLink REM |

| LL_OP_SOF_N | O | 1 | LocalLink 帧开始（低有效） |

| LL_OP_EOF_N | O | 1 | LocalLink 帧结束（低有效） |

| LL_OP_SRC_RDY_N | O | 1 | LocalLink 源就绪（低有效） |

| LL_IP_DST_RDY_N | I | 1 | LocalLink 目的就绪（低有效） |

| USER_CLK | I | 1 | 用户时钟 |

| CHANNEL_UP | I | 1 | 通道建立标志 |

| RESET | I | 1 | 全局复位 |


2.3.3 接口时序

模块接口的时序图如下：

图中可以看到AXIS接口的数据转换到LL接口数据。TKEEP的FF对应REM的7，TKEEP的F0对应REM的3。由于经过量级的reg_slice，转换后的LL接口的数据相比转换前的AXIS接口数据延迟两拍输出。

图5  Aurora AXIS2LL模块时序

2.3.4 功能设计

组合逻辑转换规则：

数据：直接传递 AXI4_S_IP_TX_TDATA_m（输入切片输出）。

EOF：LL_OP_EOF_N = !AXI4_S_IP_TX_TLAST_m。

源就绪：LL_OP_SRC_RDY = AXI4_S_IP_TX_TVALID_m，取反后得到 LL_OP_SRC_RDY_N。

REM 计算：tkeep 指示每个字节是否有效，需要转换为有效字节数减 1。使用循环计算 tkeep 中 1 的个数cnt，并在循环计算结束后将LL_OP_REM_INT 赋值为cnt-1 。cnt-1 范围为0~7。

SOF 生成：需要检测新包的开始，SOF 应在 new_pkt 从 0 变为 1 的时钟周期有效。 new_pkt 信号表示当正在传输一个包时它为高。状态转移如下：

当有效传输且当前不是最后一拍（tlast=0）时，下一周期 new_pkt 为 1。

当有效传输且是最后一拍（tlast=1）时，下一周期 new_pkt 为 0。

讨论第一包的 SOF 产生：在通道刚建立时，第一个有效拍应产生 SOF。这由 new_pkt 的初始值保证：复位时 new_pkt_r 为 0，当第一个有效拍（且非 last）到来时，new_pkt 变为 1，从而产生 SOF。

2.4 时钟与复位管理

时钟与复位管理模块负责生成系统所需的复位信号和 PMA 初始化脉冲，确保 Aurora IP 核及用户逻辑正确启动。主要功能包括：

缓冲输入时钟 INIT_CLK_IN，提供稳定的初始化时钟。

将外部 PMA_INIT 脉冲与内部生成的 GT 复位组合，经过延迟链后送入 Aurora IP 的 pma_init 端口。

产生用户逻辑复位 reset_i，同步到 user_clk 域。

可选地支持 LabTools 调试时的 VIO 复位注入。

时钟缓冲：

INIT_CLK_IN 通过 BUFG 驱动整个初始化时钟域，记为 INIT_CLK_i。该时钟用于 GT 复位逻辑中的延迟链和状态机。

用户时钟 user_clk_i 由 Aurora IP 核的 user_clk_out 提供，所有用户逻辑（帧生成器、检查器等）均工作于此时钟域。

参考时钟 GTHQ0_P/N 直接连接到 Aurora IP 核的 gt_refclk1_p/n 端口，用于 GT 收发器。

GT 复位生成：

GT 复位信号 gt_reset_i 需要满足特定的时序要求，通常要求在 PMA 初始化期间保持一定宽度。设计中采用了延迟链和脉冲发生器：

组合复位源：

gt_reset_i_tmp = PMA_INIT | gtreset_from_vio_r3 | pma_init_from_fsm_r1，其中后两个信号用于 LabTools 调试，若未使用则忽略。

延迟链：

gt_reset_i_tmp 在 INIT_CLK_i 域经过 128 级移位寄存器延迟，得到 gt_reset_i_delayed。此延迟用于模拟 PMA 初始化的建立时间。

PMA 初始化脉冲：

当检测到 gt_reset_i_delayed 下降沿时，生成一个宽度为 24'hFFFFFF 周期的脉冲 pma_init_assertion。脉冲期间强制复位，脉冲结束后跟随延迟链的输出。

用户复位生成：

用户逻辑复位 reset_i 由外部 RESET 和内部 gt_reset_i_tmp2（同步到 user_clk 的 GT 复位）相或产生。其中 gt_reset_i_tmp2 通过一个同步器将 gt_reset_i_tmp 同步到 user_clk 域。这样，当 GT 复位时，用户逻辑也会被复位，确保通道未就绪时停止发送数据。

3 Aurora测试

3.1 测试环境与用例

本工程设计了FRAME_GEN（帧生成器）、FRAME_CHECK（帧检查器）两个模块来辅助搭建测试环境，这两个模块的详细设计会在后面两节描述，本节描述测试环境与用例。

测试环境

硬件结构：独立的 TX 和 RX 数据路径。

发送路径：从用户逻辑（如 frame_gen）获取数据，经过编码、加扰、串行化后通过 TX 引脚发出。

接收路径：从 RX 引脚接收串行数据，经过解串、对齐、解码后，将恢复的数据通过 AXI4-Stream 接口送给用户逻辑（如 frame_check）。

时钟设置：安装预期设置156.25M的Aurora ip的参考时钟，设置50M的Aurora ip的初始化时钟。

测试用例

测试用例名称：aurora_64b66b_0_tb.v

测试用例实现：首先进行双向链路同步建立。只有当 DUT1 的接收端成功锁定 DUT2 发送的初始化序列，且 DUT2 的接收端成功锁定 DUT1 发送的初始化序列时，两个方向的 channel_up 才会同时或先后变为高电平。数据流：两个发送器完全独立、并行工作，构成了双向激励的源头。

DUT1 的 frame_gen_i 持续向 Aurora 核发送数据，这些数据通过串行口 TXP/TXN 输出。

DUT2 的 frame_gen_i 也独立地持续向自身的 Aurora 核发送数据，通过其 TXP/TXN 输出。

激励构造：连续发送500个帧，每帧包含 10 个周期（64-bit 数据），数据内容交替为 0x5555_5555_5555_5555（帧类型 A）和 0xAAAA_AAAA_AAAA_AAAA（帧类型 B）。

图6 Aurora 仿真测试设计框图

3.2 Aurora Frame Gen模块设计

3.2.1 规格概述

帧生成器负责产生符合 LocalLink 协议的测试帧，用于激励 Aurora 发送通道。其核心功能包括：

在通道建立（CHANNEL_UP 为高）后持续发送固定长度的帧。

每帧包含 10 个周期（64-bit 数据），数据内容交替为 0x5555_5555_5555_5555（帧类型 A）和 0xAAAA_AAAA_AAAA_AAAA（帧类型 B）。

正确产生帧起始（SOF）、帧结束（EOF）及有效字节数指示（REM）。

支持反压时的握手处理（TX_DST_RDY_N 信号），当下游未就绪时暂停发送。

3.2.2 接口列表

| 信号 | 方向 | 位宽 | 描述 |

| TX_D | O | 64 | 发送数据总线 |

| TX_REM | O | 3 | 有效字节数减 1（0~7），在 EOF 周期指示最后一拍的有效字节数 |

| TX_SOF_N | O | 1 | 帧开始标志，低有效（在帧的第一个周期为 0） |

| TX_EOF_N | O | 1 | 帧结束标志，低有效（在帧的最后一个周期为 0） |

| TX_SRC_RDY_N | O | 1 | 源就绪，低有效（数据有效时为 0） |

| TX_DST_RDY_N | I | 1 | 目的就绪，低有效（下游可接收数据时为 0） |

| CHANNEL_UP | I | 1 | 通道已建立标志，高有效 |

| USER_CLK | I | 1 | 用户时钟，由 Aurora IP 核提供 |


3.2.3 接口时序

模块接口的时序图如下：

图中可以看到当CHANNEL_UP起来后，状态机跳转到frame即工作模式，直到下次系统复位才会再进入idle模式。只有当源头来自aurora ip的TX_DST_RDY和该模块的输出数据有效指示TX_SRC_RDY都有效，数据可以被正确握手传输到后级模块。

发送的激励数据固定为一帧10拍数据，每拍8byte数据。同时规定了每帧的最后一拍数据的REM指示为3，表示只有大端模式的高4byte数据有效；其他拍数为7，表示8byte数据均有效选通。每帧发送的数据DATA也是固定的，其中奇数帧为64’h5555_5555；偶数帧为64’haaaa_aaaa。

图7 Aurora Frame Gen模块时序

3.2.4 功能设计

模块内部使用以下寄存器：

state：当前状态（IDLE 或 FRAME）。

cnt[3:0]：帧内周期计数器，取值范围 0~9。

frame_type：当前帧类型，0 表示类型 A，1 表示类型 B。

bytes_sent_r[31:0]：累计发送字节数（用于统计，不影响帧产生）。

first_tx_dst_rdy_n：用于记录第一次握手，可选。

状态机状态设计：

IDLE 状态：复位后进入。一旦 CHANNEL_UP 有效且复位无效，立即进入 FRAME 状态，同时 cnt 清零。

FRAME 状态：在此状态下持续发送当前帧的数据。每个时钟周期，若 TX_DST_RDY_N 为低（即下游准备好接收数据），则 cnt 递增；否则 cnt 保持不变，直到握手成功。当 cnt 达到 9 时，表示当前帧结束，下一周期 cnt 回绕到 0，开始新一帧，同时 frame_type 翻转，实现交替模式。

数据总线TX_D：根据 frame_type 直接输出对应的常数，不随 cnt 变化。数据通过类型 A、类型 B固定的交替模式来生成。类型 A 为 64'h5555_5555_5555_5555，类型 B 为 64'hAAAA_AAAA_AAAA_AAAA。这种固定模式简化了后续检查。

帧控制信号：

TX_SOF_N：在 FRAME 状态且 cnt == 0 时为 0，否则为 1。

TX_EOF_N：在 FRAME 状态且 cnt == 9 时为 0，否则为 1。

TX_REM：在非 EOF 周期可为任意值，但为统一设计，非 EOF 周期固定为 3'b111（表示 8 字节有效）；在 EOF 周期（cnt==9）也固定为 3'b111，因为本设计每帧均为整 8 字节，无需部分字节。

TX_SRC_RDY_N：在 FRAME 状态时为 0，否则为 1。状态机仅在 TX_DST_RDY_N 为低时递增计数器，确保数据不会因下游未就绪而丢失。这符合 LocalLink 协议的握手规则。

复位行为：复位时状态回到 IDLE，cnt 清零，frame_type 复位为 0，确保首次发送为类型 A。

本设计在测试 Aurora 通道的完整性时使用了固定的交替模式，主要基于以下考虑：

简化验证：固定模式便于在帧检查器中直接比对，无需复杂的数据预测逻辑。

硬件测试适配：某些硬件测试场景需要已知的激励模式，例如眼图测试、误码率测试，固定模式有助于定位问题。

帧长度固定：每帧 10 周期（80 字节），长度适中，既不过短导致通道频繁建立，也不过长影响仿真时间。

3.3 Aurora Frame Check模块设计

2.5.1 规格概述

帧检查器接收来自 Aurora 接收路径的 LocalLink 数据，与期望的交替数据模式进行比对，统计错误字节数。其核心任务包括：

对输入数据进行打拍，以改善时序。

根据 RX_REM 对齐接收数据和期望数据，仅比较有效字节。

通过检测接收到的 EOF 自动切换期望帧类型，与发送端保持同步。

错误计数器递增直到饱和，输出 DATA_ERR_COUNT。

3.3.2 接口列表

| 信号 | 方向 | 位宽 | 描述 |

| RX_D | I | 64 | 接收数据总线 |

| RX_REM | I | 3 | 有效字节数减 1（0~7） |

| RX_SOF_N | I | 1 | 帧开始标志，低有效（未使用） |

| RX_EOF_N | I | 1 | 帧结束标志，低有效 |

| RX_SRC_RDY_N | I | 1 | 源就绪，低有效（数据有效） |

| DATA_ERR_COUNT | O | 8 | 错误字节计数，饱和至 8'hFF |

| CHANNEL_UP | I | 1 | 通道建立标志 |

| USER_CLK | I | 1 | 用户时钟 |

| RESET | I | 1 | 全局复位 |


3.3.3 接口时序

模块接口的时序图如下：

图中可以看到frame check模块。该模块会将收到的RX_D数据根据RX_REM来映射出aligned_rx，每帧last拍的aligned_rx为64’h5555_0000或64’haaaa_0000。根据 RX_REM 对齐接收数据和期望数据，并比较每拍有效字节的数据是否匹配，若有错误，会进行DATA_ERR_COUNT错误统计。

图8  Aurora Frame Check模块时序

3.3.4 功能设计

模块内部寄存器与功能设计：

输入打拍寄存器：RX_D_R, RX_REM_R, RX_EOF_N_R, RX_SRC_RDY_N_R，在 USER_CLK 上升沿采样输入信号，用于后续组合逻辑。打拍可减少输入延迟对比较逻辑的影响。

期望帧类型寄存器：exp_frame_type，0 表示当前期望类型 A，1 表示类型 B。由 EOF 检测触发翻转。

数据有效标志：data_valid = !RX_SRC_RDY_N_R，表示当前周期数据有效。

EOF 检测：eof_detected = !RX_EOF_N_R && !RX_SRC_RDY_N_R，即数据有效且 EOF 为低。

对齐后的数据：aligned_rx 和 aligned_exp，根据 RX_REM_R 将无效字节置零。

期望帧类型切换设计：

为了与发送端保持同步，帧检查器必须知道当前帧应为何种类型。由于发送端每帧交替，接收端可通过检测 EOF 来切换期望类型。当检测到有效的 EOF 时，期望类型会由FF（64位完整有效的数据）翻转为F0。

错误计数逻辑设计：

错误计数仅在通道建立后使能，避免通道未就绪时的误报。

计数达到 255 后停止递增，防止溢出。

3.4 测试步骤与判定

上电步骤：

给 FPGA 板上电，等待时钟稳定和系统控制释放 RESET。

通过 ILA 捕获LANE_UP 和 CHANNEL_UP ：两个信号拉高，表示链路建立成功。

通过 ILA 捕获HARD_ERR 、 SOFT_ERR和DATA_ERR_COUNT：若存在信号非零，说明链路存在误码。

双向通信成功标志：

两个 DUT 的 通道建立信号channel_up 都变为高电平，表明两条物理链路均已建立。

接收有效标志：

监测每个 DUT 内部的 rx_tvalid_r 信号（该信号在 exdes 中寄存了 Aurora 核的 rx_tvalid_i，表示有数据被接收）rx_tvalid_r 有效会置位flag_rxtvalid。

flag_rxtvalid1 置位 → DUT1 至少成功接收过一次数据。flag_rxtvalid2 置位 → DUT2 至少成功接收过一次数据。

错误计数器统计标志：

若任一方向的错误计数器data_err_count_1_o 或data_err_count_2_o 非零，即测试失败。

帧计数器统计标志：

可设置发送方向发送的帧数量，在仿真结束时会比较发送方向的总发送帧计数tx_frame_cnt和接收方向收到的总接收帧计数rx_frame_cnt。若两者不同，即测试失败，并打印 frame_cnt check Fail。

CRC校验结果标志：

对Aurora ip1，在crc_valid_1有效时检查对应的crc_pass_fail_n_1信号是否为高，即证明CRC校验成功。

对Aurora ip2，在crc_valid_2有效时检查对应的crc_pass_fail_n_2信号是否为高，即证明CRC校验成功。

以上标志在实测中均为正常结果，即测试预期与实测结果一致。
