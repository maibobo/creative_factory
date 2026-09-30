# new 目录运行流程与文件块级解读

<!-- 文档导读：本文是对 new 目录 RTL、testbench 和说明文件的总览，重点说明仿真模式与硬件模式两条运行链路，并精确列出各文件的 module/interface/task/always 等关键块。 -->

- 目录：`E:\gpt_doc\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new`
- 生成时间：2026/6/24 13:03:10
- 说明：当前 `new` 目录没有发现 `class` 块；验证代码主要使用 `package/interface/task/initial/always` 和队列式 scoreboard。
- 注释策略：所有 `.v/.sv` 已补充 `// ...`，两份既有 `.md` 已补充 `<!-- ... -->` 标题导读。

## 1. 两个主运行模式

<!-- 本节先从运行入口讲清楚代码如何动起来，再进入每个子文件。 -->

### 1.1 仿真模式：SIMULATION=1，Vivado/XSim 行为仿真

仿真模式的典型入口是 `tb_fdma_aurora_brg_aurora_loop_nobp.sv` 或 `tb_fdma_aurora_brg_aurora_loop_bp.sv`。这两个 testbench 都会例化 `fdma_aurora_brg_aurora_loop`，并把参数 `SIMULATION` 置为 1，用于加快 Aurora IP 初始化。

运行流程：

1. testbench 产生 fdma_clk、init_clk、gt_ref_clk_n/gt_ref_clk_p，并释放 sys_rst/fdma_rstn。
2. testbench 将 TXP/TXN 回接到 RXP/RXN，形成 GT 自环；Aurora IP 初始化后拉高 channel_up/lane_up。
3. fdma_aurora_brg_top 内部先用 cdc_sync 把 channel_up 同步到 fdma_clk。
4. TX 方向：fdma_aurora_brg_tx 的 FDMA 读状态机发起 fdma_rareq，读 BFM 响应 rbusy/rvalid/rdata，数据写入异步 FIFO。
5. TX user_clk 域从 FIFO 读出数据，生成 tx_sof/tx_eof/tx_rem/tx_src_rdy，送入 aurora_64b66b_top。
6. Aurora/GT 自环后，RX LocalLink 数据回到 fdma_aurora_brg_rx，先写入 RX 异步 FIFO。
7. RX FDMA 域按 512B burst 发起 fdma_wareq，在 wbusy/wready 握手时输出 fdma_wdata/fdma_wvalid。
8. scoreboard 分两层比对：LocalLink TX vs RX，以及 FDMA read BFM 送出的数据 vs FDMA write BFM 收到的数据。

仿真模式下又分两个验证场景：

- NOBP：`tb_fdma_aurora_brg_aurora_loop_nobp.sv`，FDMA 从机基本立即响应，先确认主链路无丢字、无错序。
- BP：`tb_fdma_aurora_brg_aurora_loop_bp.sv`，读写 BFM 随机插入 burst 接受延迟和 burst 内停顿，用来压 FIFO 水位、握手保持和排空逻辑。

### 1.2 硬件模式：SIMULATION=0，板级自测/ILA 调试

硬件模式的入口是 `fdma_aurora_brg_aurora_loop_hw.v`。它把 `fdma_aurora_brg_aurora_loop` 的 `SIMULATION` 置为 0、`DEBUG_ENABLE` 置为 1，并在外层加入板级时钟、VIO 控制、硬件自测引擎和 ILA。

运行流程：

1. clk_wiz_1 从板级差分时钟产生 clk_init 和 fdma_clk，locked 作为全局复位依据。
2. fdma_reset_sync 在 fdma_clk 域同步释放 fdma_rstn，减少复位释放亚稳风险。
3. VIO 输出 test_start/test_clear/auto_enable/frame_limit，用于手动或自动启动板上测试。
4. fdma_hw_test_engine 充当可综合 FDMA 从机：读侧按地址/计数生成确定性数据，写侧检查 DUT 写回数据。
5. fdma_aurora_brg_aurora_loop 连接真实 Aurora IP 和 GT 引脚，SFP 控制脚保持发送使能/速率选择。
6. ila_brg_loop 把 FDMA 状态、user_clk 域帧信号、硬件自测结果码和首个错误值接入 ILA，便于上板抓波形。
7. 测试结束后观察 test_done/test_pass/test_result_code/error_count/first_error_*，判断链路通过、超时、链路掉线还是数据不一致。

## 2. 顶层数据流

<!-- 本节把 TX/RX 两半桥串起来看，帮助定位数据在哪个边界变化。 -->

数据从 FDMA 读侧进入，再经 Aurora 环回回到 FDMA 写侧：

    FDMA read BFM/硬件自测引擎
      -> fdma_aurora_brg_tx: RD FSM
      -> TX async FIFO: fdma_clk 到 user_clk
      -> fdma_aurora_brg_tx: LocalLink TX FSM
      -> aurora_64b66b_top / GT
      -> fdma_aurora_brg_rx: LocalLink RX
      -> RX async FIFO: user_clk 到 fdma_clk
      -> fdma_aurora_brg_rx: WR FSM
      -> FDMA write BFM/硬件自测引擎

核心边界是三个：FDMA 读握手边界、Aurora LocalLink 帧边界、FDMA 写握手边界。调试时优先比对这些边界上的队列长度和首个错位位置。

## 3. 文件角色总表

<!-- 本表用于快速确定某个文件属于核心 RTL、硬件顶层、调试封装还是 testbench。 -->

| 文件 | 类别 | 作用 |
|---|---|---|
| `FIFO 转 AXI4 接口模块设计-ostd方案.md` | 参考设计材料 | 历史设计/交流记录，和 FIFO 到 AXI/FDMA 类接口转换思路有关。 |
| `cdc_sync.v` | 基础 CDC | 两级触发器同步单比特电平，用在 channel_up 等跨域状态信号。 |
| `fdma_aurora_brg_aurora_loop.v` | 集成 RTL / Aurora 环回 | 把桥接顶层接到 aurora_64b66b_top，并暴露 GT、SFP、FDMA 和链路状态端口。 |
| `fdma_aurora_brg_aurora_loop_hw.v` | 硬件顶层 | 板级顶层，加入 clk_wiz、VIO、硬件测试引擎、Aurora 环回 wrapper 与 ILA 调试。 |
| `fdma_aurora_brg_rx.v` | 核心 RTL / RX | Aurora RX LocalLink 数据写入异步 FIFO，FDMA 域按 512B burst 发起写请求并输出 wdata/wvalid。 |
| `fdma_aurora_brg_sim_verification.md` | 既有仿真说明 | 原有验证文档，说明 testcase、seed、回归和 Vivado 运行方式。 |
| `fdma_aurora_brg_top.v` | 核心 RTL / 桥接顶层 | 例化 channel_up CDC、TX 桥和 RX 桥，是不含 Aurora IP 的桥接核心。 |
| `fdma_aurora_brg_tx.v` | 核心 RTL / TX | FDMA 读侧状态机发起读 burst，数据写入异步 FIFO，再由 user_clk 域封装成 Aurora LocalLink 帧。 |
| `fdma_hw_test_engine.v` | 硬件自测 RTL | 可综合 FDMA 从机/数据检查器，在无外部 FDMA 主机时完成板上读写环回验证。 |
| `ila_brg_loop.v` | 调试 RTL | 集中打包 FDMA 域、user_clk 域和硬件自测状态，并接入 ILA IP。 |
| `tb_aurora_power_on_reset_seq.sv` | 专项 TB | 只验证 Aurora 推荐上电复位顺序，检查 pma_init 与 reset_pb 的断言/释放关系。 |
| `tb_backpressure_test.sv` | 早期/直接桥接 TB | 不经 Aurora IP，使用接口模型和队列验证反压条件下的桥接数据流。 |
| `tb_fdma_aurora_brg.sv` | 基础桥接 TB | 与 tb_backpressure_test 类似，偏基础功能验证；已统一改写为 UTF-8 以容纳中文注释。 |
| `tb_fdma_aurora_brg_aurora_loop.sv` | 完整 Aurora 自环 TB | 例化 fdma_aurora_brg_aurora_loop，GT TX/RX 自环，验证带 Aurora IP 的完整路径。 |
| `tb_fdma_aurora_brg_aurora_loop_bp - note.sv` | BP 记录副本 | 保留带反压用例的较早版本/记录，适合对照随机延迟策略。 |
| `tb_fdma_aurora_brg_aurora_loop_bp.sv` | BP 主验证 TB | 带 FDMA 读写随机延迟，包含多级队列观察和数据流静默等待。 |
| `tb_fdma_aurora_brg_aurora_loop_nobp.sv` | NOBP 主验证 TB | FDMA 读写从机立即响应，用于确认无反压时链路和边界条件正确。 |
| `tb_fdma_hw_test_engine.sv` | 硬件自测引擎 TB | 单独验证 fdma_hw_test_engine 的 start/clear/auto、读写 burst、错误记录和超时。 |
| `tb_fdma_tx_burst_boundary.sv` | TX 边界 TB | 用 SVA 检查 TX 侧 512B burst 的第 64 个字不会在 FIFO 写入时丢失。 |

## 4. 各子文件详细解读

<!-- 每个子节列出结构块索引，行号以当前已加注释后的文件为准。 -->

### 4.1 `cdc_sync.v`

- 类别：基础 CDC
- 作用：两级触发器同步单比特电平，用在 channel_up 等跨域状态信号。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 7 | module | `module cdc_sync (` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：cdc_sync |
| 19 | always | `// 时序 always 块在指定时钟/复位边沿更新寄存器状态。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 20 | always | `always @(posedge dst_clk or negedge dst_rstn) begin` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 31 | assign | `assign dst_signal = sync_reg2;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |

### 4.2 `fdma_aurora_brg_aurora_loop_hw.v`

- 类别：硬件顶层
- 作用：板级顶层，加入 clk_wiz、VIO、硬件测试引擎、Aurora 环回 wrapper 与 ILA 调试。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 9 | module | `module fdma_aurora_brg_aurora_loop_hw #(` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：fdma_aurora_brg_aurora_loop_hw |
| 83 | instance | `clk_wiz_1 u_clk_wiz_1 (` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |
| 92 | assign | `assign sys_rst = ~locked;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 95 | always | `always @(posedge fdma_clk or negedge locked) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 132 | instance | `vio_hw_ctrl u_vio_hw_ctrl (` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |

### 4.3 `fdma_aurora_brg_aurora_loop.v`

- 类别：集成 RTL / Aurora 环回
- 作用：把桥接顶层接到 aurora_64b66b_top，并暴露 GT、SFP、FDMA 和链路状态端口。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 11 | module | `module fdma_aurora_brg_aurora_loop #(` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：fdma_aurora_brg_aurora_loop |
| 201 | instance | `ila_brg_loop u_ila_brg_loop (` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |
| 251 | assign | `assign channel_up  = aurora_channel_up ;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 253 | assign | `assign lane_up     = aurora_lane_up    ;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 255 | assign | `assign user_clk    = aurora_user_clk   ;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 257 | assign | `assign user_rstn   = aurora_user_rstn  ;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |

### 4.4 `fdma_aurora_brg_rx.v`

- 类别：核心 RTL / RX
- 作用：Aurora RX LocalLink 数据写入异步 FIFO，FDMA 域按 512B burst 发起写请求并输出 wdata/wvalid。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 11 | module | `module fdma_aurora_brg_rx(` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：fdma_aurora_brg_rx |
| 44 | localparam | `localparam TEST_MEM_SIZE   = 32'd4 * 1024;   // 4KB 测试空间` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 46 | localparam | `localparam FDMA_BURST_LEN  = 16'd512;         // 512 字节/burst` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 48 | localparam | `//localparam FRAME_BYTES     = 16'd1024;        // 1024 字节/帧，128 个 64 位字` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 50 | localparam | `localparam BURST_WORDS     = FDMA_BURST_LEN / 8;  // 512 字节对应 64 个 64 位字` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 52 | localparam | `//localparam FRAME_WORDS     = FRAME_BYTES / 8;     // 1024 字节对应 128 个 64 位字` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 56 | localparam | `localparam WR_IDLE  = 2'd0;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 58 | localparam | `localparam WR_REQ   = 2'd1;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 60 | localparam | `localparam WR_DATA  = 2'd2;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 62 | localparam | `localparam WR_WAIT  = 2'd3;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 95 | assign | `assign wr_clk = user_clk;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 97 | assign | `assign rd_clk = fdma_clk;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 98 | always | `// The Aurora RX LocalLink side is always ready in this bridge.` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 100 | assign | `assign rx_dst_rdy = 1'b1;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 105 | assign | `assign rx_dst_rdy = 1'b1;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 121 | assign | `assign fifo_rd_en = (wr_state == WR_DATA) && fdma_wbusy && !fifo_empty && !rd_rst_busy &&` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 125 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 147 | assign | `assign fdma_wvalid = wdata_hold_valid && (wr_state == WR_DATA) && fdma_wbusy;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 149 | assign | `assign fdma_wdata  = wdata_hold;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 153 | assign | `assign fifo_wr_en = rx_src_rdy && !fifo_full;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 155 | assign | `assign wr_en = fifo_wr_en && !wr_rst_busy;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 157 | assign | `assign rd_en = fifo_rd_en;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 160 | assign | `assign fifo_wdata = rx_d;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 162 | assign | `assign fifo_rst = ~user_rstn;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 165 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 172 | always | `// 组合 always 块计算下一状态/输出，注意不要引入锁存器。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 173 | always | `always @(*) begin` | 组合逻辑块；计算下一状态或组合输出。 |
| 194 | assign | `assign wr_burst_done = (wr_state == WR_DATA) && w_hs && (wr_word_cnt == BURST_WORDS-1);` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 197 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 213 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 225 | assign | `assign fdma_waddr = wr_addr;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 227 | assign | `assign fdma_wsize = FDMA_BURST_LEN;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 231 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 294 | always | `always @(posedge user_clk or negedge user_rstn) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 301 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 310 | assign | `assign dbg_user_bus = {` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 318 | assign | `assign dbg_fdma_bus = {` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 335 | always | `always @(posedge user_clk or negedge user_rstn) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 344 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |

### 4.5 `fdma_aurora_brg_sim_verification.md`

- 类别：既有仿真说明
- 作用：原有验证文档，说明 testcase、seed、回归和 Vivado 运行方式。
- Markdown 文件，无 always/class；按标题结构阅读。

| 行号 | 标题 | 解读 |
|---:|---|---|
| 1 | `fdma_aurora_brg 仿真结构与测试用例说明` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 5 | `1. 验证目标` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 13 | `2. 目录与编译关系` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 41 | `3. 数据流与scoreboard` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 68 | `4. 公共随机延迟配置` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 88 | `5. Seed、日志和打印等级` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 103 | `6. 测试用例` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 107 | `6.1 tc_aurora_loop_nobp` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 132 | `6.2 tc_aurora_loop_bp` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 157 | `6.3 tc_aurora_loop_addr_wrap` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 179 | `6.4 tc_brg_rd_ready_stall` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 202 | `6.5 tc_brg_wr_ready_stall` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 224 | `6.6 tc_brg_tx_fifo_waterline` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 248 | `6.7 tc_brg_rx_fifo_overflow` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 272 | `7. 回归配置与输出` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 289 | `8. SystemVerilog语法、依赖关系与运行时调用` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 293 | `8.1 为什么不再只有一个传统TB文件` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 313 | `8.2 编译依赖` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 349 | `8.3 virtual方法如何调用` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 382 | `9. Vivado如何识别这套平台` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 386 | `9.1 当前XPR已经配置好的内容` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 422 | `9.2 在一个全新Vivado工程中手工加入` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 453 | `10. ENABLE_ILA宏` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 485 | `11. Vivado/XSim使用` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 489 | `11.1 PowerShell批量回归` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 507 | `11.2 Vivado GUI/Tcl Console` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 527 | `11.3 与VCS/Verdi流程对照` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |

### 4.6 `fdma_aurora_brg_top.v`

- 类别：核心 RTL / 桥接顶层
- 作用：例化 channel_up CDC、TX 桥和 RX 桥，是不含 Aurora IP 的桥接核心。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 26 | module | `module fdma_aurora_brg_top #(` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：fdma_aurora_brg_top |
| 82 | assign | `assign dbg_channel_up_fdma = channel_up_fdma;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 86 | instance | `cdc_sync u_channel_up_sync (` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |
| 121 | instance | `fdma_aurora_brg_rx u_fdma_aurora_brg_rx(` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |

### 4.7 `fdma_aurora_brg_tx.v`

- 类别：核心 RTL / TX
- 作用：FDMA 读侧状态机发起读 burst，数据写入异步 FIFO，再由 user_clk 域封装成 Aurora LocalLink 帧。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 26 | module | `module fdma_aurora_brg_tx #(` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：fdma_aurora_brg_tx |
| 65 | localparam | `localparam TEST_MEM_SIZE   = 32'd4 * 1024;        // 4KB 测试空间` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 67 | localparam | `localparam FDMA_BURST_LEN  = 16'd512;             // 512 字节/burst` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 69 | localparam | `localparam BURST_WORDS     = FDMA_BURST_LEN / 8;  // 512/8=64 个 64bit 字` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 71 | localparam | `localparam FRAME_WORDS     = FRAME_BYTES / 8;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 75 | localparam | `localparam RD_IDLE  = 2'd0;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 77 | localparam | `localparam RD_REQ   = 2'd1;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 79 | localparam | `localparam RD_DATA  = 2'd2;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 81 | localparam | `localparam RD_WAIT  = 2'd3;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 91 | localparam | `localparam TX_IDLE = 2'd0;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 93 | localparam | `localparam TX_SOF  = 2'd1;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 95 | localparam | `localparam TX_DATA = 2'd2;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 127 | assign | `assign wr_clk = fdma_clk;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 129 | assign | `assign rd_clk = user_clk;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 132 | assign | `assign fdma_rready = ~fifo_almost_full;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 137 | assign | `assign fdma_rready = ~fifo_almost_full;  // FIFO 不满时授权 FDMA 传输数据` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 144 | assign | `assign fifo_wr_en = rd_data_hs;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 146 | assign | `assign fifo_wdata = fdma_rdata;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 150 | assign | `assign wr_en = fifo_wr_en && (~wr_rst_busy);` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 152 | assign | `assign rd_en = fifo_rd_en && (~rd_rst_busy);` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 155 | assign | `assign fifo_rst = (~fdma_rstn);` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 159 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 166 | always | `// 组合 always 块计算下一状态/输出，注意不要引入锁存器。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 167 | always | `always @(*) begin` | 组合逻辑块；计算下一状态或组合输出。 |
| 189 | assign | `assign  rd_burst_done = rd_data_hs && (rd_word_cnt == BURST_WORDS - 1);` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 192 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 207 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 220 | assign | `assign fdma_raddr = rd_addr;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 224 | always | `//always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 233 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 247 | always | `always @(posedge user_clk or negedge user_rstn) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 255 | assign | `assign wr_burst_done = tx_dst_rdy && (tx_word_cnt ==FRAME_WORDS-1);` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 257 | always | `// 组合 always 块计算下一状态/输出，注意不要引入锁存器。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 258 | always | `always @(*) begin` | 组合逻辑块；计算下一状态或组合输出。 |
| 275 | always | `// 组合 always 块计算下一状态/输出，注意不要引入锁存器。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 276 | always | `always @(*) begin` | 组合逻辑块；计算下一状态或组合输出。 |
| 287 | always | `always @(posedge user_clk or negedge user_rstn) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 310 | assign | `assign fifo_rd_en = (tx_state !=TX_IDLE) && (~fifo_empty) && tx_dst_rdy;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 362 | function | `// 该 function 提供纯计算/格式化辅助，不直接消耗仿真时间。` | 无时延辅助函数；用于计算或格式化。 |
| 363 | function | `// DFX function` | 无时延辅助函数；用于计算或格式化。 |
| 367 | always | `always @(posedge user_clk or negedge user_rstn) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 375 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 384 | assign | `assign dbg_fdma_bus = {` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 395 | assign | `assign dbg_user_bus = {` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |

### 4.8 `fdma_hw_test_engine.v`

- 类别：硬件自测 RTL
- 作用：可综合 FDMA 从机/数据检查器，在无外部 FDMA 主机时完成板上读写环回验证。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 6 | module | `module fdma_hw_test_engine #(` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：fdma_hw_test_engine |
| 44 | localparam | `localparam integer FRAME_WORDS = FRAME_BYTES / 8;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 46 | localparam | `localparam integer BURST_WORDS = BURST_BYTES / 8;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 48 | localparam | `localparam [1:0] RD_IDLE = 2'd0, RD_ACCEPT = 2'd1,` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 51 | localparam | `localparam [1:0] WR_IDLE = 2'd0, WR_ACCEPT = 2'd1,` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 54 | localparam | `localparam [2:0] RESULT_IDLE = 3'd0, RESULT_RUNNING = 3'd1,` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 58 | localparam | `localparam [1:0] ERR_NONE = 2'd0, ERR_SKIPPED_WORD = 2'd1,` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 109 | assign | `assign dbg_bus = {hw_rd_word_total, hw_wr_word_total,` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 114 | assign | `assign status_dbg_bus = {` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 132 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 215 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 283 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |

### 4.9 `FIFO 转 AXI4 接口模块设计-ostd方案.md`

- 类别：参考设计材料
- 作用：历史设计/交流记录，和 FIFO 到 AXI/FDMA 类接口转换思路有关。
- Markdown 文件，无 always/class；按标题结构阅读。

| 行号 | 标题 | 解读 |
|---:|---|---|
| 1 | `解决个人热点DNS手动问题` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 15 | `npm 安装 Codex CLI 完整指令总结` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 23 | `1. 检查 Node.js 是否已安装` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 33 | `2. 安装 Node.js LTS 版本` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 43 | `3. 设置 PowerShell 执行策略（解决 npm 脚本权限问题）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 53 | `4. 刷新环境变量 + 安装 Codex CLI` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 64 | `5. 验证安装` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 75 | `一键安装脚本（汇总版）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 82 | `安装 Node.js` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 85 | `设置执行策略` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 88 | `刷新环境变量并安装 Codex` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 92 | `验证` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 98 | `后续使用 Codex 的指令` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 120 | `支持的 Verilog 相关后缀` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 136 | `Trae 支持的文件类型` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 142 | `硬件描述语言` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 151 | `软件语言` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 162 | `配置文件` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 169 | `文档` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 176 | `注意事项` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 188 | `直接上传 .v 文件` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 213 | `方法1：使用不同的工作区文件（推荐）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 231 | `方法2：多窗口模式` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 243 | `方法3：使用工作区设置` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 266 | `方法4：使用配置文件切换` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 273 | `打开特定工作区` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 276 | `打开特定文件夹` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 282 | `最佳实践` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 295 | `快速操作` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 314 | `数字芯片设计领域模型能力评估` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 320 | `综合排名（满分 100）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 341 | `详细分析` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 345 | `第一梯队（90+ 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 349 | `**DeepSeek-V4-Pro（92分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 356 | `**Qwen3.6-Plus（90分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 365 | `🥈 第二梯队（80-89 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 369 | `**GLM-5.1（85分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 375 | `**DeepSeek-V4-Flash（83分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 381 | `**Kimi-K2.6（80分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 389 | `🥉 第三梯队（70-79 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 393 | `**GLM-5V-Turbo（78分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 399 | `**MiniMax-M3（75分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 404 | `**Qwen3.5-Plus（74分）**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 411 | `第四梯队（<70 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 420 | `针对你的项目推荐` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 436 | `建议` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 454 | `数字芯片设计领域模型能力评估（独立分析）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 460 | `综合排名` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 481 | `各模型详细评估` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 485 | `第一梯队（90+ 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 489 | `**DeepSeek-V4-Pro**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 496 | `**Qwen3.6-Plus**（当前选中）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 505 | `第二梯队（80-89 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 509 | `**GLM-5.1**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 516 | `**DeepSeek-V4-Flash**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 523 | `**Kimi-K2.6**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 532 | `第三梯队（70-79 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 536 | `**GLM-5V-Turbo**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 542 | `**MiniMax-M3**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 548 | `**Qwen3.5-Plus**` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 556 | `第四梯队（<70 分）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 565 | `针对 TDC/DDR/AXI/SPI 项目的推荐` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 580 | `建议` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 596 | `DeepSeek-V4-Pro 与免费版网页的区别` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 598 | `版本体系概览` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 610 | `核心区别对比` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 614 | `1. 模型能力差异` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 626 | `2. 数字芯片设计场景对比` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 639 | `3. 功能特性差异` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 653 | `Trae IDE 中的 DeepSeek-V4-Pro 优势` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 667 | `成本对比` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 679 | `结论` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 701 | `为什么你觉得 GLM-5.1 最好？` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 705 | `GLM-5.1 的独特优势（智谱）` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 715 | `DeepSeek-V4-Pro 的问题` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 726 | `Qwen3.6-Plus 为什么也可以？` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 737 | `主观体验 vs 客观能力` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 751 | `你的实际使用建议` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 766 | `总结` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| 798 | `使用方法` | 本节属于该说明文件的主题段落，已补充 HTML 中文注释作为阅读提示。 |
| - | `...` | 标题较多，表中仅列前 80 个；完整内容见原文件。 |

### 4.10 `ila_brg_loop.v`

- 类别：调试 RTL
- 作用：集中打包 FDMA 域、user_clk 域和硬件自测状态，并接入 ILA IP。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 7 | module | `module ila_brg_loop (` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：ila_brg_loop |
| 124 | always | `always @(posedge fdma_clk or negedge fdma_rstn) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 144 | always | `always @(posedge user_clk or negedge user_rstn) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 172 | instance | `ila_fdma_hw u_ila_fdma (` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |
| 230 | instance | `ila_user_hw u_ila_user (` | 子模块/IP 实例化；把当前层信号接到下一级功能块。 |

### 4.11 `tb_aurora_power_on_reset_seq.sv`

- 类别：专项 TB
- 作用：只验证 Aurora 推荐上电复位顺序，检查 pma_init 与 reset_pb 的断言/释放关系。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 4 | module | `module tb_aurora_power_on_reset_seq;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_aurora_power_on_reset_seq |
| 6 | localparam | `localparam integer PMA_CYCLES = 8;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 8 | localparam | `localparam integer GAP_CYCLES = 3;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 18 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 19 | always | `always #10 clk_init = ~clk_init;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 33 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 34 | task | `task check_asserted;` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 41 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 42 | task | `task run_complete_sequence;` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 65 | always | `// 时序 always 块在指定时钟/复位边沿更新寄存器状态。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 66 | always | `always @(negedge pma_init)` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 70 | always | `// 时序 always 块在指定时钟/复位边沿更新寄存器状态。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 71 | always | `always @(negedge reset_pb)` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 75 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 76 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.12 `tb_backpressure_test.sv`

- 类别：早期/直接桥接 TB
- 作用：不经 Aurora IP，使用接口模型和队列验证反压条件下的桥接数据流。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 26 | package | `package local_pkg;` | 本地参数/类型包，通常定义时钟周期、帧长度和队列元素结构。 |
| 59 | interface | `interface fdma_read_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 78 | interface | `interface fdma_write_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 98 | interface | `interface aurora_ll_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 140 | module | `module tb_simple;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_simple |
| 151 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 152 | initial | `initial fdma_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 153 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 154 | always | `always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 155 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 156 | initial | `initial user_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 157 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 158 | always | `always #(USER_CLK_PERIOD_NS/2) user_clk = ~user_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 161 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 162 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 219 | task | `task automatic fdma_read_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 272 | task | `task automatic fdma_write_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 346 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 347 | initial | `//initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 358 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 359 | initial | `//initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 370 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 371 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 382 | task | `task automatic compare_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 449 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 450 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 458 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 459 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 518 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 519 | task | `task automatic send_aurora_frame(input aurora_frame_t frame);` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 550 | assign | `// 删除原有的 assign aur_if.tx_dst_rdy = 1'b1; 这一行，改为由以下逻辑驱动` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 552 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 553 | initial | `// 反压生成任务（在 initial 中启动一个 forever 循环驱动）` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 554 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 555 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.13 `tb_fdma_aurora_brg_aurora_loop_bp - note.sv`

- 类别：BP 记录副本
- 作用：保留带反压用例的较早版本/记录，适合对照随机延迟策略。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 33 | package | `package loop_bp_pkg;` | 本地参数/类型包，通常定义时钟周期、帧长度和队列元素结构。 |
| 67 | interface | `interface fdma_read_if_bp(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 87 | interface | `interface fdma_write_if_bp(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 109 | module | `module tb_fdma_aurora_brg_aurora_loop_bp;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_fdma_aurora_brg_aurora_loop_bp |
| 123 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 124 | initial | `initial fdma_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 125 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 126 | always | `always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 128 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 129 | initial | `initial init_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 130 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 131 | always | `always #(INIT_CLK_PERIOD_NS/2) init_clk = ~init_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 133 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 134 | initial | `initial gt_ref_clk_n = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 135 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 136 | always | `always #(GT_REF_CLK_PERIOD_NS/2) gt_ref_clk_n = ~gt_ref_clk_n;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 140 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 141 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 164 | assign | `assign rxp = txp;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 166 | assign | `assign rxn = txn;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 220 | always | `always @(posedge user_clk) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 235 | task | `task automatic fdma_read_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 283 | task | `task automatic fdma_write_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 335 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 336 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 346 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 347 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 358 | task | `task automatic compare_ll_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 379 | task | `task automatic compare_fdma_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 402 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 403 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 413 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 414 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 497 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 498 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.14 `tb_fdma_aurora_brg_aurora_loop_bp.sv`

- 类别：BP 主验证 TB
- 作用：带 FDMA 读写随机延迟，包含多级队列观察和数据流静默等待。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 28 | package | `package loop_bp_pkg;` | 本地参数/类型包，通常定义时钟周期、帧长度和队列元素结构。 |
| 62 | interface | `interface fdma_read_if_bp(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 86 | interface | `interface fdma_write_if_bp(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 111 | module | `module tb_fdma_aurora_brg_aurora_loop_bp;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_fdma_aurora_brg_aurora_loop_bp |
| 126 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 127 | initial | `initial fdma_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 128 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 129 | always | `always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 131 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 132 | initial | `initial init_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 133 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 134 | always | `always #(INIT_CLK_PERIOD_NS/2) init_clk = ~init_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 136 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 137 | initial | `initial gt_ref_clk_n = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 138 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 139 | always | `always #(GT_REF_CLK_PERIOD_NS/2) gt_ref_clk_n = ~gt_ref_clk_n;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 143 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 144 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 167 | assign | `assign rxp = txp;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 169 | assign | `assign rxn = txn;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 224 | always | `always @(posedge user_clk) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 241 | task | `task automatic fdma_read_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 317 | task | `task automatic fdma_write_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 430 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 431 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 446 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 447 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 462 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 463 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 504 | task | `task automatic compare_ll_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 525 | task | `task automatic compare_fdma_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 546 | task | `task automatic report_queue_pair(` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 598 | task | `task automatic report_dataflow_observations();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 639 | task | `task automatic wait_dataflow_quiet(input int quiet_user_cycles, input int timeout_user_cycles);` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 696 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 697 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 708 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 709 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 785 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 786 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.15 `tb_fdma_aurora_brg_aurora_loop_nobp.sv`

- 类别：NOBP 主验证 TB
- 作用：FDMA 读写从机立即响应，用于确认无反压时链路和边界条件正确。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 28 | package | `package loop_nobp_pkg;` | 本地参数/类型包，通常定义时钟周期、帧长度和队列元素结构。 |
| 62 | interface | `interface fdma_read_if_nobp(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 82 | interface | `interface fdma_write_if_nobp(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 104 | module | `module tb_fdma_aurora_brg_aurora_loop_nobp;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_fdma_aurora_brg_aurora_loop_nobp |
| 118 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 119 | initial | `initial fdma_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 120 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 121 | always | `always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 123 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 124 | initial | `initial init_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 125 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 126 | always | `always #(INIT_CLK_PERIOD_NS/2) init_clk = ~init_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 128 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 129 | initial | `initial gt_ref_clk_n = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 130 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 131 | always | `always #(GT_REF_CLK_PERIOD_NS/2) gt_ref_clk_n = ~gt_ref_clk_n;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 135 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 136 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 159 | assign | `assign rxp = txp;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 161 | assign | `assign rxn = txn;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 218 | task | `task automatic fdma_read_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 253 | task | `task automatic fdma_write_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 288 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 289 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 299 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 300 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 311 | task | `task automatic compare_ll_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 332 | task | `task automatic compare_fdma_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 355 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 356 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 366 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 367 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 440 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 441 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.16 `tb_fdma_aurora_brg_aurora_loop.sv`

- 类别：完整 Aurora 自环 TB
- 作用：例化 fdma_aurora_brg_aurora_loop，GT TX/RX 自环，验证带 Aurora IP 的完整路径。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 31 | package | `package loop_pkg;` | 本地参数/类型包，通常定义时钟周期、帧长度和队列元素结构。 |
| 69 | interface | `interface fdma_read_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 89 | interface | `interface fdma_write_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 111 | module | `module tb_fdma_aurora_brg_aurora_loop;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_fdma_aurora_brg_aurora_loop |
| 126 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 127 | initial | `initial fdma_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 128 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 129 | always | `always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 131 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 132 | initial | `initial init_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 133 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 134 | always | `always #(INIT_CLK_PERIOD_NS/2) init_clk = ~init_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 136 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 137 | initial | `initial gt_ref_clk_n = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 138 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 139 | always | `always #(GT_REF_CLK_PERIOD_NS/2) gt_ref_clk_n = ~gt_ref_clk_n;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 144 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 145 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 168 | assign | `assign rxp = txp;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 170 | assign | `assign rxn = txn;` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 241 | task | `task automatic fdma_read_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 289 | task | `task automatic fdma_write_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 341 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 342 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 353 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 354 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 368 | task | `task automatic compare_ll_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 415 | task | `task automatic compare_fdma_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 460 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 461 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 471 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 472 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 556 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 557 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.17 `tb_fdma_aurora_brg.sv`

- 类别：基础桥接 TB
- 作用：与 tb_backpressure_test 类似，偏基础功能验证；已统一改写为 UTF-8 以容纳中文注释。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 26 | package | `package local_pkg;` | 本地参数/类型包，通常定义时钟周期、帧长度和队列元素结构。 |
| 59 | interface | `interface fdma_read_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 78 | interface | `interface fdma_write_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 98 | interface | `interface aurora_ll_if(input logic clk, input logic rst_n);` | SystemVerilog 接口，封装一组握手信号和 modport/clocking block。 |
| 140 | module | `module tb_simple;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_simple |
| 151 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 152 | initial | `initial fdma_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 153 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 154 | always | `always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 155 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 156 | initial | `initial user_clk = 0;` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 157 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 158 | always | `always #(USER_CLK_PERIOD_NS/2) user_clk = ~user_clk;` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 161 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 162 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 219 | task | `task automatic fdma_read_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 263 | task | `task automatic fdma_write_slave();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 328 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 329 | initial | `//initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 340 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 341 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 352 | task | `task automatic compare_data();` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 387 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 388 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 396 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 397 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 444 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 445 | task | `task automatic send_aurora_frame(input aurora_frame_t frame);` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 476 | assign | `// 鍒犻櫎鍘熸湁鐨? assign aur_if.tx_dst_rdy = 1'b1; 杩欎竴琛岋紝鏀逛负鐢变互涓嬮?昏緫椹卞姩` | 连续赋值；完成组合连接、握手控制、FIFO 控制或调试总线打包。 |
| 478 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 479 | initial | `// 鍙嶅帇鐢熸垚浠诲姟锛堝湪 initial 涓惎鍔ㄤ竴涓? forever 寰幆椹卞姩锛?` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 480 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 481 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.18 `tb_fdma_hw_test_engine.sv`

- 类别：硬件自测引擎 TB
- 作用：单独验证 fdma_hw_test_engine 的 start/clear/auto、读写 burst、错误记录和超时。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 4 | module | `module tb_fdma_hw_test_engine;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_fdma_hw_test_engine |
| 6 | localparam | `localparam integer WORDS_PER_BURST = 64;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 42 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 43 | always | `always #2 fdma_clk = ~fdma_clk; // 250 MHz` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 65 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 66 | task | `task automatic start_run(input integer frames);` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 78 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 79 | task | `task automatic clear_run;` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 89 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 90 | task | `task automatic check(input bit condition, input string message);` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 100 | task | `task automatic run_read_burst(input integer frame_number,` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 145 | task | `task automatic run_write_burst(input integer frame_number,` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 181 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 182 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 247 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 248 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

### 4.19 `tb_fdma_tx_burst_boundary.sv`

- 类别：TX 边界 TB
- 作用：用 SVA 检查 TX 侧 512B burst 的第 64 个字不会在 FIFO 写入时丢失。
- class 块：无

| 行号 | 块类型 | 原始入口 | 解读 |
|---:|---|---|---|
| 7 | module | `module tb_fdma_tx_burst_boundary;` | 模块入口，定义本文件的顶层硬件或 testbench 作用域：tb_fdma_tx_burst_boundary |
| 9 | localparam | `localparam integer WORDS_PER_BURST = 64;` | 局部常量；定义状态编码、帧/burst 尺寸、超时或测试规模。 |
| 35 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 36 | always | `always #2.0 fdma_clk = ~fdma_clk;       // 250 MHz` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 37 | always | `// 该 always 块产生周期时钟，是本仿真时序推进的节拍源。` | 时序/事件触发块；根据敏感列表更新检查或寄存器。 |
| 38 | always | `always #3.103 user_clk = ~user_clk;     // approximately 161.13 MHz` | 时钟发生器 always 块，按半周期翻转仿真时钟。 |
| 54 | property | `property p_fifo_write_is_fdma_handshake;` | SVA 属性定义，描述必须满足的握手/边界协议。 |
| 59 | assert | `assert property (p_fifo_write_is_fdma_handshake)` | SVA 断言绑定属性，失败时中止或报告。 |
| 64 | property | `property p_last_word_is_written;` | SVA 属性定义，描述必须满足的握手/边界协议。 |
| 69 | assert | `assert property (p_last_word_is_written)` | SVA 断言绑定属性，失败时中止或报告。 |
| 74 | property | `property p_read_data_stable_when_stalled;` | SVA 属性定义，描述必须满足的握手/边界协议。 |
| 80 | assert | `assert property (p_read_data_stable_when_stalled)` | SVA 断言绑定属性，失败时中止或报告。 |
| 84 | always | `always @(posedge fdma_clk) begin` | FDMA 时钟域时序块；通常维护 FDMA 状态机、地址、计数器或硬件测试状态。 |
| 102 | always | `always @(posedge user_clk) begin` | Aurora user_clk 域时序块；通常维护 LocalLink 帧、FIFO 读出或链路侧采样。 |
| 107 | initial | `// 该 task 封装一段可复用流程，避免 initial 块里堆叠重复时序。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 108 | task | `task automatic provide_burst(input integer frame_number);` | 可复用仿真任务；封装 BFM 驱动、scoreboard 比对、报告或等待流程。 |
| 130 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 131 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 166 | initial | `// initial 块负责仿真初始化、复位释放、激励启动或最终检查。` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |
| 167 | initial | `initial begin` | 仿真初始流程；负责初始化、复位、启动激励、等待完成或结束仿真。 |

## 5. 调试建议

<!-- 本节给出实际排错顺序，减少在跨时钟和反压问题中来回跳。 -->

1. 先跑 NOBP，确认 channel_up、SOF/EOF、512B burst 边界和地址回绕都正确。
2. 再跑 BP，重点看 fifo_full/fifo_empty/almost_full、rready/wready 停顿期间数据是否保持。
3. 如果 LL 层一致但 FDMA 层不一致，优先查 RX FIFO 读出和 fdma_wvalid/wdata 保持。
4. 如果 FDMA 读队列与 LL TX 已经不一致，优先查 TX FIFO 写入条件和 rd_burst_done 最后一字。
5. 上板时先用 auto_enable 小帧数自测，再放大 frame_limit；失败时看 first_error_index/class/expected/actual。

## 本次修正与编译检查

- 已删除所有文件中的自动注释固定前缀。
- .v/.sv 已转换为无 BOM GBK/GB18030 兼容编码，Vivado 不再会把 UTF-8 BOM 当成源码字符。
- 已在控制语句前补充 if 级注释，覆盖 if / else if / else / case / default / for / repeat / wait 等分支。
- 已用 Vivado 2020.2 的 xvlog -sv 对 new 目录全部 .v/.sv 文件做文件级编译检查：退出码 0，无 Syntax Error。
- 剩余 warning 是既有 testbench 重名、变量需显式 automatic/static 等提示，不是编码或注释导致。
