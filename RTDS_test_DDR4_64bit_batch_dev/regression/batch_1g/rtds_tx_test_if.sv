`timescale 1ns/1ps
// TX定向前仿接口：FDMA响应由producer拥有，LocalLink ready由consumer拥有。
interface rtds_tx_test_if(input logic fdma_clk,input logic user_clk);
    logic rst_n=0;    // 双域复位（fdma与user侧同源）
    logic channel_up=0;    // 链路up指示（两域共用一份驱动）
    logic [15:0] limit=0;    // 读突发帧数上限（满阈值）
    logic [31:0] raddr;    // FDMA读地址（帧号×16Byte）
    logic rareq,rready;    // FDMA读请求与读ready
    logic rbusy=0,rvalid=0;    // 验证侧响应：读busy与数据valid
    logic [63:0] rdata=0;    // FDMA读返回数据（64bit/拍）
    logic [63:0] tx_data;    // LocalLink发送数据
    logic sof,eof,valid,done;    // 帧首/帧尾/有效/单帧完成标志
    logic [2:0] rem;    // 本拍有效字节数-1（16Byte帧两拍均7）
    logic ready=0;    // LocalLink dst_rdy反压（consumer驱动）
    logic [37:0] dbg_fdma;    // FDMA域调试总线（FIFO占用/溢出等）
    logic [38:0] dbg_user;    // 用户域调试总线（含underflow标志）
    // FDMA域clocking：producer在此响应读请求、驱动读数据
    clocking fdma_cb @(posedge fdma_clk);
        default input #1step output #0;
        input raddr,rareq,rready,dbg_fdma;
        output rst_n,channel_up,limit,rbusy,rvalid,rdata;
    endclocking
    // 用户域clocking：consumer在此驱动ready反压
    clocking tx_cb @(posedge user_clk);
        default input #1step output #0;
        input tx_data,sof,eof,valid,rem,done,dbg_user;
        output ready;
    endclocking
    // 用户域监视clocking：observer只采样发送流与调试总线
    clocking monitor_cb @(posedge user_clk);
        default input #1step output #0;
        input tx_data,sof,eof,valid,rem,ready,dbg_user;
    endclocking
    // modport：producer/consumer/observer三角色权限隔离
    modport producer(clocking fdma_cb);
    modport consumer(clocking tx_cb);
    modport observer(clocking monitor_cb);
endinterface
