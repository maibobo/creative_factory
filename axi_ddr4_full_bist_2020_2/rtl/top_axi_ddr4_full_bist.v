`timescale 1ns / 1ps

// KU040 自研板 DDR4 验证顶层。
// 板级端口只连接 MIG、可综合 AXI BIST 和 FPGA 调试 IP；VIO 负责下发模式，
// ILA 负责采样而不参与判定，所有 PASS/FAIL 均由 BIST 在 ui_clk 域内产生。
module TOP_AXI_DDR4_FULL_BIST #(
    parameter integer AUTO_START = 1
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

localparam integer AXI_ADDR_WIDTH = 32;
localparam integer AXI_DATA_WIDTH = 64;
localparam integer AXI_ID_WIDTH = 4;

wire init_calib_complete;
wire ui_clk;
wire ui_clk_sync_rst;
wire axi_aresetn;
reg [1:0] axi_reset_pipe;
reg auto_start_pending;
reg [27:0] status_counter;
reg led1_value;

wire vio_start;
wire vio_restart;
wire [2:0] vio_test_mode;
wire vio_repeat_enable;
wire bist_start;
wire bist_busy;
wire bist_done;
wire bist_pass;
wire bist_fail;
wire [8:0] bist_phase;
wire [32:0] bist_current_addr_ext;
wire [15:0] bist_progress;
wire [31:0] bist_write_transaction_count;
wire [31:0] bist_read_transaction_count;
wire [63:0] bist_elapsed_cycle_count;
wire [31:0] bist_timeout_count;
wire [31:0] bist_error_count;
wire [31:0] bist_first_error_addr;
wire [63:0] bist_first_expected_data;
wire [63:0] bist_first_actual_data;
wire [3:0] bist_last_axi_response;

wire [AXI_ID_WIDTH-1:0] axi_awid;
wire [AXI_ADDR_WIDTH-1:0] axi_awaddr;
wire [7:0] axi_awlen;
wire [2:0] axi_awsize;
wire [1:0] axi_awburst;
wire [0:0] axi_awlock;
wire [3:0] axi_awcache;
wire [2:0] axi_awprot;
wire [3:0] axi_awqos;
wire axi_awvalid;
wire axi_awready;
wire [AXI_DATA_WIDTH-1:0] axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb;
wire axi_wlast;
wire axi_wvalid;
wire axi_wready;
wire [AXI_ID_WIDTH-1:0] axi_bid;
wire [1:0] axi_bresp;
wire axi_bvalid;
wire axi_bready;
wire [AXI_ID_WIDTH-1:0] axi_arid;
wire [AXI_ADDR_WIDTH-1:0] axi_araddr;
wire [7:0] axi_arlen;
wire [2:0] axi_arsize;
wire [1:0] axi_arburst;
wire [0:0] axi_arlock;
wire [3:0] axi_arcache;
wire [2:0] axi_arprot;
wire [3:0] axi_arqos;
wire axi_arvalid;
wire axi_arready;
wire [AXI_ID_WIDTH-1:0] axi_rid;
wire [AXI_DATA_WIDTH-1:0] axi_rdata;
wire [1:0] axi_rresp;
wire axi_rlast;
wire axi_rvalid;
wire axi_rready;

wire [5:0] ila_control;
wire [1:0] ila_aw_handshake;
wire [2:0] ila_w_handshake;
wire [3:0] ila_b_channel;
wire [1:0] ila_ar_handshake;
wire [4:0] ila_r_channel;
wire unused_mig_dbg_clk;
wire [511:0] unused_mig_dbg_bus;
wire mig_sys_rst;
wire led0_value;

assign axi_aresetn = axi_reset_pipe[1];
assign bist_start = vio_start | auto_start_pending;
assign led0_value = init_calib_complete ? 1'b1 : status_counter[23];
assign led = {led1_value, led0_value};
assign ila_control = {vio_repeat_enable, vio_test_mode, vio_restart, vio_start};
assign ila_aw_handshake = {axi_awvalid, axi_awready};
assign ila_w_handshake = {axi_wvalid, axi_wready, axi_wlast};
assign ila_b_channel = {axi_bvalid, axi_bready, axi_bresp};
assign ila_ar_handshake = {axi_arvalid, axi_arready};
assign ila_r_channel = {axi_rvalid, axi_rready, axi_rlast, axi_rresp};
assign mig_sys_rst = ~sys_rst_n;

// LED1 用三种互斥节奏区分运行、PASS 和 FAIL；组合过程完整覆盖所有分支。
always @(*) begin : led1_decode
    led1_value = status_counter[23];
    if (bist_fail) begin
        led1_value = status_counter[20];
    end else if (bist_done) begin
        led1_value = bist_pass;
    end
end

// MIG 在校准完成且 ui_clk 同步复位撤销后，再延迟两个 ui_clk 周期释放 AXI。
// axi_reset_pipe 是同一复位条件下的紧密移位向量，属于一个左值根对象。
always @(posedge ui_clk) begin : axi_reset_release
    if (ui_clk_sync_rst | ~init_calib_complete) begin
        axi_reset_pipe <= 2'b00;
    end else begin
        axi_reset_pipe <= {axi_reset_pipe[0], 1'b1};
    end
end

// 自动启动只服务于上电即跑的兼容冒烟 bitstream；VIO restart 始终可重启并换模式。
always @(posedge ui_clk) begin : auto_start_control
    if (!axi_aresetn) begin
        auto_start_pending <= (AUTO_START != 0);
    end else begin
        auto_start_pending <= 1'b0;
    end
end

always @(posedge ui_clk) begin : led_timebase
    if (!axi_aresetn) begin
        status_counter <= 28'd0;
    end else begin
        status_counter <= status_counter + 28'd1;
    end
end

AXI_DDR_FULL_BIST #(
    .ADDR_WIDTH       (AXI_ADDR_WIDTH),
    .DATA_WIDTH       (AXI_DATA_WIDTH),
    .ID_WIDTH         (AXI_ID_WIDTH),
    .FULL_SPACE_LIMIT (33'h1_0000_0000)
) U_AXI_DDR_FULL_BIST (
    .aclk                    (ui_clk),
    .aresetn                 (axi_aresetn),
    .start                   (bist_start),
    .restart                 (vio_restart),
    .test_mode               (vio_test_mode),
    .repeat_enable           (vio_repeat_enable),
    .busy                    (bist_busy),
    .done                    (bist_done),
    .pass                    (bist_pass),
    .fail                    (bist_fail),
    .phase                   (bist_phase),
    .current_addr_ext        (bist_current_addr_ext),
    .progress                (bist_progress),
    .write_transaction_count (bist_write_transaction_count),
    .read_transaction_count  (bist_read_transaction_count),
    .elapsed_cycle_count     (bist_elapsed_cycle_count),
    .timeout_count           (bist_timeout_count),
    .error_count             (bist_error_count),
    .first_error_addr        (bist_first_error_addr),
    .first_expected_data     (bist_first_expected_data),
    .first_actual_data       (bist_first_actual_data),
    .last_axi_response       (bist_last_axi_response),
    .m_axi_awid              (axi_awid),
    .m_axi_awaddr            (axi_awaddr),
    .m_axi_awlen             (axi_awlen),
    .m_axi_awsize            (axi_awsize),
    .m_axi_awburst           (axi_awburst),
    .m_axi_awlock            (axi_awlock),
    .m_axi_awcache           (axi_awcache),
    .m_axi_awprot            (axi_awprot),
    .m_axi_awqos             (axi_awqos),
    .m_axi_awvalid           (axi_awvalid),
    .m_axi_awready           (axi_awready),
    .m_axi_wdata             (axi_wdata),
    .m_axi_wstrb             (axi_wstrb),
    .m_axi_wlast             (axi_wlast),
    .m_axi_wvalid            (axi_wvalid),
    .m_axi_wready            (axi_wready),
    .m_axi_bid               (axi_bid),
    .m_axi_bresp             (axi_bresp),
    .m_axi_bvalid            (axi_bvalid),
    .m_axi_bready            (axi_bready),
    .m_axi_arid              (axi_arid),
    .m_axi_araddr            (axi_araddr),
    .m_axi_arlen             (axi_arlen),
    .m_axi_arsize            (axi_arsize),
    .m_axi_arburst           (axi_arburst),
    .m_axi_arlock            (axi_arlock),
    .m_axi_arcache           (axi_arcache),
    .m_axi_arprot            (axi_arprot),
    .m_axi_arqos             (axi_arqos),
    .m_axi_arvalid           (axi_arvalid),
    .m_axi_arready           (axi_arready),
    .m_axi_rid               (axi_rid),
    .m_axi_rdata             (axi_rdata),
    .m_axi_rresp             (axi_rresp),
    .m_axi_rlast             (axi_rlast),
    .m_axi_rvalid            (axi_rvalid),
    .m_axi_rready            (axi_rready)
);

vio_bist_ctrl U_VIO_BIST_CTRL (
    .clk        (ui_clk),
    .probe_in0  (init_calib_complete),
    .probe_in1  (bist_busy),
    .probe_in2  (bist_done),
    .probe_in3  (bist_pass),
    .probe_in4  (bist_fail),
    .probe_in5  (bist_phase),
    .probe_in6  (bist_current_addr_ext),
    .probe_in7  (bist_progress),
    .probe_in8  (bist_error_count),
    .probe_in9  (bist_first_error_addr),
    .probe_in10 (bist_last_axi_response),
    .probe_in11 (bist_timeout_count),
    .probe_out0 (vio_start),
    .probe_out1 (vio_restart),
    .probe_out2 (vio_test_mode),
    .probe_out3 (vio_repeat_enable)
);

ila_bist_status U_ILA_BIST_STATUS (
    .clk     (ui_clk),
    .probe0  (init_calib_complete),
    .probe1  (axi_aresetn),
    .probe2  (ila_control),
    .probe3  (bist_phase),
    .probe4  (bist_current_addr_ext),
    .probe5  (bist_progress),
    .probe6  (ila_aw_handshake),
    .probe7  (ila_w_handshake),
    .probe8  (ila_b_channel),
    .probe9  (ila_ar_handshake),
    .probe10 (ila_r_channel),
    .probe11 (bist_error_count),
    .probe12 (bist_first_error_addr),
    .probe13 (bist_first_expected_data),
    .probe14 (bist_first_actual_data),
    .probe15 (bist_elapsed_cycle_count)
);

// MIG 与 BIST 共用 ui_clk 和 axi_aresetn，不存在用户 AXI 侧 CDC。
// 物理参考时钟仅由 MIG 内部差分输入缓冲接收，XDC 不再额外创建重复时钟。
ddr4_axi_0 U_DDR4_AXI_0 (
    .c0_init_calib_complete  (init_calib_complete),
    .dbg_clk                 (unused_mig_dbg_clk),
    .c0_sys_clk_p            (sys_clk_p),
    .c0_sys_clk_n            (sys_clk_n),
    .dbg_bus                 (unused_mig_dbg_bus),
    .c0_ddr4_adr             (c0_ddr4_adr),
    .c0_ddr4_ba              (c0_ddr4_ba),
    .c0_ddr4_cke             (c0_ddr4_cke),
    .c0_ddr4_cs_n            (c0_ddr4_cs_n),
    .c0_ddr4_dm_dbi_n        (c0_ddr4_dm_dbi_n),
    .c0_ddr4_dq              (c0_ddr4_dq),
    .c0_ddr4_dqs_c           (c0_ddr4_dqs_c),
    .c0_ddr4_dqs_t           (c0_ddr4_dqs_t),
    .c0_ddr4_odt             (c0_ddr4_odt),
    .c0_ddr4_bg              (c0_ddr4_bg),
    .c0_ddr4_reset_n         (c0_ddr4_reset_n),
    .c0_ddr4_act_n           (c0_ddr4_act_n),
    .c0_ddr4_ck_c            (c0_ddr4_ck_c),
    .c0_ddr4_ck_t            (c0_ddr4_ck_t),
    .c0_ddr4_ui_clk          (ui_clk),
    .c0_ddr4_ui_clk_sync_rst (ui_clk_sync_rst),
    .c0_ddr4_aresetn         (axi_aresetn),
    .c0_ddr4_s_axi_awid      (axi_awid),
    .c0_ddr4_s_axi_awaddr    (axi_awaddr),
    .c0_ddr4_s_axi_awlen     (axi_awlen),
    .c0_ddr4_s_axi_awsize    (axi_awsize),
    .c0_ddr4_s_axi_awburst   (axi_awburst),
    .c0_ddr4_s_axi_awlock    (axi_awlock),
    .c0_ddr4_s_axi_awcache   (axi_awcache),
    .c0_ddr4_s_axi_awprot    (axi_awprot),
    .c0_ddr4_s_axi_awqos     (axi_awqos),
    .c0_ddr4_s_axi_awvalid   (axi_awvalid),
    .c0_ddr4_s_axi_awready   (axi_awready),
    .c0_ddr4_s_axi_wdata     (axi_wdata),
    .c0_ddr4_s_axi_wstrb     (axi_wstrb),
    .c0_ddr4_s_axi_wlast     (axi_wlast),
    .c0_ddr4_s_axi_wvalid    (axi_wvalid),
    .c0_ddr4_s_axi_wready    (axi_wready),
    .c0_ddr4_s_axi_bready    (axi_bready),
    .c0_ddr4_s_axi_bid       (axi_bid),
    .c0_ddr4_s_axi_bresp     (axi_bresp),
    .c0_ddr4_s_axi_bvalid    (axi_bvalid),
    .c0_ddr4_s_axi_arid      (axi_arid),
    .c0_ddr4_s_axi_araddr    (axi_araddr),
    .c0_ddr4_s_axi_arlen     (axi_arlen),
    .c0_ddr4_s_axi_arsize    (axi_arsize),
    .c0_ddr4_s_axi_arburst   (axi_arburst),
    .c0_ddr4_s_axi_arlock    (axi_arlock),
    .c0_ddr4_s_axi_arcache   (axi_arcache),
    .c0_ddr4_s_axi_arprot    (axi_arprot),
    .c0_ddr4_s_axi_arqos     (axi_arqos),
    .c0_ddr4_s_axi_arvalid   (axi_arvalid),
    .c0_ddr4_s_axi_arready   (axi_arready),
    .c0_ddr4_s_axi_rready    (axi_rready),
    .c0_ddr4_s_axi_rlast     (axi_rlast),
    .c0_ddr4_s_axi_rvalid    (axi_rvalid),
    .c0_ddr4_s_axi_rresp     (axi_rresp),
    .c0_ddr4_s_axi_rid       (axi_rid),
    .c0_ddr4_s_axi_rdata     (axi_rdata),
    .sys_rst                 (mig_sys_rst)
);

endmodule
