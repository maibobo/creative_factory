`timescale 1ns/1ps
// Test boundary: real INFO_EXCH/adapter/CONV_DMA/DDR backend and real 1G TX.
// DDR_SIM_RAM; CPU preload and C2H master are behavioral. No GT/XDMA/board proof.
// 修改点 2026-10-13：专用VIO冒烟封装，JTAG控制以同域start激励替代。
module rtds_vio_harness #(parameter integer RX_VIO_TEST_ENABLE=1);
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 logic vio_start=0;
 wire vio_busy;wire[1:0] vio_accepted;wire[3:0] vio_status;
 logic clk=0,uclk=0,gclk=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 bit user_clock_enable=1;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 real user_half_period=3.2;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 bit random_tx_ready=1;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 always #2 clk=~clk;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 initial begin   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   #(0.1*phase2_pick(0,31));   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   forever begin #(user_half_period); if(user_clock_enable) uclk=~uclk; end   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 end   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 always #16 gclk=~gclk;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 rtds_regs_test_if regbus(clk);
 wire rst_n=regbus.rst_n;
 logic pcie_up=1,channel_up=1,lane_up=1,ddr_reset_n=1,tx_ready=1;
 always @(negedge uclk) if(rst_n && random_tx_ready) tx_ready<=phase2_pick(0,9)<7;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 logic[63:0] rx_data=0; logic rx_valid=0,rx_sof=1,rx_eof=1; wire rx_ready;
 wire[63:0] tx_data;wire tx_sof,tx_eof,tx_valid;wire[2:0] tx_rem;
 wire[63:0] fdma_raddr,fdma_rdata,fdma_waddr,fdma_wdata;
 wire[15:0] fdma_rsize,fdma_wsize;wire[7:0] fdma_wstrb;
 wire fdma_rareq,fdma_rbusy,fdma_rvalid,fdma_rready,fdma_wareq,fdma_wbusy,fdma_wvalid,fdma_waccept,fdma_wdone,fdma_werror;
 wire[31:0] head_addr,head_len,head_seq,ready_blocks,dropped_words;
 wire int_state,rec_state,irq,overflow,overrun,underflow,fdma_timeout,length_error,link_error,rx_pending;
 wire[3:0] tx_state,rx_state;wire fifo_afull,fifo_full,done_event,done_resp;
 wire[7:0] cfg_byte;wire cfg_valid;
 wire ddr_ready,calib,response_error,ddr_timeout;
 // Exact DDR_STATUS concatenation from PCIe.v, not a synthetic register model.
 wire[31:0] ddr_status={27'd0,(ddr_timeout|fdma_timeout),overflow,response_error,calib,ddr_ready};
 INFO_EXCH U_REG (
 .CPU_WR_DONE_EVENT(done_event),.FPGA_TEMP_W(32'd0),.INT_STATE_W(int_state),.CPU_REC_STATE_W(rec_state),
 .FPGA_CPU_START_ADDR(head_addr),.FPGA_CPU_LEN(head_len),.CPU_WR_DONE_resp(done_resp),.DDR_STATUS_W(ddr_status),
 .RX_READY_BLOCKS(ready_blocks),.RX_HEAD_SEQ(head_seq),.RX_DROPPED_FRAMES(dropped_words),
 .r_INT_STATE(regbus.clear_irq),.r_CLEAR_INTER(regbus.clear_inter),.r_CPU_REC_STATE(regbus.ack),.r_RD_START(regbus.start),
 .r_CPU_FPGA_START_ADDR(regbus.command_addr),.r_CPU_FPGA_LEN(regbus.command_len),.S_AXI_ACLK(clk),.S_AXI_ARESETN(rst_n),
 .S_AXI_AWADDR(regbus.awaddr),.S_AXI_AWPROT(3'd0),.S_AXI_AWVALID(regbus.awvalid),.S_AXI_AWREADY(regbus.awready),
 .S_AXI_WDATA(regbus.wdata),.S_AXI_WSTRB(regbus.wstrb),.S_AXI_WVALID(regbus.wvalid),.S_AXI_WREADY(regbus.wready),
 .S_AXI_BRESP(regbus.bresp),.S_AXI_BVALID(regbus.bvalid),.S_AXI_BREADY(regbus.bready),
 .S_AXI_ARADDR(regbus.araddr),.S_AXI_ARPROT(3'd0),.S_AXI_ARVALID(regbus.arvalid),.S_AXI_ARREADY(regbus.arready),
 .S_AXI_RDATA(regbus.rdata),.S_AXI_RRESP(regbus.rresp),.S_AXI_RVALID(regbus.rvalid),.S_AXI_RREADY(regbus.rready));
 pcie_fdma_aurora_brg_adapter #(.RX_VIO_TEST_ENABLE(RX_VIO_TEST_ENABLE),.RX_PERIOD_CYCLES(2000),.FDMA_TIMEOUT_CYCLES(256)) U_ADAPTER (
 .rx_test_start(vio_start),.rx_test_busy(vio_busy),.rx_test_accepted(vio_accepted),.rx_test_status(vio_status),
 .fdma_clk(clk),.fdma_rstn(rst_n),.aurora_user_clk(uclk),.aurora_user_rstn(rst_n),
 .pcie_link_up(pcie_up),.ddr_ready(ddr_ready),.aurora_channel_up(channel_up),.aurora_lane_up(lane_up),
 .aurora_tx_d(tx_data),.aurora_tx_sof(tx_sof),.aurora_tx_eof(tx_eof),.aurora_tx_rem(tx_rem),.aurora_tx_src_rdy(tx_valid),.aurora_tx_dst_rdy(tx_ready),
 .aurora_rx_d(rx_data),.aurora_rx_sof(rx_sof),.aurora_rx_eof(rx_eof),.aurora_rx_rem(3'd7),.aurora_rx_src_rdy(rx_valid),.aurora_rx_dst_rdy(rx_ready),
 .rd_start(regbus.start),.cpu_fpga_start_addr(regbus.command_addr),.cpu_fpga_len(regbus.command_len),
 .cpu_wr_done_event(done_event),.cpu_wr_done_resp(done_resp),.fdma_wstrb(fdma_wstrb),
 .fpga_cpu_start_addr(head_addr),.fpga_cpu_len(head_len),.int_state_w(int_state),.int_state_clear(regbus.clear_irq),
 .clear_inter(regbus.clear_inter),.cpu_rec_state_r(regbus.ack),.cpu_rec_state_w(rec_state),.fpga_cpu_irq_req(irq),
 .fdma_raddr(fdma_raddr),.fdma_rareq(fdma_rareq),.fdma_rbusy(fdma_rbusy),.fdma_rdata(fdma_rdata),.fdma_rvalid(fdma_rvalid),.fdma_rready(fdma_rready),.fdma_rsize(fdma_rsize),
 .fdma_waddr(fdma_waddr),.fdma_wareq(fdma_wareq),.fdma_wbusy(fdma_wbusy),.fdma_wdone(fdma_wdone),.fdma_werror(fdma_werror),
 .rx_ready_blocks(ready_blocks),.rx_head_seq(head_seq),.rx_dropped_frames(dropped_words),.cfg_byte(cfg_byte),.cfg_byte_valid(cfg_valid),
 .fdma_wdata(fdma_wdata),.fdma_wvalid(fdma_wvalid),.fdma_wready(fdma_waccept),.fdma_wsize(fdma_wsize),
 .rx_fifo_almost_full(fifo_afull),.rx_fifo_full(fifo_full),.rx_overflow_sticky(overflow),.rx_overrun_sticky(overrun),
 .tx_underflow_sticky(underflow),.fdma_timeout_sticky(fdma_timeout),.length_error_sticky(length_error),.link_down_sticky(link_error),
 .rx_pending(rx_pending),.dbg_tx_state(tx_state),.dbg_rx_state(rx_state));
 wire tick_2us,gpio_50us;wire[31:0] gdata;wire[1:0] grem;wire gsof,geof,gvalid,configured;wire[7:0] configured_id;wire[31:0] skipped;
 RTDS_SYNC_TIMEBASE U_TIME (.clk_250m(clk),.rst_n(rst_n),.tick_toggle_2us(tick_2us),.cpu_sync_50us(gpio_50us));
 RTDS_1G_PERIODIC_TX U_1G (.clk_250m(clk),.tick_toggle_2us(tick_2us),.rst_n(rst_n),.cfg_byte(cfg_byte),.cfg_byte_valid(cfg_valid),   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
 .user_clk(gclk),.user_reset(!rst_n),.channel_up(channel_up),.tx_ready(1'b1),.tx_data(gdata),.tx_rem(grem),
 .tx_sof(gsof),.tx_eof(geof),.tx_valid(gvalid),.configured(configured),.configured_id(configured_id),.skipped_periods(skipped));
 logic fault_read=0,fault_write=0,hold_r=0,hold_b=0;
 logic cpu_read_mode=0,cpu_arvalid=0,cpu_rready=0;logic[31:0] cpu_araddr=0;
 wire cpu_arready,cpu_rvalid,cpu_rlast;wire[63:0] cpu_rdata;wire[1:0] cpu_rresp;
 wire a_awid;
 wire [63:0] a_awaddr;
 wire [7:0] a_awlen;
 wire [2:0] a_awsize;
 wire [1:0] a_awburst;
 wire a_awlock;
 wire [3:0] a_awcache;
 wire [2:0] a_awprot;
 wire [3:0] a_awqos;
 wire a_awvalid;
 wire a_awready;
 wire a_wid;
 wire [63:0] a_wdata;
 wire [7:0] a_wstrb;
 wire a_wlast;
 wire a_wvalid;
 wire a_wready;
 wire a_bid;
 wire [1:0] a_bresp;
 wire a_bvalid;
 wire a_bready;
 wire a_arid;
 wire [63:0] a_araddr;
 wire [7:0] a_arlen;
 wire [2:0] a_arsize;
 wire [1:0] a_arburst;
 wire a_arlock;
 wire [3:0] a_arcache;
 wire [2:0] a_arprot;
 wire [3:0] a_arqos;
 wire a_arvalid;
 wire a_arready;
 wire a_rid;
 wire [63:0] a_rdata;
 wire [1:0] a_rresp;
 wire a_rlast;
 wire a_rvalid;
 wire a_rready;
 CONV_DMA U_DMA (
.fdma_wstrb(fdma_wstrb),.fdma_wdone(fdma_wdone),.fdma_werror(fdma_werror),.fdma_waddr(fdma_waddr),.fdma_wareq(fdma_wareq),.fdma_wsize(fdma_wsize),.fdma_wbusy(fdma_wbusy),.fdma_wdata(fdma_wdata),.fdma_wvalid(fdma_waccept),.fdma_wready(fdma_wvalid),.fdma_raddr(fdma_raddr),.fdma_rareq(fdma_rareq),.fdma_rsize(fdma_rsize),.fdma_rbusy(fdma_rbusy),.fdma_rdata(fdma_rdata),.fdma_rvalid(fdma_rvalid),.fdma_rready(fdma_rready),
.M_AXI_AWID(a_awid),.M_AXI_AWADDR(a_awaddr),.M_AXI_AWLEN(a_awlen),.M_AXI_AWSIZE(a_awsize),.M_AXI_AWBURST(a_awburst),.M_AXI_AWLOCK(a_awlock),.M_AXI_AWCACHE(a_awcache),.M_AXI_AWPROT(a_awprot),.M_AXI_AWQOS(a_awqos),.M_AXI_AWVALID(a_awvalid),.M_AXI_AWREADY(a_awready),.M_AXI_WID(a_wid),.M_AXI_WDATA(a_wdata),.M_AXI_WSTRB(a_wstrb),.M_AXI_WLAST(a_wlast),.M_AXI_WVALID(a_wvalid),.M_AXI_WREADY(a_wready),.M_AXI_BID(a_bid),.M_AXI_BRESP(a_bresp),.M_AXI_BVALID(a_bvalid),.M_AXI_BREADY(a_bready),.M_AXI_ARID(a_arid),.M_AXI_ARADDR(a_araddr),.M_AXI_ARLEN(a_arlen),.M_AXI_ARSIZE(a_arsize),.M_AXI_ARBURST(a_arburst),.M_AXI_ARLOCK(a_arlock),.M_AXI_ARCACHE(a_arcache),.M_AXI_ARPROT(a_arprot),.M_AXI_ARQOS(a_arqos),.M_AXI_ARVALID(a_arvalid),.M_AXI_ARREADY(a_arready),.M_AXI_RID(a_rid),.M_AXI_RDATA(a_rdata),.M_AXI_RRESP(a_rresp),.M_AXI_RLAST(a_rlast),.M_AXI_RVALID(a_rvalid),.M_AXI_RREADY(a_rready),.M_AXI_ACLK(clk),.M_AXI_ARESETN(rst_n));
 wire b_arready,b_rvalid,b_rlast,b_bvalid;wire[63:0] b_rdata;wire[1:0] b_rresp,b_bresp;wire b_bid,b_rid;
 assign a_arready=!cpu_read_mode && b_arready;
 assign a_rvalid=!cpu_read_mode && !hold_r && b_rvalid;
 assign a_rdata=b_rdata;assign a_rresp=b_rresp;assign a_rlast=b_rlast;assign a_rid=b_rid;
 assign a_bvalid=!hold_b && b_bvalid;assign a_bresp=b_bresp;assign a_bid=b_bid;
 assign cpu_arready=cpu_read_mode && b_arready;
 assign cpu_rvalid=cpu_read_mode && b_rvalid;assign cpu_rdata=b_rdata;assign cpu_rresp=b_rresp;assign cpu_rlast=b_rlast;
 rtds_ddr4_backend #(.AXI_ID_WIDTH(1),.TIMEOUT_CYCLES(256)) U_DDR (.s_axi_aclk(clk),.s_axi_aresetn(rst_n),.ddr_sys_clk_i(clk),.ddr_sys_rst_n(ddr_reset_n),.clear_status(regbus.clear_inter),
.s_axi_awid(a_awid),.s_axi_awaddr(fault_write ? 32'h00800000 : a_awaddr[31:0]),.s_axi_awlen(a_awlen),.s_axi_awsize(a_awsize),.s_axi_awburst(a_awburst),.s_axi_awlock(a_awlock),.s_axi_awcache(a_awcache),.s_axi_awprot(a_awprot),.s_axi_awqos(a_awqos),.s_axi_awvalid(a_awvalid),.s_axi_awready(a_awready),.s_axi_wdata(a_wdata),.s_axi_wstrb(a_wstrb),.s_axi_wlast(a_wlast),.s_axi_wvalid(a_wvalid),.s_axi_wready(a_wready),.s_axi_bid(b_bid),.s_axi_bresp(b_bresp),.s_axi_bvalid(b_bvalid),.s_axi_bready(a_bready && !hold_b),.s_axi_arid(a_arid),.s_axi_araddr(cpu_read_mode ? cpu_araddr : (fault_read ? 32'h00800000 : a_araddr[31:0])),.s_axi_arlen(cpu_read_mode ? 8'd0 : a_arlen),.s_axi_arsize(3'd3),.s_axi_arburst(2'd1),.s_axi_arlock(a_arlock),.s_axi_arcache(a_arcache),.s_axi_arprot(a_arprot),.s_axi_arqos(a_arqos),.s_axi_arvalid(cpu_read_mode ? cpu_arvalid : a_arvalid),.s_axi_arready(b_arready),.s_axi_rid(b_rid),.s_axi_rdata(b_rdata),.s_axi_rresp(b_rresp),.s_axi_rlast(b_rlast),.s_axi_rvalid(b_rvalid),.s_axi_rready(cpu_read_mode ? cpu_rready : (a_rready && !hold_r)),.s_axi_awregion(4'd0),.s_axi_arregion(4'd0),
.ddr_ready(ddr_ready),.init_calib_complete(calib),.ddr_axi_response_error_sticky(response_error),.ddr_axi_timeout_sticky(ddr_timeout));
 int read_beats=0,read_requests=0,tx_beats=0,tx_frames=0,cfg_pulses=0,done_events=0,acks=0;
 logic check_tx=0;int expected_tx_base=0,expected_tx_len=0,expected_seed=0;logic[7:0] expected_byte1=0;
 function automatic logic[63:0] tx_pattern(input int offset);
   logic[63:0] v;v={32'(expected_seed+offset+1),32'(expected_seed+offset)};
   if((offset%2)==0) v[15:8]=expected_byte1;
   return v;
 endfunction
 always @(posedge clk) if(rst_n) begin
   if(fdma_rareq && !fdma_rbusy) begin
     if(check_tx && (fdma_rsize!=2 || fdma_raddr!=expected_tx_base+read_requests*16)) $fatal(1,"REAL/REQUEST addr=%h n=%0d",fdma_raddr,read_requests);
     read_requests++;
   end
   if(fdma_rvalid && fdma_rready) read_beats++;
   if(cfg_valid) begin
     if(check_tx && cfg_byte!=expected_byte1) $fatal(1,"REAL/BYTE1");cfg_pulses++;
   end
   if(done_event) done_events++;
   if(regbus.ack) acks++;
 end
 always @(posedge uclk) if(rst_n && tx_valid && tx_ready) begin
   if(check_tx && (tx_data!==tx_pattern(tx_beats) || tx_rem!=7 || tx_sof!=(tx_beats%2==0) || tx_eof!=(tx_beats%2==1)))
     $fatal(1,"REAL/TX beat=%0d data=%h expected=%h sof=%b eof=%b",tx_beats,tx_data,tx_pattern(tx_beats),tx_sof,tx_eof);
   tx_beats++;if(tx_eof) tx_frames++;
 end
 task automatic reset(input bit initial_ddr_ready=1);
   @(regbus.driver_cb);regbus.driver_cb.rst_n<=0;
   vio_start=0;pcie_up=1;channel_up=1;lane_up=1;ddr_reset_n=initial_ddr_ready;tx_ready=1;hold_r=0;hold_b=0;fault_read=0;fault_write=0;rx_valid=0;
   repeat(100) @(regbus.driver_cb);regbus.driver_cb.rst_n<=1;
   repeat(200) @(regbus.driver_cb);
   read_beats=0;read_requests=0;tx_beats=0;tx_frames=0;cfg_pulses=0;done_events=0;acks=0;
 endtask
 task automatic wr(input int address,input int value,input logic[3:0] strobe=4'hf);
   repeat(phase2_pick(0,3)) @(regbus.driver_cb);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   @(regbus.driver_cb);regbus.driver_cb.awaddr<=address;regbus.driver_cb.wdata<=value;regbus.driver_cb.wstrb<=strobe;
   regbus.driver_cb.awvalid<=1;regbus.driver_cb.wvalid<=1;
   do @(regbus.driver_cb);while(!(regbus.driver_cb.awready && regbus.driver_cb.wready));
   regbus.driver_cb.awvalid<=0;regbus.driver_cb.wvalid<=0;
   do @(regbus.driver_cb);while(!regbus.driver_cb.bvalid);
   if(regbus.driver_cb.bresp!=0) $fatal(1,"REAL/REG_WRITE");
 endtask
 task automatic rd(input int address,output logic[31:0] value);
   repeat(phase2_pick(0,3)) @(regbus.driver_cb);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   @(regbus.driver_cb);regbus.driver_cb.araddr<=address;regbus.driver_cb.arvalid<=1;
   do @(regbus.driver_cb);while(!regbus.driver_cb.arready);
   regbus.driver_cb.arvalid<=0;
   do @(regbus.driver_cb);while(!regbus.driver_cb.rvalid);
   if(regbus.driver_cb.rresp!=0) $fatal(1,"REAL/REG_READ");
   value=regbus.driver_cb.rdata;
 endtask
 task automatic check_reg(input int address,input int expected);
   logic[31:0] got;rd(address,got);if(got!==32'(expected)) $fatal(1,"REAL/REG addr=%h got=%h expected=%h",address,got,expected);
 endtask
 task automatic wait_end;
   logic[31:0] busy;
   for(int i=0;i<100000;i++) begin rd('h20,busy);if(busy==0) begin repeat(100) @(regbus.driver_cb);return;end end
   $fatal(1,"REAL/COMMAND_TIMEOUT");
 endtask
 task automatic prepare_tx(input int addr,input int len,input int seed,input logic[7:0] id);
   expected_tx_base=addr;expected_tx_len=len;expected_seed=seed^phase2_pick(1,1048575);expected_byte1=id;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   read_beats=0;read_requests=0;tx_beats=0;tx_frames=0;cfg_pulses=0;done_events=0;
   for(int i=0;i<len/8;i++) U_DDR.u_sim_ram.mem[addr/8+i]=tx_pattern(i);
 endtask
 task automatic command(input int addr,input int len);wr('h24,addr);wr('h28,len);wr('h20,1);endtask
 task automatic valid_tx(input int addr,input int len,input int seed,input logic[7:0] id);
   prepare_tx(addr,len,seed,id);check_tx=1;command(addr,len);wait_end();
   if(read_beats!=len/8 || tx_beats!=len/8 || tx_frames!=len/16 || cfg_pulses!=len/16 || done_events!=1 || read_requests!=len/16)
     $fatal(1,"REAL/COUNTS bytes=%0d r=%0d tx=%0d frames=%0d cfg=%0d done=%0d requests=%0d",len,read_beats,tx_beats,tx_frames,cfg_pulses,done_events,read_requests);
   $display("TX_CHECK addr=%h length=%0d end=%h frames=%0d beats=%0d",addr,len,addr+len,tx_frames,tx_beats);
   check_tx=0;
 endtask
 task automatic send_rx(input int value);
   repeat(phase2_pick(0,3)) @(negedge uclk);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
   @(negedge uclk);rx_data={32'hdeadbeef,32'(value)};rx_valid=1;
   @(negedge uclk);rx_valid=0;
 endtask
 task automatic cpu_read64(input int address,output logic[63:0] value);
   if(fdma_rbusy || fdma_rareq) $fatal(1,"REAL/CPU_READ_CONFLICT");
   @(negedge clk);cpu_read_mode=1;cpu_araddr=address;cpu_arvalid=1;cpu_rready=1;
   do @(posedge clk);while(!cpu_arready);
   @(negedge clk);cpu_arvalid=0;
   do @(posedge clk);while(!cpu_rvalid);
   if(cpu_rresp!=0 || !cpu_rlast) $fatal(1,"REAL/C2H_RESPONSE");value=cpu_rdata;
   @(negedge clk);cpu_rready=0;cpu_read_mode=0;
 endtask
endmodule
