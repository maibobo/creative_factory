# axi_ddr_bist

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\rtl\axi_ddr_bist.v`
- SHA-256: `84bb4dc5a1e14674efdbca28c968f68a9975833f0c9bfaa26592bfc66bb2b6da`
- Extractor: `text`
- Tags: `axi, bist, ddr4, rtl`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\rtl\axi_ddr_bist.v

```verilog
`timescale 1ns / 1ps

// AXI4 DDR 自检主控。
// 测试流程采用“全部写入、再全部回读”的方式，便于把写通路和读通路问题分开定位。
// 当前每次只发起一个 64-bit 单拍事务，不使用多 outstanding，也不依赖 AXI ID 重排。
module axi_ddr_bist #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4,
    parameter integer TEST_WORDS = 4096,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = {ADDR_WIDTH{1'b0}}
) (
    input  wire                      aclk,
    input  wire                      aresetn,
    input  wire                      start,

    output reg                       done,
    output reg                       pass,
    output reg                       fail,
    output reg  [31:0]               error_count,
    output reg  [ADDR_WIDTH-1:0]     first_error_addr,
    output reg  [DATA_WIDTH-1:0]     first_expected_data,
    output reg  [DATA_WIDTH-1:0]     first_actual_data,

    output wire [ID_WIDTH-1:0]       m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output wire [7:0]                m_axi_awlen,
    output wire [2:0]                m_axi_awsize,
    output wire [1:0]                m_axi_awburst,
    output wire [0:0]                m_axi_awlock,
    output wire [3:0]                m_axi_awcache,
    output wire [2:0]                m_axi_awprot,
    output wire [3:0]                m_axi_awqos,
    output reg                       m_axi_awvalid,
    input  wire                      m_axi_awready,

    output reg  [DATA_WIDTH-1:0]     m_axi_wdata,
    output wire [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output wire                      m_axi_wlast,
    output reg                       m_axi_wvalid,
    input  wire                      m_axi_wready,

    input  wire [ID_WIDTH-1:0]       m_axi_bid,
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output reg                       m_axi_bready,

    output wire [ID_WIDTH-1:0]       m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]     m_axi_araddr,
    output wire [7:0]                m_axi_arlen,
    output wire [2:0]                m_axi_arsize,
    output wire [1:0]                m_axi_arburst,
    output wire [0:0]                m_axi_arlock,
    output wire [3:0]                m_axi_arcache,
    output wire [2:0]                m_axi_arprot,
    output wire [3:0]                m_axi_arqos,
    output reg                       m_axi_arvalid,
    input  wire                      m_axi_arready,

    input  wire [ID_WIDTH-1:0]       m_axi_rid,
    input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rlast,
    input  wire                      m_axi_rvalid,
    output reg                       m_axi_rready
);

// 状态机把一次 AXI 写事务拆成地址/数据发送和写响应两个阶段；
// 读事务拆成读地址发送和读数据接收两个阶段。
localparam [2:0] ST_IDLE       = 3'd0;
localparam [2:0] ST_WRITE_SEND = 3'd1;
localparam [2:0] ST_WRITE_RESP = 3'd2;
localparam [2:0] ST_READ_ADDR  = 3'd3;
localparam [2:0] ST_READ_DATA  = 3'd4;
localparam [2:0] ST_DONE       = 3'd5;

reg [2:0] state;
reg [31:0] write_index;
reg [31:0] read_index;
// AXI4 允许 AW 与 W 通道独立握手。这两个标志用于记录某个通道是否已经完成，
// 防止把 AWREADY、WREADY 不同周期到达误判成事务未完成。
reg aw_sent;
reg w_sent;

// 统一定义五个 AXI 通道的有效握手事件，后续状态机只在 fire 为 1 时推进。
wire aw_fire = m_axi_awvalid && m_axi_awready;
wire w_fire  = m_axi_wvalid  && m_axi_wready;
wire b_fire  = m_axi_bvalid  && m_axi_bready;
wire ar_fire = m_axi_arvalid && m_axi_arready;
wire r_fire  = m_axi_rvalid  && m_axi_rready;

// 写阶段检查 BRESP；读阶段同时检查 RRESP、数据内容和单拍事务的 RLAST。
// 任意一项异常都会计入 error_count，并锁存第一次错误现场。
wire write_response_error = (m_axi_bresp != 2'b00);
wire read_response_error  = (m_axi_rresp != 2'b00);
wire read_data_error      = (m_axi_rdata != data_pattern(read_index));
wire read_protocol_error  = !m_axi_rlast;
wire read_error           = read_response_error || read_data_error || read_protocol_error;

// 64-bit 测试数据由“索引取反 + 原索引”组成，例如 index=1 时为
// 64'hFFFF_FFFE_0000_0001。该模式同时覆盖高低位差异并便于从波形反推地址。
function [DATA_WIDTH-1:0] data_pattern;
    input [31:0] index;
    begin
        data_pattern = {~index, index};
    end
endfunction

// 每个测试字占 DATA_WIDTH/8 字节，地址按数据总线宽度连续递增。
function [ADDR_WIDTH-1:0] word_address;
    input [31:0] index;
    begin
        word_address = BASE_ADDR + (index * (DATA_WIDTH/8));
    end
endfunction

// 当前方案固定使用 ID=0、INCR、单拍、全字节有效。虽然接口保留完整 AXI4 字段，
// BIST 只实现最小且容易调试的访问子集。
assign m_axi_awid    = {ID_WIDTH{1'b0}};
assign m_axi_awlen   = 8'd0;
assign m_axi_awsize  = $clog2(DATA_WIDTH/8);
assign m_axi_awburst = 2'b01;
assign m_axi_awlock  = 1'b0;
assign m_axi_awcache = 4'b0011;
assign m_axi_awprot  = 3'b000;
assign m_axi_awqos   = 4'b0000;

assign m_axi_wstrb   = {(DATA_WIDTH/8){1'b1}};
assign m_axi_wlast   = 1'b1;

assign m_axi_arid    = {ID_WIDTH{1'b0}};
assign m_axi_arlen   = 8'd0;
assign m_axi_arsize  = $clog2(DATA_WIDTH/8);
assign m_axi_arburst = 2'b01;
assign m_axi_arlock  = 1'b0;
assign m_axi_arcache = 4'b0011;
assign m_axi_arprot  = 3'b000;
assign m_axi_arqos   = 4'b0000;

// 主状态机和结果寄存器均工作在 MIG ui_clk 域，使用同步时序和低有效复位。
always @(posedge aclk) begin
    if (!aresetn) begin
        state               <= ST_IDLE;
        write_index         <= 32'd0;
        read_index          <= 32'd0;
        aw_sent             <= 1'b0;
        w_sent              <= 1'b0;
        done                <= 1'b0;
        pass                <= 1'b0;
        fail                <= 1'b0;
        error_count         <= 32'd0;
        first_error_addr    <= {ADDR_WIDTH{1'b0}};
        first_expected_data <= {DATA_WIDTH{1'b0}};
        first_actual_data   <= {DATA_WIDTH{1'b0}};
        m_axi_awaddr        <= {ADDR_WIDTH{1'b0}};
        m_axi_awvalid       <= 1'b0;
        m_axi_wdata         <= {DATA_WIDTH{1'b0}};
        m_axi_wvalid        <= 1'b0;
        m_axi_bready        <= 1'b0;
        m_axi_araddr        <= {ADDR_WIDTH{1'b0}};
        m_axi_arvalid       <= 1'b0;
        m_axi_rready        <= 1'b0;
    end else begin
        case (state)
            // 等待 start。启动时清空上次结果，并同时给出第一个 AW/W 请求。
            ST_IDLE: begin
                if (start) begin
                    write_index   <= 32'd0;
                    read_index    <= 32'd0;
                    aw_sent       <= 1'b0;
                    w_sent        <= 1'b0;
                    done          <= 1'b0;
                    pass          <= 1'b0;
                    fail          <= 1'b0;
                    error_count   <= 32'd0;
                    m_axi_awaddr  <= word_address(32'd0);
                    m_axi_wdata   <= data_pattern(32'd0);
                    m_axi_awvalid <= 1'b1;
                    m_axi_wvalid  <= 1'b1;
                    state         <= ST_WRITE_SEND;
                end
            end

            // 分别等待 AW、W 握手；两个通道都完成后才打开 BREADY。
            ST_WRITE_SEND: begin
                if (aw_fire) begin
                    m_axi_awvalid <= 1'b0;
                    aw_sent       <= 1'b1;
                end
                if (w_fire) begin
                    m_axi_wvalid <= 1'b0;
                    w_sent       <= 1'b1;
                end
                if ((aw_sent || aw_fire) && (w_sent || w_fire)) begin
                    m_axi_bready <= 1'b1;
                    state        <= ST_WRITE_RESP;
                end
            end

            // 接收写响应。若仍有测试字，准备下一地址和数据；否则切换到读阶段。
            ST_WRITE_RESP: begin
                if (b_fire) begin
                    m_axi_bready <= 1'b0;
                    if (write_response_error) begin
                        fail        <= 1'b1;
                        error_count <= error_count + 32'd1;
                        if (!fail) begin
                            first_error_addr    <= word_address(write_index);
                            first_expected_data <= data_pattern(write_index);
                            first_actual_data   <= {DATA_WIDTH{1'b0}};
                        end
                    end

                    if (write_index == TEST_WORDS-1) begin
                        read_index    <= 32'd0;
                        m_axi_araddr  <= word_address(32'd0);
                        m_axi_arvalid <= 1'b1;
                        state         <= ST_READ_ADDR;
                    end else begin
                        write_index   <= write_index + 32'd1;
                        m_axi_awaddr  <= word_address(write_index + 32'd1);
                        m_axi_wdata   <= data_pattern(write_index + 32'd1);
                        m_axi_awvalid <= 1'b1;
                        m_axi_wvalid  <= 1'b1;
                        aw_sent       <= 1'b0;
                        w_sent        <= 1'b0;
                        state         <= ST_WRITE_SEND;
                    end
                end
            end

            // 读地址握手后关闭 ARVALID，并打开 RREADY 等待返回数据。
            ST_READ_ADDR: begin
                if (ar_fire) begin
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready  <= 1'b1;
                    state         <= ST_READ_DATA;
                end
            end

            // 比较读响应、RLAST 和期望数据。最后一个测试字完成后锁存最终 PASS/FAIL。
            ST_READ_DATA: begin
                if (r_fire) begin
                    m_axi_rready <= 1'b0;
                    if (read_error) begin
                        fail        <= 1'b1;
                        error_count <= error_count + 32'd1;
                        if (!fail) begin
                            first_error_addr    <= word_address(read_index);
                            first_expected_data <= data_pattern(read_index);
                            first_actual_data   <= m_axi_rdata;
                        end
                    end

                    if (read_index == TEST_WORDS-1) begin
                        done  <= 1'b1;
                        pass  <= !(fail || read_error);
                        state <= ST_DONE;
                    end else begin
                        read_index    <= read_index + 32'd1;
                        m_axi_araddr  <= word_address(read_index + 32'd1);
                        m_axi_arvalid <= 1'b1;
                        state         <= ST_READ_ADDR;
                    end
                end
            end

            // 结果保持，直到系统复位。这样板上 LED 和 ILA 都能稳定观察测试结论。
            ST_DONE: begin
                done  <= 1'b1;
                state <= ST_DONE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end

endmodule
```
