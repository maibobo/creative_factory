// 主机侧数据连接：XDMA/寄存器、FDMA业务和DDR后端之间的封装。
// INFO_EXCH接收软件启动、地址、长度与读完确认；adapter完成10G收发业务。
// 下行地址范围为0x8000～0xFFFF；上行使用0x100000开始的8个256KiB块。
// DDR接口使用低32bit地址；软件命令结束、写响应成功和块可读是不同状态。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module PCIe #(
    parameter integer RX_PERIOD_CYCLES = 25000000,
    parameter integer RX_VIO_TEST_ENABLE = 0 // 2026-10-13：默认不改变正式接收通路
) (

    output wire   [7:0]                        cfg_byte,                              // 首读拍Byte1配置编号
    output wire                                cfg_byte_valid,                        // 该帧首读拍被实际接受的配置事件

    input         [1:0]                        pcie_mgt_rxn,                          // PCIe GT接收差分负端
    input         [1:0]                        pcie_mgt_rxp,                          // PCIe GT接收差分正端
    output        [1:0]                        pcie_mgt_txn,                          // PCIe GT发送差分负端
    output        [1:0]                        pcie_mgt_txp,                          // PCIe GT发送差分正端
    input         [0:0]                        pcie_diff_clk_n,                       // 对应接口时钟，使用域由连接关系确定
    input         [0:0]                        pcie_diff_clk_p,                       // 对应接口时钟，使用域由连接关系确定
    input                                      pcie_rst_n,                            // 低有效复位或同步复位状态
    output                                     user_lnk_up,                           // XDMA报告PCIe链路已经建立

    input         [31:0]                       FPGA_TEMP_W,                           // 温度原始码和busy组合状态

    input                                      i_sys_clk,                             // 本模块业务时钟
    input                                      i_sys_rst,                             // 本模块高有效复位

    input                                      ddr_sys_clk_i,                         // 对应接口时钟，使用域由连接关系确定
    input                                      ddr_sys_rst_n,                         // DDR系统低有效复位
    output                                     c0_ddr4_act_n,                         // DDR4行激活控制，低有效
    output        [16:0]                       c0_ddr4_adr,                           // DDR4行列复用地址
    output        [1:0]                        c0_ddr4_ba,                            // DDR4Bank地址
    output        [0:0]                        c0_ddr4_bg,                            // DDR4Bank组地址
    output        [0:0]                        c0_ddr4_cke,                           // DDR4时钟使能输出
    output        [0:0]                        c0_ddr4_odt,                           // DDR4片内终端电阻控制输出
    output        [0:0]                        c0_ddr4_cs_n,                          // DDR4片选，低有效
    output        [0:0]                        c0_ddr4_ck_t,                          // DDR4差分时钟正端
    output        [0:0]                        c0_ddr4_ck_c,                          // DDR4差分时钟负端
    output                                     c0_ddr4_reset_n,                       // 低有效复位或同步复位状态
    inout         [7:0]                        c0_ddr4_dm_dbi_n,                      // DDR4双向字节掩码/DBI
    inout         [63:0]                       c0_ddr4_dq,                            // DDR4双向数据线
    inout         [7:0]                        c0_ddr4_dqs_c,                         // DDR4双向选通负端
    inout         [7:0]                        c0_ddr4_dqs_t,                         // DDR4双向选通正端

    input                                      aurora_user_clk,                       // 对应接口时钟，使用域由连接关系确定
    input                                      aurora_user_rstn,                      // 低有效复位或同步复位状态
    input                                      aurora_channel_up,                     // 对应链路就绪状态，跨域副本按后缀区分
    input                                      aurora_lane_up,                        // 10G Aurora lane就绪状态
    input                                      aurora1g_channel_up,                    // 1G Aurora用户域channel_up，跨域后供状态寄存器读取
    input                                      aurora1g_configured,                    // 1G首次合法配置已完成，来自250MHz业务域

    output        [63:0]                       aurora_tx_d,                           // 发送当前数据拍
    output                                     aurora_tx_sof,                         // 当前帧首拍标志，与有效/接受共同使用
    output                                     aurora_tx_eof,                         // 当前帧末拍标志，与有效/接受共同使用
    output        [2:0]                        aurora_tx_rem,                         // 当前拍有效字节数减1
    output                                     aurora_tx_src_rdy,                     // 当前数据/事件有效
    input                                      aurora_tx_dst_rdy,                     // 当前通道可接受数据或业务

    input         [63:0]                       aurora_rx_d,                           // 接收当前数据拍
    input                                      aurora_rx_sof,                         // 当前帧首拍标志，与有效/接受共同使用
    input                                      aurora_rx_eof,                         // 当前帧末拍标志，与有效/接受共同使用
    input         [2:0]                        aurora_rx_rem,                         // 当前拍有效字节数减1
    input                                      aurora_rx_src_rdy,                     // 当前数据/事件有效
    output                                     aurora_rx_dst_rdy                      // 当前通道可接受数据或业务
    );


    localparam integer                             FRAME_BYTES = 16               ;    // 单帧字节数，当前16Byte
    localparam integer                             ACTIVE_WINDOW_BYTES = 32 * 1024;    // 允许的下行数据字节范围
    localparam    [31:0]                       RX_BASE_ADDR_LO = 32'h0010_0000    ;    // 本模块RX_BASE_ADDR_LO固定配置/状态编码
    localparam    [31:0]                       TX_BASE_ADDR_LO = 32'h0000_8000    ;    // 当前任务锁定的DDR低32bit起始地址
    localparam    [31:0]                       CARD_ADDR_HI = 32'h0000_0000       ;    // 卡端地址高32bit，当前使用0


    wire          [63:0]                       fdma_raddr                         ;    // 读起始字节地址
    wire                                       fdma_rareq                         ;    // 读请求，保持到busy接受
    wire                                       fdma_rbusy                         ;    // 读请求仍在处理
    wire          [63:0]                       fdma_rdata                         ;    // 当前读数据
    wire          [15:0]                       fdma_rsize                         ;    // 读请求64bit拍数
    wire                                       fdma_rvalid                        ;    // 读数据已接受事件
    wire                                       fdma_rready                        ;    // 读数据接收许可

    wire          [63:0]                       fdma_waddr                         ;    // 写起始字节地址
    wire                                       fdma_wareq                         ;    // 写请求，保持到busy接受
    wire                                       fdma_wbusy                         ;    // 写请求仍在处理，包含等待响应
    wire                                       fdma_wdone                         ;    // 本次写最终响应完成单拍
    wire                                       fdma_werror                        ;    // 本次写错误，与done共同判断
    wire          [31:0]                       RX_READY_BLOCKS                    ;    // 完整待读块数量
    wire          [31:0]                       RX_HEAD_SEQ                        ;    // 最早待读块的顺序编号
    wire          [31:0]                       RX_DROPPED_FRAMES                  ;    // 累计丢失32bit字数，端口名保留历史命名
    wire          [7:0]                        fdma_wstrb                         ;    // 写字节使能，完整FF、尾字0F
    wire                                       cpu_wr_done_event                  ;    // 本条下行命令结束单拍，成功/拒绝/失效均可能触发
    wire          [63:0]                       fdma_wdata                         ;    // 当前写数据
    wire          [15:0]                       fdma_wsize                         ;    // 写请求64bit拍数


    wire                                       fdma_w_source_valid                ;    // 当前数据/事件有效
    wire                                       fdma_w_accept                      ;    // CONV_DMA已接受当前写拍，映射至adapter写接收输入

    wire          [31:0]                       FPGA_CPU_START_ADDR                ;    // 最早待读块的DDR字节地址
    wire          [31:0]                       FPGA_CPU_LEN                       ;    // 最早待读块成功写入的字节长度
    wire          [31:0]                       CPU_FPGA_START_ADDR                ;    // 软件配置的下行DDR起始字节地址
    wire          [31:0]                       CPU_FPGA_LEN                       ;    // 软件配置的下行字节长度

    wire                                       CLEAR_INTER_R                      ;    // 读取0x10形成的单拍清相关错误
    wire                                       CPU_REC_STATE_R                    ;    // 软件写0x14形成的CPU读完确认
    wire                                       CPU_REC_STATE_W                    ;    // CPU确认状态返回寄存器侧
    wire                                       INT_STATE_W                        ;    // 当前待读块的通知状态
    wire                                       INT_STATE_R                        ;    // 读取0x10形成的单拍清通知
    wire                                       RD_START                           ;    // INFO_EXCH发出的单拍下行启动命令
    wire                                       CPU_WR_DONE_resp                   ;    // 下行业务任务响应忙状态
    wire                                       FPGA_CPU_irq_req                   ;    // 有待读块时向XDMA申请中断
    wire                                       user_lnk_up_int                    ;    // XDMA链路状态内部连接

    wire                                       rx_fifo_almost_full                ;    // FIFO接近满，需暂停继续输入
    wire                                       rx_fifo_full                       ;    // FIFO当前已满
    wire                                       rx_overflow_sticky                 ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       rx_overrun_sticky                  ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       tx_underflow_sticky                ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       fdma_timeout_sticky                ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       length_error_sticky                ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       link_down_sticky                   ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       rx_pending                         ;    // 至少有一个完整上行块等待CPU读取确认
    wire          [3:0]                        adapter_tx_state_dbg               ;    // adapter发送状态调试值
    wire          [3:0]                        adapter_rx_state_dbg               ;    // adapter块写状态调试值


    wire          [4:0]                        mem_awid                           ;    // 写地址事务ID
    wire          [4:0]                        mem_bid                            ;    // 写响应事务ID
    wire          [4:0]                        mem_arid                           ;    // 读地址事务ID
    wire          [4:0]                        mem_rid                            ;    // 读数据事务ID
    wire          [63:0]                       mem_awaddr                         ;    // 写突发起始字节地址
    wire          [63:0]                       mem_araddr                         ;    // 读突发起始字节地址
    wire          [7:0]                        mem_awlen                          ;    // 写地址突发拍数减1
    wire          [7:0]                        mem_arlen                          ;    // 读地址突发拍数减1
    wire          [2:0]                        mem_awsize                         ;    // 写地址每拍字节数的log2编码
    wire          [2:0]                        mem_arsize                         ;    // 读地址每拍字节数的log2编码
    wire          [1:0]                        mem_awburst                        ;    // 写地址地址类型，INCR为逐拍递增
    wire          [1:0]                        mem_arburst                        ;    // 读地址地址类型，INCR为逐拍递增
    wire          [0:0]                        mem_awlock                         ;    // 写地址通道lock属性
    wire          [0:0]                        mem_arlock                         ;    // 读地址通道lock属性
    wire          [3:0]                        mem_awcache                        ;    // 写地址通道cache属性
    wire          [3:0]                        mem_arcache                        ;    // 读地址通道cache属性
    wire          [3:0]                        mem_awregion                       ;    // 写地址通道region属性
    wire          [3:0]                        mem_arregion                       ;    // 读地址通道region属性
    wire          [3:0]                        mem_awqos                          ;    // 写地址通道qos属性
    wire          [3:0]                        mem_arqos                          ;    // 读地址通道qos属性
    wire          [2:0]                        mem_awprot                         ;    // 写地址通道prot属性
    wire          [2:0]                        mem_arprot                         ;    // 读地址通道prot属性
    wire                                       mem_awvalid                        ;    // 写地址通道有效，保持到ready接受
    wire                                       mem_awready                        ;    // 写地址通道当前可接受
    wire                                       mem_wlast                          ;    // 写数据最后一拍标志
    wire                                       mem_wvalid                         ;    // 写数据通道有效，保持到ready接受
    wire                                       mem_wready                         ;    // 写数据通道当前可接受
    wire          [63:0]                       mem_wdata                          ;    // 写数据当前数据
    wire          [63:0]                       mem_rdata                          ;    // 读数据当前数据
    wire          [7:0]                        mem_wstrb                          ;    // 写数据逐字节使能，尾字仅低4位
    wire          [1:0]                        mem_bresp                          ;    // 写响应响应码，0为OKAY、2为SLVERR
    wire          [1:0]                        mem_rresp                          ;    // 读数据响应码，0为OKAY、2为SLVERR
    wire                                       mem_bvalid                         ;    // 写响应通道有效，保持到ready接受
    wire                                       mem_bready                         ;    // 写响应通道当前可接受
    wire                                       mem_arvalid                        ;    // 读地址通道有效，保持到ready接受
    wire                                       mem_arready                        ;    // 读地址通道当前可接受
    wire                                       mem_rlast                          ;    // 读数据最后一拍标志
    wire                                       mem_rvalid                         ;    // 读数据通道有效，保持到ready接受
    wire                                       mem_rready                         ;    // 读数据通道当前可接受
    wire                                       ddr_ready                          ;    // 存储接口可用且旧读写错误事务已结束，可接收新业务
    wire                                       ddr_init_calib_complete            ;    // 后端DDR校准完成状态
    wire                                       ddr_axi_response_error_sticky      ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire                                       ddr_axi_timeout_sticky             ;    // 相应错误出现后保持为1，直到软件清除或复位
    wire          [31:0]                       DDR_STATUS_W                       ;    // DDR状态、错误事件及Aurora调试状态

    (* ASYNC_REG = "TRUE" *) reg [1:0] aurora10g_channel_up_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] aurora1g_channel_up_sync;
    reg                                        aurora10g_seen_up;
    reg                                        aurora10g_link_down_sticky;

    // 0x2C状态采样统一在i_sys_clk域；channel_up来自Aurora用户时钟，使用两级同步。
    // Bit6记录10G channel_up曾经建立后又拉低；读0x10的清除脉冲清除该历史标志。
    always @(posedge i_sys_clk) begin : update_aurora_debug_status
        if (i_sys_rst) begin
            aurora10g_channel_up_sync <= 2'b00;
            aurora1g_channel_up_sync <= 2'b00;
            aurora10g_seen_up <= 1'b0;
            aurora10g_link_down_sticky <= 1'b0;
        end else begin
            aurora10g_channel_up_sync <= {aurora10g_channel_up_sync[0], aurora_channel_up};
            aurora1g_channel_up_sync <= {aurora1g_channel_up_sync[0], aurora1g_channel_up};

            if (aurora10g_channel_up_sync[1])
                aurora10g_seen_up <= 1'b1;

            if (CLEAR_INTER_R)
                aurora10g_link_down_sticky <= 1'b0;
            else if (aurora10g_seen_up && !aurora10g_channel_up_sync[1])
                aurora10g_link_down_sticky <= 1'b1;
        end
    end

    // 保留Bit0～4原定义；Bit5～8依次为10G建链、10G断链历史、1G建链、1G配置完成。
    assign DDR_STATUS_W = {23'd0,
                                aurora1g_configured,
                                aurora1g_channel_up_sync[1],
                                aurora10g_link_down_sticky,
                                aurora10g_channel_up_sync[1],
                                (ddr_axi_timeout_sticky | fdma_timeout_sticky),
                                rx_overflow_sticky,
                                ddr_axi_response_error_sticky,
                                ddr_init_calib_complete,
                                ddr_ready}                                        ;



    // PCIe diagnostics 2026-10-14: separate registered observation path.
    wire [5:0] pcie_dbg_ltssm;
    wire [2:0] pcie_dbg_speed;
    wire [3:0] pcie_dbg_width;
    wire pcie_dbg_axi_clk;
    wire pcie_dbg_axi_aresetn;
    wire pcie_dbg_qpll1lock;
    wire pcie_dbg_err_cor;
    wire pcie_dbg_err_nonfatal;
    wire pcie_dbg_err_fatal;
    wire [4:0] pcie_dbg_local_error;
    wire pcie_dbg_local_error_valid;
    wire pcie_dbg_awvalid;
    wire pcie_dbg_awready;
    wire pcie_dbg_wvalid;
    wire pcie_dbg_wready;
    wire pcie_dbg_bvalid;
    wire pcie_dbg_bready;
    wire pcie_dbg_arvalid;
    wire pcie_dbg_arready;
    wire pcie_dbg_rvalid;
    wire pcie_dbg_rready;
    wire pcie_dbg_wlast;
    wire pcie_dbg_rlast;
    wire [1:0] pcie_dbg_bresp;
    wire [1:0] pcie_dbg_rresp;
    wire [7:0] pcie_dbg_wstrb;
    wire [63:0] pcie_dbg_awaddr;
    wire [63:0] pcie_dbg_araddr;
    wire [63:0] pcie_dbg_wdata;
    wire [63:0] pcie_dbg_rdata;

    assign user_lnk_up = user_lnk_up_int                                          ;    // XDMA报告PCIe链路已经建立


    // 修改点 2026-10-13：单输出VIO触发；观察量再寄存一拍，减少原业务信号负载。
    wire       rx_test_start;                                                                           // VIO单输出，0到1触发一次
    wire       rx_test_busy;                                                                            // 等待周期、输入接受及真实块完成期间保持忙
    wire [1:0] rx_test_accepted;                                                                        // 本次已接受的32bit字数，0到2
    wire [3:0] rx_test_status;                                                                          // bit3中断、bit2失败、bit1 PCIe就绪、bit0 DDR就绪
    reg        rx_test_busy_r;                                                                          // VIO观察用busy寄存副本
    reg  [1:0] rx_test_accepted_r;                                                                      // VIO观察用接受字数寄存副本
    reg  [3:0] rx_test_status_r;                                                                        // VIO观察用状态寄存副本
    reg  [3:0] rx_test_blocks_r;                                                                        // VIO观察用块数量寄存副本，0到8
    always @(posedge i_sys_clk) begin
        if (i_sys_rst) begin
            rx_test_busy_r <= 1'b0;
            rx_test_accepted_r <= 2'd0;
            rx_test_status_r <= 4'd0;
            rx_test_blocks_r <= 4'd0;
        end else begin
            rx_test_busy_r <= rx_test_busy;
            rx_test_accepted_r <= rx_test_accepted;
            rx_test_status_r <= rx_test_status;
            rx_test_blocks_r <= RX_READY_BLOCKS[3:0];
        end
    end
    generate
        if (RX_VIO_TEST_ENABLE != 0) begin : G_RX_VIO
            vio_rtds_rx_start U_VIO_RX_START (
                .clk(i_sys_clk),
                .probe_in0(rx_test_busy_r),
                .probe_in1(rx_test_accepted_r),
                .probe_in2(rx_test_status_r),
                .probe_in3(rx_test_blocks_r),
                .probe_out0(rx_test_start)
            );
        end else begin : G_RX_NO_VIO
            assign rx_test_start = 1'b0;
        end
    endgenerate

    pcie_fdma_aurora_brg_adapter #(
        .RX_VIO_TEST_ENABLE (RX_VIO_TEST_ENABLE), // 2026-10-13：编译选择
        .FRAME_BYTES         (FRAME_BYTES),
        .RX_PERIOD_CYCLES    (RX_PERIOD_CYCLES),
        .ACTIVE_WINDOW_BYTES (ACTIVE_WINDOW_BYTES),
        .RX_BASE_ADDR_LO      (RX_BASE_ADDR_LO),
        .TX_BASE_ADDR_LO      (TX_BASE_ADDR_LO),
        .CARD_ADDR_HI         (CARD_ADDR_HI)
    ) u_pcie_fdma_aurora_brg_adapter (
        .rx_test_start         (rx_test_start),
        .rx_test_busy          (rx_test_busy),
        .rx_test_accepted      (rx_test_accepted),
        .rx_test_status        (rx_test_status),
        .fdma_clk              (i_sys_clk),
        .fdma_rstn             (!i_sys_rst),
        .aurora_user_clk       (aurora_user_clk),
        .aurora_user_rstn      (aurora_user_rstn),
        .pcie_link_up          (user_lnk_up_int),
        .ddr_ready             (ddr_ready),
        .aurora_channel_up     (aurora_channel_up),
        .aurora_lane_up        (aurora_lane_up),
        .aurora_tx_d           (aurora_tx_d),
        .aurora_tx_sof         (aurora_tx_sof),
        .aurora_tx_eof         (aurora_tx_eof),
        .aurora_tx_rem         (aurora_tx_rem),
        .aurora_tx_src_rdy     (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy     (aurora_tx_dst_rdy),
        .aurora_rx_d           (aurora_rx_d),
        .aurora_rx_sof         (aurora_rx_sof),
        .aurora_rx_eof         (aurora_rx_eof),
        .aurora_rx_rem         (aurora_rx_rem),
        .aurora_rx_src_rdy     (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy     (aurora_rx_dst_rdy),
        .rd_start              (RD_START),
        .cpu_fpga_start_addr   (CPU_FPGA_START_ADDR),
        .cpu_fpga_len          (CPU_FPGA_LEN),
        .cpu_wr_done_event     (cpu_wr_done_event),
        .fdma_wstrb            (fdma_wstrb),
        .cpu_wr_done_resp      (CPU_WR_DONE_resp),
        .fpga_cpu_start_addr   (FPGA_CPU_START_ADDR),
        .fpga_cpu_len          (FPGA_CPU_LEN),
        .int_state_w           (INT_STATE_W),
        .int_state_clear       (INT_STATE_R),
        .clear_inter           (CLEAR_INTER_R),
        .cpu_rec_state_r       (CPU_REC_STATE_R),
        .cpu_rec_state_w       (CPU_REC_STATE_W),
        .fpga_cpu_irq_req      (FPGA_CPU_irq_req),
        .fdma_raddr            (fdma_raddr),
        .fdma_rareq            (fdma_rareq),
        .fdma_rbusy            (fdma_rbusy),
        .fdma_rdata            (fdma_rdata),
        .fdma_rvalid           (fdma_rvalid),
        .fdma_rready           (fdma_rready),
        .fdma_rsize            (fdma_rsize),
        .fdma_waddr            (fdma_waddr),
        .fdma_wareq            (fdma_wareq),
        .fdma_wbusy            (fdma_wbusy),
        .fdma_wdone(fdma_wdone),
        .fdma_werror(fdma_werror),
        .rx_ready_blocks(RX_READY_BLOCKS),
        .rx_head_seq(RX_HEAD_SEQ),
        .rx_dropped_frames(RX_DROPPED_FRAMES),
        .cfg_byte(cfg_byte),
        .cfg_byte_valid(cfg_byte_valid),
        .fdma_wdata            (fdma_wdata),
        .fdma_wvalid           (fdma_w_source_valid),
        .fdma_wready           (fdma_w_accept),
        .fdma_wsize            (fdma_wsize),
        .rx_fifo_almost_full   (rx_fifo_almost_full),
        .rx_fifo_full          (rx_fifo_full),
        .rx_overflow_sticky    (rx_overflow_sticky),
        .rx_overrun_sticky     (rx_overrun_sticky),
        .tx_underflow_sticky   (tx_underflow_sticky),
        .fdma_timeout_sticky   (fdma_timeout_sticky),
        .length_error_sticky   (length_error_sticky),
        .link_down_sticky      (link_down_sticky),
        .rx_pending            (rx_pending),
        .dbg_tx_state          (adapter_tx_state_dbg),
        .dbg_rx_state          (adapter_rx_state_dbg)
    );


    ila_FDMA ila_FDMA_inst (
        .clk     (i_sys_clk),
        .probe0  (fdma_raddr[31:0]),
        .probe1  (fdma_rareq),
        .probe2  (fdma_rbusy),
        .probe3  (fdma_rdata),
        .probe4  (fdma_rsize),
        .probe5  (fdma_rvalid),
        .probe6  (fdma_waddr[31:0]),
        .probe7  (fdma_wareq),
        .probe8  (fdma_wbusy),
        .probe9  (fdma_wdata),
        .probe10 (fdma_wsize),
        .probe11 (fdma_w_source_valid),
        .probe12 (adapter_rx_state_dbg),
        .probe13 (adapter_tx_state_dbg)
    );


    design_1_wrapper design_1_wrapper_inst (
        .DDR_STATUS_W             (DDR_STATUS_W),
        .RX_READY_BLOCKS(RX_READY_BLOCKS),
        .RX_HEAD_SEQ(RX_HEAD_SEQ),
        .RX_DROPPED_FRAMES(RX_DROPPED_FRAMES),
        .fdma_wdone_0(fdma_wdone),
        .fdma_werror_0(fdma_werror),
        .fdma_raddr_0            (fdma_raddr),
        .fdma_rareq_0            (fdma_rareq),
        .fdma_rbusy_0            (fdma_rbusy),
        .fdma_rdata_0            (fdma_rdata),
        .fdma_rready_0           (fdma_rready),
        .fdma_rsize_0            (fdma_rsize),
        .fdma_rvalid_0           (fdma_rvalid),
        .fdma_waddr_0            (fdma_waddr),
        .fdma_wareq_0            (fdma_wareq),
        .fdma_wbusy_0            (fdma_wbusy),
        .CPU_WR_DONE_EVENT     (cpu_wr_done_event),
        .fdma_wstrb_0          (fdma_wstrb),
        .fdma_wdata_0            (fdma_wdata),
        .fdma_wready_0           (fdma_w_source_valid),
        .fdma_wsize_0            (fdma_wsize),
        .fdma_wvalid_0           (fdma_w_accept),
        .sys_clk                 (i_sys_clk),
        .M_AXI_MEM_awid           (mem_awid),
        .M_AXI_MEM_awaddr         (mem_awaddr),
        .M_AXI_MEM_awlen          (mem_awlen),
        .M_AXI_MEM_awsize         (mem_awsize),
        .M_AXI_MEM_awburst        (mem_awburst),
        .M_AXI_MEM_awlock         (mem_awlock),
        .M_AXI_MEM_awcache        (mem_awcache),
        .M_AXI_MEM_awprot         (mem_awprot),
        .M_AXI_MEM_awregion       (mem_awregion),
        .M_AXI_MEM_awqos          (mem_awqos),
        .M_AXI_MEM_awvalid        (mem_awvalid),
        .M_AXI_MEM_awready        (mem_awready),
        .M_AXI_MEM_wdata          (mem_wdata),
        .M_AXI_MEM_wstrb          (mem_wstrb),
        .M_AXI_MEM_wlast          (mem_wlast),
        .M_AXI_MEM_wvalid         (mem_wvalid),
        .M_AXI_MEM_wready         (mem_wready),
        .M_AXI_MEM_bid            (mem_bid),
        .M_AXI_MEM_bresp          (mem_bresp),
        .M_AXI_MEM_bvalid         (mem_bvalid),
        .M_AXI_MEM_bready         (mem_bready),
        .M_AXI_MEM_arid           (mem_arid),
        .M_AXI_MEM_araddr         (mem_araddr),
        .M_AXI_MEM_arlen          (mem_arlen),
        .M_AXI_MEM_arsize         (mem_arsize),
        .M_AXI_MEM_arburst        (mem_arburst),
        .M_AXI_MEM_arlock         (mem_arlock),
        .M_AXI_MEM_arcache        (mem_arcache),
        .M_AXI_MEM_arprot         (mem_arprot),
        .M_AXI_MEM_arregion       (mem_arregion),
        .M_AXI_MEM_arqos          (mem_arqos),
        .M_AXI_MEM_arvalid        (mem_arvalid),
        .M_AXI_MEM_arready        (mem_arready),
        .M_AXI_MEM_rid            (mem_rid),
        .M_AXI_MEM_rdata          (mem_rdata),
        .M_AXI_MEM_rresp          (mem_rresp),
        .M_AXI_MEM_rlast          (mem_rlast),
        .M_AXI_MEM_rvalid         (mem_rvalid),
        .M_AXI_MEM_rready         (mem_rready),
        .sys_rst_n               (!i_sys_rst),
        .FPGA_TEMP_W_0           (FPGA_TEMP_W),
        .INT_STATE_W_0           (INT_STATE_W),
        .r_INT_STATE_0           (INT_STATE_R),
        .r_CLEAR_INTER_0         (CLEAR_INTER_R),
        .r_CPU_REC_STATE_0       (CPU_REC_STATE_R),
        .CPU_REC_STATE_W_0       (CPU_REC_STATE_W),
        .r_RD_START_0            (RD_START),
        .CPU_WR_DONE_resp_0      (CPU_WR_DONE_resp),
        .FPGA_CPU_LEN_0          (FPGA_CPU_LEN),
        .FPGA_CPU_START_ADDR_0   (FPGA_CPU_START_ADDR),
        .r_CPU_FPGA_START_ADDR_0 (CPU_FPGA_START_ADDR),
        .r_CPU_FPGA_LEN_0        (CPU_FPGA_LEN),
        .pcie_7x_mgt_rxn         (pcie_mgt_rxn),
        .pcie_7x_mgt_rxp         (pcie_mgt_rxp),
        .pcie_7x_mgt_txn         (pcie_mgt_txn),
        .pcie_7x_mgt_txp         (pcie_mgt_txp),
        .pcie_diff_clock_clk_n   (pcie_diff_clk_n),
        .pcie_diff_clock_clk_p   (pcie_diff_clk_p),
        .pcie_rst_n              (pcie_rst_n),
        .user_lnk_up             (user_lnk_up_int),
        .FPGA_CPU_irq_req        (FPGA_CPU_irq_req),
        .pcie_dbg_ltssm(pcie_dbg_ltssm),
        .pcie_dbg_speed(pcie_dbg_speed),
        .pcie_dbg_width(pcie_dbg_width),
        .pcie_dbg_axi_clk(pcie_dbg_axi_clk),
        .pcie_dbg_axi_aresetn(pcie_dbg_axi_aresetn),
        .pcie_dbg_qpll1lock(pcie_dbg_qpll1lock),
        .pcie_dbg_err_cor(pcie_dbg_err_cor),
        .pcie_dbg_err_nonfatal(pcie_dbg_err_nonfatal),
        .pcie_dbg_err_fatal(pcie_dbg_err_fatal),
        .pcie_dbg_local_error(pcie_dbg_local_error),
        .pcie_dbg_local_error_valid(pcie_dbg_local_error_valid),
        .pcie_dbg_awvalid(pcie_dbg_awvalid),
        .pcie_dbg_awready(pcie_dbg_awready),
        .pcie_dbg_wvalid(pcie_dbg_wvalid),
        .pcie_dbg_wready(pcie_dbg_wready),
        .pcie_dbg_bvalid(pcie_dbg_bvalid),
        .pcie_dbg_bready(pcie_dbg_bready),
        .pcie_dbg_arvalid(pcie_dbg_arvalid),
        .pcie_dbg_arready(pcie_dbg_arready),
        .pcie_dbg_rvalid(pcie_dbg_rvalid),
        .pcie_dbg_rready(pcie_dbg_rready),
        .pcie_dbg_wlast(pcie_dbg_wlast),
        .pcie_dbg_rlast(pcie_dbg_rlast),
        .pcie_dbg_bresp(pcie_dbg_bresp),
        .pcie_dbg_rresp(pcie_dbg_rresp),
        .pcie_dbg_wstrb(pcie_dbg_wstrb),
        .pcie_dbg_awaddr(pcie_dbg_awaddr),
        .pcie_dbg_araddr(pcie_dbg_araddr),
        .pcie_dbg_wdata(pcie_dbg_wdata),
        .pcie_dbg_rdata(pcie_dbg_rdata)

    );


    rtds_pcie_link_debug U_PCIE_LINK_DEBUG (
        .board_clk(i_sys_clk), .board_reset(i_sys_rst),
        .pcie_clk(pcie_dbg_axi_clk), .perst_n(pcie_rst_n),
        .qpll1_lock(pcie_dbg_qpll1lock), .user_lnk_up(user_lnk_up_int),
        .axi_aresetn(pcie_dbg_axi_aresetn), .ddr_ready(ddr_ready),
        .irq_req(FPGA_CPU_irq_req), .ltssm(pcie_dbg_ltssm),
        .speed(pcie_dbg_speed), .width(pcie_dbg_width),
        .err_cor(pcie_dbg_err_cor), .err_nonfatal(pcie_dbg_err_nonfatal),
        .err_fatal(pcie_dbg_err_fatal), .local_error_valid(pcie_dbg_local_error_valid),
        .local_error(pcie_dbg_local_error),
        .axi_flags({pcie_dbg_rready,pcie_dbg_rvalid,pcie_dbg_arready,pcie_dbg_arvalid,
                    pcie_dbg_bready,pcie_dbg_bvalid,pcie_dbg_wready,pcie_dbg_wvalid,
                    pcie_dbg_awready,pcie_dbg_awvalid}),
        .bresp(pcie_dbg_bresp), .rresp(pcie_dbg_rresp),
        .wlast(pcie_dbg_wlast), .rlast(pcie_dbg_rlast), .wstrb(pcie_dbg_wstrb),
        .awaddr(pcie_dbg_awaddr[31:0]), .araddr(pcie_dbg_araddr[31:0]),
        .wdata(pcie_dbg_wdata), .rdata(pcie_dbg_rdata)
    );

    rtds_ddr4_backend u_rtds_ddr4_backend (
        .s_axi_aclk(i_sys_clk),
        .s_axi_aresetn(!i_sys_rst),
        .ddr_sys_clk_i(ddr_sys_clk_i),
        .ddr_sys_rst_n(ddr_sys_rst_n),
        .clear_status(CLEAR_INTER_R),
        .s_axi_awid(mem_awid),
        .s_axi_awaddr(mem_awaddr[31:0]),
        .s_axi_awlen(mem_awlen),
        .s_axi_awsize(mem_awsize),
        .s_axi_awburst(mem_awburst),
        .s_axi_awlock(mem_awlock),
        .s_axi_awcache(mem_awcache),
        .s_axi_awprot(mem_awprot),
        .s_axi_awregion(mem_awregion),
        .s_axi_awqos(mem_awqos),
        .s_axi_awvalid(mem_awvalid),
        .s_axi_awready(mem_awready),
        .s_axi_wdata(mem_wdata),
        .s_axi_wstrb(mem_wstrb),
        .s_axi_wlast(mem_wlast),
        .s_axi_wvalid(mem_wvalid),
        .s_axi_wready(mem_wready),
        .s_axi_bid(mem_bid),
        .s_axi_bresp(mem_bresp),
        .s_axi_bvalid(mem_bvalid),
        .s_axi_bready(mem_bready),
        .s_axi_arid(mem_arid),
        .s_axi_araddr(mem_araddr[31:0]),
        .s_axi_arlen(mem_arlen),
        .s_axi_arsize(mem_arsize),
        .s_axi_arburst(mem_arburst),
        .s_axi_arlock(mem_arlock),
        .s_axi_arcache(mem_arcache),
        .s_axi_arprot(mem_arprot),
        .s_axi_arregion(mem_arregion),
        .s_axi_arqos(mem_arqos),
        .s_axi_arvalid(mem_arvalid),
        .s_axi_arready(mem_arready),
        .s_axi_rid(mem_rid),
        .s_axi_rdata(mem_rdata),
        .s_axi_rresp(mem_rresp),
        .s_axi_rlast(mem_rlast),
        .s_axi_rvalid(mem_rvalid),
        .s_axi_rready(mem_rready),
        .ddr_ready(ddr_ready),
        .init_calib_complete(ddr_init_calib_complete),
        .ddr_axi_response_error_sticky(ddr_axi_response_error_sticky),
        .ddr_axi_timeout_sticky(ddr_axi_timeout_sticky),
        .c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_adr(c0_ddr4_adr),
        .c0_ddr4_ba(c0_ddr4_ba),
        .c0_ddr4_bg(c0_ddr4_bg),
        .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_cs_n(c0_ddr4_cs_n),
        .c0_ddr4_ck_t(c0_ddr4_ck_t),
        .c0_ddr4_ck_c(c0_ddr4_ck_c),
        .c0_ddr4_reset_n(c0_ddr4_reset_n),
        .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t(c0_ddr4_dqs_t)
    );

`ifndef SYNTHESIS


    // 仅仿真检查实际AXI地址握手：高32bit非零时报错，防止连接到32bit后端时静默截断。
    always @(posedge i_sys_clk) begin
        if (mem_awvalid && mem_awready && |mem_awaddr[63:32])
            $error("DDR write address exceeds 32-bit backend aperture");
        if (mem_arvalid && mem_arready && |mem_araddr[63:32])
            $error("DDR read address exceeds 32-bit backend aperture");
    end
`endif

endmodule
