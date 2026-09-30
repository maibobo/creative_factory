`timescale 1ns/1ps
// FPGA 平台适配层：48bit 配置采用 XPM 完整请求/确认握手。
// 源数据从 send 拉高前保持至 rcv；再次发送必须先完成四相返回空闲。
// XPM 无业务复位端口：主机复位须使 send/ack 保持低，且两域时钟均运行
// 至少 16 拍后才提交新配置。Aurora 链路复位不复位这份上电配置。
module RTDS_FPGA_CFG_CDC (
    input wire src_clk, // DDR/控制域，250MHz
    input wire dst_clk, // 1G 用户域，31.25MHz
    input wire [47:0] src_data, // 一次传递 {Vin[31:0],duty[15:0]}
    input wire src_send, // 源端请求，收到 src_rcv 后撤销
    input wire dst_ack, // 目的端确认，dst_req 撤销后撤销
    output wire src_rcv, // 源端已完成数据传递
    output wire dst_req, // 目的端数据有效请求
    output wire [47:0] dst_data // 在 dst_req 有效时整体采样
);
    xpm_cdc_handshake #(
        .DEST_EXT_HSK(1), .DEST_SYNC_FF(4), .SRC_SYNC_FF(4),
        .INIT_SYNC_FF(1), .SIM_ASSERT_CHK(1), .WIDTH(48)
    ) U_XPM_CDC_HANDSHAKE (
        .src_clk(src_clk), .src_in(src_data), .src_send(src_send),
        .src_rcv(src_rcv), .dest_clk(dst_clk), .dest_req(dst_req),
        .dest_ack(dst_ack), .dest_out(dst_data)
    );
endmodule
