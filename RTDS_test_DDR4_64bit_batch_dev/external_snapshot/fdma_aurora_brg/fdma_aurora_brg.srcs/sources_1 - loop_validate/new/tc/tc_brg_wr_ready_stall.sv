`timescale 1ns / 1ps
// File: tc_brg_wr_ready_stall.sv

// 直连 bridge 测试：分别停顿早期、中间和末尾的 FDMA 写数据字。
package tc_brg_wr_ready_stall_pkg;            // Namespace for this 直连 类.
    import fdma_aurora_brg_tb_pkg::*;         // Import base behavior and types.

    class tc_brg_wr_ready_stall extends tc_base; // Inherit standard traffic/checking.
        int unsigned early_word, middle_word, late_word; // Three distinct 注入区域.
        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // FDMA 句柄s.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // LL/控制 句柄s.
                     virtual brg_obs_if obs_i);                            // Probe 句柄.
            super.new("tc_brg_wr_ready_stall", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // Initialize the inherited 对象.
        endfunction

        virtual function void apply_directed_plan();
            early_word = rand_range(0, 7);                 // Select near 帧 start.
            middle_word = rand_range(8, total_words-9);    // Select interior data.
            late_word = total_words-1-rand_range(0, 7);    // Select near final 数据字.
            wr_ready_stall[early_word] = rand_range(2, 5);
            wr_ready_stall[middle_word] = rand_range(2, 8);
            wr_ready_stall[late_word] = rand_range(2, 5);
            $display("[STIM] wready stall words=%0d/%0d/%0d cycles=%0d/%0d/%0d",
                     early_word, middle_word, late_word,
                     wr_ready_stall[early_word], wr_ready_stall[middle_word], wr_ready_stall[late_word]);
        endfunction
    endclass
endpackage

module tc_brg_wr_ready_stall_top;            // Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;        // Seed/verbosity 辅助s.
    import tc_brg_wr_ready_stall_pkg::*;     // 直连 类.
    brg_harness #(.FRAME_BYTES(512)) h();    // 直连 LL loopback without Aurora IP.
    initial begin
        int unsigned seed;
        int unsigned verbose;
        string seed_source;
        tc_brg_wr_ready_stall test;
        seed = resolve_seed(seed_source);     // Select deterministic random plan.
        verbose = resolve_verbose();          // Select log detail.
        $display("[RANDOM] testcase=tc_brg_wr_ready_stall seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // 绑定到 harness。
        test.run();                           // 公共 run 使用修改后的停顿数组。
        if (test.error_count != 0) $fatal(1, "tc_brg_wr_ready_stall failed");
        $finish;
    end
endmodule