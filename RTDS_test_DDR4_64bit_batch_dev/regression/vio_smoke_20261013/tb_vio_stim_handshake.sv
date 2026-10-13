`timescale 1ns/1ps
// 修改点 2026-10-13：发生器反压保持、忙时触发忽略及失去就绪后的错误保持。
module tb_vio_stim_handshake;
    logic clk=0,rst_n=0,start=0,ready=1,tick=0,commit=0,werror=0,accept=0;
    wire[63:0] data;wire valid,busy,fault;wire[1:0] words;
    always #2 clk=~clk;
    RTDS_RX_VIO_STIM U(.clk(clk),.rst_n(rst_n),.start(start),.store_ready(ready),.ready_blocks(32'd0),.period_tick(tick),.block_committed(commit),.write_error(werror),.frame_ready(accept),.frame_data(data),.frame_valid(valid),.busy(busy),.accepted_words(words),.fault(fault));
    initial begin
        repeat(4) @(negedge clk);rst_n=1;repeat(4) @(negedge clk);start=1;
        repeat(4) @(negedge clk);tick=1;@(negedge clk);tick=0;
        repeat(4) @(negedge clk);
        for(int i=0;i<8;i++) begin
            @(negedge clk);
            if(!valid || data!==64'h11 || words!=0 || !busy) $fatal(1,"UNIT/STALL_FIRST");
        end
        accept=1;@(negedge clk);accept=0;
        if(!valid || data!==64'h22 || words!=1) $fatal(1,"UNIT/FIRST_ACCEPT");
        start=0;repeat(4) @(negedge clk);start=1;
        repeat(4) @(negedge clk);
        if(data!==64'h22 || words!=1) $fatal(1,"UNIT/BUSY_RETRIGGER");
        accept=1;@(negedge clk);accept=0;
        if(valid || words!=2 || !busy) $fatal(1,"UNIT/WAIT_COMMIT");
        repeat(4) @(negedge clk);commit=1;@(negedge clk);commit=0;repeat(4) @(negedge clk);
        if(busy || fault || words!=2) $fatal(1,"UNIT/COMMIT");
        start=0;repeat(4) @(negedge clk);start=1;repeat(4) @(negedge clk);
        ready=0;repeat(4) @(negedge clk);
        if(busy || valid || !fault) $fatal(1,"UNIT/ABORT");
        ready=1;start=0;repeat(4) @(negedge clk);start=1;repeat(4) @(negedge clk);
        if(busy || !fault) $fatal(1,"UNIT/FAULT_RESTART");
        $display("TEST PASS tb_vio_stim_handshake registered_hold=1 busy_trigger_ignored=1 commit_required=1 fault_requires_reset=1");$finish;
    end
    initial begin #10000;$fatal(1,"UNIT/WATCHDOG");end
endmodule
