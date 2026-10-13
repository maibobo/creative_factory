`timescale 1ns/1ps
// 功能：把Aurora接收侧的完整64位数据拍送入跨域FIFO，再供DDR时钟域读取。
// 线路侧持续给出rx_ready；FIFO不可写或接收暂停时，统计丢失的有效32位字。
// FIFO采用首字直通模式；读侧只有在数据有效且下游接受时才推进。
// 复位在接收用户时钟域同步解除，满状态和丢失计数分别传到DDR时钟域。
// SOF、EOF和REM仅保留接口兼容；此模块不按线路帧长度筛选数据。
module RTDS_RX_FRAME_FIFO #(
    parameter integer  FIFO_DEPTH = 2048    // 跨域FIFO可保存的64位数据拍数。
) (
    input  wire          rst_n,               // 主机低有效逻辑复位；配置和统计的唯一全局清除入口
    input  wire          user_clk,            // Aurora 用户域时钟，1G 为 31.25MHz，RX 包装层为 10G 用户时钟
    input  wire          user_ready,          // 10G用户域接收允许；失效期间每个有效拍计为丢失一个字
    input  wire [63:0]   rx_data,             // 10G当前64bit接收数据，字节0位于低8bit
    input  wire          rx_sof,              // 新帧首拍
    input  wire          rx_eof,              // 线路帧尾，本模块不用于数据长度判断
    input  wire [2:0]    rx_rem,              // 封装REM，仅为接口兼容保留
    input  wire          rx_valid,            // 接收拍有效；线路不能按DDR状态反压
    output wire          rx_ready,            // 持续接受用户接口，无法存储时按32bit有效字计数丢弃
    input  wire          mem_clk,             // DDR/队列域时钟
    output wire [63:0]   frame_data,          // 未压缩的64bit接收拍，DDR域仅保存低32bit
    output wire          frame_valid,         // 当前64bit接收拍有效，接受前保持
    input  wire          frame_ready,         // DDR域本拍可以读取当前接收拍
    output wire          fifo_full,           // 已同步到DDR域的FIFO满状态
    output wire          fifo_almost_full,    // 已同步到DDR域的接近满状态
    output wire [31:0]   dropped_frames,      // 累计32bit有效字丢失数；32bit饱和，复位清零
    output reg           length_error         // 兼容旧端口，V2.01不判帧长，固定输出0
);

    // 复位和丢失统计。
    wire            user_rst_n                                          ;    // 用户域同步解除后的复位。
    reg     [31:0]  drop_bin                                            ;    // 接收域内的饱和丢失字计数。

    // FIFO状态与读写控制。
    wire            full_user                                           ;    // 接收侧FIFO已满。
    wire            almost_full_user                                    ;    // 接收侧FIFO接近满。
    wire            empty_mem                                           ;    // DDR侧FIFO为空。
    wire            wr_busy                                             ;    // FIFO写侧复位仍在进行。
    wire            rd_busy                                             ;    // FIFO读侧复位仍在进行。
    wire            fifo_reset                                          ;    // 送入FIFO的高有效复位。
    wire            fifo_read                                           ;    // DDR侧读使能。
    wire            fifo_write                                          ;    // 接收侧写使能。
    wire    [63:0]  fifo_input                                          ;    // 送入FIFO的完整64位数据拍。

    // 未使用的FIFO状态输出。
    wire                            almost_empty_nc                     ;    // 未使用的接近空指示。
    wire                            almost_full_nc                      ;    // 未使用的接近满输出。
    wire                            data_valid_nc                       ;    // 未使用的数据有效输出。
    wire                            dbiterr_nc                          ;    // 未使用的双位错误输出。
    wire                            overflow_nc                         ;    // 未使用的写溢出输出。
    wire                            prog_empty_nc                       ;    // 未使用的可编程空指示。
    wire                            sbiterr_nc                          ;    // 未使用的单比特错误输出。
    wire                            underflow_nc                        ;    // 未使用的读空错误输出。
    wire                            wr_ack_nc                           ;    // 未使用的写确认输出。
    wire    [$clog2(FIFO_DEPTH):0]  rd_data_count_nc                    ;    // 未使用的读侧数据拍计数。
    wire    [$clog2(FIFO_DEPTH):0]  wr_data_count_nc                    ;    // 未使用的写侧数据拍计数。


    // 接收域复位和跨域FIFO输入。
    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_USER (
        .clk(user_clk),
        .rst_async_n(rst_n),
        .rst_sync_n(user_rst_n)
    );

    // 复位和读写条件。
    assign fifo_reset = !user_rst_n                                     ;    // 把用户域低有效复位转换为FIFO高有效复位。
    assign fifo_read = frame_valid && frame_ready                       ;    // 输出有效且DDR端接受时推进读指针。
    assign fifo_write = user_ready && rx_valid && !full_user && !wr_busy;    // 输入有效、允许接收且FIFO可写时存入整拍数据。
    assign fifo_input = rx_data                                         ;    // 保持接收的完整64位数据拍。


    // 接收接口及DDR输出状态。

    // 接口组合输出。
    assign rx_ready = 1'b1                                              ;    // 接收接口始终给出就绪状态。
    assign frame_valid = !empty_mem && !rd_busy                         ;    // FIFO非空且读侧复位结束时提供有效数据。

    // 兼容状态和丢失统计。
    // 兼容输出固定为零。
    always @(posedge user_clk or negedge user_rst_n) begin : update_length_error
        if (!user_rst_n)
            length_error <= 1'b0;
        else
            length_error <= 1'b0;
    end

    // 接收暂停或FIFO不可写时统计丢失的数据字。
    always @(posedge user_clk or negedge user_rst_n) begin : update_drop_bin
        if (!user_rst_n)
            drop_bin <= 32'd0;
        else if (rx_valid && (!user_ready || full_user || wr_busy) && drop_bin != 32'hffffffff)
            drop_bin <= drop_bin + 32'd1;
    end


    // 跨域统计和FIFO实例。
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
