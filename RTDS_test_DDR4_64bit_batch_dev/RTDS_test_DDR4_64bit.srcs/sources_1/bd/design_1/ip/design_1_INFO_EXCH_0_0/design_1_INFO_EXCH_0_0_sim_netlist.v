// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Sun Sep 20 15:47:07 2026
// Host        : DESKTOP-H0AB0MD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
// Design      : design_1_INFO_EXCH_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xcku040-ffva1156-2-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "design_1_INFO_EXCH_0_0,INFO_EXCH,{}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) (* IP_DEFINITION_SOURCE = "module_ref" *) 
(* X_CORE_INFO = "INFO_EXCH,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module design_1_INFO_EXCH_0_0
   (CPU_WR_DONE_EVENT,
    FPGA_TEMP_W,
    INT_STATE_W,
    CPU_REC_STATE_W,
    FPGA_CPU_START_ADDR,
    FPGA_CPU_LEN,
    CPU_WR_DONE_resp,
    DDR_STATUS_W,
    RX_READY_BLOCKS,
    RX_HEAD_SEQ,
    RX_DROPPED_FRAMES,
    r_INT_STATE,
    r_CLEAR_INTER,
    r_CPU_REC_STATE,
    r_RD_START,
    r_CPU_FPGA_START_ADDR,
    r_CPU_FPGA_LEN,
    S_AXI_ACLK,
    S_AXI_ARESETN,
    S_AXI_AWADDR,
    S_AXI_AWPROT,
    S_AXI_AWVALID,
    S_AXI_AWREADY,
    S_AXI_WDATA,
    S_AXI_WSTRB,
    S_AXI_WVALID,
    S_AXI_WREADY,
    S_AXI_BRESP,
    S_AXI_BVALID,
    S_AXI_BREADY,
    S_AXI_ARADDR,
    S_AXI_ARPROT,
    S_AXI_ARVALID,
    S_AXI_ARREADY,
    S_AXI_RDATA,
    S_AXI_RRESP,
    S_AXI_RVALID,
    S_AXI_RREADY);
  input CPU_WR_DONE_EVENT;
  input [31:0]FPGA_TEMP_W;
  input [0:0]INT_STATE_W;
  input [0:0]CPU_REC_STATE_W;
  input [31:0]FPGA_CPU_START_ADDR;
  input [31:0]FPGA_CPU_LEN;
  input [0:0]CPU_WR_DONE_resp;
  input [31:0]DDR_STATUS_W;
  input [31:0]RX_READY_BLOCKS;
  input [31:0]RX_HEAD_SEQ;
  input [31:0]RX_DROPPED_FRAMES;
  output r_INT_STATE;
  output r_CLEAR_INTER;
  output r_CPU_REC_STATE;
  output r_RD_START;
  output [31:0]r_CPU_FPGA_START_ADDR;
  output [31:0]r_CPU_FPGA_LEN;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 S_AXI_ACLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_ACLK, ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET S_AXI_ARESETN, FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, INSERT_VIP 0" *) input S_AXI_ACLK;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 S_AXI_ARESETN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input S_AXI_ARESETN;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *) input [31:0]S_AXI_AWADDR;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *) input [2:0]S_AXI_AWPROT;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *) input S_AXI_AWVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *) output S_AXI_AWREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *) input [31:0]S_AXI_WDATA;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *) input [3:0]S_AXI_WSTRB;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *) input S_AXI_WVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *) output S_AXI_WREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *) output [1:0]S_AXI_BRESP;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *) output S_AXI_BVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *) input S_AXI_BREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *) input [31:0]S_AXI_ARADDR;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *) input [2:0]S_AXI_ARPROT;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *) input S_AXI_ARVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *) output S_AXI_ARREADY;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *) output [31:0]S_AXI_RDATA;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *) output [1:0]S_AXI_RRESP;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *) output S_AXI_RVALID;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 250000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.000, CLK_DOMAIN design_1_sys_clk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *) input S_AXI_RREADY;

  wire \<const0> ;
  wire CPU_WR_DONE_EVENT;
  wire [31:0]DDR_STATUS_W;
  wire [31:0]FPGA_CPU_LEN;
  wire [31:0]FPGA_CPU_START_ADDR;
  wire [31:0]FPGA_TEMP_W;
  wire [0:0]INT_STATE_W;
  wire [31:0]RX_DROPPED_FRAMES;
  wire [31:0]RX_HEAD_SEQ;
  wire [31:0]RX_READY_BLOCKS;
  wire S_AXI_ACLK;
  wire [31:0]S_AXI_ARADDR;
  wire S_AXI_ARESETN;
  wire S_AXI_ARREADY;
  wire S_AXI_ARVALID;
  wire [31:0]S_AXI_AWADDR;
  wire S_AXI_AWREADY;
  wire S_AXI_AWVALID;
  wire S_AXI_BREADY;
  wire S_AXI_BVALID;
  wire [31:0]S_AXI_RDATA;
  wire S_AXI_RREADY;
  wire S_AXI_RVALID;
  wire [31:0]S_AXI_WDATA;
  wire S_AXI_WREADY;
  wire [3:0]S_AXI_WSTRB;
  wire S_AXI_WVALID;
  wire r_CLEAR_INTER;
  wire [31:0]r_CPU_FPGA_LEN;
  wire [31:0]r_CPU_FPGA_START_ADDR;
  wire r_CPU_REC_STATE;
  wire r_RD_START;

  assign S_AXI_BRESP[1] = \<const0> ;
  assign S_AXI_BRESP[0] = \<const0> ;
  assign S_AXI_RRESP[1] = \<const0> ;
  assign S_AXI_RRESP[0] = \<const0> ;
  assign r_INT_STATE = r_CLEAR_INTER;
  GND GND
       (.G(\<const0> ));
  design_1_INFO_EXCH_0_0_INFO_EXCH inst
       (.CPU_WR_DONE_EVENT(CPU_WR_DONE_EVENT),
        .DDR_STATUS_W(DDR_STATUS_W),
        .FPGA_CPU_LEN(FPGA_CPU_LEN),
        .FPGA_CPU_START_ADDR(FPGA_CPU_START_ADDR),
        .FPGA_TEMP_W(FPGA_TEMP_W),
        .INT_STATE_W(INT_STATE_W),
        .RX_DROPPED_FRAMES(RX_DROPPED_FRAMES),
        .RX_HEAD_SEQ(RX_HEAD_SEQ),
        .RX_READY_BLOCKS(RX_READY_BLOCKS),
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARADDR(S_AXI_ARADDR[15:0]),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_AWADDR(S_AXI_AWADDR[15:0]),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RREADY(S_AXI_RREADY),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .r_CLEAR_INTER(r_CLEAR_INTER),
        .r_CPU_FPGA_LEN(r_CPU_FPGA_LEN),
        .r_CPU_FPGA_START_ADDR(r_CPU_FPGA_START_ADDR),
        .r_CPU_REC_STATE(r_CPU_REC_STATE),
        .r_RD_START(r_RD_START));
endmodule

(* ORIG_REF_NAME = "INFO_EXCH" *) 
module design_1_INFO_EXCH_0_0_INFO_EXCH
   (S_AXI_ARREADY,
    r_CLEAR_INTER,
    S_AXI_AWREADY,
    S_AXI_WREADY,
    r_CPU_REC_STATE,
    r_CPU_FPGA_START_ADDR,
    r_CPU_FPGA_LEN,
    S_AXI_RDATA,
    S_AXI_RVALID,
    r_RD_START,
    S_AXI_BVALID,
    S_AXI_ACLK,
    S_AXI_AWADDR,
    S_AXI_WDATA,
    S_AXI_ARADDR,
    S_AXI_ARVALID,
    S_AXI_WSTRB,
    S_AXI_WVALID,
    S_AXI_AWVALID,
    DDR_STATUS_W,
    FPGA_TEMP_W,
    FPGA_CPU_LEN,
    INT_STATE_W,
    FPGA_CPU_START_ADDR,
    RX_READY_BLOCKS,
    RX_DROPPED_FRAMES,
    RX_HEAD_SEQ,
    S_AXI_ARESETN,
    CPU_WR_DONE_EVENT,
    S_AXI_BREADY,
    S_AXI_RREADY);
  output S_AXI_ARREADY;
  output r_CLEAR_INTER;
  output S_AXI_AWREADY;
  output S_AXI_WREADY;
  output r_CPU_REC_STATE;
  output [31:0]r_CPU_FPGA_START_ADDR;
  output [31:0]r_CPU_FPGA_LEN;
  output [31:0]S_AXI_RDATA;
  output S_AXI_RVALID;
  output r_RD_START;
  output S_AXI_BVALID;
  input S_AXI_ACLK;
  input [15:0]S_AXI_AWADDR;
  input [31:0]S_AXI_WDATA;
  input [15:0]S_AXI_ARADDR;
  input S_AXI_ARVALID;
  input [3:0]S_AXI_WSTRB;
  input S_AXI_WVALID;
  input S_AXI_AWVALID;
  input [31:0]DDR_STATUS_W;
  input [31:0]FPGA_TEMP_W;
  input [31:0]FPGA_CPU_LEN;
  input [0:0]INT_STATE_W;
  input [31:0]FPGA_CPU_START_ADDR;
  input [31:0]RX_READY_BLOCKS;
  input [31:0]RX_DROPPED_FRAMES;
  input [31:0]RX_HEAD_SEQ;
  input S_AXI_ARESETN;
  input CPU_WR_DONE_EVENT;
  input S_AXI_BREADY;
  input S_AXI_RREADY;

  wire \CPU_FPGA_LEN[15]_i_1_n_0 ;
  wire \CPU_FPGA_LEN[23]_i_1_n_0 ;
  wire \CPU_FPGA_LEN[31]_i_1_n_0 ;
  wire \CPU_FPGA_LEN[31]_i_2_n_0 ;
  wire \CPU_FPGA_LEN[31]_i_3_n_0 ;
  wire \CPU_FPGA_LEN[7]_i_1_n_0 ;
  wire \CPU_FPGA_START_ADDR[15]_i_1_n_0 ;
  wire \CPU_FPGA_START_ADDR[23]_i_1_n_0 ;
  wire \CPU_FPGA_START_ADDR[31]_i_1_n_0 ;
  wire \CPU_FPGA_START_ADDR[31]_i_2_n_0 ;
  wire \CPU_FPGA_START_ADDR[31]_i_3_n_0 ;
  wire \CPU_FPGA_START_ADDR[31]_i_4_n_0 ;
  wire \CPU_FPGA_START_ADDR[31]_i_5_n_0 ;
  wire \CPU_FPGA_START_ADDR[31]_i_6_n_0 ;
  wire \CPU_FPGA_START_ADDR[7]_i_1_n_0 ;
  wire CPU_REC_STATE2;
  wire \CPU_REC_STATE[0]_i_2_n_0 ;
  wire \CPU_REC_STATE[0]_i_4_n_0 ;
  wire \CPU_REC_STATE[0]_i_5_n_0 ;
  wire \CPU_REC_STATE[0]_i_6_n_0 ;
  wire \CPU_WR_DONE[0]_i_1_n_0 ;
  wire \CPU_WR_DONE[0]_i_3_n_0 ;
  wire \CPU_WR_DONE[0]_i_4_n_0 ;
  wire CPU_WR_DONE_EVENT;
  wire CPU_WR_DONE_d;
  wire \CPU_WR_DONE_reg_n_0_[0] ;
  wire [31:0]DDR_STATUS_W;
  wire [31:0]FPGA_CPU_LEN;
  wire [31:0]FPGA_CPU_START_ADDR;
  wire [31:0]FPGA_TEMP_W;
  wire INT_STATE_R0;
  wire \INT_STATE_R[0]_i_1_n_0 ;
  wire \INT_STATE_R[0]_i_3_n_0 ;
  wire \INT_STATE_R[0]_i_4_n_0 ;
  wire \INT_STATE_R[0]_i_5_n_0 ;
  wire [0:0]INT_STATE_W;
  wire [31:0]RX_DROPPED_FRAMES;
  wire [31:0]RX_HEAD_SEQ;
  wire [31:0]RX_READY_BLOCKS;
  wire S_AXI_ACLK;
  wire [15:0]S_AXI_ARADDR;
  wire S_AXI_ARESETN;
  wire S_AXI_ARREADY;
  wire S_AXI_ARVALID;
  wire [15:0]S_AXI_AWADDR;
  wire S_AXI_AWREADY;
  wire S_AXI_AWVALID;
  wire S_AXI_BREADY;
  wire S_AXI_BVALID;
  wire [31:0]S_AXI_RDATA;
  wire S_AXI_RREADY;
  wire S_AXI_RVALID;
  wire [31:0]S_AXI_WDATA;
  wire S_AXI_WREADY;
  wire [3:0]S_AXI_WSTRB;
  wire S_AXI_WVALID;
  wire aw_en_i_1_n_0;
  wire aw_en_reg_n_0;
  wire [15:0]axi_araddr;
  wire axi_arready0;
  wire [15:0]axi_awaddr;
  wire axi_awready0;
  wire axi_bvalid_i_1_n_0;
  wire \axi_rdata[0]_i_1_n_0 ;
  wire \axi_rdata[0]_i_2_n_0 ;
  wire \axi_rdata[0]_i_3_n_0 ;
  wire \axi_rdata[0]_i_4_n_0 ;
  wire \axi_rdata[0]_i_5_n_0 ;
  wire \axi_rdata[10]_i_1_n_0 ;
  wire \axi_rdata[10]_i_2_n_0 ;
  wire \axi_rdata[10]_i_3_n_0 ;
  wire \axi_rdata[10]_i_4_n_0 ;
  wire \axi_rdata[11]_i_1_n_0 ;
  wire \axi_rdata[11]_i_2_n_0 ;
  wire \axi_rdata[11]_i_3_n_0 ;
  wire \axi_rdata[11]_i_4_n_0 ;
  wire \axi_rdata[12]_i_1_n_0 ;
  wire \axi_rdata[12]_i_2_n_0 ;
  wire \axi_rdata[12]_i_3_n_0 ;
  wire \axi_rdata[12]_i_4_n_0 ;
  wire \axi_rdata[13]_i_1_n_0 ;
  wire \axi_rdata[13]_i_2_n_0 ;
  wire \axi_rdata[13]_i_3_n_0 ;
  wire \axi_rdata[13]_i_4_n_0 ;
  wire \axi_rdata[14]_i_1_n_0 ;
  wire \axi_rdata[14]_i_2_n_0 ;
  wire \axi_rdata[14]_i_3_n_0 ;
  wire \axi_rdata[14]_i_4_n_0 ;
  wire \axi_rdata[15]_i_1_n_0 ;
  wire \axi_rdata[15]_i_2_n_0 ;
  wire \axi_rdata[15]_i_3_n_0 ;
  wire \axi_rdata[15]_i_4_n_0 ;
  wire \axi_rdata[16]_i_1_n_0 ;
  wire \axi_rdata[16]_i_2_n_0 ;
  wire \axi_rdata[16]_i_3_n_0 ;
  wire \axi_rdata[16]_i_4_n_0 ;
  wire \axi_rdata[17]_i_1_n_0 ;
  wire \axi_rdata[17]_i_2_n_0 ;
  wire \axi_rdata[17]_i_3_n_0 ;
  wire \axi_rdata[17]_i_4_n_0 ;
  wire \axi_rdata[18]_i_1_n_0 ;
  wire \axi_rdata[18]_i_2_n_0 ;
  wire \axi_rdata[18]_i_3_n_0 ;
  wire \axi_rdata[18]_i_4_n_0 ;
  wire \axi_rdata[19]_i_1_n_0 ;
  wire \axi_rdata[19]_i_2_n_0 ;
  wire \axi_rdata[19]_i_3_n_0 ;
  wire \axi_rdata[19]_i_4_n_0 ;
  wire \axi_rdata[1]_i_1_n_0 ;
  wire \axi_rdata[1]_i_2_n_0 ;
  wire \axi_rdata[1]_i_3_n_0 ;
  wire \axi_rdata[1]_i_4_n_0 ;
  wire \axi_rdata[20]_i_1_n_0 ;
  wire \axi_rdata[20]_i_2_n_0 ;
  wire \axi_rdata[20]_i_3_n_0 ;
  wire \axi_rdata[20]_i_4_n_0 ;
  wire \axi_rdata[21]_i_1_n_0 ;
  wire \axi_rdata[21]_i_2_n_0 ;
  wire \axi_rdata[21]_i_3_n_0 ;
  wire \axi_rdata[21]_i_4_n_0 ;
  wire \axi_rdata[22]_i_1_n_0 ;
  wire \axi_rdata[22]_i_2_n_0 ;
  wire \axi_rdata[22]_i_3_n_0 ;
  wire \axi_rdata[22]_i_4_n_0 ;
  wire \axi_rdata[23]_i_1_n_0 ;
  wire \axi_rdata[23]_i_2_n_0 ;
  wire \axi_rdata[23]_i_3_n_0 ;
  wire \axi_rdata[23]_i_4_n_0 ;
  wire \axi_rdata[24]_i_1_n_0 ;
  wire \axi_rdata[24]_i_2_n_0 ;
  wire \axi_rdata[24]_i_3_n_0 ;
  wire \axi_rdata[24]_i_4_n_0 ;
  wire \axi_rdata[25]_i_1_n_0 ;
  wire \axi_rdata[25]_i_2_n_0 ;
  wire \axi_rdata[25]_i_3_n_0 ;
  wire \axi_rdata[25]_i_4_n_0 ;
  wire \axi_rdata[26]_i_1_n_0 ;
  wire \axi_rdata[26]_i_2_n_0 ;
  wire \axi_rdata[26]_i_3_n_0 ;
  wire \axi_rdata[26]_i_4_n_0 ;
  wire \axi_rdata[27]_i_1_n_0 ;
  wire \axi_rdata[27]_i_2_n_0 ;
  wire \axi_rdata[27]_i_3_n_0 ;
  wire \axi_rdata[27]_i_4_n_0 ;
  wire \axi_rdata[28]_i_1_n_0 ;
  wire \axi_rdata[28]_i_2_n_0 ;
  wire \axi_rdata[28]_i_3_n_0 ;
  wire \axi_rdata[28]_i_4_n_0 ;
  wire \axi_rdata[29]_i_1_n_0 ;
  wire \axi_rdata[29]_i_2_n_0 ;
  wire \axi_rdata[29]_i_3_n_0 ;
  wire \axi_rdata[29]_i_4_n_0 ;
  wire \axi_rdata[2]_i_1_n_0 ;
  wire \axi_rdata[2]_i_2_n_0 ;
  wire \axi_rdata[2]_i_3_n_0 ;
  wire \axi_rdata[2]_i_4_n_0 ;
  wire \axi_rdata[30]_i_1_n_0 ;
  wire \axi_rdata[30]_i_2_n_0 ;
  wire \axi_rdata[30]_i_3_n_0 ;
  wire \axi_rdata[30]_i_4_n_0 ;
  wire \axi_rdata[31]_i_2_n_0 ;
  wire \axi_rdata[31]_i_3_n_0 ;
  wire \axi_rdata[31]_i_4_n_0 ;
  wire \axi_rdata[31]_i_5_n_0 ;
  wire \axi_rdata[31]_i_6_n_0 ;
  wire \axi_rdata[31]_i_7_n_0 ;
  wire \axi_rdata[31]_i_8_n_0 ;
  wire \axi_rdata[3]_i_1_n_0 ;
  wire \axi_rdata[3]_i_2_n_0 ;
  wire \axi_rdata[3]_i_3_n_0 ;
  wire \axi_rdata[3]_i_4_n_0 ;
  wire \axi_rdata[4]_i_1_n_0 ;
  wire \axi_rdata[4]_i_2_n_0 ;
  wire \axi_rdata[4]_i_3_n_0 ;
  wire \axi_rdata[4]_i_4_n_0 ;
  wire \axi_rdata[5]_i_1_n_0 ;
  wire \axi_rdata[5]_i_2_n_0 ;
  wire \axi_rdata[5]_i_3_n_0 ;
  wire \axi_rdata[5]_i_4_n_0 ;
  wire \axi_rdata[6]_i_1_n_0 ;
  wire \axi_rdata[6]_i_2_n_0 ;
  wire \axi_rdata[6]_i_3_n_0 ;
  wire \axi_rdata[6]_i_4_n_0 ;
  wire \axi_rdata[7]_i_1_n_0 ;
  wire \axi_rdata[7]_i_2_n_0 ;
  wire \axi_rdata[7]_i_3_n_0 ;
  wire \axi_rdata[7]_i_4_n_0 ;
  wire \axi_rdata[8]_i_1_n_0 ;
  wire \axi_rdata[8]_i_2_n_0 ;
  wire \axi_rdata[8]_i_3_n_0 ;
  wire \axi_rdata[8]_i_4_n_0 ;
  wire \axi_rdata[9]_i_1_n_0 ;
  wire \axi_rdata[9]_i_2_n_0 ;
  wire \axi_rdata[9]_i_3_n_0 ;
  wire \axi_rdata[9]_i_4_n_0 ;
  wire axi_rvalid_i_1_n_0;
  wire axi_wready0;
  wire p_7_in;
  wire p_8_in;
  wire r_CLEAR_INTER;
  wire [31:0]r_CPU_FPGA_LEN;
  wire [31:0]r_CPU_FPGA_START_ADDR;
  wire r_CPU_REC_STATE;
  wire r_RD_START;
  wire slv_reg_rden;

  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_LEN[15]_i_1 
       (.I0(\CPU_FPGA_LEN[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[1]),
        .O(\CPU_FPGA_LEN[15]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_LEN[23]_i_1 
       (.I0(\CPU_FPGA_LEN[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[2]),
        .O(\CPU_FPGA_LEN[23]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_LEN[31]_i_1 
       (.I0(\CPU_FPGA_LEN[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[3]),
        .O(\CPU_FPGA_LEN[31]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h0008000000000000)) 
    \CPU_FPGA_LEN[31]_i_2 
       (.I0(\CPU_FPGA_LEN[31]_i_3_n_0 ),
        .I1(\CPU_REC_STATE[0]_i_4_n_0 ),
        .I2(\CPU_FPGA_START_ADDR[31]_i_4_n_0 ),
        .I3(\CPU_FPGA_START_ADDR[31]_i_5_n_0 ),
        .I4(\CPU_FPGA_START_ADDR[31]_i_6_n_0 ),
        .I5(p_7_in),
        .O(\CPU_FPGA_LEN[31]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT3 #(
    .INIT(8'h04)) 
    \CPU_FPGA_LEN[31]_i_3 
       (.I0(axi_awaddr[4]),
        .I1(axi_awaddr[3]),
        .I2(axi_awaddr[2]),
        .O(\CPU_FPGA_LEN[31]_i_3_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_LEN[7]_i_1 
       (.I0(\CPU_FPGA_LEN[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[0]),
        .O(\CPU_FPGA_LEN[7]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[0]),
        .Q(r_CPU_FPGA_LEN[0]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[10] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[10]),
        .Q(r_CPU_FPGA_LEN[10]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[11] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[11]),
        .Q(r_CPU_FPGA_LEN[11]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[12] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[12]),
        .Q(r_CPU_FPGA_LEN[12]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[13] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[13]),
        .Q(r_CPU_FPGA_LEN[13]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[14] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[14]),
        .Q(r_CPU_FPGA_LEN[14]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDSE \CPU_FPGA_LEN_reg[15] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[15]),
        .Q(r_CPU_FPGA_LEN[15]),
        .S(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[16] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[16]),
        .Q(r_CPU_FPGA_LEN[16]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[17] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[17]),
        .Q(r_CPU_FPGA_LEN[17]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[18] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[18]),
        .Q(r_CPU_FPGA_LEN[18]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[19] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[19]),
        .Q(r_CPU_FPGA_LEN[19]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[1] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[1]),
        .Q(r_CPU_FPGA_LEN[1]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[20] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[20]),
        .Q(r_CPU_FPGA_LEN[20]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[21] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[21]),
        .Q(r_CPU_FPGA_LEN[21]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[22] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[22]),
        .Q(r_CPU_FPGA_LEN[22]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[23] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[23]),
        .Q(r_CPU_FPGA_LEN[23]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[24] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[24]),
        .Q(r_CPU_FPGA_LEN[24]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[25] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[25]),
        .Q(r_CPU_FPGA_LEN[25]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[26] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[26]),
        .Q(r_CPU_FPGA_LEN[26]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[27] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[27]),
        .Q(r_CPU_FPGA_LEN[27]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[28] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[28]),
        .Q(r_CPU_FPGA_LEN[28]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[29] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[29]),
        .Q(r_CPU_FPGA_LEN[29]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[2] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[2]),
        .Q(r_CPU_FPGA_LEN[2]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[30] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[30]),
        .Q(r_CPU_FPGA_LEN[30]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[31] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[31]),
        .Q(r_CPU_FPGA_LEN[31]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[3] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[3]),
        .Q(r_CPU_FPGA_LEN[3]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[4] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[4]),
        .Q(r_CPU_FPGA_LEN[4]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[5] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[5]),
        .Q(r_CPU_FPGA_LEN[5]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[6] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[6]),
        .Q(r_CPU_FPGA_LEN[6]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[7] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[7]),
        .Q(r_CPU_FPGA_LEN[7]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[8] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[8]),
        .Q(r_CPU_FPGA_LEN[8]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_LEN_reg[9] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_LEN[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[9]),
        .Q(r_CPU_FPGA_LEN[9]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_START_ADDR[15]_i_1 
       (.I0(\CPU_FPGA_START_ADDR[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[1]),
        .O(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_START_ADDR[23]_i_1 
       (.I0(\CPU_FPGA_START_ADDR[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[2]),
        .O(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_START_ADDR[31]_i_1 
       (.I0(\CPU_FPGA_START_ADDR[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[3]),
        .O(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h0008000000000000)) 
    \CPU_FPGA_START_ADDR[31]_i_2 
       (.I0(\CPU_FPGA_START_ADDR[31]_i_3_n_0 ),
        .I1(\CPU_REC_STATE[0]_i_4_n_0 ),
        .I2(\CPU_FPGA_START_ADDR[31]_i_4_n_0 ),
        .I3(\CPU_FPGA_START_ADDR[31]_i_5_n_0 ),
        .I4(\CPU_FPGA_START_ADDR[31]_i_6_n_0 ),
        .I5(p_7_in),
        .O(\CPU_FPGA_START_ADDR[31]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT3 #(
    .INIT(8'h04)) 
    \CPU_FPGA_START_ADDR[31]_i_3 
       (.I0(axi_awaddr[4]),
        .I1(axi_awaddr[2]),
        .I2(axi_awaddr[3]),
        .O(\CPU_FPGA_START_ADDR[31]_i_3_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \CPU_FPGA_START_ADDR[31]_i_4 
       (.I0(axi_awaddr[10]),
        .I1(axi_awaddr[11]),
        .I2(axi_awaddr[12]),
        .I3(axi_awaddr[13]),
        .O(\CPU_FPGA_START_ADDR[31]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \CPU_FPGA_START_ADDR[31]_i_5 
       (.I0(axi_awaddr[7]),
        .I1(axi_awaddr[6]),
        .I2(axi_awaddr[15]),
        .I3(axi_awaddr[14]),
        .I4(axi_awaddr[8]),
        .I5(axi_awaddr[9]),
        .O(\CPU_FPGA_START_ADDR[31]_i_5_n_0 ));
  LUT3 #(
    .INIT(8'hF4)) 
    \CPU_FPGA_START_ADDR[31]_i_6 
       (.I0(axi_awaddr[0]),
        .I1(axi_awaddr[5]),
        .I2(axi_awaddr[1]),
        .O(\CPU_FPGA_START_ADDR[31]_i_6_n_0 ));
  LUT2 #(
    .INIT(4'h8)) 
    \CPU_FPGA_START_ADDR[7]_i_1 
       (.I0(\CPU_FPGA_START_ADDR[31]_i_2_n_0 ),
        .I1(S_AXI_WSTRB[0]),
        .O(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[0]),
        .Q(r_CPU_FPGA_START_ADDR[0]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[10] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[10]),
        .Q(r_CPU_FPGA_START_ADDR[10]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[11] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[11]),
        .Q(r_CPU_FPGA_START_ADDR[11]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[12] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[12]),
        .Q(r_CPU_FPGA_START_ADDR[12]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[13] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[13]),
        .Q(r_CPU_FPGA_START_ADDR[13]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[14] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[14]),
        .Q(r_CPU_FPGA_START_ADDR[14]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDSE \CPU_FPGA_START_ADDR_reg[15] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[15]),
        .Q(r_CPU_FPGA_START_ADDR[15]),
        .S(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[16] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[16]),
        .Q(r_CPU_FPGA_START_ADDR[16]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[17] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[17]),
        .Q(r_CPU_FPGA_START_ADDR[17]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[18] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[18]),
        .Q(r_CPU_FPGA_START_ADDR[18]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[19] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[19]),
        .Q(r_CPU_FPGA_START_ADDR[19]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[1] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[1]),
        .Q(r_CPU_FPGA_START_ADDR[1]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[20] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[20]),
        .Q(r_CPU_FPGA_START_ADDR[20]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[21] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[21]),
        .Q(r_CPU_FPGA_START_ADDR[21]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[22] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[22]),
        .Q(r_CPU_FPGA_START_ADDR[22]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[23] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[23]_i_1_n_0 ),
        .D(S_AXI_WDATA[23]),
        .Q(r_CPU_FPGA_START_ADDR[23]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[24] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[24]),
        .Q(r_CPU_FPGA_START_ADDR[24]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[25] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[25]),
        .Q(r_CPU_FPGA_START_ADDR[25]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[26] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[26]),
        .Q(r_CPU_FPGA_START_ADDR[26]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[27] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[27]),
        .Q(r_CPU_FPGA_START_ADDR[27]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[28] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[28]),
        .Q(r_CPU_FPGA_START_ADDR[28]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[29] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[29]),
        .Q(r_CPU_FPGA_START_ADDR[29]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[2] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[2]),
        .Q(r_CPU_FPGA_START_ADDR[2]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[30] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[30]),
        .Q(r_CPU_FPGA_START_ADDR[30]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[31] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[31]_i_1_n_0 ),
        .D(S_AXI_WDATA[31]),
        .Q(r_CPU_FPGA_START_ADDR[31]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[3] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[3]),
        .Q(r_CPU_FPGA_START_ADDR[3]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[4] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[4]),
        .Q(r_CPU_FPGA_START_ADDR[4]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[5] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[5]),
        .Q(r_CPU_FPGA_START_ADDR[5]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[6] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[6]),
        .Q(r_CPU_FPGA_START_ADDR[6]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[7] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[7]_i_1_n_0 ),
        .D(S_AXI_WDATA[7]),
        .Q(r_CPU_FPGA_START_ADDR[7]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[8] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[8]),
        .Q(r_CPU_FPGA_START_ADDR[8]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_FPGA_START_ADDR_reg[9] 
       (.C(S_AXI_ACLK),
        .CE(\CPU_FPGA_START_ADDR[15]_i_1_n_0 ),
        .D(S_AXI_WDATA[9]),
        .Q(r_CPU_FPGA_START_ADDR[9]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000800000)) 
    \CPU_REC_STATE[0]_i_1 
       (.I0(\CPU_REC_STATE[0]_i_2_n_0 ),
        .I1(p_8_in),
        .I2(axi_awaddr[2]),
        .I3(axi_awaddr[3]),
        .I4(\CPU_REC_STATE[0]_i_4_n_0 ),
        .I5(\CPU_REC_STATE[0]_i_5_n_0 ),
        .O(CPU_REC_STATE2));
  LUT6 #(
    .INIT(64'h0000000000002000)) 
    \CPU_REC_STATE[0]_i_2 
       (.I0(axi_awaddr[4]),
        .I1(axi_awaddr[5]),
        .I2(S_AXI_WDATA[0]),
        .I3(S_AXI_WSTRB[0]),
        .I4(axi_awaddr[6]),
        .I5(axi_awaddr[7]),
        .O(\CPU_REC_STATE[0]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT4 #(
    .INIT(16'h8000)) 
    \CPU_REC_STATE[0]_i_3 
       (.I0(S_AXI_WREADY),
        .I1(S_AXI_AWREADY),
        .I2(S_AXI_AWVALID),
        .I3(S_AXI_WVALID),
        .O(p_8_in));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT2 #(
    .INIT(4'h1)) 
    \CPU_REC_STATE[0]_i_4 
       (.I0(axi_awaddr[0]),
        .I1(axi_awaddr[1]),
        .O(\CPU_REC_STATE[0]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'hFFFFFFFE)) 
    \CPU_REC_STATE[0]_i_5 
       (.I0(axi_awaddr[11]),
        .I1(axi_awaddr[10]),
        .I2(axi_awaddr[9]),
        .I3(axi_awaddr[8]),
        .I4(\CPU_REC_STATE[0]_i_6_n_0 ),
        .O(\CPU_REC_STATE[0]_i_5_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \CPU_REC_STATE[0]_i_6 
       (.I0(axi_awaddr[12]),
        .I1(axi_awaddr[13]),
        .I2(axi_awaddr[15]),
        .I3(axi_awaddr[14]),
        .O(\CPU_REC_STATE[0]_i_6_n_0 ));
  FDRE \CPU_REC_STATE_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(CPU_REC_STATE2),
        .Q(r_CPU_REC_STATE),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h00000000BAAA0000)) 
    \CPU_WR_DONE[0]_i_1 
       (.I0(\CPU_WR_DONE_reg_n_0_[0] ),
        .I1(\CPU_REC_STATE[0]_i_5_n_0 ),
        .I2(p_7_in),
        .I3(\CPU_WR_DONE[0]_i_3_n_0 ),
        .I4(S_AXI_ARESETN),
        .I5(CPU_WR_DONE_EVENT),
        .O(\CPU_WR_DONE[0]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'h00008000)) 
    \CPU_WR_DONE[0]_i_2 
       (.I0(S_AXI_WVALID),
        .I1(S_AXI_AWVALID),
        .I2(S_AXI_AWREADY),
        .I3(S_AXI_WREADY),
        .I4(\CPU_WR_DONE_reg_n_0_[0] ),
        .O(p_7_in));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT5 #(
    .INIT(32'h00000002)) 
    \CPU_WR_DONE[0]_i_3 
       (.I0(\CPU_WR_DONE[0]_i_4_n_0 ),
        .I1(axi_awaddr[2]),
        .I2(axi_awaddr[3]),
        .I3(axi_awaddr[0]),
        .I4(axi_awaddr[1]),
        .O(\CPU_WR_DONE[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h0000000000002000)) 
    \CPU_WR_DONE[0]_i_4 
       (.I0(axi_awaddr[5]),
        .I1(axi_awaddr[4]),
        .I2(S_AXI_WDATA[0]),
        .I3(S_AXI_WSTRB[0]),
        .I4(axi_awaddr[6]),
        .I5(axi_awaddr[7]),
        .O(\CPU_WR_DONE[0]_i_4_n_0 ));
  FDRE CPU_WR_DONE_d_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(\CPU_WR_DONE_reg_n_0_[0] ),
        .Q(CPU_WR_DONE_d),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \CPU_WR_DONE_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(\CPU_WR_DONE[0]_i_1_n_0 ),
        .Q(\CPU_WR_DONE_reg_n_0_[0] ),
        .R(1'b0));
  LUT1 #(
    .INIT(2'h1)) 
    \INT_STATE_R[0]_i_1 
       (.I0(S_AXI_ARESETN),
        .O(\INT_STATE_R[0]_i_1_n_0 ));
  LUT3 #(
    .INIT(8'h80)) 
    \INT_STATE_R[0]_i_2 
       (.I0(\INT_STATE_R[0]_i_3_n_0 ),
        .I1(\INT_STATE_R[0]_i_4_n_0 ),
        .I2(\INT_STATE_R[0]_i_5_n_0 ),
        .O(INT_STATE_R0));
  LUT6 #(
    .INIT(64'h0000000000000001)) 
    \INT_STATE_R[0]_i_3 
       (.I0(S_AXI_ARADDR[8]),
        .I1(S_AXI_ARADDR[9]),
        .I2(S_AXI_ARADDR[6]),
        .I3(S_AXI_ARADDR[7]),
        .I4(S_AXI_ARADDR[11]),
        .I5(S_AXI_ARADDR[10]),
        .O(\INT_STATE_R[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h0001000000000000)) 
    \INT_STATE_R[0]_i_4 
       (.I0(S_AXI_ARADDR[14]),
        .I1(S_AXI_ARADDR[15]),
        .I2(S_AXI_ARADDR[12]),
        .I3(S_AXI_ARADDR[13]),
        .I4(S_AXI_ARREADY),
        .I5(S_AXI_ARVALID),
        .O(\INT_STATE_R[0]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'h0000000100000000)) 
    \INT_STATE_R[0]_i_5 
       (.I0(S_AXI_ARADDR[2]),
        .I1(S_AXI_ARADDR[3]),
        .I2(S_AXI_ARADDR[0]),
        .I3(S_AXI_ARADDR[1]),
        .I4(S_AXI_ARADDR[5]),
        .I5(S_AXI_ARADDR[4]),
        .O(\INT_STATE_R[0]_i_5_n_0 ));
  FDRE \INT_STATE_R_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(INT_STATE_R0),
        .Q(r_CLEAR_INTER),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hFF7FF070F070F070)) 
    aw_en_i_1
       (.I0(S_AXI_WVALID),
        .I1(S_AXI_AWVALID),
        .I2(aw_en_reg_n_0),
        .I3(S_AXI_AWREADY),
        .I4(S_AXI_BREADY),
        .I5(S_AXI_BVALID),
        .O(aw_en_i_1_n_0));
  FDSE aw_en_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(aw_en_i_1_n_0),
        .Q(aw_en_reg_n_0),
        .S(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[0]),
        .Q(axi_araddr[0]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[10] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[10]),
        .Q(axi_araddr[10]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[11] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[11]),
        .Q(axi_araddr[11]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[12] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[12]),
        .Q(axi_araddr[12]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[13] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[13]),
        .Q(axi_araddr[13]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[14] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[14]),
        .Q(axi_araddr[14]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[15] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[15]),
        .Q(axi_araddr[15]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[1] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[1]),
        .Q(axi_araddr[1]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[2] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[2]),
        .Q(axi_araddr[2]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[3] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[3]),
        .Q(axi_araddr[3]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[4] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[4]),
        .Q(axi_araddr[4]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[5] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[5]),
        .Q(axi_araddr[5]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[6] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[6]),
        .Q(axi_araddr[6]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[7] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[7]),
        .Q(axi_araddr[7]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[8] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[8]),
        .Q(axi_araddr[8]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_araddr_reg[9] 
       (.C(S_AXI_ACLK),
        .CE(axi_arready0),
        .D(S_AXI_ARADDR[9]),
        .Q(axi_araddr[9]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h2)) 
    axi_arready_i_1
       (.I0(S_AXI_ARVALID),
        .I1(S_AXI_ARREADY),
        .O(axi_arready0));
  FDRE axi_arready_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(axi_arready0),
        .Q(S_AXI_ARREADY),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[0]),
        .Q(axi_awaddr[0]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[10] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[10]),
        .Q(axi_awaddr[10]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[11] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[11]),
        .Q(axi_awaddr[11]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[12] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[12]),
        .Q(axi_awaddr[12]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[13] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[13]),
        .Q(axi_awaddr[13]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[14] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[14]),
        .Q(axi_awaddr[14]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[15] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[15]),
        .Q(axi_awaddr[15]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[1] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[1]),
        .Q(axi_awaddr[1]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[2] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[2]),
        .Q(axi_awaddr[2]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[3] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[3]),
        .Q(axi_awaddr[3]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[4] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[4]),
        .Q(axi_awaddr[4]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[5] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[5]),
        .Q(axi_awaddr[5]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[6] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[6]),
        .Q(axi_awaddr[6]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[7] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[7]),
        .Q(axi_awaddr[7]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[8] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[8]),
        .Q(axi_awaddr[8]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_awaddr_reg[9] 
       (.C(S_AXI_ACLK),
        .CE(axi_awready0),
        .D(S_AXI_AWADDR[9]),
        .Q(axi_awaddr[9]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h4000)) 
    axi_awready_i_1
       (.I0(S_AXI_AWREADY),
        .I1(aw_en_reg_n_0),
        .I2(S_AXI_AWVALID),
        .I3(S_AXI_WVALID),
        .O(axi_awready0));
  FDRE axi_awready_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(axi_awready0),
        .Q(S_AXI_AWREADY),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'h0000FFFF80008000)) 
    axi_bvalid_i_1
       (.I0(S_AXI_WVALID),
        .I1(S_AXI_AWVALID),
        .I2(S_AXI_WREADY),
        .I3(S_AXI_AWREADY),
        .I4(S_AXI_BREADY),
        .I5(S_AXI_BVALID),
        .O(axi_bvalid_i_1_n_0));
  FDRE axi_bvalid_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(axi_bvalid_i_1_n_0),
        .Q(S_AXI_BVALID),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT6 #(
    .INIT(64'hAAAAAAAAA0208000)) 
    \axi_rdata[0]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[0]_i_2_n_0 ),
        .I4(\axi_rdata[0]_i_3_n_0 ),
        .I5(\axi_rdata[0]_i_4_n_0 ),
        .O(\axi_rdata[0]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[0]_i_2 
       (.I0(RX_READY_BLOCKS[0]),
        .I1(RX_DROPPED_FRAMES[0]),
        .I2(RX_HEAD_SEQ[0]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[0]_i_2_n_0 ));
  LUT6 #(
    .INIT(64'hCFAFCFA0C0AFC0A0)) 
    \axi_rdata[0]_i_3 
       (.I0(r_CPU_FPGA_START_ADDR[0]),
        .I1(DDR_STATUS_W[0]),
        .I2(axi_araddr[2]),
        .I3(axi_araddr[3]),
        .I4(\CPU_WR_DONE_reg_n_0_[0] ),
        .I5(r_CPU_FPGA_LEN[0]),
        .O(\axi_rdata[0]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'h00000000B88888BB)) 
    \axi_rdata[0]_i_4 
       (.I0(\axi_rdata[0]_i_5_n_0 ),
        .I1(axi_araddr[4]),
        .I2(FPGA_TEMP_W[0]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .I5(axi_araddr[5]),
        .O(\axi_rdata[0]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hCFAFCFA0C0AFC0A0)) 
    \axi_rdata[0]_i_5 
       (.I0(r_CPU_REC_STATE),
        .I1(FPGA_CPU_LEN[0]),
        .I2(axi_araddr[2]),
        .I3(axi_araddr[3]),
        .I4(INT_STATE_W),
        .I5(FPGA_CPU_START_ADDR[0]),
        .O(\axi_rdata[0]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[10]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[10]_i_2_n_0 ),
        .I4(\axi_rdata[10]_i_3_n_0 ),
        .I5(\axi_rdata[10]_i_4_n_0 ),
        .O(\axi_rdata[10]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[10]_i_2 
       (.I0(RX_READY_BLOCKS[10]),
        .I1(RX_DROPPED_FRAMES[10]),
        .I2(RX_HEAD_SEQ[10]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[10]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[10]_i_3 
       (.I0(r_CPU_FPGA_LEN[10]),
        .I1(r_CPU_FPGA_START_ADDR[10]),
        .I2(DDR_STATUS_W[10]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[10]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[10]_i_4 
       (.I0(FPGA_CPU_START_ADDR[10]),
        .I1(FPGA_TEMP_W[10]),
        .I2(FPGA_CPU_LEN[10]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[10]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[11]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[11]_i_2_n_0 ),
        .I4(\axi_rdata[11]_i_3_n_0 ),
        .I5(\axi_rdata[11]_i_4_n_0 ),
        .O(\axi_rdata[11]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[11]_i_2 
       (.I0(RX_READY_BLOCKS[11]),
        .I1(RX_DROPPED_FRAMES[11]),
        .I2(RX_HEAD_SEQ[11]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[11]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[11]_i_3 
       (.I0(r_CPU_FPGA_LEN[11]),
        .I1(r_CPU_FPGA_START_ADDR[11]),
        .I2(DDR_STATUS_W[11]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[11]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[11]_i_4 
       (.I0(FPGA_CPU_START_ADDR[11]),
        .I1(FPGA_CPU_LEN[11]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[11]),
        .O(\axi_rdata[11]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[12]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[12]_i_2_n_0 ),
        .I4(\axi_rdata[12]_i_3_n_0 ),
        .I5(\axi_rdata[12]_i_4_n_0 ),
        .O(\axi_rdata[12]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[12]_i_2 
       (.I0(RX_READY_BLOCKS[12]),
        .I1(RX_DROPPED_FRAMES[12]),
        .I2(RX_HEAD_SEQ[12]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[12]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[12]_i_3 
       (.I0(r_CPU_FPGA_LEN[12]),
        .I1(r_CPU_FPGA_START_ADDR[12]),
        .I2(DDR_STATUS_W[12]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[12]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[12]_i_4 
       (.I0(FPGA_CPU_START_ADDR[12]),
        .I1(FPGA_TEMP_W[12]),
        .I2(FPGA_CPU_LEN[12]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[12]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[13]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[13]_i_2_n_0 ),
        .I4(\axi_rdata[13]_i_3_n_0 ),
        .I5(\axi_rdata[13]_i_4_n_0 ),
        .O(\axi_rdata[13]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[13]_i_2 
       (.I0(RX_READY_BLOCKS[13]),
        .I1(RX_DROPPED_FRAMES[13]),
        .I2(RX_HEAD_SEQ[13]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[13]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[13]_i_3 
       (.I0(r_CPU_FPGA_LEN[13]),
        .I1(r_CPU_FPGA_START_ADDR[13]),
        .I2(DDR_STATUS_W[13]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[13]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hCF00A00FC000A00F)) 
    \axi_rdata[13]_i_4 
       (.I0(FPGA_TEMP_W[13]),
        .I1(FPGA_CPU_LEN[13]),
        .I2(axi_araddr[2]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[4]),
        .I5(FPGA_CPU_START_ADDR[13]),
        .O(\axi_rdata[13]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[14]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[14]_i_2_n_0 ),
        .I4(\axi_rdata[14]_i_3_n_0 ),
        .I5(\axi_rdata[14]_i_4_n_0 ),
        .O(\axi_rdata[14]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[14]_i_2 
       (.I0(RX_READY_BLOCKS[14]),
        .I1(RX_DROPPED_FRAMES[14]),
        .I2(RX_HEAD_SEQ[14]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[14]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[14]_i_3 
       (.I0(r_CPU_FPGA_LEN[14]),
        .I1(r_CPU_FPGA_START_ADDR[14]),
        .I2(DDR_STATUS_W[14]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[14]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[14]_i_4 
       (.I0(FPGA_CPU_START_ADDR[14]),
        .I1(FPGA_TEMP_W[14]),
        .I2(FPGA_CPU_LEN[14]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[14]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[15]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[15]_i_2_n_0 ),
        .I4(\axi_rdata[15]_i_3_n_0 ),
        .I5(\axi_rdata[15]_i_4_n_0 ),
        .O(\axi_rdata[15]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[15]_i_2 
       (.I0(RX_READY_BLOCKS[15]),
        .I1(RX_DROPPED_FRAMES[15]),
        .I2(RX_HEAD_SEQ[15]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[15]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[15]_i_3 
       (.I0(r_CPU_FPGA_LEN[15]),
        .I1(r_CPU_FPGA_START_ADDR[15]),
        .I2(DDR_STATUS_W[15]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[15]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[15]_i_4 
       (.I0(FPGA_CPU_START_ADDR[15]),
        .I1(FPGA_TEMP_W[15]),
        .I2(FPGA_CPU_LEN[15]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[15]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[16]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[16]_i_2_n_0 ),
        .I4(\axi_rdata[16]_i_3_n_0 ),
        .I5(\axi_rdata[16]_i_4_n_0 ),
        .O(\axi_rdata[16]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[16]_i_2 
       (.I0(RX_READY_BLOCKS[16]),
        .I1(RX_DROPPED_FRAMES[16]),
        .I2(RX_HEAD_SEQ[16]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[16]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[16]_i_3 
       (.I0(r_CPU_FPGA_LEN[16]),
        .I1(r_CPU_FPGA_START_ADDR[16]),
        .I2(DDR_STATUS_W[16]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[16]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[16]_i_4 
       (.I0(FPGA_CPU_START_ADDR[16]),
        .I1(FPGA_TEMP_W[16]),
        .I2(FPGA_CPU_LEN[16]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[16]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[17]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[17]_i_2_n_0 ),
        .I4(\axi_rdata[17]_i_3_n_0 ),
        .I5(\axi_rdata[17]_i_4_n_0 ),
        .O(\axi_rdata[17]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[17]_i_2 
       (.I0(RX_READY_BLOCKS[17]),
        .I1(RX_DROPPED_FRAMES[17]),
        .I2(RX_HEAD_SEQ[17]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[17]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[17]_i_3 
       (.I0(r_CPU_FPGA_LEN[17]),
        .I1(r_CPU_FPGA_START_ADDR[17]),
        .I2(DDR_STATUS_W[17]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[17]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[17]_i_4 
       (.I0(FPGA_CPU_START_ADDR[17]),
        .I1(FPGA_CPU_LEN[17]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[17]),
        .O(\axi_rdata[17]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[18]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[18]_i_2_n_0 ),
        .I4(\axi_rdata[18]_i_3_n_0 ),
        .I5(\axi_rdata[18]_i_4_n_0 ),
        .O(\axi_rdata[18]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[18]_i_2 
       (.I0(RX_READY_BLOCKS[18]),
        .I1(RX_DROPPED_FRAMES[18]),
        .I2(RX_HEAD_SEQ[18]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[18]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[18]_i_3 
       (.I0(r_CPU_FPGA_LEN[18]),
        .I1(r_CPU_FPGA_START_ADDR[18]),
        .I2(DDR_STATUS_W[18]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[18]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0CC0000AAFFFF00)) 
    \axi_rdata[18]_i_4 
       (.I0(FPGA_TEMP_W[18]),
        .I1(FPGA_CPU_START_ADDR[18]),
        .I2(FPGA_CPU_LEN[18]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[18]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[19]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[19]_i_2_n_0 ),
        .I4(\axi_rdata[19]_i_3_n_0 ),
        .I5(\axi_rdata[19]_i_4_n_0 ),
        .O(\axi_rdata[19]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[19]_i_2 
       (.I0(RX_READY_BLOCKS[19]),
        .I1(RX_DROPPED_FRAMES[19]),
        .I2(RX_HEAD_SEQ[19]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[19]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[19]_i_3 
       (.I0(r_CPU_FPGA_LEN[19]),
        .I1(r_CPU_FPGA_START_ADDR[19]),
        .I2(DDR_STATUS_W[19]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[19]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[19]_i_4 
       (.I0(FPGA_CPU_START_ADDR[19]),
        .I1(FPGA_TEMP_W[19]),
        .I2(FPGA_CPU_LEN[19]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[19]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[1]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[1]_i_2_n_0 ),
        .I4(\axi_rdata[1]_i_3_n_0 ),
        .I5(\axi_rdata[1]_i_4_n_0 ),
        .O(\axi_rdata[1]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[1]_i_2 
       (.I0(RX_READY_BLOCKS[1]),
        .I1(RX_DROPPED_FRAMES[1]),
        .I2(RX_HEAD_SEQ[1]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[1]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[1]_i_3 
       (.I0(r_CPU_FPGA_LEN[1]),
        .I1(r_CPU_FPGA_START_ADDR[1]),
        .I2(DDR_STATUS_W[1]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[1]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[1]_i_4 
       (.I0(FPGA_CPU_START_ADDR[1]),
        .I1(FPGA_TEMP_W[1]),
        .I2(FPGA_CPU_LEN[1]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[1]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[20]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[20]_i_2_n_0 ),
        .I4(\axi_rdata[20]_i_3_n_0 ),
        .I5(\axi_rdata[20]_i_4_n_0 ),
        .O(\axi_rdata[20]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[20]_i_2 
       (.I0(RX_READY_BLOCKS[20]),
        .I1(RX_DROPPED_FRAMES[20]),
        .I2(RX_HEAD_SEQ[20]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[20]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[20]_i_3 
       (.I0(r_CPU_FPGA_LEN[20]),
        .I1(r_CPU_FPGA_START_ADDR[20]),
        .I2(DDR_STATUS_W[20]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[20]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[20]_i_4 
       (.I0(FPGA_CPU_START_ADDR[20]),
        .I1(FPGA_TEMP_W[20]),
        .I2(FPGA_CPU_LEN[20]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[20]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[21]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[21]_i_2_n_0 ),
        .I4(\axi_rdata[21]_i_3_n_0 ),
        .I5(\axi_rdata[21]_i_4_n_0 ),
        .O(\axi_rdata[21]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[21]_i_2 
       (.I0(RX_READY_BLOCKS[21]),
        .I1(RX_DROPPED_FRAMES[21]),
        .I2(RX_HEAD_SEQ[21]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[21]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[21]_i_3 
       (.I0(r_CPU_FPGA_LEN[21]),
        .I1(r_CPU_FPGA_START_ADDR[21]),
        .I2(DDR_STATUS_W[21]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[21]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[21]_i_4 
       (.I0(FPGA_CPU_START_ADDR[21]),
        .I1(FPGA_CPU_LEN[21]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[21]),
        .O(\axi_rdata[21]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[22]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[22]_i_2_n_0 ),
        .I4(\axi_rdata[22]_i_3_n_0 ),
        .I5(\axi_rdata[22]_i_4_n_0 ),
        .O(\axi_rdata[22]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[22]_i_2 
       (.I0(RX_READY_BLOCKS[22]),
        .I1(RX_DROPPED_FRAMES[22]),
        .I2(RX_HEAD_SEQ[22]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[22]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[22]_i_3 
       (.I0(r_CPU_FPGA_LEN[22]),
        .I1(r_CPU_FPGA_START_ADDR[22]),
        .I2(DDR_STATUS_W[22]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[22]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[22]_i_4 
       (.I0(FPGA_CPU_START_ADDR[22]),
        .I1(FPGA_TEMP_W[22]),
        .I2(FPGA_CPU_LEN[22]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[22]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[23]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[23]_i_2_n_0 ),
        .I4(\axi_rdata[23]_i_3_n_0 ),
        .I5(\axi_rdata[23]_i_4_n_0 ),
        .O(\axi_rdata[23]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[23]_i_2 
       (.I0(RX_READY_BLOCKS[23]),
        .I1(RX_DROPPED_FRAMES[23]),
        .I2(RX_HEAD_SEQ[23]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[23]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[23]_i_3 
       (.I0(r_CPU_FPGA_LEN[23]),
        .I1(r_CPU_FPGA_START_ADDR[23]),
        .I2(DDR_STATUS_W[23]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[23]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[23]_i_4 
       (.I0(FPGA_CPU_START_ADDR[23]),
        .I1(FPGA_TEMP_W[23]),
        .I2(FPGA_CPU_LEN[23]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[23]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[24]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[24]_i_2_n_0 ),
        .I4(\axi_rdata[24]_i_3_n_0 ),
        .I5(\axi_rdata[24]_i_4_n_0 ),
        .O(\axi_rdata[24]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[24]_i_2 
       (.I0(RX_READY_BLOCKS[24]),
        .I1(RX_DROPPED_FRAMES[24]),
        .I2(RX_HEAD_SEQ[24]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[24]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[24]_i_3 
       (.I0(r_CPU_FPGA_LEN[24]),
        .I1(r_CPU_FPGA_START_ADDR[24]),
        .I2(DDR_STATUS_W[24]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[24]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[24]_i_4 
       (.I0(FPGA_CPU_START_ADDR[24]),
        .I1(FPGA_TEMP_W[24]),
        .I2(FPGA_CPU_LEN[24]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[24]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[25]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[25]_i_2_n_0 ),
        .I4(\axi_rdata[25]_i_3_n_0 ),
        .I5(\axi_rdata[25]_i_4_n_0 ),
        .O(\axi_rdata[25]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[25]_i_2 
       (.I0(RX_READY_BLOCKS[25]),
        .I1(RX_DROPPED_FRAMES[25]),
        .I2(RX_HEAD_SEQ[25]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[25]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[25]_i_3 
       (.I0(r_CPU_FPGA_LEN[25]),
        .I1(r_CPU_FPGA_START_ADDR[25]),
        .I2(DDR_STATUS_W[25]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[25]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[25]_i_4 
       (.I0(FPGA_CPU_START_ADDR[25]),
        .I1(FPGA_TEMP_W[25]),
        .I2(FPGA_CPU_LEN[25]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[25]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[26]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[26]_i_2_n_0 ),
        .I4(\axi_rdata[26]_i_3_n_0 ),
        .I5(\axi_rdata[26]_i_4_n_0 ),
        .O(\axi_rdata[26]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[26]_i_2 
       (.I0(RX_READY_BLOCKS[26]),
        .I1(RX_DROPPED_FRAMES[26]),
        .I2(RX_HEAD_SEQ[26]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[26]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[26]_i_3 
       (.I0(r_CPU_FPGA_LEN[26]),
        .I1(r_CPU_FPGA_START_ADDR[26]),
        .I2(DDR_STATUS_W[26]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[26]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[26]_i_4 
       (.I0(FPGA_CPU_START_ADDR[26]),
        .I1(FPGA_TEMP_W[26]),
        .I2(FPGA_CPU_LEN[26]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[26]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[27]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[27]_i_2_n_0 ),
        .I4(\axi_rdata[27]_i_3_n_0 ),
        .I5(\axi_rdata[27]_i_4_n_0 ),
        .O(\axi_rdata[27]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[27]_i_2 
       (.I0(RX_READY_BLOCKS[27]),
        .I1(RX_DROPPED_FRAMES[27]),
        .I2(RX_HEAD_SEQ[27]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[27]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[27]_i_3 
       (.I0(r_CPU_FPGA_LEN[27]),
        .I1(r_CPU_FPGA_START_ADDR[27]),
        .I2(DDR_STATUS_W[27]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[27]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[27]_i_4 
       (.I0(FPGA_CPU_START_ADDR[27]),
        .I1(FPGA_TEMP_W[27]),
        .I2(FPGA_CPU_LEN[27]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[27]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[28]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[28]_i_2_n_0 ),
        .I4(\axi_rdata[28]_i_3_n_0 ),
        .I5(\axi_rdata[28]_i_4_n_0 ),
        .O(\axi_rdata[28]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[28]_i_2 
       (.I0(RX_READY_BLOCKS[28]),
        .I1(RX_DROPPED_FRAMES[28]),
        .I2(RX_HEAD_SEQ[28]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[28]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[28]_i_3 
       (.I0(r_CPU_FPGA_LEN[28]),
        .I1(r_CPU_FPGA_START_ADDR[28]),
        .I2(DDR_STATUS_W[28]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[28]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[28]_i_4 
       (.I0(FPGA_CPU_START_ADDR[28]),
        .I1(FPGA_TEMP_W[28]),
        .I2(FPGA_CPU_LEN[28]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[28]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[29]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[29]_i_2_n_0 ),
        .I4(\axi_rdata[29]_i_3_n_0 ),
        .I5(\axi_rdata[29]_i_4_n_0 ),
        .O(\axi_rdata[29]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[29]_i_2 
       (.I0(RX_READY_BLOCKS[29]),
        .I1(RX_DROPPED_FRAMES[29]),
        .I2(RX_HEAD_SEQ[29]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[29]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[29]_i_3 
       (.I0(r_CPU_FPGA_LEN[29]),
        .I1(r_CPU_FPGA_START_ADDR[29]),
        .I2(DDR_STATUS_W[29]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[29]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[29]_i_4 
       (.I0(FPGA_CPU_START_ADDR[29]),
        .I1(FPGA_CPU_LEN[29]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[29]),
        .O(\axi_rdata[29]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[2]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[2]_i_2_n_0 ),
        .I4(\axi_rdata[2]_i_3_n_0 ),
        .I5(\axi_rdata[2]_i_4_n_0 ),
        .O(\axi_rdata[2]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[2]_i_2 
       (.I0(RX_READY_BLOCKS[2]),
        .I1(RX_DROPPED_FRAMES[2]),
        .I2(RX_HEAD_SEQ[2]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[2]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[2]_i_3 
       (.I0(r_CPU_FPGA_LEN[2]),
        .I1(r_CPU_FPGA_START_ADDR[2]),
        .I2(DDR_STATUS_W[2]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[2]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[2]_i_4 
       (.I0(FPGA_CPU_START_ADDR[2]),
        .I1(FPGA_CPU_LEN[2]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[2]),
        .O(\axi_rdata[2]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[30]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[30]_i_2_n_0 ),
        .I4(\axi_rdata[30]_i_3_n_0 ),
        .I5(\axi_rdata[30]_i_4_n_0 ),
        .O(\axi_rdata[30]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[30]_i_2 
       (.I0(RX_READY_BLOCKS[30]),
        .I1(RX_DROPPED_FRAMES[30]),
        .I2(RX_HEAD_SEQ[30]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[30]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[30]_i_3 
       (.I0(r_CPU_FPGA_LEN[30]),
        .I1(r_CPU_FPGA_START_ADDR[30]),
        .I2(DDR_STATUS_W[30]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[30]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[30]_i_4 
       (.I0(FPGA_CPU_START_ADDR[30]),
        .I1(FPGA_TEMP_W[30]),
        .I2(FPGA_CPU_LEN[30]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[30]_i_4_n_0 ));
  LUT3 #(
    .INIT(8'h08)) 
    \axi_rdata[31]_i_1 
       (.I0(S_AXI_ARREADY),
        .I1(S_AXI_ARVALID),
        .I2(S_AXI_RVALID),
        .O(slv_reg_rden));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[31]_i_2 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[31]_i_4_n_0 ),
        .I4(\axi_rdata[31]_i_5_n_0 ),
        .I5(\axi_rdata[31]_i_6_n_0 ),
        .O(\axi_rdata[31]_i_2_n_0 ));
  LUT4 #(
    .INIT(16'h0001)) 
    \axi_rdata[31]_i_3 
       (.I0(axi_araddr[0]),
        .I1(\axi_rdata[31]_i_7_n_0 ),
        .I2(\axi_rdata[31]_i_8_n_0 ),
        .I3(axi_araddr[1]),
        .O(\axi_rdata[31]_i_3_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[31]_i_4 
       (.I0(RX_READY_BLOCKS[31]),
        .I1(RX_DROPPED_FRAMES[31]),
        .I2(RX_HEAD_SEQ[31]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[31]_i_4_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[31]_i_5 
       (.I0(r_CPU_FPGA_LEN[31]),
        .I1(r_CPU_FPGA_START_ADDR[31]),
        .I2(DDR_STATUS_W[31]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[31]_i_5_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[31]_i_6 
       (.I0(FPGA_CPU_START_ADDR[31]),
        .I1(FPGA_TEMP_W[31]),
        .I2(FPGA_CPU_LEN[31]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[31]_i_6_n_0 ));
  LUT6 #(
    .INIT(64'hFFFFFFFFFFFFFFFE)) 
    \axi_rdata[31]_i_7 
       (.I0(axi_araddr[15]),
        .I1(axi_araddr[14]),
        .I2(axi_araddr[13]),
        .I3(axi_araddr[12]),
        .I4(axi_araddr[6]),
        .I5(axi_araddr[7]),
        .O(\axi_rdata[31]_i_7_n_0 ));
  LUT4 #(
    .INIT(16'hFFFE)) 
    \axi_rdata[31]_i_8 
       (.I0(axi_araddr[8]),
        .I1(axi_araddr[9]),
        .I2(axi_araddr[10]),
        .I3(axi_araddr[11]),
        .O(\axi_rdata[31]_i_8_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[3]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[3]_i_2_n_0 ),
        .I4(\axi_rdata[3]_i_3_n_0 ),
        .I5(\axi_rdata[3]_i_4_n_0 ),
        .O(\axi_rdata[3]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[3]_i_2 
       (.I0(RX_READY_BLOCKS[3]),
        .I1(RX_DROPPED_FRAMES[3]),
        .I2(RX_HEAD_SEQ[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[3]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[3]_i_3 
       (.I0(r_CPU_FPGA_LEN[3]),
        .I1(r_CPU_FPGA_START_ADDR[3]),
        .I2(DDR_STATUS_W[3]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[3]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[3]_i_4 
       (.I0(FPGA_CPU_START_ADDR[3]),
        .I1(FPGA_TEMP_W[3]),
        .I2(FPGA_CPU_LEN[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[3]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[4]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[4]_i_2_n_0 ),
        .I4(\axi_rdata[4]_i_3_n_0 ),
        .I5(\axi_rdata[4]_i_4_n_0 ),
        .O(\axi_rdata[4]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[4]_i_2 
       (.I0(RX_READY_BLOCKS[4]),
        .I1(RX_DROPPED_FRAMES[4]),
        .I2(RX_HEAD_SEQ[4]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[4]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[4]_i_3 
       (.I0(r_CPU_FPGA_LEN[4]),
        .I1(r_CPU_FPGA_START_ADDR[4]),
        .I2(DDR_STATUS_W[4]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[4]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[4]_i_4 
       (.I0(FPGA_CPU_START_ADDR[4]),
        .I1(FPGA_CPU_LEN[4]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[4]),
        .O(\axi_rdata[4]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[5]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[5]_i_2_n_0 ),
        .I4(\axi_rdata[5]_i_3_n_0 ),
        .I5(\axi_rdata[5]_i_4_n_0 ),
        .O(\axi_rdata[5]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[5]_i_2 
       (.I0(RX_READY_BLOCKS[5]),
        .I1(RX_DROPPED_FRAMES[5]),
        .I2(RX_HEAD_SEQ[5]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[5]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[5]_i_3 
       (.I0(r_CPU_FPGA_LEN[5]),
        .I1(r_CPU_FPGA_START_ADDR[5]),
        .I2(DDR_STATUS_W[5]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[5]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[5]_i_4 
       (.I0(FPGA_CPU_START_ADDR[5]),
        .I1(FPGA_TEMP_W[5]),
        .I2(FPGA_CPU_LEN[5]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[5]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[6]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[6]_i_2_n_0 ),
        .I4(\axi_rdata[6]_i_3_n_0 ),
        .I5(\axi_rdata[6]_i_4_n_0 ),
        .O(\axi_rdata[6]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[6]_i_2 
       (.I0(RX_READY_BLOCKS[6]),
        .I1(RX_DROPPED_FRAMES[6]),
        .I2(RX_HEAD_SEQ[6]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[6]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[6]_i_3 
       (.I0(r_CPU_FPGA_LEN[6]),
        .I1(r_CPU_FPGA_START_ADDR[6]),
        .I2(DDR_STATUS_W[6]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[6]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[6]_i_4 
       (.I0(FPGA_CPU_START_ADDR[6]),
        .I1(FPGA_TEMP_W[6]),
        .I2(FPGA_CPU_LEN[6]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[6]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[7]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[7]_i_2_n_0 ),
        .I4(\axi_rdata[7]_i_3_n_0 ),
        .I5(\axi_rdata[7]_i_4_n_0 ),
        .O(\axi_rdata[7]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[7]_i_2 
       (.I0(RX_READY_BLOCKS[7]),
        .I1(RX_DROPPED_FRAMES[7]),
        .I2(RX_HEAD_SEQ[7]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[7]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[7]_i_3 
       (.I0(r_CPU_FPGA_LEN[7]),
        .I1(r_CPU_FPGA_START_ADDR[7]),
        .I2(DDR_STATUS_W[7]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[7]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[7]_i_4 
       (.I0(FPGA_CPU_START_ADDR[7]),
        .I1(FPGA_TEMP_W[7]),
        .I2(FPGA_CPU_LEN[7]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[7]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[8]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[8]_i_2_n_0 ),
        .I4(\axi_rdata[8]_i_3_n_0 ),
        .I5(\axi_rdata[8]_i_4_n_0 ),
        .O(\axi_rdata[8]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[8]_i_2 
       (.I0(RX_READY_BLOCKS[8]),
        .I1(RX_DROPPED_FRAMES[8]),
        .I2(RX_HEAD_SEQ[8]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[8]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[8]_i_3 
       (.I0(r_CPU_FPGA_LEN[8]),
        .I1(r_CPU_FPGA_START_ADDR[8]),
        .I2(DDR_STATUS_W[8]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[8]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hC0A0FF00C0A00F00)) 
    \axi_rdata[8]_i_4 
       (.I0(FPGA_CPU_START_ADDR[8]),
        .I1(FPGA_CPU_LEN[8]),
        .I2(axi_araddr[3]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[4]),
        .I5(FPGA_TEMP_W[8]),
        .O(\axi_rdata[8]_i_4_n_0 ));
  LUT6 #(
    .INIT(64'hAA2A8A0AA0208000)) 
    \axi_rdata[9]_i_1 
       (.I0(\axi_rdata[31]_i_3_n_0 ),
        .I1(axi_araddr[4]),
        .I2(axi_araddr[5]),
        .I3(\axi_rdata[9]_i_2_n_0 ),
        .I4(\axi_rdata[9]_i_3_n_0 ),
        .I5(\axi_rdata[9]_i_4_n_0 ),
        .O(\axi_rdata[9]_i_1_n_0 ));
  LUT5 #(
    .INIT(32'h00CCF0AA)) 
    \axi_rdata[9]_i_2 
       (.I0(RX_READY_BLOCKS[9]),
        .I1(RX_DROPPED_FRAMES[9]),
        .I2(RX_HEAD_SEQ[9]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .O(\axi_rdata[9]_i_2_n_0 ));
  LUT5 #(
    .INIT(32'hF0CCAA00)) 
    \axi_rdata[9]_i_3 
       (.I0(r_CPU_FPGA_LEN[9]),
        .I1(r_CPU_FPGA_START_ADDR[9]),
        .I2(DDR_STATUS_W[9]),
        .I3(axi_araddr[3]),
        .I4(axi_araddr[2]),
        .O(\axi_rdata[9]_i_3_n_0 ));
  LUT6 #(
    .INIT(64'hF0AA0000CC000000)) 
    \axi_rdata[9]_i_4 
       (.I0(FPGA_CPU_START_ADDR[9]),
        .I1(FPGA_TEMP_W[9]),
        .I2(FPGA_CPU_LEN[9]),
        .I3(axi_araddr[2]),
        .I4(axi_araddr[3]),
        .I5(axi_araddr[4]),
        .O(\axi_rdata[9]_i_4_n_0 ));
  FDRE \axi_rdata_reg[0] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[0]_i_1_n_0 ),
        .Q(S_AXI_RDATA[0]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[10] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[10]_i_1_n_0 ),
        .Q(S_AXI_RDATA[10]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[11] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[11]_i_1_n_0 ),
        .Q(S_AXI_RDATA[11]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[12] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[12]_i_1_n_0 ),
        .Q(S_AXI_RDATA[12]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[13] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[13]_i_1_n_0 ),
        .Q(S_AXI_RDATA[13]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[14] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[14]_i_1_n_0 ),
        .Q(S_AXI_RDATA[14]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[15] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[15]_i_1_n_0 ),
        .Q(S_AXI_RDATA[15]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[16] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[16]_i_1_n_0 ),
        .Q(S_AXI_RDATA[16]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[17] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[17]_i_1_n_0 ),
        .Q(S_AXI_RDATA[17]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[18] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[18]_i_1_n_0 ),
        .Q(S_AXI_RDATA[18]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[19] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[19]_i_1_n_0 ),
        .Q(S_AXI_RDATA[19]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[1] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[1]_i_1_n_0 ),
        .Q(S_AXI_RDATA[1]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[20] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[20]_i_1_n_0 ),
        .Q(S_AXI_RDATA[20]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[21] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[21]_i_1_n_0 ),
        .Q(S_AXI_RDATA[21]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[22] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[22]_i_1_n_0 ),
        .Q(S_AXI_RDATA[22]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[23] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[23]_i_1_n_0 ),
        .Q(S_AXI_RDATA[23]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[24] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[24]_i_1_n_0 ),
        .Q(S_AXI_RDATA[24]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[25] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[25]_i_1_n_0 ),
        .Q(S_AXI_RDATA[25]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[26] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[26]_i_1_n_0 ),
        .Q(S_AXI_RDATA[26]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[27] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[27]_i_1_n_0 ),
        .Q(S_AXI_RDATA[27]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[28] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[28]_i_1_n_0 ),
        .Q(S_AXI_RDATA[28]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[29] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[29]_i_1_n_0 ),
        .Q(S_AXI_RDATA[29]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[2] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[2]_i_1_n_0 ),
        .Q(S_AXI_RDATA[2]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[30] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[30]_i_1_n_0 ),
        .Q(S_AXI_RDATA[30]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[31] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[31]_i_2_n_0 ),
        .Q(S_AXI_RDATA[31]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[3] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[3]_i_1_n_0 ),
        .Q(S_AXI_RDATA[3]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[4] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[4]_i_1_n_0 ),
        .Q(S_AXI_RDATA[4]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[5] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[5]_i_1_n_0 ),
        .Q(S_AXI_RDATA[5]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[6] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[6]_i_1_n_0 ),
        .Q(S_AXI_RDATA[6]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[7] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[7]_i_1_n_0 ),
        .Q(S_AXI_RDATA[7]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[8] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[8]_i_1_n_0 ),
        .Q(S_AXI_RDATA[8]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  FDRE \axi_rdata_reg[9] 
       (.C(S_AXI_ACLK),
        .CE(slv_reg_rden),
        .D(\axi_rdata[9]_i_1_n_0 ),
        .Q(S_AXI_RDATA[9]),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h7444)) 
    axi_rvalid_i_1
       (.I0(S_AXI_RREADY),
        .I1(S_AXI_RVALID),
        .I2(S_AXI_ARVALID),
        .I3(S_AXI_ARREADY),
        .O(axi_rvalid_i_1_n_0));
  FDRE axi_rvalid_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(axi_rvalid_i_1_n_0),
        .Q(S_AXI_RVALID),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT4 #(
    .INIT(16'h4000)) 
    axi_wready_i_1
       (.I0(S_AXI_WREADY),
        .I1(aw_en_reg_n_0),
        .I2(S_AXI_AWVALID),
        .I3(S_AXI_WVALID),
        .O(axi_wready0));
  FDRE axi_wready_reg
       (.C(S_AXI_ACLK),
        .CE(1'b1),
        .D(axi_wready0),
        .Q(S_AXI_WREADY),
        .R(\INT_STATE_R[0]_i_1_n_0 ));
  LUT2 #(
    .INIT(4'h2)) 
    r_RD_START_INST_0
       (.I0(\CPU_WR_DONE_reg_n_0_[0] ),
        .I1(CPU_WR_DONE_d),
        .O(r_RD_START));
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
