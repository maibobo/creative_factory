`timescale 1ns / 1ps
// File: tc_brg_rd_ready_stall.sv

// 直连 bridge 测试：rvalid 保持有效时拉低 rready。
package tc_brg_rd_ready_stall_pkg;            // Namespace for this 直连 类.
    import fdma_aurora_brg_tb_pkg::*;         // Import tc_base and interface types.

    class tc_brg_rd_ready_stall extends tc_base; // Reuse the 公共 end-to-end flow.
        int unsigned stall_word;              // Global 数据字 索引 选择 for 注入.
        int unsigned stall_cycles;            // Number of rready-low fdma_clk 周期.

        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // FDMA 句柄s.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // LL and fault 控制.
                     virtual brg_obs_if obs_i);                            // 内部 observations.
            super.new("tc_brg_rd_ready_stall", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // Initialize inherited 状态.
        endfunction

        virtual function void apply_directed_plan();
            stall_word = rand_range(8, total_words-8); // 避开首尾 8 个数据字。
            stall_cycles = rand_range(2, 5);          // Short but observable 停顿.
            $display("[STIM] rready stall word=%0d cycles=%0d", stall_word, stall_cycles);
        endfunction

        virtual task on_read_word_presented(int unsigned global_word_index);
            logic [6:0] saved_count;
            int unsigned i;
            if (global_word_index != stall_word) return; // Inject at one 选择 数据字 only.
            saved_count = obs_vif.tx_rd_word_cnt;        // 计数器必须保持不变。
            ctrl_vif.force_tx_almost_full <= 1'b1;       // Drives DUT rready low through harness.
            for (i = 0; i < stall_cycles; i++) begin
                @(rd_vif.cb);
                if (rd_vif.cb.rready !== 1'b0) record_error("rready did not deassert");
                if (obs_vif.tx_fifo_wr_en !== 1'b0) record_error("TX FIFO wrote while rready=0");
                if (obs_vif.tx_rd_word_cnt !== saved_count) record_error("rd_word_cnt advanced while rready=0");
            end
            ctrl_vif.force_tx_almost_full <= 1'b0;       // Resume the held read transfer.
        endtask
    endclass
endpackage

module tc_brg_rd_ready_stall_top;            // Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;        // 公共辅助函数。
    import tc_brg_rd_ready_stall_pkg::*;     // 直连 类.
    brg_harness #(.FRAME_BYTES(512)) h();    // Static 直连-bridge structure.
    initial begin
        int unsigned seed;
        int unsigned verbose;
        string seed_source;
        tc_brg_rd_ready_stall test;
        seed = resolve_seed(seed_source);     // Read or generate the decimal seed.
        verbose = resolve_verbose();          // Read the desired logging level.
        $display("[RANDOM] testcase=tc_brg_rd_ready_stall seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // Create/bind 对象.
        test.run();                           // 基础 run 调用被覆盖的注入 hook。
        if (test.error_count != 0) $fatal(1, "tc_brg_rd_ready_stall failed");
        $finish;
    end
endmodule