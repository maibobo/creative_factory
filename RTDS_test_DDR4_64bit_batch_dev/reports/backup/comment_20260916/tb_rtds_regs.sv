`timescale 1ns/1ps
// 使用真实寄存器RTL验证自动清零，不用BFM寄存器模型代替被测逻辑。
module tb_rtds_regs;
    logic clk=0;

    always #2 clk=~clk;
    rtds_regs_test_if bus(clk);
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
    int starts=0,acks=0;

    always @(bus.monitor_cb) begin
        if(bus.monitor_cb.rst_n && bus.monitor_cb.start)
            starts++;
    end

    always @(bus.monitor_cb) begin
        if(bus.monitor_cb.rst_n && bus.monitor_cb.ack)
            acks++;
    end
    task automatic wr(input int address,input int value,input logic[3:0] strobe=4'hf);
        @(bus.driver_cb);bus.driver_cb.awaddr<=address;bus.driver_cb.wdata<=value;
        bus.driver_cb.wstrb<=strobe;bus.driver_cb.awvalid<=1;bus.driver_cb.wvalid<=1;
        do @(bus.driver_cb); while(!(bus.driver_cb.awready && bus.driver_cb.wready));
        bus.driver_cb.awvalid<=0;bus.driver_cb.wvalid<=0;
        do @(bus.driver_cb); while(!bus.driver_cb.bvalid);
        if(bus.driver_cb.bresp!=0)
            $fatal(1,"REG/WRITE_RESPONSE");
    endtask
    task automatic check(input int address,input int value);
        @(bus.driver_cb);bus.driver_cb.araddr<=address;bus.driver_cb.arvalid<=1;
        do @(bus.driver_cb); while(!bus.driver_cb.arready);
        bus.driver_cb.arvalid<=0;
        do @(bus.driver_cb); while(!bus.driver_cb.rvalid);
        if(bus.driver_cb.rdata!==32'(value))
            $fatal(1,"REG/READ addr=%h expected=%h got=%h",address,value,bus.driver_cb.rdata);
    endtask
    initial begin
        repeat(8) @(bus.driver_cb);bus.driver_cb.rst_n<=1;
        check('h00,'h2001);check('h04,'h20260914);check('h08,'h40000);
        check('h30,1);check('h34,7);check('h38,9);
        wr('h24,'h8000);wr('h28,16);
        wr('h20,1);check('h20,1);
        wr('h20,1);wr('h24,'h9000);wr('h28,32);
        check('h24,'h8000);check('h28,16);
        if(starts!=1)
            $fatal(1,"REG/DUPLICATE_START");
        @(bus.driver_cb);bus.driver_cb.done<=1;
        @(bus.driver_cb);bus.driver_cb.done<=0;
        check('h20,0);
        wr('h20,1);check('h20,1);
        if(starts!=2)
            $fatal(1,"REG/NEXT_START");
        wr('h14,1);check('h14,0);wr('h14,1);check('h14,0);
        wr('h14,1,4'he);check('h14,0);
        if(acks!=2)
            $fatal(1,"REG/ACK_COUNT %0d",acks);
        $display("TEST PASS tb_rtds_regs V2.01");$finish;
    end
    initial begin
        #100000; $fatal(1,"REG/WATCHDOG");end
endmodule
