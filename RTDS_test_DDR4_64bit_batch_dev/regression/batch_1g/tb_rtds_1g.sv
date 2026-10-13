`timescale 1ns/1ps
// 定向前仿：十组 LUT、非法/重复配置、异步时钟、四拍字节序、反压及重建链。
// 无 Aurora IP；检验主机用户接口契约。没有运行，不预填 PASS 结果。
module tb_rtds_1g;
 // 修改记录 2026-10-11：加入随机种子激励。
 `include "rtds_random.svh"   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    logic src_clk = 0;
    logic user_clk = 0;

    // 250MHz 源时钟（半周期 2ns）
    always #2 src_clk = ~src_clk;

    // 31.25MHz 用户时钟（半周期 16ns），与源时钟异步
    always #16 user_clk = ~user_clk;
    rtds_1g_test_if bus(.src_clk(src_clk), .user_clk(user_clk));
    // 被测设计：以250MHz同源2us事件驱动四拍16Byte状态帧
    wire tick_toggle_2us, cpu_sync_50us;
    RTDS_SYNC_TIMEBASE U_TIME (.clk_250m(src_clk),.rst_n(bus.rst_n),.tick_toggle_2us(tick_toggle_2us),.cpu_sync_50us(cpu_sync_50us));
    RTDS_1G_PERIODIC_TX U_DUT (
        .clk_250m(src_clk), .tick_toggle_2us(tick_toggle_2us), .rst_n(bus.rst_n),
        .cfg_byte(bus.cfg_byte), .cfg_byte_valid(bus.cfg_byte_valid),
        .user_clk(user_clk), .user_reset(bus.user_reset), .channel_up(bus.channel_up),
        .tx_ready(bus.tx_ready), .tx_data(bus.tx_data), .tx_rem(bus.tx_rem),
        .tx_sof(bus.tx_sof), .tx_eof(bus.tx_eof), .tx_valid(bus.tx_valid),
        .configured(bus.configured), .configured_id(bus.configured_id),
        .skipped_periods(bus.skipped_periods)
    );
    integer phase2_beat=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    logic[31:0] phase2_expected;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    int expected_duty;    // 当前组期望的占空比码值，用于生成参考载荷
    int expected_voltage;    // 当前组期望的电压码值，用于生成参考载荷
    bit check_cadence=1; // 无反压时检查32ns量化后的相邻发送周期
    time last_sof_time=0;    // 上一帧首拍时刻，用于 2016ns 发送周期检查
    int completed_frames = 0;    // monitor 已完整收到的帧数
    bit partial_frame = 0;    // 组帧中间状态：已收首拍、未收末拍
    bit previous_stall = 0;    // 上一拍是否处于 valid 无 ready 的保持状态
    logic [35:0] held_payload;    // 反压期间应保持不变的发送载荷快照
    logic [31:0] first_word;    // 帧首拍 32bit 数据，末拍拼接比对时使用
    logic [47:0] observed_payload;    // 按规格字节序重组后的实测 48bit 载荷
    logic [47:0] expected_payload;    // 由期望电压/占空比计算出的 48bit 参考载荷

    // 只由 monitor 维护组帧状态。两个字节位于第二拍高 16bit，低 16bit 无效。
    // 比较式从规格整数生成载荷，避免照抄 DUT 的 LUT 和状态转移。

    // 发送监测器：组帧、字节序重组、周期节拍与反压保持检查均在此完成
    always @(bus.tx_mon_cb) begin : monitor_tx
        if (!bus.tx_mon_cb.rst_n || bus.tx_mon_cb.user_reset || !bus.tx_mon_cb.channel_up) begin
            partial_frame = 0; phase2_beat=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
            previous_stall = 0;
            last_sof_time = 0;
        end else begin
            if (previous_stall && (!bus.tx_mon_cb.tx_valid ||
                {bus.tx_mon_cb.tx_sof,bus.tx_mon_cb.tx_eof,bus.tx_mon_cb.tx_rem,bus.tx_mon_cb.tx_data} !== held_payload)) begin
                $fatal(1,"ONE_G/HOLD: stalled payload changed");
            end
            previous_stall = bus.tx_mon_cb.tx_valid && !bus.tx_mon_cb.tx_ready;
            held_payload = {bus.tx_mon_cb.tx_sof,bus.tx_mon_cb.tx_eof,bus.tx_mon_cb.tx_rem,bus.tx_mon_cb.tx_data};
            if (bus.tx_mon_cb.tx_valid && bus.tx_mon_cb.tx_ready) begin
                if ($isunknown(held_payload))
                    $fatal(1,"ONE_G/X: unknown accepted payload");
                case (phase2_beat)   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                  0: phase2_expected={expected_payload[7:0],expected_payload[15:8],expected_payload[23:16],expected_payload[31:24]};   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                  1: phase2_expected={expected_payload[39:32],expected_payload[47:40],8'hf0,8'h00};   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                  default: phase2_expected=0;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                endcase   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                if(bus.tx_mon_cb.tx_sof!=(phase2_beat==0) || bus.tx_mon_cb.tx_eof!=(phase2_beat==3) || bus.tx_mon_cb.tx_rem!=3 || bus.tx_mon_cb.tx_data!==phase2_expected)   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                    $fatal(1,"ONE_G/FOUR_BEAT_TARGET beat=%0d data=%h expected=%h eof=%b rem=%d",phase2_beat,bus.tx_mon_cb.tx_data,phase2_expected,bus.tx_mon_cb.tx_eof,bus.tx_mon_cb.tx_rem);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                if(phase2_beat==0) begin   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                    if(check_cadence && last_sof_time!=0 && $time-last_sof_time!=1984 && $time-last_sof_time!=2016) $fatal(1,"ONE_G/CADENCE");   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                    last_sof_time=$time;
                end
                if(phase2_beat==3) begin phase2_beat=0;partial_frame=0;completed_frames++;end   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
                else begin phase2_beat++;partial_frame=1;end   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
            end
        end
    end
    // 向配置口提交一个字节（单拍 valid 脉冲）
    task automatic submit(input logic [7:0] id);
        @(bus.src_drv_cb);
        bus.src_drv_cb.cfg_byte <= id;
        bus.src_drv_cb.cfg_byte_valid <= 1;
        @(bus.src_drv_cb);
        bus.src_drv_cb.cfg_byte_valid <= 0;
    endtask
    // 等待 monitor 收满 target 帧，超时说明发送功能停摆
    task automatic wait_frames(input int target);
        for (int cycles=0; cycles<2000; cycles++) begin
            @(bus.tx_drv_cb);
            if (completed_frames >= target)
                return;
        end
        $fatal(1,"ONE_G/TIMEOUT: target=%0d actual=%0d",target,completed_frames);
    endtask
    // 主激励：十组参数各执行 复位→配置→反压→断链重建 全流程
    initial begin : stimulus
        int previous_frames;
        // 每组重新上电；复位保持覆盖两个时钟域和无复位端口的 XPM 四相返回。
        for (int id=1; id<=10; id++) begin
            @(bus.src_drv_cb); bus.src_drv_cb.rst_n <= 0;
            @(bus.tx_drv_cb);
            bus.tx_drv_cb.user_reset <= 1; bus.tx_drv_cb.channel_up <= 0; bus.tx_drv_cb.tx_ready <= 0;
            repeat (24) @(bus.tx_drv_cb);
            // 1~3 组 5V、4~7 组 12V、8~10 组 24V，遍历电压 LUT 全部档位
            expected_voltage = (id <= 3) ? 5 : ((id <= 7) ? 12 : 24);
            case (id)
                1,5,8: expected_duty=3000;
                2,6,9: expected_duty=5000;
                3,7,10: expected_duty=8000;
                4: expected_duty=2000;
                default: $fatal(1,"ONE_G/TEST_CONFIG");
            endcase
            @(bus.src_drv_cb); bus.src_drv_cb.rst_n <= 1;
            @(bus.tx_drv_cb);
            bus.tx_drv_cb.user_reset <= 0; bus.tx_drv_cb.channel_up <= 1; bus.tx_drv_cb.tx_ready <= 1;
            check_cadence=1;
            previous_frames=completed_frames;
            // 先提交两个非法 id（0 与 11），验证配置口过滤
            submit(0); submit(11);
            repeat (160) @(bus.tx_drv_cb);
            // 非法 id 不得置起 configured，也不得发出任何帧
            if (completed_frames != previous_frames || bus.configured)
                $fatal(1,"ONE_G/INVALID");
            // 提交有效配置 id，等待至少 2 帧新载荷产出
            expected_payload=(48'(expected_voltage*1048576)<<16)|48'(expected_duty);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
            submit(8'(id));
            wait_frames(previous_frames+2);
            // 锁存的配置号必须等于本次提交的有效 id
            if (bus.configured_id != id)
                $fatal(1,"ONE_G/ID");
            submit(8'd10); // 已锁存后再次配置不改变原始载荷
            wait_frames(previous_frames+3);
            check_cadence=0;
            // 首拍反压跨越多个 2.016us；恢复后只完成在途帧，不补排队任务。
            @(bus.tx_drv_cb); bus.tx_drv_cb.tx_ready <= 0;
            repeat (210+phase2_pick(0,50)) @(bus.tx_drv_cb);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
            // 长反压期间必须累计跳过的发送周期
            if (bus.tx_drv_cb.skipped_periods == 0)
                $fatal(1,"ONE_G/SKIP_NOT_EXERCISED");
            bus.tx_drv_cb.tx_ready <= 1;
            // 接受首拍后，clocking output 在本拍 NBA 拉低 ready，阻塞末拍。
            do @(bus.tx_drv_cb); while (!(bus.tx_drv_cb.tx_valid && bus.tx_drv_cb.tx_sof));
            bus.tx_drv_cb.tx_ready <= 0;
            repeat (90+phase2_pick(0,30)) @(bus.tx_drv_cb);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
            bus.tx_drv_cb.tx_ready <= 1;
            wait_frames(previous_frames+4);
            // 断开链路再重建，验证发送随之恢复
            @(bus.tx_drv_cb); bus.tx_drv_cb.channel_up <= 0;
            repeat (100) @(bus.tx_drv_cb);
            bus.tx_drv_cb.channel_up <= 1;
            previous_frames=completed_frames;
            wait_frames(previous_frames+2);
        end
        @(bus.tx_drv_cb); bus.tx_drv_cb.channel_up <= 0;
        repeat (2) @(bus.tx_drv_cb);
        // 全部用例结束后不得残留半帧状态
        if (partial_frame)
            $fatal(1,"ONE_G/RESIDUAL");
        $display("TEST PASS tb_rtds_1g completed_frames=%0d",completed_frames);
        $finish;
    end
    // 全局看门狗：2ms 未完成即失败
    initial begin : watchdog
        #2000000;
        $fatal(1,"ONE_G/GLOBAL_TIMEOUT");
    end
endmodule
