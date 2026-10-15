# tb_axi_ddr_bist

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\sim\tb_axi_ddr_bist.sv`
- SHA-256: `1986619b001fa8d988fac37b73b0588bf18534b97f8f1a05dba2464fb950db66`
- Extractor: `text`
- Tags: `ddr4, simulation`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

// axi_ddr_bist 的行为级定向验证环境。
// Testbench 用寄存器数组模拟 AXI Memory Slave，不实例化 MIG 和 DDR4 器件模型。
// 它用于快速检查五通道握手、错误检测、首错锁存和复位恢复；完整 DDR4 校准仍由
// sim_full 下的 MIG Example Design 仿真负责。
module tb_axi_ddr_bist;

localparam integer TEST_WORDS = 32;
localparam integer TIMEOUT_CYCLES = 20000;

reg aclk = 1'b0;
reg aresetn = 1'b0;
reg start = 1'b0;
always #5 aclk = ~aclk;

wire done;
wire pass;
wire fail;
wire [31:0] error_count;
wire [31:0] first_error_addr;
wire [63:0] first_expected_data;
wire [63:0] first_actual_data;

wire [3:0] awid;
wire [31:0] awaddr;
wire [7:0] awlen;
wire [2:0] awsize;
wire [1:0] awburst;
wire [0:0] awlock;
wire [3:0] awcache;
wire [2:0] awprot;
wire [3:0] awqos;
wire awvalid;
reg awready = 1'b0;

wire [63:0] wdata;
wire [7:0] wstrb;
wire wlast;
wire wvalid;
reg wready = 1'b0;

reg [3:0] bid = 4'd0;
reg [1:0] bresp = 2'b00;
reg bvalid = 1'b0;
wire bready;

wire [3:0] arid;
wire [31:0] araddr;
wire [7:0] arlen;
wire [2:0] arsize;
wire [1:0] arburst;
wire [0:0] arlock;
wire [3:0] arcache;
wire [2:0] arprot;
wire [3:0] arqos;
wire arvalid;
reg arready = 1'b0;

reg [3:0] rid = 4'd0;
reg [63:0] rdata = 64'd0;
reg [1:0] rresp = 2'b00;
reg rlast = 1'b0;
reg rvalid = 1'b0;
wire rready;

reg [63:0] memory [0:TEST_WORDS-1];
reg [31:0] cycle_count = 32'd0;
reg aw_pending = 1'b0;
reg w_pending = 1'b0;
reg [31:0] awaddr_hold = 32'd0;
reg [63:0] wdata_hold = 64'd0;
reg [31:0] read_index_hold = 32'd0;
reg [2:0] read_delay = 3'd0;

// 注错开关由测试控制流程设置。DIRECTED 第一阶段四项全开，复位恢复阶段全关。
reg inject_bresp_error = 1'b0;
reg inject_read_data_error = 1'b0;
reg inject_rresp_error = 1'b0;
reg inject_rlast_error = 1'b0;

integer write_txn_count = 0;
integer aw_first_count = 0;
integer w_first_count = 0;
integer same_cycle_count = 0;
integer i;
string test_case;

wire aw_fire = awvalid && awready;
wire w_fire = wvalid && wready;
wire ar_fire = arvalid && arready;

function [63:0] expected_pattern;
    input [31:0] index;
    begin
        expected_pattern = {~index, index};
    end
endfunction

axi_ddr_bist #(
    .TEST_WORDS(TEST_WORDS)
) dut (
    .aclk(aclk),
    .aresetn(aresetn),
    .start(start),
    .done(done),
    .pass(pass),
    .fail(fail),
    .error_count(error_count),
    .first_error_addr(first_error_addr),
    .first_expected_data(first_expected_data),
    .first_actual_data(first_actual_data),
    .m_axi_awid(awid),
    .m_axi_awaddr(awaddr),
    .m_axi_awlen(awlen),
    .m_axi_awsize(awsize),
    .m_axi_awburst(awburst),
    .m_axi_awlock(awlock),
    .m_axi_awcache(awcache),
    .m_axi_awprot(awprot),
    .m_axi_awqos(awqos),
    .m_axi_awvalid(awvalid),
    .m_axi_awready(awready),
    .m_axi_wdata(wdata),
    .m_axi_wstrb(wstrb),
    .m_axi_wlast(wlast),
    .m_axi_wvalid(wvalid),
    .m_axi_wready(wready),
    .m_axi_bid(bid),
    .m_axi_bresp(bresp),
    .m_axi_bvalid(bvalid),
    .m_axi_bready(bready),
    .m_axi_arid(arid),
    .m_axi_araddr(araddr),
    .m_axi_arlen(arlen),
    .m_axi_arsize(arsize),
    .m_axi_arburst(arburst),
    .m_axi_arlock(arlock),
    .m_axi_arcache(arcache),
    .m_axi_arprot(arprot),
    .m_axi_arqos(arqos),
    .m_axi_arvalid(arvalid),
    .m_axi_arready(arready),
    .m_axi_rid(rid),
    .m_axi_rdata(rdata),
    .m_axi_rresp(rresp),
    .m_axi_rlast(rlast),
    .m_axi_rvalid(rvalid),
    .m_axi_rready(rready)
);

// 确定性 AXI Slave：按写事务序号循环制造 AW 先到、W 先到和同拍握手。
// 每个读地址握手后固定等待三个时钟再返回数据，并可在指定索引注入协议/数据错误。
always @(posedge aclk) begin
    if (!aresetn) begin
        cycle_count <= 32'd0;
        awready <= 1'b0;
        wready <= 1'b0;
        arready <= 1'b0;
        aw_pending <= 1'b0;
        w_pending <= 1'b0;
        bvalid <= 1'b0;
        bresp <= 2'b00;
        rvalid <= 1'b0;
        rresp <= 2'b00;
        rlast <= 1'b0;
        read_delay <= 3'd0;
        write_txn_count <= 0;
        aw_first_count <= 0;
        w_first_count <= 0;
        same_cycle_count <= 0;
    end else begin
        cycle_count <= cycle_count + 32'd1;
        awready <= 1'b0;
        wready <= 1'b0;

        if (!bvalid) begin
            case (write_txn_count % 3)
                0: begin
                    if (!aw_pending)
                        awready <= 1'b1;
                    else if (!w_pending)
                        wready <= 1'b1;
                end
                1: begin
                    if (!w_pending)
                        wready <= 1'b1;
                    else if (!aw_pending)
                        awready <= 1'b1;
                end
                default: begin
                    awready <= !aw_pending;
                    wready <= !w_pending;
                end
            endcase
        end

        arready <= !rvalid && (read_delay == 0) && cycle_count[0];

        if (!aw_pending && !w_pending) begin
            if (aw_fire && w_fire)
                same_cycle_count <= same_cycle_count + 1;
            else if (aw_fire)
                aw_first_count <= aw_first_count + 1;
            else if (w_fire)
                w_first_count <= w_first_count + 1;
        end

        if (aw_fire) begin
            aw_pending <= 1'b1;
            awaddr_hold <= awaddr;
        end
        if (w_fire) begin
            w_pending <= 1'b1;
            wdata_hold <= wdata;
        end

        if (!bvalid && (aw_pending || aw_fire) && (w_pending || w_fire)) begin
            memory[(aw_pending ? awaddr_hold : awaddr) >> 3]
                <= w_pending ? wdata_hold : wdata;
            if (inject_bresp_error &&
                (((aw_pending ? awaddr_hold : awaddr) >> 3) == 3))
                bresp <= 2'b10;
            else
                bresp <= 2'b00;
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            bvalid <= 1'b1;
            write_txn_count <= write_txn_count + 1;
        end else if (bvalid && bready) begin
            bvalid <= 1'b0;
            bresp <= 2'b00;
        end

        if (ar_fire) begin
            read_index_hold <= araddr >> 3;
            read_delay <= 3'd3;
        end else if (read_delay != 0) begin
            read_delay <= read_delay - 3'd1;
            if (read_delay == 1) begin
                rdata <= memory[read_index_hold];
                if (inject_read_data_error && read_index_hold == 7)
                    rdata <= memory[read_index_hold] ^ 64'h1;
                if (inject_rresp_error && read_index_hold == 9)
                    rresp <= 2'b10;
                else
                    rresp <= 2'b00;
                if (inject_rlast_error && read_index_hold == 11)
                    rlast <= 1'b0;
                else
                    rlast <= 1'b1;
                rvalid <= 1'b1;
            end
        end

        if (rvalid && rready) begin
            rvalid <= 1'b0;
            rresp <= 2'b00;
            rlast <= 1'b0;
        end
    end
end

task set_injections;
    input bresp_en;
    input data_en;
    input rresp_en;
    input rlast_en;
    begin
        inject_bresp_error = bresp_en;
        inject_read_data_error = data_en;
        inject_rresp_error = rresp_en;
        inject_rlast_error = rlast_en;
    end
endtask

task reset_and_release;
    begin
        @(negedge aclk);
        aresetn = 1'b0;
        start = 1'b0;
        repeat (4) @(posedge aclk);
        #1;
        if (done !== 1'b0 || pass !== 1'b0 || fail !== 1'b0 ||
            error_count !== 32'd0 || awvalid !== 1'b0 || wvalid !== 1'b0 ||
            bready !== 1'b0 || arvalid !== 1'b0 || rready !== 1'b0)
            $fatal(1, "RESET_CHECK_FAIL: DUT outputs were not cleared");
        $display("DIRECTED_RESET_STATE=PASS time=%0t", $time);
        @(negedge aclk);
        aresetn = 1'b1;
        repeat (2) @(posedge aclk);
    end
endtask

task pulse_start;
    begin
        @(negedge aclk);
        start = 1'b1;
        @(negedge aclk);
        start = 1'b0;
    end
endtask

task wait_for_done;
    integer timeout_count;
    begin
        timeout_count = 0;
        while (done !== 1'b1 && timeout_count < TIMEOUT_CYCLES) begin
            @(posedge aclk);
            #1;
            timeout_count = timeout_count + 1;
        end
        if (done !== 1'b1)
            $fatal(1, "TIMEOUT: BIST did not complete after %0d cycles", timeout_count);
    end
endtask

task check_handshake_order;
    begin
        if (aw_first_count == 0 || w_first_count == 0 || same_cycle_count == 0)
            $fatal(1, "HANDSHAKE_ORDER_FAIL aw_first=%0d w_first=%0d same_cycle=%0d",
                   aw_first_count, w_first_count, same_cycle_count);
        $display("HANDSHAKE_ORDER_COVERAGE=PASS aw_first=%0d w_first=%0d same_cycle=%0d",
                 aw_first_count, w_first_count, same_cycle_count);
    end
endtask

task check_clean_result;
    begin
        if (done !== 1'b1 || pass !== 1'b1 || fail !== 1'b0 || error_count !== 32'd0)
            $fatal(1, "CLEAN_RESULT_FAIL done=%b pass=%b fail=%b errors=%0d",
                   done, pass, fail, error_count);
        check_handshake_order();
    end
endtask

task check_error_result;
    input [31:0] expected_count;
    input [31:0] expected_addr;
    input [63:0] expected_data;
    input [63:0] expected_actual;
    begin
        if (done !== 1'b1 || pass !== 1'b0 || fail !== 1'b1 ||
            error_count !== expected_count || first_error_addr !== expected_addr ||
            first_expected_data !== expected_data || first_actual_data !== expected_actual)
            $fatal(1,
                   "ERROR_RESULT_FAIL done=%b pass=%b fail=%b errors=%0d addr=%h expected=%h actual=%h",
                   done, pass, fail, error_count, first_error_addr,
                   first_expected_data, first_actual_data);
        check_handshake_order();
    end
endtask

task run_one_phase;
    begin
        reset_and_release();
        pulse_start();
        wait_for_done();
    end
endtask

initial begin
    for (i = 0; i < TEST_WORDS; i = i + 1)
        memory[i] = 64'd0;

    test_case = "CLEAN";
    if (!$value$plusargs("TEST_CASE=%s", test_case)) begin
        if ($test$plusargs("INJECT_ERROR"))
            test_case = "READ_DATA_ERROR";
    end
    $display("TEST_CASE_SELECTED=%s", test_case);

    case (test_case)
        "CLEAN": begin
            set_injections(0, 0, 0, 0);
            run_one_phase();
            check_clean_result();
            $display("CASE_RESULT=PASS case=CLEAN");
        end

        "READ_DATA_ERROR": begin
            set_injections(0, 1, 0, 0);
            run_one_phase();
            check_error_result(1, 32'h0000_0038,
                               expected_pattern(32'd7),
                               expected_pattern(32'd7) ^ 64'h1);
            $display("CASE_RESULT=PASS case=READ_DATA_ERROR");
        end

        "BRESP_ERROR": begin
            set_injections(1, 0, 0, 0);
            run_one_phase();
            check_error_result(1, 32'h0000_0018,
                               expected_pattern(32'd3), 64'd0);
            $display("CASE_RESULT=PASS case=BRESP_ERROR");
        end

        "RRESP_ERROR": begin
            set_injections(0, 0, 1, 0);
            run_one_phase();
            check_error_result(1, 32'h0000_0048,
                               expected_pattern(32'd9),
                               expected_pattern(32'd9));
            $display("CASE_RESULT=PASS case=RRESP_ERROR");
        end

        "RLAST_ERROR": begin
            set_injections(0, 0, 0, 1);
            run_one_phase();
            check_error_result(1, 32'h0000_0058,
                               expected_pattern(32'd11),
                               expected_pattern(32'd11));
            $display("CASE_RESULT=PASS case=RLAST_ERROR");
        end

        "RESET_RECOVERY": begin
            set_injections(0, 0, 0, 0);
            run_one_phase();
            check_clean_result();
            $display("RESET_RECOVERY_PHASE1=PASS");
            run_one_phase();
            check_clean_result();
            $display("RESET_RECOVERY_PHASE2=PASS");
            $display("CASE_RESULT=PASS case=RESET_RECOVERY");
        end

        "DIRECTED": begin
            set_injections(1, 1, 1, 1);
            run_one_phase();
            check_error_result(4, 32'h0000_0018,
                               64'hFFFF_FFFC_0000_0003, 64'd0);
            $display("DIRECTED_PHASE1_RESULT=PASS errors=%0d first_addr=0x%08h",
                     error_count, first_error_addr);

            set_injections(0, 0, 0, 0);
            run_one_phase();
            check_clean_result();
            $display("DIRECTED_PHASE2_RESULT=PASS errors=%0d", error_count);
            $display("DIRECTED_CASE_RESULT=PASS");
        end

        default: begin
            $fatal(1, "UNKNOWN_TEST_CASE: %s", test_case);
        end
    endcase

    repeat (2) @(posedge aclk);
    $finish;
end

endmodule
```
