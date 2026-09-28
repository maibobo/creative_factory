`timescale 1ns/1ps
// FPGA 接收平台包装层：无线路反压；有效64bit拍进入 XPM 跨域 FIFO。
// FIFO满时丢弃当前有效拍并按一个32bit有效数据字计数，不保留线路帧边界。
module RTDS_RX_FRAME_FIFO #(
    parameter integer FIFO_DEPTH = 2048
) (
    input wire rst_n, // 主机低有效逻辑复位；配置和统计的唯一全局清除入口
    input wire user_clk, // Aurora 用户域时钟，1G 为 31.25MHz，RX 包装层为 10G 用户时钟
    input wire user_ready, // 10G用户域接收允许；失效期间每个有效拍计为丢失一个字
    input wire [63:0] rx_data, // 10G当前64bit接收数据，字节0位于低8bit
    input wire rx_sof, // 新帧首拍
    input wire rx_eof, // 线路帧尾，本模块不用于数据长度判断
    input wire [2:0] rx_rem, // 封装REM，仅为接口兼容保留
    input wire rx_valid, // 接收拍有效；线路不能按DDR状态反压
    output wire rx_ready, // 持续接受用户接口，无法存储时按32bit有效字计数丢弃
    input wire mem_clk, // DDR/队列域时钟
    output wire [63:0] frame_data, // 未压缩的64bit接收拍，DDR域仅保存低32bit
    output wire frame_valid, // 当前64bit接收拍有效，接受前保持
    input wire frame_ready, // DDR域本拍可以消费当前接收拍
    output wire fifo_full, // 已同步到DDR域的FIFO满状态
    output wire fifo_almost_full, // 已同步到DDR域的接近满状态
    output wire [31:0] dropped_frames, // 累计32bit有效字丢失数；32bit饱和，复位清零
    output reg length_error // 兼容旧端口，V2.01不判帧长，固定输出0
);
    wire user_rst_n; // 接收用户域同步释放的复位
    RTDS_FPGA_RESET_SYNC U_RTDS_FPGA_RESET_SYNC_USER (
        .clk(user_clk), .rst_async_n(rst_n), .rst_sync_n(user_rst_n)
    );
    reg [31:0] drop_bin; // 接收域每拍最多丢一个32bit有效字，饱和后保持。
    wire full_user, almost_full_user, empty_mem, wr_busy, rd_busy;
    wire fifo_reset, fifo_read, fifo_write;
    wire [63:0] fifo_input;
    wire almost_empty_nc, almost_full_nc, data_valid_nc, dbiterr_nc;
    wire overflow_nc, prog_empty_nc, sbiterr_nc, underflow_nc, wr_ack_nc;
    wire [$clog2(FIFO_DEPTH):0] rd_data_count_nc, wr_data_count_nc;
    // 复位极性/状态转换；解除时序由对应时钟域的复位包装层保证。
    assign fifo_reset = !user_rst_n;
    // 仅在跨域FIFO输出有效且消费者接受时推进读指针。
    assign fifo_read = frame_valid && frame_ready;
    // 仅把允许接收且FIFO可写的有效拍入队，无法写入时由丢失计数处理。
    assign fifo_write = user_ready && rx_valid && !full_user && !wr_busy;
    // 跨域FIFO保留整个64bit原拍；丢弃高32bit在DDR域执行。
    assign fifo_input = rx_data;
    // 10G线路业务接收不能依赖DDR反压，无法存储的数据由本地统计丢弃。
    assign rx_ready = 1'b1;
    // FWFT输出非空且复位忙结束时，当前64bit原拍才可被消费。
    assign frame_valid = !empty_mem && !rd_busy;
    // 接口保留SOF/EOF/REM用于兼容已有封装；业务流不按线路帧长拒收。

    always @(posedge user_clk or negedge user_rst_n) begin : update_length_error
        if (!user_rst_n)
            length_error <= 1'b0;
        else
            length_error <= 1'b0;
    end

    always @(posedge user_clk or negedge user_rst_n) begin : update_drop_bin
        if (!user_rst_n)
            drop_bin <= 32'd0;
        else if (rx_valid && (!user_ready || full_user || wr_busy) && drop_bin != 32'hffffffff)
            drop_bin <= drop_bin + 32'd1;
    end

    // 计数跨域集中在 FPGA 平台单元，业务层不自写两级同步链。
    RTDS_FPGA_COUNT_CDC U_RTDS_FPGA_COUNT_CDC (
        .src_clk(user_clk), .dst_clk(mem_clk), .src_count(drop_bin), .dst_count(dropped_frames)
    );
    xpm_cdc_single #(.DEST_SYNC_FF(2), .SRC_INPUT_REG(0)) U_XPM_CDC_FULL
        (.src_clk(user_clk), .src_in(full_user), .dest_clk(mem_clk), .dest_out(fifo_full));
    xpm_cdc_single #(.DEST_SYNC_FF(2), .SRC_INPUT_REG(0)) U_XPM_CDC_ALMOST_FULL
        (.src_clk(user_clk), .src_in(almost_full_user), .dest_clk(mem_clk), .dest_out(fifo_almost_full));

    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE("block"), .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .WRITE_DATA_WIDTH(64), .READ_DATA_WIDTH(64),
        .READ_MODE("fwft"), .FIFO_READ_LATENCY(0), .CDC_SYNC_STAGES(2),
        .DOUT_RESET_VALUE("0"), .ECC_MODE("no_ecc"), .FULL_RESET_VALUE(0),
        .PROG_EMPTY_THRESH(5), .PROG_FULL_THRESH(FIFO_DEPTH-5),
        .RD_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH)+1),
        .WR_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH)+1),
        .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) U_XPM_FIFO_ASYNC (
        .rst(fifo_reset), .wr_clk(user_clk), .rd_clk(mem_clk),
        .din(fifo_input), .wr_en(fifo_write), .full(full_user),
        .prog_full(almost_full_user), .wr_rst_busy(wr_busy),
        .dout(frame_data), .empty(empty_mem), .rd_rst_busy(rd_busy),
        .rd_en(fifo_read), .sleep(1'b0),
        .injectsbiterr(1'b0), .injectdbiterr(1'b0),
        .almost_empty(almost_empty_nc), .almost_full(almost_full_nc), .data_valid(data_valid_nc), .dbiterr(dbiterr_nc),
        .overflow(overflow_nc), .prog_empty(prog_empty_nc), .rd_data_count(rd_data_count_nc), .sbiterr(sbiterr_nc),
        .underflow(underflow_nc), .wr_ack(wr_ack_nc), .wr_data_count(wr_data_count_nc)
    );
endmodule
