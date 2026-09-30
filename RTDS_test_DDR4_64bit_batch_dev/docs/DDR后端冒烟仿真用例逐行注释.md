# DDR 后端冒烟仿真用例逐行注释


```systemverilog
`timescale 1ns/1ps // 仿真时间单位为 1ns，时间精度为 1ps。
`define DDR4_SIM_RAM // 选择被测模块的行为 AXI RAM 分支，避免真实 MIG 依赖。
    reg clk=0, ddr_clk=0, resetn=0, ddr_resetn=0, clear_status=0; // 声明控制时钟、DDR系统时钟、两路低有效复位和状态清除输入，并初始化。
    always #2 clk=~clk; // 每 2ns 翻转控制时钟，得到周期为 4ns、频率为 250MHz 的 s_axi_aclk。
    always #5 ddr_clk=~ddr_clk; // 每 5ns 翻转 DDR 系统时钟，得到周期为 10ns、频率为 100MHz 的 ddr_sys_clk_i；在 SIM_RAM 分支仅作接口输入。

    reg [4:0] awid=0, arid=0; // 声明 AXI 写地址和读地址通道 ID，由测试平台驱动。
    reg [31:0] awaddr=0, araddr=0; // 声明 AXI 写、读起始字节地址。
    reg [7:0] awlen=0, arlen=0; // 声明突发长度减一；0 表示单拍，15 表示 16 拍。
    reg [2:0] awsize=3, arsize=3; // 设置每拍大小为 2^3=8 字节，对应 64 位数据总线。
    reg [1:0] awburst=1, arburst=1; // 设置突发类型为 2'b01，即 AXI INCR 递增地址突发。
    reg [0:0] awlock=0, arlock=0; // 设置 AXI 独占锁属性为普通访问。
    reg [3:0] awcache=0, arcache=0, awregion=0, arregion=0, awqos=0, arqos=0; // 将缓存、区域和服务质量属性清零，使用普通默认事务。
    reg [2:0] awprot=0, arprot=0; // 将保护属性清零，使用默认数据访问属性。
    reg awvalid=0, wvalid=0, bready=0, arvalid=0, rready=0; // 声明并初始化测试平台驱动的五条 AXI valid/ready 握手控制信号。
    reg [63:0] wdata=0; // 声明 64 位写数据。
    reg [7:0] wstrb=8'hff; // 使能全部 8 个字节写选通，表示整拍写入。
    reg wlast=0; // 声明写数据通道的突发末拍标记。
    wire awready,wready,bvalid,arready,rlast,rvalid; // 声明由被测模块返回的 AXI 握手与读末拍信号。
    wire [4:0] bid,rid; // 声明由被测模块返回的写、读响应 ID。
    wire [1:0] bresp,rresp; // 声明由被测模块返回的写、读响应码。
    wire [63:0] rdata; // 声明由被测模块返回的 64 位读数据。
    wire ddr_ready,calib,resp_err,timeout_err; // 声明后端就绪、校准完成和两类粘滞错误状态输出。
    wire act_n,reset_ddr_n; // 声明真实 DDR4 物理接口的单比特输出；SIM_RAM 模式下只用于完成端口连接。
    wire [16:0] adr; // 声明 DDR4 地址物理接口；SIM_RAM 模式下不参与存储访问。
    wire [1:0] ba; // 声明 DDR4 Bank 地址物理接口。
    wire [0:0] bg,cke,odt,cs_n,ck_t,ck_c; // 声明 DDR4 Bank Group、时钟使能、终端、片选和差分时钟物理接口。
    wire [7:0] dm,dqs_c,dqs_t; // 声明 DDR4 数据掩码/DBI 和差分数据选通物理接口。
    wire [63:0] dq; // 声明 DDR4 数据物理接口；SIM_RAM 模式下为高阻，不参与本用例数据通路。

      .s_axi_aclk(clk),.s_axi_aresetn(resetn),.ddr_sys_clk_i(ddr_clk),.ddr_sys_rst_n(ddr_resetn),.clear_status(clear_status), // 连接控制时钟/复位、DDR系统时钟/复位和状态清除输入。
      .s_axi_awid(awid),.s_axi_awaddr(awaddr),.s_axi_awlen(awlen),.s_axi_awsize(awsize),.s_axi_awburst(awburst), // 连接 AXI 写地址通道的 ID、地址、长度、拍大小和突发类型。
      .s_axi_awlock(awlock),.s_axi_awcache(awcache),.s_axi_awprot(awprot),.s_axi_awregion(awregion),.s_axi_awqos(awqos), // 连接 AXI 写地址通道的锁、缓存、保护、区域和 QoS 属性。
      .s_axi_awvalid(awvalid),.s_axi_awready(awready),.s_axi_wdata(wdata),.s_axi_wstrb(wstrb),.s_axi_wlast(wlast), // 连接写地址握手及写数据、字节选通和末拍标记。
      .s_axi_wvalid(wvalid),.s_axi_wready(wready),.s_axi_bid(bid),.s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready), // 连接写数据握手和写响应通道。
      .s_axi_arid(arid),.s_axi_araddr(araddr),.s_axi_arlen(arlen),.s_axi_arsize(arsize),.s_axi_arburst(arburst), // 连接 AXI 读地址通道的 ID、地址、长度、拍大小和突发类型。
      .s_axi_arlock(arlock),.s_axi_arcache(arcache),.s_axi_arprot(arprot),.s_axi_arregion(arregion),.s_axi_arqos(arqos), // 连接 AXI 读地址通道的锁、缓存、保护、区域和 QoS 属性。
      .s_axi_arvalid(arvalid),.s_axi_arready(arready),.s_axi_rid(rid),.s_axi_rdata(rdata),.s_axi_rresp(rresp), // 连接读地址握手及读响应的 ID、数据和响应码。
      .s_axi_rlast(rlast),.s_axi_rvalid(rvalid),.s_axi_rready(rready),.ddr_ready(ddr_ready),.init_calib_complete(calib), // 连接读响应握手、读末拍、后端就绪和校准完成状态。
      .ddr_axi_response_error_sticky(resp_err),.ddr_axi_timeout_sticky(timeout_err), // 连接响应错误和超时的粘滞状态输出。
      .c0_ddr4_act_n(act_n),.c0_ddr4_adr(adr),.c0_ddr4_ba(ba),.c0_ddr4_bg(bg),.c0_ddr4_cke(cke),.c0_ddr4_odt(odt), // 连接 DDR4 命令、地址和控制物理端口，保证模块端口完整。
      .c0_ddr4_cs_n(cs_n),.c0_ddr4_ck_t(ck_t),.c0_ddr4_ck_c(ck_c),.c0_ddr4_reset_n(reset_ddr_n), // 连接 DDR4 片选、差分时钟和复位物理端口。
      .c0_ddr4_dm_dbi_n(dm),.c0_ddr4_dq(dq),.c0_ddr4_dqs_c(dqs_c),.c0_ddr4_dqs_t(dqs_t) // 连接 DDR4 数据、掩码/DBI 和数据选通物理端口。
    ); // 完成被测模块例化。

    task automatic send_aw(input [31:0] a,input [7:0] len,input [4:0] id); begin // 定义写地址发送任务，参数分别是地址、突发长度减一和事务 ID。
      @(negedge clk); awaddr=a;awlen=len;awid=id;awvalid=1; // 在时钟下降沿稳定地址字段并拉高 AWVALID，避免与上升沿采样竞争。
      while(!awready) @(posedge clk); @(negedge clk);awvalid=0; // 等待 AWREADY 完成握手，再于下降沿撤销 AWVALID；地址字段保持到握手发生。
    end endtask // 结束写地址发送任务。
    task automatic send_w(input [63:0] d,input last); begin // 定义单拍写数据发送任务，参数是数据和该拍是否为突发末拍。
      @(negedge clk);wdata=d;wlast=last;wvalid=1; // 在下降沿稳定写数据和 WLAST，并拉高 WVALID。
      while(!wready) @(posedge clk);@(negedge clk);wvalid=0;wlast=0; // 等待 WREADY 完成握手，随后撤销 WVALID 和 WLAST，避免影响下一拍事务。
    end endtask // 结束写数据发送任务。
    task automatic wait_b(input [4:0] id); begin // 定义等待写响应任务，参数是期望返回的事务 ID。
      @(negedge clk);bready=1;while(!bvalid) @(posedge clk); // 在下降沿拉高 BREADY，然后等待被测模块给出 BVALID。
      if(bresp!==2'b00||bid!==id) fail("bad write response"); // 检查响应码必须为 OKAY 且响应 ID 必须与写地址 ID 一致，否则报告失败。
      @(negedge clk);bready=0; // 在响应握手后撤销 BREADY，避免无关响应被测试平台意外接受。
    end endtask // 结束写响应检查任务。
    task automatic read_burst_check(input [31:0] a,input integer beats,input [4:0] id,input [63:0] base); integer i; begin // 定义读突发和逐拍校验任务；参数为起始地址、拍数、期望 ID 和首拍期望数据。
      @(negedge clk);araddr=a;arlen=beats-1;arid=id;arvalid=1;rready=1; // 在下降沿发送读地址，并提前拉高 RREADY 以连续接收读数据。
      while(!arready) @(posedge clk);@(negedge clk);arvalid=0; // 等待 ARREADY 完成读地址握手，随后撤销 ARVALID。
      for(i=0;i<beats;i=i+1) begin // 遍历本次读突发应返回的每一拍数据。
        while(!rvalid) @(posedge clk); // 等待当前拍的 RVALID；后端可插入任意数量等待周期。
        if(rresp!==2'b00||rid!==id||rdata!==(base+i)) fail("read data/response mismatch"); // 同时检查 OKAY 响应、ID 保持和数据递增序列，任一不符即失败。
        if(rlast!==(i==beats-1)) fail("RLAST mismatch"); // 仅最后一拍必须断言 RLAST，其他拍必须保持低电平。
        @(negedge clk); // 等待到下降沿再检查下一拍，避免与上升沿读数据采样相互竞争。
      end // 结束所有读数据拍的检查。
      rready=0; // 读突发完成后撤销 RREADY。
    end endtask // 结束读突发校验任务。

    integer i; // 声明主测试流程中用于发送 16 个写数据拍的循环变量。
    initial begin // 定义一次性主测试流程，仿真开始时执行。
      repeat(5) @(posedge clk);resetn=1;ddr_resetn=1; // 保持两路复位 5 个控制时钟周期后释放；SIM_RAM 分支由 resetn 驱动 ready 管线。
      repeat(20) begin @(posedge clk); if(ddr_ready) begin $display("DDR_READY_AFTER_TWO_CYCLES_PASS"); break; end end // 最多等待 20 拍 ready；一旦 ready 置位就打印通过标记并退出循环。
      if(!ddr_ready||!calib) fail("DDR ready/calibration did not assert"); // 断言后端就绪和校准完成均已置位；SIM_RAM 中二者都是两拍就绪管线的输出。

      // W-first single-beat transaction proves AW/W channel independence. // 本段验证 W 通道先于 AW 通道到达时，后端仍能接受并正确完成单拍写。
      send_w(64'h1122_3344_5566_7788,1); // 先发送唯一一拍写数据，并将 WLAST 置 1。
      send_aw(32'h0000_0000,0,5'h03); // 后发送地址 0x0000_0000 的单拍写请求，AWLEN=0，ID=3。
      wait_b(5'h03); // 等待并检查该写事务的 OKAY 响应和 ID=3。
      read_burst_check(32'h0000_0000,1,5'h03,64'h1122_3344_5566_7788); // 读回同一地址的一拍数据，检查写入值、ID、响应码和 RLAST。
      $display("W_FIRST_SINGLE_PASS"); // 打印 W-first 用例通过标记，供日志检索。

      // Sixteen-beat INCR burst in the CPU->Aurora 0x8000 window. // 本段在后端地址 0x8000 做 16 拍递增突发；这里仅验证 RAM 地址和 AXI 突发，不驱动 CPU 或 Aurora 顶层链路。
      send_aw(32'h0000_8000,15,5'h12); // 发送起始地址 0x8000、AWLEN=15 的 16 拍 INCR 写请求，ID=0x12。
      for(i=0;i<16;i=i+1) send_w(64'hA500_0000_0000_0000+i,i==15); // 连续发送 16 拍递增数据，只有 i=15 的末拍置 WLAST。
      wait_b(5'h12); // 等待并检查 16 拍写突发的 OKAY 响应和 ID=0x12。
      read_burst_check(32'h0000_8000,16,5'h12,64'hA500_0000_0000_0000); // 读回 16 拍，逐拍核对递增数据、ID、响应码和最后一拍 RLAST。
      $display("INCR16_8000_PASS"); // 打印 16 拍递增突发用例通过标记。

      if(resp_err||timeout_err) fail("unexpected sticky status"); // 确认正常读写未置位响应错误或事务超时粘滞标志。
      $finish; // 正常结束仿真。
    end // 结束主测试流程。
    initial begin #200000; fail("simulation timeout"); end // 建立 200us 看门狗；主流程卡死或迟迟不结束时，打印失败并结束仿真。
endmodule // 结束测试平台模块。
```

本用例最近一次运行的通过日志为 `regression/timing_xdc_fix_20260921/smoke_retry.log`，详细 XSim 输出为 `regression/timing_xdc_fix_20260921/smoke/project/smoke.sim/sim_1/behav/xsim/simulate.log`。
