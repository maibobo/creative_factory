`timescale 1ns / 1ps
// File: tc_if.sv

// FDMA 读侧接口，testcase BFM 驱动 busy、data 和 valid。
interface fdma_read_if(input logic clk, input logic rst_n);
    logic [31:0] raddr;  // DUT-选择 byte 地址 for the next 512B 突发.
    logic        rareq;  // DUT 请求; held until the slave asserts rbusy.
    logic        rbusy;  // BFM 响应，表示读事务处于活动状态。
    logic [63:0] rdata;  // BFM 提供的读载荷。
    logic        rvalid; // BFM 表示 rdata 有效。
    logic        rready; // DUT 状态s that it can accept rdata.

    // #1step 采样避免与 DUT 时序逻辑竞争。
    clocking cb @(posedge clk);
        default input #1step output #1step; // Sample/drive immediately around each fdma_clk edge.
        input  raddr, rareq, rready;        // 信号 produced by the DUT.
        output rbusy, rdata, rvalid;        // 信号 produced by the 类 BFM.
    endclocking

    modport dut(
        output raddr, rareq, rready,
        input  rbusy, rdata, rvalid
    );
endinterface


// FDMA 写侧接口，testcase BFM 驱动 busy 和 ready。
interface fdma_write_if(input logic clk, input logic rst_n);
    logic [31:0] waddr;  // DUT-选择 byte 地址 for the write 突发.
    logic        wareq;  // DUT 请求; held until the slave asserts wbusy.
    logic        wbusy;  // BFM 响应，表示写事务处于活动状态。
    logic [63:0] wdata;  // DUT write 载荷.
    logic        wvalid; // DUT 状态s that wdata is 有效.
    logic [15:0] wsize;  // 请求ed byte count; 期望 to be 512.
    logic        wready; // BFM 表示可以接收 wdata。

    clocking cb @(posedge clk);
        default input #1step output #1step;       // Race-free FDMA-时钟域 sampling/driving.
        input  waddr, wareq, wdata, wvalid, wsize; // DUT 输出s sampled by the BFM.
        output wbusy, wready;                      // 测试平台 response and 反压.
    endclocking

    modport dut(
        output waddr, wareq, wdata, wvalid, wsize,
        input  wbusy, wready
    );
endinterface


// 在 bridge 与 Aurora 边界观测 LocalLink 信号。
interface ll_link_if(input logic clk, input logic rst_n);
    logic [63:0] tx_d;       // 桥接到 Aurora 的载荷。
    logic        tx_sof;     // Start-of-帧 marker for the current TX 数据字.
    logic        tx_eof;     // End-of-frame marker for the current TX word.
    logic [2:0]  tx_rem;     // 有效-byte encoding; 111 means all eight bytes.
    logic        tx_src_rdy; // 桥接端给出有效 TX 数据字。
    logic        tx_dst_rdy; // Aurora/直连 harness 接收 TX 数据字。

    logic [63:0] rx_d;       // Aurora/直连注入返回桥接端的载荷。
    logic        rx_sof;     // RX start-of-帧 marker.
    logic        rx_eof;     // RX end-of-帧 marker.
    logic [2:0]  rx_rem;     // RX 有效-byte encoding.
    logic        rx_src_rdy; // Aurora/测试用例给出有效 RX 数据字。
    logic        rx_dst_rdy; // Bridge advertises RX acceptance.

    clocking mon_cb @(posedge clk);
        default input #1step;
        input tx_d, tx_sof, tx_eof, tx_rem, tx_src_rdy, tx_dst_rdy;
        input rx_d, rx_sof, rx_eof, rx_rem, rx_src_rdy, rx_dst_rdy;
    endclocking
endinterface


// brg_harness 实现的仅验证控制信号。
interface brg_ctrl_if;
    // 直连 bridge harness 控制信号；Aurora 环回测试保持默认值。
    logic force_tx_almost_full; // Force hook used only by tc_brg_rd_就绪_停顿.
    logic can_drive_tx_dst_rdy; // One for brg_harness, 零 for the Aurora core.
    logic rx_loopback_enable;   // Select TX loopback (1) or 直连 RX 注入 (0).
    logic [63:0] rx_drive_d;    // 直连-注入 载荷.
    logic [15:0] cfg_tx_burst_limit;
    logic        rx_drive_sof;  // 直连-注入 SOF.
    logic        rx_drive_eof;  // 直连-注入 EOF.
    logic [2:0]  rx_drive_rem;  // 直连-注入 byte-有效 value.
    logic        rx_drive_src_rdy; // 直连-注入 源-有效.
endinterface


// 检查与日志使用的只读 DUT 状态和 FIFO 观测点。
interface brg_obs_if(input logic fdma_clk, input logic user_clk);
    logic        is_full_loop; // One for Aurora harness, 零 for 直连 bridge harness.
    logic        channel_up;   // Link-就绪 状态 used by the 公共 start sequence.
    logic        lane_up;      // Aurora lane 状态；直连模式下连接到 channel_up。
    logic        user_rstn;    // LocalLink-时钟域 活动-low 复位 状态.

    logic [1:0]  tx_rd_state;       // FDMA read-状态 encoding.
    logic [1:0]  tx_state;          // LocalLink TX-状态 encoding.
    logic [6:0]  tx_rd_word_cnt;    // FDMA 数据字 观测到 in the current 突发.
    logic [7:0]  tx_word_cnt;       // LL 数据字 emitted in the current 帧.
    logic        tx_fifo_wr_en;     // 实际 TX FIFO 写使能。
    logic        tx_fifo_rd_en;     // 实际 TX FIFO 读使能。
    logic [63:0] tx_fifo_wdata;     // TX FIFO write 载荷.
    logic [63:0] tx_fifo_rdata;     // TX FIFO FWFT 输出 载荷.
    logic [9:0]  tx_fifo_wr_cnt;    // 同步到 FIFO 写域的计数。
    logic [9:0]  tx_fifo_rd_cnt;    // 同步到 FIFO 读域的计数。
    logic        tx_fifo_overflow;  // XPM overflow 错误 indication.
    logic        tx_fifo_underflow; // XPM underflow 错误 indication.
    logic        tx_fifo_almost_full;  // 448-数据字 可编程满水线。
    logic        tx_fifo_almost_empty; // Programmed-empty waterline.
    logic        tx_fifo_full;         // Physical TX FIFO full flag.
    logic        tx_fifo_empty;        // Physical TX FIFO empty flag.

    logic [1:0]  rx_wr_state;        // FDMA write-状态 encoding.
    logic [6:0]  rx_wr_word_cnt;     // 握手n 数据字 in the current write 突发.
    logic        rx_wdata_hold_valid;// 输出 holding-register 有效 bit.
    logic        rx_fifo_wr_en;      // 实际 RX FIFO 写使能。
    logic        rx_fifo_rd_en;      // 实际 RX FIFO 读使能。
    logic [63:0] rx_fifo_wdata;      // RX FIFO 输入 载荷.
    logic [63:0] rx_fifo_rdata;      // RX FIFO FWFT 输出 载荷.
    logic [10:0] rx_fifo_wr_cnt;     // 同步到写/user 域的计数。
    logic [10:0] rx_fifo_rd_cnt;     // 同步到读/FDMA 域的计数。
    logic        rx_fifo_overflow;   // XPM overflow 错误 indication.
    logic        rx_fifo_underflow;  // XPM underflow 错误 indication.
    logic        rx_fifo_almost_full;// 2032-数据字 可编程满水线。
    logic        rx_fifo_full;       // Physical RX FIFO full flag.
    logic        rx_fifo_empty;      // Physical RX FIFO empty flag.

    // FIFO 边界测试使用边沿前采样点，避免 NBA 竞争。
    clocking user_cb @(posedge user_clk);
        default input #1step;
        input rx_fifo_wr_en, rx_fifo_wr_cnt, rx_fifo_almost_full;
        input rx_fifo_full, rx_fifo_overflow;
    endclocking
endinterface