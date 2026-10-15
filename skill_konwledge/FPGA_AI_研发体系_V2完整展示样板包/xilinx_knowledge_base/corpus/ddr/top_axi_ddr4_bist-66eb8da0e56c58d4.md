# top_axi_ddr4_bist

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\rtl\top_axi_ddr4_bist.v`
- SHA-256: `66eb8da0e56c58d4a282c01fb97a59c788501a2f2dc802e81f8f984fb9799895`
- Extractor: `text`
- Tags: `axi, bist, ddr4, rtl`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\rtl\top_axi_ddr4_bist.v

```verilog
`timescale 1ns / 1ps

// KU040 DDR4 最小上板验证顶层。
// 本模块只保留 MIG、一个 AXI4 BIST 主控和 LED 状态指示，不引入 MicroBlaze、DMA、
// FIFO 或视频链路，用于缩小 DDR 校准及基础读写问题的定位范围。
module top_axi_ddr4_bist #(
    parameter integer TEST_WORDS = 4096
) (
    input  wire         sys_clk_p,
    input  wire         sys_clk_n,
    input  wire         sys_rst_n,

    output wire         c0_ddr4_act_n,
    output wire [16:0]  c0_ddr4_adr,
    output wire [1:0]   c0_ddr4_ba,
    output wire [0:0]   c0_ddr4_bg,
    output wire [0:0]   c0_ddr4_cke,
    output wire [0:0]   c0_ddr4_odt,
    output wire [0:0]   c0_ddr4_cs_n,
    output wire [0:0]   c0_ddr4_ck_t,
    output wire [0:0]   c0_ddr4_ck_c,
    output wire         c0_ddr4_reset_n,
    inout  wire [7:0]   c0_ddr4_dm_dbi_n,
    inout  wire [63:0]  c0_ddr4_dq,
    inout  wire [7:0]   c0_ddr4_dqs_c,
    inout  wire [7:0]   c0_ddr4_dqs_t,

    output wire [1:0]   led
);

// MIG 用户侧采用 32-bit 地址、64-bit 数据和 4-bit ID。
// 4096 个 64-bit 测试字覆盖从 0 地址开始的 32 KiB 空间。
localparam integer AXI_ADDR_WIDTH = 32;
localparam integer AXI_DATA_WIDTH = 64;
localparam integer AXI_ID_WIDTH   = 4;

// MIG 输出的校准完成、用户时钟和同步复位共同决定 BIST 何时可以访问 DDR。
(* mark_debug = "true" *) wire init_calib_complete;
wire ui_clk;
wire ui_clk_sync_rst;
wire axi_aresetn;
reg [1:0] axi_reset_pipe = 2'b00;

// BIST 与 MIG AXI Slave 之间的五通道直连信号。
wire [AXI_ID_WIDTH-1:0]   axi_awid;
wire [AXI_ADDR_WIDTH-1:0] axi_awaddr;
wire [7:0]                axi_awlen;
wire [2:0]                axi_awsize;
wire [1:0]                axi_awburst;
wire [0:0]                axi_awlock;
wire [3:0]                axi_awcache;
wire [2:0]                axi_awprot;
wire [3:0]                axi_awqos;
wire                      axi_awvalid;
wire                      axi_awready;
wire [AXI_DATA_WIDTH-1:0] axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb;
wire                      axi_wlast;
wire                      axi_wvalid;
wire                      axi_wready;
wire [AXI_ID_WIDTH-1:0]   axi_bid;
wire [1:0]                axi_bresp;
wire                      axi_bvalid;
wire                      axi_bready;
wire [AXI_ID_WIDTH-1:0]   axi_arid;
wire [AXI_ADDR_WIDTH-1:0] axi_araddr;
wire [7:0]                axi_arlen;
wire [2:0]                axi_arsize;
wire [1:0]                axi_arburst;
wire [0:0]                axi_arlock;
wire [3:0]                axi_arcache;
wire [2:0]                axi_arprot;
wire [3:0]                axi_arqos;
wire                      axi_arvalid;
wire                      axi_arready;
wire [AXI_ID_WIDTH-1:0]   axi_rid;
wire [AXI_DATA_WIDTH-1:0] axi_rdata;
wire [1:0]                axi_rresp;
wire                      axi_rlast;
wire                      axi_rvalid;
wire                      axi_rready;

// 关键结果加 mark_debug，综合实现后可按需插入 ILA 或在网表中保留观察点。
(* mark_debug = "true" *) wire bist_done;
(* mark_debug = "true" *) wire bist_pass;
(* mark_debug = "true" *) wire bist_fail;
(* mark_debug = "true" *) wire [31:0] bist_error_count;
(* mark_debug = "true" *) wire [AXI_ADDR_WIDTH-1:0] first_error_addr;
(* mark_debug = "true" *) wire [AXI_DATA_WIDTH-1:0] first_expected_data;
(* mark_debug = "true" *) wire [AXI_DATA_WIDTH-1:0] first_actual_data;

// 状态计数器只用于生成肉眼可分辨的 LED 闪烁频率，不参与 BIST 判定。
reg [27:0] status_counter = 28'd0;

// 校准完成后再延迟两个 ui_clk 周期释放 AXI 复位，避免校准状态变化直接驱动主控。
always @(posedge ui_clk) begin
    if (ui_clk_sync_rst || !init_calib_complete)
        axi_reset_pipe <= 2'b00;
    else
        axi_reset_pipe <= {axi_reset_pipe[0], 1'b1};
end

assign axi_aresetn = axi_reset_pipe[1];

always @(posedge ui_clk) begin
    if (ui_clk_sync_rst)
        status_counter <= 28'd0;
    else
        status_counter <= status_counter + 28'd1;
end

// LED0：校准中闪烁，校准完成常亮。
// LED1：测试进行中慢闪，PASS 常亮，FAIL 快闪。
assign led[0] = init_calib_complete ? 1'b1 : status_counter[25];
assign led[1] = bist_fail ? status_counter[23] :
                bist_done ? bist_pass :
                            status_counter[25];

// BIST 在 init_calib_complete 拉高后启动。start 即使持续为高也只会执行一次，
// 因为 BIST 完成后停在 ST_DONE，必须复位后才能重新开始。
axi_ddr_bist #(
    .ADDR_WIDTH (AXI_ADDR_WIDTH),
    .DATA_WIDTH (AXI_DATA_WIDTH),
    .ID_WIDTH   (AXI_ID_WIDTH),
    .TEST_WORDS (TEST_WORDS),
    .BASE_ADDR  (32'h0000_0000)
) u_axi_ddr_bist (
    .aclk                (ui_clk),
    .aresetn             (axi_aresetn),
    .start               (init_calib_complete),
    .done                (bist_done),
    .pass                (bist_pass),
    .fail                (bist_fail),
    .error_count         (bist_error_count),
    .first_error_addr    (first_error_addr),
    .first_expected_data (first_expected_data),
    .first_actual_data   (first_actual_data),
    .m_axi_awid          (axi_awid),
    .m_axi_awaddr        (axi_awaddr),
    .m_axi_awlen         (axi_awlen),
    .m_axi_awsize        (axi_awsize),
    .m_axi_awburst       (axi_awburst),
    .m_axi_awlock        (axi_awlock),
    .m_axi_awcache       (axi_awcache),
    .m_axi_awprot        (axi_awprot),
    .m_axi_awqos         (axi_awqos),
    .m_axi_awvalid       (axi_awvalid),
    .m_axi_awready       (axi_awready),
    .m_axi_wdata         (axi_wdata),
    .m_axi_wstrb         (axi_wstrb),
    .m_axi_wlast         (axi_wlast),
    .m_axi_wvalid        (axi_wvalid),
    .m_axi_wready        (axi_wready),
    .m_axi_bid           (axi_bid),
    .m_axi_bresp         (axi_bresp),
    .m_axi_bvalid        (axi_bvalid),
    .m_axi_bready        (axi_bready),
    .m_axi_arid          (axi_arid),
    .m_axi_araddr        (axi_araddr),
    .m_axi_arlen         (axi_arlen),
    .m_axi_arsize        (axi_arsize),
    .m_axi_arburst       (axi_arburst),
    .m_axi_arlock        (axi_arlock),
    .m_axi_arcache       (axi_arcache),
    .m_axi_arprot        (axi_arprot),
    .m_axi_arqos         (axi_arqos),
    .m_axi_arvalid       (axi_arvalid),
    .m_axi_arready       (axi_arready),
    .m_axi_rid           (axi_rid),
    .m_axi_rdata         (axi_rdata),
    .m_axi_rresp         (axi_rresp),
    .m_axi_rlast         (axi_rlast),
    .m_axi_rvalid        (axi_rvalid),
    .m_axi_rready        (axi_rready)
);

// Vivado 2020.2 生成的 DDR4 MIG：物理侧连接板上 DDR4，用户侧暴露 AXI4 Slave。
// BIST 与 MIG 使用同一个 ui_clk/axi_aresetn 时钟复位域，不需要额外 CDC。
ddr4_axi_0 u_ddr4_axi_0 (
    .c0_init_calib_complete    (init_calib_complete),
    .dbg_clk                   (),
    .c0_sys_clk_p              (sys_clk_p),
    .c0_sys_clk_n              (sys_clk_n),
    .dbg_bus                   (),
    .c0_ddr4_adr               (c0_ddr4_adr),
    .c0_ddr4_ba                (c0_ddr4_ba),
    .c0_ddr4_cke               (c0_ddr4_cke),
    .c0_ddr4_cs_n              (c0_ddr4_cs_n),
    .c0_ddr4_dm_dbi_n          (c0_ddr4_dm_dbi_n),
    .c0_ddr4_dq                (c0_ddr4_dq),
    .c0_ddr4_dqs_c             (c0_ddr4_dqs_c),
    .c0_ddr4_dqs_t             (c0_ddr4_dqs_t),
    .c0_ddr4_odt               (c0_ddr4_odt),
    .c0_ddr4_bg                (c0_ddr4_bg),
    .c0_ddr4_reset_n           (c0_ddr4_reset_n),
    .c0_ddr4_act_n             (c0_ddr4_act_n),
    .c0_ddr4_ck_c              (c0_ddr4_ck_c),
    .c0_ddr4_ck_t              (c0_ddr4_ck_t),
    .c0_ddr4_ui_clk            (ui_clk),
    .c0_ddr4_ui_clk_sync_rst   (ui_clk_sync_rst),
    .c0_ddr4_aresetn           (axi_aresetn),
    .c0_ddr4_s_axi_awid        (axi_awid),
    .c0_ddr4_s_axi_awaddr      (axi_awaddr),
    .c0_ddr4_s_axi_awlen       (axi_awlen),
    .c0_ddr4_s_axi_awsize      (axi_awsize),
    .c0_ddr4_s_axi_awburst     (axi_awburst),
    .c0_ddr4_s_axi_awlock      (axi_awlock),
    .c0_ddr4_s_axi_awcache     (axi_awcache),
    .c0_ddr4_s_axi_awprot      (axi_awprot),
    .c0_ddr4_s_axi_awqos       (axi_awqos),
    .c0_ddr4_s_axi_awvalid     (axi_awvalid),
    .c0_ddr4_s_axi_awready     (axi_awready),
    .c0_ddr4_s_axi_wdata       (axi_wdata),
    .c0_ddr4_s_axi_wstrb       (axi_wstrb),
    .c0_ddr4_s_axi_wlast       (axi_wlast),
    .c0_ddr4_s_axi_wvalid      (axi_wvalid),
    .c0_ddr4_s_axi_wready      (axi_wready),
    .c0_ddr4_s_axi_bready      (axi_bready),
    .c0_ddr4_s_axi_bid         (axi_bid),
    .c0_ddr4_s_axi_bresp       (axi_bresp),
    .c0_ddr4_s_axi_bvalid      (axi_bvalid),
    .c0_ddr4_s_axi_arid        (axi_arid),
    .c0_ddr4_s_axi_araddr      (axi_araddr),
    .c0_ddr4_s_axi_arlen       (axi_arlen),
    .c0_ddr4_s_axi_arsize      (axi_arsize),
    .c0_ddr4_s_axi_arburst     (axi_arburst),
    .c0_ddr4_s_axi_arlock      (axi_arlock),
    .c0_ddr4_s_axi_arcache     (axi_arcache),
    .c0_ddr4_s_axi_arprot      (axi_arprot),
    .c0_ddr4_s_axi_arqos       (axi_arqos),
    .c0_ddr4_s_axi_arvalid     (axi_arvalid),
    .c0_ddr4_s_axi_arready     (axi_arready),
    .c0_ddr4_s_axi_rready      (axi_rready),
    .c0_ddr4_s_axi_rlast       (axi_rlast),
    .c0_ddr4_s_axi_rvalid      (axi_rvalid),
    .c0_ddr4_s_axi_rresp       (axi_rresp),
    .c0_ddr4_s_axi_rid         (axi_rid),
    .c0_ddr4_s_axi_rdata       (axi_rdata),
    .sys_rst                   (~sys_rst_n)
);

endmodule
```
