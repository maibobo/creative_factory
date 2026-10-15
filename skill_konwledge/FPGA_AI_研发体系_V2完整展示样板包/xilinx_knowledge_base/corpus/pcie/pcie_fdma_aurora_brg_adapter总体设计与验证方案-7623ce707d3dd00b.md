# pcie_fdma_aurora_brg_adapter总体设计与验证方案

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\pcie_fdma_aurora_brg_adapter总体设计与验证方案.docx`
- SHA-256: `7623ce707d3dd00be20671e58c241d304eaf06e9c3e40621f918f7ef31958f30`
- Extractor: `python-docx+zip-structure-check`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

| 产品名称Product name | 密级Confidentiality level |

| RTDS_test / PCIe-FDMA-Aurora |  |

| 产品版本Product version | Total 16 pages 共 16 页 |

| V1.0 | Total 16 pages 共 16 页 |


pcie_fdma_aurora_brg_adapter 总体设计与验证方案

| Prepared by 拟制 |  | Date 日期 | 2026-07-09 |

| Reviewed by 评审人 |  | Date 日期 |  |

| Approved by 批准 |  | Date 日期 |  |


Revision Record 修订记录

| Revision Version 修订版本 | Change Description 修改描述 | Author 作者 | Date 日期 |

| 1.0 | 完成 RTDS_test PCIe-FDMA-Aurora Bridge 设计方案文档，明确 adapter 插入位置、PCIe.v 连接方式、BD 维持策略和验证路径。 |  | 2026-07-09 |

| 1.1 | 按完整 FDMA2AURORA 异步桥已包含 Aurora 与 FIFO CDC 的口径重设计，删除最终主路径中的 DATA_CDC，并重绘全部结构图和时序图。 |  | 2026-07-09 |


目录

Revision Record 修订记录......................................................2

目录..........................................................................3

1 工程背景与当前边界..........................................................5

1.1 设计依据与资料来源....................................................5

1.2 当前 RTL 边界.........................................................5

2 原结构与最终结构对比........................................................5

2.1 adapter 插入前结构....................................................5

2.2 adapter 插入后结构....................................................6

2.3 adapter 与完整异步桥的边界............................................7

3 pcie_fdma_aurora_brg_adapter 设计...........................................7

3.1 内部职责..............................................................7

3.2 关键接口与状态........................................................8

3.3 CPU 到 Aurora 数据流..................................................8

3.4 Aurora 到 CPU 数据流..................................................9

4 PCIe.v 设计方案.............................................................9

4.1 保留边界..............................................................9

4.2 与 design_1_wrapper 的连接............................................10

4.3 link_enable 当前方案与最终建议........................................10

5 主模块关键接口时序..........................................................10

5.1 INFO_EXCH 到 adapter 的 TX 启动.......................................11

5.2 FDMA read 与 rvalid stall.............................................11

5.3 完整桥 TX 帧边界......................................................12

5.4 完整桥 RX 到 FDMA write 与中断........................................12

5.5 RX 中断清除...........................................................13

5.6 完整异步桥内部 FIFO CDC...............................................13

5.7 link_enable 与 channel_up.............................................13

6 剩余不变模块设计说明........................................................14

7 BD 与扩展状态寄存器策略.....................................................15

8 验证方案与风险清单..........................................................15

# 工程背景与当前边界

## 设计依据与资料来源

本文面向 RTDS_test 工程中 PCIe、FDMA、Aurora Bridge 的真实集成方案说明，重点阅读目录为 E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new。设计判断以 2026-07-08_08-56_工程评估.md 为主线，并交叉参考 rtds_top_fdma_aurora_brg_real_integration.md 与 fdma_aurora_brg_added_files_theory_design_registers.md。

当前工程已经存在 pcie_fdma_aurora_brg_adapter.v 和修改后的 PCIe.v；本文按“完整 FDMA2AURORA 异步桥已经包含 Aurora 与 FIFO 跨时钟域转换”的口径描述最终结构，同时说明当前遗留 debug 模块与最终产品主链路的取舍。

## 当前 RTL 边界

TOP.v 当前仍是 Vivado synthesis top，负责板级时钟、PCIe 管脚、PCIe 子系统、LED 和温度读取；PCIe.v 当前已例化 pcie_fdma_aurora_brg_adapter，并继续连接 design_1_wrapper 内的 XDMA、CONV_DMA、INFO_EXCH 和 BRAM 数据窗口。

DATA_CDC 当前只解释为遗留 debug/占位路径：Aurora_frame_gen 产生测试数据，PCIe->Aurora 方向输出也未形成真实 Aurora 闭环。由于完整 FDMA2AURORA 异步桥已经包含 Aurora 与 FIFO CDC，最终主路径应删除 DATA_CDC，避免重复跨域、重复协议边界和职责误导。

# 原结构与最终结构对比

## adapter 插入前结构

图1  adapter 插入前的当前 RTDS_test 数据路径

原结构的核心问题不是 PCIe 或 BD 完全不可用，而是 Aurora 侧仍处在 debug/占位状态。Aurora->PCIe 方向由 Aurora_frame_gen 产生测试帧；PCIe->Aurora 方向的 CDC 输出没有继续接到真实 Aurora 发送路径。该结构只能用于局部烟测和 ILA 观察，最终集成时应整体退出主路径。

## adapter 插入后结构

图2  pcie_fdma_aurora_brg_adapter 的最终插入位置

最终结构中，adapter 插在 PCIe.v 内部，位于 design_1_wrapper/CONV_DMA 的 FDMA 边界与完整 FDMA2AURORA 异步桥的控制/FDMA 边界之间。完整桥负责 FDMA-to-Aurora 数据桥、内部 FIFO CDC、Aurora IP/GT 和 channel_up/lane_up 状态，因此最终主路径不再经过 DATA_CDC。

## adapter 与完整异步桥的边界

需要特别区分：pcie_fdma_aurora_brg_adapter 在最终方案中不是重复实现 Aurora bridge TX/RX 的模块，而是保留 RTDS_test 原 PCIe 软件协议的适配层。它负责 INFO_EXCH 控制语义、地址/长度检查、start/done、IRQ/status 和 BD FDMA 端口适配。

完整 FDMA2AURORA 异步桥负责数据面重活：FDMA-to-Aurora 转换、跨时钟 FIFO、Aurora IP/GT、真实收发链路和 channel_up/lane_up。这样边界清楚，PCIe 工程不用再维护另一套 DATA_CDC 或 debug 66-bit stream 主链路。

# pcie_fdma_aurora_brg_adapter 设计

## 内部职责

图3  pcie_fdma_aurora_brg_adapter 内部职责分解

adapter 的设计目标是保留原 RTDS_test PCIe 软件协议，并把 INFO_EXCH/CONV_DMA 暴露出的控制与 FDMA 语义送入完整 FDMA2AURORA 异步桥。软件仍通过 XDMA/INFO_EXCH 写起始地址、长度和 CPU_WR_DONE；adapter 负责锁存、检查、启动、完成反馈、中断和状态汇总。

## 关键接口与状态

adapter 对外接口可以分成两组：第一组是 INFO_EXCH 控制、IRQ 和状态边界，第二组是与 design_1_wrapper/CONV_DMA 以及完整 FDMA2AURORA 异步桥之间的 FDMA/控制边界。当前代码里存在的 66-bit debug stream 边界只作为遗留实现现状，不作为最终主路径。

| 数据/控制接口 | 方向 | 功能说明 |

| bridge_rx_done/status | 输入 | 完整 FDMA2AURORA 异步桥返回的 RX 完成、FIFO 和错误状态。 |

| bridge_tx_start/control | 输出 | adapter 根据 INFO_EXCH start、地址和长度触发完整异步桥 TX 方向传输。 |

| rd_start / CPU_FPGA_* | 输入 | INFO_EXCH 发出的 TX 启动脉冲、起始地址和长度。长度必须 512B 对齐。 |

| CPU_WR_DONE_resp | 输出 | adapter 启动 TX 后反馈给 INFO_EXCH，TX 完成后清除。 |


| 状态/FDMA接口 | 方向 | 功能说明 |

| FPGA_CPU_START_ADDR / FPGA_CPU_LEN | 输出 | RX 写入完成后提供给 CPU 的可读 payload 地址和长度。 |

| INT_STATE_W / FPGA_CPU_irq_req | 输出 | RX 完成后置位中断状态，CPU 读 INT_STATE 后清除。 |

| fdma_r* / fdma_w* | 双向 | 连接 design_1_wrapper/CONV_DMA 的 FDMA 读写接口，size 固定为 64 beat。 |

| rx_overflow_sticky / length_error_sticky 等 | 输出 | 用于 ILA 或后续寄存器的错误锁存状态。 |


## CPU 到 Aurora 数据流

图4  CPU->Aurora 与 Aurora->CPU 双向数据流

CPU->Aurora 方向中，CPU 先通过 XDMA 写 payload buffer，再写 CPU_FPGA_START_ADDR、CPU_FPGA_LEN 和 CPU_WR_DONE。INFO_EXCH 将 CPU_WR_DONE 上升沿转换成 RD_START 单周期脉冲。adapter 锁存地址和长度，完成 512B 对齐检查后触发完整 FDMA2AURORA 异步桥，由完整桥完成 FDMA read、内部 FIFO 跨域和 Aurora TX。

## Aurora 到 CPU 数据流

Aurora->CPU 方向中，完整 FDMA2AURORA 异步桥接收 Aurora 链路数据，并在桥内部完成 Aurora RX、FIFO CDC 和 FDMA write，把一帧 512B 写入 payload window。写完后 adapter 根据桥侧 done/status 更新 FPGA_CPU_START_ADDR、FPGA_CPU_LEN，并置 INT_STATE_W 和 FPGA_CPU_irq_req。

RX 方向的关键风险是 Aurora 侧通常不适合被下游 full 直接反压。因此风险控制应放在完整桥内部 FIFO 深度、almost_full/full、overflow sticky、远端限速和软件及时读取策略上，而不是额外串接 DATA_CDC。

# PCIe.v 设计方案

## 保留边界

PCIe.v 应继续保持 PCIe MGT、PCIe refclk/reset、user_lnk_up、FPGA_TEMP_W、i_sys_clk/i_sys_rst 等板级边界。最终版本应删除或旁路当前 Aurora/debug 66-bit 输入输出，把 PCIe.v 内部 adapter 直接接到完整 FDMA2AURORA 异步桥的控制/FDMA 边界。

## 与 design_1_wrapper 的连接

| PCIe.v 连接项 | 当前连接对象 | 设计含义 |

| fdma_raddr/fdma_rareq/fdma_rsize/fdma_rdata/fdma_rvalid/fdma_rready | design_1_wrapper fdma_r*_0 | CPU->Aurora 时从 payload window 读取 512B frame。 |

| fdma_waddr/fdma_wareq/fdma_wsize/fdma_wdata/fdma_wvalid/fdma_wready | design_1_wrapper fdma_w*_0 | Aurora->CPU 时写入 payload window。 |

| RD_START / CPU_FPGA_START_ADDR / CPU_FPGA_LEN | INFO_EXCH 输出 | 软件 TX start、地址和长度配置。 |

| INT_STATE_W / FPGA_CPU_irq_req | INFO_EXCH / XDMA IRQ | RX 完成后通知 CPU。 |

| CLEAR_INTER_R / INT_STATE_R | INFO_EXCH 清除脉冲 | CPU 读 INT_STATE 后清中断。 |

| ila_FDMA probes | ILA IP | 观察 FDMA 地址、请求、数据、size 和 adapter 状态。 |


## link_enable 当前方案与最终建议

当前 PCIe.v 将 adapter.link_enable 暂接 user_lnk_up_int。这在工程未接完整 FDMA2AURORA 桥状态时可以用于语法和 PCIe 侧 smoke，但它只说明主机 PCIe 链路可用，不代表 Aurora 链路可发送。最终建议将 link_enable 改成 pcie_link_up && bridge_channel_up && bridge_lane_up，并按桥侧状态所属时钟域完成同步。

# 主模块关键接口时序

## INFO_EXCH 到 adapter 的 TX 启动

图5  INFO_EXCH 到 adapter 的 TX 启动时序

说明：

• INFO_EXCH 在 CPU_WR_DONE[0] 上升沿产生 r_RD_START 单周期脉冲。

• adapter 在 RD_START 有效时锁存 CPU_FPGA_START_ADDR 和 CPU_FPGA_LEN，并检查长度是否 512B 对齐。

• 当前代码在启动后置 CPU_WR_DONE_resp，TX 完成后清零。

## FDMA read 与 rvalid stall

图6  adapter FDMA read 与 rvalid stall 时序

说明：

• fdma_rsize=64 表示 64 个 64-bit beat，即 512B。

• 当 fdma_rvalid 暂停时，TX 侧计数和输出只在 rvalid && rready 成立时推进。

• fdma_raddr 由 adapter 将 32-bit 软件地址显式扩展为 64-bit 后输出。

## 完整桥 TX 帧边界

图7  完整 FDMA2AURORA 桥 TX 帧边界时序

说明：

• 单帧为 64 个有效 beat；首拍 SOF=1，末拍 EOF=1。

• 该帧边界属于完整 FDMA2AURORA 异步桥内部或桥侧边界，不再经过 DATA_CDC。

## 完整桥 RX 到 FDMA write 与中断

图8  完整 FDMA2AURORA 桥 RX 到 FDMA write 与中断置位时序

说明：

• RX 数据先进入 bridge RX FIFO，再由 FDMA write 写入 payload window。

• 写完一个 512B 可交付单位后，adapter 更新 FPGA_CPU_START_ADDR/FPGA_CPU_LEN，并置位中断状态。

## RX 中断清除

图9  RX 中断清除时序

说明：

• INFO_EXCH 读 0x0010 时产生 INT_STATE_R 和 CLEAR_INTER_R。

• adapter 看到 int_state_clear 或 clear_inter 后清 fpga_cpu_irq_req 和 int_state_w。

## 完整异步桥内部 FIFO CDC

图10  完整 FDMA2AURORA 异步桥内部 FIFO CDC 时序

说明：

• 该跨时钟关系位于完整 FDMA2AURORA 异步桥内部，不再由 RTDS_test 的 DATA_CDC 承担。

• 跨域后 valid/data 有 FIFO 延迟，adapter 和 PCIe.v 不应假设同周期穿透。

## link_enable 与 channel_up

图11  link_enable 与完整桥 channel_up/lane_up 建议时序

说明：

• 当前 adapter 的 link_enable 暂接 user_lnk_up_int，只代表 PCIe 链路可用。

• 最终建议使用 pcie_link_up && bridge_channel_up && bridge_lane_up。

# 剩余不变模块设计说明

| 模块 | 保持/改动策略 | 说明 |

| TOP.v | 保持顶层并删主路径占位 | 继续实例化 CLK_GEN、PCIe、LED、TEMP_RD；最终主路径不再实例化 DATA_CDC。 |

| DATA_CDC.v | 最终删除/仅留旧调试说明 | 当前使用 Aurora_frame_gen 和两个方向 CDC；完整 FDMA2AURORA 桥已含 Aurora+FIFO CDC，因此产品主路径删除。 |

| Aurora_PCIe_cdc.v | 最终删除 | 其跨域功能由完整 FDMA2AURORA 异步桥内部 FIFO CDC 承担。 |

| PCIe_Aurora_cdc.v | 最终删除 | 其跨域功能由完整 FDMA2AURORA 异步桥内部 FIFO CDC 承担。 |

| CONV_DMA.v | 保持 | 继续承担 FDMA 到 AXI4 burst 转换，adapter/完整桥需保证 size=64 beat。 |

| INFO_EXCH.v | 第一版保持 | 保留 0x0000-0x0028 原寄存器语义；扩展状态后续再做。 |

| CLK_GEN.v | 保持 | 继续输出 250 MHz、100 MHz 和 sys_rst。 |

| LED.v / TEMP_RD.v | 保持 | 板级心跳和温度读数，不进入本次数据路径改造。 |

| Aurora_frame_gen.v | 最终不进主路径 | 可作为单独 testbench 或 bring-up pattern 源，不作为 TOP 默认数据源。 |


# BD 与扩展状态寄存器策略

第一版建议维持现有 BD，不同步新增扩展状态寄存器。原因是 INFO_EXCH 位于 block design 内，新增 AXI-Lite slave 或扩展端口会牵动 BD 地址分配、wrapper 端口、软件地址表和回归验证。当前 adapter 已把 sticky/status 暴露给 ILA，足以支撑上板前的 bring-up 和定位。

| 方案 | 工作量 | 收益 | 风险/代价 |

| 维持 BD，仅 ILA 观察 sticky/status | 0-1 人日 | 最快进入综合、仿真和上板前检查。 | 软件无法直接读取 overflow/timeout/link 状态，长期联调可观测性弱。 |

| 在 INFO_EXCH 内扩展简单状态寄存器 | 3-6 人日 | 软件可读基本状态，地址空间集中。 | INFO_EXCH 会变大，需谨慎保持 0x0000-0x0028 兼容。 |

| 新增独立 AXI-Lite 状态寄存器 slave | 5-9 人日 | 边界清晰，支持 IRQ_ENABLE、W1C、计数器和自测。 | 需要修改 BD、地址分配、wrapper、驱动/脚本和更多验证。 |

| 先维持 BD，后续补寄存器 | 后续约 2-4 人日；若未预留状态端口约 4-7 人日 | 当前进度最快，后续可按问题再补。 | 需在 adapter 中保留清晰状态信号，避免后续拆线返工。 |


因此建议当前文档方案明确：先维持 BD，保留原寄存器表；后续若需要软件长期运行可观测性，再从 0x0030 之后增加 AURORA_STATUS、FDMA_STATUS、FIFO_STATUS、IRQ_ENABLE、IRQ_STATUS 和 ERROR_CLEAR 等寄存器，不覆盖原 0x0000-0x0028。

# 验证方案与风险清单

| 验证层级 | 目标 | 关键检查 |

| bridge 单元回归 | 确认完整 FDMA2AURORA 异步桥原行为未破坏。 | TX/RX、stall、地址回绕、FIFO sticky、Aurora link。 |

| adapter 功能 TB | 证明 INFO_EXCH 语义、FDMA size、frame 边界正确。 | TX/RX 单帧、多帧、非 512B 对齐、IRQ/clear、rvalid/wready stall。 |

| PCIe.v 级 mock TB | 证明 PCIe.v 嵌入点与 design_1_wrapper 端口语义匹配。 | RD_START、CPU_WR_DONE_resp、FPGA_CPU_irq_req、64-bit 地址、ILA probe。 |

| Vivado 综合实现 | 证明工程收录、IP 状态和时序可通过。 | TOP 为 synthesis top、XPM_CDC/XPM_FIFO、Vivado 2020.2 IP locked 状态处理。 |

| 上板 bring-up | 证明 PCIe、Aurora、FDMA 和软件闭环可运行。 | PCIe 枚举、BAR 读写、TX 单帧、RX 单帧、连续帧、异常 sticky。 |


| 风险 | 影响 | 建议措施 |

| 完整桥状态未接入 adapter | Aurora 未 up 时 TX 仍可能启动。 | 最终改为 PCIe link 与 bridge channel/lane up 相与。 |

| 旧 66-bit debug 端口未删除 | 容易让 DATA_CDC 被误接回主路径。 | 最终 PCIe.v/TOP.v 清理旧 debug stream 边界，只保留必要 ILA/test hook。 |

| RX 方向不能可靠反压 | CPU 慢读或 FDMA stall 时可能 overflow。 | 增加 FIFO 水位观测、overflow sticky、远端限速和软件读取策略。 |

| 暂不加状态寄存器 | 软件长期调试状态不足。 | 当前用 ILA，上板稳定后补 0x0030 以后的扩展寄存器。 |

| Vivado IP 版本 locked | 综合/实现可能被 IP 状态阻塞。 | 上板前固定 Vivado 版本策略或 regenerate IP 后重跑实现。 |
