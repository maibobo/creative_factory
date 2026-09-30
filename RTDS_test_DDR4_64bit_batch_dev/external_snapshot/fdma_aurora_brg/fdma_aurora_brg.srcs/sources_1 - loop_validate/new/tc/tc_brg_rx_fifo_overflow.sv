`timescale 1ns / 1ps
// File: tc_brg_rx_fifo_overflow.sv

// FDMA 写回排空关闭时，向 RX 输入路径灌入超过容量的数据。
// Aurora RX 数据侧不允许下游反压；FIFO 满后应丢弃新数据且不能触发 XPM overflow。
package tc_brg_rx_fifo_overflow_pkg;         // Namespace for the RX 容量 test.
    import fdma_aurora_brg_tb_pkg::*;        // Import 公共类型 and 辅助s.

    class tc_brg_rx_fifo_overflow extends tc_base; // Override run because traffic is RX-only.
        int unsigned injection_words;        // FIFO depth plus one to sixty-four extra 数据字.

        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // Keep base constructor uniform.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // 直连 RX 注入 句柄s.
                     virtual brg_obs_if obs_i);                            // FIFO 状态 采样点.
            super.new("tc_brg_rx_fifo_overflow", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // Initialize PRNG and virtual interface.
        endfunction

        virtual task run();
            int unsigned word_index;
            int unsigned accepted_words;
            int unsigned stored_words;
            logic [63:0] drive_word;
            bit almost_full_seen, full_seen, drop_reported;

            initialize_drivers();                    // Put all BFM-owned 信号 in idle 状态.
            ctrl_vif.rx_loopback_enable <= 1'b0;    // Disconnect normal TX-to-RX loopback.
            ctrl_vif.rx_drive_src_rdy <= 1'b0;      // Keep 直连 源 idle during 复位.
            wait_for_channel_up();                   // 直连 harness raises channel_up after 复位.
            repeat (20) @(ll_vif.mon_cb); // 等待 XPM reset-busy 信号清除。

            injection_words = 2048 + rand_range(1, 64); // Guarantee traffic beyond FIFO 容量.
            $display("============================================================");
            $display("TESTCASE=%s SEED=%06d VERBOSE=%0d", test_name, seed, verbose);
            $display("[STIM][RX_FIFO] depth=2048 almost_full_threshold=2032 injection_words=%0d",
                     injection_words);
            $display("============================================================");

            accepted_words = 0;              // LL 握手 观测到.
            stored_words = 0;                // 观测到的实际 FIFO 写使能。
            almost_full_seen = 1'b0;         // 覆盖 flag for the 2032-数据字 threshold.
            full_seen = 1'b0;                // 容量覆盖标志。
            drop_reported = 1'b0;            // Limit data-loss reporting to the first 数据字.

            for (word_index = 0; word_index < injection_words; word_index++) begin
                drive_word = {next_rand(), next_rand()}; // Deterministic 64-bit 载荷.
                ctrl_vif.rx_drive_d <= drive_word;       // Drive the 直连 RX mux 输入.
                ctrl_vif.rx_drive_sof <= ((word_index % FRAME_WORDS) == 0);
                ctrl_vif.rx_drive_eof <= ((word_index % FRAME_WORDS) == FRAME_WORDS-1);
                ctrl_vif.rx_drive_rem <= 3'b111;
                ctrl_vif.rx_drive_src_rdy <= 1'b1;
                @(obs_vif.user_cb);           // Sample pre-edge FIFO 控制信号 without NBA races.

                if (ll_vif.mon_cb.rx_dst_rdy === 1'b1)
                    accepted_words++;         // RTL advertises acceptance through rx_dst_rdy.
                if (obs_vif.user_cb.rx_fifo_wr_en === 1'b1)
                    stored_words++;           // XPM FIFO 实际ly receives this 数据字.
                if (obs_vif.user_cb.rx_fifo_almost_full === 1'b1)
                    almost_full_seen = 1'b1;  // Remember even if the flag later 清除s.
                if (obs_vif.user_cb.rx_fifo_full === 1'b1)
                    full_seen = 1'b1;         // Remember 容量 was reached.

                if (full_seen &&
                    (ll_vif.mon_cb.rx_dst_rdy === 1'b1) &&
                    (obs_vif.user_cb.rx_fifo_wr_en !== 1'b1) && !drop_reported) begin
                    $display("[CHECK][RX_FIFO] saturated drop word=%0d data=%016h count=%0d full=%b",
                             word_index, drive_word,
                             obs_vif.user_cb.rx_fifo_wr_cnt,
                             obs_vif.user_cb.rx_fifo_full);
                    drop_reported = 1'b1;     // 满 FIFO 后观察到预期的丢弃保护。
                end
                if (obs_vif.user_cb.rx_fifo_overflow)
                    record_error($sformatf("RX XPM overflow asserted at word=%0d", word_index));
                if ((verbose >= 2) || ((word_index % 64) == 0))
                    $display("[STIM][RX_FIFO] word=%0d data=%016h count=%0d afull=%b full=%b wr_en=%b ready=%b",
                             word_index, drive_word, obs_vif.user_cb.rx_fifo_wr_cnt,
                             obs_vif.user_cb.rx_fifo_almost_full, obs_vif.user_cb.rx_fifo_full,
                             obs_vif.user_cb.rx_fifo_wr_en, ll_vif.mon_cb.rx_dst_rdy);
            end

            ctrl_vif.rx_drive_src_rdy <= 1'b0; // End direct LocalLink traffic.
            repeat (4) @(ll_vif.mon_cb);
            if (!almost_full_seen) record_error("RX FIFO almost_full was not observed");
            if (!full_seen) record_error("RX FIFO full was not observed");
            if (!drop_reported) record_error("RX saturated-drop condition was not observed");
            $display("[CHECK][RX_FIFO] accepted=%0d stored=%0d peak=%0d almost_full_seen=%b full_seen=%b",
                     accepted_words, stored_words, obs_vif.rx_fifo_wr_cnt,
                     almost_full_seen, full_seen);
            if (error_count == 0)
                $display("TEST_PASS: %s seed=%06d", test_name, seed);
            else
                $display("TEST_FAIL: %s seed=%06d errors=%0d", test_name, seed, error_count);
        endtask
    endclass
endpackage

module tc_brg_rx_fifo_overflow_top;          // Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;        // 运行期 辅助s.
    import tc_brg_rx_fifo_overflow_pkg::*;   // RX overflow 类.
    brg_harness #(.FRAME_BYTES(512)) h();    // 直连 harness provides 注入 mux.
    initial begin
        int unsigned seed;
        int unsigned verbose;
        string seed_source;
        tc_brg_rx_fifo_overflow test;
        seed = resolve_seed(seed_source);     // Select deterministic 载荷 sequence.
        verbose = resolve_verbose();          // Select log detail.
        $display("[RANDOM] testcase=tc_brg_rx_fifo_overflow seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // Create/bind 类.
        test.run();                           // Dynamic dispatch calls the RX-only run override.
        if (test.error_count != 0) $fatal(1, "tc_brg_rx_fifo_overflow failed");
        $finish;
    end
endmodule
