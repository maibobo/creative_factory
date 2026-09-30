`timescale 1ns/1ps
// 功能：从250MHz控制域接收首次合法配置编号，查表得到占空比和电压值。
// 通过配置跨域模块将完整48位参数送到Aurora 1G用户时钟域。
// 配置完成后每PERIOD_CYCLES拍尝试发送两拍数据；反压期间保持当前拍。
// 链路断开或用户接口复位会中止当前帧，已锁定的配置保留到主机复位。
// 输出数据按线上发送字节顺序排列，末拍只有两个有效字节。
module RTDS_1G_PERIODIC_TX #(
    parameter integer  PERIOD_CYCLES = 63    // 两次发送机会之间的用户时钟拍数。
) (
    input  wire          clk_250m,           // 控制时钟 250MHz；仅用于配置提交；周期在 user_clk 域产生
    input  wire          rst_n,              // 主机低有效逻辑复位；配置和统计的唯一全局清除入口
    input  wire [7:0]    cfg_byte,           // 完整 16Byte 下行帧 Byte1，合法编号为 1~10
    input  wire          cfg_byte_valid,     // DDR 首拍实际接受事件；不能使用未握手数据
    input  wire          user_clk,           // Aurora 用户域时钟，1G 为 31.25MHz，RX 包装层为 10G 用户时钟
    input  wire          user_reset,         // 1G 链路/接口复位；丢弃在途帧但保留已配置参数
    input  wire          channel_up,         // 用户域链路可运行状态，拉低中止帧
    input  wire          tx_ready,           // 目的端接受能力；有效拍必须保持到握手
    output wire [31:0]   tx_data,            // 32bit 用户数据，先发字节放在高位
    output wire [1:0]    tx_rem,             // 当前拍有效字节数减一，首拍3、末拍1
    output wire          tx_sof,             // 首拍标记，反压时保持
    output wire          tx_eof,             // 末拍标记，反压时保持
    output wire          tx_valid,           // 有效拍；发送开始后不能因周期结束撤销
    output reg           configured,         // 配置已跨域确认，控制域状态
    output reg  [7:0]    configured_id,      // 第一次合法编号，后续配置帧不覆盖
    output reg  [31:0]   skipped_periods     // 用户域累计跳过周期；调试读取须遵守时钟域
);

    // 状态机编码。
    localparam [1:0] IDLE     = 2'd0;    // 尚无正在发送的数据拍。
    localparam [1:0] FIRST    = 2'd1;    // 正在发送首拍。
    localparam [1:0] LAST     = 2'd2;    // 正在发送末拍。

    // 两个时钟域的复位信号。
    wire      src_rst_n                                                ;    // 250MHz控制域同步解除后的复位。
    wire      user_rst_n                                               ;    // Aurora用户域同步解除后的复位。

    // 编号译码信号。
    reg     [15:0]  decoded_duty                                       ;    // 编号对应的占空比，组合查表得出。
    reg     [31:0]  decoded_vin                                        ;    // 编号对应的定点电压值，组合查表得出。
    reg             decode_valid                                       ;    // 编号在1到10范围内时为1。

    // 配置跨域信号。
    reg     [47:0]  cfg_hold                                           ;    // 控制域首次合法配置的48位参数。
    reg             cfg_req                                            ;    // 控制域已记录配置的保持标志。
    wire            cfg_send                                           ;    // 控制域送给跨域模块的请求。
    wire            ack_sync                                           ;    // 目的端确认返回控制域后的信号。
    wire            req_sync                                           ;    // 跨域模块送到用户域的请求。
    wire    [47:0]  cfg_cdc_data                                       ;    // 跨域模块送到用户域的完整参数。
    reg     [47:0]  cfg_user                                           ;    // 用户域已锁定的48位参数。
    reg             cfg_ack                                            ;    // 用户域已经接收参数的保持标志。
    reg             cfg_dest_ack                                       ;    // 用户域返回跨域模块的寄存确认。

    // 发送周期和状态信号。
    reg     [31:0]  period_count                                       ;    // 用户域的周期计数。
    wire            period_tick                                        ;    // 周期计满时产生的单拍事件。
    reg     [2:0]   arm_count                                          ;    // 链路恢复后等待四拍的计数。
    reg     [1:0]   tx_curr_st                                         ;    // 两拍发送状态机的当前状态。
    reg     [1:0]   tx_next_st                                         ;    // 组合逻辑计算的下一发送状态。


    // 复位同步和配置编号译码。
    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_SRC (
        .clk(clk_250m),
        .rst_async_n(rst_n),
        .rst_sync_n(src_rst_n)
    );

    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_USER (
        .clk(user_clk),
        .rst_async_n(rst_n),
        .rst_sync_n(user_rst_n)
    );

    // 组合查表同时给占空比、电压值和合法标志赋值；默认值避免锁存器。
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


    // 控制域锁定首次合法配置。
    // 首次合法编号到达时锁定完整参数。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_cfg_hold
        if (! src_rst_n) begin
            cfg_hold <= 48'd0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                cfg_hold <= { decoded_vin , decoded_duty } ;
            end
        end
    end

    // 首次合法编号到达后保持跨域请求标志。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_cfg_req
        if (! src_rst_n) begin
            cfg_req <= 1'b0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                cfg_req <= 1'b1 ;
            end
        end
    end

    // 源端收到返回确认后记录配置完成。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_configured
        if (! src_rst_n) begin
            configured <= 1'b0 ;
        end else begin
            if (ack_sync) begin
                configured <= 1'b1 ;
            end
        end
    end

    // 控制域保存首次合法编号。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_configured_id
        if (! src_rst_n) begin
            configured_id <= 8'd0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                configured_id <= cfg_byte ;
            end
        end
    end

    // 跨域请求条件。
    assign cfg_send = cfg_req && !configured && rst_n                  ;    // 源端已记录配置且尚未收到确认时保持跨域请求。


    // 用户域接收配置并计时。
    RTDS_FPGA_CFG_CDC U_RTDS_FPGA_CFG_CDC (
        .src_clk(clk_250m),
        .dst_clk(user_clk),
        .src_data(cfg_hold),
        .src_send(cfg_send),
        .dst_ack(cfg_dest_ack),
        .src_rcv(ack_sync),
        .dst_req(req_sync),
        .dst_data(cfg_cdc_data)
    );

    // 把目的端确认寄存后送回跨域模块。
    always @(posedge user_clk or negedge user_rst_n) begin
        if (!user_rst_n) cfg_dest_ack <= 1'b0;
        else cfg_dest_ack <= req_sync && cfg_ack;
    end

    // 目的端收到请求后记录已接收状态。
    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_cfg_ack
        if (! user_rst_n) begin
            cfg_ack <= 1'b0 ;
        end else begin
            if (req_sync && ! cfg_ack) begin
                cfg_ack <= 1'b1 ;
            end
        end
    end

    // 目的端只在首次请求到达时锁定完整参数。
    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_cfg_user
        if (! user_rst_n) begin
            cfg_user <= 48'd0 ;
        end else begin
            if (req_sync && ! cfg_ack) begin
                cfg_user <= cfg_cdc_data ;
            end
        end
    end

    // 用户域按固定拍数循环计数。
    always @(posedge user_clk or negedge user_rst_n) begin : update_period_count
        if (!user_rst_n)
            period_count <= 32'd0;
        else if (!cfg_ack || period_tick)
            period_count <= 32'd0;
        else
            period_count <= period_count + 32'd1;
    end

    // 链路恢复后等待四拍再允许发送。
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

    // 周期到达条件。
    assign period_tick = cfg_ack && (period_count == PERIOD_CYCLES - 1);    // 配置已到达且计满一个发送周期时产生单拍事件。


    // 两拍发送控制和统计。
    // 根据链路状态、周期事件和握手计算发送次态。
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

    // 在用户时钟沿锁定发送次态。
    always @(posedge user_clk or negedge user_rst_n) begin : register_tx_state
        if (!user_rst_n) begin
            tx_curr_st <= IDLE;
        end else begin
            tx_curr_st <= tx_next_st;
        end
    end

    // 发送忙时统计错过的周期机会。
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


    // 发送数据和接口标志。

    // 组合输出。
    assign tx_data = (tx_curr_st == FIRST) ?
        {cfg_user[7:0], cfg_user[15:8], cfg_user[23:16], cfg_user[31:24]} :
        {cfg_user[39:32], cfg_user[47:40], 16'd0}                      ;    // 首拍发送duty的低、高字节及Vin低两字节，末拍发送Vin高两字节。
    assign tx_rem = (tx_curr_st == LAST) ? 2'd1 : 2'd3                 ;    // 末拍有两个有效字节，其余拍有四个。
    assign tx_sof = (tx_curr_st == FIRST)                              ;    // 首拍状态持续提供帧起始标记。
    assign tx_eof = (tx_curr_st == LAST)                               ;    // 末拍状态持续提供帧结束标记。
    assign tx_valid = (tx_curr_st != IDLE) && channel_up && !user_reset;    // 发送状态有效且链路可用时提供有效拍。
endmodule
