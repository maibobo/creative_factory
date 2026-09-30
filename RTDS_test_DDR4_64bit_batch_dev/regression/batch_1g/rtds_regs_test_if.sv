`timescale 1ns/1ps
// 寄存器验证接口：AXI-Lite激励由driver集中驱动，monitor只采样内部脉冲。
interface rtds_regs_test_if(input logic clk);
    logic rst_n=0, done=0;    // 复位与CPU写完成事件（done脉冲触发start自动清零）
    logic[31:0] awaddr=0,wdata=0,araddr=0;    // AXI-Lite写/读地址与写数据
    logic awvalid=0,wvalid=0,arvalid=0,bready=1,rready=1;    // 通道valid激励；bready/rready常1
    logic[3:0] wstrb=4'hf;    // 写字节使能（默认全字节写）
    wire awready,wready,bvalid,arready,rvalid;    // AXI-Lite通道ready与响应valid
    wire[31:0] rdata,command_addr,command_len;    // 读数据与命令寄存器镜像（起始地址/长度）
    wire[1:0] bresp,rresp;    // 写/读响应码
    wire start,ack,clear_irq,clear_inter;    // DUT内部脉冲：读启动/CPU应答/清中断/清交互
    // 主机驱动clocking：AXI-Lite五通道激励在此驱动
    clocking driver_cb @(posedge clk);
        default input #1step output #0;
        output rst_n,done,awaddr,wdata,araddr,awvalid,wvalid,arvalid,wstrb,bready,rready;
        input awready,wready,bvalid,arready,rvalid,rdata,bresp,rresp;
    endclocking
    // 监视clocking：只读采样start/ack脉冲与命令寄存器镜像
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input rst_n,start,ack,command_addr,command_len;
    endclocking
    // modport：driver/monitor权限隔离
    modport driver_access(clocking driver_cb);
    modport monitor_access(clocking monitor_cb);
endinterface
