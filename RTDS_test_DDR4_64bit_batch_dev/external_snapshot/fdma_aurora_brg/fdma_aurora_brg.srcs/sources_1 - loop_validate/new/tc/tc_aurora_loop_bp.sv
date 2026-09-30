`timescale 1ns / 1ps
// File: tc_aurora_loop_bp.sv

// 完整 Aurora/GT 环回测试，随机插入 FDMA 响应延迟和数据停顿。
package tc_aurora_loop_bp_pkg;                // Test-local package prevents 类-name collisions.
    import fdma_aurora_brg_tb_pkg::*;         // Import the 公共 base package.

    class tc_aurora_loop_bp extends tc_base;  // Reuse BFM/监测/scoreboard through inheritance.
        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // FDMA 句柄s.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // LL/控制 句柄s.
                     virtual brg_obs_if obs_i);                            // Observation 句柄.
            super.new("tc_aurora_loop_bp", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // 先构造基类部分。
        endfunction

        virtual function void configure();
            num_frames = rand_range(1, 3);
            enable_backpressure = 1'b1; // Use the public cfg_* fields in tc_base.sv.
        endfunction
    endclass
endpackage

module tc_aurora_loop_bp_top;                 // 随机反压用例的 Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;         // 运行期 seed and verbosity 辅助s.
    import tc_aurora_loop_bp_pkg::*;          // Testcase 类 definition.
    aurora_loop_harness #(.FRAME_BYTES(512)) h(); // Static full-loop structure.

    initial begin                             // 运行期 类 creation and execution.
        int unsigned seed, verbose;           // Decimal seed and print level.
        string seed_source;                   // AUTO 或 PLUSARG。
        tc_aurora_loop_bp test;               // Initially-null 类 句柄.
        seed = resolve_seed(seed_source);      // Select the reproducible random plan.
        verbose = resolve_verbose();           // Select log detail.
        $display("[RANDOM] testcase=tc_aurora_loop_bp seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // 绑定 virtual interface。
        test.run();                           // Dynamic dispatch enters tc_base.run().
        if (test.error_count != 0) $fatal(1, "tc_aurora_loop_bp failed"); // Non零 process 状态.
        $finish;                              // Passing termination.
    end
endmodule