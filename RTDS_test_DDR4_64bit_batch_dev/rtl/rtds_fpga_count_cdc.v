// 把源域32bit累计计数以Gray编码跨到目的时钟域。
// 输入计数与src_clk同步，目的域得到有同步延迟的计数值。
// 用于统计读回，不能把目的域延迟后的值当成同拍数据接受事件。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_FPGA_COUNT_CDC (
    input wire                                 src_clk,                               // 源时钟域时钟
    input wire                                 dst_clk,                               // 目的时钟域时钟
    input wire    [31:0]                       src_count,                             // 单步递增的累计丢帧数
    output wire   [31:0]                       dst_count                              // Gray 同步并还原的目的域计数
);
    xpm_cdc_gray #(
        .DEST_SYNC_FF(2),
        .INIT_SYNC_FF(1),
        .REG_OUTPUT(1),
        .SIM_ASSERT_CHK(0),
        .SIM_LOSSLESS_GRAY_CHK(0),
        .WIDTH(32)
    ) U_XPM_CDC_GRAY (
        .src_clk(src_clk),
        .src_in_bin(src_count),
        .dest_clk(dst_clk),
        .dest_out_bin(dst_count)
    );
endmodule
