// File: tb_fdma_aurora_brg.sv
// Create Date: 2026/04/28 16:22:12
// 模块名称: tb_backpressure_test
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

// ======================== 参数和类型本地定义 ========================
// 本 package 集中放置该仿真用例的参数、帧结构和共享类型。
package local_pkg;
    // 时钟参数
    // FDMA 时钟周期，单位 ns。
    parameter real FDMA_CLK_PERIOD_NS = 4.0;      // 250 MHz
    // Aurora user_clk 时钟周期，单位 ns。
    parameter real USER_CLK_PERIOD_NS = 6.667;    // 150 MHz
    // 测试配置
    // TEST_MEM_SIZE_BYTES 表示测试地址窗口大小。
    parameter int TEST_MEM_SIZE_BYTES = 4 * 1024; // 4KB
    // FDMA_BURST_LEN_BYTES 表示单次 FDMA 突发字节数。
    parameter int FDMA_BURST_LEN_BYTES = 512;
    // AURORA_FRAME_BYTES 表示单个 Aurora 测试帧字节数。
    parameter int AURORA_FRAME_BYTES = 1024;
    // 本测试平台生成并比较的帧数量。
    parameter int NUM_FRAMES_TO_TEST = 5;
    // 派生参数
    // 单个 FDMA 突发包含的 64bit 数据字数量。
    parameter int BURST_WORDS = FDMA_BURST_LEN_BYTES / 8;   // 64
    // 单帧包含的 64bit 数据字数量。
    parameter int FRAME_WORDS = AURORA_FRAME_BYTES / 8;     // 128
    // 事务类型
    // 结构体把一组关联字段合成一个对象，方便队列、scoreboard 和任务传递。
    typedef struct {
        int frame_id;
        logic [63:0] words [0:FRAME_WORDS-1];
    } aurora_frame_t;
endpackage

// 导入本 测试平台 的本地参数和类型，后续模块/任务可直接使用。
import local_pkg::*;

// ======================== 接口定义 ========================
// FDMA 读接口模型封装 rareq、rbusy、rvalid、rready 等握手信号。
interface fdma_read_if(input logic clk, input logic rst_n);
    logic [31:0] raddr;
    logic        rareq;
    logic        rbusy;
    logic [63:0] rdata;
    logic        rvalid;

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport dut(output raddr, rareq, input rbusy, rdata, rvalid);
    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport tb (input raddr, rareq, output rbusy, rdata, rvalid);
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tb_cb @(posedge clk); default input #1step output #1step;
        input raddr, rareq;
        output rbusy, rdata, rvalid;
    endclocking
endinterface

// FDMA 写接口模型封装 wareq、wbusy、wvalid、wready 等握手信号。
interface fdma_write_if(input logic clk, input logic rst_n);
    logic [31:0] waddr;
    logic        wareq;
    logic        wbusy;
    logic [63:0] wdata;
    logic        wvalid;
    logic [15:0] wsize;

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport dut(output waddr, wareq, wdata, wvalid, wsize, input wbusy);
    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport tb (input waddr, wareq, wdata, wvalid, wsize, output wbusy);
    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tb_cb @(posedge clk); default input #1step output #1step;
        input waddr, wareq, wdata, wvalid, wsize;
        output wbusy;
    endclocking
endinterface

// Aurora LocalLink 接口模型封装数据、帧边界和 ready/valid 握手。
interface aurora_ll_if(input logic clk, input logic rst_n);
    // TX 方向 (DUT 输出)
    logic [63:0] tx_d;
    logic        tx_sof;
    logic        tx_eof;
    logic [2:0]  tx_rem;
    logic        tx_src_rdy;
    logic        tx_dst_rdy;
    // RX 方向 (DUT 输入)
    logic [63:0] rx_d;
    logic        rx_sof;
    logic        rx_eof;
    logic [2:0]  rx_rem;
    logic        rx_src_rdy;
    logic        rx_dst_rdy;

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport dut(output tx_d, tx_sof, tx_eof, tx_rem, tx_src_rdy,
                input tx_dst_rdy,
                input rx_d, rx_sof, rx_eof, rx_rem, rx_src_rdy,
                output rx_dst_rdy);

    // modport 明确 DUT 与 TB 两侧的信号方向，降低接线歧义。
    modport tb (input tx_d, tx_sof, tx_eof, tx_rem, tx_src_rdy,
                output tx_dst_rdy,
                output rx_d, rx_sof, rx_eof, rx_rem, rx_src_rdy,
                input rx_dst_rdy);

    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking tx_mon_cb @(posedge clk); default input #1step;
        input tx_d, tx_sof, tx_eof, tx_rem, tx_src_rdy;
    endclocking

    // clocking block 固定采样和驱动偏移，减少 TB 与 DUT 的竞争。
    clocking rx_drv_cb @(posedge clk); default output #1step;
        output rx_d, rx_sof, rx_eof, rx_rem, rx_src_rdy;
        input  rx_dst_rdy;
    endclocking
endinterface

// ======================== 测试平台 顶层 ========================
// tb_simple 模块入口；基础桥接测试平台：不经过 Aurora IP，直接验证 FDMA 到 LocalLink 再回写的桥接逻辑。
module tb_simple;

    // 导入本 测试平台 的本地参数和类型，后续模块/任务可直接使用。
    import local_pkg::*;

    // 时钟与复位
    logic fdma_clk, fdma_rst_n;
    logic user_clk, user_rst_n;
    logic sys_reset, channel_up;

    // 生成时钟
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial fdma_clk = 0;
    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #(FDMA_CLK_PERIOD_NS/2) fdma_clk = ~fdma_clk;
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial user_clk = 0;
    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #(USER_CLK_PERIOD_NS/2) user_clk = ~user_clk;

    // 复位序列
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        fdma_rst_n = 0; user_rst_n = 0;
        sys_reset = 1;
        channel_up = 0;
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat(5) @(posedge fdma_clk);
        fdma_rst_n = 1; user_rst_n = 1;
        sys_reset = 0;
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat(5) @(posedge user_clk);
        channel_up = 1;
    end

    // 实例化接口
    fdma_read_if   rd_if (fdma_clk, fdma_rst_n);
    fdma_write_if  wr_if (fdma_clk, fdma_rst_n);
    aurora_ll_if   aur_if(user_clk, user_rst_n);

    // DUT 例化（需要确保 fdma_aurora_brg_顶层 模块存在）
    fdma_aurora_brg_top dut (
        .fdma_clk      (fdma_clk),
        .fdma_rstn     (fdma_rst_n),
        .user_clk      (user_clk),
        .user_rstn     (user_rst_n),
        .channel_up    (channel_up),
        .cfg_tx_burst_limit(16'd0),
        .fdma_raddr    (rd_if.raddr),
        .fdma_rareq    (rd_if.rareq),
        .fdma_rbusy    (rd_if.rbusy),
        .fdma_rdata    (rd_if.rdata),
        .fdma_rvalid   (rd_if.rvalid),
        .fdma_waddr    (wr_if.waddr),
        .fdma_wareq    (wr_if.wareq),
        .fdma_wbusy    (wr_if.wbusy),
        .fdma_wdata    (wr_if.wdata),
        .fdma_wvalid   (wr_if.wvalid),
        .fdma_wsize    (wr_if.wsize),
        .aurora_tx_d   (aur_if.tx_d),
        .aurora_tx_sof (aur_if.tx_sof),
        .aurora_tx_eof (aur_if.tx_eof),
        .aurora_tx_rem (aur_if.tx_rem),
        .aurora_tx_src_rdy (aur_if.tx_src_rdy),
        .aurora_tx_dst_rdy (aur_if.tx_dst_rdy),
        .aurora_rx_d   (aur_if.rx_d),
        .aurora_rx_sof (aur_if.rx_sof),
        .aurora_rx_eof (aur_if.rx_eof),
        .aurora_rx_rem (aur_if.rx_rem),
        .aurora_rx_src_rdy (aur_if.rx_src_rdy),
        .aurora_rx_dst_rdy (aur_if.rx_dst_rdy)
    );

    //===========================================================
    //  等待读请求并按 FDMA 读从机时序响应。
    //===========================================================
    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    // - 当 rareq=1 且当前 rbusy=0 时，下一周期拉高 rbusy 表示接受请求。
    // 连续提供 rvalid 数据，共 BURST_WORDS 拍。
    // 最后一拍 rvalid 被 DUT 接收后的下一周期拉低 rbusy。
    //===========================================================
    // 该 任务 模拟/驱动 FDMA 读侧行为，把期望数据送入 DUT。
    task automatic fdma_read_slave();
        logic [63:0] burst_data_queue [$];
        automatic logic [63:0] burst_data[0:BURST_WORDS-1];
        // Aurora 环回激励与监测说明。
        // 原注释编码已损坏，按当前代码上下文保留为调试说明。
        forever begin
            // 等待读请求并按 FDMA 读从机时序响应。
            @(posedge fdma_clk);
            while (!(rd_if.tb_cb.rareq === 1 && rd_if.rbusy === 0))
                @(posedge fdma_clk);

            // 等待读请求并按 FDMA 读从机时序响应。
            @(posedge fdma_clk);
            rd_if.tb_cb.rbusy <= 1;

            // 原注释编码已损坏，按当前代码上下文保留为调试说明。
            // 等待读请求并按 FDMA 读从机时序响应。
            // 原注释编码已损坏，按当前代码上下文保留为调试说明。
            wait (read_burst_queue.size() > 0);
            
            burst_data = read_burst_queue.pop_front();

            // 连续提供 rvalid 数据，共 BURST_WORDS 拍。
            for (int i = 0; i < BURST_WORDS; i++) begin
                @(posedge fdma_clk);
                rd_if.tb_cb.rdata  <= burst_data[i];
                rd_if.tb_cb.rvalid <= 1;
            end
            // 等待读请求并按 FDMA 读从机时序响应。
            @(posedge fdma_clk);
            rd_if.tb_cb.rvalid <= 0;
            rd_if.tb_cb.rbusy  <= 0;
        end
    endtask

    //===========================================================
    //  等待写请求并按 FDMA 写从机时序响应。
    //===========================================================
    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    // - 当 wareq=1 且当前 wbusy=0 时，下一周期拉高 wbusy 表示接受请求。
    // 随后接收 W_SIZE/8 拍 wvalid 数据。
    // 等待写请求并按 FDMA 写从机时序响应。
    //===========================================================
    // 该 任务 模拟/驱动 FDMA 写侧行为，并记录 DUT 写回的数据。
    task automatic fdma_write_slave();
        // 获取本次 FDMA 写突发长度，单位为 64bit 数据字。
        int num_words = 0;
        int timeout = 0;
        forever begin
            // 等待写请求并按 FDMA 写从机时序响应。
            @(posedge fdma_clk);
            // 原注释编码已损坏，按当前代码上下文保留为调试说明。
            //if (!(wr_if.tb_cb.wareq && !wr_if.wbusy)) begin
            //    $display("[%t] Write slave: start to wait wareq=1, wbusy=0", $time);
            //end
            while (!(wr_if.tb_cb.wareq === 1 && wr_if.wbusy === 0)) begin
                @(posedge fdma_clk);
                //超时++;
                //if (timeout > 100000) begin
                //    $error("fdma_write_slave timeout: no wareq detected");
                //    原注释编码已损坏，按当前代码上下文保留为调试说明。
                //end
            end
            // 原注释编码已损坏，按当前代码上下文保留为调试说明。
            //$display("[%t] Write slave: request accepted (wareq=1, wbusy=0), about to set wbusy=1", $time);
            // 等待读请求并按 FDMA 读从机时序响应。
            @(posedge fdma_clk);
            wr_if.tb_cb.wbusy <= 1;
            //$display("[%t] Write slave: wbusy set to 1", $time);
            
            num_words = wr_if.wsize / 8;      
            $display("[%t] Write slave: wsize=%0d bytes -> %0d words", $time, wr_if.wsize, num_words);
            //if (num_words == 0) begin
            //    $warning("[%t] wsize=0, using BURST_WORDS=%0d", $time, BURST_WORDS);
            //    num_words = 64;
            //end else begin
            //    $display("[%t] Write burst: wsize=%0d, num_words=%0d", $time, wr_if.wsize, num_words);
            //end
            // 原注释编码已损坏，按当前代码上下文保留为调试说明。
            for (int i = 0; i < num_words; i++) begin
                @(posedge fdma_clk);
                // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                while (wr_if.tb_cb.wvalid !== 1) begin
                    @(posedge fdma_clk);
                    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                    //if (i == 0 && $time > 10000) $display("[%t] Warning: Write slave timeout: waiting for first wvalid...", $time);
                end
                
                // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                actual_queue.push_back(wr_if.tb_cb.wdata);
                $display("[%t] Write slave: received word %0d: data=0x%0h, queue size now %0d", $time, i, wr_if.tb_cb.wdata, actual_queue.size());
            end
            // 等待写请求并按 FDMA 写从机时序响应。
            @(posedge fdma_clk);
            wr_if.tb_cb.wbusy <= 0;
            //$display("[%t] Write slave: burst done, wbusy cleared", $time);
        end
    endtask

    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    typedef logic [63:0] burst_data_t [0:BURST_WORDS-1];
    burst_data_t read_burst_queue [$];

    // 监测与比对队列
    reg [63:0] expected_queue [$];
    reg [63:0] actual_queue   [$];
    integer    error_count = 0;

    //监测 Aurora TX 输出
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    //initial begin
    //    forever begin
    //        @(posedge user_clk);
    //        if (aur_if.tx_mon_cb.tx_src_rdy) begin
    //            期望_queue.push_back(aur_if.tx_mon_cb.tx_d);
    //        end
    //    end
    //end

    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    // 也可以用 $readmemh 或手动方式初始化期望队列，避免主激励循环重复追加。
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        int idx = 0;
        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int f = 0; f < NUM_FRAMES_TO_TEST; f++) begin
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int w = 0; w < FRAME_WORDS; w++) begin
                expected_queue[idx++] = (f << 32) | w;
            end
        end
    end

    // 自动比对 任务
    // 该 任务 执行 scoreboard 比对，检查队列长度、顺序和首个不匹配位置。
    task automatic compare_data();

        int min_size;
        // 期望队列和实际队列长度不一致时记录失败并打印长度差异。
        if (expected_queue.size() != actual_queue.size()) begin
            $error("Data length mismatch: expected %0d words, got %0d words", expected_queue.size(), actual_queue.size());
            error_count++;
        end
        
        min_size = (expected_queue.size() < actual_queue.size()) ? expected_queue.size() : actual_queue.size();

        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int f = 0; f < NUM_FRAMES_TO_TEST; f++) begin
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int w = 0; w < FRAME_WORDS; w++) begin
                int idx = f * FRAME_WORDS + w;
                // 首个错误附近仍在有效范围内时打印上下文窗口。
                if(idx <= min_size)
                    // 当前位置实际数据与期望数据不一致时打印首个错误样本。
                    if (actual_queue[idx] !== expected_queue[idx]) begin
                        $error("Frame %0d word %0d: expected 0x%0h, got 0x%0h", f, w, expected_queue[idx], actual_queue[idx]);
                        error_count++;
                    end
            end
        end        

        //for (int i = 0; i < min_size; i++) begin
        //    if (expected_queue[i] !== actual_queue[i]) begin
        //        $error("Data mismatch at index %0d: expected 0x%0h, got 0x%0h", i, expected_queue[i], actual_queue[i]);
        //        错误_count++;
        //    end
        //end

        if (error_count == 0)
            $display("PASS: All data matched (%0d transactions).", min_size);
        // 未达到收尾条件时，保持本阶段输出并等待后续握手。
        else
            $display("FAIL: %0d mismatches detected.", error_count);
    endtask

    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        fork
            fdma_read_slave();
            fdma_write_slave();
        join_none
    end

    // 主激励序列
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin

        int burst_cnt = FRAME_WORDS / BURST_WORDS;  // 每帧 2 个 突发
        wr_if.tb_cb.wbusy <= 0;
        rd_if.tb_cb.rbusy <= 0;
        // 绛夊緟閫氶亾寤虹珛
        wait(channel_up == 1);
        $display("channel_up == 1");
        // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
        repeat(800) @(posedge user_clk);        
        $display("Start sending test data...");

        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int f = 0; f < NUM_FRAMES_TO_TEST; f++) begin
            aurora_frame_t tx_frame;
            tx_frame.frame_id = f;
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (int w = 0; w < FRAME_WORDS; w++) begin
                tx_frame.words[w] = (f << 32) | w;
            end

            // 1. 发送 Aurora 帧到 RX 端（模拟远端）
            send_aurora_frame(tx_frame);

            // 2. 准备 FDMA 读的 突发 数据（与发送帧数据相同）
            for (int b = 0; b < burst_cnt; b++) begin
                burst_data_t burst_data;
                // 循环处理：逐项生成、检查或打印一组连续数据。
                for (int w = 0; w < BURST_WORDS; w++) begin
                    burst_data[w] = tx_frame.words[b * BURST_WORDS + w];
                end
                // 等待读请求并按 FDMA 读从机时序响应。
                read_burst_queue.push_back(burst_data);
            end
        end

        // 等待所有数据流经 DUT
        repeat (20000) begin
            @(posedge fdma_clk);
            //if (actual_queue.size() >= expected_queue.size()) begin
            //    $display("actual_queue.size() %0d has already >= expected_queue.size() %0d", actual_queue.size(), expected_queue.size());
            //end
            //if((actual_queue.size()==640) && (expected_queue.size()==640 )) begin
            //    $display("actual_queue.size() %0d == expected_queue.size() %0d", actual_queue.size(), expected_queue.size());
                //跳出循环；
        end
        compare_data(); 
        $finish;
    end

    // Aurora 环回激励与监测说明。
    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task automatic send_aurora_frame(input aurora_frame_t frame);
        int timeout = 0;
        // 循环处理：逐项生成、检查或打印一组连续数据。
        for (int w = 0; w < FRAME_WORDS; w++) begin
            @(posedge user_clk);
            aur_if.rx_drv_cb.rx_d       <= frame.words[w];
            aur_if.rx_drv_cb.rx_sof     <= (w == 0);
            aur_if.rx_drv_cb.rx_eof     <= (w == FRAME_WORDS-1);
            aur_if.rx_drv_cb.rx_rem     <= 3'b111;
            aur_if.rx_drv_cb.rx_src_rdy <= 1;
            while (!aur_if.rx_drv_cb.rx_dst_rdy) begin
                @(posedge user_clk);
                timeout++;
                // 等待数据流收敛超过上限时报告仿真超时。
                if (timeout > 10000) begin
                    $error("send_aurora_frame: rx_dst_rdy stuck at 0 or X");
                    disable fork;
                end
            end;
        end
        @(posedge user_clk);
        aur_if.rx_drv_cb.rx_src_rdy <= 0;
        aur_if.rx_drv_cb.rx_sof     <= 0;
        aur_if.rx_drv_cb.rx_eof     <= 0;
    endtask

    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    
    // 在参数定义区域增加反压模式选择。
    parameter int BACKPRESSURE_MODE = 1;  // 0:鏃? 1:杩炵画100% 2:闅旀媿50% 3:鍥哄畾闂撮殧 4:闅忔満
    
    // ready/valid 握手控制，用于表达当前模块是否可接收或发送数据。
    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        int stall_duration, idle_duration;
        int seed = $time;
        forever begin
            // 根据 BACKPRESSURE_MODE 选择对应状态的输出赋值和下一拍转移。
            case (BACKPRESSURE_MODE)
                0: begin  // 鏃犲弽鍘嬶紝姘歌繙灏辩华
                    aur_if.tx_dst_rdy = 1'b1;
                    @(posedge user_clk);
                end
                1: begin  // 长时间连续反压。
                    stall_duration = 200;
                    idle_duration = 900;
                    // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                    repeat (idle_duration) begin
                        aur_if.tx_dst_rdy = 1'b1;
                        @(posedge user_clk);
                    end
                    // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                    repeat (stall_duration) begin
                        aur_if.tx_dst_rdy = 1'b0;
                        @(posedge user_clk);
                    end
                    aur_if.tx_dst_rdy = 1'b1;
                end
                2: begin  // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                    // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                    aur_if.tx_dst_rdy = 1'b1;
                    @(posedge user_clk);
                    aur_if.tx_dst_rdy = 1'b0;
                    @(posedge user_clk);
                end
                3: begin  // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                    stall_duration = 5;
                    idle_duration = 10;
                    // 随机停顿周期设置。
                    repeat (idle_duration) begin
                        aur_if.tx_dst_rdy = 1'b1;
                        @(posedge user_clk);
                    end
                    // 随机停顿周期设置。
                    repeat (stall_duration) begin
                        aur_if.tx_dst_rdy = 1'b0;
                        @(posedge user_clk);
                    end
                end
                4: begin  // 闅忔満鍙嶅帇锛堥殢鏈洪棿闅斿拰闅忔満鎸佺画鏃堕棿锛?
                    stall_duration = $urandom_range(1, 20);   // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                    idle_duration  = $urandom_range(5, 30);   // 原注释编码已损坏，按当前代码上下文保留为调试说明。
                    // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                    repeat (idle_duration) begin
                        aur_if.tx_dst_rdy = 1'b1;
                        @(posedge user_clk);
                    end
                    // 延时/重复等待：按指定周期数推进仿真或模拟反压停顿。
                    repeat (stall_duration) begin
                        aur_if.tx_dst_rdy = 1'b0;
                        @(posedge user_clk);
                    end
                end
                // 未列出的编码回到安全取值，避免状态机停留在非法状态。
                default: begin
                    aur_if.tx_dst_rdy = 1'b1;
                    @(posedge user_clk);
                end
            endcase
        end
    end







    

endmodule