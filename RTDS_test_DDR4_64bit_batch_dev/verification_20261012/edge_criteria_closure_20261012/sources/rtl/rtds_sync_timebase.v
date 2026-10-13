// 同一个250MHz时钟与复位产生2µs源事件和50µs GPIO。
// 每500拍翻转tick_toggle_2us一次；翻转间隔是2µs，完整高低周期为4µs。
// GPIO每12500拍一周期，高低各6250拍；每个GPIO周期包含25个源事件。
// 低有效复位清计数和输出；事件与GPIO不会因1G反压或断链暂停。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_SYNC_TIMEBASE (
    input wire                                 clk_250m,                              // 250MHz业务/时间基准时钟
    input wire                                 rst_n,                                 // 低有效全局复位输入
    output reg                                 tick_toggle_2us,                       // 250MHz域每2µs翻转一次的事件标志
    output reg                                 cpu_sync_50us                          // 50µs GPIO输出，高低各25µs
);
    reg           [8:0]                        count_2us                   ;    // 500拍源事件计数
    reg           [13:0]                       count_50us                  ;    // 12500拍GPIO周期计数


    // 250MHz沿同时推进两个计数；2µs计数归零时翻转事件，50µs计数产生6250高/6250低，复位同时清输出。
    always @(posedge clk_250m or negedge rst_n) begin
        if (!rst_n) begin
            count_2us        <= 9'd0;
            count_50us       <= 14'd0;
            tick_toggle_2us <= 1'b0;
            cpu_sync_50us   <= 1'b0;
        end else begin
            count_2us <= (count_2us == 9'd499) ? 9'd0 : count_2us + 9'd1;
            count_50us <= (count_50us == 14'd12499) ? 14'd0 : count_50us + 14'd1;
            if (count_2us == 9'd0)
                tick_toggle_2us <= ~tick_toggle_2us;
            cpu_sync_50us <= (count_50us < 14'd6250);
        end
    end
endmodule
