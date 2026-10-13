// 10G协议核的板级封装，连接GT差分引脚、参考时钟和LocalLink业务接口。
// 业务传输使用协议核输出的user_clk，初始化使用独立clk_init。
// 包含上电复位顺序模块：保持PMA复位后先释放PMA，再经过间隔释放协议复位。
// 官方协议核内部保持原样；本文件负责外围连接和复位顺序。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module aurora_64b66b_top #(
    parameter                                  SIMULATION         = 0,                   // 本模块SIMULATION固定配置/状态编码
    parameter integer                             INIT_CLK_FREQ_HZ   = 100_000_000,      // 对应接口时钟，使用域由连接关系确定
    parameter integer                             PMA_HOLD_TIME_MS   = 1_600,            // 本模块PMA_HOLD_TIME_MS固定配置/状态编码
    parameter integer                             RESET_GAP_TIME_MS  = 20                // 高有效复位或同步复位状态
)(

    input                                      clk_init            ,                     // 对应接口时钟，使用域由连接关系确定
    input                                      sys_rst             ,                     // 高有效系统复位


    input                                      GTHQ0_P             ,                     // GT参考差分时钟正端
    input                                      GTHQ0_N             ,                     // GT参考差分时钟负端
    input                                      RXP                 ,                     // GT接收差分正端
    input                                      RXN                 ,                     // GT接收差分负端
    output                                     TXP                 ,                     // GT发送差分正端
    output                                     TXN                 ,                     // GT发送差分负端

    output                                     sfp_tx_disable      ,                     // SFP发送禁止控制，当前固定允许发送
    output                                     sfp_rs0             ,                     // SFP速率选择控制位0
    output                                     sfp_rs1             ,                     // SFP速率选择控制位1


    input         [63: 0]                      tx_d                ,                     // 发送当前数据拍
    input                                      tx_sof              ,                     // 当前帧首拍标志，与有效/接受共同使用
    input                                      tx_eof              ,                     // 当前帧末拍标志，与有效/接受共同使用
    input         [ 2: 0]                      tx_rem              ,                     // 当前拍有效字节数减1
    input                                      tx_src_vld          ,                     // 10G LocalLink发送有效，随当前拍保持
    output                                     tx_dst_rdy          ,                     // 当前通道可接受数据或业务

    output        [63: 0]                      rx_d                ,                     // 接收当前数据拍
    output                                     rx_sof              ,                     // 当前帧首拍标志，与有效/接受共同使用
    output                                     rx_eof              ,                     // 当前帧末拍标志，与有效/接受共同使用
    output        [ 2: 0]                      rx_rem              ,                     // 当前拍有效字节数减1
    output                                     rx_src_vld          ,                     // 10G LocalLink接收有效
    input                                      rx_dst_rdy          ,                     // 当前通道可接受数据或业务


    output                                     user_clk            ,                     // 对应接口时钟，使用域由连接关系确定
    output                                     channel_up          ,                     // 对应链路就绪状态，跨域副本按后缀区分
    output                                     lane_up             ,                     // 对应链路就绪状态，跨域副本按后缀区分
    output                                     user_rstn                                 // 用户域低有效复位
    );


    localparam integer                             CYCLES_PER_MS      = INIT_CLK_FREQ_HZ / 1000          ;    // 本模块CYCLES_PER_MS固定配置/状态编码
    localparam integer                             PMA_HOLD_CYCLES    = CYCLES_PER_MS * PMA_HOLD_TIME_MS ;    // 本模块PMA_HOLD_CYCLES固定配置/状态编码
    localparam integer                             RESET_GAP_CYCLES   = CYCLES_PER_MS * RESET_GAP_TIME_MS;    // 高有效复位或同步复位状态


    wire                                       PMA_INIT                                                  ;    // PMA高有效初始化复位
    wire                                       RESET                                                     ;    // 高有效复位或同步复位状态
    wire          [ 1: 0]                      reset_seq_state                                           ;    // 高有效复位或同步复位状态
    wire          [26: 0]                      reset_seq_cnt                                             ;    // 高有效复位或同步复位状态
    wire                                       gt_pll_lock_i                                             ;    // 10G GT PLL锁定状态


    wire                                       channel_up_i                                              ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       lane_up_i                                                 ;    // 对应链路就绪状态，跨域副本按后缀区分
    wire                                       user_clk_i                                                ;    // 对应接口时钟，使用域由连接关系确定
    wire                                       system_reset_i                                            ;    // 高有效复位或同步复位状态


    generate
        if (SIMULATION != 0) begin : sim_init


            assign PMA_INIT        = sys_rst                                                             ;    // PMA高有效初始化复位
            assign RESET           = sys_rst                                                             ;    // 高有效复位或同步复位状态
            assign reset_seq_state = 2'd0                                                                ;    // 高有效复位或同步复位状态
            assign reset_seq_cnt   = 27'd0                                                               ;    // 高有效复位或同步复位状态
        end else begin : silicon_init
            aurora_power_on_reset_seq #(
                .PMA_HOLD_CYCLES  (PMA_HOLD_CYCLES),
        .RESET_GAP_CYCLES (RESET_GAP_CYCLES)
            ) u_power_on_reset_seq (
                .clk_init  (clk_init),
        .sys_rst   (sys_rst),
        .pma_init  (PMA_INIT),
        .reset_pb  (RESET),
        .state_dbg (reset_seq_state),
        .count_dbg (reset_seq_cnt)
            );
        end
    endgenerate

aurora_64b66b_0_exdes # (
    .USE_CORE_TRAFFIC     (1'b1               ),
        .USR_CLK_PCOUNT       (9'd255             ),
        .EXAMPLE_SIMULATION   (SIMULATION != 0    ),
        .USE_LABTOOLS         (1'b1               )
  )
  aurora_64b66b_0_exdes_inst (
    .PMA_INIT             (PMA_INIT           ),
        .INIT_CLK_IN          (clk_init           ),
        .RESET                (RESET              ),
        .LANE_UP              (lane_up_i          ),
        .CHANNEL_UP           (channel_up_i       ),
        .GTHQ0_P              (GTHQ0_P            ),
        .GTHQ0_N              (GTHQ0_N            ),
        .RXP                  (RXP                ),
        .RXN                  (RXN                ),
        .TXP                  (TXP                ),
        .TXN                  (TXN                ),
        .HARD_ERR             (                   ),
        .SOFT_ERR             (                   ),
        .CRC_PASS_FAIL_N      (                   ),
        .CRC_VALID            (                   ),
        .tx_d                 (tx_d               ),
        .tx_sof               (tx_sof             ),
        .tx_eof               (tx_eof             ),
        .tx_rem               (tx_rem             ),
        .tx_src_vld           (tx_src_vld         ),
        .tx_dst_rdy           (tx_dst_rdy         ),
        .rx_d                 (rx_d               ),
        .rx_sof               (rx_sof             ),
        .rx_eof               (rx_eof             ),
        .rx_rem               (rx_rem             ),
        .rx_src_vld           (rx_src_vld         ),
        .rx_dst_rdy           (rx_dst_rdy         ),
        .user_clk             (user_clk_i         ),
        .sys_reset_out        (system_reset_i     ),
        .gt_pll_lock_out      (gt_pll_lock_i      )
  );


    assign                     sfp_tx_disable     = 1'b0                                                 ;    // SFP发送禁止控制，当前固定允许发送
    assign                     sfp_rs0            = 1'b1                                                 ;    // SFP速率选择控制位0
    assign                     sfp_rs1            = 1'b1                                                 ;    // SFP速率选择控制位1


    assign                     user_clk           = user_clk_i                                           ;    // 对应接口时钟，使用域由连接关系确定
    assign                     channel_up         = channel_up_i                                         ;    // 对应链路就绪状态，跨域副本按后缀区分
    assign                     lane_up            = lane_up_i                                            ;    // 对应链路就绪状态，跨域副本按后缀区分
    assign                     user_rstn          = ~system_reset_i                                      ;    // 用户域低有效复位


endmodule

// 模块参数与输入输出。
module aurora_power_on_reset_seq #(
    parameter integer                             PMA_HOLD_CYCLES  = 80_000_000,         // 本模块PMA_HOLD_CYCLES固定配置/状态编码
    parameter integer                             RESET_GAP_CYCLES = 1_000_000           // 高有效复位或同步复位状态
)(
    input                                      clk_init,                                 // 对应接口时钟，使用域由连接关系确定
    input                                      sys_rst,                                  // 高有效系统复位
    output reg                                 pma_init,                                 // PMA高有效初始化复位
    output reg                                 reset_pb,                                 // 10G协议核高有效复位
    output reg    [ 1:0]                       state_dbg,                                // 上电复位顺序状态
    output reg    [26:0]                       count_dbg                                 // 当前复位阶段拍计数
);
    localparam    [1:0]                        ST_HOLD_BOTH  = 2'd0                                      ;    // 本模块ST_HOLD_BOTH固定配置/状态编码
    localparam    [1:0]                        ST_RESET_ONLY = 2'd1                                      ;    // 高有效复位或同步复位状态
    localparam    [1:0]                        ST_RUN        = 2'd2                                      ;    // 本模块ST_RUN固定配置/状态编码


    (* ASYNC_REG = "TRUE" *) reg [1:0] sys_rst_sync                                                      ;    // 初始化域高有效复位同步管线


    // clk_init沿处理复位同步：sys_rst立即置两级为1，解除后逐拍移入0。
    always @(posedge clk_init or posedge sys_rst) begin
        if (sys_rst)
            sys_rst_sync <= 2'b11;
        else
            sys_rst_sync <= {sys_rst_sync[0], 1'b0};
    end


    // clk_init沿执行PMA与协议核复位顺序：先保持两者，再释放PMA、等待间隔，最后解除协议复位。
    always @(posedge clk_init or posedge sys_rst_sync[1]) begin
        if (sys_rst_sync[1]) begin
            pma_init  <= 1'b1;
            reset_pb  <= 1'b1;
            state_dbg <= ST_HOLD_BOTH;
            count_dbg <= 27'd0;
        end else begin
            case (state_dbg)
                ST_HOLD_BOTH: begin
                    pma_init <= 1'b1;
                    reset_pb <= 1'b1;
                    if (count_dbg == PMA_HOLD_CYCLES - 1) begin
                        pma_init  <= 1'b0;
                        state_dbg <= ST_RESET_ONLY;
                        count_dbg <= 27'd0;
                    end else count_dbg <= count_dbg + 1'b1;
                end
                ST_RESET_ONLY: begin
                    pma_init <= 1'b0;
                    reset_pb <= 1'b1;
                    if (count_dbg == RESET_GAP_CYCLES - 1) begin
                        reset_pb  <= 1'b0;
                        state_dbg <= ST_RUN;
                        count_dbg <= 27'd0;
                    end else count_dbg <= count_dbg + 1'b1;
                end
                default: begin
                    pma_init  <= 1'b0;
                    reset_pb  <= 1'b0;
                    state_dbg <= ST_RUN;
                    count_dbg <= 27'd0;
                end
            endcase
        end
    end
endmodule
