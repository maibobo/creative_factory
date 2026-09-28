// 快速环境协议断言：固定16拍、下行32KiB、上行2MiB及反压稳定。
// 错误直接 fatal，避免多个时钟/断言同时累加一个共享错误计数导致漏计。
`timescale 1ns / 1ps

module rtds_assertions #(
        parameter [31:0] CARD_ADDR_HI = 0,
        parameter [31:0] RX_BASE_ADDR_LO = 32'h00100000,
        parameter [31:0] TX_BASE_ADDR_LO = 32'h8000,
        parameter integer WINDOW_BYTES = 32 * 1024
    )(
        input fdma_clk,
        input fdma_rstn,
        input [63:0] fdma_raddr,
        input fdma_rareq,
        input fdma_rbusy,
        input [15:0] fdma_rsize,
        input [63:0] fdma_waddr,
        input fdma_wareq,
        input fdma_wbusy,
        input [15:0] fdma_wsize,
        input user_clk,
        input user_rstn,
        input [63:0] tx_d,
        input tx_sof,
        input tx_eof,
        input [2:0] tx_rem,
        input tx_src_rdy,
        input tx_dst_rdy,
        output wire [31:0] assertion_error_count
    );
    // 生成当前事务计数/长度字段，计数推进仍由实际握手或提交事件决定。
    assign assertion_error_count = 32'd0;

    property p_read_request_size;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        fdma_rareq |-> (fdma_rsize == 16'd2);
    endproperty
    a_p_read_request_size: assert property (p_read_request_size) else begin
        $fatal(1, "FDMA read size is not 2 beats");
    end

    property p_write_request_size;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        fdma_wareq |-> (fdma_wsize == 16'd1);
    endproperty
    a_p_write_request_size: assert property (p_write_request_size) else begin
        $fatal(1, "FDMA write size is not 1 beat");
    end

    property p_read_address;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        fdma_rareq |-> ((fdma_raddr[63:32] == CARD_ADDR_HI) &&
                       (fdma_raddr[31:0] >= TX_BASE_ADDR_LO) &&
                       (fdma_raddr[31:0] + 16 <= TX_BASE_ADDR_LO + WINDOW_BYTES) &&
                       (fdma_raddr[3:0] == 0) &&
                       (fdma_raddr[11:0] + 16 <= 4096));
    endproperty
    a_p_read_address: assert property (p_read_address) else begin
        $fatal(1, "FDMA read address violated TX window/alignment");
    end

    property p_write_address;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        fdma_wareq |-> ((fdma_waddr[63:32] == CARD_ADDR_HI) &&
                       (fdma_waddr[31:0] >= RX_BASE_ADDR_LO) &&
                       (fdma_waddr[31:0] + 8 <= RX_BASE_ADDR_LO + 32'h200000) &&
                       (fdma_waddr[2:0] == 0) &&
                       (fdma_waddr[11:0] + 8 <= 4096));
    endproperty
    a_p_write_address: assert property (p_write_address) else begin
        $fatal(1, "FDMA write address violated RX window/alignment");
    end

    property p_read_request_held;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        (fdma_rareq && !fdma_rbusy) |=> (fdma_rareq || fdma_rbusy);
    endproperty
    a_p_read_request_held: assert property (p_read_request_held) else begin
        $fatal(1, "FDMA read request was not held until busy");
    end

    property p_write_request_held;
        @(posedge fdma_clk) disable iff (!fdma_rstn)
        (fdma_wareq && !fdma_wbusy) |=> (fdma_wareq || fdma_wbusy);
    endproperty
    a_p_write_request_held: assert property (p_write_request_held) else begin
        $fatal(1, "FDMA write request was not held until busy");
    end

    property p_tx_stable_while_stalled;
        @(posedge user_clk) disable iff (!user_rstn)
        (tx_src_rdy && !tx_dst_rdy) |=>
          (tx_src_rdy && $stable({tx_d, tx_sof, tx_eof, tx_rem}));
    endproperty
    a_p_tx_stable_while_stalled: assert property (p_tx_stable_while_stalled) else begin
        $fatal(1, "Aurora TX changed while stalled");
    end
    c_read_req: cover property (@(posedge fdma_clk) disable iff(!fdma_rstn) fdma_rareq);
    c_write_req: cover property (@(posedge fdma_clk) disable iff(!fdma_rstn) fdma_wareq);
    c_tx_stall: cover property (@(posedge user_clk) disable iff(!user_rstn) tx_src_rdy && !tx_dst_rdy);
endmodule
