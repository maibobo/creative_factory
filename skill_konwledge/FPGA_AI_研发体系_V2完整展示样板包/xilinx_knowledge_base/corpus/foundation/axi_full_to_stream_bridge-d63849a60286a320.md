# axi_full_to_stream_bridge

- Category: `foundation`
- Source: `R:\AXI4 2 AXI4-STREAM GEN\axi_full_to_stream_bridge.v`
- SHA-256: `d63849a60286a320b51a67d910bed7e7920f61a4adbc841b2a931a64acfe10bf`
- Extractor: `text`
- Tags: `adapter, axi, axi-stream`
- Duplicate sources:
  - none

```verilog
// AXI4-Full (64-bit) ↔ AXI4-Stream (64-bit) Bidirectional Bridge
module axi_full_to_stream_bridge (
    // AXI4-Full Slave Interface (250MHz Clock Domain)
    input  wire         s_axi_aclk,        // 250MHz AXI clock
    input  wire         s_axi_aresetn,     // Active-low AXI reset
    // AXI Write Address Channel
    input  wire [31:0]  s_axi_awaddr,
    input  wire [3:0]   s_axi_awlen,
    input  wire [2:0]   s_axi_awsize,
    input  wire [1:0]   s_axi_awburst,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    // AXI Write Data Channel
    input  wire [63:0]  s_axi_wdata,
    input  wire [7:0]   s_axi_wstrb,
    input  wire         s_axi_wlast,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    // AXI Write Response Channel
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    // AXI Read Address Channel
    input  wire [31:0]  s_axi_araddr,
    input  wire [3:0]   s_axi_arlen,
    input  wire [2:0]   s_axi_arsize,
    input  wire [1:0]   s_axi_arburst,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    // AXI Read Data Channel
    output reg [63:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rlast,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,

    // AXI4-Stream Clock Domain (156.25MHz)
    input  wire         m_axis_aclk,       // 156.25MHz Stream clock
    input  wire         m_axis_aresetn,    // Active-low Stream reset
    // AXI4-Stream Master (TX: AXI-Full Write → Stream)
    output reg [63:0]   m_axis_tdata,
    output reg [7:0]    m_axis_tkeep,
    output reg          m_axis_tlast,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    // AXI4-Stream Slave (RX: Stream → AXI-Full Read)
    input  wire [63:0]  s_axis_tdata,
    input  wire [7:0]   s_axis_tkeep,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tvalid,
    output reg          s_axis_tready
);

// ---------------------------
// Local Parameters
// ---------------------------
localparam FIFO_DEPTH     = 64;           // FIFO depth for rate mismatch (250→156.25MHz)
localparam CTRL_FRAME_W   = 32+4+2+4;     // 32addr +4len +2burst +4opcode = 42bit
localparam DATA_FRAME_W   = 64+8;         // 64data +8strobe =72bit (mapped to tdata+tkeep)

// Opcode Definitions (per spec)
localparam OP_WR_ADDR     = 4'b0001;      // Write Address Control Frame
localparam OP_WR_DATA     = 4'b0010;      // Write Data Frame
localparam OP_RD_ADDR     = 4'b0011;      // Read Address Control Frame
localparam OP_RD_DATA     = 4'b0100;      // Read Data Frame

// AXI Response (OKAY = 00)
localparam RESP_OKAY      = 2'b00;

// ---------------------------
// Internal Signals
// ---------------------------
// Write Path: AXI → Stream FIFO (Control + Data Frames)
wire [63:0] wr_frame_fifo_wdata;
reg         wr_frame_fifo_wren;
wire        wr_frame_fifo_full;
wire [63:0] wr_frame_fifo_rdata;
reg         wr_frame_fifo_rden;
wire        wr_frame_fifo_empty;

// Read Request Path: AXI → Stream FIFO (Read Address Control Frame)
wire [63:0] rd_req_fifo_wdata;
reg         rd_req_fifo_wren;
wire        rd_req_fifo_full;
wire [63:0] rd_req_fifo_rdata;
reg         rd_req_fifo_rden;
wire        rd_req_fifo_empty;

// Read Data Path: Stream → AXI FIFO (Read Data + Last)
wire [64:0] rd_data_fifo_wdata;  // {tlast, 64bit rdata}
reg         rd_data_fifo_wren;
wire        rd_data_fifo_full;
wire [64:0] rd_data_fifo_rdata;
reg         rd_data_fifo_rden;
wire        rd_data_fifo_empty;

// Write Path Control
reg         wr_addr_captured;
reg [3:0]   wr_burst_cnt;
reg         wr_tx_done;

// Read Path Control
reg [3:0]   rd_burst_cnt;

// ---------------------------
// Instantiate Asynchronous FIFOs (CDC)
// ---------------------------
// 1. Write Frame FIFO (AXI clk → Stream clk: Control + Data Frames)
async_fifo #(
    .DATA_WIDTH(64),
    .FIFO_DEPTH(FIFO_DEPTH)
) wr_frame_fifo (
    .wr_clk(s_axi_aclk),
    .wr_rst_n(s_axi_aresetn),
    .wr_en(wr_frame_fifo_wren),
    .wr_data(wr_frame_fifo_wdata),
    .full(wr_frame_fifo_full),
    .rd_clk(m_axis_aclk),
    .rd_rst_n(m_axis_aresetn),
    .rd_en(wr_frame_fifo_rden),
    .rd_data(wr_frame_fifo_rdata),
    .empty(wr_frame_fifo_empty)
);

// 2. Read Request FIFO (AXI clk → Stream clk: Read Address Frame)
async_fifo #(
    .DATA_WIDTH(64),
    .FIFO_DEPTH(FIFO_DEPTH)
) rd_req_fifo (
    .wr_clk(s_axi_aclk),
    .wr_rst_n(s_axi_aresetn),
    .wr_en(rd_req_fifo_wren),
    .wr_data(rd_req_fifo_wdata),
    .full(rd_req_fifo_full),
    .rd_clk(m_axis_aclk),
    .rd_rst_n(m_axis_aresetn),
    .rd_en(rd_req_fifo_rden),
    .rd_data(rd_req_fifo_rdata),
    .empty(rd_req_fifo_empty)
);

// 3. Read Data FIFO (Stream clk → AXI clk: Read Data + Last)
async_fifo #(
    .DATA_WIDTH(65),  // {tlast, 64bit data}
    .FIFO_DEPTH(FIFO_DEPTH)
) rd_data_fifo (
    .wr_clk(m_axis_aclk),
    .wr_rst_n(m_axis_aresetn),
    .wr_en(rd_data_fifo_wren),
    .wr_data(rd_data_fifo_wdata),
    .full(rd_data_fifo_full),
    .rd_clk(s_axi_aclk),
    .rd_rst_n(s_axi_aresetn),
    .rd_en(rd_data_fifo_rden),
    .rd_data(rd_data_fifo_rdata),
    .empty(rd_data_fifo_empty)
);

// ==========================================================================
// ========================== WRITE PATH (AXI → STREAM) ======================
// ==========================================================================
// 1. Capture AXI Write Address Channel
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_awready <= 1'b0;
        wr_addr_captured <= 1'b0;
    end else begin
        s_axi_awready <= ~wr_addr_captured & ~wr_frame_fifo_full;
        if (s_axi_awvalid & s_axi_awready) begin
            wr_addr_captured <= 1'b1;
        end
    end
end

// 2. Pack Write Address Control Frame (per spec: {addr, len, burst, opcode})
assign wr_frame_fifo_wdata = {{(64-CTRL_FRAME_W){1'b0}},
                              s_axi_awaddr,    // 32bit
                              s_axi_awlen,     // 4bit
                              s_axi_awburst,   // 2bit
                              OP_WR_ADDR};     // 4bit opcode

// 3. Capture AXI Write Data Channel & Pack Data Frames
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_wready <= 1'b0;
        wr_frame_fifo_wren <= 1'b0;
        wr_burst_cnt <= '0;
        wr_tx_done <= 1'b0;
    end else begin
        s_axi_wready <= wr_addr_captured & ~wr_frame_fifo_full;
        wr_frame_fifo_wren <= 1'b0;

        // Send Write Address Control Frame first
        if (s_axi_awvalid & s_axi_awready) begin
            wr_frame_fifo_wren <= 1'b1;
        end

        // Send Write Data Frames
        if (s_axi_wvalid & s_axi_wready) begin
            wr_frame_fifo_wren <= 1'b1;
            wr_burst_cnt <= wr_burst_cnt + 1'b1;
            if (s_axi_wlast) begin
                wr_tx_done <= 1'b1;
                wr_addr_captured <= 1'b0;
                wr_burst_cnt <= '0;
            end
        end
    end
end

// Override FIFO write data for Write Data Frames (data + strobe → tdata + tkeep)
always @(*) begin
    if (s_axi_wvalid & s_axi_wready) begin
        wr_frame_fifo_wdata = s_axi_wdata;  // 64bit data
        m_axis_tkeep = s_axi_wstrb;         // 8bit strobe
    end
end

// 4. AXI Write Response (B Channel)
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_bvalid <= 1'b0;
        s_axi_bresp  <= RESP_OKAY;
        wr_tx_done   <= 1'b0;
    end else begin
        if (wr_tx_done & ~s_axi_bvalid) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= RESP_OKAY;
        end
        if (s_axi_bvalid & s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            wr_tx_done   <= 1'b0;
        end
    end
end

// ==========================================================================
// ========================== READ PATH (AXI → STREAM) ======================
// ==========================================================================
// 1. Capture AXI Read Address Channel
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_arready <= 1'b0;
        rd_req_fifo_wren <= 1'b0;
    end else begin
        s_axi_arready <= ~rd_req_fifo_full;
        rd_req_fifo_wren <= s_axi_arvalid & s_axi_arready;
    end
end

// 2. Pack Read Address Control Frame (per spec: {addr, len, burst, opcode})
assign rd_req_fifo_wdata = {{(64-CTRL_FRAME_W){1'b0}},
                            s_axi_araddr,    // 32bit
                            s_axi_arlen,     // 4bit
                            s_axi_arburst,   // 2bit
                            OP_RD_ADDR};     // 4bit opcode

// 3. AXI Read Data Channel (from Stream RX FIFO)
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_rvalid <= 1'b0;
        s_axi_rdata  <= '0;
        s_axi_rlast  <= 1'b0;
        s_axi_rresp  <= RESP_OKAY;
        rd_data_fifo_rden <= 1'b0;
    end else begin
        rd_data_fifo_rden <= ~rd_data_fifo_empty & ~s_axi_rvalid;
        if (rd_data_fifo_rden) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rdata  <= rd_data_fifo_rdata[63:0];
            s_axi_rlast  <= rd_data_fifo_rdata[64];
            s_axi_rresp  <= RESP_OKAY;
        end
        if (s_axi_rvalid & s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end
end

// ==========================================================================
// ======================== STREAM TX (MASTER INTERFACE) ====================
// ==========================================================================
// Transmit Write Frames + Read Requests to AXI-Stream
always @(posedge m_axis_aclk or negedge m_axis_aresetn) begin
    if (!m_axis_aresetn) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tdata  <= '0;
        m_axis_tkeep  <= 8'hff;
        m_axis_tlast  <= 1'b0;
        wr_frame_fifo_rden <= 1'b0;
        rd_req_fifo_rden  <= 1'b0;
    end else begin
        // Defaults
        m_axis_tvalid <= 1'b0;
        m_axis_tlast  <= 1'b0;
        wr_frame_fifo_rden <= 1'b0;
        rd_req_fifo_rden  <= 1'b0;

        // Priority: Transmit Write Frames first
        if (~wr_frame_fifo_empty) begin
            wr_frame_fifo_rden <= ~m_axis_tvalid & m_axis_tready;
            if (wr_frame_fifo_rden) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= wr_frame_fifo_rdata;
                m_axis_tkeep  <= (wr_frame_fifo_rdata[3:0] == OP_WR_ADDR) ? 8'hff : s_axi_wstrb;
                m_axis_tlast  <= (wr_frame_fifo_rdata[3:0] == OP_WR_DATA) & s_axi_wlast;
            end
        end
        // Transmit Read Requests
        else if (~rd_req_fifo_empty) begin
            rd_req_fifo_rden <= ~m_axis_tvalid & m_axis_tready;
            if (rd_req_fifo_rden) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= rd_req_fifo_rdata;
                m_axis_tkeep  <= 8'hff;
                m_axis_tlast  <= 1'b1;
            end
        end
    end
end

// ==========================================================================
// ======================== STREAM RX (SLAVE INTERFACE) =====================
// ==========================================================================
// Receive Read Data Frames from AXI-Stream & push to AXI Read FIFO
always @(posedge m_axis_aclk or negedge m_axis_aresetn) begin
    if (!m_axis_aresetn) begin
        s_axis_tready <= 1'b0;
        rd_data_fifo_wren <= 1'b0;
    end else begin
        s_axis_tready <= ~rd_data_fifo_full;
        rd_data_fifo_wren <= s_axis_tvalid & s_axis_tready & (s_axis_tdata[3:0] == OP_RD_DATA);

        // Pack Read Data: {tlast, 64bit data}
        if (rd_data_fifo_wren) begin
            rd_data_fifo_wdata = {s_axis_tlast, s_axis_tdata};
        end
    end
end

endmodule
```
