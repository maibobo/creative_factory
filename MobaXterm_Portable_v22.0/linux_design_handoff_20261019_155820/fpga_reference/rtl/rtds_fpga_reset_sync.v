// 低有效复位封装：异步进入复位，在目标clk连续运行后同步解除。
// rst_async_n为外部复位，rst_sync_n供本时钟域业务逻辑使用。
// 使用XPM复位同步结构，不改变上游复位来源或极性。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_FPGA_RESET_SYNC (
    input wire                                 clk,                                   // 必须在复位释放过程中持续运行
    input wire                                 rst_async_n,                           // 外部低有效异步复位
    output wire                                rst_sync_n                             // 本时钟域同步解除后的低有效复位
);
    xpm_cdc_async_rst #(
        .DEST_SYNC_FF(4),
        .INIT_SYNC_FF(1),
        .RST_ACTIVE_HIGH(0)
    ) U_XPM_CDC_ASYNC_RST (
        .src_arst(rst_async_n),
        .dest_clk(clk),
        .dest_arst(rst_sync_n)
    );
endmodule
