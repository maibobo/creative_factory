`timescale 1ns/1ps
// FPGA 平台适配层：仅允许源端已寄存、无毛刺的电平或低速翻转事件。
// 不得用于直接同步短脉冲；本工程 tick 是每 500 个源时钟翻转一次。
module RTDS_FPGA_BIT_CDC (
    input wire src_clk, // 源时钟；SRC_INPUT_REG=0，源业务寄存器负责稳定性
    input wire dst_clk, // 接收域时钟
    input wire src_bit, // 稳定电平/翻转位
    output wire dst_bit // 两级同步输出，业务复位后先吸收历史状态
);
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .SRC_INPUT_REG(0), .INIT_SYNC_FF(1), .SIM_ASSERT_CHK(1)
    ) U_XPM_CDC_SINGLE (
        .src_clk(src_clk), .src_in(src_bit), .dest_clk(dst_clk), .dest_out(dst_bit)
    );
endmodule
