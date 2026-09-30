`timescale 1ns / 1ps
// File: fdma_aurora_brg_top.v
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/04/20 16:19:56
// Design Name:
// 模块名称: fdma_aurora_brg_顶层
// Project Name:
// Target Devices:
// Tool Versions:
// 说明: Integrates the FDMA-to-LL TX path and LL-to-FDMA RX path.
//              channel_up 先同步后再允许两个 FDMA 状态机运行。
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


// fdma_aurora_brg_顶层 模块入口；桥接顶层：把 TX、RX 两个方向和 channel_up 跨域同步组合成完整 FDMA/Aurora 转换桥。
module fdma_aurora_brg_top #(
        // 传递给 TX 格式化逻辑；默认值为一个 512 字节 FDMA 突发。
        // 定义单帧传输的字节数，512B 正好对应一个 64 个 64bit 字的 FDMA 突发。
        parameter integer FRAME_BYTES = 512,
        parameter integer MEM_WINDOW_BYTES = 4096
    )(
        // 时钟与复位
        input   fdma_clk,
        input   fdma_rstn,
        input   user_clk,
        input   user_rstn,
        input   channel_up,        // 来自 Aurora core (user_clk 域)
        input   [15:0] cfg_tx_burst_limit,

        // FDMA 读接口 (连接 BRAM/DDR 读)
        output  [31:0] fdma_raddr,
        output         fdma_rareq,
        input          fdma_rbusy,
        input   [63:0] fdma_rdata,
        input          fdma_rvalid,
        output         fdma_rready,    // AXI-like: 用户授权FDMA传输数据

        // FDMA 写接口 (连接 BRAM/DDR 写)
        output  [31:0] fdma_waddr,
        output         fdma_wareq,
        input          fdma_wbusy,
        output  [63:0] fdma_wdata,
        output         fdma_wvalid,
        output  [15:0] fdma_wsize,
        input          fdma_wready,    // AXI-like: 从机准备好接收数据

        // Aurora TX LL 接口
        output  [63:0] aurora_tx_d,
        output         aurora_tx_sof,
        output         aurora_tx_eof,
        output  [2:0]  aurora_tx_rem,
        output         aurora_tx_src_rdy,
        input          aurora_tx_dst_rdy,

        // Aurora RX LL 接口
        input   [63:0] aurora_rx_d,
        input          aurora_rx_sof,
        input          aurora_rx_eof,
        input   [2:0]  aurora_rx_rem,
        input          aurora_rx_src_rdy,
        output         aurora_rx_dst_rdy,

        // 仅调试用输出；上方功能接口保持不变。
        output         dbg_channel_up_fdma,
        output [37:0]  tx_fdma_dbg_bus,
        output [38:0]  tx_user_dbg_bus,
        output [105:0] rx_fdma_dbg_bus,
        output [28:0]  rx_user_dbg_bus,
        output         rx_fifo_almost_full,
        output         rx_fifo_full,
        output         rx_fifo_overflow,
        output         tx_frame_done_user,
        output         rx_burst_done_fdma

    );

    wire channel_up_fdma;
    // 调试总线打包，将关键状态压缩到 ILA/测试平台 可观测端口。
    assign dbg_channel_up_fdma = channel_up_fdma;

    // 同步 channel_up 到 fdma_clk 域
    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    cdc_sync u_channel_up_sync (
                 .src_clk    (user_clk),
                 .src_rstn   (user_rstn),
                 .src_signal (channel_up),
                 .dst_clk    (fdma_clk),
                 .dst_rstn   (fdma_rstn),
                 .dst_signal (channel_up_fdma)
             );

    fdma_aurora_brg_tx #(
                           .FRAME_BYTES       ( FRAME_BYTES       ),
                           .MEM_WINDOW_BYTES  ( MEM_WINDOW_BYTES  )
                       ) u_fdma_aurora_brg_tx(
                           .fdma_clk        	( fdma_clk         ),
                           .fdma_rstn       	( fdma_rstn        ),
                           .user_clk        	( user_clk         ),
                           .user_rstn       	( user_rstn        ),
                           .channel_up      	( channel_up       ),
                           .channel_up_fdma 	( channel_up_fdma  ),
                           .cfg_tx_burst_limit( cfg_tx_burst_limit ),
                           .fdma_raddr      	( fdma_raddr       ),
                           .fdma_rareq      	( fdma_rareq       ),
                           .fdma_rbusy      	( fdma_rbusy       ),
                           .fdma_rdata      	( fdma_rdata       ),
                           .fdma_rvalid     	( fdma_rvalid      ),
                           .fdma_rready     	( fdma_rready      ),
                           .tx_d            	( aurora_tx_d             ),
                           .tx_sof          	( aurora_tx_sof           ),
                           .tx_eof          	( aurora_tx_eof           ),
                           .tx_rem          	( aurora_tx_rem           ),
                           .tx_src_rdy      	( aurora_tx_src_rdy       ),
                           .tx_dst_rdy      	( aurora_tx_dst_rdy       ),
                           .dbg_fdma_bus     ( tx_fdma_dbg_bus          ),
                           .dbg_user_bus     ( tx_user_dbg_bus          ),
                           .tx_frame_done    ( tx_frame_done_user       )
                       );

    // 这里实例化子模块或 Vivado IP，并把本层信号接入其端口。
    fdma_aurora_brg_rx #(
                           .MEM_WINDOW_BYTES  ( MEM_WINDOW_BYTES  )
                       ) u_fdma_aurora_brg_rx(
                           .fdma_clk        	( fdma_clk         ),
                           .fdma_rstn       	( fdma_rstn        ),
                           .user_clk        	( user_clk         ),
                           .user_rstn       	( user_rstn        ),
                           .channel_up_fdma 	( channel_up_fdma  ),
                           .fdma_waddr      	( fdma_waddr       ),
                           .fdma_wareq      	( fdma_wareq       ),
                           .fdma_wbusy      	( fdma_wbusy       ),
                           .fdma_wdata      	( fdma_wdata       ),
                           .fdma_wvalid     	( fdma_wvalid      ),
                           .fdma_wsize      	( fdma_wsize       ),
                           .fdma_wready     	( fdma_wready      ),
                           .rx_d            	( aurora_rx_d             ),
                           .rx_sof          	( aurora_rx_sof           ),
                           .rx_eof          	( aurora_rx_eof           ),
                           .rx_rem          	( aurora_rx_rem           ),
                           .rx_src_rdy      	( aurora_rx_src_rdy       ),
                           .rx_fifo_almost_full( rx_fifo_almost_full      ),
                           .rx_fifo_full       ( rx_fifo_full             ),
                           .rx_fifo_overflow   ( rx_fifo_overflow         ),
                           .rx_dst_rdy      	( aurora_rx_dst_rdy       ),
                           .dbg_user_bus     ( rx_user_dbg_bus          ),
                           .dbg_fdma_bus     ( rx_fdma_dbg_bus          ),
                           .rx_burst_done    ( rx_burst_done_fdma       )
                       );

endmodule
