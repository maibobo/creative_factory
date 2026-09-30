`timescale 1ns / 1ps
// File: fdma_hw_test_engine.v

// 有界、可综合的 FDMA 从机和硬件端到端数据检查器。
// fdma_hw_test_engine 模块入口；硬件自测引擎：在板上模拟 FDMA 读写从机，生成确定性数据并检查环回写回是否一致。
module fdma_hw_test_engine #(
    // 定义单帧传输的字节数，512B 正好对应一个 64 个 64bit 字的 FDMA 突发。
    parameter integer FRAME_BYTES = 512,
    // 固定 BURST_BYTES 的传输规模，保证读写两侧按同一长度收尾。
    parameter integer BURST_BYTES = 512,
    // 设置 AUTO_START_DELAY_CYCLES 的等待周期上限，防止异常场景下仿真无限挂起。
    parameter integer AUTO_START_DELAY_CYCLES = 1250000000,
    // 设置 DRAIN_TIMEOUT_CYCLES 的等待周期上限，防止异常场景下仿真无限挂起。
    parameter integer DRAIN_TIMEOUT_CYCLES = 1000000
)(
    input  wire         fdma_clk,
    input  wire         fdma_rstn,
    input  wire         channel_up,
    input  wire         test_start,
    input  wire         test_clear,
    input  wire         auto_enable,
    input  wire [15:0]  frame_limit,

    input  wire [31:0]  fdma_raddr,
    input  wire         fdma_rareq,
    output reg          fdma_rbusy,
    output reg  [63:0]  fdma_rdata,
    output reg          fdma_rvalid,
    input  wire         fdma_rready,

    input  wire [31:0]  fdma_waddr,
    input  wire         fdma_wareq,
    output reg          fdma_wbusy,
    input  wire [63:0]  fdma_wdata,
    input  wire         fdma_wvalid,
    input  wire [15:0]  fdma_wsize,
    output reg          fdma_wready,

    output wire [256:0] dbg_bus,
    output wire [187:0] status_dbg_bus
);

    // 把单帧字节数换算成 64bit 字数量，供突发长度、SOF/EOF 和地址推进使用。
    localparam integer FRAME_WORDS = FRAME_BYTES / 8;
    // 固定单次 FDMA 突发包含的 64bit 字数，和 512B 帧长度保持一致。
    localparam integer BURST_WORDS = BURST_BYTES / 8;
    // FDMA 读状态机空闲编码。
    localparam [1:0] RD_IDLE = 2'd0, RD_ACCEPT = 2'd1,
                     RD_SEND = 2'd2, RD_FINISH = 2'd3;
    // FDMA 写状态机空闲编码。
    localparam [1:0] WR_IDLE = 2'd0, WR_ACCEPT = 2'd1,
                     WR_RECV = 2'd2, WR_FINISH = 2'd3;
    // 硬件自测结果状态的空闲编码。
    localparam [2:0] RESULT_IDLE = 3'd0, RESULT_RUNNING = 3'd1,
                     RESULT_PASS = 3'd2, RESULT_MISMATCH = 3'd3,
                     RESULT_TIMEOUT = 3'd4, RESULT_LINK_DOWN = 3'd5;
    // 首错分类：未发现错误。
    localparam [1:0] ERR_NONE = 2'd0, ERR_SKIPPED_WORD = 2'd1,
                     ERR_DUPLICATED_WORD = 2'd2, ERR_OTHER = 2'd3;

    reg [1:0] rd_state, wr_state;
    reg [31:0] source_frame_cnt, source_word_in_frame;
    reg [15:0] rd_word_in_burst;
    reg [31:0] expected_frame_cnt, expected_word_in_frame;
    reg [12:0] wr_word_in_burst, wr_words_expected;

    reg [31:0] hw_rd_word_total, hw_wr_word_total;
    reg [15:0] hw_rd_burst_count, hw_wr_burst_count;
    reg [31:0] hw_error_count;
    reg        hw_error_sticky;
    reg [63:0] hw_first_error_expected, hw_first_error_actual;

    reg        test_running, test_done, test_pass;
    reg [2:0]  result_code;
    reg [15:0] target_frames;
    reg        timeout_sticky, link_down_sticky;
    reg [31:0] first_error_index;
    reg [1:0]  first_error_class;
    reg [63:0] last_good_data, first_error_expected_next;
    reg        first_error_pulse;
    reg [7:0]  start_pulse_stretch;

    reg start_d, clear_d;
    (* ASYNC_REG = "TRUE" *) reg [1:0] channel_sync;
    reg [31:0] auto_delay_count, drain_timeout_count;
    reg auto_consumed, rd_source_done;
    reg wr_all_received_pulse;

    wire manual_start_edge = test_start && !start_d;
    wire clear_edge = test_clear && !clear_d;
    wire channel_up_fdma = channel_sync[1];
    wire auto_fire = !test_running && !test_done && !auto_consumed &&
                     auto_enable && channel_up_fdma &&
                     (auto_delay_count >= AUTO_START_DELAY_CYCLES-1);
    wire accepted_start = !test_running &&
                          (manual_start_edge || auto_fire) && channel_up_fdma;
    wire [63:0] expected_data = {expected_frame_cnt, expected_word_in_frame};
    wire [63:0] expected_next_data =
        (expected_word_in_frame == FRAME_WORDS-1) ?
        {expected_frame_cnt + 1'b1, 32'd0} :
        {expected_frame_cnt, expected_word_in_frame + 1'b1};
    wire read_hs  = fdma_rvalid && fdma_rready;
    wire write_hs = fdma_wvalid && fdma_wready;

    // 地址保持可观测，但不会按真实存储器解码。
    wire unused_addr = ^{fdma_raddr, fdma_waddr};

    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign dbg_bus = {hw_rd_word_total, hw_wr_word_total,
                      hw_rd_burst_count, hw_wr_burst_count,
                      hw_error_count, hw_error_sticky,
                      hw_first_error_expected, hw_first_error_actual};
    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign status_dbg_bus = {
        test_running,                 // [187]
        test_done,                    // [186]
        test_pass,                    // [185]
        result_code,                  // [184:182]
        target_frames,                // [181:166]
        |start_pulse_stretch,         // [165]
        first_error_pulse,            // [164]
        first_error_index,            // [163:132]
        first_error_class,            // [131:130]
        last_good_data,               // [129:66]
        first_error_expected_next,    // [65:2]
        timeout_sticky,               // [1]
        link_down_sticky              // [0]
    };

    // 运行控制和持久结果状态。
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!fdma_rstn) begin
            channel_sync <= 2'b00;
            start_d <= 1'b0;
            clear_d <= 1'b0;
            test_running <= 1'b0;
            test_done <= 1'b0;
            test_pass <= 1'b0;
            result_code <= RESULT_IDLE;
            target_frames <= 16'd16;
            timeout_sticky <= 1'b0;
            link_down_sticky <= 1'b0;
            auto_delay_count <= 32'd0;
            drain_timeout_count <= 32'd0;
            auto_consumed <= 1'b0;
            start_pulse_stretch <= 8'd0;
        end else begin
            channel_sync <= {channel_sync[0], channel_up};
            start_d <= test_start;
            clear_d <= test_clear;
            // 启动脉冲展宽计数未归零时逐拍递减。
            if (start_pulse_stretch != 0)
                start_pulse_stretch <= start_pulse_stretch - 1'b1;

            // 清除控制出现上升沿时复位硬件测试状态和统计寄存器。
            if (clear_edge) begin
                test_running <= 1'b0;
                test_done <= 1'b0;
                test_pass <= 1'b0;
                result_code <= RESULT_IDLE;
                timeout_sticky <= 1'b0;
                link_down_sticky <= 1'b0;
                auto_delay_count <= 32'd0;
                drain_timeout_count <= 32'd0;
                auto_consumed <= 1'b0;
                start_pulse_stretch <= 8'd0;
            end else if (accepted_start) begin
                test_running <= 1'b1;
                test_done <= 1'b0;
                test_pass <= 1'b0;
                result_code <= RESULT_RUNNING;
                target_frames <= (frame_limit == 0) ? 16'd1 : frame_limit;
                timeout_sticky <= 1'b0;
                link_down_sticky <= 1'b0;
                auto_delay_count <= 32'd0;
                drain_timeout_count <= 32'd0;
                auto_consumed <= 1'b1;
                start_pulse_stretch <= 8'hff;
            end else begin
                // 当前路径按相邻控制信号更新寄存器。
                if (!test_running && !test_done && !auto_consumed &&
                    auto_enable && channel_up_fdma) begin
                    // 自动启动延迟尚未到期时继续累加等待计数。
                    if (auto_delay_count < AUTO_START_DELAY_CYCLES-1)
                        auto_delay_count <= auto_delay_count + 1'b1;
                end else if (!auto_enable || !channel_up_fdma) begin
                    auto_delay_count <= 32'd0;
                end

                // Aurora 链路置位后才允许 FDMA 和 LocalLink 数据通路继续推进。
                if (test_running && !channel_up_fdma) begin
                    test_running <= 1'b0;
                    test_done <= 1'b1;
                    test_pass <= 1'b0;
                    result_code <= RESULT_LINK_DOWN;
                    link_down_sticky <= 1'b1;
                end else if (test_running && wr_all_received_pulse) begin
                    test_running <= 1'b0;
                    test_done <= 1'b1;
                    test_pass <= !hw_error_sticky;
                    result_code <= hw_error_sticky ? RESULT_MISMATCH : RESULT_PASS;
                end else if (test_running && rd_source_done) begin
                    // 排空等待超过上限时结束测试，避免硬件自测长时间挂起。
                    if (drain_timeout_count >= DRAIN_TIMEOUT_CYCLES-1) begin
                        test_running <= 1'b0;
                        test_done <= 1'b1;
                        test_pass <= 1'b0;
                        result_code <= RESULT_TIMEOUT;
                        timeout_sticky <= 1'b1;
                    end else begin
                        drain_timeout_count <= drain_timeout_count + 1'b1;
                    end
                end
            end
        end
    end

    // FDMA 读从机/数据源。
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!fdma_rstn) begin
            rd_state <= RD_IDLE;
            fdma_rbusy <= 1'b0;
            fdma_rdata <= 64'd0;
            fdma_rvalid <= 1'b0;
            source_frame_cnt <= 32'd0;
            source_word_in_frame <= 32'd0;
            rd_word_in_burst <= 16'd0;
            hw_rd_word_total <= 32'd0;
            hw_rd_burst_count <= 16'd0;
            rd_source_done <= 1'b0;
        end else if (clear_edge || accepted_start) begin
            rd_state <= RD_IDLE;
            fdma_rbusy <= 1'b0;
            fdma_rdata <= 64'd0;
            fdma_rvalid <= 1'b0;
            source_frame_cnt <= 32'd0;
            source_word_in_frame <= 32'd0;
            rd_word_in_burst <= 16'd0;
            hw_rd_word_total <= 32'd0;
            hw_rd_burst_count <= 16'd0;
            rd_source_done <= 1'b0;
        end else begin
            // 根据 rd_state 选择对应状态的输出赋值和下一拍转移。
            case (rd_state)
                // RD_IDLE 等待读请求和链路就绪，未满足时不发起 FIFO 读出。
                RD_IDLE: begin
                    fdma_rbusy <= 1'b0;
                    fdma_rvalid <= 1'b0;
                    // 测试运行中收到 rareq 且读源未完成时，读从机接受当前突发请求。
                    if (test_running && !rd_source_done && fdma_rareq) begin
                        fdma_rbusy <= 1'b1;
                        rd_word_in_burst <= 16'd0;
                        rd_state <= RD_ACCEPT;
                    end
                end
                // RD_ACCEPT 接受当前读请求，准备从硬件测试源输出第一个数据字。
                RD_ACCEPT: begin
                    fdma_rbusy <= 1'b1;
                    fdma_rvalid <= 1'b0;
                    fdma_rdata <= {source_frame_cnt, source_word_in_frame};
                    rd_state <= RD_SEND;
                end
                // RD_SEND 按 fdma_rready 节拍输出测试数据，并维护帧内字索引。
                RD_SEND: begin
                    fdma_rbusy <= 1'b1;
                    fdma_rvalid <= fdma_rready;
                    // 当前通道完成有效握手时才推进数据、计数器或队列指针。
                    if (read_hs) begin
                        // 读侧总字数未饱和时继续累加硬件读出统计。
                        if (hw_rd_word_total != 32'hffff_ffff)
                            hw_rd_word_total <= hw_rd_word_total + 1'b1;
                        // 测试源输出到帧尾时切到下一帧并清零帧内字索引。
                        if (source_word_in_frame == FRAME_WORDS-1) begin
                            fdma_rdata <= {source_frame_cnt + 1'b1, 32'd0};
                            source_word_in_frame <= 32'd0;
                            source_frame_cnt <= source_frame_cnt + 1'b1;
                        end else begin
                            fdma_rdata <= {source_frame_cnt,
                                           source_word_in_frame + 1'b1};
                            source_word_in_frame <= source_word_in_frame + 1'b1;
                        end
                        // 读突发最后一个字完成后撤销 rvalid 并进入收尾阶段。
                        if (rd_word_in_burst == BURST_WORDS-1) begin
                            fdma_rvalid <= 1'b0;
                            hw_rd_burst_count <= hw_rd_burst_count + 1'b1;
                            // 已输出的读突发达到目标帧数时标记测试源完成。
                            if (hw_rd_burst_count + 1'b1 >= target_frames)
                                rd_source_done <= 1'b1;
                            rd_state <= RD_FINISH;
                        end else begin
                            rd_word_in_burst <= rd_word_in_burst + 1'b1;
                        end
                    end
                end
                // RD_FINISH 撤销 rbusy/rvalid，等待主机侧释放 rareq 后回到空闲。
                RD_FINISH: begin
                    fdma_rbusy <= 1'b0;
                    fdma_rvalid <= 1'b0;
                    // 主机释放 rareq 后，读响应状态机回到空闲等待下一次请求。
                    if (!fdma_rareq)
                        rd_state <= RD_IDLE;
                end
                // 未列出的编码回到安全取值，避免状态机停留在非法状态。
                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // FDMA 写从机/数据检查器。
    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!fdma_rstn) begin
            wr_state <= WR_IDLE;
            fdma_wbusy <= 1'b0;
            fdma_wready <= 1'b0;
            expected_frame_cnt <= 32'd0;
            expected_word_in_frame <= 32'd0;
            wr_word_in_burst <= 13'd0;
            wr_words_expected <= 13'd0;
            hw_wr_word_total <= 32'd0;
            hw_wr_burst_count <= 16'd0;
            hw_error_count <= 32'd0;
            hw_error_sticky <= 1'b0;
            hw_first_error_expected <= 64'd0;
            hw_first_error_actual <= 64'd0;
            first_error_index <= 32'd0;
            first_error_class <= ERR_NONE;
            first_error_expected_next <= 64'd0;
            last_good_data <= 64'd0;
            first_error_pulse <= 1'b0;
            wr_all_received_pulse <= 1'b0;
        end else if (clear_edge || accepted_start) begin
            wr_state <= WR_IDLE;
            fdma_wbusy <= 1'b0;
            fdma_wready <= 1'b0;
            expected_frame_cnt <= 32'd0;
            expected_word_in_frame <= 32'd0;
            wr_word_in_burst <= 13'd0;
            wr_words_expected <= 13'd0;
            hw_wr_word_total <= 32'd0;
            hw_wr_burst_count <= 16'd0;
            hw_error_count <= 32'd0;
            hw_error_sticky <= 1'b0;
            hw_first_error_expected <= 64'd0;
            hw_first_error_actual <= 64'd0;
            first_error_index <= 32'd0;
            first_error_class <= ERR_NONE;
            first_error_expected_next <= 64'd0;
            last_good_data <= 64'd0;
            first_error_pulse <= 1'b0;
            wr_all_received_pulse <= 1'b0;
        end else begin
            first_error_pulse <= 1'b0;
            wr_all_received_pulse <= 1'b0;
            // 根据 wr_state 选择对应状态的输出赋值和下一拍转移。
            case (wr_state)
                // WR_IDLE 等待 RX FIFO 中出现可写回的数据，并保持写请求空闲。
                WR_IDLE: begin
                    fdma_wbusy <= 1'b0;
                    fdma_wready <= 1'b0;
                    // 测试运行中收到 wareq 且目标帧未收满时，写从机接受当前突发请求。
                    if (test_running && fdma_wareq &&
                        (hw_wr_burst_count < target_frames)) begin
                        fdma_wbusy <= 1'b1;
                        wr_words_expected <= (fdma_wsize[15:3] == 0) ?
                                             13'd1 : fdma_wsize[15:3];
                        wr_word_in_burst <= 13'd0;
                        wr_state <= WR_ACCEPT;
                    end
                end
                // WR_ACCEPT 接受当前写请求，并打开 wready 准备校验写回数据。
                WR_ACCEPT: begin
                    fdma_wbusy <= 1'b1;
                    fdma_wready <= 1'b1;
                    wr_state <= WR_RECV;
                end
                // WR_RECV 在 wvalid/wready 握手时校验写回数据并推进期望值模型。
                WR_RECV: begin
                    fdma_wbusy <= 1'b1;
                    fdma_wready <= 1'b1;
                    // 当前通道完成有效握手时才推进数据、计数器或队列指针。
                    if (write_hs) begin
                        // 写侧总字数未饱和时继续累加硬件写回统计。
                        if (hw_wr_word_total != 32'hffff_ffff)
                            hw_wr_word_total <= hw_wr_word_total + 1'b1;
                        // 写回数据与期望模型不一致时，记录首个错误并分类。
                        if (fdma_wdata != expected_data) begin
                            // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
                            if (hw_error_count != 32'hffff_ffff)
                                hw_error_count <= hw_error_count + 1'b1;
                            // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
                            if (!hw_error_sticky) begin
                                hw_error_sticky <= 1'b1;
                                first_error_pulse <= 1'b1;
                                first_error_index <= hw_wr_word_total;
                                hw_first_error_expected <= expected_data;
                                hw_first_error_actual <= fdma_wdata;
                                first_error_expected_next <= expected_next_data;
                                // 实际数据等于下一个期望字时，将首错归类为跳字。
                                if (fdma_wdata == expected_next_data)
                                    first_error_class <= ERR_SKIPPED_WORD;
                                // (hw_wr_word_total != 0 对应的事件发生时执行本段处理。
                                else if ((hw_wr_word_total != 0) &&
                                         (fdma_wdata == last_good_data))
                                    first_error_class <= ERR_DUPLICATED_WORD;
                                // 首个错误既非跳字也非重字时，归类为其它数据异常。
                                else
                                    first_error_class <= ERR_OTHER;
                            end
                        end else begin
                            last_good_data <= fdma_wdata;
                        end

                        // 期望模型到达帧尾时切到下一帧并清零帧内字索引。
                        if (expected_word_in_frame == FRAME_WORDS-1) begin
                            expected_word_in_frame <= 32'd0;
                            expected_frame_cnt <= expected_frame_cnt + 1'b1;
                        end else begin
                            expected_word_in_frame <= expected_word_in_frame + 1'b1;
                        end

                        // 写突发最后一个字完成后撤销 wready 并进入收尾阶段。
                        if (wr_word_in_burst == wr_words_expected-1'b1) begin
                            fdma_wready <= 1'b0;
                            hw_wr_burst_count <= hw_wr_burst_count + 1'b1;
                            // 已接收的写突发达到目标帧数时产生写回完成脉冲。
                            if (hw_wr_burst_count + 1'b1 >= target_frames)
                                wr_all_received_pulse <= 1'b1;
                            wr_state <= WR_FINISH;
                        end else begin
                            wr_word_in_burst <= wr_word_in_burst + 1'b1;
                        end
                    end
                end
                // WR_FINISH 撤销 wbusy/wready，等待主机侧释放 wareq 后回到空闲。
                WR_FINISH: begin
                    fdma_wbusy <= 1'b0;
                    fdma_wready <= 1'b0;
                    // 主机释放 wareq 后，写响应状态机回到空闲等待下一次请求。
                    if (!fdma_wareq)
                        wr_state <= WR_IDLE;
                end
                // 未列出的编码回到安全取值，避免状态机停留在非法状态。
                default: wr_state <= WR_IDLE;
            endcase
        end
    end
endmodule