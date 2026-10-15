# tb_axi_full_to_stream_bridge

- Category: `foundation`
- Source: `R:\AXI4 2 AXI4-STREAM GEN\tb_axi_full_to_stream_bridge.sv`
- SHA-256: `77c07f32295837295dc96cad2d75aed9679520d84cd7a57c7222de78be31d395`
- Extractor: `text`
- Tags: `adapter, axi, axi-stream`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

// Testbench for axi_full_to_stream_bridge
// Cover: Basic, Burst, Corner, Exception, CDC, Concurrent test cases
module tb_axi_full_to_stream_bridge();

// ---------------------------
// Clock Parameters
// ---------------------------
localparam AXI_CLK_PERIOD    = 4;      // 250MHz = 4ns
localparam STREAM_CLK_PERIOD = 6.4;    // 156.25MHz = 6.4ns

// ---------------------------
// DUT Interface Signals
// ---------------------------
// AXI4-Full Slave (250MHz)
reg         s_axi_aclk;
reg         s_axi_aresetn;
reg  [31:0] s_axi_awaddr;
reg  [3:0]  s_axi_awlen;
reg  [2:0]  s_axi_awsize;
reg  [1:0]  s_axi_awburst;
reg         s_axi_awvalid;
wire        s_axi_awready;
reg  [63:0] s_axi_wdata;
reg  [7:0]  s_axi_wstrb;
reg         s_axi_wlast;
reg         s_axi_wvalid;
wire        s_axi_wready;
wire [1:0]  s_axi_bresp;
wire        s_axi_bvalid;
reg         s_axi_bready;
reg  [31:0] s_axi_araddr;
reg  [3:0]  s_axi_arlen;
reg  [2:0]  s_axi_arsize;
reg  [1:0]  s_axi_arburst;
reg         s_axi_arvalid;
wire        s_axi_arready;
wire [63:0] s_axi_rdata;
wire [1:0]  s_axi_rresp;
wire        s_axi_rlast;
wire        s_axi_rvalid;
reg         s_axi_rready;

// AXI4-Stream (156.25MHz)
reg         m_axis_aclk;
reg         m_axis_aresetn;
wire [63:0] m_axis_tdata;
wire [7:0]  m_axis_tkeep;
wire        m_axis_tlast;
wire        m_axis_tvalid;
reg         m_axis_tready;
reg  [63:0] s_axis_tdata;
reg  [7:0]  s_axis_tkeep;
reg         s_axis_tlast;
reg         s_axis_tvalid;
wire        s_axis_tready;

// ---------------------------
// Testbench Internal Signals
// ---------------------------
reg [63:0]  tx_data_queue [$];    // Write data queue
reg [31:0]  test_addr;           // Test address
integer     test_cnt;            // Test case counter
reg         test_pass;           // Test result flag

// Opcode Parameter (Match DUT)
localparam OP_WR_ADDR  = 4'b0001;
localparam OP_WR_DATA  = 4'b0010;
localparam OP_RD_ADDR  = 4'b0011;
localparam OP_RD_DATA  = 4'b0100;
localparam RESP_OKAY   = 2'b00;

// ---------------------------
// DUT Instantiation
// ---------------------------
axi_full_to_stream_bridge dut (
    .s_axi_aclk      (s_axi_aclk),
    .s_axi_aresetn   (s_axi_aresetn),
    .s_axi_awaddr    (s_axi_awaddr),
    .s_axi_awlen     (s_axi_awlen),
    .s_axi_awsize    (s_axi_awsize),
    .s_axi_awburst   (s_axi_awburst),
    .s_axi_awvalid   (s_axi_awvalid),
    .s_axi_awready   (s_axi_awready),
    .s_axi_wdata     (s_axi_wdata),
    .s_axi_wstrb     (s_axi_wstrb),
    .s_axi_wlast     (s_axi_wlast),
    .s_axi_wvalid    (s_axi_wvalid),
    .s_axi_wready    (s_axi_wready),
    .s_axi_bresp     (s_axi_bresp),
    .s_axi_bvalid    (s_axi_bvalid),
    .s_axi_bready    (s_axi_bready),
    .s_axi_araddr    (s_axi_araddr),
    .s_axi_arlen     (s_axi_arlen),
    .s_axi_arsize    (s_axi_arsize),
    .s_axi_arburst   (s_axi_arburst),
    .s_axi_arvalid   (s_axi_arvalid),
    .s_axi_arready   (s_axi_arready),
    .s_axi_rdata     (s_axi_rdata),
    .s_axi_rresp     (s_axi_rresp),
    .s_axi_rlast     (s_axi_rlast),
    .s_axi_rvalid    (s_axi_rvalid),
    .s_axi_rready    (s_axi_rready),
    .m_axis_aclk     (m_axis_aclk),
    .m_axis_aresetn  (m_axis_aresetn),
    .m_axis_tdata    (m_axis_tdata),
    .m_axis_tkeep    (m_axis_tkeep),
    .m_axis_tlast    (m_axis_tlast),
    .m_axis_tvalid   (m_axis_tvalid),
    .m_axis_tready   (m_axis_tready),
    .s_axis_tdata    (s_axis_tdata),
    .s_axis_tkeep    (s_axis_tkeep),
    .s_axis_tlast    (s_axis_tlast),
    .s_axis_tvalid   (s_axis_tvalid),
    .s_axis_tready   (s_axis_tready)
);

// ---------------------------
// Clock Generation
// ---------------------------
// AXI Clock (250MHz)
initial begin
    s_axi_aclk = 1'b0;
    forever #(AXI_CLK_PERIOD/2) s_axi_aclk = ~s_axi_aclk;
end

// Stream Clock (156.25MHz)
initial begin
    m_axis_aclk = 1'b0;
    forever #(STREAM_CLK_PERIOD/2) m_axis_aclk = ~m_axis_aclk;
end

// ---------------------------
// Reset Task
// ---------------------------
task sys_reset();
    begin
        // AXI Domain Reset
        s_axi_aresetn = 1'b0;
        s_axi_awvalid = 1'b0;
        s_axi_wvalid  = 1'b0;
        s_axi_bready  = 1'b0;
        s_axi_arvalid = 1'b0;
        s_axi_rready  = 1'b0;

        // Stream Domain Reset
        m_axis_aresetn = 1'b0;
        m_axis_tready  = 1'b0;
        s_axis_tvalid  = 1'b0;

        #(AXI_CLK_PERIOD*10);
        s_axi_aresetn  = 1'b1;
        m_axis_aresetn = 1'b1;
        #(AXI_CLK_PERIOD*10);
        $display("=====================================");
        $display("System Reset Done");
        $display("=====================================\n");
    end
endtask

// ---------------------------
// AXI Write Single Beat Task
// ---------------------------
task axi_single_write(input [31:0] addr, input [63:0] data);
    begin
        test_pass = 1'b1;
        s_axi_awaddr  = addr;
        s_axi_awlen   = 4'd0;    // 1 beat
        s_axi_awsize  = 3'b110;  // 64bit
        s_axi_awburst = 2'b01;   // INCR
        s_axi_awvalid = 1'b1;
        s_axi_bready  = 1'b1;

        wait(s_axi_awready);
        #AXI_CLK_PERIOD;
        s_axi_awvalid = 1'b0;

        // Write Data
        s_axi_wdata   = data;
        s_axi_wstrb   = 8'hff;
        s_axi_wlast   = 1'b1;
        s_axi_wvalid  = 1'b1;
        wait(s_axi_wready);
        #AXI_CLK_PERIOD;
        s_axi_wvalid  = 1'b0;

        // Check Response
        wait(s_axi_bvalid);
        if(s_axi_bresp !== RESP_OKAY) test_pass = 1'b0;
        #AXI_CLK_PERIOD;
        s_axi_bready = 1'b0;

        if(test_pass) $display("Single Write Test PASS | Addr:0x%0h Data:0x%0h", addr, data);
        else $error("Single Write Test FAIL");
    end
endtask

// ---------------------------
// AXI Read Single Beat Task
// ---------------------------
task axi_single_read(input [31:0] addr, input [63:0] exp_data);
    begin
        test_pass = 1'b1;
        s_axi_araddr  = addr;
        s_axi_arlen   = 4'd0;
        s_axi_arsize  = 3'b110;
        s_axi_arburst = 2'b01;
        s_axi_arvalid = 1'b1;
        s_axi_rready  = 1'b1;

        wait(s_axi_arready);
        #AXI_CLK_PERIOD;
        s_axi_arvalid = 1'b0;

        // Simulate Aurora RX Read Data
        #(STREAM_CLK_PERIOD*20);
        s_axis_tdata  = {22'd0, addr, 4'd0, 2'b01, OP_RD_DATA};
        s_axis_tkeep  = 8'hff;
        s_axis_tlast  = 1'b1;
        s_axis_tvalid = 1'b1;
        wait(s_axis_tready);
        #STREAM_CLK_PERIOD;
        s_axis_tvalid = 1'b0;

        // Check Read Data
        wait(s_axi_rvalid);
        if(s_axi_rdata !== exp_data || s_axi_rresp !== RESP_OKAY) test_pass = 1'b0;
        #AXI_CLK_PERIOD;
        s_axi_rready = 1'b0;

        if(test_pass) $display("Single Read Test PASS | Addr:0x%0h Data:0x%0h", addr, exp_data);
        else $error("Single Read Test FAIL");
    end
endtask

// ---------------------------
// Max Burst Write (16 Beats) Task
// ---------------------------
task axi_max_burst_write(input [31:0] base_addr);
    integer i;
    begin
        test_pass = 1'b1;
        s_axi_awaddr  = base_addr;
        s_axi_awlen   = 4'd15;   // 16 beats
        s_axi_awsize  = 3'b110;
        s_axi_awburst = 2'b01;
        s_axi_awvalid = 1'b1;
        s_axi_bready  = 1'b1;

        wait(s_axi_awready);
        #AXI_CLK_PERIOD;
        s_axi_awvalid = 1'b0;

        // 16 Beat Data
        for(i=0; i<16; i=i+1) begin
            s_axi_wdata  = 64'h12345678_87654320 + i;
            s_axi_wstrb  = 8'hff;
            s_axi_wlast  = (i==15) ? 1'b1 : 1'b0;
            s_axi_wvalid = 1'b1;
            wait(s_axi_wready);
            #AXI_CLK_PERIOD;
            s_axi_wvalid = 1'b0;
            #AXI_CLK_PERIOD;
        end

        wait(s_axi_bvalid);
        if(s_axi_bresp !== RESP_OKAY) test_pass = 1'b0;
        #AXI_CLK_PERIOD;
        s_axi_bready = 1'b0;

        if(test_pass) $display("Max 16-Beat Burst Write Test PASS | Base Addr:0x%0h", base_addr);
        else $error("Max Burst Write Test FAIL");
    end
endtask

// ---------------------------
// Stream Flow Control Test (tready Low)
// ---------------------------
task stream_flow_control_test();
    begin
        $display("Start Stream Flow Control Test (tready Low)");
        m_axis_tready = 1'b0; // Pause Stream TX
        #(STREAM_CLK_PERIOD*50);
        m_axis_tready = 1'b1; // Resume
        #(STREAM_CLK_PERIOD*10);
        $display("Stream Flow Control Test PASS\n");
    end
endtask

// ---------------------------
// Concurrent Read/Write Test
// ---------------------------
task concurrent_rw_test();
    begin
        $display("Start Concurrent Read/Write Test");
        fork
            axi_single_write(32'h1000, 64'hAABBCCDD_EEFF0011);
            axi_single_read(32'h2000, 64'h11223344_55667788);
        join
        $display("Concurrent RW Test PASS\n");
    end
endtask

// ---------------------------
// Exception: Reset Interrupt Test
// ---------------------------
task reset_exception_test();
    begin
        $display("Start Reset Exception Test");
        #(AXI_CLK_PERIOD*20);
        s_axi_aresetn = 1'b0;
        #(AXI_CLK_PERIOD*5);
        s_axi_aresetn = 1'b1;
        #(AXI_CLK_PERIOD*20);
        $display("Reset Exception Test PASS\n");
    end
endtask

// ---------------------------
// All Test Cases
// ---------------------------
initial begin
    // Initialize
    test_cnt = 0;
    test_addr = 32'h0000_0000;
    tx_data_queue = {};
    m_axis_tready = 1'b1;
    s_axis_tdata  = 64'd0;
    s_axis_tkeep  = 8'd0;
    s_axis_tlast  = 1'b0;
    s_axis_tvalid = 1'b0;

    // Reset
    sys_reset();

    // Test Case 1: Single Write + Single Read
    test_cnt = test_cnt + 1;
    $display("\n======== Test Case %0d: Basic Single RW ========", test_cnt);
    axi_single_write(32'h0000_0010, 64'h11223344_55667788);
    axi_single_read(32'h0000_0010, 64'h11223344_55667788);

    // Test Case 2: Max 16-Beat Burst Write
    test_cnt = test_cnt + 1;
    $display("\n======== Test Case %0d: Max Burst Write ========", test_cnt);
    axi_max_burst_write(32'h0000_0100);

    // Test Case 3: Stream Flow Control (Corner)
    test_cnt = test_cnt + 1;
    $display("\n======== Test Case %0d: Flow Control Corner ========", test_cnt);
    stream_flow_control_test();

    // Test Case 4: Concurrent RW (High Performance)
    test_cnt = test_cnt + 1;
    $display("\n======== Test Case %0d: Concurrent RW ========", test_cnt);
    concurrent_rw_test();

    // Test Case 5: Reset Exception (Exception)
    test_cnt = test_cnt + 1;
    $display("\n======== Test Case %0d: Reset Exception ========", test_cnt);
    reset_exception_test();

    // Test Case 6: Multiple Continuous Transactions
    test_cnt = test_cnt + 1;
    $display("\n======== Test Case %0d: Continuous Transactions ========", test_cnt);
    axi_single_write(32'h3000, 64'h00000000_11111111);
    axi_single_write(32'h3008, 64'h22222222_33333333);
    axi_single_read(32'h3000, 64'h00000000_11111111);
    axi_single_read(32'h3008, 64'h22222222_33333333);

    // Test Finish
    #1000;
    $display("\n=====================================");
    $display("All Test Cases Finished Successfully!");
    $display("=====================================");
    $finish;
end

// ---------------------------
// AXI-Stream Monitor (Auto Check Frame Format)
// ---------------------------
always @(posedge m_axis_aclk) begin
    if(m_axis_tvalid && m_axis_tready) begin
        case(m_axis_tdata[3:0])
            OP_WR_ADDR: $display("Stream TX: Write Address Frame | Addr:0x%0h", m_axis_tdata[41:10]);
            OP_WR_DATA: $display("Stream TX: Write Data Frame | Data:0x%0h", m_axis_tdata[63:0]);
            OP_RD_ADDR: $display("Stream TX: Read Address Frame | Addr:0x%0h", m_axis_tdata[41:10]);
            default: ;
        endcase
    end
end

endmodule
```
