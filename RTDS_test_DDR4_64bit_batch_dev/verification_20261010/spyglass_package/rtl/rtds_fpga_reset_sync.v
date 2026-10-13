`timescale 1ns/1ps
// FPGA 平台复位单元：异步拉低、目标域四拍同步释放。
// 链路复位是业务运行控制；不能接到保存上电配置的 rst_async_n。
module RTDS_FPGA_RESET_SYNC (
    input wire clk, // 必须在复位释放过程中持续运行
    input wire rst_async_n, // 主机逻辑复位，低有效
    output wire rst_sync_n // 本时钟域叶级寄存器使用的复位
);
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF(4), .INIT_SYNC_FF(1), .RST_ACTIVE_HIGH(0)
    ) U_XPM_CDC_ASYNC_RST (
        .src_arst(rst_async_n), .dest_clk(clk), .dest_arst(rst_sync_n)
    );
endmodule
