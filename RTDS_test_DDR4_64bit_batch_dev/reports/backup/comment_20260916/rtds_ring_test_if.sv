`timescale 1ns/1ps
// 验证接口：集中定义引脚所有权与clocking采样，协议驱动不直接写DUT层次。
interface rtds_ring_test_if (input logic clk);
    logic rst_n=0, enable=0, frame_valid=0, cpu_ack=0, irq_clear=0;
    logic [63:0] frame_data=0;
    wire frame_ready;
    wire [31:0] head_addr, head_len, head_seq, ready_blocks, dropped_frames;
    wire irq;
    wire [63:0] fdma_waddr, fdma_wdata;
    wire [7:0] fdma_wstrb;
    wire [15:0] fdma_wsize;
    wire fdma_wareq, fdma_wvalid;
    logic fdma_wbusy=0, fdma_waccept=0, fdma_wdone=0, fdma_werror=0;
    wire [3:0] dbg_state;
    clocking host_cb @(posedge clk);
        default input #1step output #0;
        output rst_n, enable, frame_valid, frame_data, cpu_ack, irq_clear;
        input frame_ready, head_addr, head_len, head_seq, ready_blocks, dropped_frames, irq;
    endclocking
    clocking fdma_cb @(posedge clk);
        default input #1step output #0;
        input rst_n, fdma_wareq, fdma_waddr, fdma_wsize, fdma_wstrb, fdma_wvalid, fdma_wdata;
        output fdma_wbusy, fdma_wdone, fdma_werror;
        inout fdma_waccept;
    endclocking
    modport host_cb_access (clocking host_cb);
    modport fdma_cb_access (clocking fdma_cb);
    // 独立被动采样入口；检查器不得通过它驱动任何协议引脚。
    clocking monitor_cb @(posedge clk);
        default input #1step output #0;
        input rst_n, enable, frame_valid, cpu_ack, irq_clear, frame_data, frame_ready, head_addr, head_len, head_seq, ready_blocks, dropped_frames, irq, fdma_waddr, fdma_wdata, fdma_wsize, fdma_wareq, fdma_wvalid, fdma_wbusy, fdma_waccept, fdma_wdone, fdma_werror, dbg_state;
    endclocking
    modport monitor_access (clocking monitor_cb);
endinterface
