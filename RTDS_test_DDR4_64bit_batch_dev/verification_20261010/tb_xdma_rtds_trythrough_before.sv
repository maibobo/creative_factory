// 新版快速集成前仿：复用原adapter/BFM/Host任务，验证16Byte与批次ACK。
// RX窗口仅本验证实例加速为2500拍；生产默认100ms。三轮八块读取后逐块ACK。
`timescale 1ns / 1ps

module tb_xdma_rtds_trythrough;
    import rtds_test_pkg::*;

`ifdef RTDS_TEST_NONZERO_CARD_HI
    localparam [31:0] CARD_ADDR_HI = 32'h0000_0001;
`else
    localparam [31:0] CARD_ADDR_HI = 32'h0000_0000;
`endif
    localparam [31:0] RX_BASE = 32'h0010_0000;
    localparam [31:0] TX_BASE = 32'h0000_8000;
    localparam integer WINDOW_BYTES = 32 * 1024;

    reg fdma_clk = 0;
    reg user_clk = 0;

    always #2.0 fdma_clk = ~fdma_clk;

    always #3.2 user_clk = ~user_clk;

    reg fdma_rstn;
    reg user_rstn;
    reg pcie_link_up;
    reg aurora_channel_up;
    reg aurora_lane_up;

    wire [63:0] aurora_tx_d;
    wire aurora_tx_sof;
    wire aurora_tx_eof;
    wire [2:0] aurora_tx_rem;
    wire aurora_tx_src_rdy;
    wire aurora_tx_dst_rdy;
    wire [63:0] aurora_rx_d;
    wire aurora_rx_sof;
    wire aurora_rx_eof;
    wire [2:0] aurora_rx_rem;
    wire aurora_rx_src_rdy;
    wire aurora_rx_dst_rdy;

    reg rd_start;
    reg [31:0] cpu_fpga_start_addr;
    reg [31:0] cpu_fpga_len;
    wire cpu_wr_done_resp;
    wire [31:0] fpga_cpu_start_addr;
    wire [31:0] fpga_cpu_len;
    wire int_state_w;
    reg int_state_clear;
    reg clear_inter;
    reg cpu_rec_state_r;
    wire cpu_rec_state_w;
    wire fpga_cpu_irq_req;

    wire [63:0] fdma_raddr;
    wire fdma_rareq;
    wire fdma_rbusy;
    wire [63:0] fdma_rdata;
    wire fdma_rvalid;
    wire fdma_rready;
    wire [15:0] fdma_rsize;
    wire [63:0] fdma_waddr;
    wire fdma_wareq;
    wire fdma_wbusy;
    wire [7:0] fdma_wstrb; // 低32bit尾拍写使能
    wire cpu_wr_done_event; // 门铃自动清零事件
    wire fdma_wdone, fdma_werror;
    wire [31:0] rx_ready_blocks, rx_head_seq, rx_dropped_frames;
    wire [7:0] cfg_byte_nc;
    wire cfg_byte_valid_nc;
    integer config_sample_count=0;
    integer config_word_index=0;

    always @(posedge fdma_clk) begin : monitor_config_byte
        if (!fdma_rstn) begin
            config_sample_count=0;
            config_word_index=0;
        end else if(fdma_rvalid && fdma_rready) begin
            if(cfg_byte_valid_nc !== (config_word_index==0))
                $fatal(1,"FAST/CFG_BOUNDARY");
            if(cfg_byte_valid_nc) begin
                if(cfg_byte_nc !== 8'h5A)
                    $fatal(1,"FAST/CFG_BYTE1");
                config_sample_count=config_sample_count+1;
            end
            config_word_index=(config_word_index+1)%2;
        end
    end
    wire [63:0] fdma_wdata;
    wire fdma_wvalid;
    wire fdma_wready;
    wire [15:0] fdma_wsize;

    wire rx_fifo_almost_full;
    wire rx_fifo_full;
    wire rx_overflow_sticky;
    wire rx_overrun_sticky;
    wire tx_underflow_sticky;
    wire fdma_timeout_sticky;
    wire length_error_sticky;
    wire link_down_sticky;
    wire rx_pending;
    wire [3:0] dbg_tx_state;
    wire [3:0] dbg_rx_state;

    wire [31:0] backend_error_count;
    wire [31:0] scoreboard_error_count;
    wire [31:0] tx_total_frames;
    wire tx_expectation_active;
    wire [31:0] tx_stall_cycles;
    wire [31:0] assertion_error_count;
    integer test_error_count;
    integer compare_mismatches;
    integer frame_index;
    reg [31:0] bar_value;

    pcie_fdma_aurora_brg_adapter #(
        .FRAME_BYTES(16),
        .RX_PERIOD_CYCLES(2500),
        .ACTIVE_WINDOW_BYTES(WINDOW_BYTES),
        .RX_BASE_ADDR_LO(RX_BASE),
        .TX_BASE_ADDR_LO(TX_BASE),
        .CARD_ADDR_HI(CARD_ADDR_HI),
        .FDMA_TIMEOUT_CYCLES(500)
    ) dut (
        .fdma_clk(fdma_clk), .fdma_rstn(fdma_rstn),
        .aurora_user_clk(user_clk), .aurora_user_rstn(user_rstn),
        .pcie_link_up(pcie_link_up),
        .aurora_channel_up(aurora_channel_up),
        .aurora_lane_up(aurora_lane_up),
        .aurora_tx_d(aurora_tx_d), .aurora_tx_sof(aurora_tx_sof),
        .aurora_tx_eof(aurora_tx_eof), .aurora_tx_rem(aurora_tx_rem),
        .aurora_tx_src_rdy(aurora_tx_src_rdy),
        .aurora_tx_dst_rdy(aurora_tx_dst_rdy),
        .aurora_rx_d(aurora_rx_d), .aurora_rx_sof(aurora_rx_sof),
        .aurora_rx_eof(aurora_rx_eof), .aurora_rx_rem(aurora_rx_rem),
        .aurora_rx_src_rdy(aurora_rx_src_rdy),
        .aurora_rx_dst_rdy(aurora_rx_dst_rdy),
        .rd_start(rd_start),
        .cpu_fpga_start_addr(cpu_fpga_start_addr),
        .cpu_fpga_len(cpu_fpga_len),
        .cpu_wr_done_resp(cpu_wr_done_resp), .cpu_wr_done_event(cpu_wr_done_event),
        .fpga_cpu_start_addr(fpga_cpu_start_addr),
        .fpga_cpu_len(fpga_cpu_len),
        .int_state_w(int_state_w), .int_state_clear(int_state_clear),
        .clear_inter(clear_inter), .cpu_rec_state_r(cpu_rec_state_r),
        .cpu_rec_state_w(cpu_rec_state_w),
        .fpga_cpu_irq_req(fpga_cpu_irq_req),
        .fdma_raddr(fdma_raddr), .fdma_rareq(fdma_rareq),
        .fdma_rbusy(fdma_rbusy), .fdma_rdata(fdma_rdata),
        .fdma_rvalid(fdma_rvalid), .fdma_rready(fdma_rready),
        .fdma_rsize(fdma_rsize),
        .fdma_waddr(fdma_waddr), .fdma_wareq(fdma_wareq),
        .rx_ready_blocks(rx_ready_blocks), .rx_head_seq(rx_head_seq),
        .rx_dropped_frames(rx_dropped_frames), .cfg_byte(cfg_byte_nc), .cfg_byte_valid(cfg_byte_valid_nc),
        .fdma_wbusy(fdma_wbusy), .fdma_wdata(fdma_wdata),
        .fdma_wdone(fdma_wdone), .fdma_werror(fdma_werror), .fdma_wstrb(fdma_wstrb),
        .fdma_wvalid(fdma_wvalid), .fdma_wready(fdma_wready),
        .fdma_wsize(fdma_wsize),
        .rx_fifo_almost_full(rx_fifo_almost_full),
        .rx_fifo_full(rx_fifo_full),
        .rx_overflow_sticky(rx_overflow_sticky),
        .rx_overrun_sticky(rx_overrun_sticky),
        .tx_underflow_sticky(tx_underflow_sticky),
        .fdma_timeout_sticky(fdma_timeout_sticky),
        .length_error_sticky(length_error_sticky),
        .link_down_sticky(link_down_sticky), .rx_pending(rx_pending),
        .dbg_tx_state(dbg_tx_state), .dbg_rx_state(dbg_rx_state)
    );

    xdma_rp_backend #(
        .MEM_BYTES(4 * 1024 * 1024), .CARD_ADDR_HI(CARD_ADDR_HI)
    ) u_backend (
        .clk(fdma_clk), .rstn(fdma_rstn),
        .fdma_raddr(fdma_raddr), .fdma_rareq(fdma_rareq),
        .fdma_rsize(fdma_rsize), .fdma_rbusy(fdma_rbusy),
        .fdma_rdata(fdma_rdata), .fdma_rvalid(fdma_rvalid),
        .fdma_rready(fdma_rready),
        .fdma_waddr(fdma_waddr), .fdma_wareq(fdma_wareq),
        .fdma_wsize(fdma_wsize), .fdma_wbusy(fdma_wbusy),
        .fdma_wdone(fdma_wdone), .fdma_werror(fdma_werror), .fdma_wstrb(fdma_wstrb),
        .fdma_wdata(fdma_wdata), .fdma_wvalid(fdma_wvalid),
        .fdma_wready(fdma_wready),
        .backend_error_count(backend_error_count)
    );

    aurora_ll_peer_bfm u_aurora_peer (
        .user_clk(user_clk), .user_rstn(user_rstn),
        .link_up(pcie_link_up && aurora_channel_up && aurora_lane_up),
        .tx_d(aurora_tx_d), .tx_sof(aurora_tx_sof),
        .tx_eof(aurora_tx_eof), .tx_rem(aurora_tx_rem),
        .tx_src_rdy(aurora_tx_src_rdy), .tx_dst_rdy(aurora_tx_dst_rdy),
        .rx_d(aurora_rx_d), .rx_sof(aurora_rx_sof),
        .rx_eof(aurora_rx_eof), .rx_rem(aurora_rx_rem),
        .rx_src_rdy(aurora_rx_src_rdy), .rx_dst_rdy(aurora_rx_dst_rdy),
        .tx_stall_cycles(tx_stall_cycles)
    );

    rtds_scoreboard u_scoreboard (
        .user_clk(user_clk), .user_rstn(user_rstn),
        .tx_d(aurora_tx_d), .tx_sof(aurora_tx_sof),
        .tx_eof(aurora_tx_eof), .tx_rem(aurora_tx_rem),
        .tx_src_rdy(aurora_tx_src_rdy), .tx_dst_rdy(aurora_tx_dst_rdy),
        .error_count(scoreboard_error_count),
        .tx_total_frames(tx_total_frames),
        .tx_expectation_active(tx_expectation_active)
    );

    rtds_assertions #(
        .CARD_ADDR_HI(CARD_ADDR_HI), .RX_BASE_ADDR_LO(RX_BASE),
        .TX_BASE_ADDR_LO(TX_BASE), .WINDOW_BYTES(WINDOW_BYTES)
    ) u_assertions (
        .fdma_clk(fdma_clk), .fdma_rstn(fdma_rstn),
        .fdma_raddr(fdma_raddr), .fdma_rareq(fdma_rareq),
        .fdma_rbusy(fdma_rbusy), .fdma_rsize(fdma_rsize),
        .fdma_waddr(fdma_waddr), .fdma_wareq(fdma_wareq),
        .fdma_wbusy(fdma_wbusy), .fdma_wsize(fdma_wsize),
        .user_clk(user_clk), .user_rstn(user_rstn),
        .tx_d(aurora_tx_d), .tx_sof(aurora_tx_sof),
        .tx_eof(aurora_tx_eof), .tx_rem(aurora_tx_rem),
        .tx_src_rdy(aurora_tx_src_rdy), .tx_dst_rdy(aurora_tx_dst_rdy),
        .assertion_error_count(assertion_error_count)
    );

`include "rp_api.svh"

    task automatic start_tx_command(
        input [31:0] card_address,
        input integer length_bytes,
        input integer first_frame
    );
        begin
            u_scoreboard.arm_tx(first_frame, length_bytes / 16);
            bar_write32(32'h0024, card_address);
            bar_write32(32'h0028, length_bytes);
            bar_write32(32'h0020, 32'd1);
            wait_cpu_tx_complete(200000);
            u_scoreboard.wait_tx_complete(200000);
            bar_write32(32'h0020, 32'd0);
        end
    endtask

    task automatic check_rx_notification(input [31:0] expected_address);
        begin
            wait_user_irq(100000);
            if (!rx_pending || fpga_cpu_start_addr !== expected_address ||
                fpga_cpu_len !== 32'd16) begin
                test_error_count = test_error_count + 1;
                $error("RX notification expected addr=%h got addr=%h len=%0d pending=%b",
                       expected_address, fpga_cpu_start_addr, fpga_cpu_len, rx_pending);
            end
        end
    endtask

    initial begin
        fdma_rstn = 0;
        user_rstn = 0;
        pcie_link_up = 0;
        aurora_channel_up = 0;
        aurora_lane_up = 0;
        rd_start = 0;
        cpu_fpga_start_addr = TX_BASE;
        cpu_fpga_len = 16;
        int_state_clear = 0;
        clear_inter = 0;
        cpu_rec_state_r = 0;
        cpu_wr_done_shadow = 0;
        test_error_count = 0;

        repeat (20) @(posedge fdma_clk);
        fdma_rstn = 1;
        repeat (10) @(posedge user_clk);
        user_rstn = 1;
        pcie_link_up = 1;
        aurora_channel_up = 1;
        aurora_lane_up = 1;
        rp_init_and_enumerate();

        bar_read32(32'h0008, bar_value);
        if (bar_value !== 32'h0004_0000) begin
            test_error_count = test_error_count + 1;
            $error("BUF_LEN_MAX is not 256 KiB");
        end

        // Invalid TX address must be rejected before any FDMA request.
        bar_write32(32'h0024, RX_BASE);
        bar_write32(32'h0028, 16);
        bar_write32(32'h0020, 1);
        repeat (20) @(posedge fdma_clk);
        if (!length_error_sticky || fdma_rareq) begin
            test_error_count = test_error_count + 1;
            $error("Invalid TX command was not rejected cleanly");
        end
        bar_write32(32'h0020, 0);
        clear_irq_by_read();

        // 16-byte transaction.
        u_backend.host_fill_pattern(64'h0000_0000_0000_0000, 16, 8'h54, 0);
        h2c_transfer(64'h0, {CARD_ADDR_HI, TX_BASE}, 16);
        start_tx_command(TX_BASE, 16, 0);

        // 1-KiB application unit = 64 16-byte frames, with LocalLink stalls.
        u_backend.host_fill_pattern(64'h0000_0000_0000_1000, 1024, 8'h54, 1);
        h2c_transfer(64'h1000, {CARD_ADDR_HI, 32'h0000_8200}, 1024);
        u_aurora_peer.set_tx_stall(1);
        u_backend.set_fdma_stalls(1, 1);
        start_tx_command(32'h0000_8200, 1024, 1);
        u_backend.set_fdma_stalls(0, 0);

        // Full 32-KiB TX window. Inject one RX frame concurrently.
        u_backend.host_fill_pattern(64'h0000_0000_0000_2000,
                                    WINDOW_BYTES, 8'h54, 10);
        h2c_transfer(64'h2000, {CARD_ADDR_HI, TX_BASE}, WINDOW_BYTES);
        fork
            begin
                start_tx_command(TX_BASE, WINDOW_BYTES, 10);
            end
            begin
                repeat (50) @(posedge user_clk);
                u_aurora_peer.send_rx_frame(0);
            end
        join
        u_aurora_peer.set_tx_stall(0);

        check_rx_notification(RX_BASE);
        c2h_transfer({CARD_ADDR_HI, RX_BASE}, 64'h0000_0000_0001_0000, 16);
        u_backend.compare_host_pattern(64'h0001_0000, 16, 8'h52, 0, compare_mismatches);
        test_error_count = test_error_count + compare_mismatches;
        clear_irq_by_read();
        if (!rx_pending) begin
            test_error_count = test_error_count + 1;
            $error("INT_STATE read incorrectly released RX ownership");
        end

        cpu_rec_acknowledge();
        // 新版按块确认；每个用例帧等封存后读出并确认，连续跨越三轮八块。
        for (frame_index = 1; frame_index < 24; frame_index = frame_index + 1) begin
            u_aurora_peer.send_rx_frame(frame_index);
            check_rx_notification(RX_BASE + (frame_index % 8) * 32'h40000);
            c2h_transfer({CARD_ADDR_HI, RX_BASE + (frame_index % 8) * 32'h40000}, 64'h11000, 16);
            u_backend.compare_host_pattern(64'h11000, 16, 8'h52, frame_index, compare_mismatches);
            test_error_count = test_error_count + compare_mismatches;
            clear_irq_by_read();
            cpu_rec_acknowledge();
        end
        if (config_sample_count != 2113)
            $fatal(1,"FAST/CFG_COUNT actual=%0d",config_sample_count);
        if (rx_ready_blocks != 0 || rx_dropped_frames != 0) begin
            test_error_count = test_error_count + 1;
            $error("RTDS_BATCH_RESIDUAL blocks=%0d dropped=%0d",rx_ready_blocks,rx_dropped_frames);
        end

        test_error_count = test_error_count + backend_error_count +
                           scoreboard_error_count + assertion_error_count;
        $display("RTDS_RESULT card_hi=%h tx_frames=%0d rx_frames=24 stalls=%0d errors=%0d",
                 CARD_ADDR_HI, tx_total_frames, tx_stall_cycles, test_error_count);
        if (test_error_count != 0)
            $fatal(1, "RTDS try-through regression FAILED");
        $display("RTDS_TRYTHROUGH_PASS");
        $finish;
    end

    initial begin
        #2ms;
        $fatal(1, "Global simulation timeout");
    end
endmodule
