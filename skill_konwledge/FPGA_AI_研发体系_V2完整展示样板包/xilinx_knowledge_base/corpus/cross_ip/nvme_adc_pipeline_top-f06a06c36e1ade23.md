# nvme_adc_pipeline_top

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\nvme_adc_pipeline_top.sv`
- SHA-256: `f06a06c36e1ade2368d94fd73e37464ddcf4801384c5c51dc5dce1f548f68e79`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\nvme_adc_pipeline_top.sv

```systemverilog
`timescale 1ns/1ps

// ADC -> DDR分段缓存 -> 抽象NVMe请求的集成顶层。
//
// adc_clk域负责锁存采集配置、按单/双通道紧凑格式组成256 bit数据字；
// sys_clk域负责写DDR、维护分段所有权并顺序提交NVMe Write/Flush请求。
// 本顶层没有实例化MIG、SmartConnect、PCIe或供应商NVMe IP，这些板级模块
// 应连接到本模块的DDR AXI口和nvme_req/nvme_cpl抽象接口。
module nvme_adc_pipeline_top #(
    parameter integer AXI_ADDR_WIDTH = 32,    // 已交付XSA的NoPHAE与DDR地址位宽
    parameter integer AXI_DATA_WIDTH = 256,    // Writer数据位宽，当前固定32 Byte/beat
    parameter integer SEGMENT_BYTES  = 1024 * 1024,    // 单个DDR Segment容量
    parameter integer SEGMENT_COUNT  = 8,    // DDR Segment槽位数量
    parameter integer BURST_BEATS    = 16,    // 每个AXI INCR Burst的数据拍数
    parameter integer ADC_FIFO_AW    = 10,    // 329 bit异步FIFO地址位宽，默认1024项
    parameter integer COMMAND_TIMEOUT_CYCLES = 125_000_000,    // NVMe Completion超时周期数
    parameter integer LBA_BYTES = 512,    // SSD逻辑块字节数
    // Segment 0在DDR中的AXI物理地址。默认使用2 GiB窗口的上半区，
    // 避开现有Vitis/NoPHAE在0x8000_0000附近使用的队列和测试缓冲区。
    parameter [AXI_ADDR_WIDTH-1:0] DDR_BASE_ADDR = 32'hC000_0000,    // Segment 0 DDR地址
    // 独立4 KiB Commit页地址，默认紧跟所有Payload分段之后。
    parameter [AXI_ADDR_WIDTH-1:0] COMMIT_DDR_ADDR =
        DDR_BASE_ADDR + SEGMENT_COUNT * SEGMENT_BYTES,    // 固定4 KiB Commit页DDR地址
    parameter [63:0] BASE_SLBA = 64'd2048    // Raw LBA连续写入区起点
) (
    // ADC采样域：capture_start时锁存模式和Capture ID。
    input  wire                         adc_clk,    // ADC采样时钟
    input  wire                         adc_rst_n,    // ADC域低有效异步复位
    input  wire                         capture_start,    // 启动并锁存一次Capture的单拍脉冲
    input  wire                         capture_stop,    // 停止当前Capture并排空尾字
    input  wire                         cfg_two_channel,    // 待锁存单双通道模式
    input  wire                         cfg_single_channel_select,    // 待锁存单通道选择
    input  wire [63:0]                  cfg_capture_id,    // 待锁存Capture编号
    input  wire                         adc_valid,    // 当前ADC输入数据时刻有效
    input  wire [11:0]                  adc_ch0,    // ADC通道0采样
    input  wire [11:0]                  adc_ch1,    // ADC通道1采样

    // 系统/DDR控制域及真实集成状态输入。
    input  wire                         sys_clk,    // DDR、Manager、Scheduler系统时钟
    input  wire                         sys_rst_n,    // 系统域低有效同步复位
    input  wire                         ddr_init_done,    // MIG校准完成，允许CDC FIFO出队
    input  wire                         nvme_init_done,    // NoPHAE初始化完成
    input  wire                         pcie_link_up,    // PCIe链路可用
    input  wire                         ecqe_error_valid,    // NoPHAE错误完成事件有效
    input  wire [15:0]                  ecqe_error_status,    // NoPHAE错误完成状态
    // 每次FDMA兼容任务开始时装载本次Raw LBA起点；普通独立使用时可固定为0。
    input  wire                         session_start,    // 新Capture装载Raw起始LBA的单拍脉冲
    input  wire [63:0]                  session_base_slba,    // 本次Capture的Raw起始LBA

    // ADC Writer的AXI4写主口。真实工程中接SmartConnect，再接MIG AXI Slave；
    // NVMe IP的DDR AXI Master是SmartConnect的另一主设备。
    output wire [AXI_ADDR_WIDTH-1:0]    m_axi_ddr_awaddr,    // Writer AXI写地址
    output wire [7:0]                   m_axi_ddr_awlen,    // Writer Burst长度减1
    output wire [2:0]                   m_axi_ddr_awsize,    // Writer每拍字节数log2
    output wire [1:0]                   m_axi_ddr_awburst,    // Writer Burst类型
    output wire                         m_axi_ddr_awvalid,    // Writer写地址有效
    input  wire                         m_axi_ddr_awready,    // DDR互连接受写地址
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_ddr_wdata,    // Writer写数据
    output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_ddr_wstrb,    // Writer字节写使能
    output wire                         m_axi_ddr_wlast,    // Writer Burst末拍
    output wire                         m_axi_ddr_wvalid,    // Writer写数据有效
    input  wire                         m_axi_ddr_wready,    // DDR互连接受写数据
    input  wire [1:0]                   m_axi_ddr_bresp,    // DDR写响应
    input  wire                         m_axi_ddr_bvalid,    // DDR写响应有效
    output wire                         m_axi_ddr_bready,    // Writer等待写响应

    // 与仿真Stub、MicroBlaze Mailbox或未来供应商Adapter共用的抽象请求接口。
    output wire                         nvme_req_valid,    // Scheduler抽象请求有效
    input  wire                         nvme_req_ready,    // 后端接受抽象请求
    output wire [1:0]                   nvme_req_opcode,    // WRITE/READ/FLUSH抽象操作码
    output wire [AXI_ADDR_WIDTH-1:0]    nvme_req_ddr_addr,    // 请求DMA DDR地址
    output wire [31:0]                  nvme_req_byte_len,    // 请求DMA字节数
    output wire [63:0]                  nvme_req_slba,    // 请求SSD起始LBA
    output wire [15:0]                  nvme_req_user_tag,    // 请求应用层Tag
    input  wire                         nvme_cpl_valid,    // 后端Completion有效
    output wire                         nvme_cpl_ready,    // Scheduler可接收Completion
    input  wire [15:0]                  nvme_cpl_user_tag,    // Completion应用层Tag
    input  wire [15:0]                  nvme_cpl_status,    // Completion状态

    // 运行状态、错误锁存和调试计数；适合映射到ILA或软件可读寄存器。
    output wire                         capture_active,    // Packer处于采样或尾字排空期
    output wire                         capture_ready,    // Packer可接受新Capture
    output wire                         capture_done,    // 第二次Flush成功的单拍完成
    output wire [63:0]                  last_capture_id,    // 最近成功持久化的Capture编号
    output wire                         adc_overflow_sticky,    // ADC无法反压导致的丢数粘滞位
    output wire                         config_change_sticky,    // Capture运行中配置变化粘滞位
    output wire                         stream_format_error_sticky,    // Writer输入格式错误粘滞位
    output wire [63:0]                  adc_accepted_sample_times,    // Packer接受的数据时刻数
    output wire [63:0]                  adc_dropped_sample_times,    // Packer丢弃的数据时刻数
    output wire                         ddr_axi_error_sticky,    // DDR非OKAY B响应粘滞位
    output wire                         timeout_sticky,    // NVMe请求超时粘滞位
    output wire                         link_down_sticky,    // 运行期PCIe掉线粘滞位
    output wire                         fatal_error,    // 全链路致命错误汇总
    output wire [31:0]                  submitted_requests,    // 已提交项目级NVMe请求数
    output wire [31:0]                  completed_requests,    // 已完成项目级NVMe请求数
    output wire [SEGMENT_COUNT*3-1:0]   segment_states,    // Manager各槽位状态展平总线
    output wire [$clog2(SEGMENT_COUNT+1)-1:0] segment_free_count,    // Manager空闲槽位数
    // FIFO告警同步到sys_clk后输出，供Vitis兼容状态寄存器安全采样。
    output wire                         adc_fifo_full_sys,    // 同步到系统域的FIFO满告警
    output wire                         adc_fifo_prog_full_sys,    // 同步到系统域的FIFO预满告警
    output reg  [ADC_FIFO_AW:0]         adc_fifo_max_used_count    // ADC域历史最高FIFO占用
);

    wire [255:0] adc_packed_data;    // Packer当前输出数据字
    wire [5:0] adc_packed_valid_bytes;    // Packer当前字真实字节数
    wire adc_packed_eoc;    // Packer当前字Capture结束标记
    wire adc_packed_valid;    // Packer输出有效
    wire adc_packed_ready;    // CDC FIFO写侧可接受
    wire active_two_channel_adc;    // Packer已锁存单双通道模式
    wire active_single_select_adc;    // Packer已锁存单通道选择
    wire [63:0] active_capture_id_adc;    // Packer已锁存Capture编号

    // adc_channel_packer没有参数覆盖：使用默认的12 bit符号扩展。
    // 它在ADC域按双通道8个采样时刻/字、单通道16个采样时刻/字打包。
    adc_channel_packer u_adc_channel_packer (
        .adc_clk                       (adc_clk),
        .adc_rst_n                     (adc_rst_n),
        .capture_start                 (capture_start),
        .capture_stop                  (capture_stop),
        .cfg_two_channel               (cfg_two_channel),
        .cfg_single_channel_select     (cfg_single_channel_select),
        .cfg_capture_id                (cfg_capture_id),
        .adc_valid                     (adc_valid),
        .adc_ch0                       (adc_ch0),
        .adc_ch1                       (adc_ch1),
        .m_axis_tdata                  (adc_packed_data),
        .m_axis_valid_bytes            (adc_packed_valid_bytes),
        .m_axis_end_of_capture         (adc_packed_eoc),
        .m_axis_tvalid                 (adc_packed_valid),
        .m_axis_tready                 (adc_packed_ready),
        .capture_active                (capture_active),
        .capture_ready                 (capture_ready),
        .active_two_channel            (active_two_channel_adc),
        .active_single_channel_select  (active_single_select_adc),
        .active_capture_id             (active_capture_id_adc),
        .overflow_sticky               (adc_overflow_sticky),
        .config_change_sticky          (config_change_sticky),
        .accepted_sample_times         (adc_accepted_sample_times),
        .dropped_sample_times          (adc_dropped_sample_times)
    );

    // 329 bit CDC载荷的精确位域定义：
    //   [328]     end_of_capture，本字是本次Capture的最后一个传输标记；
    //   [327:322] valid_bytes，data中真实有效的低位字节数，取值0..32；
    //   [321]     本Capture是否为双通道；
    //   [320]     单通道时选择CH1(1)还是CH0(0)；
    //   [319:256] Capture ID；
    //   [255:0]   按采样时间顺序紧凑排列的ADC Payload，未用高字节补零。
    //
    // 模式和Capture ID必须与数据原子跨域。旧实现把这66 bit另行用两级
    // 寄存器同步，首个数据字可能先于上下文到达sys_clk，从而被标成上一
    // Capture；把上下文放入同一FIFO表项可从结构上消除该竞态。
    wire [328:0] adc_fifo_sdata = {
        adc_packed_eoc,
        adc_packed_valid_bytes,
        active_two_channel_adc,
        active_single_select_adc,
        active_capture_id_adc,
        adc_packed_data
    };
    wire [328:0] adc_fifo_mdata;    // sys_clk域FWFT队首复合条目
    wire adc_fifo_mvalid;    // CDC FIFO读侧条目有效
    wire adc_fifo_mready;    // DDR就绪且Writer可接收队首
    wire adc_fifo_full;    // ADC写侧FIFO满
    wire adc_fifo_empty;    // 当前未参与决策；保留的FIFO空诊断
    wire adc_fifo_prog_full;    // ADC写侧FIFO接近满
    wire [ADC_FIFO_AW:0] adc_fifo_wr_count;    // ADC写侧观察到的占用量
    wire [ADC_FIFO_AW:0] adc_fifo_rd_count;    // 当前未参与决策；保留的读侧占用诊断

    // axis_async_fifo是本项目RTL封装，内部例化Xilinx XPM的xpm_fifo_async
    // IP宏；它不是单独生成的.xci FIFO，也不是由移位寄存器手写的FIFO。
    // DATA_WIDTH=329对应上面的复合载荷，保证数据、边界和Capture上下文
    // 原子跨域；
    // ADDR_WIDTH=ADC_FIFO_AW表示深度为2^ADC_FIFO_AW，默认2^10=1024表项。
    // s_axis_tready由XPM full状态形成反压；若不可反压ADC仍继续给数，
    // packer会用overflow_sticky和dropped_sample_times记录数据损失。
    axis_async_fifo #(
        // 每个FIFO表项同时携带256 bit数据、7 bit边界和66 bit上下文。
        .DATA_WIDTH (329),
        // 读写指针地址位宽，默认10对应1024表项，双通道约32.8 us缓存。
        .ADDR_WIDTH (ADC_FIFO_AW)
    ) u_adc_cdc_fifo (
        .s_clk          (adc_clk),
        .s_rst_n        (adc_rst_n),
        .s_axis_tdata   (adc_fifo_sdata),
        .s_axis_tvalid  (adc_packed_valid),
        .s_axis_tready  (adc_packed_ready),
        .m_clk          (sys_clk),
        .m_rst_n        (sys_rst_n),
        .m_axis_tdata   (adc_fifo_mdata),
        .m_axis_tvalid  (adc_fifo_mvalid),
        .m_axis_tready  (adc_fifo_mready),
        .full           (adc_fifo_full),
        .empty          (adc_fifo_empty),
        .prog_full      (adc_fifo_prog_full),
        .wr_used_count  (adc_fifo_wr_count),
        .rd_used_count  (adc_fifo_rd_count)
    );

    // 记录ADC写侧观测到的历史最高占用量，用于上板后反推最坏DDR停顿。
    always @(posedge adc_clk or negedge adc_rst_n) begin
        if (!adc_rst_n)
            adc_fifo_max_used_count <= {(ADC_FIFO_AW+1){1'b0}};
        else if (adc_fifo_wr_count > adc_fifo_max_used_count)
            adc_fifo_max_used_count <= adc_fifo_wr_count;
    end

    // ADC域的两个错误均为Sticky单bit，使用两级同步后参与sys_clk域冻结。
    // Payload上下文本身已经随329 bit FIFO原子跨域，不再走多位寄存器CDC。
    reg adc_integrity_meta;    // ADC错误粘滞汇总的系统域第一级同步
    reg adc_integrity_sys;    // ADC错误粘滞汇总的系统域第二级同步
    reg adc_fifo_full_meta_sys;    // FIFO满标志的系统域第一级同步
    reg adc_fifo_full_sync_sys;    // FIFO满标志的系统域第二级同步
    reg adc_fifo_prog_full_meta_sys;    // FIFO预满标志的系统域第一级同步
    reg adc_fifo_prog_full_sync_sys;    // FIFO预满标志的系统域第二级同步
    assign adc_fifo_full_sys = adc_fifo_full_sync_sys;
    assign adc_fifo_prog_full_sys = adc_fifo_prog_full_sync_sys;
    always @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            adc_integrity_meta <= 1'b0;
            adc_integrity_sys  <= 1'b0;
            adc_fifo_full_meta_sys      <= 1'b0;
            adc_fifo_full_sync_sys      <= 1'b0;
            adc_fifo_prog_full_meta_sys <= 1'b0;
            adc_fifo_prog_full_sync_sys <= 1'b0;
        end else begin
            adc_integrity_meta <= adc_overflow_sticky ||
                                  config_change_sticky;
            adc_integrity_sys  <= adc_integrity_meta;
            adc_fifo_full_meta_sys      <= adc_fifo_full;
            adc_fifo_full_sync_sys      <= adc_fifo_full_meta_sys;
            adc_fifo_prog_full_meta_sys <= adc_fifo_prog_full;
            adc_fifo_prog_full_sync_sys <= adc_fifo_prog_full_meta_sys;
        end
    end

    wire alloc_valid;    // Writer到Manager的槽位申请有效
    wire alloc_ready;    // Manager存在FREE槽位
    wire [$clog2(SEGMENT_COUNT)-1:0] alloc_segment_id;    // Manager分配的槽位编号
    wire [15:0] alloc_tag;    // Manager分配的代数Tag
    wire [AXI_ADDR_WIDTH-1:0] alloc_ddr_addr;    // Manager分配的DDR地址
    wire fill_valid;    // Writer到Manager的描述符有效
    wire fill_ready;    // Manager可接收描述符
    wire [$clog2(SEGMENT_COUNT)-1:0] fill_segment_id;    // 完成写入的槽位编号
    wire [15:0] fill_tag;    // 完成写入的槽位Tag
    wire fill_error;    // Segment DDR写错误
    wire [63:0] fill_payload_bytes;    // Segment真实Payload字节数
    wire [31:0] fill_dma_bytes;    // Segment对齐DMA字节数
    wire [63:0] fill_sequence;    // Segment顺序号
    wire [31:0] fill_crc32c;    // Segment真实Payload CRC32C
    wire [63:0] fill_capture_id;    // Segment所属Capture编号
    wire [63:0] fill_sample_count;    // Segment数据时刻数
    wire fill_two_channel;    // Segment单双通道格式
    wire fill_single_select;    // Segment单通道选择
    wire fill_capture_last;    // Segment为Capture尾段
    wire writer_stream_ready;    // Writer对CDC FIFO队首的接收许可

    wire commit_valid;    // Writer Commit页准备完成
    wire commit_ready;    // Scheduler已接收Commit上下文
    wire [AXI_ADDR_WIDTH-1:0] commit_ddr_addr;    // Commit页DDR地址
    wire [31:0] commit_dma_bytes;    // Commit页DMA长度
    wire [63:0] commit_capture_id;    // Commit页Capture编号
    wire [63:0] commit_sample_count;    // 当前未被Scheduler读取；保留的Capture时刻汇总
    wire [63:0] commit_payload_bytes;    // 当前未被Scheduler读取；保留的Capture字节汇总
    wire commit_error;    // Commit页DDR写错误

    // DDR Writer参数含义：
    // AXI_ADDR_WIDTH/AXI_DATA_WIDTH定义实际AXI总线形态；
    // SEGMENT_BYTES/SEGMENT_COUNT定义固定分段布局；
    // BURST_BEATS定义单次固定Burst长度；
    // DDR_BASE_ADDR和COMMIT_DDR_ADDR分别定位Payload区与独立Commit页。
    adc_ddr_segment_writer #(
        // 透传顶层DDR地址宽度。
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
        // 透传256 bit数据总线宽度。
        .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
        // 每个Payload分段的固定容量。
        .SEGMENT_BYTES   (SEGMENT_BYTES),
        // 可轮转使用的Payload分段数量。
        .SEGMENT_COUNT   (SEGMENT_COUNT),
        // 每次AXI写Burst的数据拍数。
        .BURST_BEATS     (BURST_BEATS),
        // 分段地址计算基址。
        .DDR_BASE_ADDR   (DDR_BASE_ADDR),
        // Capture Commit页专用DDR地址。
        .COMMIT_DDR_ADDR (COMMIT_DDR_ADDR)
    ) u_segment_writer (
        .clk                           (sys_clk),
        .rst_n                         (sys_rst_n),
        .s_axis_tdata                  (adc_fifo_mdata[255:0]),
        .s_axis_valid_bytes            (adc_fifo_mdata[327:322]),
        .s_axis_end_of_capture         (adc_fifo_mdata[328]),
        .s_axis_tvalid                 (adc_fifo_mvalid && ddr_init_done),
        .s_axis_tready                 (writer_stream_ready),
        .cfg_two_channel               (adc_fifo_mdata[321]),
        .cfg_single_channel_select     (adc_fifo_mdata[320]),
        .cfg_capture_id                (adc_fifo_mdata[319:256]),
        .alloc_valid                   (alloc_valid),
        .alloc_ready                   (alloc_ready),
        .alloc_segment_id              (alloc_segment_id),
        .alloc_tag                     (alloc_tag),
        .alloc_ddr_addr                (alloc_ddr_addr),
        .fill_valid                    (fill_valid),
        .fill_ready                    (fill_ready),
        .fill_segment_id               (fill_segment_id),
        .fill_tag                      (fill_tag),
        .fill_error                    (fill_error),
        .fill_payload_bytes            (fill_payload_bytes),
        .fill_dma_bytes                (fill_dma_bytes),
        .fill_sequence                 (fill_sequence),
        .fill_crc32c                   (fill_crc32c),
        .fill_capture_id               (fill_capture_id),
        .fill_sample_count             (fill_sample_count),
        .fill_two_channel              (fill_two_channel),
        .fill_single_channel_select    (fill_single_select),
        .fill_capture_last             (fill_capture_last),
        .commit_valid                  (commit_valid),
        .commit_ready                  (commit_ready),
        .commit_ddr_addr               (commit_ddr_addr),
        .commit_dma_bytes              (commit_dma_bytes),
        .commit_capture_id             (commit_capture_id),
        .commit_sample_count           (commit_sample_count),
        .commit_payload_bytes          (commit_payload_bytes),
        .commit_error                  (commit_error),
        .m_axi_awaddr                  (m_axi_ddr_awaddr),
        .m_axi_awlen                   (m_axi_ddr_awlen),
        .m_axi_awsize                  (m_axi_ddr_awsize),
        .m_axi_awburst                 (m_axi_ddr_awburst),
        .m_axi_awvalid                 (m_axi_ddr_awvalid),
        .m_axi_awready                 (m_axi_ddr_awready),
        .m_axi_wdata                   (m_axi_ddr_wdata),
        .m_axi_wstrb                   (m_axi_ddr_wstrb),
        .m_axi_wlast                   (m_axi_ddr_wlast),
        .m_axi_wvalid                  (m_axi_ddr_wvalid),
        .m_axi_wready                  (m_axi_ddr_wready),
        .m_axi_bresp                   (m_axi_ddr_bresp),
        .m_axi_bvalid                  (m_axi_ddr_bvalid),
        .m_axi_bready                  (m_axi_ddr_bready),
        .axi_error_sticky              (ddr_axi_error_sticky),
        .stream_format_error_sticky    (stream_format_error_sticky),
        .accepted_sample_times         (),
        .sequence_counter              ()
    );

    // DDR校准前禁止从CDC FIFO取数；校准完成后由Writer的内部空间反压决定。
    assign adc_fifo_mready = ddr_init_done && writer_stream_ready;

    wire manager_ready_valid;    // Manager已有READY Payload描述符
    wire manager_ready_accept;    // Scheduler已提交该Payload请求
    wire [$clog2(SEGMENT_COUNT)-1:0] manager_ready_segment_id;    // 当前未参与调度；保留的READY槽位诊断
    wire [15:0] manager_ready_tag;    // READY Payload Tag
    wire [AXI_ADDR_WIDTH-1:0] manager_ready_addr;    // READY Payload DDR地址
    wire [63:0] manager_ready_payload;    // READY真实Payload字节数
    wire [31:0] manager_ready_dma;    // READY对齐DMA字节数
    wire manager_completion_valid;    // Scheduler返回Payload完成
    wire [15:0] manager_completion_tag;    // Payload完成Tag
    wire [15:0] manager_completion_status;    // Payload完成状态
    wire manager_state_error;    // Manager状态/Tag错误粘滞位

    // 分段管理器参数与Writer完全一致，二者必须对同一个segment_id计算出
    // 相同DDR地址，否则NVMe可能读取到另一个分段。
    segment_buffer_manager #(
        // DDR地址位宽。
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        // 每段字节数。
        .SEGMENT_BYTES  (SEGMENT_BYTES),
        // 分段表项数。
        .SEGMENT_COUNT  (SEGMENT_COUNT),
        // Segment 0基址。
        .DDR_BASE_ADDR  (DDR_BASE_ADDR)
    ) u_segment_manager (
        .clk                         (sys_clk),
        .rst_n                       (sys_rst_n),
        .alloc_valid                 (alloc_valid),
        .alloc_ready                 (alloc_ready),
        .alloc_segment_id            (alloc_segment_id),
        .alloc_tag                   (alloc_tag),
        .alloc_ddr_addr              (alloc_ddr_addr),
        .fill_valid                  (fill_valid),
        .fill_ready                  (fill_ready),
        .fill_segment_id             (fill_segment_id),
        .fill_tag                    (fill_tag),
        .fill_error                  (fill_error),
        .fill_payload_bytes          (fill_payload_bytes),
        .fill_dma_bytes              (fill_dma_bytes),
        .fill_sequence               (fill_sequence),
        .fill_crc32c                 (fill_crc32c),
        .fill_capture_id             (fill_capture_id),
        .fill_sample_count           (fill_sample_count),
        .fill_two_channel            (fill_two_channel),
        .fill_single_channel_select  (fill_single_select),
        .fill_capture_last           (fill_capture_last),
        .ready_valid                 (manager_ready_valid),
        .ready_accept                (manager_ready_accept),
        .ready_segment_id            (manager_ready_segment_id),
        .ready_tag                   (manager_ready_tag),
        .ready_ddr_addr              (manager_ready_addr),
        .ready_payload_bytes         (manager_ready_payload),
        .ready_dma_bytes             (manager_ready_dma),
        .ready_sequence              (),
        .ready_crc32c                 (),
        .ready_capture_id             (),
        .ready_sample_count           (),
        .ready_two_channel            (),
        .ready_single_channel_select  (),
        .ready_capture_last           (),
        .completion_valid             (manager_completion_valid),
        .completion_tag               (manager_completion_tag),
        .completion_status            (manager_completion_status),
        .segment_states               (segment_states),
        .free_count                   (segment_free_count),
        .state_error_sticky           (manager_state_error)
    );

    wire scheduler_fatal;    // Scheduler错误、超时或链路异常锁存

    // 调度器参数含义：
    // AXI_ADDR_WIDTH保证DDR描述符不截断；
    // COMMAND_TIMEOUT_CYCLES定义外部后端无响应的冻结门限；
    // BASE_SLBA定义Raw LBA连续写指针初值。
    // LBA_BYTES未覆盖，当前使用模块默认512 B；接真实SSD后须按Identify核对。
    nvme_request_scheduler #(
        // NVMe请求中的DDR缓冲区地址宽度。
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        // 请求完成超时周期数。
        .COMMAND_TIMEOUT_CYCLES  (COMMAND_TIMEOUT_CYCLES),
        // 与Vitis test_seq()中size的512 B LBA计数语义保持一致。
        .LBA_BYTES               (LBA_BYTES),
        // 本次Raw LBA数据区起点。
        .BASE_SLBA               (BASE_SLBA)
    ) u_nvme_scheduler (
        .clk                         (sys_clk),
        .rst_n                       (sys_rst_n),
        .nvme_init_done              (nvme_init_done),
        .pcie_link_up                (pcie_link_up),
        .ecqe_error_valid            (ecqe_error_valid),
        .ecqe_error_status           (ecqe_error_status),
        .external_fatal_error        (manager_state_error ||
                                      adc_integrity_sys ||
                                      stream_format_error_sticky),
        .session_start               (session_start),
        .session_base_slba           (session_base_slba),
        .ready_valid                 (manager_ready_valid),
        .ready_accept                (manager_ready_accept),
        .ready_tag                   (manager_ready_tag),
        .ready_ddr_addr              (manager_ready_addr),
        .ready_payload_bytes         (manager_ready_payload),
        .ready_dma_bytes             (manager_ready_dma),
        .manager_completion_valid    (manager_completion_valid),
        .manager_completion_tag      (manager_completion_tag),
        .manager_completion_status   (manager_completion_status),
        .commit_valid                (commit_valid),
        .commit_ready                (commit_ready),
        .commit_ddr_addr             (commit_ddr_addr),
        .commit_dma_bytes            (commit_dma_bytes),
        .commit_capture_id           (commit_capture_id),
        .commit_error                (commit_error),
        .nvme_req_valid              (nvme_req_valid),
        .nvme_req_ready              (nvme_req_ready),
        .nvme_req_opcode             (nvme_req_opcode),
        .nvme_req_ddr_addr           (nvme_req_ddr_addr),
        .nvme_req_byte_len           (nvme_req_byte_len),
        .nvme_req_slba               (nvme_req_slba),
        .nvme_req_user_tag           (nvme_req_user_tag),
        .nvme_cpl_valid              (nvme_cpl_valid),
        .nvme_cpl_ready              (nvme_cpl_ready),
        .nvme_cpl_user_tag           (nvme_cpl_user_tag),
        .nvme_cpl_status             (nvme_cpl_status),
        .capture_done                (capture_done),
        .last_capture_id             (last_capture_id),
        .fatal_error                 (scheduler_fatal),
        .timeout_sticky              (timeout_sticky),
        .link_down_sticky            (link_down_sticky),
        .submitted_requests          (submitted_requests),
        .completed_requests          (completed_requests)
    );

    // 三类错误任一发生都构成顶层fatal：NVMe/链路、所有权状态、DDR AXI响应。
    assign fatal_error = scheduler_fatal || manager_state_error ||
                         ddr_axi_error_sticky ||
                         stream_format_error_sticky ||
                         adc_integrity_sys;

endmodule
```
