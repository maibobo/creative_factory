# tb_fdma_aurora_brg_aurora_loop - gold

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\tb_fdma_aurora_brg_aurora_loop - gold.sv`
- SHA-256: `42f93a296c1a2a1a6cfd6de094c8af3487a10958cd24502d609947128f80607d`
- Extractor: `text`
- Tags: `aurora, fdma, pcie, testbench`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_fdma_aurora_brg_aurora_loop
// Description: 验证 fdma_aurora_brg_aurora_loop 顶层模块
//
// 架构 (GT 自环回):
//   DUT (fdma_aurora_brg_aurora_loop)
//   ┌─────────────────────────────────┐
//   │ fdma_aurora_brg_top             │
//   │   ↓ (LL TX)                     │
//   │ aurora_64b66b_top               │
//   │   ↓ (GT TX) ───┐               │
//   │                 │ GT self-loop  │
//   │   ↑ (GT RX) ───┘               │
//   │   ↑ (LL RX)                     │
//   │ fdma_aurora_brg_top             │
//   └─────────────────────────────────┘
//
//   DUT 已包含完整的 TX+RX 双向路径，GT 自环回即可验证端到端数据传输。
//   无需 Partner。
//
//   比对策略:
//   1. LL 层比对: brg TX LL 发出的数据 vs brg RX LL 收到的数据
//   2. FDMA 层比对: FDMA 读从机发出的数据 vs FDMA 写从机收到的数据
//////////////////////////////////////////////////////////////////////////////////

// ======================== 参数和类型本地定义 ========================
package loop_pkg;
    // 时钟参数 (与参考 TB 一致)
    parameter real FDMA_CLK_PERIOD_NS = 4.0;      // 250 MHz
    parameter real INIT_CLK_PERIOD_NS = 20.0;     // 50 MHz (参考 TB: INIT_CLOCKPERIOD_1=20)
    parameter real GT_REF_CLK_PERIOD_NS = 6.4;    // ~156.25 MHz

    // 测试配置
    parameter int TEST_MEM_SIZE_BYTES = 4 * 1024; // 4KB
    parameter int FDMA_BURST_LEN_BYTES = 512;
    parameter int AURORA_FRAME_BYTES = 1024;
    parameter int NUM_FRAMES_TO_TEST = 20;        // 增加到 20 帧 (40 次 rareq)

    // 派生参数
    parameter int BURST_WORDS = FDMA_BURST_LEN_BYTES / 8;   // 64
    parameter int FRAME_WORDS = AURORA_FRAME_BYTES / 8;     // 128

    // 事务类型
    typedef struct {
        int frame_id;
        logic [63:0] words [0:FRAME_WORDS-1];
    } aurora_frame_t;
endpackage

import loop_pkg::*;

// ======================== 接口定义 ========================
interface fdma_read_if(input logic clk, input logic rst_n);
    logic [31:0] raddr;
    logic        rareq;
    logic        rbusy;
    logic [63:0] rdata;
    logic        rvalid;

    modport dut(output raddr, rareq, input rbusy, rdata, rvalid);
    modport tb (input raddr, rareq, output rbusy, rdata, rvalid);
    clocking tb_cb @(posedge clk); default input #1step output #1step;
        input raddr, rareq;
        output rbusy, rdata, rvalid;
    endclocking
endinterface

interface fdma_write_if(input logic clk, input logic rst_n);
    logic [31:0] waddr;
    logic        wareq;
    logic        wbusy;
    logic [63:0] wdata;
    logic        wvalid;
    logic [15:0] wsize;

    modport dut(output waddr, wareq, wdata, wvalid, wsize, input wbusy);
    modport tb (input waddr, wareq, wdata, wvalid, wsize, output wbusy);
    clocking tb_cb @(posedge clk); default input #1step output #1step;
        input waddr, wareq, wdata, wvalid, wsize;
        output wbusy;
    endclocking
endinterface

// ======================== Testbench 顶层 ========================
module tb_fdma_aurora_brg_aurora_loop;

    import loop_pkg::*;

    //====================================================================================
    // 时钟与复位
    //====================================================================================
    logic fdma_clk;
    logic init_clk;
    logic gt_ref_clk_n;
    logic sys_rst;
    logic fdma_rstn;

    // 生成时钟
    initial fdma_clk = 0;
    always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;

    initial init_clk = 0;
    always #(INIT_CLK_PERIOD_NS/2) init_clk = ~init_clk;

    initial gt_ref_clk_n = 0;
    always #(GT_REF_CLK_PERIOD_NS/2) gt_ref_clk_n = ~gt_ref_clk_n;

    wire gt_ref_clk_p = ~gt_ref_clk_n;

    // 复位序列
    initial begin
        sys_rst   = 1;
        fdma_rstn = 0;
        repeat(160) @(posedge init_clk);
        sys_rst = 0;
        #(60) fdma_rstn = 1;
    end

    //====================================================================================
    // DUT 状态信号
    //====================================================================================
    wire channel_up;
    wire lane_up;
    wire user_clk;
    wire user_rstn;

    //====================================================================================
    // GT 自环回: DUT TX → DUT RX
    //====================================================================================
    wire txp, txn;
    wire rxp, rxn;

    assign rxp = txp;
    assign rxn = txn;

    //====================================================================================
    // FDMA 接口
    //====================================================================================
    fdma_read_if   rd_if (fdma_clk, fdma_rstn);
    fdma_write_if  wr_if (fdma_clk, fdma_rstn);

    //====================================================================================
    // 例化 DUT: fdma_aurora_brg_aurora_loop (SIMULATION=1 加速初始化)
    //====================================================================================
    fdma_aurora_brg_aurora_loop #(
        .SIMULATION     (1)
    ) dut (
        // Aurora 初始化时钟与复位
        .clk_init       (init_clk       ),
        .sys_rst        (sys_rst        ),

        // GT IO
        .GTHQ0_P        (gt_ref_clk_p   ),
        .GTHQ0_N        (gt_ref_clk_n   ),
        .RXP            (rxp            ),
        .RXN            (rxn            ),
        .TXP            (txp            ),
        .TXN            (txn            ),

        // SFP 控制
        .sfp_tx_disable (               ),
        .sfp_rs0        (               ),
        .sfp_rs1        (               ),

        // FDMA 时钟与复位
        .fdma_clk       (fdma_clk       ),
        .fdma_rstn      (fdma_rstn      ),

        // FDMA 读接口
        .fdma_raddr     (rd_if.raddr    ),
        .fdma_rareq     (rd_if.rareq    ),
        .fdma_rbusy     (rd_if.rbusy    ),
        .fdma_rdata     (rd_if.rdata    ),
        .fdma_rvalid    (rd_if.rvalid   ),

        // FDMA 写接口
        .fdma_waddr     (wr_if.waddr    ),
        .fdma_wareq     (wr_if.wareq    ),
        .fdma_wbusy     (wr_if.wbusy    ),
        .fdma_wdata     (wr_if.wdata    ),
        .fdma_wvalid    (wr_if.wvalid   ),
        .fdma_wsize     (wr_if.wsize    ),

        // 状态输出
        .channel_up     (channel_up     ),
        .lane_up        (lane_up        ),
        .user_clk       (user_clk       ),
        .user_rstn      (user_rstn      )
    );

    //====================================================================================
    // FDMA 读从机模型 (含随机反压)
    //====================================================================================
    typedef logic [63:0] burst_data_t [0:BURST_WORDS-1];
    burst_data_t read_burst_queue [$];

    // FDMA 读从机发出的数据队列（用于 FDMA 层比对）
    reg [63:0] fdma_rd_data_queue [$];

    task automatic fdma_read_slave();
        automatic logic [63:0] burst_data[0:BURST_WORDS-1];
        automatic int bp_delay;
        forever begin
            @(posedge fdma_clk);
            while (!(rd_if.tb_cb.rareq === 1 && rd_if.rbusy === 0))
                @(posedge fdma_clk);

            // 随机反压: 30% 概率插入 1~8 周期延迟
            bp_delay = ($urandom_range(0, 9) < 3) ? $urandom_range(1, 8) : 0;
            repeat(bp_delay) @(posedge fdma_clk);

            rd_if.tb_cb.rbusy <= 1;

            wait (read_burst_queue.size() > 0);
            burst_data = read_burst_queue.pop_front();

            for (int i = 0; i < BURST_WORDS; i++) begin
                @(posedge fdma_clk);
                // 突发内随机反压: 10% 概率插入 1~4 周期延迟
                bp_delay = ($urandom_range(0, 9) < 1) ? $urandom_range(1, 4) : 0;
                repeat(bp_delay) begin
                    rd_if.tb_cb.rvalid <= 0;
                    @(posedge fdma_clk);
                end
                rd_if.tb_cb.rdata  <= burst_data[i];
                rd_if.tb_cb.rvalid <= 1;
                fdma_rd_data_queue.push_back(burst_data[i]);
            end

            @(posedge fdma_clk);
            rd_if.tb_cb.rvalid <= 0;
            rd_if.tb_cb.rbusy  <= 0;
        end
    endtask

    //====================================================================================
    // FDMA 写从机模型 (含随机反压)
    //====================================================================================
    // FDMA 写从机收到的数据队列（用于 FDMA 层比对）
    reg [63:0] fdma_wr_data_queue [$];

    task automatic fdma_write_slave();
        int num_words = 0;
        automatic int bp_delay;
        forever begin
            @(posedge fdma_clk);
            while (!(wr_if.tb_cb.wareq === 1 && wr_if.wbusy === 0))
                @(posedge fdma_clk);

            // 随机反压: 30% 概率插入 1~8 周期延迟
            bp_delay = ($urandom_range(0, 9) < 3) ? $urandom_range(1, 8) : 0;
            repeat(bp_delay) @(posedge fdma_clk);

            wr_if.tb_cb.wbusy <= 1;

            num_words = wr_if.wsize / 8;

            for (int i = 0; i < num_words; i++) begin
                // 突发内随机反压: 10% 概率插入 1~4 周期延迟
                bp_delay = ($urandom_range(0, 9) < 1) ? $urandom_range(1, 4) : 0;
                repeat(bp_delay) @(posedge fdma_clk);

                @(posedge fdma_clk);
                while (wr_if.wvalid !== 1)
                    @(posedge fdma_clk);
                fdma_wr_data_queue.push_back(wr_if.wdata);
            end

            @(posedge fdma_clk);
            wr_if.tb_cb.wbusy <= 0;
        end
    endtask

    //====================================================================================
    // 监测与比对
    //====================================================================================
    // LL 层监测队列
    reg [63:0] ll_tx_data_queue [$];   // brg TX LL 发出的数据
    reg [63:0] ll_rx_data_queue [$];    // brg RX LL 收到的数据

    integer ll_error_count  = 0;
    integer fdma_error_count = 0;

    // 监测 brg TX LL 输出 (DUT 内部 fdma_aurora_brg_top 的 aurora_tx_* 接口)
    initial begin
        forever begin
            @(posedge user_clk);
            if (dut.u_fdma_aurora_brg_top.aurora_tx_src_rdy &&
                dut.u_fdma_aurora_brg_top.aurora_tx_dst_rdy) begin
                ll_tx_data_queue.push_back(dut.u_fdma_aurora_brg_top.aurora_tx_d);
            end
        end
    end

    // 监测 brg RX LL 输入 (DUT 内部 fdma_aurora_brg_top 的 aurora_rx_* 接口)
    initial begin
        forever begin
            @(posedge user_clk);
            if (dut.u_fdma_aurora_brg_top.aurora_rx_src_rdy &&
                dut.u_fdma_aurora_brg_top.aurora_rx_dst_rdy) begin
                ll_rx_data_queue.push_back(dut.u_fdma_aurora_brg_top.aurora_rx_d);
            end
        end
    end

    //====================================================================================
    // 比对 Task 1: LL 层比对 - brg TX 发出的数据 vs brg RX 收到的数据
    //====================================================================================
    task automatic compare_ll_data();
        int min_size;

        $display("=== Comparison 1: LL TX vs LL RX (GT self-loopback) ===");
        $display("ll_tx_data_queue length: %0d", ll_tx_data_queue.size());
        $display("ll_rx_data_queue length: %0d", ll_rx_data_queue.size());

        if (ll_tx_data_queue.size() == 0) begin
            $display("SKIP: No LL TX data to compare.");
            return;
        end

        if (ll_rx_data_queue.size() == 0) begin
            $error("FAIL: LL RX received 0 words, but LL TX sent %0d words.",
                   ll_tx_data_queue.size());
            ll_error_count++;
            return;
        end

        // 逐字比对 (TX 和 RX 长度可能不同，取最小值)
        min_size = (ll_tx_data_queue.size() < ll_rx_data_queue.size()) ?
                    ll_tx_data_queue.size() : ll_rx_data_queue.size();

        for (int i = 0; i < min_size; i++) begin
            if (ll_tx_data_queue[i] !== ll_rx_data_queue[i]) begin
                $error("LL Data mismatch at word %0d: TX=0x%0h, RX=0x%0h",
                       i, ll_tx_data_queue[i], ll_rx_data_queue[i]);
                ll_error_count++;
            end
        end

        if (ll_tx_data_queue.size() != ll_rx_data_queue.size()) begin
            $display("NOTE: LL TX/RX length differ: TX=%0d, RX=%0d",
                     ll_tx_data_queue.size(), ll_rx_data_queue.size());
        end

        if (ll_error_count == 0)
            $display("PASS: LL TX vs LL RX - All %0d words matched.", min_size);
        else
            $display("FAIL: LL TX vs LL RX - %0d mismatches detected.", ll_error_count);
    endtask

    //====================================================================================
    // 比对 Task 2: FDMA 层比对 - FDMA 读从机发出的数据 vs FDMA 写从机收到的数据
    // 端到端验证: FDMA读 → brg_tx → Aurora TX → GT自环回 → Aurora RX → brg_rx → FDMA写
    //====================================================================================
    task automatic compare_fdma_data();
        int min_size;

        $display("=== Comparison 2: FDMA Read vs FDMA Write (end-to-end) ===");
        $display("fdma_rd_data_queue length: %0d", fdma_rd_data_queue.size());
        $display("fdma_wr_data_queue length: %0d", fdma_wr_data_queue.size());

        if (fdma_rd_data_queue.size() == 0) begin
            $display("SKIP: No FDMA read data to compare.");
            return;
        end

        if (fdma_wr_data_queue.size() == 0) begin
            $error("FAIL: FDMA write received 0 words, but FDMA read sent %0d words.",
                   fdma_rd_data_queue.size());
            fdma_error_count++;
            return;
        end

        // 逐字比对
        min_size = (fdma_rd_data_queue.size() < fdma_wr_data_queue.size()) ?
                    fdma_rd_data_queue.size() : fdma_wr_data_queue.size();

        for (int i = 0; i < min_size; i++) begin
            if (fdma_rd_data_queue[i] !== fdma_wr_data_queue[i]) begin
                $error("FDMA Data mismatch at word %0d: RD=0x%0h, WR=0x%0h",
                       i, fdma_rd_data_queue[i], fdma_wr_data_queue[i]);
                fdma_error_count++;
            end
        end

        if (fdma_rd_data_queue.size() != fdma_wr_data_queue.size()) begin
            $display("NOTE: FDMA RD/WR length differ: RD=%0d, WR=%0d",
                     fdma_rd_data_queue.size(), fdma_wr_data_queue.size());
        end

        if (fdma_error_count == 0)
            $display("PASS: FDMA Read vs FDMA Write - All %0d words matched.", min_size);
        else
            $display("FAIL: FDMA Read vs FDMA Write - %0d mismatches detected.", fdma_error_count);
    endtask

    //====================================================================================
    // 启动从机模型
    //====================================================================================
    initial begin
        fork
            fdma_read_slave();
            fdma_write_slave();
        join_none
    end

    //====================================================================================
    // 主激励序列
    //====================================================================================
    initial begin
        static int burst_cnt = FRAME_WORDS / BURST_WORDS;  // 每帧 2 个 burst

        wr_if.tb_cb.wbusy <= 0;
        rd_if.tb_cb.rbusy <= 0;
        rd_if.tb_cb.rvalid <= 0;

        // 等待 Aurora 通道建立
        $display("[%t] Waiting for channel_up...", $time);
        wait(channel_up == 1);
        $display("[%t] DUT channel_up == 1", $time);
        repeat(800) @(posedge user_clk);
        $display("[%t] Start sending test data...", $time);

        // TX 方向: 通过 FDMA 读接口发送数据
        for (int f = 0; f < NUM_FRAMES_TO_TEST; f++) begin
            aurora_frame_t tx_frame;
            tx_frame.frame_id = f;
            for (int w = 0; w < FRAME_WORDS; w++) begin
                tx_frame.words[w] = (f << 32) | w;
            end

            // 准备 FDMA 读的 burst 数据
            for (int b = 0; b < burst_cnt; b++) begin
                burst_data_t burst_data;
                for (int w = 0; w < BURST_WORDS; w++) begin
                    burst_data[w] = tx_frame.words[b * BURST_WORDS + w];
                end
                read_burst_queue.push_back(burst_data);
            end
        end

        // 等待 TX 方向数据流经 DUT (LL TX 监测)
        fork
            begin
                wait(ll_tx_data_queue.size() >= NUM_FRAMES_TO_TEST * FRAME_WORDS);
                $display("[%t] All LL TX data transmitted.", $time);
            end
            begin
                repeat(5000000) @(posedge fdma_clk);
                $display("[%t] WARNING: LL TX timeout, got %0d/%0d words",
                         $time, ll_tx_data_queue.size(), NUM_FRAMES_TO_TEST * FRAME_WORDS);
            end
        join_any

        // 等待 RX 方向数据 (GT 自环回后 DUT RX 应收到 TX 发出的数据)
        fork
            begin
                wait(ll_rx_data_queue.size() >= ll_tx_data_queue.size());
                $display("[%t] All LL RX data received.", $time);
            end
            begin
                repeat(10000000) @(posedge fdma_clk);
                $display("[%t] WARNING: LL RX timeout, got %0d/%0d words",
                         $time, ll_rx_data_queue.size(), ll_tx_data_queue.size());
            end
        join_any

        // 等待 FDMA 写从机收到数据
        fork
            begin
                wait(fdma_wr_data_queue.size() >= fdma_rd_data_queue.size());
                $display("[%t] All FDMA write data received.", $time);
            end
            begin
                repeat(10000000) @(posedge fdma_clk);
                $display("[%t] WARNING: FDMA write timeout, got %0d/%0d words",
                         $time, fdma_wr_data_queue.size(), fdma_rd_data_queue.size());
            end
        join_any

        repeat(1000) @(posedge fdma_clk);
        #100;

        // 自动比对
        compare_ll_data();
        compare_fdma_data();
        $finish;
    end

    //====================================================================================
    // 仿真超时保护
    //====================================================================================
    initial begin
        #(5_000_000); // 5ms 超时 (SIMULATION=1 模式下初始化约 700us)
        $display("[%t] ERROR: Simulation timeout!", $time);
        $display("DUT: channel_up=%b, lane_up=%b", channel_up, lane_up);
        $display("LL TX: %0d words, LL RX: %0d words", ll_tx_data_queue.size(), ll_rx_data_queue.size());
        $display("FDMA RD: %0d words, FDMA WR: %0d words", fdma_rd_data_queue.size(), fdma_wr_data_queue.size());
        $finish;
    end

endmodule
```
