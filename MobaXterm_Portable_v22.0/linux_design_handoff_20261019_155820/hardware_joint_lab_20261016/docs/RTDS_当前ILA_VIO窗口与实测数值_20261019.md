# 当前 ILA、VIO 窗口与实测数值

日期：2026-10-19。下列编号已与本次 GUI 日志核对；换会话后编号可能变化，实例路径才是识别依据。VIO 表取自 09:12:34 最终快照；ILA 是保存的历史采样，不是实时电平。

## 1. 先打开哪几个

| 当前编号 | 实例路径 | 本轮用途 |
|---|---|---|
| hw_vio_1 | u_pcie/G_RX_VIO.U_VIO_RX_START | 上行测试注入和块队列状态 |
| hw_vio_2 | u_pcie/U_PCIE_LINK_DEBUG/vio | PCIe、DDR、复位、时钟与错误观察 |
| hw_ila_1 | u_pcie/U_PCIE_LINK_DEBUG/ila | ARM H2C/C2H 的 XDMA AXI 数据通路；保存两次 |
| hw_ila_2 | u_pcie/ila_FDMA_inst | VIO 数据写入真实 DDR 的业务通路；保存一次 |
| hw_ila_3 | u_temp_rd/ila_temp_inst | 温度采集；本轮未重新采集 |
| hw_ila_4 | ila_pcie_phy | PHY 建链排查；本轮未重新采集 |

以 hw_vio_1、hw_vio_2、hw_ila_1、hw_ila_2 为主。不要把 ILA 中保存的旧电平当成当前 VIO 状态。推荐状态寄存器和总线使用 Hex，块数、字数和 busy 使用 Unsigned Decimal。

用户现场看到 ILA4 的 pcie_diag_phy_value_5 为0：它表示 lane1 CPLLLOCK，当前使用 QPLL1，因此不要求该位为1。应重点结合 value_6=1（QPLL1LOCK）、value_7/8/9=1（硬核相关复位已释放）、VIO link及实际DMA判断；不能要求十位全为1。本轮没有重新采集ILA4，该观察值来自用户现场反馈。

## 2. hw_vio_1：上行注入

信号前缀 u_pcie/。这些输入来自逻辑，输出 rx_test_start 由 VIO 驱动。

| 信号 | 最终值 | 含义 |
|---|---|---|
| rx_test_start | 1 | 保持高不重复发送。提交 0，再提交 1，才启动一次；本轮由助手控制 |
| rx_test_busy_r | 0 | 注入已结束；一次动作很短，VIO 可能看不到短暂的 1 |
| rx_test_accepted_r | 2 | 本次已接受两个 32bit 字，0x11、0x22，共 8Byte；不是两个块，也不是单凭此值证明 DDR 完成 |
| rx_test_blocks_r | 0 | 已完成、尚未归还的块数；与 ARM 寄存器 0x30 一致 |
| rx_test_status_r | 0x3 | DDR、链路就绪，fault=0，通知=0 |

rx_test_status_r 的位：bit0 DDR ready；bit1 PCIe link；bit2 注入 fault；bit3 原业务通知请求。0x3 是正常空闲；0xB 是就绪且有通知。若按十进制显示，0xB 会显示 11，不是 0x11。

本轮队列依次经历单块 0→1→0，然后多块 0→2→0、0→8→0、0→2→0。读清 0x10 仅清通知，不等于归还块。有效数据比较成功后，ARM 写一次 0x14=1，队列才减一。

“2→8→2”表示三轮独立的积累、排空，不是最终队列还保留12块：

| 批次 | 注入阶段 blocks | C2H比较并归还阶段 blocks | 本次实际块序号 |
|---|---|---|---|
| 2块 | 0→1→2 | 2→1→0 | 1、2 |
| 8块 | 0→1→2→3→4→5→6→7→8 | 8→7→6→5→4→3→2→1→0 | 3～10 |
| 再2块 | 0→1→2 | 2→1→0 | 11、12 |

多块前的单块实验使用序号0，序号并非每轮从0开始。第二批次实际地址依次为 0x1C0000、0x200000、0x240000、0x280000、0x2C0000、0x100000、0x140000、0x180000；0x2C0000→0x100000显示了跨环形区末尾。第三批次继续用0x1C0000、0x200000。每次均重新读取硬件队头地址，未用软件推算地址代替读取。

前台看 hw_vio_1/rx_test_blocks_r；软件对应寄存器为 BAR0+0x30。队头地址、有效长度、序号分别看0x18/0x1C/0x34，已同步记录在ARM日志的REGISTERS事件中。不要为了观察而额外读取读清寄存器0x10或写归还寄存器0x14。自动归还较快，最终blocks=0不代表没有经过8；应结合逐步日志和result.json中的blocks记录复核。

## 3. hw_vio_2：当前状态和历史

信号前缀 u_pcie/U_PCIE_LINK_DEBUG/。表中原始总线值均为十六进制。

| 信号 | 09:12:34 值 | 含义 |
|---|---|---|
| live_vio | 00BF | 当前状态位；解码见下表 |
| history_vio | E | 曾见 PLL、时钟和 link；观察器稳定后未记录 PERST# 低。不是故障码 |
| ups_vio | 0001 | 观察到一次 link 0→1 |
| downs_vio | 0000 | 未记录 link 1→0 |
| persts_vio | 0000 | 未记录 PERST# 1→0；不是复位低电平时长 |
| pll_losses_vio | 0000 | 未记录 PLL 锁定丢失 |
| ar_falls_vio | 0000 | 未记录 axi_aresetn 1→0；ar 在这里不是 AXI 读地址通道 |
| uptime_vio | 0015DEBC | 业务复位释放后的毫秒计数；会自然回绕 |
| seq_vio | 436E | 跨时钟域快照更新序号，持续更新并可回绕；不是数据块序号 |
| age_vio | 00000000 | 距上次快照更新的毫秒，此次为 0，观察信息未停滞 |
| first_link_vio | 00000F56 | 首次观察 link=1 的 uptime，即 3926ms |
| first_perst_vio | 00000000 | 首次观察 PERST# 高的 uptime；不是低脉宽 |
| snapshot_vio_1 | 0001E490 | LTSSM=0x10、speed 编码=2、width=2、link/AXI reset release/PERST#/PLL 均为1，错误标志为0 |
| snapshot_vio_2 | 0000000000017FF7 | LTSSM 曾经过状态位图，bit N=1 表示曾见状态 N；不表示当前停在多个状态 |
| snapshot_vio_3 | 00000000000000000000000E00000001 | 累计 DMA 写地址握手1、读地址握手14；PCIe 错误周期计数均0 |
| snapshot_vio | FFFFFFFF00000000029E6D78DE66 | 原生 ticks、LTSSM 跳变及响应错误和停留时间；分解见下文 |
| clear_vio | 0 | 诊断历史清除控制；本轮没有拉高，不清现场 |
| capture_axi_vio | 0 | AXI 活动是否参与原生 capture_event；不是 DMA 开关。常规 ILA 连续采样无需拉高 |

live_vio=0x00BF 解码：

| 位 | 含义 | 当前 |
|---|---|---|
| 0 | PERST# 已释放，高电平 | 1 |
| 1 | QPLL1LOCK | 1 |
| 2 | PCIe 时钟心跳可见 | 1 |
| 3 | PCIe user_lnk_up | 1 |
| 4 | AXI 复位已释放，axi_aresetn=1 | 1 |
| 5 | DDR ready | 1 |
| 6 | 板载业务复位有效 | 0，正常 |
| 7 | 观察器 settle 完成 | 1 |
| 8 | 业务 IRQ 请求 | 0；有通知时通常变成1，整个值变为01BF |

snapshot_vio_3 是 DMA AXI 口计数，不包括 io 访问 BAR 的 AXI-Lite 事务。写1次对应 DDR H2C；读14次对应 DDR C2H 1次加上13个上行块。计数不是字节数。

snapshot_vio 分解：native_ticks=1836637798；LTSSM 跳变次数=670；错误写响应计数=0；错误读数据拍计数=0；当前状态停留周期=0xFFFFFFFF，表示计数饱和，不是错误。ticks/停留时间的单位是原生时钟周期，不能直接当毫秒。VIO 逐项刷新，整张表并非同一时钟拍的原子快照。

## 4. hw_ila_2：单块上行波形怎样看

打开保存的 gui_fdma_20261019_091109_1792372269768.csv/.ila。1024个采样点，触发标记在样点128，触发条件为 fdma_wareq=1。

| 信号 | 本次有效阶段的值 | 含义 |
|---|---|---|
| fdma_waddr | 00100000 | 该块 DDR 起始字节地址；后续块地址以硬件返回值为准 |
| fdma_wareq | 样点128、129为1 | 上行 writer 请求发起 DDR 写 |
| fdma_wbusy | 请求后变1，完成后回0 | 写事务进行中，包含等响应 |
| fdma_wsize | 0001 | 一个64bit拍，即8Byte；不是1Byte |
| fdma_wdata | 0000002200000011 | 高32位0x22、低32位0x11；小端字节排列为11 00 00 00 22 00 00 00 |
| fdma_w_source_valid | 样点130～133为1 | 源端提供的数据有效；保持4拍不等于写了4个字，缺少直接接受探针 |
| adapter_rx_state_dbg | 0→1→2→3→0 | writer 的空闲→请求→数据→等最终响应→空闲 |
| adapter_tx_state_dbg | 0 | 下行业务读状态空闲 |
| fdma_raddr | 00008000 | 下行业务读地址的保留值，本次没有启动下行业务 |
| fdma_rareq | 0 | 本次没有业务读请求 |
| fdma_rbusy | 0 | 业务读空闲 |
| fdma_rdata | 0F0E0D0C0B0A0908 | 保留数据；rvalid=0 时不能算本次读到的数据 |
| fdma_rsize | 0002 | 保留的两个64bit拍配置，即16Byte，不代表本次已执行下行 |
| fdma_rvalid | 0 | 没有业务读接受拍 |

单凭 busy 回0或状态回0不能证明写入成功。本轮另有块登记、寄存器健康检查、ARM C2H逐字节比较和一次归还作为闭环证据。真实 Aurora 接收未参与当前 VIO 实验。

## 5. hw_ila_1：DDR 写、读两份波形

每份2048个样点，触发点128。写波形 gui_native_20261019_091031_1792372231992；读波形 gui_native_20261019_091042_1792372242631。

| 信号 | 两次触发附近值 | 含义 |
|---|---|---|
| ila_ltssm | 0x10 | 本PCIe核的L0运行状态；需结合link和事务判断 |
| ila_flags_1 | 1 | PCIe link up |
| ila_flags_2 | 1 | AXI复位已释放 |
| ila_flags_3 | 1 | PERST# 高 |
| ila_flags_4 | 1 | PLL锁定 |
| ila_speed | 2 | cfg_current_speed 编码，本工程速查表中2对应Gen2；不是2条lane |
| ila_width | 2 | 协商宽度x2；与speed是不同字段 |
| ila_flags | 0 | capture_event；不是link信号。采用ALWAYS采样，无需它为1 |
| ila_ticks | 写触发0C97BEBC、读触发AA42D4DF | 自由运行周期计数，会回绕；不用于毫秒直读 |
| ila_errors | 000 | 已保存两份波形中全部样点的错误探针为0 |
| ila_axi | 216bit总线 | 打包的地址、数据、VALID/READY、响应；分解见下表 |

ila_axi 的低位握手和数据切片：

| 位 | 字段 | 本次核对结果 |
|---|---|---|
| 0、1 | AWVALID、AWREADY | 写波形同时为1共1拍，AWADDR=0x8000 |
| 2、3 | WVALID、WREADY | 写波形同时为1共2拍，共16Byte |
| 4、5 | BVALID、BREADY | 写响应握手1次，BRESP=0 |
| 6、7 | ARVALID、ARREADY | 读波形同时为1共1拍，ARADDR=0x8000 |
| 8、9 | RVALID、RREADY | 读波形同时为1共2拍，共16Byte |
| 11:10、13:12 | BRESP、RRESP | 有效响应均0，即OKAY |
| 14、15 | WLAST、RLAST | 对应两拍数据的最后一拍为1 |
| 23:16 | WSTRB | 两个有效写拍均FF，8个字节全有效 |
| 55:24、87:56 | AWADDR、ARADDR | 地址握手时为00008000 |
| 151:88 | WDATA | 0706050403020100、0F0E0D0C0B0A0908 |
| 215:152 | RDATA | 0706050403020100、0F0E0D0C0B0A0908 |

只有 VALID 和 READY 同时为1才算成功接受一拍。数据在其他拍显示为0或旧值并非故障；不能把216bit总线整体的十六进制数当成一个寄存器值。该 ILA 观察 XDMA DMA AXI，不直接观察 BAR 寄存器访问。

## 6. 证据位置与当前结论

远程 Vivado 采集目录：

```text
C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\debug\hardware_joint_lab_20261016\captures\gui_20261019_085727_1792371448033
```

本机解码证据：validation/20261019/capture_decode.json；输入为上述3份真实CSV，解码程序只读文件，不操作硬件。

环境、寄存器、配置、DDR、VIO单块、2/8/2多块与环回均通过。当前 RX_VIO_TEST_ENABLE=1；该结论不是全部RTL功能或真实Aurora/对端收发验收。

补充：最终快照中的 PROGRAM.FILE 属性被配置存储器流程设为 Vivado 的 spi_xcku040_pullnone.bit 辅助文件；PROBES.FILE 仍为配套 TOP_main_spi4_50.ltx。PROGRAM.FILE 是主机设置，不能证明板上已下载该文件。当前主设计的调试核和数据闭环确实可访问；本轮没有执行 program_hw_devices。后续若要 Program Device，须重新选择既定 TOP_main_spi4_50.bit，不要直接沿用该辅助文件属性。

完整温度/PHY和全部信号定义另见2026-10-15的 RTDS_现有VIO_ILA全部信号速查_20261015.md；这些核本轮未新采集，不将旧波形值写为今日实测。
