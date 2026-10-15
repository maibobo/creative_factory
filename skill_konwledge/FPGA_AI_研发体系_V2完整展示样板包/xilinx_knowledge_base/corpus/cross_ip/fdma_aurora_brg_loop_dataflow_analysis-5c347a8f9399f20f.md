# fdma_aurora_brg_loop_dataflow_analysis

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\fdma_aurora_brg_loop_dataflow_analysis.md`
- SHA-256: `5c347a8f9399f20f701a85734f8477da0add350a5087e6a8e6529f0160d9f205`
- Extractor: `text`
- Tags: `aurora, dataflow, fdma, pcie`
- Duplicate sources:
  - none

# FDMA Aurora Bridge 环回验证数据流详细分析

## 1. 系统架构概述

本验证采用 GT 自环回架构，DUT 为 `fdma_aurora_brg_aurora_loop`，内部包含：
- `fdma_aurora_brg_top`：转换桥顶层，包含 TX 桥和 RX 桥
- `aurora_64b66b_top`：Aurora 64b66b 核，负责 64bit 数据的 66b 编码和 GT 串并转换

数据通路为：
```
FDMA 读从机(TB) → TX桥(DUT) → Aurora TX → GT TX → GT RX(自环回) → Aurora RX → RX桥(DUT) → FDMA 写从机(TB)
```

## 2. 时钟域说明

| 时钟 | 频率 | 周期 | 用途 |
|------|------|------|------|
| fdma_clk | 250MHz | 4ns | FDMA 接口、TX桥读状态机、RX桥写状态机 |
| user_clk | ~100MHz | ~10ns | Aurora 用户侧、TX桥Aurora发送引擎、RX桥Aurora接收引擎 |
| init_clk | 50MHz | 20ns | Aurora 核初始化时钟 |
| gt_ref_clk | 156.25MHz | 6.4ns | GT 参考时钟 |

## 3. 测试参数

| 参数 | 值 | 说明 |
|------|-----|------|
| NUM_FRAMES_TO_TEST | 3 | 测试帧数 |
| AURORA_FRAME_BYTES | 1536 | 每帧 1536 字节 = 3 个 burst |
| FDMA_BURST_LEN_BYTES | 512 | 每个 burst 512 字节 = 64 个 64bit word |
| BURST_WORDS | 64 | 每个 burst 64 个 word |
| FRAME_WORDS | 192 | 每帧 192 个 word |
| TEST_MEM_SIZE | 4KB | FDMA 地址空间 |
| 总 burst 数 | 9 | 3帧 × 3burst/帧 |
| 总 word 数 | 576 | 9burst × 64word/burst |

## 4. 详细时间线（基于仿真日志）

### 阶段 0：仿真启动与复位（0ns ~ 3200ns）

```
T=0ns:
  - fdma_clk 开始翻转（周期 4ns）
  - init_clk 开始翻转（周期 20ns）
  - gt_ref_clk 开始翻转（周期 6.4ns）
  - sys_rst = 1, fdma_rstn = 0
  - TB 主 initial 块启动：
    → wr_if.wbusy <= 0, wr_if.wready <= 0
    → rd_if.rbusy <= 0, rd_if.rvalid <= 0
  - TB 从机 initial 块启动：
    → fork fdma_read_slave() 和 fdma_write_slave()
    → 读从机进入 forever 循环，等待 rareq && !rbusy
    → 写从机进入 forever 循环，等待 wareq && !wbusy
  - DUT 内部：
    → Aurora 核开始初始化（GT PLL 锁定、通道对齐）
    → TX桥读状态机：rd_state = RD_IDLE
    → RX桥写状态机：wr_state = WR_IDLE

T=3200ns (160个init_clk周期后):
  - sys_rst = 0（Aurora 核复位释放）
  - fdma_rstn = 1（FDMA 逻辑复位释放，延迟60ns确保稳定）
```

### 阶段 1：Aurora 通道建立（3200ns ~ 29100ns）

```
T=3200ns ~ 29099000ns:
  - Aurora 核执行 GT PLL 锁定、速率匹配、通道初始化
  - 此过程约需 29ms（Aurora 64b66b 标准初始化时间）
  - 期间 channel_up = 0, lane_up = 0
  - TX桥：rd_state 保持 RD_IDLE（因为 channel_up_fdma = 0）
  - RX桥：wr_state 保持 WR_IDLE（因为 channel_up_fdma = 0）
  - 读从机：持续等待 rareq（不会到来）
  - 写从机：持续等待 wareq（不会到来）

T=29099000ns:
  - Aurora 核完成初始化，channel_up 拉高
  - channel_up_fdma（同步到 fdma_clk 域）随后拉高
  - TB 主 initial 检测到 channel_up == 1，打印 "[29099000] channel_up == 1"
```

### 阶段 2：测试数据准备（29100ns ~ 34064ns）

```
T=29099000ns:
  - TB 主 initial 等待 800 个 user_clk 周期（约 8000ns）
  - 目的：等待 Aurora 通道完全稳定，避免初始传输错误

T≈29122000ns:
  - TX桥读状态机检测到 channel_up_fdma = 1 且 TX FIFO 非满
  - rd_state: RD_IDLE → RD_REQ
  - fdma_rareq 拉高（rd_state == RD_REQ && !fdma_rbusy）
  - 读从机检测到 rareq = 1 && rbusy = 0
  - 打印 "[29122000] RD_SLAVE: Burst 0 request received, raddr=0x0"
  - 但此时 read_burst_queue 尚未填充！
  - 【关键】读从机阻塞在 wait(read_burst_queue.size() > 0)
    读从机已拉高 rbusy=1，等待 read_burst_queue 有数据后才能继续
  - TX桥检测到 rbusy=1，rd_state: RD_REQ → RD_DATA
  - 但 rvalid=0（读从机还没发数据），TX桥等待 rvalid

T=34064000ns:
  - TB 主 initial 完成 800 周期等待
  - 打印 "[34064000] Start sending test data (WITH backpressure)..."
  - 开始填充 read_burst_queue：
    for (f=0; f<3; f++)       // 3帧
      for (b=0; b<3; b++)     // 每帧3个burst
        push 64个word到read_burst_queue
    → 共 9 个 burst，576 个 word
  - 数据格式：word = (frame_id << 32) | word_index
    帧0: 0x0000000000000000, 0x0000000000000001, ..., 0x00000000000000BF
    帧1: 0x0000000100000000, 0x0000000100000001, ..., 0x00000001000000BF
    帧2: 0x0000000200000000, 0x0000000200000001, ..., 0x00000002000000BF
  - 打印 "[34064000] read_burst_queue aleady be established..."
  - 读从机从 wait 中唤醒，取出 burst 0 的数据，开始发送
```

### 阶段 3：FDMA 读通路 - 数据从读从机流向 TX 桥（34100ns ~ 37650ns）

#### 3.1 Burst 0 详细流程

```
T=29122000ns:
  读从机（fdma_read_slave）检测到 Burst 0 请求:
  1. rareq=1 && rbusy=0 → 打印 "RD_SLAVE: Burst 0 request received, raddr=0x0"
  2. 30%概率插入突发间延迟
  3. rd_if.rbusy <= 1（通过 clocking block 驱动）
  4. wait(read_burst_queue.size() > 0) → 阻塞！队列此时为空

T=34064000ns:
  read_burst_queue 填充完成，读从机从 wait 唤醒:
  5. 从 read_burst_queue 弹出 burst_data[0]
  6. 开始逐 word 发送：
     for (i=0; i<64; i++):
       a. 20%概率插入突发内延迟（拉低 rvalid 1~4周期）
       b. rd_if.rdata <= burst_data[i]
       c. rd_if.rvalid <= 1
       d. 等待 AXI 握手：rvalid && rready
          rready 由 DUT TX桥驱动 = ~fifo_almost_full
       e. 握手成功后：fdma_rd_data_queue.push_back(burst_data[i])

  TX桥（fdma_aurora_brg_tx）处理读请求:
  1. rd_state: RD_REQ → RD_DATA（当 fdma_rbusy=1，已在29122us发生）
  2. fdma_rareq 拉低（fdma_rareq && fdma_rbusy → rareq=0）
  3. fifo_wr_en = (rd_state_nxt==RD_DATA) && fdma_rvalid && fdma_rready
     → 当 rvalid && rready 同时为高时，数据写入 TX FIFO
  4. rd_word_cnt 在每次 rvalid 时递增（0→1→2→...→63）
  5. rd_burst_done = (rd_state==RD_DATA) && fdma_rvalid && (rd_word_cnt==63)
     → rd_state: RD_DATA → RD_WAIT

T=34446000ns:
  读从机 Burst 0 完成:
  - 打印 "RD_SLAVE: Burst 0 done, sent 64 words, rd_queue_size=64, remaining_bursts=8"
  - rd_if.rvalid <= 0
  - rd_if.rbusy <= 0

  TX桥:
  - rd_state: RD_DATA → RD_WAIT（等待 rbusy 拉低）
  - 检测到 fdma_rbusy=0 后：RD_WAIT → RD_IDLE
  - rd_addr 更新：0x0 → 0x200（+512字节）
```

#### 3.2 Burst 1~8 流程（类似 Burst 0，读从机与写从机交错进行）

```
T=34470000ns: RD_SLAVE: Burst 1 request received, raddr=0x200
T=34886000ns: RD_SLAVE: Burst 1 done, rd_queue_size=128, remaining_bursts=7
T=34910000ns: RD_SLAVE: Burst 2 request received, raddr=0x400
T=35238000ns: RD_SLAVE: Burst 2 done, rd_queue_size=192, remaining_bursts=6
T=35262000ns: RD_SLAVE: Burst 3 request received, raddr=0x600
T=35570000ns: RD_SLAVE: Burst 3 done, rd_queue_size=256, remaining_bursts=5
T=35594000ns: RD_SLAVE: Burst 4 request received, raddr=0x800
T=35978000ns: RD_SLAVE: Burst 4 done, rd_queue_size=320, remaining_bursts=4
T=36002000ns: RD_SLAVE: Burst 5 request received, raddr=0xa00
T=36378000ns: RD_SLAVE: Burst 5 done, rd_queue_size=384, remaining_bursts=3
T=36402000ns: RD_SLAVE: Burst 6 request received, raddr=0xc00
T=36802000ns: RD_SLAVE: Burst 6 done, rd_queue_size=448, remaining_bursts=2
T=36826000ns: RD_SLAVE: Burst 7 request received, raddr=0xe00
T=37258000ns: RD_SLAVE: Burst 7 done, rd_queue_size=512, remaining_bursts=1
T=37282000ns: RD_SLAVE: Burst 8 request received, raddr=0x0（地址回绕，0xE00+512=0x1000 >= TEST_MEM_SIZE）
T=37658000ns: RD_SLAVE: Burst 8 done, rd_queue_size=576, remaining_bursts=0
T=37658000ns: All FDMA read data sent, rd_queue_size=576.

注意：
  - Burst 8 的地址从 0xE00+512=0x1000 >= TEST_MEM_SIZE(0x1000)，所以回绕到 0x0
  - 读从机完成全部 9 个 burst 后，TX桥继续请求第 10 个 burst
  - T=37682000ns: RD_SLAVE: Burst 9 request received, raddr=0x200
  - 读从机阻塞在 wait(read_burst_queue.size() > 0)，因为队列已空
  - 【死锁点】TX桥无限循环，读从机无数据可发
```

### 阶段 4：Aurora LL 传输 - 数据从 TX 桥经 Aurora 核到 RX 桥

#### 4.1 TX 桥 Aurora 发送引擎（user_clk 域）

```
TX桥 Aurora 发送引擎状态机：
  TX_IDLE → TX_SOF → TX_DATA → TX_IDLE（循环）

时序（与 FDMA 读引擎并行执行）:

当 TX FIFO 中有数据（~fifo_almost_empty）且 channel_up=1:
  1. tx_state: TX_IDLE → TX_SOF
  2. TX_SOF 状态：
     - tx_sof = 1（帧起始标志）
     - tx_src_rdy = 1
     - tx_d = fifo_rdata（FIFO 读出的第一个 word）
     - tx_rem = 3'b111（8字节有效）
     - 等待 tx_dst_rdy = 1（Aurora 核准备好接收）
     - 当 tx_sof && fifo_rd_en 有效时：tx_word_cnt <= 1
  3. TX_DATA 状态：
     - tx_sof = 0
     - tx_src_rdy = 1 && fifo_rd_en
     - tx_d = fifo_rdata
     - 每次有效传输：tx_word_cnt++
     - 当 tx_word_cnt == FRAME_WORDS-1(191) 且 tx_dst_rdy=1：
       → tx_eof = 1（帧结束标志）
       → wr_burst_done = 1
       → tx_state: TX_DATA → TX_IDLE
       → frame_cnt++
     - 一帧传输 192 个 word（3个burst的数据量）

FIFO 读使能：
  fifo_rd_en = (tx_state != TX_IDLE) && (~fifo_empty) && tx_dst_rdy

LL TX 数据采集（TB 监控）:
  当 aurora_tx_src_rdy && aurora_tx_dst_rdy 时：
    ll_tx_data_queue.push_back(aurora_tx_d)
  → 记录 TX 桥发出的每一个 word
```

#### 4.2 Aurora 核内部传输

```
Aurora 64b66b 核处理流程:
  1. TX 侧：
     - 接收 tx_d[63:0]、tx_sof、tx_eof、tx_src_rdy
     - 64b→66b 编码（加 2bit 同步头）
     - 通过 GT TX 串行发送
  2. GT 自环回：
     - TXP/TXN → RXP/RXN（外部连线短接）
     - 串行数据从发送端直接到接收端
  3. RX 侧：
     - GT RX 接收串行数据
     - 66b→64b 解码
     - 输出 rx_d[63:0]、rx_sof、rx_eof、rx_src_rdy
     - 通道对齐后：channel_up = 1

传输延迟：
  - GT 串并转换延迟：约 20~30 个 user_clk 周期
  - Aurora 协议层延迟：约 5~10 个 user_clk 周期
  - 总延迟：约 25~40 个 user_clk 周期（~250~400ns）
```

#### 4.3 RX 桥 Aurora 接收（user_clk 域）

```
RX桥 Aurora 接收逻辑:
  - rx_dst_rdy = 1（恒为1，不能反压 Aurora RX）
  - 当 rx_src_rdy = 1 时：
    fifo_wr_en = rx_src_rdy && !fifo_full
    fifo_wdata = rx_d
    → 数据写入 RX FIFO

  - RX FIFO 参数：
    深度：2048（远大于一帧的 192 word，可缓冲多帧数据）
    写时钟：user_clk
    读时钟：fdma_clk
    模式：FWFT（First Word Fall Through，读延迟为0）

  - FIFO 写保护：
    当 fifo_full=1 时丢弃数据（fifo_wr_en = rx_src_rdy && !fifo_full）
    → 正常情况下不会满（RX桥写状态机会及时读走数据）

LL RX 数据采集（TB 监控）:
  当 aurora_rx_src_rdy && aurora_rx_dst_rdy 时：
    ll_rx_data_queue.push_back(aurora_rx_d)
  → 记录 RX 桥收到的每一个 word
```

### 阶段 5：FDMA 写通路 - 数据从 RX 桥流向写从机（34500ns ~ 39400ns）

#### 5.1 RX 桥写状态机（fdma_clk 域）

```
RX桥写状态机：
  WR_IDLE → WR_REQ → WR_DATA → WR_WAIT → WR_IDLE（循环）

时序:

当 RX FIFO 非空且 channel_up_fdma=1:
  1. wr_state: WR_IDLE → WR_REQ
  2. WR_REQ 状态：
     - fdma_wareq 拉高（wr_state==WR_REQ && !fdma_wbusy）
     - 等待写从机响应：fdma_wbusy=1
     - wr_state: WR_REQ → WR_DATA
     - fdma_wareq 拉低（fdma_wareq && fdma_wbusy → wareq=0）
  3. WR_DATA 状态：
     - AXI-like 写数据握手：
       fifo_rd_en = (wr_state==WR_DATA) && fdma_wbusy && !wdata_hold_valid && !fifo_empty
       → 从 FIFO 预取数据到 wdata_hold
       fdma_wvalid = wdata_hold_valid && (wr_state==WR_DATA) && fdma_wbusy
       fdma_wdata = wdata_hold
       w_hs = fdma_wvalid && fdma_wready
       → 当 wvalid && wready 时，数据传输完成
     - wr_word_cnt 在每次 w_hs 时递增（0→1→2→...→63）
     - wr_burst_done = (wr_state==WR_DATA) && w_hs && (wr_word_cnt==63)
       → wr_state: WR_DATA → WR_WAIT
  4. WR_WAIT 状态：
     - 等待 fdma_wbusy 拉低
     - wr_state: WR_WAIT → WR_IDLE
     - wr_addr 更新（+512字节，到达 TEST_MEM_SIZE 边界时回绕到 0）
```

#### 5.2 写从机处理流程（fdma_clk 域）

```
写从机（fdma_write_slave）处理每个 burst:

1. 检测到 wareq=1 && wbusy=0
2. 打印 "WR_SLAVE: Burst N request received, waddr=0x..., wsize=512"
3. 30%概率插入突发间延迟（1~8个fdma_clk周期）
4. wr_if.wbusy <= 1（响应请求）
5. wr_if.wready <= 1（默认准备好接收）
6. 逐 word 接收：
   for (i=0; i<num_words; i++):
     a. 20%概率拉低 wready 1~4周期（突发内反压）
     b. 等待 AXI 握手：wvalid && wready
     c. 握手成功后：fdma_wr_data_queue.push_back(wr_if.wdata)
7. 打印 "WR_SLAVE: Burst N done, received 64 words, wr_queue_size=..."
8. wr_if.wbusy <= 0
9. wr_if.wready <= 0
```

#### 5.3 写从机详细日志

```
T=34506000ns: WR_SLAVE: Burst 0 request received, waddr=0x0, wsize=512
T=35130000ns: WR_SLAVE: Burst 0 done, wr_queue_size=64
T=35154000ns: WR_SLAVE: Burst 1 request received, waddr=0x200, wsize=512
T=35726000ns: WR_SLAVE: Burst 1 done, wr_queue_size=128
T=35750000ns: WR_SLAVE: Burst 2 request received, waddr=0x400, wsize=512
T=36342000ns: WR_SLAVE: Burst 2 done, wr_queue_size=192
T=36366000ns: WR_SLAVE: Burst 3 request received, waddr=0x600, wsize=512
T=36938000ns: WR_SLAVE: Burst 3 done, wr_queue_size=256
T=36962000ns: WR_SLAVE: Burst 4 request received, waddr=0x800, wsize=512
T=37594000ns: WR_SLAVE: Burst 4 done, wr_queue_size=320
T=37618000ns: WR_SLAVE: Burst 5 request received, waddr=0xa00, wsize=512
T=38166000ns: WR_SLAVE: Burst 5 done, wr_queue_size=384
T=38190000ns: WR_SLAVE: Burst 6 request received, waddr=0xc00, wsize=512
T=38774000ns: WR_SLAVE: Burst 6 done, wr_queue_size=448
T=38798000ns: WR_SLAVE: Burst 7 request received, waddr=0xe00, wsize=512
T=39438000ns: WR_SLAVE: Burst 7 done, wr_queue_size=512
T=39462000ns: WR_SLAVE: Burst 8 request received, waddr=0x0, wsize=512
（Burst 8 未完成 → 仿真超时）

写从机与读从机的时间差分析：
  - 读从机 Burst 0 完成于 34446us，写从机 Burst 0 完成于 35130us
  - 延迟 ≈ 684us，包含：Aurora 传输延迟 + RX FIFO 缓冲 + RX桥写状态机处理
  - 每个写 burst 比对应读 burst 晚约 5~7us 完成
```

### 阶段 6：仿真超时与数据统计

#### 6.1 超时现象

```
T=110000000ns (110us):
  - 仿真超时，打印 "ERROR: Simulation timeout!"
  - 最终数据统计：
    DUT: channel_up=1, lane_up=1
    LL TX: 572, LL RX: 569
    FDMA RD: 576, FDMA WR: 569

  - FDMA RD = 576（全部9个burst的576个word已发送完毕）
  - FDMA WR = 569（还差7个word未收到）
  - LL TX = 572（572个word已通过Aurora LL发送）
  - LL RX = 569（569个word已通过Aurora LL接收）

  数据差距分析：
    576(FDMA RD) - 572(LL TX) = 4 words → 仍在TX FIFO或Aurora TX管道中
    572(LL TX) - 569(LL RX) = 3 words → 仍在Aurora RX管道中
    576(FDMA RD) - 569(FDMA WR) = 7 words → 端到端未完成传输
```

#### 6.2 超时根因分析

```
死锁链条：

1. TX桥读状态机是无限循环的（没有帧数限制）
   → 9个burst完成后，继续请求第10个burst
   → T=37682000ns: RD_SLAVE: Burst 9 request received, raddr=0x200

2. 读从机 read_burst_queue 已空
   → wait(read_burst_queue.size() > 0) 永远阻塞
   → 读从机进程卡死，不再响应任何请求
   → rbusy 保持为 0（Burst 8 完成后已释放）

3. TX桥卡在 RD_REQ 状态
   → fdma_rareq=1，等待 rbusy=1（永远不会来）
   → TX桥的 FDMA 读引擎停止工作
   → 但 Aurora TX 引擎仍可独立运行（从 TX FIFO 读取已有数据）

4. Aurora TX 引擎继续发送 TX FIFO 中的剩余数据
   → 但 TX FIFO 只有 4 个 word 未发送（576-572=4）
   → 4 < PROG_EMPTY_THRESH(10)，fifo_almost_empty 仍为高
   → Aurora TX 引擎在 TX_IDLE 状态等待 ~fifo_almost_empty
   → 【关键】如果剩余 4 个 word 不足以触发 ~fifo_almost_empty，
     Aurora TX 引擎不会启动新帧发送！
   → 这 4 个 word 永远留在 TX FIFO 中

5. RX桥收不到新数据
   → Aurora RX 无新数据输出
   → RX FIFO 逐渐被读空
   → 写从机 Burst 8 只收到 57 个 word（569-512=57），还差 7 个
   → 写从机等待 wvalid，但 RX FIFO 已空，wvalid=0
   → 写从机卡死

6. TB wait 条件无法满足
   → wait(fdma_wr_data_queue.size() >= 576) 永远等不到
   → 仿真超时
```

#### 6.3 比对策略

```
两个独立比对：

Comparison 1: LL 层比对（Aurora 传输正确性）
  ll_tx_data_queue vs ll_rx_data_queue
  → 验证 Aurora 核的 GT 自环回传输是否正确
  → 如果 LL 层比对失败，说明 Aurora 传输有问题

Comparison 2: FDMA 层比对（端到端正确性）
  fdma_rd_data_queue vs fdma_wr_data_queue
  → 验证从 FDMA 读 → TX桥 → Aurora → RX桥 → FDMA 写 的完整通路
  → 如果 FDMA 层比对失败但 LL 层通过，说明 TX/RX 桥逻辑有问题
```

#### 6.2 比对流程

```
1. 等待条件满足（FDMA RD 和 WR 队列都达到 576 words）
2. 额外等待 1000 个 fdma_clk 周期 + 100ns（确保所有数据传输完成）
3. 执行 compare_ll_data():
   a. 打印队列长度
   b. 取 min(tx_size, rx_size) 作为比对范围
   c. 逐 word 比较：
      - 匹配：继续
      - 不匹配：打印错误信息，ll_error_count++
   d. 如果长度不等，打印 NOTE
   e. 打印 PASS/FAIL 总结
4. 执行 compare_fdma_data():
   a. 打印队列长度
   b. 取 min(rd_size, wr_size) 作为比对范围
   c. 逐 word 比较：
      - 匹配：继续
      - 不匹配：打印错误信息，fdma_error_count++
   d. 如果长度不等，打印 NOTE
   e. 打印 PASS/FAIL 总结
5. 打印反压测试总结（RX FIFO overflow 事件数）
6. $finish 结束仿真
```

## 5. 关键信号时序关系

### 5.1 FDMA 读通路握手时序

```
fdma_clk  ──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──
            └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘

rd_state   ◄── RD_IDLE ──► RD_REQ ──► RD_DATA ──► RD_WAIT ──► RD_IDLE

fdma_rareq ◄────────────────┐                    ┌──────────────
                            └────────────────────┘

fdma_rbusy ◄──────────────────────┐              ┌──────────────
                                  └──────────────┘

fdma_rvalid◄────────────────────────────┐ ┐ ┐ ┐ ┐
                                        └─┘─┘─┘─┘  (64个word)

fdma_rready◄───────────────────────────────────────────────────
             (由TX桥驱动 = ~fifo_almost_full，通常为1)

fifo_wr_en ◄────────────────────────────┐ ┐ ┐ ┐ ┐
                                        └─┘─┘─┘─┘  (与rvalid&&rready对齐)
```

### 5.2 FDMA 写通路握手时序

```
fdma_clk  ──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──
            └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘

wr_state   ◄── WR_IDLE ──► WR_REQ ──► WR_DATA ──► WR_WAIT ──► WR_IDLE

fdma_wareq ◄────────────────┐                    ┌──────────────
                            └────────────────────┘

fdma_wbusy ◄──────────────────────┐              ┌──────────────
                                  └──────────────┘

fifo_rd_en ◄──────────────────────────┐     ┐     ┐
                                      └─────┘─────┘  (预取到wdata_hold)

fdma_wvalid◄──────────────────────────┐  ┐  ┐  ┐  ┐
                                      └──┘──┘──┘──┘  (wdata_hold_valid)

fdma_wready◄──────────────────────────┐  ┌──┐  ┌──┐
                                      └──┘  └──┘     (从机随机反压)

w_hs      ◄──────────────────────────┐   ┐   ┐   ┐
                                      └───┘───┘───┘  (wvalid&&wready)
```

### 5.3 Aurora LL 传输时序

```
user_clk  ──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──
            └──┘  └──┘  └──┘  └──┘  └──┘  └──┘  └──┘

tx_state   ◄── TX_IDLE ──► TX_SOF ──► TX_DATA(192拍) ──► TX_IDLE

tx_sof     ◄─────────────────┐
                              └──────────────────────────────

tx_eof     ◄──────────────────────────────────────────┐
                                                       └──

tx_src_rdy ◄─────────────────────────────────────────────
             (TX_SOF和TX_DATA期间持续为1，受fifo_rd_en门控)

tx_dst_rdy ◄─────────────────────────────────────────────
             (Aurora核准备好接收，通常为1)

fifo_rd_en ◄──────────────────┐ ┐ ┐ ... ┐ ┐
                              └─┘─┘     └─┘  (192次FIFO读取)
```

## 6. 数据队列收纳详解

### 6.1 read_burst_queue（TB 激励队列）

```
填充时机：channel_up 后 800 个 user_clk 周期
填充内容：9 个 burst，每个 burst 64 个 word
数据格式：word = (frame_id << 32) | word_index

Burst 0: [0x0000000000000000, 0x0000000000000001, ..., 0x000000000000003F]  ← 帧0, burst0
Burst 1: [0x0000000000000040, 0x0000000000000041, ..., 0x000000000000007F]  ← 帧0, burst1
Burst 2: [0x0000000000000080, 0x0000000000000081, ..., 0x00000000000000BF]  ← 帧0, burst2
Burst 3: [0x0000000100000000, 0x0000000100000001, ..., 0x000000010000003F]  ← 帧1, burst0
Burst 4: [0x0000000100000040, 0x0000000100000041, ..., 0x000000010000007F]  ← 帧1, burst1
Burst 5: [0x0000000100000080, 0x0000000100000081, ..., 0x00000001000000BF]  ← 帧1, burst2
Burst 6: [0x0000000200000000, 0x0000000200000001, ..., 0x000000020000003F]  ← 帧2, burst0
Burst 7: [0x0000000200000040, 0x0000000200000041, ..., 0x000000020000007F]  ← 帧2, burst1
Burst 8: [0x0000000200000080, 0x0000000200000081, ..., 0x00000002000000BF]  ← 帧2, burst2

消费方式：读从机 pop_front() 取出每个 burst 数据
```

### 6.2 fdma_rd_data_queue（FDMA 读从机记录）

```
填充时机：读从机每次 AXI 握手成功后 push_back
填充内容：与 read_burst_queue 完全相同的数据（按发送顺序）
预期大小：576 words（9 bursts × 64 words/burst）

用途：作为 FDMA 层比对的"期望值"（发送了什么数据）
```

### 6.3 ll_tx_data_queue（Aurora LL TX 监控）

```
填充时机：user_clk 域，当 aurora_tx_src_rdy && aurora_tx_dst_rdy 时 push_back
填充内容：TX 桥通过 Aurora LL 发出的数据
预期大小：约 576 words（可能因 Aurora 核内部帧而略有差异）

注意：
  - 此队列在 user_clk 域填充，与 fdma_clk 域的队列异步
  - Aurora 核可能在 channel_up 后产生少量内部管理帧
  - 队列大小可能略大于 576（包含 Aurora 核的额外数据）

用途：作为 LL 层比对的"发送值"
```

### 6.4 ll_rx_data_queue（Aurora LL RX 监控）

```
填充时机：user_clk 域，当 aurora_rx_src_rdy && aurora_rx_dst_rdy 时 push_back
填充内容：RX 桥通过 Aurora LL 收到的数据
预期大小：约 576 words（可能因 Aurora 核内部帧而略有差异）

注意：
  - 此队列在 user_clk 域填充
  - 正常情况下 ll_rx_data_queue 应为 ll_tx_data_queue 的子集
  - 大小可能略小于 ll_tx_data_queue（最后几个 word 可能还在 Aurora 管道中）

用途：作为 LL 层比对的"接收值"
```

### 6.5 fdma_wr_data_queue（FDMA 写从机记录）

```
填充时机：写从机每次 AXI 握手成功后 push_back
填充内容：RX 桥通过 FDMA 写接口发送的数据
预期大小：576 words（9 bursts × 64 words/burst）

用途：作为 FDMA 层比对的"实际值"（接收到了什么数据）
```

## 7. 反压机制详解

### 7.1 FDMA 读从机反压

```
突发间反压（Burst Inter-backpressure）:
  - 触发条件：30% 概率
  - 表现：在响应 rareq 后，延迟 1~8 个 fdma_clk 周期才拉高 rbusy
  - 影响：TX桥在 RD_REQ 状态多等待几个周期
  - 不会丢数据：rbusy=0 期间 TX桥不会发 rvalid

突发内反压（Burst Intra-backpressure）:
  - 触发条件：20% 概率
  - 表现：在突发传输中，拉低 rvalid 1~4 个周期
  - 影响：TX桥的 fifo_wr_en 暂停，数据传输速度降低
  - 不会丢数据：rvalid=0 期间不传输数据，只是暂停
```

### 7.2 FDMA 写从机反压

```
突发间反压（Burst Inter-backpressure）:
  - 触发条件：30% 概率
  - 表现：在响应 wareq 后，延迟 1~8 个 fdma_clk 周期才拉高 wbusy
  - 影响：RX桥在 WR_REQ 状态多等待几个周期
  - 不会丢数据：wbusy=0 期间 RX桥不会发 wvalid

突发内反压（Burst Intra-backpressure）:
  - 触发条件：20% 概率
  - 表现：在突发传输中，拉低 wready 1~4 个周期
  - 影响：RX桥的 wdata_hold_valid 保持为1，FIFO 读取暂停
  - 不会丢数据：wready=0 时数据保持在 wdata_hold 中
  - 带宽影响：当前 wdata_hold_valid 方式下，反压期间无法预取下一个 word
```

### 7.3 FIFO 缓冲

```
TX FIFO（fdma_aurora_brg_tx）:
  - 深度：512 entries
  - 写端：fdma_clk 域（FDMA 读数据写入）
  - 读端：user_clk 域（Aurora LL 发送读取）
  - 反压：fifo_almost_full 时 fdma_rready=0，阻止 FDMA 继续写入
  - 缓冲能力：可缓冲 8 个 burst（512/64=8），即约 2.67 帧

RX FIFO（fdma_aurora_brg_rx）:
  - 深度：2048 entries
  - 写端：user_clk 域（Aurora LL 接收写入）
  - 读端：fdma_clk 域（FDMA 写数据读取）
  - 反压：rx_dst_rdy=1（恒为1，不能反压 Aurora RX）
  - 缓冲能力：可缓冲 32 个 burst（2048/64=32），即约 10.67 帧
  - 溢出保护：fifo_full 时丢弃数据（正常不应发生）
```

## 8. 已知问题与待修复项

### 8.1 TX 桥无限循环导致死锁（核心问题）

TX 桥读状态机没有帧数限制，会持续发起读请求。当 read_burst_queue 为空后：

```
死锁路径：
  TX桥 RD_REQ → 读从机 wait(queue.size()>0) 阻塞 → rbusy 永远不拉高
  → TX桥卡在 RD_REQ → 无新数据进入 TX FIFO
  → Aurora TX 引擎发完已有数据后停止
  → RX桥收不到数据 → 写从机卡在等待 wvalid
  → 仿真超时

修复方案（二选一）：
  方案A：TX桥添加帧数/burst数限制，发完指定数量后停止
  方案B：读从机在队列为空时拒绝请求（rbusy保持0），TX桥在RD_REQ超时后停止
```

### 8.2 TX FIFO almost_empty 阈值问题

TX FIFO 的 `PROG_EMPTY_THRESH=10`，Aurora TX 引擎在 `TX_IDLE` 状态等待 `~fifo_almost_empty` 才启动新帧。如果最后一个帧的数据量不足以填满到阈值以上，剩余数据会永远留在 FIFO 中。

```
当前情况：
  - 576 words 全部写入 TX FIFO
  - Aurora TX 发送了 572 words（2个完整帧 + 第3帧的188个word）
  - 剩余 4 words 在 TX FIFO 中
  - 4 < PROG_EMPTY_THRESH(10) → fifo_almost_empty 仍为高
  - Aurora TX 不会启动新帧 → 4 words 永远留在 FIFO

修复方案：
  - 将 TX_IDLE 的启动条件从 ~fifo_almost_empty 改为 ~fifo_empty
  - 或者降低 PROG_EMPTY_THRESH 阈值
  - 或者支持发送不完整帧（最后一帧可能不足192个word）
```

### 8.3 wdata_hold_valid 带宽限制

当前 RX 桥使用 wdata_hold_valid 方式实现 AXI 握手：
- 无反压时：每个 word 至少需要 2 拍（1拍预取 + 1拍握手）
- 带宽减半
- 建议改为 Skid Buffer 方案：无反压时直通（1拍/word），有反压时暂存

### 8.4 LL 队列大小不一致

ll_tx_data_queue 和 ll_rx_data_queue 的大小可能不完全相等：
- 原因：Aurora 核内部可能产生额外数据帧；数据仍在管道中
- 影响：LL 层比对时取 min(tx_size, rx_size)，不影响正确性
- 但不能作为仿真完成的判断条件
