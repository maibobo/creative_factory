// 把板载100MHz通过BUFGCE_DIV四分频成25MHz的1G初始化时钟。
// 主机复位重新开始初始化计数；GT复位先于协议核复位解除。
// 计数和输出在init_clk域更新，复位解除经过本域同步；不由业务数据生成时钟。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_FPGA_1G_INIT (
    input wire                                 clk_100m,                              // 100MHz板载或初始化参考时钟
    input wire                                 rst,                                   // 主机复位，高有效；不由Aurora用户时钟生成
    output wire                                init_clk,                              // 25MHz专用分频初始化时钟
    output reg                                 core_reset,                            // 1G协议核高有效复位
    output reg                                 gt_reset                               // GT高有效复位，早于协议核解除

);


    wire                                       rst_n                       ;    // 低有效全局复位输入
    wire                                       init_rst_n                  ;    // 初始化时钟域同步解除后的复位
    reg           [7:0]                        startup_count               ;    // 1G初始化计数，255后保持


    assign rst_n = !rst                                                    ;    // 低有效全局复位输入

    BUFGCE_DIV #(
        .BUFGCE_DIVIDE(4)
    ) U_BUFGCE_DIV_INIT (
        .I(clk_100m),
        .CE(1'b1),
        .CLR(rst),
        .O(init_clk)
    );

    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_INIT (
        .clk(init_clk),
        .rst_async_n(rst_n),
        .rst_sync_n(init_rst_n)
    );


    // 25MHz初始化时钟沿累加到255后保持，复位重新从0开始。
    always @(posedge init_clk or negedge init_rst_n) begin : update_startup_count
        if (!init_rst_n)
            startup_count <= 8'd0;
        else if (startup_count != 8'hff)
            startup_count <= startup_count + 8'd1;
    end


    // 初始化域先在计数128后解除GT复位，再在255后解除协议核复位；输出均由寄存器形成。
    always @(posedge init_clk or negedge init_rst_n) begin
        if (!init_rst_n) begin
            gt_reset <= 1'b1;
            core_reset <= 1'b1;
        end else begin
            gt_reset <= startup_count < 8'd128;
            core_reset <= startup_count != 8'hff;
        end
    end
endmodule
