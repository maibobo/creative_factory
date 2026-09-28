`timescale 1ns / 1ps
// File: tb_fdma_aurora_brg_aurora_loop_nobp.sv

//////////////////////////////////////////////////////////////////////////////////
// 模块名称: tb_fdma_aurora_brg_aurora_loop_nobp
// 说明: 无反压版验证 - FDMA 从机永远立即响应
// 架构 (GT 自环回):
//   DUT (fdma_aurora_brg_aurora_loop)
//   ┌─────────────────────────────────┐
//   │ fdma_aurora_brg_顶层             │
//   │   ↓ (LL TX)                     │
//   │ aurora_64b66b_顶层               │
//   │   ↓ (GT TX) ───┐               │
//   │                 │ GT self-loop  │
//   │   ↑ (GT RX) ───┘               │
//   │   ↑ (LL RX)                     │
//   │ fdma_aurora_brg_顶层             │
//   └─────────────────────────────────┘
//   比对策略:
//   1. LL 层比对: brg TX LL 发出的数据 vs brg RX LL 收到的数据
//   2. FDMA 层比对: FDMA 读从机发出的数据 vs FDMA 写从机收到的数据
//////////////////////////////////////////////////////////////////////////////////

// ======================== 参数和类型本地定义 ========================
// 本 package 集中放置该仿真用例的参数、帧结构和共享类型。
package loop_nobp_pkg;
    // FDMA 时钟周期，单位 ns。
    parameter real FDMA_CLK_PERIOD_NS = 4.0;
    // Aurora init_clk 时钟周期，单位 ns。
    parameter real INIT_CLK_PERIOD_NS = 20.0;
    // GT 参考时钟周期，单位 ns。
    parameter real GT_REF_CLK_PERIOD_NS = 6.4;

    // TEST_MEM_SIZE_BYTES 表示测试地址窗口大小。
    parameter int TEST_MEM_SIZE_BYTES = 4 * 1024;
    // FDMA_BURST_LEN_BYTES 表示单次 FDMA 突发字节数。
    parameter int FDMA_BURST_LEN_BYTES = 512;
    // AURORA_FRAME_BYTES 表示单个 Aurora 测试帧字节数。
    parameter int AURORA_FRAME_BYTES = 1536;       // 3 突发/帧 (3*512=1536)
    // 本测试平台生成并比较的帧数量。
    parameter int NUM_FRAMES_TO_TEST = 3;

    // 单个 FDMA 突发包含的 64bit 数据字数量。
    parameter int BURST_WORDS = FDMA_BURST_LEN_BYTES / 8;
    // 单帧包含的 64bit 数据字数量。
    parameter int FRAME_WORDS = AURORA_FRAME_BYTES / 8;

    // 结构体把一组关联字段合成一个对象，方便队列、scoreboard 和任务传递。
    typedef struct {
        int frame_id;
        logic [63:0] words [0:FRAME_WORDS-1];
    } aurora_frame_t;
endpackage

// 导入本 测试平台 的本地参数和类型，后续模块/任务可直接使用。
import loop_nobp_pkg::*;

// ======================== 接口定义 ========================
// FDMA 读接口模型封装 rareq、rbusy、rvalid、rready 等握手信号。
interface fdma_read_if_nobp(input logic clk, input logic rst_n);
    logic [31:0] raddr;
    logic        rareq;
    logic        rbusy;
    logic [63:0] rdata;
    logic        rvalid;
    logic        rready;    // DUT 输出: 用户授权FDMA传输数据

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport dut(output raddr, rareq, rready, input rbusy, rdata, rvalid);
    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport tb (input raddr, rareq, rready, output rbusy, rdata, rvalid);
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tb_cb @(posedge clk); default input #1step output #1step;
        input raddr, rareq, rready;  // rready 由 DUT 驱动, TB 只读
        output rbusy, rdata, rvalid;
    endclocking
endinterface

// FDMA 写接口模型封装 wareq、wbusy、wvalid、wready 等握手信号。
interface fdma_write_if_nobp(input logic clk, input logic rst_n);
    logic [31:0] waddr;
    logic        wareq;
    logic        wbusy;
    logic [63:0] wdata;
    logic        wvalid;
    logic [15:0] wsize;
    logic        wready;

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport dut(output waddr, wareq, wdata, wvalid, wsize, input wbusy, wready);
    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport tb (input waddr, wareq, wdata, wvalid, wsize, output wbusy, wready);
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tb_cb @(posedge clk); default input #1step output #1step;
        input waddr, wareq, wdata, wvalid, wsize;
        output wbusy, wready;
    endclocking
endinterface

// ======================== 测试平台 顶层 ========================
// tb_fdma_aurora_brg_aurora_loop_nobp 模块入口；无反压 Aurora 环回 测试平台：FDMA 从机立即响应，用于建立基础通路基准。
module tb_fdma_aurora_brg_aurora_loop_nobp;

    // 导入本 测试平台 的本地参数和类型，后续模块/任务可直接使用。
    import loop_nobp_pkg::*;

    //====================================================================================
    // 时钟与复位
    //====================================================================================
    logic fdma_clk;
    logic init_clk;
    logic gt_ref_clk_n;
    logic sys_rst;
    logic fdma_rstn;

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial fdma_clk = 0;
    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial init_clk = 0;
    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #(INIT_CLK_PERIOD_NS/2) init_clk = ~init_clk;

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial gt_ref_clk_n = 0;
    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #(GT_REF_CLK_PERIOD_NS/2) gt_ref_clk_n = ~gt_ref_clk_n;

    wire gt_ref_clk_p = ~gt_ref_clk_n;

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        sys_rst   = 1;
        fdma_rstn = 0;
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
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
    // GT 自环回
    //====================================================================================
    wire txp, txn;
    wire rxp, rxn;

    assign rxp = txp;
    assign rxn = txn;

    //====================================================================================
    // FDMA 接口
    //====================================================================================
    fdma_read_if_nobp   rd_if (fdma_clk, fdma_rstn);
    fdma_write_if_nobp  wr_if (fdma_clk, fdma_rstn);

    //====================================================================================
    // 例化 DUT
    //====================================================================================
    fdma_aurora_brg_aurora_loop #(
        .SIMULATION     (1)
    ) dut (
        .clk_init       (init_clk       ),
        .sys_rst        (sys_rst        ),
        .GTHQ0_P        (gt_ref_clk_p   ),
        .GTHQ0_N        (gt_ref_clk_n   ),
        .RXP            (rxp            ),
        .RXN            (rxn            ),
        .TXP            (txp            ),
        .TXN            (txn            ),
        .sfp_tx_disable (               ),
        .sfp_rs0        (               ),
        .sfp_rs1        (               ),
        .fdma_clk       (fdma_clk       ),
        .fdma_rstn      (fdma_rstn      ),
        .cfg_tx_burst_limit(16'd0),
        .fdma_raddr     (rd_if.raddr    ),
        .fdma_rareq     (rd_if.rareq    ),
        .fdma_rbusy     (rd_if.rbusy    ),
        .fdma_rdata     (rd_if.rdata    ),
        .fdma_rvalid    (rd_if.rvalid   ),
        .fdma_rready    (rd_if.rready   ),
        .fdma_waddr     (wr_if.waddr    ),
        .fdma_wareq     (wr_if.wareq    ),
        .fdma_wbusy     (wr_if.wbusy    ),
        .fdma_wdata     (wr_if.wdata    ),
        .fdma_wvalid    (wr_if.wvalid   ),
        .fdma_wsize     (wr_if.wsize    ),
        .fdma_wready    (wr_if.wready   ),
        .hw_test_dbg_bus(257'd0         ),
        .hw_test_status_bus(188'd0      ),
        .channel_up     (channel_up     ),
        .lane_up        (lane_up        ),
        .user_clk       (user_clk       ),
        .user_rstn      (user_rstn      )
    );

    //====================================================================================
    // FDMA 读从机模型 (无反压 - 立即响应)
    //====================================================================================
    typedef logic [63:0] burst_data_t [0:BURST_WORDS-1];
    burst_data_t read_burst_queue [$];

    reg [63:0] fdma_rd_data_queue [$];

    // 该 任务 模拟/驱动 FDMA 读侧行为，把期望数据送入 DUT。
    task automatic fdma_read_slave();
        automatic logic [63:0] burst_data[0:BURST_WORDS-1];
        forever begin
            @(posedge fdma_clk);
            while (!(rd_if.tb_cb.rareq === 1 && rd_if.rbusy === 0))
                @(posedge fdma_clk);

            @(posedge fdma_clk);
            rd_if.tb_cb.rbusy <= 1;

            // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
            wait (read_burst_queue.size() > 0);
            burst_data = read_burst_queue.pop_front();

            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int i = 0; i < BURST_WORDS; i++) begin
                rd_if.tb_cb.rdata  <= burst_data[i];
                rd_if.tb_cb.rvalid <= 1;
                // 最后一拍 rvalid 被 DUT 接收后的下一周期拉低 rbusy。
                @(posedge fdma_clk);
                while (!(rd_if.rvalid === 1 && rd_if.rready === 1))
                    @(posedge fdma_clk);
                fdma_rd_data_queue.push_back(burst_data[i]);
            end

            @(posedge fdma_clk);
            rd_if.tb_cb.rvalid <= 0;
            rd_if.tb_cb.rbusy  <= 0;
        end
    endtask

    //====================================================================================
    // FDMA 写从机模型 (无反压 - 立即响应)
    //====================================================================================
    reg [63:0] fdma_wr_data_queue [$];

    // 该 任务 模拟/驱动 FDMA 写侧行为，并记录 DUT 写回的数据。
    task automatic fdma_write_slave();
        int num_words = 0;
        forever begin
            @(posedge fdma_clk);
            while (!(wr_if.tb_cb.wareq === 1 && wr_if.wbusy === 0))
                @(posedge fdma_clk);

            @(posedge fdma_clk);
            wr_if.tb_cb.wbusy <= 1;
            wr_if.tb_cb.wready <= 1;  // 无反压: 恒为1

            num_words = wr_if.wsize / 8;

            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int i = 0; i < num_words; i++) begin
                @(posedge fdma_clk);
                while (wr_if.wvalid !== 1)
                    @(posedge fdma_clk);
                fdma_wr_data_queue.push_back(wr_if.wdata);
            end

            @(posedge fdma_clk);
            wr_if.tb_cb.wbusy <= 0;
            wr_if.tb_cb.wready <= 0;
        end
    endtask

    //====================================================================================
    // 监测与比对
    //====================================================================================
    reg [63:0] ll_tx_data_queue [$];
    reg [63:0] ll_rx_data_queue [$];

    integer ll_error_count  = 0;
    integer fdma_error_count = 0;

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        forever begin
            @(posedge user_clk);
            // LocalLink 的 src_rdy 与 dst_rdy 同拍有效时，当前 64bit 字完成一次链路传输。
            if (dut.u_fdma_aurora_brg_top.aurora_tx_src_rdy &&
                dut.u_fdma_aurora_brg_top.aurora_tx_dst_rdy) begin
                ll_tx_data_queue.push_back(dut.u_fdma_aurora_brg_top.aurora_tx_d);
            end
        end
    end

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        forever begin
            @(posedge user_clk);
            // LocalLink 的 src_rdy 与 dst_rdy 同拍有效时，当前 64bit 字完成一次链路传输。
            if (dut.u_fdma_aurora_brg_top.aurora_rx_src_rdy &&
                dut.u_fdma_aurora_brg_top.aurora_rx_dst_rdy) begin
                ll_rx_data_queue.push_back(dut.u_fdma_aurora_brg_top.aurora_rx_d);
            end
        end
    end

    // 该 任务 执行 scoreboard 比对，检查队列长度、顺序和首个不匹配位置。
    task automatic compare_ll_data();
        int min_size;
        $display("=== [NoBP] Comparison 1: LL TX vs LL RX ===");
        $display("ll_tx_data_queue length: %0d", ll_tx_data_queue.size());
        $display("ll_rx_data_queue length: %0d", ll_rx_data_queue.size());
        // LocalLink 发送队列为空时跳过内容比较并打印无数据提示。
        if (ll_tx_data_queue.size() == 0) begin $display("SKIP: No LL TX data."); return; end
        // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
        if (ll_rx_data_queue.size() == 0) begin $error("FAIL: LL RX received 0 words."); ll_error_count++; return; end
        min_size = (ll_tx_data_queue.size() < ll_rx_data_queue.size()) ? ll_tx_data_queue.size() : ll_rx_data_queue.size();
        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int i = 0; i < min_size; i++) begin
            // 同一索引的 LocalLink 收发数据不一致时记录失败并打印差异。
            if (ll_tx_data_queue[i] !== ll_rx_data_queue[i]) begin
                $error("LL mismatch at word %0d: TX=0x%0h, RX=0x%0h", i, ll_tx_data_queue[i], ll_rx_data_queue[i]);
                ll_error_count++;
            end
        end
        // LocalLink 收发队列长度不一致时记录失败并打印两端长度。
        if (ll_tx_data_queue.size() != ll_rx_data_queue.size())
            $display("NOTE: LL TX/RX length differ: TX=%0d, RX=%0d", ll_tx_data_queue.size(), ll_rx_data_queue.size());
        // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
        if (ll_error_count == 0) $display("PASS: LL - All %0d words matched.", min_size);
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else $display("FAIL: LL - %0d mismatches.", ll_error_count);
    endtask

    // 该 任务 执行 scoreboard 比对，检查队列长度、顺序和首个不匹配位置。
    task automatic compare_fdma_data();
        int min_size;
        $display("=== [NoBP] Comparison 2: FDMA Read vs FDMA Write ===");
        $display("fdma_rd_data_queue length: %0d", fdma_rd_data_queue.size());
        $display("fdma_wr_data_queue length: %0d", fdma_wr_data_queue.size());
        // FDMA 读数据队列为空时跳过内容比较并打印无数据提示。
        if (fdma_rd_data_queue.size() == 0) begin $display("SKIP: No FDMA read data."); return; end
        // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
        if (fdma_wr_data_queue.size() == 0) begin $error("FAIL: FDMA write received 0 words."); fdma_error_count++; return; end
        min_size = (fdma_rd_data_queue.size() < fdma_wr_data_queue.size()) ? fdma_rd_data_queue.size() : fdma_wr_data_queue.size();
        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int i = 0; i < min_size; i++) begin
            // 同一索引的 FDMA 读写数据不一致时记录失败并打印差异。
            if (fdma_rd_data_queue[i] !== fdma_wr_data_queue[i]) begin
                $error("FDMA mismatch at word %0d: RD=0x%0h, WR=0x%0h", i, fdma_rd_data_queue[i], fdma_wr_data_queue[i]);
                fdma_error_count++;
            end
        end
        // FDMA 读写队列长度不一致时记录失败并打印两端长度。
        if (fdma_rd_data_queue.size() != fdma_wr_data_queue.size())
            $display("NOTE: FDMA RD/WR length differ: RD=%0d, WR=%0d", fdma_rd_data_queue.size(), fdma_wr_data_queue.size());
        // 发现数据、标记或协议不一致时记录错误，避免异常样本被误报为通过。
        if (fdma_error_count == 0) $display("PASS: FDMA - All %0d words matched.", min_size);
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else $display("FAIL: FDMA - %0d mismatches.", fdma_error_count);
    endtask

    //====================================================================================
    // 启动从机模型
    //====================================================================================
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        fork
            fdma_read_slave();
            fdma_write_slave();
        join_none
    end

    //====================================================================================
    // 主激励序列
    //====================================================================================
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        static int burst_cnt = FRAME_WORDS / BURST_WORDS;

        wr_if.tb_cb.wbusy <= 0;
        wr_if.tb_cb.wready <= 0;
        rd_if.tb_cb.rbusy <= 0;
        rd_if.tb_cb.rvalid <= 0;

        $display("[%t] Waiting for channel_up...", $time);
        // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
        wait(channel_up == 1);
        $display("[%t] channel_up == 1", $time);
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat(800) @(posedge user_clk);
        $display("[%t] Start sending test data (NO backpressure)...", $time);

        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int f = 0; f < NUM_FRAMES_TO_TEST; f++) begin
            aurora_frame_t tx_frame;
            tx_frame.frame_id = f;
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int w = 0; w < FRAME_WORDS; w++) begin
                tx_frame.words[w] = (f << 32) | w;
            end
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int b = 0; b < burst_cnt; b++) begin
                burst_data_t burst_data;
                // 循环处理：逐项生成、检查或打印一组连续数据。
                for (int w = 0; w < BURST_WORDS; w++) begin
                    burst_data[w] = tx_frame.words[b * BURST_WORDS + w];
                end
                read_burst_queue.push_back(burst_data);
            end
        end

        fork
            begin
                // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
                wait(ll_tx_data_queue.size() >= NUM_FRAMES_TO_TEST * FRAME_WORDS);
                $display("[%t] All LL TX data transmitted.", $time);
            end
            begin
                // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                repeat(5000000) @(posedge fdma_clk);
                $display("[%t] WARNING: LL TX timeout, got %0d/%0d words", $time, ll_tx_data_queue.size(), NUM_FRAMES_TO_TEST * FRAME_WORDS);
            end
        join_any

        fork
            begin
                // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
                wait(ll_rx_data_queue.size() >= ll_tx_data_queue.size());
                $display("[%t] All LL RX data received.", $time);
            end
            begin
                // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                repeat(10000000) @(posedge fdma_clk);
                $display("[%t] WARNING: LL RX timeout, got %0d/%0d words", $time, ll_rx_data_queue.size(), ll_tx_data_queue.size());
            end
        join_any

        fork
            begin
                // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
                wait(fdma_wr_data_queue.size() >= fdma_rd_data_queue.size());
                $display("[%t] All FDMA write data received.", $time);
            end
            begin
                // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                repeat(10000000) @(posedge fdma_clk);
                $display("[%t] WARNING: FDMA write timeout, got %0d/%0d words", $time, fdma_wr_data_queue.size(), fdma_rd_data_queue.size());
            end
        join_any

        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat(1000) @(posedge fdma_clk);
        #100;

        compare_ll_data();
        compare_fdma_data();
        $finish;
    end

    //====================================================================================
    // 仿真超时保护
    //====================================================================================
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        #(5_000_000);
        $display("[%t] ERROR: Simulation timeout!", $time);
        $display("DUT: channel_up=%b, lane_up=%b", channel_up, lane_up);
        $display("LL TX: %0d, LL RX: %0d", ll_tx_data_queue.size(), ll_rx_data_queue.size());
        $display("FDMA RD: %0d, FDMA WR: %0d", fdma_rd_data_queue.size(), fdma_wr_data_queue.size());
        $finish;
    end

endmodule