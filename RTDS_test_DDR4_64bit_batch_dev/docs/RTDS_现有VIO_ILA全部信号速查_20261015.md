# RTDS 现有 VIO / ILA 全部信号速查

核对日期：2026-10-15。与 `main_spi4_50_gui/TOP_main_spi4_50.ltx` 对照。实例编号 `hw_vio_1/2`、`hw_ila_1～4` 可能改变，按下表实例路径识别。本表也是《RTDS PCIe 软硬件联调与烧录操作手册》的附录 A/B。

## A. 两组 VIO：全部 20 个输入、3 个输出

方向以 VIO 核为参考，IN=逻辑送给 VIO 的观察，OUT=VIO 驱动逻辑。两组 VIO 均使用板载业务 250MHz，输出控制和观察路径已有寄存处理。不要把在 GUI 中添加探针误认为修改硬件设计。

### A.1 旧 VIO：上行固定数据注入

实例 `u_pcie/G_RX_VIO.U_VIO_RX_START`，常见 `hw_vio_1`。信号名前缀 `u_pcie/`。

| 端口 | LTX 信号名 | 位宽 | 解释与正常期望 |
|---|---|---|---|
| IN0 | `rx_test_busy_r` | 1 | 包含等周期、两字输入、等真实块登记；空闲 0 |
| IN1 | `rx_test_accepted_r` | 2 | 本次已接受的 32bit 字数 0/1/2，成功后可保持 2；不是 DDR 完成计数 |
| IN2 | `rx_test_status_r` | 4 | bit0 DDR ready；bit1 同步后的 PCIe link；bit2 注入 fault；bit3 原业务通知请求 |
| IN3 | `rx_test_blocks_r` | 4 | 已完成未归还块数 0～8；与软件 `0x30` 交叉核对 |
| OUT0 | `rx_test_start` | 1 | 默认 0；提交 0→1 一次产生两个字 0x11/0x22；保持 1 不重复；busy 时/未就绪时边沿被忽略 |

status=1：DDR ready、PCIe 未 ready；status=3：DDR/PCIe ready、无 fault/通知；status=B：低两位 ready、bit3 通知。fault=1 时不要仅按低两位为 3 继续触发。fault 保持到全局复位，新 VIO clear 和软件读清都不清它。

### A.2 新 VIO：PCIe 链路与稳定性观察

实例 `u_pcie/U_PCIE_LINK_DEBUG/vio`，常见 `hw_vio_2`。表中信号名前缀 `u_pcie/U_PCIE_LINK_DEBUG/`。GUI 的 `snapshot_vio_1/_2/_3` 是 LTX 将一个大快照拆分后的实际名字。

| 端口 | LTX 实际信号名 | 位宽 | 含义 / 推荐进制 |
|---|---|---|---|
| IN0 | `live_vio` | 16 | 当前独立状态位，见 A.3；Binary/Hex |
| IN1 | `history_vio` | 4 | 曾经状态位，见 A.4；Binary |
| IN2 | `ups_vio` | 16 | 已观察的 link 0→1 次数，饱和；Unsigned Decimal |
| IN3 | `downs_vio` | 16 | link 1→0 次数，饱和；Unsigned Decimal |
| IN4 | `persts_vio` | 16 | PERST# 1→0 次数，不是启动时低电平时长；Unsigned Decimal |
| IN5 | `pll_losses_vio` | 16 | QPLL1LOCK 1→0 次数；Unsigned Decimal |
| IN6 | `uptime_vio` | 32 | 本次板载业务复位释放后的运行毫秒，自然回绕 |
| IN7 | `snapshot_vio_1` | 32 | 原 RTL snapshot[271:240]，一致性原生摘要，见 A.5；Hex |
| IN8 | `snapshot_vio_2` | 64 | 原 snapshot[335:272]，LTSSM 曾经过位图，bit N 表示状态 N 出现过；Hex |
| IN9 | `snapshot_vio_3` | 128 | 原 snapshot[239:112]，AXI握手/错误计数打包，见 A.6；Hex |
| IN10 | `snapshot_vio` | 112 | 原 snapshot[111:0]，ticks/跳变/响应错误/dwell，见 A.7；Hex |
| IN11 | `seq_vio` | 16 | 跨域一致性快照更新序号，自然回绕；快照持续变化时应更新 |
| IN12 | `age_vio` | 32 | 距上一次快照更新的毫秒，饱和；正常很小，不能持续增长 |
| IN13 | `first_link_vio` | 32 | 首次观察 link=1 的 uptime 毫秒，FFFFFFFF=尚未看到 |
| IN14 | `first_perst_vio` | 32 | 首次观察 PERST# 高的 uptime 毫秒，不是低脉宽，FFFFFFFF=尚未看到 |
| IN15 | `ar_falls_vio` | 16 | axi_aresetn 1→0 次数；名称 ar 指 AXI reset，不是 AXI AR 事务 |
| OUT0 | `clear_vio` | 1 | 默认0，0→1清诊断历史/计数；不驱动功能复位；清后提交回0 |
| OUT1 | `capture_axi_vio` | 1 | 默认0；为1时AXI活动也可产生原生capture_event，主要供事件资格采集；不发起AXI事务 |

普通连续 ILA 采样时不需要将 capture_axi_vio 置 1；它也不打开/关闭 XDMA 业务。所有 VIO 输入多了显示寄存，PCIe 编码状态通过 held-bus handshake 一致传递，不是独立逐位同步编码总线。新 VIO 能在 PCIe 时钟停止时继续显示板载域信息，原生快照则可能停在旧值，必须结合 clock_alive 和 age 解读。

### A.3 live_vio 全部位

| 位 | 为1表示 | 初次健康空闲值/注意 |
|---|---|---|
| 0 | PERST# 已释放/输入为高 | 1 |
| 1 | QPLL1LOCK | 1 |
| 2 | 观察到 PCIe 时钟心跳 | 1；不是 link up |
| 3 | user_lnk_up | 1；与 LED17 灭对应 |
| 4 | axi_aresetn 高，AXI 复位已释放 | 1 |
| 5 | DDR ready | 1 |
| 6 | 板载业务 reset 有效 | 正常为0 |
| 7 | 观察器 settle 已完成 | 1 |
| 8 | 原业务 IRQ 请求 | 空队列通常0，待取通知时可1；不等同CPU实际收到中断次数 |
| 15:9 | 保留 | 0 |

健康空闲可见 00BF，有通知可见 01BF。过去失败现场 00A7 表示 PERST/PLL/时钟/DDR/settled 有效，但 link/AXI reset release 为0。

### A.4 history_vio 全部位

| 位 | 含义 |
|---|---|
| 0 | 观察器稳定后曾观察 PERST# 低；未置1不证明配置前从未复位 |
| 1 | 曾观察 QPLL1LOCK |
| 2 | 曾观察 PCIe 时钟活动 |
| 3 | 曾观察 link=1 |

清历史后，当前为真的曾经位会很快重新置位。board_reset 清板载历史；PCIe PERST/AXI reset 本身不被用作诊断历史的统一复位。历史位图没有事件先后顺序。

### A.5 snapshot_vio_1 的32位摘要

| 位范围 | 内容 |
|---|---|
| 5:0 | cfg_ltssm_state |
| 8:6 | cfg_current_speed：1=Gen1，2=Gen2，4=Gen3；未建链前不作协商速率结论 |
| 12:9 | cfg_negotiated_width：有效协商后2=x2；未建链的异常/初始值如8不等于真实x8连接 |
| 13 | user_lnk_up |
| 14 | axi_aresetn |
| 15 | 同步后的 PERST# |
| 16 | 同步后的 QPLL1LOCK |
| 21:17 | local_error code，只在bit22=1时解释 |
| 22 | local_error_valid |
| 23 | err_cor |
| 24 | err_nonfatal |
| 25 | err_fatal |
| 31:26 | 0 |

LTSSM 的完整数值以当前 AMD PCIe 核定义为准；本轮常用0x00/0x01为Detect Quiet/Active，L0使用该核定义的0x10。不要把RK3588控制器自己的LTSSM编码与FPGA编码混用。link=1、有效speed/width、事务结果是主要联合判据，不单独只比一个状态码。

### A.6 snapshot_vio_3 的128位计数

| 位范围 | 单独字段位宽 | 含义 |
|---|---|---|
| 31:0 | 32 | XDMA M_AXI AWVALID且AWREADY握手次数，按写突发地址计数，不是字节数 |
| 63:32 | 32 | XDMA M_AXI ARVALID且ARREADY握手次数，按读突发地址计数 |
| 79:64 | 16 | err_cor 有效周期计数 |
| 95:80 | 16 | err_nonfatal 有效周期计数 |
| 111:96 | 16 | err_fatal 有效周期计数 |
| 127:112 | 16 | local_error_valid 有效周期计数 |

均饱和。错误有效持续多拍会累计多次，不是去重后的物理故障个数。AW/AR 只看 XDMA DMA AXI 口，不包含用户 AXI-Lite BAR；BAR 读写时计数不增加可属正常。记录本轮差值，饱和后差值失去统计意义，先保存旧值后再分段清历史。

### A.7 snapshot_vio 的112位扩展信息

| 位范围 | 字段 | 含义 |
|---|---|---|
| 31:0 | native_ticks | PCIe 原生时钟计数，自然回绕；清历史不清此自由计数 |
| 47:32 | transitions | LTSSM 跳变次数，饱和 |
| 63:48 | berror_count | BVALID且BREADY且BRESP非零的有效写响应计数，饱和 |
| 79:64 | rerror_count | RVALID且RREADY且RRESP非零的有效读拍计数，饱和 |
| 111:80 | dwell | 当前 LTSSM 连续停留时钟数，状态变化归零，饱和 |

ticks/dwell 单位是 PCIe 原生时钟周期，不是毫秒。需要换算时用当前实际 axi_aclk 周期。32bit ticks 会回绕，跨界差值按模2^32计算；VIO刷新不能代替逐拍波形。

## B. 四组 ILA 的全部已有信号

当前 LTX 为31个RTL/IP ILA探针端口（原生11、FDMA14、温度6）及PHY的1个10bit端口。PHY端口在GUI/LTX拆成10个1bit对象，总计可见41个信号对象。两种计数口径不要混用。

### B.1 PCIe 原生 ILA：11个端口

实例 `u_pcie/U_PCIE_LINK_DEBUG/ila`，采样时钟为 XDMA axi_aclk。深度2048；所有下列信号前缀 `u_pcie/U_PCIE_LINK_DEBUG/`。触发与payload一同寄存。

| 端口 | LTX实际信号 | 位宽 | 含义 |
|---|---|---|---|
| probe0 | `ila_ltssm` | 6 | 原生LTSSM寄存副本 |
| probe1 | `ila_flags_1` | 1 | user_lnk_up，原RTL ila_flags[0] |
| probe2 | `ila_flags_2` | 1 | axi_aresetn，原ila_flags[1] |
| probe3 | `ila_flags_3` | 1 | PERST#同步副本，原ila_flags[2] |
| probe4 | `ila_flags_4` | 1 | QPLL1LOCK同步副本，原ila_flags[3] |
| probe5 | `ila_speed` | 3 | cfg_current_speed |
| probe6 | `ila_width` | 4 | cfg_negotiated_width |
| probe7 | `ila_flags` | 1 | capture_event，原ila_flags[4]；不是link |
| probe8 | `ila_ticks` | 32 | 原生自由运行周期计数 |
| probe9 | `ila_errors` | 9 | 错误打包，见下表 |
| probe10 | `ila_axi` | 216 | XDMA M_AXI观察，见下表；不是M_AXI_LITE |

ila_errors：

| 位 | 内容 |
|---|---|
| 4:0 | local_error code，bit5有效时解释 |
| 5 | local_error_valid |
| 6 | err_cor |
| 7 | err_nonfatal |
| 8 | err_fatal |

ila_axi的全部216位：

| 位范围 | 内容 | 解读方法 |
|---|---|---|
| 0 | AWVALID | 与bit1同时1才接受写地址 |
| 1 | AWREADY | VALID可跨多拍保持，不能只数VALID |
| 2 | WVALID | 与bit3同时1才接受写数据 |
| 3 | WREADY | 写反压时检查数据/strb/last保持 |
| 4 | BVALID | 与bit5同时1才接受写响应 |
| 5 | BREADY | 当前接收许可 |
| 6 | ARVALID | 与bit7同时1才接受读地址 |
| 7 | ARREADY | 读地址接收许可 |
| 8 | RVALID | 与bit9同时1才接受读数据 |
| 9 | RREADY | 接收许可 |
| 11:10 | BRESP | 0=OKAY；非零结合握手看响应错误 |
| 13:12 | RRESP | 0=OKAY；非零结合握手看响应错误 |
| 14 | WLAST | 与有效写接受拍共同解释 |
| 15 | RLAST | 与有效读接受拍共同解释 |
| 23:16 | WSTRB | 每位对应WDATA的一个有效字节 |
| 55:24 | AWADDR[31:0] | 卡端字节地址低32位，仅接受时计为事务 |
| 87:56 | ARADDR[31:0] | 卡端字节地址低32位 |
| 151:88 | WDATA[63:0] | 仅写握手拍计入成功接受数据 |
| 215:152 | RDATA[63:0] | 仅读握手拍计入已接受数据 |

当前没捕获 AWLEN/ARLEN、AXI ID 和 AXI-Lite BAR，因此不能仅凭这一组完整重建所有突发边界或软件寄存器事务。CPU对DDR直接DMA可见；业务FDMA经过互连另一入口，不等于XDMA这个M_AXI口的活动。

### B.2 FDMA业务ILA：14个端口

实例 `u_pcie/ila_FDMA_inst`，板载clk_250m，深度1024。前缀 `u_pcie/`。

| 端口 | LTX信号名 | 位宽 | 含义/有效条件 |
|---|---|---|---|
| probe0 | `fdma_raddr` | 32 | 下行业务读起始字节地址低32位 |
| probe1 | `fdma_rareq` | 1 | 下行业务读请求；适合启动触发 |
| probe2 | `fdma_rbusy` | 1 | CONV_DMA读事务非空闲 |
| probe3 | `fdma_rdata` | 64 | 仅在fdma_rvalid=1计入已接受数据 |
| probe4 | `fdma_rsize` | 16 | 本次读64bit拍数，16Byte帧为2，不是字节数 |
| probe5 | `fdma_rvalid` | 1 | 实际读数据接受脉冲，等于CONV_DMA的RVALID且RREADY；不是单纯RVALID |
| probe6 | `fdma_waddr` | 32 | 上行业务写起始字节地址低32位 |
| probe7 | `fdma_wareq` | 1 | 上行writer写请求；VIO注入时用其触发 |
| probe8 | `fdma_wbusy` | 1 | CONV_DMA写事务进行中，包含等写响应 |
| probe9 | `fdma_wdata` | 64 | 上行当前写数据；需结合源valid，缺少直接接受探针 |
| probe10 | `fdma_wsize` | 16 | 写64bit拍数，当前writer为1；尾字也可发1拍但只有低4Byte有效 |
| probe11 | `fdma_w_source_valid` | 1 | writer提供数据有效；不是接受脉冲，不能按其保持周期数计写成功 |
| probe12 | `adapter_rx_state_dbg` | 4 | writer写状态0空闲/1请求/2数据/3等最终响应 |
| probe13 | `adapter_tx_state_dbg` | 4 | 发送桥FDMA读状态0空闲/1请求/2数据/3等读busy清零 |

两种状态都常见0→1→2→3→0，含义不同。缺少fdma_w_accept、wdone、werror、wstrb和B响应，不能用busy回0/状态回0判写成功。真实成功需块登记、软件状态和C2H比对。故障排空也可能产生rvalid，不能据此证明数据已交付10G。

### B.3 温度ILA：6个端口

实例 `u_temp_rd/ila_temp_inst`，板载clk_250m，深度1024。TEMP_RD周期为1ms；单屏只有约4.096µs。

| 端口 | 完整信号名 | 位宽 | 含义 |
|---|---|---|---|
| probe0 | `u_temp_rd/den_in` | 1 | SYSMON DRP操作使能；适合==1触发 |
| probe1 | `u_temp_rd/dwe_in` | 1 | 当前代码与den_in同步置1；不描述成dwe=0的纯读 |
| probe2 | `u_temp_rd/cnt_time` | 32 | 0～249999循环；Immediate可看活动 |
| probe3 | `u_temp_rd/daddr_in` | 8 | DRP地址，当前保持0 |
| probe4 | `u_temp_rd/temp` | 16 | SYSMON do_out原始码，不是摄氏温度 |
| probe5 | `u_temp_rd/busy` | 1 | TEMP_RD周期末提示，不是SYSMON busy_out，也不是PCIe/DDR忙 |

此核没有drdy_out。不能只凭原始码变化证明一次DRP操作完成；需要温度标定/换算时依据对应SYSMON型号手册，不将原始寄存器值直接标℃。

### B.4 PHY ILA：一个10bit端口，GUI拆为10个信号

实例 `ila_pcie_phy`，板载clk_250m，深度2048；每个被观察信号先经过两级FDRE采样，再加ILA输入管线。同步后的值适合看状态先后，不用于测亚周期模拟细节。

| probe0位 | LTX信号名 | 来源 | 解读 |
|---|---|---|---|
| 0 | `pcie_diag_phy_value_0` | 逻辑lane0 TXRESETDONE | 1=TX复位流程完成 |
| 1 | `pcie_diag_phy_value_1` | 逻辑lane0 RXRESETDONE | 1=RX复位流程完成，不证明接收数据/对端存在 |
| 2 | `pcie_diag_phy_value_2` | 逻辑lane0 CPLLLOCK | 当前使用QPLL1，不能要求此位一定1 |
| 3 | `pcie_diag_phy_value_3` | 逻辑lane1 TXRESETDONE | 同lane0 |
| 4 | `pcie_diag_phy_value_4` | 逻辑lane1 RXRESETDONE | 同lane0 |
| 5 | `pcie_diag_phy_value_5` | 逻辑lane1 CPLLLOCK | QPLL1配置下不作主要判据 |
| 6 | `pcie_diag_phy_value_6` | QPLL1LOCK | 当前应重点检查为1 |
| 7 | `pcie_diag_phy_value_7` | PCIe硬核RESETN | 高为释放 |
| 8 | `pcie_diag_phy_value_8` | PCIe硬核PIPERESETN | 高为释放 |
| 9 | `pcie_diag_phy_value_9` | PCIe硬核MGMTRESETN | 高为释放 |

逻辑lane按顶层TX pin关系映射，不按生成代码内部gen索引猜测。当前实际lane0/1使用GTHE3_CHANNEL_X0Y0/X0Y1，QPLL common为X0Y0。以上十位全部为1也不等于已经建链；建链仍看user_lnk_up和实际事务。

## C. 其他调试核和未覆盖信号

| 核 | 实例/用途 | 边界 |
|---|---|---|
| debug hub | `dbg_hub` | JTAG调试枢纽，板载约250MHz；不是业务状态探针 |
| MIG校准核 | `u_pcie/u_rtds_ddr4_backend/u_ddr4_mig` | Memory Calibration Debug查看CAL PASS；不是backend事务采集器 |
| PCIe内部JTAG AXI | `u_pcie/design_1_wrapper_inst/design_1_i/xdma_0/inst/pcie3_ip_i/inst/debug_wrapper_U/jtag_axi4l_m_inst` | 只用于官方PCIe调试空间LTSSM/reset/RXDET；不是通往业务BAR/DDR的任意JTAG总线主机 |

当前没有进入VIO/ILA的信号包括：用户BAR AXI-Lite AW/AR/W/R、CPU确认脉冲、fdma_w_accept/wdone/werror/wstrb、backend recovery细节、1G configured/id/tx握手/skipped_periods、cpu_sync_50us及2µs源事件、10G完整收发握手。它们不能通过GUI添加不存在的探针补出来。

优先使用已有寄存器、DMA比对和外部I/O测量形成闭环。确需新增信号时才另做RTL/ILA修改及实现；当前手册及辅助脚本不要求重新生成逻辑。
