`timescale 1ns / 1ps
// File: tb_fdma_tx_burst_boundary.sv

// 专项 bridge 测试：两个 512 字节 FDMA 突发必须形成 128 个有序数据字。
// 检查 LocalLink 传输计数；断言只保留在验证代码中。
// tb_fdma_tx_突发_boundary 模块入口；TX 突发 边界专项 测试平台，检查每个 512B 突发 的第 64 个字不会丢失。
module tb_fdma_tx_burst_boundary;
    // 固定 WORDS_PER_BURST 的传输规模，保证读写两侧按同一长度收尾。
    localparam integer WORDS_PER_BURST = 64;
    reg fdma_clk = 1'b0;
    reg user_clk = 1'b0;
    reg fdma_rstn = 1'b0;
    reg user_rstn = 1'b0;
    reg channel_up = 1'b0;
    reg channel_up_fdma = 1'b0;
    wire [31:0] fdma_raddr;
    wire fdma_rareq;
    reg fdma_rbusy = 1'b0;
    reg [63:0] fdma_rdata = 64'd0;
    reg fdma_rvalid = 1'b0;
    wire fdma_rready;
    wire [63:0] tx_d;
    wire tx_sof, tx_eof;
    wire [2:0] tx_rem;
    wire tx_src_rdy;
    reg tx_dst_rdy = 1'b1;
    wire [37:0] dbg_fdma_bus;
    wire [38:0] dbg_user_bus;

    logic [63:0] actual_words[$];
    integer burst_fifo_write_count = 0;
    integer completed_write_bursts = 0;
    integer failures = 0;

    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #2.0 fdma_clk = ~fdma_clk;       // 250 MHz
    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #3.103 user_clk = ~user_clk;     // 约 161.13 MHz

    fdma_aurora_brg_tx #(.FRAME_BYTES(512)) dut (
        .fdma_clk(fdma_clk), .fdma_rstn(fdma_rstn),
        .user_clk(user_clk), .user_rstn(user_rstn),
        .channel_up(channel_up), .channel_up_fdma(channel_up_fdma),
        .cfg_tx_burst_limit(16'd0),
        .fdma_raddr(fdma_raddr), .fdma_rareq(fdma_rareq),
        .fdma_rbusy(fdma_rbusy), .fdma_rdata(fdma_rdata),
        .fdma_rvalid(fdma_rvalid), .fdma_rready(fdma_rready),
        .tx_d(tx_d), .tx_sof(tx_sof), .tx_eof(tx_eof), .tx_rem(tx_rem),
        .tx_src_rdy(tx_src_rdy), .tx_dst_rdy(tx_dst_rdy),
        .dbg_fdma_bus(dbg_fdma_bus), .dbg_user_bus(dbg_user_bus)
    );

    // 每次 FIFO 写入都必须来自 RD_DATA 状态下的一次真实 FDMA 握手。
    // SVA 属性描述协议/边界约束，用于在仿真中捕捉隐藏时序错误。
    property p_fifo_write_is_fdma_handshake;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        dut.fifo_wr_en |-> (dut.rd_state == 2'd2 && fdma_rvalid && fdma_rready);
    endproperty
    // 断言把协议约束转成自动检查，失败时直接报告定位信息。
    assert property (p_fifo_write_is_fdma_handshake)
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else $fatal(1, "fifo_wr_en without an RD_DATA handshake");

    // 旧的 rd_state_nxt 门控会在第 63 个数据字触发该断言。
    // SVA 属性描述协议/边界约束，用于在仿真中捕捉隐藏时序错误。
    property p_last_word_is_written;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        dut.rd_burst_done |-> (dut.fifo_wr_en && dut.rd_word_cnt == 7'd63);
    endproperty
    // 断言把协议约束转成自动检查，失败时直接报告定位信息。
    assert property (p_last_word_is_written)
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else $fatal(1, "FDMA burst last word was not written to TX FIFO");

    // 反压期间检查源侧类 AXI 稳定性规则。
    // SVA 属性描述协议/边界约束，用于在仿真中捕捉隐藏时序错误。
    property p_read_data_stable_when_stalled;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        fdma_rvalid && !fdma_rready |=>
            fdma_rvalid && $stable(fdma_rdata);
    endproperty
    // 断言把协议约束转成自动检查，失败时直接报告定位信息。
    assert property (p_read_data_stable_when_stalled)
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else $fatal(1, "FDMA source changed data while stalled");

    // FDMA 时钟域时序逻辑，处理 FDMA 握手、地址、突发 计数或硬件自测状态。
    always @(posedge fdma_clk) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!fdma_rstn) begin
            burst_fifo_write_count <= 0;
            completed_write_bursts <= 0;
        end else begin
            // DUT 写入 FIFO 时采集实际数据字，供突发边界检查。
            if (dut.fifo_wr_en)
                burst_fifo_write_count <= burst_fifo_write_count + 1;
            // DUT 报告读突发完成时累计完成次数。
            if (dut.rd_burst_done) begin
                assert (burst_fifo_write_count + 1 == WORDS_PER_BURST)
                    // 未命中前面的互斥路径时，保持当前阶段的正常推进。
                    else $fatal(1, "burst contained %0d FIFO writes",
                                burst_fifo_write_count + 1);
                burst_fifo_write_count <= 0;
                completed_write_bursts <= completed_write_bursts + 1;
            end
        end
    end

    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。
    always @(posedge user_clk) begin
        // LocalLink 的 src_rdy 与 dst_rdy 同拍有效时，当前 64bit 字完成一次链路传输。
        if (user_rstn && tx_src_rdy && tx_dst_rdy)
            actual_words.push_back(tx_d);
    end

    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task automatic provide_burst(input integer frame_number);
        integer word_number;
        begin
            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (fdma_rareq === 1'b1);
            @(negedge fdma_clk);
            fdma_rbusy = 1'b1;
            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (dut.rd_state == 2'd2);
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (word_number = 0; word_number < WORDS_PER_BURST;
                 word_number = word_number + 1) begin
                @(negedge fdma_clk);
                fdma_rdata = {frame_number[31:0], word_number[31:0]};
                fdma_rvalid = 1'b1;
                do @(posedge fdma_clk); while (!(fdma_rvalid && fdma_rready));
            end
            @(negedge fdma_clk);
            fdma_rvalid = 1'b0;
            fdma_rbusy = 1'b0;
        end
    endtask

    integer i;
    reg [63:0] expected;
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat (20) @(posedge fdma_clk);
        @(negedge fdma_clk);
        fdma_rstn = 1'b1;
        user_rstn = 1'b1;
        // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
        wait (dut.wr_rst_busy === 1'b0 && dut.rd_rst_busy === 1'b0);
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat (2) @(posedge fdma_clk);
        channel_up = 1'b1;
        channel_up_fdma = 1'b1;

        provide_burst(0);
        provide_burst(1);

        // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
        wait (actual_words.size() >= 128);
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat (10) @(posedge user_clk);
        assert (completed_write_bursts == 2)
            // 未命中前面的互斥路径时，保持当前阶段的正常推进。
            else $fatal(1, "expected two completed FDMA bursts");
        assert (actual_words.size() == 128)
            // 未达到收尾条件时，保持本阶段输出并等待后续握手。
            else $fatal(1, "expected 128 LL words, got %0d", actual_words.size());
        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (i = 0; i < 128; i = i + 1) begin
            expected = {32'd0 + (i / 64), 32'd0 + (i % 64)};
            // 边界测试读出的数据字与期望值不一致时记录失败。
            if (actual_words[i] !== expected) begin
                failures = failures + 1;
                $error("word[%0d] expected=%016h actual=%016h",
                       i, expected, actual_words[i]);
            end
        end
        assert (actual_words[63] == 64'h00000000_0000003f);
        assert (actual_words[64] == 64'h00000001_00000000);
        // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
        if (failures != 0)
            $fatal(1, "TB_FAIL: %0d ordering errors", failures);
        $display("TB_PASS: fdma_tx_burst_boundary");
        $finish;
    end

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        #500000;
        $fatal(1, "TB_TIMEOUT state=%0d req=%b busy=%b ready=%b full=%b empty=%b wr_busy=%b rd_busy=%b actual=%0d",
               dut.rd_state, fdma_rareq, fdma_rbusy, fdma_rready,
               dut.fifo_full, dut.fifo_empty, dut.wr_rst_busy,
               dut.rd_rst_busy, actual_words.size());
    end
endmodule
