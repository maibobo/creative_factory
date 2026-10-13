// 用XPM握手成组传递48bit配置，源域保持数据直到目的域确认。
// src_send发请求，dst_req表示目的侧得到完整数据，dst_ack返回接受确认。
// 多位配置作为一个整体传递，不逐位独立同步；两侧按各自时钟推进。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_FPGA_CFG_CDC (
    input wire                                 src_clk,                               // 源时钟域时钟
    input wire                                 dst_clk,                               // 目的时钟域时钟
    input wire    [47:0]                       src_data,                              // 源域保持的成组数据
    input wire                                 src_send,                              // 源域提交请求
    input wire                                 dst_ack,                               // 目的域已接收的返回确认
    output wire                                src_rcv,                               // 源域收到目的端接受确认
    output wire                                dst_req,                               // 目的域配置请求已到达
    output wire   [47:0]                       dst_data                               // 目的域收到的完整成组数据
);
    xpm_cdc_handshake #(
        .DEST_EXT_HSK(1),
        .DEST_SYNC_FF(4),
        .SRC_SYNC_FF(4),
        .INIT_SYNC_FF(1),
        .SIM_ASSERT_CHK(1),
        .WIDTH(48)
    ) U_XPM_CDC_HANDSHAKE (
        .src_clk(src_clk),
        .src_in(src_data),
        .src_send(src_send),
        .src_rcv(src_rcv),
        .dest_clk(dst_clk),
        .dest_req(dst_req),
        .dest_ack(dst_ack),
        .dest_out(dst_data)
    );
endmodule
