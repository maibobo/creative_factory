// 快速环境 TX 计分板：只依据实际 valid/ready 握手比对16Byte帧。
// arm_tx 提交预期序号，wait_tx_complete 有界等待；任何比较错误必须进入最终失败判定。
`timescale 1ns / 1ps

module rtds_scoreboard (
        input              user_clk,
        input              user_rstn,
        input      [63:0]  tx_d,
        input              tx_sof,
        input              tx_eof,
        input      [2:0]   tx_rem,
        input              tx_src_rdy,
        input              tx_dst_rdy,
        output reg [31:0]  error_count,
        output reg [31:0]  tx_total_frames,
        output reg         tx_expectation_active
    );
    import rtds_test_pkg::*;
    integer expected_first_frame;
    integer expected_frame_count;
    integer run_frame_index;
    integer beat_index;
    logic [63:0] expected_data;

    task automatic arm_tx(input integer first_frame, input integer frame_count);
        begin
            @(negedge user_clk);
            expected_first_frame = first_frame;
            expected_frame_count = frame_count;
            run_frame_index = 0;
            beat_index = 0;
            tx_expectation_active = 1'b1;
        end
    endtask

    task automatic wait_tx_complete(input integer timeout_cycles);
        integer cycle_count;
        begin : wait_block
            for (cycle_count = 0; cycle_count < timeout_cycles; cycle_count = cycle_count + 1) begin
                @(posedge user_clk);
                if (!tx_expectation_active)
                    disable wait_block;
            end
            if (tx_expectation_active) begin
                error_count = error_count + 1;
                $error("SCOREBOARD timeout waiting for TX frames");
            end
        end
    endtask

    initial begin
        error_count = 0;
        tx_total_frames = 0;
        tx_expectation_active = 0;
        expected_first_frame = 0;
        expected_frame_count = 0;
        run_frame_index = 0;
        beat_index = 0;
    end

    always @(posedge user_clk) begin
        if (!user_rstn) begin
            tx_expectation_active <= 1'b0;
            run_frame_index <= 0;
            beat_index <= 0;
        end else if (tx_src_rdy && tx_dst_rdy) begin
            if (!tx_expectation_active) begin
                error_count = error_count + 1;
                $error("SCOREBOARD observed unexpected TX data");
            end else begin
                expected_data = make_pattern(8'h54,
                    expected_first_frame + run_frame_index, beat_index);
                if (tx_d !== expected_data) begin
                    error_count = error_count + 1;
                    $error("TX_DATA frame=%0d beat=%0d expected=%h actual=%h",
                           expected_first_frame + run_frame_index,
                           beat_index, expected_data, tx_d);
                end
                if (tx_sof !== (beat_index == 0)) begin
                    error_count = error_count + 1;
                    $error("TX_SOF frame=%0d beat=%0d", run_frame_index, beat_index);
                end
                if (tx_eof !== (beat_index == 1)) begin
                    error_count = error_count + 1;
                    $error("TX_EOF frame=%0d beat=%0d", run_frame_index, beat_index);
                end
                if ((beat_index == 1) && (tx_rem != 3'b111)) begin
                    error_count = error_count + 1;
                    $error("TX_REM was not 3'b111 on EOF");
                end

                if (beat_index == 1) begin
                    tx_total_frames <= tx_total_frames + 1;
                    beat_index <= 0;
                    if ((run_frame_index + 1) >= expected_frame_count) begin
                        tx_expectation_active <= 1'b0;
                        run_frame_index <= 0;
                    end else begin
                        run_frame_index <= run_frame_index + 1;
                    end
                end else begin
                    beat_index <= beat_index + 1;
                end
            end
        end
    end
endmodule
