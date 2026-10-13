`timescale 1ns / 1ps

module TOP #(
        parameter integer AURORA_SIMULATION = 0,
        parameter integer RX_PERIOD_CYCLES = 25000000,
        parameter integer AURORA1G_PERIOD_CYCLES = 63,
        parameter integer EPOCH_CYCLES = 12500
    )(
        input                   clk_p,
        input                   clk_n,

        input       [1:0]       pcie_mgt_rxn,
        input       [1:0]       pcie_mgt_rxp,
        output      [1:0]       pcie_mgt_txn,
        output      [1:0]       pcie_mgt_txp,
        input       [0:0]       pcie_diff_clk_n,
        input       [0:0]       pcie_diff_clk_p,
        input                   pcie_rst_n,
        output                  user_lnk_up,

        input                   GTHQ0_P,
        input                   GTHQ0_N,
        input                   aurora_rxp,
        input                   aurora_rxn,
        output                  aurora_txp,
        output                  aurora_txn,

        // 单个1G物理链路；业务仅发送，物理RX仍用于Duplex建链。
        input wire aurora1g_refclk_p,
        input wire aurora1g_refclk_n,
        input wire aurora1g_rxp,
        input wire aurora1g_rxn,
        output wire aurora1g_txp,
        output wire aurora1g_txn,
        output                  c0_ddr4_act_n,
        output      [16:0]      c0_ddr4_adr,
        output      [1:0]       c0_ddr4_ba,
        output      [0:0]       c0_ddr4_bg,
        output      [0:0]       c0_ddr4_cke,
        output      [0:0]       c0_ddr4_odt,
        output      [0:0]       c0_ddr4_cs_n,
        output      [0:0]       c0_ddr4_ck_t,
        output      [0:0]       c0_ddr4_ck_c,
        output                  c0_ddr4_reset_n,
        inout       [7:0]       c0_ddr4_dm_dbi_n,
        inout       [63:0]      c0_ddr4_dq,
        inout       [7:0]       c0_ddr4_dqs_c,
        inout       [7:0]       c0_ddr4_dqs_t,

        output                  led
    );

    wire [63:0] aurora_tx_d;
    wire        aurora_tx_sof;
    wire        aurora_tx_eof;
    wire [2:0]  aurora_tx_rem;
    wire        aurora_tx_src_rdy;
    wire        aurora_tx_dst_rdy;
    wire [63:0] app_tx_d;
    wire        app_tx_sof, app_tx_eof, app_tx_src_rdy, app_tx_dst_rdy;
    wire [2:0]  app_tx_rem;
    wire [31:0] sync_missed_epochs;

    wire [63:0] aurora_rx_d;
    wire        aurora_rx_sof;
    wire        aurora_rx_eof;
    wire [2:0]  aurora_rx_rem;
    wire        aurora_rx_src_rdy;
    wire        aurora_rx_dst_rdy;

    wire        aurora_user_clk;
    wire        aurora_user_rstn;
    wire        aurora_channel_up;
    wire        aurora_lane_up;

    wire aurora1g_user_clk, aurora1g_user_reset, aurora1g_channel_up;
    wire aurora1g_tx_ready, aurora1g_tx_sof, aurora1g_tx_eof, aurora1g_tx_valid;
    wire [31:0] aurora1g_tx_data;
    wire [1:0] aurora1g_tx_rem;
    wire aurora1g_configured;
    wire [7:0] aurora1g_configured_id;
    wire [31:0] aurora1g_skipped_periods;
    wire [31:0] aurora1g_rx_data_nc;
    wire [1:0] aurora1g_rx_rem_nc;
    wire aurora1g_rx_sof_nc, aurora1g_rx_eof_nc, aurora1g_rx_valid_nc, aurora1g_rx_crc_error_nc;
    wire init_clk_25m, aurora1g_reset, aurora1g_gt_reset;

    wire clk_250m;
    wire clk_156m;
    wire clk_100m;
    wire sys_rst;
    wire clk_100m_ibuf;
    wire epoch_rst_n;
    reg [31:0] epoch_count;
    reg epoch_toggle_250m;

    RTDS_FPGA_RESET_SYNC u_epoch_reset_sync (
        .clk(clk_250m), .rst_async_n(!sys_rst), .rst_sync_n(epoch_rst_n)
    );

    // 同一个250MHz源每12500拍翻转一次，10G与1G各自在用户域恢复单拍事件。
    always @(posedge clk_250m or negedge epoch_rst_n) begin
        if (!epoch_rst_n) begin
            epoch_count <= 32'd0;
            epoch_toggle_250m <= 1'b0;
        end else if (epoch_count == EPOCH_CYCLES - 1) begin
            epoch_count <= 32'd0;
            epoch_toggle_250m <= ~epoch_toggle_250m;
        end else begin
            epoch_count <= epoch_count + 32'd1;
        end
    end

    // PCB AC34悬空：DDR复位由现有系统复位产生，100MHz域四拍同步释放。
    wire ddr_sys_rst_n;
    RTDS_FPGA_RESET_SYNC u_ddr_sys_reset_sync (
        .clk(clk_100m), .rst_async_n(!sys_rst), .rst_sync_n(ddr_sys_rst_n)
    );
    wire host_rst_n; // 系统复位的低有效命名网络，域内由平台同步器释放
    reg [31:0] fpga_temp_status; // 250MHz域温度状态寄存器，隔离SYSMON到AXI译码的长路径
    wire [15:0] FPGA_TEMP_W;
    wire        FPGA_TEMP_BUSY_W;

    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign host_rst_n = !sys_rst;

    // SYSMON输出先在250MHz主逻辑域寄存，再交给AXI寄存器译码读取。该一级流水
    // 只增加一个时钟周期的状态可见延迟，不改变温度编码和busy位位置。
    always @(posedge clk_250m) begin
        if (sys_rst) begin
            fpga_temp_status <= 32'd0;
        end else begin
            fpga_temp_status <= {15'd0, FPGA_TEMP_BUSY_W, FPGA_TEMP_W};
        end
    end

    wire [7:0] cfg_byte;
    wire cfg_byte_valid;

    IBUFDS u_shared_100m_ibuf (
        .I  (clk_p),
        .IB (clk_n),
        .O  (clk_100m_ibuf)
    );

    CLK_GEN u_clk_gen (
        .clk_i     (clk_100m_ibuf),
        .clk_250m  (clk_250m),
        .clk_156m  (clk_156m),
        .clk_100m  (clk_100m),
        .sys_rst   (sys_rst)
    );

    // Aurora owns its recovered/user clock. clk_100m is used only as the
    // free-running initialization clock required by the configured core.
    aurora_64b66b_top #(
        .SIMULATION       (AURORA_SIMULATION),
        .INIT_CLK_FREQ_HZ (100_000_000)
    ) u_aurora_64b66b_top (
        .clk_init       (clk_100m),
        .sys_rst        (sys_rst),
        .GTHQ0_P        (GTHQ0_P),
        .GTHQ0_N        (GTHQ0_N),
        .RXP            (aurora_rxp),
        .RXN            (aurora_rxn),
        .TXP            (aurora_txp),
        .TXN            (aurora_txn),
        .sfp_tx_disable (),
        .sfp_rs0        (),
        .sfp_rs1        (),
        .tx_d           (aurora_tx_d),
        .tx_sof         (aurora_tx_sof),
        .tx_eof         (aurora_tx_eof),
        .tx_rem         (aurora_tx_rem),
        .tx_src_vld     (aurora_tx_src_rdy),
        .tx_dst_rdy     (aurora_tx_dst_rdy),
        .rx_d           (aurora_rx_d),
        .rx_sof         (aurora_rx_sof),
        .rx_eof         (aurora_rx_eof),
        .rx_rem         (aurora_rx_rem),
        .rx_src_vld     (aurora_rx_src_rdy),
        .rx_dst_rdy     (aurora_rx_dst_rdy),
        .user_clk       (aurora_user_clk),
        .channel_up     (aurora_channel_up),
        .lane_up        (aurora_lane_up),
        .user_rstn      (aurora_user_rstn)
    );

    // 软件提交的16Byte帧保持原样；同步帧只在帧边界插入，不抢断在途帧。
    RTDS_50US_SYNC_MUX u_50us_sync_mux (
        .user_clk(aurora_user_clk), .user_rstn(aurora_user_rstn),
        .channel_up(aurora_channel_up && aurora_lane_up),
        .epoch_toggle_250m(epoch_toggle_250m), .run_250m(aurora1g_configured),
        .app_d(app_tx_d), .app_sof(app_tx_sof), .app_eof(app_tx_eof),
        .app_rem(app_tx_rem), .app_valid(app_tx_src_rdy), .app_ready(app_tx_dst_rdy),
        .tx_d(aurora_tx_d), .tx_sof(aurora_tx_sof), .tx_eof(aurora_tx_eof),
        .tx_rem(aurora_tx_rem), .tx_valid(aurora_tx_src_rdy), .tx_ready(aurora_tx_dst_rdy),
        .missed_epochs(sync_missed_epochs)
    );

    // FPGA平台分频与启动复位：25MHz初始化时钟独立于GT用户时钟。
    RTDS_FPGA_1G_INIT U_RTDS_FPGA_1G_INIT (
        .clk_100m(clk_100m), .rst(sys_rst), .init_clk(init_clk_25m),
        .core_reset(aurora1g_reset), .gt_reset(aurora1g_gt_reset)
    );
    // 只例化一个verified 32bit 1G封装，不接入Buck算法和业务RX。
    aurora_8b10b_1p25g_design U_AURORA_1G (
        .reset(aurora1g_reset), .gt_reset(aurora1g_gt_reset), .init_clk_in(init_clk_25m),
        .gt_refclk_p(aurora1g_refclk_p), .gt_refclk_n(aurora1g_refclk_n),
        .rxp(aurora1g_rxp), .rxn(aurora1g_rxn), .txp(aurora1g_txp), .txn(aurora1g_txn),
        .tx_data(aurora1g_tx_data), .tx_rem(aurora1g_tx_rem),
        .tx_sof(aurora1g_tx_sof), .tx_eof(aurora1g_tx_eof),
        .tx_valid(aurora1g_tx_valid), .tx_ready(aurora1g_tx_ready),
        .rx_data(aurora1g_rx_data_nc), .rx_rem(aurora1g_rx_rem_nc),
        .rx_sof(aurora1g_rx_sof_nc), .rx_eof(aurora1g_rx_eof_nc),
        .rx_valid(aurora1g_rx_valid_nc), .rx_crc_error(aurora1g_rx_crc_error_nc),
        .user_clk_out(aurora1g_user_clk), .system_reset_out(aurora1g_user_reset),
        .channel_up(aurora1g_channel_up)
    );

    RTDS_1G_PERIODIC_TX #(.PERIOD_CYCLES(AURORA1G_PERIOD_CYCLES)) U_RTDS_1G_PERIODIC_TX (
        .clk_250m(clk_250m), .rst_n(host_rst_n),
        .cfg_byte(cfg_byte), .cfg_byte_valid(cfg_byte_valid),
        .epoch_toggle_250m(epoch_toggle_250m),
        .user_clk(aurora1g_user_clk), .user_reset(aurora1g_user_reset),
        .channel_up(aurora1g_channel_up), .tx_ready(aurora1g_tx_ready),
        .tx_data(aurora1g_tx_data), .tx_rem(aurora1g_tx_rem),
        .tx_sof(aurora1g_tx_sof), .tx_eof(aurora1g_tx_eof), .tx_valid(aurora1g_tx_valid),
        .configured(aurora1g_configured), .configured_id(aurora1g_configured_id),
        .skipped_periods(aurora1g_skipped_periods)
    );

    PCIe #(.RX_PERIOD_CYCLES(RX_PERIOD_CYCLES)) u_pcie (
        .cfg_byte(cfg_byte), .cfg_byte_valid(cfg_byte_valid),
        .pcie_mgt_rxn        (pcie_mgt_rxn),
        .pcie_mgt_rxp        (pcie_mgt_rxp),
        .pcie_mgt_txn        (pcie_mgt_txn),
        .pcie_mgt_txp        (pcie_mgt_txp),
        .pcie_diff_clk_n     (pcie_diff_clk_n),
        .pcie_diff_clk_p     (pcie_diff_clk_p),
        .pcie_rst_n          (pcie_rst_n),
        .user_lnk_up         (user_lnk_up),
        .FPGA_TEMP_W         (fpga_temp_status),
        .i_sys_clk           (clk_250m),
        .i_sys_rst           (sys_rst),
        // MIG配置为SYSCLK_TYPE=NO_BUFFER，输入必须直接来自共享IBUFDS。
        // 禁止使用clk_wiz输出，否则形成用户MMCM级联MIG MMCM；DDR4-2400
        // 下会因级联时钟抖动触发Mig 66-99并在opt_design阶段终止。
        .ddr_sys_clk_i        (clk_100m_ibuf),
        .ddr_sys_rst_n        (ddr_sys_rst_n),
        .c0_ddr4_act_n        (c0_ddr4_act_n),
        .c0_ddr4_adr          (c0_ddr4_adr),
        .c0_ddr4_ba           (c0_ddr4_ba),
        .c0_ddr4_bg           (c0_ddr4_bg),
        .c0_ddr4_cke          (c0_ddr4_cke),
        .c0_ddr4_odt          (c0_ddr4_odt),
        .c0_ddr4_cs_n         (c0_ddr4_cs_n),
        .c0_ddr4_ck_t         (c0_ddr4_ck_t),
        .c0_ddr4_ck_c         (c0_ddr4_ck_c),
        .c0_ddr4_reset_n      (c0_ddr4_reset_n),
        .c0_ddr4_dm_dbi_n     (c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq           (c0_ddr4_dq),
        .c0_ddr4_dqs_c        (c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t        (c0_ddr4_dqs_t),
        .aurora_user_clk     (aurora_user_clk),
        .aurora_user_rstn    (aurora_user_rstn),
        .aurora_channel_up   (aurora_channel_up),
        .aurora_lane_up      (aurora_lane_up),
        .aurora_tx_d         (app_tx_d),
        .aurora_tx_sof       (app_tx_sof),
        .aurora_tx_eof       (app_tx_eof),
        .aurora_tx_rem       (app_tx_rem),
        .aurora_tx_src_rdy   (app_tx_src_rdy),
        .aurora_tx_dst_rdy   (app_tx_dst_rdy),
        .aurora_rx_d         (aurora_rx_d),
        .aurora_rx_sof       (aurora_rx_sof),
        .aurora_rx_eof       (aurora_rx_eof),
        .aurora_rx_rem       (aurora_rx_rem),
        .aurora_rx_src_rdy   (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy   (aurora_rx_dst_rdy)
    );

    LED #(
        .SYS_CLK   (250000000),
        .LED_CYCLE (1000000)
    ) u_led (
        .i_sys_clk (clk_250m),
        .i_sys_rst (sys_rst),
        .o_led     (led)
    );

    TEMP_RD #(
        .SYS_CLK       (250000000),
        .RD_TEMP_CYCLE (1000)
    ) u_temp_rd (
        .sys_clk (clk_250m),
        .sys_rst (sys_rst),
        .busy    (FPGA_TEMP_BUSY_W),
        .temp    (FPGA_TEMP_W)
    );

    // clk_156m remains available for board-level diagnostics. The Aurora data
    // path intentionally uses aurora_user_clk from the core instead.

endmodule

// 主机发往子机的50us同步帧：16Byte，网络字节顺序。
// Byte0..3="RTDS"，Byte4=1(同步类型)，Byte5.bit0=RUN，Byte6..7=16，
// Byte8..11=周期序号，Byte12..15=0。序号每个本地周期递增，链路丢帧时可见跳号。
// 仅保留一个待发同步帧；若持续反压超过一个周期，丢弃旧待发帧并计数。
module RTDS_50US_SYNC_MUX (
    input  wire        user_clk,
    input  wire        user_rstn,
    input  wire        channel_up,
    input  wire        epoch_toggle_250m,
    input  wire        run_250m,
    input  wire [63:0] app_d,
    input  wire        app_sof,
    input  wire        app_eof,
    input  wire [2:0]  app_rem,
    input  wire        app_valid,
    output wire        app_ready,
    output wire [63:0] tx_d,
    output wire        tx_sof,
    output wire        tx_eof,
    output wire [2:0]  tx_rem,
    output wire        tx_valid,
    input  wire        tx_ready,
    output reg  [31:0] missed_epochs
);
    localparam [1:0] IDLE=2'd0, APP=2'd1, SYNC_FIRST=2'd2, SYNC_LAST=2'd3;
    reg [1:0] state;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] epoch_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] run_sync;
    reg epoch_prev;
    reg [1:0] epoch_init_count;
    reg [31:0] epoch_seq, pending_seq, active_seq;
    reg pending;
    wire epoch_pulse = (epoch_init_count == 2'd3) && (epoch_sync[1] ^ epoch_prev);
    wire select_sync_first = (state == SYNC_FIRST) || ((state == IDLE) && pending);
    wire select_sync_last = (state == SYNC_LAST);
    wire select_app = (state == APP) || ((state == IDLE) && !pending);

    assign app_ready = channel_up && select_app && tx_ready;
    assign tx_d = select_sync_first ? {32'h5254_4453, 8'h01, 7'd0, run_sync[1], 16'h0010} :
                  select_sync_last  ? {active_seq, 32'd0} : app_d;
    assign tx_sof = select_sync_first ? 1'b1 : select_sync_last ? 1'b0 : app_sof;
    assign tx_eof = select_sync_last ? 1'b1 : select_sync_first ? 1'b0 : app_eof;
    assign tx_rem = (select_sync_first || select_sync_last) ? 3'd7 : app_rem;
    assign tx_valid = channel_up && ((select_sync_first || select_sync_last) ||
                                      (select_app && app_valid));

    always @(posedge user_clk or negedge user_rstn) begin
        if (!user_rstn) begin
            epoch_sync <= 2'b00;
            run_sync <= 2'b00;
            epoch_prev <= 1'b0;
            epoch_init_count <= 2'd0;
            state <= IDLE;
            epoch_seq <= 32'd0;
            pending_seq <= 32'd0;
            active_seq <= 32'd0;
            pending <= 1'b0;
            missed_epochs <= 32'd0;
        end else begin
            epoch_sync <= {epoch_sync[0], epoch_toggle_250m};
            run_sync <= {run_sync[0], run_250m};
            epoch_prev <= epoch_sync[1];
            if (epoch_init_count != 2'd3)
                epoch_init_count <= epoch_init_count + 2'd1;
            if (epoch_pulse)
                epoch_seq <= epoch_seq + 32'd1;

            if (!channel_up) begin
                state <= IDLE;
                pending <= 1'b0;
            end else begin
                if (epoch_pulse) begin
                    pending <= 1'b1;
                    pending_seq <= epoch_seq + 32'd1;
                    if (pending && (state != IDLE) &&
                        missed_epochs != 32'hffff_ffff)
                        missed_epochs <= missed_epochs + 32'd1;
                end
                case (state)
                    IDLE: begin
                        if (pending) begin
                            active_seq <= pending_seq;
                            pending <= epoch_pulse; // 同拍若又来新周期，保留新的待发帧
                            state <= tx_ready ? SYNC_LAST : SYNC_FIRST;
                        end else if (app_valid) begin
                            // 首拍尚未握手也锁定APP，防止新周期到来时改变已呈现数据。
                            state <= (tx_ready && app_eof) ? IDLE : APP;
                        end
                    end
                    APP: begin
                        if (app_valid && tx_ready && app_eof)
                            state <= IDLE;
                    end
                    SYNC_FIRST: begin
                        if (tx_ready)
                            state <= SYNC_LAST;
                    end
                    SYNC_LAST: begin
                        if (tx_ready)
                            state <= IDLE;
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule
