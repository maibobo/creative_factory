`timescale 1ns/1ps
// 实际发送桥+XPM FIFO专项，不使用Aurora物理核；逐拍验证16Byte帧和反压恢复。
module tb_rtds_tx;
    logic fdma_clk=0,user_clk=0;
    // FDMA 侧时钟 250MHz（半周期 2ns）
    always #2 fdma_clk=~fdma_clk;

    // 用户侧时钟 156.25MHz（半周期 3.2ns），与 FDMA 域异步
    always #3.2 user_clk=~user_clk;
    rtds_tx_test_if bus(fdma_clk,user_clk);
    int received=0,peak_words=0;    // 已验收字数与观测到的 FIFO 占用峰值
    bit monitor_enable=0;    // 复位完成后才使能检查，避免复位期间误报
    logic [69:0] held_payload;    // 反压期间应保持不变的 70bit 发送载荷快照
    bit was_stalled=0;    // 上一拍是否处于 valid 无 ready 的保持状态
    // 被测设计：FDMA 读出经 XPM FIFO 跨域后按 16Byte 帧发送
    fdma_aurora_brg_tx #(.FRAME_BYTES(16),.MEM_WINDOW_BYTES(32768)) U_DUT (
        .fdma_clk(fdma_clk),.fdma_rstn(bus.rst_n),.user_clk(user_clk),.user_rstn(bus.rst_n),
        .channel_up(bus.channel_up),.channel_up_fdma(bus.channel_up),.cfg_tx_burst_limit(bus.limit),
        .fdma_raddr(bus.raddr),.fdma_rareq(bus.rareq),.fdma_rbusy(bus.rbusy),
        .fdma_rdata(bus.rdata),.fdma_rvalid(bus.rvalid),.fdma_rready(bus.rready),
        .tx_d(bus.tx_data),.tx_sof(bus.sof),.tx_eof(bus.eof),.tx_rem(bus.rem),
        .tx_src_rdy(bus.valid),.tx_dst_rdy(bus.ready),.tx_frame_done(bus.done),
        .dbg_fdma_bus(bus.dbg_fdma),.dbg_user_bus(bus.dbg_user)
    );
    // 数据包含递增序号及固定高位，任何丢拍、重拍、错序都会改变比较结果。
    function automatic logic [63:0] payload(input int word_index);
        return {32'hA5C32001,32'(word_index)};
    endfunction
    // 只通过公开调试端口观察FIFO占用及异常，不驱动DUT内部状态。
    initial forever begin
        @(bus.fdma_cb);
        // 记录 FIFO 占用峰值，供近满场景判定
        if(bus.fdma_cb.dbg_fdma[35:26]>peak_words)
            peak_words=bus.fdma_cb.dbg_fdma[35:26];
        // 调试口 FIFO 溢出标志置位即失败
        if(monitor_enable && bus.fdma_cb.dbg_fdma[0])
            $fatal(1,"TX/FIFO_OVERFLOW");
    end
    // 用户侧监测：核对数据序号、SOF/EOF 边界与反压保持
    initial forever begin
        @(bus.monitor_cb);
        if(monitor_enable) begin
            if(was_stalled && (!bus.monitor_cb.valid ||
                {bus.monitor_cb.tx_data,bus.monitor_cb.sof,bus.monitor_cb.eof,bus.monitor_cb.rem}!==held_payload))
                $fatal(1,"TX/STALL_HOLD");
            // 被接受的字必须匹配期望序号与奇偶交替的帧边界
            if(bus.monitor_cb.valid && bus.monitor_cb.ready) begin
                if(bus.monitor_cb.tx_data!==payload(received) || bus.monitor_cb.sof!==(received%2==0) ||
                    bus.monitor_cb.eof!==(received%2==1) || bus.monitor_cb.rem!==3'd7)
                    $fatal(1,"TX/DATA_OR_BOUNDARY word=%0d actual=%h",received,bus.monitor_cb.tx_data);
                received++;
            end
            // 调试口 FIFO 下溢标志置位即失败
            if(bus.monitor_cb.dbg_user[0])
                $fatal(1,"TX/FIFO_UNDERFLOW");
            was_stalled=bus.monitor_cb.valid && !bus.monitor_cb.ready;
            held_payload={bus.monitor_cb.tx_data,bus.monitor_cb.sof,bus.monitor_cb.eof,bus.monitor_cb.rem};
        end else begin
            was_stalled=0;
        end
    end
    // FDMA 从端角色：按帧号×16Byte 步进地址供给递增序号数据
    task automatic produce(input int frames);
        for(int frame_id=0;frame_id<frames;frame_id++) begin
            do @(bus.fdma_cb); while(!bus.fdma_cb.rareq);
            // 读地址必须严格按帧号步进 16 字节
            if(bus.fdma_cb.raddr!==32'(frame_id*16))
                $fatal(1,"TX/ADDRESS");
            bus.fdma_cb.rbusy<=1;
            for(int beat=0;beat<2;beat++) begin
                bus.fdma_cb.rdata<=payload(frame_id*2+beat);
                bus.fdma_cb.rvalid<=1;
                do @(bus.fdma_cb); while(!bus.fdma_cb.rready);
            end
            bus.fdma_cb.rvalid<=0;
            bus.fdma_cb.rbusy<=0;
            do @(bus.fdma_cb); while(bus.fdma_cb.rareq);
        end
    endtask
    // 用户接收角色：先长时间停顿再周期性放行，构造各类反压
    task automatic consume(input int frames,input int hold_cycles);
        @(bus.tx_cb);
        bus.tx_cb.ready<=0;
        repeat(hold_cycles) @(bus.tx_cb);
        for(int cycle=0;received<frames*2;cycle++) begin
            @(bus.tx_cb);
            // 先长时间堵塞使FIFO达到阈值，再周期性停顿，覆盖首末拍保持。
            bus.tx_cb.ready<=((cycle%7)<4);
        end
        repeat(20) @(bus.tx_cb);
        bus.tx_cb.ready<=0;
    endtask
    // 单轮用例：复位→起链→生产/消费并行→汇合后校验
    task automatic run_case(input int frames,input int hold_cycles);
        monitor_enable=0;
        @(bus.fdma_cb);
        bus.fdma_cb.rst_n<=0;
        bus.fdma_cb.channel_up<=0;
        bus.fdma_cb.limit<=16'(frames);
        repeat(20) @(bus.fdma_cb);
        received=0;peak_words=0;
        bus.fdma_cb.rst_n<=1;
        repeat(20) @(bus.fdma_cb);
        monitor_enable=1;
        bus.fdma_cb.channel_up<=1;
        fork
            produce(frames);
            consume(frames,hold_cycles);
        join
        // 汇合后验收字数必须恰好等于帧数×2
        if(received!=frames*2)
            $fatal(1,"TX/COUNT");
        // 大批量用例必须真实到达 FIFO 近满区
        if(frames>256 && peak_words<500)
            $fatal(1,"TX/NEAR_FULL_NOT_REACHED peak=%0d",peak_words);
        $display("TX CASE PASS frames=%0d peak=%0d",frames,peak_words);
    endtask
    // 顶层流程：先单帧冒烟，再大批量近满+反压用例
    initial begin
        run_case(1,10);
        run_case(300,3000);
        $display("TEST PASS tb_rtds_tx single/batch/near_full/backpressure");
        $finish;
    end
    // 看门狗：2ms 未完成即失败
    initial begin
        #2000000;
        $fatal(1,"TX/WATCHDOG received=%0d",received);
    end
endmodule
