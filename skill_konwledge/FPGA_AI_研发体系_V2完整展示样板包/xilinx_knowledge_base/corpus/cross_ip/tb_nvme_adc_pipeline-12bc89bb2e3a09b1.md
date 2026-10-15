# tb_nvme_adc_pipeline

- Category: `cross_ip`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\sim\tb_nvme_adc_pipeline.sv`
- SHA-256: `12bc89bb2e3a09b1f4de60e2011b57d5ceaaf6c5edfede29e5c2716dbdfab2ee`
- Extractor: `text`
- Tags: `nvme, pcie, verification`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps

// ADC到DDR分段及抽象NVMe请求的系统级行为回归。
//
// 真实ADC由测试激励代替，真实MIG由axi_ddr_mem_stub代替，真实PCIe/NVMe/SSD
// 由nvme_req_cpl_stub代替。因此PASS证明数据格式、CDC、AXI写、分段状态和
// Write/Flush/Commit顺序闭环正确，不证明DDR校准、PCIe Link或SSD写入成功。
module tb_nvme_adc_pipeline;

    // 为加快行为仿真，每个Segment缩小为4 KiB；4段Payload后紧接4 KiB Commit页。
    localparam integer AXI_ADDR_WIDTH = 64;
    localparam integer AXI_DATA_WIDTH = 256;
    localparam integer SEGMENT_BYTES  = 4096;
    localparam integer SEGMENT_COUNT  = 4;
    localparam integer COMMIT_ADDR    = SEGMENT_BYTES * SEGMENT_COUNT;
    localparam integer MEM_BYTES      = COMMIT_ADDR + 4096;

    // ADC固定250 MHz；sys_clk为125 MHz且相位偏移1 ns，刻意形成异步CDC关系。
    reg adc_clk = 1'b0;
    reg sys_clk = 1'b0;
    always #2 adc_clk = ~adc_clk;       // 250 MHz
    initial begin
        #1;
        forever #4 sys_clk = ~sys_clk;  // 125 MHz, phase shifted
    end

    reg adc_rst_n = 1'b0;
    reg sys_rst_n = 1'b0;
    reg capture_start = 1'b0;
    reg capture_stop = 1'b0;
    reg cfg_two_channel = 1'b1;
    reg cfg_single_channel_select = 1'b0;
    reg [63:0] cfg_capture_id = 64'd0;
    reg adc_valid = 1'b0;
    reg [11:0] adc_ch0 = 12'd0;
    reg [11:0] adc_ch1 = 12'd0;
    reg ddr_init_done = 1'b0;
    reg nvme_init_done = 1'b0;
    reg pcie_link_up = 1'b1;
    reg ecqe_error_valid = 1'b0;
    reg [15:0] ecqe_error_status = 16'd0;
    reg session_start = 1'b0;
    reg [63:0] session_base_slba = 64'd2048;

    wire [AXI_ADDR_WIDTH-1:0] ddr_awaddr;
    wire [7:0] ddr_awlen;
    wire [2:0] ddr_awsize;
    wire [1:0] ddr_awburst;
    wire ddr_awvalid;
    wire ddr_awready;
    wire [AXI_DATA_WIDTH-1:0] ddr_wdata;
    wire [AXI_DATA_WIDTH/8-1:0] ddr_wstrb;
    wire ddr_wlast;
    wire ddr_wvalid;
    wire ddr_wready;
    wire [1:0] ddr_bresp;
    wire ddr_bvalid;
    wire ddr_bready;

    wire nvme_req_valid;
    wire nvme_req_ready;
    wire [1:0] nvme_req_opcode;
    wire [AXI_ADDR_WIDTH-1:0] nvme_req_ddr_addr;
    wire [31:0] nvme_req_byte_len;
    wire [63:0] nvme_req_slba;
    wire [15:0] nvme_req_user_tag;
    wire nvme_cpl_valid;
    wire nvme_cpl_ready;
    wire [15:0] nvme_cpl_user_tag;
    wire [15:0] nvme_cpl_status;

    wire capture_active;
    wire capture_ready;
    wire capture_done;
    wire [63:0] last_capture_id;
    wire adc_overflow_sticky;
    wire config_change_sticky;
    wire stream_format_error_sticky;
    wire [63:0] accepted_sample_times;
    wire [63:0] dropped_sample_times;
    wire ddr_axi_error_sticky;
    wire timeout_sticky;
    wire link_down_sticky;
    wire fatal_error;
    wire [31:0] submitted_requests;
    wire [31:0] completed_requests;
    wire [SEGMENT_COUNT*3-1:0] segment_states;
    wire [$clog2(SEGMENT_COUNT+1)-1:0] segment_free_count;
    wire [10:0] adc_fifo_max_used_count;

    // DUT参数含义：
    // 地址/数据宽度匹配行为DDR；4 KiB x 4用于快速轮转；
    // 16拍Burst=512 Byte；ADC FIFO地址位宽10=1024项；
    // 超时5000个sys_clk周期；Commit位于Payload区末尾；Raw LBA从2048开始。
    nvme_adc_pipeline_top #(
        // 64 bit DDR描述符地址。
        .AXI_ADDR_WIDTH          (AXI_ADDR_WIDTH),
        // 256 bit AXI数据拍。
        .AXI_DATA_WIDTH          (AXI_DATA_WIDTH),
        // 仿真分段4 KiB。
        .SEGMENT_BYTES           (SEGMENT_BYTES),
        // 4个可轮转分段。
        .SEGMENT_COUNT           (SEGMENT_COUNT),
        // 每Burst 16拍。
        .BURST_BEATS             (16),
        // 异步FIFO 2^10=1024项。
        .ADC_FIFO_AW             (10),
        // 仿真用5000周期请求watchdog。
        .COMMAND_TIMEOUT_CYCLES  (5000),
        // 行为内存从地址0开始。
        .DDR_BASE_ADDR           (64'd0),
        // Commit页位于四个Segment之后。
        .COMMIT_DDR_ADDR         (COMMIT_ADDR),
        // Raw LBA起点。
        .BASE_SLBA               (64'd2048)
    ) dut (
        .adc_clk                     (adc_clk),
        .adc_rst_n                   (adc_rst_n),
        .capture_start               (capture_start),
        .capture_stop                (capture_stop),
        .cfg_two_channel             (cfg_two_channel),
        .cfg_single_channel_select   (cfg_single_channel_select),
        .cfg_capture_id              (cfg_capture_id),
        .adc_valid                   (adc_valid),
        .adc_ch0                     (adc_ch0),
        .adc_ch1                     (adc_ch1),
        .sys_clk                     (sys_clk),
        .sys_rst_n                   (sys_rst_n),
        .ddr_init_done               (ddr_init_done),
        .nvme_init_done              (nvme_init_done),
        .pcie_link_up                (pcie_link_up),
        .ecqe_error_valid            (ecqe_error_valid),
        .ecqe_error_status           (ecqe_error_status),
        .session_start               (session_start),
        .session_base_slba           (session_base_slba),
        .m_axi_ddr_awaddr            (ddr_awaddr),
        .m_axi_ddr_awlen             (ddr_awlen),
        .m_axi_ddr_awsize            (ddr_awsize),
        .m_axi_ddr_awburst           (ddr_awburst),
        .m_axi_ddr_awvalid           (ddr_awvalid),
        .m_axi_ddr_awready           (ddr_awready),
        .m_axi_ddr_wdata             (ddr_wdata),
        .m_axi_ddr_wstrb             (ddr_wstrb),
        .m_axi_ddr_wlast             (ddr_wlast),
        .m_axi_ddr_wvalid            (ddr_wvalid),
        .m_axi_ddr_wready            (ddr_wready),
        .m_axi_ddr_bresp             (ddr_bresp),
        .m_axi_ddr_bvalid            (ddr_bvalid),
        .m_axi_ddr_bready            (ddr_bready),
        .nvme_req_valid              (nvme_req_valid),
        .nvme_req_ready              (nvme_req_ready),
        .nvme_req_opcode             (nvme_req_opcode),
        .nvme_req_ddr_addr           (nvme_req_ddr_addr),
        .nvme_req_byte_len           (nvme_req_byte_len),
        .nvme_req_slba               (nvme_req_slba),
        .nvme_req_user_tag           (nvme_req_user_tag),
        .nvme_cpl_valid              (nvme_cpl_valid),
        .nvme_cpl_ready              (nvme_cpl_ready),
        .nvme_cpl_user_tag           (nvme_cpl_user_tag),
        .nvme_cpl_status             (nvme_cpl_status),
        .capture_active              (capture_active),
        .capture_ready               (capture_ready),
        .capture_done                (capture_done),
        .last_capture_id             (last_capture_id),
        .adc_overflow_sticky         (adc_overflow_sticky),
        .config_change_sticky        (config_change_sticky),
        .stream_format_error_sticky  (stream_format_error_sticky),
        .adc_accepted_sample_times   (accepted_sample_times),
        .adc_dropped_sample_times    (dropped_sample_times),
        .ddr_axi_error_sticky        (ddr_axi_error_sticky),
        .timeout_sticky              (timeout_sticky),
        .link_down_sticky            (link_down_sticky),
        .fatal_error                 (fatal_error),
        .submitted_requests          (submitted_requests),
        .completed_requests          (completed_requests),
        .segment_states              (segment_states),
        .segment_free_count          (segment_free_count),
        .adc_fifo_max_used_count     (adc_fifo_max_used_count)
    );

    reg ddr_stall_enable = 1'b1;
    reg ddr_inject_error = 1'b0;

    // DDR桩参数与DUT AXI口一致，MEM_BYTES覆盖四个Payload段和一个Commit页。
    // stall_enable打开随机AW/W反压和B响应延迟，验证Writer握手稳定性。
    axi_ddr_mem_stub #(
        // 64 bit地址。
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        // 256 bit数据。
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        // 行为字节数组覆盖本用例全部地址。
        .MEM_BYTES      (MEM_BYTES)
    ) u_ddr (
        .clk                         (sys_clk),
        .rst_n                       (sys_rst_n),
        .s_axi_awaddr                (ddr_awaddr),
        .s_axi_awlen                 (ddr_awlen),
        .s_axi_awsize                (ddr_awsize),
        .s_axi_awburst               (ddr_awburst),
        .s_axi_awvalid               (ddr_awvalid),
        .s_axi_awready               (ddr_awready),
        .s_axi_wdata                 (ddr_wdata),
        .s_axi_wstrb                 (ddr_wstrb),
        .s_axi_wlast                 (ddr_wlast),
        .s_axi_wvalid                (ddr_wvalid),
        .s_axi_wready                (ddr_wready),
        .s_axi_bresp                 (ddr_bresp),
        .s_axi_bvalid                (ddr_bvalid),
        .s_axi_bready                (ddr_bready),
        .stall_enable                (ddr_stall_enable),
        .inject_bresp_error_next     (ddr_inject_error)
    );

    reg inject_fail_next = 1'b0;
    reg inject_timeout_next = 1'b0;
    reg inject_bad_tag_next = 1'b0;
    wire [31:0] stub_request_count;
    wire [31:0] stub_write_count;
    wire [31:0] stub_read_count;
    wire [31:0] stub_flush_count;
    wire [1:0] stub_last_opcode;
    wire [63:0] stub_last_ddr_addr;
    wire [31:0] stub_last_byte_len;
    wire [63:0] stub_last_slba;
    wire [15:0] stub_last_user_tag;

    // NVMe桩只验证抽象请求序列，24周期后回送同Tag成功Completion；
    // 它不会从u_ddr.mem读取Payload，DDR正确性由下方check_payload独立检查。
    nvme_req_cpl_stub #(
        // 请求DDR地址宽度。
        .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH),
        // 正常Completion固定延迟24个sys_clk周期。
        .COMPLETE_LATENCY (24)
    ) u_nvme (
        .clk                 (sys_clk),
        .rst_n               (sys_rst_n),
        .req_valid           (nvme_req_valid),
        .req_ready           (nvme_req_ready),
        .req_opcode          (nvme_req_opcode),
        .req_ddr_addr        (nvme_req_ddr_addr),
        .req_byte_len        (nvme_req_byte_len),
        .req_slba            (nvme_req_slba),
        .req_user_tag        (nvme_req_user_tag),
        .cpl_valid           (nvme_cpl_valid),
        .cpl_ready           (nvme_cpl_ready),
        .cpl_user_tag        (nvme_cpl_user_tag),
        .cpl_status          (nvme_cpl_status),
        .inject_fail_next    (inject_fail_next),
        .inject_timeout_next (inject_timeout_next),
        .inject_bad_tag_next (inject_bad_tag_next),
        .request_count       (stub_request_count),
        .write_count         (stub_write_count),
        .read_count          (stub_read_count),
        .flush_count         (stub_flush_count),
        .last_opcode         (stub_last_opcode),
        .last_ddr_addr       (stub_last_ddr_addr),
        .last_byte_len       (stub_last_byte_len),
        .last_slba           (stub_last_slba),
        .last_user_tag       (stub_last_user_tag)
    );

    reg aw_held = 1'b0;
    reg [76:0] aw_payload_held;
    reg w_held = 1'b0;
    reg [288:0] w_payload_held;
    reg req_held = 1'b0;
    reg [177:0] req_payload_held;
    reg [SEGMENT_COUNT*3-1:0] previous_segment_states;
    integer state_index;
    reg [2:0] previous_state;
    reg [2:0] current_state;

    // 在线断言分四组：
    // 1. AW、W和NVMe请求在valid&&!ready时全部字段稳定；
    // 2. 每条已接受的AXI AW Burst不得跨越4 KiB地址边界；
    // 3. READ/WRITE DMA非零且地址、长度均4 KiB对齐；
    // 4. 每个Segment只按允许的所有权状态边迁移，ERROR_HOLD不可自行释放。
    always @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            aw_held <= 1'b0;
            w_held <= 1'b0;
            req_held <= 1'b0;
            previous_segment_states <= {SEGMENT_COUNT*3{1'b0}};
        end else begin
            if (ddr_awvalid && !ddr_awready) begin
                if (aw_held &&
                    aw_payload_held !== {ddr_awaddr, ddr_awlen,
                                         ddr_awsize, ddr_awburst})
                    $fatal(1, "ASSERT: AXI AW changed while stalled");
                aw_payload_held <= {ddr_awaddr, ddr_awlen,
                                    ddr_awsize, ddr_awburst};
                aw_held <= 1'b1;
            end else begin
                aw_held <= 1'b0;
            end

            if (ddr_wvalid && !ddr_wready) begin
                if (w_held &&
                    w_payload_held !== {ddr_wdata, ddr_wstrb, ddr_wlast})
                    $fatal(1, "ASSERT: AXI W changed while stalled");
                w_payload_held <= {ddr_wdata, ddr_wstrb, ddr_wlast};
                w_held <= 1'b1;
            end else begin
                w_held <= 1'b0;
            end

            // AXI4禁止一个Burst跨越4 KiB边界。断言只在AWVALID/AWREADY
            // 握手时检查已经被DDR从接口受理的事务：
            //   ddr_awaddr[11:0]              = 本4 KiB页内起始字节偏移；
            //   ddr_awlen + 1                 = 实际Beat数，AWLEN为0-based；
            //   1 << ddr_awsize               = 每Beat字节数；
            //   (AWLEN+1) << AWSIZE           = 整个Burst字节数。
            // 当前256 bit、16拍配置为512 Byte/Burst；4 KiB对齐Segment
            // 以512 Byte递增，最后一个0xE00起点的Burst正好结束于0x1000，
            // 等于边界合法，只有大于4096才表示跨页。该断言不限制上层NVMe
            // 大DMA跨多个页面；上层任务应由IP拆成合法的内部AXI Burst。
            if (ddr_awvalid && ddr_awready &&
                ({1'b0, ddr_awaddr[11:0]} +
                 ((ddr_awlen + 1) << ddr_awsize) > 13'd4096))
                $fatal(1,
                       "ASSERT: AXI AW burst crosses 4 KiB boundary: addr=%h len=%0d size=%0d",
                       ddr_awaddr, ddr_awlen, ddr_awsize);

            if (nvme_req_valid && !nvme_req_ready) begin
                if (req_held &&
                    req_payload_held !== {nvme_req_opcode,
                                          nvme_req_ddr_addr,
                                          nvme_req_byte_len,
                                          nvme_req_slba,
                                          nvme_req_user_tag})
                    $fatal(1, "ASSERT: NVMe request changed while stalled");
                req_payload_held <= {nvme_req_opcode, nvme_req_ddr_addr,
                                     nvme_req_byte_len, nvme_req_slba,
                                     nvme_req_user_tag};
                req_held <= 1'b1;
            end else begin
                req_held <= 1'b0;
            end

            if (nvme_req_valid && nvme_req_ready &&
                ((nvme_req_opcode == 2'd0) ||
                 (nvme_req_opcode == 2'd1)) &&
                (((nvme_req_ddr_addr % 4096) != 0) ||
                 ((nvme_req_byte_len % 4096) != 0) ||
                 (nvme_req_byte_len == 0)))
                $fatal(1, "ASSERT: invalid NVMe DMA alignment/length");

            for (state_index = 0; state_index < SEGMENT_COUNT;
                 state_index = state_index + 1) begin
                previous_state =
                    previous_segment_states[state_index*3 +: 3];
                current_state = segment_states[state_index*3 +: 3];
                case (previous_state)
                    3'd0: if (!((current_state == 3'd0) ||
                                (current_state == 3'd1)))
                              $fatal(1, "ASSERT: illegal FREE transition");
                    3'd1: if (!((current_state == 3'd1) ||
                                (current_state == 3'd2) ||
                                (current_state == 3'd4)))
                              $fatal(1, "ASSERT: illegal FILLING transition");
                    3'd2: if (!((current_state == 3'd2) ||
                                (current_state == 3'd3)))
                              $fatal(1, "ASSERT: illegal READY transition");
                    3'd3: if (!((current_state == 3'd3) ||
                                (current_state == 3'd0) ||
                                (current_state == 3'd4)))
                              $fatal(1, "ASSERT: illegal INFLIGHT transition");
                    3'd4: if (current_state != 3'd4)
                              $fatal(1, "ASSERT: ERROR_HOLD was released");
                    default: $fatal(1, "ASSERT: unknown Segment state");
                endcase
            end
            previous_segment_states <= segment_states;
        end
    end

    // 测试平台参考模型与DUT默认符号扩展配置一致。
    function automatic [15:0] ext12;
        input [11:0] raw;
        begin
            ext12 = {{4{raw[11]}}, raw};
        end
    endfunction

    // 连续产生sample_count个采样时刻：
    // CH0=i，CH1=i+0x155；在capture_ready后启动，最后用capture_stop收尾。
    task automatic drive_capture;
        input bit two_channel;
        input bit select_ch1;
        input integer sample_count;
        input [63:0] capture_id;
        integer i;
        begin
            while (!capture_ready)
                @(negedge adc_clk);
            @(negedge adc_clk);
            cfg_two_channel           = two_channel;
            cfg_single_channel_select = select_ch1;
            cfg_capture_id            = capture_id;
            capture_start             = 1'b1;
            @(negedge adc_clk);
            capture_start = 1'b0;

            for (i = 0; i < sample_count; i = i + 1) begin
                adc_valid = 1'b1;
                adc_ch0   = i[11:0];
                adc_ch1   = (i + 12'h155) & 12'hFFF;
                @(negedge adc_clk);
            end
            adc_valid    = 1'b0;
            capture_stop = 1'b1;
            @(negedge adc_clk);
            capture_stop = 1'b0;
        end
    endtask

    // capture_done只应在Payload Write、Flush、Commit Write、Flush全部完成后产生。
    task automatic wait_capture_done;
        input [63:0] expected_id;
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (!capture_done && wait_cycles < 200000) begin
                @(posedge sys_clk);
                wait_cycles = wait_cycles + 1;
            end
            if (!capture_done)
                $fatal(1, "Capture %0d timed out", expected_id);
            if (last_capture_id != expected_id)
                $fatal(1, "Capture ID mismatch: got %0d expected %0d",
                       last_capture_id, expected_id);
            @(posedge sys_clk);
        end
    endtask

    // 分层读取DDR桩的字节数组。双通道验证{CH1,CH0}的32 bit小端布局；
    // 单通道验证只保存所选通道的紧凑16 bit数据。
    task automatic check_payload;
        input bit two_channel;
        input bit select_ch1;
        input integer sample_count;
        integer i;
        integer byte_addr;
        reg [15:0] expected16;
        reg [31:0] expected32;
        reg [31:0] observed32;
        begin
            for (i = 0; i < sample_count; i = i + 1) begin
                if (two_channel) begin
                    byte_addr = i * 4;
                    expected32 = {
                        ext12((i + 12'h155) & 12'hFFF),
                        ext12(i[11:0])
                    };
                    observed32 = {
                        u_ddr.mem[byte_addr+3],
                        u_ddr.mem[byte_addr+2],
                        u_ddr.mem[byte_addr+1],
                        u_ddr.mem[byte_addr]
                    };
                    if (observed32 !== expected32)
                        $fatal(1, "Dual-channel mismatch at %0d: %08x != %08x",
                               i, observed32, expected32);
                end else begin
                    byte_addr = i * 2;
                    expected16 = select_ch1 ?
                        ext12((i + 12'h155) & 12'hFFF) : ext12(i[11:0]);
                    if ({u_ddr.mem[byte_addr+1], u_ddr.mem[byte_addr]} !==
                        expected16)
                        $fatal(1, "Single-channel mismatch at %0d", i);
                end
            end
        end
    endtask

    // 每次Capture后的公共不变量：样本无丢失、无错误、累计请求数正确、
    // 所有Segment回到FREE，且Commit页Magic已写入预定DDR地址。
    task automatic check_common;
        input integer expected_samples;
        input integer expected_request_total;
        begin
            if (accepted_sample_times != expected_samples)
                $fatal(1, "Accepted sample count %0d != %0d",
                       accepted_sample_times, expected_samples);
            if (dropped_sample_times != 0 || adc_overflow_sticky)
                $fatal(1, "ADC overflow: dropped=%0d", dropped_sample_times);
            if (config_change_sticky)
                $fatal(1, "Configuration changed during capture");
            if (fatal_error || ddr_axi_error_sticky ||
                timeout_sticky || link_down_sticky)
                $fatal(1, "Unexpected error flags");
            if (stub_request_count != expected_request_total)
                $fatal(1, "Request count %0d != %0d",
                       stub_request_count, expected_request_total);
            if (segment_free_count != SEGMENT_COUNT)
                $fatal(1, "Not all segments are FREE");
            if ({u_ddr.mem[COMMIT_ADDR+7], u_ddr.mem[COMMIT_ADDR+6],
                 u_ddr.mem[COMMIT_ADDR+5], u_ddr.mem[COMMIT_ADDR+4],
                 u_ddr.mem[COMMIT_ADDR+3], u_ddr.mem[COMMIT_ADDR+2],
                 u_ddr.mem[COMMIT_ADDR+1], u_ddr.mem[COMMIT_ADDR]} !==
                64'h314D_4D4F_4343_4441)
                $fatal(1, "Commit magic mismatch");
        end
    endtask

    initial begin
        // 先释放两时钟域复位，再分别模拟DDR校准完成和NVMe初始化完成。
        repeat (12) @(posedge adc_clk);
        adc_rst_n <= 1'b1;
        sys_rst_n <= 1'b1;
        repeat (12) @(posedge sys_clk);
        ddr_init_done  <= 1'b1;
        nvme_init_done <= 1'b1;

        // 1024个双通道采样恰好填满4 KiB Segment。
        // 本Capture产生：Payload WRITE、Flush1、Commit WRITE、Flush2，共4请求。
        drive_capture(1'b1, 1'b0, 1024, 64'd1);
        wait_capture_done(64'd1);
        check_payload(1'b1, 1'b0, 1024);
        check_common(1024, 4);

        // 17个CH0样本验证单通道跨越16 sample/word边界及4 KiB尾段补零。
        drive_capture(1'b0, 1'b0, 17, 64'd2);
        wait_capture_done(64'd2);
        check_payload(1'b0, 1'b0, 17);
        check_common(17, 8);

        // 9个CH1样本验证单通道选择和非整256 bit尾字。
        drive_capture(1'b0, 1'b1, 9, 64'd3);
        wait_capture_done(64'd3);
        check_payload(1'b0, 1'b1, 9);
        check_common(9, 12);

        // 三个Capture各包含两次WRITE和两次FLUSH，累计6/6。
        if (stub_write_count != 6 || stub_flush_count != 6)
            $fatal(1, "Opcode totals mismatch: write=%0d flush=%0d",
                   stub_write_count, stub_flush_count);

        $display("TEST_PASS: dual/CH0/CH1 modes, 250MHz ADC -> 125MHz system");
        $display("TEST_STATS: requests=%0d fifo_max=%0d",
                 stub_request_count, adc_fifo_max_used_count);
        $finish;
    end

    // 全局死锁保护；失败信息保留请求和完成计数便于定位所处阶段。
    initial begin
        #5_000_000;
        $fatal(1, "Simulation timeout: req=%0d done=%0d fatal=%0b",
               stub_request_count, completed_requests, fatal_error);
    end

endmodule
```
