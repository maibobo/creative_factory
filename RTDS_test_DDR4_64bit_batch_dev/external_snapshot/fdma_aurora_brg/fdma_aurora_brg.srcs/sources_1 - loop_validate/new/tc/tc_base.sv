`timescale 1ns / 1ps
// File: tc_base.sv

// 共享的非 UVM 验证 package。
// 提供确定性随机、FDMA BFM、监测器和 scoreboard。
package fdma_aurora_brg_tb_pkg;
    // 所有 testcase 和地址参考模型共用的协议常量。
    localparam int WORD_BYTES          = 8;    // One interface 数据字 contains eight bytes.
    localparam int FRAME_WORDS         = 64;   // One LL 帧 contains sixty-four 数据字.
    localparam int BURST_WORDS         = 64;   // One FDMA 突发 contains sixty-four 数据字.
    localparam int FDMA_BURST_BYTES    = 512;  // 每个 burst 后递增地址。
    localparam int TEST_MEM_SIZE_BYTES = 4096; // 地址模型在 4KB 边界回绕。
    // 直连 GUI 运行仅在调用方显式传入 0 seed 时使用该路径。
    localparam int DEFAULT_SEED        = 260622;

    typedef logic [63:0] data_queue_t[$]; // Queue type used for ordered 载荷 comparison.
    typedef logic [31:0] addr_queue_t[$]; // Queue type used for 请求-地址 checking.

    // 解析 GUI 和批处理仿真共用的运行期控制项。
    function automatic int unsigned resolve_seed(output string seed_source);
        int unsigned selected_seed;       // Temporary parsed or automatically generated value.
        if ($value$plusargs("SEED=%d", selected_seed)) begin
            seed_source = "PLUSARG";      // Record that the user supplied a replay seed.
            if ((selected_seed < 1) || (selected_seed > 999999))
                $fatal(1, "SEED must be a six-decimal-digit value in 000001..999999");
        end else begin
            seed_source = "AUTO";         // Record automatic GUI selection.
            selected_seed = $urandom_range(999999, 1); // Six decimal digits, excluding 零.
        end
        return selected_seed;
    endfunction

    function automatic int unsigned resolve_verbose();
        int unsigned selected_verbose;    // Temporary +VERBOSE value.
        if (!$value$plusargs("VERBOSE=%d", selected_verbose))
            selected_verbose = 1;         // Default to 帧/突发-level diagnostics.
        if (selected_verbose > 2)
            $fatal(1, "VERBOSE must be 0, 1, or 2");
        return selected_verbose;
    endfunction

    class tc_base;
        // =====================================================================
        // USER-CONFIGURABLE RANDOM DELAY PARAMETERS
        // =====================================================================
        // 单位为 fdma_clk 周期，min/max 为闭区间，prob 范围为 0 到 100。
        // prob=0 or enable_backpressure=0 disables the corresponding delay.
        // 派生测试用例可以覆盖 configure() 中的任意字段。
        int unsigned cfg_rd_accept_delay_min = 1; // rareq -> rbusy assertion
        int unsigned cfg_rd_accept_delay_max = 8;    // Inclusive maximum 响应延迟.
        int unsigned cfg_rd_accept_delay_prob = 30;  // Percentage of read 请求 delayed.
        int unsigned cfg_wr_accept_delay_min = 1; // wareq -> wbusy assertion
        int unsigned cfg_wr_accept_delay_max = 8;    // Inclusive maximum 响应延迟.
        int unsigned cfg_wr_accept_delay_prob = 30;  // Percentage of write 请求 delayed.
        int unsigned cfg_rd_inter_burst_gap_min = 1; // last read 数据字 -> rbusy release
        int unsigned cfg_rd_inter_burst_gap_max = 8;   // Inclusive maximum read completion gap.
        int unsigned cfg_rd_inter_burst_gap_prob = 30; // Percentage of read 突发 extended.
        int unsigned cfg_wr_inter_burst_gap_min = 1; // last write 数据字 -> wbusy release
        int unsigned cfg_wr_inter_burst_gap_max = 8;   // Inclusive maximum write completion gap.
        int unsigned cfg_wr_inter_burst_gap_prob = 30; // Percentage of write 突发 extended.
        int unsigned cfg_rd_valid_gap_min = 1; // rvalid-low 周期 before a 数据字
        int unsigned cfg_rd_valid_gap_max = 4;    // Inclusive maximum rvalid-low interval.
        int unsigned cfg_rd_valid_gap_prob = 20;  // Percentage of read 数据字 preceded by a gap.
        int unsigned cfg_wr_ready_stall_min = 1; // wready-low 周期 for a 数据字
        int unsigned cfg_wr_ready_stall_max = 4;   // Inclusive maximum wready-low interval.
        int unsigned cfg_wr_ready_stall_prob = 20; // Percentage of write 数据字 停顿ed.

        string test_name;              // Name printed in logs and PASS/FAIL markers.
        int unsigned seed;             // Six-digit decimal replay seed.
        int unsigned rng_state;        // Private LCG 状态 advanced in one deterministic 线程.
        int unsigned verbose;          // 0=summary, 1=plan/frame, 2=every handshake.
        int unsigned num_frames;       // 帧 选择 by the derived 配置() method.
        int unsigned total_words;      // num_帧 multiplied by 帧_数据字S.
        bit enable_backpressure;       // Master switch for all 公共 random delays.
        bit stop_requested;            // 请求 all forever-running BFM 任务s to exit.
        bit fdma_x_reported;            // Prevent repeated FDMA X/Z messages.
        bit ll_x_reported;              // Prevent repeated LL X/Z messages.
        int error_count;                // Non零 makes the 顶层 issue $fatal.

        virtual fdma_read_if  rd_vif;   // 句柄 to harness read interface instance.
        virtual fdma_write_if wr_vif;   // 句柄 to harness write interface instance.
        virtual ll_link_if    ll_vif;   // 句柄 to harness LocalLink interface instance.
        virtual brg_ctrl_if   ctrl_vif; // 句柄 to verification-only 控制信号.
        virtual brg_obs_if    obs_vif;  // 句柄 to read-only DUT probe.

        // One queue per protocol boundary makes the first corrupting stage visible.
        data_queue_t expected_q;        // Random 源 data generated before traffic starts.
        data_queue_t fdma_rd_hs_q;      // Data 已接受 at the FDMA read 握手.
        data_queue_t tx_fifo_wr_q;      // Data written into the TX FIFO.
        data_queue_t tx_fifo_rd_q;      // Data removed from the TX FIFO.
        data_queue_t ll_tx_q;           // Data transferred at the LL TX boundary.
        data_queue_t ll_rx_q;           // Data transferred at the LL RX boundary.
        data_queue_t rx_fifo_wr_q;      // Data written into the RX FIFO.
        data_queue_t rx_fifo_rd_q;      // Data removed from the RX FIFO.
        data_queue_t fdma_wr_hs_q;      // Data 已接受 by the FDMA write BFM.
        addr_queue_t fdma_rd_addr_q;    // Read 地址es captured once per 请求.
        addr_queue_t fdma_wr_addr_q;    // Write 地址es captured once per 请求.

        int unsigned rd_accept_delay[];     // One read 响应延迟 per 帧/突发.
        int unsigned wr_accept_delay[];     // One write 响应延迟 per 帧/突发.
        int unsigned rd_inter_burst_gap[];  // One rbusy-release delay per 突发.
        int unsigned wr_inter_burst_gap[];  // One wbusy-release delay per 突发.
        int unsigned rd_valid_gap[];        // One optional rvalid gap per 源 数据字.
        int unsigned wr_ready_stall[];      // One optional wready 停顿 per sink 数据字.

        int unsigned tx_frame_word_count; // Current 数据字 position in the LL TX 帧.
        int unsigned rx_frame_word_count; // Current 数据字 position in the LL RX 帧.
        int unsigned tx_frame_count;      // 已完成的 LL TX 帧数。
        int unsigned rx_frame_count;      // 已完成的 LL RX 帧数。
        int unsigned tx_fifo_peak;        // Largest 观测到 TX FIFO count.
        int unsigned rx_fifo_peak;        // Largest 观测到 RX FIFO count.

        function new(
            string name,
            int unsigned seed_i,
            int unsigned verbose_i,
            virtual fdma_read_if rd_vif_i,
            virtual fdma_write_if wr_vif_i,
            virtual ll_link_if ll_vif_i,
            virtual brg_ctrl_if ctrl_vif_i,
            virtual brg_obs_if obs_vif_i
        );
            test_name = name;                                   // Save 派生测试用例 name.
            seed = (seed_i == 0) ? DEFAULT_SEED : seed_i;       // Guard against a 零 seed.
            rng_state = seed;                                  // Initialize deterministic LCG.
            verbose = verbose_i;                               // Save print-level selection.
            rd_vif = rd_vif_i;                                 // 绑定读接口句柄。
            wr_vif = wr_vif_i;                                 // 绑定写接口句柄。
            ll_vif = ll_vif_i;                                 // 绑定 LL 接口句柄。
            ctrl_vif = ctrl_vif_i;                             // 绑定 harness 控制句柄。
            obs_vif = obs_vif_i;                               // 绑定观测句柄。
            enable_backpressure = 1'b0;                        // Derived 配置() opts in.
            stop_requested = 1'b0;                             // 后台线程初始运行。
            error_count = 0;                                   // Start with a passing 结果.
        endfunction

        // Local LCG: the same six-digit seed always produces the same full plan.
        function int unsigned next_rand();
            rng_state = (rng_state * 32'd1664525) + 32'd1013904223; // Numerical Recipes LCG.
            return rng_state;
        endfunction

        function int unsigned rand_range(int unsigned low, int unsigned high);
            if (high <= low)
                return low;
            return low + (next_rand() % (high - low + 1));
        endfunction

        // 不使用约束随机语法，按配置选择延迟。
        function int unsigned choose_delay(
            int unsigned probability,
            int unsigned minimum,
            int unsigned maximum
        );
            if (!enable_backpressure || (probability == 0))
                return 0;
            if (rand_range(1, 100) <= probability)
                return rand_range(minimum, maximum);
            return 0;
        endfunction

        virtual function void configure();
            num_frames = rand_range(1, 3); // Default ordinary-test 帧 range.
            enable_backpressure = 1'b0;   // Default is an un停顿ed transfer.
        endfunction

        // 公共 BFM 执行前后的可选直连测试钩子。
        virtual task pre_start();
        endtask

        virtual task after_channel_up();
        endtask

        virtual function void apply_directed_plan();
        endfunction

        virtual task on_read_word_presented(int unsigned global_word_index);
        endtask

        // 并发 BFM 线程启动前生成全部数据和延迟决策。
        function void build_random_plan();
            logic [63:0] word_data;
            int unsigned i;

            total_words = num_frames * FRAME_WORDS; // Fix all array sizes before fork.
            expected_q.delete();                    // Remove data from any prior invocation.
            rd_accept_delay = new[num_frames];
            wr_accept_delay = new[num_frames];
            rd_inter_burst_gap = new[num_frames];
            wr_inter_burst_gap = new[num_frames];
            rd_valid_gap = new[total_words];
            wr_ready_stall = new[total_words];

            for (i = 0; i < total_words; i++) begin
                word_data = {next_rand(), next_rand()}; // Form one random 64-bit 载荷.
                expected_q.push_back(word_data);        // Preserve 源 order for scoreboard.
            end

            for (i = 0; i < num_frames; i++) begin
                rd_accept_delay[i] = choose_delay(cfg_rd_accept_delay_prob,
                                                   cfg_rd_accept_delay_min,
                                                   cfg_rd_accept_delay_max);
                wr_accept_delay[i] = choose_delay(cfg_wr_accept_delay_prob,
                                                   cfg_wr_accept_delay_min,
                                                   cfg_wr_accept_delay_max);
                rd_inter_burst_gap[i] = choose_delay(cfg_rd_inter_burst_gap_prob,
                                                      cfg_rd_inter_burst_gap_min,
                                                      cfg_rd_inter_burst_gap_max);
                wr_inter_burst_gap[i] = choose_delay(cfg_wr_inter_burst_gap_prob,
                                                      cfg_wr_inter_burst_gap_min,
                                                      cfg_wr_inter_burst_gap_max);
            end

            for (i = 0; i < total_words; i++) begin
                rd_valid_gap[i] = choose_delay(cfg_rd_valid_gap_prob,
                                                cfg_rd_valid_gap_min,
                                                cfg_rd_valid_gap_max);
                wr_ready_stall[i] = choose_delay(cfg_wr_ready_stall_prob,
                                                  cfg_wr_ready_stall_min,
                                                  cfg_wr_ready_stall_max);
            end

            apply_directed_plan(); // Give a derived TC the final chance to alter the plan.
        endfunction

        task record_error(string message);
            error_count++; // Preserve 每次 failure while continuing to collect diagnostics.
            $error("[%0t] [%s] %s", $time, test_name, message);
        endtask

        // 把测试平台驱动的每个信号置为已知空闲值。
        task initialize_drivers();
            rd_vif.cb.rbusy <= 1'b0;               // No 读事务 is 活动.
            rd_vif.cb.rdata <= '0;                 // 无效周期内避免 X 载荷。
            rd_vif.cb.rvalid <= 1'b0;              // No read 数据字 is presented.
            wr_vif.cb.wbusy <= 1'b0;               // No 写事务 is 活动.
            wr_vif.cb.wready <= 1'b0;              // Do not accept data before wareq.
            ctrl_vif.force_tx_almost_full <= 1'b0; // Disable 直连 TX force.
            ctrl_vif.rx_loopback_enable <= 1'b1;   // Default to normal bridge loopback.
            ctrl_vif.rx_drive_d <= '0;             // 清除直连 RX 载荷。
            ctrl_vif.cfg_tx_burst_limit <= 16'd0;
            ctrl_vif.rx_drive_sof <= 1'b0;         // 清除直连 SOF。
            ctrl_vif.rx_drive_eof <= 1'b0;         // 清除直连 EOF。
            ctrl_vif.rx_drive_rem <= 3'b111;       // Default 直连 载荷 is full width.
            ctrl_vif.rx_drive_src_rdy <= 1'b0;     // Disable 直连 RX 注入.
            if (ctrl_vif.can_drive_tx_dst_rdy)
                ll_vif.tx_dst_rdy <= 1'b1;
        endtask

        task wait_for_channel_up();
            int unsigned cycles; // 统计 fdma_clk 边沿直到链路就绪。
            cycles = 0;          // Start 超时 measurement at 零.
            while ((obs_vif.channel_up !== 1'b1) && (cycles < 500000)) begin
                @(posedge rd_vif.clk);
                cycles++;        // 推进 500000 周期超时计数。
            end
            if (obs_vif.channel_up !== 1'b1)
                record_error("channel_up timeout");
            else
                $display("[%0t] [%s] channel_up after %0d fdma_clk cycles", $time, test_name, cycles);
        endtask

        // FDMA 读从机接受 DUT 读请求，每个突发返回 64 个数据字。
        task fdma_read_slave();
            int unsigned burst_idx;  // 帧/突发 currently being supplied.
            int unsigned word_idx;   // 数据字 position inside the current 突发.
            int unsigned global_idx; // Flat 索引 into 期望 and delay arrays.

            burst_idx = 0; // 地址和载荷处理从 burst 0 开始。
            while (!stop_requested && (burst_idx < num_frames)) begin
                @(rd_vif.cb);
                while (!stop_requested &&
                       !((rd_vif.cb.rareq === 1'b1) && (rd_vif.rbusy === 1'b0)))
                    @(rd_vif.cb);
                if (stop_requested)
                    return;

                fdma_rd_addr_q.push_back(rd_vif.cb.raddr); // 每个请求捕获一个地址。
                if (verbose >= 1)
                    $display("[STIM][RD_REQ] burst=%0d addr=0x%08h accept_delay=%0d",
                             burst_idx, rd_vif.cb.raddr, rd_accept_delay[burst_idx]);
                repeat (rd_accept_delay[burst_idx]) @(rd_vif.cb);

                rd_vif.cb.rbusy <= 1'b1; // 配置的响应延迟结束后接受 rareq。
                @(rd_vif.cb);

                for (word_idx = 0; word_idx < BURST_WORDS; word_idx++) begin
                    global_idx = burst_idx * BURST_WORDS + word_idx; // 转换为扁平源索引。
                    repeat (rd_valid_gap[global_idx]) begin
                        rd_vif.cb.rvalid <= 1'b0; // Insert the 选择 read-data bubble.
                        @(rd_vif.cb);
                    end

                    rd_vif.cb.rdata <= expected_q[global_idx]; // Hold this value until 握手.
                    rd_vif.cb.rvalid <= 1'b1;                  // Present the 选择 源 数据字.
                    if (verbose >= 2)
                        $display("[STIM][RD_DATA] word=%0d data=0x%016h gap=%0d",
                                 global_idx, expected_q[global_idx], rd_valid_gap[global_idx]);
                    on_read_word_presented(global_idx);

                    @(rd_vif.cb);
                    while (!stop_requested &&
                           !((rd_vif.rvalid === 1'b1) && (rd_vif.cb.rready === 1'b1)))
                        @(rd_vif.cb);
                    if (stop_requested)
                        return;
                end

                rd_vif.cb.rvalid <= 1'b0; // End the sixty-four-word read burst.
                rd_vif.cb.rdata <= '0;    // 清除无效载荷，便于查看波形。
                repeat (rd_inter_burst_gap[burst_idx] + 1) @(rd_vif.cb);
                rd_vif.cb.rbusy <= 1'b0; // Release the transaction after inter-突发 gap.
                burst_idx++;             // Wait for the next DUT rareq.
            end

            while (!stop_requested)
                @(rd_vif.cb);
        endtask

        task check_write_data_stable(int unsigned stall_cycles);
            logic [63:0] held_data; // First wdata value 观测到 while 就绪 is low.
            int unsigned i;         // Number of checked 停顿 周期.

            while (!stop_requested && (wr_vif.cb.wvalid !== 1'b1))
                @(wr_vif.cb);
            if (stop_requested)
                return;

            held_data = wr_vif.cb.wdata; // 后续所有停顿周期都必须保持该数据字。
            for (i = 0; i < stall_cycles; i++) begin
                @(wr_vif.cb);
                if (wr_vif.cb.wvalid !== 1'b1)
                    record_error("wvalid dropped while wready was low");
                if (wr_vif.cb.wdata !== held_data)
                    record_error("wdata changed while wready was low");
            end
        endtask

        // FDMA 写从机接受 DUT 写请求，并按计划插入 wready 停顿。
        task fdma_write_slave();
            int unsigned burst_idx;   // 帧/突发 currently being 已接受.
            int unsigned word_idx;    // 数据字 position inside that 突发.
            int unsigned global_idx;  // Flat scoreboard/delay-array 索引.
            int unsigned stall_cycles;// 选择 wready-low duration for this 数据字.

            burst_idx = 0; // Begin with the zero-address write burst.
            while (!stop_requested && (burst_idx < num_frames)) begin
                @(wr_vif.cb);
                while (!stop_requested &&
                       !((wr_vif.cb.wareq === 1'b1) && (wr_vif.wbusy === 1'b0)))
                    @(wr_vif.cb);
                if (stop_requested)
                    return;

                fdma_wr_addr_q.push_back(wr_vif.cb.waddr); // 每个写请求捕获一个地址。
                if (verbose >= 1)
                    $display("[STIM][WR_REQ] burst=%0d addr=0x%08h accept_delay=%0d",
                             burst_idx, wr_vif.cb.waddr, wr_accept_delay[burst_idx]);
                if (wr_vif.cb.wsize !== FDMA_BURST_BYTES)
                    record_error($sformatf("unexpected wsize=%0d", wr_vif.cb.wsize));

                repeat (wr_accept_delay[burst_idx]) @(wr_vif.cb);
                wr_vif.cb.wbusy <= 1'b1; // 配置的响应延迟结束后接受 wareq。

                for (word_idx = 0; word_idx < BURST_WORDS; word_idx++) begin
                    global_idx = burst_idx * BURST_WORDS + word_idx; // Flat sink 索引.
                    stall_cycles = wr_ready_stall[global_idx];       // Look up this 数据字's 停顿.

                    if (stall_cycles == 0) begin
                        wr_vif.cb.wready <= 1'b1; // 未选择停顿时立即接受。
                    end else begin
                        wr_vif.cb.wready <= 1'b0; // 施加写侧反压。
                        @(wr_vif.cb);             // 让 clocking block 输出低电平先生效，再检查保持。
                        check_write_data_stable(stall_cycles);
                        wr_vif.cb.wready <= 1'b1; // Release the held 数据字 after stability checks.
                    end

                    @(wr_vif.cb);
                    while (!stop_requested &&
                           !((wr_vif.cb.wvalid === 1'b1) && (wr_vif.wready === 1'b1)))
                        @(wr_vif.cb);
                    if (stop_requested)
                        return;
                    if (verbose >= 2)
                        $display("[CHECK][WR_DATA] word=%0d actual=0x%016h stall=%0d",
                                 global_idx, wr_vif.cb.wdata, stall_cycles);
                end

                repeat (wr_inter_burst_gap[burst_idx] + 1) @(wr_vif.cb);
                wr_vif.cb.wbusy <= 1'b0; // End the transaction after its configured gap.
                wr_vif.cb.wready <= 1'b0;// Return the sink to idle between 突发.
                burst_idx++;             // Wait for the next DUT wareq.
            end

            while (!stop_requested)
                @(wr_vif.cb);
        endtask

        // FDMA 时钟域监测握手、FIFO 边界、X/Z 和错误标志。
        task monitor_fdma_and_fifos();
            if (verbose >= 1)
                $display("[MON][FDMA][ACTIVE][TIME=%0t][PATH=%m][COMP=monitor_fdma_and_fifos][SRC=tc_base.sv:402] monitor started",
                         $time);
            forever begin
                @(posedge rd_vif.clk);
                if (rd_vif.rst_n) begin
                    if (!fdma_x_reported &&
                        $isunknown({rd_vif.rareq, rd_vif.rbusy, rd_vif.rvalid,
                                    rd_vif.rready, wr_vif.wareq, wr_vif.wbusy,
                                    wr_vif.wvalid, wr_vif.wready})) begin
                        record_error("X/Z on FDMA control signals");
                        fdma_x_reported = 1'b1;
                    end
                    if ((rd_vif.rvalid === 1'b1) && (rd_vif.rready === 1'b1)) begin
                        if ($isunknown({rd_vif.rdata, rd_vif.raddr}))
                            record_error("X/Z on FDMA read handshake");
                        fdma_rd_hs_q.push_back(rd_vif.rdata);
                        if (verbose >= 2)
                            $display("[MON][FDMA_RD][TIME=%0t][PATH=%m][COMP=FDMA_RD][SRC=tc_base.sv:419] index=%0d addr=%08h data=%016h",
                                     $time, fdma_rd_hs_q.size()-1, rd_vif.raddr, rd_vif.rdata);
                    end
                    if (obs_vif.tx_fifo_wr_en) begin
                        tx_fifo_wr_q.push_back(obs_vif.tx_fifo_wdata);
                        if (verbose >= 2)
                            $display("[MON][TX_FIFO_WR][TIME=%0t][PATH=%m][COMP=TX_FIFO_WR][SRC=tc_base.sv:425] index=%0d data=%016h count=%0d",
                                     $time, tx_fifo_wr_q.size()-1, obs_vif.tx_fifo_wdata, obs_vif.tx_fifo_wr_cnt);
                    end
                    if (obs_vif.rx_fifo_rd_en) begin
                        rx_fifo_rd_q.push_back(obs_vif.rx_fifo_rdata);
                        if (verbose >= 2)
                            $display("[MON][RX_FIFO_RD][TIME=%0t][PATH=%m][COMP=RX_FIFO_RD][SRC=tc_base.sv:431] index=%0d data=%016h count=%0d",
                                     $time, rx_fifo_rd_q.size()-1, obs_vif.rx_fifo_rdata, obs_vif.rx_fifo_rd_cnt);
                    end
                    if ((wr_vif.wvalid === 1'b1) && (wr_vif.wready === 1'b1)) begin
                        if ($isunknown({wr_vif.wdata, wr_vif.waddr}))
                            record_error("X/Z on FDMA write handshake");
                        fdma_wr_hs_q.push_back(wr_vif.wdata);
                        if (verbose >= 2)
                            $display("[MON][FDMA_WR][TIME=%0t][PATH=%m][COMP=FDMA_WR][SRC=tc_base.sv:439] index=%0d addr=%08h data=%016h",
                                     $time, fdma_wr_hs_q.size()-1, wr_vif.waddr, wr_vif.wdata);
                    end

                    if (obs_vif.tx_fifo_wr_cnt > tx_fifo_peak)
                        tx_fifo_peak = obs_vif.tx_fifo_wr_cnt;
                    if (obs_vif.rx_fifo_rd_cnt > rx_fifo_peak)
                        rx_fifo_peak = obs_vif.rx_fifo_rd_cnt;

                    if (obs_vif.tx_fifo_overflow)
                        record_error("unexpected TX FIFO overflow");
                    if (obs_vif.tx_fifo_underflow)
                        record_error("unexpected TX FIFO underflow");
                    if (obs_vif.rx_fifo_overflow)
                        record_error("unexpected RX FIFO overflow");
                    if (obs_vif.rx_fifo_underflow)
                        record_error("unexpected RX FIFO underflow");
                end
            end
        endtask

        task check_frame_markers(
            string direction,
            int unsigned word_in_frame,
            logic sof,
            logic eof,
            logic [2:0] rem
        );
            if (sof !== (word_in_frame == 0))
                record_error($sformatf("%s SOF error at frame word %0d", direction, word_in_frame));
            if (eof !== (word_in_frame == FRAME_WORDS-1))
                record_error($sformatf("%s EOF error at frame word %0d", direction, word_in_frame));
            if ((word_in_frame == FRAME_WORDS-1) && (rem !== 3'b111))
                record_error($sformatf("%s REM error: %b", direction, rem));
        endtask

        // user_clk 时钟域监测 LocalLink 帧标记和两个 FIFO 用户侧端口。
        task monitor_ll_and_rx_fifo();
            if (verbose >= 1)
                $display("[MON][LL][ACTIVE][TIME=%0t][PATH=%m][COMP=monitor_ll_and_rx_fifo][SRC=tc_base.sv:478] monitor started",
                         $time);
            forever begin
                @(ll_vif.mon_cb);
                if (ll_vif.rst_n) begin
                    if (!ll_x_reported &&
                        $isunknown({ll_vif.mon_cb.tx_sof, ll_vif.mon_cb.tx_eof,
                                    ll_vif.mon_cb.tx_rem, ll_vif.mon_cb.tx_src_rdy,
                                    ll_vif.mon_cb.tx_dst_rdy, ll_vif.mon_cb.rx_sof,
                                    ll_vif.mon_cb.rx_eof, ll_vif.mon_cb.rx_rem,
                                    ll_vif.mon_cb.rx_src_rdy, ll_vif.mon_cb.rx_dst_rdy})) begin
                        record_error("X/Z on LocalLink control signals");
                        ll_x_reported = 1'b1;
                    end
                    if ((ll_vif.mon_cb.tx_src_rdy === 1'b1) &&
                        (ll_vif.mon_cb.tx_dst_rdy === 1'b1)) begin
                        if ($isunknown(ll_vif.mon_cb.tx_d))
                            record_error("X/Z on LL TX handshake");
                        check_frame_markers("LL_TX", tx_frame_word_count,
                                            ll_vif.mon_cb.tx_sof,
                                            ll_vif.mon_cb.tx_eof,
                                            ll_vif.mon_cb.tx_rem);
                        ll_tx_q.push_back(ll_vif.mon_cb.tx_d);
                        if (verbose >= 2)
                            $display("[MON][LL_TX][TIME=%0t][PATH=%m][COMP=LL_TX][SRC=tc_base.sv:502] index=%0d data=%016h sof=%b eof=%b rem=%b",
                                     $time, ll_tx_q.size()-1, ll_vif.mon_cb.tx_d,
                                     ll_vif.mon_cb.tx_sof, ll_vif.mon_cb.tx_eof, ll_vif.mon_cb.tx_rem);
                        if (tx_frame_word_count == FRAME_WORDS-1) begin
                            tx_frame_word_count = 0;
                            tx_frame_count++;
                        end else begin
                            tx_frame_word_count++;
                        end
                    end

                    if (obs_vif.tx_fifo_rd_en) begin
                        tx_fifo_rd_q.push_back(obs_vif.tx_fifo_rdata);
                        if (verbose >= 2)
                            $display("[MON][TX_FIFO_RD][TIME=%0t][PATH=%m][COMP=TX_FIFO_RD][SRC=tc_base.sv:516] index=%0d data=%016h count=%0d",
                                     $time, tx_fifo_rd_q.size()-1, obs_vif.tx_fifo_rdata, obs_vif.tx_fifo_rd_cnt);
                    end

                    if ((ll_vif.mon_cb.rx_src_rdy === 1'b1) &&
                        (ll_vif.mon_cb.rx_dst_rdy === 1'b1)) begin
                        if ($isunknown(ll_vif.mon_cb.rx_d))
                            record_error("X/Z on LL RX handshake");
                        check_frame_markers("LL_RX", rx_frame_word_count,
                                            ll_vif.mon_cb.rx_sof,
                                            ll_vif.mon_cb.rx_eof,
                                            ll_vif.mon_cb.rx_rem);
                        ll_rx_q.push_back(ll_vif.mon_cb.rx_d);
                        if (verbose >= 2)
                            $display("[MON][LL_RX][TIME=%0t][PATH=%m][COMP=LL_RX][SRC=tc_base.sv:530] index=%0d data=%016h sof=%b eof=%b rem=%b",
                                     $time, ll_rx_q.size()-1, ll_vif.mon_cb.rx_d,
                                     ll_vif.mon_cb.rx_sof, ll_vif.mon_cb.rx_eof, ll_vif.mon_cb.rx_rem);
                        if (rx_frame_word_count == FRAME_WORDS-1) begin
                            rx_frame_word_count = 0;
                            rx_frame_count++;
                        end else begin
                            rx_frame_word_count++;
                        end
                    end

                    if (obs_vif.rx_fifo_wr_en) begin
                        rx_fifo_wr_q.push_back(obs_vif.rx_fifo_wdata);
                        if (verbose >= 2)
                            $display("[MON][RX_FIFO_WR][TIME=%0t][PATH=%m][COMP=RX_FIFO_WR][SRC=tc_base.sv:544] index=%0d data=%016h count=%0d",
                                     $time, rx_fifo_wr_q.size()-1, obs_vif.rx_fifo_wdata, obs_vif.rx_fifo_wr_cnt);
                    end
                    if (obs_vif.rx_fifo_wr_cnt > rx_fifo_peak)
                        rx_fifo_peak = obs_vif.rx_fifo_wr_cnt;
                end
            end
        endtask

        task wait_for_completion();
            int unsigned cycles;
            int unsigned max_cycles;

            cycles = 0;
            max_cycles = obs_vif.is_full_loop ? 500000 : 100000;
            while ((fdma_wr_hs_q.size() < total_words) && (cycles < max_cycles)) begin
                @(posedge rd_vif.clk);
                cycles++;
            end

            if (fdma_wr_hs_q.size() < total_words)
                record_error($sformatf("completion timeout: got %0d/%0d FDMA write words",
                                       fdma_wr_hs_q.size(), total_words));
            else
                repeat (100) @(ll_vif.mon_cb);
        endtask

        task compare_data_queues(input string lhs_name, ref data_queue_t lhs,
                                 input string rhs_name, ref data_queue_t rhs);
            int unsigned i;
            int unsigned min_size;
            bit mismatch_reported;
            bit length_mismatch;

            mismatch_reported = 1'b0;
            length_mismatch = (lhs.size() != rhs.size());
            if (length_mismatch)
                record_error($sformatf("%s/%s length mismatch: %0d/%0d",
                                       lhs_name, rhs_name, lhs.size(), rhs.size()));

            min_size = (lhs.size() < rhs.size()) ? lhs.size() : rhs.size();
            for (i = 0; i < min_size; i++) begin
                if ((lhs[i] !== rhs[i]) && !mismatch_reported) begin
                    record_error($sformatf("%s/%s first mismatch at %0d: %016h/%016h",
                                           lhs_name, rhs_name, i, lhs[i], rhs[i]));
                    mismatch_reported = 1'b1;
                end
            end
            if (verbose >= 1) begin
                if (min_size == 0)
                    $display("[COMPARE] %s/%s size=%0d/%0d empty",
                             lhs_name, rhs_name, lhs.size(), rhs.size());
                else
                    $display("[COMPARE] %s/%s size=%0d/%0d first=%016h/%016h last=%016h/%016h status=%s",
                             lhs_name, rhs_name, lhs.size(), rhs.size(),
                             lhs[0], rhs[0], lhs[min_size-1], rhs[min_size-1],
                             (length_mismatch || mismatch_reported) ? "FAIL" : "PASS");
            end
        endtask

        task check_addresses();
            logic [31:0] expected_addr;
            int unsigned i;

            if (fdma_rd_addr_q.size() != num_frames)
                record_error($sformatf("read address count %0d, expected %0d",
                                       fdma_rd_addr_q.size(), num_frames));
            if (fdma_wr_addr_q.size() != num_frames)
                record_error($sformatf("write address count %0d, expected %0d",
                                       fdma_wr_addr_q.size(), num_frames));

            expected_addr = 32'd0;
            for (i = 0; i < num_frames; i++) begin
                if ((i < fdma_rd_addr_q.size()) && (fdma_rd_addr_q[i] !== expected_addr))
                    record_error($sformatf("read address[%0d]=%08h, expected %08h",
                                           i, fdma_rd_addr_q[i], expected_addr));
                if ((i < fdma_wr_addr_q.size()) && (fdma_wr_addr_q[i] !== expected_addr))
                    record_error($sformatf("write address[%0d]=%08h, expected %08h",
                                           i, fdma_wr_addr_q[i], expected_addr));
                if (verbose >= 1)
                    $display("[ADDR] burst=%0d expected=0x%08h read=0x%08h write=0x%08h",
                             i, expected_addr,
                             (i < fdma_rd_addr_q.size()) ? fdma_rd_addr_q[i] : 32'hxxxxxxxx,
                             (i < fdma_wr_addr_q.size()) ? fdma_wr_addr_q[i] : 32'hxxxxxxxx);

                if (expected_addr + FDMA_BURST_BYTES >= TEST_MEM_SIZE_BYTES)
                    expected_addr = 32'd0;
                else
                    expected_addr = expected_addr + FDMA_BURST_BYTES;
            end
        endtask

        // End-of-test scoreboard: compare every boundary, address and frame count.
        task check_results();
            compare_data_queues("expected", expected_q, "fdma_rd_hs", fdma_rd_hs_q);
            compare_data_queues("fdma_rd_hs", fdma_rd_hs_q, "tx_fifo_wr", tx_fifo_wr_q);
            compare_data_queues("tx_fifo_wr", tx_fifo_wr_q, "tx_fifo_rd", tx_fifo_rd_q);
            compare_data_queues("tx_fifo_rd", tx_fifo_rd_q, "ll_tx", ll_tx_q);
            compare_data_queues("ll_tx", ll_tx_q, "ll_rx", ll_rx_q);
            compare_data_queues("ll_rx", ll_rx_q, "rx_fifo_wr", rx_fifo_wr_q);
            compare_data_queues("rx_fifo_wr", rx_fifo_wr_q, "rx_fifo_rd", rx_fifo_rd_q);
            compare_data_queues("rx_fifo_rd", rx_fifo_rd_q, "fdma_wr_hs", fdma_wr_hs_q);
            compare_data_queues("expected", expected_q, "fdma_wr_hs", fdma_wr_hs_q);
            check_addresses();

            if (tx_frame_count != num_frames)
                record_error($sformatf("TX frame count %0d, expected %0d", tx_frame_count, num_frames));
            if (rx_frame_count != num_frames)
                record_error($sformatf("RX frame count %0d, expected %0d", rx_frame_count, num_frames));
            if ((tx_frame_word_count != 0) || (rx_frame_word_count != 0))
                record_error("partial LL frame remained at end of test");
        endtask

        task print_configuration();
            int unsigned rd_delay_total;
            int unsigned wr_delay_total;
            int unsigned rd_inter_total;
            int unsigned wr_inter_total;
            int unsigned rd_gap_total;
            int unsigned wr_stall_total;
            int unsigned i;

            rd_delay_total = 0;
            wr_delay_total = 0;
            rd_gap_total = 0;
            wr_stall_total = 0;
            rd_inter_total = 0;
            wr_inter_total = 0;
            for (i = 0; i < num_frames; i++) begin
                rd_delay_total += rd_accept_delay[i];
                wr_delay_total += wr_accept_delay[i];
                rd_inter_total += rd_inter_burst_gap[i];
                wr_inter_total += wr_inter_burst_gap[i];
            end
            for (i = 0; i < total_words; i++) begin
                rd_gap_total += rd_valid_gap[i];
                wr_stall_total += wr_ready_stall[i];
            end

            $display("============================================================");
            $display("TESTCASE=%s SEED=%06d FRAMES=%0d WORDS=%0d VERBOSE=%0d", test_name, seed,
                     num_frames, total_words, verbose);
            $display("[CFG] rd_accept=%0d..%0d@%0d%% wr_accept=%0d..%0d@%0d%%",
                     cfg_rd_accept_delay_min, cfg_rd_accept_delay_max, cfg_rd_accept_delay_prob,
                     cfg_wr_accept_delay_min, cfg_wr_accept_delay_max, cfg_wr_accept_delay_prob);
            $display("[CFG] rd_inter=%0d..%0d@%0d%% wr_inter=%0d..%0d@%0d%%",
                     cfg_rd_inter_burst_gap_min, cfg_rd_inter_burst_gap_max, cfg_rd_inter_burst_gap_prob,
                     cfg_wr_inter_burst_gap_min, cfg_wr_inter_burst_gap_max, cfg_wr_inter_burst_gap_prob);
            $display("[CFG] rvalid_gap=%0d..%0d@%0d%% wready_stall=%0d..%0d@%0d%%",
                     cfg_rd_valid_gap_min, cfg_rd_valid_gap_max, cfg_rd_valid_gap_prob,
                     cfg_wr_ready_stall_min, cfg_wr_ready_stall_max, cfg_wr_ready_stall_prob);
            $display("[CFG_TOTAL] rd_accept=%0d wr_accept=%0d rd_inter=%0d wr_inter=%0d rvalid_gap=%0d wready_stall=%0d",
                     rd_delay_total, wr_delay_total, rd_inter_total, wr_inter_total,
                     rd_gap_total, wr_stall_total);
            if (verbose >= 1) begin
                for (i = 0; i < num_frames; i++) begin
                    $display("  FRAME[%0d] rd_accept=%0d wr_accept=%0d rd_inter=%0d wr_inter=%0d first=%016h last=%016h",
                             i, rd_accept_delay[i], wr_accept_delay[i],
                             rd_inter_burst_gap[i], wr_inter_burst_gap[i],
                             expected_q[i*FRAME_WORDS], expected_q[(i+1)*FRAME_WORDS-1]);
                end
                for (i = 0; i < total_words; i++) begin
                    if ((rd_valid_gap[i] != 0) || (wr_ready_stall[i] != 0))
                        $display("  WORD[%0d] rvalid_gap=%0d wready_stall=%0d",
                                 i, rd_valid_gap[i], wr_ready_stall[i]);
                end
            end
            $display("============================================================");
        endtask

        // 公共测试生命周期；定向测试通过 hook 定制行为。
        virtual task run();
            configure();
            build_random_plan();
            initialize_drivers();
            ctrl_vif.cfg_tx_burst_limit <= num_frames[15:0];
            print_configuration();
            pre_start();

            fork
                fdma_read_slave();
                fdma_write_slave();
                monitor_fdma_and_fifos();
                monitor_ll_and_rx_fifo();
            join_none

            wait_for_channel_up();
            after_channel_up();
            if (error_count == 0)
                wait_for_completion();

            stop_requested = 1'b1;
            repeat (4) @(posedge rd_vif.clk);
            disable fork;

            check_results();
            $display("[%s] FIFO peaks: TX=%0d RX=%0d", test_name, tx_fifo_peak, rx_fifo_peak);
            $display("[%s] LL frames: TX=%0d RX=%0d words_per_frame=%0d",
                     test_name, tx_frame_count, rx_frame_count, FRAME_WORDS);
            if (error_count == 0)
                $display("TEST_PASS: %s seed=%06d frames=%0d", test_name, seed, num_frames);
            else
                $display("TEST_FAIL: %s seed=%06d errors=%0d", test_name, seed, error_count);
        endtask
    endclass


endpackage
