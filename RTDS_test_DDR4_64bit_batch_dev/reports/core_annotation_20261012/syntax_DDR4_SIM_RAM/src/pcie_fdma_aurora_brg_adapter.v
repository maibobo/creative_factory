// 连接软件控制、CONV_DMA读写和Aurora 10G用户接口。
// 下行把DDR载荷按16Byte帧发送，并在每帧首个已接受读拍提取Byte1。
// 上行每个有效拍取低32bit，经异步FIFO、拼接和块写模块保存到DDR。
// 链路或DDR失效后停止业务交付，但继续接收旧读，防止旧数据混入下一任务。
// 重新允许任务需旧读结束、用户域桥停止确认及8拍无旧完成事件；正常结束可暂存一条下一命令。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。
// 功能修改 2026-10-11：旧读排空、用户停止确认、跨任务完成事件隔离及正常下一命令暂存。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module pcie_fdma_aurora_brg_adapter #(
        parameter integer                             FRAME_BYTES          = 16,               // 单帧字节数，当前16Byte
        parameter integer                             ACTIVE_WINDOW_BYTES  = 32 * 1024,        // 允许的下行数据字节范围
        parameter     [31:0]                       RX_BASE_ADDR_LO       = 32'h0010_0000,      // 本模块RX_BASE_ADDR_LO固定配置/状态编码
        parameter     [31:0]                       TX_BASE_ADDR_LO       = 32'h0000_8000,      // 当前任务锁定的DDR低32bit起始地址
        parameter     [31:0]                       CARD_ADDR_HI          = 32'h0000_0000,      // 卡端地址高32bit，当前使用0
        parameter integer                             RX_PERIOD_CYCLES = 25000000,             // 上行接收周期拍数，生产值25000000
        parameter integer                             RX_BLOCK_BYTES = 262144,                 // 本模块RX_BLOCK_BYTES固定配置/状态编码
        parameter integer                             RX_BLOCK_COUNT = 8,                      // 本模块RX_BLOCK_COUNT固定配置/状态编码
        parameter integer                             FDMA_TIMEOUT_CYCLES   = 16'hffff         // FDMA持续无进展的诊断阈值拍数
    )(
        input                                      fdma_clk,                                   // 对应接口时钟，使用域由连接关系确定
        input                                      fdma_rstn,                                  // FDMA域低有效复位
        input                                      aurora_user_clk,                            // 对应接口时钟，使用域由连接关系确定
        input                                      aurora_user_rstn,                           // 低有效复位或同步复位状态

        input                                      pcie_link_up,                               // 对应链路就绪状态，跨域副本按后缀区分
        input                                      ddr_ready,                                  // 存储接口可用且旧读写错误事务已结束，可接收新业务
        input                                      aurora_channel_up,                          // 对应链路就绪状态，跨域副本按后缀区分
        input                                      aurora_lane_up,                             // 对应链路就绪状态，跨域副本按后缀区分

        output        [63:0]                       aurora_tx_d,                                // 发送当前数据拍
        output                                     aurora_tx_sof,                              // 当前帧首拍标志，与有效/接受共同使用
        output                                     aurora_tx_eof,                              // 当前帧末拍标志，与有效/接受共同使用
        output        [2:0]                        aurora_tx_rem,                              // 当前拍有效字节数减1
        output                                     aurora_tx_src_rdy,                          // 当前数据/事件有效
        input                                      aurora_tx_dst_rdy,                          // 当前通道可接受数据或业务

        input         [63:0]                       aurora_rx_d,                                // 接收当前数据拍
        input                                      aurora_rx_sof,                              // 当前帧首拍标志，与有效/接受共同使用
        input                                      aurora_rx_eof,                              // 当前帧末拍标志，与有效/接受共同使用
        input         [2:0]                        aurora_rx_rem,                              // 当前拍有效字节数减1
        input                                      aurora_rx_src_rdy,                          // 当前数据/事件有效
        output                                     aurora_rx_dst_rdy,                          // 当前通道可接受数据或业务

        input                                      rd_start,                                   // INFO_EXCH发出的单拍下行启动命令
        input         [31:0]                       cpu_fpga_start_addr,                        // 软件配置的下行DDR起始字节地址
        input         [31:0]                       cpu_fpga_len,                               // 软件配置的下行字节长度
        output wire                                cpu_wr_done_event,                          // 本条下行命令结束单拍，成功/拒绝/失效均可能触发
        output wire   [7:0]                        fdma_wstrb,                                 // DDR尾拍字节使能
        output reg                                 cpu_wr_done_resp,                           // 下行业务任务响应忙状态

        output wire   [31:0]                       fpga_cpu_start_addr,                        // 最早待读块的DDR字节地址
        output wire   [31:0]                       fpga_cpu_len,                               // 最早待读块成功写入的字节长度
        output                                     int_state_w,                                // 当前待读块的通知状态
        input                                      int_state_clear,                            // 软件读0x10形成的清通知单拍
        input                                      clear_inter,                                // 软件读0x10形成的清相关错误单拍
        input                                      cpu_rec_state_r,                            // 软件写0x14形成的CPU读完确认
        output reg                                 cpu_rec_state_w,                            // CPU确认状态返回寄存器侧
        output wire                                fpga_cpu_irq_req,                           // 有待读块时向XDMA申请中断

        output        [63:0]                       fdma_raddr,                                 // FDMA 读地址=静态高32位+TX基址+bridge游标
        output                                     fdma_rareq,                                 // 断链后不再接受桥发出的新读请求
        input                                      fdma_rbusy,                                 // 读请求仍在处理
        input         [63:0]                       fdma_rdata,                                 // 当前读数据
        input                                      fdma_rvalid,                                // 读数据已接受事件
        output                                     fdma_rready,                                // 有旧读事务时继续排空；空闲时撤销ready，避免误计无进展超时
        output        [15:0]                       fdma_rsize,                                 // FDMA 读突发固定 2 拍（16B 帧）

        output        [63:0]                       fdma_waddr,                                 // 写起始字节地址
        output                                     fdma_wareq,                                 // 写请求，保持到busy接受
        input                                      fdma_wbusy,                                 // 写请求仍在处理，包含等待响应
        input                                      fdma_wdone,                                 // 本次写最终响应完成单拍
        input                                      fdma_werror,                                // 本次写错误，与done共同判断
        output wire   [31:0]                       rx_ready_blocks,                            // 已经完整写入且等待CPU读取的块数量
        output wire   [31:0]                       rx_head_seq,                                // 最早待读块的顺序编号
        output wire   [31:0]                       rx_dropped_frames,                          // FIFO和块写统计的累计丢失32bit字数
        output wire   [7:0]                        cfg_byte,                                   // 首读拍Byte1配置编号
        output wire                                cfg_byte_valid,                             // 该帧首读拍被实际接受的配置事件
        output        [63:0]                       fdma_wdata,                                 // 当前写数据
        output                                     fdma_wvalid,                                // 写有效/接受信号，方向含义见模块头
        input                                      fdma_wready,                                // 写接受/有效信号，方向含义见模块头
        output        [15:0]                       fdma_wsize,                                 // 写请求64bit拍数

        output                                     rx_fifo_almost_full,                        // FIFO接近满，需暂停继续输入
        output                                     rx_fifo_full,                               // FIFO当前已满
        output                                     rx_overflow_sticky,                         // RX 溢出 sticky 输出
        output                                     rx_overrun_sticky,                          // RX 丢字增长 sticky（clear 后可重捕获）
        output                                     tx_underflow_sticky,                        // TX 下溢 sticky 输出
        output                                     fdma_timeout_sticky,                        // FDMA 超时 sticky 输出
        output                                     length_error_sticky,                        // 帧长错误 sticky 输出
        output                                     link_down_sticky,                           // 链路断 sticky 输出
        output                                     rx_pending,                                 // 至少有一个完整上行块等待CPU读取确认
        output        [3:0]                        dbg_tx_state,                               // 下行桥当前状态
        output        [3:0]                        dbg_rx_state                                // 上行块写模块当前状态
    );

    localparam integer                             FRAME_WORDS = FRAME_BYTES / 8     ;    // 本模块FRAME_WORDS固定配置/状态编码
    localparam    [31:0]                       FRAME_BYTES_32 = FRAME_BYTES          ;    // 本模块FRAME_BYTES_32固定配置/状态编码
    localparam    [15:0]                       FRAME_WORDS_16 = FRAME_WORDS          ;    // 本模块FRAME_WORDS_16固定配置/状态编码


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


    // 将PCIe、DDR和Aurora就绪分别同步到使用域。
    wire                                       pcie_link_up_user                     ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       pcie_link_up_fdma                     ;    // 对应链路就绪状态，跨域副本按后缀区分

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(1),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_pcie_link_to_fdma (
        .src_clk(1'b0),
        .src_in(pcie_link_up),
        .dest_clk(fdma_clk),
        .dest_out(pcie_link_up_fdma)
    );
    wire                                       ddr_ready_user                        ;    // DDR业务ready同步到Aurora用户域
    wire                                       aurora_channel_up_fdma                ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       aurora_lane_up_fdma                   ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       link_up_user                          ;    // 用户域命令门控：PCIe/DDR/Aurora 三链路状态全有效

    assign link_up_user = pcie_link_up_user && ddr_ready_user &&
                        aurora_channel_up && aurora_lane_up                          ;    // 用户域命令门控：PCIe/DDR/Aurora 三链路状态全有效
    wire                                       link_up_fdma                          ;    // FDMA侧命令门控：PCIe/DDR/Aurora 三链路状态全有效

    assign link_up_fdma = pcie_link_up_fdma && ddr_ready &&
                        aurora_channel_up_fdma && aurora_lane_up_fdma                ;    // FDMA侧命令门控：PCIe/DDR/Aurora 三链路状态全有效

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_ddr_ready_to_user (
        .src_clk(fdma_clk),
        .src_in(ddr_ready),
        .dest_clk(aurora_user_clk),
        .dest_out(ddr_ready_user)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_pcie_link_to_user (
        .src_clk(fdma_clk),
        .src_in(pcie_link_up),
        .dest_clk(aurora_user_clk),
        .dest_out(pcie_link_up_user)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_channel_to_fdma (
        .src_clk(aurora_user_clk),
        .src_in(aurora_channel_up),
        .dest_clk(fdma_clk),
        .dest_out(aurora_channel_up_fdma)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_lane_to_fdma (
        .src_clk(aurora_user_clk),
        .src_in(aurora_lane_up),
        .dest_clk(fdma_clk),
        .dest_out(aurora_lane_up_fdma)
    );


    // 下行任务地址、目标帧数和完成统计。
    reg                                        tx_active                             ;    // 当前下行业务任务有效
    reg           [15:0]                       tx_target_frames                      ;    // 当前下行批量目标帧数
    reg           [15:0]                       tx_completed_frames                   ;    // 当前任务已经接受完成事件的帧数
    reg           [31:0]                       tx_base_addr_lo                       ;    // 当前任务锁定的DDR低32bit起始地址


    // 2026-10-11修改：旧任务隔离、停止确认和下一命令暂存。
    reg                                        tx_recovering                         ;    // 旧读和跨域事件尚在清理，禁止新任务立即启动
    reg           [3:0]                        tx_quiet_count                        ;    // 旧读结束及用户停止确认后的连续安静拍数
    wire                                       tx_user_quiet_fdma                    ;    // 用户发送桥停止确认已同步回FDMA域
    wire                                       tx_bridge_rareq                       ;    // 发送桥提出的原始读请求，仍需adapter门控
    wire                                       tx_bridge_rready                      ;    // 发送桥正常接收读数据许可
    wire                                       tx_deliver_enable                     ;    // 当前数据可进入发送桥和Byte1配置提取
    wire                                       tx_start_valid                        ;    // 可以实际启动当前或等待命令的条件


    reg                                        tx_recovery_aborted                   ;    // 当前清理来自异常退出，不能暂存下一命令
    reg                                        tx_restart_pending                    ;    // 正常结束期间已保存一条等待启动的命令
    reg           [31:0]                       tx_deferred_base                      ;    // 等待命令的起始地址快照
    reg           [15:0]                       tx_deferred_frames                    ;    // 等待命令的总帧数快照
    wire                                       tx_defer_accept                       ;    // 正常结束清理阶段接受一条合法下一命令
    wire                                       tx_frame_done_fdma                    ;    // FDMA域恢复的单拍帧完成事件
    wire          [32:0]                       tx_requested_end                      ;    // 请求末端地址的33bit中间值


    assign tx_requested_end = {1'b0, cpu_fpga_start_addr} +
                                    {1'b0, cpu_fpga_len}                             ;    // 请求末端地址的33bit中间值
    wire          [32:0]                       tx_window_end                         ;    // 允许下行地址范围的末端

    assign tx_window_end = {1'b0, TX_BASE_ADDR_LO} +
                                ACTIVE_WINDOW_BYTES                                  ;    // 允许下行地址范围的末端
    wire                                       tx_addr_aligned                       ;    // 起始地址为16Byte对齐

    assign tx_addr_aligned = ((cpu_fpga_start_addr & (FRAME_BYTES - 1)) == 0)        ;    // 起始地址为16Byte对齐
    wire                                       tx_len_aligned                        ;    // 长度为16Byte整数倍

    assign tx_len_aligned = ((cpu_fpga_len & (FRAME_BYTES - 1)) == 0)                ;    // 长度为16Byte整数倍
    wire                                       tx_config_valid                       ;    // 地址、长度和范围满足下行请求要求

    assign tx_config_valid = (cpu_fpga_len != 0) &&
                           tx_addr_aligned && tx_len_aligned &&
                           (cpu_fpga_len <= ACTIVE_WINDOW_BYTES) &&
                           (cpu_fpga_start_addr >= TX_BASE_ADDR_LO) &&
                           (tx_requested_end <= tx_window_end) &&
                           !tx_requested_end[32]                                     ;    // 地址、长度和范围满足下行请求要求

    assign cpu_wr_done_event = (rd_start && !tx_start_valid && !tx_defer_accept) ||
        (tx_restart_pending && !link_up_fdma) ||
        (tx_active && (!link_up_fdma || (tx_frame_done_fdma &&
        (tx_completed_frames + 16'd1 >= tx_target_frames))))                         ;    // 本条下行命令结束单拍，成功/拒绝/失效均可能触发

    assign tx_start_valid = !tx_active && !tx_recovering && !fdma_rbusy && link_up_fdma &&
        ((rd_start && tx_config_valid) || tx_restart_pending)                        ;    // 可以实际启动当前或等待命令的条件
    assign tx_defer_accept = rd_start && !tx_active && tx_recovering && !tx_recovery_aborted &&
        !tx_restart_pending && link_up_fdma && tx_config_valid                       ;    // 正常结束清理阶段接受一条合法下一命令
    wire                                       tx_config_error_event                 ;    // 非法请求或不允许的重复启动事件

    assign tx_config_error_event = rd_start && (!tx_config_valid || tx_active || tx_restart_pending ||
        (tx_recovering && tx_recovery_aborted) || (!tx_recovering && fdma_rbusy))    ;    // 非法请求或不允许的重复启动事件
    wire                                       tx_start_link_error                   ;    // 启动时完整就绪未成立的错误事件

    assign tx_start_link_error = rd_start && !link_up_fdma                           ;    // 启动时完整就绪未成立的错误事件
    wire          [31:0]                       requested_frames_32                   ;    // 由字节长度除16得到的帧数

    assign requested_frames_32 = cpu_fpga_len / FRAME_BYTES                          ;    // 由字节长度除16得到的帧数


    // FDMA域保存一条正常结束期间的下一命令及地址/帧数；失去就绪取消，异常退出期间不接收暂存命令。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            tx_recovery_aborted <= 1'b1;
            tx_restart_pending <= 1'b0;
            tx_deferred_base <= TX_BASE_ADDR_LO;
            tx_deferred_frames <= 16'd0;
        end else begin
            if (!link_up_fdma) begin
                tx_recovery_aborted <= 1'b1;
                tx_restart_pending <= 1'b0;
            end else begin
                if (tx_active && tx_frame_done_fdma && (tx_completed_frames + 16'd1 >= tx_target_frames))
                    tx_recovery_aborted <= 1'b0;
                if (tx_defer_accept) begin
                    tx_restart_pending <= 1'b1;
                    tx_deferred_base <= cpu_fpga_start_addr;
                    tx_deferred_frames <= requested_frames_32[15:0];
                end else if (tx_start_valid) begin
                    tx_restart_pending <= 1'b0;
                end
            end
        end
    end

    wire                                       tx_active_user                        ;    // 当前任务有效标志已同步到用户域
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_tx_active_to_user (
        .src_clk(fdma_clk),
        .src_in(tx_active),
        .dest_clk(aurora_user_clk),
        .dest_out(tx_active_user)
    );


    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] tx_fdma_reset_pipe      ;    // 发送桥FDMA侧同步解除复位管线
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] tx_user_reset_pipe      ;    // 发送桥用户侧同步解除复位管线


    // 2026-10-11修改：FDMA域产生发送桥复位：链路失效或无当前任务时清管线，有效任务连续两拍后解除。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) tx_fdma_reset_pipe <= 2'b00;
        else if (!link_up_fdma || !tx_active) tx_fdma_reset_pipe <= 2'b00;
        else tx_fdma_reset_pipe <= {tx_fdma_reset_pipe[0], 1'b1};
    end


    // 2026-10-11修改：用户域产生发送桥复位：用户未就绪或任务无效时清管线，两拍稳定后解除。
    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin
        if (!aurora_user_rstn) tx_user_reset_pipe <= 2'b00;
        else if (!link_up_user || !tx_active_user) tx_user_reset_pipe <= 2'b00;
        else tx_user_reset_pipe <= {tx_user_reset_pipe[0], 1'b1};
    end
    wire                                       tx_fdma_rstn                          ;    // 发送桥FDMA侧低有效复位


    assign tx_fdma_rstn = tx_fdma_reset_pipe[1]                                      ;    // 发送桥FDMA侧低有效复位
    wire                                       tx_user_rstn                          ;    // 发送桥用户侧低有效复位

    assign tx_user_rstn = tx_user_reset_pipe[1]                                      ;    // 发送桥用户侧低有效复位


    reg                                        tx_user_quiet                         ;    // 用户域看到任务无效且发送桥复位的确认


    // 在用户时钟沿确认任务无效且桥处于复位，得到tx_user_quiet，再同步回FDMA域。
    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin
        if (!aurora_user_rstn)
            tx_user_quiet <= 1'b0;
        else
            tx_user_quiet <= !tx_active_user && !tx_user_rstn;
    end
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_tx_quiet_to_fdma (
        .src_clk(aurora_user_clk),
        .src_in(tx_user_quiet),
        .dest_clk(fdma_clk),
        .dest_out(tx_user_quiet_fdma)
    );


    // 2026-10-11修改：保持旧任务清理状态；旧busy结束、用户停止确认及无旧完成事件连续8拍后才允许下一任务。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            tx_recovering <= 1'b1;
            tx_quiet_count <= 4'd0;
        end else if (!link_up_fdma || (tx_active && tx_frame_done_fdma && (tx_completed_frames + 16'd1 >= tx_target_frames))) begin
            tx_recovering <= 1'b1;
            tx_quiet_count <= 4'd0;
        end else if (tx_recovering) begin
            if (!tx_active && !fdma_rbusy && tx_user_quiet_fdma && !tx_frame_done_fdma) begin
                if (tx_quiet_count == 4'd7) begin
                    tx_recovering <= 1'b0;
                    tx_quiet_count <= 4'd0;
                end else begin
                    tx_quiet_count <= tx_quiet_count + 1'b1;
                end
            end else begin
                tx_quiet_count <= 4'd0;
            end
        end
    end

    assign tx_deliver_enable = tx_active && link_up_fdma && !tx_recovering           ;    // 当前数据可进入发送桥和Byte1配置提取
    assign fdma_rareq = tx_bridge_rareq && tx_deliver_enable                         ;    // 断链后不再接受桥发出的新读请求

    assign fdma_rready = tx_deliver_enable ? tx_bridge_rready : fdma_rbusy           ;    // 有旧读事务时继续排空；空闲时撤销ready，避免误计无进展超时

    // 发送桥的地址、调试状态和跨域完成事件。
    wire          [31:0]                       tx_fdma_raddr_raw                     ;    // 发送桥给出的相对DDR读字节地址
    wire          [37:0]                       tx_fdma_dbg_bus                       ;    // 发送桥FDMA侧状态和FIFO写侧统计
    wire          [38:0]                       tx_user_dbg_bus                       ;    // 发送桥用户侧状态和FIFO读侧统计
    wire                                       tx_frame_done_user                    ;    // 用户域当前帧完成单拍


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
        .fdma_rareq         (tx_bridge_rareq),
        .fdma_rbusy         (fdma_rbusy),
        .fdma_rdata         (fdma_rdata),
        .fdma_rvalid        (fdma_rvalid && tx_deliver_enable),
        .fdma_rready        (tx_bridge_rready),
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


    assign fdma_raddr = {CARD_ADDR_HI, tx_base_addr_lo} +
                        {32'd0, tx_fdma_raddr_raw}                                   ;    // FDMA 读地址=静态高32位+TX基址+bridge游标

    assign fdma_rsize = FRAME_WORDS_16                                               ;    // FDMA 读突发固定 2 拍（16B 帧）


    reg                                        tx_done_toggle_user                   ;    // 用户域每完成一帧翻转的事件标志


    // 每完成一帧翻转用户域完成标志，跨域后通过异或恢复单拍事件。
    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin
        if (!aurora_user_rstn)
            tx_done_toggle_user <= 1'b0;
        else if (tx_frame_done_user)
            tx_done_toggle_user <= ~tx_done_toggle_user;
    end

    wire                                       tx_done_toggle_fdma                   ;    // 完成翻转标志已同步到FDMA域
    reg                                        tx_done_toggle_fdma_d                 ;    // 上一拍同步完成翻转标志
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_tx_done_toggle (
        .src_clk(aurora_user_clk),
        .src_in(tx_done_toggle_user),
        .dest_clk(fdma_clk),
        .dest_out(tx_done_toggle_fdma)
    );

    assign tx_frame_done_fdma = tx_done_toggle_fdma ^ tx_done_toggle_fdma_d          ;    // FDMA域恢复的单拍帧完成事件


    // 保存上一拍同步完成翻转位，供异或检测新完成事件。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_done_toggle_fdma_d
        if (! fdma_rstn) begin
            tx_done_toggle_fdma_d <= 1'b0 ;
        end else begin
            tx_done_toggle_fdma_d <= tx_done_toggle_fdma ;
        end
    end


    // 启动有效任务置tx_active；就绪失效或最后一帧完成后清除。
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


    // 启动时保存目标帧数，正常暂存命令使用其快照；任务结束或失效清目标。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_target_frames
        if (! fdma_rstn) begin
            tx_target_frames <= 16'd0 ;
        end else begin
            if (tx_start_valid) begin
                tx_target_frames <= tx_restart_pending ? tx_deferred_frames : requested_frames_32[15:0];
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


    // 只为当前有效任务计已完成帧，启动、失效或最后帧结束时清零。
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


    // 启动时锁定本批起始地址，暂存命令用地址快照，读数据时不再跟随软件寄存器变化。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_tx_base_addr_lo
        if (! fdma_rstn) begin
            tx_base_addr_lo <= TX_BASE_ADDR_LO ;
        end else begin
            if (tx_start_valid) begin
                tx_base_addr_lo <= tx_restart_pending ? tx_deferred_base : cpu_fpga_start_addr;
            end
        end
    end


    // 当前任务开始置响应忙，完成或就绪失效清除；与旧读busy是否结束分开判断。
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


    // 上行异步FIFO数据、块写接口及丢字统计。
    wire          [63:0]                       rx_packet                             ;    // 异步FIFO送到DDR域的原始64bit接收拍
    wire                                       rx_packet_valid                       ;    // 当前数据/事件有效
    wire                                       rx_packet_ready                       ;    // 当前通道可接受数据或业务
    wire          [31:0]                       fifo_drops                            ;    // 接收FIFO累计丢失32bit字数
    wire          [31:0]                       writer_drops                          ;    // 块空间不足或写响应失败的累计丢字
    reg           [31:0]                       fifo_drops_previous                   ;    // 上一拍FIFO丢字计数


    // 保存上一拍FIFO丢字计数，识别接收侧新丢字。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            fifo_drops_previous <= 32'd0;
        end else begin
            fifo_drops_previous <= fifo_drops;
        end
    end
    wire          [32:0]                       total_drops                           ;    // 两个饱和计数求和时保留进位
    wire                                       rx_accept_enable                      ;    // 用户域链路有效即组帧；存储不可用由writer整帧丢弃并计数
    wire                                       rx_store_enable                       ;    // DDR 初始化和 PCIe 链路就绪后允许写缓存
    wire                                       rx_irq_clear                          ;    // 两种通知清除入口，不代表释放块

    assign rx_accept_enable = aurora_user_rstn && aurora_channel_up && aurora_lane_up;    // 用户域链路有效即组帧；存储不可用由writer整帧丢弃并计数

    assign rx_store_enable = ddr_ready && pcie_link_up_fdma                          ;    // DDR 初始化和 PCIe 链路就绪后允许写缓存

    assign rx_irq_clear = int_state_clear || clear_inter                             ;    // 两种通知清除入口，不代表释放块
    wire                                       rx_length_error_raw                   ;    // RX FIFO保留的长度错误兼容输出
    wire                                       rx_fifo_overflow_user                 ;    // FIFO 溢出统计在 mem 域，user 域恒 0
    wire                                       rx_burst_done_fdma                    ;    // RX 写 burst 成功提交事件（无写错误）

    // CPU读完确认的单拍检测。
    reg                                        cpu_rec_state_d                       ;    // 上一拍CPU确认位，用于检测0到1变化
    wire                                       cpu_rec_ack                           ;    // INFO_EXCH输出每次写1对应的单周期命令

    assign cpu_rec_ack = cpu_rec_state_r                                             ;    // INFO_EXCH输出每次写1对应的单周期命令

    assign int_state_w = fpga_cpu_irq_req                                            ;    // 当前待读块的通知状态

    assign rx_pending = (rx_ready_blocks != 0)                                       ;    // 至少有一个完整上行块等待CPU读取确认
    reg                                        rx_overrun_flag                       ;    // 块空间或写入失败引起的新丢字保持标志
    reg           [31:0]                       dropped_frames_previous               ;    // 上一拍合计丢字，用于检测新增加的丢字

    assign rx_overrun_sticky = rx_overrun_flag                                       ;    // RX 丢字增长 sticky（clear 后可重捕获）


    // 保存上一拍块写丢字计数，识别DDR写入或空间不足引起的新丢字。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            dropped_frames_previous <= 32'd0;
        end else begin
            dropped_frames_previous <= rx_dropped_frames;
        end
    end


    // 发现新的丢字时保持接收超额错误，软件清相关状态后解除。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            rx_overrun_flag <= 1'b0;
        end else if (rx_dropped_frames != dropped_frames_previous) begin
            rx_overrun_flag <= 1'b1;
        end else if (clear_inter) begin
            rx_overrun_flag <= 1'b0;
        end
    end

    assign total_drops = {1'b0,fifo_drops} + {1'b0,writer_drops}                     ;    // 两个饱和计数求和时保留进位

    assign rx_dropped_frames = total_drops[32] ? 32'hffffffff : total_drops[31:0]    ;    // FIFO和块写统计的累计丢失32bit字数

    assign rx_burst_done_fdma = fdma_wdone && !fdma_werror                           ;    // RX 写 burst 成功提交事件（无写错误）

    assign rx_fifo_overflow_user = 1'b0                                              ;    // FIFO 溢出统计在 mem 域，user 域恒 0


    // 保存CPU确认位的上一拍，形成一次0到1确认事件。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_cpu_rec_state_d
        if (! fdma_rstn) begin
            cpu_rec_state_d <= 1'b0 ;
        end else begin
            cpu_rec_state_d <= cpu_rec_state_r ;
        end
    end


    // 同步保存当前CPU确认状态，供寄存器读回。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_cpu_rec_state_w
        if (! fdma_rstn) begin
            cpu_rec_state_w <= 1'b0 ;
        end else begin
            cpu_rec_state_w <= cpu_rec_state_r ;
        end
    end

    RTDS_RX_FRAME_FIFO U_RTDS_RX_FRAME_FIFO (
        .rst_n(fdma_rstn),
        .user_clk(aurora_user_clk),
        .user_ready(rx_accept_enable),
        .rx_data(aurora_rx_d),
        .rx_sof(aurora_rx_sof),
        .rx_eof(aurora_rx_eof),
        .rx_rem(aurora_rx_rem),
        .rx_valid(aurora_rx_src_rdy),
        .rx_ready(aurora_rx_dst_rdy),
        .mem_clk(fdma_clk),
        .frame_data(rx_packet),
        .frame_valid(rx_packet_valid),
        .frame_ready(rx_packet_ready),
        .fifo_full(rx_fifo_full),
        .fifo_almost_full(rx_fifo_almost_full),
        .dropped_frames(fifo_drops),
        .length_error(rx_length_error_raw)
    );
    RTDS_RX_BLOCK_WRITER #(
        .BLOCK_COUNT(RX_BLOCK_COUNT),
        .BLOCK_BYTES(RX_BLOCK_BYTES),
        .PERIOD_CYCLES(RX_PERIOD_CYCLES),
        .BASE_ADDR(RX_BASE_ADDR_LO)
    ) U_RTDS_RX_BLOCK_WRITER (
        .clk(fdma_clk),
        .rst_n(fdma_rstn),
        .enable(rx_store_enable),
        .frame_data(rx_packet),
        .frame_valid(rx_packet_valid),
        .frame_ready(rx_packet_ready),
        .cpu_ack(cpu_rec_ack),
        .irq_clear(rx_irq_clear),
        .head_addr(fpga_cpu_start_addr),
        .head_len(fpga_cpu_len),
        .head_seq(rx_head_seq),
        .ready_blocks(rx_ready_blocks),
        .dropped_frames(writer_drops),
        .irq(fpga_cpu_irq_req),
        .fdma_waddr(fdma_waddr),
        .fdma_wsize(fdma_wsize),
        .fdma_wareq(fdma_wareq),
        .fdma_wstrb(fdma_wstrb),
        .fdma_wbusy(fdma_wbusy),
        .fdma_wdata(fdma_wdata),
        .fdma_wvalid(fdma_wvalid),
        .fdma_waccept(fdma_wready),
        .fdma_wdone(fdma_wdone),
        .fdma_werror(fdma_werror),
        .dbg_state(dbg_rx_state)
    );

    reg                                        config_read_beat                      ;    // 帧内读拍位置，0表示下一拍提取Byte1


    // 仅当前有效交付任务统计帧内读拍；每两拍归零，停止交付时重置首拍位置。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn)
            config_read_beat<=1'b0;
        else if (!tx_deliver_enable)
            config_read_beat<=1'b0;
        else if (fdma_rvalid && fdma_rready)
            config_read_beat<=!config_read_beat;
    end

    assign cfg_byte = fdma_rdata[15:8]                                               ;    // 首读拍Byte1配置编号

    assign cfg_byte_valid =
        tx_deliver_enable && fdma_rvalid && fdma_rready && (config_read_beat==0)     ;    // 该帧首读拍被实际接受的配置事件


    // 软件清错事件的翻转跨域传递。
    reg                                        status_clear_toggle_fdma              ;    // 软件每次清错翻转的源事件位


    // 每次软件清相关错误翻转标志，将清除动作可靠传到用户域。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn)
            status_clear_toggle_fdma <= 1'b0;
        else if (clear_inter)
            status_clear_toggle_fdma <= ~status_clear_toggle_fdma;
    end

    wire                                       status_clear_toggle_user              ;    // 同步到用户域的清错翻转位
    reg                                        status_clear_toggle_user_d            ;    // 用户域上一拍清错翻转位
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_status_clear (
        .src_clk(fdma_clk),
        .src_in(status_clear_toggle_fdma),
        .dest_clk(aurora_user_clk),
        .dest_out(status_clear_toggle_user)
    );
    wire                                       status_clear_user                     ;    // 用户域检测到的单拍清错事件

    assign status_clear_user = status_clear_toggle_user ^ status_clear_toggle_user_d ;    // 用户域检测到的单拍清错事件

    // 用户域帧观察和错误状态。
    reg                                        rx_in_frame                           ;    // 用户域接收当前处于SOF和EOF之间
    reg           [8:0]                        rx_frame_word_count                   ;    // 用户域接收帧内实际接受的拍数
    reg                                        rx_length_error_user_sticky           ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        rx_overflow_user_sticky               ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        tx_underflow_user_sticky              ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       rx_hs                                 ;    // RX LocalLink 握手成功一拍

    assign rx_hs = aurora_rx_src_rdy && aurora_rx_dst_rdy                            ;    // RX LocalLink 握手成功一拍
    wire                                       tx_underflow_user                     ;    // TX 下溢标志取自调试总线 bit0

    assign tx_underflow_user = tx_user_dbg_bus[0]                                    ;    // TX 下溢标志取自调试总线 bit0


    // 保存用户域上一拍清除翻转位，通过异或检测清除单拍。
    always @ ( posedge aurora_user_clk or negedge aurora_user_rstn ) begin : update_status_clear_toggle_user_d
        if (! aurora_user_rstn) begin
            status_clear_toggle_user_d <= 1'b0 ;
        end else begin
            status_clear_toggle_user_d <= status_clear_toggle_user ;
        end
    end


    // 跟踪接收帧是否处于首尾之间，失去用户就绪时回到无帧状态。
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


    // 在用户域按实际接收握手统计帧内拍数，首拍重新计数，末拍归零。
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


    // 长度筛除已取消，此兼容错误标志复位及运行时均为0。
    always @(posedge aurora_user_clk or negedge aurora_user_rstn) begin : update_rx_length_error_user_sticky
        if (!aurora_user_rstn)
            rx_length_error_user_sticky <= 1'b0;
        else
            rx_length_error_user_sticky <= 1'b0;
    end


    // 用户域检测接收无法保存的拍并保持溢出标志，收到软件跨域清除后归零。
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


    // 用户域保持发送读空错误，收到跨域清除后归零。
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


    wire                                       rx_length_error_fdma                  ;    // 用户长度错误同步到FDMA域的兼容状态
    wire                                       rx_overflow_fdma                      ;    // 对应FIFO不能保存新输入的溢出状态
    wire                                       tx_underflow_fdma                     ;    // 对应FIFO读侧无数据的错误状态
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_rx_length_error (
        .src_clk(aurora_user_clk),
        .src_in(rx_length_error_user_sticky),
        .dest_clk(fdma_clk),
        .dest_out(rx_length_error_fdma)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_rx_overflow (
        .src_clk(aurora_user_clk),
        .src_in(rx_overflow_user_sticky),
        .dest_clk(fdma_clk),
        .dest_out(rx_overflow_fdma)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0)
    ) u_cdc_tx_underflow (
        .src_clk(aurora_user_clk),
        .src_in(tx_underflow_user_sticky),
        .dest_clk(fdma_clk),
        .dest_out(tx_underflow_fdma)
    );


    // FDMA域错误保持与软件清除。
    reg                                        rx_overflow_sticky_r                  ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        tx_underflow_sticky_r                 ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        fdma_timeout_sticky_r                 ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        length_error_sticky_r                 ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        link_down_sticky_r                    ;    // 相应错误出现后保持为1，直到软件清除或复位
    reg                                        seen_link_up                          ;    // 对应链路就绪状态，跨域副本按后缀区分
    reg           [31:0]                       fdma_wait_count                       ;    // FDMA连续等待且无进展的拍计数
    reg                                        user_status_clear_hold                ;    // 等待用户域旧错误清除反馈，避免旧高电平重新置错


    assign rx_overflow_sticky  = rx_overflow_sticky_r                                ;    // RX 溢出 sticky 输出

    assign tx_underflow_sticky = tx_underflow_sticky_r                               ;    // TX 下溢 sticky 输出

    assign fdma_timeout_sticky = fdma_timeout_sticky_r                               ;    // FDMA 超时 sticky 输出

    assign length_error_sticky = length_error_sticky_r                               ;    // 帧长错误 sticky 输出

    assign link_down_sticky    = link_down_sticky_r                                  ;    // 链路断 sticky 输出

    // 等待/进展判断；仅持续无进展时累计超时。
    wire                                       fdma_waiting                          ;    // FDMA 等待中：请求未接受或数据未返回


    // 等待/进展判断；仅持续无进展时累计超时。
    assign fdma_waiting = fdma_rareq || fdma_wareq ||
                        (fdma_rready && !fdma_rvalid) ||
                        (fdma_wvalid && !fdma_wready)                                ;    // FDMA 等待中：请求未接受或数据未返回
    wire                                       fdma_progress                         ;    // FDMA 前进：任一握手或提交事件

    assign fdma_progress = (fdma_rareq && fdma_rbusy) ||
                         (fdma_wareq && fdma_wbusy) ||
                         (fdma_rvalid && fdma_rready) ||
                         (fdma_wvalid && fdma_wready) ||
                         rx_burst_done_fdma                                          ;    // FDMA 前进：任一握手或提交事件

    reg                                        fdma_waiting_q                        ;    // FDMA等待状态流水，切断AXI反压到超时计数器的长组合路径
    reg                                        fdma_progress_q                       ;    // FDMA进展状态流水，保持超时判断与等待状态使用同一拍快照


    // 把等待和进展条件同时寄存一级，使超时计算使用同一拍状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin : pipeline_fdma_timeout_status
        if (!fdma_rstn) begin
            fdma_waiting_q  <= 1'b0;
            fdma_progress_q <= 1'b0;
        end else begin
            fdma_waiting_q  <= fdma_waiting;
            fdma_progress_q <= fdma_progress;
        end
    end


    // FDMA域保持新的接收溢出或丢字错误；清除后等旧跨域高电平撤销再允许重新置位。
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


    // FDMA域保持用户侧发送读空错误；软件清除时优先清零。
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


    // 仅等待且无进展达到阈值时置超时，软件清除时归零；空闲不应算等待。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_fdma_timeout_sticky_r
        if (! fdma_rstn) begin
            fdma_timeout_sticky_r <= 1'b0 ;
        end else begin
            if (clear_inter) begin
                fdma_timeout_sticky_r <= 1'b0 ;
            end
            if (fdma_progress_q || !fdma_waiting_q) begin
            end else begin
                if (fdma_wait_count >= FDMA_TIMEOUT_CYCLES - 1) begin
                    fdma_timeout_sticky_r <= 1'b1 ;
                end
            end
        end
    end


    // 保持非法命令或用户侧长度错误；软件清除和跨域清除等待共同约束重新置位。
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


    // 启动时未就绪或活动任务失去就绪时置链路错误；曾建立链路后下降也记录。
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


    // 记录是否曾出现完整就绪，复位清零，用于区别尚未建链与建链后丢失。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_seen_link_up
        if (! fdma_rstn) begin
            seen_link_up <= 1'b0 ;
        end else begin
            if (link_up_fdma) begin
                seen_link_up <= 1'b1 ;
            end
        end
    end


    // 有进展、无等待或软件清错时清计数，仅持续无进展等待时累加到超时阈值。
    always @ ( posedge fdma_clk or negedge fdma_rstn ) begin : update_fdma_wait_count
        if (! fdma_rstn) begin
            fdma_wait_count <= 32'd0 ;
        end else begin
            if (clear_inter) begin
                fdma_wait_count <= 32'd0 ;
            end
            if (fdma_progress_q || !fdma_waiting_q) begin
                fdma_wait_count <= 32'd0 ;
            end else begin
                if (fdma_wait_count >= FDMA_TIMEOUT_CYCLES - 1) begin
                end else begin
                    fdma_wait_count <= fdma_wait_count + 32'd1 ;
                end
            end
        end
    end


    // 软件清错后保持用户侧清除等待；旧跨域错误都回低后再接受新的错误事件。
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


    assign dbg_tx_state = {2'b00, tx_fdma_dbg_bus[37:36]}                            ;    // 下行桥当前状态

endmodule
