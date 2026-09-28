# ring、axi、regs：按时间刻度复核 WCFG 观察链

本文展开 [WCFG 总览](WCFG_阅读与代码对照.md) 中 ring、axi、regs 三行。结论来自本机保存的 [ring.vcd](ring/ring.vcd)、[axi.vcd](axi/axi.vcd)、[regs.vcd](regs/regs.vcd)，并对照相应测试台、RTL 与 `simulation.log`；不把 WCFG 的信号列表或一张截图本身当作行为证明。WCFG 决定显示什么，VCD/WDB 才记录变化。三组都是模块级行为仿真，axi 的下游是行为 RAM，ring 的 FDMA 下游是测试台 responder，regs 的状态输入也是测试台常量；下面的结论不外推为 PCIe、Aurora、真实 DDR 整机验证。

## 先把时标和读法固定

- 三份 VCD 的时间分辨率均为 **1 ps**；本文把 VCD 时间戳除以 1000，以 **ns** 表示。ring 终点 28902 ns，axi 终点 13318 ns，regs 终点 422 ns。三组时钟都是 250 MHz，即相邻上升沿间隔 **4 ns**。
- 文中的 `t=... ns` 若写“跳变”，指该时间戳 VCD 记录的新值；寄存器的新值通常是这个上升沿之后的结果。判断 AXI `VALID && READY` 或 ring 的输入接受，要看**上升沿到来前**二者是否同时为 1。比如 AWREADY 在 70 ns 变高且 AWVALID 仍为 1，实际 AW 握手在 74 ns 上升沿，随后 AWVALID 撤销。
- 用 `Open_ring.cmd`、`Open_axi.cmd`、`Open_regs.cmd` 打开各自 HTML；也可在本机 PowerShell 5 执行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\Open-LocalWave.ps1' -Case ring`。在远程 Windows **已登录桌面**执行时，把 `-File` 路径换成 `C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\scripts\Open-LocalWave.ps1`。`-Case` 可改为 `axi` 或 `regs`。顶部两个数字框输入下表的起止 **ns**，点“跳转”。缩窄或隐藏代码栏可多留波形宽度；检查同名信号时切到“全称”。
- 下文未写根路径的 `bus/x`、`U_DUT/x`、顶层 `x`，分别表示 `/tb_rtds_<组>/bus/x`、`/tb_rtds_<组>/U_DUT/x`、`/tb_rtds_<组>/x`。优先看 `bus` 接口，再看 `U_DUT` 内部原因，最后对照测试台的 `$fatal`/读回检查。一个数值保持不变不代表每拍都传输。
- 代码栏黄色行只做**静态标识符定位**，不是“这个时间运行到此行”。本文提到的 RTL 条件需结合相邻时钟边沿与波形判读。ring 的 `block_len[]`、`block_seq[]` 是 VCD 不支持的 unpacked array；它们的对外结果 `head_len/head_seq` 可在 HTML 直接看，数组元素要用同组 WDB。

## ring：32-bit 字流 → FDMA 成功写 → 封块发布 → CPU 确认

本组入口是 [ring_viewer.html](ring/ring_viewer.html)，主要对照 [rtds_rx_block_writer.v](../../rtl/rtds_rx_block_writer.v) 的 `take_word`、`pair_start/tail_start`、`write_success/write_failure`、`used_bytes`、`seal_done/push_block/pop_block`，以及 [tb_rtds_ring.sv](../../regression/batch_1g/tb_rtds_ring.sv) 的 `send_word`、`check_head` 和四段主激励。建议始终把 `bus/clk`、`bus/frame_valid/frame_ready/frame_data`、`bus/fdma_w*`、`bus/ready_blocks/head_*` 放在相邻行；内部条件从“DUT端口/状态”里找。

| HTML 跳转范围 | 这段要验证什么 | 最有用的信号 |
|---|---|---|
| 34–96 ns | 两个低 32-bit 字如何拼成一个完整 FDMA 写拍，以及何时真正记为成功 | `frame_data/valid/ready`、`half_valid/data`、`pair_start`、`fdma_wdata/wstrb/wareq/waccept/wdone`、`write_success`、`used_bytes` |
| 824–854 ns | 成功写之后才封块、发布队头，CPU ACK 后弹出 | `tick`、`seal_pending`、`push_block/pop_block`、`ready_blocks`、`head_*`、`irq/cpu_ack` |
| 1628–1695 ns | 三个 32-bit 字的最后一个如何变成 `WSTRB=0F` 尾拍 | `half_data/valid`、`tail_start`、`fdma_wdata/wstrb/waddr/wdone`、`used_bytes/head_len` |
| 6470–6510 与 7225–7265 ns | 第 7 块到第 8 块时地址/指针回绕 | `write_block/read_block`、`head_addr/head_seq`、`ready_blocks` |
| 24870–25710 与 25730–25860 ns | 八块全满后丢弃两个额外字，旧队头不被覆盖，随后依次 ACK | `queued/ready_blocks`、`reject_word/dropped_frames`、`head_addr/seq`、`cpu_ack/pop_block` |
| 25860–27130 ns | 延迟写响应跨过周期边界时，发布必须等待完成 | 顶层 `response_delay`、`fdma_waccept/wdone`、`seal_pending`、`write_curr_st`、`used_bytes/ready_blocks` |
| 27135–27200 与 28110–28895 ns | 错误写不发布、按字计丢失，之后正常写恢复 | 顶层 `inject_error`、`fdma_wdone/werror`、`write_failure`、`dropped_frames`、`push_block/head_seq` |

**1. 拼接与提交（34–96 ns）。** 38 ns 输入 `frame_data=0xBD00CB88_00000000`、`frame_valid=1`，42 ns `half_valid` 置 1；46 ns 第二个输入为 `0x90C06CCD_00000001`，`pair_start=1`。50 ns `fdma_wdata=0x00000001_00000000`、`fdma_wstrb=0xFF`、`fdma_wareq=1`，说明 DUT 只取两个输入的低 32 bit，前一个字在低半拍，后一个字在高半拍；随机高 32 bit 没有混入有效写数据。该请求的 `fdma_wsize` 恒为 1 个 64-bit 拍，首地址是 `0x00100000`。70 ns `fdma_waccept` 变 1，此时只是**数据被接受**；86 ns `fdma_wdone=1` 且 `fdma_werror=0` 才有 `write_success=1`；90 ns `used_bytes:0→8`，写地址随之到 `0x00100008`。代码中 `used_bytes` 只在 `write_success` 时按 `active_transfer` 的有效字节数增长，因此不能把 W 接受误认成 DDR 提交成功。

**2. 封块发布与确认（824–854 ns）。** `PERIOD_CYCLES=200`，250 MHz 测试时钟下窗口为 **800 ns**；这是测试缩短的周期，不是产品实际采集周期。830 ns `tick=1`，834 ns `seal_pending=1`、`seal_done=1`、`push_block=1`。838 ns `ready_blocks/queued:0→1`，`head_addr=0x00100000`、`head_len=8`、`head_seq=0`、`irq=1`。这一发布晚于上段的成功响应 86 ns。846 ns `cpu_ack=1`、`pop_block=1`，850 ns 队列归零、队头和 IRQ 清零。`irq_clear` 不是替代 `cpu_ack` 的出队握手；代码的 `pop_block=cpu_ack && queued!=0`。

**3. 奇数尾字（1628–1695 ns）。** 第 1 块的前两个字已使 `used_bytes=8`；剩余 `half_data=0x12`。1634 ns `tail_start=1`，1638 ns `fdma_waddr=0x00140008`、`fdma_wdata=0x00000000_00000012`、`fdma_wstrb=0x0F`：只写低四个字节，高四字节无效。1674 ns 成功响应，1678 ns `used_bytes:8→12` 且封块条件成立，1682 ns 队头 `head_len=12`、`head_seq=1`。这里 `WSTRB=0F` 与 `head_len=12` 一起证明尾字按 **4 字节**计入；字节记分板还在测试台 `check_head` 中逐字比较实际写入内容。

**4. 环形回绕和满队保护。** 6482 ns，`head_seq=7`、`head_addr=0x002C0000`，发布后写指针回到 0；7238 ns，下一块 `head_seq=8`、`head_addr=0x00100000`。测试台把序号 0–23 分三轮逐块读回，按 `0x100000+(seq%8)*0x40000` 检查地址和字节数据；波形显示的这两个边界是回绕的可见例子。后续积压场景中，25682 ns `ready_blocks=8`、`head_seq=24`、`head_addr=0x00100000`、`head_len=4`，读/写块指针都为 0。25690 ns 送入值 999、25698 ns 送入值 1000，`take_word` 与 `reject_word` 同时为 1；25694/25702 ns `dropped_frames` 分别变 1/2，但 `head_seq/head_addr` 不变。这里 `frame_ready` 仍可能为 1：设计语义是**接受后记丢弃**，并非用 ready 反压满队输入。25738–25850 ns 的八次 `cpu_ack/pop_block` 让队列 8→0，队头依序从 seq24 到 seq31；每次 `head_addr` 跟随块指针推进。仅靠队列数最多为 8 还不足以证明“不覆盖旧块”；测试台对积压期间每个队头的 `check_head` 又检查了地址、长度和独立字节记分板。

**5. 跨窗口延迟响应（25860–27130 ns）。** 25866 ns 顶层 `response_delay:3→300`，25870/25878 ns 输入两个字，25902 ns 写数据被 responder 接受。26430 ns 定时窗口到点、26434 ns `seal_pending=1`，但此时 `write_curr_st=RESPONSE`、`fdma_wbusy=1`、`fdma_wdone=0`、`used_bytes=0`、`ready_blocks=0`；27000 ns 仍是同一状态。直到 **27106 ns** `fdma_wdone=1`/`write_success=1`，27110 ns `used_bytes=8`、`push_block=1`，27114 ns 才有 `ready_blocks=1`、`head_len=8`、`head_seq=32`。这条“封存请求已到 → 写响应未到 → 队列始终空 → 成功响应后发布”的链条直接对应测试台的 `STREAM/EARLY_PUBLISH` 检查。`seal_pending` 高电平本身不是已发布。

**6. 错误与恢复（27135–28895 ns）。** 27138 ns `inject_error=1`，27142/27150 ns 输入低 32 bit 为 3000/3001 的两个字。27190 ns `fdma_wdone=1`、`fdma_werror=1`、`write_failure=1`；27194 ns `dropped_frames:2→4`，`used_bytes` 仍为 0。到 28000 ns `ready_blocks` 仍为 0、发布序号仍为 33，因此错误块没有作为队头出现。28114 ns 取消注错，28118 ns 送入值 4000；28838 ns 出现 `WSTRB=0F` 尾拍，28874 ns 成功响应，28882 ns `head_len=4`、`head_seq=33`、`ready_blocks=1`。错误块没有占用发布序号，也没有阻止下一块恢复。测试台另断言错误后 `ready_blocks==0 && dropped_frames==4`，最终日志为 [ring/simulation.log](ring/simulation.log) 中的 `TEST PASS`。

ring 的可见结论是**本测试激励**下的拼接、尾拍、队列、响应延迟和错误路径符合代码预期。`dropped_frames` 在此实现里按 **32-bit 字**累计；名字不要误读成“完整帧个数”。

## axi：FDMA 请求 → AXI AW/W/B 与 AR/R → RAM 读回

本组入口是 [axi_viewer.html](axi/axi_viewer.html)，对照 [CONV_DMA.v](../../RTDS_test_DDR4_64bit.srcs/sources_1/new/CONV_DMA.v) 的 `burst_beats`、`wa/ra`、`wleft/rleft`、`wb/rb`、`aw_pending/w_pending`、`whs/rhs` 和 `fdma_wdone/werror`；下游行为模型及比较在 [rtds_axi_ram_model.sv](../../rtl/ddr4/rtds_axi_ram_model.sv)、[tb_rtds_axi.sv](../../regression/batch_1g/tb_rtds_axi.sv)。先选 `bus/M_AXI_*` 看真实五通道边界，再看顶层 `allow_aw/w/b` 与 DUT 内部计数。`bus/fdma_wvalid` 和 `bus/fdma_rvalid` 在本桥的历史命名下是**接受脉冲**（代码分别等于 `whs/rhs`），不能当作标准 AXI 通道的连续 VALID。

| HTML 跳转范围 | 重点 |
|---|---|
| 40–300 ns，尤其 218–238 ns | 第一笔 16 拍写：AW/W 独立反压，末拍保持，B 后才完成 |
| 300–2035 与 2038–3220 ns | 八个相隔 256 KiB 的地址分别写、再读回 |
| 3218–3290、5868–6020、8708–8854 ns | 520 拍写拆分的首段、中段、末段 |
| 8858–8900、10920–10950、12980–13060 ns | 相同 520 拍请求的读拆分与各段 RLAST |
| 13060–13316 ns | 注入 `BRESP=SLVERR`，最终 `fdma_werror` 跟随 B 响应 |

**1. 先理解独立通道反压（40–300 ns）。** 42 ns `fdma_wareq=1` 请求 `0x00100000` 的 16 拍；50 ns `M_AXI_AWVALID=1`、`AWADDR=0x00100000`、`AWLEN=0x0F`。测试台的 `allow_aw` 到 70 ns 才让 `AWREADY=1`，74 ns 上升沿 AW 握手；期间地址、长度保持。W 数据通道独立推进。218 ns `M_AXI_WLAST=1`、`WDATA=0x00000000_0000000F`，此时 `WREADY=0`；到 230 ns `WREADY=1`、234 ns 上升沿才接受最后一拍，期间 `WVALID/WDATA/WSTRB/WLAST` 保持。238 ns 才进入等待 B 的状态，286 ns `BVALID=1`，290 ns B 握手后 `fdma_wdone=1`、`fdma_wbusy=0`。**WLAST 出现不是 FDMA 写完成**。另一个有意制造的合法次序是 520 拍请求首段：W 末拍在 3234 ns 接受，AW 却到 3242 ns 才接受，B 在 3266 ns；因此应分别看 `AWVALID&&AWREADY`、`WVALID&&WREADY`、`BVALID&&BREADY`。按每个上升沿前的 VCD 值复核，全程有 50 个 AW 停顿采样沿、1084 个 W 停顿采样沿；下一沿 VALID 和负载保持的违例均为 0。测试台还对 AW/W 保持写了断言，且波形中确实命中停顿前件。

**2. 高地址隔离（约 40–3220 ns）。** 前八次 AW 握手地址依次为 `0x00100000、0x00140000、0x00180000、0x001C0000、0x00200000、0x00240000、0x00280000、0x002C0000`，各 `AWLEN=0x0F`、16 拍；AW 上升沿时间分别为 74、338、562、822、1086、1306、1570、1834 ns。对应 B 响应均为 OKAY，完成后才开始下一写请求。AR 在 2050–3086 ns 对同八个地址各发 16 拍，八个 RLAST 接受沿为 2178、2326、2474、2622、2770、2918、3066、3214 ns；末拍数据从 `{0,15}` 到 `{7,15}`，例如首块 `0x00000000_0000000F`、第八块 `0x00000007_0000000F`。测试台 `read_words` 不只检查末拍，而是将每一拍与 `{block_id,beat}` 比较；这才使“高地址没有被低位截断成别名”的判断完整。这里验证的是实际 CONV_DMA 加 **4 MiB 行为 RAM** 的路径。

**3. 4 KiB/256 拍拆分（3222–13054 ns）。** 3222 ns FDMA 提出 `addr=0x00180FF8, size=520` 拍。`burst_beats` 同时限制 4 KiB 剩余空间与 256 拍上限，AXI 的 LEN 字段是“拍数减一”。从 VCD 按上升沿采样并逐段统计得到：

| 段 | AW 地址 / AWLEN | AW 握手 | WLAST 接受 / 本段 W 拍数 | B 握手 | AR 握手 | RLAST 接受 / 本段 R 拍数 |
|---:|---|---:|---|---:|---:|---|
| 1 | `0x00180FF8 / 0x00` | 3242 ns | 3234 ns / 1 | 3266 ns | 8870 ns | 8878 ns / 1 |
| 2 | `0x00181000 / 0xFF` | 3286 ns | 5878 ns / 256 | 5994 ns | 8886 ns | 10934 ns / 256 |
| 3 | `0x00181800 / 0xFF` | 6014 ns | 8598 ns / 256 | 8722 ns | 10942 ns | 12990 ns / 256 |
| 4 | `0x00182000 / 0x06` | 8742 ns | 8810 ns / 7 | 8846 ns | 12998 ns | 13054 ns / 7 |

第一段从 `0x...0FF8` 到下一个 4 KiB 边界只剩 8 字节，所以必须为 1 拍；后两段各 256×8 字节，最后剩 7 拍，合计 **1+256+256+7=520**。`wleft` 在请求接受时为 520，第一、二、三次 B 后依次为 519、263、7；可分别在 3226、3266、5994、8722 ns 附近看。AW 13 次握手中跨 4 KiB 的段为 0。最后一次 B 握手 8846 ns 后 `fdma_wdone` 才拉高；前面三个 B 只是分段完成。读侧相同四段的 RLAST 值依次为 `{123,0}`、`{123,256}`、`{123,512}`、`{123,519}`，末值可在波形中看，全部 520 拍由测试台逐拍比较。`fdma_rvalid` 在这里是 `RVALID&&RREADY` 的接受脉冲，读数据线上停留的值不是自动多算一拍。

**4. 错误传播（13060–13316 ns）。** 13062 ns 测试台 `bus/inject_error=1`，把总线可见 `M_AXI_BRESP` 强制为 `2`（SLVERR）；这不是行为 RAM 自行报错，RAM 原始 `ram_bresp` 为 OKAY。最后一笔写地址为 `0x00200000`、16 拍，AW 在 13098 ns 握手，W 末拍在 13290 ns 接受。13306 ns `BVALID=1`，13310 ns B 握手后 `fdma_wdone=1` 且 `fdma_werror=1`。测试台以 `bad=1` 调用 `write_words`，明确要求该错误输出为 1；因此波形中的 `fdma_werror` 是**预期注错结果**，而不是此用例失败。最终 [axi/simulation.log](axi/simulation.log) 为 `TEST PASS`。本组 `fdma_wstrb/M_AXI_WSTRB` 固定 `0xFF`，部分字节写的证据在另一组 `axi_tail`，不能用本组证明。

## regs：AXI-Lite 写/读 → 命令锁存与边沿 → 完成清零/ACK

本组入口是 [regs_viewer.html](regs/regs_viewer.html)，对照 [INFO_EXCH.v](../../RTDS_test_DDR4_64bit.srcs/sources_1/new/INFO_EXCH.v) 的 `slv_reg_wren`、`CPU_WR_DONE/CPU_WR_DONE_d/CPU_WR_DONE_pos`、`CPU_REC_STATE`、`reg_data_out`，以及 [tb_rtds_regs.sv](../../regression/batch_1g/tb_rtds_regs.sv) 的 `wr/check`、`starts/acks` 计数。`bus/start` 是 DUT 的 `r_RD_START` 输出，`bus/ack` 是 `r_CPU_REC_STATE` 输出；顶层 `starts/acks` 是测试台采样计数，不是 DUT 寄存器。

| HTML 跳转范围 | 重点 |
|---|---|
| 30–126 ns | AXI-Lite AR/R 读出版本、参数与三个队头状态输入 |
| 128–190 ns | 地址/长度写入与第一次 `0x20` 启动，确认只出一拍 start |
| 194–270 ns | 忙时重复写 start、修改地址/长度尝试，读回旧值 |
| 272–314 ns | `done` 清掉忙位后第二次启动 |
| 330–406 ns | 两次有效 ACK 与一次 `WSTRB=E` 无效 ACK |

**1. 固定读回（30–126 ns）。** 地址 `0x00、0x04、0x08、0x30、0x34、0x38` 分别在 34、50、66、82、98、114 ns 拉高 ARVALID；随后的 ARREADY/`slv_reg_rden` 使 RDATA/RVALID 在 42、58、74、90、106、122 ns 有效，读值依次为 `0x2001、0x20260914、0x40000、1、7、9`。测试台 `check()` 对每个读值做严格比较。这里的 `0x30/34/38` 输入分别由测试台固定接 `RX_READY_BLOCKS=1`、`RX_HEAD_SEQ=7`、`RX_DROPPED_FRAMES=9`；波形证明 **INFO_EXCH 译码与读回**，不能说它同时证明了上面 ring 的实时队头已连进本模块。

**2. 首次启动（128–190 ns）。** 130 ns 对 `0x24` 发起写 `0x8000`，134 ns `AWREADY/WREADY/slv_reg_wren=1`，138 ns 写事务推进到 B 响应；`command_addr` 从复位起本来就是 `0x8000`，因此这次写相同值**没有数据线跳变**，不能因平直就说“没有写入”。146 ns 对 `0x28` 发起写 `16`，154 ns `command_len:0x8000→16`。162 ns 对 `0x20` 写 1，166 ns写握手条件成立，170 ns `CPU_WR_DONE:0→1` 且 `CPU_WR_DONE_pos/bus/start:0→1`，174 ns它们回 0，顶层 `starts:0→1`；186 ns读 `0x20` 得 1。`CPU_WR_DONE_d` 是延迟一拍的旧值，`CPU_WR_DONE_pos=CPU_WR_DONE[0] && !CPU_WR_DONE_d`，所以保持的忙位并不会每周期重启。

**3. 忙时重复提交（194–270 ns）。** 194 ns 第二次对 `0x20` 写 1，198 ns `slv_reg_wren=1`、202 ns事务结束，但 `CPU_WR_DONE` 已为 1，没有新的 `CPU_WR_DONE_pos/start`，`starts` 保持 1。210 ns 又向 `0x24` 写 `0x9000`，226 ns向 `0x28` 写 `32`；两次写握手均发生，但 RTL 的 `!CPU_WR_DONE[0]` 条件阻止命令参数更新。250/266 ns读回 `0x24/0x28` 仍为 `0x8000/16`。这一组证据同时排除“只因没有握手而未修改”的误判：握手有，拒绝更新来自忙位门控。

**4. 完成后重新启动（272–314 ns）。** 274 ns 测试台 `bus/done=1`，278 ns `CPU_WR_DONE:1→0`，282 ns延迟位 `CPU_WR_DONE_d` 也清零；290 ns读 `0x20` 得 0。随后新一笔 `0x20=1` 在 302 ns写条件成立，306 ns `CPU_WR_DONE`、`CPU_WR_DONE_pos` 和 `bus/start` 再次置 1，310 ns脉冲撤销且 `starts:1→2`。因此“忙时只启动一次”和“完成后允许下一次”在同一组波形内有正反两个对照。`done` 来自测试台模拟完成事件，不代表真实 FDMA 在这个短用例里完成了传输。

**5. ACK 字节使能（330–406 ns）。** 前两次 `0x14=1` 写分别在 334/366 ns有 `slv_reg_wren`，`bus/ack` 在 338–342 ns、370–374 ns各高一个周期；顶层 `acks` 在 342/374 ns变为 1/2，读回 `0x14` 在 354/386 ns均为 0。394 ns再发 `0x14=1`，但 `bus/wstrb=0xE`（二进制 `1110`，最低字节的使能 bit0=0）；398 ns仍有真实写握手，402 ns有 B 响应，却没有第三个 `bus/ack`，`acks` 到仿真结束仍是 2。源码将 ACK 条件写成 `slv_reg_wren && addr==0x14 && S_AXI_WSTRB[0] && S_AXI_WDATA[0]`，所以这个负例确实检验了 byte strobe，而不只是“没有发写命令”。最终 [regs/simulation.log](regs/simulation.log) 为 `TEST PASS`。

regs 本次 `BREADY/RREADY` 恒为 1，没有测试 AXI-Lite 主机在 B/R 通道长期反压；也没有读 `0x10` 来测试 read-to-clear。此处不要把 `clear_irq/clear_inter` 静止为 0 说成读清功能已覆盖。

## 证据边界和可重复复核

这三组的最强证据由三层构成：**VCD 上的实际时间/值**说明事件顺序；**RTL 条件**说明何种事件允许更新状态；**测试台检查和 PASS 日志**补上波形不适合逐字列出的记分板比较。PASS 表示这些激励和断言通过，不表示所有系统场景通过。信号列表与跳变次数见各组 `signals_summary.md`/`signals.csv`；VCD 的变化次数不是握手次数。若想看缺失于 VCD 的 ring 块长/序号数组，可在**本机 F 盘环境**用 `Open-LocalWave.ps1 -Case ring -Vivado` 打开 WDB；远端原生入口需要按 C 盘工程重新生成。

远端当前的 `rtl/rtds_rx_block_writer.v` 与生成 ring 波形时的源码快照 SHA-256 不同。同步前逐项核对过：模块接口、参数值及声明位宽一致，去掉注释和空白后的全部 `assign`/`always` 行为段完全相同；差异是中文注释、对齐和多变量声明拆行。这里保留远端现有 RTL，不用本机旧排版覆盖它。HTML 代码栏仍显示生成波形时嵌入的源码快照；在远端外部源码中搜索相同标识符即可对应，行号可能不同。

本说明使用的本地复核小工具是 [trace_probe.py](trace_probe.py)（按 ns 提取单信号跳变/快照）与 [axi_handshake_table.py](axi_handshake_table.py)（在上升沿前取样，枚举 AW/WLAST/B/AR/RLAST 并检查 AW/W 保持和 4 KiB 边界）。它们只读现有 VCD，不重跑仿真、不调用 Computer Use、不连接远程机。若后续重跑覆盖 VCD，应以新波形重新核对本文时间戳，不能直接沿用。
