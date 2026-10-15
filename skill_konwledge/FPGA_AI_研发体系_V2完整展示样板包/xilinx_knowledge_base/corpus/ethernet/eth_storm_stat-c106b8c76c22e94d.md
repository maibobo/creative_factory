# eth_storm_stat

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_stat.v`
- SHA-256: `c106b8c76c22e94d9bb4ead8d1709b8e51d2cdc0de78347d8b5cbe6c994cf3a6`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// Module : eth_storm_stat
// 位置   : eth_storm_filter 内部，接收主状态机完成一帧判决后在此提交统计结果。
// 功能   : 维护风暴检测窗口、窗口 epoch、帧时间戳、通过/丢弃累计计数以及
//          当前窗口的帧数、字节数和风暴锁存状态。
// 时序   : 全部状态和输出均在 gmii_rx_clk 域；rst 为高有效异步复位。
// 提交   : commit_can_push 表示主状态机处于可真正写入描述符 FIFO 的提交拍。
//          只有该信号有效时，本模块才消费 dec_*_q 并形成一次通过或丢弃事件，
//          从而保证统计与实际提交的帧一一对应。
// =============================================================================

module eth_storm_stat #(
    parameter integer CLK_FREQ_HZ = 125000000,
    parameter integer WINDOW_MS   = 10
)(
    // 接收处理时钟与高有效异步复位
    input  wire        gmii_rx_clk,
    input  wire        rst,

    // 配置控制；cfg_clear_stats 进入本时钟域后延迟两拍生效
    input  wire        cfg_clear_stats,
    input  wire        cfg_filter_en,
    input  wire        cfg_frame_storm_en,
    input  wire        cfg_byte_storm_en,
    input  wire [31:0] cfg_window_ms,

    // 主状态机锁存的本帧判决结果，仅在 commit_can_push 拍消费
    input  wire        commit_can_push,
    input  wire        dec_count_window_q,
    input  wire [31:0] frame_cnt_next_q,
    input  wire [31:0] byte_cnt_next_q,
    input  wire        frame_over_q,
    input  wire        byte_over_q,
    input  wire        dec_pass_q,
    input  wire [15:0] dec_drop_reason_q,

    // 反馈给主状态机和 CRC 表清理模块的当前窗口实时状态
    output wire [0:0]  active_epoch,
    output wire        win_rollover,
    output reg  [31:0] win_frame_cnt_g,
    output reg  [31:0] win_byte_cnt_g,
    output reg         frame_storm_active_g,
    output reg         byte_storm_active_g,
    output reg  [31:0] frame_time_cnt_g,

    // 单拍丢弃事件：drop_valid=1 时 drop_reason 才表示本次提交帧的原因
    output reg         drop_valid,
    output reg  [15:0] drop_reason,

    // 软件可读的累计计数与当前窗口状态，均保持在 gmii_rx_clk 域
    output reg [31:0]  stat_pass_cnt,
    output reg [31:0]  stat_drop_crc_err_cnt,
    output reg [31:0]  stat_drop_dup_crc_cnt,
    output reg [31:0]  stat_drop_frame_storm_cnt,
    output reg [31:0]  stat_drop_byte_storm_cnt,
    output reg [31:0]  stat_drop_buf_full_cnt,
    output reg [31:0]  stat_drop_len_err_cnt,
    output reg [31:0]  stat_drop_blacklist_cnt,
    output reg [31:0]  stat_drop_not_white_cnt,
    output reg [31:0]  stat_drop_dst_miss_cnt,
    output reg [31:0]  stat_win_frame_cnt,
    output reg [31:0]  stat_win_byte_cnt,
    output reg [15:0]  stat_last_drop_reason,
    output reg         stat_frame_storm_active,
    output reg         stat_byte_storm_active
);

    localparam [31:0] WIN_CYCLES_DEFAULT = (CLK_FREQ_HZ / 1000) * WINDOW_MS;

    localparam [15:0] DROP_NONE = 16'h0000;


    // cfg_window_ms=0 时采用参数默认值；最终至少保留 1 个时钟周期的窗口。
    wire [31:0] cfg_window_cycles_raw = (cfg_window_ms == 32'd0) ?
                                        WIN_CYCLES_DEFAULT :
                                        ((CLK_FREQ_HZ / 1000) * cfg_window_ms);
    wire [31:0] eff_win_cycles    = (cfg_window_cycles_raw == 32'd0) ? 32'd1 : cfg_window_cycles_raw;
    wire [31:0] eff_win_cycles_m1 = eff_win_cycles - 32'd1;

    reg [31:0] win_cycle_cnt;
    reg [0:0]  win_epoch;

    reg cfg_clear_stats_g1;
    reg cfg_clear_stats_g2;

    // 计数达到“窗口周期数-1”的当前拍即产生 rollover，epoch 每个窗口翻转一次。
    assign win_rollover = (win_cycle_cnt >= eff_win_cycles_m1);
    assign active_epoch = win_epoch;

    // 将清零控制同步/流水到本模块使用的 gmii_rx_clk 域；这是电平控制而非边沿脉冲。
    always @(posedge gmii_rx_clk or posedge rst) begin
        if (rst) begin
            cfg_clear_stats_g1 <= 1'b0;
            cfg_clear_stats_g2 <= 1'b0;
        end else begin
            cfg_clear_stats_g1 <= cfg_clear_stats;
            cfg_clear_stats_g2 <= cfg_clear_stats_g1;
        end
    end

    // 窗口时基、主状态机反馈计数和帧时间戳。
    // 窗口中第一次越限后，storm_active 会保持到窗口结束；rollover 同拍若提交
    // 一帧，则 frame_cnt_next_q/byte_cnt_next_q 作为新窗口的首帧结果写入。
    always @(posedge gmii_rx_clk or posedge rst) begin
        if (rst) begin
            win_cycle_cnt <= 32'd0;
            win_epoch     <= 1'b0;

            win_frame_cnt_g <= 32'd0;
            win_byte_cnt_g  <= 32'd0;
            frame_storm_active_g <= 1'b0;
            byte_storm_active_g  <= 1'b0;
            frame_time_cnt_g     <= 32'd0;
        end else begin
            // 时间戳每拍累加 8，且不受统计清零影响；gmii_rx_clk=125 MHz 时单位为 ns。
            frame_time_cnt_g <= frame_time_cnt_g + 32'd8;

            if (cfg_clear_stats_g2) begin
                // 统计清零优先于同周期窗口翻转和帧提交
                win_frame_cnt_g <= 32'd0;
                win_byte_cnt_g  <= 32'd0;
                frame_storm_active_g <= 1'b0;
                byte_storm_active_g  <= 1'b0;

                // 保留当前统计窗口时基
                if (win_rollover) begin
                    win_cycle_cnt <= 32'd0;
                    win_epoch     <= ~win_epoch;
                end else begin
                    win_cycle_cnt <= win_cycle_cnt + 1'b1;
                end
            end else if (win_rollover) begin
                win_cycle_cnt <= 32'd0;
                win_epoch     <= ~win_epoch;

                if (commit_can_push && dec_count_window_q) begin
                    win_frame_cnt_g <= frame_cnt_next_q;
                    win_byte_cnt_g  <= byte_cnt_next_q;

                    frame_storm_active_g <=
                        cfg_filter_en &&
                        cfg_frame_storm_en &&
                        frame_over_q;

                    byte_storm_active_g <=
                        cfg_filter_en &&
                        cfg_byte_storm_en &&
                        byte_over_q;
                end else begin
                    win_frame_cnt_g <= 32'd0;
                    win_byte_cnt_g  <= 32'd0;
                    frame_storm_active_g <= 1'b0;
                    byte_storm_active_g  <= 1'b0;
                end
            end else begin
                win_cycle_cnt <= win_cycle_cnt + 1'b1;

                if (commit_can_push && dec_count_window_q) begin
                    win_frame_cnt_g <= frame_cnt_next_q;
                    win_byte_cnt_g  <= byte_cnt_next_q;

                    if (cfg_filter_en &&
                        cfg_frame_storm_en &&
                        frame_over_q)
                        frame_storm_active_g <= 1'b1;

                    if (cfg_filter_en &&
                        cfg_byte_storm_en &&
                        byte_over_q)
                        byte_storm_active_g <= 1'b1;
                end
            end
        end
    end

    // 丢弃事件及软件统计计数。drop_reason 位定义：
    // [0]CRC 错误，[1]重复 CRC，[2]帧数风暴，[3]字节数风暴，[4]缓存满，
    // [5]长度错误，[6]黑名单，[7]未命中白名单，[8]目的 MAC 未命中。
    // 每个置位原因分别累加对应计数；通过帧只累加 stat_pass_cnt。
    always @(posedge gmii_rx_clk or posedge rst) begin
        if (rst) begin
            drop_valid  <= 1'b0;
            drop_reason <= DROP_NONE;

            stat_pass_cnt <= 32'd0;
            stat_drop_crc_err_cnt <= 32'd0;
            stat_drop_dup_crc_cnt <= 32'd0;
            stat_drop_frame_storm_cnt <= 32'd0;
            stat_drop_byte_storm_cnt <= 32'd0;
            stat_drop_buf_full_cnt <= 32'd0;
            stat_drop_len_err_cnt <= 32'd0;
            stat_drop_blacklist_cnt <= 32'd0;
            stat_drop_not_white_cnt <= 32'd0;
            stat_drop_dst_miss_cnt <= 32'd0;
            stat_win_frame_cnt <= 32'd0;
            stat_win_byte_cnt <= 32'd0;
            stat_last_drop_reason <= DROP_NONE;
            stat_frame_storm_active <= 1'b0;
            stat_byte_storm_active  <= 1'b0;
        end else begin
            // 默认无事件；只有本拍真正提交了一帧丢弃判决时才拉高一个周期。
            drop_valid  <= 1'b0;
            drop_reason <= DROP_NONE;

            if (cfg_clear_stats_g2) begin
                stat_pass_cnt <= 32'd0;
                stat_drop_crc_err_cnt <= 32'd0;
                stat_drop_dup_crc_cnt <= 32'd0;
                stat_drop_frame_storm_cnt <= 32'd0;
                stat_drop_byte_storm_cnt <= 32'd0;
                stat_drop_buf_full_cnt <= 32'd0;
                stat_drop_len_err_cnt <= 32'd0;
                stat_drop_blacklist_cnt <= 32'd0;
                stat_drop_not_white_cnt <= 32'd0;
                stat_drop_dst_miss_cnt <= 32'd0;
                stat_win_frame_cnt <= 32'd0;
                stat_win_byte_cnt <= 32'd0;
                stat_last_drop_reason <= DROP_NONE;
                stat_frame_storm_active <= 1'b0;
                stat_byte_storm_active  <= 1'b0;
            end else begin
                // stat_win_* 是当前窗口实时镜像，而非上一完整窗口的快照。
                if (win_rollover) begin
                    if (commit_can_push && dec_count_window_q) begin
                        stat_win_frame_cnt <= frame_cnt_next_q;
                        stat_win_byte_cnt  <= byte_cnt_next_q;
                        stat_frame_storm_active <= cfg_filter_en && cfg_frame_storm_en && frame_over_q;
                        stat_byte_storm_active  <= cfg_filter_en && cfg_byte_storm_en  && byte_over_q;
                    end else begin
                        stat_win_frame_cnt <= 32'd0;
                        stat_win_byte_cnt  <= 32'd0;
                        stat_frame_storm_active <= 1'b0;
                        stat_byte_storm_active  <= 1'b0;
                    end
                end else if (commit_can_push && dec_count_window_q) begin
                    stat_win_frame_cnt <= frame_cnt_next_q;
                    stat_win_byte_cnt  <= byte_cnt_next_q;
                    if (cfg_filter_en && cfg_frame_storm_en && frame_over_q)
                        stat_frame_storm_active <= 1'b1;
                    if (cfg_filter_en && cfg_byte_storm_en && byte_over_q)
                        stat_byte_storm_active <= 1'b1;
                end

                if (commit_can_push) begin
                    if (dec_pass_q) begin
                        stat_pass_cnt <= stat_pass_cnt + 32'd1;
                    end else begin
                        drop_valid <= 1'b1;
                        drop_reason <= dec_drop_reason_q;
                        stat_last_drop_reason <= dec_drop_reason_q;
                        if (dec_drop_reason_q[0]) stat_drop_crc_err_cnt <= stat_drop_crc_err_cnt + 32'd1;
                        if (dec_drop_reason_q[1]) stat_drop_dup_crc_cnt <= stat_drop_dup_crc_cnt + 32'd1;
                        if (dec_drop_reason_q[2]) stat_drop_frame_storm_cnt <= stat_drop_frame_storm_cnt + 32'd1;
                        if (dec_drop_reason_q[3]) stat_drop_byte_storm_cnt <= stat_drop_byte_storm_cnt + 32'd1;
                        if (dec_drop_reason_q[4]) stat_drop_buf_full_cnt <= stat_drop_buf_full_cnt + 32'd1;
                        if (dec_drop_reason_q[5]) stat_drop_len_err_cnt <= stat_drop_len_err_cnt + 32'd1;
                        if (dec_drop_reason_q[6]) stat_drop_blacklist_cnt <= stat_drop_blacklist_cnt + 32'd1;
                        if (dec_drop_reason_q[7]) stat_drop_not_white_cnt <= stat_drop_not_white_cnt + 32'd1;
                        if (dec_drop_reason_q[8]) stat_drop_dst_miss_cnt <= stat_drop_dst_miss_cnt + 32'd1;
                    end
                end
            end
        end
    end

endmodule
```
