`timescale 1ns/1ps
// 主机配置到 1G 用户接口；不例化 Aurora，不包含 Buck 算法。
// cfg_byte_valid 仅在一帧首个 DDR 读数据拍被接收时有效。
module RTDS_1G_PERIODIC_TX #(
    parameter integer PERIOD_CYCLES = 63
) (
    input wire clk_250m, // 控制时钟 250MHz；仅用于配置提交；周期在 user_clk 域产生
    input wire rst_n, // 主机低有效逻辑复位；配置和统计的唯一全局清除入口
    input wire [7:0] cfg_byte, // 完整 16Byte 下行帧 Byte1，合法编号为 1~10
    input wire cfg_byte_valid, // DDR 首拍实际接受事件；不能使用未握手数据
    input wire user_clk, // Aurora 用户域时钟，1G 为 31.25MHz，RX 包装层为 10G 用户时钟
    input wire user_reset, // 1G 链路/接口复位；丢弃在途帧但保留已配置参数
    input wire channel_up, // 用户域链路可运行状态，拉低中止帧
    input wire tx_ready, // 目的端接受能力；有效拍必须保持到握手
    output wire [31:0] tx_data, // 32bit 用户数据，先发字节放在高位
    output wire [1:0] tx_rem, // 当前拍有效字节数减一，首拍3、末拍1
    output wire tx_sof, // 首拍标记，反压时保持
    output wire tx_eof, // 末拍标记，反压时保持
    output wire tx_valid, // 有效拍；发送开始后不能因周期结束撤销
    output reg configured, // 配置已跨域确认，控制域状态
    output reg [7:0] configured_id, // 第一次合法编号，后续配置帧不覆盖
    output reg [31:0] skipped_periods // 用户域累计跳过周期；调试读取须遵守时钟域
);
    wire src_rst_n; // 250MHz 域同步释放
    wire user_rst_n; // 31.25MHz 域同步释放；独立于 user_reset
    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_SRC (
        .clk(clk_250m), .rst_async_n(rst_n), .rst_sync_n(src_rst_n)
    );
    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_USER (
        .clk(user_clk), .rst_async_n(rst_n), .rst_sync_n(user_rst_n)
    );
    reg [47:0] cfg_hold; // 请求期间保持不变：{Vin,duty}
    reg cfg_req; // 上电一次的邮箱请求，直到主机复位保持
    reg cfg_ack; // 目的域已经原子接收全部 48bit
    wire req_sync; // XPM 目的域请求
    wire [47:0] cfg_cdc_data; // XPM 保证原子传递的配置
    wire cfg_send; // 完成确认后撤销源端请求
    wire cfg_dest_ack; // 请求撤销时同时撤销目的端确认
    wire ack_sync; // XPM 返回源域的接收确认
    reg [47:0] cfg_user; // 仅在完整请求同步后采样，多位总线不逐位打拍
    reg [31:0] period_count;    // 用户域周期计数器（每63拍一次发送机会）
    wire period_tick; // 用户域63拍一次，不跨时钟传递周期事件
    // 配置握手完成后，1G用户域每63拍产生一次发送机会；忙时不排队。
    assign period_tick = cfg_ack && (period_count == PERIOD_CYCLES - 1);
    reg [2:0] arm_count; // 建链/接口复位后先吸收历史事件
    reg [1:0] tx_curr_st;    // 发送状态机现态
    // 发送状态编码：IDLE→FIRST（首拍）→LAST（末拍）。
    localparam [1:0] IDLE = 2'd0, FIRST = 2'd1, LAST = 2'd2;
    reg [15:0] decoded_duty;    // 译码后的占空比（1~10号→2000~8000）
    reg [31:0] decoded_vin;    // 译码后的电压值（电压×1048576 定点）
    reg decode_valid;    // 编号合法标志（1~10以外为非法）

    // CUSTOM-RTL-001 组合译码例外：duty/Vin/valid 共享同一编号分支，
    // 合并便于逐行核对参数表；无时钟或复位生命周期混合。

    always @(*) begin
        decoded_duty = 16'd0;
        decoded_vin = 32'd0;
        decode_valid = 1'b1;
        case (cfg_byte)
            8'd1: begin
                decoded_duty=16'd3000; decoded_vin=32'h00500000; end
            8'd2: begin
                decoded_duty=16'd5000; decoded_vin=32'h00500000; end
            8'd3: begin
                decoded_duty=16'd8000; decoded_vin=32'h00500000; end
            8'd4: begin
                decoded_duty=16'd2000; decoded_vin=32'h00c00000; end
            8'd5: begin
                decoded_duty=16'd3000; decoded_vin=32'h00c00000; end
            8'd6: begin
                decoded_duty=16'd5000; decoded_vin=32'h00c00000; end
            8'd7: begin
                decoded_duty=16'd8000; decoded_vin=32'h00c00000; end
            8'd8: begin
                decoded_duty=16'd3000; decoded_vin=32'h01800000; end
            8'd9: begin
                decoded_duty=16'd5000; decoded_vin=32'h01800000; end
            8'd10:begin
                decoded_duty=16'd8000; decoded_vin=32'h01800000; end
            default: begin
                decode_valid=1'b0; end
        endcase
    end

    // 一次配置邮箱：source 发请求并保持数据，destination 返回接收确认。
    // 数据由 XPM 邮箱传递，cfg_hold 在整个上电周期保持不变。
        // cfg_hold：首次合法配置提交后保持至主机复位；传递期间不允许源数据改变。

    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_cfg_hold
        if (! src_rst_n) begin
            cfg_hold <= 48'd0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                cfg_hold <= { decoded_vin , decoded_duty } ;
            end
        end
    end

    // cfg_req：一次配置提交标记；不随 Aurora 链路掉线清除。

    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_cfg_req
        if (! src_rst_n) begin
            cfg_req <= 1'b0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                cfg_req <= 1'b1 ;
            end
        end
    end

    // configured：源端收到 XPM 确认后锁存，用于启动独立周期计时。

    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_configured
        if (! src_rst_n) begin
            configured <= 1'b0 ;
        end else begin
            if (ack_sync) begin
                configured <= 1'b1 ;
            end
        end
    end

    // configured_id：保存第一次合法编号供调试，重复提交不改变该编号。

    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_configured_id
        if (! src_rst_n) begin
            configured_id <= 8'd0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                configured_id <= cfg_byte ;
            end
        end
    end

    // period_count：配置到达后连续计时；忙和链路掉线不累计待发任务。

    always @(posedge user_clk or negedge user_rst_n) begin : update_period_count
        if (!user_rst_n)
            period_count <= 32'd0;
        else if (!cfg_ack || period_tick)
            period_count <= 32'd0;
        else
            period_count <= period_count + 32'd1;
    end

        // cfg_ack：目的域完整接收标记；与外部链路复位分离，恢复后继续使用旧参数。

    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_cfg_ack
        if (! user_rst_n) begin
            cfg_ack <= 1'b0 ;
        end else begin
            if (req_sync && ! cfg_ack) begin
                cfg_ack <= 1'b1 ;
            end
        end
    end

    // cfg_user：目的域只在 XPM 请求有效且尚未配置时原子采样。

    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_cfg_user
        if (! user_rst_n) begin
            cfg_user <= 48'd0 ;
        end else begin
            if (req_sync && ! cfg_ack) begin
                cfg_user <= cfg_cdc_data ;
            end
        end
    end

    // arm_count：链路恢复后等待同步链稳定，吸收停机期间遗留的周期事件。

    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_arm_count
        if (! user_rst_n) begin
            arm_count <= 3'd0 ;
        end else begin
            if (user_reset || ! channel_up || ! cfg_ack) begin
                arm_count <= 3'd0 ;
            end else begin
                if (arm_count != 3'd4) begin
                    arm_count <= arm_count + 3'd1 ;
                end
            end
        end
    end

    // tx_curr_st：事务寄存器按原状态分支和握手条件更新；未命中分支保持，复位回到确定初值。
    reg [1:0] tx_next_st; // 完整组合次态，默认保持当前态
    // 两段式状态机：输出由当前态形成，只有实际握手才推进；非法态回空闲。

    always @(*) begin : calculate_tx_next_st
        tx_next_st = tx_curr_st;

        if (!user_rst_n) begin
            tx_next_st = IDLE;
        end else if (user_reset || !channel_up || !cfg_ack || arm_count != 3'd4) begin
            tx_next_st = IDLE;
        end else begin
            case (tx_curr_st)
                IDLE: begin
                    if (period_tick) begin
                        tx_next_st = FIRST;
                    end
                end
                FIRST: begin
                    if (tx_ready) begin
                        tx_next_st = LAST;
                    end
                end
                LAST: begin
                    if (tx_ready) begin
                        tx_next_st = IDLE;
                    end
                end
                default: begin
                    tx_next_st = IDLE;
                end
            endcase
        end
        end

    always @(posedge user_clk or negedge user_rst_n) begin : register_tx_state
        if (!user_rst_n) begin
            tx_curr_st <= IDLE;
        end else begin
            tx_curr_st <= tx_next_st;
        end
    end

    // skipped_periods：忙时到达的周期任务只累计统计，当前有效数据拍继续等待握手。

    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_skipped_periods
        if (! user_rst_n) begin
            skipped_periods <= 32'd0 ;
        end else begin
            if (user_reset || ! channel_up || ! cfg_ack) begin
            end else begin
                if (arm_count != 3'd4) begin
                end else begin
                    if (period_tick) begin
                        if (tx_curr_st == IDLE) begin
                        end else begin
                            skipped_periods <= skipped_periods + 32'd1 ;
                        end
                    end
                end
            end
        end
    end


    // 四相邮箱：cfg_req 记录已经提交，configured 记录已经确认，两者上电保持。
    // src_send 在确认后撤销；dst_ack 随请求撤销，XPM 返回空闲后不再发送配置。
    assign cfg_send = cfg_req && !configured && rst_n;
    // 目的域收到并锁存参数后确认；源请求撤销后确认随之释放。
    assign cfg_dest_ack = req_sync && cfg_ack && rst_n;
    RTDS_FPGA_CFG_CDC U_RTDS_FPGA_CFG_CDC (
        .src_clk(clk_250m), .dst_clk(user_clk), .src_data(cfg_hold),
        .src_send(cfg_send), .dst_ack(cfg_dest_ack), .src_rcv(ack_sync),
        .dst_req(req_sync), .dst_data(cfg_cdc_data)
    );

    // 封装为降序 [31:0] 数据，线上第一个字节在 [31:24]。
    // 载荷顺序 duty低、高、Vin最低、次低、次高、最高。
    assign tx_data = (tx_curr_st == FIRST) ?
        {cfg_user[7:0], cfg_user[15:8], cfg_user[23:16], cfg_user[31:24]} :
        {cfg_user[39:32], cfg_user[47:40], 16'd0};
    // 1G尾拍只含两个有效字节，REM为有效字节数减一。
    assign tx_rem = (tx_curr_st == LAST) ? 2'd1 : 2'd3;
    // 首拍标记随FIRST状态保持，反压时不提前撤销。
    assign tx_sof = (tx_curr_st == FIRST);
    // 末拍标记随LAST状态保持，直到握手完成。
    assign tx_eof = (tx_curr_st == LAST);
    // 仅在链路可用且存在待发拍时有效；数据状态机负责反压保持。
    assign tx_valid = (tx_curr_st != IDLE) && channel_up && !user_reset;
endmodule
