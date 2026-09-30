`timescale 1ns/1ps
// 验证接口：控制域和发送域分别采样；test 是全部激励的唯一所有者。
// monitor 在 #1step 观察握手前的稳定值，不把驱动意图当成已传输数据。
interface rtds_1g_test_if(input logic src_clk, input logic user_clk);
    logic rst_n = 0;
    logic [7:0] cfg_byte = 0;
    logic cfg_byte_valid = 0;
    logic user_reset = 1;
    logic channel_up = 0;
    logic tx_ready = 0;
    wire [31:0] tx_data;
    wire [1:0] tx_rem;
    wire tx_sof, tx_eof, tx_valid, configured;
    wire [7:0] configured_id;
    wire [31:0] skipped_periods;
    clocking src_drv_cb @(posedge src_clk);
        default input #1step output #0;
        output rst_n, cfg_byte, cfg_byte_valid;
        input configured, configured_id;
    endclocking
    clocking tx_drv_cb @(posedge user_clk);
        default input #1step output #0;
        output user_reset, channel_up, tx_ready;
        input tx_valid, tx_sof, tx_eof, tx_data, tx_rem, skipped_periods;
    endclocking
    clocking tx_mon_cb @(posedge user_clk);
        default input #1step output #0;
        input rst_n, user_reset, channel_up, tx_ready;
        input tx_valid, tx_sof, tx_eof, tx_data, tx_rem;
    endclocking
    modport driver(clocking src_drv_cb, clocking tx_drv_cb);
    modport monitor(clocking tx_mon_cb);
endinterface
