# nophae_ctrl_reg_stub

- Category: `cross_ip`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\stubs\nophae_ctrl_reg_stub.sv`
- SHA-256: `21877590d2c9ebd381c29088cf87aa5a2cf8a7118cc7305a2f9aec9c52c5dcff`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps

// NoPHAE s_axi_ctrl的最小行为模型，仅覆盖现有Vitis源码和
// nophae_dma_backend实际访问的寄存器。它不模拟PCIe、NVMe队列或SSD，
// 只用于证明AXI-Lite握手、寄存器顺序、DDR地址偏移和长度单位。
module nophae_ctrl_reg_stub #(
    parameter integer CTRL_ADDR_WIDTH = 40,
    parameter [CTRL_ADDR_WIDTH-1:0] CTRL_BASE_ADDR = 40'h00_1000_0000,
    parameter integer DMA_COMPLETE_LATENCY = 4,
    parameter integer FLUSH_COMPLETE_LATENCY = 4
) (
    input  wire                         clk,
    input  wire                         rst_n,

    input  wire [CTRL_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [2:0]                   s_axi_awprot,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready,
    input  wire [31:0]                  s_axi_wdata,
    input  wire [3:0]                   s_axi_wstrb,
    input  wire                         s_axi_wvalid,
    output wire                         s_axi_wready,
    output reg  [1:0]                   s_axi_bresp,
    output reg                          s_axi_bvalid,
    input  wire                         s_axi_bready,
    input  wire [CTRL_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [2:0]                   s_axi_arprot,
    input  wire                         s_axi_arvalid,
    output wire                         s_axi_arready,
    output reg  [31:0]                  s_axi_rdata,
    output reg  [1:0]                   s_axi_rresp,
    output reg                          s_axi_rvalid,
    input  wire                         s_axi_rready,

    input  wire                         stall_all,
    input  wire                         force_slverr,
    input  wire                         dma_ready_value,
    input  wire                         dma_never_done,
    input  wire                         flush_never_done,

    output reg  [31:0]                  dma_start_count,
    output reg  [31:0]                  flush_start_count,
    output reg  [31:0]                  last_dma_direction,
    output reg  [31:0]                  last_dma_src,
    output reg  [31:0]                  last_dma_dst,
    output reg  [31:0]                  last_dma_lba_count,
    output reg  [31:0]                  last_cmd_code,
    output reg  [31:0]                  debug_lock_value,
    output reg  [31:0]                  command_count
);

    localparam [11:0] OFS_DEBUG_LOCK = 12'h008;
    localparam [11:0] OFS_DMA_TYPE   = 12'h044;
    localparam [11:0] OFS_DMA_LEN    = 12'h048;
    localparam [11:0] OFS_DMA_SRC    = 12'h04C;
    localparam [11:0] OFS_DMA_DST    = 12'h050;
    localparam [11:0] OFS_DMA_READY  = 12'h054;
    localparam [11:0] OFS_CMD_CODE   = 12'h060;
    localparam [11:0] OFS_CMD_PRP1   = 12'h06C;
    localparam [11:0] OFS_CMD_PRP2   = 12'h074;
    localparam [11:0] OFS_CMD_DW10   = 12'h078;
    localparam [11:0] OFS_CMD_DW11   = 12'h07C;
    localparam [11:0] OFS_CMD_DW12   = 12'h080;
    localparam [11:0] OFS_CMD_DW13   = 12'h084;
    localparam [11:0] OFS_CMD_WR     = 12'h08C;
    localparam [11:0] OFS_CMD_CCNT   = 12'h0C0;
    localparam [11:0] OFS_DMA_DONE   = 12'h0C8;

    reg aw_hold_valid;
    reg [CTRL_ADDR_WIDTH-1:0] aw_hold_addr;
    reg w_hold_valid;
    reg [31:0] w_hold_data;
    reg [3:0] w_hold_strb;

    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid && s_axi_wready;
    wire have_aw = aw_hold_valid || aw_fire;
    wire have_w  = w_hold_valid || w_fire;
    wire write_commit = !s_axi_bvalid && have_aw && have_w;
    wire [CTRL_ADDR_WIDTH-1:0] write_addr =
        aw_hold_valid ? aw_hold_addr : s_axi_awaddr;
    wire [31:0] write_data =
        w_hold_valid ? w_hold_data : s_axi_wdata;
    wire [3:0] write_strb =
        w_hold_valid ? w_hold_strb : s_axi_wstrb;
    wire [11:0] write_offset = write_addr[11:0];

    assign s_axi_awready = !stall_all && !aw_hold_valid && !s_axi_bvalid;
    assign s_axi_wready  = !stall_all && !w_hold_valid && !s_axi_bvalid;
    assign s_axi_arready = !stall_all && !s_axi_rvalid;

    function automatic [31:0] merge_wstrb;
        input [31:0] previous;
        input [31:0] update;
        input [3:0] strobe;
        integer byte_index;
        begin
            merge_wstrb = previous;
            for (byte_index = 0; byte_index < 4;
                 byte_index = byte_index + 1)
                if (strobe[byte_index])
                    merge_wstrb[byte_index*8 +: 8] =
                        update[byte_index*8 +: 8];
        end
    endfunction

    reg [31:0] dma_src_reg;
    reg [31:0] dma_dst_reg;
    reg [31:0] dma_len_reg;
    reg [31:0] dma_done_reg;
    reg [31:0] cmd_prp1_reg;
    reg [31:0] cmd_prp2_reg;
    reg [31:0] cmd_dw10_reg;
    reg [31:0] cmd_dw11_reg;
    reg [31:0] cmd_dw12_reg;
    reg [31:0] cmd_dw13_reg;
    reg [31:0] dma_countdown;
    reg [31:0] flush_countdown;

    always @(posedge clk) begin
        if (!rst_n) begin
            aw_hold_valid       <= 1'b0;
            aw_hold_addr        <= {CTRL_ADDR_WIDTH{1'b0}};
            w_hold_valid        <= 1'b0;
            w_hold_data         <= 32'd0;
            w_hold_strb         <= 4'd0;
            s_axi_bresp         <= 2'b00;
            s_axi_bvalid        <= 1'b0;
            s_axi_rdata         <= 32'd0;
            s_axi_rresp         <= 2'b00;
            s_axi_rvalid        <= 1'b0;
            dma_src_reg         <= 32'd0;
            dma_dst_reg         <= 32'd0;
            dma_len_reg         <= 32'd0;
            dma_done_reg        <= 32'd0;
            cmd_prp1_reg        <= 32'd0;
            cmd_prp2_reg        <= 32'd0;
            cmd_dw10_reg        <= 32'd0;
            cmd_dw11_reg        <= 32'd0;
            cmd_dw12_reg        <= 32'd0;
            cmd_dw13_reg        <= 32'd0;
            dma_countdown       <= 32'd0;
            flush_countdown     <= 32'd0;
            dma_start_count     <= 32'd0;
            flush_start_count   <= 32'd0;
            last_dma_direction  <= 32'd0;
            last_dma_src        <= 32'd0;
            last_dma_dst        <= 32'd0;
            last_dma_lba_count  <= 32'd0;
            last_cmd_code       <= 32'd0;
            debug_lock_value    <= 32'd0;
            command_count       <= 32'd0;
        end else begin
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (aw_fire)
                aw_hold_addr <= s_axi_awaddr;
            if (w_fire) begin
                w_hold_data <= s_axi_wdata;
                w_hold_strb <= s_axi_wstrb;
            end

            if (write_commit) begin
                aw_hold_valid <= 1'b0;
                w_hold_valid  <= 1'b0;
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= force_slverr ? 2'b10 : 2'b00;
                if (!force_slverr) begin
                    case (write_offset)
                        OFS_DEBUG_LOCK:
                            debug_lock_value <= merge_wstrb(
                                debug_lock_value, write_data, write_strb);
                        OFS_DMA_SRC:
                            dma_src_reg <= merge_wstrb(
                                dma_src_reg, write_data, write_strb);
                        OFS_DMA_DST:
                            dma_dst_reg <= merge_wstrb(
                                dma_dst_reg, write_data, write_strb);
                        OFS_DMA_LEN:
                            dma_len_reg <= merge_wstrb(
                                dma_len_reg, write_data, write_strb);
                        OFS_DMA_TYPE: begin
                            last_dma_direction <= write_data;
                            last_dma_src       <= dma_src_reg;
                            last_dma_dst       <= dma_dst_reg;
                            last_dma_lba_count <= dma_len_reg;
                            dma_start_count    <= dma_start_count + 1'b1;
                            dma_done_reg       <= 32'd0;
                            dma_countdown      <= DMA_COMPLETE_LATENCY;
                        end
                        OFS_CMD_CODE:
                            last_cmd_code <= merge_wstrb(
                                last_cmd_code, write_data, write_strb);
                        OFS_CMD_PRP1:
                            cmd_prp1_reg <= merge_wstrb(
                                cmd_prp1_reg, write_data, write_strb);
                        OFS_CMD_PRP2:
                            cmd_prp2_reg <= merge_wstrb(
                                cmd_prp2_reg, write_data, write_strb);
                        OFS_CMD_DW10:
                            cmd_dw10_reg <= merge_wstrb(
                                cmd_dw10_reg, write_data, write_strb);
                        OFS_CMD_DW11:
                            cmd_dw11_reg <= merge_wstrb(
                                cmd_dw11_reg, write_data, write_strb);
                        OFS_CMD_DW12:
                            cmd_dw12_reg <= merge_wstrb(
                                cmd_dw12_reg, write_data, write_strb);
                        OFS_CMD_DW13:
                            cmd_dw13_reg <= merge_wstrb(
                                cmd_dw13_reg, write_data, write_strb);
                        OFS_CMD_WR: begin
                            if ((write_data[0] == 1'b1) &&
                                (last_cmd_code == 32'h0101_0000)) begin
                                flush_start_count <=
                                    flush_start_count + 1'b1;
                                flush_countdown <= FLUSH_COMPLETE_LATENCY;
                            end
                        end
                        default: begin end
                    endcase
                end
            end else begin
                if (aw_fire)
                    aw_hold_valid <= 1'b1;
                if (w_fire)
                    w_hold_valid <= 1'b1;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= force_slverr ? 2'b10 : 2'b00;
                case (s_axi_araddr[11:0])
                    OFS_DEBUG_LOCK: s_axi_rdata <= debug_lock_value;
                    OFS_DMA_TYPE:   s_axi_rdata <= last_dma_direction;
                    OFS_DMA_LEN:    s_axi_rdata <= dma_len_reg;
                    OFS_DMA_SRC:    s_axi_rdata <= dma_src_reg;
                    OFS_DMA_DST:    s_axi_rdata <= dma_dst_reg;
                    OFS_DMA_READY:  s_axi_rdata <=
                        dma_ready_value ? 32'd1 : 32'd0;
                    OFS_CMD_CODE:   s_axi_rdata <= last_cmd_code;
                    OFS_CMD_PRP1:   s_axi_rdata <= cmd_prp1_reg;
                    OFS_CMD_PRP2:   s_axi_rdata <= cmd_prp2_reg;
                    OFS_CMD_DW10:   s_axi_rdata <= cmd_dw10_reg;
                    OFS_CMD_DW11:   s_axi_rdata <= cmd_dw11_reg;
                    OFS_CMD_DW12:   s_axi_rdata <= cmd_dw12_reg;
                    OFS_CMD_DW13:   s_axi_rdata <= cmd_dw13_reg;
                    OFS_CMD_CCNT:   s_axi_rdata <= command_count;
                    OFS_DMA_DONE:   s_axi_rdata <= dma_done_reg;
                    default:        s_axi_rdata <= 32'd0;
                endcase
            end

            if (dma_countdown != 0) begin
                dma_countdown <= dma_countdown - 1'b1;
                if ((dma_countdown == 1) && !dma_never_done)
                    dma_done_reg <= 32'd1;
            end
            if (flush_countdown != 0) begin
                flush_countdown <= flush_countdown - 1'b1;
                if ((flush_countdown == 1) && !flush_never_done)
                    command_count <= command_count + 1'b1;
            end
        end
    end

    initial begin
        if (DMA_COMPLETE_LATENCY < 1)
            $error("DMA_COMPLETE_LATENCY must be at least 1");
        if (FLUSH_COMPLETE_LATENCY < 1)
            $error("FLUSH_COMPLETE_LATENCY must be at least 1");
    end

    wire unused = &{1'b0, s_axi_awprot, s_axi_arprot,
                    CTRL_BASE_ADDR[0]};

endmodule
```
