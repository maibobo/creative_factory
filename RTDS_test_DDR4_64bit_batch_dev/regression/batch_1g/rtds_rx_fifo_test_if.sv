`timescale 1ns/1ps
// 验证接口：集中定义引脚所有权与clocking采样，协议驱动不直接写DUT层次。
interface rtds_rx_fifo_test_if (input logic user_clk, input logic mem_clk);
    logic rst_n=0, user_ready=0, rx_valid=0, rx_sof=0, rx_eof=0;    // 用户侧驱动：复位、接收允许、写入流控制
    logic [63:0] rx_data=0;    // 用户侧写入数据（64bit原拍）
    logic [2:0] rx_rem=7;    // 封装REM（本层不使用，默认整拍7）
    wire rx_ready, frame_valid, fifo_full, fifo_almost_full, length_error;    // DUT输出：反压、帧有效、满/近满、长度错误（兼容口恒0）
    wire [63:0] frame_data;    // 存储侧读出的64bit原拍
    logic frame_ready=0;    // 读侧ready（验证侧驱动）
    wire [31:0] dropped_frames;    // 满丢弃的32bit字计数（跨域同步）
    // 用户域驱动clocking：写入激励在此驱动，采样rx_ready
    clocking user_drv_cb @(posedge user_clk);
        default input #1step output #0;
        output rst_n,user_ready,rx_data,rx_sof,rx_eof,rx_rem,rx_valid;
        input rx_ready;
    endclocking
    // 存储域驱动clocking：读侧ready在此驱动，采样状态输出
    clocking mem_drv_cb @(posedge mem_clk);
        default input #1step output #0;
        output frame_ready;
        input dropped_frames,frame_valid,fifo_full;
    endclocking
    // 存储域监视clocking：只读采样握手与数据，供输出检查器
    clocking mem_mon_cb @(posedge mem_clk);
        default input #1step output #0;
        input rst_n,frame_valid,frame_ready,frame_data;
    endclocking
    // modport：写驱动/读驱动/监视三种角色隔离
    modport user_drv_cb_access (clocking user_drv_cb);
    modport mem_drv_cb_access (clocking mem_drv_cb);
    modport mem_mon_cb_access (clocking mem_mon_cb);
endinterface
