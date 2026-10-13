`timescale 1ns/1ps
// FPGA 平台计数跨域：源计数每拍最多加一，目的域允许跳过中间值。
// 复位期间计数可回零；统计值只在两域复位稳定释放后供软件使用。
module RTDS_FPGA_COUNT_CDC (
    input wire src_clk, // 10G 用户域
    input wire dst_clk, // DDR/PCIe 控制域
    input wire [31:0] src_count, // 单步递增的累计丢帧数
    output wire [31:0] dst_count // Gray 同步并还原的目的域计数
);
    xpm_cdc_gray #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(1), .REG_OUTPUT(1),
        .SIM_ASSERT_CHK(0), .SIM_LOSSLESS_GRAY_CHK(0), .WIDTH(32)
    ) U_XPM_CDC_GRAY (
        .src_clk(src_clk), .src_in_bin(src_count), .dest_clk(dst_clk), .dest_out_bin(dst_count)
    );
endmodule
