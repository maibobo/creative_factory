# async_fifo

- Category: `foundation`
- Source: `R:\AXI4 2 AXI4-STREAM GEN\async_fifo.v`
- SHA-256: `12ec4fe15baa39c0f132b09059cff6bc2bd6011ebe6c986e1a6278c73baff609`
- Extractor: `text`
- Tags: `adapter, axi, axi-stream`
- Duplicate sources:
  - none

```verilog
// Asynchronous FIFO with Gray code counter for CDC
module async_fifo #(
    parameter DATA_WIDTH = 64,
    parameter FIFO_DEPTH = 64,
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    // Write Domain (s_axi_aclk / m_axis_aclk)
    input  wire                     wr_clk,
    input  wire                     wr_rst_n,
    input  wire                     wr_en,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    output wire                     full,

    // Read Domain (m_axis_aclk / s_axi_aclk)
    input  wire                     rd_clk,
    input  wire                     rd_rst_n,
    input  wire                     rd_en,
    output reg  [DATA_WIDTH-1:0]    rd_data,
    output wire                     empty
);

// Write pointer (binary + gray)
reg [ADDR_WIDTH:0] wr_bin, wr_gray;
reg [ADDR_WIDTH:0] rd_gray_sync1, rd_gray_sync2;
// Read pointer (binary + gray)
reg [ADDR_WIDTH:0] rd_bin, rd_gray;
reg [ADDR_WIDTH:0] wr_gray_sync1, wr_gray_sync2;

// Memory array
reg [DATA_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

// ---------------------------
// Write Domain Logic
// ---------------------------
wire [ADDR_WIDTH:0] wr_bin_next = wr_bin + (wr_en & ~full);
wire [ADDR_WIDTH:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_bin  <= '0;
        wr_gray <= '0;
    end else begin
        wr_bin  <= wr_bin_next;
        wr_gray <= wr_gray_next;
    end
end

// Write to memory
always @(posedge wr_clk) begin
    if (wr_en & ~full)
        mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
end

// Sync read gray pointer to write clock
always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        rd_gray_sync1 <= '0;
        rd_gray_sync2 <= '0;
    end else begin
        rd_gray_sync1 <= rd_gray;
        rd_gray_sync2 <= rd_gray_sync1;
    end
end

assign full = (wr_gray_next == {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_gray_sync2[ADDR_WIDTH-2:0]});

// ---------------------------
// Read Domain Logic
// ---------------------------
wire [ADDR_WIDTH:0] rd_bin_next = rd_bin + (rd_en & ~empty);
wire [ADDR_WIDTH:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_bin  <= '0;
        rd_gray <= '0;
    end else begin
        rd_bin  <= rd_bin_next;
        rd_gray <= rd_gray_next;
    end
end

// Read from memory
always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n)
        rd_data <= '0;
    else if (rd_en & ~empty)
        rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
end

// Sync write gray pointer to read clock
always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        wr_gray_sync1 <= '0;
        wr_gray_sync2 <= '0;
    end else begin
        wr_gray_sync1 <= wr_gray;
        wr_gray_sync2 <= wr_gray_sync1;
    end
end

assign empty = (rd_gray_next == wr_gray_sync2);

endmodule
```
