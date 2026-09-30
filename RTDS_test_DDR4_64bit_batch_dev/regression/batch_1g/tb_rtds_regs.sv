`timescale 1ns/1ps
// 使用真实寄存器RTL验证自动清零，不用BFM寄存器模型代替被测逻辑。
module tb_rtds_regs;
    logic clk=0;

    // 生成 250MHz 寄存器总线时钟
    always #2 clk=~clk;
    rtds_regs_test_if bus(clk);
    // 被测设计：信息交换寄存器组（状态回读 + 命令/自清零位）
    INFO_EXCH U_DUT (
        .CPU_WR_DONE_EVENT(bus.done), .FPGA_TEMP_W(32'd0), .INT_STATE_W(1'b0),
        .CPU_REC_STATE_W(1'b0), .FPGA_CPU_START_ADDR(32'h100000), .FPGA_CPU_LEN(32'd12),
        .CPU_WR_DONE_resp(1'b0), .DDR_STATUS_W(32'd0), .RX_READY_BLOCKS(32'd1),
        .RX_HEAD_SEQ(32'd7), .RX_DROPPED_FRAMES(32'd9),
        .r_INT_STATE(bus.clear_irq), .r_CLEAR_INTER(bus.clear_inter),
        .r_CPU_REC_STATE(bus.ack), .r_RD_START(bus.start),
        .r_CPU_FPGA_START_ADDR(bus.command_addr), .r_CPU_FPGA_LEN(bus.command_len),
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(bus.rst_n),
        .S_AXI_AWADDR(bus.awaddr), .S_AXI_AWPROT(3'd0), .S_AXI_AWVALID(bus.awvalid), .S_AXI_AWREADY(bus.awready),
        .S_AXI_WDATA(bus.wdata), .S_AXI_WSTRB(bus.wstrb), .S_AXI_WVALID(bus.wvalid), .S_AXI_WREADY(bus.wready),
        .S_AXI_BRESP(bus.bresp), .S_AXI_BVALID(bus.bvalid), .S_AXI_BREADY(bus.bready),
        .S_AXI_ARADDR(bus.araddr), .S_AXI_ARPROT(3'd0), .S_AXI_ARVALID(bus.arvalid), .S_AXI_ARREADY(bus.arready),
        .S_AXI_RDATA(bus.rdata), .S_AXI_RRESP(bus.rresp), .S_AXI_RVALID(bus.rvalid), .S_AXI_RREADY(bus.rready)
    );
    int starts=0,acks=0;    // start 与 ack 脉冲的累计观测计数

    // 累计启动脉冲数，检验写 1 自动清零不重复触发
    always @(bus.monitor_cb) begin
        if(bus.monitor_cb.rst_n && bus.monitor_cb.start)
            starts++;
    end

    // 累计应答脉冲数，供最终次数核对
    always @(bus.monitor_cb) begin
        if(bus.monitor_cb.rst_n && bus.monitor_cb.ack)
            acks++;
    end
    // AXI4-Lite 写事务：可选字节使能，响应必须为 OKAY
    task automatic wr(input int address,input int value,input logic[3:0] strobe=4'hf);
        @(bus.driver_cb);bus.driver_cb.awaddr<=address;bus.driver_cb.wdata<=value;
        bus.driver_cb.wstrb<=strobe;bus.driver_cb.awvalid<=1;bus.driver_cb.wvalid<=1;
        do @(bus.driver_cb); while(!(bus.driver_cb.awready && bus.driver_cb.wready));
        bus.driver_cb.awvalid<=0;bus.driver_cb.wvalid<=0;
        do @(bus.driver_cb); while(!bus.driver_cb.bvalid);
        if(bus.driver_cb.bresp!=0)
            $fatal(1,"REG/WRITE_RESPONSE");
    endtask
    // AXI4-Lite 读事务：读回值必须与期望完全一致
    task automatic check(input int address,input int value);
        @(bus.driver_cb);bus.driver_cb.araddr<=address;bus.driver_cb.arvalid<=1;
        do @(bus.driver_cb); while(!bus.driver_cb.arready);
        bus.driver_cb.arvalid<=0;
        do @(bus.driver_cb); while(!bus.driver_cb.rvalid);
        if(bus.driver_cb.rdata!==32'(value))
            $fatal(1,"REG/READ addr=%h expected=%h got=%h",address,value,bus.driver_cb.rdata);
    endtask
    // 主激励：默认值→启动自清零→done 后再启动→应答脉冲全流程
    initial begin
        repeat(8) @(bus.driver_cb);bus.driver_cb.rst_n<=1;
        // 校验只读状态、版本与预置参数寄存器的默认值
        check('h00,'h2001);check('h04,'h20260914);check('h08,'h40000);
        check('h30,1);check('h34,7);check('h38,9);
        // 预写命令地址 0x8000 与长度 16
        wr('h24,'h8000);wr('h28,16);
        // 写 start=1 启动传输，读回确认该位已置位
        wr('h20,1);check('h20,1);
        // start 仍置位期间再次写 start 与新地址/长度
        wr('h20,1);wr('h24,'h9000);wr('h28,32);
        // 第二次写入应被忽略，读回仍为旧参数
        check('h24,'h8000);check('h28,16);
        // 重复写 start 不得产生第二个启动脉冲
        if(starts!=1)
            $fatal(1,"REG/DUPLICATE_START");
        // 模拟 CPU 写完成事件（单拍脉冲），触发 start 位自动清零
        @(bus.driver_cb);bus.driver_cb.done<=1;
        @(bus.driver_cb);bus.driver_cb.done<=0;
        check('h20,0);
        // 自动清零后允许再次启动，读回确认重新置位
        wr('h20,1);check('h20,1);
        if(starts!=2)
            $fatal(1,"REG/NEXT_START");
        // 应答位写 1 后立即自清零，读回恒为 0
        wr('h14,1);check('h14,0);wr('h14,1);check('h14,0);
        // 字节使能不完整的写入不得额外触发应答脉冲
        wr('h14,1,4'he);check('h14,0);
        // 应答脉冲总数必须恰好为 2
        if(acks!=2)
            $fatal(1,"REG/ACK_COUNT %0d",acks);
        $display("TEST PASS tb_rtds_regs V2.01");$finish;
    end
    // 看门狗：100us 未完成即失败
    initial begin
        #100000; $fatal(1,"REG/WATCHDOG");end
endmodule
