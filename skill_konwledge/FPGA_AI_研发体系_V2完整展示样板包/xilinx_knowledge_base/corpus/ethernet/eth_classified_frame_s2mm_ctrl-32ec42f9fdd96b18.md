# eth_classified_frame_s2mm_ctrl

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream_AXI4-Full DMA Writer\Packet Stream_AXI4-Full DMA Writer\eth_classified_frame_s2mm_ctrl.v`
- SHA-256: `32ec42f9fdd96b184f4f996876588f449752f6cad75af94a779a5189cdba3bbf`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// =============================================================================
// 模块名称：eth_classified_frame_s2mm_ctrl
// 功能说明：
//   1. 接收仲裁后的报文信息，并申请对应通道的环形缓冲区槽位；
//   2. 控制数据打包模块读取报文数据；
//   3. 向 AXI DataMover 依次发送数据写命令、报文数据、描述符写命令和描述符；
//   4. 检查 DataMover 返回状态，成功时提交槽位，失败时中止槽位；
//   5. 错误发生后记录错误类型和次数，并自动恢复处理后续报文，不再停留在错误状态。
//
// 单帧事务顺序：
//   S_IDLE 接收描述符并同时申请槽位/启动 packer
//   -> S_SEND_DATA_CMD -> S_STREAM_DATA -> S_WAIT_DATA_STS
//   -> S_SEND_DESC_CMD -> S_STREAM_DESC -> S_WAIT_DESC_STS
//   -> S_COMMIT -> S_IDLE。
// 先确认帧数据写成功，再写 8 字节软件描述符，最后提交环写指针；因此描述符和写指针
// 都不会先于帧数据对软件可见。任一 DataMover 状态异常时转入 S_RECOVER，发出 abort 后
// 自动回到 S_IDLE。全部状态在 clk 上升沿更新，rst 高有效。
// =============================================================================

module eth_classified_frame_s2mm_ctrl #(
    parameter integer FRAME_SLOT_BYTES   = 1536,
    parameter integer DESC_BYTES         = 8,
    parameter [3:0]   TAG_DATA           = 4'h1,
    parameter [3:0]   TAG_DESC           = 4'h2,
    parameter         ENABLE_DRE_REALIGN = 1'b0
)(
    input  wire                         clk,
    input  wire                         rst,

    // 清除粘滞错误标志、错误码及各错误计数，不参与状态机恢复，也不会取消当前 DMA 事务。
    input  wire                         clear_error,

    // 仲裁后的报文信息接口。
    input  wire                         frame_valid,
    output wire                         frame_ready,
    input  wire [1:0]                   frame_channel,
    input  wire [1:0]                   frame_mac_class,
    input  wire [15:0]                  frame_len,
    input  wire [31:0]                  frame_timestamp,

    // 环形槽位申请、提交和中止接口。alloc 与合法帧接收同拍握手；commit/abort 均为事务结束动作。
    output wire                         ring_alloc_valid,
    input  wire                         ring_alloc_ready,
    output wire [1:0]                   ring_alloc_channel,
    input  wire [31:0]                  ring_alloc_data_addr,
    input  wire [31:0]                  ring_alloc_desc_addr,
    input  wire [31:0]                  ring_alloc_entry_index,
    output wire                         ring_commit_valid,
    output reg                          ring_abort_valid,

    // 数据打包模块控制及 64 位数据流接口；DataMover 的 TREADY 经本模块门控后向 packer 传递反压。
    output wire                         packer_start_valid,
    input  wire                         packer_start_ready,
    output wire [1:0]                   packer_start_channel,
    output wire [15:0]                  packer_start_length,
    output reg                          packer_abort,
    input  wire [63:0]                  packer_axis_tdata,
    input  wire [7:0]                   packer_axis_tkeep,
    input  wire                         packer_axis_tlast,
    input  wire                         packer_axis_tvalid,
    output wire                         packer_axis_tready,

    // 当前报文对应的 64 位输出描述符。
    input  wire [63:0]                  desc_payload,

    // 向 AXI DataMover 发送的 S2MM 写命令接口。
    output wire                         m_axis_s2mm_cmd_tvalid,
    input  wire                         m_axis_s2mm_cmd_tready,
    output wire [71:0]                  m_axis_s2mm_cmd_tdata,

    // 向 AXI DataMover 发送的报文数据或描述符数据接口，两类负载按状态机严格串行复用此接口。
    output wire                         s_axis_s2mm_tvalid,
    input  wire                         s_axis_s2mm_tready,
    output wire [63:0]                  s_axis_s2mm_tdata,
    output wire [7:0]                   s_axis_s2mm_tkeep,
    output wire                         s_axis_s2mm_tlast,

    // AXI DataMover 返回的 S2MM 写入状态接口。
    input  wire                         m_axis_s2mm_sts_tvalid,
    output wire                         m_axis_s2mm_sts_tready,
    input  wire [7:0]                   m_axis_s2mm_sts_tdata,
    input  wire [0:0]                   m_axis_s2mm_sts_tkeep,
    input  wire                         m_axis_s2mm_sts_tlast,

    // 运行状态与成功帧统计。
    output wire                         busy,
    output reg                          frame_done_pulse,

    // 其他类型帧完成中断接口：其他类型帧成功提交后置位请求，收到 ACK 后清零。
    input  wire                         data_irq_ack,
    output reg                          data_irq_req,
    output reg [31:0]                   frame_count,
    output reg [31:0]                   last_data_addr,
    output reg [31:0]                   last_desc_addr,
    output reg [1:0]                    current_channel,
    output wire [1:0]                   active_mac_class,
    output wire [15:0]                  active_frame_len,
    output wire [31:0]                  active_timestamp,

    // 错误状态与错误统计。
    // error 为粘滞错误标志，发生过错误后保持为 1，clear_error 时清零；
    // error_pulse 在每次检测到错误时仅保持一个时钟周期。
    output reg                          error,
    output reg                          error_pulse,
    output reg [7:0]                    error_code,
    output reg [31:0]                   error_count,
    output reg [31:0]                   param_error_count,
    output reg [31:0]                   tag_mismatch_count,
    output reg [31:0]                   data_status_error_count,
    output reg [31:0]                   desc_status_error_count
);

    // -------------------------------------------------------------------------
    // 通道编码
    // -------------------------------------------------------------------------
    localparam [1:0] CH_NONE  = 2'd0;
    localparam [1:0] CH_OTHER = 2'd3;

    // -------------------------------------------------------------------------
    // 主状态机编码
    // -------------------------------------------------------------------------
    localparam [3:0] S_IDLE          = 4'd0;
    localparam [3:0] S_SEND_DATA_CMD = 4'd1;
    localparam [3:0] S_STREAM_DATA   = 4'd2;
    localparam [3:0] S_WAIT_DATA_STS = 4'd3;
    localparam [3:0] S_SEND_DESC_CMD = 4'd4;
    localparam [3:0] S_STREAM_DESC   = 4'd5;
    localparam [3:0] S_WAIT_DESC_STS = 4'd6;
    localparam [3:0] S_COMMIT        = 4'd7;
    localparam [3:0] S_RECOVER       = 4'd8;

    // -------------------------------------------------------------------------
    // 错误码定义
    // -------------------------------------------------------------------------
    localparam [7:0] ERR_NONE            = 8'h00;
    localparam [7:0] ERR_ZERO_LENGTH     = 8'h01;
    localparam [7:0] ERR_FRAME_TOO_LARGE = 8'h02;
    localparam [7:0] ERR_DESC_CONFIG     = 8'h03;
    localparam [7:0] ERR_TAG_MISMATCH    = 8'h10;
    localparam [7:0] ERR_DATA_STS        = 8'h11;
    localparam [7:0] ERR_DESC_STS        = 8'h12;
    localparam [7:0] ERR_ILLEGAL_STATE   = 8'h13;

    localparam [31:0] FRAME_SLOT_BYTES_U32 = FRAME_SLOT_BYTES;
    localparam [31:0] DESC_BYTES_U32       = DESC_BYTES;

    // -------------------------------------------------------------------------
    // 当前帧上下文及槽位占用状态。
    // frame_* 只在 frame_accept 时采样；后续命令、描述符和状态统计均使用这些锁存值，
    // 避免上游仲裁结果在 DMA 事务进行期间变化影响当前帧。
    // -------------------------------------------------------------------------
    reg [3:0]  state;
    reg [1:0]  mac_class_r;
    reg [15:0] frame_len_r;
    reg [31:0] timestamp_r;
    reg [31:0] data_addr_r;
    reg [31:0] desc_addr_r;
    reg [31:0] entry_index_r;
    reg        slot_allocated;

    // -------------------------------------------------------------------------
    // 报文参数检查。
    // DataMover BTT 字段为 23 位；帧长度还必须能装入固定槽位，输出描述符长度固定要求为 8 字节。
    // -------------------------------------------------------------------------
    wire [31:0] frame_len_u32 = {16'd0, frame_len};

    wire frame_too_large =
        (FRAME_SLOT_BYTES_U32 == 32'd0) ||
        (frame_len_u32 > FRAME_SLOT_BYTES_U32) ||
        (frame_len_u32 > 32'd8388607);

    wire desc_config_bad =
        (DESC_BYTES_U32 != 32'd8) ||
        (DESC_BYTES_U32 > 32'd8388607);

    wire frame_params_ok =
        (frame_len != 16'd0) &&
        (!frame_too_large) &&
        (!desc_config_bad);

    // 合法报文只有在环形槽位和数据打包模块均就绪时才接收。
    // 参数非法的描述符可以直接被接收并计数；此时不申请槽位，也不启动 packer。
    assign frame_ready =
        (state == S_IDLE) &&
        ((!frame_params_ok) ||
         (ring_alloc_ready && packer_start_ready));

    wire frame_accept = frame_valid && frame_ready;
    wire start_frame  = frame_accept && frame_params_ok;

    // 合法报文在同一拍申请环形槽位并启动数据打包模块；frame_ready 的条件保证二者同时接受。
    assign ring_alloc_valid     = start_frame;
    assign ring_alloc_channel   = frame_channel;
    assign ring_commit_valid    = (state == S_COMMIT);

    assign packer_start_valid   = start_frame;
    assign packer_start_channel = frame_channel;
    assign packer_start_length  = frame_len;

    // 状态输出。
    assign busy             = (state != S_IDLE);
    assign active_mac_class = mac_class_r;
    assign active_frame_len = frame_len_r;
    assign active_timestamp = timestamp_r;

    // 其他类型帧进入 S_COMMIT 状态表示数据和描述符均已成功写入，并准备提交环形缓冲区写指针。
    // GOOSE/SV 的成功提交只产生通用 frame_done_pulse，不置位 data_irq_req。
    wire other_frame_done =
        (state == S_COMMIT) &&
        (current_channel == CH_OTHER);

    // -------------------------------------------------------------------------
    // DataMover S2MM 命令生成。
    // 72 位命令包含写地址、TAG、BTT、地址递增、EOF 和可选 DRE 重对齐请求；数据命令使用
    // TAG_DATA/帧长度，描述符命令使用 TAG_DESC/DESC_BYTES，便于返回状态与当前阶段对应。
    // -------------------------------------------------------------------------
    function [71:0] make_cmd;
        input [31:0] addr;
        input [3:0]  tag;
        input [22:0] btt;
        begin
            make_cmd = {
                4'd0,                                      // 保留位
                tag,                                       // 事务标识
                addr,                                      // 写起始地址
                (ENABLE_DRE_REALIGN ? 1'b1 : 1'b0),       // 重新对齐请求
                1'b1,                                      // 完整数据包结束标志
                6'd0,                                      // 对齐字段
                1'b1,                                      // 地址递增
                btt                                        // 传输字节数
            };
        end
    endfunction

    // 命令数据来自锁存后的帧上下文，在等待就绪期间保持稳定。
    assign m_axis_s2mm_cmd_tvalid =
        (state == S_SEND_DATA_CMD) ||
        (state == S_SEND_DESC_CMD);

    assign m_axis_s2mm_cmd_tdata =
        (state == S_SEND_DESC_CMD) ?
        make_cmd(
            desc_addr_r,
            TAG_DESC,
            DESC_BYTES_U32[22:0]
        ) :
        make_cmd(
            data_addr_r,
            TAG_DATA,
            {7'd0, frame_len_r}
        );

    // -------------------------------------------------------------------------
    // DataMover 数据流选择。
    // 数据阶段透明转发 packer 的 TVALID/TDATA/TKEEP/TLAST；描述符阶段固定发送一拍 64 位数据，
    // TKEEP=8'hFF 且 TLAST=1。只有 TVALID 与 TREADY 同时为 1 才推进状态。
    // -------------------------------------------------------------------------
    assign s_axis_s2mm_tvalid =
        (state == S_STREAM_DATA) ? packer_axis_tvalid :
        (state == S_STREAM_DESC) ? 1'b1 :
                                   1'b0;

    assign s_axis_s2mm_tdata =
        (state == S_STREAM_DESC) ? desc_payload :
                                   packer_axis_tdata;

    assign s_axis_s2mm_tkeep =
        (state == S_STREAM_DESC) ? 8'hFF :
                                   packer_axis_tkeep;

    assign s_axis_s2mm_tlast =
        (state == S_STREAM_DESC) ? 1'b1 :
                                   packer_axis_tlast;

    assign packer_axis_tready =
        (state == S_STREAM_DATA) &&
        s_axis_s2mm_tready;

    // -------------------------------------------------------------------------
    // DataMover 状态接收与检查。
    // 只在两个等待状态拉高 TREADY；状态字 bit7 表示完成，bit[6:4] 任一置位表示错误，
    // bit[3:0] 必须匹配当前命令 TAG，错误状态或错序 TAG 都不会进入后续提交阶段。
    // -------------------------------------------------------------------------
    assign m_axis_s2mm_sts_tready =
        (state == S_WAIT_DATA_STS) ||
        (state == S_WAIT_DESC_STS);

    wire status_handshake =
        m_axis_s2mm_sts_tvalid &&
        m_axis_s2mm_sts_tready;

    wire status_complete  = m_axis_s2mm_sts_tdata[7];
    wire status_has_error = |m_axis_s2mm_sts_tdata[6:4];
    wire status_ok        = status_complete && (!status_has_error);

    wire data_tag_match =
        (m_axis_s2mm_sts_tdata[3:0] == TAG_DATA);

    wire desc_tag_match =
        (m_axis_s2mm_sts_tdata[3:0] == TAG_DESC);

    // 当前未参与功能判断的输入统一接入，避免综合工具产生未使用告警。
    wire unused_ctrl_inputs =
        ring_alloc_entry_index[0] ^
        m_axis_s2mm_sts_tkeep[0] ^
        m_axis_s2mm_sts_tlast ^
        entry_index_r[0];

    // -------------------------------------------------------------------------
    // 32 位饱和计数函数
    // -------------------------------------------------------------------------
    function [31:0] count_inc_sat;
        input [31:0] value;
        begin
            if (value == 32'hFFFF_FFFF)
                count_inc_sat = value;
            else
                count_inc_sat = value + 32'd1;
        end
    endfunction

    // -------------------------------------------------------------------------
    // 其他类型帧完成中断请求。
    //   - 其他类型帧在 S_COMMIT 时置 1；
    //   - 外部 data_irq_ack 置 1 后清 0；
    //   - 若新帧完成与 ACK 同拍到达，新中断优先，避免丢失请求。
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            data_irq_req <= 1'b0;
        end else begin
            if (other_frame_done)
                data_irq_req <= 1'b1;
            else if (data_irq_ack)
                data_irq_req <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // 主状态机
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state                   <= S_IDLE;
            mac_class_r             <= 2'b00;
            frame_len_r             <= 16'd0;
            timestamp_r             <= 32'd0;
            data_addr_r             <= 32'd0;
            desc_addr_r             <= 32'd0;
            entry_index_r           <= 32'd0;
            slot_allocated          <= 1'b0;

            ring_abort_valid        <= 1'b0;
            packer_abort            <= 1'b0;
            frame_done_pulse        <= 1'b0;

            frame_count             <= 32'd0;
            last_data_addr          <= 32'd0;
            last_desc_addr          <= 32'd0;
            current_channel         <= CH_NONE;

            error                   <= 1'b0;
            error_pulse             <= 1'b0;
            error_code              <= ERR_NONE;
            error_count             <= 32'd0;
            param_error_count       <= 32'd0;
            tag_mismatch_count      <= 32'd0;
            data_status_error_count <= 32'd0;
            desc_status_error_count <= 32'd0;
        end else begin
            // 单周期脉冲信号默认清零。
            ring_abort_valid <= 1'b0;
            packer_abort     <= 1'b0;
            frame_done_pulse <= 1'b0;
            error_pulse      <= 1'b0;

            // clear_error 仅清除错误记录，不影响当前事务和状态机运行。
            if (clear_error) begin
                error                   <= 1'b0;
                error_code              <= ERR_NONE;
                error_count             <= 32'd0;
                param_error_count       <= 32'd0;
                tag_mismatch_count      <= 32'd0;
                data_status_error_count <= 32'd0;
                desc_status_error_count <= 32'd0;
            end

            case (state)
                // 空闲状态：接收帧信息，合法帧进入写入流程；
                // 非法帧只记录错误并停留在空闲态，下一周期即可继续接收后续描述符。
                S_IDLE: begin
                    current_channel <= CH_NONE;

                    if (frame_accept) begin
                        mac_class_r    <= frame_mac_class;
                        frame_len_r    <= frame_len;
                        timestamp_r    <= frame_timestamp;
                        data_addr_r    <= ring_alloc_data_addr;
                        desc_addr_r    <= ring_alloc_desc_addr;
                        entry_index_r  <= ring_alloc_entry_index;
                        last_data_addr <= ring_alloc_data_addr;
                        last_desc_addr <= ring_alloc_desc_addr;

                        if (frame_len == 16'd0) begin
                            error             <= 1'b1;
                            error_pulse       <= 1'b1;
                            error_code        <= ERR_ZERO_LENGTH;
                            error_count       <= count_inc_sat(error_count);
                            param_error_count <= count_inc_sat(param_error_count);
                        end else if (frame_too_large) begin
                            error             <= 1'b1;
                            error_pulse       <= 1'b1;
                            error_code        <= ERR_FRAME_TOO_LARGE;
                            error_count       <= count_inc_sat(error_count);
                            param_error_count <= count_inc_sat(param_error_count);
                        end else if (desc_config_bad) begin
                            error             <= 1'b1;
                            error_pulse       <= 1'b1;
                            error_code        <= ERR_DESC_CONFIG;
                            error_count       <= count_inc_sat(error_count);
                            param_error_count <= count_inc_sat(param_error_count);
                        end else begin
                            current_channel <= frame_channel;
                            slot_allocated  <= 1'b1;
                            state           <= S_SEND_DATA_CMD;
                        end
                    end
                end

                // 发送报文数据写命令；若 DataMover 反压，命令地址、TAG 和 BTT 保持稳定。
                S_SEND_DATA_CMD: begin
                    if (m_axis_s2mm_cmd_tvalid &&
                        m_axis_s2mm_cmd_tready)
                        state <= S_STREAM_DATA;
                end

                // 转发打包后的报文数据；只在带 TLAST 的最后一拍完成握手后等待写状态。
                S_STREAM_DATA: begin
                    if (s_axis_s2mm_tvalid &&
                        s_axis_s2mm_tready &&
                        s_axis_s2mm_tlast)
                        state <= S_WAIT_DATA_STS;
                end

                // 检查报文数据写入状态；成功才允许发送描述符，失败则中止预留槽位。
                S_WAIT_DATA_STS: begin
                    if (status_handshake) begin
                        if (!data_tag_match) begin
                            error              <= 1'b1;
                            error_pulse        <= 1'b1;
                            error_code         <= ERR_TAG_MISMATCH;
                            error_count        <= count_inc_sat(error_count);
                            tag_mismatch_count <= count_inc_sat(tag_mismatch_count);

                            ring_abort_valid <= slot_allocated;
                            packer_abort     <= 1'b1;
                            slot_allocated   <= 1'b0;
                            current_channel  <= CH_NONE;
                            state            <= S_RECOVER;
                        end else if (!status_ok) begin
                            error                   <= 1'b1;
                            error_pulse             <= 1'b1;
                            error_code              <= ERR_DATA_STS;
                            error_count             <= count_inc_sat(error_count);
                            data_status_error_count <= count_inc_sat(data_status_error_count);

                            ring_abort_valid <= slot_allocated;
                            packer_abort     <= 1'b1;
                            slot_allocated   <= 1'b0;
                            current_channel  <= CH_NONE;
                            state            <= S_RECOVER;
                        end else begin
                            state <= S_SEND_DESC_CMD;
                        end
                    end
                end

                // 发送描述符写命令；地址来自同一预留槽位的独立描述符区。
                S_SEND_DESC_CMD: begin
                    if (m_axis_s2mm_cmd_tvalid &&
                        m_axis_s2mm_cmd_tready)
                        state <= S_STREAM_DESC;
                end

                // 发送单拍 64 位描述符。
                S_STREAM_DESC: begin
                    if (s_axis_s2mm_tvalid &&
                        s_axis_s2mm_tready)
                        state <= S_WAIT_DESC_STS;
                end

                // 检查描述符写入状态；只有 TAG 和完成/错误位均正确才进入 S_COMMIT。
                S_WAIT_DESC_STS: begin
                    if (status_handshake) begin
                        if (!desc_tag_match) begin
                            error              <= 1'b1;
                            error_pulse        <= 1'b1;
                            error_code         <= ERR_TAG_MISMATCH;
                            error_count        <= count_inc_sat(error_count);
                            tag_mismatch_count <= count_inc_sat(tag_mismatch_count);

                            ring_abort_valid <= slot_allocated;
                            packer_abort     <= 1'b1;
                            slot_allocated   <= 1'b0;
                            current_channel  <= CH_NONE;
                            state            <= S_RECOVER;
                        end else if (!status_ok) begin
                            error                   <= 1'b1;
                            error_pulse             <= 1'b1;
                            error_code              <= ERR_DESC_STS;
                            error_count             <= count_inc_sat(error_count);
                            desc_status_error_count <= count_inc_sat(desc_status_error_count);

                            ring_abort_valid <= slot_allocated;
                            packer_abort     <= 1'b1;
                            slot_allocated   <= 1'b0;
                            current_channel  <= CH_NONE;
                            state            <= S_RECOVER;
                        end else begin
                            state <= S_COMMIT;
                        end
                    end
                end

                // 数据和描述符均成功后提交槽位并统计成功帧。
                // ring_commit_valid 在整个 S_COMMIT 周期为高，环管理器在该周期末推进对应写指针；
                // frame_done_pulse 同时产生，Other 通道的保持型中断请求也在该提交周期置位。
                S_COMMIT: begin
                    slot_allocated   <= 1'b0;
                    frame_count      <= count_inc_sat(frame_count);
                    frame_done_pulse <= 1'b1;
                    current_channel  <= CH_NONE;
                    state            <= S_IDLE;
                end

                // 自动恢复状态：错误检测周期产生的 packer_abort/ring_abort_valid 在本周期被下游采样，
                // 本状态不等待 clear_error，下一拍自动返回空闲；粘滞 error 和计数仍保留供软件读取。
                S_RECOVER: begin
                    current_channel <= CH_NONE;
                    state           <= S_IDLE;
                end

                // 非法状态：记录错误、中止残留槽位并自动恢复。
                default: begin
                    error       <= 1'b1;
                    error_pulse <= 1'b1;
                    error_code  <= ERR_ILLEGAL_STATE;
                    error_count <= count_inc_sat(error_count);

                    ring_abort_valid <= slot_allocated;
                    packer_abort     <= 1'b1;
                    slot_allocated   <= 1'b0;
                    current_channel  <= CH_NONE;
                    state            <= S_RECOVER;
                end
            endcase
        end
    end

endmodule
```
