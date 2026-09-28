`timescale 1ns / 1ps
// File: fdma_aurora_pcie_conv_dma_wrapper.v
//
// Integration shim for connecting fdma_aurora_brg_top to MiLianKe CONV_DMA.
// The bridge keeps its legacy byte-size debug contract, while CONV_DMA expects
// fdma_*size to mean 64-bit beat count. For the default 512B frame this wrapper
// drives size=64 toward CONV_DMA.

module fdma_aurora_pcie_conv_dma_wrapper #(
        parameter integer FRAME_BYTES = 512,
        parameter integer MEM_WINDOW_BYTES = 8192,
        parameter integer RX_FIFO_ALMOST_FULL_WORDS = 2032,
        parameter integer RX_FIFO_FULL_WORDS = 2047,
        parameter integer FDMA_TIMEOUT_CYCLES = 16'hffff
    )(
        input              fdma_clk,
        input              fdma_rstn,
        input              fdma_status_clear,

        input              user_clk,
        input              user_rstn,
        input              user_status_clear,
        input              channel_up,
        input      [15:0]  cfg_tx_burst_limit,

        output     [31:0]  fdma_raddr,
        output             fdma_rareq,
        output     [15:0]  fdma_rsize,
        input              fdma_rbusy,
        input      [63:0]  fdma_rdata,
        input              fdma_rvalid,
        output             fdma_rready,

        output     [31:0]  fdma_waddr,
        output             fdma_wareq,
        output     [15:0]  fdma_wsize,
        input              fdma_wbusy,
        output     [63:0]  fdma_wdata,
        output             fdma_wvalid,
        input              fdma_wready,

        output     [63:0]  aurora_tx_d,
        output             aurora_tx_sof,
        output             aurora_tx_eof,
        output     [2:0]   aurora_tx_rem,
        output             aurora_tx_src_rdy,
        input              aurora_tx_dst_rdy,

        input      [63:0]  aurora_rx_d,
        input              aurora_rx_sof,
        input              aurora_rx_eof,
        input      [2:0]   aurora_rx_rem,
        input              aurora_rx_src_rdy,
        output             aurora_rx_dst_rdy,

        output             dbg_channel_up_fdma,
        output     [37:0]  tx_fdma_dbg_bus,
        output     [38:0]  tx_user_dbg_bus,
        output     [105:0] rx_fdma_dbg_bus,
        output     [28:0]  rx_user_dbg_bus,
        output             tx_frame_done_user,
        output             rx_burst_done_fdma,

        output     [15:0]  bridge_fdma_wsize_raw,
        output     [10:0]  rx_fifo_wr_count,
        output             rx_fifo_almost_full,
        output             rx_fifo_full,
        output reg         rx_almost_full_sticky,
        output reg         rx_full_sticky,
        output reg         rx_overflow_sticky,
        output reg         tx_underflow_sticky,
        output reg         link_down_sticky,
        output reg         fdma_timeout_sticky
    );

    localparam [15:0] FRAME_WORDS = FRAME_BYTES / 8;
    localparam [10:0] RX_ALMOST_FULL_THRESH = RX_FIFO_ALMOST_FULL_WORDS;
    localparam [10:0] RX_FULL_THRESH = RX_FIFO_FULL_WORDS;
    localparam [15:0] FDMA_TIMEOUT_LIMIT = FDMA_TIMEOUT_CYCLES;

    wire [15:0] brg_fdma_wsize;
    wire        rx_fifo_almost_full_raw;
    wire        rx_fifo_full_raw;
    wire        rx_fifo_overflow_raw;

    assign fdma_rsize = FRAME_WORDS;
    assign fdma_wsize = FRAME_WORDS;
    assign bridge_fdma_wsize_raw = brg_fdma_wsize;

    fdma_aurora_brg_top #(
        .FRAME_BYTES      (FRAME_BYTES),
        .MEM_WINDOW_BYTES (MEM_WINDOW_BYTES)
    ) u_fdma_aurora_brg_top (
        .fdma_clk            (fdma_clk),
        .fdma_rstn           (fdma_rstn),
        .user_clk            (user_clk),
        .user_rstn           (user_rstn),
        .channel_up          (channel_up),
        .cfg_tx_burst_limit  (cfg_tx_burst_limit),

        .fdma_raddr          (fdma_raddr),
        .fdma_rareq          (fdma_rareq),
        .fdma_rbusy          (fdma_rbusy),
        .fdma_rdata          (fdma_rdata),
        .fdma_rvalid         (fdma_rvalid),
        .fdma_rready         (fdma_rready),

        .fdma_waddr          (fdma_waddr),
        .fdma_wareq          (fdma_wareq),
        .fdma_wbusy          (fdma_wbusy),
        .fdma_wdata          (fdma_wdata),
        .fdma_wvalid         (fdma_wvalid),
        .fdma_wsize          (brg_fdma_wsize),
        .fdma_wready         (fdma_wready),

        .aurora_tx_d         (aurora_tx_d),
        .aurora_tx_sof       (aurora_tx_sof),
        .aurora_tx_eof       (aurora_tx_eof),
        .aurora_tx_rem       (aurora_tx_rem),
        .aurora_tx_src_rdy   (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy   (aurora_tx_dst_rdy),

        .aurora_rx_d         (aurora_rx_d),
        .aurora_rx_sof       (aurora_rx_sof),
        .aurora_rx_eof       (aurora_rx_eof),
        .aurora_rx_rem       (aurora_rx_rem),
        .aurora_rx_src_rdy   (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy   (aurora_rx_dst_rdy),

        .dbg_channel_up_fdma (dbg_channel_up_fdma),
        .tx_fdma_dbg_bus     (tx_fdma_dbg_bus),
        .tx_user_dbg_bus     (tx_user_dbg_bus),
        .rx_fdma_dbg_bus     (rx_fdma_dbg_bus),
        .rx_user_dbg_bus     (rx_user_dbg_bus),
        .rx_fifo_almost_full (rx_fifo_almost_full_raw),
        .rx_fifo_full        (rx_fifo_full_raw),
        .rx_fifo_overflow    (rx_fifo_overflow_raw),
        .tx_frame_done_user  (tx_frame_done_user),
        .rx_burst_done_fdma  (rx_burst_done_fdma)
    );

    assign rx_fifo_wr_count = rx_user_dbg_bus[28:18];
    assign rx_fifo_almost_full = rx_fifo_almost_full_raw ||
                                 (rx_fifo_wr_count >= RX_ALMOST_FULL_THRESH);
    assign rx_fifo_full = rx_fifo_full_raw ||
                          (rx_fifo_wr_count >= RX_FULL_THRESH);

    wire rx_accept_when_full = aurora_rx_src_rdy && aurora_rx_dst_rdy && rx_fifo_full;
    wire tx_fifo_underflow_raw = tx_user_dbg_bus[0];

    reg seen_channel_up;

    always @(posedge user_clk or negedge user_rstn) begin
        if (!user_rstn) begin
            rx_almost_full_sticky <= 1'b0;
            rx_full_sticky        <= 1'b0;
            rx_overflow_sticky    <= 1'b0;
            tx_underflow_sticky   <= 1'b0;
            link_down_sticky      <= 1'b0;
            seen_channel_up       <= 1'b0;
        end else begin
            if (user_status_clear) begin
                rx_almost_full_sticky <= 1'b0;
                rx_full_sticky        <= 1'b0;
                rx_overflow_sticky    <= 1'b0;
                tx_underflow_sticky   <= 1'b0;
                link_down_sticky      <= 1'b0;
            end

            if (channel_up)
                seen_channel_up <= 1'b1;
            else if (seen_channel_up)
                link_down_sticky <= 1'b1;

            if (rx_fifo_almost_full)
                rx_almost_full_sticky <= 1'b1;
            if (rx_fifo_full)
                rx_full_sticky <= 1'b1;
            if (rx_fifo_overflow_raw || rx_accept_when_full)
                rx_overflow_sticky <= 1'b1;
            if (tx_fifo_underflow_raw)
                tx_underflow_sticky <= 1'b1;
        end
    end

    wire fdma_waiting = fdma_rareq ||
                        fdma_wareq ||
                        (fdma_rready && !fdma_rvalid) ||
                        (fdma_wvalid && !fdma_wready);

    reg [15:0] fdma_wait_cnt;

    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            fdma_wait_cnt        <= 16'd0;
            fdma_timeout_sticky  <= 1'b0;
        end else if (fdma_status_clear) begin
            fdma_wait_cnt        <= 16'd0;
            fdma_timeout_sticky  <= 1'b0;
        end else if (fdma_waiting) begin
            if (fdma_wait_cnt >= FDMA_TIMEOUT_LIMIT)
                fdma_timeout_sticky <= 1'b1;
            else
                fdma_wait_cnt <= fdma_wait_cnt + 16'd1;
        end else begin
            fdma_wait_cnt <= 16'd0;
        end
    end

endmodule
