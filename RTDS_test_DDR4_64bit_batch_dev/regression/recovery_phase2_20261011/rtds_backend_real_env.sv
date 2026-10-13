`timescale 1ns/1ps   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
// 修改记录 2026-10-11：改用module包装以兼容Vivado 2020.2的例化限制，直接驱动真实DDR后端的公开AXI接口，模型只负责存储。
module rtds_backend_real_env(input logic clk);   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
 logic rst_n=0,ddr_rst_n=1,clear_status=0;   // 2026-10-11：主机复位和DDR复位分别控制
 logic[4:0] awid=0,arid=0;   // 2026-10-11：覆盖五位ID，区分旧事务和新事务
 logic[31:0] awaddr=0,araddr=0;   // 2026-10-11：模型字节地址
 logic[7:0] awlen=0,arlen=0;   // 2026-10-11：支持一至256拍突发
 logic awvalid=0,wvalid=0,arvalid=0,bready=0,rready=0;   // 2026-10-11：五通道独立驱动
 logic[63:0] wdata=0;   // 2026-10-11：写数据在被接受前保持
 logic[7:0] wstrb=8'hff;   // 2026-10-11：支持完整写拍和低四字节尾拍
 logic wlast=0;   // 2026-10-11：驱动突发最后一拍
 wire awready,wready,bvalid,arready,rvalid,rlast;   // 2026-10-11：真实后端握手输出
 wire[4:0] bid,rid;   // 2026-10-11：真实响应ID
 wire[1:0] bresp,rresp;   // 2026-10-11：真实响应码
 wire[63:0] rdata;   // 2026-10-11：真实读数据
 wire ready,calib,response_error,timeout_error;   // 2026-10-11：分别观察就绪、校准及诊断

 logic ref_clk=0;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 always #4.998 ref_clk=~ref_clk;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 wire act_n,reset_n;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 wire[16:0] adr;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 wire[1:0] ba;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 wire[0:0] bg,cke,odt,cs_n,ck_t,ck_c;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 wire[7:0] dm,dqs_t,dqs_c;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 wire[63:0] dq;   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 rtds_ddr4_backend #(.AXI_ID_WIDTH(5),.TIMEOUT_CYCLES(64)) U_DDR (   // 2026-10-11：使用当前活动业务RTL
 .s_axi_aclk(clk),.s_axi_aresetn(rst_n),.ddr_sys_clk_i(ref_clk),.ddr_sys_rst_n(ddr_rst_n),.clear_status(clear_status),   // 2026-10-11：两个复位范围分开
 .s_axi_awid(awid),.s_axi_awaddr(awaddr),.s_axi_awlen(awlen),.s_axi_awsize(3'd3),.s_axi_awburst(2'd1),   // 2026-10-11：64bit INCR写突发
 .s_axi_awlock(1'b0),.s_axi_awcache(4'd0),.s_axi_awprot(3'd0),.s_axi_awregion(4'd0),.s_axi_awqos(4'd0),   // 2026-10-11：不启用锁定和特殊属性
 .s_axi_awvalid(awvalid),.s_axi_awready(awready),.s_axi_wdata(wdata),.s_axi_wstrb(wstrb),.s_axi_wlast(wlast),   // 2026-10-11：地址和数据分别握手
 .s_axi_wvalid(wvalid),.s_axi_wready(wready),.s_axi_bid(bid),.s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready),   // 2026-10-11：写完成以B响应为准
 .s_axi_arid(arid),.s_axi_araddr(araddr),.s_axi_arlen(arlen),.s_axi_arsize(3'd3),.s_axi_arburst(2'd1),   // 2026-10-11：64bit INCR读突发
 .s_axi_arlock(1'b0),.s_axi_arcache(4'd0),.s_axi_arprot(3'd0),.s_axi_arregion(4'd0),.s_axi_arqos(4'd0),   // 2026-10-11：读属性保持固定
 .s_axi_arvalid(arvalid),.s_axi_arready(arready),.s_axi_rid(rid),.s_axi_rdata(rdata),.s_axi_rresp(rresp),   // 2026-10-11：按原ID和长度检查读响应
 .s_axi_rlast(rlast),.s_axi_rvalid(rvalid),.s_axi_rready(rready),.ddr_ready(ready),.init_calib_complete(calib),   // 2026-10-11：校准与业务就绪分开观察
 .ddr_axi_response_error_sticky(response_error),.ddr_axi_timeout_sticky(timeout_error),   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 .c0_ddr4_act_n(act_n),.c0_ddr4_adr(adr),.c0_ddr4_ba(ba),.c0_ddr4_bg(bg),   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 .c0_ddr4_cke(cke),.c0_ddr4_odt(odt),.c0_ddr4_cs_n(cs_n),.c0_ddr4_ck_t(ck_t),.c0_ddr4_ck_c(ck_c),   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
 .c0_ddr4_reset_n(reset_n),.c0_ddr4_dm_dbi_n(dm),.c0_ddr4_dq(dq),.c0_ddr4_dqs_t(dqs_t),.c0_ddr4_dqs_c(dqs_c)   // 2026-10-11：错误诊断由真实后端产生
 );   // 2026-10-11：物理引脚在RAM模型配置下不参与检查
 bit r_stalled=0,b_stalled=0;   // 2026-10-11：上一拍反压状态
 logic[71:0] r_held;   // 2026-10-11：DATA64、ID5、RESP2、LAST1完整快照
 logic[6:0] b_held;   // 2026-10-11：BID5与BRESP2完整快照
 always @(posedge clk) begin   // 2026-10-11：独立协议监测，DDR复位期间仍检查展示响应
   if(!rst_n) begin r_stalled=0;b_stalled=0;end   // 2026-10-11：仅主机接口复位免除保持义务
   else begin   // 2026-10-11：DDR不可用不免除上游接口保持义务
     if(r_stalled && (!rvalid || {rdata,rid,rresp,rlast}!==r_held)) $fatal(1,"BACKEND/R_STALL_CHANGED");   // 2026-10-11：检查读响应反压稳定
     if(b_stalled && (!bvalid || {bid,bresp}!==b_held)) $fatal(1,"BACKEND/B_STALL_CHANGED");   // 2026-10-11：检查写响应反压稳定
     r_stalled=rvalid&&!rready;b_stalled=bvalid&&!bready;   // 2026-10-11：保存本拍反压条件
     r_held={rdata,rid,rresp,rlast};b_held={bid,bresp};   // 2026-10-11：保存全部响应字段
   end   // 2026-10-11：完成协议监测
 end   // 2026-10-11：监测以真实总线时钟为准
 rtds_ddr4_physical_peer MEM(.act_n(act_n),.adr(adr),.ba(ba),.bg(bg),.cke(cke),.odt(odt),.cs_n(cs_n),.ck_t(ck_t),.ck_c(ck_c),.reset_n(reset_n),.dq(dq),.dm(dm),.dqs_t(dqs_t),.dqs_c(dqs_c));   // 2026-10-11：真实MIG恢复验证，物理接线依据官方示例
endmodule   // 2026-10-11：新增恢复验证：按真实握手检查长度、ID、数据与中断边界
