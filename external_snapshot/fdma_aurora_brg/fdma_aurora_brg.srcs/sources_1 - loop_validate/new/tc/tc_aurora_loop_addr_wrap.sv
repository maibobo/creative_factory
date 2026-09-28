`timescale 1ns / 1ps
// File: tc_aurora_loop_addr_wrap.sv

// 运行足够多的完整环回帧，覆盖 4KB 地址回绕边界。
package tc_aurora_loop_addr_wrap_pkg;         // Namespace for the 地址-回绕 类.
    import fdma_aurora_brg_tb_pkg::*;         // Import 公共类 and constants.

    class tc_aurora_loop_addr_wrap extends tc_base; // Inherit complete end-to-end checking.
        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // FDMA 句柄s.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // LL/控制 句柄s.
                     virtual brg_obs_if obs_i);                            // Probe 句柄.
            super.new("tc_aurora_loop_addr_wrap", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // Initialize base members and 句柄s.
        endfunction

        virtual function void configure();
            num_frames = rand_range(9, 12); // At least one 0xE00 -> 0 回绕.
            enable_backpressure = 1'b0;
        endfunction
    endclass
endpackage

module tc_aurora_loop_addr_wrap_top;          // 地址回绕覆盖用例的 Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;         // 公共运行期函数。
    import tc_aurora_loop_addr_wrap_pkg::*;   // 地址回绕测试类。
    aurora_loop_harness #(.FRAME_BYTES(512)) h(); // Static full Aurora loop.

    initial begin                             // 运行期 test entry.
        int unsigned seed, verbose;           // Random seed and logging level.
        string seed_source;                   // AUTO 或 PLUSARG 标记。
        tc_aurora_loop_addr_wrap test;        // 类句柄。
        seed = resolve_seed(seed_source);      // Resolve deterministic random data.
        verbose = resolve_verbose();           // Resolve log detail.
        $display("[RANDOM] testcase=tc_aurora_loop_addr_wrap seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // 将类连接到静态 harness。
        test.run();                           // Execute base flow with overridden 帧 count.
        if (test.error_count != 0) $fatal(1, "tc_aurora_loop_addr_wrap failed"); // Report to batch Tcl.
        $finish;                              // End pass.
    end
endmodule