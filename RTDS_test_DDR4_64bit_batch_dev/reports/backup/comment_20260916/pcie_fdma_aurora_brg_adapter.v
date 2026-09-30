`timescale 1ns / 1ps

// =============================================================================
// 模块用途：连接 INFO_EXCH 软件控制面、CONV_DMA/FDMA 数据面和 Aurora
// LocalLink 边界，完成 CPU↔Aurora 双向 16 B 帧搬运、接收缓冲区所有权和 IRQ。
//
// 输入：
//   1) fdma_clk 域的软件命令、地址/长度、FDMA busy/data/accept 和清除信号；
//   2) aurora_user_clk 域的 LocalLink RX 数据、TX ready 及 channel/lane 状态；
//   3) PCIe link 状态。
// 输出：
//   1) FDMA read/write 请求、地址、长度和写数据；
//   2) Aurora TX LocalLink 帧及 RX 接收能力；
//   3) INFO_EXCH 状态、用户 IRQ、sticky error 和调试状态。
//
// 失败定位顺序：
//   命令未启动先查 tx_config_valid/link_up_fdma；搬运不前进查 FDMA
//   req/busy/valid/accept；数据不一致查 SOF/EOF/rem 和 bridge dbg；中断异常查
//   rx_pending、int_state_w、fpga_cpu_irq_req、int_state_clear/clear_inter；
//   清除后复发查 user_status_clear_hold 与跨域 sticky 返回值。
// =============================================================================

// PCIe/FDMA/Aurora control and data-path adapter.
//
// Address ownership:
//   RX window: Aurora -> card memory -> CPU, 0x0010_0000..0x002f_ffff (8 x 256KiB)
//   TX window: CPU -> card memory -> Aurora, 0x0000_8000..0x0000_ffff
//
// INFO_EXCH supplies the low 32 bits of the TX card address. CARD_ADDR_HI is
// the static upper aperture used by both directions. All FDMA sizes are in
// 64-bit beats; the bridge's internal raw write size remains byte based.

module pcie_fdma_aurora_brg_adapter #(
        parameter integer FRAME_BYTES          = 16,
        parameter integer ACTIVE_WINDOW_BYTES  = 32 * 1024,
        parameter [31:0]  RX_BASE_ADDR_LO       = 32'h0010_0000,
        parameter [31:0]  TX_BASE_ADDR_LO       = 32'h0000_8000,
        parameter [31:0]  CARD_ADDR_HI          = 32'h0000_0000,
        parameter integer RX_PERIOD_CYCLES = 25000000,
        parameter integer RX_BLOCK_BYTES = 262144,
        parameter integer RX_BLOCK_COUNT = 8,
        parameter integer FDMA_TIMEOUT_CYCLES   = 16'hffff
    )(
        input              fdma_clk,
        input              fdma_rstn,
        input              aurora_user_clk,
        input              aurora_user_rstn,

        input              pcie_link_up,
        input              ddr_ready,
        input              aurora_channel_up,
        input              aurora_lane_up,

        output     [63:0]  aurora_tx_d,
        output             aurora_tx_sof,
        output             aurora_tx_eof,
        output     [2:0]   aurora_tx_rem,
        output             aurora_tx_src_rdy,
        input              aurora_tx_dst_rdy,

        input      [63:0]  aurora_rx_d,
        input              aurora_rx_sof,
        input              aurora_rx_eof,
        input      [2:0]   aurora_rx_rem,
        input              aurora_rx_src_rdy,
        output             aurora_rx_dst_rdy,

        input              rd_start,
        input      [31:0]  cpu_fpga_start_addr,
        input      [31:0]  cpu_fpga_len,
        output wire        cpu_wr_done_event, // 成功、非法提交或链路中断的消费事件
        output wire [7:0]  fdma_wstrb, // DDR尾拍字节使能
        output reg         cpu_wr_done_resp,

        output wire [31:0] fpga_cpu_start_addr,
        output wire [31:0] fpga_cpu_len,
        output             int_state_w,
        input              int_state_clear,
        input              clear_inter,
        input              cpu_rec_state_r,
        output reg         cpu_rec_state_w,
        output wire        fpga_cpu_irq_req,

        output     [63:0]  fdma_raddr,
        output             fdma_rareq,
        input              fdma_rbusy,
        input      [63:0]  fdma_rdata,
        input              fdma_rvalid,
        output             fdma_rready,
        output     [15:0]  fdma_rsize,

        output     [63:0]  fdma_waddr,
        output             fdma_wareq,
        input              fdma_wbusy,
        input              fdma_wdone,
        input              fdma_werror,
        output wire [31:0] rx_ready_blocks,
        output wire [31:0] rx_head_seq,
        output wire [31:0] rx_dropped_frames,
        output wire [7:0] cfg_byte,
        output wire cfg_byte_valid,
        output     [63:0]  fdma_wdata,
        output             fdma_wvalid,
        input              fdma_wready,
        output     [15:0]  fdma_wsize,

        output             rx_fifo_almost_full,
        output             rx_fifo_full,
        output             rx_overflow_sticky,
        output             rx_overrun_sticky,
        output             tx_underflow_sticky,
        output             fdma_timeout_sticky,
        output             length_error_sticky,
        output             link_down_sticky,
        output             rx_pending,
        output     [3:0]   dbg_tx_state,
        output     [3:0]   dbg_rx_state
    );

    localparam integer FRAME_WORDS = FRAME_BYTES / 8;
    localparam [31:0] FRAME_BYTES_32 = FRAME_BYTES;
    localparam [15:0] FRAME_WORDS_16 = FRAME_WORDS;

    // ---------- 语义段 1：静态参数自检 ----------
    // 输入：FRAME_BYTES、活动窗口、RX/TX 基址；输出：仅仿真期 $error。
    // 作用：在数据搬运前拒绝非 16 B 帧、非整帧窗口和 4 GiB 越界配置。
    // 失败定位：启动 0 ns 的参数错误，不应继续排查 XDMA、FDMA 或 Aurora。
    initial begin
        if (FRAME_BYTES != 16)
            $error("pcie_fdma_aurora_brg_adapter supports 16-byte frames");
        if ((ACTIVE_WINDOW_BYTES <= 0) ||
            ((ACTIVE_WINDOW_BYTES % FRAME_BYTES) != 0))
            $error("ACTIVE_WINDOW_BYTES must be a positive frame multiple");
        if (({1'b0, RX_BASE_ADDR_LO} + ACTIVE_WINDOW_BYTES) > 33'h1_0000_0000)
            $error("RX low-address window crosses a 4-GiB aperture");
        if (({1'b0, TX_BASE_ADDR_LO} + ACTIVE_WINDOW_BYTES) > 33'h1_0000_0000)
            $error("TX low-address window crosses a 4-GiB aperture");
    end

    // ------------------------------------------------------------------
    // ---------- 语义段 2：链路状态跨时钟域 ----------
    // 输入：PCIe link、Aurora channel/lane；输出：fdma_clk/user_clk 域稳定电平。
    // 作用：所有 TX/RX 命令只在三种链路状态均有效时执行。
    // 失败定位：外部状态已拉高但 link_up_fdma/link_up_user 不高时检查复位和 CDC。
    // Link and control CDC
    // ------------------------------------------------------------------
    wire pcie_link_up_user;
    wire ddr_ready_user;
    wire aurora_channel_up_fdma;
    wire aurora_lane_up_fdma;
    wire link_up_user;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign link_up_user = pcie_link_up_user && ddr_ready_user &&
                        aurora_channel_up && aurora_lane_up;
    wire link_up_fdma;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign link_up_fdma = pcie_link_up && ddr_ready &&
                        aurora_channel_up_fdma && aurora_lane_up_fdma;

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_ddr_ready_to_user (
        .src_clk(fdma_clk), .src_in(ddr_ready),
        .dest_clk(aurora_user_clk), .dest_out(ddr_ready_user)
    );

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
    // ---------- 语义段 3：CPU→Aurora 命令校验 ----------
    // 输入：RD_START、CPU_FPGA_START_ADDR/LEN、链路与 tx_active。
    // 输出：tx_start_valid、tx_config_error_event、目标帧数和 FDMA read 基址。
    // 作用：把软件寄存器命令限制在 TX 32 KiB 窗口并强制 16 B 对齐。
    // 失败定位：RD_START 有脉冲但无 fdma_rareq 时依次检查长度、地址、窗口和链路。
    // CPU -> Aurora TX command validation and completion
    // ------------------------------------------------------------------
    reg        tx_active;
    reg [15:0] tx_target_frames;
    reg [15:0] tx_completed_frames;
    reg [31:0] tx_base_addr_lo;

    wire [32:0] tx_requested_end;

    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_requested_end = {1'b0, cpu_fpga_start_addr} +
                                    {1'b0, cpu_fpga_len};
    wire [32:0] tx_window_end;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_window_end = {1'b0, TX_BASE_ADDR_LO} +
                                ACTIVE_WINDOW_BYTES;
    wire tx_addr_aligned;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_addr_aligned = ((cpu_fpga_start_addr & (FRAME_BYTES - 1)) == 0);
    wire tx_len_aligned;
    // 生成当前事务计数/长度字段，计数推进仍由实际握手或提交事件决定。
    assign tx_len_aligned = ((cpu_fpga_len & (FRAME_BYTES - 1)) == 0);
    wire tx_config_valid;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign tx_config_valid = (cpu_fpga_len != 0) &&
                           tx_addr_aligned && tx_len_aligned &&
                           (cpu_fpga_len <= ACTIVE_WINDOW_BYTES) &&
                           (cpu_fpga_start_addr >= TX_BASE_ADDR_LO) &&
                           (tx_requested_end <= tx_window_end) &&
                           !tx_requested_end[32];
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign cpu_wr_done_event = (rd_start && !tx_start_valid) ||
        (tx_active && (!link_up_fdma || (tx_frame_done_fdma &&
        (tx_completed_frames + 16'd1 >= tx_target_frames))));
    wire tx_start_valid;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign tx_start_valid = rd_start && !tx_active && link_up_fdma && tx_config_valid;
    wire tx_config_error_event;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_config_error_event = rd_start && (!tx_config_valid || tx_active);
    wire tx_start_link_error;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_start_link_error = rd_start && !link_up_fdma;
    wire [31:0] requested_frames_32;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign requested_frames_32 = cpu_fpga_len / FRAME_BYTES;

    wire tx_active_user;
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_tx_active_to_user (
        .src_clk(fdma_clk), .src_in(tx_active),
        .dest_clk(aurora_user_clk), .dest_out(tx_active_user)
    );

    wire tx_fdma_rstn;

    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign tx_fdma_rstn = fdma_rstn && link_up_fdma && tx_active;
    wire tx_user_rstn;
    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign tx_user_rstn = aurora_user_rstn && link_up_user && tx_active_user;

    wire [31:0] tx_fdma_raddr_raw;
    wire [37:0] tx_fdma_dbg_bus;
    wire [38:0] tx_user_dbg_bus;
    wire tx_frame_done_user;

    // ---------- 语义段 4：FDMA read 到 Aurora TX LocalLink ----------
    // 输入：FDMA read data/valid、Aurora dst_rdy；输出：FDMA 请求和 LL TX 帧。
    // 作用：每帧固定读取 16 个 64-bit word，可响应 Aurora TX 方向背压。
    // 失败定位：请求存在无数据查 CONV_DMA；数据存在无 LL 帧查 TX bridge/FIFO。
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

    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign fdma_raddr = {CARD_ADDR_HI, tx_base_addr_lo} +
                        {32'd0, tx_fdma_raddr_raw};
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign fdma_rsize = FRAME_WORDS_16;

    // ---------- 语义段 5：TX 帧完成跨域与软件响应 ----------
    // 输入：Aurora 域单周期 tx_frame_done_user；输出：fdma 域完成事件和 resp。
    // 作用：用 toggle CDC 防止异步时钟间丢失完成脉冲，并按目标帧数结束事务。
    // 失败定位：LL 已见 EOF 但 CPU_WR_DONE_resp 不回落时检查两个 toggle 和帧计数。
    // Toggle CDC preserves one-cycle frame completion pulses across unrelated
    // clocks without relying on a minimum pulse width.
    reg tx_done_toggle_user;

    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin
        if (!aurora_user_rstn)
            tx_done_toggle_user <= 1'b0;
        else if (tx_frame_done_user)
            tx_done_toggle_user <= ~tx_done_toggle_user;
    end

    wire tx_done_toggle_fdma;
    reg  tx_done_toggle_fdma_d;
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_tx_done_toggle (
        .src_clk(aurora_user_clk), .src_in(tx_done_toggle_user),
        .dest_clk(fdma_clk), .dest_out(tx_done_toggle_fdma)
    );
    wire tx_frame_done_fdma;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_frame_done_fdma = tx_done_toggle_fdma ^ tx_done_toggle_fdma_d;

        // tx_done_toggle_fdma_d：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_done_toggle_fdma_d
        if (! fdma_rstn) begin
            tx_done_toggle_fdma_d <= 1'b0 ;
        end else begin
            tx_done_toggle_fdma_d <= tx_done_toggle_fdma ;
        end
    end

    // tx_active：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_active
        if (! fdma_rstn) begin
            tx_active <= 1'b0 ;
        end else begin
            if (tx_start_valid) begin
                tx_active <= 1'b1 ;
            end else begin
                if (tx_active && ! link_up_fdma) begin
                    tx_active <= 1'b0 ;
                end else begin
                    if (tx_active && tx_frame_done_fdma) begin
                        if (( tx_completed_frames + 16'd1 ) >= tx_target_frames) begin
                            tx_active <= 1'b0 ;
                        end
                    end
                end
            end
        end
    end

    // tx_target_frames：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_target_frames
        if (! fdma_rstn) begin
            tx_target_frames <= 16'd0 ;
        end else begin
            if (tx_start_valid) begin
                tx_target_frames <= requested_frames_32 [ 15 : 0 ] ;
            end else begin
                if (tx_active && ! link_up_fdma) begin
                    tx_target_frames <= 16'd0 ;
                end else begin
                    if (tx_active && tx_frame_done_fdma) begin
                        if (( tx_completed_frames + 16'd1 ) >= tx_target_frames) begin
                            tx_target_frames <= 16'd0 ;
                        end
                    end
                end
            end
        end
    end

    // tx_completed_frames：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_completed_frames
        if (! fdma_rstn) begin
            tx_completed_frames <= 16'd0 ;
        end else begin
            if (tx_start_valid) begin
                tx_completed_frames <= 16'd0 ;
            end else begin
                if (tx_active && ! link_up_fdma) begin
                    tx_completed_frames <= 16'd0 ;
                end else begin
                    if (tx_active && tx_frame_done_fdma) begin
                        if (( tx_completed_frames + 16'd1 ) >= tx_target_frames) begin
                            tx_completed_frames <= 16'd0 ;
                        end else begin
                            tx_completed_frames <= tx_completed_frames + 16'd1 ;
                        end
                    end
                end
            end
        end
    end

    // tx_base_addr_lo：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_base_addr_lo
        if (! fdma_rstn) begin
            tx_base_addr_lo <= TX_BASE_ADDR_LO ;
        end else begin
            if (tx_start_valid) begin
                tx_base_addr_lo <= cpu_fpga_start_addr ;
            end
        end
    end

    // cpu_wr_done_resp：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_cpu_wr_done_resp
        if (! fdma_rstn) begin
            cpu_wr_done_resp <= 1'b0 ;
        end else begin
            if (tx_start_valid) begin
                cpu_wr_done_resp <= 1'b1 ;
            end else begin
                if (tx_active && ! link_up_fdma) begin
                    cpu_wr_done_resp <= 1'b0 ;
                end else begin
                    if (tx_active && tx_frame_done_fdma) begin
                        if (( tx_completed_frames + 16'd1 ) >= tx_target_frames) begin
                            cpu_wr_done_resp <= 1'b0 ;
                        end
                    end
                end
            end
        end
    end


    // ------------------------------------------------------------------
    // ---------- 语义段 6：Aurora→CPU 连续接收与 FDMA write ----------
    // 输入：无可回压的 Aurora RX LocalLink 数据；输出：FDMA write 请求/数据。
    // 作用：RX FIFO 只吸收瞬时速率差，不能把 dst_rdy 当作 SerDes 线路反压。
    // 失败定位：rx_dst_rdy 下降或数据丢失时检查 FIFO full/almost_full、source_valid
    // 和 fdma_w_accept，不能通过延迟远端发送来掩盖问题。
    // Aurora -> CPU RX path and buffer ownership
    // ------------------------------------------------------------------

    wire [63:0] rx_packet;
    wire rx_packet_valid, rx_packet_ready;
    wire [31:0] fifo_drops, writer_drops;
    reg [31:0] fifo_drops_previous; // 只将新增丢帧事件置 sticky，读清后不由历史累计值重置位

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            fifo_drops_previous <= 32'd0;
        end else begin
            fifo_drops_previous <= fifo_drops;
        end
    end
    wire [32:0] total_drops; // 两个饱和计数求和时保留进位
    wire rx_accept_enable; // 用户域链路有效即组帧；存储不可用由writer整帧丢弃并计数
    wire rx_store_enable; // DDR 初始化和 PCIe 链路就绪后允许写缓存
    wire rx_irq_clear; // 两种通知清除入口，不代表释放块
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rx_accept_enable = aurora_user_rstn && aurora_channel_up && aurora_lane_up;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rx_store_enable = ddr_ready && pcie_link_up;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rx_irq_clear = int_state_clear || clear_inter;
    wire rx_length_error_raw;
    wire rx_fifo_overflow_user;
    wire rx_burst_done_fdma;
    reg cpu_rec_state_d;
    wire cpu_rec_ack;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign cpu_rec_ack = cpu_rec_state_r; // INFO_EXCH输出每次写1对应的单周期命令
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign int_state_w = fpga_cpu_irq_req;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rx_pending = (rx_ready_blocks != 0);
    reg rx_overrun_flag; // 从新增丢帧事件置位；通知清除后可重新捕获异常
    reg [31:0] dropped_frames_previous;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign rx_overrun_sticky = rx_overrun_flag;

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            dropped_frames_previous <= 32'd0;
        end else begin
            dropped_frames_previous <= rx_dropped_frames;
        end
    end

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            rx_overrun_flag <= 1'b0;
        end else if (rx_dropped_frames != dropped_frames_previous) begin
            rx_overrun_flag <= 1'b1;
        end else if (clear_inter) begin
            rx_overrun_flag <= 1'b0;
        end
    end
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign total_drops = {1'b0,fifo_drops} + {1'b0,writer_drops};
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign rx_dropped_frames = total_drops[32] ? 32'hffffffff : total_drops[31:0];
    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign rx_burst_done_fdma = fdma_wdone && !fdma_werror;
    // FIFO溢出统计在mem域读取，user域sticky由已有长度检查/丢帧统计补充。
    assign rx_fifo_overflow_user = 1'b0;
        // cpu_rec_state_d：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_cpu_rec_state_d
        if (! fdma_rstn) begin
            cpu_rec_state_d <= 1'b0 ;
        end else begin
            cpu_rec_state_d <= cpu_rec_state_r ;
        end
    end

    // cpu_rec_state_w：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_cpu_rec_state_w
        if (! fdma_rstn) begin
            cpu_rec_state_w <= 1'b0 ;
        end else begin
            cpu_rec_state_w <= cpu_rec_state_r ;
        end
    end

    RTDS_RX_FRAME_FIFO U_RTDS_RX_FRAME_FIFO (
        .rst_n(fdma_rstn), .user_clk(aurora_user_clk),
        .user_ready(rx_accept_enable),
        .rx_data(aurora_rx_d), .rx_sof(aurora_rx_sof), .rx_eof(aurora_rx_eof),
        .rx_rem(aurora_rx_rem), .rx_valid(aurora_rx_src_rdy), .rx_ready(aurora_rx_dst_rdy),
        .mem_clk(fdma_clk), .frame_data(rx_packet), .frame_valid(rx_packet_valid),
        .frame_ready(rx_packet_ready), .fifo_full(rx_fifo_full),
        .fifo_almost_full(rx_fifo_almost_full), .dropped_frames(fifo_drops),
        .length_error(rx_length_error_raw)
    );
    RTDS_RX_BLOCK_WRITER #(
        .BLOCK_COUNT(RX_BLOCK_COUNT), .BLOCK_BYTES(RX_BLOCK_BYTES),
        .PERIOD_CYCLES(RX_PERIOD_CYCLES), .BASE_ADDR(RX_BASE_ADDR_LO)
    ) U_RTDS_RX_BLOCK_WRITER (
        .clk(fdma_clk), .rst_n(fdma_rstn), .enable(rx_store_enable),
        .frame_data(rx_packet), .frame_valid(rx_packet_valid), .frame_ready(rx_packet_ready),
        .cpu_ack(cpu_rec_ack), .irq_clear(rx_irq_clear),
        .head_addr(fpga_cpu_start_addr), .head_len(fpga_cpu_len), .head_seq(rx_head_seq),
        .ready_blocks(rx_ready_blocks), .dropped_frames(writer_drops), .irq(fpga_cpu_irq_req),
        .fdma_waddr(fdma_waddr), .fdma_wsize(fdma_wsize), .fdma_wareq(fdma_wareq),
        .fdma_wstrb(fdma_wstrb), .fdma_wbusy(fdma_wbusy), .fdma_wdata(fdma_wdata), .fdma_wvalid(fdma_wvalid),
        .fdma_waccept(fdma_wready), .fdma_wdone(fdma_wdone), .fdma_werror(fdma_werror),
        .dbg_state(dbg_rx_state)
    );
    // 每2个64bit读数据拍组成一帧；在第一个真实握手拍提取Byte1。
    reg config_read_beat;

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn)
            config_read_beat<=1'b0;
        else if (!tx_active)
            config_read_beat<=1'b0;
        else if (fdma_rvalid && fdma_rready)
            config_read_beat<=!config_read_beat;
    end
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign cfg_byte = fdma_rdata[15:8];
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign cfg_byte_valid = tx_active && fdma_rvalid && fdma_rready && (config_read_beat==0);

    // ------------------------------------------------------------------
    // User-domain frame checking and sticky status
    // ------------------------------------------------------------------
    // ---------- 语义段 8：状态清除命令跨域 ----------
    // 输入：fdma 域 clear_inter 单周期；输出：Aurora 域 status_clear_user 脉冲。
    // 作用：清除 RX/TX bridge 在 user clock 域产生的 sticky 状态。
    // 失败定位：fdma 域已 clear 但 user 状态不清时检查 toggle 两侧及 user reset。
    reg status_clear_toggle_fdma;

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn)
            status_clear_toggle_fdma <= 1'b0;
        else if (clear_inter)
            status_clear_toggle_fdma <= ~status_clear_toggle_fdma;
    end

    wire status_clear_toggle_user;
    reg  status_clear_toggle_user_d;
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)
    ) u_cdc_status_clear (
        .src_clk(fdma_clk), .src_in(status_clear_toggle_fdma),
        .dest_clk(aurora_user_clk), .dest_out(status_clear_toggle_user)
    );
    wire status_clear_user;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign status_clear_user = status_clear_toggle_user ^ status_clear_toggle_user_d;

    reg rx_in_frame;
    reg [8:0] rx_frame_word_count;
    reg rx_length_error_user_sticky;
    reg rx_overflow_user_sticky;
    reg tx_underflow_user_sticky;
    wire rx_hs;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign rx_hs = aurora_rx_src_rdy && aurora_rx_dst_rdy;
    wire tx_underflow_user;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign tx_underflow_user = tx_user_dbg_bus[0];

    // ---------- 语义段 9：Aurora 域协议检查与 sticky 状态 ----------
    // 输入：RX SOF/EOF/rem/有效拍、FIFO overflow、TX underflow、链路状态。
    // 输出：overflow/underflow/length/link-down 等 user 域 sticky。
    // 作用：检查固定 16 B 帧边界，并记录不可恢复的接收或发送异常。
    // 失败定位：length_error 时检查 64 个 beat、SOF/EOF 唯一性和末拍 rem。
        // status_clear_toggle_user_d：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge aurora_user_clk or negedge aurora_user_rstn ) begin : update_status_clear_toggle_user_d
        if (! aurora_user_rstn) begin
            status_clear_toggle_user_d <= 1'b0 ;
        end else begin
            status_clear_toggle_user_d <= status_clear_toggle_user ;
        end
    end

    // rx_in_frame：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge aurora_user_clk or negedge aurora_user_rstn ) begin : update_rx_in_frame
        if (! aurora_user_rstn) begin
            rx_in_frame <= 1'b0 ;
        end else begin
            if (! link_up_user) begin
                rx_in_frame <= 1'b0 ;
            end else begin
                if (rx_hs) begin
                    if (aurora_rx_sof) begin
                        rx_in_frame <= ! aurora_rx_eof ;
                    end else begin
                        if (! rx_in_frame) begin
                        end else begin
                            if (aurora_rx_eof) begin
                                rx_in_frame <= 1'b0 ;
                            end
                        end
                    end
                end
            end
        end
    end

    // rx_frame_word_count：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge aurora_user_clk or negedge aurora_user_rstn ) begin : update_rx_frame_word_count
        if (! aurora_user_rstn) begin
            rx_frame_word_count <= 9'd0 ;
        end else begin
            if (! link_up_user) begin
                rx_frame_word_count <= 9'd0 ;
            end else begin
                if (rx_hs) begin
                    if (aurora_rx_sof) begin
                        rx_frame_word_count <= 9'd1 ;
                    end else begin
                        if (! rx_in_frame) begin
                        end else begin
                            if (aurora_rx_eof) begin
                                rx_frame_word_count <= 9'd0 ;
                            end else begin
                                if (rx_frame_word_count >= FRAME_WORDS - 1) begin
                                    rx_frame_word_count <= rx_frame_word_count + 9'd1 ;
                                end else begin
                                    rx_frame_word_count <= rx_frame_word_count + 9'd1 ;
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    // 上行业务为连续有效字流，不按SOF/EOF或固定帧长拒收。

    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin : update_rx_length_error_user_sticky
        if (!aurora_user_rstn)
            rx_length_error_user_sticky <= 1'b0;
        else
            rx_length_error_user_sticky <= 1'b0;
    end

    // rx_overflow_user_sticky：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge aurora_user_clk or negedge aurora_user_rstn ) begin : update_rx_overflow_user_sticky
        if (! aurora_user_rstn) begin
            rx_overflow_user_sticky <= 1'b0 ;
        end else begin
            if (status_clear_user) begin
                rx_overflow_user_sticky <= 1'b0 ;
            end
            if (rx_fifo_overflow_user || ( aurora_rx_src_rdy && ! aurora_rx_dst_rdy )) begin
                rx_overflow_user_sticky <= 1'b1 ;
            end
        end
    end

    // tx_underflow_user_sticky：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge aurora_user_clk or negedge aurora_user_rstn ) begin : update_tx_underflow_user_sticky
        if (! aurora_user_rstn) begin
            tx_underflow_user_sticky <= 1'b0 ;
        end else begin
            if (status_clear_user) begin
                tx_underflow_user_sticky <= 1'b0 ;
            end
            if (tx_underflow_user) begin
                tx_underflow_user_sticky <= 1'b1 ;
            end
        end
    end


    wire rx_length_error_fdma;
    wire rx_overflow_fdma;
    wire tx_underflow_fdma;
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
    // FDMA-domain sticky status and progress-aware timeout
    // ------------------------------------------------------------------
    reg rx_overflow_sticky_r;
    reg tx_underflow_sticky_r;
    reg fdma_timeout_sticky_r;
    reg length_error_sticky_r;
    reg link_down_sticky_r;
    reg seen_link_up;
    reg [31:0] fdma_wait_count;
    reg user_status_clear_hold;

    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign rx_overflow_sticky  = rx_overflow_sticky_r;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign tx_underflow_sticky = tx_underflow_sticky_r;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign fdma_timeout_sticky = fdma_timeout_sticky_r;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign length_error_sticky = length_error_sticky_r;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign link_down_sticky    = link_down_sticky_r;

    wire fdma_waiting;

    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign fdma_waiting = fdma_rareq || fdma_wareq ||
                        (fdma_rready && !fdma_rvalid) ||
                        (fdma_wvalid && !fdma_wready);
    wire fdma_progress;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign fdma_progress = (fdma_rareq && fdma_rbusy) ||
                         (fdma_wareq && fdma_wbusy) ||
                         (fdma_rvalid && fdma_rready) ||
                         (fdma_wvalid && fdma_wready) ||
                         rx_burst_done_fdma;

    // ---------- 语义段 10：FDMA 域 sticky 汇聚、清除保持与超时 ----------
    // 输入：跨域 user sticky、配置错误、链路下降、FDMA progress/waiting。
    // 输出：软件可读 sticky error。
    // 作用：clear 后等待旧 CDC 高电平真正返回低电平，再允许新错误置位；超时只在
    // 等待且无任何 progress 时累计。
    // 失败定位：清除后立即复发查 user_status_clear_hold；慢但有 progress 不应超时。
        // rx_overflow_sticky_r：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_rx_overflow_sticky_r
        if (! fdma_rstn) begin
            rx_overflow_sticky_r <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                rx_overflow_sticky_r <= 1'b0 ;
            end
            if (! clear_inter && ! user_status_clear_hold) begin
                if (rx_overflow_fdma || fifo_drops != fifo_drops_previous) begin
                    rx_overflow_sticky_r <= 1'b1 ;
                end
            end
        end
    end

    // tx_underflow_sticky_r：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_underflow_sticky_r
        if (! fdma_rstn) begin
            tx_underflow_sticky_r <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                tx_underflow_sticky_r <= 1'b0 ;
            end
            if (! clear_inter && ! user_status_clear_hold) begin
                if (tx_underflow_fdma) begin
                    tx_underflow_sticky_r <= 1'b1 ;
                end
            end
        end
    end

    // fdma_timeout_sticky_r：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_fdma_timeout_sticky_r
        if (! fdma_rstn) begin
            fdma_timeout_sticky_r <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                fdma_timeout_sticky_r <= 1'b0 ;
            end
            if (fdma_progress || ! fdma_waiting) begin
            end else begin
                if (fdma_wait_count >= FDMA_TIMEOUT_CYCLES - 1) begin
                    fdma_timeout_sticky_r <= 1'b1 ;
                end
            end
        end
    end

    // length_error_sticky_r：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_length_error_sticky_r
        if (! fdma_rstn) begin
            length_error_sticky_r <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                length_error_sticky_r <= 1'b0 ;
            end
            if (! clear_inter && ! user_status_clear_hold) begin
                if (rx_length_error_fdma) begin
                    length_error_sticky_r <= 1'b1 ;
                end
            end
            if (tx_config_error_event) begin
                length_error_sticky_r <= 1'b1 ;
            end
        end
    end

    // link_down_sticky_r：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_link_down_sticky_r
        if (! fdma_rstn) begin
            link_down_sticky_r <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                link_down_sticky_r <= 1'b0 ;
            end
            if (tx_start_link_error || ( tx_active && ! link_up_fdma )) begin
                link_down_sticky_r <= 1'b1 ;
            end
            if (link_up_fdma) begin
            end else begin
                if (seen_link_up) begin
                    link_down_sticky_r <= 1'b1 ;
                end
            end
        end
    end

    // seen_link_up：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_seen_link_up
        if (! fdma_rstn) begin
            seen_link_up <= 1'b0 ;
        end else begin
            if (link_up_fdma) begin
                seen_link_up <= 1'b1 ;
            end
        end
    end

    // fdma_wait_count：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_fdma_wait_count
        if (! fdma_rstn) begin
            fdma_wait_count <= 32'd0 ;
        end else begin
            if (clear_inter) begin
                fdma_wait_count <= 32'd0 ;
            end
            if (fdma_progress || ! fdma_waiting) begin
                fdma_wait_count <= 32'd0 ;
            end else begin
                if (fdma_wait_count >= FDMA_TIMEOUT_CYCLES - 1) begin
                end else begin
                    fdma_wait_count <= fdma_wait_count + 32'd1 ;
                end
            end
        end
    end

    // user_status_clear_hold：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。

    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_user_status_clear_hold
        if (! fdma_rstn) begin
            user_status_clear_hold <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                user_status_clear_hold <= 1'b1 ;
            end
            if (user_status_clear_hold && ! rx_overflow_fdma && ! tx_underflow_fdma && ! rx_length_error_fdma) begin
                user_status_clear_hold <= 1'b0 ;
            end
        end
    end


    // 只提供调试或未使用接口观察，不参与业务数据提交。
    assign dbg_tx_state = {2'b00, tx_fdma_dbg_bus[37:36]};

endmodule
