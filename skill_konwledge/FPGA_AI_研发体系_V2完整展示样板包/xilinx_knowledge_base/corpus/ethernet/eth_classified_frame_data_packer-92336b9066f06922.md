# eth_classified_frame_data_packer

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream_AXI4-Full DMA Writer\Packet Stream_AXI4-Full DMA Writer\eth_classified_frame_data_packer.v`
- SHA-256: `92336b9066f069224946e668d9fd9b6cfc0f2b292d67e8176c72532e00d6eba2`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// =============================================================================
// 模块名称：eth_classified_frame_data_packer
// 功能说明：
//   1. 根据通道选择一个 8 位 FWFT FIFO，并严格读取 start_length 指定的字节数；
//   2. 将连续字节打包成 64 位 AXI4-Stream 数据，自动生成 TKEEP 和 TLAST；
//   3. 支持输出反压，在下游未就绪时保持当前 AXI 数据拍稳定。
//
// 层级关系与事务边界：
//   - 位于三个分类数据 FIFO 与 S2MM 控制器之间；一次 start 握手只服务一个已仲裁通道；
//   - start_channel/start_length 在启动时锁存，随后不再跟随输入变化；上游控制器保证长度非零；
//   - 每帧恰好读取 start_length 个 FIFO 字节，最后一个字节所在拍置 TLAST，最后一拍真正握手后
//     才撤销 active 并产生单周期 done_pulse。
//
// FWFT 读取规则：
//   当前周期满足“FIFO 非空且读使能有效”时，fifo_dout 会在同一上升沿被消费。
//   因此读使能采用组合逻辑产生，并在同一上升沿将当前字节写入打包缓冲区，
//   不额外增加延迟采样流水线，从而避免最后一个字节读完后多读一次。
//
// 字节排列：第 1 个字节放入 TDATA[7:0]，随后依次放入更高字节通道；不足 8 字节的末拍
// 使用从 bit0 起连续为 1 的 TKEEP 标出有效字节。所有寄存器在 clk 上升沿更新，rst 高有效。
// =============================================================================
module eth_classified_frame_data_packer (
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         abort,

    input  wire                         start_valid,
    output wire                         start_ready,
    input  wire [1:0]                   start_channel,
    input  wire [15:0]                  start_length,

    input  wire [7:0]                   goose_data_dout,
    input  wire                         goose_data_empty,
    output reg                          goose_data_rd_en,

    input  wire [7:0]                   sv_data_dout,
    input  wire                         sv_data_empty,
    output reg                          sv_data_rd_en,

    input  wire [7:0]                   other_data_dout,
    input  wire                         other_data_empty,
    output reg                          other_data_rd_en,

    output wire [63:0]                  m_axis_tdata,
    output wire [7:0]                   m_axis_tkeep,
    output wire                         m_axis_tlast,
    output wire                         m_axis_tvalid,
    input  wire                         m_axis_tready,

    output reg                          done_pulse,
    output wire                         active
);

    localparam [1:0] CH_NONE  = 2'd0;
    localparam [1:0] CH_GOOSE = 2'd1;
    localparam [1:0] CH_SV    = 2'd2;
    localparam [1:0] CH_OTHER = 2'd3;

    reg        active_r;
    reg [1:0]  channel_r;
    reg [15:0] bytes_left;

    // pack_buf/pack_count 保存尚未组成完整 AXI 拍的字节；axis_* 是一拍深的输出保持寄存器。
    reg [63:0] pack_buf;
    reg [2:0]  pack_count;

    reg [63:0] axis_data_r;
    reg [7:0]  axis_keep_r;
    reg        axis_last_r;
    reg        axis_valid_r;

    reg        selected_empty;
    reg [7:0]  selected_byte;

    assign active        = active_r;
    // 只有当前帧结束且输出寄存器中没有待握手数据时，才允许开始下一帧。
    assign start_ready   = (!active_r) && (!axis_valid_r);
    assign m_axis_tdata  = axis_data_r;
    assign m_axis_tkeep  = axis_keep_r;
    assign m_axis_tlast  = axis_last_r;
    assign m_axis_tvalid = axis_valid_r;

    // -------------------------------------------------------------------------
    // 根据当前通道选择对应 FWFT FIFO 的数据和空标志。
    // -------------------------------------------------------------------------
    always @(*) begin
        selected_empty = 1'b1;
        selected_byte  = 8'd0;
        case (channel_r)
            CH_GOOSE: begin
                selected_empty = goose_data_empty;
                selected_byte  = goose_data_dout;
            end
            CH_SV: begin
                selected_empty = sv_data_empty;
                selected_byte  = sv_data_dout;
            end
            CH_OTHER: begin
                selected_empty = other_data_empty;
                selected_byte  = other_data_dout;
            end
            default: begin
                selected_empty = 1'b1;
                selected_byte  = 8'd0;
            end
        endcase
    end

    // 辅助函数仅依赖显式输入参数，避免在函数内部隐藏对模块级信号的依赖。
    // 将本拍有效字节数转换为 AXI4-Stream TKEEP 低位连续掩码。
    function [7:0] keep_mask;
        input [3:0] byte_count;
        begin
            case (byte_count)
                4'd1: keep_mask = 8'h01;
                4'd2: keep_mask = 8'h03;
                4'd3: keep_mask = 8'h07;
                4'd4: keep_mask = 8'h0F;
                4'd5: keep_mask = 8'h1F;
                4'd6: keep_mask = 8'h3F;
                4'd7: keep_mask = 8'h7F;
                4'd8: keep_mask = 8'hFF;
                default: keep_mask = 8'h00;
            endcase
        end
    endfunction

    // 按到达顺序把一个 FIFO 字节插入 64 位数据拍的指定字节通道。
    function [63:0] pack_insert;
        input [63:0] pack_buf_i;
        input [2:0]  lane;
        input [7:0]  byte_in;
        begin
            pack_insert = pack_buf_i;
            case (lane)
                3'd0: pack_insert[7:0]    = byte_in;
                3'd1: pack_insert[15:8]   = byte_in;
                3'd2: pack_insert[23:16]  = byte_in;
                3'd3: pack_insert[31:24]  = byte_in;
                3'd4: pack_insert[39:32]  = byte_in;
                3'd5: pack_insert[47:40]  = byte_in;
                3'd6: pack_insert[55:48]  = byte_in;
                3'd7: pack_insert[63:56]  = byte_in;
                default: pack_insert      = pack_buf_i;
            endcase
        end
    endfunction

    wire [3:0]  pack_count_plus_one = {1'b0, pack_count} + 4'd1;
    wire        byte_is_last        = (bytes_left == 16'd1);
    wire        byte_emits_beat     = (pack_count == 3'd7) || byte_is_last;
    wire [63:0] pack_with_byte      = pack_insert(pack_buf, pack_count, selected_byte);

    // AXI 输出寄存器为空时可装载新数据；当前数据拍被接收的同一周期也允许直接装载下一拍。
    // 当 TREADY=0 且已有有效拍时 output_has_room=0，FIFO 读使能随之关闭，TDATA/TKEEP/TLAST
    // 均保持不变，从输入 FIFO 一直向上传递 DataMover 的反压。
    wire output_has_room = (!axis_valid_r) || m_axis_tready;

    // FWFT 字节消费条件：本周期可见的 selected_byte 会在同一上升沿随读使能一起被消费。
    wire consume_byte = active_r && (!abort) &&
                        (bytes_left != 16'd0) &&
                        (!selected_empty) && output_has_room;

    // -------------------------------------------------------------------------
    // FIFO 读使能选择。为满足 FWFT 时序语义，读使能采用组合逻辑产生。
    // -------------------------------------------------------------------------
    always @(*) begin
        goose_data_rd_en = 1'b0;
        sv_data_rd_en    = 1'b0;
        other_data_rd_en = 1'b0;

        if (consume_byte) begin
            case (channel_r)
                CH_GOOSE: goose_data_rd_en = 1'b1;
                CH_SV:    sv_data_rd_en    = 1'b1;
                CH_OTHER: other_data_rd_en = 1'b1;
                default:  ;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // 主时序逻辑：处理启动、字节打包、AXI 握手、结束脉冲以及中止恢复。
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            active_r     <= 1'b0;
            channel_r    <= CH_NONE;
            bytes_left   <= 16'd0;
            pack_buf     <= 64'd0;
            pack_count   <= 3'd0;
            axis_data_r  <= 64'd0;
            axis_keep_r  <= 8'd0;
            axis_last_r  <= 1'b0;
            axis_valid_r <= 1'b0;
            done_pulse   <= 1'b0;
        end else begin
            done_pulse <= 1'b0;

            if (abort) begin
                // abort 立即丢弃本模块内尚未发送的打包状态并撤销 AXI TVALID；不产生 done_pulse。
                active_r     <= 1'b0;
                channel_r    <= CH_NONE;
                bytes_left   <= 16'd0;
                pack_buf     <= 64'd0;
                pack_count   <= 3'd0;
                axis_data_r  <= 64'd0;
                axis_keep_r  <= 8'd0;
                axis_last_r  <= 1'b0;
                axis_valid_r <= 1'b0;
            end else begin
                // 当前 AXI 数据拍完成握手后释放输出寄存器；若为最后一拍则结束本帧。
                if (axis_valid_r && m_axis_tready) begin
                    axis_valid_r <= 1'b0;
                    axis_keep_r  <= 8'd0;

                    if (axis_last_r) begin
                        axis_last_r <= 1'b0;
                        active_r    <= 1'b0;
                        channel_r   <= CH_NONE;
                        done_pulse  <= 1'b1;
                    end else begin
                        axis_last_r <= 1'b0;
                    end
                end

                // 在读使能生效的同一上升沿消费当前 FWFT 字节并更新打包状态。
                if (consume_byte) begin
                    bytes_left <= bytes_left - 16'd1;

                    if (byte_emits_beat) begin
                        // 缓冲区装满或读到本帧最后一个字节时，形成一拍稳定的 AXI 输出。
                        axis_data_r  <= pack_with_byte;
                        axis_keep_r  <= keep_mask(pack_count_plus_one);
                        axis_last_r  <= byte_is_last;
                        axis_valid_r <= 1'b1;
                        pack_buf     <= 64'd0;
                        pack_count   <= 3'd0;
                    end else begin
                        pack_buf   <= pack_with_byte;
                        pack_count <= pack_count_plus_one[2:0];
                    end
                end

                // 仅在上一帧事务结束且 AXI 输出寄存器空闲时，才允许启动新的帧打包。
                if (start_valid && start_ready) begin
                    active_r     <= 1'b1;
                    channel_r    <= start_channel;
                    bytes_left   <= start_length;
                    pack_buf     <= 64'd0;
                    pack_count   <= 3'd0;
                    axis_data_r  <= 64'd0;
                    axis_keep_r  <= 8'd0;
                    axis_last_r  <= 1'b0;
                    axis_valid_r <= 1'b0;
                end
            end
        end
    end

endmodule
```
