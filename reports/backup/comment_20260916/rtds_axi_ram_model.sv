`timescale 1ns/1ps

module rtds_axi_ram_model #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 5,
    parameter integer MEM_BYTES  = 4194304
) (
    input  wire                     aclk,
    input  wire                     aresetn,
    input  wire [ID_WIDTH-1:0]      s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                     s_axi_wlast,
    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    output reg  [ID_WIDTH-1:0]      s_axi_bid,
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,
    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,
    output reg  [ID_WIDTH-1:0]      s_axi_rid,
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rlast,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready
);
    localparam integer STRB_WIDTH = DATA_WIDTH / 8;
    localparam integer WORDS = MEM_BYTES / STRB_WIDTH;
    localparam integer BYTE_BITS = $clog2(STRB_WIDTH);
    localparam integer INDEX_BITS = $clog2(WORDS);
    reg [DATA_WIDTH-1:0] mem [0:WORDS-1];

    reg aw_hold_valid;
    reg [ID_WIDTH-1:0] aw_hold_id;
    reg [ADDR_WIDTH-1:0] aw_hold_addr;
    reg [7:0] aw_beats_left;
    reg [2:0] aw_hold_size;
    reg [1:0] aw_hold_burst;
    reg aw_error;

    reg w_hold_valid;
    reg [DATA_WIDTH-1:0] w_hold_data;
    reg [STRB_WIDTH-1:0] w_hold_strb;
    reg w_hold_last;

    wire aw_in_range = (aw_hold_addr < MEM_BYTES);
    wire write_commit = aw_hold_valid && w_hold_valid && !s_axi_bvalid;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_awready = aresetn && !aw_hold_valid && !s_axi_bvalid;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_wready  = aresetn && !w_hold_valid && !s_axi_bvalid;

    integer byte_index;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_hold_valid <= 1'b0;
            w_hold_valid  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_bresp   <= 2'b00;
            aw_error      <= 1'b0;
        end else begin
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (s_axi_awvalid && s_axi_awready) begin
                aw_hold_valid <= 1'b1;
                aw_hold_id    <= s_axi_awid;
                aw_hold_addr  <= s_axi_awaddr;
                aw_beats_left <= s_axi_awlen;
                aw_hold_size  <= s_axi_awsize;
                aw_hold_burst <= s_axi_awburst;
                aw_error      <= (s_axi_awsize != 3'd3) ||
                                 ((s_axi_awburst != 2'b01) && (s_axi_awburst != 2'b00));
            end

            if (s_axi_wvalid && s_axi_wready) begin
                w_hold_valid <= 1'b1;
                w_hold_data  <= s_axi_wdata;
                w_hold_strb  <= s_axi_wstrb;
                w_hold_last  <= s_axi_wlast;
            end

            if (write_commit) begin
                if (aw_in_range) begin
                    for (byte_index = 0; byte_index < STRB_WIDTH; byte_index = byte_index + 1)
                        if (w_hold_strb[byte_index])
                            mem[aw_hold_addr[BYTE_BITS +: INDEX_BITS]][byte_index*8 +: 8] <=
                                w_hold_data[byte_index*8 +: 8];
                end else begin
                    aw_error <= 1'b1;
                end

                w_hold_valid <= 1'b0;
                if ((aw_beats_left == 0) || w_hold_last) begin
                    s_axi_bid    <= aw_hold_id;
                    s_axi_bresp  <= (aw_error || !aw_in_range ||
                                     (w_hold_last != (aw_beats_left == 0))) ? 2'b10 : 2'b00;
                    s_axi_bvalid <= 1'b1;
                    aw_hold_valid <= 1'b0;
                end else begin
                    aw_beats_left <= aw_beats_left - 1'b1;
                    if (aw_hold_burst == 2'b01)
                        aw_hold_addr <= aw_hold_addr + (1 << aw_hold_size);
                end
            end
        end
    end

    reg read_active;
    reg [ID_WIDTH-1:0] read_id;
    reg [ADDR_WIDTH-1:0] read_addr;
    reg [7:0] read_beats_left;
    reg [2:0] read_size;
    reg [1:0] read_burst;
    reg read_error;

    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_arready = aresetn && !read_active && !s_axi_rvalid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            read_active    <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rlast    <= 1'b0;
            s_axi_rid      <= {ID_WIDTH{1'b0}};
            s_axi_rdata    <= {DATA_WIDTH{1'b0}};
            s_axi_rresp    <= 2'b00;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                read_active     <= 1'b1;
                read_id         <= s_axi_arid;
                read_addr       <= s_axi_araddr;
                read_beats_left <= s_axi_arlen;
                read_size       <= s_axi_arsize;
                read_burst      <= s_axi_arburst;
                read_error      <= (s_axi_arsize != 3'd3) ||
                                   ((s_axi_arburst != 2'b01) && (s_axi_arburst != 2'b00));
            end

            if (read_active && !s_axi_rvalid) begin
                s_axi_rid    <= read_id;
                s_axi_rdata  <= (read_addr < MEM_BYTES) ? mem[read_addr[BYTE_BITS +: INDEX_BITS]] : {DATA_WIDTH{1'b0}};
                s_axi_rresp  <= (read_error || (read_addr >= MEM_BYTES)) ? 2'b10 : 2'b00;
                s_axi_rlast  <= (read_beats_left == 0);
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                if (s_axi_rlast) begin
                    read_active <= 1'b0;
                    s_axi_rlast <= 1'b0;
                end else begin
                    read_beats_left <= read_beats_left - 1'b1;
                    if (read_burst == 2'b01)
                        read_addr <= read_addr + (1 << read_size);
                end
            end
        end
    end
endmodule
