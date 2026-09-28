`timescale 1ns/1ps

// AXI4 行为级 RAM 模型（仿真专用）：单拍就绪/单事务缓存，
// 支持 INCR/FIXED、按 WSTRB 写入、范围外地址返回 SLVERR。
module rtds_axi_ram_model #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 5,
    parameter integer MEM_BYTES  = 4194304
) (
    input  wire                     aclk,    // AXI 时钟
    input  wire                     aresetn,    // AXI 低有效复位
    input  wire [ID_WIDTH-1:0]      s_axi_awid,    // 写地址通道 ID
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,    // 写起始字节地址
    input  wire [7:0]               s_axi_awlen,    // 写突发拍数减一
    input  wire [2:0]               s_axi_awsize,    // 写每拍字节数（3=8Byte）
    input  wire [1:0]               s_axi_awburst,    // 写突发类型
    input  wire                     s_axi_awvalid,    // 写地址有效
    output wire                     s_axi_awready,    // 写地址就绪
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,    // 写数据
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,    // 写字节使能
    input  wire                     s_axi_wlast,    // 写末拍标志
    input  wire                     s_axi_wvalid,    // 写数据有效
    output wire                     s_axi_wready,    // 写数据就绪
    output reg  [ID_WIDTH-1:0]      s_axi_bid,    // 写响应 ID
    output reg  [1:0]               s_axi_bresp,    // 写响应码
    output reg                      s_axi_bvalid,    // 写响应有效
    input  wire                     s_axi_bready,    // 写响应就绪
    input  wire [ID_WIDTH-1:0]      s_axi_arid,    // 读地址通道 ID
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,    // 读起始字节地址
    input  wire [7:0]               s_axi_arlen,    // 读突发拍数减一
    input  wire [2:0]               s_axi_arsize,    // 读每拍字节数
    input  wire [1:0]               s_axi_arburst,    // 读突发类型
    input  wire                     s_axi_arvalid,    // 读地址有效
    output wire                     s_axi_arready,    // 读地址就绪
    output reg  [ID_WIDTH-1:0]      s_axi_rid,    // 读响应 ID
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,    // 读数据
    output reg  [1:0]               s_axi_rresp,    // 读响应码
    output reg                      s_axi_rlast,    // 读末拍标志
    output reg                      s_axi_rvalid,    // 读数据有效
    input  wire                     s_axi_rready    // 读就绪
);
    localparam integer STRB_WIDTH = DATA_WIDTH / 8;    // 字节使能位宽（64bit=8）
    localparam integer WORDS = MEM_BYTES / STRB_WIDTH;    // 存储字数
    localparam integer BYTE_BITS = $clog2(STRB_WIDTH);    // 字内字节地址位宽（8Byte=3）
    localparam integer INDEX_BITS = $clog2(WORDS);    // 字索引位宽
    reg [DATA_WIDTH-1:0] mem [0:WORDS-1];    // 行为存储阵列

    reg aw_hold_valid;    // 已接受 AW 标志
    reg [ID_WIDTH-1:0] aw_hold_id;    // 锁存的写 ID
    reg [ADDR_WIDTH-1:0] aw_hold_addr;    // 锁存的写地址（INCR 时递增）
    reg [7:0] aw_beats_left;    // 剩余写拍计数
    reg [2:0] aw_hold_size;    // 锁存的每拍字节数
    reg [1:0] aw_hold_burst;    // 锁存的突发类型
    reg aw_error;    // 本写事务已检出协议错误

    reg w_hold_valid;    // 已接受 W 标志
    reg [DATA_WIDTH-1:0] w_hold_data;    // 锁存的写数据
    reg [STRB_WIDTH-1:0] w_hold_strb;    // 锁存的字节使能
    reg w_hold_last;    // 锁存的末拍标志

    wire aw_in_range = (aw_hold_addr < MEM_BYTES);    // AW 地址在存储范围内
    wire write_commit = aw_hold_valid && w_hold_valid && !s_axi_bvalid;    // AW/W 均就绪且 B 空闲时可提交
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_awready = aresetn && !aw_hold_valid && !s_axi_bvalid;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_wready  = aresetn && !w_hold_valid && !s_axi_bvalid;

    integer byte_index;    // 按字节写入循环变量

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

    reg read_active;    // 读事务进行中标志
    reg [ID_WIDTH-1:0] read_id;    // 锁存的读 ID
    reg [ADDR_WIDTH-1:0] read_addr;    // 锁存的读地址（INCR 时递增）
    reg [7:0] read_beats_left;    // 剩余读拍计数
    reg [2:0] read_size;    // 锁存的每拍字节数
    reg [1:0] read_burst;    // 锁存的突发类型
    reg read_error;    // 本读事务已检出协议错误

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
