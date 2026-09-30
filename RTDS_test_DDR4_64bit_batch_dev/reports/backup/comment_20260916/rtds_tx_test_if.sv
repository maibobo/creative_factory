`timescale 1ns/1ps
// TX定向前仿接口：FDMA响应由producer拥有，LocalLink ready由consumer拥有。
interface rtds_tx_test_if(input logic fdma_clk,input logic user_clk);
    logic rst_n=0;
    logic channel_up=0;
    logic [15:0] limit=0;
    logic [31:0] raddr;
    logic rareq,rready;
    logic rbusy=0,rvalid=0;
    logic [63:0] rdata=0;
    logic [63:0] tx_data;
    logic sof,eof,valid,done;
    logic [2:0] rem;
    logic ready=0;
    logic [37:0] dbg_fdma;
    logic [38:0] dbg_user;
    clocking fdma_cb @(posedge fdma_clk);
        default input #1step output #0;
        input raddr,rareq,rready,dbg_fdma;
        output rst_n,channel_up,limit,rbusy,rvalid,rdata;
    endclocking
    clocking tx_cb @(posedge user_clk);
        default input #1step output #0;
        input tx_data,sof,eof,valid,rem,done,dbg_user;
        output ready;
    endclocking
    clocking monitor_cb @(posedge user_clk);
        default input #1step output #0;
        input tx_data,sof,eof,valid,rem,ready,dbg_user;
    endclocking
    modport producer(clocking fdma_cb);
    modport consumer(clocking tx_cb);
    modport observer(clocking monitor_cb);
endinterface
