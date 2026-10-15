# fdma_aurora_brg IP  IT验证1

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\fdma_aurora_brg IP  IT验证1.docx`
- SHA-256: `b8c1416a9fca7f2909a364220bdd7a7e9e01945a89a42dec37aa7e7fd4afc6ef`
- Extractor: `python-docx+zip-structure-check`
- Tags: `aurora, fdma, pcie, verification`
- Duplicate sources:
  - none

| 产品名称Product name | 密级Confidentiality level |

| RTDS |  |

| 产品版本Product version | Total pages 共 页 |

| V1.0 | Total pages 共 页 |


FDMA2LocalLink IP开发验证方案

| Prepared by 拟制 |  | Date 日期 | 2026-5-30 |

| Reviewed by 评审人 |  | Date 日期 |  |

| Approved by 批准 |  | Date 日期 |  |


Revision Record 修订记录

| Revision Version 修订版本 | Change Description 修改描述 | Author 作者 | Date 日期 |

| 1.0 | 完成初稿 | 买博 | 26.5.30 |


目录

Revision Record 修订记录	2

目录	3

1 概述	3

1.1 验证对象	3

1.2 验证平台	3

1.3 接口列表	4

1.4 时钟和复位	6

2 测试用例	7

2.1 基础功能测试 (basic_test)	7

2.2 反压测试 (backpressure_test)	8

3 测试结果	9

3.1 测试通过标准	9

3.2 仿真结果	10

1 概述

1.1 验证对象

fdma_aurora_brg 是一个双向桥接 IP，完成 FDMA 总线接口与 Aurora 64B66B 核 LocalLink 接口之间的协议转换与数据缓冲。包含两个独立数据通路：

TX 方向：从 FDMA 读接口（250 MHz，64 bit）读取固定长度突发（512 字节），写入异步 FIFO，再以 1024 字节固定帧格式通过 LocalLink 发送接口输出。

RX 方向：从 LocalLink 接收接口接收 1024 字节帧，写入异步 FIFO，再以 512 字节突发通过 FDMA 写接口存入存储器。

验证需覆盖两个方向的功能正确性、跨时钟域数据完整性、流控反压机制、边界条件及异常恢复能力。

1.2 验证平台

采用模块级验证（IP 级），基于 SystemVerilog 搭建 UVM 或轻量级直接测试平台，仿真验证为主。

fdma_aurora_brg_tx将FDMA的读从机读出的数据写入AFIFO，再从AFIFO读出送到LL TX模块。fdma_aurora_brg_rx将LL RX模块接收的数据写入AFIFO，再从AFIFO读出送到FDMA的写从机。

图1 系统顶层验证平台

DUT：fdma_aurora_brg_top 模块。

FDMA读BFM：模拟 FDMA 从机，接收读请求，按突发返回数据，支持 rbusy 反压。

FDMA写BFM：模拟 FDMA 从机，接收写数据，支持 wbusy 反压，记录写数据。

Aurora RX激励器：模拟远端 Aurora 发送，将预先生成的帧按 LocalLink 协议驱动到 DUT 的 RX 接口。

Aurora TX 监视器：监测 DUT 的 TX 接口，收集输出数据帧。

Scoreboard：比对发送端原始数据与接收端输出数据（双向独立比对），统计错误。

反压控制器：可编程控制 tx_dst_rdy 信号，产生随机或确定性反压模式。

1.3 接口列表

以下为DUT模块的接口列表：

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


1.4 时钟和复位

提供两个独立时钟：fdma_clk (250 MHz)，user_clk (161.13 MHz)。

异步复位 fdma_rstn、user_rstn，复位释放需同步。

channel_up 信号在复位释放后拉高，模拟 Aurora 通道建立。

2 测试用例

2.1 基础功能测试 (basic_test)

目的：

验证无反压时，双向数据通路能正确传输若干帧。

测试步骤：

复位释放，等待 channel_up 拉高。

发送方向：主激励生成 NUM_FRAMES_TO_TEST（例如 5 帧），每帧 1024 字节（128 个 64bit 字）。数据内容为 (frame_id << 32) | word_index。

将每帧拆分为 2 个 FDMA 读突发（每个突发 512 字节 = 64 字），将突发数据压入 read_burst_queue 供 FDMA 读从机返回。

同时将预期数据压入 tx_expected_queue。

接收方向：通过 send_aurora_frame 向 DUT 的 RX 接口发送相同内容的帧，同时将预期数据压入 rx_expected_queue。

DUT 处理后，FDMA 写从机将接收到的数据存入 rx_actual_queue；Aurora TX 监测将发送的数据存入 tx_actual_queue。

等待所有数据传输完成（队列长度达到预期）。

调用 compare_data() 比对 tx_expected_queue vs tx_actual_queue 以及 rx_expected_queue vs rx_actual_queue。

预期结果：

比对结果全部匹配，无错误。

无 FIFO 溢出/下溢。

状态机转移正常。

2.2 反压测试 (backpressure_test)

目的：

验证 Aurora 发送侧反压（tx_dst_rdy）时，DUT 能正确暂停发送，FIFO 不溢出，恢复后继续正确传输。

测试步骤：

复位释放，等待 channel_up 拉高。

配置反压模式（参数 BACKPRESSURE_MODE）：

MODE 1：长时间连续反压（如拉低 200 周期，拉高 900 周期）

MODE 2：隔拍反压（50% 占空比，一周期高、一周期低）

MODE 3：固定间隔反压（如每 10 周期拉低 5 周期）

MODE 4：随机反压（随机间隔 1~20 周期，随机持续时间 5~30 周期）

启动主激励，发送 50 帧（数据同基础测试）。

在仿真过程中，aur_if.tx_dst_rdy 按选定模式动态变化。

结束后比对预期队列与实际队列。

预期结果：

所有数据最终完全匹配，无丢失。

FIFO 水位动态变化，但不会溢出（almost_full 会反压 FDMA 读请求，防止溢出）。

无 FIFO 下溢（发送端不会在 FIFO 空时读数据）。

tx_src_rdy 会根据 tx_dst_rdy 和 FIFO 非空正确拉高/拉低。

2.3 地址边界回绕测试 (tb_address_wrap_test)

目的：验证 TX/RX 方向 FDMA 地址在 TEST_MEM_SIZE（4KB）边界处正确回绕到 0，回绕后数据连续无丢失。

2.4 FIFO特殊场景测试 (tb_fifo_corner_test)

目的：验证 FIFO 在 almost_full/almost_empty 阈值触发、复位恢复、极端速率差异等特殊场景下的行为正确性。通过 TEST_SCENARIO 参数选择子场景。

3 测试结果

3.1 测试通过标准

基础测试用例100% 通过，数据比对无错误。

反压测试用例均通过，数据比对无错误。

仿真日志中无 fifo_overflow、fifo_underflow 意外触发（允许在反压切换瞬间短暂出现，但不影响最终正确性）。

channel_up 为高后，双方向均有数据传输且正确。

3.2 仿真结果

：

。

：

。

：

以上标志在实测中均为正常结果，即测试预期与实测结果一致。
