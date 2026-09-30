`timescale 1ns/1ps
// 验证接口：集中定义引脚所有权与clocking采样，协议驱动不直接写DUT层次。
interface rtds_axi_test_if (input logic M_AXI_ACLK);
    logic fdma_wdone;    // 写事务完成脉冲（DUT 驱动）
    logic fdma_werror;    // 写事务错误标志，镜像 BRESP（DUT 驱动）
    logic [64-1 : 0]		fdma_waddr = '0;    // 写目标字节地址（测试侧驱动）
    logic fdma_wareq = '0;    // 写请求脉冲（测试侧驱动）
    logic [15 : 0]						fdma_wsize = '0;    // 写长度，单位 8 字节拍（测试侧驱动）
    logic fdma_wbusy;    // 写通道忙标志（DUT 驱动）
    logic [64-1 :0]			fdma_wdata = '0;    // 写数据（测试侧驱动）
    logic fdma_wvalid;    // 写数据有效（DUT 驱动）
    logic fdma_wready = '0;    // 写数据就绪（测试侧驱动）
    logic [64-1 : 0]		fdma_raddr = '0;    // 读起始字节地址（测试侧驱动）
    logic fdma_rareq = '0;    // 读请求脉冲（测试侧驱动）
    logic [15 : 0]						fdma_rsize = '0;    // 读长度，单位 8 字节拍（测试侧驱动）
    logic fdma_rbusy;    // 读通道忙标志（DUT 驱动）
    logic [64-1 :0]			fdma_rdata;    // 读返回数据（DUT 驱动）
    logic fdma_rvalid;    // 读数据有效（DUT 驱动）
    logic fdma_rready = '0;    // 读数据就绪（测试侧驱动）
    logic M_AXI_ARESETN = '0;    // AXI 低有效复位（测试侧驱动）
    // AXI 写地址通道（AW）信号组
    logic [1-1 : 0]			M_AXI_AWID;
    logic [64-1 : 0]		M_AXI_AWADDR;
    logic [7 : 0]							M_AXI_AWLEN;
    logic [2 : 0]							M_AXI_AWSIZE;
    logic [1 : 0]							M_AXI_AWBURST;
    logic M_AXI_AWLOCK;
    logic [3 : 0]							M_AXI_AWCACHE;
    logic [2 : 0]							M_AXI_AWPROT;
    logic [3 : 0]							M_AXI_AWQOS;
    logic M_AXI_AWVALID;
    logic M_AXI_AWREADY;
    // AXI 写数据通道（W）信号组
    logic [1-1 : 0]			M_AXI_WID;
    logic [64-1 : 0]		M_AXI_WDATA;
    logic [64/8-1 : 0]		M_AXI_WSTRB;
    logic M_AXI_WLAST;
    logic M_AXI_WVALID;
    logic M_AXI_WREADY;
    // AXI 写响应通道（B）信号组
    logic [1-1 : 0]			M_AXI_BID;
    logic [1 : 0]							M_AXI_BRESP;
    logic M_AXI_BVALID;
    logic M_AXI_BREADY;
    // AXI 读地址通道（AR）信号组
    logic [1-1 : 0]			M_AXI_ARID;
    logic [64-1 : 0]		M_AXI_ARADDR;
    logic [7 : 0]							M_AXI_ARLEN;
    logic [2 : 0]							M_AXI_ARSIZE;
    logic [1 : 0]							M_AXI_ARBURST;
    logic M_AXI_ARLOCK;
    logic [3 : 0]							M_AXI_ARCACHE;
    logic [2 : 0]							M_AXI_ARPROT;
    logic [3 : 0]							M_AXI_ARQOS;
    logic M_AXI_ARVALID;
    logic M_AXI_ARREADY;
    // AXI 读数据通道（R）信号组
    logic [1-1 : 0]			M_AXI_RID;
    logic [64-1 : 0]		M_AXI_RDATA;
    logic [1 : 0]							M_AXI_RRESP;
    logic M_AXI_RLAST;
    logic M_AXI_RVALID;
    logic M_AXI_RREADY;
    logic inject_error=0;    // 置 1 时包装层将 BRESP 改写为 SLVERR
    // 激励驱动 clocking：测试程序只经此驱动 DUT 输入引脚
    clocking driver_cb @(posedge M_AXI_ACLK);
        default input #1step output #0;
        output M_AXI_ARESETN,fdma_waddr,fdma_wareq,fdma_wsize,fdma_wdata,fdma_wready;
        output fdma_raddr,fdma_rareq,fdma_rsize,fdma_rready,inject_error;
        input fdma_wbusy,fdma_wvalid,fdma_wdone,fdma_werror,fdma_rbusy,fdma_rvalid,fdma_rdata;
    endclocking
    // 驱动侧 modport：task 经此访问 driver_cb
    modport driver_cb_access (clocking driver_cb);
    // 独立被动采样入口；检查器不得通过它驱动任何协议引脚。
    clocking monitor_cb @(posedge M_AXI_ACLK);
        default input #1step output #0;
        input fdma_wdone, fdma_werror, fdma_waddr, fdma_wareq, fdma_wsize, fdma_wbusy, fdma_wdata, fdma_wvalid, fdma_wready, fdma_raddr, fdma_rareq, fdma_rsize, fdma_rbusy, fdma_rdata, fdma_rvalid, fdma_rready, M_AXI_ARESETN, M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS, M_AXI_AWVALID, M_AXI_AWREADY, M_AXI_WID, M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST, M_AXI_WVALID, M_AXI_WREADY, M_AXI_BID, M_AXI_BRESP, M_AXI_BVALID, M_AXI_BREADY, M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS, M_AXI_ARVALID, M_AXI_ARREADY, M_AXI_RID, M_AXI_RDATA, M_AXI_RRESP, M_AXI_RLAST, M_AXI_RVALID, M_AXI_RREADY, inject_error;
    endclocking
    // 监测侧 modport：检查器只读采样
    modport monitor_access (clocking monitor_cb);
endinterface
