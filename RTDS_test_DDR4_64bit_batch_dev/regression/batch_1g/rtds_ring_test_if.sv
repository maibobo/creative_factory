`timescale 1ns/1ps
// 验证接口：集中定义引脚所有权与clocking采样，协议驱动不直接写DUT层次。
interface rtds_ring_test_if (input logic clk);
    logic rst_n=0, enable=0, frame_valid=0, cpu_ack=0, irq_clear=0;    // 主机侧驱动：复位、使能、帧写入、CPU应答、中断清零
    logic [63:0] frame_data=0;    // 上行数据拍（64bit，业务字在低32bit）
    wire frame_ready;    // 写侧流控（DUT输出）
    wire [31:0] head_addr, head_len, head_seq, ready_blocks, dropped_frames;    // 队头块描述与统计：DDR地址/有效字节/序号/待取块数/丢字计数
    wire irq;    // 队头可读通知中断（读清）
    wire [63:0] fdma_waddr, fdma_wdata;    // FDMA写地址与写数据
    wire [7:0] fdma_wstrb;    // FDMA写字节使能（双字FF，尾字0F）
    wire [15:0] fdma_wsize;    // FDMA写长度（64bit拍数，固定1）
    wire fdma_wareq, fdma_wvalid;    // FDMA写请求与源端有效
    logic fdma_wbusy=0, fdma_waccept=0, fdma_wdone=0, fdma_werror=0;    // 验证侧驱动的FDMA响应：busy/accept/done/error
    wire [3:0] dbg_state;    // DUT写状态机调试观察
    // 主机域clocking：host驱动帧流与控制，采样DUT状态输出与中断
    clocking host_cb @(posedge clk);
        default input #1step output #0;
        output rst_n, enable, frame_valid, frame_data, cpu_ack, irq_clear;
        input frame_ready, head_addr, head_len, head_seq, ready_blocks, dropped_frames, irq;
    endclocking
    // FDMA域clocking：responder独占busy/done/error响应，accept经inout完成握手
    clocking fdma_cb @(posedge clk);
        default input #1step output #0;
        input rst_n, fdma_wareq, fdma_waddr, fdma_wsize, fdma_wstrb, fdma_wvalid, fdma_wdata;
        output fdma_wbusy, fdma_wdone, fdma_werror;
        inout fdma_waccept;
    endclocking
    // 角色modport：host/fdma各自限定可用的clocking
    modport host_cb_access (clocking host_cb);
    modport fdma_cb_access (clocking fdma_cb);
    // 独立被动采样入口；检查器不得通过它驱动任何协议引脚。
    clocking monitor_cb @(posedge clk);
        default input #1step output #0;
        input rst_n, enable, frame_valid, cpu_ack, irq_clear, frame_data, frame_ready, head_addr, head_len, head_seq, ready_blocks, dropped_frames, irq, fdma_waddr, fdma_wdata, fdma_wsize, fdma_wareq, fdma_wvalid, fdma_wbusy, fdma_waccept, fdma_wdone, fdma_werror, dbg_state;
    endclocking
    modport monitor_access (clocking monitor_cb);
endinterface
