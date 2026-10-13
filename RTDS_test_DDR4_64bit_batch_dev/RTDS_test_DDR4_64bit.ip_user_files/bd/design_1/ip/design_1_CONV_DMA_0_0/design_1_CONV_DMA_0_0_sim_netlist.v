// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Tue Sep 15 08:53:04 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/RTDS_test_DDR4_64bit.srcs/sources_1/bd/design_1/ip/design_1_CONV_DMA_0_0/design_1_CONV_DMA_0_0_sim_netlist.v
// Design      : design_1_CONV_DMA_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "design_1_CONV_DMA_0_0,CONV_DMA,{}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) (* IP_DEFINITION_SOURCE = "module_ref" *) 
(* X_CORE_INFO = "CONV_DMA,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module design_1_CONV_DMA_0_0
   (fdma_wstrb,
    fdma_wdone,
    fdma_werror,
    fdma_waddr,
    fdma_wareq,
    fdma_wsize,
    fdma_wbusy,
    fdma_wdata,
    fdma_wvalid,
    fdma_wready,
    fdma_raddr,
    fdma_rareq,
    fdma_rsize,
    fdma_rbusy,
    fdma_rdata,
    fdma_rvalid,
    fdma_rready,
    M_AXI_ACLK,
    M_AXI_ARESETN,
    M_AXI_AWID,
    M_AXI_AWADDR,
    M_AXI_AWLEN,
    M_AXI_AWSIZE,
    M_AXI_AWBURST,
    M_AXI_AWLOCK,
    M_AXI_AWCACHE,
    M_AXI_AWPROT,
    M_AXI_AWQOS,
    M_AXI_AWVALID,
    M_AXI_AWREADY,
    M_AXI_WID,
    M_AXI_WDATA,
    M_AXI_WSTRB,
    M_AXI_WLAST,
    M_AXI_WVALID,
    M_AXI_WREADY,
    M_AXI_BID,
    M_AXI_BRESP,
    M_AXI_BVALID,
    M_AXI_BREADY,
    M_AXI_ARID,
    M_AXI_ARADDR,
    M_AXI_ARLEN,
    M_AXI_ARSIZE,
    M_AXI_ARBURST,
    M_AXI_ARLOCK,
    M_AXI_ARCACHE,
    M_AXI_ARPROT,
    M_AXI_ARQOS,
    M_AXI_ARVALID,
    M_AXI_ARREADY,
    M_AXI_RID,
    M_AXI_RDATA,
    M_AXI_RRESP,
    M_AXI_RLAST,
    M_AXI_RVALID,
    M_AXI_RREADY);
  input [7:0]fdma_wstrb;
  output fdma_wdone;
  output fdma_werror;
  input [63:0]fdma_waddr;
  input fdma_wareq;
  input [15:0]fdma_wsize;
  output fdma_wbusy;
  input [63:0]fdma_wdata;
  output fdma_wvalid;
  input fdma_wready;
  input [63:0]fdma_raddr;
  input fdma_rareq;
  input [15:0]fdma_rsize;
  output fdma_rbusy;
  output [63:0]fdma_rdata;
  output fdma_rvalid;
  input fdma_rready;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 M_AXI_ACLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_ACLK, ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET M_AXI_ARESETN, FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, INSERT_VIP 0" *) input M_AXI_ACLK;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 M_AXI_ARESETN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input M_AXI_ARESETN;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWID" *) output [0:0]M_AXI_AWID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWADDR" *) output [63:0]M_AXI_AWADDR;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWLEN" *) output [7:0]M_AXI_AWLEN;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWSIZE" *) output [2:0]M_AXI_AWSIZE;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWBURST" *) output [1:0]M_AXI_AWBURST;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWLOCK" *) output M_AXI_AWLOCK;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWCACHE" *) output [3:0]M_AXI_AWCACHE;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWPROT" *) output [2:0]M_AXI_AWPROT;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWQOS" *) output [3:0]M_AXI_AWQOS;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWVALID" *) output M_AXI_AWVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREADY" *) input M_AXI_AWREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WID" *) output [0:0]M_AXI_WID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WDATA" *) output [63:0]M_AXI_WDATA;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WSTRB" *) output [7:0]M_AXI_WSTRB;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WLAST" *) output M_AXI_WLAST;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WVALID" *) output M_AXI_WVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WREADY" *) input M_AXI_WREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BID" *) input [0:0]M_AXI_BID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BRESP" *) input [1:0]M_AXI_BRESP;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BVALID" *) input M_AXI_BVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BREADY" *) output M_AXI_BREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARID" *) output [0:0]M_AXI_ARID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARADDR" *) output [63:0]M_AXI_ARADDR;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARLEN" *) output [7:0]M_AXI_ARLEN;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARSIZE" *) output [2:0]M_AXI_ARSIZE;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARBURST" *) output [1:0]M_AXI_ARBURST;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARLOCK" *) output M_AXI_ARLOCK;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARCACHE" *) output [3:0]M_AXI_ARCACHE;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARPROT" *) output [2:0]M_AXI_ARPROT;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARQOS" *) output [3:0]M_AXI_ARQOS;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARVALID" *) output M_AXI_ARVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREADY" *) input M_AXI_ARREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RID" *) input [0:0]M_AXI_RID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RDATA" *) input [63:0]M_AXI_RDATA;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RRESP" *) input [1:0]M_AXI_RRESP;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RLAST" *) input M_AXI_RLAST;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RVALID" *) input M_AXI_RVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RREADY" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI, DATA_WIDTH 64, PROTOCOL AXI4, FREQ_HZ 250000000, ID_WIDTH 1, ADDR_WIDTH 64, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 1, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 256, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *) output M_AXI_RREADY;

  wire \<const0> ;
  wire \<const1> ;
  wire M_AXI_ACLK;
  wire [63:0]M_AXI_ARADDR;
  wire M_AXI_ARESETN;
  wire [7:0]M_AXI_ARLEN;
  wire M_AXI_ARREADY;
  wire M_AXI_ARVALID;
  wire [63:0]M_AXI_AWADDR;
  wire [7:0]M_AXI_AWLEN;
  wire M_AXI_AWREADY;
  wire M_AXI_AWVALID;
  wire [0:0]M_AXI_BID;
  wire M_AXI_BREADY;
  wire [1:0]M_AXI_BRESP;
  wire M_AXI_BVALID;
  wire [63:0]M_AXI_RDATA;
  wire M_AXI_RREADY;
  wire M_AXI_RVALID;
  wire M_AXI_WLAST;
  wire M_AXI_WREADY;
  wire M_AXI_WVALID;
  wire [63:0]fdma_raddr;
  wire fdma_rareq;
  wire fdma_rbusy;
  wire fdma_rready;
  wire [15:0]fdma_rsize;
  wire fdma_rvalid;
  wire [63:0]fdma_waddr;
  wire fdma_wareq;
  wire fdma_wbusy;
  wire [63:0]fdma_wdata;
  wire fdma_wdone;
  wire fdma_werror;
  wire fdma_wready;
  wire [15:0]fdma_wsize;
  wire [7:0]fdma_wstrb;
  wire fdma_wvalid;

  assign M_AXI_ARBURST[1] = \<const0> ;
  assign M_AXI_ARBURST[0] = \<const1> ;
  assign M_AXI_ARCACHE[3] = \<const0> ;
  assign M_AXI_ARCACHE[2] = \<const0> ;
  assign M_AXI_ARCACHE[1] = \<const1> ;
  assign M_AXI_ARCACHE[0] = \<const0> ;
  assign M_AXI_ARID[0] = \<const0> ;
  assign M_AXI_ARLOCK = \<const0> ;
  assign M_AXI_ARPROT[2] = \<const0> ;
  assign M_AXI_ARPROT[1] = \<const0> ;
  assign M_AXI_ARPROT[0] = \<const0> ;
  assign M_AXI_ARQOS[3] = \<const0> ;
  assign M_AXI_ARQOS[2] = \<const0> ;
  assign M_AXI_ARQOS[1] = \<const0> ;
  assign M_AXI_ARQOS[0] = \<const0> ;
  assign M_AXI_ARSIZE[2] = \<const0> ;
  assign M_AXI_ARSIZE[1] = \<const1> ;
  assign M_AXI_ARSIZE[0] = \<const1> ;
  assign M_AXI_AWBURST[1] = \<const0> ;
  assign M_AXI_AWBURST[0] = \<const1> ;
  assign M_AXI_AWCACHE[3] = \<const0> ;
  assign M_AXI_AWCACHE[2] = \<const0> ;
  assign M_AXI_AWCACHE[1] = \<const1> ;
  assign M_AXI_AWCACHE[0] = \<const0> ;
  assign M_AXI_AWID[0] = \<const0> ;
  assign M_AXI_AWLOCK = \<const0> ;
  assign M_AXI_AWPROT[2] = \<const0> ;
  assign M_AXI_AWPROT[1] = \<const0> ;
  assign M_AXI_AWPROT[0] = \<const0> ;
  assign M_AXI_AWQOS[3] = \<const0> ;
  assign M_AXI_AWQOS[2] = \<const0> ;
  assign M_AXI_AWQOS[1] = \<const0> ;
  assign M_AXI_AWQOS[0] = \<const0> ;
  assign M_AXI_AWSIZE[2] = \<const0> ;
  assign M_AXI_AWSIZE[1] = \<const1> ;
  assign M_AXI_AWSIZE[0] = \<const1> ;
  assign M_AXI_WDATA[63:0] = fdma_wdata;
  assign M_AXI_WID[0] = \<const0> ;
  assign M_AXI_WSTRB[7:0] = fdma_wstrb;
  assign fdma_rdata[63:0] = M_AXI_RDATA;
  GND GND
       (.G(\<const0> ));
  VCC VCC
       (.P(\<const1> ));
  design_1_CONV_DMA_0_0_CONV_DMA inst
       (.M_AXI_ACLK(M_AXI_ACLK),
        .M_AXI_ARESETN(M_AXI_ARESETN),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_AWLEN(M_AXI_AWLEN),
        .M_AXI_AWREADY(M_AXI_AWREADY),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_BID(M_AXI_BID),
        .M_AXI_BREADY(M_AXI_BREADY),
        .M_AXI_BRESP(M_AXI_BRESP),
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_RREADY(M_AXI_RREADY),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RVALID_0(fdma_rvalid),
        .M_AXI_WLAST(M_AXI_WLAST),
        .M_AXI_WREADY(M_AXI_WREADY),
        .M_AXI_WVALID(M_AXI_WVALID),
        .Q(M_AXI_ARADDR),
        .fdma_raddr(fdma_raddr),
        .fdma_rareq(fdma_rareq),
        .fdma_rbusy(fdma_rbusy),
        .fdma_rready(fdma_rready),
        .fdma_rsize(fdma_rsize),
        .fdma_waddr(fdma_waddr),
        .fdma_wareq(fdma_wareq),
        .fdma_wbusy(fdma_wbusy),
        .fdma_wdone(fdma_wdone),
        .fdma_werror(fdma_werror),
        .fdma_wready(fdma_wready),
        .fdma_wsize(fdma_wsize),
        .fdma_wvalid(fdma_wvalid),
        .\wa_reg[63]_0 (M_AXI_AWADDR));
endmodule

(* ORIG_REF_NAME = "CONV_DMA" *) 
module design_1_CONV_DMA_0_0_CONV_DMA
   (Q,
    \wa_reg[63]_0 ,
    fdma_wdone,
    fdma_werror,
    M_AXI_AWVALID,
    fdma_wvalid,
    M_AXI_WLAST,
    M_AXI_WVALID,
    M_AXI_AWLEN,
    M_AXI_BREADY,
    fdma_wbusy,
    M_AXI_RVALID_0,
    fdma_rbusy,
    M_AXI_ARVALID,
    M_AXI_ARLEN,
    M_AXI_RREADY,
    fdma_rareq,
    M_AXI_ACLK,
    M_AXI_BVALID,
    fdma_wareq,
    fdma_waddr,
    fdma_wsize,
    fdma_wready,
    M_AXI_WREADY,
    M_AXI_BID,
    M_AXI_BRESP,
    M_AXI_ARREADY,
    M_AXI_RVALID,
    fdma_rready,
    fdma_rsize,
    fdma_raddr,
    M_AXI_ARESETN,
    M_AXI_AWREADY);
  output [63:0]Q;
  output [63:0]\wa_reg[63]_0 ;
  output fdma_wdone;
  output fdma_werror;
  output M_AXI_AWVALID;
  output fdma_wvalid;
  output M_AXI_WLAST;
  output M_AXI_WVALID;
  output [7:0]M_AXI_AWLEN;
  output M_AXI_BREADY;
  output fdma_wbusy;
  output M_AXI_RVALID_0;
  output fdma_rbusy;
  output M_AXI_ARVALID;
  output [7:0]M_AXI_ARLEN;
  output M_AXI_RREADY;
  input fdma_rareq;
  input M_AXI_ACLK;
  input M_AXI_BVALID;
  input fdma_wareq;
  input [63:0]fdma_waddr;
  input [15:0]fdma_wsize;
  input fdma_wready;
  input M_AXI_WREADY;
  input [0:0]M_AXI_BID;
  input [1:0]M_AXI_BRESP;
  input M_AXI_ARREADY;
  input M_AXI_RVALID;
  input fdma_rready;
  input [15:0]fdma_rsize;
  input [63:0]fdma_raddr;
  input M_AXI_ARESETN;
  input M_AXI_AWREADY;

  wire [8:0]A;
  wire \FSM_sequential_read_curr_st[0]_i_1_n_0 ;
  wire \FSM_sequential_read_curr_st[1]_i_2_n_0 ;
  wire \FSM_sequential_write_curr_st[0]_i_1_n_0 ;
  wire \FSM_sequential_write_curr_st[1]_i_2_n_0 ;
  wire \FSM_sequential_write_curr_st[1]_i_3_n_0 ;
  wire M_AXI_ACLK;
  wire M_AXI_ARESETN;
  wire [7:0]M_AXI_ARLEN;
  wire \M_AXI_ARLEN[7]_INST_0_i_1_n_0 ;
  wire M_AXI_ARREADY;
  wire M_AXI_ARVALID;
  wire [7:0]M_AXI_AWLEN;
  wire \M_AXI_AWLEN[7]_INST_0_i_1_n_0 ;
  wire M_AXI_AWREADY;
  wire M_AXI_AWVALID;
  wire [0:0]M_AXI_BID;
  wire M_AXI_BREADY;
  wire [1:0]M_AXI_BRESP;
  wire M_AXI_BVALID;
  wire M_AXI_RREADY;
  wire M_AXI_RVALID;
  wire M_AXI_RVALID_0;
  wire M_AXI_WLAST;
  wire M_AXI_WLAST_INST_0_i_1_n_0;
  wire M_AXI_WLAST_INST_0_i_2_n_0;
  wire M_AXI_WLAST_INST_0_i_3_n_0;
  wire M_AXI_WLAST_INST_0_i_4_n_0;
  wire M_AXI_WLAST_INST_0_i_5_n_0;
  wire M_AXI_WLAST_INST_0_i_6_n_0;
  wire M_AXI_WREADY;
  wire M_AXI_WVALID;
  wire [63:0]Q;
  wire aw_pending_i_1_n_0;
  wire aw_pending_reg_n_0;
  wire [63:0]fdma_raddr;
  wire fdma_rareq;
  wire fdma_rbusy;
  wire fdma_rready;
  wire [15:0]fdma_rsize;
  wire [63:0]fdma_waddr;
  wire fdma_wareq;
  wire fdma_wbusy;
  wire fdma_wdone;
  wire fdma_wdone_i_10_n_0;
  wire fdma_wdone_i_11_n_0;
  wire fdma_wdone_i_12_n_0;
  wire fdma_wdone_i_13_n_0;
  wire fdma_wdone_i_1_n_0;
  wire fdma_wdone_i_2_n_0;
  wire fdma_wdone_i_4_n_0;
  wire fdma_wdone_i_5_n_0;
  wire fdma_wdone_i_6_n_0;
  wire fdma_wdone_i_7_n_0;
  wire fdma_wdone_i_8_n_0;
  wire fdma_wdone_i_9_n_0;
  wire fdma_werror;
  wire fdma_werror_i_1_n_0;
  wire fdma_werror_i_2_n_0;
  wire fdma_wready;
  wire [15:0]fdma_wsize;
  wire fdma_wvalid;
  wire [15:0]in10;
  wire [63:2]in12;
  wire [63:2]in14;
  wire p_4_in;
  wire [63:0]ra;
  wire \ra[17]_i_3_n_0 ;
  wire \ra[17]_i_4_n_0 ;
  wire \ra[63]_i_10_n_0 ;
  wire \ra[63]_i_11_n_0 ;
  wire \ra[63]_i_12_n_0 ;
  wire \ra[63]_i_13_n_0 ;
  wire \ra[63]_i_14_n_0 ;
  wire \ra[63]_i_15_n_0 ;
  wire \ra[63]_i_16_n_0 ;
  wire \ra[63]_i_17_n_0 ;
  wire \ra[63]_i_18_n_0 ;
  wire \ra[63]_i_19_n_0 ;
  wire \ra[63]_i_20_n_0 ;
  wire \ra[63]_i_4_n_0 ;
  wire \ra[63]_i_5_n_0 ;
  wire \ra[63]_i_7_n_0 ;
  wire \ra[63]_i_8_n_0 ;
  wire \ra[63]_i_9_n_0 ;
  wire \ra[9]_i_3_n_0 ;
  wire \ra[9]_i_4_n_0 ;
  wire \ra[9]_i_5_n_0 ;
  wire \ra[9]_i_6_n_0 ;
  wire \ra[9]_i_7_n_0 ;
  wire \ra[9]_i_8_n_0 ;
  wire \ra[9]_i_9_n_0 ;
  wire ra_2;
  wire \ra_reg[17]_i_2_n_0 ;
  wire \ra_reg[17]_i_2_n_1 ;
  wire \ra_reg[17]_i_2_n_2 ;
  wire \ra_reg[17]_i_2_n_3 ;
  wire \ra_reg[17]_i_2_n_4 ;
  wire \ra_reg[17]_i_2_n_5 ;
  wire \ra_reg[17]_i_2_n_6 ;
  wire \ra_reg[17]_i_2_n_7 ;
  wire \ra_reg[25]_i_2_n_0 ;
  wire \ra_reg[25]_i_2_n_1 ;
  wire \ra_reg[25]_i_2_n_2 ;
  wire \ra_reg[25]_i_2_n_3 ;
  wire \ra_reg[25]_i_2_n_4 ;
  wire \ra_reg[25]_i_2_n_5 ;
  wire \ra_reg[25]_i_2_n_6 ;
  wire \ra_reg[25]_i_2_n_7 ;
  wire \ra_reg[33]_i_2_n_0 ;
  wire \ra_reg[33]_i_2_n_1 ;
  wire \ra_reg[33]_i_2_n_2 ;
  wire \ra_reg[33]_i_2_n_3 ;
  wire \ra_reg[33]_i_2_n_4 ;
  wire \ra_reg[33]_i_2_n_5 ;
  wire \ra_reg[33]_i_2_n_6 ;
  wire \ra_reg[33]_i_2_n_7 ;
  wire \ra_reg[41]_i_2_n_0 ;
  wire \ra_reg[41]_i_2_n_1 ;
  wire \ra_reg[41]_i_2_n_2 ;
  wire \ra_reg[41]_i_2_n_3 ;
  wire \ra_reg[41]_i_2_n_4 ;
  wire \ra_reg[41]_i_2_n_5 ;
  wire \ra_reg[41]_i_2_n_6 ;
  wire \ra_reg[41]_i_2_n_7 ;
  wire \ra_reg[49]_i_2_n_0 ;
  wire \ra_reg[49]_i_2_n_1 ;
  wire \ra_reg[49]_i_2_n_2 ;
  wire \ra_reg[49]_i_2_n_3 ;
  wire \ra_reg[49]_i_2_n_4 ;
  wire \ra_reg[49]_i_2_n_5 ;
  wire \ra_reg[49]_i_2_n_6 ;
  wire \ra_reg[49]_i_2_n_7 ;
  wire \ra_reg[57]_i_2_n_0 ;
  wire \ra_reg[57]_i_2_n_1 ;
  wire \ra_reg[57]_i_2_n_2 ;
  wire \ra_reg[57]_i_2_n_3 ;
  wire \ra_reg[57]_i_2_n_4 ;
  wire \ra_reg[57]_i_2_n_5 ;
  wire \ra_reg[57]_i_2_n_6 ;
  wire \ra_reg[57]_i_2_n_7 ;
  wire \ra_reg[63]_i_6_n_3 ;
  wire \ra_reg[63]_i_6_n_4 ;
  wire \ra_reg[63]_i_6_n_5 ;
  wire \ra_reg[63]_i_6_n_6 ;
  wire \ra_reg[63]_i_6_n_7 ;
  wire \ra_reg[9]_i_2_n_0 ;
  wire \ra_reg[9]_i_2_n_1 ;
  wire \ra_reg[9]_i_2_n_2 ;
  wire \ra_reg[9]_i_2_n_3 ;
  wire \ra_reg[9]_i_2_n_4 ;
  wire \ra_reg[9]_i_2_n_5 ;
  wire \ra_reg[9]_i_2_n_6 ;
  wire \ra_reg[9]_i_2_n_7 ;
  wire rb;
  wire \rb[0]_i_1_n_0 ;
  wire \rb[0]_i_2_n_0 ;
  wire \rb[1]_i_1_n_0 ;
  wire \rb[1]_i_2_n_0 ;
  wire \rb[2]_i_1_n_0 ;
  wire \rb[2]_i_2_n_0 ;
  wire \rb[3]_i_1_n_0 ;
  wire \rb[4]_i_1_n_0 ;
  wire \rb[4]_i_2_n_0 ;
  wire \rb[5]_i_1_n_0 ;
  wire \rb[5]_i_2_n_0 ;
  wire \rb[6]_i_1_n_0 ;
  wire \rb[6]_i_2_n_0 ;
  wire \rb[7]_i_1_n_0 ;
  wire \rb[7]_i_2_n_0 ;
  wire \rb[8]_i_2_n_0 ;
  wire \rb[8]_i_3_n_0 ;
  wire \rb[8]_i_4_n_0 ;
  wire \rb[8]_i_5_n_0 ;
  wire \rb[8]_i_6_n_0 ;
  wire \rb[8]_i_7_n_0 ;
  wire \rb[8]_i_8_n_0 ;
  wire \rb_reg_n_0_[0] ;
  wire \rb_reg_n_0_[1] ;
  wire \rb_reg_n_0_[2] ;
  wire \rb_reg_n_0_[3] ;
  wire \rb_reg_n_0_[4] ;
  wire \rb_reg_n_0_[5] ;
  wire \rb_reg_n_0_[6] ;
  wire \rb_reg_n_0_[7] ;
  wire \rb_reg_n_0_[8] ;
  wire [0:0]rbeat;
  wire \rbeat[1]_i_1_n_0 ;
  wire \rbeat[2]_i_1_n_0 ;
  wire \rbeat[3]_i_1_n_0 ;
  wire \rbeat[4]_i_1_n_0 ;
  wire \rbeat[5]_i_1_n_0 ;
  wire \rbeat[5]_i_2_n_0 ;
  wire \rbeat[6]_i_1_n_0 ;
  wire \rbeat[7]_i_1_n_0 ;
  wire \rbeat[8]_i_2_n_0 ;
  wire \rbeat[8]_i_3_n_0 ;
  wire rbeat_3;
  wire \rbeat_reg_n_0_[0] ;
  wire \rbeat_reg_n_0_[1] ;
  wire \rbeat_reg_n_0_[2] ;
  wire \rbeat_reg_n_0_[3] ;
  wire \rbeat_reg_n_0_[4] ;
  wire \rbeat_reg_n_0_[5] ;
  wire \rbeat_reg_n_0_[6] ;
  wire \rbeat_reg_n_0_[7] ;
  wire \rbeat_reg_n_0_[8] ;
  wire [1:0]read_curr_st;
  wire \read_curr_st[0]_i_1_n_0 ;
  wire \read_curr_st[1]_i_1_n_0 ;
  wire [1:0]read_curr_st__0;
  wire read_next_st;
  wire read_next_st0__16;
  wire [15:0]rleft;
  wire \rleft[15]_i_10_n_0 ;
  wire \rleft[15]_i_3_n_0 ;
  wire \rleft[15]_i_4_n_0 ;
  wire \rleft[15]_i_5_n_0 ;
  wire \rleft[15]_i_6_n_0 ;
  wire \rleft[15]_i_7_n_0 ;
  wire \rleft[15]_i_8_n_0 ;
  wire \rleft[15]_i_9_n_0 ;
  wire \rleft[7]_i_10_n_0 ;
  wire \rleft[7]_i_3_n_0 ;
  wire \rleft[7]_i_4_n_0 ;
  wire \rleft[7]_i_5_n_0 ;
  wire \rleft[7]_i_6_n_0 ;
  wire \rleft[7]_i_7_n_0 ;
  wire \rleft[7]_i_8_n_0 ;
  wire \rleft[7]_i_9_n_0 ;
  wire \rleft_reg[15]_i_2_n_1 ;
  wire \rleft_reg[15]_i_2_n_10 ;
  wire \rleft_reg[15]_i_2_n_11 ;
  wire \rleft_reg[15]_i_2_n_12 ;
  wire \rleft_reg[15]_i_2_n_13 ;
  wire \rleft_reg[15]_i_2_n_14 ;
  wire \rleft_reg[15]_i_2_n_15 ;
  wire \rleft_reg[15]_i_2_n_2 ;
  wire \rleft_reg[15]_i_2_n_3 ;
  wire \rleft_reg[15]_i_2_n_4 ;
  wire \rleft_reg[15]_i_2_n_5 ;
  wire \rleft_reg[15]_i_2_n_6 ;
  wire \rleft_reg[15]_i_2_n_7 ;
  wire \rleft_reg[15]_i_2_n_8 ;
  wire \rleft_reg[15]_i_2_n_9 ;
  wire \rleft_reg[7]_i_2_n_0 ;
  wire \rleft_reg[7]_i_2_n_1 ;
  wire \rleft_reg[7]_i_2_n_10 ;
  wire \rleft_reg[7]_i_2_n_11 ;
  wire \rleft_reg[7]_i_2_n_12 ;
  wire \rleft_reg[7]_i_2_n_13 ;
  wire \rleft_reg[7]_i_2_n_14 ;
  wire \rleft_reg[7]_i_2_n_15 ;
  wire \rleft_reg[7]_i_2_n_2 ;
  wire \rleft_reg[7]_i_2_n_3 ;
  wire \rleft_reg[7]_i_2_n_4 ;
  wire \rleft_reg[7]_i_2_n_5 ;
  wire \rleft_reg[7]_i_2_n_6 ;
  wire \rleft_reg[7]_i_2_n_7 ;
  wire \rleft_reg[7]_i_2_n_8 ;
  wire \rleft_reg[7]_i_2_n_9 ;
  wire \rleft_reg_n_0_[0] ;
  wire \rleft_reg_n_0_[10] ;
  wire \rleft_reg_n_0_[11] ;
  wire \rleft_reg_n_0_[12] ;
  wire \rleft_reg_n_0_[13] ;
  wire \rleft_reg_n_0_[14] ;
  wire \rleft_reg_n_0_[15] ;
  wire \rleft_reg_n_0_[1] ;
  wire \rleft_reg_n_0_[2] ;
  wire \rleft_reg_n_0_[3] ;
  wire \rleft_reg_n_0_[4] ;
  wire \rleft_reg_n_0_[5] ;
  wire \rleft_reg_n_0_[6] ;
  wire \rleft_reg_n_0_[7] ;
  wire \rleft_reg_n_0_[8] ;
  wire \rleft_reg_n_0_[9] ;
  wire \update_wb.available1 ;
  wire \update_wb.available1_carry__0_n_0 ;
  wire \update_wb.available1_carry__0_n_1 ;
  wire \update_wb.available1_carry__0_n_2 ;
  wire \update_wb.available1_carry__0_n_3 ;
  wire \update_wb.available1_carry__0_n_4 ;
  wire \update_wb.available1_carry__0_n_5 ;
  wire \update_wb.available1_carry__0_n_6 ;
  wire \update_wb.available1_carry__0_n_7 ;
  wire \update_wb.available1_carry_i_10__0_n_0 ;
  wire \update_wb.available1_carry_i_10_n_0 ;
  wire \update_wb.available1_carry_i_11__0_n_0 ;
  wire \update_wb.available1_carry_i_11_n_0 ;
  wire \update_wb.available1_carry_i_12__0_n_0 ;
  wire \update_wb.available1_carry_i_12_n_0 ;
  wire \update_wb.available1_carry_i_13__0_n_0 ;
  wire \update_wb.available1_carry_i_13_n_0 ;
  wire \update_wb.available1_carry_i_14__0_n_0 ;
  wire \update_wb.available1_carry_i_14_n_0 ;
  wire \update_wb.available1_carry_i_15__0_n_0 ;
  wire \update_wb.available1_carry_i_15_n_0 ;
  wire \update_wb.available1_carry_i_16__0_n_0 ;
  wire \update_wb.available1_carry_i_16_n_0 ;
  wire \update_wb.available1_carry_i_17_n_0 ;
  wire \update_wb.available1_carry_i_1__0_n_0 ;
  wire \update_wb.available1_carry_i_1_n_0 ;
  wire \update_wb.available1_carry_i_2__0_n_0 ;
  wire \update_wb.available1_carry_i_2_n_0 ;
  wire \update_wb.available1_carry_i_3__0_n_0 ;
  wire \update_wb.available1_carry_i_3_n_0 ;
  wire \update_wb.available1_carry_i_4__0_n_0 ;
  wire \update_wb.available1_carry_i_4_n_0 ;
  wire \update_wb.available1_carry_i_5__0_n_0 ;
  wire \update_wb.available1_carry_i_5_n_0 ;
  wire \update_wb.available1_carry_i_6__0_n_0 ;
  wire \update_wb.available1_carry_i_6_n_0 ;
  wire \update_wb.available1_carry_i_7__0_n_0 ;
  wire \update_wb.available1_carry_i_7_n_0 ;
  wire \update_wb.available1_carry_i_8__0_n_0 ;
  wire \update_wb.available1_carry_i_8_n_0 ;
  wire \update_wb.available1_carry_i_9__0_n_0 ;
  wire \update_wb.available1_carry_i_9_n_0 ;
  wire \update_wb.available1_carry_n_1 ;
  wire \update_wb.available1_carry_n_2 ;
  wire \update_wb.available1_carry_n_3 ;
  wire \update_wb.available1_carry_n_4 ;
  wire \update_wb.available1_carry_n_5 ;
  wire \update_wb.available1_carry_n_6 ;
  wire \update_wb.available1_carry_n_7 ;
  wire [10:4]\update_wb.available3 ;
  wire w_pending_i_1_n_0;
  wire w_pending_reg_n_0;
  wire [63:0]wa;
  wire \wa[17]_i_3_n_0 ;
  wire \wa[17]_i_4_n_0 ;
  wire \wa[63]_i_3_n_0 ;
  wire \wa[9]_i_3_n_0 ;
  wire \wa[9]_i_4_n_0 ;
  wire \wa[9]_i_5_n_0 ;
  wire \wa[9]_i_6_n_0 ;
  wire \wa[9]_i_7_n_0 ;
  wire \wa[9]_i_8_n_0 ;
  wire \wa[9]_i_9_n_0 ;
  wire wa_0;
  wire \wa_reg[17]_i_2_n_0 ;
  wire \wa_reg[17]_i_2_n_1 ;
  wire \wa_reg[17]_i_2_n_2 ;
  wire \wa_reg[17]_i_2_n_3 ;
  wire \wa_reg[17]_i_2_n_4 ;
  wire \wa_reg[17]_i_2_n_5 ;
  wire \wa_reg[17]_i_2_n_6 ;
  wire \wa_reg[17]_i_2_n_7 ;
  wire \wa_reg[25]_i_2_n_0 ;
  wire \wa_reg[25]_i_2_n_1 ;
  wire \wa_reg[25]_i_2_n_2 ;
  wire \wa_reg[25]_i_2_n_3 ;
  wire \wa_reg[25]_i_2_n_4 ;
  wire \wa_reg[25]_i_2_n_5 ;
  wire \wa_reg[25]_i_2_n_6 ;
  wire \wa_reg[25]_i_2_n_7 ;
  wire \wa_reg[33]_i_2_n_0 ;
  wire \wa_reg[33]_i_2_n_1 ;
  wire \wa_reg[33]_i_2_n_2 ;
  wire \wa_reg[33]_i_2_n_3 ;
  wire \wa_reg[33]_i_2_n_4 ;
  wire \wa_reg[33]_i_2_n_5 ;
  wire \wa_reg[33]_i_2_n_6 ;
  wire \wa_reg[33]_i_2_n_7 ;
  wire \wa_reg[41]_i_2_n_0 ;
  wire \wa_reg[41]_i_2_n_1 ;
  wire \wa_reg[41]_i_2_n_2 ;
  wire \wa_reg[41]_i_2_n_3 ;
  wire \wa_reg[41]_i_2_n_4 ;
  wire \wa_reg[41]_i_2_n_5 ;
  wire \wa_reg[41]_i_2_n_6 ;
  wire \wa_reg[41]_i_2_n_7 ;
  wire \wa_reg[49]_i_2_n_0 ;
  wire \wa_reg[49]_i_2_n_1 ;
  wire \wa_reg[49]_i_2_n_2 ;
  wire \wa_reg[49]_i_2_n_3 ;
  wire \wa_reg[49]_i_2_n_4 ;
  wire \wa_reg[49]_i_2_n_5 ;
  wire \wa_reg[49]_i_2_n_6 ;
  wire \wa_reg[49]_i_2_n_7 ;
  wire \wa_reg[57]_i_2_n_0 ;
  wire \wa_reg[57]_i_2_n_1 ;
  wire \wa_reg[57]_i_2_n_2 ;
  wire \wa_reg[57]_i_2_n_3 ;
  wire \wa_reg[57]_i_2_n_4 ;
  wire \wa_reg[57]_i_2_n_5 ;
  wire \wa_reg[57]_i_2_n_6 ;
  wire \wa_reg[57]_i_2_n_7 ;
  wire [63:0]\wa_reg[63]_0 ;
  wire \wa_reg[63]_i_4_n_3 ;
  wire \wa_reg[63]_i_4_n_4 ;
  wire \wa_reg[63]_i_4_n_5 ;
  wire \wa_reg[63]_i_4_n_6 ;
  wire \wa_reg[63]_i_4_n_7 ;
  wire \wa_reg[9]_i_2_n_0 ;
  wire \wa_reg[9]_i_2_n_1 ;
  wire \wa_reg[9]_i_2_n_2 ;
  wire \wa_reg[9]_i_2_n_3 ;
  wire \wa_reg[9]_i_2_n_4 ;
  wire \wa_reg[9]_i_2_n_5 ;
  wire \wa_reg[9]_i_2_n_6 ;
  wire \wa_reg[9]_i_2_n_7 ;
  wire wb;
  wire \wb[0]_i_2_n_0 ;
  wire \wb[2]_i_2_n_0 ;
  wire \wb[4]_i_2_n_0 ;
  wire \wb[6]_i_2_n_0 ;
  wire \wb[8]_i_3_n_0 ;
  wire \wb[8]_i_4_n_0 ;
  wire \wb[8]_i_5_n_0 ;
  wire \wb[8]_i_6_n_0 ;
  wire \wb[8]_i_7_n_0 ;
  wire \wb_reg_n_0_[0] ;
  wire \wb_reg_n_0_[1] ;
  wire \wb_reg_n_0_[2] ;
  wire \wb_reg_n_0_[3] ;
  wire \wb_reg_n_0_[4] ;
  wire \wb_reg_n_0_[5] ;
  wire \wb_reg_n_0_[6] ;
  wire \wb_reg_n_0_[7] ;
  wire \wb_reg_n_0_[8] ;
  wire [8:0]wbeat;
  wire \wbeat[5]_i_2_n_0 ;
  wire \wbeat[8]_i_3_n_0 ;
  wire wbeat_1;
  wire \wbeat_reg_n_0_[0] ;
  wire \wbeat_reg_n_0_[1] ;
  wire \wbeat_reg_n_0_[2] ;
  wire \wbeat_reg_n_0_[3] ;
  wire \wbeat_reg_n_0_[4] ;
  wire \wbeat_reg_n_0_[5] ;
  wire \wbeat_reg_n_0_[6] ;
  wire \wbeat_reg_n_0_[7] ;
  wire \wbeat_reg_n_0_[8] ;
  wire [15:0]wleft;
  wire \wleft[15]_i_10_n_0 ;
  wire \wleft[15]_i_3_n_0 ;
  wire \wleft[15]_i_4_n_0 ;
  wire \wleft[15]_i_5_n_0 ;
  wire \wleft[15]_i_6_n_0 ;
  wire \wleft[15]_i_7_n_0 ;
  wire \wleft[15]_i_8_n_0 ;
  wire \wleft[15]_i_9_n_0 ;
  wire \wleft[7]_i_10_n_0 ;
  wire \wleft[7]_i_3_n_0 ;
  wire \wleft[7]_i_4_n_0 ;
  wire \wleft[7]_i_5_n_0 ;
  wire \wleft[7]_i_6_n_0 ;
  wire \wleft[7]_i_7_n_0 ;
  wire \wleft[7]_i_8_n_0 ;
  wire \wleft[7]_i_9_n_0 ;
  wire \wleft_reg[15]_i_2_n_1 ;
  wire \wleft_reg[15]_i_2_n_2 ;
  wire \wleft_reg[15]_i_2_n_3 ;
  wire \wleft_reg[15]_i_2_n_4 ;
  wire \wleft_reg[15]_i_2_n_5 ;
  wire \wleft_reg[15]_i_2_n_6 ;
  wire \wleft_reg[15]_i_2_n_7 ;
  wire \wleft_reg[7]_i_2_n_0 ;
  wire \wleft_reg[7]_i_2_n_1 ;
  wire \wleft_reg[7]_i_2_n_2 ;
  wire \wleft_reg[7]_i_2_n_3 ;
  wire \wleft_reg[7]_i_2_n_4 ;
  wire \wleft_reg[7]_i_2_n_5 ;
  wire \wleft_reg[7]_i_2_n_6 ;
  wire \wleft_reg[7]_i_2_n_7 ;
  wire \wleft_reg_n_0_[0] ;
  wire \wleft_reg_n_0_[10] ;
  wire \wleft_reg_n_0_[11] ;
  wire \wleft_reg_n_0_[12] ;
  wire \wleft_reg_n_0_[13] ;
  wire \wleft_reg_n_0_[14] ;
  wire \wleft_reg_n_0_[15] ;
  wire \wleft_reg_n_0_[1] ;
  wire \wleft_reg_n_0_[2] ;
  wire \wleft_reg_n_0_[3] ;
  wire \wleft_reg_n_0_[4] ;
  wire \wleft_reg_n_0_[5] ;
  wire \wleft_reg_n_0_[6] ;
  wire \wleft_reg_n_0_[7] ;
  wire \wleft_reg_n_0_[8] ;
  wire \wleft_reg_n_0_[9] ;
  wire [1:0]write_curr_st;
  wire \write_curr_st[0]_i_1_n_0 ;
  wire \write_curr_st[1]_i_1_n_0 ;
  wire [1:0]write_curr_st__0;
  wire write_next_st;
  wire write_next_st1__23;
  wire [7:5]\NLW_ra_reg[63]_i_6_CO_UNCONNECTED ;
  wire [7:6]\NLW_ra_reg[63]_i_6_O_UNCONNECTED ;
  wire [7:7]\NLW_rleft_reg[15]_i_2_CO_UNCONNECTED ;
  wire [7:0]\NLW_update_wb.available1_carry_O_UNCONNECTED ;
  wire [7:0]\NLW_update_wb.available1_carry__0_O_UNCONNECTED ;
  wire [7:5]\NLW_wa_reg[63]_i_4_CO_UNCONNECTED ;
  wire [7:6]\NLW_wa_reg[63]_i_4_O_UNCONNECTED ;
  wire [7:7]\NLW_wleft_reg[15]_i_2_CO_UNCONNECTED ;

  (* SOFT_HLUTNM = "soft_lutpair72" *) 
  LUT3 #(
    .INIT(8'h5D)) 
    \FSM_sequential_read_curr_st[0]_i_1 
       (.I0(read_curr_st__0[0]),
        .I1(read_curr_st__0[1]),
        .I2(\ra[63]_i_4_n_0 ),
        .O(\FSM_sequential_read_curr_st[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFFEAAFEAAFEAAFEA)) 
    \FSM_sequential_read_curr_st[1]_i_1 
       (.I0(\ra[63]_i_5_n_0 ),
        .I1(M_AXI_ARREADY),
        .I2(read_curr_st__0[1]),
        .I3(read_curr_st__0[0]),
        .I4(M_AXI_RVALID_0),
        .I5(read_next_st0__16),
        .O(read_next_st));
  (* SOFT_HLUTNM = "soft_lutpair72" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \FSM_sequential_read_curr_st[1]_i_2 
       (.I0(read_curr_st__0[0]),
        .I1(read_curr_st__0[1]),
        .O(\FSM_sequential_read_curr_st[1]_i_2_n_0 ));
  (* FSM_ENCODED_STATES = "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01" *) 
  FDRE \FSM_sequential_read_curr_st_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(read_next_st),
        .D(\FSM_sequential_read_curr_st[0]_i_1_n_0 ),
        .Q(read_curr_st__0[0]),
        .R(fdma_wdone_i_1_n_0));
  (* FSM_ENCODED_STATES = "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01" *) 
  FDRE \FSM_sequential_read_curr_st_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(read_next_st),
        .D(\FSM_sequential_read_curr_st[1]_i_2_n_0 ),
        .Q(read_curr_st__0[1]),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair16" *) 
  LUT3 #(
    .INIT(8'h4F)) 
    \FSM_sequential_write_curr_st[0]_i_1 
       (.I0(write_next_st1__23),
        .I1(write_curr_st__0[1]),
        .I2(write_curr_st__0[0]),
        .O(\FSM_sequential_write_curr_st[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFF040404)) 
    \FSM_sequential_write_curr_st[1]_i_1 
       (.I0(write_curr_st__0[1]),
        .I1(fdma_wareq),
        .I2(fdma_wdone_i_4_n_0),
        .I3(\wa[63]_i_3_n_0 ),
        .I4(write_curr_st__0[0]),
        .I5(\FSM_sequential_write_curr_st[1]_i_3_n_0 ),
        .O(write_next_st));
  (* SOFT_HLUTNM = "soft_lutpair28" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \FSM_sequential_write_curr_st[1]_i_2 
       (.I0(write_curr_st__0[1]),
        .I1(write_curr_st__0[0]),
        .O(\FSM_sequential_write_curr_st[1]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair16" *) 
  LUT4 #(
    .INIT(16'h0F10)) 
    \FSM_sequential_write_curr_st[1]_i_3 
       (.I0(w_pending_reg_n_0),
        .I1(aw_pending_reg_n_0),
        .I2(write_curr_st__0[1]),
        .I3(write_curr_st__0[0]),
        .O(\FSM_sequential_write_curr_st[1]_i_3_n_0 ));
  (* FSM_ENCODED_STATES = "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01" *) 
  FDRE \FSM_sequential_write_curr_st_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(write_next_st),
        .D(\FSM_sequential_write_curr_st[0]_i_1_n_0 ),
        .Q(write_curr_st__0[0]),
        .R(fdma_wdone_i_1_n_0));
  (* FSM_ENCODED_STATES = "iSTATE:10,iSTATE0:11,iSTATE1:00,iSTATE2:01" *) 
  FDRE \FSM_sequential_write_curr_st_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(write_next_st),
        .D(\FSM_sequential_write_curr_st[1]_i_2_n_0 ),
        .Q(write_curr_st__0[1]),
        .R(fdma_wdone_i_1_n_0));
  LUT1 #(
    .INIT(2'h1)) 
    \M_AXI_ARLEN[0]_INST_0 
       (.I0(\rb_reg_n_0_[0] ),
        .O(M_AXI_ARLEN[0]));
  (* SOFT_HLUTNM = "soft_lutpair71" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \M_AXI_ARLEN[1]_INST_0 
       (.I0(\rb_reg_n_0_[1] ),
        .I1(\rb_reg_n_0_[0] ),
        .O(M_AXI_ARLEN[1]));
  (* SOFT_HLUTNM = "soft_lutpair71" *) 
  LUT3 #(
    .INIT(8'hA9)) 
    \M_AXI_ARLEN[2]_INST_0 
       (.I0(\rb_reg_n_0_[2] ),
        .I1(\rb_reg_n_0_[0] ),
        .I2(\rb_reg_n_0_[1] ),
        .O(M_AXI_ARLEN[2]));
  (* SOFT_HLUTNM = "soft_lutpair20" *) 
  LUT4 #(
    .INIT(16'hAAA9)) 
    \M_AXI_ARLEN[3]_INST_0 
       (.I0(\rb_reg_n_0_[3] ),
        .I1(\rb_reg_n_0_[1] ),
        .I2(\rb_reg_n_0_[0] ),
        .I3(\rb_reg_n_0_[2] ),
        .O(M_AXI_ARLEN[3]));
  (* SOFT_HLUTNM = "soft_lutpair11" *) 
  LUT5 #(
    .INIT(32'hAAAAAAA9)) 
    \M_AXI_ARLEN[4]_INST_0 
       (.I0(\rb_reg_n_0_[4] ),
        .I1(\rb_reg_n_0_[2] ),
        .I2(\rb_reg_n_0_[0] ),
        .I3(\rb_reg_n_0_[1] ),
        .I4(\rb_reg_n_0_[3] ),
        .O(M_AXI_ARLEN[4]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAAAA9)) 
    \M_AXI_ARLEN[5]_INST_0 
       (.I0(\rb_reg_n_0_[5] ),
        .I1(\rb_reg_n_0_[3] ),
        .I2(\rb_reg_n_0_[1] ),
        .I3(\rb_reg_n_0_[0] ),
        .I4(\rb_reg_n_0_[2] ),
        .I5(\rb_reg_n_0_[4] ),
        .O(M_AXI_ARLEN[5]));
  (* SOFT_HLUTNM = "soft_lutpair70" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \M_AXI_ARLEN[6]_INST_0 
       (.I0(\rb_reg_n_0_[6] ),
        .I1(\M_AXI_ARLEN[7]_INST_0_i_1_n_0 ),
        .O(M_AXI_ARLEN[6]));
  (* SOFT_HLUTNM = "soft_lutpair70" *) 
  LUT3 #(
    .INIT(8'hA9)) 
    \M_AXI_ARLEN[7]_INST_0 
       (.I0(\rb_reg_n_0_[7] ),
        .I1(\M_AXI_ARLEN[7]_INST_0_i_1_n_0 ),
        .I2(\rb_reg_n_0_[6] ),
        .O(M_AXI_ARLEN[7]));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \M_AXI_ARLEN[7]_INST_0_i_1 
       (.I0(\rb_reg_n_0_[4] ),
        .I1(\rb_reg_n_0_[2] ),
        .I2(\rb_reg_n_0_[0] ),
        .I3(\rb_reg_n_0_[1] ),
        .I4(\rb_reg_n_0_[3] ),
        .I5(\rb_reg_n_0_[5] ),
        .O(\M_AXI_ARLEN[7]_INST_0_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair113" *) 
  LUT2 #(
    .INIT(4'h2)) 
    M_AXI_ARVALID_INST_0
       (.I0(read_curr_st[1]),
        .I1(read_curr_st[0]),
        .O(M_AXI_ARVALID));
  LUT1 #(
    .INIT(2'h1)) 
    \M_AXI_AWLEN[0]_INST_0 
       (.I0(\wb_reg_n_0_[0] ),
        .O(M_AXI_AWLEN[0]));
  (* SOFT_HLUTNM = "soft_lutpair25" *) 
  LUT2 #(
    .INIT(4'h9)) 
    \M_AXI_AWLEN[1]_INST_0 
       (.I0(\wb_reg_n_0_[0] ),
        .I1(\wb_reg_n_0_[1] ),
        .O(M_AXI_AWLEN[1]));
  (* SOFT_HLUTNM = "soft_lutpair15" *) 
  LUT3 #(
    .INIT(8'hE1)) 
    \M_AXI_AWLEN[2]_INST_0 
       (.I0(\wb_reg_n_0_[1] ),
        .I1(\wb_reg_n_0_[0] ),
        .I2(\wb_reg_n_0_[2] ),
        .O(M_AXI_AWLEN[2]));
  (* SOFT_HLUTNM = "soft_lutpair15" *) 
  LUT4 #(
    .INIT(16'hAAA9)) 
    \M_AXI_AWLEN[3]_INST_0 
       (.I0(\wb_reg_n_0_[3] ),
        .I1(\wb_reg_n_0_[1] ),
        .I2(\wb_reg_n_0_[0] ),
        .I3(\wb_reg_n_0_[2] ),
        .O(M_AXI_AWLEN[3]));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT5 #(
    .INIT(32'hAAAAAAA9)) 
    \M_AXI_AWLEN[4]_INST_0 
       (.I0(\wb_reg_n_0_[4] ),
        .I1(\wb_reg_n_0_[2] ),
        .I2(\wb_reg_n_0_[0] ),
        .I3(\wb_reg_n_0_[1] ),
        .I4(\wb_reg_n_0_[3] ),
        .O(M_AXI_AWLEN[4]));
  LUT6 #(
    .INIT(64'hAAAAAAAAAAAAAAA9)) 
    \M_AXI_AWLEN[5]_INST_0 
       (.I0(\wb_reg_n_0_[5] ),
        .I1(\wb_reg_n_0_[3] ),
        .I2(\wb_reg_n_0_[1] ),
        .I3(\wb_reg_n_0_[0] ),
        .I4(\wb_reg_n_0_[2] ),
        .I5(\wb_reg_n_0_[4] ),
        .O(M_AXI_AWLEN[5]));
  LUT5 #(
    .INIT(32'hFFFE0001)) 
    \M_AXI_AWLEN[6]_INST_0 
       (.I0(\wb_reg_n_0_[5] ),
        .I1(\wb_reg_n_0_[3] ),
        .I2(\M_AXI_AWLEN[7]_INST_0_i_1_n_0 ),
        .I3(\wb_reg_n_0_[4] ),
        .I4(\wb_reg_n_0_[6] ),
        .O(M_AXI_AWLEN[6]));
  LUT6 #(
    .INIT(64'hFFFFFFFE00000001)) 
    \M_AXI_AWLEN[7]_INST_0 
       (.I0(\wb_reg_n_0_[6] ),
        .I1(\wb_reg_n_0_[4] ),
        .I2(\M_AXI_AWLEN[7]_INST_0_i_1_n_0 ),
        .I3(\wb_reg_n_0_[3] ),
        .I4(\wb_reg_n_0_[5] ),
        .I5(\wb_reg_n_0_[7] ),
        .O(M_AXI_AWLEN[7]));
  (* SOFT_HLUTNM = "soft_lutpair25" *) 
  LUT3 #(
    .INIT(8'hFE)) 
    \M_AXI_AWLEN[7]_INST_0_i_1 
       (.I0(\wb_reg_n_0_[1] ),
        .I1(\wb_reg_n_0_[0] ),
        .I2(\wb_reg_n_0_[2] ),
        .O(\M_AXI_AWLEN[7]_INST_0_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair24" *) 
  LUT3 #(
    .INIT(8'h40)) 
    M_AXI_AWVALID_INST_0
       (.I0(write_curr_st[0]),
        .I1(write_curr_st[1]),
        .I2(aw_pending_reg_n_0),
        .O(M_AXI_AWVALID));
  (* SOFT_HLUTNM = "soft_lutpair26" *) 
  LUT2 #(
    .INIT(4'h8)) 
    M_AXI_BREADY_INST_0
       (.I0(write_curr_st[1]),
        .I1(write_curr_st[0]),
        .O(M_AXI_BREADY));
  (* SOFT_HLUTNM = "soft_lutpair19" *) 
  LUT3 #(
    .INIT(8'h80)) 
    M_AXI_RREADY_INST_0
       (.I0(read_curr_st[1]),
        .I1(read_curr_st[0]),
        .I2(fdma_rready),
        .O(M_AXI_RREADY));
  LUT6 #(
    .INIT(64'h8228000000000000)) 
    M_AXI_WLAST_INST_0
       (.I0(M_AXI_WLAST_INST_0_i_1_n_0),
        .I1(\wbeat_reg_n_0_[5] ),
        .I2(\wb_reg_n_0_[5] ),
        .I3(M_AXI_WLAST_INST_0_i_2_n_0),
        .I4(M_AXI_WLAST_INST_0_i_3_n_0),
        .I5(M_AXI_WLAST_INST_0_i_4_n_0),
        .O(M_AXI_WLAST));
  LUT5 #(
    .INIT(32'h90060990)) 
    M_AXI_WLAST_INST_0_i_1
       (.I0(\wbeat_reg_n_0_[4] ),
        .I1(\wb_reg_n_0_[4] ),
        .I2(\M_AXI_AWLEN[7]_INST_0_i_1_n_0 ),
        .I3(\wb_reg_n_0_[3] ),
        .I4(\wbeat_reg_n_0_[3] ),
        .O(M_AXI_WLAST_INST_0_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    M_AXI_WLAST_INST_0_i_2
       (.I0(\wb_reg_n_0_[3] ),
        .I1(\wb_reg_n_0_[1] ),
        .I2(\wb_reg_n_0_[0] ),
        .I3(\wb_reg_n_0_[2] ),
        .I4(\wb_reg_n_0_[4] ),
        .O(M_AXI_WLAST_INST_0_i_2_n_0));
  LUT6 #(
    .INIT(64'h8020200808020280)) 
    M_AXI_WLAST_INST_0_i_3
       (.I0(M_AXI_WLAST_INST_0_i_5_n_0),
        .I1(\wbeat_reg_n_0_[6] ),
        .I2(\wbeat_reg_n_0_[7] ),
        .I3(\wb_reg_n_0_[6] ),
        .I4(M_AXI_WLAST_INST_0_i_6_n_0),
        .I5(\wb_reg_n_0_[7] ),
        .O(M_AXI_WLAST_INST_0_i_3_n_0));
  LUT5 #(
    .INIT(32'hAAA95556)) 
    M_AXI_WLAST_INST_0_i_4
       (.I0(\wb_reg_n_0_[8] ),
        .I1(\wb_reg_n_0_[6] ),
        .I2(M_AXI_WLAST_INST_0_i_6_n_0),
        .I3(\wb_reg_n_0_[7] ),
        .I4(\wbeat_reg_n_0_[8] ),
        .O(M_AXI_WLAST_INST_0_i_4_n_0));
  LUT6 #(
    .INIT(64'h4010200804010280)) 
    M_AXI_WLAST_INST_0_i_5
       (.I0(\wbeat_reg_n_0_[0] ),
        .I1(\wbeat_reg_n_0_[1] ),
        .I2(\wbeat_reg_n_0_[2] ),
        .I3(\wb_reg_n_0_[1] ),
        .I4(\wb_reg_n_0_[0] ),
        .I5(\wb_reg_n_0_[2] ),
        .O(M_AXI_WLAST_INST_0_i_5_n_0));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    M_AXI_WLAST_INST_0_i_6
       (.I0(\wb_reg_n_0_[4] ),
        .I1(\wb_reg_n_0_[2] ),
        .I2(\wb_reg_n_0_[0] ),
        .I3(\wb_reg_n_0_[1] ),
        .I4(\wb_reg_n_0_[3] ),
        .I5(\wb_reg_n_0_[5] ),
        .O(M_AXI_WLAST_INST_0_i_6_n_0));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT4 #(
    .INIT(16'h0800)) 
    M_AXI_WVALID_INST_0
       (.I0(w_pending_reg_n_0),
        .I1(fdma_wready),
        .I2(write_curr_st[0]),
        .I3(write_curr_st[1]),
        .O(M_AXI_WVALID));
  LUT6 #(
    .INIT(64'hAAAAFFFFA2AAAAAA)) 
    aw_pending_i_1
       (.I0(aw_pending_reg_n_0),
        .I1(M_AXI_AWREADY),
        .I2(write_curr_st[0]),
        .I3(write_curr_st[1]),
        .I4(write_curr_st__0[1]),
        .I5(write_curr_st__0[0]),
        .O(aw_pending_i_1_n_0));
  FDRE aw_pending_reg
       (.C(M_AXI_ACLK),
        .CE(1'b1),
        .D(aw_pending_i_1_n_0),
        .Q(aw_pending_reg_n_0),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair73" *) 
  LUT2 #(
    .INIT(4'hE)) 
    fdma_rbusy_INST_0
       (.I0(read_curr_st[1]),
        .I1(read_curr_st[0]),
        .O(fdma_rbusy));
  (* SOFT_HLUTNM = "soft_lutpair19" *) 
  LUT4 #(
    .INIT(16'h8000)) 
    fdma_rvalid_INST_0
       (.I0(M_AXI_RVALID),
        .I1(fdma_rready),
        .I2(read_curr_st[0]),
        .I3(read_curr_st[1]),
        .O(M_AXI_RVALID_0));
  LUT2 #(
    .INIT(4'hE)) 
    fdma_wbusy_INST_0
       (.I0(write_curr_st[1]),
        .I1(write_curr_st[0]),
        .O(fdma_wbusy));
  LUT1 #(
    .INIT(2'h1)) 
    fdma_wdone_i_1
       (.I0(M_AXI_ARESETN),
        .O(fdma_wdone_i_1_n_0));
  LUT4 #(
    .INIT(16'h6FF6)) 
    fdma_wdone_i_10
       (.I0(\wleft_reg_n_0_[4] ),
        .I1(\wb_reg_n_0_[4] ),
        .I2(\wleft_reg_n_0_[3] ),
        .I3(\wb_reg_n_0_[3] ),
        .O(fdma_wdone_i_10_n_0));
  LUT4 #(
    .INIT(16'h6FF6)) 
    fdma_wdone_i_11
       (.I0(\wleft_reg_n_0_[5] ),
        .I1(\wb_reg_n_0_[5] ),
        .I2(\wleft_reg_n_0_[2] ),
        .I3(\wb_reg_n_0_[2] ),
        .O(fdma_wdone_i_11_n_0));
  LUT4 #(
    .INIT(16'h0001)) 
    fdma_wdone_i_12
       (.I0(fdma_wsize[11]),
        .I1(fdma_wsize[10]),
        .I2(fdma_wsize[9]),
        .I3(fdma_wsize[8]),
        .O(fdma_wdone_i_12_n_0));
  LUT4 #(
    .INIT(16'h0001)) 
    fdma_wdone_i_13
       (.I0(fdma_wsize[7]),
        .I1(fdma_wsize[6]),
        .I2(fdma_wsize[5]),
        .I3(fdma_wsize[4]),
        .O(fdma_wdone_i_13_n_0));
  LUT6 #(
    .INIT(64'h8800880000F00000)) 
    fdma_wdone_i_2
       (.I0(write_next_st1__23),
        .I1(M_AXI_BVALID),
        .I2(fdma_wdone_i_4_n_0),
        .I3(write_curr_st[1]),
        .I4(fdma_wareq),
        .I5(write_curr_st[0]),
        .O(fdma_wdone_i_2_n_0));
  LUT6 #(
    .INIT(64'h0000000000000001)) 
    fdma_wdone_i_3
       (.I0(fdma_wdone_i_5_n_0),
        .I1(\wleft_reg_n_0_[13] ),
        .I2(\wleft_reg_n_0_[12] ),
        .I3(\wleft_reg_n_0_[15] ),
        .I4(\wleft_reg_n_0_[14] ),
        .I5(fdma_wdone_i_6_n_0),
        .O(write_next_st1__23));
  LUT5 #(
    .INIT(32'hFFFEFEFE)) 
    fdma_wdone_i_4
       (.I0(fdma_waddr[1]),
        .I1(fdma_waddr[0]),
        .I2(fdma_waddr[2]),
        .I3(fdma_wdone_i_7_n_0),
        .I4(fdma_wdone_i_8_n_0),
        .O(fdma_wdone_i_4_n_0));
  LUT5 #(
    .INIT(32'hBEFFFFBE)) 
    fdma_wdone_i_5
       (.I0(fdma_wdone_i_9_n_0),
        .I1(\wb_reg_n_0_[7] ),
        .I2(\wleft_reg_n_0_[7] ),
        .I3(\wb_reg_n_0_[8] ),
        .I4(\wleft_reg_n_0_[8] ),
        .O(fdma_wdone_i_5_n_0));
  LUT6 #(
    .INIT(64'hFFFFFFFFBEFFFFBE)) 
    fdma_wdone_i_6
       (.I0(fdma_wdone_i_10_n_0),
        .I1(\wleft_reg_n_0_[1] ),
        .I2(\wb_reg_n_0_[1] ),
        .I3(\wleft_reg_n_0_[0] ),
        .I4(\wb_reg_n_0_[0] ),
        .I5(fdma_wdone_i_11_n_0),
        .O(fdma_wdone_i_6_n_0));
  LUT5 #(
    .INIT(32'h00010000)) 
    fdma_wdone_i_7
       (.I0(fdma_wsize[12]),
        .I1(fdma_wsize[13]),
        .I2(fdma_wsize[14]),
        .I3(fdma_wsize[15]),
        .I4(fdma_wdone_i_12_n_0),
        .O(fdma_wdone_i_7_n_0));
  LUT5 #(
    .INIT(32'h00010000)) 
    fdma_wdone_i_8
       (.I0(fdma_wsize[2]),
        .I1(fdma_wsize[3]),
        .I2(fdma_wsize[0]),
        .I3(fdma_wsize[1]),
        .I4(fdma_wdone_i_13_n_0),
        .O(fdma_wdone_i_8_n_0));
  LUT5 #(
    .INIT(32'hFFFFFFBE)) 
    fdma_wdone_i_9
       (.I0(\wleft_reg_n_0_[11] ),
        .I1(\wb_reg_n_0_[6] ),
        .I2(\wleft_reg_n_0_[6] ),
        .I3(\wleft_reg_n_0_[9] ),
        .I4(\wleft_reg_n_0_[10] ),
        .O(fdma_wdone_i_9_n_0));
  FDRE fdma_wdone_reg
       (.C(M_AXI_ACLK),
        .CE(1'b1),
        .D(fdma_wdone_i_2_n_0),
        .Q(fdma_wdone),
        .R(fdma_wdone_i_1_n_0));
  LUT6 #(
    .INIT(64'hFFFFFFEFFFFF0020)) 
    fdma_werror_i_1
       (.I0(fdma_wdone_i_4_n_0),
        .I1(write_curr_st[0]),
        .I2(fdma_wareq),
        .I3(write_curr_st[1]),
        .I4(fdma_werror_i_2_n_0),
        .I5(fdma_werror),
        .O(fdma_werror_i_1_n_0));
  LUT5 #(
    .INIT(32'h44444440)) 
    fdma_werror_i_2
       (.I0(p_4_in),
        .I1(\wa[63]_i_3_n_0 ),
        .I2(M_AXI_BID),
        .I3(M_AXI_BRESP[0]),
        .I4(M_AXI_BRESP[1]),
        .O(fdma_werror_i_2_n_0));
  (* SOFT_HLUTNM = "soft_lutpair27" *) 
  LUT3 #(
    .INIT(8'h04)) 
    fdma_werror_i_3
       (.I0(write_curr_st[1]),
        .I1(fdma_wareq),
        .I2(write_curr_st[0]),
        .O(p_4_in));
  FDRE fdma_werror_reg
       (.C(M_AXI_ACLK),
        .CE(1'b1),
        .D(fdma_werror_i_1_n_0),
        .Q(fdma_werror),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT5 #(
    .INIT(32'h20000000)) 
    fdma_wvalid_INST_0
       (.I0(write_curr_st[1]),
        .I1(write_curr_st[0]),
        .I2(fdma_wready),
        .I3(w_pending_reg_n_0),
        .I4(M_AXI_WREADY),
        .O(fdma_wvalid));
  (* SOFT_HLUTNM = "soft_lutpair23" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[0]_i_1 
       (.I0(Q[0]),
        .I1(fdma_raddr[0]),
        .I2(read_curr_st__0[1]),
        .O(ra[0]));
  (* SOFT_HLUTNM = "soft_lutpair86" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[10]_i_1 
       (.I0(in12[10]),
        .I1(fdma_raddr[10]),
        .I2(read_curr_st__0[1]),
        .O(ra[10]));
  (* SOFT_HLUTNM = "soft_lutpair87" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[11]_i_1 
       (.I0(in12[11]),
        .I1(fdma_raddr[11]),
        .I2(read_curr_st__0[1]),
        .O(ra[11]));
  (* SOFT_HLUTNM = "soft_lutpair87" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[12]_i_1 
       (.I0(in12[12]),
        .I1(fdma_raddr[12]),
        .I2(read_curr_st__0[1]),
        .O(ra[12]));
  (* SOFT_HLUTNM = "soft_lutpair88" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[13]_i_1 
       (.I0(in12[13]),
        .I1(fdma_raddr[13]),
        .I2(read_curr_st__0[1]),
        .O(ra[13]));
  (* SOFT_HLUTNM = "soft_lutpair88" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[14]_i_1 
       (.I0(in12[14]),
        .I1(fdma_raddr[14]),
        .I2(read_curr_st__0[1]),
        .O(ra[14]));
  (* SOFT_HLUTNM = "soft_lutpair89" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[15]_i_1 
       (.I0(in12[15]),
        .I1(fdma_raddr[15]),
        .I2(read_curr_st__0[1]),
        .O(ra[15]));
  (* SOFT_HLUTNM = "soft_lutpair89" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[16]_i_1 
       (.I0(in12[16]),
        .I1(fdma_raddr[16]),
        .I2(read_curr_st__0[1]),
        .O(ra[16]));
  (* SOFT_HLUTNM = "soft_lutpair90" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[17]_i_1 
       (.I0(in12[17]),
        .I1(fdma_raddr[17]),
        .I2(read_curr_st__0[1]),
        .O(ra[17]));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[17]_i_3 
       (.I0(Q[11]),
        .I1(\rb_reg_n_0_[8] ),
        .O(\ra[17]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[17]_i_4 
       (.I0(Q[10]),
        .I1(\rb_reg_n_0_[7] ),
        .O(\ra[17]_i_4_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair90" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[18]_i_1 
       (.I0(in12[18]),
        .I1(fdma_raddr[18]),
        .I2(read_curr_st__0[1]),
        .O(ra[18]));
  (* SOFT_HLUTNM = "soft_lutpair91" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[19]_i_1 
       (.I0(in12[19]),
        .I1(fdma_raddr[19]),
        .I2(read_curr_st__0[1]),
        .O(ra[19]));
  (* SOFT_HLUTNM = "soft_lutpair82" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[1]_i_1 
       (.I0(Q[1]),
        .I1(fdma_raddr[1]),
        .I2(read_curr_st__0[1]),
        .O(ra[1]));
  (* SOFT_HLUTNM = "soft_lutpair91" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[20]_i_1 
       (.I0(in12[20]),
        .I1(fdma_raddr[20]),
        .I2(read_curr_st__0[1]),
        .O(ra[20]));
  (* SOFT_HLUTNM = "soft_lutpair92" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[21]_i_1 
       (.I0(in12[21]),
        .I1(fdma_raddr[21]),
        .I2(read_curr_st__0[1]),
        .O(ra[21]));
  (* SOFT_HLUTNM = "soft_lutpair92" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[22]_i_1 
       (.I0(in12[22]),
        .I1(fdma_raddr[22]),
        .I2(read_curr_st__0[1]),
        .O(ra[22]));
  (* SOFT_HLUTNM = "soft_lutpair93" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[23]_i_1 
       (.I0(in12[23]),
        .I1(fdma_raddr[23]),
        .I2(read_curr_st__0[1]),
        .O(ra[23]));
  (* SOFT_HLUTNM = "soft_lutpair93" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[24]_i_1 
       (.I0(in12[24]),
        .I1(fdma_raddr[24]),
        .I2(read_curr_st__0[1]),
        .O(ra[24]));
  (* SOFT_HLUTNM = "soft_lutpair94" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[25]_i_1 
       (.I0(in12[25]),
        .I1(fdma_raddr[25]),
        .I2(read_curr_st__0[1]),
        .O(ra[25]));
  (* SOFT_HLUTNM = "soft_lutpair94" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[26]_i_1 
       (.I0(in12[26]),
        .I1(fdma_raddr[26]),
        .I2(read_curr_st__0[1]),
        .O(ra[26]));
  (* SOFT_HLUTNM = "soft_lutpair95" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[27]_i_1 
       (.I0(in12[27]),
        .I1(fdma_raddr[27]),
        .I2(read_curr_st__0[1]),
        .O(ra[27]));
  (* SOFT_HLUTNM = "soft_lutpair95" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[28]_i_1 
       (.I0(in12[28]),
        .I1(fdma_raddr[28]),
        .I2(read_curr_st__0[1]),
        .O(ra[28]));
  (* SOFT_HLUTNM = "soft_lutpair96" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[29]_i_1 
       (.I0(in12[29]),
        .I1(fdma_raddr[29]),
        .I2(read_curr_st__0[1]),
        .O(ra[29]));
  (* SOFT_HLUTNM = "soft_lutpair82" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[2]_i_1 
       (.I0(in12[2]),
        .I1(fdma_raddr[2]),
        .I2(read_curr_st__0[1]),
        .O(ra[2]));
  (* SOFT_HLUTNM = "soft_lutpair96" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[30]_i_1 
       (.I0(in12[30]),
        .I1(fdma_raddr[30]),
        .I2(read_curr_st__0[1]),
        .O(ra[30]));
  (* SOFT_HLUTNM = "soft_lutpair97" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[31]_i_1 
       (.I0(in12[31]),
        .I1(fdma_raddr[31]),
        .I2(read_curr_st__0[1]),
        .O(ra[31]));
  (* SOFT_HLUTNM = "soft_lutpair97" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[32]_i_1 
       (.I0(in12[32]),
        .I1(fdma_raddr[32]),
        .I2(read_curr_st__0[1]),
        .O(ra[32]));
  (* SOFT_HLUTNM = "soft_lutpair98" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[33]_i_1 
       (.I0(in12[33]),
        .I1(fdma_raddr[33]),
        .I2(read_curr_st__0[1]),
        .O(ra[33]));
  (* SOFT_HLUTNM = "soft_lutpair98" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[34]_i_1 
       (.I0(in12[34]),
        .I1(fdma_raddr[34]),
        .I2(read_curr_st__0[1]),
        .O(ra[34]));
  (* SOFT_HLUTNM = "soft_lutpair99" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[35]_i_1 
       (.I0(in12[35]),
        .I1(fdma_raddr[35]),
        .I2(read_curr_st__0[1]),
        .O(ra[35]));
  (* SOFT_HLUTNM = "soft_lutpair99" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[36]_i_1 
       (.I0(in12[36]),
        .I1(fdma_raddr[36]),
        .I2(read_curr_st__0[1]),
        .O(ra[36]));
  (* SOFT_HLUTNM = "soft_lutpair100" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[37]_i_1 
       (.I0(in12[37]),
        .I1(fdma_raddr[37]),
        .I2(read_curr_st__0[1]),
        .O(ra[37]));
  (* SOFT_HLUTNM = "soft_lutpair100" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[38]_i_1 
       (.I0(in12[38]),
        .I1(fdma_raddr[38]),
        .I2(read_curr_st__0[1]),
        .O(ra[38]));
  (* SOFT_HLUTNM = "soft_lutpair101" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[39]_i_1 
       (.I0(in12[39]),
        .I1(fdma_raddr[39]),
        .I2(read_curr_st__0[1]),
        .O(ra[39]));
  (* SOFT_HLUTNM = "soft_lutpair83" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[3]_i_1 
       (.I0(in12[3]),
        .I1(fdma_raddr[3]),
        .I2(read_curr_st__0[1]),
        .O(ra[3]));
  (* SOFT_HLUTNM = "soft_lutpair101" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[40]_i_1 
       (.I0(in12[40]),
        .I1(fdma_raddr[40]),
        .I2(read_curr_st__0[1]),
        .O(ra[40]));
  (* SOFT_HLUTNM = "soft_lutpair102" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[41]_i_1 
       (.I0(in12[41]),
        .I1(fdma_raddr[41]),
        .I2(read_curr_st__0[1]),
        .O(ra[41]));
  (* SOFT_HLUTNM = "soft_lutpair102" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[42]_i_1 
       (.I0(in12[42]),
        .I1(fdma_raddr[42]),
        .I2(read_curr_st__0[1]),
        .O(ra[42]));
  (* SOFT_HLUTNM = "soft_lutpair103" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[43]_i_1 
       (.I0(in12[43]),
        .I1(fdma_raddr[43]),
        .I2(read_curr_st__0[1]),
        .O(ra[43]));
  (* SOFT_HLUTNM = "soft_lutpair103" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[44]_i_1 
       (.I0(in12[44]),
        .I1(fdma_raddr[44]),
        .I2(read_curr_st__0[1]),
        .O(ra[44]));
  (* SOFT_HLUTNM = "soft_lutpair104" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[45]_i_1 
       (.I0(in12[45]),
        .I1(fdma_raddr[45]),
        .I2(read_curr_st__0[1]),
        .O(ra[45]));
  (* SOFT_HLUTNM = "soft_lutpair104" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[46]_i_1 
       (.I0(in12[46]),
        .I1(fdma_raddr[46]),
        .I2(read_curr_st__0[1]),
        .O(ra[46]));
  (* SOFT_HLUTNM = "soft_lutpair105" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[47]_i_1 
       (.I0(in12[47]),
        .I1(fdma_raddr[47]),
        .I2(read_curr_st__0[1]),
        .O(ra[47]));
  (* SOFT_HLUTNM = "soft_lutpair105" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[48]_i_1 
       (.I0(in12[48]),
        .I1(fdma_raddr[48]),
        .I2(read_curr_st__0[1]),
        .O(ra[48]));
  (* SOFT_HLUTNM = "soft_lutpair106" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[49]_i_1 
       (.I0(in12[49]),
        .I1(fdma_raddr[49]),
        .I2(read_curr_st__0[1]),
        .O(ra[49]));
  (* SOFT_HLUTNM = "soft_lutpair83" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[4]_i_1 
       (.I0(in12[4]),
        .I1(fdma_raddr[4]),
        .I2(read_curr_st__0[1]),
        .O(ra[4]));
  (* SOFT_HLUTNM = "soft_lutpair106" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[50]_i_1 
       (.I0(in12[50]),
        .I1(fdma_raddr[50]),
        .I2(read_curr_st__0[1]),
        .O(ra[50]));
  (* SOFT_HLUTNM = "soft_lutpair107" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[51]_i_1 
       (.I0(in12[51]),
        .I1(fdma_raddr[51]),
        .I2(read_curr_st__0[1]),
        .O(ra[51]));
  (* SOFT_HLUTNM = "soft_lutpair107" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[52]_i_1 
       (.I0(in12[52]),
        .I1(fdma_raddr[52]),
        .I2(read_curr_st__0[1]),
        .O(ra[52]));
  (* SOFT_HLUTNM = "soft_lutpair108" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[53]_i_1 
       (.I0(in12[53]),
        .I1(fdma_raddr[53]),
        .I2(read_curr_st__0[1]),
        .O(ra[53]));
  (* SOFT_HLUTNM = "soft_lutpair108" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[54]_i_1 
       (.I0(in12[54]),
        .I1(fdma_raddr[54]),
        .I2(read_curr_st__0[1]),
        .O(ra[54]));
  (* SOFT_HLUTNM = "soft_lutpair109" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[55]_i_1 
       (.I0(in12[55]),
        .I1(fdma_raddr[55]),
        .I2(read_curr_st__0[1]),
        .O(ra[55]));
  (* SOFT_HLUTNM = "soft_lutpair109" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[56]_i_1 
       (.I0(in12[56]),
        .I1(fdma_raddr[56]),
        .I2(read_curr_st__0[1]),
        .O(ra[56]));
  (* SOFT_HLUTNM = "soft_lutpair110" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[57]_i_1 
       (.I0(in12[57]),
        .I1(fdma_raddr[57]),
        .I2(read_curr_st__0[1]),
        .O(ra[57]));
  (* SOFT_HLUTNM = "soft_lutpair110" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[58]_i_1 
       (.I0(in12[58]),
        .I1(fdma_raddr[58]),
        .I2(read_curr_st__0[1]),
        .O(ra[58]));
  (* SOFT_HLUTNM = "soft_lutpair111" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[59]_i_1 
       (.I0(in12[59]),
        .I1(fdma_raddr[59]),
        .I2(read_curr_st__0[1]),
        .O(ra[59]));
  (* SOFT_HLUTNM = "soft_lutpair84" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[5]_i_1 
       (.I0(in12[5]),
        .I1(fdma_raddr[5]),
        .I2(read_curr_st__0[1]),
        .O(ra[5]));
  (* SOFT_HLUTNM = "soft_lutpair111" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[60]_i_1 
       (.I0(in12[60]),
        .I1(fdma_raddr[60]),
        .I2(read_curr_st__0[1]),
        .O(ra[60]));
  (* SOFT_HLUTNM = "soft_lutpair112" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[61]_i_1 
       (.I0(in12[61]),
        .I1(fdma_raddr[61]),
        .I2(read_curr_st__0[1]),
        .O(ra[61]));
  (* SOFT_HLUTNM = "soft_lutpair112" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[62]_i_1 
       (.I0(in12[62]),
        .I1(fdma_raddr[62]),
        .I2(read_curr_st__0[1]),
        .O(ra[62]));
  LUT6 #(
    .INIT(64'h0800FFFF08000000)) 
    \ra[63]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(read_next_st0__16),
        .I2(\ra[63]_i_4_n_0 ),
        .I3(M_AXI_RVALID_0),
        .I4(read_curr_st__0[0]),
        .I5(\ra[63]_i_5_n_0 ),
        .O(ra_2));
  LUT6 #(
    .INIT(64'h0000000800000000)) 
    \ra[63]_i_10 
       (.I0(\ra[63]_i_18_n_0 ),
        .I1(\ra[63]_i_19_n_0 ),
        .I2(\rleft_reg_n_0_[11] ),
        .I3(\rleft_reg_n_0_[10] ),
        .I4(\rleft_reg_n_0_[9] ),
        .I5(\ra[63]_i_20_n_0 ),
        .O(\ra[63]_i_10_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \ra[63]_i_11 
       (.I0(fdma_rsize[10]),
        .I1(fdma_rsize[11]),
        .I2(fdma_rsize[8]),
        .I3(fdma_rsize[9]),
        .O(\ra[63]_i_11_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \ra[63]_i_12 
       (.I0(fdma_rsize[15]),
        .I1(fdma_rsize[14]),
        .I2(fdma_rsize[12]),
        .I3(fdma_rsize[13]),
        .O(\ra[63]_i_12_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \ra[63]_i_13 
       (.I0(fdma_rsize[2]),
        .I1(fdma_rsize[3]),
        .I2(fdma_rsize[0]),
        .I3(fdma_rsize[1]),
        .O(\ra[63]_i_13_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \ra[63]_i_14 
       (.I0(fdma_rsize[6]),
        .I1(fdma_rsize[7]),
        .I2(fdma_rsize[4]),
        .I3(fdma_rsize[5]),
        .O(\ra[63]_i_14_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair20" *) 
  LUT4 #(
    .INIT(16'h01FE)) 
    \ra[63]_i_15 
       (.I0(\rb_reg_n_0_[2] ),
        .I1(\rb_reg_n_0_[0] ),
        .I2(\rb_reg_n_0_[1] ),
        .I3(\rb_reg_n_0_[3] ),
        .O(\ra[63]_i_15_n_0 ));
  LUT6 #(
    .INIT(64'h00000001FFFFFFFE)) 
    \ra[63]_i_16 
       (.I0(\rb_reg_n_0_[4] ),
        .I1(\rb_reg_n_0_[2] ),
        .I2(\rb_reg_n_0_[0] ),
        .I3(\rb_reg_n_0_[1] ),
        .I4(\rb_reg_n_0_[3] ),
        .I5(\rb_reg_n_0_[5] ),
        .O(\ra[63]_i_16_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair11" *) 
  LUT5 #(
    .INIT(32'h0001FFFE)) 
    \ra[63]_i_17 
       (.I0(\rb_reg_n_0_[3] ),
        .I1(\rb_reg_n_0_[1] ),
        .I2(\rb_reg_n_0_[0] ),
        .I3(\rb_reg_n_0_[2] ),
        .I4(\rb_reg_n_0_[4] ),
        .O(\ra[63]_i_17_n_0 ));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    \ra[63]_i_18 
       (.I0(\rleft_reg_n_0_[3] ),
        .I1(\rb_reg_n_0_[3] ),
        .I2(\rb_reg_n_0_[5] ),
        .I3(\rleft_reg_n_0_[5] ),
        .I4(\rb_reg_n_0_[4] ),
        .I5(\rleft_reg_n_0_[4] ),
        .O(\ra[63]_i_18_n_0 ));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    \ra[63]_i_19 
       (.I0(\rleft_reg_n_0_[0] ),
        .I1(\rb_reg_n_0_[0] ),
        .I2(\rb_reg_n_0_[2] ),
        .I3(\rleft_reg_n_0_[2] ),
        .I4(\rb_reg_n_0_[1] ),
        .I5(\rleft_reg_n_0_[1] ),
        .O(\ra[63]_i_19_n_0 ));
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[63]_i_2 
       (.I0(in12[63]),
        .I1(fdma_raddr[63]),
        .I2(read_curr_st__0[1]),
        .O(ra[63]));
  LUT6 #(
    .INIT(64'h9009000000009009)) 
    \ra[63]_i_20 
       (.I0(\rleft_reg_n_0_[6] ),
        .I1(\rb_reg_n_0_[6] ),
        .I2(\rb_reg_n_0_[8] ),
        .I3(\rleft_reg_n_0_[8] ),
        .I4(\rb_reg_n_0_[7] ),
        .I5(\rleft_reg_n_0_[7] ),
        .O(\ra[63]_i_20_n_0 ));
  LUT6 #(
    .INIT(64'h8228000000000000)) 
    \ra[63]_i_3 
       (.I0(\ra[63]_i_7_n_0 ),
        .I1(\rbeat_reg_n_0_[6] ),
        .I2(\M_AXI_ARLEN[7]_INST_0_i_1_n_0 ),
        .I3(\rb_reg_n_0_[6] ),
        .I4(\ra[63]_i_8_n_0 ),
        .I5(\ra[63]_i_9_n_0 ),
        .O(read_next_st0__16));
  LUT5 #(
    .INIT(32'h00010000)) 
    \ra[63]_i_4 
       (.I0(\rleft_reg_n_0_[12] ),
        .I1(\rleft_reg_n_0_[13] ),
        .I2(\rleft_reg_n_0_[14] ),
        .I3(\rleft_reg_n_0_[15] ),
        .I4(\ra[63]_i_10_n_0 ),
        .O(\ra[63]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h00000000FFFE0000)) 
    \ra[63]_i_5 
       (.I0(\ra[63]_i_11_n_0 ),
        .I1(\ra[63]_i_12_n_0 ),
        .I2(\ra[63]_i_13_n_0 ),
        .I3(\ra[63]_i_14_n_0 ),
        .I4(fdma_rareq),
        .I5(read_curr_st__0[1]),
        .O(\ra[63]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h4002100808400210)) 
    \ra[63]_i_7 
       (.I0(\rbeat_reg_n_0_[0] ),
        .I1(\rb_reg_n_0_[2] ),
        .I2(\rb_reg_n_0_[0] ),
        .I3(\rb_reg_n_0_[1] ),
        .I4(\rbeat_reg_n_0_[2] ),
        .I5(\rbeat_reg_n_0_[1] ),
        .O(\ra[63]_i_7_n_0 ));
  LUT6 #(
    .INIT(64'h8484844221212118)) 
    \ra[63]_i_8 
       (.I0(\rbeat_reg_n_0_[7] ),
        .I1(\rbeat_reg_n_0_[8] ),
        .I2(\rb_reg_n_0_[7] ),
        .I3(\M_AXI_ARLEN[7]_INST_0_i_1_n_0 ),
        .I4(\rb_reg_n_0_[6] ),
        .I5(\rb_reg_n_0_[8] ),
        .O(\ra[63]_i_8_n_0 ));
  LUT6 #(
    .INIT(64'h0000066006600000)) 
    \ra[63]_i_9 
       (.I0(\rbeat_reg_n_0_[3] ),
        .I1(\ra[63]_i_15_n_0 ),
        .I2(\ra[63]_i_16_n_0 ),
        .I3(\rbeat_reg_n_0_[5] ),
        .I4(\ra[63]_i_17_n_0 ),
        .I5(\rbeat_reg_n_0_[4] ),
        .O(\ra[63]_i_9_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair84" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[6]_i_1 
       (.I0(in12[6]),
        .I1(fdma_raddr[6]),
        .I2(read_curr_st__0[1]),
        .O(ra[6]));
  (* SOFT_HLUTNM = "soft_lutpair85" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[7]_i_1 
       (.I0(in12[7]),
        .I1(fdma_raddr[7]),
        .I2(read_curr_st__0[1]),
        .O(ra[7]));
  (* SOFT_HLUTNM = "soft_lutpair85" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[8]_i_1 
       (.I0(in12[8]),
        .I1(fdma_raddr[8]),
        .I2(read_curr_st__0[1]),
        .O(ra[8]));
  (* SOFT_HLUTNM = "soft_lutpair86" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \ra[9]_i_1 
       (.I0(in12[9]),
        .I1(fdma_raddr[9]),
        .I2(read_curr_st__0[1]),
        .O(ra[9]));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_3 
       (.I0(Q[9]),
        .I1(\rb_reg_n_0_[6] ),
        .O(\ra[9]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_4 
       (.I0(Q[8]),
        .I1(\rb_reg_n_0_[5] ),
        .O(\ra[9]_i_4_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_5 
       (.I0(Q[7]),
        .I1(\rb_reg_n_0_[4] ),
        .O(\ra[9]_i_5_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_6 
       (.I0(Q[6]),
        .I1(\rb_reg_n_0_[3] ),
        .O(\ra[9]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_7 
       (.I0(Q[5]),
        .I1(\rb_reg_n_0_[2] ),
        .O(\ra[9]_i_7_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_8 
       (.I0(Q[4]),
        .I1(\rb_reg_n_0_[1] ),
        .O(\ra[9]_i_8_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \ra[9]_i_9 
       (.I0(Q[3]),
        .I1(\rb_reg_n_0_[0] ),
        .O(\ra[9]_i_9_n_0 ));
  FDRE \ra_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[0]),
        .Q(Q[0]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[10] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[10]),
        .Q(Q[10]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[11] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[11]),
        .Q(Q[11]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[12] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[12]),
        .Q(Q[12]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[13] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[13]),
        .Q(Q[13]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[14] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[14]),
        .Q(Q[14]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[15] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[15]),
        .Q(Q[15]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[16] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[16]),
        .Q(Q[16]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[17] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[17]),
        .Q(Q[17]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[17]_i_2 
       (.CI(\ra_reg[9]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\ra_reg[17]_i_2_n_0 ,\ra_reg[17]_i_2_n_1 ,\ra_reg[17]_i_2_n_2 ,\ra_reg[17]_i_2_n_3 ,\ra_reg[17]_i_2_n_4 ,\ra_reg[17]_i_2_n_5 ,\ra_reg[17]_i_2_n_6 ,\ra_reg[17]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,Q[11:10]}),
        .O(in12[17:10]),
        .S({Q[17:12],\ra[17]_i_3_n_0 ,\ra[17]_i_4_n_0 }));
  FDRE \ra_reg[18] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[18]),
        .Q(Q[18]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[19] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[19]),
        .Q(Q[19]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[1]),
        .Q(Q[1]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[20] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[20]),
        .Q(Q[20]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[21] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[21]),
        .Q(Q[21]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[22] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[22]),
        .Q(Q[22]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[23] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[23]),
        .Q(Q[23]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[24] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[24]),
        .Q(Q[24]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[25] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[25]),
        .Q(Q[25]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[25]_i_2 
       (.CI(\ra_reg[17]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\ra_reg[25]_i_2_n_0 ,\ra_reg[25]_i_2_n_1 ,\ra_reg[25]_i_2_n_2 ,\ra_reg[25]_i_2_n_3 ,\ra_reg[25]_i_2_n_4 ,\ra_reg[25]_i_2_n_5 ,\ra_reg[25]_i_2_n_6 ,\ra_reg[25]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in12[25:18]),
        .S(Q[25:18]));
  FDRE \ra_reg[26] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[26]),
        .Q(Q[26]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[27] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[27]),
        .Q(Q[27]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[28] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[28]),
        .Q(Q[28]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[29] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[29]),
        .Q(Q[29]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[2]),
        .Q(Q[2]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[30] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[30]),
        .Q(Q[30]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[31] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[31]),
        .Q(Q[31]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[32] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[32]),
        .Q(Q[32]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[33] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[33]),
        .Q(Q[33]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[33]_i_2 
       (.CI(\ra_reg[25]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\ra_reg[33]_i_2_n_0 ,\ra_reg[33]_i_2_n_1 ,\ra_reg[33]_i_2_n_2 ,\ra_reg[33]_i_2_n_3 ,\ra_reg[33]_i_2_n_4 ,\ra_reg[33]_i_2_n_5 ,\ra_reg[33]_i_2_n_6 ,\ra_reg[33]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in12[33:26]),
        .S(Q[33:26]));
  FDRE \ra_reg[34] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[34]),
        .Q(Q[34]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[35] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[35]),
        .Q(Q[35]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[36] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[36]),
        .Q(Q[36]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[37] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[37]),
        .Q(Q[37]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[38] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[38]),
        .Q(Q[38]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[39] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[39]),
        .Q(Q[39]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[3]),
        .Q(Q[3]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[40] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[40]),
        .Q(Q[40]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[41] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[41]),
        .Q(Q[41]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[41]_i_2 
       (.CI(\ra_reg[33]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\ra_reg[41]_i_2_n_0 ,\ra_reg[41]_i_2_n_1 ,\ra_reg[41]_i_2_n_2 ,\ra_reg[41]_i_2_n_3 ,\ra_reg[41]_i_2_n_4 ,\ra_reg[41]_i_2_n_5 ,\ra_reg[41]_i_2_n_6 ,\ra_reg[41]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in12[41:34]),
        .S(Q[41:34]));
  FDRE \ra_reg[42] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[42]),
        .Q(Q[42]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[43] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[43]),
        .Q(Q[43]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[44] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[44]),
        .Q(Q[44]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[45] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[45]),
        .Q(Q[45]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[46] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[46]),
        .Q(Q[46]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[47] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[47]),
        .Q(Q[47]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[48] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[48]),
        .Q(Q[48]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[49] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[49]),
        .Q(Q[49]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[49]_i_2 
       (.CI(\ra_reg[41]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\ra_reg[49]_i_2_n_0 ,\ra_reg[49]_i_2_n_1 ,\ra_reg[49]_i_2_n_2 ,\ra_reg[49]_i_2_n_3 ,\ra_reg[49]_i_2_n_4 ,\ra_reg[49]_i_2_n_5 ,\ra_reg[49]_i_2_n_6 ,\ra_reg[49]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in12[49:42]),
        .S(Q[49:42]));
  FDRE \ra_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[4]),
        .Q(Q[4]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[50] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[50]),
        .Q(Q[50]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[51] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[51]),
        .Q(Q[51]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[52] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[52]),
        .Q(Q[52]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[53] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[53]),
        .Q(Q[53]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[54] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[54]),
        .Q(Q[54]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[55] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[55]),
        .Q(Q[55]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[56] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[56]),
        .Q(Q[56]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[57] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[57]),
        .Q(Q[57]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[57]_i_2 
       (.CI(\ra_reg[49]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\ra_reg[57]_i_2_n_0 ,\ra_reg[57]_i_2_n_1 ,\ra_reg[57]_i_2_n_2 ,\ra_reg[57]_i_2_n_3 ,\ra_reg[57]_i_2_n_4 ,\ra_reg[57]_i_2_n_5 ,\ra_reg[57]_i_2_n_6 ,\ra_reg[57]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in12[57:50]),
        .S(Q[57:50]));
  FDRE \ra_reg[58] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[58]),
        .Q(Q[58]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[59] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[59]),
        .Q(Q[59]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[5]),
        .Q(Q[5]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[60] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[60]),
        .Q(Q[60]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[61] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[61]),
        .Q(Q[61]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[62] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[62]),
        .Q(Q[62]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[63] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[63]),
        .Q(Q[63]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[63]_i_6 
       (.CI(\ra_reg[57]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\NLW_ra_reg[63]_i_6_CO_UNCONNECTED [7:5],\ra_reg[63]_i_6_n_3 ,\ra_reg[63]_i_6_n_4 ,\ra_reg[63]_i_6_n_5 ,\ra_reg[63]_i_6_n_6 ,\ra_reg[63]_i_6_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O({\NLW_ra_reg[63]_i_6_O_UNCONNECTED [7:6],in12[63:58]}),
        .S({1'b0,1'b0,Q[63:58]}));
  FDRE \ra_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[6]),
        .Q(Q[6]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[7]),
        .Q(Q[7]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[8]),
        .Q(Q[8]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \ra_reg[9] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(ra[9]),
        .Q(Q[9]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \ra_reg[9]_i_2 
       (.CI(1'b0),
        .CI_TOP(1'b0),
        .CO({\ra_reg[9]_i_2_n_0 ,\ra_reg[9]_i_2_n_1 ,\ra_reg[9]_i_2_n_2 ,\ra_reg[9]_i_2_n_3 ,\ra_reg[9]_i_2_n_4 ,\ra_reg[9]_i_2_n_5 ,\ra_reg[9]_i_2_n_6 ,\ra_reg[9]_i_2_n_7 }),
        .DI({Q[9:3],1'b0}),
        .O(in12[9:2]),
        .S({\ra[9]_i_3_n_0 ,\ra[9]_i_4_n_0 ,\ra[9]_i_5_n_0 ,\ra[9]_i_6_n_0 ,\ra[9]_i_7_n_0 ,\ra[9]_i_8_n_0 ,\ra[9]_i_9_n_0 ,Q[2]}));
  LUT4 #(
    .INIT(16'hAA0C)) 
    \rb[0]_i_1 
       (.I0(\rleft_reg_n_0_[0] ),
        .I1(\rb[0]_i_2_n_0 ),
        .I2(\rb[8]_i_4_n_0 ),
        .I3(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair14" *) 
  LUT4 #(
    .INIT(16'h01FE)) 
    \rb[0]_i_2 
       (.I0(Q[2]),
        .I1(Q[1]),
        .I2(Q[0]),
        .I3(Q[3]),
        .O(\rb[0]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hAA0C)) 
    \rb[1]_i_1 
       (.I0(\rleft_reg_n_0_[1] ),
        .I1(\rb[1]_i_2_n_0 ),
        .I2(\rb[8]_i_4_n_0 ),
        .I3(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT5 #(
    .INIT(32'h0001FFFE)) 
    \rb[1]_i_2 
       (.I0(Q[3]),
        .I1(Q[0]),
        .I2(Q[1]),
        .I3(Q[2]),
        .I4(Q[4]),
        .O(\rb[1]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hAA0C)) 
    \rb[2]_i_1 
       (.I0(\rleft_reg_n_0_[2] ),
        .I1(\rb[2]_i_2_n_0 ),
        .I2(\rb[8]_i_4_n_0 ),
        .I3(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[2]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h00000001FFFFFFFE)) 
    \rb[2]_i_2 
       (.I0(Q[4]),
        .I1(Q[2]),
        .I2(Q[1]),
        .I3(Q[0]),
        .I4(Q[3]),
        .I5(Q[5]),
        .O(\rb[2]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair12" *) 
  LUT5 #(
    .INIT(32'hAAAA00C3)) 
    \rb[3]_i_1 
       (.I0(\rleft_reg_n_0_[3] ),
        .I1(Q[6]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(\rb[8]_i_4_n_0 ),
        .I4(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[3]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAAAAAAAA000033C3)) 
    \rb[4]_i_1 
       (.I0(\rleft_reg_n_0_[4] ),
        .I1(Q[7]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(Q[6]),
        .I4(\rb[8]_i_4_n_0 ),
        .I5(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[4]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000000001)) 
    \rb[4]_i_2 
       (.I0(Q[4]),
        .I1(Q[2]),
        .I2(Q[1]),
        .I3(Q[0]),
        .I4(Q[3]),
        .I5(Q[5]),
        .O(\rb[4]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hAA0C)) 
    \rb[5]_i_1 
       (.I0(\rleft_reg_n_0_[5] ),
        .I1(\rb[5]_i_2_n_0 ),
        .I2(\rb[8]_i_4_n_0 ),
        .I3(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[5]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair13" *) 
  LUT4 #(
    .INIT(16'h04FB)) 
    \rb[5]_i_2 
       (.I0(Q[7]),
        .I1(\rb[4]_i_2_n_0 ),
        .I2(Q[6]),
        .I3(Q[8]),
        .O(\rb[5]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hAA0C)) 
    \rb[6]_i_1 
       (.I0(\rleft_reg_n_0_[6] ),
        .I1(\rb[6]_i_2_n_0 ),
        .I2(\rb[8]_i_4_n_0 ),
        .I3(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[6]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT5 #(
    .INIT(32'h0010FFEF)) 
    \rb[6]_i_2 
       (.I0(Q[8]),
        .I1(Q[6]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(Q[7]),
        .I4(Q[9]),
        .O(\rb[6]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'hAA0C)) 
    \rb[7]_i_1 
       (.I0(\rleft_reg_n_0_[7] ),
        .I1(\rb[7]_i_2_n_0 ),
        .I2(\rb[8]_i_4_n_0 ),
        .I3(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[7]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h00000010FFFFFFEF)) 
    \rb[7]_i_2 
       (.I0(Q[9]),
        .I1(Q[7]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(Q[6]),
        .I4(Q[8]),
        .I5(Q[10]),
        .O(\rb[7]_i_2_n_0 ));
  LUT2 #(
    .INIT(4'h2)) 
    \rb[8]_i_1 
       (.I0(read_curr_st__0[0]),
        .I1(read_curr_st__0[1]),
        .O(rb));
  LUT5 #(
    .INIT(32'hAAAAFFC3)) 
    \rb[8]_i_2 
       (.I0(\rleft_reg_n_0_[8] ),
        .I1(Q[11]),
        .I2(\rb[8]_i_3_n_0 ),
        .I3(\rb[8]_i_4_n_0 ),
        .I4(\update_wb.available1_carry__0_n_0 ),
        .O(\rb[8]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000000010)) 
    \rb[8]_i_3 
       (.I0(Q[9]),
        .I1(Q[7]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(Q[6]),
        .I4(Q[8]),
        .I5(Q[10]),
        .O(\rb[8]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h30303020FFFFFFFB)) 
    \rb[8]_i_4 
       (.I0(\rb[8]_i_5_n_0 ),
        .I1(Q[10]),
        .I2(\rb[8]_i_6_n_0 ),
        .I3(\rb[0]_i_2_n_0 ),
        .I4(\rb[8]_i_7_n_0 ),
        .I5(Q[11]),
        .O(\rb[8]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'hF7FFFFEF)) 
    \rb[8]_i_5 
       (.I0(Q[6]),
        .I1(Q[4]),
        .I2(\rb[8]_i_8_n_0 ),
        .I3(Q[5]),
        .I4(Q[7]),
        .O(\rb[8]_i_5_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT5 #(
    .INIT(32'h00000010)) 
    \rb[8]_i_6 
       (.I0(Q[8]),
        .I1(Q[6]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(Q[7]),
        .I4(Q[9]),
        .O(\rb[8]_i_6_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair13" *) 
  LUT5 #(
    .INIT(32'h5575FFEF)) 
    \rb[8]_i_7 
       (.I0(Q[9]),
        .I1(Q[7]),
        .I2(\rb[4]_i_2_n_0 ),
        .I3(Q[6]),
        .I4(Q[8]),
        .O(\rb[8]_i_7_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair14" *) 
  LUT4 #(
    .INIT(16'h0001)) 
    \rb[8]_i_8 
       (.I0(Q[2]),
        .I1(Q[1]),
        .I2(Q[0]),
        .I3(Q[3]),
        .O(\rb[8]_i_8_n_0 ));
  FDRE \rb_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[0]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[0] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[1]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[1] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[2]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[2] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[3]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[3] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[4]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[4] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[5]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[5] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[6]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[6] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[7]_i_1_n_0 ),
        .Q(\rb_reg_n_0_[7] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rb_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(rb),
        .D(\rb[8]_i_2_n_0 ),
        .Q(\rb_reg_n_0_[8] ),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair21" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \rbeat[0]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[0] ),
        .O(rbeat));
  (* SOFT_HLUTNM = "soft_lutpair21" *) 
  LUT3 #(
    .INIT(8'h28)) 
    \rbeat[1]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[1] ),
        .I2(\rbeat_reg_n_0_[0] ),
        .O(\rbeat[1]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT4 #(
    .INIT(16'h2888)) 
    \rbeat[2]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[2] ),
        .I2(\rbeat_reg_n_0_[1] ),
        .I3(\rbeat_reg_n_0_[0] ),
        .O(\rbeat[2]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT5 #(
    .INIT(32'h28888888)) 
    \rbeat[3]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[3] ),
        .I2(\rbeat_reg_n_0_[2] ),
        .I3(\rbeat_reg_n_0_[0] ),
        .I4(\rbeat_reg_n_0_[1] ),
        .O(\rbeat[3]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h2888888888888888)) 
    \rbeat[4]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[4] ),
        .I2(\rbeat_reg_n_0_[3] ),
        .I3(\rbeat_reg_n_0_[1] ),
        .I4(\rbeat_reg_n_0_[0] ),
        .I5(\rbeat_reg_n_0_[2] ),
        .O(\rbeat[4]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair22" *) 
  LUT3 #(
    .INIT(8'h28)) 
    \rbeat[5]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[5] ),
        .I2(\rbeat[5]_i_2_n_0 ),
        .O(\rbeat[5]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h80000000)) 
    \rbeat[5]_i_2 
       (.I0(\rbeat_reg_n_0_[4] ),
        .I1(\rbeat_reg_n_0_[2] ),
        .I2(\rbeat_reg_n_0_[0] ),
        .I3(\rbeat_reg_n_0_[1] ),
        .I4(\rbeat_reg_n_0_[3] ),
        .O(\rbeat[5]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair22" *) 
  LUT3 #(
    .INIT(8'h28)) 
    \rbeat[6]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[6] ),
        .I2(\rbeat[8]_i_3_n_0 ),
        .O(\rbeat[6]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT4 #(
    .INIT(16'h2888)) 
    \rbeat[7]_i_1 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[7] ),
        .I2(\rbeat_reg_n_0_[6] ),
        .I3(\rbeat[8]_i_3_n_0 ),
        .O(\rbeat[7]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h22A2)) 
    \rbeat[8]_i_1 
       (.I0(read_curr_st__0[0]),
        .I1(read_curr_st__0[1]),
        .I2(M_AXI_RVALID_0),
        .I3(read_next_st0__16),
        .O(rbeat_3));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'h28888888)) 
    \rbeat[8]_i_2 
       (.I0(read_curr_st__0[1]),
        .I1(\rbeat_reg_n_0_[8] ),
        .I2(\rbeat_reg_n_0_[7] ),
        .I3(\rbeat[8]_i_3_n_0 ),
        .I4(\rbeat_reg_n_0_[6] ),
        .O(\rbeat[8]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h8000000000000000)) 
    \rbeat[8]_i_3 
       (.I0(\rbeat_reg_n_0_[5] ),
        .I1(\rbeat_reg_n_0_[3] ),
        .I2(\rbeat_reg_n_0_[1] ),
        .I3(\rbeat_reg_n_0_[0] ),
        .I4(\rbeat_reg_n_0_[2] ),
        .I5(\rbeat_reg_n_0_[4] ),
        .O(\rbeat[8]_i_3_n_0 ));
  FDRE \rbeat_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(rbeat),
        .Q(\rbeat_reg_n_0_[0] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[1]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[1] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[2]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[2] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[3]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[3] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[4]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[4] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[5]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[5] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[6]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[6] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[7]_i_1_n_0 ),
        .Q(\rbeat_reg_n_0_[7] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rbeat_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(rbeat_3),
        .D(\rbeat[8]_i_2_n_0 ),
        .Q(\rbeat_reg_n_0_[8] ),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair73" *) 
  LUT3 #(
    .INIT(8'h5D)) 
    \read_curr_st[0]_i_1 
       (.I0(read_curr_st[0]),
        .I1(read_curr_st[1]),
        .I2(\ra[63]_i_4_n_0 ),
        .O(\read_curr_st[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair113" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \read_curr_st[1]_i_1 
       (.I0(read_curr_st[0]),
        .I1(read_curr_st[1]),
        .O(\read_curr_st[1]_i_1_n_0 ));
  FDRE \read_curr_st_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(read_next_st),
        .D(\read_curr_st[0]_i_1_n_0 ),
        .Q(read_curr_st[0]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \read_curr_st_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(read_next_st),
        .D(\read_curr_st[1]_i_1_n_0 ),
        .Q(read_curr_st[1]),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair74" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[0]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_15 ),
        .I1(fdma_rsize[0]),
        .I2(read_curr_st__0[1]),
        .O(rleft[0]));
  (* SOFT_HLUTNM = "soft_lutpair79" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[10]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_13 ),
        .I1(fdma_rsize[10]),
        .I2(read_curr_st__0[1]),
        .O(rleft[10]));
  (* SOFT_HLUTNM = "soft_lutpair79" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[11]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_12 ),
        .I1(fdma_rsize[11]),
        .I2(read_curr_st__0[1]),
        .O(rleft[11]));
  (* SOFT_HLUTNM = "soft_lutpair80" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[12]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_11 ),
        .I1(fdma_rsize[12]),
        .I2(read_curr_st__0[1]),
        .O(rleft[12]));
  (* SOFT_HLUTNM = "soft_lutpair80" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[13]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_10 ),
        .I1(fdma_rsize[13]),
        .I2(read_curr_st__0[1]),
        .O(rleft[13]));
  (* SOFT_HLUTNM = "soft_lutpair81" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[14]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_9 ),
        .I1(fdma_rsize[14]),
        .I2(read_curr_st__0[1]),
        .O(rleft[14]));
  (* SOFT_HLUTNM = "soft_lutpair81" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[15]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_8 ),
        .I1(fdma_rsize[15]),
        .I2(read_curr_st__0[1]),
        .O(rleft[15]));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[15]_i_10 
       (.I0(\rleft_reg_n_0_[8] ),
        .I1(\rb_reg_n_0_[8] ),
        .O(\rleft[15]_i_10_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_3 
       (.I0(\rleft_reg_n_0_[15] ),
        .O(\rleft[15]_i_3_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_4 
       (.I0(\rleft_reg_n_0_[14] ),
        .O(\rleft[15]_i_4_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_5 
       (.I0(\rleft_reg_n_0_[13] ),
        .O(\rleft[15]_i_5_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_6 
       (.I0(\rleft_reg_n_0_[12] ),
        .O(\rleft[15]_i_6_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_7 
       (.I0(\rleft_reg_n_0_[11] ),
        .O(\rleft[15]_i_7_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_8 
       (.I0(\rleft_reg_n_0_[10] ),
        .O(\rleft[15]_i_8_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \rleft[15]_i_9 
       (.I0(\rleft_reg_n_0_[9] ),
        .O(\rleft[15]_i_9_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair74" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[1]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_14 ),
        .I1(fdma_rsize[1]),
        .I2(read_curr_st__0[1]),
        .O(rleft[1]));
  (* SOFT_HLUTNM = "soft_lutpair75" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[2]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_13 ),
        .I1(fdma_rsize[2]),
        .I2(read_curr_st__0[1]),
        .O(rleft[2]));
  (* SOFT_HLUTNM = "soft_lutpair75" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[3]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_12 ),
        .I1(fdma_rsize[3]),
        .I2(read_curr_st__0[1]),
        .O(rleft[3]));
  (* SOFT_HLUTNM = "soft_lutpair76" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[4]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_11 ),
        .I1(fdma_rsize[4]),
        .I2(read_curr_st__0[1]),
        .O(rleft[4]));
  (* SOFT_HLUTNM = "soft_lutpair76" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[5]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_10 ),
        .I1(fdma_rsize[5]),
        .I2(read_curr_st__0[1]),
        .O(rleft[5]));
  (* SOFT_HLUTNM = "soft_lutpair77" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[6]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_9 ),
        .I1(fdma_rsize[6]),
        .I2(read_curr_st__0[1]),
        .O(rleft[6]));
  (* SOFT_HLUTNM = "soft_lutpair77" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[7]_i_1 
       (.I0(\rleft_reg[7]_i_2_n_8 ),
        .I1(fdma_rsize[7]),
        .I2(read_curr_st__0[1]),
        .O(rleft[7]));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_10 
       (.I0(\rleft_reg_n_0_[0] ),
        .I1(\rb_reg_n_0_[0] ),
        .O(\rleft[7]_i_10_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_3 
       (.I0(\rleft_reg_n_0_[7] ),
        .I1(\rb_reg_n_0_[7] ),
        .O(\rleft[7]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_4 
       (.I0(\rleft_reg_n_0_[6] ),
        .I1(\rb_reg_n_0_[6] ),
        .O(\rleft[7]_i_4_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_5 
       (.I0(\rleft_reg_n_0_[5] ),
        .I1(\rb_reg_n_0_[5] ),
        .O(\rleft[7]_i_5_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_6 
       (.I0(\rleft_reg_n_0_[4] ),
        .I1(\rb_reg_n_0_[4] ),
        .O(\rleft[7]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_7 
       (.I0(\rleft_reg_n_0_[3] ),
        .I1(\rb_reg_n_0_[3] ),
        .O(\rleft[7]_i_7_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_8 
       (.I0(\rleft_reg_n_0_[2] ),
        .I1(\rb_reg_n_0_[2] ),
        .O(\rleft[7]_i_8_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \rleft[7]_i_9 
       (.I0(\rleft_reg_n_0_[1] ),
        .I1(\rb_reg_n_0_[1] ),
        .O(\rleft[7]_i_9_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair78" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[8]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_15 ),
        .I1(fdma_rsize[8]),
        .I2(read_curr_st__0[1]),
        .O(rleft[8]));
  (* SOFT_HLUTNM = "soft_lutpair78" *) 
  LUT3 #(
    .INIT(8'hAC)) 
    \rleft[9]_i_1 
       (.I0(\rleft_reg[15]_i_2_n_14 ),
        .I1(fdma_rsize[9]),
        .I2(read_curr_st__0[1]),
        .O(rleft[9]));
  FDRE \rleft_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[0]),
        .Q(\rleft_reg_n_0_[0] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[10] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[10]),
        .Q(\rleft_reg_n_0_[10] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[11] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[11]),
        .Q(\rleft_reg_n_0_[11] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[12] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[12]),
        .Q(\rleft_reg_n_0_[12] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[13] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[13]),
        .Q(\rleft_reg_n_0_[13] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[14] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[14]),
        .Q(\rleft_reg_n_0_[14] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[15] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[15]),
        .Q(\rleft_reg_n_0_[15] ),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \rleft_reg[15]_i_2 
       (.CI(\rleft_reg[7]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\NLW_rleft_reg[15]_i_2_CO_UNCONNECTED [7],\rleft_reg[15]_i_2_n_1 ,\rleft_reg[15]_i_2_n_2 ,\rleft_reg[15]_i_2_n_3 ,\rleft_reg[15]_i_2_n_4 ,\rleft_reg[15]_i_2_n_5 ,\rleft_reg[15]_i_2_n_6 ,\rleft_reg[15]_i_2_n_7 }),
        .DI({1'b0,\rleft_reg_n_0_[14] ,\rleft_reg_n_0_[13] ,\rleft_reg_n_0_[12] ,\rleft_reg_n_0_[11] ,\rleft_reg_n_0_[10] ,\rleft_reg_n_0_[9] ,\rleft_reg_n_0_[8] }),
        .O({\rleft_reg[15]_i_2_n_8 ,\rleft_reg[15]_i_2_n_9 ,\rleft_reg[15]_i_2_n_10 ,\rleft_reg[15]_i_2_n_11 ,\rleft_reg[15]_i_2_n_12 ,\rleft_reg[15]_i_2_n_13 ,\rleft_reg[15]_i_2_n_14 ,\rleft_reg[15]_i_2_n_15 }),
        .S({\rleft[15]_i_3_n_0 ,\rleft[15]_i_4_n_0 ,\rleft[15]_i_5_n_0 ,\rleft[15]_i_6_n_0 ,\rleft[15]_i_7_n_0 ,\rleft[15]_i_8_n_0 ,\rleft[15]_i_9_n_0 ,\rleft[15]_i_10_n_0 }));
  FDRE \rleft_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[1]),
        .Q(\rleft_reg_n_0_[1] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[2]),
        .Q(\rleft_reg_n_0_[2] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[3]),
        .Q(\rleft_reg_n_0_[3] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[4]),
        .Q(\rleft_reg_n_0_[4] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[5]),
        .Q(\rleft_reg_n_0_[5] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[6]),
        .Q(\rleft_reg_n_0_[6] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[7]),
        .Q(\rleft_reg_n_0_[7] ),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \rleft_reg[7]_i_2 
       (.CI(1'b1),
        .CI_TOP(1'b0),
        .CO({\rleft_reg[7]_i_2_n_0 ,\rleft_reg[7]_i_2_n_1 ,\rleft_reg[7]_i_2_n_2 ,\rleft_reg[7]_i_2_n_3 ,\rleft_reg[7]_i_2_n_4 ,\rleft_reg[7]_i_2_n_5 ,\rleft_reg[7]_i_2_n_6 ,\rleft_reg[7]_i_2_n_7 }),
        .DI({\rleft_reg_n_0_[7] ,\rleft_reg_n_0_[6] ,\rleft_reg_n_0_[5] ,\rleft_reg_n_0_[4] ,\rleft_reg_n_0_[3] ,\rleft_reg_n_0_[2] ,\rleft_reg_n_0_[1] ,\rleft_reg_n_0_[0] }),
        .O({\rleft_reg[7]_i_2_n_8 ,\rleft_reg[7]_i_2_n_9 ,\rleft_reg[7]_i_2_n_10 ,\rleft_reg[7]_i_2_n_11 ,\rleft_reg[7]_i_2_n_12 ,\rleft_reg[7]_i_2_n_13 ,\rleft_reg[7]_i_2_n_14 ,\rleft_reg[7]_i_2_n_15 }),
        .S({\rleft[7]_i_3_n_0 ,\rleft[7]_i_4_n_0 ,\rleft[7]_i_5_n_0 ,\rleft[7]_i_6_n_0 ,\rleft[7]_i_7_n_0 ,\rleft[7]_i_8_n_0 ,\rleft[7]_i_9_n_0 ,\rleft[7]_i_10_n_0 }));
  FDRE \rleft_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[8]),
        .Q(\rleft_reg_n_0_[8] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \rleft_reg[9] 
       (.C(M_AXI_ACLK),
        .CE(ra_2),
        .D(rleft[9]),
        .Q(\rleft_reg_n_0_[9] ),
        .R(fdma_wdone_i_1_n_0));
  (* COMPARATOR_THRESHOLD = "11" *) 
  CARRY8 \update_wb.available1_carry 
       (.CI(1'b0),
        .CI_TOP(1'b0),
        .CO({\update_wb.available1 ,\update_wb.available1_carry_n_1 ,\update_wb.available1_carry_n_2 ,\update_wb.available1_carry_n_3 ,\update_wb.available1_carry_n_4 ,\update_wb.available1_carry_n_5 ,\update_wb.available1_carry_n_6 ,\update_wb.available1_carry_n_7 }),
        .DI({1'b0,1'b0,1'b0,\update_wb.available1_carry_i_1_n_0 ,\update_wb.available1_carry_i_2_n_0 ,\update_wb.available1_carry_i_3_n_0 ,\update_wb.available1_carry_i_4_n_0 ,\update_wb.available1_carry_i_5_n_0 }),
        .O(\NLW_update_wb.available1_carry_O_UNCONNECTED [7:0]),
        .S({\update_wb.available1_carry_i_6_n_0 ,\update_wb.available1_carry_i_7_n_0 ,\update_wb.available1_carry_i_8_n_0 ,\update_wb.available1_carry_i_9_n_0 ,\update_wb.available1_carry_i_10_n_0 ,\update_wb.available1_carry_i_11_n_0 ,\update_wb.available1_carry_i_12_n_0 ,\update_wb.available1_carry_i_13_n_0 }));
  (* COMPARATOR_THRESHOLD = "11" *) 
  CARRY8 \update_wb.available1_carry__0 
       (.CI(1'b0),
        .CI_TOP(1'b0),
        .CO({\update_wb.available1_carry__0_n_0 ,\update_wb.available1_carry__0_n_1 ,\update_wb.available1_carry__0_n_2 ,\update_wb.available1_carry__0_n_3 ,\update_wb.available1_carry__0_n_4 ,\update_wb.available1_carry__0_n_5 ,\update_wb.available1_carry__0_n_6 ,\update_wb.available1_carry__0_n_7 }),
        .DI({1'b0,1'b0,1'b0,\update_wb.available1_carry_i_1__0_n_0 ,\update_wb.available1_carry_i_2__0_n_0 ,\update_wb.available1_carry_i_3__0_n_0 ,\update_wb.available1_carry_i_4__0_n_0 ,\update_wb.available1_carry_i_5__0_n_0 }),
        .O(\NLW_update_wb.available1_carry__0_O_UNCONNECTED [7:0]),
        .S({\update_wb.available1_carry_i_6__0_n_0 ,\update_wb.available1_carry_i_7__0_n_0 ,\update_wb.available1_carry_i_8__0_n_0 ,\update_wb.available1_carry_i_9__0_n_0 ,\update_wb.available1_carry_i_10__0_n_0 ,\update_wb.available1_carry_i_11__0_n_0 ,\update_wb.available1_carry_i_12__0_n_0 ,\update_wb.available1_carry_i_13__0_n_0 }));
  LUT5 #(
    .INIT(32'h000100F7)) 
    \update_wb.available1_carry_i_1 
       (.I0(\wa_reg[63]_0 [11]),
        .I1(\wb[8]_i_3_n_0 ),
        .I2(\wb[8]_i_4_n_0 ),
        .I3(\wleft_reg_n_0_[9] ),
        .I4(\wleft_reg_n_0_[8] ),
        .O(\update_wb.available1_carry_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h000900900024FF42)) 
    \update_wb.available1_carry_i_10 
       (.I0(\wb[6]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [9]),
        .I2(\wa_reg[63]_0 [10]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[7] ),
        .I5(\wleft_reg_n_0_[6] ),
        .O(\update_wb.available1_carry_i_10_n_0 ));
  LUT6 #(
    .INIT(64'h0000214255558418)) 
    \update_wb.available1_carry_i_10__0 
       (.I0(\rleft_reg_n_0_[6] ),
        .I1(Q[10]),
        .I2(\update_wb.available1_carry_i_14__0_n_0 ),
        .I3(Q[9]),
        .I4(\rb[8]_i_4_n_0 ),
        .I5(\rleft_reg_n_0_[7] ),
        .O(\update_wb.available1_carry_i_10__0_n_0 ));
  LUT6 #(
    .INIT(64'h000900900024FF42)) 
    \update_wb.available1_carry_i_11 
       (.I0(\update_wb.available1_carry_i_14_n_0 ),
        .I1(\wa_reg[63]_0 [7]),
        .I2(\wa_reg[63]_0 [8]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[5] ),
        .I5(\wleft_reg_n_0_[4] ),
        .O(\update_wb.available1_carry_i_11_n_0 ));
  LUT6 #(
    .INIT(64'h0000214255558418)) 
    \update_wb.available1_carry_i_11__0 
       (.I0(\rleft_reg_n_0_[4] ),
        .I1(Q[8]),
        .I2(\update_wb.available1_carry_i_15__0_n_0 ),
        .I3(Q[7]),
        .I4(\rb[8]_i_4_n_0 ),
        .I5(\rleft_reg_n_0_[5] ),
        .O(\update_wb.available1_carry_i_11__0_n_0 ));
  LUT6 #(
    .INIT(64'h000900900024FF42)) 
    \update_wb.available1_carry_i_12 
       (.I0(\update_wb.available1_carry_i_15_n_0 ),
        .I1(\wa_reg[63]_0 [5]),
        .I2(\wa_reg[63]_0 [6]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[3] ),
        .I5(\wleft_reg_n_0_[2] ),
        .O(\update_wb.available1_carry_i_12_n_0 ));
  LUT6 #(
    .INIT(64'h0000214255558418)) 
    \update_wb.available1_carry_i_12__0 
       (.I0(\rleft_reg_n_0_[2] ),
        .I1(Q[6]),
        .I2(\update_wb.available1_carry_i_16__0_n_0 ),
        .I3(Q[5]),
        .I4(\rb[8]_i_4_n_0 ),
        .I5(\rleft_reg_n_0_[3] ),
        .O(\update_wb.available1_carry_i_12__0_n_0 ));
  LUT6 #(
    .INIT(64'h000900900024FF42)) 
    \update_wb.available1_carry_i_13 
       (.I0(\update_wb.available1_carry_i_16_n_0 ),
        .I1(\wa_reg[63]_0 [3]),
        .I2(\wa_reg[63]_0 [4]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[1] ),
        .I5(\wleft_reg_n_0_[0] ),
        .O(\update_wb.available1_carry_i_13_n_0 ));
  LUT6 #(
    .INIT(64'h0000214255558418)) 
    \update_wb.available1_carry_i_13__0 
       (.I0(\rleft_reg_n_0_[0] ),
        .I1(Q[4]),
        .I2(\update_wb.available1_carry_i_17_n_0 ),
        .I3(Q[3]),
        .I4(\rb[8]_i_4_n_0 ),
        .I5(\rleft_reg_n_0_[1] ),
        .O(\update_wb.available1_carry_i_13__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_14 
       (.I0(\wb[4]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [6]),
        .O(\update_wb.available1_carry_i_14_n_0 ));
  LUT4 #(
    .INIT(16'h0004)) 
    \update_wb.available1_carry_i_14__0 
       (.I0(Q[7]),
        .I1(\rb[4]_i_2_n_0 ),
        .I2(Q[6]),
        .I3(Q[8]),
        .O(\update_wb.available1_carry_i_14__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT5 #(
    .INIT(32'h00000001)) 
    \update_wb.available1_carry_i_15 
       (.I0(\wa_reg[63]_0 [1]),
        .I1(\wa_reg[63]_0 [0]),
        .I2(\wa_reg[63]_0 [2]),
        .I3(\wa_reg[63]_0 [3]),
        .I4(\wa_reg[63]_0 [4]),
        .O(\update_wb.available1_carry_i_15_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair12" *) 
  LUT2 #(
    .INIT(4'h2)) 
    \update_wb.available1_carry_i_15__0 
       (.I0(\rb[4]_i_2_n_0 ),
        .I1(Q[6]),
        .O(\update_wb.available1_carry_i_15__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair17" *) 
  LUT3 #(
    .INIT(8'h01)) 
    \update_wb.available1_carry_i_16 
       (.I0(\wa_reg[63]_0 [1]),
        .I1(\wa_reg[63]_0 [0]),
        .I2(\wa_reg[63]_0 [2]),
        .O(\update_wb.available1_carry_i_16_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT5 #(
    .INIT(32'h00000001)) 
    \update_wb.available1_carry_i_16__0 
       (.I0(Q[3]),
        .I1(Q[0]),
        .I2(Q[1]),
        .I3(Q[2]),
        .I4(Q[4]),
        .O(\update_wb.available1_carry_i_16__0_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair23" *) 
  LUT3 #(
    .INIT(8'h01)) 
    \update_wb.available1_carry_i_17 
       (.I0(Q[0]),
        .I1(Q[1]),
        .I2(Q[2]),
        .O(\update_wb.available1_carry_i_17_n_0 ));
  LUT5 #(
    .INIT(32'h11111301)) 
    \update_wb.available1_carry_i_1__0 
       (.I0(\rleft_reg_n_0_[8] ),
        .I1(\rleft_reg_n_0_[9] ),
        .I2(Q[11]),
        .I3(\rb[8]_i_3_n_0 ),
        .I4(\rb[8]_i_4_n_0 ),
        .O(\update_wb.available1_carry_i_1__0_n_0 ));
  LUT6 #(
    .INIT(64'h0000002D000900BD)) 
    \update_wb.available1_carry_i_2 
       (.I0(\wb[6]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [9]),
        .I2(\wa_reg[63]_0 [10]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[7] ),
        .I5(\wleft_reg_n_0_[6] ),
        .O(\update_wb.available1_carry_i_2_n_0 ));
  LUT6 #(
    .INIT(64'h0000000017033017)) 
    \update_wb.available1_carry_i_2__0 
       (.I0(\rleft_reg_n_0_[6] ),
        .I1(\rleft_reg_n_0_[7] ),
        .I2(Q[10]),
        .I3(\update_wb.available1_carry_i_14__0_n_0 ),
        .I4(Q[9]),
        .I5(\rb[8]_i_4_n_0 ),
        .O(\update_wb.available1_carry_i_2__0_n_0 ));
  LUT6 #(
    .INIT(64'h0000002D000900BD)) 
    \update_wb.available1_carry_i_3 
       (.I0(\update_wb.available1_carry_i_14_n_0 ),
        .I1(\wa_reg[63]_0 [7]),
        .I2(\wa_reg[63]_0 [8]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[5] ),
        .I5(\wleft_reg_n_0_[4] ),
        .O(\update_wb.available1_carry_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h0000000017033017)) 
    \update_wb.available1_carry_i_3__0 
       (.I0(\rleft_reg_n_0_[4] ),
        .I1(\rleft_reg_n_0_[5] ),
        .I2(Q[8]),
        .I3(\update_wb.available1_carry_i_15__0_n_0 ),
        .I4(Q[7]),
        .I5(\rb[8]_i_4_n_0 ),
        .O(\update_wb.available1_carry_i_3__0_n_0 ));
  LUT6 #(
    .INIT(64'h0000002D000900BD)) 
    \update_wb.available1_carry_i_4 
       (.I0(\update_wb.available1_carry_i_15_n_0 ),
        .I1(\wa_reg[63]_0 [5]),
        .I2(\wa_reg[63]_0 [6]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[3] ),
        .I5(\wleft_reg_n_0_[2] ),
        .O(\update_wb.available1_carry_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h0000000017033017)) 
    \update_wb.available1_carry_i_4__0 
       (.I0(\rleft_reg_n_0_[2] ),
        .I1(\rleft_reg_n_0_[3] ),
        .I2(Q[6]),
        .I3(\update_wb.available1_carry_i_16__0_n_0 ),
        .I4(Q[5]),
        .I5(\rb[8]_i_4_n_0 ),
        .O(\update_wb.available1_carry_i_4__0_n_0 ));
  LUT6 #(
    .INIT(64'h0000002D000900BD)) 
    \update_wb.available1_carry_i_5 
       (.I0(\update_wb.available1_carry_i_16_n_0 ),
        .I1(\wa_reg[63]_0 [3]),
        .I2(\wa_reg[63]_0 [4]),
        .I3(\wb[8]_i_4_n_0 ),
        .I4(\wleft_reg_n_0_[1] ),
        .I5(\wleft_reg_n_0_[0] ),
        .O(\update_wb.available1_carry_i_5_n_0 ));
  LUT6 #(
    .INIT(64'h0000000017033017)) 
    \update_wb.available1_carry_i_5__0 
       (.I0(\rleft_reg_n_0_[0] ),
        .I1(\rleft_reg_n_0_[1] ),
        .I2(Q[4]),
        .I3(\update_wb.available1_carry_i_17_n_0 ),
        .I4(Q[3]),
        .I5(\rb[8]_i_4_n_0 ),
        .O(\update_wb.available1_carry_i_5__0_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_6 
       (.I0(\wleft_reg_n_0_[15] ),
        .I1(\wleft_reg_n_0_[14] ),
        .O(\update_wb.available1_carry_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_6__0 
       (.I0(\rleft_reg_n_0_[14] ),
        .I1(\rleft_reg_n_0_[15] ),
        .O(\update_wb.available1_carry_i_6__0_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_7 
       (.I0(\wleft_reg_n_0_[13] ),
        .I1(\wleft_reg_n_0_[12] ),
        .O(\update_wb.available1_carry_i_7_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_7__0 
       (.I0(\rleft_reg_n_0_[12] ),
        .I1(\rleft_reg_n_0_[13] ),
        .O(\update_wb.available1_carry_i_7__0_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_8 
       (.I0(\wleft_reg_n_0_[11] ),
        .I1(\wleft_reg_n_0_[10] ),
        .O(\update_wb.available1_carry_i_8_n_0 ));
  LUT2 #(
    .INIT(4'h1)) 
    \update_wb.available1_carry_i_8__0 
       (.I0(\rleft_reg_n_0_[10] ),
        .I1(\rleft_reg_n_0_[11] ),
        .O(\update_wb.available1_carry_i_8__0_n_0 ));
  LUT5 #(
    .INIT(32'h00F60108)) 
    \update_wb.available1_carry_i_9 
       (.I0(\wa_reg[63]_0 [11]),
        .I1(\wb[8]_i_3_n_0 ),
        .I2(\wb[8]_i_4_n_0 ),
        .I3(\wleft_reg_n_0_[9] ),
        .I4(\wleft_reg_n_0_[8] ),
        .O(\update_wb.available1_carry_i_9_n_0 ));
  LUT5 #(
    .INIT(32'h0010AA86)) 
    \update_wb.available1_carry_i_9__0 
       (.I0(\rleft_reg_n_0_[8] ),
        .I1(Q[11]),
        .I2(\rb[8]_i_3_n_0 ),
        .I3(\rb[8]_i_4_n_0 ),
        .I4(\rleft_reg_n_0_[9] ),
        .O(\update_wb.available1_carry_i_9__0_n_0 ));
  LUT6 #(
    .INIT(64'hFFFF7FFF00FF0000)) 
    w_pending_i_1
       (.I0(M_AXI_WLAST),
        .I1(M_AXI_WREADY),
        .I2(M_AXI_WVALID),
        .I3(write_curr_st__0[1]),
        .I4(write_curr_st__0[0]),
        .I5(w_pending_reg_n_0),
        .O(w_pending_i_1_n_0));
  FDRE w_pending_reg
       (.C(M_AXI_ACLK),
        .CE(1'b1),
        .D(w_pending_i_1_n_0),
        .Q(w_pending_reg_n_0),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair68" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[0]_i_1 
       (.I0(\wa_reg[63]_0 [0]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[0]),
        .O(wa[0]));
  (* SOFT_HLUTNM = "soft_lutpair63" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[10]_i_1 
       (.I0(in14[10]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[10]),
        .O(wa[10]));
  (* SOFT_HLUTNM = "soft_lutpair62" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[11]_i_1 
       (.I0(in14[11]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[11]),
        .O(wa[11]));
  (* SOFT_HLUTNM = "soft_lutpair62" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[12]_i_1 
       (.I0(in14[12]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[12]),
        .O(wa[12]));
  (* SOFT_HLUTNM = "soft_lutpair61" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[13]_i_1 
       (.I0(in14[13]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[13]),
        .O(wa[13]));
  (* SOFT_HLUTNM = "soft_lutpair61" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[14]_i_1 
       (.I0(in14[14]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[14]),
        .O(wa[14]));
  (* SOFT_HLUTNM = "soft_lutpair60" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[15]_i_1 
       (.I0(in14[15]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[15]),
        .O(wa[15]));
  (* SOFT_HLUTNM = "soft_lutpair60" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[16]_i_1 
       (.I0(in14[16]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[16]),
        .O(wa[16]));
  (* SOFT_HLUTNM = "soft_lutpair59" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[17]_i_1 
       (.I0(in14[17]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[17]),
        .O(wa[17]));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[17]_i_3 
       (.I0(\wa_reg[63]_0 [11]),
        .I1(\wb_reg_n_0_[8] ),
        .O(\wa[17]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[17]_i_4 
       (.I0(\wa_reg[63]_0 [10]),
        .I1(\wb_reg_n_0_[7] ),
        .O(\wa[17]_i_4_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair59" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[18]_i_1 
       (.I0(in14[18]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[18]),
        .O(wa[18]));
  (* SOFT_HLUTNM = "soft_lutpair58" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[19]_i_1 
       (.I0(in14[19]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[19]),
        .O(wa[19]));
  (* SOFT_HLUTNM = "soft_lutpair67" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[1]_i_1 
       (.I0(\wa_reg[63]_0 [1]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[1]),
        .O(wa[1]));
  (* SOFT_HLUTNM = "soft_lutpair58" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[20]_i_1 
       (.I0(in14[20]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[20]),
        .O(wa[20]));
  (* SOFT_HLUTNM = "soft_lutpair57" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[21]_i_1 
       (.I0(in14[21]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[21]),
        .O(wa[21]));
  (* SOFT_HLUTNM = "soft_lutpair57" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[22]_i_1 
       (.I0(in14[22]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[22]),
        .O(wa[22]));
  (* SOFT_HLUTNM = "soft_lutpair56" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[23]_i_1 
       (.I0(in14[23]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[23]),
        .O(wa[23]));
  (* SOFT_HLUTNM = "soft_lutpair56" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[24]_i_1 
       (.I0(in14[24]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[24]),
        .O(wa[24]));
  (* SOFT_HLUTNM = "soft_lutpair55" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[25]_i_1 
       (.I0(in14[25]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[25]),
        .O(wa[25]));
  (* SOFT_HLUTNM = "soft_lutpair55" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[26]_i_1 
       (.I0(in14[26]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[26]),
        .O(wa[26]));
  (* SOFT_HLUTNM = "soft_lutpair54" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[27]_i_1 
       (.I0(in14[27]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[27]),
        .O(wa[27]));
  (* SOFT_HLUTNM = "soft_lutpair54" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[28]_i_1 
       (.I0(in14[28]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[28]),
        .O(wa[28]));
  (* SOFT_HLUTNM = "soft_lutpair53" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[29]_i_1 
       (.I0(in14[29]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[29]),
        .O(wa[29]));
  (* SOFT_HLUTNM = "soft_lutpair67" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[2]_i_1 
       (.I0(in14[2]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[2]),
        .O(wa[2]));
  (* SOFT_HLUTNM = "soft_lutpair53" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[30]_i_1 
       (.I0(in14[30]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[30]),
        .O(wa[30]));
  (* SOFT_HLUTNM = "soft_lutpair52" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[31]_i_1 
       (.I0(in14[31]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[31]),
        .O(wa[31]));
  (* SOFT_HLUTNM = "soft_lutpair52" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[32]_i_1 
       (.I0(in14[32]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[32]),
        .O(wa[32]));
  (* SOFT_HLUTNM = "soft_lutpair51" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[33]_i_1 
       (.I0(in14[33]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[33]),
        .O(wa[33]));
  (* SOFT_HLUTNM = "soft_lutpair51" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[34]_i_1 
       (.I0(in14[34]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[34]),
        .O(wa[34]));
  (* SOFT_HLUTNM = "soft_lutpair50" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[35]_i_1 
       (.I0(in14[35]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[35]),
        .O(wa[35]));
  (* SOFT_HLUTNM = "soft_lutpair50" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[36]_i_1 
       (.I0(in14[36]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[36]),
        .O(wa[36]));
  (* SOFT_HLUTNM = "soft_lutpair49" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[37]_i_1 
       (.I0(in14[37]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[37]),
        .O(wa[37]));
  (* SOFT_HLUTNM = "soft_lutpair49" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[38]_i_1 
       (.I0(in14[38]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[38]),
        .O(wa[38]));
  (* SOFT_HLUTNM = "soft_lutpair48" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[39]_i_1 
       (.I0(in14[39]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[39]),
        .O(wa[39]));
  (* SOFT_HLUTNM = "soft_lutpair66" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[3]_i_1 
       (.I0(in14[3]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[3]),
        .O(wa[3]));
  (* SOFT_HLUTNM = "soft_lutpair48" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[40]_i_1 
       (.I0(in14[40]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[40]),
        .O(wa[40]));
  (* SOFT_HLUTNM = "soft_lutpair47" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[41]_i_1 
       (.I0(in14[41]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[41]),
        .O(wa[41]));
  (* SOFT_HLUTNM = "soft_lutpair47" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[42]_i_1 
       (.I0(in14[42]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[42]),
        .O(wa[42]));
  (* SOFT_HLUTNM = "soft_lutpair46" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[43]_i_1 
       (.I0(in14[43]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[43]),
        .O(wa[43]));
  (* SOFT_HLUTNM = "soft_lutpair46" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[44]_i_1 
       (.I0(in14[44]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[44]),
        .O(wa[44]));
  (* SOFT_HLUTNM = "soft_lutpair45" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[45]_i_1 
       (.I0(in14[45]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[45]),
        .O(wa[45]));
  (* SOFT_HLUTNM = "soft_lutpair45" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[46]_i_1 
       (.I0(in14[46]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[46]),
        .O(wa[46]));
  (* SOFT_HLUTNM = "soft_lutpair44" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[47]_i_1 
       (.I0(in14[47]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[47]),
        .O(wa[47]));
  (* SOFT_HLUTNM = "soft_lutpair44" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[48]_i_1 
       (.I0(in14[48]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[48]),
        .O(wa[48]));
  (* SOFT_HLUTNM = "soft_lutpair43" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[49]_i_1 
       (.I0(in14[49]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[49]),
        .O(wa[49]));
  (* SOFT_HLUTNM = "soft_lutpair66" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[4]_i_1 
       (.I0(in14[4]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[4]),
        .O(wa[4]));
  (* SOFT_HLUTNM = "soft_lutpair43" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[50]_i_1 
       (.I0(in14[50]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[50]),
        .O(wa[50]));
  (* SOFT_HLUTNM = "soft_lutpair42" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[51]_i_1 
       (.I0(in14[51]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[51]),
        .O(wa[51]));
  (* SOFT_HLUTNM = "soft_lutpair42" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[52]_i_1 
       (.I0(in14[52]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[52]),
        .O(wa[52]));
  (* SOFT_HLUTNM = "soft_lutpair41" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[53]_i_1 
       (.I0(in14[53]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[53]),
        .O(wa[53]));
  (* SOFT_HLUTNM = "soft_lutpair41" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[54]_i_1 
       (.I0(in14[54]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[54]),
        .O(wa[54]));
  (* SOFT_HLUTNM = "soft_lutpair40" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[55]_i_1 
       (.I0(in14[55]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[55]),
        .O(wa[55]));
  (* SOFT_HLUTNM = "soft_lutpair40" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[56]_i_1 
       (.I0(in14[56]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[56]),
        .O(wa[56]));
  (* SOFT_HLUTNM = "soft_lutpair39" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[57]_i_1 
       (.I0(in14[57]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[57]),
        .O(wa[57]));
  (* SOFT_HLUTNM = "soft_lutpair39" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[58]_i_1 
       (.I0(in14[58]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[58]),
        .O(wa[58]));
  (* SOFT_HLUTNM = "soft_lutpair38" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[59]_i_1 
       (.I0(in14[59]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[59]),
        .O(wa[59]));
  (* SOFT_HLUTNM = "soft_lutpair65" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[5]_i_1 
       (.I0(in14[5]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[5]),
        .O(wa[5]));
  (* SOFT_HLUTNM = "soft_lutpair38" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[60]_i_1 
       (.I0(in14[60]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[60]),
        .O(wa[60]));
  (* SOFT_HLUTNM = "soft_lutpair37" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[61]_i_1 
       (.I0(in14[61]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[61]),
        .O(wa[61]));
  (* SOFT_HLUTNM = "soft_lutpair37" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[62]_i_1 
       (.I0(in14[62]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[62]),
        .O(wa[62]));
  LUT6 #(
    .INIT(64'h44004400000F0000)) 
    \wa[63]_i_1 
       (.I0(write_next_st1__23),
        .I1(\wa[63]_i_3_n_0 ),
        .I2(fdma_wdone_i_4_n_0),
        .I3(write_curr_st__0[1]),
        .I4(fdma_wareq),
        .I5(write_curr_st__0[0]),
        .O(wa_0));
  (* SOFT_HLUTNM = "soft_lutpair36" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[63]_i_2 
       (.I0(in14[63]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[63]),
        .O(wa[63]));
  (* SOFT_HLUTNM = "soft_lutpair26" *) 
  LUT3 #(
    .INIT(8'h80)) 
    \wa[63]_i_3 
       (.I0(write_curr_st[0]),
        .I1(write_curr_st[1]),
        .I2(M_AXI_BVALID),
        .O(\wa[63]_i_3_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair65" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[6]_i_1 
       (.I0(in14[6]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[6]),
        .O(wa[6]));
  (* SOFT_HLUTNM = "soft_lutpair64" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[7]_i_1 
       (.I0(in14[7]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[7]),
        .O(wa[7]));
  (* SOFT_HLUTNM = "soft_lutpair64" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[8]_i_1 
       (.I0(in14[8]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[8]),
        .O(wa[8]));
  (* SOFT_HLUTNM = "soft_lutpair63" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wa[9]_i_1 
       (.I0(in14[9]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_waddr[9]),
        .O(wa[9]));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_3 
       (.I0(\wa_reg[63]_0 [9]),
        .I1(\wb_reg_n_0_[6] ),
        .O(\wa[9]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_4 
       (.I0(\wa_reg[63]_0 [8]),
        .I1(\wb_reg_n_0_[5] ),
        .O(\wa[9]_i_4_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_5 
       (.I0(\wa_reg[63]_0 [7]),
        .I1(\wb_reg_n_0_[4] ),
        .O(\wa[9]_i_5_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_6 
       (.I0(\wa_reg[63]_0 [6]),
        .I1(\wb_reg_n_0_[3] ),
        .O(\wa[9]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_7 
       (.I0(\wa_reg[63]_0 [5]),
        .I1(\wb_reg_n_0_[2] ),
        .O(\wa[9]_i_7_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_8 
       (.I0(\wa_reg[63]_0 [4]),
        .I1(\wb_reg_n_0_[1] ),
        .O(\wa[9]_i_8_n_0 ));
  LUT2 #(
    .INIT(4'h6)) 
    \wa[9]_i_9 
       (.I0(\wa_reg[63]_0 [3]),
        .I1(\wb_reg_n_0_[0] ),
        .O(\wa[9]_i_9_n_0 ));
  FDRE \wa_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[0]),
        .Q(\wa_reg[63]_0 [0]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[10] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[10]),
        .Q(\wa_reg[63]_0 [10]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[11] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[11]),
        .Q(\wa_reg[63]_0 [11]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[12] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[12]),
        .Q(\wa_reg[63]_0 [12]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[13] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[13]),
        .Q(\wa_reg[63]_0 [13]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[14] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[14]),
        .Q(\wa_reg[63]_0 [14]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[15] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[15]),
        .Q(\wa_reg[63]_0 [15]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[16] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[16]),
        .Q(\wa_reg[63]_0 [16]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[17] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[17]),
        .Q(\wa_reg[63]_0 [17]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[17]_i_2 
       (.CI(\wa_reg[9]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\wa_reg[17]_i_2_n_0 ,\wa_reg[17]_i_2_n_1 ,\wa_reg[17]_i_2_n_2 ,\wa_reg[17]_i_2_n_3 ,\wa_reg[17]_i_2_n_4 ,\wa_reg[17]_i_2_n_5 ,\wa_reg[17]_i_2_n_6 ,\wa_reg[17]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,\wa_reg[63]_0 [11:10]}),
        .O(in14[17:10]),
        .S({\wa_reg[63]_0 [17:12],\wa[17]_i_3_n_0 ,\wa[17]_i_4_n_0 }));
  FDRE \wa_reg[18] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[18]),
        .Q(\wa_reg[63]_0 [18]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[19] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[19]),
        .Q(\wa_reg[63]_0 [19]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[1]),
        .Q(\wa_reg[63]_0 [1]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[20] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[20]),
        .Q(\wa_reg[63]_0 [20]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[21] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[21]),
        .Q(\wa_reg[63]_0 [21]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[22] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[22]),
        .Q(\wa_reg[63]_0 [22]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[23] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[23]),
        .Q(\wa_reg[63]_0 [23]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[24] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[24]),
        .Q(\wa_reg[63]_0 [24]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[25] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[25]),
        .Q(\wa_reg[63]_0 [25]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[25]_i_2 
       (.CI(\wa_reg[17]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\wa_reg[25]_i_2_n_0 ,\wa_reg[25]_i_2_n_1 ,\wa_reg[25]_i_2_n_2 ,\wa_reg[25]_i_2_n_3 ,\wa_reg[25]_i_2_n_4 ,\wa_reg[25]_i_2_n_5 ,\wa_reg[25]_i_2_n_6 ,\wa_reg[25]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in14[25:18]),
        .S(\wa_reg[63]_0 [25:18]));
  FDRE \wa_reg[26] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[26]),
        .Q(\wa_reg[63]_0 [26]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[27] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[27]),
        .Q(\wa_reg[63]_0 [27]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[28] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[28]),
        .Q(\wa_reg[63]_0 [28]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[29] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[29]),
        .Q(\wa_reg[63]_0 [29]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[2]),
        .Q(\wa_reg[63]_0 [2]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[30] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[30]),
        .Q(\wa_reg[63]_0 [30]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[31] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[31]),
        .Q(\wa_reg[63]_0 [31]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[32] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[32]),
        .Q(\wa_reg[63]_0 [32]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[33] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[33]),
        .Q(\wa_reg[63]_0 [33]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[33]_i_2 
       (.CI(\wa_reg[25]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\wa_reg[33]_i_2_n_0 ,\wa_reg[33]_i_2_n_1 ,\wa_reg[33]_i_2_n_2 ,\wa_reg[33]_i_2_n_3 ,\wa_reg[33]_i_2_n_4 ,\wa_reg[33]_i_2_n_5 ,\wa_reg[33]_i_2_n_6 ,\wa_reg[33]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in14[33:26]),
        .S(\wa_reg[63]_0 [33:26]));
  FDRE \wa_reg[34] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[34]),
        .Q(\wa_reg[63]_0 [34]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[35] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[35]),
        .Q(\wa_reg[63]_0 [35]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[36] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[36]),
        .Q(\wa_reg[63]_0 [36]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[37] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[37]),
        .Q(\wa_reg[63]_0 [37]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[38] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[38]),
        .Q(\wa_reg[63]_0 [38]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[39] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[39]),
        .Q(\wa_reg[63]_0 [39]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[3]),
        .Q(\wa_reg[63]_0 [3]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[40] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[40]),
        .Q(\wa_reg[63]_0 [40]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[41] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[41]),
        .Q(\wa_reg[63]_0 [41]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[41]_i_2 
       (.CI(\wa_reg[33]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\wa_reg[41]_i_2_n_0 ,\wa_reg[41]_i_2_n_1 ,\wa_reg[41]_i_2_n_2 ,\wa_reg[41]_i_2_n_3 ,\wa_reg[41]_i_2_n_4 ,\wa_reg[41]_i_2_n_5 ,\wa_reg[41]_i_2_n_6 ,\wa_reg[41]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in14[41:34]),
        .S(\wa_reg[63]_0 [41:34]));
  FDRE \wa_reg[42] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[42]),
        .Q(\wa_reg[63]_0 [42]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[43] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[43]),
        .Q(\wa_reg[63]_0 [43]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[44] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[44]),
        .Q(\wa_reg[63]_0 [44]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[45] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[45]),
        .Q(\wa_reg[63]_0 [45]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[46] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[46]),
        .Q(\wa_reg[63]_0 [46]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[47] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[47]),
        .Q(\wa_reg[63]_0 [47]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[48] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[48]),
        .Q(\wa_reg[63]_0 [48]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[49] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[49]),
        .Q(\wa_reg[63]_0 [49]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[49]_i_2 
       (.CI(\wa_reg[41]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\wa_reg[49]_i_2_n_0 ,\wa_reg[49]_i_2_n_1 ,\wa_reg[49]_i_2_n_2 ,\wa_reg[49]_i_2_n_3 ,\wa_reg[49]_i_2_n_4 ,\wa_reg[49]_i_2_n_5 ,\wa_reg[49]_i_2_n_6 ,\wa_reg[49]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in14[49:42]),
        .S(\wa_reg[63]_0 [49:42]));
  FDRE \wa_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[4]),
        .Q(\wa_reg[63]_0 [4]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[50] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[50]),
        .Q(\wa_reg[63]_0 [50]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[51] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[51]),
        .Q(\wa_reg[63]_0 [51]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[52] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[52]),
        .Q(\wa_reg[63]_0 [52]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[53] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[53]),
        .Q(\wa_reg[63]_0 [53]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[54] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[54]),
        .Q(\wa_reg[63]_0 [54]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[55] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[55]),
        .Q(\wa_reg[63]_0 [55]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[56] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[56]),
        .Q(\wa_reg[63]_0 [56]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[57] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[57]),
        .Q(\wa_reg[63]_0 [57]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[57]_i_2 
       (.CI(\wa_reg[49]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\wa_reg[57]_i_2_n_0 ,\wa_reg[57]_i_2_n_1 ,\wa_reg[57]_i_2_n_2 ,\wa_reg[57]_i_2_n_3 ,\wa_reg[57]_i_2_n_4 ,\wa_reg[57]_i_2_n_5 ,\wa_reg[57]_i_2_n_6 ,\wa_reg[57]_i_2_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O(in14[57:50]),
        .S(\wa_reg[63]_0 [57:50]));
  FDRE \wa_reg[58] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[58]),
        .Q(\wa_reg[63]_0 [58]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[59] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[59]),
        .Q(\wa_reg[63]_0 [59]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[5]),
        .Q(\wa_reg[63]_0 [5]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[60] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[60]),
        .Q(\wa_reg[63]_0 [60]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[61] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[61]),
        .Q(\wa_reg[63]_0 [61]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[62] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[62]),
        .Q(\wa_reg[63]_0 [62]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[63] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[63]),
        .Q(\wa_reg[63]_0 [63]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[63]_i_4 
       (.CI(\wa_reg[57]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\NLW_wa_reg[63]_i_4_CO_UNCONNECTED [7:5],\wa_reg[63]_i_4_n_3 ,\wa_reg[63]_i_4_n_4 ,\wa_reg[63]_i_4_n_5 ,\wa_reg[63]_i_4_n_6 ,\wa_reg[63]_i_4_n_7 }),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .O({\NLW_wa_reg[63]_i_4_O_UNCONNECTED [7:6],in14[63:58]}),
        .S({1'b0,1'b0,\wa_reg[63]_0 [63:58]}));
  FDRE \wa_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[6]),
        .Q(\wa_reg[63]_0 [6]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[7]),
        .Q(\wa_reg[63]_0 [7]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[8]),
        .Q(\wa_reg[63]_0 [8]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wa_reg[9] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wa[9]),
        .Q(\wa_reg[63]_0 [9]),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wa_reg[9]_i_2 
       (.CI(1'b0),
        .CI_TOP(1'b0),
        .CO({\wa_reg[9]_i_2_n_0 ,\wa_reg[9]_i_2_n_1 ,\wa_reg[9]_i_2_n_2 ,\wa_reg[9]_i_2_n_3 ,\wa_reg[9]_i_2_n_4 ,\wa_reg[9]_i_2_n_5 ,\wa_reg[9]_i_2_n_6 ,\wa_reg[9]_i_2_n_7 }),
        .DI({\wa_reg[63]_0 [9:3],1'b0}),
        .O(in14[9:2]),
        .S({\wa[9]_i_3_n_0 ,\wa[9]_i_4_n_0 ,\wa[9]_i_5_n_0 ,\wa[9]_i_6_n_0 ,\wa[9]_i_7_n_0 ,\wa[9]_i_8_n_0 ,\wa[9]_i_9_n_0 ,\wa_reg[63]_0 [2]}));
  LUT4 #(
    .INIT(16'h88B8)) 
    \wb[0]_i_1 
       (.I0(\wleft_reg_n_0_[0] ),
        .I1(\update_wb.available1 ),
        .I2(\wb[0]_i_2_n_0 ),
        .I3(\wb[8]_i_4_n_0 ),
        .O(A[0]));
  (* SOFT_HLUTNM = "soft_lutpair17" *) 
  LUT4 #(
    .INIT(16'h01FE)) 
    \wb[0]_i_2 
       (.I0(\wa_reg[63]_0 [2]),
        .I1(\wa_reg[63]_0 [0]),
        .I2(\wa_reg[63]_0 [1]),
        .I3(\wa_reg[63]_0 [3]),
        .O(\wb[0]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'h88B8)) 
    \wb[1]_i_1 
       (.I0(\wleft_reg_n_0_[1] ),
        .I1(\update_wb.available1 ),
        .I2(\update_wb.available3 [4]),
        .I3(\wb[8]_i_4_n_0 ),
        .O(A[1]));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT5 #(
    .INIT(32'h0001FFFE)) 
    \wb[1]_i_2 
       (.I0(\wa_reg[63]_0 [1]),
        .I1(\wa_reg[63]_0 [0]),
        .I2(\wa_reg[63]_0 [2]),
        .I3(\wa_reg[63]_0 [3]),
        .I4(\wa_reg[63]_0 [4]),
        .O(\update_wb.available3 [4]));
  LUT4 #(
    .INIT(16'h88B8)) 
    \wb[2]_i_1 
       (.I0(\wleft_reg_n_0_[2] ),
        .I1(\update_wb.available1 ),
        .I2(\wb[2]_i_2_n_0 ),
        .I3(\wb[8]_i_4_n_0 ),
        .O(A[2]));
  LUT6 #(
    .INIT(64'h00000001FFFFFFFE)) 
    \wb[2]_i_2 
       (.I0(\wa_reg[63]_0 [4]),
        .I1(\wa_reg[63]_0 [3]),
        .I2(\wa_reg[63]_0 [2]),
        .I3(\wa_reg[63]_0 [0]),
        .I4(\wa_reg[63]_0 [1]),
        .I5(\wa_reg[63]_0 [5]),
        .O(\wb[2]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT5 #(
    .INIT(32'h88888BB8)) 
    \wb[3]_i_1 
       (.I0(\wleft_reg_n_0_[3] ),
        .I1(\update_wb.available1 ),
        .I2(\wb[4]_i_2_n_0 ),
        .I3(\wa_reg[63]_0 [6]),
        .I4(\wb[8]_i_4_n_0 ),
        .O(A[3]));
  LUT6 #(
    .INIT(64'h888888888B8B8BB8)) 
    \wb[4]_i_1 
       (.I0(\wleft_reg_n_0_[4] ),
        .I1(\update_wb.available1 ),
        .I2(\wa_reg[63]_0 [7]),
        .I3(\wb[4]_i_2_n_0 ),
        .I4(\wa_reg[63]_0 [6]),
        .I5(\wb[8]_i_4_n_0 ),
        .O(A[4]));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \wb[4]_i_2 
       (.I0(\wa_reg[63]_0 [5]),
        .I1(\wa_reg[63]_0 [4]),
        .I2(\wa_reg[63]_0 [3]),
        .I3(\wa_reg[63]_0 [2]),
        .I4(\wa_reg[63]_0 [0]),
        .I5(\wa_reg[63]_0 [1]),
        .O(\wb[4]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'h88B8)) 
    \wb[5]_i_1 
       (.I0(\wleft_reg_n_0_[5] ),
        .I1(\update_wb.available1 ),
        .I2(\update_wb.available3 [8]),
        .I3(\wb[8]_i_4_n_0 ),
        .O(A[5]));
  (* SOFT_HLUTNM = "soft_lutpair18" *) 
  LUT4 #(
    .INIT(16'h01FE)) 
    \wb[5]_i_2 
       (.I0(\wb[4]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [6]),
        .I2(\wa_reg[63]_0 [7]),
        .I3(\wa_reg[63]_0 [8]),
        .O(\update_wb.available3 [8]));
  LUT5 #(
    .INIT(32'hFF009090)) 
    \wb[6]_i_1 
       (.I0(\wa_reg[63]_0 [9]),
        .I1(\wb[6]_i_2_n_0 ),
        .I2(\wa_reg[63]_0 [11]),
        .I3(\wleft_reg_n_0_[6] ),
        .I4(\update_wb.available1 ),
        .O(A[6]));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT4 #(
    .INIT(16'h0001)) 
    \wb[6]_i_2 
       (.I0(\wb[4]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [6]),
        .I2(\wa_reg[63]_0 [7]),
        .I3(\wa_reg[63]_0 [8]),
        .O(\wb[6]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'h88B8)) 
    \wb[7]_i_1 
       (.I0(\wleft_reg_n_0_[7] ),
        .I1(\update_wb.available1 ),
        .I2(\update_wb.available3 [10]),
        .I3(\wb[8]_i_4_n_0 ),
        .O(A[7]));
  LUT6 #(
    .INIT(64'h00000001FFFFFFFE)) 
    \wb[7]_i_2 
       (.I0(\wb[4]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [6]),
        .I2(\wa_reg[63]_0 [7]),
        .I3(\wa_reg[63]_0 [8]),
        .I4(\wa_reg[63]_0 [9]),
        .I5(\wa_reg[63]_0 [10]),
        .O(\update_wb.available3 [10]));
  LUT2 #(
    .INIT(4'h2)) 
    \wb[8]_i_1 
       (.I0(write_curr_st__0[0]),
        .I1(write_curr_st__0[1]),
        .O(wb));
  LUT5 #(
    .INIT(32'hBBBB8BB8)) 
    \wb[8]_i_2 
       (.I0(\wleft_reg_n_0_[8] ),
        .I1(\update_wb.available1 ),
        .I2(\wa_reg[63]_0 [11]),
        .I3(\wb[8]_i_3_n_0 ),
        .I4(\wb[8]_i_4_n_0 ),
        .O(A[8]));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \wb[8]_i_3 
       (.I0(\wb[4]_i_2_n_0 ),
        .I1(\wa_reg[63]_0 [6]),
        .I2(\wa_reg[63]_0 [7]),
        .I3(\wa_reg[63]_0 [8]),
        .I4(\wa_reg[63]_0 [9]),
        .I5(\wa_reg[63]_0 [10]),
        .O(\wb[8]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h555D555D555D4555)) 
    \wb[8]_i_4 
       (.I0(\wa_reg[63]_0 [11]),
        .I1(\wb[6]_i_2_n_0 ),
        .I2(\wa_reg[63]_0 [9]),
        .I3(\wa_reg[63]_0 [10]),
        .I4(\wb[8]_i_5_n_0 ),
        .I5(\wb[8]_i_6_n_0 ),
        .O(\wb[8]_i_4_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair18" *) 
  LUT3 #(
    .INIT(8'h1E)) 
    \wb[8]_i_5 
       (.I0(\wa_reg[63]_0 [6]),
        .I1(\wb[4]_i_2_n_0 ),
        .I2(\wa_reg[63]_0 [7]),
        .O(\wb[8]_i_5_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT5 #(
    .INIT(32'hBBFFFFBE)) 
    \wb[8]_i_6 
       (.I0(\wb[8]_i_7_n_0 ),
        .I1(\wa_reg[63]_0 [8]),
        .I2(\wa_reg[63]_0 [7]),
        .I3(\wa_reg[63]_0 [6]),
        .I4(\wb[4]_i_2_n_0 ),
        .O(\wb[8]_i_6_n_0 ));
  LUT6 #(
    .INIT(64'h5557FFFFFFFFFFFE)) 
    \wb[8]_i_7 
       (.I0(\wa_reg[63]_0 [5]),
        .I1(\wa_reg[63]_0 [1]),
        .I2(\wa_reg[63]_0 [0]),
        .I3(\wa_reg[63]_0 [2]),
        .I4(\wa_reg[63]_0 [3]),
        .I5(\wa_reg[63]_0 [4]),
        .O(\wb[8]_i_7_n_0 ));
  FDRE \wb_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[0]),
        .Q(\wb_reg_n_0_[0] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[1]),
        .Q(\wb_reg_n_0_[1] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[2]),
        .Q(\wb_reg_n_0_[2] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[3]),
        .Q(\wb_reg_n_0_[3] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[4]),
        .Q(\wb_reg_n_0_[4] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[5]),
        .Q(\wb_reg_n_0_[5] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[6]),
        .Q(\wb_reg_n_0_[6] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[7]),
        .Q(\wb_reg_n_0_[7] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wb_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(wb),
        .D(A[8]),
        .Q(\wb_reg_n_0_[8] ),
        .R(fdma_wdone_i_1_n_0));
  LUT2 #(
    .INIT(4'h2)) 
    \wbeat[0]_i_1 
       (.I0(write_curr_st__0[1]),
        .I1(\wbeat_reg_n_0_[0] ),
        .O(wbeat[0]));
  (* SOFT_HLUTNM = "soft_lutpair69" *) 
  LUT3 #(
    .INIT(8'h48)) 
    \wbeat[1]_i_1 
       (.I0(\wbeat_reg_n_0_[0] ),
        .I1(write_curr_st__0[1]),
        .I2(\wbeat_reg_n_0_[1] ),
        .O(wbeat[1]));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT4 #(
    .INIT(16'h7080)) 
    \wbeat[2]_i_1 
       (.I0(\wbeat_reg_n_0_[0] ),
        .I1(\wbeat_reg_n_0_[1] ),
        .I2(write_curr_st__0[1]),
        .I3(\wbeat_reg_n_0_[2] ),
        .O(wbeat[2]));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT5 #(
    .INIT(32'h7F008000)) 
    \wbeat[3]_i_1 
       (.I0(\wbeat_reg_n_0_[1] ),
        .I1(\wbeat_reg_n_0_[0] ),
        .I2(\wbeat_reg_n_0_[2] ),
        .I3(write_curr_st__0[1]),
        .I4(\wbeat_reg_n_0_[3] ),
        .O(wbeat[3]));
  LUT6 #(
    .INIT(64'h7FFF000080000000)) 
    \wbeat[4]_i_1 
       (.I0(\wbeat_reg_n_0_[2] ),
        .I1(\wbeat_reg_n_0_[0] ),
        .I2(\wbeat_reg_n_0_[1] ),
        .I3(\wbeat_reg_n_0_[3] ),
        .I4(write_curr_st__0[1]),
        .I5(\wbeat_reg_n_0_[4] ),
        .O(wbeat[4]));
  (* SOFT_HLUTNM = "soft_lutpair68" *) 
  LUT3 #(
    .INIT(8'h48)) 
    \wbeat[5]_i_1 
       (.I0(\wbeat[5]_i_2_n_0 ),
        .I1(write_curr_st__0[1]),
        .I2(\wbeat_reg_n_0_[5] ),
        .O(wbeat[5]));
  LUT5 #(
    .INIT(32'h80000000)) 
    \wbeat[5]_i_2 
       (.I0(\wbeat_reg_n_0_[4] ),
        .I1(\wbeat_reg_n_0_[3] ),
        .I2(\wbeat_reg_n_0_[1] ),
        .I3(\wbeat_reg_n_0_[0] ),
        .I4(\wbeat_reg_n_0_[2] ),
        .O(\wbeat[5]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair69" *) 
  LUT3 #(
    .INIT(8'h84)) 
    \wbeat[6]_i_1 
       (.I0(\wbeat[8]_i_3_n_0 ),
        .I1(write_curr_st__0[1]),
        .I2(\wbeat_reg_n_0_[6] ),
        .O(wbeat[6]));
  (* SOFT_HLUTNM = "soft_lutpair10" *) 
  LUT4 #(
    .INIT(16'hB040)) 
    \wbeat[7]_i_1 
       (.I0(\wbeat[8]_i_3_n_0 ),
        .I1(\wbeat_reg_n_0_[6] ),
        .I2(write_curr_st__0[1]),
        .I3(\wbeat_reg_n_0_[7] ),
        .O(wbeat[7]));
  LUT5 #(
    .INIT(32'h00FF4000)) 
    \wbeat[8]_i_1 
       (.I0(M_AXI_WLAST),
        .I1(M_AXI_WREADY),
        .I2(M_AXI_WVALID),
        .I3(write_curr_st__0[1]),
        .I4(write_curr_st__0[0]),
        .O(wbeat_1));
  (* SOFT_HLUTNM = "soft_lutpair10" *) 
  LUT5 #(
    .INIT(32'hDF002000)) 
    \wbeat[8]_i_2 
       (.I0(\wbeat_reg_n_0_[6] ),
        .I1(\wbeat[8]_i_3_n_0 ),
        .I2(\wbeat_reg_n_0_[7] ),
        .I3(write_curr_st__0[1]),
        .I4(\wbeat_reg_n_0_[8] ),
        .O(wbeat[8]));
  LUT6 #(
    .INIT(64'h7FFFFFFFFFFFFFFF)) 
    \wbeat[8]_i_3 
       (.I0(\wbeat_reg_n_0_[2] ),
        .I1(\wbeat_reg_n_0_[0] ),
        .I2(\wbeat_reg_n_0_[1] ),
        .I3(\wbeat_reg_n_0_[3] ),
        .I4(\wbeat_reg_n_0_[4] ),
        .I5(\wbeat_reg_n_0_[5] ),
        .O(\wbeat[8]_i_3_n_0 ));
  FDRE \wbeat_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[0]),
        .Q(\wbeat_reg_n_0_[0] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[1]),
        .Q(\wbeat_reg_n_0_[1] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[2]),
        .Q(\wbeat_reg_n_0_[2] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[3]),
        .Q(\wbeat_reg_n_0_[3] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[4]),
        .Q(\wbeat_reg_n_0_[4] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[5]),
        .Q(\wbeat_reg_n_0_[5] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[6]),
        .Q(\wbeat_reg_n_0_[6] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[7]),
        .Q(\wbeat_reg_n_0_[7] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wbeat_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(wbeat_1),
        .D(wbeat[8]),
        .Q(\wbeat_reg_n_0_[8] ),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair36" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[0]_i_1 
       (.I0(in10[0]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[0]),
        .O(wleft[0]));
  (* SOFT_HLUTNM = "soft_lutpair31" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[10]_i_1 
       (.I0(in10[10]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[10]),
        .O(wleft[10]));
  (* SOFT_HLUTNM = "soft_lutpair30" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[11]_i_1 
       (.I0(in10[11]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[11]),
        .O(wleft[11]));
  (* SOFT_HLUTNM = "soft_lutpair30" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[12]_i_1 
       (.I0(in10[12]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[12]),
        .O(wleft[12]));
  (* SOFT_HLUTNM = "soft_lutpair29" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[13]_i_1 
       (.I0(in10[13]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[13]),
        .O(wleft[13]));
  (* SOFT_HLUTNM = "soft_lutpair29" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[14]_i_1 
       (.I0(in10[14]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[14]),
        .O(wleft[14]));
  (* SOFT_HLUTNM = "soft_lutpair28" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[15]_i_1 
       (.I0(in10[15]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[15]),
        .O(wleft[15]));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[15]_i_10 
       (.I0(\wleft_reg_n_0_[8] ),
        .I1(\wb_reg_n_0_[8] ),
        .O(\wleft[15]_i_10_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_3 
       (.I0(\wleft_reg_n_0_[15] ),
        .O(\wleft[15]_i_3_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_4 
       (.I0(\wleft_reg_n_0_[14] ),
        .O(\wleft[15]_i_4_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_5 
       (.I0(\wleft_reg_n_0_[13] ),
        .O(\wleft[15]_i_5_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_6 
       (.I0(\wleft_reg_n_0_[12] ),
        .O(\wleft[15]_i_6_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_7 
       (.I0(\wleft_reg_n_0_[11] ),
        .O(\wleft[15]_i_7_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_8 
       (.I0(\wleft_reg_n_0_[10] ),
        .O(\wleft[15]_i_8_n_0 ));
  LUT1 #(
    .INIT(2'h1)) 
    \wleft[15]_i_9 
       (.I0(\wleft_reg_n_0_[9] ),
        .O(\wleft[15]_i_9_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair35" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[1]_i_1 
       (.I0(in10[1]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[1]),
        .O(wleft[1]));
  (* SOFT_HLUTNM = "soft_lutpair35" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[2]_i_1 
       (.I0(in10[2]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[2]),
        .O(wleft[2]));
  (* SOFT_HLUTNM = "soft_lutpair34" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[3]_i_1 
       (.I0(in10[3]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[3]),
        .O(wleft[3]));
  (* SOFT_HLUTNM = "soft_lutpair34" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[4]_i_1 
       (.I0(in10[4]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[4]),
        .O(wleft[4]));
  (* SOFT_HLUTNM = "soft_lutpair33" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[5]_i_1 
       (.I0(in10[5]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[5]),
        .O(wleft[5]));
  (* SOFT_HLUTNM = "soft_lutpair33" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[6]_i_1 
       (.I0(in10[6]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[6]),
        .O(wleft[6]));
  (* SOFT_HLUTNM = "soft_lutpair32" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[7]_i_1 
       (.I0(in10[7]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[7]),
        .O(wleft[7]));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_10 
       (.I0(\wleft_reg_n_0_[0] ),
        .I1(\wb_reg_n_0_[0] ),
        .O(\wleft[7]_i_10_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_3 
       (.I0(\wleft_reg_n_0_[7] ),
        .I1(\wb_reg_n_0_[7] ),
        .O(\wleft[7]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_4 
       (.I0(\wleft_reg_n_0_[6] ),
        .I1(\wb_reg_n_0_[6] ),
        .O(\wleft[7]_i_4_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_5 
       (.I0(\wleft_reg_n_0_[5] ),
        .I1(\wb_reg_n_0_[5] ),
        .O(\wleft[7]_i_5_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_6 
       (.I0(\wleft_reg_n_0_[4] ),
        .I1(\wb_reg_n_0_[4] ),
        .O(\wleft[7]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_7 
       (.I0(\wleft_reg_n_0_[3] ),
        .I1(\wb_reg_n_0_[3] ),
        .O(\wleft[7]_i_7_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_8 
       (.I0(\wleft_reg_n_0_[2] ),
        .I1(\wb_reg_n_0_[2] ),
        .O(\wleft[7]_i_8_n_0 ));
  LUT2 #(
    .INIT(4'h9)) 
    \wleft[7]_i_9 
       (.I0(\wleft_reg_n_0_[1] ),
        .I1(\wb_reg_n_0_[1] ),
        .O(\wleft[7]_i_9_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair32" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[8]_i_1 
       (.I0(in10[8]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[8]),
        .O(wleft[8]));
  (* SOFT_HLUTNM = "soft_lutpair31" *) 
  LUT3 #(
    .INIT(8'hB8)) 
    \wleft[9]_i_1 
       (.I0(in10[9]),
        .I1(write_curr_st__0[1]),
        .I2(fdma_wsize[9]),
        .O(wleft[9]));
  FDRE \wleft_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[0]),
        .Q(\wleft_reg_n_0_[0] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[10] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[10]),
        .Q(\wleft_reg_n_0_[10] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[11] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[11]),
        .Q(\wleft_reg_n_0_[11] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[12] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[12]),
        .Q(\wleft_reg_n_0_[12] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[13] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[13]),
        .Q(\wleft_reg_n_0_[13] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[14] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[14]),
        .Q(\wleft_reg_n_0_[14] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[15] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[15]),
        .Q(\wleft_reg_n_0_[15] ),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wleft_reg[15]_i_2 
       (.CI(\wleft_reg[7]_i_2_n_0 ),
        .CI_TOP(1'b0),
        .CO({\NLW_wleft_reg[15]_i_2_CO_UNCONNECTED [7],\wleft_reg[15]_i_2_n_1 ,\wleft_reg[15]_i_2_n_2 ,\wleft_reg[15]_i_2_n_3 ,\wleft_reg[15]_i_2_n_4 ,\wleft_reg[15]_i_2_n_5 ,\wleft_reg[15]_i_2_n_6 ,\wleft_reg[15]_i_2_n_7 }),
        .DI({1'b0,\wleft_reg_n_0_[14] ,\wleft_reg_n_0_[13] ,\wleft_reg_n_0_[12] ,\wleft_reg_n_0_[11] ,\wleft_reg_n_0_[10] ,\wleft_reg_n_0_[9] ,\wleft_reg_n_0_[8] }),
        .O(in10[15:8]),
        .S({\wleft[15]_i_3_n_0 ,\wleft[15]_i_4_n_0 ,\wleft[15]_i_5_n_0 ,\wleft[15]_i_6_n_0 ,\wleft[15]_i_7_n_0 ,\wleft[15]_i_8_n_0 ,\wleft[15]_i_9_n_0 ,\wleft[15]_i_10_n_0 }));
  FDRE \wleft_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[1]),
        .Q(\wleft_reg_n_0_[1] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[2] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[2]),
        .Q(\wleft_reg_n_0_[2] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[3] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[3]),
        .Q(\wleft_reg_n_0_[3] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[4] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[4]),
        .Q(\wleft_reg_n_0_[4] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[5] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[5]),
        .Q(\wleft_reg_n_0_[5] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[6] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[6]),
        .Q(\wleft_reg_n_0_[6] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[7] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[7]),
        .Q(\wleft_reg_n_0_[7] ),
        .R(fdma_wdone_i_1_n_0));
  (* ADDER_THRESHOLD = "35" *) 
  CARRY8 \wleft_reg[7]_i_2 
       (.CI(1'b1),
        .CI_TOP(1'b0),
        .CO({\wleft_reg[7]_i_2_n_0 ,\wleft_reg[7]_i_2_n_1 ,\wleft_reg[7]_i_2_n_2 ,\wleft_reg[7]_i_2_n_3 ,\wleft_reg[7]_i_2_n_4 ,\wleft_reg[7]_i_2_n_5 ,\wleft_reg[7]_i_2_n_6 ,\wleft_reg[7]_i_2_n_7 }),
        .DI({\wleft_reg_n_0_[7] ,\wleft_reg_n_0_[6] ,\wleft_reg_n_0_[5] ,\wleft_reg_n_0_[4] ,\wleft_reg_n_0_[3] ,\wleft_reg_n_0_[2] ,\wleft_reg_n_0_[1] ,\wleft_reg_n_0_[0] }),
        .O(in10[7:0]),
        .S({\wleft[7]_i_3_n_0 ,\wleft[7]_i_4_n_0 ,\wleft[7]_i_5_n_0 ,\wleft[7]_i_6_n_0 ,\wleft[7]_i_7_n_0 ,\wleft[7]_i_8_n_0 ,\wleft[7]_i_9_n_0 ,\wleft[7]_i_10_n_0 }));
  FDRE \wleft_reg[8] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[8]),
        .Q(\wleft_reg_n_0_[8] ),
        .R(fdma_wdone_i_1_n_0));
  FDRE \wleft_reg[9] 
       (.C(M_AXI_ACLK),
        .CE(wa_0),
        .D(wleft[9]),
        .Q(\wleft_reg_n_0_[9] ),
        .R(fdma_wdone_i_1_n_0));
  (* SOFT_HLUTNM = "soft_lutpair27" *) 
  LUT3 #(
    .INIT(8'h4F)) 
    \write_curr_st[0]_i_1 
       (.I0(write_next_st1__23),
        .I1(write_curr_st[1]),
        .I2(write_curr_st[0]),
        .O(\write_curr_st[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair24" *) 
  LUT2 #(
    .INIT(4'h6)) 
    \write_curr_st[1]_i_1 
       (.I0(write_curr_st[0]),
        .I1(write_curr_st[1]),
        .O(\write_curr_st[1]_i_1_n_0 ));
  FDRE \write_curr_st_reg[0] 
       (.C(M_AXI_ACLK),
        .CE(write_next_st),
        .D(\write_curr_st[0]_i_1_n_0 ),
        .Q(write_curr_st[0]),
        .R(fdma_wdone_i_1_n_0));
  FDRE \write_curr_st_reg[1] 
       (.C(M_AXI_ACLK),
        .CE(write_next_st),
        .D(\write_curr_st[1]_i_1_n_0 ),
        .Q(write_curr_st[1]),
        .R(fdma_wdone_i_1_n_0));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
