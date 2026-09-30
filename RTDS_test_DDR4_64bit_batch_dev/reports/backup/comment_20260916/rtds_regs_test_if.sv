`timescale 1ns/1ps
interface rtds_regs_test_if(input logic clk);
    logic rst_n=0, done=0;
    logic[31:0] awaddr=0,wdata=0,araddr=0;
    logic awvalid=0,wvalid=0,arvalid=0,bready=1,rready=1;
    logic[3:0] wstrb=4'hf;
    wire awready,wready,bvalid,arready,rvalid;
    wire[31:0] rdata,command_addr,command_len;
    wire[1:0] bresp,rresp;
    wire start,ack,clear_irq,clear_inter;
    clocking driver_cb @(posedge clk);
        default input #1step output #0;
        output rst_n,done,awaddr,wdata,araddr,awvalid,wvalid,arvalid,wstrb,bready,rready;
        input awready,wready,bvalid,arready,rvalid,rdata,bresp,rresp;
    endclocking
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input rst_n,start,ack,command_addr,command_len;
    endclocking
    modport driver_access(clocking driver_cb);
    modport monitor_access(clocking monitor_cb);
endinterface
