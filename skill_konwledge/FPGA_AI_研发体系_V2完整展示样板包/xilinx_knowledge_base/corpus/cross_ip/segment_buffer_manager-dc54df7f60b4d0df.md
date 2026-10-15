# segment_buffer_manager

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\segment_buffer_manager.sv`
- SHA-256: `dc54df7f60b4d0df00b7cf52131a2fa9a5a35906e48a8fe6bb7b496bfab06208`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\segment_buffer_manager.sv

```systemverilog
`timescale 1ns/1ps

// DDR分段所有权管理器。
//
// 本模块不搬运ADC数据，也不访问SSD；它只维护每个固定DDR分段的生命周期：
//   FREE -> FILLING -> READY -> INFLIGHT -> FREE
// DDR写入失败、NVMe完成失败、Tag不匹配或非法状态操作会把分段置为
// ERROR_HOLD，避免仍可能被DDR Writer或SSD使用的数据被再次覆盖。
//
// 分配采用“最低编号优先”。READY输出也采用“最低编号优先”，因此当前实现
// 提供确定性的扫描顺序，而不是基于时间戳或优先级的调度。
module segment_buffer_manager #(
    parameter integer AXI_ADDR_WIDTH = 64,    // DDR地址位宽，与Writer和NVMe DMA地址口一致
    parameter integer SEGMENT_BYTES  = 1024 * 1024,    // 单个固定DDR槽位大小，单位Byte
    parameter integer SEGMENT_COUNT  = 8,    // DDR Segment槽位总数
    parameter [AXI_ADDR_WIDTH-1:0] DDR_BASE_ADDR = {AXI_ADDR_WIDTH{1'b0}}    // Segment 0物理基地址
) (
    input  wire                         clk,    // Manager状态表所在系统时钟域
    input  wire                         rst_n,    // 低有效同步复位

    // Writer申请一个FREE分段。握手发生的同一拍，该分段即进入FILLING，
    // 不能等到整段写完后才占用，否则可能被第二次分配。
    input  wire                         alloc_valid,    // Writer申请一个FREE槽位
    output wire                         alloc_ready,    // 至少存在一个FREE槽位
    output wire [$clog2(SEGMENT_COUNT)-1:0] alloc_segment_id,    // 最低编号FREE槽位
    output wire [15:0]                  alloc_tag,    // 下一代{generation,segment_id}
    output wire [AXI_ADDR_WIDTH-1:0]    alloc_ddr_addr,    // 所分配槽位的DDR物理起始地址

    // Writer在最后一个DDR写响应完成后提交分段描述符。
    // payload_bytes是原始有效数据量，dma_bytes是补零后的4 KiB对齐传输量。
    input  wire                         fill_valid,    // Writer提交写完后的项目内描述符
    output wire                         fill_ready,    // Manager当前可检查并接收描述符
    input  wire [$clog2(SEGMENT_COUNT)-1:0] fill_segment_id,    // 描述符对应的DDR槽位编号
    input  wire [15:0]                  fill_tag,    // 分配时取得的代数Tag
    input  wire                         fill_error,    // DDR写响应或格式处理发生错误
    input  wire [63:0]                  fill_payload_bytes,    // ADC真实Payload字节数，不含补零
    input  wire [31:0]                  fill_dma_bytes,    // 4 KiB对齐后的DDR/NVMe传输字节数
    input  wire [63:0]                  fill_sequence,    // 本次Capture内的Segment顺序号
    input  wire [31:0]                  fill_crc32c,    // 真实Payload的CRC32C结果
    input  wire [63:0]                  fill_capture_id,    // 描述符所属Capture编号
    input  wire [63:0]                  fill_sample_count,    // 本段累计的数据时刻数
    input  wire                         fill_two_channel,    // 本段采用双通道格式
    input  wire                         fill_single_channel_select,    // 单通道格式所选通道
    input  wire                         fill_capture_last,    // 本段是Capture最后一个Payload Segment

    // 向NVMe调度器暴露一个READY分段。ready_accept表示请求已被后端接受，
    // 此时状态从READY转为INFLIGHT，但仍不能释放或覆盖DDR内容。
    output wire                         ready_valid,    // 至少存在一个READY描述符
    input  wire                         ready_accept,    // Scheduler已接收本描述符并提交其请求
    output wire [$clog2(SEGMENT_COUNT)-1:0] ready_segment_id,    // 最低编号READY槽位
    output wire [15:0]                  ready_tag,    // 当前READY槽位Tag
    output wire [AXI_ADDR_WIDTH-1:0]    ready_ddr_addr,    // 当前READY槽位DDR地址
    output wire [63:0]                  ready_payload_bytes,    // 当前READY真实Payload字节数
    output wire [31:0]                  ready_dma_bytes,    // 当前READY对齐DMA字节数
    output wire [63:0]                  ready_sequence,    // 当前READY Segment顺序号
    output wire [31:0]                  ready_crc32c,    // 当前READY Payload CRC32C
    output wire [63:0]                  ready_capture_id,    // 当前READY所属Capture编号
    output wire [63:0]                  ready_sample_count,    // 当前READY内的数据时刻数
    output wire                         ready_two_channel,    // 当前READY的单双通道格式
    output wire                         ready_single_channel_select,    // 当前READY的单通道选择
    output wire                         ready_capture_last,    // 当前READY是否为Capture尾段

    // NVMe完成通过应用层Tag寻找原分段。status=0才允许INFLIGHT回到FREE。
    input  wire                         completion_valid,    // Scheduler返回一个Payload完成
    input  wire [15:0]                  completion_tag,    // 完成所携带的应用层Tag
    input  wire [15:0]                  completion_status,    // 0=成功，非0=错误

    output wire [SEGMENT_COUNT*3-1:0]   segment_states,    // 每槽3 bit状态的展平诊断总线
    output reg  [$clog2(SEGMENT_COUNT+1)-1:0] free_count,    // 当前FREE槽位数量
    output reg                          state_error_sticky    // 状态/Tag错误粘滞位，复位前保持为1
);

    // 16位应用Tag由“代数 + segment_id”组成。分段每次重新分配时代数加一，
    // 可阻止复位、超时或异常恢复后的迟到Completion误释放新一代数据。
    localparam integer SEGMENT_ID_W = $clog2(SEGMENT_COUNT);    // segment_id占用的Tag低位宽度
    localparam integer GEN_W = 16 - SEGMENT_ID_W;    // 防迟到Completion的代数位宽

    // 三位状态同时通过segment_states导出，供仿真断言、ILA和软件诊断使用。
    localparam [2:0] SEG_FREE       = 3'd0;    // 无模块持有，可由Writer申请
    localparam [2:0] SEG_FILLING    = 3'd1;    // Writer持有，正在写DDR
    localparam [2:0] SEG_READY      = 3'd2;    // 数据与描述符完整，等待Scheduler
    localparam [2:0] SEG_INFLIGHT   = 3'd3;    // SSD请求在途，DDR内容禁止覆盖
    localparam [2:0] SEG_ERROR_HOLD = 3'd4;    // 错误隔离，复位前不再分配

    reg [2:0] state [0:SEGMENT_COUNT-1];    // 每个DDR槽位的所有权状态
    reg [GEN_W-1:0] generation [0:SEGMENT_COUNT-1];    // 每槽重分配代数

    // 描述符表与DDR Payload分离保存。表项只在FILLING成功结束时更新，
    // READY/INFLIGHT期间保持不变，供调度器提交和错误定位。
    reg [15:0] tag_table [0:SEGMENT_COUNT-1];    // 各槽当前代数Tag
    reg [63:0] payload_table [0:SEGMENT_COUNT-1];    // 各槽真实Payload字节数
    reg [31:0] dma_table [0:SEGMENT_COUNT-1];    // 各槽4 KiB对齐DMA字节数
    reg [63:0] sequence_table [0:SEGMENT_COUNT-1];    // 各槽Segment顺序号
    reg [31:0] crc_table [0:SEGMENT_COUNT-1];    // 各槽真实Payload CRC32C
    reg [63:0] capture_id_table [0:SEGMENT_COUNT-1];    // 各槽所属Capture编号
    reg [63:0] sample_count_table [0:SEGMENT_COUNT-1];    // 各槽数据时刻数
    reg two_channel_table [0:SEGMENT_COUNT-1];    // 各槽单双通道格式
    reg single_select_table [0:SEGMENT_COUNT-1];    // 各槽单通道选择
    reg capture_last_table [0:SEGMENT_COUNT-1];    // 各槽是否为Capture尾段

    reg [SEGMENT_ID_W-1:0] first_free;    // 组合扫描得到的最低编号FREE槽位
    reg [SEGMENT_ID_W-1:0] first_ready;    // 组合扫描得到的最低编号READY槽位
    reg free_found;    // FREE扫描命中标志
    reg ready_found;    // READY扫描命中标志
    reg completion_match_found;    // Completion Tag命中任一当前表项
    integer i;    // FREE/READY组合扫描循环变量
    integer k;    // Completion Tag组合扫描循环变量

    // 组合扫描同时完成三个任务：统计空闲数、选择首个FREE分段、
    // 选择首个READY分段。SEGMENT_COUNT较小时这种结构直观且便于验证。
    always @* begin
        first_free = {SEGMENT_ID_W{1'b0}};
        first_ready = {SEGMENT_ID_W{1'b0}};
        free_found = 1'b0;
        ready_found = 1'b0;
        free_count = 0;
        for (i = 0; i < SEGMENT_COUNT; i = i + 1) begin
            if (state[i] == SEG_FREE) begin
                free_count = free_count + 1'b1;
                if (!free_found) begin
                    first_free = i[SEGMENT_ID_W-1:0];
                    free_found = 1'b1;
                end
            end
            if ((state[i] == SEG_READY) && !ready_found) begin
                first_ready = i[SEGMENT_ID_W-1:0];
                ready_found = 1'b1;
            end
        end
    end

    // Completion的Tag必须命中当前表中的某一代分段。旧实现对完全未知的
    // Tag静默忽略，会使上层以为错误完成已经被处理；现在把它锁存为状态错。
    always @* begin
        completion_match_found = 1'b0;
        for (k = 0; k < SEGMENT_COUNT; k = k + 1)
            if (tag_table[k] == completion_tag)
                completion_match_found = 1'b1;
    end

    // alloc_tag使用“下一代”值，与时序块在分配握手时写回的generation一致。
    assign alloc_ready      = free_found;
    assign alloc_segment_id = first_free;
    assign alloc_tag        = {generation[first_free] + 1'b1, first_free};
    assign alloc_ddr_addr   = DDR_BASE_ADDR + (first_free * SEGMENT_BYTES);
    assign fill_ready       = 1'b1;

    // READY描述符始终来自first_ready指向的稳定表项。只有ready_accept握手
    // 才会改变该表项状态，因此后端反压期间这些输出必须保持不变。
    assign ready_valid                 = ready_found;
    assign ready_segment_id            = first_ready;
    assign ready_tag                   = tag_table[first_ready];
    assign ready_ddr_addr              = DDR_BASE_ADDR + (first_ready * SEGMENT_BYTES);
    assign ready_payload_bytes         = payload_table[first_ready];
    assign ready_dma_bytes             = dma_table[first_ready];
    assign ready_sequence              = sequence_table[first_ready];
    assign ready_crc32c                 = crc_table[first_ready];
    assign ready_capture_id            = capture_id_table[first_ready];
    assign ready_sample_count          = sample_count_table[first_ready];
    assign ready_two_channel           = two_channel_table[first_ready];
    assign ready_single_channel_select = single_select_table[first_ready];
    assign ready_capture_last          = capture_last_table[first_ready];

    // 将state数组展平，布局为segment_states[g*3 +: 3] = state[g]。
    // 该调试口不参与所有权决策。
    generate
        genvar g;    // Segment状态展平生成循环索引
        for (g = 0; g < SEGMENT_COUNT; g = g + 1) begin : g_state_export
            assign segment_states[g*3 +: 3] = state[g];
        end
    endgenerate

    // 这些是结构约束，不是运行时恢复逻辑。
    initial begin
        if (SEGMENT_COUNT < 2)
            $error("SEGMENT_COUNT must be at least 2");
        if (SEGMENT_ID_W >= 16)
            $error("SEGMENT_COUNT leaves no generation bits in the 16-bit tag");
        if ((SEGMENT_BYTES % 4096) != 0)
            $error("SEGMENT_BYTES must be 4 KiB aligned");
    end

    integer j;    // 状态表复位和Completion乱序匹配循环变量
    always @(posedge clk) begin
        if (!rst_n) begin
            // 复位后所有分段均可分配；代数清零，首次分配Tag使用generation=1。
            state_error_sticky <= 1'b0;
            for (j = 0; j < SEGMENT_COUNT; j = j + 1) begin
                state[j] <= SEG_FREE;
                generation[j] <= {GEN_W{1'b0}};
                tag_table[j] <= 16'd0;
                payload_table[j] <= 64'd0;
                dma_table[j] <= 32'd0;
                sequence_table[j] <= 64'd0;
                crc_table[j] <= 32'd0;
                capture_id_table[j] <= 64'd0;
                sample_count_table[j] <= 64'd0;
                two_channel_table[j] <= 1'b0;
                single_select_table[j] <= 1'b0;
                capture_last_table[j] <= 1'b0;
            end
        end else begin
            // 分配握手：抢占first_free并立即建立本代Tag。
            if (alloc_valid && alloc_ready) begin
                state[first_free] <= SEG_FILLING;
                generation[first_free] <= generation[first_free] + 1'b1;
                tag_table[first_free] <= alloc_tag;
            end

            // 写入完成：只有segment_id和Tag都匹配当前FILLING对象才接受。
            // fill_error直接进入ERROR_HOLD，防止部分写入的分段被送往SSD。
            if (fill_valid && fill_ready) begin
                if ((state[fill_segment_id] != SEG_FILLING) ||
                    (tag_table[fill_segment_id] != fill_tag)) begin
                    state_error_sticky <= 1'b1;
                    state[fill_segment_id] <= SEG_ERROR_HOLD;
                end else if (fill_error) begin
                    state[fill_segment_id] <= SEG_ERROR_HOLD;
                    state_error_sticky <= 1'b1;
                end else begin
                    state[fill_segment_id] <= SEG_READY;
                    payload_table[fill_segment_id] <= fill_payload_bytes;
                    dma_table[fill_segment_id] <= fill_dma_bytes;
                    sequence_table[fill_segment_id] <= fill_sequence;
                    crc_table[fill_segment_id] <= fill_crc32c;
                    capture_id_table[fill_segment_id] <= fill_capture_id;
                    sample_count_table[fill_segment_id] <= fill_sample_count;
                    two_channel_table[fill_segment_id] <= fill_two_channel;
                    single_select_table[fill_segment_id] <= fill_single_channel_select;
                    capture_last_table[fill_segment_id] <= fill_capture_last;
                end
            end

            // 提交握手：NVMe调度器已取得地址、长度和Tag，所有权转为INFLIGHT。
            if (ready_valid && ready_accept) begin
                if (state[first_ready] != SEG_READY) begin
                    state_error_sticky <= 1'b1;
                end else begin
                    state[first_ready] <= SEG_INFLIGHT;
                end
            end

            // 完成处理允许乱序扫描Tag。成功只释放仍处于INFLIGHT的同代分段；
            // 对READY/FILLING/FREE对象收到Completion均视为严重状态错误。
            if (completion_valid) begin
                if (!completion_match_found)
                    state_error_sticky <= 1'b1;
                for (j = 0; j < SEGMENT_COUNT; j = j + 1) begin
                    if (tag_table[j] == completion_tag) begin
                        if (state[j] != SEG_INFLIGHT) begin
                            state_error_sticky <= 1'b1;
                            state[j] <= SEG_ERROR_HOLD;
                        end else if (completion_status == 16'd0) begin
                            state[j] <= SEG_FREE;
                        end else begin
                            state[j] <= SEG_ERROR_HOLD;
                        end
                    end
                end
            end
        end
    end

endmodule
```
