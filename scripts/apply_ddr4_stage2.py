from pathlib import Path
ROOT=Path(r"C:\project\RTDS\DDR\RTDS_test_DDR4_64bit")
SRC=ROOT/"RTDS_test_DDR4_64bit.srcs"/"sources_1"/"new"
def rep(path,old,new):
 t=path.read_text(encoding="utf-8")
 if new in t: print("ALREADY",path.name); return
 if old not in t: raise RuntimeError(f"pattern not found in {path}: {old[:100]!r}")
 path.write_text(t.replace(old,new,1),encoding="utf-8",newline="\n");print("PATCHED",path.name)
def rep_last(path,old,new):
 t=path.read_text(encoding="utf-8");i=t.rfind(old)
 if i<0: raise RuntimeError(f"last pattern not found in {path}")
 path.write_text(t[:i]+new+t[i+len(old):],encoding="utf-8",newline="\n");print("PATCHED_LAST",path.name)

pcie=SRC/"PCIe.v"
rep(pcie,"    input             i_sys_clk,\n    input             i_sys_rst,\n\n    input             aurora_user_clk,","    input             i_sys_clk,\n    input             i_sys_rst,\n\n    input             ddr_sys_clk_i,\n    input             ddr_sys_rst_n,\n    output            c0_ddr4_act_n,\n    output     [16:0] c0_ddr4_adr,\n    output     [1:0]  c0_ddr4_ba,\n    output     [0:0]  c0_ddr4_bg,\n    output     [0:0]  c0_ddr4_cke,\n    output     [0:0]  c0_ddr4_odt,\n    output     [0:0]  c0_ddr4_cs_n,\n    output     [0:0]  c0_ddr4_ck_t,\n    output     [0:0]  c0_ddr4_ck_c,\n    output            c0_ddr4_reset_n,\n    inout      [7:0]  c0_ddr4_dm_dbi_n,\n    inout      [63:0] c0_ddr4_dq,\n    inout      [7:0]  c0_ddr4_dqs_c,\n    inout      [7:0]  c0_ddr4_dqs_t,\n\n    input             aurora_user_clk,")
wires="""

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
    wire [31:0] DDR_STATUS_W = {27'd0,
                                (ddr_axi_timeout_sticky | fdma_timeout_sticky),
                                rx_overflow_sticky,
                                ddr_axi_response_error_sticky,
                                ddr_init_calib_complete,
                                ddr_ready};
"""
rep(pcie,"    wire [3:0]  adapter_rx_state_dbg;\n\n    assign user_lnk_up", "    wire [3:0]  adapter_rx_state_dbg;"+wires+"\n    assign user_lnk_up")
rep(pcie,"        .pcie_link_up          (user_lnk_up_int),\n        .aurora_channel_up", "        .pcie_link_up          (user_lnk_up_int),\n        .ddr_ready             (ddr_ready),\n        .aurora_channel_up")
rep(pcie,"    design_1_wrapper design_1_wrapper_inst (\n        .fdma_raddr_0", "    design_1_wrapper design_1_wrapper_inst (\n        .DDR_STATUS_W             (DDR_STATUS_W),\n        .fdma_raddr_0")
mem_ports="""
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
"""
rep(pcie,"        .sys_clk                 (i_sys_clk),\n        .sys_rst_n", "        .sys_clk                 (i_sys_clk),\n"+mem_ports+"        .sys_rst_n")
backend="""
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
"""
rep_last(pcie,"    );\n\nendmodule\n",backend)

top=SRC/"TOP.v"
ddr_ports="""        input                   ddr_sys_rst_n,
        output                  c0_ddr4_act_n,
        output      [16:0]      c0_ddr4_adr,
        output      [1:0]       c0_ddr4_ba,
        output      [0:0]       c0_ddr4_bg,
        output      [0:0]       c0_ddr4_cke,
        output      [0:0]       c0_ddr4_odt,
        output      [0:0]       c0_ddr4_cs_n,
        output      [0:0]       c0_ddr4_ck_t,
        output      [0:0]       c0_ddr4_ck_c,
        output                  c0_ddr4_reset_n,
        inout       [7:0]       c0_ddr4_dm_dbi_n,
        inout       [63:0]      c0_ddr4_dq,
        inout       [7:0]       c0_ddr4_dqs_c,
        inout       [7:0]       c0_ddr4_dqs_t,

"""
rep(top,"        output                  led\n",ddr_ports+"        output                  led\n")
rep(top,"    wire sys_rst;\n", "    wire sys_rst;\n    wire clk_100m_ibuf;\n")
rep(top,"    CLK_GEN u_clk_gen (\n        .clk_p     (clk_p),\n        .clk_n     (clk_n),", "    IBUFDS u_shared_100m_ibuf (\n        .I  (clk_p),\n        .IB (clk_n),\n        .O  (clk_100m_ibuf)\n    );\n\n    CLK_GEN u_clk_gen (\n        .clk_i     (clk_100m_ibuf),")
rep(top,"        .i_sys_rst           (sys_rst),\n        .aurora_user_clk", "        .i_sys_rst           (sys_rst),\n        .ddr_sys_clk_i        (clk_100m_ibuf),\n        .ddr_sys_rst_n        (ddr_sys_rst_n),\n        .c0_ddr4_act_n        (c0_ddr4_act_n),\n        .c0_ddr4_adr          (c0_ddr4_adr),\n        .c0_ddr4_ba           (c0_ddr4_ba),\n        .c0_ddr4_bg           (c0_ddr4_bg),\n        .c0_ddr4_cke          (c0_ddr4_cke),\n        .c0_ddr4_odt          (c0_ddr4_odt),\n        .c0_ddr4_cs_n         (c0_ddr4_cs_n),\n        .c0_ddr4_ck_t         (c0_ddr4_ck_t),\n        .c0_ddr4_ck_c         (c0_ddr4_ck_c),\n        .c0_ddr4_reset_n      (c0_ddr4_reset_n),\n        .c0_ddr4_dm_dbi_n     (c0_ddr4_dm_dbi_n),\n        .c0_ddr4_dq           (c0_ddr4_dq),\n        .c0_ddr4_dqs_c        (c0_ddr4_dqs_c),\n        .c0_ddr4_dqs_t        (c0_ddr4_dqs_t),\n        .aurora_user_clk")

wrap=ROOT/"regression"/"sim_xdma_rootport"/"tb"/"rtds_pcie_ep_sim_wrapper.sv"
rep(wrap,"        .i_sys_rst          (i_sys_rst),\n        .aurora_user_clk", "        .i_sys_rst          (i_sys_rst),\n        .ddr_sys_clk_i       (i_sys_clk),\n        .ddr_sys_rst_n       (!i_sys_rst),\n        .aurora_user_clk")

# DDR pin constraints: same physical board; exclude golden LEDs and duplicate sys_clk pins.
golden=Path(r"C:\project\RTDS\DDR\axi_ddr4_min_2020_2\constr\top_axi_ddr4_bist.xdc")
out=ROOT/"RTDS_test_DDR4_64bit.srcs"/"constrs_1"/"new"/"DDR4_PIN.xdc"
lines=["# DDR4 pins from axi_ddr4_min_2020_2; same KU040 board.","# AK17/AK16 are owned by TOP's single shared IBUFDS in PIN.xdc."]
for line in golden.read_text(encoding="utf-8").splitlines():
 if "sys_clk" in line or "led[" in line: continue
 lines.append(line.replace("sys_rst_n","ddr_sys_rst_n"))
out.write_text("\n".join(lines)+"\n",encoding="utf-8",newline="\n")
print("PATCH_STAGE2_DONE")