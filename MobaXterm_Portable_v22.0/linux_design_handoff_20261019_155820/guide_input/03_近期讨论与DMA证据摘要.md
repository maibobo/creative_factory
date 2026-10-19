# 近期讨论与上午DMA证据摘要

本文件是当前对话的事实要点整理，不是完整聊天记录，也不声称包含精确时间窗口内的全部逐字内容。

## 已澄清的认识

1. 当前验证对象是主机板ARM CPU与FPGA，不是主机与子机联调。
2. 寄存器配地址/长度并不会直接把载荷送入DDR。载荷由已有XDMA驱动通过H2C/C2H搬运，rtds_dma.c是调用它的用户态示例。
3. 上午不仅测试BAR回读：DDR16Byte往返、VIO单块、2/8/2排队环回均实测通过。不能由此声称全部RTL、全部业务或用户新应用已通过。
4. FPGA端ILA1看XDMA M_AXI地址/数据/响应；ILA2看业务FDMA写DDR；VIO只提供本设计暴露的控制/状态，不能任意改DDR数据。ILA只能观察。
5. CPU软件能控制DMA卡内地址并读写CPU缓冲区；FPGA逻辑能读写DDR。共享地址区需要按队列/归还协议交接，不应同时无序修改同一块。
6. ARM部署在持久根分区，断电保留；不代表有开机自启动。PC远程控制只是入口，实际寄存器和DMA操作均在ARM。
7. 已采用现有远程Vivado GUI与已有ARM终端，不增加前台窗口。寄存器监视器默认只在变化时追加，温度不触发默认变化输出；旧监视进程需重启才使用新代码。

## 最直接的DMA证据

第一轮DDR用例run_id=20261019_091019_ddr_3159c：

- H2C：card_address=32768(0x8000)，requested=16，completed=16，errno=0，returncode=0。
- C2H：同一地址，requested=16，completed=16，errno=0，returncode=0。
- ddr_tx.bin与ddr_rx.bin均为00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F，逐字节比较PASS。
- ILA1 H2C保存gui_native_20261019_091031_1792372231992.csv：AW握手1次，地址8000；W握手2次，每次64bit，WSTRB=FF，末拍WLAST=1；B握手1次，BRESP=0。
- ILA1 C2H保存gui_native_20261019_091042_1792372242631.csv：AR握手1次，地址8000；R握手2次，末拍RLAST=1，RRESP=0。
- 写、读两份波形两拍数据都为0706050403020100和0F0E0D0C0B0A0908；小端即上面的00..0F。两份全部采样ila_errors=0。

VALID与READY同时为1才算接受数据。仅链路亮、DDR ready、配置回读正确、busy归零或最终队列为0，都不是充分的DMA数据正确证据。

## VIO上行与队列证据

第一轮单块run_id=20261019_091052_single_b260f，multi=20261019_091120_multi_01905。

- VIO accepted=2指两个32bit字，共8Byte；busy=0、fault=0只是注入状态，不单独证明DDR/C2H正确。
- ILA2 gui_fdma_20261019_091109_1792372269768.csv：waddr=100000，wsize=1个64bit拍，wdata=0000002200000011，writer状态0→1→2→3→0。source_valid高4拍不等于接受4个数据。
- ARM每块C2H请求并完成16Byte，比较前8Byte=11 00 00 00 22 00 00 00；成功后才ACK一次。
- 0x2C=3说明DDR就绪；0x30记录入队/归还，0x38维持0。队头0x18、长度0x1C、序号0x34逐块重新读取。读清0x10不改变队头/数量；写0x14才归还。
- 多块依次积累/排空2、8、2块，经过全部8槽；地址2C0000→100000显示环回，序号连续。
- 09:12:34 VIO2快照DMA写地址握手1次、读地址握手14次（1次DDR读+13块上行），响应错误计数0。这是历史时点计数，不是以后实时值，次数也不是字节数。

共三轮、18用例PASS、39个上行块。两种PC控制路径结果一致，见final_route_comparison.json。有效载荷8Byte与传输请求16Byte必须分别记录。程序增加中文注释前后执行逻辑不变、ARM二进制哈希相同，但源码哈希因注释而改变；不要因历史result.json的源码哈希与当前注释版不同就误报数据作假。

## 未验收

真实Aurora与子机交互、真实下行业务触发、用户MSI向CPU投递、长时间/性能/大包与尾部边界、故障恢复专项、外部I/O、Flash/JTAG分别启动及reboot专项。本轮不改RTL、驱动或启动配置。syn/impl out of date不等于当前固定bit运行失败，也未定位其具体触发文件。

固定bit/LTX基线位于远程C:/project/RTDS/pcie_cold_boot_audit_20261014/main_spi4_50_gui/TOP_main_spi4_50.bit及同名.ltx。bit SHA256=5131C34A2C2C4D84564A867D4B177105951C43C361DCD8D892D18CEF564C7E45；LTX SHA256=4E388540548B63F639255A7C6FF0947FFDA6CC7380FC4866571E7687EE6D56E5。文件未作为指南必需输入复制。主机PROGRAM.FILE属性曾被cfgmem辅助流程改写，不证明辅助bit已下载；再次Program Device必须核对实际选择的TOP bit。
