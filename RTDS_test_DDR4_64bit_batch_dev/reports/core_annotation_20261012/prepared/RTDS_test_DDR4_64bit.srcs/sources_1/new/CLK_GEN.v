// 板载差分参考时钟通过输入缓冲和时钟IP形成业务使用的时钟。
// locked未成立时给出系统复位；各使用域仍需按本域规则处理复位解除。
// 本文件只连接时钟IP，不在普通业务逻辑中分频生成时钟。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module CLK_GEN(

    input                                      clk_i       ,                          // 对应接口时钟，使用域由连接关系确定


    output                                     clk_250m    ,                          // 250MHz业务/时间基准时钟
    output                                     clk_156m    ,                          // 156.25MHz时钟输出
    output                                     clk_100m    ,                          // 100MHz板载或初始化参考时钟

    output                                     sys_rst                                // 高有效系统复位

    );


    wire                                       locked                      ;    // 时钟IP输出锁定状态，未锁定时保持系统复位


    clk_wiz_0 clk_wiz_0_inst
    (

    .clk_out1(clk_250m),
        .clk_out2(clk_156m),
        .clk_out3(clk_100m),
        .locked(locked),
        .clk_in1(clk_i));


    assign sys_rst = !locked                                               ;    // 高有效系统复位


endmodule
