`timescale 1ns/1ps
// 验证接口：控制域和发送域分别采样；test 是全部激励的唯一所有者。
// monitor 在 #1step 观察握手前的稳定值，不把驱动意图当成已传输数据。
interface rtds_1g_test_if(input logic src_clk, input logic user_clk);
    logic rst_n = 0;    // 控制域（src_clk 250MHz）低有效复位
    logic [7:0] cfg_byte = 0;    // 串行配置字节（同步字节后跟组号1~10）
    logic cfg_byte_valid = 0;    // 配置字节有效脉冲
    logic user_reset = 1;    // 发送域复位（上电默认处于复位态）
    logic channel_up = 0;    // Aurora链路up指示
    logic tx_ready = 0;    // 发送域反压ready（dst_rdy）
    wire [31:0] tx_data;    // 发送数据（16Byte帧=2拍32bit）
    wire [1:0] tx_rem;    // 本拍有效字节数-1（首拍3=4B，末拍1=2B）
    wire tx_sof, tx_eof, tx_valid, configured;    // 帧边界/有效与已配置标志
    wire [7:0] configured_id;    // 已锁存的配置组号
    wire [31:0] skipped_periods;    // 反压期间跳过的发送周期计数
    // 控制域驱动clocking：复位与配置字节在src_clk上驱动
    clocking src_drv_cb @(posedge src_clk);
        default input #1step output #0;
        output rst_n, cfg_byte, cfg_byte_valid;
        input configured, configured_id;
    endclocking
    // 发送域驱动clocking：user_reset/channel_up/tx_ready激励在user_clk上驱动
    clocking tx_drv_cb @(posedge user_clk);
        default input #1step output #0;
        output user_reset, channel_up, tx_ready;
        input tx_valid, tx_sof, tx_eof, tx_data, tx_rem, skipped_periods;
    endclocking
    // 发送域监视clocking：只采样握手前稳定值，供检查器判定帧边界与节奏
    clocking tx_mon_cb @(posedge user_clk);
        default input #1step output #0;
        input rst_n, user_reset, channel_up, tx_ready;
        input tx_valid, tx_sof, tx_eof, tx_data, tx_rem;
    endclocking
    // modport：driver持有全部激励，monitor只读
    modport driver(clocking src_drv_cb, clocking tx_drv_cb);
    modport monitor(clocking tx_mon_cb);
endinterface
