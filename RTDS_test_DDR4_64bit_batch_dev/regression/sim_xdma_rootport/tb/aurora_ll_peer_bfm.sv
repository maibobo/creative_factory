`timescale 1ns / 1ps

// Aurora LocalLink 边界 BFM。
// TX 表示 FPGA->Aurora，可由接收端施加背压；RX 表示 Aurora->FPGA，按真实
// SERDES 约束连续发送，绝不因为 FPGA 的 rx_dst_rdy 变低而暂停数据源。
// 输入：DUT TX LocalLink、link/reset 和用例调用的 seed/backpressure 配置。
// 输出：TX 捕获字节/帧计数、连续 RX 帧以及比较/反压错误计数。
// 失败定位：CPU→Aurora 数据错查 capture_count/首个 mismatch；Aurora→FPGA
// 接收能力不足查 rx_not_ready_errors；SOF/EOF/rem 错查对应协议错误计数。
module aurora_ll_peer_bfm (
    input             user_clk,
    input             user_rstn,
    input             link_up,

    input      [63:0] tx_d,
    input             tx_sof,
    input             tx_eof,
    input      [2:0]  tx_rem,
    input             tx_src_rdy,
    output reg        tx_dst_rdy,

    output reg [63:0] rx_d,
    output reg        rx_sof,
    output reg        rx_eof,
    output reg [2:0]  rx_rem,
    output reg        rx_src_rdy,
    input             rx_dst_rdy,

    output reg [31:0] tx_stall_cycles,
    output reg [31:0] rx_not_ready_errors,
    output reg [31:0] protocol_errors
);
    import rtds_rootport_pkg::*;

    localparam integer CAPTURE_BYTES = 32 * 1024;
    reg [7:0] tx_capture [0:CAPTURE_BYTES-1];
    integer tx_capture_count;
    integer tx_frame_count;
    reg     tx_in_frame;
    reg     tx_backpressure_enable;

    integer byte_index;
    integer valid_bytes;

    // ---------- 语义段 0：BFM 状态初始化 ----------
    // 输入：无；输出：计数器、RX/TX 驱动和背压配置的确定初值。
    // 失败定位：0 ns 出现 X/Z 或历史计数残留时检查本段是否执行。
    initial begin
        tx_dst_rdy            = 1'b0;
        rx_d                  = 64'd0;
        rx_sof                = 1'b0;
        rx_eof                = 1'b0;
        rx_rem                = 3'b111;
        rx_src_rdy            = 1'b0;
        tx_stall_cycles       = 32'd0;
        rx_not_ready_errors   = 32'd0;
        protocol_errors       = 32'd0;
        tx_capture_count      = 0;
        tx_frame_count        = 0;
        tx_in_frame           = 1'b0;
        tx_backpressure_enable = 1'b0;
    end

    // ---------- 语义段 1：FPGA→Aurora 接收和可选背压 ----------
    // 输入：tx_* 和可选背压开关；输出：tx_dst_rdy、捕获内存和协议计数。
    // 作用：只在 src_rdy&&dst_rdy 时收拍，背压期间由断言检查信号稳定。
    // 失败定位：捕获长度不对时先查握手拍数，再查 SOF/EOF/rem。
    task automatic set_tx_backpressure(input bit enable);
        tx_backpressure_enable = enable;
    endtask

    task automatic clear_tx_capture;
        begin
            @(negedge user_clk);
            tx_capture_count = 0;
            tx_frame_count   = 0;
            tx_in_frame      = 1'b0;
        end
    endtask

    always @(negedge user_clk) begin
        if (!user_rstn || !link_up)
            tx_dst_rdy <= 1'b0;
        else if (tx_backpressure_enable)
            tx_dst_rdy <= ($urandom_range(0, 3) != 0);
        else
            tx_dst_rdy <= 1'b1;
    end

    always @(posedge user_clk) begin
        if (!user_rstn) begin
            tx_stall_cycles  <= 32'd0;
            tx_capture_count <= 0;
            tx_frame_count   <= 0;
            tx_in_frame      <= 1'b0;
        end else begin
            if (tx_src_rdy && !tx_dst_rdy)
                tx_stall_cycles <= tx_stall_cycles + 1;

            if (tx_src_rdy && tx_dst_rdy) begin
                if (tx_sof && tx_in_frame) begin
                    protocol_errors <= protocol_errors + 1;
                    $error("RTDS_LL_TX_PROTOCOL: frame 内出现重复 SOF");
                end
                if (!tx_in_frame && !tx_sof) begin
                    protocol_errors <= protocol_errors + 1;
                    $error("RTDS_LL_TX_PROTOCOL: 首拍缺少 SOF");
                end

                valid_bytes = tx_eof ? (tx_rem + 1) : 8;
                for (byte_index = 0; byte_index < valid_bytes; byte_index = byte_index + 1) begin
                    if (tx_capture_count < CAPTURE_BYTES) begin
                        tx_capture[tx_capture_count] = tx_d[byte_index*8 +: 8];
                        tx_capture_count = tx_capture_count + 1;
                    end else begin
                        protocol_errors <= protocol_errors + 1;
                        $error("RTDS_LL_TX_PROTOCOL: capture buffer 溢出");
                    end
                end

                if (tx_eof) begin
                    if (!tx_in_frame && !tx_sof) begin
                        protocol_errors <= protocol_errors + 1;
                        $error("RTDS_LL_TX_PROTOCOL: EOF 不属于有效 frame");
                    end
                    tx_frame_count <= tx_frame_count + 1;
                    tx_in_frame    <= 1'b0;
                end else begin
                    tx_in_frame <= 1'b1;
                end
            end
        end
    end

    // ---------- 语义段 2：Aurora→FPGA 连续源，禁止反压 ----------
    // 输入：用例 seed 与启动 task；输出：固定 16 beat 的 RX 帧。
    // 作用：模拟 SerDes 已到达的连续数据，不因 DUT dst_rdy 低而停源。
    // 失败定位：dst_rdy 低立即累加 rx_not_ready_errors，属于 DUT 吞吐问题。

    always @(posedge user_clk) begin
        if (!user_rstn) begin
            rx_not_ready_errors <= 32'd0;
        end else if (rx_src_rdy && !rx_dst_rdy) begin
            rx_not_ready_errors <= rx_not_ready_errors + 1;
            $error("RTDS_LL_RX_NO_BACKPRESSURE: FPGA 在 Aurora 连续输入期间撤销 ready");
        end
    end

    function automatic [63:0] make_rx_beat(input [7:0] seed, input integer first_byte);
        integer lane;
        begin
            make_rx_beat[63:32] = $urandom;
            for (lane = 0; lane < 4; lane = lane + 1)
                make_rx_beat[lane*8 +: 8] = pattern_byte(seed, first_byte + lane);
        end
    endfunction

    task automatic send_rx_frame_16(input [7:0] seed);
        integer beat_index;
        begin
            while (!user_rstn || !link_up)
                @(posedge user_clk);

            for (beat_index = 0; beat_index < FRAME_BYTES/4; beat_index = beat_index + 1) begin
                @(negedge user_clk);
                rx_d       <= make_rx_beat(seed, beat_index * 4);
                rx_sof     <= (beat_index == 0);
                rx_eof     <= (beat_index == FRAME_BYTES/4-1);
                rx_rem     <= 3'b111;
                rx_src_rdy <= 1'b1;
                // 只等待采样沿，不检查/等待 rx_dst_rdy，保持 SERDES 连续源语义。
                @(posedge user_clk);
            end

            @(negedge user_clk);
            rx_d       <= 64'd0;
            rx_sof     <= 1'b0;
            rx_eof     <= 1'b0;
            rx_rem     <= 3'b111;
            rx_src_rdy <= 1'b0;
        end
    endtask

    // ---------- 语义段 3：按有效字节比较 FPGA→Aurora 输出 ----------
    // 输入：期望 seed 和已捕获 TX 字节；输出：mismatch 数及 PASS/FAIL 日志。
    // 作用：按有效字节比较，不假设 16 B 必须由某种特殊物理帧组织。
    // 失败定位：日志给出首个字节索引，回看该索引附近 LL 和 FDMA 波形。
    task automatic wait_and_compare_tx_16(
        input [7:0] seed,
        input integer timeout_cycles,
        output integer mismatch_count
    );
        integer timeout;
        integer index;
        begin : wait_compare_block
            mismatch_count = 0;
            timeout = 0;
            while ((tx_capture_count < FRAME_BYTES) && (timeout < timeout_cycles)) begin
                @(posedge user_clk);
                timeout = timeout + 1;
            end
            if (tx_capture_count != FRAME_BYTES) begin
                mismatch_count = mismatch_count + 1;
                $error("RTDS_LL_TX_COMPARE: 期望 16 字节，实际 %0d 字节", tx_capture_count);
                disable wait_compare_block;
            end
            for (index = 0; index < FRAME_BYTES; index = index + 1) begin
                if (tx_capture[index] !== pattern_byte(seed, index)) begin
                    mismatch_count = mismatch_count + 1;
                    if (mismatch_count <= 8)
                        $error("RTDS_LL_TX_COMPARE: byte[%0d] expected=%02x actual=%02x",
                               index, pattern_byte(seed, index), tx_capture[index]);
                end
            end
        end
    endtask
endmodule
