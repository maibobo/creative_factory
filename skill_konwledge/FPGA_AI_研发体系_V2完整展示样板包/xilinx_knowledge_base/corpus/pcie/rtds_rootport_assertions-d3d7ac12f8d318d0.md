# rtds_rootport_assertions

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\rtds_rootport_assertions.sv`
- SHA-256: `d3d7ac12f8d318d0a28944c0c55beed436507b105a2aaf11ac3aa74803025183`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

// 集成级断言：只验证 adapter/FDMA/LocalLink 在真实 XDMA 运行时必须成立的约束，
// 不重复构造 FDMA 或 Aurora bridge 的独立功能验证。
module rtds_rootport_assertions (
    input             fdma_clk,
    input             fdma_rstn,
    input      [63:0] fdma_raddr,
    input             fdma_rareq,
    input             fdma_rbusy,
    input      [15:0] fdma_rsize,
    input      [63:0] fdma_waddr,
    input             fdma_wareq,
    input             fdma_wbusy,
    input      [15:0] fdma_wsize,
    input             user_clk,
    input             user_rstn,
    input             link_up,
    input      [63:0] tx_d,
    input             tx_sof,
    input             tx_eof,
    input      [2:0]  tx_rem,
    input             tx_src_rdy,
    input             tx_dst_rdy,
    input             rx_src_rdy,
    input             rx_dst_rdy,
    input             clear_inter,
    input      [5:0]  sticky_status,
    output reg [31:0] assertion_error_count
);
    reg prev_tx_stalled;
    reg [68:0] prev_tx_payload;
    reg read_waiting;
    reg write_waiting;
    integer clear_watchdog;
    reg clear_seen_zero;

    initial begin
        assertion_error_count = 0;
        prev_tx_stalled       = 1'b0;
        prev_tx_payload       = 69'd0;
        read_waiting          = 1'b0;
        write_waiting         = 1'b0;
        clear_watchdog        = 0;
        clear_seen_zero       = 1'b0;
    end

    // ---------- 语义段 1：FDMA 请求尺寸、窗口和握手保持 ----------
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            read_waiting   <= 1'b0;
            write_waiting  <= 1'b0;
            clear_watchdog <= 0;
            clear_seen_zero <= 1'b0;
        end else begin
            if (fdma_rareq) begin
                if (fdma_rsize != 16'd64 || fdma_raddr[8:0] != 0 ||
                    fdma_raddr[31:0] < 32'h0000_8000 || fdma_raddr[31:0] > 32'h0000_FE00) begin
                    assertion_error_count <= assertion_error_count + 1;
                    $error("RTDS_ASSERT_FDMA_READ: size/address 非法 size=%0d addr=%h", fdma_rsize, fdma_raddr);
                end
                read_waiting <= !fdma_rbusy;
            end else if (read_waiting && !fdma_rbusy) begin
                assertion_error_count <= assertion_error_count + 1;
                read_waiting <= 1'b0;
                $error("RTDS_ASSERT_FDMA_READ: 请求未保持到 busy");
            end else if (fdma_rbusy) begin
                read_waiting <= 1'b0;
            end

            if (fdma_wareq) begin
                if (fdma_wsize != 16'd64 || fdma_waddr[8:0] != 0 ||
                    fdma_waddr[31:0] > 32'h0000_7E00) begin
                    assertion_error_count <= assertion_error_count + 1;
                    $error("RTDS_ASSERT_FDMA_WRITE: size/address 非法 size=%0d addr=%h", fdma_wsize, fdma_waddr);
                end
                write_waiting <= !fdma_wbusy;
            end else if (write_waiting && !fdma_wbusy) begin
                assertion_error_count <= assertion_error_count + 1;
                write_waiting <= 1'b0;
                $error("RTDS_ASSERT_FDMA_WRITE: 请求未保持到 busy");
            end else if (fdma_wbusy) begin
                write_waiting <= 1'b0;
            end

            if (link_up && (^({fdma_rareq, fdma_rbusy, fdma_wareq, fdma_wbusy}) === 1'bx)) begin
                assertion_error_count <= assertion_error_count + 1;
                $error("RTDS_ASSERT_X: link up 后 FDMA 控制信号含 X/Z");
            end

            // clear 后等待跨时钟域状态归零；一旦归零，16 个周期内不得由旧电平重新置位。
            if (clear_inter) begin
                clear_watchdog  <= 16;
                clear_seen_zero <= 1'b0;
            end else if (clear_watchdog > 0) begin
                clear_watchdog <= clear_watchdog - 1;
                if (sticky_status == 0)
                    clear_seen_zero <= 1'b1;
                else if (clear_seen_zero) begin
                    assertion_error_count <= assertion_error_count + 1;
                    $error("RTDS_ASSERT_STICKY_CLEAR: clear 后 sticky 状态由旧 CDC 电平重置位 %b", sticky_status);
                end
            end
        end
    end

    // ---------- 语义段 2：LocalLink TX 背压稳定和 RX 禁止反压 ----------
    always @(posedge user_clk or negedge user_rstn) begin
        if (!user_rstn) begin
            prev_tx_stalled <= 1'b0;
            prev_tx_payload <= 69'd0;
        end else begin
            if (prev_tx_stalled &&
                (!tx_src_rdy || {tx_d, tx_sof, tx_eof, tx_rem} !== prev_tx_payload)) begin
                assertion_error_count <= assertion_error_count + 1;
                $error("RTDS_ASSERT_LL_TX: 背压期间数据或边界信号发生变化");
            end
            if (rx_src_rdy && !rx_dst_rdy) begin
                assertion_error_count <= assertion_error_count + 1;
                $error("RTDS_ASSERT_LL_RX: Aurora->FPGA 不允许接收侧反压");
            end
            if (link_up && (^({tx_src_rdy, tx_dst_rdy, rx_src_rdy, rx_dst_rdy}) === 1'bx)) begin
                assertion_error_count <= assertion_error_count + 1;
                $error("RTDS_ASSERT_X: link up 后 LocalLink 控制信号含 X/Z");
            end
            prev_tx_stalled <= tx_src_rdy && !tx_dst_rdy;
            prev_tx_payload <= {tx_d, tx_sof, tx_eof, tx_rem};
        end
    end
endmodule
```
