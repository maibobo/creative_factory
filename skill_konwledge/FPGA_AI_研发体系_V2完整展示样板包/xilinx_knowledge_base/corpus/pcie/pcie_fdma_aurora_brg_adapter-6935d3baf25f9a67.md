# pcie_fdma_aurora_brg_adapter

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\pcie_fdma_aurora_brg_adapter.v`
- SHA-256: `6935d3baf25f9a6769e93d1a8bec1daca4b09ed13c1763bf31a59b1f321b71d3`
- Extractor: `text`
- Tags: `aurora, pcie, rtl, xdma`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// PCIe/FDMA/Aurora control and data-path adapter.
//
// Address ownership:
//   RX window: Aurora -> card memory -> CPU, 0x0000_0000..0x0000_7fff
//   TX window: CPU -> card memory -> Aurora, 0x0000_8000..0x0000_ffff
//
// INFO_EXCH supplies the low 32 bits of the TX card address. CARD_ADDR_HI is
// the static upper aperture used by both directions. All FDMA sizes are in
// 64-bit beats; the bridge's internal raw write size remains byte based.
//
// 模块语义：
//   本模块不是 PCIe TLP 解析器，也不直接访问主机内存。它位于 INFO_EXCH、
//   CONV_DMA/FDMA 与 Aurora LocalLink 三者之间，把软件的一次搬运命令拆成
//   固定 512 B 帧，并管理双向共享内存窗口、跨时钟完成事件和 RX 所有权。
//
// 双向数据路径：
//   CPU -> Aurora：软件先用 XDMA H2C 把数据放入 TX 窗口，再写 INFO_EXCH
//                   地址/长度并触发 rd_start；本模块用 FDMA read 取数并发 LL TX。
//   Aurora -> CPU：LL RX 数据进入异步 FIFO，本模块用 FDMA write 写入 RX 窗口；
//                   一帧落盘后上报地址/长度并触发 user IRQ，软件随后执行 C2H。
//
// 时钟域：
//   fdma_clk：软件命令、FDMA 请求/数据、IRQ/所有权和最终 sticky 状态。
//   aurora_user_clk：LocalLink TX/RX、帧边界检查和 FIFO 的 Aurora 一侧。
//   多比特数据只通过异步 FIFO 跨域；单比特状态使用 xpm_cdc_single；
//   单周期完成/清除脉冲先转为 toggle，再同步并异或恢复，避免窄脉冲丢失。
//
// 关键不变量：
//   - 地址窗口互斥：RX=[0,32 KiB)，TX=[32 KiB,64 KiB)。
//   - 软件命令地址/长度必须按 512 B 对齐，且不能跨出 TX 窗口。
//   - FDMA 对外 size 单位是 64-bit beat，因此 512 B 对外报告 64。
//   - RX 通知只在完整 FDMA 写突发完成后产生；仅收到 Aurora EOF 不等于已落盘。
//   - Aurora/FDMA错误sticky在clear_inter前保持；RX overrun由cpu_rec_ack清除；
//     clear_inter跨域期间屏蔽旧同步电平的反弹。

module pcie_fdma_aurora_brg_adapter #(
        // FRAME_BYTES 同时约束软件长度、FDMA burst 和 LocalLink 帧边界。
        // 当前桥的计数器和末拍处理只支持 512 B，initial 块会拒绝其他值。
        parameter integer FRAME_BYTES          = 512,
        // 每个方向可使用的低地址窗口大小；必须为正且是整帧倍数。
        parameter integer ACTIVE_WINDOW_BYTES  = 32 * 1024,
        // RX_BASE_ADDR_LO 是 Aurora->CPU 落盘起点；TX_BASE_ADDR_LO 是
        // CPU->Aurora 取数起点。两者是否重叠由系统集成参数负责保证。
        parameter [31:0]  RX_BASE_ADDR_LO       = 32'h0000_0000,
        parameter [31:0]  TX_BASE_ADDR_LO       = 32'h0000_8000,
        // 共享内存地址高 32 bit。非零值用于64位card address配置验证。
        parameter [31:0]  CARD_ADDR_HI          = 32'h0000_0000,
        // 仅在 FDMA 明确等待且持续无握手进展时计数；单位为 fdma_clk 周期。
        parameter integer FDMA_TIMEOUT_CYCLES   = 16'hffff
    )(
        // ---------- FDMA/软件控制域 ----------
        // fdma_rstn 为低有效；其释放不代表 Aurora 链路已经可用。
        input              fdma_clk,              // FDMA/软件控制时钟：承载命令、FDMA、IRQ、所有权和最终sticky逻辑
        input              fdma_rstn,             // FDMA域低有效复位：清除控制寄存器、计数器和最终状态
        // ---------- Aurora LocalLink 域 ----------
        input              aurora_user_clk,       // Aurora LocalLink用户时钟：承载TX/RX流、帧检查和源域sticky
        input              aurora_user_rstn,      // Aurora用户域低有效复位：清除帧上下文、toggle和源域错误状态

        // 三个链路条件全部有效才形成 link_up_fdma/link_up_user。
        // pcie_link_up 原生在 fdma_clk 域；channel/lane 原生在 user_clk 域。
        input              pcie_link_up,          // PCIe链路建立状态，原生属于fdma_clk域
        input              aurora_channel_up,     // Aurora通道建立状态，原生属于aurora_user_clk域
        input              aurora_lane_up,        // Aurora lane建立状态，原生属于aurora_user_clk域

        // FPGA -> Aurora LocalLink。仅 src_rdy && dst_rdy 的周期消费一个字；
        // dst_rdy=0 时 TX bridge 必须保持 d/SOF/EOF/REM 和 src_rdy。
        output     [63:0]  aurora_tx_d,            // FPGA到Aurora的64位LocalLink发送数据
        output             aurora_tx_sof,          // Aurora TX帧首标志，与首个有效数据beat同拍
        output             aurora_tx_eof,          // Aurora TX帧尾标志，与最后一个有效数据beat同拍
        output     [2:0]   aurora_tx_rem,          // Aurora TX末拍有效字节编码，完整512字节帧末拍为3'b111
        output             aurora_tx_src_rdy,      // Aurora TX源有效，和dst_rdy同时为1才消费一个beat
        input              aurora_tx_dst_rdy,      // Aurora TX目的端接收能力，为0时发送数据及帧界必须保持

        // Aurora -> FPGA LocalLink。rx_dst_rdy 表示本地 FIFO 当拍能否接收。
        // 真实串行链路无法依靠该信号无限停住远端，因此 dst_rdy 下降应被视为
        // 容量/吞吐异常并通过 rx_overflow_sticky 暴露，而不是正常长期流控。
        input      [63:0]  aurora_rx_d,            // Aurora到FPGA的64位LocalLink接收数据
        input              aurora_rx_sof,          // Aurora RX帧首标志，用于建立固定帧检查上下文
        input              aurora_rx_eof,          // Aurora RX帧尾标志，用于检查第64个beat和结束帧上下文
        input      [2:0]   aurora_rx_rem,          // Aurora RX末拍有效字节编码，完整帧EOF拍必须为3'b111
        input              aurora_rx_src_rdy,      // Aurora RX源有效，和dst_rdy同时为1形成真实接收握手
        output             aurora_rx_dst_rdy,      // RX bridge/FIFO当拍接收能力，拉低时同时记录容量异常

        // ---------- INFO_EXCH：CPU -> Aurora 命令 ----------
        // 软件应先稳定地址/长度，再产生 rd_start。地址是card低32位，长度是字节。
        // cpu_wr_done_resp=1 表示命令已被硬件接管且尚未发送完全部目标帧；
        // 它不是“第一帧已到 Aurora”的单周期完成脉冲。
        input              rd_start,              // INFO_EXCH产生的TX命令单周期启动脉冲
        input      [31:0]  cpu_fpga_start_addr,   // 软件下发的TX card memory低32位起始地址
        input      [31:0]  cpu_fpga_len,          // 软件下发的TX传输字节长度
        output reg         cpu_wr_done_resp,      // TX命令执行状态：硬件接管命令后置1，全部目标帧发送完成或活动期掉链后清0

        // ---------- INFO_EXCH：Aurora -> CPU 通知/所有权 ----------
        // fpga_cpu_start_addr/len 只在完整512 B已经由FDMA写入card memory后更新。
        // rx_pending=1 表示该缓冲区所有权已交给CPU；cpu_rec_state_r上升沿确认
        // 软件已接收/释放。pending未清时新帧到达不会覆盖通知，而置overrun。
        output reg [31:0]  fpga_cpu_start_addr,   // RX通知地址：最近一帧完整写入card memory后的低32位起始地址
        output reg [31:0]  fpga_cpu_len,          // RX通知长度：当前固定为FRAME_BYTES，即512字节
        output             int_state_w,           // 软件可读RX中断状态，映射内部int_state_w_r
        input              int_state_clear,       // INFO_EXCH读INT_STATE产生的清除事件，只清IRQ/INT状态
        input              clear_inter,           // 软件统一清除事件：清IRQ/最终sticky并跨域清用户域错误源
        input              cpu_rec_state_r,       // 软件RX buffer接收/归还状态，上升沿形成cpu_rec_ack
        output reg         cpu_rec_state_w,       // CPU接收状态回写镜像：在fdma_clk域跟随cpu_rec_state_r
        output reg         fpga_cpu_irq_req,      // RX用户中断请求：完整写突发完成并取得buffer所有权后置1，清中断命令清0

        // ---------- FDMA read 通道：共享内存 -> TX bridge ----------
        // rareq/raddr/rsize 描述一个512 B突发；rbusy表示CONV_DMA已接受事务。
        // 后续每个数据字只在 rvalid && rready 时进入TX异步FIFO。
        output     [63:0]  fdma_raddr,             // FDMA read的64位card memory地址
        output             fdma_rareq,             // FDMA read请求，等待rbusy接受前保持有效
        input              fdma_rbusy,             // CONV_DMA对read请求的接受/忙状态
        input      [63:0]  fdma_rdata,             // CONV_DMA返回的64位FDMA read数据
        input              fdma_rvalid,            // FDMA read数据有效，与rready同时为1时写入TX FIFO
        output             fdma_rready,            // TX bridge对FDMA read数据的接收能力
        output     [15:0]  fdma_rsize,             // FDMA read突发长度，单位为64位beat，当前固定64

        // ---------- FDMA write 通道：RX bridge -> 共享内存 ----------
        // wareq/waddr/wsize 描述一个512 B突发；每个字只在wvalid&&wready时提交。
        // PCIe.v 负责把这里的标准 valid/ready 语义转换为CONV_DMA历史端口命名。
        output     [63:0]  fdma_waddr,             // FDMA write的64位card memory地址
        output             fdma_wareq,             // FDMA write请求，等待wbusy接受前保持有效
        input              fdma_wbusy,             // CONV_DMA对write请求的接受/忙状态
        output     [63:0]  fdma_wdata,             // RX bridge从异步FIFO读出的64位FDMA write数据
        output             fdma_wvalid,            // 标准语义FDMA write源有效，PCIe.v负责适配CONV_DMA历史命名
        input              fdma_wready,            // 标准语义FDMA write数据接受，与wvalid同时为1时提交一个beat
        output     [15:0]  fdma_wsize,             // FDMA write突发长度，单位为64位beat，当前固定64

        // ---------- 状态/调试输出 ----------
        // FIFO水位是瞬时状态；一般*_sticky/timeout由clear_inter清除；
        // rx_overrun_sticky属于RX所有权异常，随cpu_rec_ack清除。
        // dbg状态仅用于ILA/仿真观测，不反馈控制路径。
        output             rx_fifo_almost_full,    // 同步到fdma_clk域的RX FIFO almost-full瞬时水位
        output             rx_fifo_full,           // 同步到fdma_clk域的RX FIFO full瞬时水位
        output             rx_overflow_sticky,     // RX FIFO溢出或valid&&!ready容量异常的最终sticky
        output             rx_overrun_sticky,      // CPU未归还上一帧buffer时新RX burst完成的所有权异常sticky
        output             tx_underflow_sticky,    // TX bridge供数不足的最终sticky
        output             fdma_timeout_sticky,    // FDMA持续等待且无真实progress达到门槛的最终sticky
        output             length_error_sticky,    // TX配置非法或RX帧长/帧界/rem错误的汇总sticky
        output             link_down_sticky,       // 命令时、活动期或曾up后链路掉线的最终sticky
        output             rx_pending,             // RX buffer已发布给CPU且尚未收到归还确认的所有权状态
        output     [3:0]   dbg_tx_state,            // TX bridge状态机编码的4位ILA/仿真观测输出
        output     [3:0]   dbg_rx_state             // RX bridge状态机编码的4位ILA/仿真观测输出
    );

    // ---------- 语义段 1：单位换算和静态参数自检 ----------
    // FRAME_WORDS 是64-bit word/beat数；FRAME_BYTES_32供软件通知；
    // FRAME_WORDS_16供FDMA接口。明确分开可防止把512字节误当512个beat。
    localparam integer FRAME_WORDS = FRAME_BYTES / 8;
    localparam [31:0] FRAME_BYTES_32 = FRAME_BYTES;
    localparam [15:0] FRAME_WORDS_16 = FRAME_WORDS;

    // initial只在仿真/展开阶段报告非法参数，不参与运行时数据通路。
    // tx_requested_end在后续另用33 bit计算运行时命令越界，避免32 bit加法回绕。
    initial begin
        if (FRAME_BYTES != 512)
            $error("pcie_fdma_aurora_brg_adapter supports 512-byte frames");
        if ((ACTIVE_WINDOW_BYTES <= 0) ||
            ((ACTIVE_WINDOW_BYTES % FRAME_BYTES) != 0))
            $error("ACTIVE_WINDOW_BYTES must be a positive frame multiple");
        if (({1'b0, RX_BASE_ADDR_LO} + ACTIVE_WINDOW_BYTES) > 33'h1_0000_0000)
            $error("RX low-address window crosses a 4-GiB aperture");
        if (({1'b0, TX_BASE_ADDR_LO} + ACTIVE_WINDOW_BYTES) > 33'h1_0000_0000)
            $error("TX low-address window crosses a 4-GiB aperture");
    end

    // ------------------------------------------------------------------
    // 语义段 2：链路状态跨时钟域和统一放行条件
    // ------------------------------------------------------------------
    // 输入：PCIe link(fdma域)、Aurora channel/lane(user域)。
    // 输出：两个域各自稳定的 link_up_user/link_up_fdma。
    // 推进条件：两个组合信号都要求 PCIe、channel、lane 三者同时有效。
    // 失败定位：外部状态正常但本域link不上，先查对应xpm同步器和目的域复位；
    // 不要把异步原始状态直接接入状态机来“缩短两拍延迟”。
    wire pcie_link_up_user;                       // 同步到aurora_user_clk域的PCIe链路状态
    wire aurora_channel_up_fdma;                  // 同步到fdma_clk域的Aurora通道建立状态
    wire aurora_lane_up_fdma;                     // 同步到fdma_clk域的Aurora lane建立状态
    // 本域组合只使用“本域原生信号 + 已同步到本域的外来信号”。
    wire link_up_user = pcie_link_up_user && aurora_channel_up && aurora_lane_up; // Aurora用户域业务总放行：PCIe、channel、lane三者均已建立
    wire link_up_fdma = pcie_link_up && aurora_channel_up_fdma && aurora_lane_up_fdma; // FDMA域业务总放行：本域PCIe状态与同步后的Aurora状态相与

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_pcie_link_to_user (
        .src_clk(fdma_clk), .src_in(pcie_link_up),
        .dest_clk(aurora_user_clk), .dest_out(pcie_link_up_user)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_channel_to_fdma (
        .src_clk(aurora_user_clk), .src_in(aurora_channel_up),
        .dest_clk(fdma_clk), .dest_out(aurora_channel_up_fdma)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_lane_to_fdma (
        .src_clk(aurora_user_clk), .src_in(aurora_lane_up),
        .dest_clk(fdma_clk), .dest_out(aurora_lane_up_fdma)
    );

    // ------------------------------------------------------------------
    // 语义段 3：CPU -> Aurora 命令校验、事务所有权和TX启动
    // ------------------------------------------------------------------
    // 输入：rd_start、软件地址/长度、link_up_fdma、tx_active。
    // 输出：tx_start_valid、目标帧数、TX基址和配置/掉链错误事件。
    // 所有权：tx_active=1期间硬件拥有当前命令配置，新的rd_start被拒绝；
    // 软件不应在active期间改写地址/长度并期待影响正在执行的事务。
    // 失败定位：rd_start后没有rareq时按顺序检查link、active、非零长度、
    // 512 B对齐、TX窗口下界和33 bit end地址。
    reg        tx_active;                         // TX事务活动标志：为1时硬件拥有当前软件命令并拒绝新启动
    reg [15:0] tx_target_frames;                  // 当前TX命令需要发送的512字节帧总数
    reg [15:0] tx_completed_frames;               // 当前TX命令已在Aurora末字真实握手完成的帧数
    reg [31:0] tx_base_addr_lo;                   // TX命令锁存的card memory低32位起始地址

    // 使用33 bit求和同时检测低32位回绕；end采用半开区间语义，恰好等于
    // tx_window_end是合法的，超过或产生第33位进位才非法。
    wire [32:0] tx_requested_end = {1'b0, cpu_fpga_start_addr} +
                                    {1'b0, cpu_fpga_len}; // TX命令半开区间结束地址：33位求和用于同时检测低32位回绕
    wire [32:0] tx_window_end = {1'b0, TX_BASE_ADDR_LO} +
                                ACTIVE_WINDOW_BYTES; // TX合法窗口半开区间上界：允许命令结束地址恰好等于该值
    wire tx_addr_aligned = ((cpu_fpga_start_addr & (FRAME_BYTES - 1)) == 0); // TX起始地址按512字节帧边界对齐标志
    wire tx_len_aligned  = ((cpu_fpga_len & (FRAME_BYTES - 1)) == 0); // TX长度按512字节帧边界对齐标志
    wire tx_config_valid = (cpu_fpga_len != 0) &&
                           tx_addr_aligned && tx_len_aligned &&
                           (cpu_fpga_len <= ACTIVE_WINDOW_BYTES) &&
                           (cpu_fpga_start_addr >= TX_BASE_ADDR_LO) &&
                           (tx_requested_end <= tx_window_end) &&
                           !tx_requested_end[32]; // TX配置总合法标志：非零、对齐、不越窗且33位加法无回绕
    // start_valid是唯一接管软件命令的事件；config_error把忙时重复启动也视为错误。
    wire tx_start_valid = rd_start && !tx_active && link_up_fdma && tx_config_valid; // 唯一合法TX命令接管事件
    wire tx_config_error_event = rd_start && (!tx_config_valid || tx_active); // 配置非法或忙时重复启动事件，用于置长度/配置错误sticky
    wire tx_start_link_error = rd_start && !link_up_fdma; // 链路未建立时收到TX启动命令的错误事件
    wire [31:0] requested_frames_32 = cpu_fpga_len / FRAME_BYTES; // 软件字节长度换算得到的512字节帧数

    wire tx_active_user;                          // 同步到aurora_user_clk域的TX事务活动电平
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_tx_active_to_user (
        .src_clk(fdma_clk), .src_in(tx_active),
        .dest_clk(aurora_user_clk), .dest_out(tx_active_user)
    );

    // TX bridge的局部复位同时受事务active和链路控制：没有有效命令时保持清空，
    // 避免FIFO残留数据在下一条软件命令中被当作首帧发送。
    wire tx_fdma_rstn = fdma_rstn && link_up_fdma && tx_active; // TX bridge FDMA侧局部低有效复位释放条件
    wire tx_user_rstn = aurora_user_rstn && link_up_user && tx_active_user; // TX bridge Aurora侧局部低有效复位释放条件

    wire [31:0] tx_fdma_raddr_raw;                // TX bridge生成的窗口内相对FDMA read地址
    wire [37:0] tx_fdma_dbg_bus;                  // TX bridge FDMA域调试总线，其中[37:36]为状态机编码
    wire [38:0] tx_user_dbg_bus;                  // TX bridge Aurora用户域调试总线，其中bit0为underflow事件
    wire tx_frame_done_user;                      // Aurora TX末字带EOF且真实握手完成时产生的user_clk单周期脉冲

    // ---------- 语义段 4：FDMA read -> 异步FIFO -> Aurora TX ----------
    // bridge每次FDMA突发和每个LL帧都是512 B；cfg_tx_burst_limit限制本命令
    // 允许发出的帧数。FDMA侧和LL侧分别按本域握手推进，跨域数据只走XPM FIFO。
    fdma_aurora_brg_tx #(
        .FRAME_BYTES      (FRAME_BYTES),
        .MEM_WINDOW_BYTES (ACTIVE_WINDOW_BYTES)
    ) u_fdma_aurora_brg_tx (
        .fdma_clk           (fdma_clk),
        .fdma_rstn          (tx_fdma_rstn),
        .user_clk           (aurora_user_clk),
        .user_rstn          (tx_user_rstn),
        .channel_up         (link_up_user && tx_active_user),
        .channel_up_fdma    (link_up_fdma && tx_active),
        .cfg_tx_burst_limit (tx_target_frames),
        .fdma_raddr         (tx_fdma_raddr_raw),
        .fdma_rareq         (fdma_rareq),
        .fdma_rbusy         (fdma_rbusy),
        .fdma_rdata         (fdma_rdata),
        .fdma_rvalid        (fdma_rvalid),
        .fdma_rready        (fdma_rready),
        .tx_d               (aurora_tx_d),
        .tx_sof             (aurora_tx_sof),
        .tx_eof             (aurora_tx_eof),
        .tx_rem             (aurora_tx_rem),
        .tx_src_rdy         (aurora_tx_src_rdy),
        .tx_dst_rdy         (aurora_tx_dst_rdy),
        .dbg_fdma_bus       (tx_fdma_dbg_bus),
        .dbg_user_bus       (tx_user_dbg_bus),
        .tx_frame_done      (tx_frame_done_user)
    );

    // bridge内部raw地址从0开始并按窗口回绕；在adapter边界叠加软件基址和
    // CARD_ADDR_HI，最终地址仍须落在本命令允许的TX窗口。
    assign fdma_raddr = {CARD_ADDR_HI, tx_base_addr_lo} +
                        {32'd0, tx_fdma_raddr_raw};
    assign fdma_rsize = FRAME_WORDS_16;

    // ---------- 语义段 5：TX帧完成toggle CDC ----------
    // tx_frame_done_user只在LL末字真正握手的一个user_clk周期有效。直接用
    // level同步器可能完全采不到，因此源域每完成一帧翻转一次toggle，目的域
    // 同步后与延迟值异或，恢复为恰好一个fdma_clk周期的完成事件。
    // 前提：相邻帧完成间隔必须大于同步器传播时间；512 B帧天然满足该条件。
    reg tx_done_toggle_user;                      // TX帧完成事件的源域toggle编码，每完成一帧翻转一次
    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin
        if (!aurora_user_rstn)
            tx_done_toggle_user <= 1'b0;
        else if (tx_frame_done_user)
            tx_done_toggle_user <= ~tx_done_toggle_user;
    end

    wire tx_done_toggle_fdma;                     // tx_done_toggle_user同步到fdma_clk域后的电平
    reg  tx_done_toggle_fdma_d;                   // 同步后toggle的一拍延迟值，用于异或恢复单周期事件
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_tx_done_toggle (
        .src_clk(aurora_user_clk), .src_in(tx_done_toggle_user),
        .dest_clk(fdma_clk), .dest_out(tx_done_toggle_fdma)
    );
    wire tx_frame_done_fdma = tx_done_toggle_fdma ^ tx_done_toggle_fdma_d; // fdma_clk域恢复的单周期TX帧完成事件

    // TX事务状态只在三个事件上改变：合法start、active期间掉链、帧完成。
    // cpu_wr_done_resp与tx_active同生命周期，用于软件观察“硬件仍持有命令”。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            tx_done_toggle_fdma_d <= 1'b0;
            tx_active             <= 1'b0;
            tx_target_frames      <= 16'd0;
            tx_completed_frames   <= 16'd0;
            tx_base_addr_lo       <= TX_BASE_ADDR_LO;
            cpu_wr_done_resp      <= 1'b0;
        end else begin
            tx_done_toggle_fdma_d <= tx_done_toggle_fdma;

            // 接管命令时一次性锁存地址、帧数，避免执行期间受软件寄存器变化影响。
            if (tx_start_valid) begin
                tx_active           <= 1'b1;
                tx_target_frames    <= requested_frames_32[15:0];
                tx_completed_frames <= 16'd0;
                tx_base_addr_lo     <= cpu_fpga_start_addr;
                cpu_wr_done_resp    <= 1'b1;
            end else if (tx_active && !link_up_fdma) begin
                tx_active           <= 1'b0;
                tx_target_frames    <= 16'd0;
                tx_completed_frames <= 16'd0;
                cpu_wr_done_resp    <= 1'b0;
            // 只有Aurora末字已被对端接受才累计完成帧；FDMA读完不等于发送完成。
            end else if (tx_active && tx_frame_done_fdma) begin
                if ((tx_completed_frames + 16'd1) >= tx_target_frames) begin
                    tx_active           <= 1'b0;
                    tx_target_frames    <= 16'd0;
                    tx_completed_frames <= 16'd0;
                    cpu_wr_done_resp    <= 1'b0;
                end else begin
                    tx_completed_frames <= tx_completed_frames + 16'd1;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // 语义段 6：Aurora RX -> 异步FIFO -> FDMA write
    // ------------------------------------------------------------------
    // 输入：LocalLink RX及FDMA write返回通道。
    // 输出：RX窗口写事务、FIFO水位和完整突发完成事件。
    // bridge内部fdma_wsize_raw沿用“字节”历史语义，但到本模块边界后统一覆盖为
    // FRAME_WORDS_16=64 beats，匹配CONV_DMA接口契约。
    // 失败定位：有LL握手无wareq查FIFO/WR状态；有wareq无完成查wbusy/wready；
    // rx_dst_rdy下降表示FIFO无法承接连续输入，应作为系统吞吐错误处理。
    wire rx_fdma_rstn = fdma_rstn && link_up_fdma; // RX bridge FDMA侧局部低有效复位释放条件
    wire rx_user_rstn = aurora_user_rstn && link_up_user; // RX bridge Aurora侧局部低有效复位释放条件
    wire [31:0]  rx_fdma_waddr_raw;               // RX bridge生成的窗口内相对FDMA write地址
    wire [15:0]  rx_fdma_wsize_raw;               // RX bridge历史byte单位写长度，仅保留连接；对外size由adapter覆盖为64 beat
    wire [105:0] rx_fdma_dbg_bus;                 // RX bridge FDMA域调试总线，其中[41:40]为状态机编码
    wire [28:0]  rx_user_dbg_bus;                 // RX bridge Aurora用户域调试总线，仅供观测
    wire rx_fifo_almost_full_user;                // RX异步FIFO在Aurora用户域的almost-full瞬时水位
    wire rx_fifo_full_user;                       // RX异步FIFO在Aurora用户域的full瞬时水位
    wire rx_fifo_overflow_user;                   // RX异步FIFO在Aurora用户域报告的原生overflow事件
    wire rx_burst_done_fdma;                      // 一次完整512字节FDMA write突发落盘完成事件

    fdma_aurora_brg_rx #(
        .MEM_WINDOW_BYTES (ACTIVE_WINDOW_BYTES)
    ) u_fdma_aurora_brg_rx (
        .fdma_clk             (fdma_clk),
        .fdma_rstn            (rx_fdma_rstn),
        .user_clk             (aurora_user_clk),
        .user_rstn            (rx_user_rstn),
        .channel_up_fdma      (link_up_fdma),
        .fdma_waddr           (rx_fdma_waddr_raw),
        .fdma_wareq           (fdma_wareq),
        .fdma_wbusy           (fdma_wbusy),
        .fdma_wdata           (fdma_wdata),
        .fdma_wvalid          (fdma_wvalid),
        .fdma_wsize           (rx_fdma_wsize_raw),
        .fdma_wready          (fdma_wready),
        .rx_d                 (aurora_rx_d),
        .rx_sof               (aurora_rx_sof),
        .rx_eof               (aurora_rx_eof),
        .rx_rem               (aurora_rx_rem),
        .rx_src_rdy           (aurora_rx_src_rdy),
        .dbg_user_bus         (rx_user_dbg_bus),
        .dbg_fdma_bus         (rx_fdma_dbg_bus),
        .rx_fifo_almost_full  (rx_fifo_almost_full_user),
        .rx_fifo_full         (rx_fifo_full_user),
        .rx_fifo_overflow     (rx_fifo_overflow_user),
        .rx_dst_rdy           (aurora_rx_dst_rdy),
        .rx_burst_done        (rx_burst_done_fdma)
    );

    // RX raw地址由bridge在ACTIVE_WINDOW_BYTES内按帧递增/回绕；外部叠加固定RX基址。
    assign fdma_waddr = {CARD_ADDR_HI, RX_BASE_ADDR_LO} +
                        {32'd0, rx_fdma_waddr_raw};
    assign fdma_wsize = FRAME_WORDS_16;

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_rx_almost_full (
        .src_clk(aurora_user_clk), .src_in(rx_fifo_almost_full_user),
        .dest_clk(fdma_clk), .dest_out(rx_fifo_almost_full)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_rx_full (
        .src_clk(aurora_user_clk), .src_in(rx_fifo_full_user),
        .dest_clk(fdma_clk), .dest_out(rx_fifo_full)
    );

    // ------------------------------------------------------------------
    // 语义段 7：RX缓冲区所有权、通知和IRQ
    // ------------------------------------------------------------------
    // rx_pending_r=1表示CPU尚未确认上一帧。cpu_rec_ack只检测CPU_REC_STATE的
    // 上升沿，防止软件保持高电平时每拍重复清pending。
    // int_state_clear/clear_inter只清IRQ/INT状态；cpu_rec_ack才释放RX所有权。
    // 两者故意分离，允许软件先应答中断、完成C2H后再归还缓冲区。
    reg int_state_w_r;                            // 软件可读RX中断状态寄存器：发布通知时置1，清中断时清0
    reg rx_pending_r;                             // RX buffer所有权标志：为1表示CPU尚未归还上一帧缓冲区
    reg rx_overrun_sticky_r;                      // RX所有权越界sticky：pending期间新burst完成时置1
    reg cpu_rec_state_d;                          // cpu_rec_state_r的一拍延迟值，用于检测软件确认上升沿
    wire cpu_rec_ack = cpu_rec_state_r && !cpu_rec_state_d; // CPU归还RX buffer所有权的单周期上升沿事件

    assign int_state_w = int_state_w_r;
    assign rx_pending = rx_pending_r;
    assign rx_overrun_sticky = rx_overrun_sticky_r;

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            fpga_cpu_start_addr <= RX_BASE_ADDR_LO;
            fpga_cpu_len        <= FRAME_BYTES_32;
            fpga_cpu_irq_req    <= 1'b0;
            int_state_w_r       <= 1'b0;
            cpu_rec_state_d     <= 1'b0;
            cpu_rec_state_w     <= 1'b0;
            rx_pending_r        <= 1'b0;
            rx_overrun_sticky_r <= 1'b0;
        end else begin
            cpu_rec_state_d <= cpu_rec_state_r;
            cpu_rec_state_w <= cpu_rec_state_r;

            // 中断清除不修改已发布的地址/长度，也不自动归还buffer ownership。
            if (int_state_clear || clear_inter) begin
                fpga_cpu_irq_req <= 1'b0;
                int_state_w_r    <= 1'b0;
            end

            if (cpu_rec_ack) begin
                rx_pending_r        <= 1'b0;
                rx_overrun_sticky_r <= 1'b0;
            end

            // 仅完整FDMA write突发完成后发布通知；如果CPU仍持有上一帧，保留原
            // 通知并置overrun，避免静默把软件尚未读取的地址语义替换成下一帧。
            if (rx_burst_done_fdma) begin
                if (!rx_pending_r || cpu_rec_ack) begin
                    fpga_cpu_start_addr <= RX_BASE_ADDR_LO + rx_fdma_waddr_raw;
                    fpga_cpu_len        <= FRAME_BYTES_32;
                    fpga_cpu_irq_req    <= 1'b1;
                    int_state_w_r       <= 1'b1;
                    rx_pending_r        <= 1'b1;
                end else begin
                    rx_overrun_sticky_r <= 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // 语义段 8：clear命令从FDMA域跨到Aurora域
    // ------------------------------------------------------------------
    // clear_inter是fdma域脉冲；用toggle CDC恢复user域单周期status_clear_user。
    // status_clear_toggle_user_d既用于边沿恢复，也必须在user复位时确定初始化。
    reg status_clear_toggle_fdma;                 // clear_inter跨到Aurora域的源toggle，每次清除命令翻转一次
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn)
            status_clear_toggle_fdma <= 1'b0;
        else if (clear_inter)
            status_clear_toggle_fdma <= ~status_clear_toggle_fdma;
    end

    wire status_clear_toggle_user;                // status_clear_toggle_fdma同步到aurora_user_clk域后的电平
    reg  status_clear_toggle_user_d;              // 同步后clear toggle的一拍延迟值，用于异或恢复脉冲
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_status_clear (
        .src_clk(fdma_clk), .src_in(status_clear_toggle_fdma),
        .dest_clk(aurora_user_clk), .dest_out(status_clear_toggle_user)
    );
    wire status_clear_user = status_clear_toggle_user ^ status_clear_toggle_user_d; // Aurora用户域恢复的单周期sticky清除事件

    // ------------------------------------------------------------------
    // 语义段 9：Aurora域帧协议检查与源域sticky
    // ------------------------------------------------------------------
    // 固定帧规则：第1个有效握手必须带SOF，第64个必须带EOF，末拍rem=111；
    // 帧外普通数据、帧内重复SOF、提前/延后EOF均置length error。
    // rx_frame_word_count统计的是已经完成rx_hs的word，不统计仅src_rdy而未ready。
    reg rx_in_frame;                              // RX帧上下文标志：SOF握手建立，合法EOF或掉链清除
    reg [8:0] rx_frame_word_count;                // 当前RX帧已真实握手的64位word计数
    reg rx_length_error_user_sticky;              // Aurora用户域RX帧长/SOF/EOF/rem错误锁存
    reg rx_overflow_user_sticky;                  // Aurora用户域RX FIFO overflow或valid&&!ready错误锁存
    reg tx_underflow_user_sticky;                 // Aurora用户域TX bridge供数不足错误锁存
    wire rx_hs = aurora_rx_src_rdy && aurora_rx_dst_rdy; // LocalLink RX真实数据握手，帧检查器唯一推进条件
    wire tx_underflow_user = tx_user_dbg_bus[0];  // 从TX用户域调试总线提取的underflow事件

    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin
        if (!aurora_user_rstn) begin
            status_clear_toggle_user_d  <= 1'b0;
            rx_in_frame                 <= 1'b0;
            rx_frame_word_count         <= 9'd0;
            rx_length_error_user_sticky <= 1'b0;
            rx_overflow_user_sticky     <= 1'b0;
            tx_underflow_user_sticky    <= 1'b0;
        end else begin
            status_clear_toggle_user_d <= status_clear_toggle_user;
            if (status_clear_user) begin
                rx_length_error_user_sticky <= 1'b0;
                rx_overflow_user_sticky     <= 1'b0;
                tx_underflow_user_sticky    <= 1'b0;
            end

            // FIFO原生overflow或上游valid而本地not-ready都表示输入无法保存。
            if (rx_fifo_overflow_user ||
                (aurora_rx_src_rdy && !aurora_rx_dst_rdy))
                rx_overflow_user_sticky <= 1'b1;
            if (tx_underflow_user)
                tx_underflow_user_sticky <= 1'b1;

            if (!link_up_user) begin
                rx_in_frame         <= 1'b0;
                rx_frame_word_count <= 9'd0;
            end else if (rx_hs) begin
                // SOF优先建立新帧上下文；SOF与EOF同拍只对1-word帧合法，当前
                // FRAME_WORDS=64，因此会被长度检查判错。
                if (aurora_rx_sof) begin
                    if (rx_in_frame)
                        rx_length_error_user_sticky <= 1'b1;
                    rx_in_frame         <= !aurora_rx_eof;
                    rx_frame_word_count <= 9'd1;
                    if (aurora_rx_eof &&
                        ((FRAME_WORDS != 1) || (aurora_rx_rem != 3'b111)))
                        rx_length_error_user_sticky <= 1'b1;
                end else if (!rx_in_frame) begin
                    rx_length_error_user_sticky <= 1'b1;
                // EOF到来时，之前已接收FRAME_WORDS-1个word才表示本拍为第64字。
                end else if (aurora_rx_eof) begin
                    if ((rx_frame_word_count != FRAME_WORDS - 1) ||
                        (aurora_rx_rem != 3'b111))
                        rx_length_error_user_sticky <= 1'b1;
                    rx_in_frame         <= 1'b0;
                    rx_frame_word_count <= 9'd0;
                end else if (rx_frame_word_count >= FRAME_WORDS - 1) begin
                    rx_length_error_user_sticky <= 1'b1;
                    rx_frame_word_count <= rx_frame_word_count + 9'd1;
                end else begin
                    rx_frame_word_count <= rx_frame_word_count + 9'd1;
                end
            end
        end
    end

    // user域sticky是电平而非脉冲；同步到fdma域后由最终sticky汇聚器锁存。
    wire rx_length_error_fdma;                    // 同步到fdma_clk域的RX帧规格错误sticky电平
    wire rx_overflow_fdma;                        // 同步到fdma_clk域的RX overflow sticky电平
    wire tx_underflow_fdma;                       // 同步到fdma_clk域的TX underflow sticky电平
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_rx_length_error (
        .src_clk(aurora_user_clk), .src_in(rx_length_error_user_sticky),
        .dest_clk(fdma_clk), .dest_out(rx_length_error_fdma)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_rx_overflow (
        .src_clk(aurora_user_clk), .src_in(rx_overflow_user_sticky),
        .dest_clk(fdma_clk), .dest_out(rx_overflow_fdma)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_tx_underflow (
        .src_clk(aurora_user_clk), .src_in(tx_underflow_user_sticky),
        .dest_clk(fdma_clk), .dest_out(tx_underflow_fdma)
    );

    // ------------------------------------------------------------------
    // 语义段 10：FDMA域sticky汇聚、清除握手和progress-aware timeout
    // ------------------------------------------------------------------
    // user_status_clear_hold解决一种CDC清除反弹：fdma域先清零后，user域旧的
    // sticky高电平仍可能在同步链中停留数拍。hold期间不重新采纳这些旧高电平，
    // 直到三个同步源全部返回0，之后才允许新的错误再次置位。
    //
    // timeout只检测“协议正在等待但没有前进”：请求被busy接受、读/写数据握手
    // 或RX突发完成都算progress并清计数。正常的长事务只要持续有数据就不超时。
    reg rx_overflow_sticky_r;                     // FDMA域最终RX overflow sticky寄存器
    reg tx_underflow_sticky_r;                    // FDMA域最终TX underflow sticky寄存器
    reg fdma_timeout_sticky_r;                    // FDMA域等待无进展超时sticky寄存器
    reg length_error_sticky_r;                    // FDMA域TX配置或RX帧规格错误汇总sticky寄存器
    reg link_down_sticky_r;                       // FDMA域命令时/活动期/曾up后掉链sticky寄存器
    reg seen_link_up;                             // 历史链路建立标志，用于抑制上电训练阶段的假掉链告警
    reg [31:0] fdma_wait_count;                   // FDMA连续等待且无progress的周期计数器
    reg user_status_clear_hold;                   // 跨域清除抑制窗口：源域旧高电平全部返回0前禁止重新吸收sticky

    assign rx_overflow_sticky  = rx_overflow_sticky_r;
    assign tx_underflow_sticky = tx_underflow_sticky_r;
    assign fdma_timeout_sticky = fdma_timeout_sticky_r;
    assign length_error_sticky = length_error_sticky_r;
    assign link_down_sticky    = link_down_sticky_r;

    // waiting覆盖请求未接受、读端等valid、写端等ready四类停顿。
    wire fdma_waiting = fdma_rareq || fdma_wareq ||
                        (fdma_rready && !fdma_rvalid) ||
                        (fdma_wvalid && !fdma_wready); // FDMA协议正在等待请求接受、读数据有效或写数据接受的汇总条件
    wire fdma_progress = (fdma_rareq && fdma_rbusy) ||
                         (fdma_wareq && fdma_wbusy) ||
                         (fdma_rvalid && fdma_rready) ||
                         (fdma_wvalid && fdma_wready) ||
                         rx_burst_done_fdma; // FDMA真实进展汇总：请求接受、数据握手或RX完整突发完成

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            rx_overflow_sticky_r  <= 1'b0;
            tx_underflow_sticky_r <= 1'b0;
            fdma_timeout_sticky_r <= 1'b0;
            length_error_sticky_r <= 1'b0;
            link_down_sticky_r    <= 1'b0;
            seen_link_up          <= 1'b0;
            fdma_wait_count       <= 32'd0;
            user_status_clear_hold <= 1'b0;
        end else begin
            // clear_inter清除最终软件可见sticky并启动跨域旧电平抑制窗口。
            if (clear_inter) begin
                rx_overflow_sticky_r  <= 1'b0;
                tx_underflow_sticky_r <= 1'b0;
                fdma_timeout_sticky_r <= 1'b0;
                length_error_sticky_r <= 1'b0;
                link_down_sticky_r    <= 1'b0;
                fdma_wait_count       <= 32'd0;
                // Source-domain sticky levels take several cycles to see the
                // clear toggle and then cross back. Suppress their stale high
                // levels until all synchronized sources have acknowledged 0.
                user_status_clear_hold <= 1'b1;
            end

            if (user_status_clear_hold && !rx_overflow_fdma &&
                !tx_underflow_fdma && !rx_length_error_fdma)
                user_status_clear_hold <= 1'b0;

            // 只有非清除周期且源域已确认清零后，才重新吸收user域sticky。
            if (!clear_inter && !user_status_clear_hold) begin
                if (rx_overflow_fdma)
                    rx_overflow_sticky_r <= 1'b1;
                if (tx_underflow_fdma)
                    tx_underflow_sticky_r <= 1'b1;
                if (rx_length_error_fdma)
                    length_error_sticky_r <= 1'b1;
            end
            if (tx_config_error_event)
                length_error_sticky_r <= 1'b1;
            if (tx_start_link_error || (tx_active && !link_up_fdma))
                link_down_sticky_r <= 1'b1;

            // seen_link_up避免上电初始链路尚未建立就误报link_down；只在曾经up后
            // 的下降，或软件在down状态强行启动TX时报告掉链。
            if (link_up_fdma)
                seen_link_up <= 1'b1;
            else if (seen_link_up)
                link_down_sticky_r <= 1'b1;

            if (fdma_progress || !fdma_waiting) begin
                fdma_wait_count <= 32'd0;
            end else if (fdma_wait_count >= FDMA_TIMEOUT_CYCLES - 1) begin
                fdma_timeout_sticky_r <= 1'b1;
            end else begin
                fdma_wait_count <= fdma_wait_count + 32'd1;
            end
        end
    end

    // 状态码零扩展为4 bit供ILA统一采样；不参与功能控制。
    assign dbg_tx_state = {2'b00, tx_fdma_dbg_bus[37:36]};
    assign dbg_rx_state = {2'b00, rx_fdma_dbg_bus[41:40]};

endmodule
```
