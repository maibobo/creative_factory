`timescale 1ns/1ps
`define DDR4_SIM_RAM
module tb_rtds_ddr4_backend_smoke;
    reg clk=0, ddr_clk=0, resetn=0, ddr_resetn=0, clear_status=0;
    always #2 clk=~clk;
    always #5 ddr_clk=~ddr_clk;

    reg [4:0] awid=0, arid=0;
    reg [31:0] awaddr=0, araddr=0;
    reg [7:0] awlen=0, arlen=0;
    reg [2:0] awsize=3, arsize=3;
    reg [1:0] awburst=1, arburst=1;
    reg [0:0] awlock=0, arlock=0;
    reg [3:0] awcache=0, arcache=0, awregion=0, arregion=0, awqos=0, arqos=0;
    reg [2:0] awprot=0, arprot=0;
    reg awvalid=0, wvalid=0, bready=0, arvalid=0, rready=0;
    reg [63:0] wdata=0;
    reg [7:0] wstrb=8'hff;
    reg wlast=0;
    wire awready,wready,bvalid,arready,rlast,rvalid;
    wire [4:0] bid,rid;
    wire [1:0] bresp,rresp;
    wire [63:0] rdata;
    wire ddr_ready,calib,resp_err,timeout_err;
    wire act_n,reset_ddr_n;
    wire [16:0] adr;
    wire [1:0] ba;
    wire [0:0] bg,cke,odt,cs_n,ck_t,ck_c;
    wire [7:0] dm,dqs_c,dqs_t;
    wire [63:0] dq;

    rtds_ddr4_backend #(.TIMEOUT_CYCLES(64)) dut (
      .s_axi_aclk(clk),.s_axi_aresetn(resetn),.ddr_sys_clk_i(ddr_clk),.ddr_sys_rst_n(ddr_resetn),.clear_status(clear_status),
      .s_axi_awid(awid),.s_axi_awaddr(awaddr),.s_axi_awlen(awlen),.s_axi_awsize(awsize),.s_axi_awburst(awburst),
      .s_axi_awlock(awlock),.s_axi_awcache(awcache),.s_axi_awprot(awprot),.s_axi_awregion(awregion),.s_axi_awqos(awqos),
      .s_axi_awvalid(awvalid),.s_axi_awready(awready),.s_axi_wdata(wdata),.s_axi_wstrb(wstrb),.s_axi_wlast(wlast),
      .s_axi_wvalid(wvalid),.s_axi_wready(wready),.s_axi_bid(bid),.s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready),
      .s_axi_arid(arid),.s_axi_araddr(araddr),.s_axi_arlen(arlen),.s_axi_arsize(arsize),.s_axi_arburst(arburst),
      .s_axi_arlock(arlock),.s_axi_arcache(arcache),.s_axi_arprot(arprot),.s_axi_arregion(arregion),.s_axi_arqos(arqos),
      .s_axi_arvalid(arvalid),.s_axi_arready(arready),.s_axi_rid(rid),.s_axi_rdata(rdata),.s_axi_rresp(rresp),
      .s_axi_rlast(rlast),.s_axi_rvalid(rvalid),.s_axi_rready(rready),.ddr_ready(ddr_ready),.init_calib_complete(calib),
      .ddr_axi_response_error_sticky(resp_err),.ddr_axi_timeout_sticky(timeout_err),
      .c0_ddr4_act_n(act_n),.c0_ddr4_adr(adr),.c0_ddr4_ba(ba),.c0_ddr4_bg(bg),.c0_ddr4_cke(cke),.c0_ddr4_odt(odt),
      .c0_ddr4_cs_n(cs_n),.c0_ddr4_ck_t(ck_t),.c0_ddr4_ck_c(ck_c),.c0_ddr4_reset_n(reset_ddr_n),
      .c0_ddr4_dm_dbi_n(dm),.c0_ddr4_dq(dq),.c0_ddr4_dqs_c(dqs_c),.c0_ddr4_dqs_t(dqs_t)
    );

    task automatic fail(input [255:0] msg); begin $display("RTDS_DDR_BACKEND_SMOKE_FAIL: %0s",msg); $finish; end endtask
    task automatic send_aw(input [31:0] a,input [7:0] len,input [4:0] id); begin
      @(negedge clk); awaddr=a;awlen=len;awid=id;awvalid=1;
      while(!awready) @(posedge clk); @(negedge clk);awvalid=0;
    end endtask
    task automatic send_w(input [63:0] d,input last); begin
      @(negedge clk);wdata=d;wlast=last;wvalid=1;
      while(!wready) @(posedge clk);@(negedge clk);wvalid=0;wlast=0;
    end endtask
    task automatic wait_b(input [4:0] id); begin
      @(negedge clk);bready=1;while(!bvalid) @(posedge clk);
      if(bresp!==2'b00||bid!==id) fail("bad write response");
      @(negedge clk);bready=0;
    end endtask
    task automatic read_burst_check(input [31:0] a,input integer beats,input [4:0] id,input [63:0] base); integer i; begin
      @(negedge clk);araddr=a;arlen=beats-1;arid=id;arvalid=1;rready=1;
      while(!arready) @(posedge clk);@(negedge clk);arvalid=0;
      for(i=0;i<beats;i=i+1) begin
        while(!rvalid) @(posedge clk);
        if(rresp!==2'b00||rid!==id||rdata!==(base+i)) fail("read data/response mismatch");
        if(rlast!==(i==beats-1)) fail("RLAST mismatch");
        @(negedge clk);
      end
      rready=0;
    end endtask

    integer i;
    initial begin
      repeat(5) @(posedge clk);resetn=1;ddr_resetn=1;
      repeat(20) begin @(posedge clk); if(ddr_ready) begin $display("DDR_READY_AFTER_TWO_CYCLES_PASS"); break; end end
      if(!ddr_ready||!calib) fail("DDR ready/calibration did not assert");

      // W-first single-beat transaction proves AW/W channel independence.
      send_w(64'h1122_3344_5566_7788,1);
      send_aw(32'h0000_0000,0,5'h03);
      wait_b(5'h03);
      read_burst_check(32'h0000_0000,1,5'h03,64'h1122_3344_5566_7788);
      $display("W_FIRST_SINGLE_PASS");

      // Sixteen-beat INCR burst in the CPU->Aurora 0x8000 window.
      send_aw(32'h0000_8000,15,5'h12);
      for(i=0;i<16;i=i+1) send_w(64'hA500_0000_0000_0000+i,i==15);
      wait_b(5'h12);
      read_burst_check(32'h0000_8000,16,5'h12,64'hA500_0000_0000_0000);
      $display("INCR16_8000_PASS");

      if(resp_err||timeout_err) fail("unexpected sticky status");
      $display("RTDS_DDR_BACKEND_SMOKE_PASS");
      $finish;
    end
    initial begin #200000; fail("simulation timeout"); end
endmodule