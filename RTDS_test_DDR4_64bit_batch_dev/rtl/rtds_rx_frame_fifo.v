// 接收时钟域保存完整64bit拍，异步FIFO送到DDR业务时钟域；低32bit提取由写块模块完成。
// 线路侧rx_ready持续为1，接收未允许、FIFO满或复位忙时丢弃新有效字并计数。
// 读侧只在frame_valid和frame_ready共同成立时取走数据，已存数据顺序保持。
// SOF/EOF/REM只保留接口兼容，不据这些标志过滤有效字；丢失计数跨域读出。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_RX_FRAME_FIFO #(
    parameter integer                             FIFO_DEPTH = 2048                   // FIFO可保存的数据拍数
) (
    input wire                                 rst_n,                                 // 低有效全局复位输入
    input wire                                 user_clk,                              // Aurora 用户域时钟，1G 为 31.25MHz，RX 包装层为 10G 用户时钟
    input wire                                 user_ready,                            // 10G用户域接收允许；失效期间每个有效拍计为丢失一个字
    input wire    [63:0]                       rx_data,                               // 10G当前64bit接收数据，字节0位于低8bit
    input wire                                 rx_sof,                                // 新帧首拍
    input wire                                 rx_eof,                                // 线路帧尾，本模块不用于数据长度判断
    input wire    [2:0]                        rx_rem,                                // 封装REM，仅为接口兼容保留
    input wire                                 rx_valid,                              // 接收拍有效；线路不能按DDR状态反压
    output wire                                rx_ready,                              // 持续接受用户接口，无法存储时按32bit有效字计数丢弃
    input wire                                 mem_clk,                               // DDR/队列域时钟
    output wire   [63:0]                       frame_data,                            // 未压缩的64bit接收拍，DDR域仅保存低32bit
    output wire                                frame_valid,                           // 当前64bit接收拍有效，接受前保持
    input wire                                 frame_ready,                           // DDR域本拍可以读取当前接收拍
    output wire                                fifo_full,                             // 已同步到DDR域的FIFO满状态
    output wire                                fifo_almost_full,                      // 已同步到DDR域的接近满状态
    output wire   [31:0]                       dropped_frames,                        // 累计32bit有效字丢失数；32bit饱和，复位清零
    output reg                                 length_error                           // 兼容旧端口，V2.01不判帧长，固定输出0
);


    wire                                       user_rst_n                  ;    // 用户时钟域同步解除后的低有效复位
    reg           [31:0]                       drop_bin                    ;    // 用户域累计丢失32bit字数，达到最大值后保持


    wire                                       full_user                   ;    // FIFO用户写侧满状态
    wire                                       almost_full_user            ;    // FIFO用户写侧接近满状态
    wire                                       empty_mem                   ;    // FIFO存储读侧空状态
    wire                                       wr_busy                     ;    // FIFO写侧复位仍在进行
    wire                                       rd_busy                     ;    // FIFO读侧复位仍在进行
    wire                                       fifo_reset                  ;    // FIFO高有效复位
    wire                                       fifo_read                   ;    // 数据有效且下游接受时取FIFO当前拍
    wire                                       fifo_write                  ;    // RX有效且允许、未满、复位不忙时写FIFO
    wire          [63:0]                       fifo_input                  ;    // 原始64bit接收数据，不在此模块丢弃高半


    wire                                       almost_empty_nc             ;    // 未使用的接近空指示
    wire                                       almost_full_nc              ;    // 未使用的接近满输出
    wire                                       data_valid_nc               ;    // 未使用的数据有效输出
    wire                                       dbiterr_nc                  ;    // 未使用的双位错误输出
    wire                                       overflow_nc                 ;    // 未使用的写溢出输出
    wire                                       prog_empty_nc               ;    // 未使用的可编程空指示
    wire                                       sbiterr_nc                  ;    // 未使用的单比特错误输出
    wire                                       underflow_nc                ;    // 未使用的读空错误输出
    wire                                       wr_ack_nc                   ;    // 未使用的写确认输出
    wire          [$clog2(FIFO_DEPTH):0]       rd_data_count_nc            ;    // 未使用的读侧数据拍计数
    wire          [$clog2(FIFO_DEPTH):0]       wr_data_count_nc            ;    // 未使用的写侧数据拍计数


    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_USER (
        .clk(user_clk),
        .rst_async_n(rst_n),
        .rst_sync_n(user_rst_n)
    );


    assign fifo_reset = !user_rst_n                                        ;    // FIFO高有效复位
    assign fifo_read = frame_valid && frame_ready                          ;    // 数据有效且下游接受时取FIFO当前拍
    assign fifo_write = user_ready && rx_valid && !full_user && !wr_busy   ;    // RX有效且允许、未满、复位不忙时写FIFO
    assign fifo_input = rx_data                                            ;    // 原始64bit接收数据，不在此模块丢弃高半


    assign rx_ready = 1'b1                                                 ;    // 持续接受用户接口，无法存储时按32bit有效字计数丢弃
    assign frame_valid = !empty_mem && !rd_busy                            ;    // 当前64bit接收拍有效，接受前保持


    // 旧长度错误端口保留兼容，用户复位和运行时都固定为0，不据SOF/EOF拒收数据。
    always @(posedge user_clk or negedge user_rst_n) begin : update_length_error
        if (!user_rst_n)
            length_error <= 1'b0;
        else
            length_error <= 1'b0;
    end


    // 接收有效但未允许、FIFO满或写复位忙时每拍计丢1字，达到FFFFFFFF后不回绕。
    always @(posedge user_clk or negedge user_rst_n) begin : update_drop_bin
        if (!user_rst_n)
            drop_bin <= 32'd0;
        else if (rx_valid && (!user_ready || full_user || wr_busy) && drop_bin != 32'hffffffff)
            drop_bin <= drop_bin + 32'd1;
    end


    RTDS_FPGA_COUNT_CDC U_RTDS_FPGA_COUNT_CDC (
        .src_clk(user_clk),
        .dst_clk(mem_clk),
        .src_count(drop_bin),
        .dst_count(dropped_frames)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .SRC_INPUT_REG(0)
    ) U_XPM_CDC_FULL (
        .src_clk(user_clk),
        .src_in(full_user),
        .dest_clk(mem_clk),
        .dest_out(fifo_full)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2),
        .SRC_INPUT_REG(0)
    ) U_XPM_CDC_ALMOST_FULL (
        .src_clk(user_clk),
        .src_in(almost_full_user),
        .dest_clk(mem_clk),
        .dest_out(fifo_almost_full)
    );

    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE("block"),
        .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .WRITE_DATA_WIDTH(64),
        .READ_DATA_WIDTH(64),
        .READ_MODE("fwft"),
        .FIFO_READ_LATENCY(0),
        .CDC_SYNC_STAGES(2),
        .DOUT_RESET_VALUE("0"),
        .ECC_MODE("no_ecc"),
        .FULL_RESET_VALUE(0),
        .PROG_EMPTY_THRESH(5),
        .PROG_FULL_THRESH(FIFO_DEPTH-5),
        .RD_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH)+1),
        .WR_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH)+1),
        .USE_ADV_FEATURES("0707"),
        .WAKEUP_TIME(0)
    ) U_XPM_FIFO_ASYNC (
        .rst(fifo_reset),
        .wr_clk(user_clk),
        .rd_clk(mem_clk),
        .din(fifo_input),
        .wr_en(fifo_write),
        .full(full_user),
        .prog_full(almost_full_user),
        .wr_rst_busy(wr_busy),
        .dout(frame_data),
        .empty(empty_mem),
        .rd_rst_busy(rd_busy),
        .rd_en(fifo_read),
        .sleep(1'b0),
        .injectsbiterr(1'b0),
        .injectdbiterr(1'b0),
        .almost_empty(almost_empty_nc),
        .almost_full(almost_full_nc),
        .data_valid(data_valid_nc),
        .dbiterr(dbiterr_nc),
        .overflow(overflow_nc),
        .prog_empty(prog_empty_nc),
        .rd_data_count(rd_data_count_nc),
        .sbiterr(sbiterr_nc),
        .underflow(underflow_nc),
        .wr_ack(wr_ack_nc),
        .wr_data_count(wr_data_count_nc)
    );
endmodule
