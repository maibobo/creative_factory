`timescale 1ns / 1ps
// File: fdma_aurora_brg_aurora_loop.v
//////////////////////////////////////////////////////////////////////////////////
// 模块名称: fdma_aurora_brg_aurora_loop
// 说明: 顶层模块，例化 fdma_aurora_brg_顶层 和 aurora_64b66b_顶层，
//              将 FDMA 桥的 Aurora LL 接口与 Aurora 64B/66B 核相连。
//              数据路径: FDMA -> brg_tx -> Aurora TX -> GT -> ... -> GT -> Aurora RX -> brg_rx -> FDMA
//////////////////////////////////////////////////////////////////////////////////

// fdma_aurora_brg_aurora_loop 模块入口；Aurora 环回集成层：连接桥接顶层、Aurora 64B/66B IP、GT 引脚和调试总线。
module fdma_aurora_brg_aurora_loop #(
    // 仿真模式开关，置位时启用适合仿真环境的 Aurora 连接方式。
    parameter                       SIMULATION         = 0,  // 1=仿真（快速初始化），0=硅片模式
    // 桥接帧大小；默认 512B，使每个 FDMA burst 对应一个 LL 帧。
    // 定义单帧传输的字节数，512B 正好对应一个 64 个 64bit 字的 FDMA 突发。
    parameter integer               FRAME_BYTES        = 512,
    // 默认 0，使行为仿真不依赖 Vivado ILA 模型。
    // ILA 调试开关，置位时例化调试探针。
    parameter integer               DEBUG_ENABLE       = 0
)(
    // Aurora 初始化时钟与复位
    input                               clk_init            ,
    input                               sys_rst             ,

    // GT IO
    input                               GTHQ0_P             ,
    input                               GTHQ0_N             ,
    input                               RXP                 ,
    input                               RXN                 ,
    output                              TXP                 ,
    output                              TXN                 ,

    // SFP 控制
    output                              sfp_tx_disable      ,
    output                              sfp_rs0             ,
    output                              sfp_rs1             ,

    // FDMA 时钟与复位
    input                               fdma_clk            ,
    input                               fdma_rstn           ,
    input               [15:0]          cfg_tx_burst_limit  ,

    // FDMA 读接口
    output              [31:0]          fdma_raddr          ,
    output                              fdma_rareq          ,
    input                               fdma_rbusy          ,
    input               [63:0]          fdma_rdata          ,
    input                               fdma_rvalid         ,
    output                              fdma_rready         ,  // AXI-like: 用户授权FDMA传输数据

    // FDMA 写接口
    output              [31:0]          fdma_waddr          ,
    output                              fdma_wareq          ,
    input                               fdma_wbusy          ,
    output              [63:0]          fdma_wdata          ,
    output                              fdma_wvalid         ,
    output              [15:0]          fdma_wsize          ,
    input                               fdma_wready         ,  // AXI-like: 从机准备好接收数据

    // 硬件测试计数器/错误捕获；仿真中该总线接 0。
    input               [256:0]         hw_test_dbg_bus     ,
    input               [187:0]         hw_test_status_bus  ,

    // 状态输出
    output                              channel_up          ,
    output                              lane_up             ,
    output                              user_clk            ,
    output                              user_rstn
);

    //====================================================================================
    // 内部连线 - Aurora LocalLink 接口
    //====================================================================================
    wire [63:0]  ll_tx_d         ;
    wire         ll_tx_sof       ;
    wire         ll_tx_eof       ;
    wire [2:0]   ll_tx_rem       ;
    wire         ll_tx_src_rdy   ;
    wire         ll_tx_dst_rdy   ;
    wire [63:0]  ll_rx_d         ;
    wire         ll_rx_sof       ;
    wire         ll_rx_eof       ;
    wire [2:0]   ll_rx_rem       ;
    wire         ll_rx_src_rdy   ;
    wire         ll_rx_dst_rdy   ;

    // Aurora 状态
    wire         aurora_channel_up;
    wire         aurora_lane_up  ;
    wire         aurora_user_clk ;
    wire         aurora_user_rstn;

    // 桥接调试总线已经按各自原生时钟域拆分。
    wire         dbg_channel_up_fdma;
    wire [37:0]  tx_fdma_dbg_bus;
    wire [38:0]  tx_user_dbg_bus;
    wire [105:0] rx_fdma_dbg_bus;
    wire [28:0]  rx_user_dbg_bus;

    //====================================================================================
    // 例化 aurora_64b66b_顶层 - Aurora 64B/66B 核
    //====================================================================================
    aurora_64b66b_top #(
        .SIMULATION         (SIMULATION         )
    ) u_aurora_64b66b_top (
        // 初始化时钟与复位
        .clk_init           (clk_init           ),
        .sys_rst            (sys_rst            ),

        // GT IO
        .GTHQ0_P            (GTHQ0_P            ),
        .GTHQ0_N            (GTHQ0_N            ),
        .RXP                (RXP                ),
        .RXN                (RXN                ),
        .TXP                (TXP                ),
        .TXN                (TXN                ),

        // SFP 控制
        .sfp_tx_disable     (sfp_tx_disable     ),
        .sfp_rs0            (sfp_rs0            ),
        .sfp_rs1            (sfp_rs1            ),

        // LocalLink TX 接口 (来自 brg_tx)
        .tx_d               (ll_tx_d            ),
        .tx_sof             (ll_tx_sof          ),
        .tx_eof             (ll_tx_eof          ),
        .tx_rem             (ll_tx_rem          ),
        .tx_src_vld         (ll_tx_src_rdy      ),
        .tx_dst_rdy         (ll_tx_dst_rdy      ),

        // LocalLink RX 接口 (送往 brg_rx)
        .rx_d               (ll_rx_d            ),
        .rx_sof             (ll_rx_sof          ),
        .rx_eof             (ll_rx_eof          ),
        .rx_rem             (ll_rx_rem          ),
        .rx_src_vld         (ll_rx_src_rdy      ),
        .rx_dst_rdy         (ll_rx_dst_rdy      ),

        // 状态输出
        .user_clk           (aurora_user_clk    ),
        .channel_up         (aurora_channel_up  ),
        .lane_up            (aurora_lane_up     ),
        .user_rstn          (aurora_user_rstn   )
    );

    //====================================================================================
    // 例化 fdma_aurora_brg_顶层 - FDMA 到 Aurora LL 桥
    //====================================================================================
    fdma_aurora_brg_top #(
        .FRAME_BYTES        (FRAME_BYTES        )
    ) u_fdma_aurora_brg_top (
        // 时钟与复位
        .fdma_clk           (fdma_clk           ),
        .fdma_rstn          (fdma_rstn          ),
        .user_clk           (aurora_user_clk    ),
        .user_rstn          (aurora_user_rstn   ),
        .channel_up         (aurora_channel_up  ),
        .cfg_tx_burst_limit (cfg_tx_burst_limit ),

        // FDMA 读接口
        .fdma_raddr         (fdma_raddr         ),
        .fdma_rareq         (fdma_rareq         ),
        .fdma_rbusy         (fdma_rbusy         ),
        .fdma_rdata         (fdma_rdata         ),
        .fdma_rvalid        (fdma_rvalid        ),
        .fdma_rready        (fdma_rready        ),

        // FDMA 写接口
        .fdma_waddr         (fdma_waddr         ),
        .fdma_wareq         (fdma_wareq         ),
        .fdma_wbusy         (fdma_wbusy         ),
        .fdma_wdata         (fdma_wdata         ),
        .fdma_wvalid        (fdma_wvalid        ),
        .fdma_wsize         (fdma_wsize         ),
        .fdma_wready        (fdma_wready        ),

        // Aurora TX LL 接口 -> Aurora 核 TX
        .aurora_tx_d        (ll_tx_d            ),
        .aurora_tx_sof      (ll_tx_sof          ),
        .aurora_tx_eof      (ll_tx_eof          ),
        .aurora_tx_rem      (ll_tx_rem          ),
        .aurora_tx_src_rdy  (ll_tx_src_rdy      ),
        .aurora_tx_dst_rdy  (ll_tx_dst_rdy      ),

        // Aurora RX LL 接口 <- Aurora 核 RX
        .aurora_rx_d        (ll_rx_d            ),
        .aurora_rx_sof      (ll_rx_sof          ),
        .aurora_rx_eof      (ll_rx_eof          ),
        .aurora_rx_rem      (ll_rx_rem          ),
        .aurora_rx_src_rdy  (ll_rx_src_rdy      ),
        .aurora_rx_dst_rdy  (ll_rx_dst_rdy      ),

        .dbg_channel_up_fdma(dbg_channel_up_fdma),
        .tx_fdma_dbg_bus    (tx_fdma_dbg_bus    ),
        .tx_user_dbg_bus    (tx_user_dbg_bus    ),
        .rx_fdma_dbg_bus    (rx_fdma_dbg_bus    ),
        .rx_user_dbg_bus    (rx_user_dbg_bus    )
    );

    generate
    // 打开调试开关时例化 ILA 调试探针，便于硬件观测桥接链路。
    if (DEBUG_ENABLE != 0) begin : g_hardware_debug
    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    ila_brg_loop u_ila_brg_loop (
        .fdma_clk             (fdma_clk            ),
        .fdma_rstn            (fdma_rstn           ),
        .user_clk             (aurora_user_clk     ),
        .user_rstn            (aurora_user_rstn    ),
        .channel_up_fdma      (dbg_channel_up_fdma ),
        .channel_up           (aurora_channel_up   ),
        .lane_up              (aurora_lane_up      ),

        .fdma_raddr           (fdma_raddr          ),
        .fdma_rareq           (fdma_rareq          ),
        .fdma_rbusy           (fdma_rbusy          ),
        .fdma_rdata           (fdma_rdata          ),
        .fdma_rvalid          (fdma_rvalid         ),
        .fdma_rready          (fdma_rready         ),
        .fdma_waddr           (fdma_waddr          ),
        .fdma_wareq           (fdma_wareq          ),
        .fdma_wbusy           (fdma_wbusy          ),
        .fdma_wdata           (fdma_wdata          ),
        .fdma_wvalid          (fdma_wvalid         ),
        .fdma_wsize           (fdma_wsize          ),
        .fdma_wready          (fdma_wready         ),

        .ll_tx_d              (ll_tx_d             ),
        .ll_tx_sof            (ll_tx_sof           ),
        .ll_tx_eof            (ll_tx_eof           ),
        .ll_tx_rem            (ll_tx_rem           ),
        .ll_tx_src_rdy        (ll_tx_src_rdy       ),
        .ll_tx_dst_rdy        (ll_tx_dst_rdy       ),
        .ll_rx_d              (ll_rx_d             ),
        .ll_rx_sof            (ll_rx_sof           ),
        .ll_rx_eof            (ll_rx_eof           ),
        .ll_rx_rem            (ll_rx_rem           ),
        .ll_rx_src_rdy        (ll_rx_src_rdy       ),
        .ll_rx_dst_rdy        (ll_rx_dst_rdy       ),

        .tx_fdma_dbg_bus      (tx_fdma_dbg_bus     ),
        .tx_user_dbg_bus      (tx_user_dbg_bus     ),
        .rx_fdma_dbg_bus      (rx_fdma_dbg_bus     ),
        .rx_user_dbg_bus      (rx_user_dbg_bus     ),
        .hw_test_dbg_bus      (hw_test_dbg_bus     ),
        .hw_test_status_bus   (hw_test_status_bus  )
    );
    end
    endgenerate

    //====================================================================================
    // 顶层状态输出
    //====================================================================================
    assign channel_up  = aurora_channel_up ;
    assign lane_up     = aurora_lane_up    ;
    assign user_clk    = aurora_user_clk   ;
    assign user_rstn   = aurora_user_rstn  ;

endmodule
