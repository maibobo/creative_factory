# tb_nophae_dma_backend

- Category: `cross_ip`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\sim\tb_nophae_dma_backend.sv`
- SHA-256: `799d38ec646b4c708b02e692484f01f1d8c826d2d10ddb193bf7be3dbce2f5a4`
- Extractor: `text`
- Tags: `nvme, pcie, verification`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps

// 以Vitis现有test_seq()/flush()为黄金寄存器序列，验证纯RTL Backend：
// 1. DDR AXI物理地址减0x8000_0000后写入NoPHAE 32 bit偏移寄存器；
// 2. byte_len按512 B换算成dma_len，而不是写字节数或NLB-1；
// 3. Write/Read的src/dst方向与软件一致；
// 4. Flush原生命令字段、CMD_CCNT轮询、Tag回送和错误/超时路径。
module tb_nophae_dma_backend;

    localparam integer CTRL_ADDR_WIDTH = 40;
    localparam [63:0] DDR_BASE = 64'h0000_0000_8000_0000;
    localparam [63:0] DDR_BYTES = 64'h0000_0000_8000_0000;

    reg clk = 1'b0;
    always #4 clk = ~clk;
    reg rst_n = 1'b0;
    reg enable = 1'b1;

    reg req_valid = 1'b0;
    wire req_ready;
    reg [1:0] req_opcode = 2'd0;
    reg [31:0] req_ddr_addr = 32'd0;
    reg [31:0] req_byte_len = 32'd0;
    reg [63:0] req_slba = 64'd0;
    reg [15:0] req_user_tag = 16'd0;
    wire cpl_valid;
    reg cpl_ready = 1'b1;
    wire [15:0] cpl_user_tag;
    wire [15:0] cpl_status;

    wire [CTRL_ADDR_WIDTH-1:0] awaddr;
    wire [2:0] awprot;
    wire awvalid;
    wire awready;
    wire [31:0] wdata;
    wire [3:0] wstrb;
    wire wvalid;
    wire wready;
    wire [1:0] bresp;
    wire bvalid;
    wire bready;
    wire [CTRL_ADDR_WIDTH-1:0] araddr;
    wire [2:0] arprot;
    wire arvalid;
    wire arready;
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    wire rready;

    wire backend_busy;
    wire error_sticky;
    wire timeout_sticky;
    wire [15:0] last_status;
    wire [31:0] completed_command_count;

    reg stall_all = 1'b0;
    reg force_slverr = 1'b0;
    reg dma_ready_value = 1'b1;
    reg dma_never_done = 1'b0;
    reg flush_never_done = 1'b0;
    wire [31:0] dma_start_count;
    wire [31:0] flush_start_count;
    wire [31:0] last_dma_direction;
    wire [31:0] last_dma_src;
    wire [31:0] last_dma_dst;
    wire [31:0] last_dma_lba_count;
    wire [31:0] last_cmd_code;
    wire [31:0] debug_lock_value;
    wire [31:0] command_count;

    nophae_dma_backend #(
        .AXI_ADDR_WIDTH        (32),
        .CTRL_ADDR_WIDTH       (CTRL_ADDR_WIDTH),
        .CTRL_BASE_ADDR        (40'h00_1000_0000),
        .DDR_AXI_BASE_ADDR     (DDR_BASE),
        .DDR_WINDOW_BYTES      (DDR_BYTES),
        .LBA_BYTES             (512),
        .COMMAND_TIMEOUT_CYCLES(160),
        .AXIL_TIMEOUT_CYCLES   (24)
    ) dut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .enable                 (enable),
        .req_valid              (req_valid),
        .req_ready              (req_ready),
        .req_opcode             (req_opcode),
        .req_ddr_addr           (req_ddr_addr),
        .req_byte_len           (req_byte_len),
        .req_slba               (req_slba),
        .req_user_tag           (req_user_tag),
        .cpl_valid              (cpl_valid),
        .cpl_ready              (cpl_ready),
        .cpl_user_tag           (cpl_user_tag),
        .cpl_status             (cpl_status),
        .m_axi_awaddr           (awaddr),
        .m_axi_awprot           (awprot),
        .m_axi_awvalid          (awvalid),
        .m_axi_awready          (awready),
        .m_axi_wdata            (wdata),
        .m_axi_wstrb            (wstrb),
        .m_axi_wvalid           (wvalid),
        .m_axi_wready           (wready),
        .m_axi_bresp            (bresp),
        .m_axi_bvalid           (bvalid),
        .m_axi_bready           (bready),
        .m_axi_araddr           (araddr),
        .m_axi_arprot           (arprot),
        .m_axi_arvalid          (arvalid),
        .m_axi_arready          (arready),
        .m_axi_rdata            (rdata),
        .m_axi_rresp            (rresp),
        .m_axi_rvalid           (rvalid),
        .m_axi_rready           (rready),
        .busy                   (backend_busy),
        .error_sticky           (error_sticky),
        .timeout_sticky         (timeout_sticky),
        .last_status            (last_status),
        .completed_command_count(completed_command_count)
    );

    nophae_ctrl_reg_stub #(
        .CTRL_ADDR_WIDTH       (CTRL_ADDR_WIDTH),
        .CTRL_BASE_ADDR        (40'h00_1000_0000),
        .DMA_COMPLETE_LATENCY  (3),
        .FLUSH_COMPLETE_LATENCY(3)
    ) u_regs (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .s_axi_awaddr          (awaddr),
        .s_axi_awprot          (awprot),
        .s_axi_awvalid         (awvalid),
        .s_axi_awready         (awready),
        .s_axi_wdata           (wdata),
        .s_axi_wstrb           (wstrb),
        .s_axi_wvalid          (wvalid),
        .s_axi_wready          (wready),
        .s_axi_bresp           (bresp),
        .s_axi_bvalid          (bvalid),
        .s_axi_bready          (bready),
        .s_axi_araddr          (araddr),
        .s_axi_arprot          (arprot),
        .s_axi_arvalid         (arvalid),
        .s_axi_arready         (arready),
        .s_axi_rdata           (rdata),
        .s_axi_rresp           (rresp),
        .s_axi_rvalid          (rvalid),
        .s_axi_rready          (rready),
        .stall_all             (stall_all),
        .force_slverr          (force_slverr),
        .dma_ready_value       (dma_ready_value),
        .dma_never_done        (dma_never_done),
        .flush_never_done      (flush_never_done),
        .dma_start_count       (dma_start_count),
        .flush_start_count     (flush_start_count),
        .last_dma_direction    (last_dma_direction),
        .last_dma_src          (last_dma_src),
        .last_dma_dst          (last_dma_dst),
        .last_dma_lba_count    (last_dma_lba_count),
        .last_cmd_code         (last_cmd_code),
        .debug_lock_value      (debug_lock_value),
        .command_count         (command_count)
    );

    task automatic submit_and_expect;
        input [1:0] opcode;
        input [31:0] ddr_addr;
        input [31:0] byte_len;
        input [63:0] slba;
        input [15:0] tag;
        input [15:0] expected_status;
        integer cycles;
        begin
            cycles = 0;
            while (!req_ready && cycles < 300) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!req_ready)
                $fatal(1, "request ready timeout");
            @(negedge clk);
            req_opcode   = opcode;
            req_ddr_addr = ddr_addr;
            req_byte_len = byte_len;
            req_slba     = slba;
            req_user_tag = tag;
            req_valid    = 1'b1;
            @(posedge clk);
            if (!(req_valid && req_ready))
                $fatal(1, "request handshake missing");
            @(negedge clk);
            req_valid = 1'b0;

            cycles = 0;
            while (!cpl_valid && cycles < 500) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!cpl_valid)
                $fatal(1, "completion timeout tag=%h", tag);
            if (cpl_user_tag !== tag)
                $fatal(1, "completion tag mismatch exp=%h got=%h",
                       tag, cpl_user_tag);
            if (cpl_status !== expected_status)
                $fatal(1, "completion status mismatch tag=%h exp=%h got=%h",
                       tag, expected_status, cpl_status);
            @(posedge clk);
        end
    endtask

    initial begin
        repeat (6) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        submit_and_expect(
            2'd0, 32'hC000_0000, 32'd4096, 64'h1234, 16'h1001, 16'd0);
        if ((last_dma_direction !== 32'd1) ||
            (last_dma_src !== 32'h4000_0000) ||
            (last_dma_dst !== 32'h0000_1234) ||
            (last_dma_lba_count !== 32'd8))
            $fatal(1, "WRITE register translation mismatch");

        submit_and_expect(
            2'd1, 32'hC000_1000, 32'd8192, 64'h2000, 16'h1002, 16'd0);
        if ((last_dma_direction !== 32'd0) ||
            (last_dma_src !== 32'h0000_2000) ||
            (last_dma_dst !== 32'h4000_1000) ||
            (last_dma_lba_count !== 32'd16))
            $fatal(1, "READ register translation mismatch");

        submit_and_expect(
            2'd2, 32'd0, 32'd0, 64'd0, 16'h1003, 16'd0);
        if ((flush_start_count !== 1) ||
            (last_cmd_code !== 32'h0101_0000) ||
            (debug_lock_value !== 0) ||
            (command_count !== 1))
            $fatal(1, "FLUSH register sequence mismatch");

        submit_and_expect(
            2'd0, 32'h7000_0000, 32'd4096, 64'h10,
            16'h1004, 16'hE003);
        submit_and_expect(
            2'd0, 32'hC000_0000, 32'd1000, 64'h10,
            16'h1005, 16'hE002);

        force_slverr = 1'b1;
        submit_and_expect(
            2'd0, 32'hC000_0000, 32'd4096, 64'h20,
            16'h1006, 16'hE005);
        force_slverr = 1'b0;

        dma_never_done = 1'b1;
        submit_and_expect(
            2'd0, 32'hC000_0000, 32'd4096, 64'h30,
            16'h1007, 16'hE007);
        dma_never_done = 1'b0;
        if (!timeout_sticky || !error_sticky)
            $fatal(1, "timeout/error sticky flags not set");

        if ((dma_start_count !== 3) ||
            (completed_command_count !== 3))
            $fatal(1, "unexpected command counters dma=%0d completed=%0d",
                   dma_start_count, completed_command_count);

        $display("TEST_PASS: NoPHAE Vitis register contract, address translation, errors and timeout");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "global simulation timeout");
    end

endmodule
```
