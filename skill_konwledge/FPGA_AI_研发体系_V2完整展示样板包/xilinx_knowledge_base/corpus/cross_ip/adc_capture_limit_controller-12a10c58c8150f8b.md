# adc_capture_limit_controller

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\adc_capture_limit_controller.sv`
- SHA-256: `12a10c58c8150f8bc88daa490d8a2869d930a42fc41a65c30ca60569b15a6e67`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\adc_capture_limit_controller.sv

```systemverilog
`timescale 1ns/1ps

// 把FDMA兼容寄存器在sys_clk域产生的“固定字节数Capture”请求安全送到
// adc_clk域。控制信息在请求期间保持稳定，启动/停止/完成使用Toggle CDC；
// 检测启动Toggle后额外等待一拍再锁存多位上下文，避免Toggle先于总线同步。
module adc_capture_limit_controller (
    input  wire         sys_clk,    // FDMA寄存器所在系统时钟域
    input  wire         sys_rst_n,    // 系统域低有效同步复位
    input  wire         start_pulse_sys,    // 软件START写命令形成的单拍脉冲
    input  wire         stop_pulse_sys,    // 软件STOP写命令形成的单拍脉冲
    input  wire [63:0]  target_bytes_sys,    // 本次Capture期望保存的Payload字节数
    input  wire         two_channel_sys,    // 软件配置的双通道模式
    input  wire         single_select_sys,    // 单通道模式下的通道选择
    input  wire [63:0]  capture_id_sys,    // 软件配置的Capture编号
    output wire         local_done_pulse_sys,    // ADC侧完整排空后返回系统域的单拍完成脉冲
    output wire         cancelled_pulse_sys,    // 尚未启采即被STOP取消的单拍指示
    output wire         controller_busy_sys,    // 同步到系统域的Capture控制忙状态

    input  wire         adc_clk,    // Packer所在ADC采样时钟域
    input  wire         adc_rst_n,    // ADC域低有效异步复位
    input  wire         packer_capture_ready,    // Packer可以接受新Capture
    input  wire         packer_capture_active,    // Packer仍在采样或排空尾字
    input  wire [63:0]  packer_accepted_sample_times,    // Packer实际接受的数据时刻数
    output reg          capture_start_adc,    // 送Packer的单拍START
    output wire         capture_stop_adc,    // 手动或定长条件形成的停止电平
    output reg          cfg_two_channel_adc,    // 已在ADC域锁存的单双通道配置
    output reg          cfg_single_select_adc,    // 已在ADC域锁存的单通道选择
    output reg  [63:0]  cfg_capture_id_adc    // 已在ADC域锁存的Capture编号
);

    reg start_toggle_sys;    // 每次START脉冲翻转，供ADC域跨时钟检测
    reg stop_toggle_sys;    // 每次STOP脉冲翻转，供ADC域跨时钟检测
    reg done_meta_sys;    // 完成Toggle返回系统域的第一级同步寄存器
    reg done_sync_sys;    // 完成Toggle返回系统域的第二级同步寄存器
    reg done_seen_sys;    // 系统域已消费的完成Toggle值
    reg cancel_meta_sys;    // 取消Toggle返回系统域的第一级同步寄存器
    reg cancel_sync_sys;    // 取消Toggle返回系统域的第二级同步寄存器
    reg cancel_seen_sys;    // 系统域已消费的取消Toggle值
    reg busy_meta_sys;    // ADC忙电平返回系统域的第一级同步寄存器
    reg busy_sync_sys;    // ADC忙电平返回系统域的第二级同步寄存器

    reg done_toggle_adc;    // 每次ADC侧Capture结束时翻转
    reg cancel_toggle_adc;    // 每次未启采取消事件发生时翻转
    reg busy_adc;    // ADC域控制器已有Capture上下文
    reg manual_stop_adc;    // 已同步STOP在ADC域形成的单拍停止请求

    assign local_done_pulse_sys = done_sync_sys ^ done_seen_sys;
    assign cancelled_pulse_sys = cancel_sync_sys ^ cancel_seen_sys;
    assign controller_busy_sys = busy_sync_sys;

    always @(posedge sys_clk) begin
        if (!sys_rst_n) begin
            start_toggle_sys <= 1'b0;
            stop_toggle_sys  <= 1'b0;
            done_meta_sys    <= 1'b0;
            done_sync_sys    <= 1'b0;
            done_seen_sys    <= 1'b0;
            cancel_meta_sys  <= 1'b0;
            cancel_sync_sys  <= 1'b0;
            cancel_seen_sys  <= 1'b0;
            busy_meta_sys    <= 1'b0;
            busy_sync_sys    <= 1'b0;
        end else begin
            if (start_pulse_sys)
                start_toggle_sys <= ~start_toggle_sys;
            if (stop_pulse_sys)
                stop_toggle_sys <= ~stop_toggle_sys;
            done_meta_sys <= done_toggle_adc;
            done_sync_sys <= done_meta_sys;
            if (done_sync_sys != done_seen_sys)
                done_seen_sys <= done_sync_sys;
            cancel_meta_sys <= cancel_toggle_adc;
            cancel_sync_sys <= cancel_meta_sys;
            if (cancel_sync_sys != cancel_seen_sys)
                cancel_seen_sys <= cancel_sync_sys;
            busy_meta_sys <= busy_adc;
            busy_sync_sys <= busy_meta_sys;
        end
    end

    reg start_meta_adc;    // START Toggle进入ADC域的第一级同步寄存器
    reg start_sync_adc;    // START Toggle进入ADC域的第二级同步寄存器
    reg start_seen_adc;    // ADC域已消费的START Toggle值
    reg stop_meta_adc;    // STOP Toggle进入ADC域的第一级同步寄存器
    reg stop_sync_adc;    // STOP Toggle进入ADC域的第二级同步寄存器
    reg stop_seen_adc;    // ADC域已消费的STOP Toggle值
    reg [63:0] bytes_meta_adc;    // 目标字节数多位上下文的第一级采样
    reg [63:0] bytes_sync_adc;    // 目标字节数多位上下文的第二级稳定值
    reg two_meta_adc;    // 双通道配置的第一级采样
    reg two_sync_adc;    // 双通道配置的第二级稳定值
    reg select_meta_adc;    // 单通道选择的第一级采样
    reg select_sync_adc;    // 单通道选择的第二级稳定值
    reg [63:0] id_meta_adc;    // Capture编号的第一级采样
    reg [63:0] id_sync_adc;    // Capture编号的第二级稳定值

    localparam [2:0] ST_IDLE       = 3'd0;    // 无活动请求，等待START Toggle
    localparam [2:0] ST_CONTEXT    = 3'd1;    // 额外等待一拍后锁存多位上下文
    localparam [2:0] ST_WAIT_READY = 3'd2;    // 等待Packer可接受START
    localparam [2:0] ST_RUNNING    = 3'd3;    // Packer采样中，监视定长或手动停止
    localparam [2:0] ST_WAIT_IDLE  = 3'd4;    // 已发STOP，等待Packer排空EOC
    reg [2:0] state;    // Capture控制器当前状态
    reg [63:0] target_sample_times;    // target_bytes换算后的目标数据时刻数
    reg cancel_next_start_adc;    // STOP先到时记住取消意图，拦截迟到START

    // accepted计数在Packer时序块中更新。组合拉高auto stop可保证计数达到
    // 目标后的下一个采样沿，Packer先看到stop，不会再多接收一个样本。
    assign capture_stop_adc =
        manual_stop_adc ||
        ((state == ST_RUNNING) &&
         (target_sample_times != 0) &&
         (packer_accepted_sample_times >= target_sample_times));

    always @(posedge adc_clk or negedge adc_rst_n) begin
        if (!adc_rst_n) begin
            start_meta_adc       <= 1'b0;
            start_sync_adc       <= 1'b0;
            start_seen_adc       <= 1'b0;
            stop_meta_adc        <= 1'b0;
            stop_sync_adc        <= 1'b0;
            stop_seen_adc        <= 1'b0;
            bytes_meta_adc       <= 64'd0;
            bytes_sync_adc       <= 64'd0;
            two_meta_adc         <= 1'b0;
            two_sync_adc         <= 1'b0;
            select_meta_adc      <= 1'b0;
            select_sync_adc      <= 1'b0;
            id_meta_adc          <= 64'd0;
            id_sync_adc          <= 64'd0;
            done_toggle_adc      <= 1'b0;
            cancel_toggle_adc    <= 1'b0;
            busy_adc             <= 1'b0;
            manual_stop_adc      <= 1'b0;
            capture_start_adc    <= 1'b0;
            cfg_two_channel_adc  <= 1'b0;
            cfg_single_select_adc <= 1'b0;
            cfg_capture_id_adc   <= 64'd0;
            state                 <= ST_IDLE;
            target_sample_times   <= 64'd0;
            cancel_next_start_adc <= 1'b0;
        end else begin
            start_meta_adc  <= start_toggle_sys;
            start_sync_adc  <= start_meta_adc;
            stop_meta_adc   <= stop_toggle_sys;
            stop_sync_adc   <= stop_meta_adc;
            bytes_meta_adc  <= target_bytes_sys;
            bytes_sync_adc  <= bytes_meta_adc;
            two_meta_adc    <= two_channel_sys;
            two_sync_adc    <= two_meta_adc;
            select_meta_adc <= single_select_sys;
            select_sync_adc <= select_meta_adc;
            id_meta_adc     <= capture_id_sys;
            id_sync_adc     <= id_meta_adc;

            capture_start_adc <= 1'b0;
            manual_stop_adc   <= 1'b0;

            if (stop_sync_adc != stop_seen_adc) begin
                stop_seen_adc <= stop_sync_adc;
                if ((state == ST_CONTEXT) || (state == ST_WAIT_READY)) begin
                    // START上下文同步期间或等待Packer就绪期间收到STOP时，
                    // 直接取消尚未真正开始的Capture，并向软件回送本地完成。
                    busy_adc        <= 1'b0;
                    done_toggle_adc <= ~done_toggle_adc;
                    cancel_toggle_adc <= ~cancel_toggle_adc;
                    cancel_next_start_adc <= 1'b0;
                    state           <= ST_IDLE;
                end else if (state == ST_RUNNING) begin
                    manual_stop_adc <= 1'b1;
                    state           <= ST_WAIT_IDLE;
                end else if (state == ST_IDLE) begin
                    // STOP可能比同一任务的START Toggle先到达ADC域。若START
                    // 已经可见就同拍消费；否则记住取消意图，禁止迟到START启动。
                    if (start_sync_adc != start_seen_adc) begin
                        start_seen_adc   <= start_sync_adc;
                        done_toggle_adc  <= ~done_toggle_adc;
                        cancel_toggle_adc <= ~cancel_toggle_adc;
                        cancel_next_start_adc <= 1'b0;
                    end else begin
                        cancel_next_start_adc <= 1'b1;
                    end
                end
            end else begin
                case (state)
                    ST_IDLE: begin
                        busy_adc <= 1'b0;
                        if (start_sync_adc != start_seen_adc) begin
                            start_seen_adc <= start_sync_adc;
                            if (cancel_next_start_adc) begin
                                cancel_next_start_adc <= 1'b0;
                                done_toggle_adc       <= ~done_toggle_adc;
                                cancel_toggle_adc     <= ~cancel_toggle_adc;
                            end else begin
                                busy_adc <= 1'b1;
                                state    <= ST_CONTEXT;
                            end
                        end
                    end

                    ST_CONTEXT: begin
                        // Toggle与多位上下文分别经过两级同步；多等这一拍后锁存。
                        cfg_two_channel_adc   <= two_sync_adc;
                        cfg_single_select_adc <= select_sync_adc;
                        cfg_capture_id_adc    <= id_sync_adc;
                        target_sample_times   <= bytes_sync_adc /
                            (two_sync_adc ? 64'd4 : 64'd2);
                        state <= ST_WAIT_READY;
                    end

                    ST_WAIT_READY: begin
                        if (packer_capture_ready) begin
                            capture_start_adc <= 1'b1;
                            state             <= ST_RUNNING;
                        end
                    end

                    ST_RUNNING: begin
                        // Packer计数只包含实际保存的样本时刻；达到目标后的下一拍
                        // 发stop，packer的stop优先级高于同拍adc_valid，不会多收一拍。
                        if (packer_accepted_sample_times >=
                            target_sample_times) begin
                            state <= ST_WAIT_IDLE;
                        end
                    end

                    ST_WAIT_IDLE: begin
                        if (!packer_capture_active) begin
                            busy_adc        <= 1'b0;
                            done_toggle_adc <= ~done_toggle_adc;
                            state           <= ST_IDLE;
                        end
                    end

                    default: begin
                        busy_adc <= 1'b0;
                        state    <= ST_IDLE;
                    end
                endcase
            end
        end
    end

endmodule
```
