`timescale 1ns / 1ps
// File: tc_aurora_loop_nobp.sv

// 无主动反压的 Aurora/GT 环回冒烟测试。
package tc_aurora_loop_nobp_pkg;             // Keep this testcase 类 in its own namespace.
    import fdma_aurora_brg_tb_pkg::*;         // Import tc_base, constants and 运行期 辅助s.

    class tc_aurora_loop_nobp extends tc_base; // Inherit all 公共 BFM and scoreboard behavior.
        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // FDMA 信号 句柄s.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // LL/控制 句柄s.
                     virtual brg_obs_if obs_i);                            // Read-only DUT probe.
            super.new("tc_aurora_loop_nobp", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // Initialize the inherited base 对象.
        endfunction

        virtual function void configure();
            num_frames = rand_range(1, 3); // Ordinary tests use one to three 帧.
            enable_backpressure = 1'b0;   // 关闭所有公共延迟控制项。
        endfunction
    endclass
endpackage

module tc_aurora_loop_nobp_top;               // 该用例的 Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;         // Make 运行期 辅助 函数s visible.
    import tc_aurora_loop_nobp_pkg::*;        // Make this testcase 类 visible.
    aurora_loop_harness #(.FRAME_BYTES(512)) h(); // Statically build bridge, Aurora and GT loop.

    initial begin                              // 运行期 entry after XSim elaboration.
        int unsigned seed, verbose;            // 选择 six-digit seed and logging level.
        string seed_source;                    // Records AUTO or PLUSARG for the log.
        tc_aurora_loop_nobp test;              // 类句柄；当前尚未创建对象。
        seed = resolve_seed(seed_source);       // Read +SEED or create and print a random seed.
        verbose = resolve_verbose();            // Read +VERBOSE, defaulting to level one.
        $display("[RANDOM] testcase=tc_aurora_loop_nobp seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // 将类绑定到 harness。
        test.run();                            // Execute the inherited 公共 生命周期.
        if (test.error_count != 0) $fatal(1, "tc_aurora_loop_nobp failed"); // Propagate failure to Tcl.
        $finish;                               // End a passing XSim run cleanly.
    end
endmodule