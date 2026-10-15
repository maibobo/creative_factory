# RTDS_test-1ch_XDMA_Aurora设计与验证方案规格书

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test-1ch_XDMA_Aurora设计与验证方案规格书.docx`
- SHA-256: `ed61096dd29e23b5a719a792734a781a77f073f47ca58b2b637a1d97f6a1d9f0`
- Extractor: `python-docx+zip-structure-check`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

TECHNICAL DESIGN SPECIFICATION

RTDS_test-1ch XDMA–Aurora

设计架构、接口规格、数据流、关键时序与 Root Port 大仿真验证方案

| 字段 | 内容 |

| 项目 | RTDS_test-1ch / PCIE-CPU |

| 工具基线 | Vivado / XSim 2020.2 |

| PCIe | XDMA Gen3 x2，H2C/C2H 各 1 通道 |

| 数据面 | AXI4 64 bit @ 250 MHz；Aurora LocalLink 64 bit @ 156.25 MHz |

| 文档状态 | V1.1 详细设计规格；以远程机现行 PCIe.v/adapter RTL 为基线 |

| 生成日期 | 2026-08-20 |


| 适用范围 本文同时描述生产设计和仿真验证环境。生产硬件包含 Aurora 64B/66B 与 GT；Root Port 大仿真在 PCIe 模块的 LocalLink 边界使用轻量 BFM，不覆盖 Aurora 编码、GT、CDR 或真实串行误码。 |


图 1  RTDS_test-1ch 生产设计总体架构

# 文档控制

| 版本 | 日期 | 状态 | 变更说明 |

| V1.0 | 2026-07-24 | 基线 | 汇总生产 RTL、1ch XDMA 配置、双向数据流、MSI/IRQ 语义及 Root Port 大仿真验证方案。 |

| V1.1 | 2026-08-20 | 详细设计 | 补充远程机现行 PCIe.v 与 adapter 的子模块架构、电路级实现、完整信号词典及关键时序图。 |


## 阅读导航

第 1～3 章：目标、约束与生产设计架构。

第 4～8 章：顶层/子模块接口、寄存器、时钟复位和双向数据流。

第 9～11 章：中断、关键时序、异常与恢复。

第 12～15 章：验证环境、测试点矩阵、波形/日志门禁和覆盖边界。

附录：完整信号词典、ILA 探针和复现入口。

# 1. 目标与设计基线

本设计在 FPGA 内部建立 CPU/PCIe 与 Aurora 串行链路之间的双向 512 B 数据通路。CPU 通过 XDMA H2C 将数据写入卡端地址窗口，Adapter 使用 FDMA 读取并发送至 Aurora；Aurora 接收数据后由 FDMA 写入卡端窗口，产生用户中断，再由 CPU 使用 XDMA C2H 读回。

| 项目 | 规格 |

| 器件工具 | Vivado 2020.2；仿真器 XSim 2020.2 |

| PCIe | Gen3 x2；Vendor ID 0x10EE；Device ID 0x8032 |

| XDMA 通道 | H2C 1 ch；C2H 1 ch |

| AXI 数据面 | 64 bit，250 MHz |

| Aurora LL | 64 bit，156.25 MHz；单帧 512 B / 64 beat |

| 卡端窗口 | RX base 0x0000；TX base 0x8000；活动窗口 32 KiB |

| 中断 | XDMA user interrupt，经 MSI；vector 0 / mask bit0 |

| 最小验收 | Gen3 x2、枚举/BAR、基础 H2C/C2H、双向 Aurora 512 B、IRQ/clear、断言与 scoreboard 全通过 |


| 核心约束 Aurora→FPGA 方向不能依赖 FPGA 对线路施加反压。BFM 连续提供 RX 数据；若 FPGA 撤销接收能力，视为溢出/协议错误，而不是合法等待。 |


# 2. 生产设计架构

生产顶层 TOP 完成板级时钟、复位、PCIe 引脚、Aurora GT/SFP 和状态 LED 的集成。TOP 内部的 PCIe 模块包含真实 design_1_wrapper/xdma_0、INFO_EXCH、CONV_DMA、BRAM/AXI Interconnect、用户中断和 FDMA–Aurora Adapter。

| 层次 | 模块 | 职责 |

| 板级 | TOP | 板级引脚、CLK_GEN、Aurora 64B/66B、PCIe、LED。 |

| PCIe 集成 | PCIe | 连接 XDMA/BD、Adapter、ILA 和 INFO_EXCH 状态。 |

| XDMA/AXI | design_1_wrapper | PCIe Endpoint、H2C/C2H、AXI/AXI-Lite、BRAM 地址空间和用户 IRQ。 |

| 协议适配 | pcie_fdma_aurora_brg_adapter | 命令校验、FDMA bridge、CDC、帧计数、IRQ 与 sticky status。 |

| 内存访问 | CONV_DMA | 把自定义 FDMA 请求转换为 AXI4 burst。 |

| 软件接口 | INFO_EXCH | AXI-Lite 寄存器、命令触发、状态和 read-to-clear。 |

| 串行链路 | aurora_64b66b_top | 生产环境的 Aurora 64B/66B、GT 和 LocalLink 接口。 |


# 3. 数据路径与所有权

图 2  双向 512 B 数据流

## 3.1 CPU → Aurora

软件准备 Host 源数据和 H2C descriptor，通过 XDMA 写入卡端 TX 窗口 0x8000。

软件写 INFO_EXCH 0x24/0x28，并对 0x20 执行 0→1→0；上升沿产生 RD_START。

Adapter 校验地址、长度、链路状态与并发状态，发出 FDMA read。

FDMA bridge 从 CONV_DMA/AXI 取得 64 个 64-bit beat，经 CDC/FIFO 进入 Aurora 用户时钟域。

LocalLink TX 产生 SOF、连续 payload 和 EOF；完成后 CPU_WR_DONE_resp 回落。

## 3.2 Aurora → CPU

Aurora RX 提供 512 B 连续 LocalLink 帧。FPGA 不得把 dst_rdy 当作对线路的长期反压机制。

RX bridge 跨时钟缓存并发出 FDMA write，目标窗口基址 0x0000。

写突发完成后 Adapter 锁存 start/len，置 rx_pending、INT_STATE 和 FPGA_CPU_irq_req。

XDMA 在 MSI 已使能时接受 usr_irq_req 并返回 usr_irq_ack；主机读取 INFO_EXCH 0x10 清状态。

软件提交 C2H descriptor，把卡端 0x0000 的 512 B 搬到 Host 目标区，再对 0x14 执行 1→0 重新武装。

# 4. 时钟、复位与链路条件

| 时钟/复位 | 频率/极性 | 使用模块 | 设计要求 |

| pcie_diff_clk | 100 MHz 差分 | XDMA Endpoint | PCIe 参考时钟。 |

| i_sys_clk / fdma_clk | 250 MHz | Adapter FDMA 域、CONV_DMA、ILA | FDMA、状态寄存及主要控制域。 |

| aurora_user_clk | 156.25 MHz | Aurora LL、TX/RX bridge | 与 fdma_clk 异步，使用 XPM CDC/FIFO。 |

| pcie_rst_n | 低有效 | XDMA Endpoint | 大仿真保持低约 5 us 后释放。 |

| i_sys_rst | 高有效 | PCIe 集成逻辑 | 传给 Adapter 时转换为 fdma_rstn=!i_sys_rst。 |

| aurora_user_rstn | 低有效 | Aurora 用户域 | BFM 稳定 16 个 LL 时钟后置 channel_up/lane_up。 |


Adapter 对 PCIe link、Aurora channel_up 和 lane_up 分别进行两级同步，并在目标域形成 link_up_user/link_up_fdma。TX 活动还参与子桥复位，使一个命令对应一个受控 burst 序列；RX 侧只要链路有效即保持可接收。

# 5. 顶层接口规格

## 5.1 TOP 板级端口

| 信号 | 方向/宽度 | 含义 |

| clk_p/n | 输入，1 bit | 板级差分系统时钟，供 CLK_GEN。 |

| pcie_mgt_rxp/n[1:0] | 输入 | PCIe Endpoint x2 串行接收。 |

| pcie_mgt_txp/n[1:0] | 输出 | PCIe Endpoint x2 串行发送。 |

| pcie_diff_clk_p/n[0] | 输入 | PCIe 100 MHz 差分参考时钟。 |

| pcie_rst_n | 输入，低有效 | PCIe PERST#。 |

| user_lnk_up | 输出 | XDMA 链路建立状态。 |

| GTHQ0_P/N | 输入 | Aurora GT 参考时钟。 |

| aurora_rxp/n | 输入 | Aurora 串行接收。 |

| aurora_txp/n | 输出 | Aurora 串行发送。 |

| sfp_tx_disable/rs0/rs1 | 输出 | SFP 控制。 |

| led | 输出 | 板级状态指示。 |


## 5.2 PCIe 模块 LocalLink 端口

| 信号 | 方向 | 语义 |

| aurora_tx_d[63:0] | 输出 | FPGA→Aurora payload。 |

| aurora_tx_sof/eof | 输出 | 帧首/帧尾。 |

| aurora_tx_rem[2:0] | 输出 | 尾拍有效字节编码；512 B 满拍为 3'b111。 |

| aurora_tx_src_rdy | 输出 | TX 数据有效。 |

| aurora_tx_dst_rdy | 输入 | Aurora Core 接收能力；TX 可按握手暂停。 |

| aurora_rx_d[63:0] | 输入 | Aurora→FPGA payload。 |

| aurora_rx_sof/eof | 输入 | RX 帧界。 |

| aurora_rx_rem[2:0] | 输入 | 尾拍有效字节编码。 |

| aurora_rx_src_rdy | 输入 | RX 数据有效，真实链路侧连续推进。 |

| aurora_rx_dst_rdy | 输出 | 内部接收能力指示；不能用于让远端 SerDes 回退已到达数据。 |


# 6. 子模块详细设计规格

| 规范性说明 本章是 PCIe.v 与 pcie_fdma_aurora_brg_adapter 的实现依据。RTL 应按本章定义的时钟域、复位极性、组合条件、寄存器生命周期、握手推进条件、地址/长度单位和异常清除规则编写；不得仅依据端口名称猜测 valid/ready 语义。 |


## 6.1 PCIe.v 集成模块

PCIe.v 是板级 TOP 与 design_1_wrapper/Adapter 之间的稳定集成边界。该层不实现 PCIe TLP、AXI burst、跨时钟 FIFO 或帧状态机，只负责固定系统参数、统一复位极性、建立语义正确的 FDMA/INFO_EXCH 连接、透传 LocalLink、汇集 ILA 探针，并保持原 XDMA Block Design 的端口和软件地址映射不变。

图 3  PCIe.v 内部子模块、接口组与职责边界

### 6.1.1 固定规格与不变量

| 常量 | 值 | 实现约束 |

| FRAME_BYTES | 512 B | 一帧固定 64 个 64-bit beat；同时约束软件命令、FDMA burst 与 LocalLink 帧界。 |

| ACTIVE_WINDOW_BYTES | 32 KiB | 每个方向 64 帧；地址逻辑采用半开区间 [base, base+32 KiB)。 |

| RX_BASE_ADDR_LO | 0x0000_0000 | Aurora→CPU 的 FDMA write 窗口低地址。 |

| TX_BASE_ADDR_LO | 0x0000_8000 | CPU→Aurora 的 FDMA read 窗口低地址。 |

| CARD_ADDR_HI | 0x0000_0000 | 与低 32-bit 地址拼成 64-bit card address；不得把软件地址当主机物理地址。 |


i_sys_rst 为高有效，而 Adapter 的 fdma_rstn 与 design_1_wrapper 的 sys_rst_n 为低有效，因此两处均使用 !i_sys_rst。user_lnk_up 直接等于 user_lnk_up_int，不额外打拍或门控，保证原 TOP/软件可见链路时序不变；Adapter 内部再把该状态与 Aurora channel_up/lane_up 同步后相与形成真实业务放行条件。

### 6.1.2 三个子模块的连接职责

| 实例 | 时钟/复位 | 输入来源 | 输出去向 | 职责 |

| u_pcie_fdma_aurora_brg_adapter | i_sys_clk/!i_sys_rst；aurora_user_clk/aurora_user_rstn | INFO、FDMA返回、PCIe/Aurora link、LL RX | FDMA请求、LL TX、IRQ/status/sticky | 完成双向桥接、CDC、帧控制和所有权。 |

| ila_FDMA_inst | i_sys_clk | FDMA地址/请求/数据/size、bridge状态 | ILA capture | 只观测，不反馈控制；probe12=RX状态，probe13=TX状态。 |

| design_1_wrapper_inst | i_sys_clk/!i_sys_rst；PCIe refclk/PERST# | PCIe物理输入、Adapter FDMA/IRQ/status | PCIe物理输出、INFO命令、FDMA返回、link | 保留 XDMA、CONV_DMA、INFO_EXCH、BRAM/AXI 和 MSI。 |


### 6.1.3 FDMA write 语义改名电路

图 4  CONV_DMA 历史端口名的语义隔离与正确连线

写数据每拍只有在 fdma_w_source_valid && fdma_w_accept 同时为 1 时提交。PCIe.v 通过 fdma_w_source_valid/fdma_w_accept 两个语义名阻断错误直觉：Adapter.fdma_wvalid 必须接 BD.fdma_wready_0；BD.fdma_wvalid_0 必须接 Adapter.fdma_wready。若按同名直连，数据源与接收确认方向会颠倒，可能造成丢字、重复或永久停顿。

### 6.1.4 连接组与关键实现

| 连接组 | 信号 | 产生者 → 消费者 | 实现规则 |

| FDMA read 请求 | fdma_raddr/rareq/rsize | Adapter → CONV_DMA | 请求被 rbusy 接受前地址和 size 保持；size=64 beat。 |

| FDMA read 数据 | fdma_rdata/rvalid/rready | CONV_DMA ↔ Adapter | 只在 rvalid&&rready 时进入 TX FIFO。 |

| FDMA write 请求 | fdma_waddr/wareq/wsize | Adapter → CONV_DMA | 请求被 wbusy 接受前地址和 size 保持。 |

| FDMA write 数据 | fdma_wdata/source_valid/accept | Adapter ↔ CONV_DMA | 按真实 source-valid/data-accept 语义推进。 |

| TX 软件命令 | RD_START/CPU_FPGA_START_ADDR/LEN | INFO_EXCH → Adapter | 地址/长度先稳定，RD_START 单周期触发。 |

| RX 软件通知 | FPGA_CPU_START_ADDR/LEN、INT_STATE_W、irq_req | Adapter → INFO/XDMA | 仅完整 FDMA write burst 后发布。 |

| 所有权/清除 | CPU_REC_STATE_R/W、INT_STATE_R、CLEAR_INTER_R | INFO ↔ Adapter | 中断清除与 buffer 归还是两个独立动作。 |

| LocalLink | aurora_tx_* / aurora_rx_* | Adapter ↔ TOP/Aurora | 所有 payload/frame/ready 语义保持在 aurora_user_clk 域。 |


## 6.2 pcie_fdma_aurora_brg_adapter

Adapter 是软件命令、FDMA、Aurora LocalLink 和中断状态之间的语义边界。它复用 fdma_aurora_brg_tx/rx 作为双向数据子桥，在外层补充命令校验、地址窗口、跨域链路条件、帧完成事件、RX 所有权、IRQ、帧协议检查和 sticky/timeout 汇聚。多比特 payload 只通过异步 FIFO 跨域，控制电平和事件采用明确的 CDC 模式。

图 5  Adapter 双时钟域功能电路与子模块分解

### 6.2.1 参数、单位与静态约束

| 参数/派生量 | 当前值 | 单位/用途 | 约束 |

| FRAME_BYTES | 512 | byte/帧 | 当前计数器与尾拍规则只允许 512。 |

| ACTIVE_WINDOW_BYTES | 32768 | byte/方向窗口 | 必须为正且为 FRAME_BYTES 整数倍。 |

| RX_BASE_ADDR_LO | 0x0000_0000 | RX低32位基址 | base+window 不得跨 4 GiB。 |

| TX_BASE_ADDR_LO | 0x0000_8000 | TX低32位基址 | base+window 不得跨 4 GiB。 |

| CARD_ADDR_HI | 0 | card address高32位 | 与低地址拼接后参与 64-bit FDMA 地址。 |

| FDMA_TIMEOUT_CYCLES | 65535 | fdma_clk 周期 | 仅 waiting 且无 progress 时累加。 |

| FRAME_WORDS | 64 | 64-bit word/帧 | FRAME_BYTES/8。 |

| FRAME_BYTES_32 | 512 | 软件通知字节数 | 固定写入 fpga_cpu_len。 |

| FRAME_WORDS_16 | 64 | FDMA size beat数 | 覆盖 RX bridge 的历史 byte-size 输出。 |


| 子模块/资源 | 数量 | 接口角色 | 设计说明 |

| fdma_aurora_brg_tx | 1 | FDMA read ↔ async FIFO ↔ LL TX | 每个 burst/frame 固定 512 B；支持 TX dst_rdy 背压。 |

| fdma_aurora_brg_rx | 1 | LL RX ↔ async FIFO ↔ FDMA write | 连续接收；FIFO 满/撤 ready 作为系统错误。 |

| xpm_cdc_single level | 9 | link/active/waterline/error 电平 | 两级目标域同步；同步结果只能在目标域使用。 |

| toggle CDC | 2 | tx_frame_done、clear_inter 脉冲 | 源域翻转、目标域同步后异或恢复单周期事件。 |

| XPM async FIFO | TX/RX 各1 | 64-bit payload CDC | TX 4 KiB，RX 16 KiB；多比特数据禁止逐位同步。 |


### 6.2.2 时钟域、链路门控与局部复位

图 6  Adapter 跨时钟域信号、方向与同步模式

| 目标域 | 放行条件 | 局部复位 | 行为 |

| fdma_clk / TX | pcie_link_up && sync(channel_up) && sync(lane_up) && tx_active | tx_fdma_rstn | 无合法命令或掉链时清 TX FDMA 侧和 FIFO 写侧，防止残留数据进入下一命令。 |

| user_clk / TX | sync(pcie_link_up) && channel_up && lane_up && sync(tx_active) | tx_user_rstn | 仅活动命令允许 LocalLink TX；末字真握手才产生 frame_done。 |

| fdma_clk / RX | pcie_link_up && sync(channel_up) && sync(lane_up) | rx_fdma_rstn | 链路有效即允许把 FIFO 数据写入 card memory。 |

| user_clk / RX | sync(pcie_link_up) && channel_up && lane_up | rx_user_rstn | 链路有效即接收；与软件是否有 TX 命令无关。 |


### 6.2.3 TX 命令校验与事务寄存器

图 7  TX 配置组合逻辑、命令接管与事务退出条件

tx_requested_end 和 tx_window_end 使用 33-bit 无符号加法。tx_config_valid 必须同时满足：cpu_fpga_len 非零；起始地址与长度按 512 B 对齐；长度不超过 32 KiB；起始地址不低于 TX_BASE_ADDR_LO；半开区间结束地址不超过 TX window end；加法最高位不产生回绕。tx_start_valid 还要求 !tx_active 与 link_up_fdma。

| 事件 | 寄存器更新 | 可见结果 |

| tx_start_valid | tx_active=1；锁存 tx_base_addr_lo、tx_target_frames；completed=0 | cpu_wr_done_resp=1；TX 子桥解除局部复位。 |

| 活动期 frame_done | completed+1；若达到 target 则 active/target/completed 清零 | 最后一帧完成后 resp=0。 |

| 活动期 link_down | active/target/completed 清零 | resp=0；link_down_sticky=1；事务需软件重发。 |

| 配置非法或忙时 rd_start | 不接管新命令 | length_error_sticky=1；原活动事务不被新配置覆盖。 |

| down 时 rd_start | 不接管命令 | link_down_sticky=1。 |


### 6.2.4 TX 数据路径、地址与完成事件

TX 子桥内部 raw 地址从 0 开始按窗口递增/回绕，Adapter 输出 fdma_raddr={CARD_ADDR_HI,tx_base_addr_lo}+{32'd0,tx_fdma_raddr_raw}。fdma_rsize 恒为 FRAME_WORDS_16=64。FDMA read beat 只在 fdma_rvalid&&fdma_rready 时进入异步 FIFO；LocalLink beat 只在 aurora_tx_src_rdy&&aurora_tx_dst_rdy 时消费，背压期间 data/SOF/EOF/rem 必须稳定。

tx_frame_done_user 只在 LocalLink 第 64 beat 且 EOF 真握手时产生。该窄脉冲先翻转 tx_done_toggle_user，经两级同步得到 tx_done_toggle_fdma，再与 tx_done_toggle_fdma_d 异或恢复 tx_frame_done_fdma。完成计数以该事件为准；FDMA read 完成不等价于链路发送完成。

### 6.2.5 RX 数据路径、帧检查和水位

RX 子桥把 LocalLink 64-bit payload 写入异步 FIFO，在 fdma_clk 域发起 512 B FDMA write。fdma_waddr={CARD_ADDR_HI,RX_BASE_ADDR_LO}+{32'd0,rx_fdma_waddr_raw}；对外 fdma_wsize 固定覆盖为 64 beat，不能使用 rx_fdma_wsize_raw 的历史 byte 语义。rx_fifo_almost_full/full 经电平同步送到 fdma_clk 域用于观测；任一 FIFO overflow，或 aurora_rx_src_rdy=1 且 aurora_rx_dst_rdy=0，均锁存 RX overflow。

| 帧检查上下文 | 合法规则 | 错误条件 |

| 帧起点 | 首个 rx_hs 必须 aurora_rx_sof=1；word_count=1 | 帧内重复 SOF；帧外无 SOF 数据。 |

| 帧中 | 每个 rx_hs 增加 word_count；无 EOF | 第64拍前提前 EOF；超过64拍仍无 EOF。 |

| 帧终点 | 此前计数=63，当前 EOF=1 且 rem=3'b111 | 计数不等于63；rem不是全有效；SOF/EOF形成非法1-word帧。 |

| 掉链 | 清 rx_in_frame 和 word_count | 链路恢复后必须从新 SOF 建立上下文。 |


### 6.2.6 RX 所有权、通知与 IRQ

图 8  RX 完整落盘、CPU 所有权、中断清除与 overrun 判定

rx_burst_done_fdma 是发布通知的唯一数据完成条件。若 !rx_pending_r 或同拍 cpu_rec_ack，Adapter 发布 FPGA_CPU_START_ADDR=RX_BASE_ADDR_LO+rx_fdma_waddr_raw、FPGA_CPU_LEN=512，并置 fpga_cpu_irq_req、int_state_w_r、rx_pending_r。若前帧仍由 CPU 持有，则保持旧通知不变，仅置 rx_overrun_sticky_r，避免静默覆盖软件尚未读取的地址。

int_state_clear 或 clear_inter 只清 fpga_cpu_irq_req/int_state_w_r。cpu_rec_ack=cpu_rec_state_r&&!cpu_rec_state_d 检测 CPU_REC_STATE 上升沿，清 rx_pending_r 与 rx_overrun_sticky_r；cpu_rec_state_w 跟随 cpu_rec_state_r 作为回读/握手镜像。软件顺序应为：响应/清中断 → C2H 读完旧 buffer → CPU_REC_STATE 产生确认边沿。

### 6.2.7 Sticky 状态、跨域清除与超时

图 9  错误源、源域/目的域 sticky、clear hold 与 progress-aware timeout

| 最终状态 | 置位来源 | 清除/保持规则 |

| rx_overflow_sticky | RX FIFO overflow；或 RX valid 且本地 not-ready | clear_inter；源域清零返回前 user_status_clear_hold 阻止旧高电平反弹。 |

| tx_underflow_sticky | tx_user_dbg_bus[0] 报告 TX FIFO/供数不足 | clear_inter，经 user 域 clear toggle 清源 sticky。 |

| length_error_sticky | RX 帧界/长度/rem 错；TX 配置非法或忙时重启 | clear_inter。 |

| fdma_timeout_sticky | fdma_waiting 持续且无 fdma_progress 达到门槛 | clear_inter；progress 或不再 waiting 时 wait_count 清零。 |

| link_down_sticky | down 状态启动；活动期掉链；曾 up 后再次 down | clear_inter；seen_link_up 避免上电训练阶段误报。 |

| rx_overrun_sticky | pending 未释放时又完成新 RX burst | cpu_rec_ack 清除，不由普通中断 clear 清除。 |


fdma_waiting 覆盖 rareq、wareq、rready&&!rvalid、wvalid&&!wready 四类等待；fdma_progress 覆盖请求被 busy 接受、读/写数据真握手和 rx_burst_done。只要有 progress 或协议不再等待，fdma_wait_count 就清零；因此正常长事务只要持续推进不会误报 timeout。

## 6.3 CONV_DMA

CONV_DMA 将自定义 FDMA request/data 接口转换为 AXI4 master 五通道。AXI 地址宽度 64 bit、数据宽度 64 bit、ID 宽度 1。FDMA size 以 64-bit word 数表示，512 B 对应 64 word。

| 端口历史语义 生产 PCIe.v 已建立语义网：fdma_w_source_valid 连接 CONV_DMA 的 fdma_wready_0 输入；fdma_w_accept 由 CONV_DMA 的 fdma_wvalid_0 输出返回。名称与常规 valid/ready 直觉相反，禁止按字面重新接线。 |


## 6.4 INFO_EXCH

INFO_EXCH 是 32-bit AXI-Lite 从设备。地址和数据按独立 AXI-Lite 握手接收，WSTRB 支持逐字节写。软件命令通过寄存器边沿转换为单周期控制脉冲；状态寄存器连接 Adapter。

| 地址基准 BD 中 INFO_EXCH AXI-Lite segment 的卡内基址为 0x4000_0000、范围 4 KiB。下表列的是模块内偏移；Root Port TPI 经过 XDMA BAR 地址转换后以用户 BAR 内偏移 0x00～0x28 访问。 |


| 偏移 | 名称 | 属性 | 典型值 | 语义 |

| 0x00 | VERSION | RO | 0x00001001 | 设计/协议版本。 |

| 0x04 | PROG_TIME | RO | 0x20260506 | 构建日期标识。 |

| 0x08 | CH_BUF_LEN | RO | 0x00008000 | 通道缓冲窗口标称长度。 |

| 0x0C | FPGA_TEMP_W | RO | 运行值 | 温度/遥测输入。 |

| 0x10 | INT_STATE | RO / read-clear | 0/1 | 读取时产生 INT_STATE_R/CLEAR_INTER_R 单周期清除。 |

| 0x14 | CPU_REC_STATE | RW | 0 | CPU 接收完成/所有权释放；验证使用 1→0。 |

| 0x18 | FPGA_CPU_START_ADDR | RO | 0x00000000 | Aurora RX 完成后的卡端地址。 |

| 0x1C | FPGA_CPU_LEN | RO | 512 | Aurora RX 完成长度。 |

| 0x20 | CPU_WR_DONE | RW / edge | 0 | bit0 上升沿生成 RD_START；软件执行 0→1→0。 |

| 0x24 | CPU_FPGA_START_ADDR | RW | 0x00008000 | CPU→Aurora 卡端起始地址。 |

| 0x28 | CPU_FPGA_LEN | RW | 512 | CPU→Aurora 发送长度。 |


## 6.5 XDMA / design_1

| 项目 | 规格/用途 |

| 链路 | Gen3 x2，真实 Endpoint 与官方 RP 模型串行互连。 |

| 通道 | H2C 1 ch；C2H 1 ch。 |

| M_AXI | 64 bit @ 250 MHz，访问 BRAM/CONV_DMA 数据空间。 |

| M_AXI-Lite | 访问 INFO_EXCH 用户寄存器。 |

| 地址映射 | BRAM segment 基址 0x0000_0000、范围 64 KiB；INFO_EXCH 基址 0x4000_0000、范围 4 KiB。 |

| User IRQ | usr_irq_req[0]；由 XDMA 在 MSI 已使能时接受并给出 usr_irq_ack[0]。 |

| 软件可见完成 | descriptor count=1，status=0x6；每个事务独立判断，不要求跨事务单调递增。 |


## 6.6 ILA

| Probe | 信号 | 用途 |

| 0 | fdma_raddr[31:0] | FDMA read 地址 |

| 1 | fdma_rareq | 读请求 |

| 2 | fdma_rbusy | 读通道忙 |

| 3 | fdma_rdata[63:0] | 读数据 |

| 4 | fdma_rsize[15:0] | 读 word 数 |

| 5 | fdma_rvalid | 读数据有效 |

| 6 | fdma_waddr[31:0] | FDMA write 地址 |

| 7 | fdma_wareq | 写请求 |

| 8 | fdma_wbusy | 写通道忙 |

| 9 | fdma_wdata[63:0] | 写数据 |

| 10 | fdma_wsize[15:0] | 写 word 数 |

| 11 | fdma_w_source_valid | Aurora RX 数据源有效 |

| 12 | adapter_rx_state_dbg[3:0] | RX bridge 状态 |

| 13 | adapter_tx_state_dbg[3:0] | TX bridge 状态 |


大仿真不读取 ILA capture RAM，而是把探针源和相关握手信号直接写入 WDB。这样保留事务级可见性，同时避免 ILA 内部存储和触发逻辑增加仿真负担。

# 7. 中断与 MSI 语义

Adapter 产生 FPGA_CPU_irq_req，并通过 BD 连接到 XDMA usr_irq_req[0]。usr_irq_req 是应用层保持请求；msi_enable 是配置空间 MSI Enable 的运行时状态；usr_irq_ack 表示 XDMA 已接受该用户请求并生成相应中断消息。三者不是同一个阶段。

| 信号/状态 | 产生者 | 含义 | 清除/完成 |

| FPGA_CPU_irq_req | Adapter | RX burst 完成且获得 buffer 所有权后置位。 | INFO 0x10 read-to-clear。 |

| usr_irq_req[0] | RTDS→XDMA | 传给 XDMA 的用户中断请求，应保持至服务/清除。 | 随 Adapter IRQ 清除。 |

| msi_enable | XDMA | Host 已在配置空间允许 MSI。 | 由 PCIe 配置空间控制。 |

| usr_irq_ack[0] | XDMA | 用户请求被接受并发送/排队为 MSI 的确认。 | 脉冲/握手证据，不等于软件 ISR 完成。 |

| INT_STATE | Adapter/INFO_EXCH | 软件可读 sticky 状态。 | 读取 0x10 产生 clear。 |


| 验证边界 仿真已证明 MSI capability 配置、msi_enable、usr_irq_req/ack 和 read-to-clear 的硬件证据链；操作系统中断控制器、驱动 ISR 与真实 CPU 调度延迟仍需上板软件验证。 |


# 8. 关键时序

图 10  CPU→Aurora 与 Aurora→CPU/MSI 总体关键时序（语义示意，非等比例）

## 8.1 TX 命令接管与 FDMA read

图 11  TX 合法命令锁存、FDMA 请求接受与 64-beat 数据推进

rd_start 仅作为单周期请求。tx_start_valid 成立的同一 fdma_clk 边沿锁存地址和帧数；tx_active/cpu_wr_done_resp 从下一拍可见。fdma_rareq 由 TX bridge 发出并保持到 fdma_rbusy 接受；随后每个 beat 由 fdma_rvalid&&fdma_rready 推进。地址和 fdma_rsize 在请求接受前保持稳定。

## 8.2 Aurora TX 背压与帧完成 CDC

图 12  LocalLink TX stall 保持、EOF 真握手与跨域完成计数

aurora_tx_dst_rdy=0 的区间不消费数据，aurora_tx_d/sof/eof/rem/src_rdy 必须保持。只有 EOF 所在 beat 的 src_rdy&&dst_rdy 为真才翻转 tx_done_toggle_user。同步后的异或脉冲更新 tx_completed_frames；因此 CDC 延迟不会改变数据顺序，只推迟软件可见完成。

## 8.3 Aurora RX、FDMA write 与通知

图 13  RX 帧接收、FDMA write 握手与完整落盘后通知

Aurora EOF 仅表示一帧已进入 RX 路径，不表示 card memory 已写完。通知必须等待 rx_burst_done_fdma。PCIe.v 的 fdma_w_source_valid/fdma_w_accept 是本图中的真实有效/接受语义；CONV_DMA 端口名虽反向，推进条件仍为二者同时为 1。

## 8.4 IRQ 清除与 RX 所有权归还

图 14  中断应答、C2H 读取与 buffer ownership 的独立生命周期

中断生命周期和 buffer 生命周期不能合并。软件可先读 INFO 0x10 清 IRQ，rx_pending 仍保持，防止新帧覆盖旧通知；C2H 完成后再产生 CPU_REC_STATE 确认边沿归还所有权。若 pending 期间新 burst 完成，地址/长度保持旧值并置 rx_overrun_sticky。

## 8.5 clear_inter 跨域与旧状态抑制

图 15  Sticky clear 的双向 CDC 延迟与 user_status_clear_hold 窗口

clear_inter 到达时，FDMA 域最终 sticky 立即清零，同时 user_status_clear_hold=1。user 域在若干周期后收到 status_clear_user，清源域 sticky；这些 0 再同步回 fdma 域。只有 rx_overflow_fdma、tx_underflow_fdma、rx_length_error_fdma 全为 0，hold 才释放，之后的新错误才可重新置位。

## 8.6 FDMA progress-aware timeout

图 16  FDMA 等待、有效进展、计数清零与 timeout sticky

fdma_wait_count 不是事务总时长计数器。只要 fdma_progress=1，或 fdma_waiting=0，计数立即清零；只有连续等待且完全无进展才递增。达到 FDMA_TIMEOUT_CYCLES-1 时置 fdma_timeout_sticky；clear_inter 清 sticky 和计数。

## 8.7 LocalLink 规则

TX：src_rdy=1 且 dst_rdy=1 的拍才传输；背压期间 data/rem/SOF/EOF 必须稳定。

RX：真实 Aurora SerDes 已经接收的数据不能由 FPGA 数据面推回线路。验证 BFM 连续发送，dst_rdy 低触发错误。

512 B 满帧为 64 个 64-bit beat；最后一拍 rem=3'b111。

SOF/EOF 与有效数据同拍；帧内不得出现无故中断、重复 SOF 或缺失 EOF。

## 8.8 FDMA 规则

地址、长度在请求有效且 busy 接受前保持稳定。

512 B 对应 size=64 word；地址必须在各自 32 KiB 活动窗口内并按 512 B 对齐。

只有真实握手或 burst 完成算 progress；等待且无 progress 达到门槛才置 timeout sticky。

任何 AXI BRESP/RRESP 非 OKAY 均使验证立即失败。

# 9. 异常状态与恢复

| 状态 | 置位条件 | 清除 | 软件建议 |

| rx_overflow_sticky | FIFO overflow 或 RX src_rdy 且 dst_rdy=0。 | 读取 0x10 的 clear 流程。 | 丢弃当前帧，检查吞吐/时钟。 |

| rx_overrun_sticky | rx_pending 未释放时又完成新 burst。 | CPU_REC_STATE ack。 | 先处理旧 buffer，再重新武装。 |

| tx_underflow_sticky | TX bridge 数据供给不足。 | clear_inter 跨域 toggle。 | 检查 FDMA read 和 AXI backpressure。 |

| fdma_timeout_sticky | 请求等待且长期无任何 progress。 | clear_inter。 | 检查 busy/valid/ready 与 AXI response。 |

| length_error_sticky | 帧长/SOF/EOF/rem 或 TX 配置非法。 | clear_inter。 | 校验 512 B 对齐和帧界。 |

| link_down_sticky | 命令时链路未起或活动期间链路掉线。 | clear_inter。 | 重新训练链路后重发。 |


clear_inter 在 FDMA 域翻转 toggle，并同步至 Aurora 用户域。源域 sticky 清零再跨回需要若干周期，因此 user_status_clear_hold 会阻止旧的同步高电平把已清除状态重新置位。

# 10. Root Port 大仿真架构

图 17  Xilinx Root Port + 真实 RTDS Endpoint 验证环境

| 组件 | 来源 | 职责 |

| board | 自定义 TB | 兼容官方 board.RP.tx_usrapp 层级；时钟、复位、互连和总控。 |

| RP | XDMA example / 2020.2 | 真实 Xilinx PCIe Root Port、TPI/USRAPP、枚举/BAR。 |

| EP | 真实 RTDS_test-1ch | PCIe/design_1_wrapper/xdma_0 与生产 Adapter/INFO/CONV_DMA。 |

| LL_BFM | 自定义已验证 BFM | TX 捕获和 RX 注入；RX 不支持随机反压。 |

| CQ_HOST | 自定义 monitor | 接收 RP m_axis_cq Memory Write 并形成 Host-memory sink。 |

| XDMA_AXI_MON | 自定义 monitor | 用本地 AXI 活动替代高频 descriptor count 轮询。 |

| IRQ bind monitor | 自定义 bind | 不改生产端口，观测 usr_irq_req/ack、msi_enable。 |

| Assertions/scoreboard | 自定义 TB | 协议、数据、顺序、超时与最终判定。 |


| CQ Host sink 的必要性 官方 RP example 的 DATA_STORE 只是 Host 发起 H2C/descriptor read 时的数据源。Endpoint 的 C2H Memory Write 从 RP m_axis_cq 入站流到达，不会自动回写 DATA_STORE。CQ_HOST 按 TLP 地址、tkeep 和 payload 建立独立主机内存模型。 |


# 11. rtds_minimum 验证流程

| 序号 | 阶段 | 动作与判据 |

| 1 | 链路与枚举 | 等待 link up；检查 Gen3 x2、Vendor/Device；完成 BAR 搜索。 |

| 2 | MSI/IRQ 配置 | MSI capability=0x90，address=0xFEE00000，data=0x0045；使能 user IRQ bit0。 |

| 3 | INFO_EXCH | 检查 0x00/0x04/0x08；0x24/0x28 写回。 |

| 4 | 基础 H2C | Host 0x400 → card 0x8000，512 B；本地 AXI write 与 status 通过。 |

| 5 | 基础 C2H | card 0x8000 → Host 0x800，512 B；CQ sink 逐字节通过。 |

| 6 | CPU→Aurora | 写 INFO 命令；LL BFM 捕获 512 B；检查 resp 生命周期。 |

| 7 | Aurora→CPU | LL BFM 注入 512 B；检查 IRQ、INFO、MSI ack。 |

| 8 | 第二次 C2H | card 0x0000 → Host 0x800；逐字节通过；CPU_REC_STATE 重新武装。 |

| 9 | 统一判定 | 断言、scoreboard、AXI response、CQ protocol、warning/fatal 全为零。 |


# 12. 测试点—验证用例矩阵

| 功能 | 测试点 | 用例 | 检查机制 | 状态 |

| PCIe link | Gen3 x2 / LTSSM | rtds_minimum | user_lnk_up、speed、width | 通过 |

| 枚举/BAR | Device/Vendor、BAR0/1 | rtds_minimum | TPI readback | 通过 |

| MSI | cap/address/data/enable | rtds_minimum | msi_enable、ack | 通过 |

| INFO | 固定值与 RW | rtds_minimum | BAR read/write | 通过 |

| H2C | 512 B 数据与 response | rtds_minimum | AXI monitor+数据 | 通过 |

| C2H | 512 B posted write | rtds_minimum | CQ sink+scoreboard | 通过 |

| CPU→Aurora | 64 beat/帧界/resp | rtds_minimum | LL scoreboard+assertion | 通过 |

| Aurora→CPU | 连续 RX/FDMA write | rtds_minimum | FDMA+INFO+C2H | 通过 |

| IRQ clear | req/ack/read-clear | rtds_minimum | bind monitor+INFO | 通过 |

| 错误门禁 | X/Z、AXI error、timeout | 所有用例 | assertion/compare_logs | 通过 |

| 压力 | 1 KiB/32 KiB/连续帧 | 后续 regression | scoreboard+性能计数 | 计划 |

| 异常注入 | link drop/overflow/timeout | 后续专项 | sticky+恢复 | 计划 |


# 13. 断言、scoreboard 与超时

LocalLink 背压稳定性：TX 在 valid=1、ready=0 时 data/rem/SOF/EOF 不变。

Aurora RX 不反压：连续源期间 dst_rdy 低立即计为错误。

FDMA：地址/长度合法、请求/忙/数据握手完整、完成响应顺序一致。

AXI：BRESP/RRESP 必须 OKAY；无越界、无 X/Z、无未完成 burst。

CQ Host：解析 Memory Write、地址递增、payload 字节数和 tkeep 一致。

IRQ：RX 完成→INFO/IRQ→usr_irq_ack→read-clear→C2H 的顺序一致。

超时：链路训练 500 us；单次 DMA/IRQ 200 us；总 HDL 2 ms；墙钟 120 min。

# 14. 波形与日志验收

| 分组 | 关键对象 |

| 01_Reset_Link | 差分时钟、复位、user_lnk_up、LTSSM、速率/宽度 |

| 02_RP_TLP | RQ/RC/CQ/CC valid/ready/last/keep/data/tuser |

| 03_TPI / DMA | testname、BAR、read data、descriptor/status、本地 AXI 计数 |

| 03_CQ_Host | write bytes、packet、address、protocol errors、包上下文 |

| 04_Endpoint_AXI | AW/W/B/AR/R 五通道及 AXI-Lite |

| 04_RTDS_FDMA | read/write request、addr、size、busy、source_valid/accept、sticky |

| 05_Aurora_LL | TX/RX data、SOF/EOF、rem、src/dst ready、channel/lane up |

| 06_XDMA_IRQ | usr_irq_req/ack、msi_enable、INT/CLEAR/CPU_REC 状态 |

| 07_Result | 各 milestone 与 test_error_count |


日志只比较语义里程碑，不比较绝对时间戳、临时路径或许可证信息。成功必须同时出现 RTDS_ROOTPORT_RESULT ... errors=0、RTDS_ROOTPORT_PASS、RTDS_LOG_COMPARE_PASS，并且 unexpected_warnings=0、fatal_lines=0。

| 仿真时间窗 | 事件 |

| 0～228.49 us | 复位、链路训练、枚举与 BAR。 |

| 228.49～245.73 us | MSI、user IRQ、INFO_EXCH。 |

| 245.73～261.94 us | 基础 H2C/C2H。 |

| 261.94～263.30 us | CPU→Aurora。 |

| 263.30～273.99 us | Aurora→CPU、IRQ、read-clear、第二次 C2H。 |

| 274.094 us | 最终 PASS 与 $finish。 |


## 14.1 最终清洁 WaveMode 回归结果

| 项目 | 最终结果 |

| 开始/结束 | 2026-07-24 12:12:54 ～ 12:35:42（UTC+8），墙钟约 22 分 48 秒 |

| XSim 终点 | 274.094 us |

| detached | state=completed，exit_code=0，accepted=true |

| 功能/日志 | RTDS_ROOTPORT_PASS；RTDS_LOG_COMPARE_PASS |

| 错误门禁 | errors=0；unexpected_warnings=0；fatal_lines=0 |

| WDB | 24,521,538 B；SHA-256 2b4814207fafce67f89132bb08512bb4f6d7f3eacefe7eacfd8865c836df2440 |

| WCFG | 796 B；SHA-256 65f56e00e8d1babc5b6e71e3105df4a0f628cd115115b78187d9cacf87aeecee |

| 日志哈希 | simulate.log 83e32043…db403；summary.json b1272471…d6090 |

| 归档 | logs/final_wave_20260724_123542 |


最终日志识别到 7 条 warning（simulate 6 条、prepare 1 条），全部命中逐条确认的精确 Xilinx 模型白名单；packed CQ tuser 位切片导致的 Simtcl 6-197/6-55 已通过仅记录完整向量消除，未加入白名单。

# 15. 已知边界与后续回归

Root Port 大仿真使用 LocalLink BFM，不覆盖 Aurora 64B/66B 编码、GT、CDR、极性和真实链路误码。

CQ Host-memory sink 不是操作系统/IOMMU/CPU cache 模型；posted write 的真实平台排序仍需上板。

MSI 仿真覆盖硬件消息链，驱动 ISR 和 OS 中断路由需软件联调。

最小门槛为单次 512 B；1 KiB、32 KiB、连续传输和压力回归作为后续扩展。

Aurora→FPGA 方向不把随机 ready 撤销当作合法测试；该方向重点验证持续吞吐和溢出检测。

descriptor count 按每次事务独立确认 count=1/status=0x6，不作为跨事务单调计数器使用。

# 附录 A：关键文件与复现入口

| 类别 | 路径/文件 |

| 生产顶层 | RTDS_test-1ch/RTDS_test.srcs/sources_1/new/TOP.v |

| PCIe 集成 | RTDS_test-1ch/RTDS_test.srcs/sources_1/new/PCIe.v |

| Adapter | RTDS_test-1ch/RTDS_test.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v |

| 寄存器 | RTDS_test-1ch/RTDS_test.srcs/sources_1/new/INFO_EXCH.v |

| 验证环境 | RTDS_test-1ch/regression/sim_xdma_rootport |

| 运行 | run_xsim_detached.ps1 -RebuildSnapshot -WaveMode -WallClockTimeoutMinutes 120 |

| 查看波形 | open_final_wdb.ps1（只读打开 final_wave_* 的 WDB/WCFG） |

| 问题台账 | docs/RTDS_test_XDMA_RootPort问题发现与处理台账.md |


# 附录 B：验证环境地址约定

| 用途 | 地址 | 长度 |

| H2C descriptor | Host 0x100 | descriptor |

| C2H descriptor | Host 0x300 | descriptor |

| Host 源数据 | Host 0x400 | 512 B |

| Host 目标数据 | Host 0x800 | 512 B |

| CPU→Aurora 卡端窗口 | Card 0x8000 | 512 B |

| Aurora→CPU 卡端窗口 | Card 0x0000 | 512 B |


# 附录 C：PCIe.v 完整信号词典

本附录覆盖远程机现行 PCIe.v 中的端口、localparam 与内部 wire。纯物理差分对和同组直连信号允许合并说明，但每个源码标识符均显式列出。

## C.1 端口

| 信号 | 方向/宽度 | 产生/连接 | 设计语义 |

| pcie_mgt_rxn / pcie_mgt_rxp | 输入，各[1:0] | PCIe RX 两条差分 lane；直接进入 design_1_wrapper。 | 物理差分输入，不参与用户逻辑组合。 |

| pcie_mgt_txn / pcie_mgt_txp | 输出，各[1:0] | design_1_wrapper 的 PCIe TX 两条差分 lane。 | 直接送 TOP 板级管脚。 |

| pcie_diff_clk_n / pcie_diff_clk_p | 输入，各[0:0] | PCIe 100 MHz 差分参考时钟。 | 只连接 XDMA Endpoint。 |

| pcie_rst_n | 输入，1 bit | 板级 PCIe PERST#，低有效。 | 直接连接 design_1_wrapper.pcie_rst_n。 |

| user_lnk_up | 输出，1 bit | assign user_lnk_up=user_lnk_up_int。 | 保持原顶层可见链路状态；业务门控在 Adapter 内完成。 |

| FPGA_TEMP_W | 输入，[31:0] | 板级温度/遥测值。 | 透传到 INFO_EXCH 路径，不改变寄存器语义。 |

| i_sys_clk | 输入，1 bit | FDMA/CONV_DMA/INFO/ILA 主时钟。 | 连接 fdma_clk、sys_clk 和 ILA clk。 |

| i_sys_rst | 输入，1 bit，高有效 | PCIe 集成逻辑系统复位。 | 取反生成 fdma_rstn/sys_rst_n。 |

| aurora_user_clk | 输入，1 bit | Aurora LocalLink 用户时钟。 | Adapter 用户域时钟。 |

| aurora_user_rstn | 输入，1 bit，低有效 | Aurora 用户域复位。 | Adapter 用户域及局部 TX/RX reset 的基础条件。 |

| aurora_channel_up / aurora_lane_up | 输入，各1 bit | Aurora channel/lane 训练完成状态。 | Adapter 同步到 fdma 域并与 PCIe link 相与。 |

| aurora_tx_d | 输出，[63:0] | Adapter TX bridge 的 LocalLink payload。 | 仅 src_rdy&&dst_rdy 时消费。 |

| aurora_tx_sof / aurora_tx_eof | 输出，各1 bit | TX 首拍/末拍标志。 | 与对应 data/rem 一起在 stall 时保持。 |

| aurora_tx_rem | 输出，[2:0] | TX 末拍有效字节编码。 | 固定满 512 B 帧末拍为 3'b111。 |

| aurora_tx_src_rdy | 输出，1 bit | TX 数据/帧界有效。 | 与 aurora_tx_dst_rdy 共同形成 TX 握手。 |

| aurora_tx_dst_rdy | 输入，1 bit | Aurora TX 接收能力。 | 为0时 Adapter 保持当前 TX beat。 |

| aurora_rx_d | 输入，[63:0] | Aurora→Adapter payload。 | 在 RX 真握手时写入异步 FIFO。 |

| aurora_rx_sof / aurora_rx_eof | 输入，各1 bit | RX 首拍/末拍标志。 | 进入 Adapter 64-beat 帧检查器。 |

| aurora_rx_rem | 输入，[2:0] | RX 末拍有效字节编码。 | 完整帧 EOF 拍必须为 3'b111。 |

| aurora_rx_src_rdy | 输入，1 bit | RX 数据有效。 | 与 aurora_rx_dst_rdy 共同形成 rx_hs。 |

| aurora_rx_dst_rdy | 输出，1 bit | RX FIFO 当拍接收能力。 | 下降视为吞吐/容量异常，不能作为线路长期反压。 |


## C.2 固定参数与内部网络

| 信号 | 宽度/域 | 产生者 | 实现含义 |

| FRAME_BYTES | integer=512 | PCIe.v 固定参数 | 传给 Adapter；帧字节数。 |

| ACTIVE_WINDOW_BYTES | integer=32768 | PCIe.v 固定参数 | 传给 Adapter；每方向活动窗口。 |

| RX_BASE_ADDR_LO | [31:0]=0 | PCIe.v 固定参数 | Aurora→CPU 写窗口基址。 |

| TX_BASE_ADDR_LO | [31:0]=0x8000 | PCIe.v 固定参数 | CPU→Aurora 读窗口基址。 |

| CARD_ADDR_HI | [31:0]=0 | PCIe.v 固定参数 | 64-bit card address 高位。 |

| fdma_raddr | [63:0] / fdma | Adapter 输出 | FDMA read 地址，送 CONV_DMA；ILA 只取低32位。 |

| fdma_rareq | 1 / fdma | Adapter 输出 | FDMA read 请求；rbusy 接受前保持。 |

| fdma_rbusy | 1 / fdma | CONV_DMA 输出 | read 请求接受/通道忙状态，返回 Adapter。 |

| fdma_rdata | [63:0] / fdma | CONV_DMA 输出 | 共享内存 read payload，送 TX bridge。 |

| fdma_rsize | [15:0] / fdma | Adapter 输出 | read burst beat 数，512 B 时固定64。 |

| fdma_rvalid | 1 / fdma | CONV_DMA 输出 | read data valid。 |

| fdma_rready | 1 / fdma | Adapter 输出 | TX bridge/FIFO 接收能力；与 rvalid 真握手。 |

| fdma_waddr | [63:0] / fdma | Adapter 输出 | FDMA write 地址，送 CONV_DMA。 |

| fdma_wareq | 1 / fdma | Adapter 输出 | FDMA write 请求；wbusy 接受前保持。 |

| fdma_wbusy | 1 / fdma | CONV_DMA 输出 | write 请求接受/通道忙状态。 |

| fdma_wdata | [63:0] / fdma | Adapter 输出 | RX FIFO 读出的 write payload。 |

| fdma_wsize | [15:0] / fdma | Adapter 输出 | write burst beat 数，固定64。 |

| fdma_w_source_valid | 1 / fdma | Adapter.fdma_wvalid | 真实写数据 source-valid；连接 BD.fdma_wready_0。 |

| fdma_w_accept | 1 / fdma | BD.fdma_wvalid_0 | 真实写数据 accept；连接 Adapter.fdma_wready。 |

| FPGA_CPU_START_ADDR | [31:0] / fdma | Adapter 输出 | 完整 RX burst 的 card memory 起始地址，送 INFO_EXCH。 |

| FPGA_CPU_LEN | [31:0] / fdma | Adapter 输出 | RX 可读取长度，当前固定512字节。 |

| CPU_FPGA_START_ADDR | [31:0] / fdma | INFO_EXCH 输出 | 软件下发 TX card memory 起始地址。 |

| CPU_FPGA_LEN | [31:0] / fdma | INFO_EXCH 输出 | 软件下发 TX 字节长度。 |

| CLEAR_INTER_R | 1 / fdma | INFO_EXCH 输出 | 软件读清/清中断脉冲，送 Adapter.clear_inter。 |

| CPU_REC_STATE_R | 1 / fdma | INFO_EXCH 输出 | 软件 RX ownership 确认电平。 |

| CPU_REC_STATE_W | 1 / fdma | Adapter 输出 | cpu_rec_state_r 的硬件镜像/回读状态。 |

| INT_STATE_W | 1 / fdma | Adapter 输出 | RX 通知 sticky 状态，送 INFO_EXCH。 |

| INT_STATE_R | 1 / fdma | INFO_EXCH 输出 | INT_STATE read-clear 事件，送 Adapter.int_state_clear。 |

| RD_START | 1 / fdma | INFO_EXCH 输出 | CPU_WR_DONE 上升沿形成的 TX 启动脉冲。 |

| CPU_WR_DONE_resp | 1 / fdma | Adapter 输出 | 硬件持有 TX 命令的生命周期指示。 |

| FPGA_CPU_irq_req | 1 / fdma | Adapter 输出 | RX 完成用户 IRQ 请求，送 XDMA。 |

| user_lnk_up_int | 1 / XDMA | design_1_wrapper 输出 | XDMA 链路状态；透传 user_lnk_up 并输入 Adapter。 |

| rx_fifo_almost_full | 1 / fdma观测 | Adapter 输出 | RX FIFO almost-full 同步状态。 |

| rx_fifo_full | 1 / fdma观测 | Adapter 输出 | RX FIFO full 同步状态。 |

| rx_overflow_sticky | 1 / fdma | Adapter 输出 | RX 容量/ready 异常锁存。 |

| rx_overrun_sticky | 1 / fdma | Adapter 输出 | CPU 未归还 buffer 时新 burst 完成。 |

| tx_underflow_sticky | 1 / fdma | Adapter 输出 | TX 供数不足锁存。 |

| fdma_timeout_sticky | 1 / fdma | Adapter 输出 | FDMA 等待无进展超时锁存。 |

| length_error_sticky | 1 / fdma | Adapter 输出 | TX 配置或 RX 帧规格错误锁存。 |

| link_down_sticky | 1 / fdma | Adapter 输出 | 命令时/活动期/曾up后掉链锁存。 |

| rx_pending | 1 / fdma | Adapter 输出 | RX buffer 所有权已交给 CPU。 |

| adapter_tx_state_dbg | [3:0] / fdma | Adapter 输出 | TX bridge 状态码，ILA probe13。 |

| adapter_rx_state_dbg | [3:0] / fdma | Adapter 输出 | RX bridge 状态码，ILA probe12。 |


# 附录 D：Adapter 完整信号词典

本附录按端口与内部逻辑组解释远程机现行 pcie_fdma_aurora_brg_adapter.v 的全部非局部临时信号。调试总线按整体及被使用位说明；仅为边沿恢复而存在的一级延迟寄存器仍列入，避免代码实现时遗漏 CDC 配对关系。

## D.1 参数与端口

| 信号 | 方向/宽度 | 来源/当前值 | 实现含义 |

| FRAME_BYTES | parameter integer | 512 | 帧字节数；当前必须为512。 |

| ACTIVE_WINDOW_BYTES | parameter integer | 32768 | 每方向低地址窗口；必须是帧长整数倍。 |

| RX_BASE_ADDR_LO | parameter [31:0] | 0x00000000 | RX FDMA write 基址。 |

| TX_BASE_ADDR_LO | parameter [31:0] | 0x00008000 | TX FDMA read 最低合法基址。 |

| CARD_ADDR_HI | parameter [31:0] | 0 | FDMA 64-bit 地址高32位。 |

| FDMA_TIMEOUT_CYCLES | parameter integer | 65535 | 无进展等待超时门槛。 |

| fdma_clk / fdma_rstn | 输入 / 低有效复位 | FDMA、INFO、IRQ主域 | 所有控制寄存器和最终 sticky 所在域。 |

| aurora_user_clk / aurora_user_rstn | 输入 / 低有效复位 | Aurora LocalLink 用户域 | LL TX/RX、帧检查和源域 sticky 所在域。 |

| pcie_link_up | 输入 1 | XDMA link / fdma域 | 同步到 user 域；两个域业务放行条件之一。 |

| aurora_channel_up | 输入 1 | Aurora / user域 | 本域直接使用并同步到 fdma 域。 |

| aurora_lane_up | 输入 1 | Aurora / user域 | 本域直接使用并同步到 fdma 域。 |

| aurora_tx_d | 输出 [63:0] | TX bridge | FPGA→Aurora payload。 |

| aurora_tx_sof / aurora_tx_eof | 输出各1 | TX bridge | 首/末拍标志，stall 时保持。 |

| aurora_tx_rem | 输出 [2:0] | TX bridge | 末拍有效字节编码。 |

| aurora_tx_src_rdy / aurora_tx_dst_rdy | 输出/输入 | TX bridge ↔ Aurora | 二者同时为1才消费一个 TX beat。 |

| aurora_rx_d | 输入 [63:0] | Aurora | Aurora→FPGA payload。 |

| aurora_rx_sof / aurora_rx_eof | 输入各1 | Aurora | RX 帧界，送 bridge 与帧检查器。 |

| aurora_rx_rem | 输入 [2:0] | Aurora | EOF 拍有效字节编码。 |

| aurora_rx_src_rdy / aurora_rx_dst_rdy | 输入/输出 | Aurora ↔ RX bridge | 二者同时为1形成 rx_hs；valid&&!ready 置 overflow。 |

| rd_start | 输入 1 / fdma | INFO_EXCH | TX 命令请求脉冲。 |

| cpu_fpga_start_addr | 输入 [31:0] / fdma | INFO_EXCH | TX card memory 起始低地址。 |

| cpu_fpga_len | 输入 [31:0] / fdma | INFO_EXCH | TX 字节长度。 |

| cpu_wr_done_resp | 输出 reg 1 / fdma | TX 事务寄存器 | tx_active 生命周期指示。 |

| fpga_cpu_start_addr | 输出 reg [31:0] / fdma | RX 通知逻辑 | 新完整 RX burst 的 card address。 |

| fpga_cpu_len | 输出 reg [31:0] / fdma | RX 通知逻辑 | 新完整 RX burst 字节数，固定512。 |

| int_state_w | 输出 1 / fdma | int_state_w_r | 软件可读 RX 中断状态。 |

| int_state_clear | 输入 1 / fdma | INFO_EXCH | 只清 IRQ/INT，不清 pending。 |

| clear_inter | 输入 1 / fdma | INFO_EXCH | 清 IRQ/INT/最终 sticky，并触发 user 域 clear。 |

| cpu_rec_state_r | 输入 1 / fdma | INFO_EXCH | 上升沿归还 RX buffer ownership。 |

| cpu_rec_state_w | 输出 reg 1 / fdma | RX 所有权逻辑 | cpu_rec_state_r 镜像。 |

| fpga_cpu_irq_req | 输出 reg 1 / fdma | RX 通知逻辑 | XDMA user IRQ 请求，保持至 clear。 |

| fdma_raddr / fdma_rareq / fdma_rsize | 输出 64/1/16 | TX bridge+地址适配 | FDMA read 请求描述；size=64 beat。 |

| fdma_rbusy | 输入 1 | CONV_DMA | read 请求接受/忙。 |

| fdma_rdata / fdma_rvalid / fdma_rready | 输入64/输入1/输出1 | CONV_DMA ↔ TX bridge | rvalid&&rready 时一个 read beat 进入 FIFO。 |

| fdma_waddr / fdma_wareq / fdma_wsize | 输出 64/1/16 | RX bridge+地址适配 | FDMA write 请求描述；size=64 beat。 |

| fdma_wbusy | 输入 1 | CONV_DMA | write 请求接受/忙。 |

| fdma_wdata / fdma_wvalid / fdma_wready | 输出64/输出1/输入1 | RX bridge ↔ CONV_DMA | 标准语义下 valid&&ready 提交一个 write beat。 |

| rx_fifo_almost_full / rx_fifo_full | 输出各1 / fdma观测 | user域水位同步 | 瞬时 FIFO 水位；不属于 sticky。 |

| rx_overflow_sticky | 输出1 / fdma | 最终 sticky | RX FIFO/ready 容量异常。 |

| rx_overrun_sticky | 输出1 / fdma | 所有权逻辑 | pending 期间新 burst 完成。 |

| tx_underflow_sticky | 输出1 / fdma | 最终 sticky | TX bridge 供数不足。 |

| fdma_timeout_sticky | 输出1 / fdma | 最终 sticky | FDMA 等待无进展。 |

| length_error_sticky | 输出1 / fdma | 最终 sticky | TX 配置或 RX 帧规格错误。 |

| link_down_sticky | 输出1 / fdma | 最终 sticky | 业务链路异常。 |

| rx_pending | 输出1 / fdma | rx_pending_r | CPU 持有 RX buffer。 |

| dbg_tx_state / dbg_rx_state | 输出各[3:0] | debug bus 位切片 | ILA 状态观测，不参与控制。 |


## D.2 内部派生、状态与 CDC 信号

| 信号 | 宽度/域 | 产生逻辑 | 消费/约束 |

| FRAME_WORDS | integer=64 | FRAME_BYTES/8 | 内部 64-bit word 数。 |

| FRAME_BYTES_32 | [31:0]=512 | FRAME_BYTES 宽度适配 | 写入 fpga_cpu_len。 |

| FRAME_WORDS_16 | [15:0]=64 | FRAME_WORDS 宽度适配 | 驱动 fdma_rsize/fdma_wsize。 |

| pcie_link_up_user | 1 / user | pcie_link_up 经 xpm_cdc_single | 参与 link_up_user。 |

| aurora_channel_up_fdma | 1 / fdma | aurora_channel_up 经 xpm_cdc_single | 参与 link_up_fdma。 |

| aurora_lane_up_fdma | 1 / fdma | aurora_lane_up 经 xpm_cdc_single | 参与 link_up_fdma。 |

| link_up_user | 1 / user | pcie_link_up_user&&channel_up&&lane_up | 用户域业务总放行。 |

| link_up_fdma | 1 / fdma | pcie_link_up&&channel_up_fdma&&lane_up_fdma | FDMA域业务总放行。 |

| tx_active | reg 1 / fdma | 合法命令置位；完成/掉链清零 | 当前 TX 命令硬件所有权。 |

| tx_target_frames | reg [15:0] / fdma | requested_frames_32[15:0] | 当前命令目标帧数。 |

| tx_completed_frames | reg [15:0] / fdma | 每个 tx_frame_done_fdma 累加 | 已完成 LL 帧数。 |

| tx_base_addr_lo | reg [31:0] / fdma | tx_start_valid 时锁存软件地址 | TX raw address 的外部基址。 |

| tx_requested_end | wire [32:0] / fdma | {0,start}+{0,len} | 33-bit 命令半开区间结束地址，检测回绕。 |

| tx_window_end | wire [32:0] / fdma | {0,TX_BASE}+window | TX 合法窗口半开区间上界。 |

| tx_addr_aligned | wire 1 / fdma | start & (FRAME_BYTES-1)==0 | 起始地址 512B 对齐条件。 |

| tx_len_aligned | wire 1 / fdma | len & (FRAME_BYTES-1)==0 | 长度 512B 对齐条件。 |

| tx_config_valid | wire 1 / fdma | 非零/对齐/长度/窗口/回绕合取 | 软件 TX 配置总合法条件。 |

| tx_start_valid | wire 1 / fdma | rd_start&&!tx_active&&link_up_fdma&&config | 唯一接管命令事件。 |

| tx_config_error_event | wire 1 / fdma | rd_start&&(!config\|\|tx_active) | 置 length_error_sticky。 |

| tx_start_link_error | wire 1 / fdma | rd_start&&!link_up_fdma | 置 link_down_sticky。 |

| requested_frames_32 | wire [31:0] / fdma | cpu_fpga_len/FRAME_BYTES | 锁存目标帧数的完整计算结果。 |

| tx_active_user | wire 1 / user | tx_active 经 xpm_cdc_single | 用户域 TX 子桥使能。 |

| tx_fdma_rstn | wire 1 / fdma | fdma_rstn&&link_up_fdma&&tx_active | TX bridge FDMA 侧局部复位。 |

| tx_user_rstn | wire 1 / user | aurora_user_rstn&&link_up_user&&tx_active_user | TX bridge user 侧局部复位。 |

| tx_fdma_raddr_raw | wire [31:0] / fdma | TX bridge 输出 | 窗口内相对 read 地址。 |

| tx_fdma_dbg_bus | wire [37:0] / fdma | TX bridge debug | [37:36] 映射 dbg_tx_state。 |

| tx_user_dbg_bus | wire [38:0] / user | TX bridge debug | [0] 提供 tx_underflow_user。 |

| tx_frame_done_user | wire 1 / user | TX bridge EOF 真握手 | 驱动完成 toggle。 |

| tx_done_toggle_user | reg 1 / user | 每帧完成翻转 | 窄脉冲跨域源编码。 |

| tx_done_toggle_fdma | wire 1 / fdma | toggle 经 xpm_cdc_single | 目的域同步 toggle。 |

| tx_done_toggle_fdma_d | reg 1 / fdma | 同步 toggle 延迟一拍 | 与当前值异或恢复边沿。 |

| tx_frame_done_fdma | wire 1 / fdma | toggle_fdma ^ toggle_fdma_d | 单周期 TX 帧完成事件。 |

| rx_fdma_rstn | wire 1 / fdma | fdma_rstn&&link_up_fdma | RX bridge FDMA 侧局部复位。 |

| rx_user_rstn | wire 1 / user | aurora_user_rstn&&link_up_user | RX bridge user 侧局部复位。 |

| rx_fdma_waddr_raw | wire [31:0] / fdma | RX bridge 输出 | 窗口内相对 write 地址；用于通知地址。 |

| rx_fdma_wsize_raw | wire [15:0] / fdma | RX bridge 历史输出 | byte 语义，仅保留连接；外部 size 被覆盖为64 beat。 |

| rx_fdma_dbg_bus | wire [105:0] / fdma | RX bridge debug | [41:40] 映射 dbg_rx_state。 |

| rx_user_dbg_bus | wire [28:0] / user | RX bridge debug | 用户域诊断总线，仅观测。 |

| rx_fifo_almost_full_user | wire 1 / user | RX FIFO | 同步到 fdma 输出水位。 |

| rx_fifo_full_user | wire 1 / user | RX FIFO | 同步到 fdma 输出水位。 |

| rx_fifo_overflow_user | wire 1 / user | RX FIFO | 置 rx_overflow_user_sticky。 |

| rx_burst_done_fdma | wire 1 / fdma | RX bridge | 完整 FDMA write burst 完成；通知唯一完成条件。 |

| int_state_w_r | reg 1 / fdma | RX burst 完成置位；INT clear清零 | 驱动 int_state_w。 |

| rx_pending_r | reg 1 / fdma | 通知发布置位；cpu_rec_ack清零 | RX buffer ownership。 |

| rx_overrun_sticky_r | reg 1 / fdma | pending期间新burst置位 | 驱动 rx_overrun_sticky；ack清除。 |

| cpu_rec_state_d | reg 1 / fdma | cpu_rec_state_r 延迟一拍 | 上升沿检测历史值。 |

| cpu_rec_ack | wire 1 / fdma | cpu_rec_state_r&&!cpu_rec_state_d | 释放 RX ownership 的单周期事件。 |

| status_clear_toggle_fdma | reg 1 / fdma | clear_inter 时翻转 | clear 跨到 user 域的源编码。 |

| status_clear_toggle_user | wire 1 / user | clear toggle 经同步 | user 域同步 toggle。 |

| status_clear_toggle_user_d | reg 1 / user | 同步 toggle 延迟一拍 | 边沿恢复历史值。 |

| status_clear_user | wire 1 / user | toggle_user ^ toggle_user_d | 清 user 源域 sticky 的单周期脉冲。 |

| rx_in_frame | reg 1 / user | SOF建立、EOF/掉链清除 | RX 帧上下文状态。 |

| rx_frame_word_count | reg [8:0] / user | 每个 rx_hs 计数 | 验证固定64-beat帧长。 |

| rx_length_error_user_sticky | reg 1 / user | 帧界/长度/rem检查 | 源域长度错误锁存。 |

| rx_overflow_user_sticky | reg 1 / user | FIFO overflow或valid&&!ready | 源域溢出锁存。 |

| tx_underflow_user_sticky | reg 1 / user | tx_underflow_user | 源域TX下溢锁存。 |

| rx_hs | wire 1 / user | aurora_rx_src_rdy&&aurora_rx_dst_rdy | 帧计数唯一推进条件。 |

| tx_underflow_user | wire 1 / user | tx_user_dbg_bus[0] | TX bridge 下溢事件。 |

| rx_length_error_fdma | wire 1 / fdma | user sticky 经同步 | 最终 length_error 的源之一。 |

| rx_overflow_fdma | wire 1 / fdma | user sticky 经同步 | 最终 rx_overflow 的源。 |

| tx_underflow_fdma | wire 1 / fdma | user sticky 经同步 | 最终 tx_underflow 的源。 |

| rx_overflow_sticky_r | reg 1 / fdma | 同步错误且非hold时置位 | 驱动最终 rx_overflow_sticky。 |

| tx_underflow_sticky_r | reg 1 / fdma | 同步错误且非hold时置位 | 驱动最终 tx_underflow_sticky。 |

| fdma_timeout_sticky_r | reg 1 / fdma | wait_count达门槛置位 | 驱动最终 fdma_timeout_sticky。 |

| length_error_sticky_r | reg 1 / fdma | RX错误或TX配置错误置位 | 驱动最终 length_error_sticky。 |

| link_down_sticky_r | reg 1 / fdma | 链路错误置位 | 驱动最终 link_down_sticky。 |

| seen_link_up | reg 1 / fdma | 首次 link_up_fdma 后保持 | 抑制上电训练未完成的假掉链。 |

| fdma_wait_count | reg [31:0] / fdma | waiting无progress时累加 | 超时计数；progress/idle/clear清零。 |

| user_status_clear_hold | reg 1 / fdma | clear置位；三同步错误源全0清除 | 抑制跨域旧高电平反弹。 |

| fdma_waiting | wire 1 / fdma | req或等rvalid/wready | 标识协议正等待。 |

| fdma_progress | wire 1 / fdma | request accept/data handshake/RX done | 任何真实推进事件。 |


# 附录 E：设计规则到 RTL 实现的约束映射

| 设计主题 | RTL对象 | 规范实现 | 禁止行为 |

| 链路放行 | link_up_user / link_up_fdma | 三个链路状态在各自目标域同步后相与 | 禁止异步原始状态直接进入状态机。 |

| TX 命令接管 | tx_start_valid | rd_start&&!active&&link&&config | 只有该事件可锁存软件地址/长度。 |

| 地址越界检测 | tx_requested_end[32:0] | 33-bit 半开区间加法 | 禁止32-bit回绕后被误判为窗口内。 |

| TX 数据推进 | fdma_rvalid&&fdma_rready；src_rdy&&dst_rdy | 分别推进 FIFO 写侧与 LL 读侧 | stall 时不得改变当前 beat。 |

| TX 完成 | tx_frame_done_user→toggle→tx_frame_done_fdma | EOF 真握手后跨域 | 不得用 FDMA read 完成替代链路发送完成。 |

| RX 数据推进 | rx_hs；fdma_wvalid&&fdma_wready | 分别推进 LL 接收与 FDMA 写 | valid&&!ready 必须记录 overflow。 |

| RX 通知 | rx_burst_done_fdma | 完整 write burst 后发布 addr/len/IRQ | 不得在 Aurora EOF 时提前通知。 |

| RX 所有权 | rx_pending_r / cpu_rec_ack | 通知置位，CPU_REC_STATE上升沿清除 | INT clear 不得清 pending。 |

| 端口命名兼容 | fdma_w_source_valid / fdma_w_accept | Adapter.valid→BD.ready；BD.valid→Adapter.ready | 以真实语义判定握手。 |

| 跨域清除 | status_clear_toggle + user_status_clear_hold | toggle清源域，hold等同步源回0 | 防止清除后的旧高电平反弹。 |

| FDMA超时 | fdma_waiting / fdma_progress / wait_count | 仅连续等待且无进展时累加 | 正常持续传输不得因总时长触发。 |

| 调试状态 | dbg_tx_state / dbg_rx_state / ILA | 只读观测 | 禁止调试信号反馈功能控制。 |


| 源码覆盖口径 远程机现行 PCIe.v 与 pcie_fdma_aurora_brg_adapter.v 的端口、参数、localparam、reg、wire 和被使用的 debug bus 位均已在附录 C/D 中解释。允许省略的仅为明显的物理差分正/负端或同组直连信号的重复文字，不省略任何控制、状态、握手、地址、长度、CDC、所有权或异常语义。 |
