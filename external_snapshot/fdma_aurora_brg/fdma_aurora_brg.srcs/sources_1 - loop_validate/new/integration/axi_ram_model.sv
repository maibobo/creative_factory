`timescale 1ns / 1ps

module axi_ram_model #(
        parameter int ID_WIDTH = 1,
        parameter int ADDR_WIDTH = 64,
        parameter int DATA_WIDTH = 64,
        parameter int MEM_BYTES = 8192
    )(
        input  logic                    clk,
        input  logic                    rstn,
        input  logic                    write_stall_enable,
        input  logic                    read_stall_enable,
        input  logic                    write_block_enable,
        input  logic                    read_block_enable,

        output logic [31:0]             aw_accept_count,
        output logic [31:0]             ar_accept_count,
        output logic [31:0]             write_word_count,
        output logic [31:0]             read_word_count,
        output logic [ADDR_WIDTH-1:0]   last_awaddr,
        output logic [ADDR_WIDTH-1:0]   last_araddr,

        input  logic [ID_WIDTH-1:0]     s_axi_awid,
        input  logic [ADDR_WIDTH-1:0]   s_axi_awaddr,
        input  logic [7:0]              s_axi_awlen,
        input  logic [2:0]              s_axi_awsize,
        input  logic [1:0]              s_axi_awburst,
        input  logic                    s_axi_awlock,
        input  logic [3:0]              s_axi_awcache,
        input  logic [2:0]              s_axi_awprot,
        input  logic [3:0]              s_axi_awqos,
        input  logic                    s_axi_awvalid,
        output logic                    s_axi_awready,

        input  logic [ID_WIDTH-1:0]     s_axi_wid,
        input  logic [DATA_WIDTH-1:0]   s_axi_wdata,
        input  logic [DATA_WIDTH/8-1:0] s_axi_wstrb,
        input  logic                    s_axi_wlast,
        input  logic                    s_axi_wvalid,
        output logic                    s_axi_wready,

        output logic [ID_WIDTH-1:0]     s_axi_bid,
        output logic [1:0]              s_axi_bresp,
        output logic                    s_axi_bvalid,
        input  logic                    s_axi_bready,

        input  logic [ID_WIDTH-1:0]     s_axi_arid,
        input  logic [ADDR_WIDTH-1:0]   s_axi_araddr,
        input  logic [7:0]              s_axi_arlen,
        input  logic [2:0]              s_axi_arsize,
        input  logic [1:0]              s_axi_arburst,
        input  logic                    s_axi_arlock,
        input  logic [3:0]              s_axi_arcache,
        input  logic [2:0]              s_axi_arprot,
        input  logic [3:0]              s_axi_arqos,
        input  logic                    s_axi_arvalid,
        output logic                    s_axi_arready,

        output logic [ID_WIDTH-1:0]     s_axi_rid,
        output logic [DATA_WIDTH-1:0]   s_axi_rdata,
        output logic [1:0]              s_axi_rresp,
        output logic                    s_axi_rlast,
        output logic                    s_axi_rvalid,
        input  logic                    s_axi_rready
    );

    localparam int WORD_BYTES = DATA_WIDTH / 8;
    localparam int MEM_WORDS = MEM_BYTES / WORD_BYTES;

    logic [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    logic                  wr_active;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [7:0]            wr_len;
    logic [7:0]            wr_count;
    logic [ID_WIDTH-1:0]   wr_id;

    logic                  rd_active;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [7:0]            rd_len;
    logic [7:0]            rd_count;
    logic [ID_WIDTH-1:0]   rd_id;

    logic [31:0]           stall_counter;

    function automatic int word_index(input logic [ADDR_WIDTH-1:0] addr);
        word_index = (addr / WORD_BYTES) % MEM_WORDS;
    endfunction

    assign s_axi_awready = !wr_active && !write_block_enable;
    assign s_axi_wready  = wr_active && !write_block_enable &&
                            !(write_stall_enable && (stall_counter[2:0] == 3'd3));
    assign s_axi_arready = !rd_active && !s_axi_rvalid && !read_block_enable;

    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;

    integer init_i;
    initial begin
        for (init_i = 0; init_i < MEM_WORDS; init_i = init_i + 1)
            mem[init_i] = '0;
    end

    integer byte_i;
    integer wr_index;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_active        <= 1'b0;
            wr_addr          <= '0;
            wr_len           <= '0;
            wr_count         <= '0;
            wr_id            <= '0;
            s_axi_bid        <= '0;
            s_axi_bvalid     <= 1'b0;
            aw_accept_count  <= 32'd0;
            write_word_count <= 32'd0;
            last_awaddr      <= '0;
            stall_counter    <= 32'd0;
        end else begin
            stall_counter <= stall_counter + 32'd1;

            if (s_axi_awvalid && s_axi_awready) begin
                wr_active       <= 1'b1;
                wr_addr         <= s_axi_awaddr;
                wr_len          <= s_axi_awlen;
                wr_count        <= 8'd0;
                wr_id           <= s_axi_awid;
                aw_accept_count <= aw_accept_count + 32'd1;
                last_awaddr     <= s_axi_awaddr;
            end

            if (s_axi_wvalid && s_axi_wready) begin
                wr_index = word_index(wr_addr);
                for (byte_i = 0; byte_i < WORD_BYTES; byte_i = byte_i + 1) begin
                    if (s_axi_wstrb[byte_i])
                        mem[wr_index][8*byte_i +: 8] <= s_axi_wdata[8*byte_i +: 8];
                end
                write_word_count <= write_word_count + 32'd1;
                wr_addr <= wr_addr + WORD_BYTES;

                if (wr_count == wr_len) begin
                    wr_active    <= 1'b0;
                    s_axi_bid    <= wr_id;
                    s_axi_bvalid <= 1'b1;
                end else begin
                    wr_count <= wr_count + 8'd1;
                end
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rd_active       <= 1'b0;
            rd_addr         <= '0;
            rd_len          <= '0;
            rd_count        <= '0;
            rd_id           <= '0;
            s_axi_rid       <= '0;
            s_axi_rdata     <= '0;
            s_axi_rlast     <= 1'b0;
            s_axi_rvalid    <= 1'b0;
            ar_accept_count <= 32'd0;
            read_word_count <= 32'd0;
            last_araddr     <= '0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                rd_active       <= 1'b1;
                rd_addr         <= s_axi_araddr;
                rd_len          <= s_axi_arlen;
                rd_count        <= 8'd0;
                rd_id           <= s_axi_arid;
                ar_accept_count <= ar_accept_count + 32'd1;
                last_araddr     <= s_axi_araddr;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                read_word_count <= read_word_count + 32'd1;
                if (s_axi_rlast) begin
                    rd_active    <= 1'b0;
                    s_axi_rvalid <= 1'b0;
                    s_axi_rlast  <= 1'b0;
                end else begin
                    rd_addr      <= rd_addr + WORD_BYTES;
                    rd_count     <= rd_count + 8'd1;
                    s_axi_rvalid <= 1'b0;
                end
            end else if (!s_axi_rvalid && rd_active && !read_block_enable &&
                         !(read_stall_enable && (stall_counter[2:0] == 3'd5))) begin
                s_axi_rid    <= rd_id;
                s_axi_rdata  <= mem[word_index(rd_addr)];
                s_axi_rlast  <= (rd_count == rd_len);
                s_axi_rvalid <= 1'b1;
            end
        end
    end

endmodule
