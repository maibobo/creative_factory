// 快速 LocalLink 对端：发送4个低32bit有效字，线路RX不接受DDR反压。
// TX可施加停顿；RX按连续4拍驱动，协议检查使用实际接收握手。
`timescale 1ns / 1ps

module aurora_ll_peer_bfm (
        input              user_clk,
        input              user_rstn,
        input              link_up,

        input      [63:0]  tx_d,
        input              tx_sof,
        input              tx_eof,
        input      [2:0]   tx_rem,
        input              tx_src_rdy,
        output reg         tx_dst_rdy,

        output reg [63:0]  rx_d,
        output reg         rx_sof,
        output reg         rx_eof,
        output reg [2:0]   rx_rem,
        output reg         rx_src_rdy,
        input              rx_dst_rdy,

        output reg [31:0]  tx_stall_cycles
    );
    import rtds_test_pkg::*;
    // 两个线路低32bit重组为一个期望64bit字，高32bit随机且不得进入DDR。
    function automatic logic [63:0] make_rx_beat(input integer frame_id,input integer word_id);
        logic [63:0] expected_word;
        expected_word=make_pattern(8'h52,frame_id,word_id/2);
        make_rx_beat={$urandom,32'(expected_word >> ((word_id%2)*32))};
    endfunction
    reg tx_stall_enable;

    initial begin
        tx_stall_enable = 1'b0;
        tx_dst_rdy = 1'b0;
        rx_d = 64'd0;
        rx_sof = 1'b0;
        rx_eof = 1'b0;
        rx_rem = 3'b111;
        rx_src_rdy = 1'b0;
        tx_stall_cycles = 32'd0;
    end

    task automatic set_tx_stall(input bit enable);
        tx_stall_enable = enable;
    endtask

    always @(negedge user_clk) begin
        if (!user_rstn || !link_up)
            tx_dst_rdy <= 1'b0;
        else if (tx_stall_enable)
            tx_dst_rdy <= ($urandom_range(0, 3) != 0);
        else
            tx_dst_rdy <= 1'b1;
    end

    always @(posedge user_clk) begin
        if (!user_rstn)
            tx_stall_cycles <= 32'd0;
        else if (tx_src_rdy && !tx_dst_rdy)
            tx_stall_cycles <= tx_stall_cycles + 1;
    end

    task automatic send_rx_frame(input integer frame_index);
        integer beat_index;
        begin
            while (!user_rstn || !link_up)
                @(posedge user_clk);
            for (beat_index = 0; beat_index < 4; beat_index = beat_index + 1) begin
                @(negedge user_clk);
                rx_d       <= make_rx_beat(frame_index, beat_index);
                rx_sof     <= (beat_index == 0);
                rx_eof     <= (beat_index == 3);
                rx_rem     <= 3'b111;
                rx_src_rdy <= 1'b1;
                @(posedge user_clk);
                while (!rx_dst_rdy)
                    @(posedge user_clk);
            end
            @(negedge user_clk);
            rx_src_rdy <= 1'b0;
            rx_sof     <= 1'b0;
            rx_eof     <= 1'b0;
            rx_d       <= 64'd0;
        end
    endtask

    // Expected-overflow pressure source. Unlike send_rx_frame, this task
    // models an upstream source that cannot honor LocalLink backpressure.
    task automatic send_rx_pressure(input integer first_frame, input integer frame_count);
        integer frame_offset;
        integer beat_index;
        begin
            while (!user_rstn || !link_up)
                @(posedge user_clk);
            for (frame_offset = 0; frame_offset < frame_count; frame_offset = frame_offset + 1) begin
                for (beat_index = 0; beat_index < 4; beat_index = beat_index + 1) begin
                    @(negedge user_clk);
                    rx_d       <= make_rx_beat(first_frame + frame_offset, beat_index);
                    rx_sof     <= (beat_index == 0);
                    rx_eof     <= (beat_index == 3);
                    rx_rem     <= 3'b111;
                    rx_src_rdy <= 1'b1;
                end
            end
            @(negedge user_clk);
            rx_src_rdy <= 1'b0;
            rx_sof     <= 1'b0;
            rx_eof     <= 1'b0;
            rx_d       <= 64'd0;
        end
    endtask
endmodule
