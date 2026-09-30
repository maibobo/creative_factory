`timescale 1ns/1ps

`ifdef DDR4_REAL
  `ifdef DDR4_SIM_RAM
    `define RTDS_DDR_MODE_CONFLICT
  `endif
`endif
`ifndef DDR4_REAL
  `ifndef DDR4_SIM_RAM
    `define DDR4_SIM_RAM
  `endif
`endif

module rtds_ddr4_backend #(
    parameter integer AXI_ADDR_WIDTH = 32,
    parameter integer AXI_DATA_WIDTH = 64,
    parameter integer AXI_ID_WIDTH   = 5,
    parameter integer TIMEOUT_CYCLES = 65535
) (
    input  wire                          s_axi_aclk,
    input  wire                          s_axi_aresetn,
    input  wire                          ddr_sys_clk_i,
    input  wire                          ddr_sys_rst_n,
    input  wire                          clear_status,
    input  wire [AXI_ID_WIDTH-1:0]       s_axi_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [7:0]                    s_axi_awlen,
    input  wire [2:0]                    s_axi_awsize,
    input  wire [1:0]                    s_axi_awburst,
    input  wire [0:0]                    s_axi_awlock,
    input  wire [3:0]                    s_axi_awcache,
    input  wire [2:0]                    s_axi_awprot,
    input  wire [3:0]                    s_axi_awregion,
    input  wire [3:0]                    s_axi_awqos,
    input  wire                          s_axi_awvalid,
    output wire                          s_axi_awready,
    input  wire [AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                          s_axi_wlast,
    input  wire                          s_axi_wvalid,
    output wire                          s_axi_wready,
    output wire [AXI_ID_WIDTH-1:0]       s_axi_bid,
    output wire [1:0]                    s_axi_bresp,
    output wire                          s_axi_bvalid,
    input  wire                          s_axi_bready,
    input  wire [AXI_ID_WIDTH-1:0]       s_axi_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [7:0]                    s_axi_arlen,
    input  wire [2:0]                    s_axi_arsize,
    input  wire [1:0]                    s_axi_arburst,
    input  wire [0:0]                    s_axi_arlock,
    input  wire [3:0]                    s_axi_arcache,
    input  wire [2:0]                    s_axi_arprot,
    input  wire [3:0]                    s_axi_arregion,
    input  wire [3:0]                    s_axi_arqos,
    input  wire                          s_axi_arvalid,
    output wire                          s_axi_arready,
    output wire [AXI_ID_WIDTH-1:0]       s_axi_rid,
    output wire [AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                    s_axi_rresp,
    output wire                          s_axi_rlast,
    output wire                          s_axi_rvalid,
    input  wire                          s_axi_rready,
    output wire                          ddr_ready,
    output wire                          init_calib_complete,
    output reg                           ddr_axi_response_error_sticky,
    output reg                           ddr_axi_timeout_sticky,
    output wire                          c0_ddr4_act_n,
    output wire [16:0]                   c0_ddr4_adr,
    output wire [1:0]                    c0_ddr4_ba,
    output wire [0:0]                    c0_ddr4_bg,
    output wire [0:0]                    c0_ddr4_cke,
    output wire [0:0]                    c0_ddr4_odt,
    output wire [0:0]                    c0_ddr4_cs_n,
    output wire [0:0]                    c0_ddr4_ck_t,
    output wire [0:0]                    c0_ddr4_ck_c,
    output wire                          c0_ddr4_reset_n,
    inout  wire [7:0]                    c0_ddr4_dm_dbi_n,
    inout  wire [63:0]                   c0_ddr4_dq,
    inout  wire [7:0]                    c0_ddr4_dqs_c,
    inout  wire [7:0]                    c0_ddr4_dqs_t
);
`ifdef RTDS_DDR_MODE_CONFLICT
    initial $error("DDR4_REAL and DDR4_SIM_RAM are mutually exclusive");
`endif

    wire aw_hs = s_axi_awvalid && s_axi_awready;
    wire w_hs  = s_axi_wvalid  && s_axi_wready;
    wire b_hs  = s_axi_bvalid  && s_axi_bready;
    wire ar_hs = s_axi_arvalid && s_axi_arready;
    wire r_hs  = s_axi_rvalid  && s_axi_rready;
    reg [7:0] outstanding_writes;
    reg [7:0] outstanding_reads;
    reg [31:0] timeout_count;
    reg ready_seen;
    wire any_pending = (outstanding_writes != 0) || (outstanding_reads != 0);
    wire any_progress = aw_hs || w_hs || b_hs || ar_hs || r_hs;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            outstanding_writes <= 0;
            outstanding_reads  <= 0;
            timeout_count      <= 0;
            ready_seen         <= 1'b0;
            ddr_axi_response_error_sticky <= 1'b0;
            ddr_axi_timeout_sticky        <= 1'b0;
        end else begin
            case ({aw_hs,b_hs})
                2'b10: outstanding_writes <= outstanding_writes + 1'b1;
                2'b01: if (outstanding_writes != 0)
                    outstanding_writes <= outstanding_writes - 1'b1;
                default: outstanding_writes <= outstanding_writes;
            endcase
            case ({ar_hs,(r_hs && s_axi_rlast)})
                2'b10: outstanding_reads <= outstanding_reads + 1'b1;
                2'b01: if (outstanding_reads != 0)
                    outstanding_reads <= outstanding_reads - 1'b1;
                default: outstanding_reads <= outstanding_reads;
            endcase

            if (ddr_ready)
                ready_seen <= 1'b1;

            if (clear_status) begin
                ddr_axi_response_error_sticky <= 1'b0;
                ddr_axi_timeout_sticky        <= 1'b0;
                timeout_count                 <= 0;
            end else begin
                if ((b_hs && (s_axi_bresp != 2'b00)) ||
                    (r_hs && (s_axi_rresp != 2'b00)))
                    ddr_axi_response_error_sticky <= 1'b1;
                if (ready_seen && !ddr_ready)
                    ddr_axi_timeout_sticky <= 1'b1;
                if (!any_pending || any_progress) begin
                    timeout_count <= 0;
                end else if (timeout_count >= TIMEOUT_CYCLES-1) begin
                    ddr_axi_timeout_sticky <= 1'b1;
                end else begin
                    timeout_count <= timeout_count + 1'b1;
                end
            end
        end
    end

`ifdef DDR4_SIM_RAM
    reg [1:0] sim_ready_pipe;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || !ddr_sys_rst_n)
            sim_ready_pipe <= 2'b00;
        else
            sim_ready_pipe <= {sim_ready_pipe[0],1'b1};
    end
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign ddr_ready = sim_ready_pipe[1];
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign init_calib_complete = sim_ready_pipe[1];

    wire ram_awready, ram_wready, ram_bvalid, ram_arready, ram_rlast, ram_rvalid;
    wire [AXI_ID_WIDTH-1:0] ram_bid, ram_rid;
    wire [1:0] ram_bresp, ram_rresp;
    wire [AXI_DATA_WIDTH-1:0] ram_rdata;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_awready = ddr_ready && ram_awready;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_wready  = ddr_ready && ram_wready;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_bvalid  = ram_bvalid;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_bid     = ram_bid;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_bresp   = ram_bresp;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_arready = ddr_ready && ram_arready;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_rid     = ram_rid;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign s_axi_rdata   = ram_rdata;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_rresp   = ram_rresp;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign s_axi_rlast   = ram_rlast;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_rvalid  = ram_rvalid;

    rtds_axi_ram_model #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH), .DATA_WIDTH(AXI_DATA_WIDTH),
        .ID_WIDTH(AXI_ID_WIDTH), .MEM_BYTES(4194304)
    ) u_sim_ram (
        .aclk(s_axi_aclk), .aresetn(s_axi_aresetn && ddr_ready),
        .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen), .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst), .s_axi_awvalid(s_axi_awvalid && ddr_ready),
        .s_axi_awready(ram_awready), .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid && ddr_ready), .s_axi_wready(ram_wready),
        .s_axi_bid(ram_bid), .s_axi_bresp(ram_bresp), .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(s_axi_bready), .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize), .s_axi_arburst(s_axi_arburst),
        .s_axi_arvalid(s_axi_arvalid && ddr_ready), .s_axi_arready(ram_arready),
        .s_axi_rid(ram_rid), .s_axi_rdata(ram_rdata), .s_axi_rresp(ram_rresp),
        .s_axi_rlast(ram_rlast), .s_axi_rvalid(ram_rvalid), .s_axi_rready(s_axi_rready)
    );

    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_act_n = 1'b1;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_adr = 17'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_ba = 2'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_bg = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_cke = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_odt = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_cs_n = 1'd1;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_ck_t = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_ck_c = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_reset_n = 1'b0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dm_dbi_n = 8'hzz;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dq = 64'hzzzz_zzzz_zzzz_zzzz;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dqs_c = 8'hzz;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dqs_t = 8'hzz;
`else
    wire ui_clk;
    wire ui_clk_sync_rst;
    wire mig_calib_complete;
    reg [1:0] ui_reset_pipe;
    reg [1:0] ready_sync;
    wire ui_axi_aresetn = ui_reset_pipe[1];

    always @(posedge ui_clk) begin
        if (ui_clk_sync_rst || !mig_calib_complete)
            ui_reset_pipe <= 2'b00;
        else
            ui_reset_pipe <= {ui_reset_pipe[0],1'b1};
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            ready_sync <= 2'b00;
        else
            ready_sync <= {ready_sync[0],ui_axi_aresetn};
    end
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign ddr_ready = ready_sync[1];
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign init_calib_complete = mig_calib_complete;

    wire cc_s_awready, cc_s_wready, cc_s_bvalid, cc_s_arready, cc_s_rlast, cc_s_rvalid;
    wire [AXI_ID_WIDTH-1:0] cc_s_bid, cc_s_rid;
    wire [1:0] cc_s_bresp, cc_s_rresp;
    wire [AXI_DATA_WIDTH-1:0] cc_s_rdata;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_awready = ddr_ready && cc_s_awready;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_wready  = ddr_ready && cc_s_wready;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_bid     = cc_s_bid;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_bresp   = cc_s_bresp;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_bvalid  = cc_s_bvalid;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_arready = ddr_ready && cc_s_arready;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_rid     = cc_s_rid;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign s_axi_rdata   = cc_s_rdata;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign s_axi_rresp   = cc_s_rresp;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign s_axi_rlast   = cc_s_rlast;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign s_axi_rvalid  = cc_s_rvalid;

    wire [AXI_ID_WIDTH-1:0] m_awid, m_bid, m_arid, m_rid;
    wire [AXI_ADDR_WIDTH-1:0] m_awaddr, m_araddr;
    wire [7:0] m_awlen, m_arlen;
    wire [2:0] m_awsize, m_arsize;
    wire [1:0] m_awburst, m_arburst;
    wire [0:0] m_awlock, m_arlock;
    wire [3:0] m_awcache, m_arcache, m_awregion, m_arregion, m_awqos, m_arqos;
    wire [2:0] m_awprot, m_arprot;
    wire m_awvalid, m_awready, m_wlast, m_wvalid, m_wready;
    wire [AXI_DATA_WIDTH-1:0] m_wdata, m_rdata;
    wire [(AXI_DATA_WIDTH/8)-1:0] m_wstrb;
    wire [1:0] m_bresp, m_rresp;
    wire m_bvalid, m_bready, m_arvalid, m_arready, m_rlast, m_rvalid, m_rready;

    rtds_axi_clock_converter u_axi_clock_converter (
        .s_axi_aclk(s_axi_aclk), .s_axi_aresetn(s_axi_aresetn),
        .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr), .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize), .s_axi_awburst(s_axi_awburst), .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache), .s_axi_awprot(s_axi_awprot), .s_axi_awregion(s_axi_awregion),
        .s_axi_awqos(s_axi_awqos), .s_axi_awvalid(s_axi_awvalid && ddr_ready), .s_axi_awready(cc_s_awready),
        .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid && ddr_ready), .s_axi_wready(cc_s_wready),
        .s_axi_bid(cc_s_bid), .s_axi_bresp(cc_s_bresp), .s_axi_bvalid(cc_s_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_arid(s_axi_arid), .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize), .s_axi_arburst(s_axi_arburst), .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache), .s_axi_arprot(s_axi_arprot), .s_axi_arregion(s_axi_arregion),
        .s_axi_arqos(s_axi_arqos), .s_axi_arvalid(s_axi_arvalid && ddr_ready), .s_axi_arready(cc_s_arready),
        .s_axi_rid(cc_s_rid), .s_axi_rdata(cc_s_rdata), .s_axi_rresp(cc_s_rresp),
        .s_axi_rlast(cc_s_rlast), .s_axi_rvalid(cc_s_rvalid), .s_axi_rready(s_axi_rready),
        .m_axi_aclk(ui_clk), .m_axi_aresetn(ui_axi_aresetn),
        .m_axi_awid(m_awid), .m_axi_awaddr(m_awaddr), .m_axi_awlen(m_awlen), .m_axi_awsize(m_awsize),
        .m_axi_awburst(m_awburst), .m_axi_awlock(m_awlock), .m_axi_awcache(m_awcache),
        .m_axi_awprot(m_awprot), .m_axi_awregion(m_awregion), .m_axi_awqos(m_awqos),
        .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready), .m_axi_wdata(m_wdata),
        .m_axi_wstrb(m_wstrb), .m_axi_wlast(m_wlast), .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
        .m_axi_bid(m_bid), .m_axi_bresp(m_bresp), .m_axi_bvalid(m_bvalid), .m_axi_bready(m_bready),
        .m_axi_arid(m_arid), .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arlock(m_arlock), .m_axi_arcache(m_arcache),
        .m_axi_arprot(m_arprot), .m_axi_arregion(m_arregion), .m_axi_arqos(m_arqos),
        .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready), .m_axi_rid(m_rid),
        .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp), .m_axi_rlast(m_rlast),
        .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready)
    );

    rtds_ddr4_mig u_ddr4_mig (
        .c0_init_calib_complete(mig_calib_complete), .dbg_clk(), .c0_sys_clk_i(ddr_sys_clk_i), .dbg_bus(),
        .c0_ddr4_adr(c0_ddr4_adr), .c0_ddr4_ba(c0_ddr4_ba), .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_cs_n(c0_ddr4_cs_n), .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n), .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c), .c0_ddr4_dqs_t(c0_ddr4_dqs_t), .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_bg(c0_ddr4_bg), .c0_ddr4_reset_n(c0_ddr4_reset_n), .c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_ck_c(c0_ddr4_ck_c), .c0_ddr4_ck_t(c0_ddr4_ck_t), .c0_ddr4_ui_clk(ui_clk),
        .c0_ddr4_ui_clk_sync_rst(ui_clk_sync_rst), .c0_ddr4_aresetn(ui_axi_aresetn),
        .c0_ddr4_s_axi_awid(m_awid), .c0_ddr4_s_axi_awaddr(m_awaddr), .c0_ddr4_s_axi_awlen(m_awlen),
        .c0_ddr4_s_axi_awsize(m_awsize), .c0_ddr4_s_axi_awburst(m_awburst), .c0_ddr4_s_axi_awlock(m_awlock),
        .c0_ddr4_s_axi_awcache(m_awcache), .c0_ddr4_s_axi_awprot(m_awprot), .c0_ddr4_s_axi_awqos(m_awqos),
        .c0_ddr4_s_axi_awvalid(m_awvalid), .c0_ddr4_s_axi_awready(m_awready),
        .c0_ddr4_s_axi_wdata(m_wdata), .c0_ddr4_s_axi_wstrb(m_wstrb), .c0_ddr4_s_axi_wlast(m_wlast),
        .c0_ddr4_s_axi_wvalid(m_wvalid), .c0_ddr4_s_axi_wready(m_wready), .c0_ddr4_s_axi_bready(m_bready),
        .c0_ddr4_s_axi_bid(m_bid), .c0_ddr4_s_axi_bresp(m_bresp), .c0_ddr4_s_axi_bvalid(m_bvalid),
        .c0_ddr4_s_axi_arid(m_arid), .c0_ddr4_s_axi_araddr(m_araddr), .c0_ddr4_s_axi_arlen(m_arlen),
        .c0_ddr4_s_axi_arsize(m_arsize), .c0_ddr4_s_axi_arburst(m_arburst), .c0_ddr4_s_axi_arlock(m_arlock),
        .c0_ddr4_s_axi_arcache(m_arcache), .c0_ddr4_s_axi_arprot(m_arprot), .c0_ddr4_s_axi_arqos(m_arqos),
        .c0_ddr4_s_axi_arvalid(m_arvalid), .c0_ddr4_s_axi_arready(m_arready),
        .c0_ddr4_s_axi_rready(m_rready), .c0_ddr4_s_axi_rlast(m_rlast), .c0_ddr4_s_axi_rvalid(m_rvalid),
        .c0_ddr4_s_axi_rresp(m_rresp), .c0_ddr4_s_axi_rid(m_rid), .c0_ddr4_s_axi_rdata(m_rdata),
        .sys_rst(~ddr_sys_rst_n)
    );
`endif
endmodule
