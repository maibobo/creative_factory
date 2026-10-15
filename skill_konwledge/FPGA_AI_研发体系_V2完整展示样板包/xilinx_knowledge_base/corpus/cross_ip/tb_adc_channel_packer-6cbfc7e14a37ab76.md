# tb_adc_channel_packer

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\sim\tb_adc_channel_packer.sv`
- SHA-256: `6cbfc7e14a37ab76236e33d65ec226c932adbd02c2c4d7fc6fa0d0802cb26b4c`
- Extractor: `text`
- Tags: `nvme, pcie, verification`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\sim\tb_adc_channel_packer.sv

```systemverilog
`timescale 1ns/1ps

// adc_channel_packer单元回归。
//
// 覆盖三种运行模式、符号扩展边界、256 bit字节顺序、0/短/整字/跨字长度、
// 输出反压稳定性以及Capture内配置锁定。该测试不经过CDC、DDR或NVMe。
module tb_adc_channel_packer;

    // 250 MHz表示每4 ns产生一个ADC采样时刻。
    reg adc_clk = 1'b0;
    always #2 adc_clk = ~adc_clk; // 250 MHz

    reg adc_rst_n = 1'b0;
    reg capture_start = 1'b0;
    reg capture_stop = 1'b0;
    reg cfg_two_channel = 1'b1;
    reg cfg_single_channel_select = 1'b0;
    reg [63:0] cfg_capture_id = 64'd0;
    reg adc_valid = 1'b0;
    reg [11:0] adc_ch0 = 12'd0;
    reg [11:0] adc_ch1 = 12'd0;

    wire [255:0] packed_data;
    wire [5:0] packed_valid_bytes;
    wire packed_eoc;
    wire packed_valid;
    reg packed_ready = 1'b0;
    wire capture_active;
    wire capture_ready;
    wire active_two_channel;
    wire active_single_select;
    wire [63:0] active_capture_id;
    wire overflow_sticky;
    wire config_change_sticky;
    wire [63:0] accepted_samples;
    wire [63:0] dropped_samples;

    // SIGN_EXTEND=1：12 bit的bit[11]复制到16 bit高四位，
    // 因而0x800和0xFFF分别扩展为0xF800和0xFFFF。
    adc_channel_packer #(
        // 本用例验证二补码符号扩展路径。
        .SIGN_EXTEND (1'b1)
    ) dut (
        .adc_clk                     (adc_clk),
        .adc_rst_n                   (adc_rst_n),
        .capture_start               (capture_start),
        .capture_stop                (capture_stop),
        .cfg_two_channel             (cfg_two_channel),
        .cfg_single_channel_select   (cfg_single_channel_select),
        .cfg_capture_id              (cfg_capture_id),
        .adc_valid                   (adc_valid),
        .adc_ch0                     (adc_ch0),
        .adc_ch1                     (adc_ch1),
        .m_axis_tdata                (packed_data),
        .m_axis_valid_bytes          (packed_valid_bytes),
        .m_axis_end_of_capture       (packed_eoc),
        .m_axis_tvalid               (packed_valid),
        .m_axis_tready               (packed_ready),
        .capture_active              (capture_active),
        .capture_ready               (capture_ready),
        .active_two_channel          (active_two_channel),
        .active_single_channel_select(active_single_select),
        .active_capture_id           (active_capture_id),
        .overflow_sticky             (overflow_sticky),
        .config_change_sticky        (config_change_sticky),
        .accepted_sample_times       (accepted_samples),
        .dropped_sample_times        (dropped_samples)
    );

    reg [15:0] lfsr = 16'hBEEF;
    reg [2:0] consecutive_stalls = 3'd0;

    // 产生有上限的伪随机反压。正常系统中这里对应1024项异步FIFO的ready；
    // 将连续stall限制为最多4个ADC周期，避免把预期溢出场景混入功能回归。
    always @(posedge adc_clk) begin
        if (!adc_rst_n) begin
            lfsr         <= 16'hBEEF;
            packed_ready <= 1'b0;
            consecutive_stalls <= 3'd0;
        end else begin
            lfsr <= {lfsr[14:0],
                     lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
            // The physical ADC cannot be backpressured.  In the complete
            // design the packer sees the 1024-word CDC FIFO, whose ready only
            // drops at reset or full.  Exercise short handshake stalls here,
            // but cap them at four ADC cycles; unbounded stalls are a
            // separate overflow/fault scenario rather than a normal case.
            if ((consecutive_stalls == 3'd3) ||
                (lfsr[0] | lfsr[2] | lfsr[4])) begin
                packed_ready <= 1'b1;
                consecutive_stalls <= 3'd0;
            end else begin
                packed_ready <= 1'b0;
                consecutive_stalls <= consecutive_stalls + 1'b1;
            end
        end
    end

    reg [255:0] observed_data [0:32767];
    reg [5:0] observed_bytes [0:32767];
    reg observed_eoc [0:32767];
    integer observed_count = 0;

    reg held_valid = 1'b0;
    reg [262:0] held_payload;

    // Scoreboard在每次输出握手时保存一个复合字；同时检查valid&&!ready期间
    // data、valid_bytes和EOC三个字段必须作为整体保持不变。
    always @(posedge adc_clk) begin
        if (!adc_rst_n) begin
            observed_count <= 0;
            held_valid     <= 1'b0;
            held_payload   <= 263'd0;
        end else begin
            if (packed_valid && !packed_ready) begin
                if (held_valid &&
                    held_payload !== {packed_eoc, packed_valid_bytes,
                                      packed_data})
                    $fatal(1, "ASSERT: packed payload changed while stalled");
                held_valid   <= 1'b1;
                held_payload <= {packed_eoc, packed_valid_bytes, packed_data};
            end else begin
                held_valid <= 1'b0;
            end

            if (packed_valid && packed_ready) begin
                observed_data[observed_count]  <= packed_data;
                observed_bytes[observed_count] <= packed_valid_bytes;
                observed_eoc[observed_count]   <= packed_eoc;
                observed_count                 <= observed_count + 1;
            end
        end
    end

    // 四值循环特意覆盖二补码的正零、最大正数、最小负数和-1边界。
    function automatic [11:0] raw_pattern;
        input integer sample_index;
        begin
            case (sample_index % 4)
                0: raw_pattern = 12'h000;
                1: raw_pattern = 12'h7FF;
                2: raw_pattern = 12'h800;
                default: raw_pattern = 12'hFFF;
            endcase
        end
    endfunction

    // 与DUT的SIGN_EXTEND=1配置对应的参考模型。
    function automatic [15:0] ext12;
        input [11:0] raw;
        begin
            ext12 = {{4{raw[11]}}, raw};
        end
    endfunction

    // 单个用例流程：
    // 等待ready -> 锁存模式并启动 -> 连续送sample_count个采样时刻 ->
    // stop -> 等待EOC被消费 -> 逐字节比较紧凑存储格式和统计计数。
    task automatic run_case;
        input bit two_channel;
        input bit select_ch1;
        input integer sample_count;
        input [63:0] capture_id;
        integer i;
        integer byte_index;
        integer word_index;
        integer word_offset;
        integer total_bytes;
        integer data_words;
        integer expected_words;
        integer expected_tail_bytes;
        reg [15:0] expected_ch0;
        reg [15:0] expected_ch1;
        reg [7:0] expected_byte;
        begin
            while (!capture_ready)
                @(negedge adc_clk);
            observed_count = 0;
            cfg_two_channel = two_channel;
            cfg_single_channel_select = select_ch1;
            cfg_capture_id = capture_id;
            capture_start = 1'b1;
            @(negedge adc_clk);
            capture_start = 1'b0;

            for (i = 0; i < sample_count; i = i + 1) begin
                adc_valid = 1'b1;
                adc_ch0 = raw_pattern(i);
                adc_ch1 = raw_pattern(i + 1);
                @(negedge adc_clk);
            end
            adc_valid = 1'b0;
            capture_stop = 1'b1;
            @(negedge adc_clk);
            capture_stop = 1'b0;

            // capture_active下降表示尾字/EOC已经通过输出握手，不只是收到stop。
            while (capture_active)
                @(negedge adc_clk);
            repeat (2) @(negedge adc_clk);

            total_bytes = sample_count * (two_channel ? 4 : 2);
            data_words = (total_bytes + 31) / 32;
            expected_words = (total_bytes == 0) ? 1 : data_words;
            // 当总字节数恰为32的整数倍时，packer允许在满数据字之后另发一个
            // valid_bytes=0的EOC控制字；Scoreboard同时接受这两种合法边界表现。
            if (!((observed_count == expected_words) ||
                  ((total_bytes != 0) && ((total_bytes % 32) == 0) &&
                   (observed_count == (data_words + 1)))))
                $fatal(1, "Word count mismatch: mode=%0d samples=%0d got=%0d exp=%0d",
                       two_channel, sample_count, observed_count,
                       expected_words);

            for (byte_index = 0; byte_index < total_bytes;
                 byte_index = byte_index + 1) begin
                // 双通道每个采样时刻按CH0低/高字节、CH1低/高字节排列；
                // 单通道只写所选通道的低/高字节，不为另一通道补零。
                word_index = byte_index / 32;
                word_offset = byte_index % 32;
                i = byte_index / (two_channel ? 4 : 2);
                expected_ch0 = ext12(raw_pattern(i));
                expected_ch1 = ext12(raw_pattern(i + 1));
                if (two_channel) begin
                    case (byte_index % 4)
                        0: expected_byte = expected_ch0[7:0];
                        1: expected_byte = expected_ch0[15:8];
                        2: expected_byte = expected_ch1[7:0];
                        default: expected_byte = expected_ch1[15:8];
                    endcase
                end else begin
                    if (select_ch1)
                        expected_ch0 = expected_ch1;
                    expected_byte = (byte_index[0]) ?
                                    expected_ch0[15:8] :
                                    expected_ch0[7:0];
                end
                if (observed_data[word_index][word_offset*8 +: 8] !==
                    expected_byte)
                    $fatal(1, "Byte mismatch mode=%0d sel=%0d samples=%0d byte=%0d got=%02x exp=%02x accepted=%0d dropped=%0d overflow=%0b",
                           two_channel, select_ch1, sample_count, byte_index,
                           observed_data[word_index][word_offset*8 +: 8],
                           expected_byte, accepted_samples, dropped_samples,
                           overflow_sticky);
            end

            if (!observed_eoc[observed_count-1])
                $fatal(1, "Last word is missing EOC");
            if ((total_bytes != 0) && (observed_count == data_words))
                expected_tail_bytes = ((total_bytes % 32) == 0) ?
                                      32 : (total_bytes % 32);
            else
                expected_tail_bytes = 0;
            if (observed_bytes[observed_count-1] != expected_tail_bytes)
                $fatal(1, "Tail valid_bytes mismatch: got=%0d exp=%0d",
                       observed_bytes[observed_count-1],
                       expected_tail_bytes);
            if ((accepted_samples != sample_count) || (dropped_samples != 0) ||
                overflow_sticky)
                $fatal(1, "Sample counters mismatch accepted=%0d dropped=%0d",
                       accepted_samples, dropped_samples);
            if ((active_capture_id != capture_id) ||
                (active_two_channel != two_channel) ||
                (active_single_select != select_ch1))
                $fatal(1, "Capture configuration was not latched");
        end
    endtask

    integer length_index;
    integer lengths [0:7];
    initial begin
        // 这些边界同时跨越双通道8 sample/word和单通道16 sample/word：
        // 7/8/9验证双通道字边界，15/16/17验证单通道字边界，0验证空Capture。
        lengths[0] = 0;
        lengths[1] = 1;
        lengths[2] = 7;
        lengths[3] = 8;
        lengths[4] = 9;
        lengths[5] = 15;
        lengths[6] = 16;
        lengths[7] = 17;

        repeat (12) @(posedge adc_clk);
        adc_rst_n = 1'b1;

        for (length_index = 0; length_index < 8;
             length_index = length_index + 1) begin
            run_case(1'b1, 1'b0, lengths[length_index],
                     64'h1000 + length_index);
            run_case(1'b0, 1'b0, lengths[length_index],
                     64'h2000 + length_index);
            run_case(1'b0, 1'b1, lengths[length_index],
                     64'h3000 + length_index);
        end

        // 真实时间长度按250 MSPS换算：10 us=2500个采样时刻，以此类推。
        run_case(1'b1, 1'b0,   2500, 64'h400A); // 10 us
        run_case(1'b0, 1'b0,  12500, 64'h4032); // 50 us
        run_case(1'b0, 1'b1,  25000, 64'h4064); // 100 us
        run_case(1'b1, 1'b0, 250000, 64'h43E8); // 1 ms

        // Changing a capture setting while ACTIVE must not change the
        // latched mode, and it must leave an observable error indication.
        while (!capture_ready)
            @(negedge adc_clk);
        cfg_two_channel = 1'b1;
        cfg_single_channel_select = 1'b0;
        cfg_capture_id = 64'h4444;
        capture_start = 1'b1;
        @(negedge adc_clk);
        capture_start = 1'b0;
        adc_valid = 1'b1;
        adc_ch0 = 12'h000;
        adc_ch1 = 12'h7FF;
        @(negedge adc_clk);
        cfg_two_channel = 1'b0;
        repeat (8) @(negedge adc_clk);
        adc_valid = 1'b0;
        capture_stop = 1'b1;
        @(negedge adc_clk);
        capture_stop = 1'b0;
        while (capture_active)
            @(negedge adc_clk);
        if (!config_change_sticky)
            $fatal(1, "Configuration change during capture was not detected");

        $display("TEST_PASS: packer boundary lengths, modes, byte order and config lock");
        $finish;
    end

    // 防止握手或状态机死锁导致批处理永久等待。
    initial begin
        #10_000_000;
        $fatal(1, "Packer regression timeout");
    end

endmodule
```
