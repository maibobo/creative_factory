// 首次合法Byte1编号1～10查表得到duty和Vin，完整48bit配置跨域后锁定。
// 250MHz产生的2µs事件同步到31.25MHz用户域，事件到来时尝试发送4×32bit。
// 16Byte四拍格式：第一拍Vin[31:0]；第二拍duty放在[31:16]；第三拍预留；第四拍[15:0]=16'hEB90。
// 反压保持当前拍；忙时跳过事件，不补发。用户复位或断链中止帧，主机复位才清首次配置。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_1G_PERIODIC_TX (
    input wire                                 clk_250m,                              // 250MHz业务/时间基准时钟
    input wire                                 tick_toggle_2us,                       // 250MHz域每2µs翻转一次的事件标志
    input wire                                 rst_n,                                 // 低有效全局复位输入
    input wire    [7:0]                        cfg_byte,                              // 首读拍Byte1配置编号
    input wire                                 cfg_byte_valid,                        // 该帧首读拍被实际接受的配置事件
    input wire                                 user_clk,                              // Aurora 1G 用户域时钟，31.25MHz
    input wire                                 user_reset,                            // 1G 链路/接口复位；丢弃在途帧但保留已配置参数
    input wire                                 channel_up,                            // 用户域链路可运行状态，拉低中止帧
    input wire                                 tx_ready,                              // 目的端接受能力；有效拍必须保持到握手
    output wire   [31:0]                       tx_data,                               // 32bit 用户数据，先发字节放在高位
    output wire   [1:0]                        tx_rem,                                // 四拍均为4个有效字节，固定为3
    output wire                                tx_sof,                                // 首拍标记，反压时保持
    output wire                                tx_eof,                                // 末拍标记，反压时保持
    output wire                                tx_valid,                              // 有效拍；发送开始后不能因周期结束撤销
    output reg                                 configured,                            // 首次配置跨域确认已完成
    output reg    [7:0]                        configured_id,                         // 首次合法配置编号
    output reg    [31:0]                       skipped_periods                        // 忙或反压遇周期事件的32bit跳过计数
);


    localparam    [2:0]                        IDLE     = 3'd0             ;    // 尚无正在发送的数据拍
    localparam    [2:0]                        FIRST    = 3'd1             ;    // 正在发送Byte0~3
    localparam    [2:0]                        SECOND   = 3'd2             ;    // 正在发送Byte4~7
    localparam    [2:0]                        THIRD    = 3'd3             ;    // 正在发送预留Byte8~11
    localparam    [2:0]                        FOURTH   = 3'd4             ;    // 正在发送预留Byte12~15


    wire                                       src_rst_n                   ;    // 源时钟域同步解除后的低有效复位
    wire                                       user_rst_n                  ;    // 用户时钟域同步解除后的低有效复位


    reg           [15:0]                       decoded_duty                ;    // 编号查表得到的16bit占空比整数
    reg           [31:0]                       decoded_vin                 ;    // 编号查表得到的32bit电压定点值
    reg                                        decode_valid                ;    // 编号处于合法1～10范围


    reg           [47:0]                       cfg_hold                    ;    // 源域首次合法配置的完整48bit参数
    reg                                        cfg_req                     ;    // 首次合法配置请求已提交并保持
    wire                                       cfg_send                    ;    // 源端配置握手提交许可
    wire                                       ack_sync                    ;    // 返回源域的配置确认
    wire                                       req_sync                    ;    // 目的域收到的配置请求
    wire          [47:0]                       cfg_cdc_data                ;    // XPM传递到目的侧的完整48bit参数
    reg           [47:0]                       cfg_user                    ;    // 用户域已经接收并锁定的完整48bit配置
    reg                                        cfg_ack                     ;    // 用户域已接收首次配置
    reg                                        cfg_dest_ack                ;    // 用户域寄存后的配置接受确认


    (* ASYNC_REG = "TRUE" *) reg [1:0] tick_sync                           ;    // 用户域同步的两级事件翻转位
    reg                                        tick_seen                   ;    // 用户域上一拍同步翻转位
    wire                                       period_tick                 ;    // 用户域恢复出的单拍周期事件
    reg           [2:0]                        arm_count                   ;    // 链路与配置有效后的4拍启动等待计数
    reg           [2:0]                        tx_curr_st                  ;    // 四拍发送状态机的当前状态
    reg           [2:0]                        tx_next_st                  ;    // 组合逻辑计算的下一发送状态


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


    // 组合译码编号1～10为duty和Vin；非法编号给默认0且decode_valid=0，所有分支都有赋值。
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


    // 控制域只在首个合法配置事件时保存完整48bit参数，此后保持到主机复位。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_cfg_hold
        if (! src_rst_n) begin
            cfg_hold <= 48'd0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                cfg_hold <= { decoded_vin , decoded_duty } ;
            end
        end
    end


    // 首个合法配置到来后保持请求，禁止后续配置覆盖已保存参数。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_cfg_req
        if (! src_rst_n) begin
            cfg_req <= 1'b0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                cfg_req <= 1'b1 ;
            end
        end
    end


    // 收到目的域确认后记录配置完成，只有主机复位清除。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_configured
        if (! src_rst_n) begin
            configured <= 1'b0 ;
        end else begin
            if (ack_sync) begin
                configured <= 1'b1 ;
            end
        end
    end


    // 首次合法配置时保存编号，后续编号不覆盖。
    always @ ( posedge clk_250m or negedge src_rst_n ) begin : update_configured_id
        if (! src_rst_n) begin
            configured_id <= 8'd0 ;
        end else begin
            if (cfg_byte_valid && decode_valid && ! cfg_req) begin
                configured_id <= cfg_byte ;
            end
        end
    end


    assign cfg_send = cfg_req && !configured && rst_n                      ;    // 源端配置握手提交许可


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


    // 用户域寄存配置接受确认，避免组合确认直接进入跨域模块。
    always @(posedge user_clk or negedge user_rst_n) begin
        if (!user_rst_n) cfg_dest_ack <= 1'b0;
        else cfg_dest_ack <= req_sync && cfg_ack;
    end


    // 用户域仅第一次配置请求建立时记录已接收，主机复位清除。
    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_cfg_ack
        if (! user_rst_n) begin
            cfg_ack <= 1'b0 ;
        end else begin
            if (req_sync && ! cfg_ack) begin
                cfg_ack <= 1'b1 ;
            end
        end
    end


    // 用户域在首次请求到达时保存完整跨域参数，避免duty和Vin来自不同配置。
    always @ ( posedge user_clk or negedge user_rst_n ) begin : update_cfg_user
        if (! user_rst_n) begin
            cfg_user <= 48'd0 ;
        end else begin
            if (req_sync && ! cfg_ack) begin
                cfg_user <= cfg_cdc_data ;
            end
        end
    end


    // 持续同步2µs翻转事件并保存上一拍值；链路暂停时也跟踪，不累存旧事件。
    always @(posedge user_clk or negedge user_rst_n) begin : sync_period_event
        if (!user_rst_n) begin
            tick_sync <= 2'b00;
            tick_seen <= 1'b0;
        end else begin
            tick_sync <= {tick_sync[0], tick_toggle_2us};
            tick_seen <= tick_sync[1];
        end
    end

    assign period_tick = tick_sync[1] ^ tick_seen                          ;    // 用户域恢复出的单拍周期事件


    // 配置和链路有效后等待4个用户时钟才开放发送，失效时重新计数。
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


    // 事件到来且ready有效时开始四拍；各拍只随握手推进，反压保持，失效立即回空闲。
    always @(*) begin : calculate_tx_next_st
        tx_next_st = tx_curr_st;
        if (!user_rst_n || user_reset || !channel_up || !cfg_ack || arm_count != 3'd4) begin
            tx_next_st = IDLE;
        end else begin
            case (tx_curr_st)
                IDLE:   if (period_tick && tx_ready) tx_next_st = FIRST;
                FIRST:  if (tx_ready) tx_next_st = SECOND;
                SECOND: if (tx_ready) tx_next_st = THIRD;
                THIRD:  if (tx_ready) tx_next_st = FOURTH;
                FOURTH: if (tx_ready) tx_next_st = IDLE;
                default: tx_next_st = IDLE;
            endcase
        end
    end


    // 用户时钟沿保存四拍发送状态，低有效复位回IDLE。
    always @(posedge user_clk or negedge user_rst_n) begin : register_tx_state
        if (!user_rst_n) begin
            tx_curr_st <= IDLE;
        end else begin
            tx_curr_st <= tx_next_st;
        end
    end


    // 仅已配置、链路有效且恢复等待结束时累计忙/反压跳过次数；32bit自然回绕，不补发。
    always @(posedge user_clk or negedge user_rst_n) begin : update_skipped_periods
        if (!user_rst_n)
            skipped_periods <= 32'd0;
        else if (!user_reset && channel_up && cfg_ack && arm_count == 3'd4 &&
                 period_tick && (tx_curr_st != IDLE || !tx_ready))
            skipped_periods <= skipped_periods + 32'd1;
    end


    assign tx_data =
        (tx_curr_st == FIRST)  ? cfg_user[47:16] :
        (tx_curr_st == SECOND) ? {cfg_user[15:0], 16'h0000} :
        (tx_curr_st == FOURTH) ? {16'h0000, 16'hEB90} :
                                32'd0                                      ;    // 保持原位序；第四拍低16bit为同步字EB90

    assign tx_rem = 2'd3                                                   ;    // 四拍均为4个有效字节，固定为3
    assign tx_sof = (tx_curr_st == FIRST)                                  ;    // 首拍标记，反压时保持
    assign tx_eof = (tx_curr_st == FOURTH)                                 ;    // 末拍标记，反压时保持
    assign tx_valid = (tx_curr_st != IDLE) && channel_up && !user_reset    ;    // 有效拍；发送开始后不能因周期结束撤销
endmodule
