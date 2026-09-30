//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Mon Sep 21 19:55:12 2026
//Host        : LAPTOP-P4UDTRLL running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (CPU_REC_STATE_W_0,
    CPU_WR_DONE_EVENT,
    CPU_WR_DONE_resp_0,
    DDR_STATUS_W,
    FPGA_CPU_LEN_0,
    FPGA_CPU_START_ADDR_0,
    FPGA_CPU_irq_req,
    FPGA_TEMP_W_0,
    INT_STATE_W_0,
    M_AXI_MEM_araddr,
    M_AXI_MEM_arburst,
    M_AXI_MEM_arcache,
    M_AXI_MEM_arid,
    M_AXI_MEM_arlen,
    M_AXI_MEM_arlock,
    M_AXI_MEM_arprot,
    M_AXI_MEM_arqos,
    M_AXI_MEM_arready,
    M_AXI_MEM_arregion,
    M_AXI_MEM_arsize,
    M_AXI_MEM_arvalid,
    M_AXI_MEM_awaddr,
    M_AXI_MEM_awburst,
    M_AXI_MEM_awcache,
    M_AXI_MEM_awid,
    M_AXI_MEM_awlen,
    M_AXI_MEM_awlock,
    M_AXI_MEM_awprot,
    M_AXI_MEM_awqos,
    M_AXI_MEM_awready,
    M_AXI_MEM_awregion,
    M_AXI_MEM_awsize,
    M_AXI_MEM_awvalid,
    M_AXI_MEM_bid,
    M_AXI_MEM_bready,
    M_AXI_MEM_bresp,
    M_AXI_MEM_bvalid,
    M_AXI_MEM_rdata,
    M_AXI_MEM_rid,
    M_AXI_MEM_rlast,
    M_AXI_MEM_rready,
    M_AXI_MEM_rresp,
    M_AXI_MEM_rvalid,
    M_AXI_MEM_wdata,
    M_AXI_MEM_wlast,
    M_AXI_MEM_wready,
    M_AXI_MEM_wstrb,
    M_AXI_MEM_wvalid,
    RX_DROPPED_FRAMES,
    RX_HEAD_SEQ,
    RX_READY_BLOCKS,
    fdma_raddr_0,
    fdma_rareq_0,
    fdma_rbusy_0,
    fdma_rdata_0,
    fdma_rready_0,
    fdma_rsize_0,
    fdma_rvalid_0,
    fdma_waddr_0,
    fdma_wareq_0,
    fdma_wbusy_0,
    fdma_wdata_0,
    fdma_wdone_0,
    fdma_werror_0,
    fdma_wready_0,
    fdma_wsize_0,
    fdma_wstrb_0,
    fdma_wvalid_0,
    pcie_7x_mgt_rxn,
    pcie_7x_mgt_rxp,
    pcie_7x_mgt_txn,
    pcie_7x_mgt_txp,
    pcie_diff_clock_clk_n,
    pcie_diff_clock_clk_p,
    pcie_rst_n,
    r_CLEAR_INTER_0,
    r_CPU_FPGA_LEN_0,
    r_CPU_FPGA_START_ADDR_0,
    r_CPU_REC_STATE_0,
    r_INT_STATE_0,
    r_RD_START_0,
    sys_clk,
    sys_rst_n,
    user_lnk_up);
  input [0:0]CPU_REC_STATE_W_0;
  input CPU_WR_DONE_EVENT;
  input [0:0]CPU_WR_DONE_resp_0;
  input [31:0]DDR_STATUS_W;
  input [31:0]FPGA_CPU_LEN_0;
  input [31:0]FPGA_CPU_START_ADDR_0;
  input [0:0]FPGA_CPU_irq_req;
  input [31:0]FPGA_TEMP_W_0;
  input [0:0]INT_STATE_W_0;
  output [63:0]M_AXI_MEM_araddr;
  output [1:0]M_AXI_MEM_arburst;
  output [3:0]M_AXI_MEM_arcache;
  output [4:0]M_AXI_MEM_arid;
  output [7:0]M_AXI_MEM_arlen;
  output [0:0]M_AXI_MEM_arlock;
  output [2:0]M_AXI_MEM_arprot;
  output [3:0]M_AXI_MEM_arqos;
  input [0:0]M_AXI_MEM_arready;
  output [3:0]M_AXI_MEM_arregion;
  output [2:0]M_AXI_MEM_arsize;
  output [0:0]M_AXI_MEM_arvalid;
  output [63:0]M_AXI_MEM_awaddr;
  output [1:0]M_AXI_MEM_awburst;
  output [3:0]M_AXI_MEM_awcache;
  output [4:0]M_AXI_MEM_awid;
  output [7:0]M_AXI_MEM_awlen;
  output [0:0]M_AXI_MEM_awlock;
  output [2:0]M_AXI_MEM_awprot;
  output [3:0]M_AXI_MEM_awqos;
  input [0:0]M_AXI_MEM_awready;
  output [3:0]M_AXI_MEM_awregion;
  output [2:0]M_AXI_MEM_awsize;
  output [0:0]M_AXI_MEM_awvalid;
  input [4:0]M_AXI_MEM_bid;
  output [0:0]M_AXI_MEM_bready;
  input [1:0]M_AXI_MEM_bresp;
  input [0:0]M_AXI_MEM_bvalid;
  input [63:0]M_AXI_MEM_rdata;
  input [4:0]M_AXI_MEM_rid;
  input [0:0]M_AXI_MEM_rlast;
  output [0:0]M_AXI_MEM_rready;
  input [1:0]M_AXI_MEM_rresp;
  input [0:0]M_AXI_MEM_rvalid;
  output [63:0]M_AXI_MEM_wdata;
  output [0:0]M_AXI_MEM_wlast;
  input [0:0]M_AXI_MEM_wready;
  output [7:0]M_AXI_MEM_wstrb;
  output [0:0]M_AXI_MEM_wvalid;
  input [31:0]RX_DROPPED_FRAMES;
  input [31:0]RX_HEAD_SEQ;
  input [31:0]RX_READY_BLOCKS;
  input [63:0]fdma_raddr_0;
  input fdma_rareq_0;
  output fdma_rbusy_0;
  output [63:0]fdma_rdata_0;
  input fdma_rready_0;
  input [15:0]fdma_rsize_0;
  output fdma_rvalid_0;
  input [63:0]fdma_waddr_0;
  input fdma_wareq_0;
  output fdma_wbusy_0;
  input [63:0]fdma_wdata_0;
  output fdma_wdone_0;
  output fdma_werror_0;
  input fdma_wready_0;
  input [15:0]fdma_wsize_0;
  input [7:0]fdma_wstrb_0;
  output fdma_wvalid_0;
  input [1:0]pcie_7x_mgt_rxn;
  input [1:0]pcie_7x_mgt_rxp;
  output [1:0]pcie_7x_mgt_txn;
  output [1:0]pcie_7x_mgt_txp;
  input [0:0]pcie_diff_clock_clk_n;
  input [0:0]pcie_diff_clock_clk_p;
  input pcie_rst_n;
  output r_CLEAR_INTER_0;
  output [31:0]r_CPU_FPGA_LEN_0;
  output [31:0]r_CPU_FPGA_START_ADDR_0;
  output r_CPU_REC_STATE_0;
  output r_INT_STATE_0;
  output r_RD_START_0;
  input sys_clk;
  input sys_rst_n;
  output user_lnk_up;

  wire [0:0]CPU_REC_STATE_W_0;
  wire CPU_WR_DONE_EVENT;
  wire [0:0]CPU_WR_DONE_resp_0;
  wire [31:0]DDR_STATUS_W;
  wire [31:0]FPGA_CPU_LEN_0;
  wire [31:0]FPGA_CPU_START_ADDR_0;
  wire [0:0]FPGA_CPU_irq_req;
  wire [31:0]FPGA_TEMP_W_0;
  wire [0:0]INT_STATE_W_0;
  wire [63:0]M_AXI_MEM_araddr;
  wire [1:0]M_AXI_MEM_arburst;
  wire [3:0]M_AXI_MEM_arcache;
  wire [4:0]M_AXI_MEM_arid;
  wire [7:0]M_AXI_MEM_arlen;
  wire [0:0]M_AXI_MEM_arlock;
  wire [2:0]M_AXI_MEM_arprot;
  wire [3:0]M_AXI_MEM_arqos;
  wire [0:0]M_AXI_MEM_arready;
  wire [3:0]M_AXI_MEM_arregion;
  wire [2:0]M_AXI_MEM_arsize;
  wire [0:0]M_AXI_MEM_arvalid;
  wire [63:0]M_AXI_MEM_awaddr;
  wire [1:0]M_AXI_MEM_awburst;
  wire [3:0]M_AXI_MEM_awcache;
  wire [4:0]M_AXI_MEM_awid;
  wire [7:0]M_AXI_MEM_awlen;
  wire [0:0]M_AXI_MEM_awlock;
  wire [2:0]M_AXI_MEM_awprot;
  wire [3:0]M_AXI_MEM_awqos;
  wire [0:0]M_AXI_MEM_awready;
  wire [3:0]M_AXI_MEM_awregion;
  wire [2:0]M_AXI_MEM_awsize;
  wire [0:0]M_AXI_MEM_awvalid;
  wire [4:0]M_AXI_MEM_bid;
  wire [0:0]M_AXI_MEM_bready;
  wire [1:0]M_AXI_MEM_bresp;
  wire [0:0]M_AXI_MEM_bvalid;
  wire [63:0]M_AXI_MEM_rdata;
  wire [4:0]M_AXI_MEM_rid;
  wire [0:0]M_AXI_MEM_rlast;
  wire [0:0]M_AXI_MEM_rready;
  wire [1:0]M_AXI_MEM_rresp;
  wire [0:0]M_AXI_MEM_rvalid;
  wire [63:0]M_AXI_MEM_wdata;
  wire [0:0]M_AXI_MEM_wlast;
  wire [0:0]M_AXI_MEM_wready;
  wire [7:0]M_AXI_MEM_wstrb;
  wire [0:0]M_AXI_MEM_wvalid;
  wire [31:0]RX_DROPPED_FRAMES;
  wire [31:0]RX_HEAD_SEQ;
  wire [31:0]RX_READY_BLOCKS;
  wire [63:0]fdma_raddr_0;
  wire fdma_rareq_0;
  wire fdma_rbusy_0;
  wire [63:0]fdma_rdata_0;
  wire fdma_rready_0;
  wire [15:0]fdma_rsize_0;
  wire fdma_rvalid_0;
  wire [63:0]fdma_waddr_0;
  wire fdma_wareq_0;
  wire fdma_wbusy_0;
  wire [63:0]fdma_wdata_0;
  wire fdma_wdone_0;
  wire fdma_werror_0;
  wire fdma_wready_0;
  wire [15:0]fdma_wsize_0;
  wire [7:0]fdma_wstrb_0;
  wire fdma_wvalid_0;
  wire [1:0]pcie_7x_mgt_rxn;
  wire [1:0]pcie_7x_mgt_rxp;
  wire [1:0]pcie_7x_mgt_txn;
  wire [1:0]pcie_7x_mgt_txp;
  wire [0:0]pcie_diff_clock_clk_n;
  wire [0:0]pcie_diff_clock_clk_p;
  wire pcie_rst_n;
  wire r_CLEAR_INTER_0;
  wire [31:0]r_CPU_FPGA_LEN_0;
  wire [31:0]r_CPU_FPGA_START_ADDR_0;
  wire r_CPU_REC_STATE_0;
  wire r_INT_STATE_0;
  wire r_RD_START_0;
  wire sys_clk;
  wire sys_rst_n;
  wire user_lnk_up;

  design_1 design_1_i
       (.CPU_REC_STATE_W_0(CPU_REC_STATE_W_0),
        .CPU_WR_DONE_EVENT(CPU_WR_DONE_EVENT),
        .CPU_WR_DONE_resp_0(CPU_WR_DONE_resp_0),
        .DDR_STATUS_W(DDR_STATUS_W),
        .FPGA_CPU_LEN_0(FPGA_CPU_LEN_0),
        .FPGA_CPU_START_ADDR_0(FPGA_CPU_START_ADDR_0),
        .FPGA_CPU_irq_req(FPGA_CPU_irq_req),
        .FPGA_TEMP_W_0(FPGA_TEMP_W_0),
        .INT_STATE_W_0(INT_STATE_W_0),
        .M_AXI_MEM_araddr(M_AXI_MEM_araddr),
        .M_AXI_MEM_arburst(M_AXI_MEM_arburst),
        .M_AXI_MEM_arcache(M_AXI_MEM_arcache),
        .M_AXI_MEM_arid(M_AXI_MEM_arid),
        .M_AXI_MEM_arlen(M_AXI_MEM_arlen),
        .M_AXI_MEM_arlock(M_AXI_MEM_arlock),
        .M_AXI_MEM_arprot(M_AXI_MEM_arprot),
        .M_AXI_MEM_arqos(M_AXI_MEM_arqos),
        .M_AXI_MEM_arready(M_AXI_MEM_arready),
        .M_AXI_MEM_arregion(M_AXI_MEM_arregion),
        .M_AXI_MEM_arsize(M_AXI_MEM_arsize),
        .M_AXI_MEM_arvalid(M_AXI_MEM_arvalid),
        .M_AXI_MEM_awaddr(M_AXI_MEM_awaddr),
        .M_AXI_MEM_awburst(M_AXI_MEM_awburst),
        .M_AXI_MEM_awcache(M_AXI_MEM_awcache),
        .M_AXI_MEM_awid(M_AXI_MEM_awid),
        .M_AXI_MEM_awlen(M_AXI_MEM_awlen),
        .M_AXI_MEM_awlock(M_AXI_MEM_awlock),
        .M_AXI_MEM_awprot(M_AXI_MEM_awprot),
        .M_AXI_MEM_awqos(M_AXI_MEM_awqos),
        .M_AXI_MEM_awready(M_AXI_MEM_awready),
        .M_AXI_MEM_awregion(M_AXI_MEM_awregion),
        .M_AXI_MEM_awsize(M_AXI_MEM_awsize),
        .M_AXI_MEM_awvalid(M_AXI_MEM_awvalid),
        .M_AXI_MEM_bid(M_AXI_MEM_bid),
        .M_AXI_MEM_bready(M_AXI_MEM_bready),
        .M_AXI_MEM_bresp(M_AXI_MEM_bresp),
        .M_AXI_MEM_bvalid(M_AXI_MEM_bvalid),
        .M_AXI_MEM_rdata(M_AXI_MEM_rdata),
        .M_AXI_MEM_rid(M_AXI_MEM_rid),
        .M_AXI_MEM_rlast(M_AXI_MEM_rlast),
        .M_AXI_MEM_rready(M_AXI_MEM_rready),
        .M_AXI_MEM_rresp(M_AXI_MEM_rresp),
        .M_AXI_MEM_rvalid(M_AXI_MEM_rvalid),
        .M_AXI_MEM_wdata(M_AXI_MEM_wdata),
        .M_AXI_MEM_wlast(M_AXI_MEM_wlast),
        .M_AXI_MEM_wready(M_AXI_MEM_wready),
        .M_AXI_MEM_wstrb(M_AXI_MEM_wstrb),
        .M_AXI_MEM_wvalid(M_AXI_MEM_wvalid),
        .RX_DROPPED_FRAMES(RX_DROPPED_FRAMES),
        .RX_HEAD_SEQ(RX_HEAD_SEQ),
        .RX_READY_BLOCKS(RX_READY_BLOCKS),
        .fdma_raddr_0(fdma_raddr_0),
        .fdma_rareq_0(fdma_rareq_0),
        .fdma_rbusy_0(fdma_rbusy_0),
        .fdma_rdata_0(fdma_rdata_0),
        .fdma_rready_0(fdma_rready_0),
        .fdma_rsize_0(fdma_rsize_0),
        .fdma_rvalid_0(fdma_rvalid_0),
        .fdma_waddr_0(fdma_waddr_0),
        .fdma_wareq_0(fdma_wareq_0),
        .fdma_wbusy_0(fdma_wbusy_0),
        .fdma_wdata_0(fdma_wdata_0),
        .fdma_wdone_0(fdma_wdone_0),
        .fdma_werror_0(fdma_werror_0),
        .fdma_wready_0(fdma_wready_0),
        .fdma_wsize_0(fdma_wsize_0),
        .fdma_wstrb_0(fdma_wstrb_0),
        .fdma_wvalid_0(fdma_wvalid_0),
        .pcie_7x_mgt_rxn(pcie_7x_mgt_rxn),
        .pcie_7x_mgt_rxp(pcie_7x_mgt_rxp),
        .pcie_7x_mgt_txn(pcie_7x_mgt_txn),
        .pcie_7x_mgt_txp(pcie_7x_mgt_txp),
        .pcie_diff_clock_clk_n(pcie_diff_clock_clk_n),
        .pcie_diff_clock_clk_p(pcie_diff_clock_clk_p),
        .pcie_rst_n(pcie_rst_n),
        .r_CLEAR_INTER_0(r_CLEAR_INTER_0),
        .r_CPU_FPGA_LEN_0(r_CPU_FPGA_LEN_0),
        .r_CPU_FPGA_START_ADDR_0(r_CPU_FPGA_START_ADDR_0),
        .r_CPU_REC_STATE_0(r_CPU_REC_STATE_0),
        .r_INT_STATE_0(r_INT_STATE_0),
        .r_RD_START_0(r_RD_START_0),
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .user_lnk_up(user_lnk_up));
endmodule
