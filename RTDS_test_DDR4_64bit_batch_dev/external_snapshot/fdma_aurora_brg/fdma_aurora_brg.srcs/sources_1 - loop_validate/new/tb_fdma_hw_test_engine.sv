`timescale 1ns / 1ps
// File: tb_fdma_hw_test_engine.sv

module tb_fdma_hw_test_engine;
    // 固定 WORDS_PER_BURST 的传输规模，保证读写两侧按同一长度收尾。
    localparam integer WORDS_PER_BURST = 64;

    reg         fdma_clk = 1'b0;
    reg         fdma_rstn = 1'b0;
    reg         channel_up = 1'b1;
    reg         test_start = 1'b0;
    reg         test_clear = 1'b0;
    reg         auto_enable = 1'b0;
    reg  [15:0] frame_limit = 16'd16;
    reg  [31:0] fdma_raddr = 32'd0;
    reg         fdma_rareq = 1'b0;
    wire        fdma_rbusy;
    wire [63:0] fdma_rdata;
    wire        fdma_rvalid;
    reg         fdma_rready = 1'b0;
    reg  [31:0] fdma_waddr = 32'd0;
    reg         fdma_wareq = 1'b0;
    wire        fdma_wbusy;
    reg  [63:0] fdma_wdata = 64'd0;
    reg         fdma_wvalid = 1'b0;
    reg  [15:0] fdma_wsize = 16'd0;
    wire        fdma_wready;
    wire [256:0] dbg_bus;
    wire [187:0] status_dbg_bus;

    wire [31:0] hw_rd_word_total        = dbg_bus[256:225];
    wire [31:0] hw_wr_word_total        = dbg_bus[224:193];
    wire [15:0] hw_rd_burst_count       = dbg_bus[192:177];
    wire [15:0] hw_wr_burst_count       = dbg_bus[176:161];
    wire [31:0] hw_error_count          = dbg_bus[160:129];
    wire        hw_error_sticky         = dbg_bus[128];
    wire [63:0] hw_first_error_expected = dbg_bus[127:64];
    wire [63:0] hw_first_error_actual   = dbg_bus[63:0];

    integer failures = 0;

    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #2 fdma_clk = ~fdma_clk; // 250 MHz

    fdma_hw_test_engine #(
        .FRAME_BYTES(512),
        .BURST_BYTES(512),
        .AUTO_START_DELAY_CYCLES(32),
        .DRAIN_TIMEOUT_CYCLES(10000)
    ) dut (
        .fdma_clk(fdma_clk), .fdma_rstn(fdma_rstn),
        .channel_up(channel_up), .test_start(test_start),
        .test_clear(test_clear), .auto_enable(auto_enable),
        .frame_limit(frame_limit),
        .fdma_raddr(fdma_raddr), .fdma_rareq(fdma_rareq),
        .fdma_rbusy(fdma_rbusy), .fdma_rdata(fdma_rdata),
        .fdma_rvalid(fdma_rvalid), .fdma_rready(fdma_rready),
        .fdma_waddr(fdma_waddr), .fdma_wareq(fdma_wareq),
        .fdma_wbusy(fdma_wbusy), .fdma_wdata(fdma_wdata),
        .fdma_wvalid(fdma_wvalid), .fdma_wsize(fdma_wsize),
        .fdma_wready(fdma_wready), .dbg_bus(dbg_bus),
        .status_dbg_bus(status_dbg_bus)
    );

    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task automatic start_run(input integer frames);
        begin
            frame_limit = frames[15:0];
            // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
            repeat (3) @(posedge fdma_clk);
            @(negedge fdma_clk);
            test_start = 1'b1;
            @(negedge fdma_clk);
            test_start = 1'b0;
            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (status_dbg_bus[187] === 1'b1);
        end
    endtask

    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task automatic clear_run;
        begin
            @(negedge fdma_clk);
            test_clear = 1'b1;
            @(negedge fdma_clk);
            test_clear = 1'b0;
            // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
            repeat (2) @(posedge fdma_clk);
        end
    endtask

    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task automatic check(input bit condition, input string message);
        begin
            // 等待条件仍未满足时继续计时，超过上限后报错。
            if (!condition) begin
                failures = failures + 1;
                $error("CHECK FAILED: %s", message);
            end
        end
    endtask

    // 该 任务 模拟/驱动 FDMA 读侧行为，把期望数据送入 DUT。
    task automatic run_read_burst(input integer frame_number,
                                  input bit insert_stall);
        integer got;
        integer stall_cycles;
        reg [63:0] held_data;
        reg [63:0] expected;
        begin
            got = 0;
            fdma_raddr = frame_number * 512;
            @(negedge fdma_clk);
            fdma_rready = 1'b1;
            fdma_rareq = 1'b1;
            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (fdma_rbusy === 1'b1);
            @(negedge fdma_clk);
            fdma_rareq = 1'b0;

            while (got < WORDS_PER_BURST) begin
                @(posedge fdma_clk);
                // valid 与 ready 同拍有效时才消费或产生一个数据字。
                if (fdma_rvalid && fdma_rready) begin
                    expected = {frame_number[31:0], got[31:0]};
                    check(fdma_rdata === expected, "read data sequence");
                    got = got + 1;
                    // 收到第 8 个写回字时插入 ready 停顿，覆盖中途反压场景。
                    if (insert_stall && got == 8) begin
                        @(negedge fdma_clk);
                        held_data = fdma_rdata;
                        fdma_rready = 1'b0;
                        // 循环处理：逐项生成、检查或打印一组连续数据。
                        for (stall_cycles = 0; stall_cycles < 4; stall_cycles = stall_cycles + 1) begin
                            @(posedge fdma_clk);
                            check(fdma_rdata === held_data,
                                  "read data changed while rready was low");
                        end
                        @(negedge fdma_clk);
                        fdma_rready = 1'b1;
                    end
                end
            end

            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (fdma_rbusy === 1'b0);
            @(negedge fdma_clk);
            fdma_rready = 1'b0;
        end
    endtask

    // error_mode：0 表示正确数据，1 表示第 5 个数据字出错，2 表示第 0 和第 1 个数据字出错。
    // 该 任务 模拟/驱动 FDMA 写侧行为，并记录 DUT 写回的数据。
    task automatic run_write_burst(input integer frame_number,
                                   input integer error_mode);
        integer word_number;
        reg [63:0] value;
        begin
            fdma_waddr = frame_number * 512;
            fdma_wsize = 16'd512;
            @(negedge fdma_clk);
            fdma_wareq = 1'b1;
            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (fdma_wbusy === 1'b1);
            @(negedge fdma_clk);
            fdma_wareq = 1'b0;

            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (word_number = 0; word_number < WORDS_PER_BURST;
                 word_number = word_number + 1) begin
                // Drive on the falling edge so DUT sampling at the next rising
                // 边沿采样不得与测试平台后续数据字更新产生竞争。
                @(negedge fdma_clk);
                while (fdma_wready !== 1'b1)
                    @(negedge fdma_clk);
                value = {frame_number[31:0], word_number[31:0]};
                // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
                if ((error_mode == 1 && word_number == 5) ||
                    (error_mode == 2 && (word_number == 0 || word_number == 1)))
                    value = value ^ 64'd1;
                fdma_wdata = value;
                fdma_wvalid = 1'b1;
                @(posedge fdma_clk);
            end

            @(negedge fdma_clk);
            fdma_wvalid = 1'b0;
            fdma_wdata = 64'd0;
            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (fdma_wbusy === 1'b0);
        end
    endtask

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat (5) @(posedge fdma_clk);
        @(negedge fdma_clk);
        fdma_rstn = 1'b1;

        // 连续发送两个源突发，第二个突发包含 4 个停顿周期。
        start_run(2);
        run_read_burst(0, 1'b0);
        run_read_burst(1, 1'b1);
        check(hw_rd_word_total == 128, "read word total after two bursts");
        check(hw_rd_burst_count == 2, "read burst count after two bursts");
        clear_run();

        // 正确返回数据不得置位任何错误状态。
        start_run(4);
        run_write_burst(0, 0);
        check(hw_wr_word_total == 64, "write word total after correct burst");
        check(hw_error_count == 0, "error count after correct burst");
        check(!hw_error_sticky, "sticky error after correct burst");

        // 首次不匹配时只精确捕获一次期望值和实际值。
        run_write_burst(1, 1);
        check(hw_error_count == 1, "single mismatch count");
        check(hw_error_sticky, "sticky error was not set");
        check(hw_first_error_expected == {32'd1, 32'd5},
              "first expected data capture");
        check(hw_first_error_actual == ({32'd1, 32'd5} ^ 64'd1),
              "first actual data capture");

        // 把计数器置于接近最大值的位置，再验证递增和饱和行为。
        @(negedge fdma_clk);
        dut.hw_error_count = 32'hffff_fffe;
        run_write_burst(2, 2);
        check(hw_error_count == 32'hffff_ffff, "error counter saturation");
        check(hw_first_error_expected == {32'd1, 32'd5},
              "first expected data was overwritten");
        check(hw_first_error_actual == ({32'd1, 32'd5} ^ 64'd1),
              "first actual data was overwritten");

        run_write_burst(3, 0);
        // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
        wait (status_dbg_bus[186] === 1'b1);
        check(status_dbg_bus[186], "four-write run did not finish");
        check(status_dbg_bus[184:182] == 3'd3, "mismatch result code");
        clear_run();

        // 读写引擎同时活动时必须保持相互独立。
        start_run(1);
        fork
            run_read_burst(0, 1'b1);
            run_write_burst(0, 0);
        join
        // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
        wait (status_dbg_bus[186] === 1'b1);
        check(hw_rd_word_total == 64, "parallel read did not complete");
        check(hw_wr_word_total == 64, "parallel write did not complete");
        check(hw_rd_burst_count == 1, "parallel read burst count");
        check(hw_wr_burst_count == 1, "parallel write burst count");
        check(status_dbg_bus[185], "parallel correct run did not pass");

        // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
        if (failures == 0)
            $display("TB_PASS: fdma_hw_test_engine");
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else
            $fatal(1, "TB_FAIL: %0d checks failed", failures);
        $finish;
    end

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        #200000;
        $fatal(1, "TB_TIMEOUT");
    end
endmodule