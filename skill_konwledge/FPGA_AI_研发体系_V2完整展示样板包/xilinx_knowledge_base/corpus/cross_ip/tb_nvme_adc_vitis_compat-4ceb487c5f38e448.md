# tb_nvme_adc_vitis_compat

- Category: `cross_ip`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\sim\tb_nvme_adc_vitis_compat.sv`
- SHA-256: `4ceb487c5f38e448cc35fc0ca950e9659d2645bddb0267d8f517a07ca9365c40`
- Extractor: `text`
- Tags: `nvme, pcie, verification`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps

// 验证“现有Vitis寄存器ABI -> 自动定长ADC采集 -> DDR -> NoPHAE寄存器序列”
// 的完整行为闭环。全部模型均为行为级，不包含综合、MIG校准、PCIe或真实SSD。
module tb_nvme_adc_vitis_compat;

    localparam integer AXI_ADDR_WIDTH = 32;
    localparam integer CTRL_ADDR_WIDTH = 40;
    localparam integer AXI_DATA_WIDTH = 256;
    localparam integer SEGMENT_BYTES = 4096;
    localparam integer SEGMENT_COUNT = 2;
    localparam [31:0] CAPTURE_BASE = 32'h8001_0000;
    localparam [31:0] COMMIT_ADDR =
        CAPTURE_BASE + SEGMENT_BYTES * SEGMENT_COUNT;
    localparam integer MEM_BYTES =
        SEGMENT_BYTES * SEGMENT_COUNT + 4096;
    localparam [39:0] FDMA_BASE = 40'h00_9000_0000;
    localparam [39:0] NOPHAE_BASE = 40'h00_1000_0000;
    localparam [31:0] SAFE_SLBA = 32'h0000_2000;

    reg adc_clk = 1'b0;
    reg sys_clk = 1'b0;
    always #2 adc_clk = ~adc_clk;
    initial begin
        #1;
        forever #4 sys_clk = ~sys_clk;
    end

    reg adc_rst_n = 1'b0;
    reg sys_rst_n = 1'b0;
    reg adc_valid = 1'b0;
    reg [11:0] adc_ch0 = 12'd0;
    reg [11:0] adc_ch1 = 12'd0;
    reg ddr_init_done = 1'b0;
    reg nvme_init_done = 1'b0;
    reg pcie_link_up = 1'b1;
    reg ecqe_error_valid = 1'b0;
    reg [15:0] ecqe_error_status = 16'd0;

    wire [31:0] ddr_awaddr;
    wire [7:0] ddr_awlen;
    wire [2:0] ddr_awsize;
    wire [1:0] ddr_awburst;
    wire ddr_awvalid;
    wire ddr_awready;
    wire [255:0] ddr_wdata;
    wire [31:0] ddr_wstrb;
    wire ddr_wlast;
    wire ddr_wvalid;
    wire ddr_wready;
    wire [1:0] ddr_bresp;
    wire ddr_bvalid;
    wire ddr_bready;

    reg [39:0] fdma_awaddr = 40'd0;
    reg [2:0] fdma_awprot = 3'd0;
    reg fdma_awvalid = 1'b0;
    wire fdma_awready;
    reg [31:0] fdma_wdata = 32'd0;
    reg [3:0] fdma_wstrb = 4'd0;
    reg fdma_wvalid = 1'b0;
    wire fdma_wready;
    wire [1:0] fdma_bresp;
    wire fdma_bvalid;
    reg fdma_bready = 1'b0;
    reg [39:0] fdma_araddr = 40'd0;
    reg [2:0] fdma_arprot = 3'd0;
    reg fdma_arvalid = 1'b0;
    wire fdma_arready;
    wire [31:0] fdma_rdata;
    wire [1:0] fdma_rresp;
    wire fdma_rvalid;
    reg fdma_rready = 1'b0;

    wire [39:0] nophae_awaddr;
    wire [2:0] nophae_awprot;
    wire nophae_awvalid;
    wire nophae_awready;
    wire [31:0] nophae_wdata;
    wire [3:0] nophae_wstrb;
    wire nophae_wvalid;
    wire nophae_wready;
    wire [1:0] nophae_bresp;
    wire nophae_bvalid;
    wire nophae_bready;
    wire [39:0] nophae_araddr;
    wire [2:0] nophae_arprot;
    wire nophae_arvalid;
    wire nophae_arready;
    wire [31:0] nophae_rdata;
    wire [1:0] nophae_rresp;
    wire nophae_rvalid;
    wire nophae_rready;

    wire fdma_transfer_active;
    wire capture_controller_busy;
    wire capture_active;
    wire capture_ready;
    wire local_capture_done_pulse;
    wire capture_cancelled_pulse;
    wire capture_done;
    wire [63:0] last_capture_id;
    wire backend_busy;
    wire [15:0] backend_last_status;
    wire [15:0] fdma_last_error;
    wire fatal_error;
    wire [63:0] accepted_sample_times;
    wire [63:0] dropped_sample_times;
    wire [31:0] submitted_requests;
    wire [31:0] completed_requests;

    nvme_adc_vitis_compat_top #(
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        .CTRL_ADDR_WIDTH         (CTRL_ADDR_WIDTH),
        .AXI_DATA_WIDTH          (AXI_DATA_WIDTH),
        .SEGMENT_BYTES           (SEGMENT_BYTES),
        .SEGMENT_COUNT           (SEGMENT_COUNT),
        .BURST_BEATS             (16),
        .ADC_FIFO_AW             (6),
        .COMMAND_TIMEOUT_CYCLES  (5000),
        .AXIL_TIMEOUT_CYCLES     (128),
        .LBA_BYTES               (512),
        .CAPTURE_DDR_BASE_ADDR   (CAPTURE_BASE),
        .COMMIT_DDR_ADDR         (COMMIT_ADDR),
        .DDR_AXI_BASE_ADDR       (64'h0000_0000_8000_0000),
        .DDR_WINDOW_BYTES        (64'h0000_0000_0100_0000),
        .NOPHAE_CTRL_BASE_ADDR   (NOPHAE_BASE),
        .FDMA_CTRL_BASE_ADDR     (FDMA_BASE),
        .MIN_START_SLBA          (32'h0000_1000)
    ) dut (
        .adc_clk                    (adc_clk),
        .adc_rst_n                  (adc_rst_n),
        .adc_valid                  (adc_valid),
        .adc_ch0                    (adc_ch0),
        .adc_ch1                    (adc_ch1),
        .sys_clk                    (sys_clk),
        .sys_rst_n                  (sys_rst_n),
        .ddr_init_done              (ddr_init_done),
        .nvme_init_done             (nvme_init_done),
        .pcie_link_up               (pcie_link_up),
        .ecqe_error_valid           (ecqe_error_valid),
        .ecqe_error_status          (ecqe_error_status),
        .m_axi_ddr_awaddr           (ddr_awaddr),
        .m_axi_ddr_awlen            (ddr_awlen),
        .m_axi_ddr_awsize           (ddr_awsize),
        .m_axi_ddr_awburst          (ddr_awburst),
        .m_axi_ddr_awvalid          (ddr_awvalid),
        .m_axi_ddr_awready          (ddr_awready),
        .m_axi_ddr_wdata            (ddr_wdata),
        .m_axi_ddr_wstrb            (ddr_wstrb),
        .m_axi_ddr_wlast            (ddr_wlast),
        .m_axi_ddr_wvalid           (ddr_wvalid),
        .m_axi_ddr_wready           (ddr_wready),
        .m_axi_ddr_bresp            (ddr_bresp),
        .m_axi_ddr_bvalid           (ddr_bvalid),
        .m_axi_ddr_bready           (ddr_bready),
        .s_axi_fdma_awaddr          (fdma_awaddr),
        .s_axi_fdma_awprot          (fdma_awprot),
        .s_axi_fdma_awvalid         (fdma_awvalid),
        .s_axi_fdma_awready         (fdma_awready),
        .s_axi_fdma_wdata           (fdma_wdata),
        .s_axi_fdma_wstrb           (fdma_wstrb),
        .s_axi_fdma_wvalid          (fdma_wvalid),
        .s_axi_fdma_wready          (fdma_wready),
        .s_axi_fdma_bresp           (fdma_bresp),
        .s_axi_fdma_bvalid          (fdma_bvalid),
        .s_axi_fdma_bready          (fdma_bready),
        .s_axi_fdma_araddr          (fdma_araddr),
        .s_axi_fdma_arprot          (fdma_arprot),
        .s_axi_fdma_arvalid         (fdma_arvalid),
        .s_axi_fdma_arready         (fdma_arready),
        .s_axi_fdma_rdata           (fdma_rdata),
        .s_axi_fdma_rresp           (fdma_rresp),
        .s_axi_fdma_rvalid          (fdma_rvalid),
        .s_axi_fdma_rready          (fdma_rready),
        .m_axi_nophae_awaddr        (nophae_awaddr),
        .m_axi_nophae_awprot        (nophae_awprot),
        .m_axi_nophae_awvalid       (nophae_awvalid),
        .m_axi_nophae_awready       (nophae_awready),
        .m_axi_nophae_wdata         (nophae_wdata),
        .m_axi_nophae_wstrb         (nophae_wstrb),
        .m_axi_nophae_wvalid        (nophae_wvalid),
        .m_axi_nophae_wready        (nophae_wready),
        .m_axi_nophae_bresp         (nophae_bresp),
        .m_axi_nophae_bvalid        (nophae_bvalid),
        .m_axi_nophae_bready        (nophae_bready),
        .m_axi_nophae_araddr        (nophae_araddr),
        .m_axi_nophae_arprot        (nophae_arprot),
        .m_axi_nophae_arvalid       (nophae_arvalid),
        .m_axi_nophae_arready       (nophae_arready),
        .m_axi_nophae_rdata         (nophae_rdata),
        .m_axi_nophae_rresp         (nophae_rresp),
        .m_axi_nophae_rvalid        (nophae_rvalid),
        .m_axi_nophae_rready        (nophae_rready),
        .fdma_transfer_active       (fdma_transfer_active),
        .capture_controller_busy    (capture_controller_busy),
        .capture_active             (capture_active),
        .capture_ready              (capture_ready),
        .local_capture_done_pulse   (local_capture_done_pulse),
        .capture_cancelled_pulse    (capture_cancelled_pulse),
        .capture_done               (capture_done),
        .last_capture_id            (last_capture_id),
        .backend_busy               (backend_busy),
        .backend_last_status        (backend_last_status),
        .fdma_last_error            (fdma_last_error),
        .fatal_error                (fatal_error),
        .adc_accepted_sample_times  (accepted_sample_times),
        .adc_dropped_sample_times   (dropped_sample_times),
        .submitted_requests         (submitted_requests),
        .completed_requests         (completed_requests)
    );

    axi_ddr_mem_stub #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .MEM_BASE_ADDR  (CAPTURE_BASE),
        .MEM_BYTES      (MEM_BYTES)
    ) u_ddr (
        .clk                     (sys_clk),
        .rst_n                   (sys_rst_n),
        .s_axi_awaddr            (ddr_awaddr),
        .s_axi_awlen             (ddr_awlen),
        .s_axi_awsize            (ddr_awsize),
        .s_axi_awburst           (ddr_awburst),
        .s_axi_awvalid           (ddr_awvalid),
        .s_axi_awready           (ddr_awready),
        .s_axi_wdata             (ddr_wdata),
        .s_axi_wstrb             (ddr_wstrb),
        .s_axi_wlast             (ddr_wlast),
        .s_axi_wvalid            (ddr_wvalid),
        .s_axi_wready            (ddr_wready),
        .s_axi_bresp             (ddr_bresp),
        .s_axi_bvalid            (ddr_bvalid),
        .s_axi_bready            (ddr_bready),
        .stall_enable            (1'b1),
        .inject_bresp_error_next (1'b0)
    );

    wire [31:0] dma_start_count;
    wire [31:0] flush_start_count;
    wire [31:0] last_dma_direction;
    wire [31:0] last_dma_src;
    wire [31:0] last_dma_dst;
    wire [31:0] last_dma_lba_count;
    wire [31:0] last_cmd_code;
    wire [31:0] debug_lock_value;
    wire [31:0] command_count;

    nophae_ctrl_reg_stub #(
        .CTRL_ADDR_WIDTH        (CTRL_ADDR_WIDTH),
        .CTRL_BASE_ADDR         (NOPHAE_BASE),
        .DMA_COMPLETE_LATENCY   (4),
        .FLUSH_COMPLETE_LATENCY (4)
    ) u_nophae (
        .clk                   (sys_clk),
        .rst_n                 (sys_rst_n),
        .s_axi_awaddr          (nophae_awaddr),
        .s_axi_awprot          (nophae_awprot),
        .s_axi_awvalid         (nophae_awvalid),
        .s_axi_awready         (nophae_awready),
        .s_axi_wdata           (nophae_wdata),
        .s_axi_wstrb           (nophae_wstrb),
        .s_axi_wvalid          (nophae_wvalid),
        .s_axi_wready          (nophae_wready),
        .s_axi_bresp           (nophae_bresp),
        .s_axi_bvalid          (nophae_bvalid),
        .s_axi_bready          (nophae_bready),
        .s_axi_araddr          (nophae_araddr),
        .s_axi_arprot          (nophae_arprot),
        .s_axi_arvalid         (nophae_arvalid),
        .s_axi_arready         (nophae_arready),
        .s_axi_rdata           (nophae_rdata),
        .s_axi_rresp           (nophae_rresp),
        .s_axi_rvalid          (nophae_rvalid),
        .s_axi_rready          (nophae_rready),
        .stall_all             (1'b0),
        .force_slverr          (1'b0),
        .dma_ready_value       (1'b1),
        .dma_never_done        (1'b0),
        .flush_never_done      (1'b0),
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

    task automatic fdma_write;
        input [7:0] offset;
        input [31:0] value;
        begin
            @(negedge sys_clk);
            fdma_awaddr  = FDMA_BASE + offset;
            fdma_awvalid = 1'b1;
            fdma_wdata   = value;
            fdma_wstrb   = 4'hF;
            fdma_wvalid  = 1'b1;
            while (!(fdma_awready && fdma_wready))
                @(negedge sys_clk);
            @(negedge sys_clk);
            fdma_awvalid = 1'b0;
            fdma_wvalid  = 1'b0;
            fdma_wstrb   = 4'd0;
            fdma_bready  = 1'b1;
            while (!fdma_bvalid)
                @(negedge sys_clk);
            if (fdma_bresp != 2'b00)
                $fatal(1, "FDMA AXI write error at offset %02x", offset);
            @(negedge sys_clk);
            fdma_bready = 1'b0;
        end
    endtask

    task automatic fdma_read;
        input [7:0] offset;
        output [31:0] value;
        begin
            @(negedge sys_clk);
            fdma_araddr  = FDMA_BASE + offset;
            fdma_arvalid = 1'b1;
            while (!fdma_arready)
                @(negedge sys_clk);
            @(negedge sys_clk);
            fdma_arvalid = 1'b0;
            fdma_rready  = 1'b1;
            while (!fdma_rvalid)
                @(negedge sys_clk);
            if (fdma_rresp != 2'b00)
                $fatal(1, "FDMA AXI read error at offset %02x", offset);
            value = fdma_rdata;
            @(negedge sys_clk);
            fdma_rready = 1'b0;
        end
    endtask

    integer adc_sample_index;
    always @(negedge adc_clk) begin
        if (!adc_rst_n || !capture_active) begin
            adc_valid <= 1'b0;
            if (!capture_active)
                adc_sample_index <= 0;
        end else begin
            adc_valid <= 1'b1;
            adc_ch0 <= adc_sample_index[11:0];
            adc_ch1 <= (adc_sample_index + 12'h100) & 12'hFFF;
            adc_sample_index <= adc_sample_index + 1;
        end
    end

    reg [31:0] previous_dma_count;
    reg [31:0] dma_src_log [0:3];
    reg [31:0] dma_dst_log [0:3];
    reg [31:0] dma_len_log [0:3];
    integer dma_log_index;
    always @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            previous_dma_count <= 32'd0;
            dma_log_index <= 0;
        end else if (dma_start_count != previous_dma_count) begin
            dma_src_log[dma_log_index] <= last_dma_src;
            dma_dst_log[dma_log_index] <= last_dma_dst;
            dma_len_log[dma_log_index] <= last_dma_lba_count;
            dma_log_index <= dma_log_index + 1;
            previous_dma_count <= dma_start_count;
        end
    end

    function automatic [15:0] ext12;
        input [11:0] raw;
        begin
            ext12 = {{4{raw[11]}}, raw};
        end
    endfunction

    task automatic wait_transfer_done;
        integer cycles;
        begin
            cycles = 0;
            while (fdma_transfer_active && cycles < 100000) begin
                @(posedge sys_clk);
                cycles = cycles + 1;
            end
            if (fdma_transfer_active)
                $fatal(1, "Vitis-compatible transfer timed out");
            repeat (4) @(posedge sys_clk);
        end
    endtask

    task automatic check_payload;
        integer sample_index;
        integer byte_index;
        reg [31:0] expected;
        reg [31:0] observed;
        begin
            for (sample_index = 0; sample_index < 16;
                 sample_index = sample_index + 1) begin
                byte_index = sample_index * 4;
                expected = {
                    ext12((sample_index + 12'h100) & 12'hFFF),
                    ext12(sample_index[11:0])
                };
                observed = {
                    u_ddr.mem[byte_index+3],
                    u_ddr.mem[byte_index+2],
                    u_ddr.mem[byte_index+1],
                    u_ddr.mem[byte_index]
                };
                if (observed !== expected)
                    $fatal(1,
                           "ADC payload mismatch sample=%0d got=%08x expected=%08x",
                           sample_index, observed, expected);
            end
            if ({u_ddr.mem[MEM_BYTES-4096+7],
                 u_ddr.mem[MEM_BYTES-4096+6],
                 u_ddr.mem[MEM_BYTES-4096+5],
                 u_ddr.mem[MEM_BYTES-4096+4],
                 u_ddr.mem[MEM_BYTES-4096+3],
                 u_ddr.mem[MEM_BYTES-4096+2],
                 u_ddr.mem[MEM_BYTES-4096+1],
                 u_ddr.mem[MEM_BYTES-4096]} !==
                64'h314D_4D4F_4343_4441)
                $fatal(1, "Commit magic mismatch");
        end
    endtask

    reg [31:0] read_value;
    integer wait_cycles;
    initial begin
        adc_sample_index = 0;
        repeat (12) @(posedge adc_clk);
        adc_rst_n <= 1'b1;
        sys_rst_n <= 1'b1;
        repeat (12) @(posedge sys_clk);
        ddr_init_done <= 1'b1;
        nvme_init_done <= 1'b1;

        // 复现现有Vitis上电配置，再通过菜单7等价AXI写把起始LBA改到安全区。
        fdma_write(8'h04, 32'h0002_0000);
        fdma_write(8'h10, 32'd0);
        fdma_write(8'h14, 32'h4000_0000);
        fdma_write(8'h30, SAFE_SLBA);
        fdma_write(8'h3C, 32'd1);
        fdma_write(8'h40, 32'd1);
        fdma_write(8'h1C, 32'd64);
        fdma_write(8'h20, 32'd0);
        fdma_write(8'h00, 32'd1);

        wait_cycles = 0;
        while (!fdma_transfer_active && wait_cycles < 100) begin
            @(posedge sys_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (!fdma_transfer_active)
            $fatal(1, "FDMA start pulse was not accepted");
        wait_transfer_done();

        fdma_read(8'h24, read_value);
        if (read_value != 1)
            $fatal(1, "WDATA_DONE mismatch: %08x", read_value);
        fdma_read(8'h38, read_value);
        if (read_value != 1)
            $fatal(1, "NVME_DONE mismatch: %08x", read_value);
        fdma_read(8'h60, read_value);
        if (read_value != 0)
            $fatal(1, "Unexpected FDMA error: %08x", read_value);
        fdma_read(8'h4C, read_value);
        if ((read_value & 32'h0000_00FF) != 32'h0000_000E)
            $fatal(1, "Unexpected FDMA terminal status: %08x", read_value);

        if (accepted_sample_times != 16 || dropped_sample_times != 0)
            $fatal(1, "Capture count mismatch accepted=%0d dropped=%0d",
                   accepted_sample_times, dropped_sample_times);
        if (last_capture_id != 1)
            $fatal(1, "Capture ID mismatch: %0d", last_capture_id);
        if (fatal_error || (fdma_last_error != 0) ||
            (backend_last_status != 0))
            $fatal(1, "Unexpected fatal/status error");
        if ((submitted_requests != 4) || (completed_requests != 4))
            $fatal(1, "Scheduler request totals mismatch %0d/%0d",
                   submitted_requests, completed_requests);
        if ((dma_start_count != 2) || (flush_start_count != 2) ||
            (command_count != 2))
            $fatal(1, "NoPHAE command totals mismatch dma=%0d flush=%0d ccnt=%0d",
                   dma_start_count, flush_start_count, command_count);
        if ((last_dma_direction != 1) ||
            (last_cmd_code != 32'h0101_0000) ||
            (debug_lock_value != 0))
            $fatal(1, "NoPHAE final register state mismatch");

        // 监控器在计数变化后一拍记录两笔DMA：Payload和Commit。
        repeat (2) @(posedge sys_clk);
        if ((dma_src_log[0] != 32'h0001_0000) ||
            (dma_dst_log[0] != SAFE_SLBA) ||
            (dma_len_log[0] != 8))
            $fatal(1, "Payload DMA translation mismatch");
        if ((dma_src_log[1] != 32'h0001_2000) ||
            (dma_dst_log[1] != (SAFE_SLBA + 8)) ||
            (dma_len_log[1] != 8))
            $fatal(1, "Commit DMA translation mismatch");
        check_payload();

        // 现有软件默认LBA0必须被保护，不得向NoPHAE提交任何新命令。
        fdma_write(8'h30, 32'd0);
        fdma_write(8'h1C, 32'd64);
        fdma_write(8'h00, 32'd1);
        repeat (4) @(posedge sys_clk);
        fdma_read(8'h60, read_value);
        if (read_value != 32'h0000_D004)
            $fatal(1, "Protected LBA was not rejected: %08x", read_value);
        if ((dma_start_count != 2) || (flush_start_count != 2) ||
            fdma_transfer_active)
            $fatal(1, "Rejected LBA reached NoPHAE backend");

        // 强制Packer暂时不可启动，使任务停在WAIT_READY；随后STOP覆盖
        // “尚未采到任何样本”的取消路径，两个旧done轮询都应退出。
        force dut.capture_ready = 1'b0;
        fdma_write(8'h30, SAFE_SLBA);
        fdma_write(8'h00, 32'd1);
        wait_cycles = 0;
        while (!capture_controller_busy && wait_cycles < 100) begin
            @(posedge sys_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (!capture_controller_busy)
            $fatal(1, "Capture controller did not enter WAIT_READY");
        fdma_write(8'h00, 32'd0);
        wait_transfer_done();
        release dut.capture_ready;
        fdma_read(8'h60, read_value);
        if (read_value != 32'h0000_D006)
            $fatal(1, "Pre-start cancellation status mismatch: %08x",
                   read_value);
        if ((dma_start_count != 2) || (flush_start_count != 2) ||
            fatal_error)
            $fatal(1, "Cancelled task leaked into NoPHAE or fatal path");

        $display("TEST_PASS: Vitis FDMA ABI -> ADC/DDR -> NoPHAE full contract");
        $display("TEST_STATS: samples=%0d dma=%0d flush=%0d requests=%0d",
                 accepted_sample_times, dma_start_count,
                 flush_start_count, submitted_requests);
        $finish;
    end

    initial begin
        #5_000_000;
        $fatal(1,
               "Simulation timeout active=%0b capture=%0b req=%0d cpl=%0d status=%04x",
               fdma_transfer_active, capture_active,
               submitted_requests, completed_requests, fdma_last_error);
    end

endmodule
```
