`timescale 1ns/1ps
// 功能：将板载100MHz时钟通过BUFGCE_DIV分频为25MHz初始化时钟。
// 主机复位到来时立即复位初始化计数及输出；复位解除后在25MHz域重新计时。
// 先解除GT复位，再解除协议核复位，为收发器提供启动时间。
// 输出复位由寄存器产生，避免多位计数值变化直接影响复位输出。
module RTDS_FPGA_1G_INIT (
    input  wire          clk_100m,      // 100MHz 板载差分时钟单端输入
    input  wire          rst,           // 主机复位，高有效；不由Aurora用户时钟生成
    output wire          init_clk,      // BUFGCE_DIV 4分频产生的25MHz初始化时钟
    output reg           core_reset,    // 协议核复位，高有效；保持至初始化计数结束
    output reg           gt_reset       // GT复位，高有效；先于core释放128拍

);

    // 复位与启动计数信号。
    wire           rst_n        ;    // 主机复位取反后供低有效复位接口使用。
    wire           init_rst_n   ;    // 25MHz初始化域同步解除后的复位。
    reg     [7:0]  startup_count;    // 计到255后保持，用于分阶段解除复位。


    // 初始化时钟及复位输入。
    assign rst_n = !rst         ;    // 把主机高有效复位转换为内部低有效复位。

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


    // 启动计数及复位输出。
    // 初始化计数到255后保持。
    always @(posedge init_clk or negedge init_rst_n) begin : update_startup_count
        if (!init_rst_n)
            startup_count <= 8'd0;
        else if (startup_count != 8'hff)
            startup_count <= startup_count + 8'd1;
    end

    // 依计数值先解除GT复位，再解除协议核复位。
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
