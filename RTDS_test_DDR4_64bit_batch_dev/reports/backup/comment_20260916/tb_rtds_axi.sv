`timescale 1ns/1ps
 // AXI 定向前仿：实际 CONV_DMA + 实际 4MiB 行为 RAM。
 // 仅在测试包装层门控握手注入 AW/W/B 延迟；不改变 RAM 和 DUT 内部信号。
module tb_rtds_axi;
    logic M_AXI_ACLK = '0;
    rtds_axi_test_if bus (.M_AXI_ACLK(M_AXI_ACLK));

    int cycle_count=0;
    wire allow_aw,allow_w,allow_b;
    wire ram_awready,ram_awvalid,ram_wready,ram_wvalid,ram_bvalid,ram_bready;
    wire [1:0] ram_bresp;

    always #2 M_AXI_ACLK=~M_AXI_ACLK;

    always @(posedge M_AXI_ACLK) begin
        if(!bus.M_AXI_ARESETN)
            cycle_count<=0;
        else
            cycle_count<=cycle_count+1;
    end
     // 地址和数据允许独立到达；末拍额外停顿，响应最多等 31 拍。
    assign allow_aw=(cycle_count%11)>7;
    // 验证层控制握手可用性，用于注入独立通道停顿，不修改DUT内部状态。
    assign allow_w=(cycle_count%5)>1 && (!bus.M_AXI_WLAST || (cycle_count%17)>13);
    // 验证层控制握手可用性，用于注入独立通道停顿，不修改DUT内部状态。
    assign allow_b=(cycle_count%31)==0;
    // 验证层控制握手可用性，用于注入独立通道停顿，不修改DUT内部状态。
    assign ram_awvalid=bus.M_AXI_AWVALID && allow_aw;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign bus.M_AXI_AWREADY=ram_awready && allow_aw;
    // 验证层控制握手可用性，用于注入独立通道停顿，不修改DUT内部状态。
    assign ram_wvalid=bus.M_AXI_WVALID && allow_w;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign bus.M_AXI_WREADY=ram_wready && allow_w;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign bus.M_AXI_BVALID=ram_bvalid && allow_b;
    // 验证层控制握手可用性，用于注入独立通道停顿，不修改DUT内部状态。
    assign ram_bready=bus.M_AXI_BREADY && allow_b;
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign bus.M_AXI_BRESP=bus.inject_error ? 2'b10 : ram_bresp;
    CONV_DMA U_DUT (
        .fdma_wdone(bus.fdma_wdone),
        .fdma_werror(bus.fdma_werror),
        .fdma_waddr(bus.fdma_waddr),
        .fdma_wareq(bus.fdma_wareq),
        .fdma_wsize(bus.fdma_wsize),
        .fdma_wbusy(bus.fdma_wbusy),
        .fdma_wstrb(8'hff), .fdma_wdata(bus.fdma_wdata),
        .fdma_wvalid(bus.fdma_wvalid),
        .fdma_wready(bus.fdma_wready),
        .fdma_raddr(bus.fdma_raddr),
        .fdma_rareq(bus.fdma_rareq),
        .fdma_rsize(bus.fdma_rsize),
        .fdma_rbusy(bus.fdma_rbusy),
        .fdma_rdata(bus.fdma_rdata),
        .fdma_rvalid(bus.fdma_rvalid),
        .fdma_rready(bus.fdma_rready),
        .M_AXI_ACLK(M_AXI_ACLK),
        .M_AXI_ARESETN(bus.M_AXI_ARESETN),
        .M_AXI_AWID(bus.M_AXI_AWID),
        .M_AXI_AWADDR(bus.M_AXI_AWADDR),
        .M_AXI_AWLEN(bus.M_AXI_AWLEN),
        .M_AXI_AWSIZE(bus.M_AXI_AWSIZE),
        .M_AXI_AWBURST(bus.M_AXI_AWBURST),
        .M_AXI_AWLOCK(bus.M_AXI_AWLOCK),
        .M_AXI_AWCACHE(bus.M_AXI_AWCACHE),
        .M_AXI_AWPROT(bus.M_AXI_AWPROT),
        .M_AXI_AWQOS(bus.M_AXI_AWQOS),
        .M_AXI_AWVALID(bus.M_AXI_AWVALID),
        .M_AXI_AWREADY(bus.M_AXI_AWREADY),
        .M_AXI_WID(bus.M_AXI_WID),
        .M_AXI_WDATA(bus.M_AXI_WDATA),
        .M_AXI_WSTRB(bus.M_AXI_WSTRB),
        .M_AXI_WLAST(bus.M_AXI_WLAST),
        .M_AXI_WVALID(bus.M_AXI_WVALID),
        .M_AXI_WREADY(bus.M_AXI_WREADY),
        .M_AXI_BID(bus.M_AXI_BID),
        .M_AXI_BRESP(bus.M_AXI_BRESP),
        .M_AXI_BVALID(bus.M_AXI_BVALID),
        .M_AXI_BREADY(bus.M_AXI_BREADY),
        .M_AXI_ARID(bus.M_AXI_ARID),
        .M_AXI_ARADDR(bus.M_AXI_ARADDR),
        .M_AXI_ARLEN(bus.M_AXI_ARLEN),
        .M_AXI_ARSIZE(bus.M_AXI_ARSIZE),
        .M_AXI_ARBURST(bus.M_AXI_ARBURST),
        .M_AXI_ARLOCK(bus.M_AXI_ARLOCK),
        .M_AXI_ARCACHE(bus.M_AXI_ARCACHE),
        .M_AXI_ARPROT(bus.M_AXI_ARPROT),
        .M_AXI_ARQOS(bus.M_AXI_ARQOS),
        .M_AXI_ARVALID(bus.M_AXI_ARVALID),
        .M_AXI_ARREADY(bus.M_AXI_ARREADY),
        .M_AXI_RID(bus.M_AXI_RID),
        .M_AXI_RDATA(bus.M_AXI_RDATA),
        .M_AXI_RRESP(bus.M_AXI_RRESP),
        .M_AXI_RLAST(bus.M_AXI_RLAST),
        .M_AXI_RVALID(bus.M_AXI_RVALID),
        .M_AXI_RREADY(bus.M_AXI_RREADY)
    );
    rtds_axi_ram_model #(.ADDR_WIDTH(64),.ID_WIDTH(1),.MEM_BYTES(4194304)) U_RAM (
        .aclk(M_AXI_ACLK),
        .aresetn(bus.M_AXI_ARESETN),
        .s_axi_awid(bus.M_AXI_AWID),
        .s_axi_awaddr(bus.M_AXI_AWADDR),
        .s_axi_awlen(bus.M_AXI_AWLEN),
        .s_axi_awsize(bus.M_AXI_AWSIZE),
        .s_axi_awburst(bus.M_AXI_AWBURST),
        .s_axi_awvalid(ram_awvalid),
        .s_axi_awready(ram_awready),
        .s_axi_wdata(bus.M_AXI_WDATA),
        .s_axi_wstrb(bus.M_AXI_WSTRB),
        .s_axi_wlast(bus.M_AXI_WLAST),
        .s_axi_wvalid(ram_wvalid),
        .s_axi_wready(ram_wready),
        .s_axi_bid(bus.M_AXI_BID),
        .s_axi_bresp(ram_bresp),
        .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(ram_bready),
        .s_axi_arid(bus.M_AXI_ARID),
        .s_axi_araddr(bus.M_AXI_ARADDR),
        .s_axi_arlen(bus.M_AXI_ARLEN),
        .s_axi_arsize(bus.M_AXI_ARSIZE),
        .s_axi_arburst(bus.M_AXI_ARBURST),
        .s_axi_arvalid(bus.M_AXI_ARVALID),
        .s_axi_arready(bus.M_AXI_ARREADY),
        .s_axi_rid(bus.M_AXI_RID),
        .s_axi_rdata(bus.M_AXI_RDATA),
        .s_axi_rresp(bus.M_AXI_RRESP),
        .s_axi_rlast(bus.M_AXI_RLAST),
        .s_axi_rvalid(bus.M_AXI_RVALID),
        .s_axi_rready(bus.M_AXI_RREADY)
    );

     // 事务接收完成的字节序列由索引生成，读回逐拍比较，不窥探 RAM 数组。
    task automatic write_words(input logic [63:0] address,input int count,input int seed,input bit bad);
        $display("WRITE_BEGIN addr=%h count=%d",address,count);
        @(bus.driver_cb);
        bus.driver_cb.inject_error<=bad;
        bus.driver_cb.fdma_waddr<=address; bus.driver_cb.fdma_wsize<=16'(count); bus.driver_cb.fdma_wareq<=1;
        do @(bus.driver_cb); while(!bus.driver_cb.fdma_wbusy);
        bus.driver_cb.fdma_wareq<=0;
        for(int beat=0;beat<count;beat++) begin
            bus.driver_cb.fdma_wdata<={32'(seed),32'(beat)};
            bus.driver_cb.fdma_wready<=1;
            do @(bus.driver_cb); while(!bus.driver_cb.fdma_wvalid);
            if(bus.driver_cb.fdma_wdone)
                $fatal(1,"AXI/EARLY_WRITE_DONE");
        end
        bus.driver_cb.fdma_wready<=0;
        do @(bus.driver_cb); while(!bus.driver_cb.fdma_wdone);
        if(bus.driver_cb.fdma_werror !== bad)
            $fatal(1,"AXI/BRESP_RESULT");
        @(bus.driver_cb); bus.driver_cb.inject_error<=0;
    endtask
    task automatic read_words(input logic [63:0] address,input int count,input int seed);
        @(bus.driver_cb);
        bus.driver_cb.fdma_raddr<=address; bus.driver_cb.fdma_rsize<=16'(count); bus.driver_cb.fdma_rareq<=1;
        do @(bus.driver_cb); while(!bus.driver_cb.fdma_rbusy);
        bus.driver_cb.fdma_rareq<=0;
        bus.driver_cb.fdma_rready<=1;
        for(int beat=0;beat<count;beat++) begin
            do @(bus.driver_cb); while(!bus.driver_cb.fdma_rvalid);
            if(bus.driver_cb.fdma_rdata !== {32'(seed),32'(beat)})
                $fatal(1,"AXI/DATA addr=%h beat=%0d actual=%h",address,beat,bus.driver_cb.fdma_rdata);
        end
        bus.driver_cb.fdma_rready<=0;
        do @(bus.driver_cb); while(bus.driver_cb.fdma_rbusy);
    endtask
     // 有界的协议级稳定性检查；每条关键反压断言均有前件覆盖。
    a_w_hold: assert property (@(posedge M_AXI_ACLK) disable iff(!bus.M_AXI_ARESETN)
        bus.M_AXI_WVALID && !bus.M_AXI_WREADY |=> bus.M_AXI_WVALID && $stable({bus.M_AXI_WDATA,bus.M_AXI_WSTRB,bus.M_AXI_WLAST}))
        else
            $fatal(1,"AXI/W_HOLD");
    c_w_stall: cover property (@(posedge M_AXI_ACLK) disable iff(!bus.M_AXI_ARESETN) bus.M_AXI_WVALID && !bus.M_AXI_WREADY);
    a_aw_hold: assert property (@(posedge M_AXI_ACLK) disable iff(!bus.M_AXI_ARESETN)
        bus.M_AXI_AWVALID && !bus.M_AXI_AWREADY |=> bus.M_AXI_AWVALID && $stable({bus.M_AXI_AWADDR,bus.M_AXI_AWLEN}))
        else
            $fatal(1,"AXI/AW_HOLD");
    c_aw_stall: cover property (@(posedge M_AXI_ACLK) disable iff(!bus.M_AXI_ARESETN) bus.M_AXI_AWVALID && !bus.M_AXI_AWREADY);
    a_boundary: assert property (@(posedge M_AXI_ACLK) disable iff(!bus.M_AXI_ARESETN)
        bus.M_AXI_AWVALID |-> ({1'b0,bus.M_AXI_AWADDR[11:0]}+(13'(bus.M_AXI_AWLEN)+1)*8)<=4096)
        else
            $fatal(1,"AXI/CROSS_4K");
    initial begin : stimulus
        repeat(10) @(bus.driver_cb);
        bus.driver_cb.M_AXI_ARESETN<=1;
         // 先写八个高地址块，再统一读回，暴露 [15:3] 截断导致的别名。
        for(int block_id=0;block_id<8;block_id++) write_words('h100000+block_id*'h40000,16,block_id,0);
        for(int block_id=0;block_id<8;block_id++) read_words('h100000+block_id*'h40000,16,block_id);
         // 从 4KiB 边界前 8Byte 开始，强制 1 拍 + 256 拍 + 其余拍的拆分。
        write_words('h180ff8,520,123,0); read_words('h180ff8,520,123);
        write_words('h200000,16,456,1);
        if(bus.fdma_wbusy || bus.fdma_rbusy)
            $fatal(1,"AXI/RESIDUAL");
        $display("TEST PASS tb_rtds_axi");
        $finish;
    end
    initial begin : watchdog
        #2000000;
        $display("AXI DIAG state=%d wb=%d beat=%d left=%d aw=%b w=%b b=%b busy=%b",U_DUT.write_curr_st,U_DUT.wb,U_DUT.wbeat,U_DUT.wleft,bus.M_AXI_AWVALID,bus.M_AXI_WVALID,bus.M_AXI_BVALID,bus.fdma_wbusy);
        $fatal(1,"AXI/GLOBAL_TIMEOUT");
    end
endmodule
