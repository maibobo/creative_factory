# adc_ddr_segment_writer

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\adc_ddr_segment_writer.sv`
- SHA-256: `4c7690f81129c8eb9b720a332201d8c660d195c72dd4779dae9978cbdded2df6`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\adc_ddr_segment_writer.sv

```systemverilog
`timescale 1ns/1ps

// 256 bit采样流到固定DDR分段的AXI4写入器。
//
// 本模块同时包含两个相互解耦的状态机：
// 1. writer_state：申请分段、统计真实Payload、计算CRC、补零、生成描述符，
//    并在Capture结束后构造独立4 KiB Commit页。
// 2. axi_state：从内部Beat FIFO取出完整Burst，通过AW/W/B写入DDR。
//
// 尾段在DDR中补零到4 KiB，但CRC和payload_bytes只覆盖真实输入字节。
// 分段只有在所有AXI B响应返回后才向segment_buffer_manager提交fill描述符。
// 这里的Capture指从START、配置锁存、多个Segment到Commit页及两次Flush的
// 一次完整采集任务，并不是SystemVerilog类型。Manager只管理DDR槽位所有权，
// 不是AXI Master，也不参与本模块实际执行的DDR数据搬运。
module adc_ddr_segment_writer #(
    parameter integer AXI_ADDR_WIDTH = 64,    // DDR AXI地址位宽
    parameter integer AXI_DATA_WIDTH = 256,    // DDR数据位宽，当前实现固定为32 Byte/beat
    parameter integer SEGMENT_BYTES  = 1024 * 1024,    // 单个Payload Segment容量，单位Byte
    parameter integer SEGMENT_COUNT  = 8,    // 仅用于推导默认Commit页地址
    parameter integer BURST_BEATS    = 16,    // 固定AXI Burst长度，默认512 Byte/Burst
    parameter integer BEAT_FIFO_AW   = 7,    // Beat FIFO地址位宽，默认深度128拍
    parameter [AXI_ADDR_WIDTH-1:0] DDR_BASE_ADDR = {AXI_ADDR_WIDTH{1'b0}},    // Payload区基地址
    parameter [AXI_ADDR_WIDTH-1:0] COMMIT_DDR_ADDR =    // 独立4 KiB Commit页DDR地址
        DDR_BASE_ADDR + SEGMENT_COUNT * SEGMENT_BYTES    // 独立4 KiB Commit页DDR地址
) (
    input  wire                         clk,    // Writer、FIFO和AXI写引擎的系统时钟
    input  wire                         rst_n,    // 低有效同步复位

    // 来自ADC异步FIFO的复合流。valid_bytes可为1..32；Capture为空时允许
    // valid_bytes=0且EOC=1，用于触发“无Payload但仍写Commit”的收尾路径。
    input  wire [255:0]                 s_axis_tdata,    // Packer输出的数据字，低位字节有效
    input  wire [5:0]                   s_axis_valid_bytes,    // 当前字真实字节数0～32
    input  wire                         s_axis_end_of_capture,    // 当前字结束本次Capture
    input  wire                         s_axis_tvalid,    // 输入复合流有效
    output wire                         s_axis_tready,    // Writer当前可以无损接收该输入字

    // 已在ADC域capture_start时锁存并稳定跨域的Capture上下文。
    input  wire                         cfg_two_channel,    // 本次Capture锁存的单双通道模式
    input  wire                         cfg_single_channel_select,    // 本次Capture锁存的单通道选择
    input  wire [63:0]                  cfg_capture_id,    // 本次Capture编号

    // 向segment_buffer_manager申请FREE分段；返回Tag包含generation和segment_id。
    output wire                         alloc_valid,    // Writer有首个非空数据字，需要FREE槽位
    input  wire                         alloc_ready,    // Manager已有可分配槽位
    input  wire [$clog2(SEGMENT_COUNT)-1:0] alloc_segment_id,    // Manager返回的槽位编号
    input  wire [15:0]                  alloc_tag,    // Manager返回的{generation,segment_id}
    input  wire [AXI_ADDR_WIDTH-1:0]    alloc_ddr_addr,    // Manager返回的槽位DDR基地址

    // DDR写工作完成后的分段描述符。fill_error表示至少一个B响应失败。
    output wire                         fill_valid,    // 项目内Segment描述符有效
    input  wire                         fill_ready,    // Manager可以接收描述符
    output wire [$clog2(SEGMENT_COUNT)-1:0] fill_segment_id,    // 本描述符对应的槽位编号
    output wire [15:0]                  fill_tag,    // 分配时取得的代数Tag
    output wire                         fill_error,    // 本Segment任一DDR写响应失败
    output wire [63:0]                  fill_payload_bytes,    // 真实ADC Payload字节数
    output wire [31:0]                  fill_dma_bytes,    // 补零后的4 KiB对齐传输字节数
    output wire [63:0]                  fill_sequence,    // Capture内递增的Segment序号
    output wire [31:0]                  fill_crc32c,    // 真实Payload CRC32C
    output wire [63:0]                  fill_capture_id,    // Segment所属Capture编号
    output wire [63:0]                  fill_sample_count,    // Segment内数据时刻数
    output wire                         fill_two_channel,    // Segment使用的单双通道格式
    output wire                         fill_single_channel_select,    // Segment单通道选择
    output wire                         fill_capture_last,    // Segment是否为Capture最后一段

    // Commit页写入DDR后提交给NVMe调度器，触发Flush/Commit/Flush序列。
    output wire                         commit_valid,    // Commit页及其汇总上下文已准备好
    input  wire                         commit_ready,    // Scheduler已锁存Commit上下文
    output wire [AXI_ADDR_WIDTH-1:0]    commit_ddr_addr,    // Commit页固定DDR地址
    output wire [31:0]                  commit_dma_bytes,    // Commit页固定传输长度4 KiB
    output wire [63:0]                  commit_capture_id,    // Commit页所属Capture编号
    output wire [63:0]                  commit_sample_count,    // Capture累计数据时刻数
    output wire [63:0]                  commit_payload_bytes,    // Capture累计真实Payload字节数
    // Commit页任一AXI写响应失败时置1；调度器必须拒绝把该页提交到SSD。
    output wire                         commit_error,    // Commit页DDR写失败指示

    // 仅实现AXI4写地址、写数据和写响应通道；真实工程中接SmartConnect/MIG。
    output wire [AXI_ADDR_WIDTH-1:0]    m_axi_awaddr,    // 当前Burst起始DDR地址
    output wire [7:0]                   m_axi_awlen,    // Burst拍数减1
    output wire [2:0]                   m_axi_awsize,    // 每拍字节数的log2
    output wire [1:0]                   m_axi_awburst,    // 固定INCR Burst
    output wire                         m_axi_awvalid,    // 写地址通道有效
    input  wire                         m_axi_awready,    // DDR互连接受写地址
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,    // Beat FIFO队首数据
    output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_wstrb,    // 全字节写使能，尾部靠数据补零
    output wire                         m_axi_wlast,    // 固定Burst最后一拍
    output wire                         m_axi_wvalid,    // 写数据通道有效
    input  wire                         m_axi_wready,    // DDR互连接受写数据
    input  wire [1:0]                   m_axi_bresp,    // AXI写响应，00为OKAY
    input  wire                         m_axi_bvalid,    // 写响应有效
    output wire                         m_axi_bready,    // Writer正在等待写响应

    output reg                          axi_error_sticky,    // 任一非OKAY写响应的粘滞位
    // 非末拍短字、valid_bytes越界或不满足样本粒度时锁存，防止静默空洞。
    output reg                          stream_format_error_sticky,    // 非法复合流格式粘滞位
    output reg  [63:0]                  accepted_sample_times,    // 当前Capture累计接收的数据时刻数
    output reg  [63:0]                  sequence_counter    // 已向Manager提交的Segment序号计数
);

    // 由参数推导出的物理粒度。SEGMENT_BEATS和COMMIT_BEATS均必须是完整Burst。
    localparam integer SEGMENT_ID_W  = $clog2(SEGMENT_COUNT);    // Segment编号位宽
    localparam integer BEAT_BYTES    = AXI_DATA_WIDTH / 8;    // 每个AXI数据拍字节数
    localparam integer SEGMENT_BEATS = SEGMENT_BYTES / BEAT_BYTES;    // 满Segment总拍数
    localparam integer COMMIT_BYTES  = 4096;    // Commit页固定字节数
    localparam integer COMMIT_BEATS  = COMMIT_BYTES / BEAT_BYTES;    // Commit页拍数
    localparam integer BURST_COUNT_W = $clog2(BURST_BEATS + 1);    // Burst内拍索引位宽
    localparam integer BURST_BYTES   = BEAT_BYTES * BURST_BEATS;    // 单Burst字节数
    localparam integer BEAT_FIFO_DEPTH = 1 << BEAT_FIFO_AW;    // Beat FIFO实际深度

    // Writer控制状态：FILL接收真实数据，PAD产生4 KiB对齐零拍，
    // WAIT_JOB等待最后一个B响应，DESC再把稳定元数据交给Manager。
    localparam [3:0] WR_IDLE        = 4'd0;    // 等首个非空字并申请Segment，或处理空Capture
    localparam [3:0] WR_FILL        = 4'd1;    // 接收真实ADC字并累计Payload/CRC
    localparam [3:0] WR_PAD         = 4'd2;    // 生成尾部零拍直到4 KiB对齐长度
    localparam [3:0] WR_WAIT_JOB    = 4'd3;    // 等Payload最后一个AXI B响应
    localparam [3:0] WR_DESC        = 4'd4;    // 保持fill描述符直到Manager握手
    localparam [3:0] WR_COMMIT_FILL = 4'd5;    // 生成完整4 KiB Commit页
    localparam [3:0] WR_COMMIT_WAIT = 4'd6;    // 等Commit页最后一个AXI B响应
    localparam [3:0] WR_COMMIT_DESC = 4'd7;    // 保持Commit请求直到Scheduler握手

    reg [3:0] writer_state;    // Writer控制状态机当前状态

    // 当前Payload分段上下文；从alloc握手开始保持到fill握手结束。
    reg [SEGMENT_ID_W-1:0] current_segment_id;    // 当前分配到的DDR槽位编号
    reg [15:0] current_tag;    // 当前槽位代数Tag
    reg [AXI_ADDR_WIDTH-1:0] current_ddr_addr;    // 当前未读取；遗留保留的分配DDR地址镜像
    reg [63:0] segment_payload_count;    // 当前Segment真实Payload累计字节数
    reg [63:0] segment_sample_count;    // 当前Segment数据时刻累计数
    reg [31:0] segment_crc_state;    // 当前Segment未最终取反的CRC32C状态
    reg [31:0] segment_crc_complete;    // 当前Segment锁存的最终CRC32C
    reg [31:0] segment_dma_count;    // 当前Segment补零后的4 KiB对齐DMA长度
    reg segment_capture_last;    // 当前Segment是否收到Capture EOC
    reg segment_job_error;    // 当前Payload job的AXI错误快照
    reg [31:0] queued_beats;    // 当前job累计推入Beat FIFO的拍数

    // Capture级上下文跨越多个Segment，只有Commit描述符被接受后才清除。
    reg capture_context_valid;    // 已锁存本次Capture级上下文
    reg capture_two_channel;    // Capture锁存的单双通道模式
    reg capture_single_select;    // Capture锁存的单通道选择
    reg [63:0] capture_id_latched;    // Capture锁存编号
    reg [63:0] capture_payload_total;    // Capture真实Payload累计字节数
    reg [63:0] capture_sample_total;    // Capture数据时刻累计数
    reg [31:0] capture_segment_total;    // Capture已完成Payload Segment数

    // Beat FIFO统一缓存三类256 bit数据：真实ADC字、尾部零填充、Commit页。
    // queued_beats统计本job已写入FIFO的总拍数，不等同于当前FIFO占用量。
    reg [255:0] beat_fifo_din;    // 本拍选中的FIFO生产数据
    reg beat_fifo_push;    // 本拍向FIFO写入一个数据拍
    wire [255:0] beat_fifo_dout;    // FIFO队首，直接驱动AXI WDATA
    wire beat_fifo_full;    // FIFO满，阻止输入或补零继续推进
    wire beat_fifo_empty;    // FIFO空，阻止WVALID
    wire [BEAT_FIFO_AW:0] beat_fifo_count;    // FIFO当前占用拍数
    wire beat_fifo_pop;    // AXI W握手形成的FIFO读脉冲

    // 一个job对应一次连续DDR区域写入：普通Segment写到对齐后的dma_bytes，
    // Commit job固定写满4 KiB。job_done_pulse只在最终B响应后产生。
    reg job_active;    // AXI引擎已有一个Payload或Commit连续写job
    reg job_start_pulse;    // 新job初始化AXI计数器的单拍脉冲
    reg job_finalized;    // job目标拍数已确定，可以在最终B响应后完成
    reg job_is_commit;    // 当前未读取；遗留保留的Payload/Commit类型镜像
    reg [AXI_ADDR_WIDTH-1:0] job_base_addr;    // 当前job连续DDR写基地址
    reg [31:0] job_target_beats;    // 当前job最终应写入的总拍数
    reg [31:0] job_beats_written;    // 当前job已完成W握手的总拍数
    reg job_done_pulse;    // 最终Burst B响应完成的单拍事件
    reg job_error;    // 当前job任一B响应非OKAY后的累计错误

    // AXI数据面每次只允许一个写Burst在途，按AW -> W -> B严格顺序执行。
    reg [2:0] axi_state;    // AXI写通道状态机当前状态
    localparam [2:0] AXI_IDLE = 3'd0;    // 等待完整Burst或job结束
    localparam [2:0] AXI_AW   = 3'd1;    // 保持AW字段直到AWREADY
    localparam [2:0] AXI_W    = 3'd2;    // 发送固定BURST_BEATS个W数据拍
    localparam [2:0] AXI_B    = 3'd3;    // 等待该Burst唯一写响应
    reg [BURST_COUNT_W-1:0] burst_beat_index;    // 当前Burst内W拍索引

    reg [31:0] commit_beat_index;    // 正在生成的Commit页beat编号0～127
    reg [255:0] commit_beat_data;    // 当前Commit页beat组合内容

    // valid_bytes除以每个采样时刻的存储字节数，统一得到sample time数量：
    // 双通道每时刻4 Byte，单通道每时刻2 Byte。
    wire stream_take = s_axis_tvalid && s_axis_tready;    // 输入复合流握手事件
    wire [63:0] stream_sample_times =    // 当前输入字代表的数据时刻数
        s_axis_valid_bytes / (capture_two_channel ? 4 : 2);
    wire [63:0] payload_after_take =    // 接受当前字后的Segment真实字节数
        segment_payload_count + s_axis_valid_bytes;
    wire segment_full_after_take = (payload_after_take == SEGMENT_BYTES);    // 当前字恰好填满Segment
    wire finalize_after_take =    // 当前握手同时结束Segment或整个Capture
        stream_take && (segment_full_after_take || s_axis_end_of_capture);

    // Packer的合法流格式是：中间字固定32 Byte，末字允许0..32 Byte；
    // 双通道有效字节数必须为4的倍数，单通道必须为2的倍数。旧实现会把
    // 一个非末拍短字写成完整32 Byte AXI拍，却只增加短长度计数，随后数据
    // 地址与payload_bytes不再一致。这里在接口边界冻结该类错误。
    wire stream_mode_two_channel =    // 格式检查所用的已锁存或首字模式
        capture_context_valid ? capture_two_channel : cfg_two_channel;
    wire stream_byte_granularity_ok =    // valid_bytes满足2/4 Byte样本粒度
        stream_mode_two_channel ? (s_axis_valid_bytes[1:0] == 2'b00) :
                                  (s_axis_valid_bytes[0] == 1'b0);
    wire stream_format_valid =    // 当前条目符合中间整字或末尾短字格式
        (s_axis_valid_bytes <= 6'd32) &&
        (((s_axis_valid_bytes == 0) && s_axis_end_of_capture) ||
         ((s_axis_valid_bytes != 0) &&
          (s_axis_end_of_capture || (s_axis_valid_bytes == 6'd32)) &&
          stream_byte_granularity_ok));

    // 逐字节CRC32C，采用反射多项式0x82F63B78、初值全1、最终按位取反。
    // 只循环byte_count个低位字节，因此尾字高位补零不进入CRC。
    function automatic [31:0] crc32c_bytes;
        input [31:0] crc_in;    // 前一输入字处理后的未取反CRC状态
        input [255:0] data_in;    // 当前256 bit输入字
        input [5:0] byte_count;    // 当前字实际参与CRC的低位字节数
        integer byte_index;    // 32个候选字节的循环索引
        integer bit_index;    // 单字节8个bit的循环索引
        reg [31:0] crc;    // 函数内逐字节更新的CRC状态
        reg [7:0] data_byte;    // 当前参与运算的一个输入字节
        begin
            crc = crc_in;
            for (byte_index = 0; byte_index < 32; byte_index = byte_index + 1) begin
                if (byte_index < byte_count) begin
                    data_byte = data_in[byte_index*8 +: 8];
                    crc = crc ^ data_byte;
                    for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                        crc = crc[0] ? ((crc >> 1) ^ 32'h82F63B78) : (crc >> 1);
                end
            end
            crc32c_bytes = crc;
        end
    endfunction

    // NVMe/DDR DMA长度统一向上取整到4 KiB；payload_bytes仍保留真实长度。
    function automatic [31:0] align_4k;
        input [63:0] byte_count;    // 待向上取整的真实Payload字节数
        begin
            align_4k = (byte_count + 64'd4095) & 64'hFFFF_FFFF_FFFF_F000;
        end
    endfunction

    // sync_fifo是本项目RTL封装，内部例化Xilinx XPM的xpm_fifo_sync IP宏；
    // 它不是独立.xci，也不是手写移位寄存器。DATA_WIDTH=256对应一个DDR拍，
    // ADDR_WIDTH=BEAT_FIFO_AW表示深度2^BEAT_FIFO_AW（默认128拍/4 KiB）。
    // 该FIFO隔离writer_state的输入/补零速率与AXI AW/W/B反压；只有pop握手
    // 才移除dout，确保WVALID等待WREADY期间数据稳定。
    sync_fifo #(
        // 一个表项等于一个256 bit AXI数据拍。
        .DATA_WIDTH (256),
        // FIFO深度指数，默认7即128个数据拍。
        .ADDR_WIDTH (BEAT_FIFO_AW)
    ) u_beat_fifo (
        .clk        (clk),
        .rst_n      (rst_n),
        .din        (beat_fifo_din),
        .wr_en      (beat_fifo_push),
        .rd_en      (beat_fifo_pop),
        .dout       (beat_fifo_dout),
        .full       (beat_fifo_full),
        .empty      (beat_fifo_empty),
        .used_count (beat_fifo_count)
    );

    // 非空数据到达IDLE时才申请分段；零字节EOC不占用Payload Segment。
    assign alloc_valid = (writer_state == WR_IDLE) && s_axis_tvalid &&
                         stream_format_valid && (s_axis_valid_bytes != 0);

    // s_axis_tready逐项门控：
    // 1) 非空数据只允许在WR_FILL接收，防止alloc前首字被误消费；
    // 2) beat_fifo_full时停顿，防止覆盖尚未写入DDR的数据；
    // 3) stream_format_valid拒绝短中间字、越界字节数和错误样本粒度；
    // 4) 累计字节不得越过SEGMENT_BYTES；5) WR_IDLE仅接受零字节EOC。
    // 删除任一门控会分别造成首字丢失、FIFO覆盖、DDR字节布局与描述符不符、
    // 跨Segment写越界，或让普通Payload绕过alloc。stall期间上游必须保持条目。
    assign s_axis_tready =
        ((writer_state == WR_IDLE) && s_axis_tvalid &&
         stream_format_valid && (s_axis_valid_bytes == 0) &&
         s_axis_end_of_capture) ||
        ((writer_state == WR_FILL) && !beat_fifo_full &&
         stream_format_valid &&
         ((segment_payload_count + s_axis_valid_bytes) <= SEGMENT_BYTES));

    // 描述符在WR_DESC期间保持稳定，直到Manager通过fill_ready接受。
    assign fill_valid                   = (writer_state == WR_DESC);
    assign fill_segment_id              = current_segment_id;
    assign fill_tag                     = current_tag;
    assign fill_error                   = segment_job_error;
    assign fill_payload_bytes           = segment_payload_count;
    assign fill_dma_bytes               = segment_dma_count;
    assign fill_sequence                = sequence_counter;
    assign fill_crc32c                   = segment_crc_complete;
    assign fill_capture_id              = capture_id_latched;
    assign fill_sample_count            = segment_sample_count;
    assign fill_two_channel             = capture_two_channel;
    assign fill_single_channel_select   = capture_single_select;
    assign fill_capture_last            = segment_capture_last;

    // Commit描述符与Commit页DDR内容对应，固定传输完整4 KiB。
    assign commit_valid                 = (writer_state == WR_COMMIT_DESC);
    assign commit_ddr_addr              = COMMIT_DDR_ADDR;
    assign commit_dma_bytes             = COMMIT_BYTES;
    assign commit_capture_id            = capture_id_latched;
    assign commit_sample_count          = capture_sample_total;
    assign commit_payload_bytes         = capture_payload_total;
    assign commit_error                 =
        (writer_state == WR_COMMIT_DESC) && job_error;

    // Commit页当前定义：
    // Beat 0保存Magic "ADCCOMM1"、版本、通道模式、页长度、Capture ID、
    // 总采样时刻数；Beat 1保存真实Payload总字节数和Segment数量；
    // 其余Beat保持0，为后续格式扩展预留。
    always @* begin
        commit_beat_data = 256'd0;
        if (commit_beat_index == 0) begin
            commit_beat_data[63:0]    = 64'h314D_4D4F_4343_4441; // "ADCCOMM1"
            commit_beat_data[79:64]   = 16'd1;
            commit_beat_data[95:80]   = {14'd0, capture_single_select,
                                         capture_two_channel};
            commit_beat_data[127:96]  = COMMIT_BYTES;
            commit_beat_data[191:128] = capture_id_latched;
            commit_beat_data[255:192] = capture_sample_total;
        end else if (commit_beat_index == 1) begin
            commit_beat_data[63:0]    = capture_payload_total;
            commit_beat_data[95:64]   = capture_segment_total;
        end
    end

    // 三种FIFO生产源互斥，优先级依writer_state天然确定：
    // 真实输入 -> 尾段补零 -> Commit页。AXI消费者可与生产同时运行。
    always @* begin
        beat_fifo_push = 1'b0;
        beat_fifo_din  = 256'd0;
        if ((writer_state == WR_FILL) && stream_take &&
            (s_axis_valid_bytes != 0)) begin
            beat_fifo_push = 1'b1;
            beat_fifo_din  = s_axis_tdata;
        end else if ((writer_state == WR_PAD) &&
                     (queued_beats < job_target_beats) && !beat_fifo_full) begin
            beat_fifo_push = 1'b1;
            beat_fifo_din  = 256'd0;
        end else if ((writer_state == WR_COMMIT_FILL) &&
                     (commit_beat_index < COMMIT_BEATS) && !beat_fifo_full) begin
            beat_fifo_push = 1'b1;
            beat_fifo_din  = commit_beat_data;
        end
    end

    // 静态结构检查；这些条件若不成立，固定全字节WSTRB和完整Burst策略失效。
    initial begin
        if (AXI_DATA_WIDTH != 256)
            $error("This writer currently requires AXI_DATA_WIDTH=256");
        if ((SEGMENT_BYTES % 4096) != 0)
            $error("SEGMENT_BYTES must be 4 KiB aligned");
        if ((SEGMENT_BYTES % (BEAT_BYTES * BURST_BEATS)) != 0)
            $error("SEGMENT_BYTES must contain complete AXI bursts");
        if ((COMMIT_BYTES % (BEAT_BYTES * BURST_BEATS)) != 0)
            $error("Commit page must contain complete AXI bursts");
        if (BURST_BEATS < 1)
            $error("BURST_BEATS must be at least 1");
        if (BURST_BEATS > 256)
            $error("AXI4 burst length cannot exceed 256 beats");
        if ((BURST_BYTES > 4096) || ((4096 % BURST_BYTES) != 0))
            $error("AXI burst size must divide 4 KiB and cannot exceed it");
        if (BEAT_FIFO_DEPTH < BURST_BEATS)
            $error("Beat FIFO must hold at least one complete AXI burst");
        if (SEGMENT_BYTES > 32'hFFFF_F000)
            $error("SEGMENT_BYTES exceeds the 32-bit DMA length contract");
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            writer_state           <= WR_IDLE;
            current_segment_id     <= {SEGMENT_ID_W{1'b0}};
            current_tag            <= 16'd0;
            current_ddr_addr       <= {AXI_ADDR_WIDTH{1'b0}};
            segment_payload_count  <= 64'd0;
            segment_sample_count   <= 64'd0;
            segment_crc_state      <= 32'hFFFF_FFFF;
            segment_crc_complete   <= 32'd0;
            segment_dma_count      <= 32'd0;
            segment_capture_last   <= 1'b0;
            segment_job_error      <= 1'b0;
            queued_beats           <= 32'd0;
            capture_context_valid  <= 1'b0;
            capture_two_channel    <= 1'b0;
            capture_single_select  <= 1'b0;
            capture_id_latched     <= 64'd0;
            capture_payload_total  <= 64'd0;
            capture_sample_total   <= 64'd0;
            capture_segment_total  <= 32'd0;
            accepted_sample_times  <= 64'd0;
            sequence_counter       <= 64'd0;
            commit_beat_index      <= 32'd0;
            job_active             <= 1'b0;
            job_start_pulse        <= 1'b0;
            job_finalized          <= 1'b0;
            job_is_commit          <= 1'b0;
            job_base_addr          <= {AXI_ADDR_WIDTH{1'b0}};
            job_target_beats       <= 32'd0;
            stream_format_error_sticky <= 1'b0;
        end else begin
            job_start_pulse <= 1'b0;
            if (s_axis_tvalid && !stream_format_valid)
                stream_format_error_sticky <= 1'b1;
            case (writer_state)
                WR_IDLE: begin
                    // 空Capture由0-byte EOC直接启动Commit job，不申请Payload段。
                    if (s_axis_tvalid && (s_axis_valid_bytes == 0) &&
                        s_axis_end_of_capture) begin
                        capture_context_valid <= 1'b1;
                        capture_two_channel   <= cfg_two_channel;
                        capture_single_select <= cfg_single_channel_select;
                        capture_id_latched    <= cfg_capture_id;
                        capture_payload_total <= 64'd0;
                        capture_sample_total  <= 64'd0;
                        capture_segment_total <= 32'd0;
                        accepted_sample_times <= 64'd0;
                        job_active            <= 1'b1;
                        job_start_pulse       <= 1'b1;
                        job_finalized         <= 1'b1;
                        job_is_commit         <= 1'b1;
                        job_base_addr         <= COMMIT_DDR_ADDR;
                        job_target_beats      <= COMMIT_BEATS;
                        commit_beat_index     <= 32'd0;
                        queued_beats          <= 32'd0;
                        writer_state          <= WR_COMMIT_FILL;
                    end else if (alloc_valid && alloc_ready) begin
                        // 普通Capture首字到达后申请分段并初始化段级CRC/计数。
                        // Capture级上下文只在第一段初始化，后续分段持续累计。
                        current_segment_id    <= alloc_segment_id;
                        current_tag           <= alloc_tag;
                        current_ddr_addr      <= alloc_ddr_addr;
                        segment_payload_count <= 64'd0;
                        segment_sample_count  <= 64'd0;
                        segment_crc_state     <= 32'hFFFF_FFFF;
                        segment_job_error     <= 1'b0;
                        segment_capture_last  <= 1'b0;
                        queued_beats          <= 32'd0;
                        job_active            <= 1'b1;
                        job_start_pulse       <= 1'b1;
                        job_finalized         <= 1'b0;
                        job_is_commit         <= 1'b0;
                        job_base_addr         <= alloc_ddr_addr;
                        job_target_beats      <= SEGMENT_BEATS;
                        if (!capture_context_valid) begin
                            capture_context_valid <= 1'b1;
                            capture_two_channel   <= cfg_two_channel;
                            capture_single_select <= cfg_single_channel_select;
                            capture_id_latched    <= cfg_capture_id;
                            capture_payload_total <= 64'd0;
                            capture_sample_total  <= 64'd0;
                            capture_segment_total <= 32'd0;
                            accepted_sample_times <= 64'd0;
                        end
                        writer_state <= WR_FILL;
                    end
                end

                WR_FILL: begin
                    // 每个流握手把一个256 bit字送入Beat FIFO；sample time计数
                    // 由valid_bytes和锁存的通道模式推导，不受补零字节影响。
                    if (stream_take) begin
                        if (s_axis_valid_bytes != 0)
                            queued_beats <= queued_beats + 1'b1;
                        segment_payload_count <= payload_after_take;
                        segment_sample_count  <= segment_sample_count +
                                                 stream_sample_times;
                        capture_payload_total <= capture_payload_total +
                                                 s_axis_valid_bytes;
                        capture_sample_total  <= capture_sample_total +
                                                 stream_sample_times;
                        accepted_sample_times <= accepted_sample_times +
                                                 stream_sample_times;
                        segment_crc_state     <= crc32c_bytes(
                                                 segment_crc_state,
                                                 s_axis_tdata,
                                                 s_axis_valid_bytes);

                        if (finalize_after_take) begin
                            // 分段填满或收到EOC时锁存最终CRC和4 KiB DMA长度。
                            // 最后一个输入字已经通过上方crc32c_bytes计入。
                            segment_crc_complete <= ~crc32c_bytes(
                                                     segment_crc_state,
                                                     s_axis_tdata,
                                                     s_axis_valid_bytes);
                            segment_dma_count    <= align_4k(payload_after_take);
                            segment_capture_last <= s_axis_end_of_capture;
                            job_target_beats     <= align_4k(payload_after_take) /
                                                    BEAT_BYTES;
                            job_finalized        <= 1'b1;
                            writer_state         <= WR_PAD;
                        end
                    end
                end

                WR_PAD: begin
                    // 将真实Payload末尾补零到job_target_beats，不扩大payload/CRC。
                    if (beat_fifo_push)
                        queued_beats <= queued_beats + 1'b1;
                    if ((queued_beats == job_target_beats) &&
                        !beat_fifo_push)
                        writer_state <= WR_WAIT_JOB;
                end

                WR_WAIT_JOB: begin
                    // 必须等所有Burst的B响应，不能以W通道最后一拍作为完成。
                    if (job_done_pulse) begin
                        segment_job_error <= job_error;
                        writer_state      <= WR_DESC;
                    end
                end

                WR_DESC: begin
                    // Manager接受描述符后，本段进入READY；若是Capture尾段，
                    // 随即复用AXI job引擎写4 KiB Commit页。
                    if (fill_valid && fill_ready) begin
                        sequence_counter      <= sequence_counter + 1'b1;
                        capture_segment_total <= capture_segment_total + 1'b1;
                        job_active            <= 1'b0;
                        job_finalized         <= 1'b0;
                        if (segment_capture_last) begin
                            job_active        <= 1'b1;
                            job_start_pulse   <= 1'b1;
                            job_finalized     <= 1'b1;
                            job_is_commit     <= 1'b1;
                            job_base_addr     <= COMMIT_DDR_ADDR;
                            job_target_beats  <= COMMIT_BEATS;
                            queued_beats      <= 32'd0;
                            commit_beat_index <= 32'd0;
                            writer_state      <= WR_COMMIT_FILL;
                        end else begin
                            writer_state <= WR_IDLE;
                        end
                    end
                end

                WR_COMMIT_FILL: begin
                    // 顺序推入完整COMMIT_BEATS，未定义字段由组合逻辑置零。
                    if (beat_fifo_push) begin
                        queued_beats      <= queued_beats + 1'b1;
                        commit_beat_index <= commit_beat_index + 1'b1;
                    end
                    if ((commit_beat_index == COMMIT_BEATS) &&
                        !beat_fifo_push)
                        writer_state <= WR_COMMIT_WAIT;
                end

                WR_COMMIT_WAIT: begin
                    // Commit页同样等待最终B响应后才允许提交收尾描述符。
                    if (job_done_pulse)
                        writer_state <= WR_COMMIT_DESC;
                end

                WR_COMMIT_DESC: begin
                    // 调度器接受Commit请求后释放Capture级上下文，准备下一次采集。
                    if (commit_valid && commit_ready) begin
                        job_active            <= 1'b0;
                        job_finalized         <= 1'b0;
                        capture_context_valid <= 1'b0;
                        writer_state          <= WR_IDLE;
                    end
                end

                default: writer_state <= WR_IDLE;
            endcase
        end
    end

    // 只有内部FIFO至少积累一个完整Burst才发AW，避免W通道中途饿死。
    // 地址按已完成/已发送的数据拍数递增；每个Burst固定为INCR、全WSTRB。
    wire enough_for_burst = (beat_fifo_count >= BURST_BEATS);    // FIFO至少有一个完整Burst
    assign m_axi_awaddr  = job_base_addr + job_beats_written * BEAT_BYTES;
    assign m_axi_awlen   = BURST_BEATS - 1;
    assign m_axi_awsize  = $clog2(BEAT_BYTES);
    assign m_axi_awburst = 2'b01;
    assign m_axi_awvalid = (axi_state == AXI_AW);
    assign m_axi_wdata   = beat_fifo_dout;
    assign m_axi_wstrb   = {AXI_DATA_WIDTH/8{1'b1}};
    assign m_axi_wlast   = (burst_beat_index == BURST_BEATS-1);
    assign m_axi_wvalid  = (axi_state == AXI_W) && !beat_fifo_empty;
    assign beat_fifo_pop = m_axi_wvalid && m_axi_wready;
    assign m_axi_bready  = (axi_state == AXI_B);

    // AXI写引擎不接受多个Burst并发：一笔AW后发送BURST_BEATS个W，
    // 收到对应B响应后才返回IDLE并考虑下一笔AW。
    always @(posedge clk) begin
        if (!rst_n) begin
            axi_state          <= AXI_IDLE;
            burst_beat_index   <= {BURST_COUNT_W{1'b0}};
            job_beats_written  <= 32'd0;
            job_done_pulse     <= 1'b0;
            job_error          <= 1'b0;
            axi_error_sticky   <= 1'b0;
        end else begin
            job_done_pulse <= 1'b0;
            if (job_start_pulse) begin
                axi_state         <= AXI_IDLE;
                burst_beat_index  <= {BURST_COUNT_W{1'b0}};
                job_beats_written <= 32'd0;
                job_error         <= 1'b0;
            end else if (!job_active && (axi_state == AXI_IDLE)) begin
                job_beats_written <= 32'd0;
                job_error         <= 1'b0;
            end else case (axi_state)
                AXI_IDLE: begin
                    // job可在输入仍持续填FIFO时开始，只要求已有完整Burst。
                    if (job_active && enough_for_burst &&
                        (job_beats_written < job_target_beats))
                        axi_state <= AXI_AW;
                end

                AXI_AW: begin
                    // AW地址/长度在AWREADY前由组合输出和稳定计数保持不变。
                    if (m_axi_awready) begin
                        burst_beat_index <= {BURST_COUNT_W{1'b0}};
                        axi_state <= AXI_W;
                    end
                end

                AXI_W: begin
                    // 每次W握手同步弹出Beat FIFO；WLAST标记固定Burst最后一拍。
                    if (m_axi_wvalid && m_axi_wready) begin
                        job_beats_written <= job_beats_written + 1'b1;
                        if (m_axi_wlast)
                            axi_state <= AXI_B;
                        else
                            burst_beat_index <= burst_beat_index + 1'b1;
                    end
                end

                AXI_B: begin
                    // 任意非OKAY响应锁存job_error和全局axi_error_sticky。
                    // 只有job已finalized且累计拍数达到目标时，才宣告整个job结束。
                    if (m_axi_bvalid) begin
                        if (m_axi_bresp != 2'b00) begin
                            job_error        <= 1'b1;
                            axi_error_sticky <= 1'b1;
                        end
                        if (job_finalized &&
                            (job_beats_written == job_target_beats))
                            job_done_pulse <= 1'b1;
                        axi_state <= AXI_IDLE;
                    end
                end

                default: axi_state <= AXI_IDLE;
            endcase
        end
    end

endmodule
```
