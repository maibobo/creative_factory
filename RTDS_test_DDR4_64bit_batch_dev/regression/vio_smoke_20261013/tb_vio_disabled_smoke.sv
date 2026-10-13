`timescale 1ns/1ps
// 修改点 2026-10-13：关闭参数时，start不生效，原Aurora FIFO和下行保持可用。
module tb_vio_disabled_smoke;
    rtds_vio_harness #(.RX_VIO_TEST_ENABLE(0)) H();
    logic [63:0] data;
    initial begin
        H.reset();H.vio_start=1;
        repeat(2200) @(negedge H.clk);
        if(H.vio_busy || H.vio_accepted || H.ready_blocks) $fatal(1,"DISABLED/INJECTION");
        H.send_rx('h55);H.send_rx('haa);
        for(int i=0;i<5000 && H.ready_blocks!=1;i++) @(negedge H.clk);
        H.check_reg('h30,1);H.check_reg('h1c,8);
        H.cpu_read64('h100000,data);
        if(data!==64'h000000aa_00000055) $fatal(1,"DISABLED/FIFO_DATA %h",data);
        H.wr('h14,1);repeat(10) @(negedge H.clk);
        H.check_reg('h30,0);
        H.valid_tx('h8000,16,'h440000,3);
        $display("TEST PASS tb_vio_disabled_smoke original_FIFO=1 ignored_start=1 TX16=1");$finish;
    end
    initial begin #1000000;$fatal(1,"DISABLED/WATCHDOG");end
endmodule
