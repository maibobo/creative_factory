// 修改点 2026-10-13：无子机时，由VIO上升沿触发两个固定32bit字。
// 本模块使用250MHz业务时钟；控制先寄存，数据和有效信号均由寄存器输出。
// 等原writer周期结束后再发送，保证两个字落在同一周期；反压时保持当前数据。
// 两拍输入接受后继续等待真实块登记，不把输入接受当成DDR写成功。
// 中途失去DDR/PCIe就绪或写失败时停止并保持fault，需全局复位后重试。
`timescale 1ns/1ps
module RTDS_RX_VIO_STIM (
    input  wire        clk,                    // 250MHz业务时钟
    input  wire        rst_n,                  // 全局低有效复位
    input  wire        start,                  // VIO输出，0到1触发一次
    input  wire        store_ready,            // 原DDR与PCIe允许存储条件
    input  wire [31:0] ready_blocks,           // 原writer已完成块数
    input  wire        period_tick,            // 原writer周期到期事件
    input  wire        block_committed,        // 原writer成功非空块登记事件
    input  wire        write_error,            // 最终写响应失败事件
    input  wire        frame_ready,            // 原writer输入接受条件
    output reg  [63:0] frame_data,             // 低32bit依次为11、22
    output reg         frame_valid,            // 当前数据有效，反压期间保持
    output wire        busy,                   // 包含等待周期、发送和等块完成
    output reg  [1:0]  accepted_words,         // 本次已接受输入字数，0到2
    output reg         fault                   // 中途失败保持到全局复位
);
    localparam [2:0] IDLE       = 3'd0;    // 等待新触发
    localparam [2:0] WAIT_TICK  = 3'd1;    // 等当前周期结束
    localparam [2:0] SEND_FIRST = 3'd2;    // 等第一个字被接受
    localparam [2:0] SEND_LAST  = 3'd3;    // 等第二个字被接受
    localparam [2:0] WAIT_BLOCK = 3'd4;    // 等真实块登记
    reg [2:0] state;                     // 发生器当前步骤
    reg       start_r;                   // VIO控制寄存副本
    reg       start_d;                   // 上一拍控制副本
    reg       tick_r;                    // 周期事件寄存副本
    reg       committed_r;               // 块登记事件寄存副本
    reg       can_start_r;               // 就绪且有空块的寄存判定
    wire      start_edge;                // 同域控制的0到1事件
    assign start_edge = start_r && !start_d;    // 保持1不重复触发
    assign busy = state != IDLE;                // 真实块登记前保持忙

    // 先寄存VIO控制和观察事件，避免从JTAG控制到数据输出形成组合长路径。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_r <= 1'b0;
            start_d <= 1'b0;
            tick_r <= 1'b0;
            committed_r <= 1'b0;
            can_start_r <= 1'b0;
        end else begin
            start_r <= start;
            start_d <= start_r;
            tick_r <= period_tick;
            committed_r <= block_committed;
            can_start_r <= store_ready && ready_blocks < 32'd8;
        end
    end

    // 仅空闲时接受触发；发送拍只在valid与ready同时成立时前进。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            frame_data <= 64'd0;
            frame_valid <= 1'b0;
            accepted_words <= 2'd0;
            fault <= 1'b0;
        end else if (busy && (!store_ready || write_error)) begin
            state <= IDLE;
            frame_valid <= 1'b0;
            fault <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    frame_valid <= 1'b0;
                    if (start_edge && can_start_r && store_ready && !fault) begin
                        accepted_words <= 2'd0;
                        frame_data <= 64'h00000000_00000011;
                        state <= WAIT_TICK;
                    end
                end
                WAIT_TICK: if (tick_r) begin
                    frame_valid <= 1'b1;
                    state <= SEND_FIRST;
                end
                SEND_FIRST: if (frame_valid && frame_ready) begin
                    accepted_words <= 2'd1;
                    frame_data <= 64'h00000000_00000022;
                    state <= SEND_LAST;
                end
                SEND_LAST: if (frame_valid && frame_ready) begin
                    accepted_words <= 2'd2;
                    frame_valid <= 1'b0;
                    state <= WAIT_BLOCK;
                end
                WAIT_BLOCK: if (committed_r) state <= IDLE;
                default: begin
                    state <= IDLE;
                    frame_valid <= 1'b0;
                    fault <= 1'b1;
                end
            endcase
        end
    end
endmodule
