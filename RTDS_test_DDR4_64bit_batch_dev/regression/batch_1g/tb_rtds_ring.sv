`timescale 1ns/1ps
// 连续字流验证：通过接口驱动，检查器逐字读取独立内存模型，不复用DUT地址算法。
module tb_rtds_ring;
    logic clk=0;

    // 生成 250MHz 系统时钟
    always #2 clk=~clk;
    rtds_ring_test_if bus(clk);
    // 被测设计：把连续 32bit 字流组块写入 8×256KiB 环形 DDR 队列
    RTDS_RX_BLOCK_WRITER #(.PERIOD_CYCLES(200)) U_DUT (
        .clk(clk), .rst_n(bus.rst_n), .enable(bus.enable),
        .frame_data(bus.frame_data), .frame_valid(bus.frame_valid), .frame_ready(bus.frame_ready),
        .cpu_ack(bus.cpu_ack), .irq_clear(bus.irq_clear), .head_addr(bus.head_addr),
        .head_len(bus.head_len), .head_seq(bus.head_seq), .ready_blocks(bus.ready_blocks),
        .dropped_frames(bus.dropped_frames), .irq(bus.irq),
        .fdma_waddr(bus.fdma_waddr), .fdma_wsize(bus.fdma_wsize), .fdma_wareq(bus.fdma_wareq),
        .fdma_wbusy(bus.fdma_wbusy), .fdma_wdata(bus.fdma_wdata), .fdma_wstrb(bus.fdma_wstrb),
        .fdma_wvalid(bus.fdma_wvalid), .fdma_waccept(bus.fdma_waccept),
        .fdma_wdone(bus.fdma_wdone), .fdma_werror(bus.fdma_werror), .dbg_state(bus.dbg_state)
    );
    byte unsigned memory[int unsigned];    // 独立字节记分板：地址→数据，仅 responder 写入
    int response_delay=3;    // 写响应延迟拍数，可加大到跨越组块周期窗口
    bit inject_error=0;    // 置 1 时 responder 回复写错误响应
    // FDMA响应器独占响应引脚；等待B时可延迟/报错，W数据与字节使能独立评分。
    initial begin : responder
        logic [63:0] address,data;
        logic [7:0] strb;
        forever begin
            do @(bus.fdma_cb); while (!bus.fdma_cb.rst_n || !bus.fdma_cb.fdma_wareq);
            address=bus.fdma_cb.fdma_waddr;
            // 每笔 FDMA 写请求必须恰好 1 拍（8 字节）
            if(bus.fdma_cb.fdma_wsize!=1)
                $fatal(1,"STREAM/SIZE");
            bus.fdma_cb.fdma_wbusy<=1;
            do @(bus.fdma_cb); while(!bus.fdma_cb.fdma_wvalid);
            data=bus.fdma_cb.fdma_wdata; strb=bus.fdma_cb.fdma_wstrb;
            repeat(2) @(bus.fdma_cb);
            // 接受写数据前，数据与字节使能必须保持稳定
            if(data!==bus.fdma_cb.fdma_wdata || strb!==bus.fdma_cb.fdma_wstrb)
                $fatal(1,"STREAM/HOLD");
            bus.fdma_cb.fdma_waccept<=1;
            @(bus.fdma_cb); bus.fdma_cb.fdma_waccept<=0;
            repeat(response_delay) @(bus.fdma_cb);
            if(!inject_error)
                for(int i=0;i<8;i++) if(strb[i])
                memory[int'(address)+i]=data[i*8+:8];
            bus.fdma_cb.fdma_werror<=inject_error;
            bus.fdma_cb.fdma_wdone<=1;
            bus.fdma_cb.fdma_wbusy<=0;
            @(bus.fdma_cb); bus.fdma_cb.fdma_wdone<=0;
        end
    end
    // 发送一个 32bit 字并等待 DUT 握手接收
    task automatic send_word(input int value);
        @(bus.host_cb); bus.host_cb.frame_data<={$urandom,32'(value)}; bus.host_cb.frame_valid<=1;
        do @(bus.host_cb); while(!bus.host_cb.frame_ready);
        bus.host_cb.frame_valid<=0;
    endtask
    // 轮询等待 ready_blocks 达到期望值，超时即失败
    task automatic wait_count(input int count);
        for(int i=0;i<2000;i++) begin
            @(bus.host_cb); if(bus.host_cb.ready_blocks==count)
                return;
        end
        $fatal(1,"STREAM/COUNT expected=%0d got=%0d",count,bus.ready_blocks);
    endtask
    // 模拟 CPU 应答：单拍脉冲 cpu_ack 与 irq_clear
    task automatic ack;
        @(bus.host_cb);bus.host_cb.cpu_ack<=1;bus.host_cb.irq_clear<=1;
        @(bus.host_cb);bus.host_cb.cpu_ack<=0;bus.host_cb.irq_clear<=0;
        repeat(2) @(bus.host_cb);
    endtask
    // 校验队头元组（序号/地址/长度）并逐字比对记分板数据
    task automatic check_head(input int seq,input int words,input int seed);
        int address;
        address=bus.head_addr;
        if(address != 'h100000+(seq%8)*'h40000 || bus.head_seq != seq || bus.head_len!=words*4)
            $fatal(1,"STREAM/HEAD seq=%0d addr=%h len=%0d",seq,address,bus.head_len);
        for(int i=0;i<words;i++) begin
            logic[31:0] got;
            for(int b=0;b<4;b++) got[b*8+:8]=memory[address+i*4+b];
            if(got!==32'(seed+i))
                $fatal(1,"STREAM/DATA %h expected=%h",got,seed+i);
        end
    endtask
    // 主激励：奇偶长度成块、八块积压丢弃、跨窗延迟响应、错误响应四大场景
    initial begin : host
        @(bus.host_cb);bus.host_cb.rst_n<=0;
        repeat(8) @(bus.host_cb);bus.host_cb.rst_n<=1;bus.host_cb.enable<=1;
        // 奇偶尾拍交替，至少三轮八块地址回绕。
        for(int n=0;n<24;n++) begin
            int words;
            words=n%2+2;
            for(int j=0;j<words;j++) send_word(n*16+j);
            wait_count(1);check_head(n,words,n*16);ack();wait_count(0);
        end
        // 积压八块，额外数据不得改写队头，丢失按32bit字计数。
        for(int n=24;n<32;n++) begin
            send_word(n*16);wait_count(n-23);
        end
        check_head(24,1,24*16);
        // 满队后送入 2 个多余字，应按 32bit 字计入丢弃
        send_word(999);send_word(1000);
        repeat(8) @(bus.host_cb);
        if(bus.dropped_frames!=2)
            $fatal(1,"STREAM/DROP");
        for(int n=24;n<32;n++) begin
            check_head(n,1,n*16);ack();end
        wait_count(0);
        // 延迟跨越窗口的写响应：B到达前不得发布队头。
        response_delay=300;send_word(2000);send_word(2001);
        repeat(220) @(bus.host_cb);
        if(bus.ready_blocks!=0)
            $fatal(1,"STREAM/EARLY_PUBLISH");
        wait_count(1);check_head(32,2,2000);ack();wait_count(0);
        // 注入写错误响应：该块不得发布，2 个字计入丢弃
        response_delay=3;inject_error=1;send_word(3000);send_word(3001);
        repeat(240) @(bus.host_cb);
        if(bus.ready_blocks!=0 || bus.dropped_frames!=4)
            $fatal(1,"STREAM/ERROR_RESPONSE");
        inject_error=0;send_word(4000);wait_count(1);check_head(33,1,4000);ack();
        $display("TEST PASS tb_rtds_ring V2.01");$finish;
    end
    // 看门狗：2ms 未完成即失败
    initial begin
        #2000000; $fatal(1,"STREAM/WATCHDOG");end
endmodule
