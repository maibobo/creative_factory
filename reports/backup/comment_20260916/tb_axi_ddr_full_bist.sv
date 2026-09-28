`timescale 1ns / 1ps

`ifdef TB_SMOKE_4096
`define TB_SMOKE_BURSTS 256
`else
`define TB_SMOKE_BURSTS 2
`endif

// BIST 行为级回归顶层。
// 同一 testbench 通过 TB_SMOKE_BURSTS 分别运行 32-word 与 4096-word 冒烟；
// TB_EXTENDED 额外执行边界、缩小空间的正反向遍历、响应错误和超时用例。
module TB_AXI_DDR_FULL_BIST;

logic aclk;
logic aresetn;
logic start;
logic restart;
logic [2:0] test_mode;
logic repeat_enable;
logic stall_all;
logic inject_data_error;
logic inject_bresp_error;

logic busy;
logic done;
logic pass;
logic fail;
logic [8:0] phase;
logic [32:0] current_addr_ext;
logic [15:0] progress;
logic [31:0] write_transaction_count;
logic [31:0] read_transaction_count;
logic [63:0] elapsed_cycle_count;
logic [31:0] timeout_count;
logic [31:0] error_count;
logic [31:0] first_error_addr;
logic [63:0] first_expected_data;
logic [63:0] first_actual_data;
logic [3:0] last_axi_response;

logic [3:0] axi_awid;
logic [31:0] axi_awaddr;
logic [7:0] axi_awlen;
logic [2:0] axi_awsize;
logic [1:0] axi_awburst;
logic [0:0] axi_awlock;
logic [3:0] axi_awcache;
logic [2:0] axi_awprot;
logic [3:0] axi_awqos;
logic axi_awvalid;
logic axi_awready;
logic [63:0] axi_wdata;
logic [7:0] axi_wstrb;
logic axi_wlast;
logic axi_wvalid;
logic axi_wready;
logic [3:0] axi_bid;
logic [1:0] axi_bresp;
logic axi_bvalid;
logic axi_bready;
logic [3:0] axi_arid;
logic [31:0] axi_araddr;
logic [7:0] axi_arlen;
logic [2:0] axi_arsize;
logic [1:0] axi_arburst;
logic [0:0] axi_arlock;
logic [3:0] axi_arcache;
logic [2:0] axi_arprot;
logic [3:0] axi_arqos;
logic axi_arvalid;
logic axi_arready;
logic [3:0] axi_rid;
logic [63:0] axi_rdata;
logic [1:0] axi_rresp;
logic axi_rlast;
logic axi_rvalid;
logic axi_rready;

logic w_before_aw_seen;
logic boundary_error;
logic [31:0] maximum_address_seen;

always begin
    #1.666 aclk = ~aclk;
end

task automatic apply_reset;
    begin
        aresetn = 1'b0;
        start = 1'b0;
        restart = 1'b0;
        stall_all = 1'b0;
        inject_data_error = 1'b0;
        inject_bresp_error = 1'b0;
        repeat (8) begin
            @(posedge aclk);
        end
        aresetn = 1'b1;
        repeat (4) begin
            @(posedge aclk);
        end
    end
endtask

task automatic launch_test(input logic [2:0] selected_mode);
    begin
        @(negedge aclk);
        test_mode = selected_mode;
        start = 1'b1;
        @(negedge aclk);
        start = 1'b0;
    end
endtask

task automatic wait_for_result(
    input logic expected_pass,
    input string test_name
);
    int wait_cycles;
    begin
        wait_cycles = 0;
        while (!done && (wait_cycles < 5000000)) begin
            @(posedge aclk);
            wait_cycles++;
        end
        if (!done) begin
            $fatal(1, "%s timed out in testbench", test_name);
        end
        if (expected_pass && (!pass || fail)) begin
            $fatal(
                1,
                "%s expected PASS: errors=%0d first_addr=%08x expected=%016x actual=%016x",
                test_name,
                error_count,
                first_error_addr,
                first_expected_data,
                first_actual_data
            );
        end
        if (!expected_pass && (!fail || pass)) begin
            $fatal(1, "%s expected FAIL", test_name);
        end
        $display(
            "CASE_PASS name=%s expected_pass=%0d writes=%0d reads=%0d errors=%0d cycles=%0d",
            test_name,
            expected_pass,
            write_transaction_count,
            read_transaction_count,
            error_count,
            elapsed_cycle_count
        );
    end
endtask

AXI_DDR_FULL_BIST #(
    .FULL_SPACE_LIMIT  (33'h0_0001_0000),
    .SMOKE_BURST_COUNT (`TB_SMOKE_BURSTS),
    .STRESS_BURST_COUNT(32'd32),
    .HOLD_CYCLES       (64'd32),
    .TIMEOUT_CYCLES    (32'd64)
) U_AXI_DDR_FULL_BIST (
    .aclk                    (aclk),
    .aresetn                 (aresetn),
    .start                   (start),
    .restart                 (restart),
    .test_mode               (test_mode),
    .repeat_enable           (repeat_enable),
    .busy                    (busy),
    .done                    (done),
    .pass                    (pass),
    .fail                    (fail),
    .phase                   (phase),
    .current_addr_ext        (current_addr_ext),
    .progress                (progress),
    .write_transaction_count (write_transaction_count),
    .read_transaction_count  (read_transaction_count),
    .elapsed_cycle_count     (elapsed_cycle_count),
    .timeout_count           (timeout_count),
    .error_count             (error_count),
    .first_error_addr        (first_error_addr),
    .first_expected_data     (first_expected_data),
    .first_actual_data       (first_actual_data),
    .last_axi_response       (last_axi_response),
    .m_axi_awid              (axi_awid),
    .m_axi_awaddr            (axi_awaddr),
    .m_axi_awlen             (axi_awlen),
    .m_axi_awsize            (axi_awsize),
    .m_axi_awburst           (axi_awburst),
    .m_axi_awlock            (axi_awlock),
    .m_axi_awcache           (axi_awcache),
    .m_axi_awprot            (axi_awprot),
    .m_axi_awqos             (axi_awqos),
    .m_axi_awvalid           (axi_awvalid),
    .m_axi_awready           (axi_awready),
    .m_axi_wdata             (axi_wdata),
    .m_axi_wstrb             (axi_wstrb),
    .m_axi_wlast             (axi_wlast),
    .m_axi_wvalid            (axi_wvalid),
    .m_axi_wready            (axi_wready),
    .m_axi_bid               (axi_bid),
    .m_axi_bresp             (axi_bresp),
    .m_axi_bvalid            (axi_bvalid),
    .m_axi_bready            (axi_bready),
    .m_axi_arid              (axi_arid),
    .m_axi_araddr            (axi_araddr),
    .m_axi_arlen             (axi_arlen),
    .m_axi_arsize            (axi_arsize),
    .m_axi_arburst           (axi_arburst),
    .m_axi_arlock            (axi_arlock),
    .m_axi_arcache           (axi_arcache),
    .m_axi_arprot            (axi_arprot),
    .m_axi_arqos             (axi_arqos),
    .m_axi_arvalid           (axi_arvalid),
    .m_axi_arready           (axi_arready),
    .m_axi_rid               (axi_rid),
    .m_axi_rdata             (axi_rdata),
    .m_axi_rresp             (axi_rresp),
    .m_axi_rlast             (axi_rlast),
    .m_axi_rvalid            (axi_rvalid),
    .m_axi_rready            (axi_rready)
);

AXI4_RAM_MODEL U_AXI4_RAM_MODEL (
    .aclk               (aclk),
    .aresetn            (aresetn),
    .stall_all          (stall_all),
    .inject_data_error  (inject_data_error),
    .inject_bresp_error (inject_bresp_error),
    .s_axi_awid         (axi_awid),
    .s_axi_awaddr       (axi_awaddr),
    .s_axi_awlen        (axi_awlen),
    .s_axi_awsize       (axi_awsize),
    .s_axi_awburst      (axi_awburst),
    .s_axi_awvalid      (axi_awvalid),
    .s_axi_awready      (axi_awready),
    .s_axi_wdata        (axi_wdata),
    .s_axi_wstrb        (axi_wstrb),
    .s_axi_wlast        (axi_wlast),
    .s_axi_wvalid       (axi_wvalid),
    .s_axi_wready       (axi_wready),
    .s_axi_bid          (axi_bid),
    .s_axi_bresp        (axi_bresp),
    .s_axi_bvalid       (axi_bvalid),
    .s_axi_bready       (axi_bready),
    .s_axi_arid         (axi_arid),
    .s_axi_araddr       (axi_araddr),
    .s_axi_arlen        (axi_arlen),
    .s_axi_arsize       (axi_arsize),
    .s_axi_arburst      (axi_arburst),
    .s_axi_arvalid      (axi_arvalid),
    .s_axi_arready      (axi_arready),
    .s_axi_rid          (axi_rid),
    .s_axi_rdata        (axi_rdata),
    .s_axi_rresp        (axi_rresp),
    .s_axi_rlast        (axi_rlast),
    .s_axi_rvalid       (axi_rvalid),
    .s_axi_rready       (axi_rready),
    .w_before_aw_seen   (w_before_aw_seen),
    .boundary_error     (boundary_error),
    .maximum_address_seen(maximum_address_seen)
);

initial begin : test_sequence
    aclk = 1'b0;
    aresetn = 1'b0;
    start = 1'b0;
    restart = 1'b0;
    test_mode = 3'd0;
    repeat_enable = 1'b0;
    stall_all = 1'b0;
    inject_data_error = 1'b0;
    inject_bresp_error = 1'b0;

    apply_reset();
    launch_test(3'd0);
    wait_for_result(1'b1, "smoke_random_backpressure");
    if (!w_before_aw_seen) begin
        $fatal(1, "AW/W independence was not exercised");
    end
    if (boundary_error) begin
        $fatal(1, "AXI burst crossed 4 KiB or used wrong burst attributes");
    end

`ifdef TB_EXTENDED
    apply_reset();
    launch_test(3'd1);
    wait_for_result(1'b1, "data_line_patterns");

    apply_reset();
    launch_test(3'd2);
    wait_for_result(1'b1, "byte_write_strobes");

    apply_reset();
    launch_test(3'd3);
    wait_for_result(1'b1, "address_line_aliases");

    apply_reset();
    launch_test(3'd4);
    wait_for_result(1'b1, "directed_boundaries");

    apply_reset();
    launch_test(3'd5);
    wait_for_result(1'b1, "reduced_full_space_forward_reverse");
    if (maximum_address_seen != 32'h0000_FFF8) begin
        $fatal(1, "Reduced full-space test missed final aligned address: %08x", maximum_address_seen);
    end

    apply_reset();
    launch_test(3'd6);
    wait_for_result(1'b1, "reduced_march_class");

    apply_reset();
    launch_test(3'd7);
    wait_for_result(1'b1, "prbs_hold_stress");

    apply_reset();
    inject_data_error = 1'b1;
    launch_test(3'd0);
    wait_for_result(1'b0, "read_data_injection");

    apply_reset();
    inject_bresp_error = 1'b1;
    launch_test(3'd0);
    wait_for_result(1'b0, "write_response_injection");

    apply_reset();
    stall_all = 1'b1;
    launch_test(3'd0);
    wait_for_result(1'b0, "protocol_timeout");
    if (timeout_count == 32'd0) begin
        $fatal(1, "Timeout test did not increment timeout_count");
    end
`endif

    $display("AXI_DDR_FULL_BIST_SIM_PASS smoke_bursts=%0d", `TB_SMOKE_BURSTS);
    $finish;
end

endmodule
