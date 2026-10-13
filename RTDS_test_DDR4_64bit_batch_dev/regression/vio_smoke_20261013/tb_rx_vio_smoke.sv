`timescale 1ns/1ps
// 修改点 2026-10-13：真实寄存器、writer、FDMA和backend；DDR使用RAM行为模型。
// VIO/JTAG操作以start电平模拟；不把本冒烟扩大为真实MSI、MIG或板级通过。
module tb_rx_vio_smoke;
    rtds_vio_harness H();
    logic [31:0] value;
    logic [63:0] data;
    task automatic trigger;
        @(negedge H.clk); H.vio_start=0;
        repeat(5) @(negedge H.clk);
        H.vio_start=1;
    endtask
    task automatic wait_count(input int count);
        for(int i=0;i<7000;i++) begin
            @(negedge H.clk);
            if(H.ready_blocks==count && !H.vio_busy) return;
        end
        $fatal(1,"VIO/BLOCK_TIMEOUT wanted=%0d got=%0d busy=%0b",count,H.ready_blocks,H.vio_busy);
    endtask
    initial begin
        H.reset(); H.channel_up=0; H.lane_up=0; H.pcie_up=0;
        repeat(20) @(negedge H.clk);
        trigger(); repeat(40) @(negedge H.clk);
        if(H.vio_busy || H.vio_accepted || H.ready_blocks) $fatal(1,"VIO/NOT_READY_STARTED");
        H.pcie_up=1; repeat(100) @(negedge H.clk);
        if(H.vio_busy || H.vio_accepted) $fatal(1,"VIO/HELD_HIGH_RETRIGGER");
        trigger();
        for(int i=0;i<4000 && H.vio_accepted!=2;i++) @(negedge H.clk);
        if(H.vio_accepted!=2 || !H.vio_busy || H.ready_blocks!=0) $fatal(1,"VIO/INPUT_IS_NOT_COMMIT");
        wait_count(1);
        if(!H.irq || H.dropped_words || H.vio_status[2]) $fatal(1,"VIO/IRQ_DROP_FAULT");
        H.check_reg('h30,1);H.check_reg('h18,'h100000);H.check_reg('h1c,8);
        H.cpu_read64('h100000,data);
        if(data!==64'h00000022_00000011) $fatal(1,"VIO/DATA %h",data);
        H.rd('h10,value);repeat(10) @(negedge H.clk);
        H.check_reg('h30,1);H.check_reg('h1c,8);
        if(H.irq) $fatal(1,"VIO/READ_CLEAR_IRQ");
        // start保持1超过完整周期，不允许重复注入。
        repeat(2200) @(negedge H.clk);
        H.check_reg('h30,1);H.check_reg('h1c,8);
        // 再触发一块，检查每次都是独立8Byte块。
        trigger();wait_count(2);
        H.wr('h14,1);repeat(10) @(negedge H.clk);
        H.check_reg('h30,1);H.check_reg('h18,'h140000);H.check_reg('h1c,8);
        H.cpu_read64('h140000,data);
        if(data!==64'h00000022_00000011 || !H.irq) $fatal(1,"VIO/SECOND_BLOCK");
        H.rd('h10,value);H.wr('h14,1);repeat(10) @(negedge H.clk);
        H.check_reg('h30,0);H.check_reg('h18,0);H.check_reg('h1c,0);
        // 测试源启用时，下行仍走原命令、DDR读取和10G发送检查。
        H.channel_up=1;H.lane_up=1;repeat(150) @(negedge H.clk);
        H.valid_tx('h8000,16,'h110000,1);
        H.valid_tx('h8010,32,'h220000,2);
        H.check_reg('h20,0);
        $display("TEST PASS tb_rx_vio_smoke no_subnode=1 blocks=2 bytes=16 holding_start_no_repeat=1 RC_not_pop=1 W1P_one_block=1 TX16_TX32=1");
        $finish;
    end
    initial begin #1000000;$fatal(1,"VIO/WATCHDOG");end
endmodule
