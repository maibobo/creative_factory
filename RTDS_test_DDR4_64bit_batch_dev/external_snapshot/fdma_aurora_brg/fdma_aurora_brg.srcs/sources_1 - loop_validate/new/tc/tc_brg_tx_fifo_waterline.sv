`timescale 1ns / 1ps
// File: tc_brg_tx_fifo_waterline.sv

// 填充 512 字 TX FIFO，直到达到配置的 448 字 almost-full 水线。
package tc_brg_tx_fifo_waterline_pkg;        // Namespace for the TX 容量 test.
    import fdma_aurora_brg_tb_pkg::*;        // Import 公共验证行为.

    class tc_brg_tx_fifo_waterline extends tc_base; // Extend base with two 生命周期钩子.
        function new(int unsigned seed_i, int unsigned verbose_i,
                     virtual fdma_read_if rd_i, virtual fdma_write_if wr_i, // FDMA 句柄s.
                     virtual ll_link_if ll_i, virtual brg_ctrl_if ctrl_i,  // LL 停顿 控制.
                     virtual brg_obs_if obs_i);                            // FIFO probe.
            super.new("tc_brg_tx_fifo_waterline", seed_i, verbose_i,
                      rd_i, wr_i, ll_i, ctrl_i, obs_i); // Initialize 公共 状态.
        endfunction

        virtual function void configure();
            num_frames = 8;             // 8 * 64 个 数据字 可以填满 512-数据字 FIFO。
            enable_backpressure = 1'b0; // Only the 直连 LL 停顿 is 活动.
        endfunction

        virtual task pre_start();
            ll_vif.tx_dst_rdy <= 1'b0; // 数据到达前阻塞 FIFO 读侧。
            $display("[STIM][TX_FIFO] tx_dst_rdy=0; waiting for almost_full at 448/512 words");
        endtask

        virtual task after_channel_up();
            int unsigned wait_cycles;
            wait_cycles = 0;                 // 超时 计数器 in fdma_clk 周期.
            while ((obs_vif.tx_fifo_almost_full !== 1'b1) && (wait_cycles < 200000)) begin
                @(posedge rd_vif.clk);
                wait_cycles++;               // Prevent an infinite fill wait.
            end
            $display("[CHECK][TX_FIFO] count=%0d almost_full=%b full=%b overflow=%b rready=%b",
                     obs_vif.tx_fifo_wr_cnt, obs_vif.tx_fifo_almost_full,
                     obs_vif.tx_fifo_full, obs_vif.tx_fifo_overflow, rd_vif.rready);
            if (obs_vif.tx_fifo_almost_full !== 1'b1)
                record_error("TX FIFO did not reach almost_full");
            if (obs_vif.tx_fifo_wr_cnt < 448)
                record_error("TX FIFO almost_full asserted below the 448-word threshold");
            if (rd_vif.rready !== 1'b0)
                record_error("fdma_rready stayed high at TX FIFO almost_full");
            if (obs_vif.tx_fifo_overflow)
                record_error("TX FIFO overflowed before backpressure took effect");
            ll_vif.tx_dst_rdy <= 1'b1; // Release the FIFO and complete end-to-end checks.
            $display("[STIM][TX_FIFO] tx_dst_rdy=1; draining FIFO");
        endtask
    endclass
endpackage

module tc_brg_tx_fifo_waterline_top;         // Vivado 仿真顶层。
    import fdma_aurora_brg_tb_pkg::*;        // 运行期 辅助s.
    import tc_brg_tx_fifo_waterline_pkg::*;  // TX waterline 类.
    brg_harness #(.FRAME_BYTES(512)) h();    // 直连 bridge exposes tx_dst_rdy 控制.
    initial begin
        int unsigned seed;
        int unsigned verbose;
        string seed_source;
        tc_brg_tx_fifo_waterline test;
        seed = resolve_seed(seed_source);     // Read/generate reproducible seed.
        verbose = resolve_verbose();          // Read logging level.
        $display("[RANDOM] testcase=tc_brg_tx_fifo_waterline seed_source=%s seed=%06d", seed_source, seed);
        test = new(seed, verbose, h.rd_if, h.wr_if, h.ll_if, h.ctrl_if, h.obs_if); // 绑定句柄。
        test.run();                           // 基础流程动态调用前置/后置 hook。
        if (test.error_count != 0) $fatal(1, "tc_brg_tx_fifo_waterline failed");
        $finish;
    end
endmodule