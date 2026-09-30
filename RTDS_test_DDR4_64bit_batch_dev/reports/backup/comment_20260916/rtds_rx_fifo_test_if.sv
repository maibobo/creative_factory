`timescale 1ns/1ps
// 验证接口：集中定义引脚所有权与clocking采样，协议驱动不直接写DUT层次。
interface rtds_rx_fifo_test_if (input logic user_clk, input logic mem_clk);
    logic rst_n=0, user_ready=0, rx_valid=0, rx_sof=0, rx_eof=0;
    logic [63:0] rx_data=0;
    logic [2:0] rx_rem=7;
    wire rx_ready, frame_valid, fifo_full, fifo_almost_full, length_error;
    wire [63:0] frame_data;
    logic frame_ready=0;
    wire [31:0] dropped_frames;
    clocking user_drv_cb @(posedge user_clk);
        default input #1step output #0;
        output rst_n,user_ready,rx_data,rx_sof,rx_eof,rx_rem,rx_valid;
        input rx_ready;
    endclocking
    clocking mem_drv_cb @(posedge mem_clk);
        default input #1step output #0;
        output frame_ready;
        input dropped_frames,frame_valid,fifo_full;
    endclocking
    clocking mem_mon_cb @(posedge mem_clk);
        default input #1step output #0;
        input rst_n,frame_valid,frame_ready,frame_data;
    endclocking
    modport user_drv_cb_access (clocking user_drv_cb);
    modport mem_drv_cb_access (clocking mem_drv_cb);
    modport mem_mon_cb_access (clocking mem_mon_cb);
endinterface
