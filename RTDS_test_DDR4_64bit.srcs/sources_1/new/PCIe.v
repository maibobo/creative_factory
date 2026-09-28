`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: PCIe
//
// TOP.v remains the board top. This module keeps the existing BD boundary and
// connects design_1_wrapper's FDMA/CONV_DMA interface to Aurora LocalLink.
//
// 中文接口说明：
// 输入为板级 PCIe、250 MHz 系统时钟/复位、Aurora 用户时钟与 LocalLink RX；
// 输出为 PCIe TX、LocalLink TX、链路状态和 RX 接收能力。模块本身不重新实现
// XDMA/CONV_DMA/INFO_EXCH，只负责把 BD、Adapter、ILA 的端口按真实语义连接。
// 失败定位：链路问题先看 design_1_wrapper/user_lnk_up；数据方向错误先看 FDMA
// 语义网；命令/IRQ 问题看 INFO_EXCH 状态线与 Adapter；ILA 只观测不参与功能。
//////////////////////////////////////////////////////////////////////////////////

module PCIe #(parameter integer RX_PERIOD_CYCLES=25000000) (

    output wire [7:0] cfg_byte,
    output wire cfg_byte_valid,
    // PCIe
    input       [1:0] pcie_mgt_rxn,
    input       [1:0] pcie_mgt_rxp,
    output      [1:0] pcie_mgt_txn,
    output      [1:0] pcie_mgt_txp,
    input       [0:0] pcie_diff_clk_n,
    input       [0:0] pcie_diff_clk_p,
    input             pcie_rst_n,
    output            user_lnk_up,

    input      [31:0] FPGA_TEMP_W,

    input             i_sys_clk,
    input             i_sys_rst,

    input             ddr_sys_clk_i,
    input             ddr_sys_rst_n,
    output            c0_ddr4_act_n,
    output     [16:0] c0_ddr4_adr,
    output     [1:0]  c0_ddr4_ba,
    output     [0:0]  c0_ddr4_bg,
    output     [0:0]  c0_ddr4_cke,
    output     [0:0]  c0_ddr4_odt,
    output     [0:0]  c0_ddr4_cs_n,
    output     [0:0]  c0_ddr4_ck_t,
    output     [0:0]  c0_ddr4_ck_c,
    output            c0_ddr4_reset_n,
    inout      [7:0]  c0_ddr4_dm_dbi_n,
    inout      [63:0] c0_ddr4_dq,
    inout      [7:0]  c0_ddr4_dqs_c,
    inout      [7:0]  c0_ddr4_dqs_t,

    input             aurora_user_clk,
    input             aurora_user_rstn,
    input             aurora_channel_up,
    input             aurora_lane_up,

    output     [63:0] aurora_tx_d,
    output            aurora_tx_sof,
    output            aurora_tx_eof,
    output     [2:0]  aurora_tx_rem,
    output            aurora_tx_src_rdy,
    input             aurora_tx_dst_rdy,

    input      [63:0] aurora_rx_d,
    input             aurora_rx_sof,
    input             aurora_rx_eof,
    input      [2:0]  aurora_rx_rem,
    input             aurora_rx_src_rdy,
    output            aurora_rx_dst_rdy
    );

    // ---------- 语义段 1：系统固定参数和双向地址窗口 ----------
    // 输入：无运行时输入；输出：传给 Adapter 的帧长和卡端窗口。
    // 作用：RX(Aurora→CPU) 使用 0x0000，TX(CPU→Aurora) 使用 0x8000。
    // 失败定位：软件地址或长度不匹配时先与本段参数核对。
    localparam integer FRAME_BYTES = 16;
    localparam integer ACTIVE_WINDOW_BYTES = 32 * 1024;
    localparam [31:0] RX_BASE_ADDR_LO = 32'h0010_0000;
    localparam [31:0] TX_BASE_ADDR_LO = 32'h0000_8000;
    localparam [31:0] CARD_ADDR_HI = 32'h0000_0000;

    // ---------- 语义段 2：BD、Adapter 与 ILA 的语义网络 ----------
    // 输入/输出：FDMA read/write、INFO 命令/状态、IRQ 和 debug。
    // 作用：用显式语义网隔离 CONV_DMA 历史反向命名，避免按名字误接。
    // 失败定位：写侧优先同时观察 source_valid 与 accept，而不是猜测 valid/ready。
    wire [63:0] fdma_raddr;
    wire        fdma_rareq;
    wire        fdma_rbusy;
    wire [63:0] fdma_rdata;
    wire [15:0] fdma_rsize;
    wire        fdma_rvalid;
    wire        fdma_rready;

    wire [63:0] fdma_waddr;
    wire        fdma_wareq;
    wire        fdma_wbusy;
    wire fdma_wdone, fdma_werror;
    wire [31:0] RX_READY_BLOCKS, RX_HEAD_SEQ, RX_DROPPED_FRAMES;
    wire [7:0] fdma_wstrb;
    wire cpu_wr_done_event;
    wire [63:0] fdma_wdata;
    wire [15:0] fdma_wsize;
    // CONV_DMA 的历史端口命名与通常的 valid/ready 语义相反：
    //   CONV_DMA.fdma_wready(input)  实际接收“上游数据有效”；
    //   CONV_DMA.fdma_wvalid(output) 实际返回“本拍已被 AXI 接受”。
    // 这里使用语义名称隔离该兼容关系，避免按同名直连形成多驱动/悬空。
    wire        fdma_w_source_valid;
    wire        fdma_w_accept;

    wire [31:0] FPGA_CPU_START_ADDR;
    wire [31:0] FPGA_CPU_LEN;
    wire [31:0] CPU_FPGA_START_ADDR;
    wire [31:0] CPU_FPGA_LEN;

    wire        CLEAR_INTER_R;
    wire        CPU_REC_STATE_R;
    wire        CPU_REC_STATE_W;
    wire        INT_STATE_W;
    wire        INT_STATE_R;
    wire        RD_START;
    wire        CPU_WR_DONE_resp;
    wire        FPGA_CPU_irq_req;
    wire        user_lnk_up_int;

    wire        rx_fifo_almost_full;
    wire        rx_fifo_full;
    wire        rx_overflow_sticky;
    wire        rx_overrun_sticky;
    wire        tx_underflow_sticky;
    wire        fdma_timeout_sticky;
    wire        length_error_sticky;
    wire        link_down_sticky;
    wire        rx_pending;
    wire [3:0]  adapter_tx_state_dbg;
    wire [3:0]  adapter_rx_state_dbg;

    // DDR memory master exported by design_1 after BRAM removal.
    wire [4:0]  mem_awid, mem_bid, mem_arid, mem_rid;
    wire [63:0] mem_awaddr, mem_araddr;
    wire [7:0]  mem_awlen, mem_arlen;
    wire [2:0]  mem_awsize, mem_arsize;
    wire [1:0]  mem_awburst, mem_arburst;
    wire [0:0]  mem_awlock, mem_arlock;
    wire [3:0]  mem_awcache, mem_arcache, mem_awregion, mem_arregion, mem_awqos, mem_arqos;
    wire [2:0]  mem_awprot, mem_arprot;
    wire        mem_awvalid, mem_awready, mem_wlast, mem_wvalid, mem_wready;
    wire [63:0] mem_wdata, mem_rdata;
    wire [7:0]  mem_wstrb;
    wire [1:0]  mem_bresp, mem_rresp;
    wire        mem_bvalid, mem_bready, mem_arvalid, mem_arready, mem_rlast, mem_rvalid, mem_rready;
    wire        ddr_ready;
    wire        ddr_init_calib_complete;
    wire        ddr_axi_response_error_sticky;
    wire        ddr_axi_timeout_sticky;
    wire [31:0] DDR_STATUS_W;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign DDR_STATUS_W = {27'd0,
                                (ddr_axi_timeout_sticky | fdma_timeout_sticky),
                                rx_overflow_sticky,
                                ddr_axi_response_error_sticky,
                                ddr_init_calib_complete,
                                ddr_ready};

    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign user_lnk_up = user_lnk_up_int;

    // ---------- 语义段 3：实例化协议 Adapter ----------
    // 输入：BD 软件控制/FDMA 与 Aurora LL；输出：双向搬运、IRQ、sticky 状态。
    // 作用：这是本文件的功能核心，生产和 Root Port 大仿真使用同一实例。
    // 失败定位：BD 信号正确但 LL/IRQ 异常时进入 Adapter 对应语义段排查。
    pcie_fdma_aurora_brg_adapter #(
        .FRAME_BYTES         (FRAME_BYTES),
        .RX_PERIOD_CYCLES    (RX_PERIOD_CYCLES),
        .ACTIVE_WINDOW_BYTES (ACTIVE_WINDOW_BYTES),
        .RX_BASE_ADDR_LO      (RX_BASE_ADDR_LO),
        .TX_BASE_ADDR_LO      (TX_BASE_ADDR_LO),
        .CARD_ADDR_HI         (CARD_ADDR_HI)
    ) u_pcie_fdma_aurora_brg_adapter (
        .fdma_clk              (i_sys_clk),
        .fdma_rstn             (!i_sys_rst),
        .aurora_user_clk       (aurora_user_clk),
        .aurora_user_rstn      (aurora_user_rstn),
        .pcie_link_up          (user_lnk_up_int),
        .ddr_ready             (ddr_ready),
        .aurora_channel_up     (aurora_channel_up),
        .aurora_lane_up        (aurora_lane_up),

        .aurora_tx_d           (aurora_tx_d),
        .aurora_tx_sof         (aurora_tx_sof),
        .aurora_tx_eof         (aurora_tx_eof),
        .aurora_tx_rem         (aurora_tx_rem),
        .aurora_tx_src_rdy     (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy     (aurora_tx_dst_rdy),
        .aurora_rx_d           (aurora_rx_d),
        .aurora_rx_sof         (aurora_rx_sof),
        .aurora_rx_eof         (aurora_rx_eof),
        .aurora_rx_rem         (aurora_rx_rem),
        .aurora_rx_src_rdy     (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy     (aurora_rx_dst_rdy),

        .rd_start              (RD_START),
        .cpu_fpga_start_addr   (CPU_FPGA_START_ADDR),
        .cpu_fpga_len          (CPU_FPGA_LEN),
        .cpu_wr_done_event     (cpu_wr_done_event),
        .fdma_wstrb            (fdma_wstrb),
        .cpu_wr_done_resp      (CPU_WR_DONE_resp),

        .fpga_cpu_start_addr   (FPGA_CPU_START_ADDR),
        .fpga_cpu_len          (FPGA_CPU_LEN),
        .int_state_w           (INT_STATE_W),
        .int_state_clear       (INT_STATE_R),
        .clear_inter           (CLEAR_INTER_R),
        .cpu_rec_state_r       (CPU_REC_STATE_R),
        .cpu_rec_state_w       (CPU_REC_STATE_W),
        .fpga_cpu_irq_req      (FPGA_CPU_irq_req),

        .fdma_raddr            (fdma_raddr),
        .fdma_rareq            (fdma_rareq),
        .fdma_rbusy            (fdma_rbusy),
        .fdma_rdata            (fdma_rdata),
        .fdma_rvalid           (fdma_rvalid),
        .fdma_rready           (fdma_rready),
        .fdma_rsize            (fdma_rsize),

        .fdma_waddr            (fdma_waddr),
        .fdma_wareq            (fdma_wareq),
        .fdma_wbusy            (fdma_wbusy),
        .fdma_wdone(fdma_wdone), .fdma_werror(fdma_werror),
        .rx_ready_blocks(RX_READY_BLOCKS), .rx_head_seq(RX_HEAD_SEQ),
        .rx_dropped_frames(RX_DROPPED_FRAMES),
        .cfg_byte(cfg_byte), .cfg_byte_valid(cfg_byte_valid),
        .fdma_wdata            (fdma_wdata),
        .fdma_wvalid           (fdma_w_source_valid),
        .fdma_wready           (fdma_w_accept),
        .fdma_wsize            (fdma_wsize),

        .rx_fifo_almost_full   (rx_fifo_almost_full),
        .rx_fifo_full          (rx_fifo_full),
        .rx_overflow_sticky    (rx_overflow_sticky),
        .rx_overrun_sticky     (rx_overrun_sticky),
        .tx_underflow_sticky   (tx_underflow_sticky),
        .fdma_timeout_sticky   (fdma_timeout_sticky),
        .length_error_sticky   (length_error_sticky),
        .link_down_sticky      (link_down_sticky),
        .rx_pending            (rx_pending),
        .dbg_tx_state          (adapter_tx_state_dbg),
        .dbg_rx_state          (adapter_rx_state_dbg)
    );

    // ---------- 语义段 4：ILA 观测 ----------
    // 输入：FDMA 事务和 Adapter 状态；输出：仅 ILA probe，不反馈数据通路。
    // 作用：上板定位请求、忙、数据、长度和 TX/RX 状态机。
    // 失败定位：ILA 缺信号只影响可观测性，不应改变仿真/硬件功能。
    ila_FDMA ila_FDMA_inst (
        .clk     (i_sys_clk),
        .probe0  (fdma_raddr[31:0]),
        .probe1  (fdma_rareq),
        .probe2  (fdma_rbusy),
        .probe3  (fdma_rdata),
        .probe4  (fdma_rsize),
        .probe5  (fdma_rvalid),
        .probe6  (fdma_waddr[31:0]),
        .probe7  (fdma_wareq),
        .probe8  (fdma_wbusy),
        .probe9  (fdma_wdata),
        .probe10 (fdma_wsize),
        .probe11 (fdma_w_source_valid),
        .probe12 (adapter_rx_state_dbg),
        .probe13 (adapter_tx_state_dbg)
    );

    // ---------- 语义段 5：真实 XDMA/AXI/INFO_EXCH Block Design ----------
    // 输入：PCIe 引脚、系统时钟复位、Adapter FDMA/状态；输出：XDMA 链路、
    // 软件寄存器命令、FDMA 数据和 usr_irq_ack 路由。
    // 作用：保持生成 BD 边界不变，只在本层完成语义正确的端口连接。
    // 失败定位：枚举/BAR/AXI 问题进入 design_1/xdma；不要在 Adapter 中猜测修复。
    design_1_wrapper design_1_wrapper_inst (
        .DDR_STATUS_W             (DDR_STATUS_W),
        .RX_READY_BLOCKS(RX_READY_BLOCKS), .RX_HEAD_SEQ(RX_HEAD_SEQ),
        .RX_DROPPED_FRAMES(RX_DROPPED_FRAMES),
        .fdma_wdone_0(fdma_wdone), .fdma_werror_0(fdma_werror),
        .fdma_raddr_0            (fdma_raddr),
        .fdma_rareq_0            (fdma_rareq),
        .fdma_rbusy_0            (fdma_rbusy),
        .fdma_rdata_0            (fdma_rdata),
        .fdma_rready_0           (fdma_rready),
        .fdma_rsize_0            (fdma_rsize),
        .fdma_rvalid_0           (fdma_rvalid),
        .fdma_waddr_0            (fdma_waddr),
        .fdma_wareq_0            (fdma_wareq),
        .fdma_wbusy_0            (fdma_wbusy),
        .CPU_WR_DONE_EVENT     (cpu_wr_done_event),
        .fdma_wstrb_0          (fdma_wstrb),
        .fdma_wdata_0            (fdma_wdata),
        // 语义适配：BD/CONV_DMA 的 ready 输入实际是 source-valid，
        // BD/CONV_DMA 的 valid 输出实际是 data-accept。
        .fdma_wready_0           (fdma_w_source_valid),
        .fdma_wsize_0            (fdma_wsize),
        .fdma_wvalid_0           (fdma_w_accept),
        .sys_clk                 (i_sys_clk),

        .M_AXI_MEM_awid           (mem_awid),
        .M_AXI_MEM_awaddr         (mem_awaddr),
        .M_AXI_MEM_awlen          (mem_awlen),
        .M_AXI_MEM_awsize         (mem_awsize),
        .M_AXI_MEM_awburst        (mem_awburst),
        .M_AXI_MEM_awlock         (mem_awlock),
        .M_AXI_MEM_awcache        (mem_awcache),
        .M_AXI_MEM_awprot         (mem_awprot),
        .M_AXI_MEM_awregion       (mem_awregion),
        .M_AXI_MEM_awqos          (mem_awqos),
        .M_AXI_MEM_awvalid        (mem_awvalid),
        .M_AXI_MEM_awready        (mem_awready),
        .M_AXI_MEM_wdata          (mem_wdata),
        .M_AXI_MEM_wstrb          (mem_wstrb),
        .M_AXI_MEM_wlast          (mem_wlast),
        .M_AXI_MEM_wvalid         (mem_wvalid),
        .M_AXI_MEM_wready         (mem_wready),
        .M_AXI_MEM_bid            (mem_bid),
        .M_AXI_MEM_bresp          (mem_bresp),
        .M_AXI_MEM_bvalid         (mem_bvalid),
        .M_AXI_MEM_bready         (mem_bready),
        .M_AXI_MEM_arid           (mem_arid),
        .M_AXI_MEM_araddr         (mem_araddr),
        .M_AXI_MEM_arlen          (mem_arlen),
        .M_AXI_MEM_arsize         (mem_arsize),
        .M_AXI_MEM_arburst        (mem_arburst),
        .M_AXI_MEM_arlock         (mem_arlock),
        .M_AXI_MEM_arcache        (mem_arcache),
        .M_AXI_MEM_arprot         (mem_arprot),
        .M_AXI_MEM_arregion       (mem_arregion),
        .M_AXI_MEM_arqos          (mem_arqos),
        .M_AXI_MEM_arvalid        (mem_arvalid),
        .M_AXI_MEM_arready        (mem_arready),
        .M_AXI_MEM_rid            (mem_rid),
        .M_AXI_MEM_rdata          (mem_rdata),
        .M_AXI_MEM_rresp          (mem_rresp),
        .M_AXI_MEM_rlast          (mem_rlast),
        .M_AXI_MEM_rvalid         (mem_rvalid),
        .M_AXI_MEM_rready         (mem_rready),
        .sys_rst_n               (!i_sys_rst),

        .FPGA_TEMP_W_0           (FPGA_TEMP_W),

        .INT_STATE_W_0           (INT_STATE_W),
        .r_INT_STATE_0           (INT_STATE_R),
        .r_CLEAR_INTER_0         (CLEAR_INTER_R),
        .r_CPU_REC_STATE_0       (CPU_REC_STATE_R),
        .CPU_REC_STATE_W_0       (CPU_REC_STATE_W),
        .r_RD_START_0            (RD_START),
        .CPU_WR_DONE_resp_0      (CPU_WR_DONE_resp),

        .FPGA_CPU_LEN_0          (FPGA_CPU_LEN),
        .FPGA_CPU_START_ADDR_0   (FPGA_CPU_START_ADDR),
        .r_CPU_FPGA_START_ADDR_0 (CPU_FPGA_START_ADDR),
        .r_CPU_FPGA_LEN_0        (CPU_FPGA_LEN),

        .pcie_7x_mgt_rxn         (pcie_mgt_rxn),
        .pcie_7x_mgt_rxp         (pcie_mgt_rxp),
        .pcie_7x_mgt_txn         (pcie_mgt_txn),
        .pcie_7x_mgt_txp         (pcie_mgt_txp),
        .pcie_diff_clock_clk_n   (pcie_diff_clk_n),
        .pcie_diff_clock_clk_p   (pcie_diff_clk_p),
        .pcie_rst_n              (pcie_rst_n),
        .user_lnk_up             (user_lnk_up_int),
        .FPGA_CPU_irq_req        (FPGA_CPU_irq_req)

    );

    rtds_ddr4_backend u_rtds_ddr4_backend (
        .s_axi_aclk(i_sys_clk), .s_axi_aresetn(!i_sys_rst),
        .ddr_sys_clk_i(ddr_sys_clk_i), .ddr_sys_rst_n(ddr_sys_rst_n),
        .clear_status(CLEAR_INTER_R),
        .s_axi_awid(mem_awid), .s_axi_awaddr(mem_awaddr[31:0]), .s_axi_awlen(mem_awlen),
        .s_axi_awsize(mem_awsize), .s_axi_awburst(mem_awburst), .s_axi_awlock(mem_awlock),
        .s_axi_awcache(mem_awcache), .s_axi_awprot(mem_awprot), .s_axi_awregion(mem_awregion),
        .s_axi_awqos(mem_awqos), .s_axi_awvalid(mem_awvalid), .s_axi_awready(mem_awready),
        .s_axi_wdata(mem_wdata), .s_axi_wstrb(mem_wstrb), .s_axi_wlast(mem_wlast),
        .s_axi_wvalid(mem_wvalid), .s_axi_wready(mem_wready), .s_axi_bid(mem_bid),
        .s_axi_bresp(mem_bresp), .s_axi_bvalid(mem_bvalid), .s_axi_bready(mem_bready),
        .s_axi_arid(mem_arid), .s_axi_araddr(mem_araddr[31:0]), .s_axi_arlen(mem_arlen),
        .s_axi_arsize(mem_arsize), .s_axi_arburst(mem_arburst), .s_axi_arlock(mem_arlock),
        .s_axi_arcache(mem_arcache), .s_axi_arprot(mem_arprot), .s_axi_arregion(mem_arregion),
        .s_axi_arqos(mem_arqos), .s_axi_arvalid(mem_arvalid), .s_axi_arready(mem_arready),
        .s_axi_rid(mem_rid), .s_axi_rdata(mem_rdata), .s_axi_rresp(mem_rresp),
        .s_axi_rlast(mem_rlast), .s_axi_rvalid(mem_rvalid), .s_axi_rready(mem_rready),
        .ddr_ready(ddr_ready), .init_calib_complete(ddr_init_calib_complete),
        .ddr_axi_response_error_sticky(ddr_axi_response_error_sticky),
        .ddr_axi_timeout_sticky(ddr_axi_timeout_sticky),
        .c0_ddr4_act_n(c0_ddr4_act_n), .c0_ddr4_adr(c0_ddr4_adr), .c0_ddr4_ba(c0_ddr4_ba),
        .c0_ddr4_bg(c0_ddr4_bg), .c0_ddr4_cke(c0_ddr4_cke), .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_cs_n(c0_ddr4_cs_n), .c0_ddr4_ck_t(c0_ddr4_ck_t), .c0_ddr4_ck_c(c0_ddr4_ck_c),
        .c0_ddr4_reset_n(c0_ddr4_reset_n), .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq(c0_ddr4_dq), .c0_ddr4_dqs_c(c0_ddr4_dqs_c), .c0_ddr4_dqs_t(c0_ddr4_dqs_t)
    );

`ifndef SYNTHESIS

    always @(posedge i_sys_clk) begin
        if (mem_awvalid && mem_awready && |mem_awaddr[63:32])
            $error("DDR write address exceeds 32-bit backend aperture");
        if (mem_arvalid && mem_arready && |mem_araddr[63:32])
            $error("DDR read address exceeds 32-bit backend aperture");
    end
`endif

endmodule
