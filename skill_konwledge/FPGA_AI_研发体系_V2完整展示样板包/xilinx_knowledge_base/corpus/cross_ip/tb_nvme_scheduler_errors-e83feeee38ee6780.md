# tb_nvme_scheduler_errors

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\sim\tb_nvme_scheduler_errors.sv`
- SHA-256: `e83feeee38ee6780b55836497cad06a88e073eb5eba520ff87a4730740b662ab`
- Extractor: `text`
- Tags: `nvme, pcie, verification`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps

// nvme_request_scheduler故障路径回归。
//
// 使用抽象req/cpl Stub分别注入完成失败、错Tag、永久无完成、Link Down、
// 第一次Flush失败和ECQE异步错误，验证调度器会锁存fatal并保留错误证据。
// 本测试不涉及DDR内容、PCIe协议或真实SSD。
module tb_nvme_scheduler_errors;

    // 125 MHz系统控制时钟。
    reg clk = 1'b0;
    always #4 clk = ~clk; // 125 MHz

    reg rst_n = 1'b0;
    reg nvme_init_done = 1'b1;
    reg pcie_link_up = 1'b1;
    reg ecqe_error_valid = 1'b0;
    reg [15:0] ecqe_error_status = 16'd0;
    reg ready_valid = 1'b0;
    wire ready_accept;
    reg [15:0] ready_tag = 16'h0102;
    reg [63:0] ready_ddr_addr = 64'h0000_0000_0000_4000;
    reg [63:0] ready_payload_bytes = 64'd1024;
    reg [31:0] ready_dma_bytes = 32'd4096;
    wire manager_completion_valid;
    wire [15:0] manager_completion_tag;
    wire [15:0] manager_completion_status;
    reg commit_valid = 1'b0;
    wire commit_ready;
    reg [63:0] commit_ddr_addr = 64'h0000_0000_0000_8000;
    reg [31:0] commit_dma_bytes = 32'd4096;
    reg [63:0] commit_capture_id = 64'h55AA;

    wire req_valid;
    wire req_ready;
    wire [1:0] req_opcode;
    wire [63:0] req_ddr_addr;
    wire [31:0] req_byte_len;
    wire [63:0] req_slba;
    wire [15:0] req_user_tag;
    wire cpl_valid;
    wire cpl_ready;
    wire [15:0] cpl_user_tag;
    wire [15:0] cpl_status;
    wire capture_done;
    wire [63:0] last_capture_id;
    wire fatal_error;
    wire timeout_sticky;
    wire link_down_sticky;
    wire [31:0] submitted_requests;
    wire [31:0] completed_requests;

    reg inject_fail_next = 1'b0;
    reg inject_timeout_next = 1'b0;
    reg inject_bad_tag_next = 1'b0;

    // 调度器参数：
    // 64 bit DDR地址；512 B LBA；为缩短仿真将超时设为32周期；
    // Raw LBA从2048开始。
    nvme_request_scheduler #(
        // 测试描述符使用64 bit DDR地址。
        .AXI_ADDR_WIDTH         (64),
        // 1个LBA为512 Byte。
        .LBA_BYTES              (512),
        // 故障回归使用32周期快速触发watchdog。
        .COMMAND_TIMEOUT_CYCLES (32),
        // 起始SLBA。
        .BASE_SLBA              (64'd2048)
    ) dut (
        .clk                       (clk),
        .rst_n                     (rst_n),
        .nvme_init_done            (nvme_init_done),
        .pcie_link_up              (pcie_link_up),
        .ecqe_error_valid          (ecqe_error_valid),
        .ecqe_error_status         (ecqe_error_status),
        .ready_valid               (ready_valid),
        .ready_accept              (ready_accept),
        .ready_tag                 (ready_tag),
        .ready_ddr_addr            (ready_ddr_addr),
        .ready_payload_bytes       (ready_payload_bytes),
        .ready_dma_bytes           (ready_dma_bytes),
        .manager_completion_valid  (manager_completion_valid),
        .manager_completion_tag    (manager_completion_tag),
        .manager_completion_status (manager_completion_status),
        .commit_valid              (commit_valid),
        .commit_ready              (commit_ready),
        .commit_ddr_addr           (commit_ddr_addr),
        .commit_dma_bytes          (commit_dma_bytes),
        .commit_capture_id         (commit_capture_id),
        .nvme_req_valid            (req_valid),
        .nvme_req_ready            (req_ready),
        .nvme_req_opcode           (req_opcode),
        .nvme_req_ddr_addr         (req_ddr_addr),
        .nvme_req_byte_len         (req_byte_len),
        .nvme_req_slba             (req_slba),
        .nvme_req_user_tag         (req_user_tag),
        .nvme_cpl_valid            (cpl_valid),
        .nvme_cpl_ready            (cpl_ready),
        .nvme_cpl_user_tag         (cpl_user_tag),
        .nvme_cpl_status           (cpl_status),
        .capture_done              (capture_done),
        .last_capture_id           (last_capture_id),
        .fatal_error               (fatal_error),
        .timeout_sticky            (timeout_sticky),
        .link_down_sticky          (link_down_sticky),
        .submitted_requests        (submitted_requests),
        .completed_requests        (completed_requests)
    );

    // 抽象Stub正常完成延迟4周期；它不访问req_ddr_addr指向的内存。
    nvme_req_cpl_stub #(
        // 与调度器地址口一致。
        .AXI_ADDR_WIDTH   (64),
        // 正常请求4周期后返回Completion。
        .COMPLETE_LATENCY (4)
    ) u_stub (
        .clk                 (clk),
        .rst_n               (rst_n),
        .req_valid           (req_valid),
        .req_ready           (req_ready),
        .req_opcode          (req_opcode),
        .req_ddr_addr        (req_ddr_addr),
        .req_byte_len        (req_byte_len),
        .req_slba            (req_slba),
        .req_user_tag        (req_user_tag),
        .cpl_valid           (cpl_valid),
        .cpl_ready           (cpl_ready),
        .cpl_user_tag        (cpl_user_tag),
        .cpl_status          (cpl_status),
        .inject_fail_next    (inject_fail_next),
        .inject_timeout_next (inject_timeout_next),
        .inject_bad_tag_next (inject_bad_tag_next),
        .request_count       (),
        .write_count         (),
        .read_count          (),
        .flush_count         (),
        .last_opcode         (),
        .last_ddr_addr       (),
        .last_byte_len       (),
        .last_slba           (),
        .last_user_tag       ()
    );

    // 每个故障用例独立复位DUT和Stub，避免前一个fatal sticky影响下一个结论。
    task automatic reset_case;
        begin
            rst_n = 1'b0;
            ready_valid = 1'b0;
            commit_valid = 1'b0;
            pcie_link_up = 1'b1;
            ecqe_error_valid = 1'b0;
            inject_fail_next = 1'b0;
            inject_timeout_next = 1'b0;
            inject_bad_tag_next = 1'b0;
            repeat (4) @(posedge clk);
            rst_n = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    // 保持ready_valid，直到调度器真正接受Payload描述符。
    task automatic submit_data;
        begin
            ready_valid = 1'b1;
            while (!ready_accept)
                @(posedge clk);
            ready_valid = 1'b0;
        end
    endtask

    // 给每个用例最多128周期观察fatal，超时表示预期保护路径未动作。
    task automatic wait_fatal;
        integer cycles;
        begin
            cycles = 0;
            while (!fatal_error && cycles < 128) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!fatal_error)
                $fatal(1, "Expected fatal_error was not asserted");
        end
    endtask

    reg [177:0] held_req;
    reg held_req_valid = 1'b0;

    // 协议断言：后端反压时请求所有字段稳定；READ/WRITE地址和长度均4 KiB对齐。
    always @(posedge clk) begin
        if (req_valid && !req_ready) begin
            if (held_req_valid &&
                held_req !== {req_opcode, req_ddr_addr, req_byte_len,
                              req_slba, req_user_tag})
                $fatal(1, "ASSERT: NVMe request changed while stalled");
            held_req <= {req_opcode, req_ddr_addr, req_byte_len,
                         req_slba, req_user_tag};
            held_req_valid <= 1'b1;
        end else begin
            held_req_valid <= 1'b0;
        end
        if (req_valid && req_ready &&
            ((req_opcode == 2'd0) || (req_opcode == 2'd1)) &&
            (((req_ddr_addr % 4096) != 0) ||
             ((req_byte_len % 4096) != 0)))
            $fatal(1, "ASSERT: unaligned DMA request");
    end

    initial begin
        // Completion status failure：非零status必须回送Manager并冻结后续请求。
        $display("CASE: completion status failure");
        reset_case();
        inject_fail_next = 1'b1;
        submit_data();
        inject_fail_next = 1'b0;
        wait_fatal();
        if (!manager_completion_valid && (manager_completion_status == 0))
            $fatal(1, "Failed completion was not surfaced");

        // Completion tag mismatch：防止错误完成释放另一个分段。
        $display("CASE: completion tag mismatch");
        reset_case();
        inject_bad_tag_next = 1'b1;
        submit_data();
        inject_bad_tag_next = 1'b0;
        wait_fatal();
        if (manager_completion_status != 16'hFFFF)
            $fatal(1, "Bad tag did not map to status FFFF");

        // Timeout：Stub永久不完成，调度器自身watchdog应置timeout_sticky。
        $display("CASE: command timeout");
        reset_case();
        inject_timeout_next = 1'b1;
        submit_data();
        inject_timeout_next = 1'b0;
        wait_fatal();
        if (!timeout_sticky)
            $fatal(1, "Timeout sticky flag was not asserted");

        // Link down：初始化后链路掉线立即进入fatal，不等待命令超时。
        $display("CASE: link down");
        reset_case();
        pcie_link_up = 1'b0;
        wait_fatal();
        if (!link_down_sticky)
            $fatal(1, "Link-down sticky flag was not asserted");

        // Flush failure：Commit描述符被接受后第一条命令应为Flush，
        // 该Flush失败时不得继续写Commit页。
        $display("CASE: flush failure");
        reset_case();
        inject_fail_next = 1'b1;
        commit_valid = 1'b1;
        while (!commit_ready)
            @(posedge clk);
        commit_valid = 1'b0;
        while (!(req_valid && req_ready))
            @(posedge clk);
        @(negedge clk);
        inject_fail_next = 1'b0;
        wait_fatal();

        // ECQE：供应商侧异步错误入口不依赖当前请求完成握手。
        $display("CASE: ECQE");
        reset_case();
        ecqe_error_status = 16'h1234;
        ecqe_error_valid = 1'b1;
        @(posedge clk);
        ecqe_error_valid = 1'b0;
        wait_fatal();

        $display("TEST_PASS: NVMe completion error, tag, timeout, link, flush and ECQE");
        $finish;
    end

    // 全局死锁保护。
    initial begin
        #1_000_000;
        $fatal(1, "Scheduler error regression timeout");
    end

endmodule
```
