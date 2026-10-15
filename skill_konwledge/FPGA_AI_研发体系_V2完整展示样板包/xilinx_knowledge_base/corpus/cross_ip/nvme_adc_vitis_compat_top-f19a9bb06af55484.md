# nvme_adc_vitis_compat_top

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\nvme_adc_vitis_compat_top.sv`
- SHA-256: `f19a9bb06af554843a0f7a9b8a25cdba6f813ec59c79b6dd3428de469f9875e7`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\nvme_adc_vitis_compat_top.sv

```systemverilog
`timescale 1ns/1ps

// 面向现有Vitis ELF的可落地集成顶层：
//
//   MicroBlaze --AXI4-Lite--> fdma_vitis_compat_regs (0x9000_0000)
//   ADC --> Packer/CDC/DDR Writer --> 分段管理/调度器
//   调度器抽象req/cpl --> nophae_dma_backend
//   nophae_dma_backend --AXI4-Lite--> NoPHAE s_axi_ctrl (0x1000_0000)
//
// 该层不实例化MIG、SmartConnect或NoPHAE加密/供应商源码。真实Vivado工程
// 只需把三个AXI接口接到现有互连，并把初始化/链路/ECQE状态接入即可。
module nvme_adc_vitis_compat_top #(
    parameter integer AXI_ADDR_WIDTH = 32,    // DDR数据面地址位宽
    parameter integer CTRL_ADDR_WIDTH = 40,    // MicroBlaze/NoPHAE控制面AXI-Lite地址位宽
    parameter integer AXI_DATA_WIDTH = 256,    // DDR Writer数据位宽
    parameter integer SEGMENT_BYTES = 1024 * 1024,    // 单个Payload Segment容量
    parameter integer SEGMENT_COUNT = 8,    // DDR Segment槽位数
    parameter integer BURST_BEATS = 16,    // Writer固定Burst拍数
    parameter integer ADC_FIFO_AW = 10,    // 329 bit ADC CDC FIFO地址位宽
    parameter integer COMMAND_TIMEOUT_CYCLES = 125_000_000,    // NVMe项目请求超时周期数
    parameter integer AXIL_TIMEOUT_CYCLES = 4096,    // NoPHAE AXI-Lite单次访问超时周期数
    parameter integer LBA_BYTES = 512,    // SSD逻辑块字节数
    parameter [AXI_ADDR_WIDTH-1:0] CAPTURE_DDR_BASE_ADDR =    // Capture Payload区DDR基地址
        32'hC000_0000,    // Capture Payload区DDR基地址
    parameter [AXI_ADDR_WIDTH-1:0] COMMIT_DDR_ADDR =    // 固定4 KiB Commit页DDR地址
        CAPTURE_DDR_BASE_ADDR + SEGMENT_COUNT * SEGMENT_BYTES,    // Commit页DDR地址
    parameter [63:0] DDR_AXI_BASE_ADDR = 64'h0000_0000_8000_0000,    // NoPHAE DMA窗口AXI基址
    parameter [63:0] DDR_WINDOW_BYTES = 64'h0000_0000_8000_0000,    // NoPHAE可访问DDR窗口大小
    parameter [CTRL_ADDR_WIDTH-1:0] NOPHAE_CTRL_BASE_ADDR =    // NoPHAE控制寄存器基址
        40'h00_1000_0000,    // NoPHAE s_axi_ctrl映射基址
    parameter [CTRL_ADDR_WIDTH-1:0] FDMA_CTRL_BASE_ADDR =    // Vitis兼容FDMA寄存器基址
        40'h00_9000_0000,    // Vitis兼容FDMA寄存器映射基址
    // 默认保护SSD前512 MiB，现有软件上电写入的LBA0任务会被明确拒绝。
    parameter [31:0] MIN_START_SLBA = 32'd1_048_576    // 允许写入的最小起始LBA
) (
    input  wire                         adc_clk,    // ADC采样时钟
    input  wire                         adc_rst_n,    // ADC域低有效异步复位
    input  wire                         adc_valid,    // 当前ADC数据时刻有效
    input  wire [11:0]                  adc_ch0,    // ADC通道0采样值
    input  wire [11:0]                  adc_ch1,    // ADC通道1采样值

    input  wire                         sys_clk,    // 控制、DDR和NoPHAE系统时钟
    input  wire                         sys_rst_n,    // 系统域低有效同步复位
    input  wire                         ddr_init_done,    // MIG初始化/校准完成
    input  wire                         nvme_init_done,    // NoPHAE初始化完成
    input  wire                         pcie_link_up,    // PCIe链路可用
    input  wire                         ecqe_error_valid,    // NoPHAE错误完成事件有效
    input  wire [15:0]                  ecqe_error_status,    // NoPHAE错误完成状态

    // ADC Writer到MIG/SmartConnect的AXI4写主口。
    output wire [AXI_ADDR_WIDTH-1:0]    m_axi_ddr_awaddr,    // ADC Writer写地址
    output wire [7:0]                   m_axi_ddr_awlen,    // ADC Writer Burst长度减1
    output wire [2:0]                   m_axi_ddr_awsize,    // ADC Writer每拍字节数log2
    output wire [1:0]                   m_axi_ddr_awburst,    // ADC Writer Burst类型
    output wire                         m_axi_ddr_awvalid,    // ADC Writer写地址有效
    input  wire                         m_axi_ddr_awready,    // DDR互连接受写地址
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_ddr_wdata,    // ADC Writer写数据
    output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_ddr_wstrb,    // ADC Writer字节写使能
    output wire                         m_axi_ddr_wlast,    // ADC Writer Burst末拍
    output wire                         m_axi_ddr_wvalid,    // ADC Writer写数据有效
    input  wire                         m_axi_ddr_wready,    // DDR互连接受写数据
    input  wire [1:0]                   m_axi_ddr_bresp,    // DDR写响应
    input  wire                         m_axi_ddr_bvalid,    // DDR写响应有效
    output wire                         m_axi_ddr_bready,    // ADC Writer等待写响应

    // MicroBlaze访问0x9000_0000兼容寄存器的AXI4-Lite Slave。
    input  wire [CTRL_ADDR_WIDTH-1:0]   s_axi_fdma_awaddr,    // FDMA写地址
    input  wire [2:0]                   s_axi_fdma_awprot,    // FDMA写保护属性，当前未参与寄存器判定
    input  wire                         s_axi_fdma_awvalid,    // FDMA写地址有效
    output wire                         s_axi_fdma_awready,    // FDMA寄存器可接收写地址
    input  wire [31:0]                  s_axi_fdma_wdata,    // FDMA写数据
    input  wire [3:0]                   s_axi_fdma_wstrb,    // FDMA写字节使能
    input  wire                         s_axi_fdma_wvalid,    // FDMA写数据有效
    output wire                         s_axi_fdma_wready,    // FDMA寄存器可接收写数据
    output wire [1:0]                   s_axi_fdma_bresp,    // FDMA写响应
    output wire                         s_axi_fdma_bvalid,    // FDMA写响应有效
    input  wire                         s_axi_fdma_bready,    // MicroBlaze接受FDMA写响应
    input  wire [CTRL_ADDR_WIDTH-1:0]   s_axi_fdma_araddr,    // FDMA读地址
    input  wire [2:0]                   s_axi_fdma_arprot,    // FDMA读保护属性，当前未参与寄存器判定
    input  wire                         s_axi_fdma_arvalid,    // FDMA读地址有效
    output wire                         s_axi_fdma_arready,    // FDMA寄存器可接收读地址
    output wire [31:0]                  s_axi_fdma_rdata,    // FDMA读数据
    output wire [1:0]                   s_axi_fdma_rresp,    // FDMA读响应
    output wire                         s_axi_fdma_rvalid,    // FDMA读数据有效
    input  wire                         s_axi_fdma_rready,    // MicroBlaze接受FDMA读数据

    // 连接NoPHAE实例32 bit s_axi_ctrl的AXI4-Lite Master。
    output wire [CTRL_ADDR_WIDTH-1:0]   m_axi_nophae_awaddr,    // NoPHAE控制寄存器写地址
    output wire [2:0]                   m_axi_nophae_awprot,    // 固定普通非安全数据访问属性
    output wire                         m_axi_nophae_awvalid,    // NoPHAE写地址有效
    input  wire                         m_axi_nophae_awready,    // NoPHAE接受写地址
    output wire [31:0]                  m_axi_nophae_wdata,    // NoPHAE寄存器写数据
    output wire [3:0]                   m_axi_nophae_wstrb,    // NoPHAE寄存器写字节使能
    output wire                         m_axi_nophae_wvalid,    // NoPHAE写数据有效
    input  wire                         m_axi_nophae_wready,    // NoPHAE接受写数据
    input  wire [1:0]                   m_axi_nophae_bresp,    // NoPHAE AXI-Lite写响应
    input  wire                         m_axi_nophae_bvalid,    // NoPHAE写响应有效
    output wire                         m_axi_nophae_bready,    // Backend接受NoPHAE写响应
    output wire [CTRL_ADDR_WIDTH-1:0]   m_axi_nophae_araddr,    // NoPHAE控制寄存器读地址
    output wire [2:0]                   m_axi_nophae_arprot,    // 固定普通非安全数据访问属性
    output wire                         m_axi_nophae_arvalid,    // NoPHAE读地址有效
    input  wire                         m_axi_nophae_arready,    // NoPHAE接受读地址
    input  wire [31:0]                  m_axi_nophae_rdata,    // NoPHAE寄存器读数据
    input  wire [1:0]                   m_axi_nophae_rresp,    // NoPHAE AXI-Lite读响应
    input  wire                         m_axi_nophae_rvalid,    // NoPHAE读数据有效
    output wire                         m_axi_nophae_rready,    // Backend接受NoPHAE读数据

    output wire                         fdma_transfer_active,    // Vitis兼容FDMA任务处于活动期
    output wire                         capture_controller_busy,    // 跨域Capture控制器忙
    output wire                         capture_active,    // Packer处于采样或尾字排空期
    output wire                         capture_ready,    // Packer可接受下一次Capture
    output wire                         local_capture_done_pulse,    // ADC侧停止并排空的本地完成脉冲
    output wire                         capture_cancelled_pulse,    // 未实际启采即取消的脉冲
    output wire                         capture_done,    // SSD第二次Flush后的最终完成脉冲
    output wire [63:0]                  last_capture_id,    // 最近成功持久化的Capture编号
    output wire                         backend_busy,    // NoPHAE Backend正在执行寄存器序列
    output wire [15:0]                  backend_last_status,    // Backend最近一条完成状态
    output wire [15:0]                  fdma_last_error,    // FDMA兼容寄存器锁存的最近错误
    output wire                         fatal_error,    // Pipeline或Backend致命错误汇总
    output wire [63:0]                  adc_accepted_sample_times,    // Packer接受的数据时刻数
    output wire [63:0]                  adc_dropped_sample_times,    // Packer丢弃的数据时刻数
    output wire [31:0]                  submitted_requests,    // Scheduler已提交项目请求数
    output wire [31:0]                  completed_requests    // Scheduler已完成项目请求数
);

    wire fdma_start_pulse;    // FDMA寄存器产生的系统域START单拍
    wire fdma_stop_pulse;    // FDMA寄存器产生的系统域STOP单拍
    wire backend_enable;    // FDMA控制位允许Backend接收请求
    wire [63:0] transfer_size_bytes;    // 本次FDMA任务目标Payload字节数
    wire [63:0] transfer_capture_id;    // 本次FDMA任务Capture编号
    wire cfg_two_channel_sys;    // 系统域单双通道配置
    wire cfg_single_select_sys;    // 系统域单通道选择
    wire [63:0] session_base_slba;    // FDMA目的地址换算出的Raw起始LBA

    wire capture_start_adc;    // CDC控制器送入ADC域的START单拍
    wire capture_stop_adc;    // CDC控制器送入ADC域的停止条件
    wire cfg_two_channel_adc;    // ADC域锁存单双通道模式
    wire cfg_single_select_adc;    // ADC域锁存单通道选择
    wire [63:0] cfg_capture_id_adc;    // ADC域锁存Capture编号

    wire nvme_req_valid;    // Scheduler到Backend的抽象请求有效
    wire nvme_req_ready;    // Backend可接收抽象请求
    wire [1:0] nvme_req_opcode;    // 抽象WRITE/READ/FLUSH操作码
    wire [AXI_ADDR_WIDTH-1:0] nvme_req_ddr_addr;    // 请求DDR缓冲物理地址
    wire [31:0] nvme_req_byte_len;    // 请求DMA字节数
    wire [63:0] nvme_req_slba;    // 请求SSD起始LBA
    wire [15:0] nvme_req_user_tag;    // 请求应用层Tag
    wire nvme_cpl_valid;    // Backend返回Completion有效
    wire nvme_cpl_ready;    // Scheduler可接收Completion
    wire [15:0] nvme_cpl_user_tag;    // Completion应用层Tag
    wire [15:0] nvme_cpl_status;    // Completion状态

    wire pipeline_fatal_error;    // Pipeline内部致命错误汇总
    wire backend_error_sticky;    // Backend寄存器序列错误粘滞位
    wire backend_timeout_sticky;    // Backend AXI-Lite或命令超时粘滞位
    wire adc_overflow_sticky;    // ADC不可反压丢数粘滞位
    wire config_change_sticky;    // Capture运行中配置变化粘滞位
    wire stream_format_error_sticky;    // Writer输入格式错误粘滞位
    wire ddr_axi_error_sticky;    // DDR写响应错误粘滞位
    wire scheduler_timeout_sticky;    // Scheduler等待Completion超时粘滞位
    wire link_down_sticky;    // Capture期间PCIe掉线粘滞位
    wire adc_fifo_full_sys;    // 系统域ADC FIFO满告警
    wire adc_fifo_prog_full_sys;    // 系统域ADC FIFO预满告警
    wire [ADC_FIFO_AW:0] adc_fifo_max_used_count;    // ADC FIFO历史最高占用

    assign fatal_error = pipeline_fatal_error || backend_error_sticky;

    fdma_vitis_compat_regs #(
        .AXIL_ADDR_WIDTH (CTRL_ADDR_WIDTH),
        .AXIL_BASE_ADDR  (FDMA_CTRL_BASE_ADDR),
        .FDMA_DATA_WIDTH (AXI_DATA_WIDTH),
        .MIN_START_SLBA  (MIN_START_SLBA)
    ) u_fdma_vitis_regs (
        .clk                       (sys_clk),
        .rst_n                     (sys_rst_n),
        .s_axi_awaddr              (s_axi_fdma_awaddr),
        .s_axi_awprot              (s_axi_fdma_awprot),
        .s_axi_awvalid             (s_axi_fdma_awvalid),
        .s_axi_awready             (s_axi_fdma_awready),
        .s_axi_wdata               (s_axi_fdma_wdata),
        .s_axi_wstrb               (s_axi_fdma_wstrb),
        .s_axi_wvalid              (s_axi_fdma_wvalid),
        .s_axi_wready              (s_axi_fdma_wready),
        .s_axi_bresp               (s_axi_fdma_bresp),
        .s_axi_bvalid              (s_axi_fdma_bvalid),
        .s_axi_bready              (s_axi_fdma_bready),
        .s_axi_araddr              (s_axi_fdma_araddr),
        .s_axi_arprot              (s_axi_fdma_arprot),
        .s_axi_arvalid             (s_axi_fdma_arvalid),
        .s_axi_arready             (s_axi_fdma_arready),
        .s_axi_rdata               (s_axi_fdma_rdata),
        .s_axi_rresp               (s_axi_fdma_rresp),
        .s_axi_rvalid              (s_axi_fdma_rvalid),
        .s_axi_rready              (s_axi_fdma_rready),
        .local_capture_done_pulse  (local_capture_done_pulse),
        .capture_cancelled_pulse   (capture_cancelled_pulse),
        .nvme_capture_done_pulse   (capture_done),
        .pipeline_fatal_error      (fatal_error),
        .adc_fifo_full             (adc_fifo_full_sys),
        .adc_fifo_prog_full        (adc_fifo_prog_full_sys),
        .accepted_sample_times     (adc_accepted_sample_times),
        .dropped_sample_times      (adc_dropped_sample_times),
        .backend_last_status       (backend_last_status),
        .transfer_start_pulse      (fdma_start_pulse),
        .transfer_stop_pulse       (fdma_stop_pulse),
        .transfer_active           (fdma_transfer_active),
        .backend_enable            (backend_enable),
        .transfer_size_bytes       (transfer_size_bytes),
        .transfer_capture_id       (transfer_capture_id),
        .cfg_two_channel           (cfg_two_channel_sys),
        .cfg_single_channel_select (cfg_single_select_sys),
        .session_base_slba         (session_base_slba),
        .last_error                (fdma_last_error)
    );

    adc_capture_limit_controller u_capture_limit (
        .sys_clk                       (sys_clk),
        .sys_rst_n                     (sys_rst_n),
        .start_pulse_sys               (fdma_start_pulse),
        .stop_pulse_sys                (fdma_stop_pulse),
        .target_bytes_sys              (transfer_size_bytes),
        .two_channel_sys               (cfg_two_channel_sys),
        .single_select_sys             (cfg_single_select_sys),
        .capture_id_sys                (transfer_capture_id),
        .local_done_pulse_sys          (local_capture_done_pulse),
        .cancelled_pulse_sys           (capture_cancelled_pulse),
        .controller_busy_sys           (capture_controller_busy),
        .adc_clk                       (adc_clk),
        .adc_rst_n                     (adc_rst_n),
        .packer_capture_ready           (capture_ready),
        .packer_capture_active          (capture_active),
        .packer_accepted_sample_times   (adc_accepted_sample_times),
        .capture_start_adc              (capture_start_adc),
        .capture_stop_adc               (capture_stop_adc),
        .cfg_two_channel_adc            (cfg_two_channel_adc),
        .cfg_single_select_adc          (cfg_single_select_adc),
        .cfg_capture_id_adc             (cfg_capture_id_adc)
    );

    nvme_adc_pipeline_top #(
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH          (AXI_DATA_WIDTH),
        .SEGMENT_BYTES           (SEGMENT_BYTES),
        .SEGMENT_COUNT           (SEGMENT_COUNT),
        .BURST_BEATS             (BURST_BEATS),
        .ADC_FIFO_AW             (ADC_FIFO_AW),
        .COMMAND_TIMEOUT_CYCLES  (COMMAND_TIMEOUT_CYCLES),
        .LBA_BYTES               (LBA_BYTES),
        .DDR_BASE_ADDR           (CAPTURE_DDR_BASE_ADDR),
        .COMMIT_DDR_ADDR         (COMMIT_DDR_ADDR),
        .BASE_SLBA               (64'd0)
    ) u_pipeline (
        .adc_clk                       (adc_clk),
        .adc_rst_n                     (adc_rst_n),
        .capture_start                 (capture_start_adc),
        .capture_stop                  (capture_stop_adc),
        .cfg_two_channel               (cfg_two_channel_adc),
        .cfg_single_channel_select     (cfg_single_select_adc),
        .cfg_capture_id                (cfg_capture_id_adc),
        .adc_valid                     (adc_valid),
        .adc_ch0                       (adc_ch0),
        .adc_ch1                       (adc_ch1),
        .sys_clk                       (sys_clk),
        .sys_rst_n                     (sys_rst_n),
        .ddr_init_done                 (ddr_init_done),
        .nvme_init_done                (nvme_init_done),
        .pcie_link_up                  (pcie_link_up),
        .ecqe_error_valid              (ecqe_error_valid),
        .ecqe_error_status             (ecqe_error_status),
        .session_start                 (fdma_start_pulse),
        .session_base_slba             (session_base_slba),
        .m_axi_ddr_awaddr              (m_axi_ddr_awaddr),
        .m_axi_ddr_awlen               (m_axi_ddr_awlen),
        .m_axi_ddr_awsize              (m_axi_ddr_awsize),
        .m_axi_ddr_awburst             (m_axi_ddr_awburst),
        .m_axi_ddr_awvalid             (m_axi_ddr_awvalid),
        .m_axi_ddr_awready             (m_axi_ddr_awready),
        .m_axi_ddr_wdata               (m_axi_ddr_wdata),
        .m_axi_ddr_wstrb               (m_axi_ddr_wstrb),
        .m_axi_ddr_wlast               (m_axi_ddr_wlast),
        .m_axi_ddr_wvalid              (m_axi_ddr_wvalid),
        .m_axi_ddr_wready              (m_axi_ddr_wready),
        .m_axi_ddr_bresp               (m_axi_ddr_bresp),
        .m_axi_ddr_bvalid              (m_axi_ddr_bvalid),
        .m_axi_ddr_bready              (m_axi_ddr_bready),
        .nvme_req_valid                (nvme_req_valid),
        .nvme_req_ready                (nvme_req_ready),
        .nvme_req_opcode               (nvme_req_opcode),
        .nvme_req_ddr_addr             (nvme_req_ddr_addr),
        .nvme_req_byte_len             (nvme_req_byte_len),
        .nvme_req_slba                 (nvme_req_slba),
        .nvme_req_user_tag             (nvme_req_user_tag),
        .nvme_cpl_valid                (nvme_cpl_valid),
        .nvme_cpl_ready                (nvme_cpl_ready),
        .nvme_cpl_user_tag             (nvme_cpl_user_tag),
        .nvme_cpl_status               (nvme_cpl_status),
        .capture_active                (capture_active),
        .capture_ready                 (capture_ready),
        .capture_done                  (capture_done),
        .last_capture_id               (last_capture_id),
        .adc_overflow_sticky           (adc_overflow_sticky),
        .config_change_sticky          (config_change_sticky),
        .stream_format_error_sticky    (stream_format_error_sticky),
        .adc_accepted_sample_times     (adc_accepted_sample_times),
        .adc_dropped_sample_times      (adc_dropped_sample_times),
        .ddr_axi_error_sticky          (ddr_axi_error_sticky),
        .timeout_sticky                (scheduler_timeout_sticky),
        .link_down_sticky              (link_down_sticky),
        .fatal_error                   (pipeline_fatal_error),
        .submitted_requests            (submitted_requests),
        .completed_requests            (completed_requests),
        .segment_states                (),
        .segment_free_count            (),
        .adc_fifo_full_sys             (adc_fifo_full_sys),
        .adc_fifo_prog_full_sys        (adc_fifo_prog_full_sys),
        .adc_fifo_max_used_count       (adc_fifo_max_used_count)
    );

    nophae_dma_backend #(
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        .CTRL_ADDR_WIDTH         (CTRL_ADDR_WIDTH),
        .CTRL_BASE_ADDR          (NOPHAE_CTRL_BASE_ADDR),
        .DDR_AXI_BASE_ADDR       (DDR_AXI_BASE_ADDR),
        .DDR_WINDOW_BYTES        (DDR_WINDOW_BYTES),
        .LBA_BYTES               (LBA_BYTES),
        .COMMAND_TIMEOUT_CYCLES  (COMMAND_TIMEOUT_CYCLES),
        .AXIL_TIMEOUT_CYCLES     (AXIL_TIMEOUT_CYCLES)
    ) u_nophae_backend (
        .clk                     (sys_clk),
        .rst_n                   (sys_rst_n),
        .enable                  (backend_enable),
        .req_valid               (nvme_req_valid),
        .req_ready               (nvme_req_ready),
        .req_opcode              (nvme_req_opcode),
        .req_ddr_addr            (nvme_req_ddr_addr),
        .req_byte_len            (nvme_req_byte_len),
        .req_slba                (nvme_req_slba),
        .req_user_tag            (nvme_req_user_tag),
        .cpl_valid               (nvme_cpl_valid),
        .cpl_ready               (nvme_cpl_ready),
        .cpl_user_tag            (nvme_cpl_user_tag),
        .cpl_status              (nvme_cpl_status),
        .m_axi_awaddr            (m_axi_nophae_awaddr),
        .m_axi_awprot            (m_axi_nophae_awprot),
        .m_axi_awvalid           (m_axi_nophae_awvalid),
        .m_axi_awready           (m_axi_nophae_awready),
        .m_axi_wdata             (m_axi_nophae_wdata),
        .m_axi_wstrb             (m_axi_nophae_wstrb),
        .m_axi_wvalid            (m_axi_nophae_wvalid),
        .m_axi_wready            (m_axi_nophae_wready),
        .m_axi_bresp             (m_axi_nophae_bresp),
        .m_axi_bvalid            (m_axi_nophae_bvalid),
        .m_axi_bready            (m_axi_nophae_bready),
        .m_axi_araddr            (m_axi_nophae_araddr),
        .m_axi_arprot            (m_axi_nophae_arprot),
        .m_axi_arvalid           (m_axi_nophae_arvalid),
        .m_axi_arready           (m_axi_nophae_arready),
        .m_axi_rdata             (m_axi_nophae_rdata),
        .m_axi_rresp             (m_axi_nophae_rresp),
        .m_axi_rvalid            (m_axi_nophae_rvalid),
        .m_axi_rready            (m_axi_nophae_rready),
        .busy                    (backend_busy),
        .error_sticky            (backend_error_sticky),
        .timeout_sticky          (backend_timeout_sticky),
        .last_status             (backend_last_status),
        .completed_command_count ()
    );

    // 仅消除当前顶层未单独导出的诊断线告警；它们仍进入fatal/status路径。
    wire unused_diagnostics = &{
        1'b0, adc_overflow_sticky, config_change_sticky,
        stream_format_error_sticky, ddr_axi_error_sticky,
        scheduler_timeout_sticky, link_down_sticky,
        backend_timeout_sticky, adc_fifo_max_used_count
    };

endmodule
```
