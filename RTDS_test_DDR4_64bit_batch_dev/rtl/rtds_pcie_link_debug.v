`timescale 1ns/1ps
// Observation-only. VIO controls clear history / capture AXI, never functional reset.
module rtds_pcie_link_debug #(parameter integer BOARD_CYCLES_PER_MS=250000, parameter integer OBSERVER_HB_BIT=12, parameter integer OBSERVER_WATCHDOG_CYCLES=250000)(
 input wire board_clk,board_reset,pcie_clk,perst_n,qpll1_lock,user_lnk_up,axi_aresetn,ddr_ready,irq_req,
 input wire [5:0] ltssm,input wire [2:0] speed,input wire [3:0] width,
 input wire err_cor,err_nonfatal,err_fatal,local_error_valid,input wire [4:0] local_error,
 input wire [9:0] axi_flags,input wire [1:0] bresp,rresp,input wire wlast,rlast,
 input wire [7:0] wstrb,input wire [31:0] awaddr,araddr,input wire [63:0] wdata,rdata
);
 wire clear_vio,capture_axi_vio;
 reg clear_r=0,clear_prev=0,capture_axi_r=0,clear_toggle=0;
 wire clear_pulse=clear_r&&!clear_prev;
 always @(posedge board_clk) begin
  clear_r<=clear_vio;capture_axi_r<=capture_axi_vio;clear_prev<=clear_r;
  if(clear_pulse) clear_toggle<=!clear_toggle;
 end
 wire [7:0] base_live;wire [3:0] base_history;
 wire [15:0] ups,downs,persts;wire unused_event,perst_p,qpll_p;wire [31:0] ticks;
 rtds_pcie_link_observer #(.HB_BIT(OBSERVER_HB_BIT),.WATCHDOG_CYCLES(OBSERVER_WATCHDOG_CYCLES)) observer(
  .board_clk(board_clk),.board_reset(board_reset),.clear_history(clear_pulse),.pcie_clk(pcie_clk),
  .perst_n(perst_n),.qpll1_lock(qpll1_lock),.user_lnk_up(user_lnk_up),.axi_aresetn(axi_aresetn),
  .ddr_ready(ddr_ready),.ltssm(ltssm),.speed(speed),.width(width),.live_status(base_live),
  .history(base_history),.link_up_count(ups),.link_down_count(downs),.perst_assert_count(persts),
  .native_event(unused_event),.native_ticks(ticks),.perst_native(perst_p),.qpll_native(qpll_p));
 (* ASYNC_REG="TRUE" *) reg [1:0] ctl_meta=0,ctl_sync=0;
 always @(posedge pcie_clk) begin ctl_meta<={capture_axi_r,clear_toggle};ctl_sync<=ctl_meta;end
 reg clear_seen=0;wire clear_native=ctl_sync[0]!=clear_seen;
 reg [5:0] ltssm_r=0;reg [2:0] speed_r=0;reg [3:0] width_r=0;
 reg link_r=0,axi_reset_r=0;reg [8:0] errors_r=0;reg [215:0] axi_r=0;
 always @(posedge pcie_clk) begin
  // Native-domain taps. Multi-bit states remain coherent.
  ltssm_r<=ltssm;speed_r<=speed;width_r<=width;link_r<=user_lnk_up;axi_reset_r<=axi_aresetn;
  errors_r<={err_fatal,err_nonfatal,err_cor,local_error_valid,local_error};
  axi_r<={rdata,wdata,araddr,awaddr,wstrb,rlast,wlast,rresp,bresp,axi_flags};clear_seen<=ctl_sync[0];
 end
 wire [31:0] native_summary={6'b0,errors_r,qpll_p,perst_p,axi_reset_r,link_r,width_r,speed_r,ltssm_r};
 reg [31:0] summary_prev=0;reg first_native=1;
 wire state_event=first_native||(native_summary!=summary_prev);
 wire axi_activity=axi_r[0]||axi_r[2]||axi_r[4]||axi_r[6]||axi_r[8];
 wire capture_event=state_event||(ctl_sync[1]&&axi_activity);
 reg [63:0] seen_states=0;
 reg [15:0] transitions=0,cor_count=0,nonfatal_count=0,fatal_count=0,local_count=0,berror_count=0,rerror_count=0;
 reg [31:0] aw_count=0,ar_count=0,dwell=0;reg [5:0] ltssm_prev=0;
 always @(posedge pcie_clk) begin
  summary_prev<=native_summary;first_native<=0;ltssm_prev<=ltssm_r;
  if(clear_native) begin
   seen_states<=0;transitions<=0;cor_count<=0;nonfatal_count<=0;fatal_count<=0;local_count<=0;
   berror_count<=0;rerror_count<=0;aw_count<=0;ar_count<=0;dwell<=0;
  end else begin
   seen_states[ltssm_r]<=1'b1;
   if(ltssm_r!=ltssm_prev) begin dwell<=0;if(transitions!=16'hffff) transitions<=transitions+1'b1;end
   else if(dwell!=32'hffffffff) dwell<=dwell+1'b1;
   if(errors_r[6]&&cor_count!=16'hffff) cor_count<=cor_count+1'b1;
   if(errors_r[7]&&nonfatal_count!=16'hffff) nonfatal_count<=nonfatal_count+1'b1;
   if(errors_r[8]&&fatal_count!=16'hffff) fatal_count<=fatal_count+1'b1;
   if(errors_r[5]&&local_count!=16'hffff) local_count<=local_count+1'b1;
   if(axi_r[0]&&axi_r[1]&&aw_count!=32'hffffffff) aw_count<=aw_count+1'b1;
   if(axi_r[6]&&axi_r[7]&&ar_count!=32'hffffffff) ar_count<=ar_count+1'b1;
   if(axi_r[4]&&axi_r[5]&&axi_r[11:10]!=0&&berror_count!=16'hffff) berror_count<=berror_count+1'b1;
   if(axi_r[8]&&axi_r[9]&&axi_r[13:12]!=0&&rerror_count!=16'hffff) rerror_count<=rerror_count+1'b1;
  end
 end
 wire [127:0] native_counts={local_count,fatal_count,nonfatal_count,cor_count,ar_count,aw_count};
 wire [111:0] native_extra={dwell,rerror_count,berror_count,transitions,ticks};
 reg [335:0] send_data=0;reg send=0;wire received,dest_request;wire [335:0] dest_data;
 always @(posedge pcie_clk) begin
  if(!send&&!received) begin send_data<={seen_states,native_summary,native_counts,native_extra};send<=1;end
  else if(send&&received) send<=0;
 end
  // Held-bus handshake, never independently synchronize encoded state bits.
 xpm_cdc_handshake #(.DEST_EXT_HSK(0),.DEST_SYNC_FF(2),.SRC_SYNC_FF(2),.INIT_SYNC_FF(1),.SIM_ASSERT_CHK(1),.WIDTH(336)) snapshot_cdc(
  .src_clk(pcie_clk),.src_in(send_data),.src_send(send),.src_rcv(received),
  .dest_clk(board_clk),.dest_out(dest_data),.dest_req(dest_request),.dest_ack(1'b0));
 reg [335:0] snapshot=0,snapshot_vio=0;reg [15:0] snapshot_seq=0;
 reg [31:0] ms_div=0,uptime_ms=0,snapshot_age_ms=0;
 reg [31:0] first_link_ms=32'hffffffff,first_perst_high_ms=32'hffffffff;
 reg [15:0] pll_losses=0,axi_reset_falls=0;reg pll_prev=0,ar_prev=0;
 (* ASYNC_REG="TRUE" *) reg irq_meta=0,irq_sync=0;
 reg [15:0] live_vio=0;reg [3:0] history_vio=0;
 reg [15:0] ups_vio=0,downs_vio=0,persts_vio=0,pll_losses_vio=0,ar_falls_vio=0,seq_vio=0;
 reg [31:0] uptime_vio=0,age_vio=0,first_link_vio=0,first_perst_vio=0;
 always @(posedge board_clk) begin
  irq_meta<=irq_req;irq_sync<=irq_meta;pll_prev<=base_live[1];ar_prev<=base_live[4];
  if(board_reset) begin
   ms_div<=0;uptime_ms<=0;snapshot_age_ms<=0;snapshot_seq<=0;snapshot<=0;
   first_link_ms<=32'hffffffff;first_perst_high_ms<=32'hffffffff;pll_losses<=0;axi_reset_falls<=0;
  end else begin
   if(ms_div==BOARD_CYCLES_PER_MS-1) begin
    ms_div<=0;uptime_ms<=uptime_ms+1'b1;if(snapshot_age_ms!=32'hffffffff) snapshot_age_ms<=snapshot_age_ms+1'b1;
   end else ms_div<=ms_div+1'b1;
   if(dest_request) begin snapshot<=dest_data;snapshot_seq<=snapshot_seq+1'b1;snapshot_age_ms<=0;end
   if(clear_pulse) begin
    pll_losses<=0;axi_reset_falls<=0;first_link_ms<=32'hffffffff;first_perst_high_ms<=32'hffffffff;
   end else if(base_live[7]) begin
    if(base_live[3]&&first_link_ms==32'hffffffff) first_link_ms<=uptime_ms;
    if(base_live[0]&&first_perst_high_ms==32'hffffffff) first_perst_high_ms<=uptime_ms;
    if(!base_live[1]&&pll_prev&&pll_losses!=16'hffff) pll_losses<=pll_losses+1'b1;
    if(!base_live[4]&&ar_prev&&axi_reset_falls!=16'hffff) axi_reset_falls<=axi_reset_falls+1'b1;
   end
  end
  // Every VIO input gets an extra display register; every output was registered above.
  live_vio<={7'b0,irq_sync,base_live};history_vio<=base_history;ups_vio<=ups;downs_vio<=downs;
  persts_vio<=persts;pll_losses_vio<=pll_losses;ar_falls_vio<=axi_reset_falls;
  snapshot_vio<=snapshot;seq_vio<=snapshot_seq;uptime_vio<=uptime_ms;age_vio<=snapshot_age_ms;
  first_link_vio<=first_link_ms;first_perst_vio<=first_perst_high_ms;
 end
 reg [5:0] ila_ltssm=0;reg [2:0] ila_speed=0;reg [3:0] ila_width=0;
 reg [4:0] ila_flags=0;reg [8:0] ila_errors=0;reg [31:0] ila_ticks=0;reg [215:0] ila_axi=0;
 always @(posedge pcie_clk) begin
  // Trigger and payload are retimed together, including diagnostic event.
  ila_ltssm<=ltssm_r;ila_speed<=speed_r;ila_width<=width_r;
  ila_flags<={capture_event,qpll_p,perst_p,axi_reset_r,link_r};
  ila_errors<=errors_r;ila_ticks<=ticks;ila_axi<=axi_r;
 end
 vio_pcie_link_diag vio(.clk(board_clk),.probe_in0(live_vio),.probe_in1(history_vio),
  .probe_in2(ups_vio),.probe_in3(downs_vio),.probe_in4(persts_vio),.probe_in5(pll_losses_vio),
  .probe_in6(uptime_vio),.probe_in7(snapshot_vio[271:240]),.probe_in8(snapshot_vio[335:272]),
  .probe_in9(snapshot_vio[239:112]),.probe_in10(snapshot_vio[111:0]),.probe_in11(seq_vio),
  .probe_in12(age_vio),.probe_in13(first_link_vio),.probe_in14(first_perst_vio),.probe_in15(ar_falls_vio),
  .probe_out0(clear_vio),.probe_out1(capture_axi_vio));
 ila_pcie_link_diag ila(.clk(pcie_clk),.probe0(ila_ltssm),.probe1(ila_flags[0]),.probe2(ila_flags[1]),
  .probe3(ila_flags[2]),.probe4(ila_flags[3]),.probe5(ila_speed),.probe6(ila_width),
  .probe7(ila_flags[4]),.probe8(ila_ticks),.probe9(ila_errors),.probe10(ila_axi));
endmodule
