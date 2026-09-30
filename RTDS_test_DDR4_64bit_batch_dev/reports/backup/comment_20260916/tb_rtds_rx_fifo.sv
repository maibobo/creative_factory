`timescale 1ns/1ps
// FIFO按有效拍存储，不依据SOF/EOF进行组帧；随机高32bit也必须在此层完整透传。
module tb_rtds_rx_fifo;
    logic user_clk=0,mem_clk=0;

    always #3.2 user_clk=~user_clk;

    always #2 mem_clk=~mem_clk;
    rtds_rx_fifo_test_if bus(user_clk,mem_clk);
    RTDS_RX_FRAME_FIFO #(.FIFO_DEPTH(16)) U_DUT (
        .rst_n(bus.rst_n), .user_clk(user_clk), .user_ready(bus.user_ready),
        .rx_data(bus.rx_data), .rx_sof(bus.rx_sof), .rx_eof(bus.rx_eof),
        .rx_rem(bus.rx_rem), .rx_valid(bus.rx_valid), .rx_ready(bus.rx_ready),
        .mem_clk(mem_clk), .frame_data(bus.frame_data), .frame_valid(bus.frame_valid),
        .frame_ready(bus.frame_ready), .fifo_full(bus.fifo_full),
        .fifo_almost_full(bus.fifo_almost_full), .dropped_frames(bus.dropped_frames),
        .length_error(bus.length_error)
    );
    logic[63:0] expected[$];
    int received=0;

    always @(bus.mem_mon_cb) begin : monitor
        logic[63:0] value;
        if(bus.mem_mon_cb.rst_n && bus.mem_mon_cb.frame_valid && bus.mem_mon_cb.frame_ready) begin
            if(expected.size()==0)
                $fatal(1,"FIFO/EXTRA");
            value=expected.pop_front();
            if(value!==bus.mem_mon_cb.frame_data)
                $fatal(1,"FIFO/ORDER");
            received++;
        end
    end
    task automatic send(input int n,input bit stored);
        logic[63:0] value;
        value={$urandom,32'(n)};
        @(bus.user_drv_cb);
        if(stored)
            expected.push_back(value);
        bus.user_drv_cb.rx_data<=value;bus.user_drv_cb.rx_valid<=1;
        bus.user_drv_cb.rx_sof<=n%3==0;bus.user_drv_cb.rx_eof<=n%5==0;
        @(bus.user_drv_cb);bus.user_drv_cb.rx_valid<=0;
    endtask
    initial begin : stimulus
        repeat(16) @(bus.user_drv_cb);
        bus.user_drv_cb.rst_n<=1;bus.user_drv_cb.user_ready<=1;
        repeat(30) @(bus.user_drv_cb);
        for(int n=0;n<17;n++) send(n,1);
        repeat(20) @(bus.mem_drv_cb);
        if(!bus.fifo_full)
            $fatal(1,"FIFO/EXPECTED_FULL");
        send(100,0);
        repeat(20) @(bus.mem_drv_cb);
        if(bus.dropped_frames!=1)
            $fatal(1,"FIFO/FULL_DROP %d",bus.dropped_frames);
        bus.mem_drv_cb.frame_ready<=1;
        wait(received==17);
        send(99,1);wait(received==18);
        if(bus.length_error)
            $fatal(1,"FIFO/FRAME_DEPENDENCE");
        $display("TEST PASS tb_rtds_rx_fifo V2.01");$finish;
    end
    initial begin
        #100000; $fatal(1,"FIFO/WATCHDOG");end
endmodule
