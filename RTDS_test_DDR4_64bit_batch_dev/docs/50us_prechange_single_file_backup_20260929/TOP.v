`timescale 1ns / 1ps

module TOP #(
        parameter integer AURORA_SIMULATION = 0,
        parameter integer RX_PERIOD_CYCLES = 25000000,
        parameter integer AURORA1G_PERIOD_CYCLES = 63
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
        .aurora_tx_d         (aurora_tx_d),
        .aurora_tx_sof       (aurora_tx_sof),
        .aurora_tx_eof       (aurora_tx_eof),
        .aurora_tx_rem       (aurora_tx_rem),
        .aurora_tx_src_rdy   (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy   (aurora_tx_dst_rdy),
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
