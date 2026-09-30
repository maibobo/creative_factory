`timescale 1ns / 1ps

module tb_fdma_aurora_brg_conv_dma_integration;

    localparam int FRAME_BYTES = 512;
    localparam int FRAME_WORDS = FRAME_BYTES / 8;
    localparam int MEM_BYTES = 8192;
    localparam int MEM_WORDS = MEM_BYTES / 8;

    logic fdma_clk = 1'b0;
    logic user_clk = 1'b0;

    always #2 fdma_clk = ~fdma_clk;
    always #3 user_clk = ~user_clk;

    logic fdma_rstn;
    logic user_rstn;
    logic fdma_status_clear;
    logic user_status_clear;
    logic channel_up;
    logic [15:0] cfg_tx_burst_limit;

    logic [31:0] fdma_raddr32;
    logic        fdma_rareq;
    logic [15:0] fdma_rsize;
    logic        fdma_rbusy;
    logic [63:0] fdma_rdata;
    logic        fdma_rvalid;
    logic        fdma_rready;

    logic [31:0] fdma_waddr32;
    logic        fdma_wareq;
    logic [15:0] fdma_wsize;
    logic        fdma_wbusy;
    logic [63:0] fdma_wdata;
    logic        fdma_wvalid;
    logic        fdma_wready;

    logic [63:0] aurora_tx_d;
    logic        aurora_tx_sof;
    logic        aurora_tx_eof;
    logic [2:0]  aurora_tx_rem;
    logic        aurora_tx_src_rdy;
    logic        aurora_tx_dst_rdy;

    logic [63:0] aurora_rx_d;
    logic        aurora_rx_sof;
    logic        aurora_rx_eof;
    logic [2:0]  aurora_rx_rem;
    logic        aurora_rx_src_rdy;
    logic        aurora_rx_dst_rdy;

    logic        dbg_channel_up_fdma;
    logic [37:0] tx_fdma_dbg_bus;
    logic [38:0] tx_user_dbg_bus;
    logic [105:0] rx_fdma_dbg_bus;
    logic [28:0] rx_user_dbg_bus;
    logic [15:0] bridge_fdma_wsize_raw;
    logic [10:0] rx_fifo_wr_count;
    logic        rx_fifo_almost_full;
    logic        rx_fifo_full;
    logic        rx_almost_full_sticky;
    logic        rx_full_sticky;
    logic        rx_overflow_sticky;
    logic        tx_underflow_sticky;
    logic        link_down_sticky;
    logic        fdma_timeout_sticky;

    logic [63:0] fdma_waddr;
    logic [63:0] fdma_raddr;
    assign fdma_waddr = {32'd0, fdma_waddr32};
    assign fdma_raddr = {32'd0, fdma_raddr32};

    logic [0:0]  m_axi_awid;
    logic [63:0] m_axi_awaddr;
    logic [7:0]  m_axi_awlen;
    logic [2:0]  m_axi_awsize;
    logic [1:0]  m_axi_awburst;
    logic        m_axi_awlock;
    logic [3:0]  m_axi_awcache;
    logic [2:0]  m_axi_awprot;
    logic [3:0]  m_axi_awqos;
    logic        m_axi_awvalid;
    logic        m_axi_awready;
    logic [0:0]  m_axi_wid;
    logic [63:0] m_axi_wdata;
    logic [7:0]  m_axi_wstrb;
    logic        m_axi_wlast;
    logic        m_axi_wvalid;
    logic        m_axi_wready;
    logic [0:0]  m_axi_bid;
    logic [1:0]  m_axi_bresp;
    logic        m_axi_bvalid;
    logic        m_axi_bready;
    logic [0:0]  m_axi_arid;
    logic [63:0] m_axi_araddr;
    logic [7:0]  m_axi_arlen;
    logic [2:0]  m_axi_arsize;
    logic [1:0]  m_axi_arburst;
    logic        m_axi_arlock;
    logic [3:0]  m_axi_arcache;
    logic [2:0]  m_axi_arprot;
    logic [3:0]  m_axi_arqos;
    logic        m_axi_arvalid;
    logic        m_axi_arready;
    logic [0:0]  m_axi_rid;
    logic [63:0] m_axi_rdata;
    logic [1:0]  m_axi_rresp;
    logic        m_axi_rlast;
    logic        m_axi_rvalid;
    logic        m_axi_rready;

    logic write_stall_enable;
    logic read_stall_enable;
    logic write_block_enable;
    logic read_block_enable;
    logic [31:0] aw_accept_count;
    logic [31:0] ar_accept_count;
    logic [31:0] write_word_count;
    logic [31:0] read_word_count;
    logic [63:0] last_awaddr;
    logic [63:0] last_araddr;

    int error_count;

    fdma_aurora_pcie_conv_dma_wrapper #(
        .FRAME_BYTES      (FRAME_BYTES),
        .MEM_WINDOW_BYTES (MEM_BYTES)
    ) u_dut (
        .fdma_clk                (fdma_clk),
        .fdma_rstn               (fdma_rstn),
        .fdma_status_clear       (fdma_status_clear),
        .user_clk                (user_clk),
        .user_rstn               (user_rstn),
        .user_status_clear       (user_status_clear),
        .channel_up              (channel_up),
        .cfg_tx_burst_limit      (cfg_tx_burst_limit),
        .fdma_raddr              (fdma_raddr32),
        .fdma_rareq              (fdma_rareq),
        .fdma_rsize              (fdma_rsize),
        .fdma_rbusy              (fdma_rbusy),
        .fdma_rdata              (fdma_rdata),
        .fdma_rvalid             (fdma_rvalid),
        .fdma_rready             (fdma_rready),
        .fdma_waddr              (fdma_waddr32),
        .fdma_wareq              (fdma_wareq),
        .fdma_wsize              (fdma_wsize),
        .fdma_wbusy              (fdma_wbusy),
        .fdma_wdata              (fdma_wdata),
        .fdma_wvalid             (fdma_wvalid),
        .fdma_wready             (fdma_wready),
        .aurora_tx_d             (aurora_tx_d),
        .aurora_tx_sof           (aurora_tx_sof),
        .aurora_tx_eof           (aurora_tx_eof),
        .aurora_tx_rem           (aurora_tx_rem),
        .aurora_tx_src_rdy       (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy       (aurora_tx_dst_rdy),
        .aurora_rx_d             (aurora_rx_d),
        .aurora_rx_sof           (aurora_rx_sof),
        .aurora_rx_eof           (aurora_rx_eof),
        .aurora_rx_rem           (aurora_rx_rem),
        .aurora_rx_src_rdy       (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy       (aurora_rx_dst_rdy),
        .dbg_channel_up_fdma     (dbg_channel_up_fdma),
        .tx_fdma_dbg_bus         (tx_fdma_dbg_bus),
        .tx_user_dbg_bus         (tx_user_dbg_bus),
        .rx_fdma_dbg_bus         (rx_fdma_dbg_bus),
        .rx_user_dbg_bus         (rx_user_dbg_bus),
        .bridge_fdma_wsize_raw   (bridge_fdma_wsize_raw),
        .rx_fifo_wr_count        (rx_fifo_wr_count),
        .rx_fifo_almost_full     (rx_fifo_almost_full),
        .rx_fifo_full            (rx_fifo_full),
        .rx_almost_full_sticky   (rx_almost_full_sticky),
        .rx_full_sticky          (rx_full_sticky),
        .rx_overflow_sticky      (rx_overflow_sticky),
        .tx_underflow_sticky     (tx_underflow_sticky),
        .link_down_sticky        (link_down_sticky),
        .fdma_timeout_sticky     (fdma_timeout_sticky)
    );

    CONV_DMA #(
        .M_AXI_ID_WIDTH   (1),
        .M_AXI_ID         (0),
        .M_AXI_ADDR_WIDTH (64),
        .M_AXI_DATA_WIDTH (64)
    ) u_conv_dma (
        .fdma_waddr      (fdma_waddr),
        .fdma_wareq      (fdma_wareq),
        .fdma_wsize      (fdma_wsize),
        .fdma_wbusy      (fdma_wbusy),
        .fdma_wdata      (fdma_wdata),
        .fdma_wvalid     (fdma_wready),
        .fdma_wready     (fdma_wvalid),
        .fdma_raddr      (fdma_raddr),
        .fdma_rareq      (fdma_rareq),
        .fdma_rsize      (fdma_rsize),
        .fdma_rbusy      (fdma_rbusy),
        .fdma_rdata      (fdma_rdata),
        .fdma_rvalid     (fdma_rvalid),
        .fdma_rready     (fdma_rready),
        .M_AXI_ACLK      (fdma_clk),
        .M_AXI_ARESETN   (fdma_rstn),
        .M_AXI_AWID      (m_axi_awid),
        .M_AXI_AWADDR    (m_axi_awaddr),
        .M_AXI_AWLEN     (m_axi_awlen),
        .M_AXI_AWSIZE    (m_axi_awsize),
        .M_AXI_AWBURST   (m_axi_awburst),
        .M_AXI_AWLOCK    (m_axi_awlock),
        .M_AXI_AWCACHE   (m_axi_awcache),
        .M_AXI_AWPROT    (m_axi_awprot),
        .M_AXI_AWQOS     (m_axi_awqos),
        .M_AXI_AWVALID   (m_axi_awvalid),
        .M_AXI_AWREADY   (m_axi_awready),
        .M_AXI_WID       (m_axi_wid),
        .M_AXI_WDATA     (m_axi_wdata),
        .M_AXI_WSTRB     (m_axi_wstrb),
        .M_AXI_WLAST     (m_axi_wlast),
        .M_AXI_WVALID    (m_axi_wvalid),
        .M_AXI_WREADY    (m_axi_wready),
        .M_AXI_BID       (m_axi_bid),
        .M_AXI_BRESP     (m_axi_bresp),
        .M_AXI_BVALID    (m_axi_bvalid),
        .M_AXI_BREADY    (m_axi_bready),
        .M_AXI_ARID      (m_axi_arid),
        .M_AXI_ARADDR    (m_axi_araddr),
        .M_AXI_ARLEN     (m_axi_arlen),
        .M_AXI_ARSIZE    (m_axi_arsize),
        .M_AXI_ARBURST   (m_axi_arburst),
        .M_AXI_ARLOCK    (m_axi_arlock),
        .M_AXI_ARCACHE   (m_axi_arcache),
        .M_AXI_ARPROT    (m_axi_arprot),
        .M_AXI_ARQOS     (m_axi_arqos),
        .M_AXI_ARVALID   (m_axi_arvalid),
        .M_AXI_ARREADY   (m_axi_arready),
        .M_AXI_RID       (m_axi_rid),
        .M_AXI_RDATA     (m_axi_rdata),
        .M_AXI_RRESP     (m_axi_rresp),
        .M_AXI_RLAST     (m_axi_rlast),
        .M_AXI_RVALID    (m_axi_rvalid),
        .M_AXI_RREADY    (m_axi_rready)
    );

    axi_ram_model #(
        .ID_WIDTH   (1),
        .ADDR_WIDTH (64),
        .DATA_WIDTH (64),
        .MEM_BYTES  (MEM_BYTES)
    ) u_axi_ram (
        .clk                (fdma_clk),
        .rstn               (fdma_rstn),
        .write_stall_enable (write_stall_enable),
        .read_stall_enable  (read_stall_enable),
        .write_block_enable (write_block_enable),
        .read_block_enable  (read_block_enable),
        .aw_accept_count    (aw_accept_count),
        .ar_accept_count    (ar_accept_count),
        .write_word_count   (write_word_count),
        .read_word_count    (read_word_count),
        .last_awaddr        (last_awaddr),
        .last_araddr        (last_araddr),
        .s_axi_awid         (m_axi_awid),
        .s_axi_awaddr       (m_axi_awaddr),
        .s_axi_awlen        (m_axi_awlen),
        .s_axi_awsize       (m_axi_awsize),
        .s_axi_awburst      (m_axi_awburst),
        .s_axi_awlock       (m_axi_awlock),
        .s_axi_awcache      (m_axi_awcache),
        .s_axi_awprot       (m_axi_awprot),
        .s_axi_awqos        (m_axi_awqos),
        .s_axi_awvalid      (m_axi_awvalid),
        .s_axi_awready      (m_axi_awready),
        .s_axi_wid          (m_axi_wid),
        .s_axi_wdata        (m_axi_wdata),
        .s_axi_wstrb        (m_axi_wstrb),
        .s_axi_wlast        (m_axi_wlast),
        .s_axi_wvalid       (m_axi_wvalid),
        .s_axi_wready       (m_axi_wready),
        .s_axi_bid          (m_axi_bid),
        .s_axi_bresp        (m_axi_bresp),
        .s_axi_bvalid       (m_axi_bvalid),
        .s_axi_bready       (m_axi_bready),
        .s_axi_arid         (m_axi_arid),
        .s_axi_araddr       (m_axi_araddr),
        .s_axi_arlen        (m_axi_arlen),
        .s_axi_arsize       (m_axi_arsize),
        .s_axi_arburst      (m_axi_arburst),
        .s_axi_arlock       (m_axi_arlock),
        .s_axi_arcache      (m_axi_arcache),
        .s_axi_arprot       (m_axi_arprot),
        .s_axi_arqos        (m_axi_arqos),
        .s_axi_arvalid      (m_axi_arvalid),
        .s_axi_arready      (m_axi_arready),
        .s_axi_rid          (m_axi_rid),
        .s_axi_rdata        (m_axi_rdata),
        .s_axi_rresp        (m_axi_rresp),
        .s_axi_rlast        (m_axi_rlast),
        .s_axi_rvalid       (m_axi_rvalid),
        .s_axi_rready       (m_axi_rready)
    );

    function automatic logic [63:0] rx_pattern(input int frame, input int beat);
        rx_pattern = {16'hA100, frame[15:0], 16'h0000, beat[15:0]};
    endfunction

    function automatic logic [63:0] tx_pattern(input int frame, input int beat);
        tx_pattern = {16'h5A00, frame[15:0], 16'h0000, beat[15:0]};
    endfunction

    task automatic fail(input string msg);
        begin
            error_count++;
            $error("%s", msg);
        end
    endtask

    task automatic reset_dut(input [15:0] tx_limit);
        begin
            fdma_rstn           <= 1'b0;
            user_rstn           <= 1'b0;
            channel_up          <= 1'b0;
            cfg_tx_burst_limit  <= tx_limit;
            fdma_status_clear   <= 1'b0;
            user_status_clear   <= 1'b0;
            aurora_tx_dst_rdy   <= 1'b1;
            aurora_rx_src_rdy   <= 1'b0;
            aurora_rx_sof       <= 1'b0;
            aurora_rx_eof       <= 1'b0;
            aurora_rx_rem       <= 3'b111;
            aurora_rx_d         <= 64'd0;
            repeat (12) @(posedge fdma_clk);
            fdma_rstn <= 1'b1;
            user_rstn <= 1'b1;
            repeat (12) @(posedge fdma_clk);
        end
    endtask

    task automatic bring_link_up;
        int cycles;
        begin
            repeat (8) @(posedge user_clk);
            channel_up <= 1'b1;
            repeat (24) @(posedge fdma_clk);
            if (dbg_channel_up_fdma !== 1'b1)
                fail("channel_up did not synchronize into fdma_clk domain");
            cycles = 0;
            while ((u_dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.wr_rst_busy ||
                    u_dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_rx.rd_rst_busy ||
                    u_dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.wr_rst_busy ||
                    u_dut.u_fdma_aurora_brg_top.u_fdma_aurora_brg_tx.rd_rst_busy) &&
                   (cycles < 1000)) begin
                @(posedge user_clk);
                cycles++;
            end
            if (cycles >= 1000)
                fail("timeout waiting for bridge FIFO reset-busy signals to clear");
        end
    endtask

    task automatic pulse_status_clear;
        begin
            @(posedge user_clk);
            user_status_clear <= 1'b1;
            @(posedge fdma_clk);
            fdma_status_clear <= 1'b1;
            @(posedge user_clk);
            user_status_clear <= 1'b0;
            @(posedge fdma_clk);
            fdma_status_clear <= 1'b0;
        end
    endtask

    task automatic drive_rx_frame(input int frame);
        int beat;
        begin
            for (beat = 0; beat < FRAME_WORDS; beat++) begin
                @(negedge user_clk);
                aurora_rx_d       <= rx_pattern(frame, beat);
                aurora_rx_sof     <= (beat == 0);
                aurora_rx_eof     <= (beat == FRAME_WORDS-1);
                aurora_rx_rem     <= 3'b111;
                aurora_rx_src_rdy <= 1'b1;
                @(posedge user_clk);
                if (aurora_rx_dst_rdy !== 1'b1)
                    fail("aurora_rx_dst_rdy must remain asserted");
            end
            @(negedge user_clk);
            aurora_rx_src_rdy <= 1'b0;
            aurora_rx_sof     <= 1'b0;
            aurora_rx_eof     <= 1'b0;
            aurora_rx_d       <= 64'd0;
        end
    endtask

    task automatic wait_write_words(input int target_words, input int timeout_cycles);
        int cycles;
        begin
            cycles = 0;
            while ((write_word_count < target_words) && (cycles < timeout_cycles)) begin
                @(posedge fdma_clk);
                cycles++;
            end
            if (write_word_count < target_words)
                fail($sformatf("timeout waiting for %0d AXI write words, got %0d",
                               target_words, write_word_count));
        end
    endtask

    task automatic check_rx_frame(input int frame, input int base_word);
        int beat;
        logic [63:0] got;
        logic [63:0] exp;
        begin
            for (beat = 0; beat < FRAME_WORDS; beat++) begin
                got = u_axi_ram.mem[(base_word + beat) % MEM_WORDS];
                exp = rx_pattern(frame, beat);
                if (got !== exp)
                    fail($sformatf("RX memory mismatch frame=%0d beat=%0d got=%016h exp=%016h",
                                   frame, beat, got, exp));
            end
        end
    endtask

    task automatic preload_tx_frame(input int frame, input int base_word);
        int beat;
        begin
            for (beat = 0; beat < FRAME_WORDS; beat++)
                u_axi_ram.mem[(base_word + beat) % MEM_WORDS] = tx_pattern(frame, beat);
        end
    endtask

    task automatic capture_tx_frame(input int frame, input bit stall_dst);
        int beat;
        int cycles;
        int stall_cycle;
        logic [63:0] exp;
        begin
            beat = 0;
            cycles = 0;
            stall_cycle = 0;
            while ((beat < FRAME_WORDS) && (cycles < 50000)) begin
                aurora_tx_dst_rdy <= !(stall_dst && ((stall_cycle % 17) == 5));
                @(posedge user_clk);
                if (aurora_tx_src_rdy && aurora_tx_dst_rdy) begin
                    exp = tx_pattern(frame, beat);
                    if ((beat == 0) && !aurora_tx_sof)
                        fail("TX frame missing SOF");
                    if ((beat != 0) && aurora_tx_sof)
                        fail("TX SOF asserted away from first beat");
                    if ((beat == FRAME_WORDS-1) && !aurora_tx_eof)
                        fail("TX frame missing EOF");
                    if ((beat != FRAME_WORDS-1) && aurora_tx_eof)
                        fail("TX EOF asserted before last beat");
                    if (aurora_tx_rem !== 3'b111)
                        fail("TX REM is not 3'b111 for a full 64-bit beat");
                    if (aurora_tx_d !== exp)
                        fail($sformatf("TX data mismatch frame=%0d beat=%0d got=%016h exp=%016h",
                                       frame, beat, aurora_tx_d, exp));
                    beat++;
                end
                stall_cycle++;
                cycles++;
            end
            aurora_tx_dst_rdy <= 1'b1;
            if (beat < FRAME_WORDS)
                fail($sformatf("timeout capturing TX frame %0d, got %0d beats", frame, beat));
        end
    endtask

    task automatic check_read_address_wrap;
        int seen;
        int cycles;
        logic prev_accept;
        logic [31:0] expected_addr;
        begin
            seen = 0;
            cycles = 0;
            prev_accept = 1'b0;
            while ((seen < 16) && (cycles < 200000)) begin
                @(posedge fdma_clk);
                if (fdma_rareq && fdma_rbusy && !prev_accept) begin
                    expected_addr = (seen * FRAME_BYTES) % MEM_BYTES;
                    if (fdma_raddr32 !== expected_addr)
                        fail($sformatf("read address wrap mismatch index=%0d got=%08h exp=%08h",
                                       seen, fdma_raddr32, expected_addr));
                    seen++;
                end
                prev_accept = fdma_rareq && fdma_rbusy;
                cycles++;
            end
            if (seen != 16)
                fail($sformatf("timeout waiting for 16 read bursts, saw %0d", seen));
        end
    endtask

    always @(posedge fdma_clk) begin
        if (fdma_rstn && m_axi_awvalid && m_axi_awready) begin
            if (m_axi_awlen !== 8'd63)
                fail($sformatf("AWLEN mismatch got=%0d exp=63", m_axi_awlen));
            if (m_axi_awsize !== 3'd3)
                fail($sformatf("AWSIZE mismatch got=%0d exp=3", m_axi_awsize));
        end
        if (fdma_rstn && m_axi_arvalid && m_axi_arready) begin
            if (m_axi_arlen !== 8'd63)
                fail($sformatf("ARLEN mismatch got=%0d exp=63", m_axi_arlen));
            if (m_axi_arsize !== 3'd3)
                fail($sformatf("ARSIZE mismatch got=%0d exp=3", m_axi_arsize));
        end
    end

    initial begin
        error_count = 0;
        write_stall_enable = 1'b0;
        read_stall_enable  = 1'b0;
        write_block_enable = 1'b0;
        read_block_enable  = 1'b0;

        reset_dut(16'd1);
        bring_link_up();

        if (fdma_rsize !== 16'd64)
            fail($sformatf("fdma_rsize mismatch got=%0d exp=64", fdma_rsize));
        if (fdma_wsize !== 16'd64)
            fail($sformatf("fdma_wsize mismatch got=%0d exp=64", fdma_wsize));
        if (bridge_fdma_wsize_raw !== 16'd512)
            fail($sformatf("raw bridge wsize mismatch got=%0d exp=512", bridge_fdma_wsize_raw));

        drive_rx_frame(0);
        drive_rx_frame(1);
        wait_write_words(128, 20000);
        check_rx_frame(0, 0);
        check_rx_frame(1, FRAME_WORDS);

        reset_dut(16'd1);
        write_stall_enable = 1'b1;
        bring_link_up();
        drive_rx_frame(2);
        wait_write_words(64, 20000);
        check_rx_frame(2, 0);
        write_stall_enable = 1'b0;

        reset_dut(16'd2);
        preload_tx_frame(0, 0);
        preload_tx_frame(1, FRAME_WORDS);
        read_stall_enable = 1'b1;
        aurora_tx_dst_rdy <= 1'b0;
        bring_link_up();
        capture_tx_frame(0, 1'b1);
        capture_tx_frame(1, 1'b1);
        read_stall_enable = 1'b0;

        reset_dut(16'd16);
        for (int frame = 0; frame < 16; frame++)
            preload_tx_frame(frame, frame * FRAME_WORDS);
        repeat (8) @(posedge user_clk);
        channel_up <= 1'b1;
        check_read_address_wrap();

        @(posedge user_clk);
        channel_up <= 1'b0;
        repeat (8) @(posedge user_clk);
        if (!link_down_sticky)
            fail("link_down_sticky did not set after channel_up dropped");
        pulse_status_clear();

        reset_dut(16'd1);
        write_block_enable = 1'b1;
        bring_link_up();
        for (int frame = 0; frame < 33; frame++)
            drive_rx_frame(100 + frame);
        repeat (40) @(posedge user_clk);
        if (aurora_rx_dst_rdy !== 1'b1)
            fail("aurora_rx_dst_rdy deasserted in RX pressure test");
        if (!rx_almost_full_sticky)
            fail("rx_almost_full_sticky did not set in pressure test");
        if (!rx_full_sticky)
            fail("rx_full_sticky did not set in pressure test");
        if (!rx_overflow_sticky)
            fail("rx_overflow_sticky did not set in pressure test");
        write_block_enable = 1'b0;

        repeat (40) @(posedge fdma_clk);
        if (error_count == 0) begin
            $display("TEST PASS: fdma_aurora_brg CONV_DMA integration");
            $finish;
        end else begin
            $fatal(1, "TEST FAIL: %0d errors", error_count);
        end
    end

endmodule
