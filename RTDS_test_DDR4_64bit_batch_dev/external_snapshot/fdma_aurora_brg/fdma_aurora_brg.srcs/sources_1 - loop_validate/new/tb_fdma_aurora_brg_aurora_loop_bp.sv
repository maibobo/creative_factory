`timescale 1ns / 1ps
// File: tb_fdma_aurora_brg_aurora_loop_bp.sv

//////////////////////////////////////////////////////////////////////////////////
// 模块名称: tb_fdma_aurora_brg_aurora_loop_bp
// 用途:
//   验证 FDMA 到 Aurora 再回到 FDMA 的完整环路数据流。
//   当前版本保留反压代码入口，但默认关闭随机反压，便于定位基础时序问题。
// 数据路径:
//   FDMA 读从机模型 -> DUT TX 桥 -> TX FIFO -> Aurora 本地链路发送端
//   -> Aurora 64B66B/GT 自环 -> Aurora 本地链路接收端
//   -> DUT RX 桥 -> RX FIFO -> FDMA 写从机模型
// 测试规模:
//   共发送 3 帧，每帧 1536 字节，即 192 个 64 位数据字。
//   每个 FDMA 突发长度为 512 字节，即 64 个 64 位数据字。
//   因此每帧拆成 3 个 FDMA 突发，整个用例共 9 个突发、576 个数据字。
// 比对策略:
//   1. 本地链路层: 比对 Aurora 发送端实际送出的数据与接收端实际收到的数据。
//   2. FDMA 层: 比对 FDMA 读侧真实握手数据与 FDMA 写侧真实握手数据。
//   3. 调试层: 在相邻数据边界建立队列，定位数据第一次变多、变少或错位的位置。
//////////////////////////////////////////////////////////////////////////////////

// ======================== 参数和类型定义 ========================
// 本 package 集中放置该仿真用例的参数、帧结构和共享类型。
package loop_bp_pkg;
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
    parameter int AURORA_FRAME_BYTES = 1536;       // 每帧 3 个 FDMA 突发
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
import loop_bp_pkg::*;

// ======================== FDMA 读接口模型 ========================
// FDMA 读接口模型封装 rareq、rbusy、rvalid、rready 等握手信号。
interface fdma_read_if_bp(input logic clk, input logic rst_n);
    // DUT 驱动读地址、读请求和读就绪；测试平台驱动读忙、读数据和读有效。
    logic [31:0] raddr;
    logic        rareq;
    logic        rbusy;
    logic [63:0] rdata;
    logic        rvalid;
    logic        rready;

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport dut(output raddr, rareq, rready, input rbusy, rdata, rvalid);
    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport tb (input raddr, rareq, rready, output rbusy, rdata, rvalid);
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    // 输入提前一个仿真步采样 DUT 输出，输出由 clocking 事件驱动，避免测试平台和 DUT 在同一时刻竞争。
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tb_cb @(posedge clk); default input #1step output #0;
        input raddr, rareq, rready;
        output rbusy, rdata, rvalid;
    endclocking
endinterface

// ======================== FDMA 写接口模型 ========================
// FDMA 写接口模型封装 wareq、wbusy、wvalid、wready 等握手信号。
interface fdma_write_if_bp(input logic clk, input logic rst_n);
    // DUT 驱动写地址、写请求、写数据、写有效和写长度；测试平台驱动写忙和写就绪。
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
    // 写接口同样使用 clocking block 固定采样和驱动顺序，避免握手信号发生仿真竞争。
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tb_cb @(posedge clk); default input #1step output #0;
        input waddr, wareq, wdata, wvalid, wsize;
        output wbusy, wready;
    endclocking
endinterface

// ======================== 测试平台顶层 ========================
// tb_fdma_aurora_brg_aurora_loop_bp 模块入口；带反压主 测试平台：在 FDMA 读写侧插入延迟/停顿，定位 FIFO、握手和数据边界问题。
module tb_fdma_aurora_brg_aurora_loop_bp;

    // 导入本 测试平台 的本地参数和类型，后续模块/任务可直接使用。
    import loop_bp_pkg::*;
    typedef logic [63:0] data_queue_t[$];

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
    // GT 串行自环
    //====================================================================================
    wire txp, txn;
    wire rxp, rxn;

    assign rxp = txp;
    assign rxn = txn;

    //====================================================================================
    // FDMA 接口实例
    //====================================================================================
    fdma_read_if_bp   rd_if (fdma_clk, fdma_rstn);
    fdma_write_if_bp  wr_if (fdma_clk, fdma_rstn);

    //====================================================================================
    // DUT 例化
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
    // RX FIFO 溢出监测
    //====================================================================================
    wire rx_fifo_overflow = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_overflow;
    integer overflow_count = 0;

    // Aurora user_clk 时钟域时序逻辑，处理 LocalLink 帧、FIFO 读写或链路侧统计。
    always @(posedge user_clk) begin
        // 发现数据、标记或协议异常时记录失败信息并保留现场。
        if (rx_fifo_overflow) begin
            overflow_count++;
            $error("[%t] RX FIFO OVERFLOW detected! Aurora RX data dropped.", $time);
        end
    end

    //====================================================================================
    // FDMA 读从机模型
    //====================================================================================
    typedef logic [63:0] burst_data_t [0:BURST_WORDS-1];
    burst_data_t read_burst_queue [$];

    // 测试平台预期发送的读数据流；每完成一次 rvalid/rready 握手就记录一个数据字。
    data_queue_t fdma_rd_data_queue;

    // 该 任务 模拟/驱动 FDMA 读侧行为，把期望数据送入 DUT。
    task automatic fdma_read_slave();
        // 当前 64 个数据字读突发的本地缓存。
        automatic logic [63:0] burst_data[0:BURST_WORDS-1];
        // 预留的随机延迟变量，当前随机反压代码保持注释状态。
        automatic int bp_delay;
        // 读突发序号，仅用于打印和调试。
        automatic int burst_idx = 0;
        forever begin
            // 每个 FDMA 时钟轮询一次 DUT 读请求。
            @(posedge fdma_clk);
            // 只有测试平台读从机空闲时才接受新的读请求。
            while (!(rd_if.tb_cb.rareq === 1 && rd_if.rbusy === 0))
                @(posedge fdma_clk);

            $display("[%t] RD_SLAVE: Burst %0d request received, raddr=0x%0h", $time, burst_idx, rd_if.raddr);

            // 突发间随机延迟入口，当前关闭。
            bp_delay = ($urandom_range(0, 9) < 3) ? $urandom_range(1, 8) : 0;
            // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
            repeat(bp_delay) @(posedge fdma_clk);

            // 应答本次读请求；DUT 看到 rbusy 后从 RD_REQ 进入 RD_DATA。
            rd_if.tb_cb.rbusy <= 1;
            // 请求应答阶段和数据阶段必须隔开 1 个 FDMA 时钟。
            // 最后一拍 rvalid 被 DUT 接收后的下一周期拉低 rbusy。
            // 但不会被 rd_数据字_cnt 计数，最终卡在 rd_数据字_cnt=63。
            @(posedge fdma_clk);

            // DUT 可能早于主激励填充数据队列就发起请求，因此这里等待队列非空。
            wait (read_burst_queue.size() > 0);
            // 本次读请求只弹出一个 512 字节、64 数据字的突发。
            burst_data = read_burst_queue.pop_front();

            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int i = 0; i < BURST_WORDS; i++) begin
                // 预留的突发内 rvalid 随机停顿入口，当前关闭。
                bp_delay = ($urandom_range(0, 9) < 2) ? $urandom_range(1, 4) : 0;
                // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                repeat(bp_delay) begin
                    rd_if.tb_cb.rvalid <= 0;
                    @(posedge fdma_clk);
                end

                // 驱动下一个数据字，并保持到 DUT 完成握手接收。
                rd_if.tb_cb.rdata  <= burst_data[i];
                // 等待 rready 期间保持 rvalid 为高。
                rd_if.tb_cb.rvalid <= 1;

                // 前进到下一个时钟沿，让 DUT 采样 rvalid/rdata。
                @(posedge fdma_clk);
                // 如果 rready 为低，同一个数据字继续保持 有效。
                while (!(rd_if.rvalid === 1 && rd_if.rready === 1))
                    @(posedge fdma_clk);
                // 只有真实握手发生后，才记录这个预期发送数据字。
                fdma_rd_data_queue.push_back(burst_data[i]);
            end
            $display("[%t] RD_SLAVE: Burst %0d done, sent %0d words, rd_queue_size=%0d, remaining_bursts=%0d",
                     $time, burst_idx, BURST_WORDS, fdma_rd_data_queue.size(), read_burst_queue.size());
            // 本突发的 64 个数据握手全部完成。
            burst_idx++;

            // 最后一个数据字握手后立即撤销 rvalid，防止 rready 持续为高时尾字被重复接收。
            rd_if.tb_cb.rvalid <= 0;
            // 清空 rdata，让意外采到旧数据的问题在波形和日志中更明显。
            rd_if.tb_cb.rdata  <= '0;
            // rbusy 在数据结束后多保持一个完整周期，把最后数据拍和突发完成阶段分开。
            @(posedge fdma_clk);
            // 释放本突发，DUT 可从 RD_WAIT 回到 RD_IDLE 或 RD_REQ。
            rd_if.tb_cb.rbusy  <= 0;
        end
    endtask

    //====================================================================================
    // FDMA 写从机模型
    //====================================================================================
    // 测试平台写从机实际接收的写数据流。
    data_queue_t fdma_wr_data_queue;

    // 该 任务 模拟/驱动 FDMA 写侧行为，并记录 DUT 写回的数据。
    task automatic fdma_write_slave();
        // 当前写突发期望接收的 64 位数据字数量。
        int num_words = 0;
        // 预留的写侧随机反压变量，当前关闭。
        automatic int bp_delay;
        // 写突发序号，仅用于打印和调试。
        automatic int burst_idx = 0;
        forever begin
            // 每个 FDMA 时钟轮询一次 DUT 写请求。
            @(posedge fdma_clk);
            // 等待 DUT 发起写突发且测试平台写从机空闲。
            while (!(wr_if.tb_cb.wareq === 1 && wr_if.wbusy === 0))
                @(posedge fdma_clk);

            $display("[%t] WR_SLAVE: Burst %0d request received, waddr=0x%0h, wsize=%0d",
                     $time, burst_idx, wr_if.waddr, wr_if.wsize);

            // 突发间随机延迟入口，当前关闭。
            bp_delay = ($urandom_range(0, 9) < 3) ? $urandom_range(1, 8) : 0;
            // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
            repeat(bp_delay) @(posedge fdma_clk);

            // 应答写请求。
            wr_if.tb_cb.wbusy <= 1;
            // 当前无写侧反压，每个 valid 数据拍都接收。
            wr_if.tb_cb.wready <= 1;

            // 将突发字节数转换为 64 位数据字数量。
            num_words = wr_if.wsize / 8;

            // wvalid 与 wready 同拍有效时完成一个写数据字传输。
            for (int i = 0; i < num_words; i++) begin
                // 预留的突发内 wready 随机停顿入口，当前关闭。
                bp_delay = ($urandom_range(0, 9) < 2) ? $urandom_range(1, 4) : 0;
                // 随机反压延迟非零时插入等待周期，模拟下游暂时不可用。
                if (bp_delay > 0) begin
                    wr_if.tb_cb.wready <= 0;
                    // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                    repeat(bp_delay) @(posedge fdma_clk);
                    wr_if.tb_cb.wready <= 1;
                end

                // 前进到时钟沿后检查写握手。
                @(posedge fdma_clk);
                // 等待 DUT 在测试平台 就绪 时给出 有效 数据。
                while (!(wr_if.wvalid === 1 && wr_if.wready === 1))
                    @(posedge fdma_clk);
                // 精确记录一个已接收的写数据字。
                fdma_wr_data_queue.push_back(wr_if.wdata);
            end
            $display("[%t] WR_SLAVE: Burst %0d done, received %0d words, wr_queue_size=%0d",
                     $time, burst_idx, num_words, fdma_wr_data_queue.size());
            // 一个完整写突发已接收完成。
            burst_idx++;

            // 撤销 wbusy 和 wready 前保留一个响应间隔。
            @(posedge fdma_clk);
            // 标记写从机空闲。
            wr_if.tb_cb.wbusy <= 0;
            // 非活动突发期间不接收写数据。
            wr_if.tb_cb.wready <= 0;
        end
    endtask

    //====================================================================================
    // 监测与比对
    //====================================================================================
    // DUT TX 输出侧观察到的 Aurora 本地链路数据。
    data_queue_t ll_tx_data_queue;
    // DUT RX 输入侧观察到的 Aurora 本地链路数据。
    data_queue_t ll_rx_data_queue;

    // DUT FDMA 读接口真正接收的数据字，采样条件为 rd_if.rvalid 与 rd_if.rready 同拍有效。
    data_queue_t fdma_rd_hs_queue;
    // 写入 DUT 内部 TX FIFO 的数据字。
    data_queue_t tx_fifo_wr_queue;
    // 从 DUT 内部 TX FIFO 读出的数据字。
    data_queue_t tx_fifo_rd_queue;
    // 写入 DUT 内部 RX FIFO 的数据字。
    data_queue_t rx_fifo_wr_queue;
    // 从 DUT 内部 RX FIFO 读出的数据字。
    data_queue_t rx_fifo_rd_queue;
    // 测试平台 FDMA 写接口真正接收的数据字，采样条件为 wr_if.wvalid 与 wr_if.wready 同拍有效。
    data_queue_t fdma_wr_hs_queue;

    // 顶层测试平台接口观察到的 FDMA 读握手。
    wire fdma_rd_hs_mon = fdma_rstn && rd_if.rvalid && rd_if.rready;
    // 顶层测试平台接口观察到的 FDMA 写握手。
    wire fdma_wr_hs_mon = fdma_rstn && wr_if.wvalid && wr_if.wready;

    // 层次引用探针，用于观察 TX FIFO 写侧。
    wire tx_fifo_wr_en_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.wr_en;
    wire [63:0] tx_fifo_wdata_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_wdata;
    // 层次引用探针，用于观察 TX FIFO 读侧。
    wire tx_fifo_rd_en_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_en;
    wire [63:0] tx_fifo_rdata_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_rdata;

    // Aurora 本地链路 TX 真实传输条件：源端和目的端均就绪。
    wire ll_tx_hs_mon = user_rstn &&
                         dut.u_fdma_aurora_brg_top.aurora_tx_src_rdy &&
                         dut.u_fdma_aurora_brg_top.aurora_tx_dst_rdy;
    // Aurora 本地链路 RX 真实传输条件：源端和目的端均就绪。
    wire ll_rx_hs_mon = user_rstn &&
                         dut.u_fdma_aurora_brg_top.aurora_rx_src_rdy &&
                         dut.u_fdma_aurora_brg_top.aurora_rx_dst_rdy;

    // 层次引用探针，用于观察 RX FIFO 写侧。
    wire rx_fifo_wr_en_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_en;
    wire [63:0] rx_fifo_wdata_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_wdata;
    // 层次引用探针，用于观察 RX FIFO 读侧。
    wire rx_fifo_rd_en_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.rd_en;
    wire [63:0] rx_fifo_rdata_mon = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_rdata;

    integer ll_error_count  = 0;
    integer fdma_error_count = 0;

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        forever begin
            // TX 侧监测运行在 Aurora 用户时钟域。
            @(posedge user_clk);
            // TX FIFO 读出监测有效时累计读出总数。
            if (tx_fifo_rd_en_mon) begin
                // 记录每个从 TX FIFO 读出的数据字。
                tx_fifo_rd_queue.push_back(tx_fifo_rdata_mon);
            end
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if (ll_tx_hs_mon) begin
                // 记录每个真正交给 Aurora 本地链路 TX 的数据字。
                ll_tx_data_queue.push_back(dut.u_fdma_aurora_brg_top.aurora_tx_d);
            end
        end
    end

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        forever begin
            // RX 侧本地链路和 FIFO 写监测运行在 Aurora 用户时钟域。
            @(posedge user_clk);
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if (ll_rx_hs_mon) begin
                // 记录每个 Aurora 本地链路 RX 送出的数据字。
                ll_rx_data_queue.push_back(dut.u_fdma_aurora_brg_top.aurora_rx_d);
            end
            // RX FIFO 写入监测有效时累计写入总数。
            if (rx_fifo_wr_en_mon) begin
                // 记录每个写入 RX FIFO 的数据字。
                rx_fifo_wr_queue.push_back(rx_fifo_wdata_mon);
            end
        end
    end

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        forever begin
            // FDMA 侧监测运行在 FDMA 时钟域。
            @(posedge fdma_clk);
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if (fdma_rd_hs_mon) begin
                // 记录 DUT 从读从机实际接收的数据字。
                fdma_rd_hs_queue.push_back(rd_if.rdata);
            end
            // TX FIFO 写入监测有效时累计写入总数。
            if (tx_fifo_wr_en_mon) begin
                // 记录 DUT 写入 TX FIFO 的数据字，理想情况下应与 FDMA 读握手队列一致。
                tx_fifo_wr_queue.push_back(tx_fifo_wdata_mon);
            end
            // RX FIFO 读出监测有效时累计读出总数。
            if (rx_fifo_rd_en_mon) begin
                // 记录 DUT 从 RX FIFO 取出的数据字。
                rx_fifo_rd_queue.push_back(rx_fifo_rdata_mon);
            end
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if (fdma_wr_hs_mon) begin
                // 记录测试平台写从机实际接收的数据字。
                fdma_wr_hs_queue.push_back(wr_if.wdata);
            end
        end
    end

    //====================================================================================
    // DUT 内部状态监测
    //====================================================================================
    // RX 桥写状态机和 FIFO 状态。
    wire [1:0] rx_wr_state  = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_state;
    wire [6:0] rx_wr_word_cnt = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_word_cnt;
    wire       rx_wdata_hold_valid = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wdata_hold_valid;
    wire       rx_fifo_empty = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_empty;
    wire [10:0] rx_fifo_rd_cnt = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_rd_cnt;
    wire [10:0] rx_fifo_wr_cnt = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.fifo_wr_cnt;

    // TX 桥读状态机和 FIFO 状态。
    wire [1:0] tx_rd_state  = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_state;
    wire [6:0] tx_rd_word_cnt = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_word_cnt;
    wire [9:0] tx_fifo_wr_cnt = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_wr_cnt;
    wire [9:0] tx_fifo_rd_cnt = dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.fifo_rd_cnt;

    // 该 任务 执行 scoreboard 比对，检查队列长度、顺序和首个不匹配位置。
    task automatic compare_ll_data();
        int min_size;
        $display("=== [BP] Comparison 1: LL TX vs LL RX ===");
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
        $display("=== [BP] Comparison 2: FDMA Read vs FDMA Write ===");
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

    // 该 任务 打印观测结果，帮助定位数据在哪个边界开始偏移。
    task automatic report_queue_pair(
        input string lhs_name,
        ref data_queue_t lhs_queue,
        input string rhs_name,
        ref data_queue_t rhs_queue
    );
        // 两个队列共同可比较的数据字数量。
        int min_size;
        // 共同前缀中的数据不匹配数量。
        int mismatch_count;
        // 左右队列第一次数据不同的位置。
        int first_mismatch;
        // 只比较共同前缀，长度差异单独报告。
        min_size = (lhs_queue.size() < rhs_queue.size()) ? lhs_queue.size() : rhs_queue.size();
        mismatch_count = 0;
        first_mismatch = -1;

        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int i = 0; i < min_size; i++) begin
            // 同一索引的左右队列数据不一致时记录首个不匹配位置。
            if (lhs_queue[i] !== rhs_queue[i]) begin
                mismatch_count++;
                // 首次发现不匹配时锁存索引，后续差异不覆盖首错位置。
                if (first_mismatch < 0)
                    first_mismatch = i;
            end
        end

        // lhs 和 rhs 表示传入本任务的左侧队列和右侧队列。
        $display("DBG_PAIR %-18s -> %-18s : lhs=%0d rhs=%0d common=%0d mismatches=%0d",
                 lhs_name, rhs_name, lhs_queue.size(), rhs_queue.size(), min_size, mismatch_count);
        // 已记录首个不匹配位置时打印首错详情。
        if (first_mismatch >= 0) begin
            // 第一个 mismatch 用来定位数据第一次被改变或错位的位置。
            $display("DBG_FIRST_MISMATCH %s -> %s @%0d: lhs=0x%0h rhs=0x%0h",
                     lhs_name, rhs_name, first_mismatch,
                     lhs_queue[first_mismatch], rhs_queue[first_mismatch]);
        end
        // 左右比较队列长度不一致时记录失败并保存长度差异。
        if (lhs_queue.size() != rhs_queue.size()) begin
            // 如果 mismatch 为 0 但长度不同，通常表示共同前缀正确，只有尾部多或少。
            $display("DBG_LENGTH_DIFF %s=%0d %s=%0d delta(rhs-lhs)=%0d",
                     lhs_name, lhs_queue.size(), rhs_name, rhs_queue.size(),
                     rhs_queue.size() - lhs_queue.size());
            // 右侧队列更长时打印第一个额外数据字。
            if (lhs_queue.size() < rhs_queue.size()) begin
                // 右侧队列更长，打印右侧队列第一个额外数据字。
                $display("DBG_FIRST_EXTRA %s[%0d]=0x%0h",
                         rhs_name, lhs_queue.size(), rhs_queue[lhs_queue.size()]);
            end else begin
                // 左侧队列更长，打印左侧队列第一个额外数据字。
                $display("DBG_FIRST_EXTRA %s[%0d]=0x%0h",
                         lhs_name, rhs_queue.size(), lhs_queue[rhs_queue.size()]);
            end
        end
    endtask

    // 该 任务 打印观测结果，帮助定位数据在哪个边界开始偏移。
    task automatic report_dataflow_observations();
        // 打印每个关键数据边界的累计计数。
        $display("=== [BP] Dataflow Observation Counters ===");
        $display("TB intended FDMA RD queue : %0d", fdma_rd_data_queue.size());
        $display("FDMA RD handshake queue   : %0d", fdma_rd_hs_queue.size());
        $display("TX FIFO write queue       : %0d", tx_fifo_wr_queue.size());
        $display("TX FIFO read queue        : %0d", tx_fifo_rd_queue.size());
        $display("LL TX handshake queue     : %0d", ll_tx_data_queue.size());
        $display("LL RX handshake queue     : %0d", ll_rx_data_queue.size());
        $display("RX FIFO write queue       : %0d", rx_fifo_wr_queue.size());
        $display("RX FIFO read queue        : %0d", rx_fifo_rd_queue.size());
        $display("FDMA WR handshake queue   : %0d", fdma_wr_hs_queue.size());
        $display("DUT TX rd_state=%0d rd_word_cnt=%0d fifo_wr_cnt=%0d fifo_rd_cnt=%0d",
                 tx_rd_state, tx_rd_word_cnt, tx_fifo_wr_cnt, tx_fifo_rd_cnt);
        $display("DUT RX wr_state=%0d wr_word_cnt=%0d hold_valid=%0d fifo_wr_cnt=%0d fifo_rd_cnt=%0d",
                 rx_wr_state, rx_wr_word_cnt, rx_wdata_hold_valid, rx_fifo_wr_cnt, rx_fifo_rd_cnt);

        // 比较测试平台预期读流与接口真实读握手流。
        report_queue_pair("tb_rd_intended", fdma_rd_data_queue,
                          "fdma_rd_hs", fdma_rd_hs_queue);
        // 比较读握手与 TX FIFO 写入，用于定位 TX 写使能或写数据问题。
        report_queue_pair("fdma_rd_hs", fdma_rd_hs_queue,
                          "tx_fifo_wr", tx_fifo_wr_queue);
        // 比较 TX FIFO 写入与读出，用于定位 FIFO 读侧或跨时钟问题。
        report_queue_pair("tx_fifo_wr", tx_fifo_wr_queue,
                          "tx_fifo_rd", tx_fifo_rd_queue);
        // 比较 TX FIFO 读出与本地链路 TX，用于定位 TX 本地链路握手或数据生成问题。
        report_queue_pair("tx_fifo_rd", tx_fifo_rd_queue,
                          "ll_tx_hs", ll_tx_data_queue);
        // 比较本地链路 RX 与 RX FIFO 写入，用于定位 RX 捕获或 FIFO 写侧问题。
        report_queue_pair("ll_rx_hs", ll_rx_data_queue,
                          "rx_fifo_wr", rx_fifo_wr_queue);
        // 比较 RX FIFO 读出与 FDMA 写握手，用于定位 RX FDMA 写侧问题。
        report_queue_pair("rx_fifo_rd", rx_fifo_rd_queue,
                          "fdma_wr_hs", fdma_wr_hs_queue);
        // 端到端真实握手流比较，不依赖测试平台预期队列。
        report_queue_pair("fdma_rd_hs", fdma_rd_hs_queue,
                          "fdma_wr_hs", fdma_wr_hs_queue);
    endtask

    // 该 任务 等待数据流进入静默/完成状态，避免过早结束仿真。
    task automatic wait_dataflow_quiet(input int quiet_user_cycles, input int timeout_user_cycles);
        int quiet_count;
        int timeout_count;
        int last_fdma_rd_hs_size;
        int last_tx_fifo_wr_size;
        int last_tx_fifo_rd_size;
        int last_ll_tx_size;
        int last_ll_rx_size;
        int last_rx_fifo_wr_size;
        int last_rx_fifo_rd_size;
        int last_fdma_wr_hs_size;

        quiet_count = 0;
        timeout_count = 0;
        last_fdma_rd_hs_size = fdma_rd_hs_queue.size();
        last_tx_fifo_wr_size = tx_fifo_wr_queue.size();
        last_tx_fifo_rd_size = tx_fifo_rd_queue.size();
        last_ll_tx_size = ll_tx_data_queue.size();
        last_ll_rx_size = ll_rx_data_queue.size();
        last_rx_fifo_wr_size = rx_fifo_wr_queue.size();
        last_rx_fifo_rd_size = rx_fifo_rd_queue.size();
        last_fdma_wr_hs_size = fdma_wr_hs_queue.size();

        while ((quiet_count < quiet_user_cycles) && (timeout_count < timeout_user_cycles)) begin
            @(posedge user_clk);
            timeout_count++;
            // 当前通道完成有效握手时才推进数据、计数器或队列指针。
            if ((last_fdma_rd_hs_size == fdma_rd_hs_queue.size()) &&
                (last_tx_fifo_wr_size == tx_fifo_wr_queue.size()) &&
                (last_tx_fifo_rd_size == tx_fifo_rd_queue.size()) &&
                (last_ll_tx_size == ll_tx_data_queue.size()) &&
                (last_ll_rx_size == ll_rx_data_queue.size()) &&
                (last_rx_fifo_wr_size == rx_fifo_wr_queue.size()) &&
                (last_rx_fifo_rd_size == rx_fifo_rd_queue.size()) &&
                (last_fdma_wr_hs_size == fdma_wr_hs_queue.size())) begin
                quiet_count++;
            end else begin
                quiet_count = 0;
                last_fdma_rd_hs_size = fdma_rd_hs_queue.size();
                last_tx_fifo_wr_size = tx_fifo_wr_queue.size();
                last_tx_fifo_rd_size = tx_fifo_rd_queue.size();
                last_ll_tx_size = ll_tx_data_queue.size();
                last_ll_rx_size = ll_rx_data_queue.size();
                last_rx_fifo_wr_size = rx_fifo_wr_queue.size();
                last_rx_fifo_rd_size = rx_fifo_rd_queue.size();
                last_fdma_wr_hs_size = fdma_wr_hs_queue.size();
            end
        end

        // 所有监测队列保持静默达到要求周期后打印稳定提示。
        if (quiet_count >= quiet_user_cycles)
            $display("[%t] Dataflow quiet for %0d user_clk cycles.", $time, quiet_user_cycles);
        // 等待超时仍未静默时，打印队列活动超时提示。
        else
            $display("[%t] WARNING: Dataflow quiet wait timeout after %0d user_clk cycles.", $time, timeout_user_cycles);
    endtask

    //====================================================================================
    // 启动 FDMA 从机模型
    //====================================================================================
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        // 读从机和写从机与主激励并行运行，随时响应 DUT 请求。
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
        // 一个 192 数据字 Aurora 帧包含 3 个 FDMA 突发。
        static int burst_cnt = FRAME_WORDS / BURST_WORDS;

        // 初始化测试平台驱动的写侧控制信号。
        wr_if.tb_cb.wbusy <= 0;
        wr_if.tb_cb.wready <= 0;
        // 初始化测试平台驱动的读侧控制信号。
        rd_if.tb_cb.rbusy <= 0;
        rd_if.tb_cb.rvalid <= 0;

        // 等待 Aurora 链路进入可传输状态。
        $display("[%t] Waiting for channel_up...", $time);
        // 等待条件：阻塞当前流程直到目标状态或握手条件成立。
        wait(channel_up == 1);
        $display("[%t] channel_up == 1", $time);
        // 链路 就绪 后额外等待一段用户时钟，避开初始稳定过程。
        repeat(800) @(posedge user_clk);
        $display("[%t] Start sending test data (WITH backpressure)...", $time);

        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int f = 0; f < NUM_FRAMES_TO_TEST; f++) begin
            // 构造一帧 192 数据字测试数据，高位放帧号，低位放帧内序号。
            aurora_frame_t tx_frame;
            tx_frame.frame_id = f;
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int w = 0; w < FRAME_WORDS; w++) begin
                tx_frame.words[w] = (f << 32) | w;
            end
            // 每帧拆成 3 个 64 数据字 FDMA 读突发。
            for (int b = 0; b < burst_cnt; b++) begin
                burst_data_t burst_data;
                // 循环处理：逐项生成、检查或打印一组连续数据。
                for (int w = 0; w < BURST_WORDS; w++) begin
                    burst_data[w] = tx_frame.words[b * BURST_WORDS + w];
                end
                // 将突发加入队列，等待读从机在 DUT 请求时返回。
                read_burst_queue.push_back(burst_data);
            end
        end
        $display("[%t] read_burst_queue aleady be established...", $time);

        // 等待 FDMA 读从机发送完所有测试数据。
        fork
            begin
                // 正常结束条件：读从机已提供全部测试数据字。
                wait(fdma_rd_data_queue.size() >= NUM_FRAMES_TO_TEST * FRAME_WORDS);
                $display("[%t] All FDMA read data sent, rd_queue_size=%0d.", $time, fdma_rd_data_queue.size());
            end
            begin
                // 如果 DUT 停止发起读请求，超时分支防止仿真无限挂起。
                repeat(27500) @(posedge fdma_clk);  // 110us
                $display("[%t] WARNING: FDMA read timeout, got %0d/%0d words", $time, fdma_rd_data_queue.size(), NUM_FRAMES_TO_TEST * FRAME_WORDS);
            end
        join_any

        // 写侧完成由链路静默等待统一覆盖，避免尾部数据还在 Aurora 或 RX 管线中时提前比对。
        // 等待读侧完成或超时后，继续等待所有监测队列稳定。
        wait_dataflow_quiet(1000, 50000);
        #100;

        // 先打印逐边界调试计数，再执行原有端到端比对。
        report_dataflow_observations();
        compare_ll_data();
        compare_fdma_data();

        // 反压测试总结。
        $display("=== Backpressure Test Summary ===");
        $display("RX FIFO overflow events: %0d", overflow_count);
        // 观测到 RX FIFO 溢出事件时打印风险提示。
        if (overflow_count > 0)
            $display("WARNING: RX FIFO overflow occurred. Data may be dropped.");
        // 没有观测到 RX FIFO 溢出时，打印容量足够的总结信息。
        else
            $display("No RX FIFO overflow - FIFO depth (2048) sufficient for this backpressure level.");

        $finish;
    end

    //====================================================================================
    // 仿真超时保护
    //====================================================================================
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        #(110_000); // 110us 超时
        $display("[%t] ERROR: Simulation timeout!", $time);
        $display("DUT: channel_up=%b, lane_up=%b", channel_up, lane_up);
        $display("LL TX: %0d, LL RX: %0d", ll_tx_data_queue.size(), ll_rx_data_queue.size());
        $display("FDMA RD: %0d, FDMA WR: %0d", fdma_rd_data_queue.size(), fdma_wr_data_queue.size());
        report_dataflow_observations();
        $finish;
    end

endmodule