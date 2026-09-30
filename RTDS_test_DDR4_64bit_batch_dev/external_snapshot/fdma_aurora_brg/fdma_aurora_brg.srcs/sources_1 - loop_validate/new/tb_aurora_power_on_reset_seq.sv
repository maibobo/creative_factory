`timescale 1ns/1ps
// File: tb_aurora_power_on_reset_seq.sv

module tb_aurora_power_on_reset_seq;
    // 设置 PMA_CYCLES 的等待周期上限，防止异常场景下仿真无限挂起。
    localparam integer PMA_CYCLES = 8;
    // 设置 GAP_CYCLES 的等待周期上限，防止异常场景下仿真无限挂起。
    localparam integer GAP_CYCLES = 3;

    reg clk_init = 1'b0;
    reg sys_rst = 1'b0;
    wire pma_init;
    wire reset_pb;
    wire [1:0] state_dbg;
    wire [26:0] count_dbg;
    integer i;

    // 该 always 块产生周期时钟，是本仿真时序推进的节拍源。
    always #10 clk_init = ~clk_init;

    aurora_power_on_reset_seq #(
        .PMA_HOLD_CYCLES  (PMA_CYCLES),
        .RESET_GAP_CYCLES (GAP_CYCLES)
    ) dut (
        .clk_init  (clk_init),
        .sys_rst   (sys_rst),
        .pma_init  (pma_init),
        .reset_pb  (reset_pb),
        .state_dbg (state_dbg),
        .count_dbg (count_dbg)
    );

    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task check_asserted;
        begin
            // 复位有效或链路失锁时清空寄存器、计数器和状态机。
            if (pma_init !== 1'b1 || reset_pb !== 1'b1)
                $fatal(1, "both resets must be asserted");
        end
    endtask

    // 该 任务 封装一段可复用流程，避免 initial 块里堆叠重复时序。
    task run_complete_sequence;
        begin
            sys_rst = 1'b0;
            @(negedge dut.sys_rst_sync[1]);
            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (i = 0; i < PMA_CYCLES - 1; i = i + 1) begin
                @(posedge clk_init); #1;
                check_asserted();
            end
            @(posedge clk_init); #1;
            // 复位有效或链路失锁时清空寄存器、计数器和状态机。
            if (pma_init !== 1'b0 || reset_pb !== 1'b1)
                $fatal(1, "PMA_INIT must release before RESET");

            // 循环处理：逐项生成、检查或打印一组连续数据。
            for (i = 0; i < GAP_CYCLES - 1; i = i + 1) begin
                @(posedge clk_init); #1;
                // 复位有效或链路失锁时清空寄存器、计数器和状态机。
                if (pma_init !== 1'b0 || reset_pb !== 1'b1)
                    $fatal(1, "RESET released before the configured gap");
            end
            @(posedge clk_init); #1;
            // 复位有效或链路失锁时清空寄存器、计数器和状态机。
            if (pma_init !== 1'b0 || reset_pb !== 1'b0 || state_dbg !== 2'd2)
                $fatal(1, "reset sequencer did not reach RUN");
        end
    endtask

    // 时序 always 块在指定时钟/复位边沿更新寄存器状态。
    always @(negedge pma_init)
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (reset_pb !== 1'b1)
            $fatal(1, "RESET must still be asserted when PMA_INIT releases");

    // 时序 always 块在指定时钟/复位边沿更新寄存器状态。
    always @(negedge reset_pb)
        // PMA 初始化未保持低电平时立即报错，验证上电复位初始态。
        if (pma_init !== 1'b0)
            $fatal(1, "RESET cannot release before PMA_INIT");

    // initial 块负责仿真初始化、复位释放、激励启动或最终检查。
    initial begin
        // 初始上电断言检查，包括无 INIT_CLK 边沿时的断言。
        #2 sys_rst = 1'b1;
        #1 check_asserted();
        // 复位保持期内调试状态或计数不为零时报告复位序列异常。
        if (state_dbg !== 2'd0 || count_dbg !== 27'd0)
            $fatal(1, "asynchronous assertion did not clear state");
        run_complete_sequence();

        // 正常运行期间 MMCM 失锁必须重新启动完整复位序列。
        #3 sys_rst = 1'b1;
        #1 check_asserted();
        // 复位保持期内调试状态或计数不为零时报告复位序列异常。
        if (state_dbg !== 2'd0 || count_dbg !== 27'd0)
            $fatal(1, "lock loss did not restart the sequencer");
        run_complete_sequence();

        $display("PASS: Aurora power-on reset sequence");
        $finish;
    end
endmodule