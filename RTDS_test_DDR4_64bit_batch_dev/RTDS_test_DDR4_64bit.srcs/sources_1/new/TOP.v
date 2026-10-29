// 板级连接：把主机PCIe、DDR4、Aurora 10G和1G业务连接起来。
// 板载100MHz经时钟模块产生业务时钟；Aurora发送使用各自用户时钟。
// 250MHz同一时间基准产生2µs事件和50µs GPIO，2µs事件连接四拍1G发送。
// 温度原始码先在业务域寄存；DDR、主机和链路复位分别按实际接口连接。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module TOP #(
        parameter integer                             AURORA_SIMULATION = 0,           // 本模块AURORA_SIMULATION固定配置/状态编码
        parameter integer                             RX_PERIOD_CYCLES = 25000000,     // 上行接收周期拍数，生产值25000000
        parameter integer RX_VIO_TEST_ENABLE = 0 // 2026-10-13：1选择VIO测试上行；0保留原FIFO
    )(
        input                                      clk_p,                              // 对应接口时钟，使用域由连接关系确定
        input                                      clk_n,                              // 对应接口时钟，使用域由连接关系确定

        input         [1:0]                        pcie_mgt_rxn,                       // PCIe GT接收差分负端
        input         [1:0]                        pcie_mgt_rxp,                       // PCIe GT接收差分正端
        output        [1:0]                        pcie_mgt_txn,                       // PCIe GT发送差分负端
        output        [1:0]                        pcie_mgt_txp,                       // PCIe GT发送差分正端
        input         [0:0]                        pcie_diff_clk_n,                    // 对应接口时钟，使用域由连接关系确定
        input         [0:0]                        pcie_diff_clk_p,                    // 对应接口时钟，使用域由连接关系确定
        input                                      pcie_rst_n,                         // 低有效复位或同步复位状态
        output                                     user_lnk_up,                        // XDMA报告PCIe链路已经建立

        input                                      GTHQ0_P,                            // GT参考差分时钟正端
        input                                      GTHQ0_N,                            // GT参考差分时钟负端
        input                                      aurora_rxp,                         // 10G GT接收差分正端
        input                                      aurora_rxn,                         // 10G GT接收差分负端
        output                                     aurora_txp,                         // 10G GT发送差分正端
        output                                     aurora_txn,                         // 10G GT发送差分负端


        input wire                                 aurora1g_refclk_p,                  // 对应接口时钟，使用域由连接关系确定
        input wire                                 aurora1g_refclk_n,                  // 对应接口时钟，使用域由连接关系确定
        input wire                                 aurora1g_rxp,                       // 1G GT接收差分正端
        input wire                                 aurora1g_rxn,                       // 1G GT接收差分负端
        output wire                                aurora1g_txp,                       // 1G GT发送差分正端
        output wire                                aurora1g_txn,                       // 1G GT发送差分负端
        output                                     c0_ddr4_act_n,                      // DDR4行激活控制，低有效
        output        [16:0]                       c0_ddr4_adr,                        // DDR4行列复用地址
        output        [1:0]                        c0_ddr4_ba,                         // DDR4Bank地址
        output        [0:0]                        c0_ddr4_bg,                         // DDR4Bank组地址
        output        [0:0]                        c0_ddr4_cke,                        // DDR4时钟使能输出
        output        [0:0]                        c0_ddr4_odt,                        // DDR4片内终端电阻控制输出
        output        [0:0]                        c0_ddr4_cs_n,                       // DDR4片选，低有效
        output        [0:0]                        c0_ddr4_ck_t,                       // DDR4差分时钟正端
        output        [0:0]                        c0_ddr4_ck_c,                       // DDR4差分时钟负端
        output                                     c0_ddr4_reset_n,                    // 低有效复位或同步复位状态
        inout         [7:0]                        c0_ddr4_dm_dbi_n,                   // DDR4双向字节掩码/DBI
        inout         [63:0]                       c0_ddr4_dq,                         // DDR4双向数据线
        inout         [7:0]                        c0_ddr4_dqs_c,                      // DDR4双向选通负端
        inout         [7:0]                        c0_ddr4_dqs_t,                      // DDR4双向选通正端

        output                                     led,                                // LED周期指示输出
        output                                     cpu_sync_50us                       // 50µs GPIO输出，高低各25µs
    );

    wire          [63:0]                       aurora_tx_d                 ;    // 发送当前数据拍
    wire                                       aurora_tx_sof               ;    // 当前帧首拍标志，与有效/接受共同使用
    wire                                       aurora_tx_eof               ;    // 当前帧末拍标志，与有效/接受共同使用
    wire          [2:0]                        aurora_tx_rem               ;    // 当前拍有效字节数减1
    wire                                       aurora_tx_src_rdy           ;    // 当前数据/事件有效
    wire                                       aurora_tx_dst_rdy           ;    // 当前通道可接受数据或业务

    wire          [63:0]                       aurora_rx_d                 ;    // 接收当前数据拍
    wire                                       aurora_rx_sof               ;    // 当前帧首拍标志，与有效/接受共同使用
    wire                                       aurora_rx_eof               ;    // 当前帧末拍标志，与有效/接受共同使用
    wire          [2:0]                        aurora_rx_rem               ;    // 当前拍有效字节数减1
    wire                                       aurora_rx_src_rdy           ;    // 当前数据/事件有效
    wire                                       aurora_rx_dst_rdy           ;    // 当前通道可接受数据或业务

    wire                                       aurora_user_clk             ;    // 对应接口时钟，使用域由连接关系确定
    wire                                       aurora_user_rstn            ;    // 低有效复位或同步复位状态
    wire                                       aurora_channel_up           ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       aurora_lane_up              ;    // 对应链路就绪状态，跨域副本按后缀区分

    wire                                       aurora1g_user_clk           ;    // 对应接口时钟，使用域由连接关系确定
    wire                                       aurora1g_user_reset         ;    // 高有效复位或同步复位状态
    wire                                       aurora1g_channel_up         ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       aurora1g_tx_ready           ;    // 当前通道可接受数据或业务
    wire                                       aurora1g_tx_sof             ;    // 当前帧首拍标志，与有效/接受共同使用
    wire                                       aurora1g_tx_eof             ;    // 当前帧末拍标志，与有效/接受共同使用
    wire                                       aurora1g_tx_valid           ;    // 当前数据/事件有效
    wire          [31:0]                       aurora1g_tx_data            ;    // 1G当前32bit发送拍，先发字节在高位
    wire          [1:0]                        aurora1g_tx_rem             ;    // 当前拍有效字节数减1
    wire                                       aurora1g_configured         ;    // 实际1G首次配置已确认
    wire          [7:0]                        aurora1g_configured_id      ;    // 实际1G保存的首次合法编号
    wire          [31:0]                       aurora1g_skipped_periods    ;    // 实际1G因忙或反压跳过的周期数
    wire          [31:0]                       aurora1g_rx_data_nc         ;    // 未使用的aurora1g_rx_data输出，仅保留接口连接
    wire          [1:0]                        aurora1g_rx_rem_nc          ;    // 未使用的aurora1g_rx_rem输出，仅保留接口连接
    wire                                       aurora1g_rx_sof_nc          ;    // 未使用的aurora1g_rx_sof输出，仅保留接口连接
    wire                                       aurora1g_rx_eof_nc          ;    // 未使用的aurora1g_rx_eof输出，仅保留接口连接
    wire                                       aurora1g_rx_valid_nc        ;    // 未使用的aurora1g_rx_valid输出，仅保留接口连接
    wire                                       aurora1g_rx_crc_error_nc    ;    // 未使用的aurora1g_rx_crc_error输出，仅保留接口连接
    wire                                       init_clk_25m                ;    // 对应接口时钟，使用域由连接关系确定
    wire                                       aurora1g_reset              ;    // 高有效复位或同步复位状态
    wire                                       aurora1g_gt_reset           ;    // 高有效复位或同步复位状态

    wire                                       clk_250m                    ;    // 250MHz业务/时间基准时钟
    wire                                       clk_156m                    ;    // 156.25MHz时钟输出
    wire                                       clk_100m                    ;    // 100MHz板载或初始化参考时钟
    wire                                       sys_rst                     ;    // 高有效系统复位
    wire                                       clk_100m_ibuf               ;    // 对应接口时钟，使用域由连接关系确定
    wire                                       sync_250m_rst_n             ;    // 低有效复位或同步复位状态
    wire                                       tick_toggle_2us             ;    // 250MHz域每2µs翻转一次的事件标志


    wire                                       ddr_sys_rst_n               ;    // DDR系统低有效复位
    RTDS_FPGA_RESET_SYNC u_ddr_sys_reset_sync (
        .clk(clk_100m),
        .rst_async_n(!sys_rst),
        .rst_sync_n(ddr_sys_rst_n)
    );
    wire                                       host_rst_n                  ;    // 系统复位的低有效命名网络，域内由平台同步器释放
    reg           [31:0]                       fpga_temp_status            ;    // 250MHz域温度状态寄存器，隔离SYSMON到AXI译码的长路径
    wire          [15:0]                       FPGA_TEMP_W                 ;    // 温度原始码和busy组合状态
    wire                                       FPGA_TEMP_BUSY_W            ;    // SYSMON周期操作busy状态


    assign host_rst_n = !sys_rst                                           ;    // 系统复位的低有效命名网络，域内由平台同步器释放


    // 250MHz沿保存温度原始码和busy字段，系统复位清零；寄存器可见值增加一拍延迟。
    always @(posedge clk_250m) begin
        if (sys_rst) begin
            fpga_temp_status <= 32'd0;
        end else begin
            fpga_temp_status <= {15'd0, FPGA_TEMP_BUSY_W, FPGA_TEMP_W};
        end
    end

    wire          [7:0]                        cfg_byte                    ;    // 首读拍Byte1配置编号
    wire                                       cfg_byte_valid              ;    // 该帧首读拍被实际接受的配置事件

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


    RTDS_FPGA_RESET_SYNC u_sync_250m_reset (
        .clk(clk_250m),
        .rst_async_n(host_rst_n),
        .rst_sync_n(sync_250m_rst_n)
    );
    RTDS_SYNC_TIMEBASE u_sync_timebase (
        .clk_250m(clk_250m),
        .rst_n(sync_250m_rst_n),
        .tick_toggle_2us(tick_toggle_2us),
        .cpu_sync_50us(cpu_sync_50us)
    );


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


    RTDS_FPGA_1G_INIT U_RTDS_FPGA_1G_INIT (
        .clk_100m(clk_100m),
        .rst(sys_rst),
        .init_clk(init_clk_25m),
        .core_reset(aurora1g_reset),
        .gt_reset(aurora1g_gt_reset)
    );

    aurora_8b10b_1p25g_design U_AURORA_1G (
        .reset(aurora1g_reset),
        .gt_reset(aurora1g_gt_reset),
        .init_clk_in(init_clk_25m),
        .gt_refclk_p(aurora1g_refclk_p),
        .gt_refclk_n(aurora1g_refclk_n),
        .rxp(aurora1g_rxp),
        .rxn(aurora1g_rxn),
        .txp(aurora1g_txp),
        .txn(aurora1g_txn),
        .tx_data(aurora1g_tx_data),
        .tx_rem(aurora1g_tx_rem),
        .tx_sof(aurora1g_tx_sof),
        .tx_eof(aurora1g_tx_eof),
        .tx_valid(aurora1g_tx_valid),
        .tx_ready(aurora1g_tx_ready),
        .rx_data(aurora1g_rx_data_nc),
        .rx_rem(aurora1g_rx_rem_nc),
        .rx_sof(aurora1g_rx_sof_nc),
        .rx_eof(aurora1g_rx_eof_nc),
        .rx_valid(aurora1g_rx_valid_nc),
        .rx_crc_error(aurora1g_rx_crc_error_nc),
        .user_clk_out(aurora1g_user_clk),
        .system_reset_out(aurora1g_user_reset),
        .channel_up(aurora1g_channel_up)
    );

    RTDS_1G_PERIODIC_TX U_RTDS_1G_PERIODIC_TX (
        .clk_250m(clk_250m),
        .tick_toggle_2us(tick_toggle_2us),
        .rst_n(host_rst_n),
        .cfg_byte(cfg_byte),
        .cfg_byte_valid(cfg_byte_valid),
        .user_clk(aurora1g_user_clk),
        .user_reset(aurora1g_user_reset),
        .channel_up(aurora1g_channel_up),
        .tx_ready(aurora1g_tx_ready),
        .tx_data(aurora1g_tx_data),
        .tx_rem(aurora1g_tx_rem),
        .tx_sof(aurora1g_tx_sof),
        .tx_eof(aurora1g_tx_eof),
        .tx_valid(aurora1g_tx_valid),
        .configured(aurora1g_configured),
        .configured_id(aurora1g_configured_id),
        .skipped_periods(aurora1g_skipped_periods)
    );

    PCIe #(
        .RX_PERIOD_CYCLES(RX_PERIOD_CYCLES),
        .RX_VIO_TEST_ENABLE(RX_VIO_TEST_ENABLE) // 2026-10-13：仅编译时选择测试源
    ) u_pcie (
        .cfg_byte(cfg_byte),
        .cfg_byte_valid(cfg_byte_valid),
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
        .aurora1g_channel_up (aurora1g_channel_up),
        .aurora1g_configured (aurora1g_configured),
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


endmodule
