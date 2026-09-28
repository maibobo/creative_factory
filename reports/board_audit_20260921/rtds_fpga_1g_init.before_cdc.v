`timescale 1ns/1ps
// FPGA平台时钟单元：使用专用BUFGCE_DIV，禁止业务逻辑产生普通布线时钟。
module RTDS_FPGA_1G_INIT (
    input wire clk_100m,    // 100MHz 板载差分时钟单端输入
    input wire rst, // 主机复位，高有效；不由Aurora用户时钟生成
    output wire init_clk,    // BUFGCE_DIV 4分频产生的25MHz初始化时钟
    output wire core_reset,    // 协议核复位，高有效；保持至初始化计数结束
    output wire gt_reset    // GT复位，高有效；先于core释放128拍
);
    wire init_rst_n;    // 初始化域同步释放的复位
    wire rst_n;    // 主机复位取反（低有效内部使用）
    reg [7:0] startup_count; // 初始化域先复位GT，再释放core，避免两种复位职责混淆
    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign rst_n = !rst;
    BUFGCE_DIV #(.BUFGCE_DIVIDE(4)) U_BUFGCE_DIV_INIT (
        .I(clk_100m), .CE(1'b1), .CLR(rst), .O(init_clk)
    );
    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_INIT (
        .clk(init_clk), .rst_async_n(rst_n), .rst_sync_n(init_rst_n)
    );

    always @(posedge init_clk or negedge init_rst_n) begin : update_startup_count
        if (!init_rst_n)
            startup_count <= 8'd0;
        else if (startup_count != 8'hff)
            startup_count <= startup_count + 8'd1;
    end
    // 初始化时钟域先保持GT复位128拍，再允许收发器启动。
    assign gt_reset = !init_rst_n || startup_count < 8'd128;
    // GT释放后继续保持协议核复位，至初始化计数255拍结束。
    assign core_reset = !init_rst_n || startup_count != 8'hff;
endmodule
