`timescale 1ns/1ps
// Exact 250 MHz cycle-level check of the shared 2 us and 50 us timebase.
module tb_rtds_sync;
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    reg clk_250m = 0;
    reg rst_n = 0;
    wire tick_toggle_2us;
    wire cpu_sync_50us;
    integer i;
    integer events_in_50us;
    reg prev_toggle;
    reg expected_gpio;
    reg expected_toggle;

    always #2 clk_250m = ~clk_250m;
    RTDS_SYNC_TIMEBASE dut (
        .clk_250m(clk_250m), .rst_n(rst_n),
        .tick_toggle_2us(tick_toggle_2us), .cpu_sync_50us(cpu_sync_50us)
    );

    initial begin
        repeat (phase2_pick(5,20)) @(negedge clk_250m);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        if (tick_toggle_2us !== 0 || cpu_sync_50us !== 0)
            $fatal(1, "TIMEBASE/RESET");
        rst_n = 1;
        prev_toggle = 0;
        events_in_50us = 0;
        for (i=0; i<25000; i=i+1) begin
            @(posedge clk_250m);
            #1;
            expected_gpio = (i % 12500) < 6250;
            expected_toggle = ((i / 500) % 2) == 0;
            if (cpu_sync_50us !== expected_gpio || tick_toggle_2us !== expected_toggle)
                $fatal(1, "TIMEBASE/CYCLE cycle=%0d gpio=%b tick=%b", i, cpu_sync_50us, tick_toggle_2us);
            if ((i % 12500) == 0) events_in_50us = 0;
            if (tick_toggle_2us != prev_toggle) events_in_50us = events_in_50us + 1;
            if ((i % 12500) == 12499 && events_in_50us != 25)
                $fatal(1, "TIMEBASE/EVENTS got=%0d", events_in_50us);
            prev_toggle = tick_toggle_2us;
        end
        @(negedge clk_250m);
        rst_n = 0;
        #1;
        if (tick_toggle_2us !== 0 || cpu_sync_50us !== 0)
            $fatal(1, "TIMEBASE/ASYNC_RESET");
        $display("TEST PASS tb_rtds_sync 2us=500 cycles 50us=12500 cycles 25 events high=6250 low=6250");
        $finish;
    end
    initial begin
        #120000;
        $fatal(1,"TIMEBASE/TIMEOUT");
    end
endmodule
