`timescale 1ns/1ps
// FIFO按有效拍存储，不依据SOF/EOF进行组帧；随机高32bit也必须在此层完整透传。
// 回归RTDS_RX_FRAME_FIFO（深度16）：判定按序透传、满丢弃计数、length_error恒0
module tb_rtds_rx_fifo;
    logic user_clk=0,mem_clk=0;    // 用户域与存储域双时钟，初值0由下方always翻转

    // 用户域时钟：周期6.4ns（约156.25MHz）
    always #3.2 user_clk=~user_clk;

    // 存储域时钟：周期4ns（250MHz），与用户域异步，验证跨域透传
    always #2 mem_clk=~mem_clk;
    // 验证接口实例：双域驱动/采样clocking集中定义
    rtds_rx_fifo_test_if bus(user_clk,mem_clk);
    // 被测DUT：RX帧FIFO，深度取16便于快速写满验证满/丢帧行为
    RTDS_RX_FRAME_FIFO #(.FIFO_DEPTH(16)) U_DUT (
        .rst_n(bus.rst_n), .user_clk(user_clk), .user_ready(bus.user_ready),
        .rx_data(bus.rx_data), .rx_sof(bus.rx_sof), .rx_eof(bus.rx_eof),
        .rx_rem(bus.rx_rem), .rx_valid(bus.rx_valid), .rx_ready(bus.rx_ready),
        .mem_clk(mem_clk), .frame_data(bus.frame_data), .frame_valid(bus.frame_valid),
        .frame_ready(bus.frame_ready), .fifo_full(bus.fifo_full),
        .fifo_almost_full(bus.fifo_almost_full), .dropped_frames(bus.dropped_frames),
        .length_error(bus.length_error)
    );
    logic[63:0] expected[$];    // 参考模型队列：按写入顺序记录期望读出的64bit原拍
    int received=0;    // 监视器已核对通过的读出拍计数

    // 输出监视：mem侧每次成功握手弹出期望队列核对，多余/乱序即报EXTRA/ORDER
    always @(bus.mem_mon_cb) begin : monitor
        logic[63:0] value;
        if(bus.mem_mon_cb.rst_n && bus.mem_mon_cb.frame_valid && bus.mem_mon_cb.frame_ready) begin
            // 断言：期望队列已空仍有输出，判多读/重复拍
            if(expected.size()==0)
                $fatal(1,"FIFO/EXTRA");
            value=expected.pop_front();
            // 断言：读出值与期望不符，判乱序或数据损坏
            if(value!==bus.mem_mon_cb.frame_data)
                $fatal(1,"FIFO/ORDER");
            received++;
        end
    end
    // send：驱动一拍64bit写入；n按3/5取模产生随机SOF/EOF组合，stored=1时同步入期望队列
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
    // 主激励：复位释放→连写17拍填满→验证满标志与整拍丢弃→放行读侧逐拍核对→确认无长度错误
    initial begin : stimulus
        repeat(16) @(bus.user_drv_cb);
        bus.user_drv_cb.rst_n<=1;bus.user_drv_cb.user_ready<=1;
        repeat(30) @(bus.user_drv_cb);
        for(int n=0;n<17;n++) send(n,1);
        repeat(20) @(bus.mem_drv_cb);
        // 断言：深度16写入17拍后FIFO必须已置满
        if(!bus.fifo_full)
            $fatal(1,"FIFO/EXPECTED_FULL");
        // 满态再写一拍（stored=0不入期望队列，应被整拍丢弃）
        send(100,0);
        repeat(20) @(bus.mem_drv_cb);
        // 断言：dropped_frames恰为1，证明满态写入被丢弃
        if(bus.dropped_frames!=1)
            $fatal(1,"FIFO/FULL_DROP %d",bus.dropped_frames);
        // 拉高读侧ready，让FIFO排空并完成17拍顺序核对
        bus.mem_drv_cb.frame_ready<=1;
        wait(received==17);
        // 排空后追加一拍并等待读出：确认满释放后恢复正常收发
        send(99,1);wait(received==18);
        // 断言：全程length_error=0，证明存储不依赖SOF/EOF组帧
        if(bus.length_error)
            $fatal(1,"FIFO/FRAME_DEPENDENCE");
        $display("TEST PASS tb_rtds_rx_fifo V2.01");$finish;
    end
    // 看门狗：100us内未打印PASS即判超时，防止仿真挂死
    initial begin
        #100000; $fatal(1,"FIFO/WATCHDOG");end
endmodule
