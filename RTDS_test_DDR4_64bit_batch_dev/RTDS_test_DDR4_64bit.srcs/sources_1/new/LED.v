// 按SYS_CLK和LED_CYCLE产生周期指示，计数在i_sys_clk域运行。
// 复位时LED为1、计数为0；每半周期翻转一次输出。
// LED只表示周期计数活动，不作为DDR校准或PCIe/Aurora就绪判断。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module LED #
    (
        parameter                                  SYS_CLK      = 125000000,          // 输入时钟频率，单位Hz
        parameter                                  LED_CYCLE    = 1000000             // LED完整指示周期，单位µs
    )
    (

    input                                      i_sys_clk   ,                          // 本模块业务时钟
    input                                      i_sys_rst   ,                          // 本模块高有效复位

    output reg                                 o_led                                  // 周期翻转的LED输出

    );


    localparam                                 CYCLE = LED_CYCLE * (SYS_CLK / 1000000);    // 由时钟频率和µs参数换算的周期拍数


    reg           [31:0]                       led_cnt                                ;    // LED半周期拍计数


    // i_sys_clk沿累加半周期计数，到设定末拍翻转LED并归零；同步复位令LED为1。
    always@(posedge i_sys_clk)
    begin
        if(i_sys_rst)
        begin
            o_led       <= 1'b1;
            led_cnt <= 32'd0;
        end
        else if(led_cnt == CYCLE/2 - 1)

        begin
            o_led       <= ~o_led;
            led_cnt <= 32'd0;
        end
        else
        begin
            o_led       <= o_led;
            led_cnt <= led_cnt + 32'b1;
        end
    end


endmodule
