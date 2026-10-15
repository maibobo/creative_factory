# adc_channel_packer

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\adc_channel_packer.sv`
- SHA-256: `03a1938867d314b7420edd58c6485be8ab4b0c96210729712d9021437b324a46`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\adc_channel_packer.sv

```systemverilog
`timescale 1ns/1ps

// ADC采样时钟域的数据格式化与打包模块。
//
// 运行时支持三种格式：
//   1) cfg_two_channel=1：每个采样时刻写入{CH1[15:0], CH0[15:0]}，
//      8个采样时刻组成一个256 bit输出字。
//   2) cfg_two_channel=0且select=0：只保存CH0，每样本16 bit，
//      16个样本组成一个256 bit输出字。
//   3) cfg_two_channel=0且select=1：只保存CH1，格式与CH0模式相同。
//
// capture_start只在capture_ready为1时接受并锁存本次Capture配置。ADC输入
// 本身不能被反压；当输出寄存器和第二级弹性缓存同时占满时，后续adc_valid
// 会被计入dropped_sample_times，并置位overflow_sticky。
module adc_channel_packer #(
    parameter bit SIGN_EXTEND = 1'b1    // 1：12 bit ADC值按二补码符号扩展；0：零扩展
) (
    input  logic         adc_clk,    // ADC采样时钟，采样接收和打包状态机均在此域运行
    input  logic         adc_rst_n,    // ADC域低有效异步复位

    // Capture控制与待锁存运行配置。capture_stop优先于同周期adc_valid。
    input  logic         capture_start,    // 新Capture启动脉冲，仅在capture_ready=1时接受
    input  logic         capture_stop,    // 当前Capture停止请求，优先于同拍adc_valid
    input  logic         cfg_two_channel,    // 待锁存模式：1=双通道，0=单通道
    input  logic         cfg_single_channel_select,    // 单通道模式选择：0=CH0，1=CH1
    input  logic [63:0]  cfg_capture_id,    // 软件分配的Capture编号，随START锁存

    // 解串完成后的两路12 bit并行ADC数据；adc_valid表示本周期样本有效。
    input  logic         adc_valid,    // 本拍两路ADC输入有效；源端不能接受反压
    input  logic [11:0]  adc_ch0,    // 通道0原始12 bit采样值
    input  logic [11:0]  adc_ch1,    // 通道1原始12 bit采样值

    // 送往CDC FIFO的ready/valid接口。valid_bytes给出tdata低位中真实有效
    // 的字节数，范围0～32；end_of_capture标记本次Capture的最后一个传输。
    output logic [255:0] m_axis_tdata,    // 打包后的256 bit数据，低位字节先写
    output logic [5:0]   m_axis_valid_bytes,    // 本传输真实字节数，取值0～32
    output logic         m_axis_end_of_capture,    // 本传输是Capture末尾标记
    output logic         m_axis_tvalid,    // 输出寄存器内容有效
    input  logic         m_axis_tready,    // 下游CDC FIFO可接收；与tvalid共同完成握手

    // 状态、已锁存配置和诊断计数。accepted/dropped的单位都是“采样时刻”。
    output logic         capture_active,    // 非IDLE即为1，表示Capture尚未完全排空
    output logic         capture_ready,    // 可以无歧义接受下一次START
    output logic         active_two_channel,    // 本次Capture已锁存的单双通道模式
    output logic         active_single_channel_select,    // 本次Capture已锁存的单通道选择
    output logic [63:0]  active_capture_id,    // 本次Capture已锁存的编号
    output logic         overflow_sticky,    // 溢出粘滞位：置1后保持到复位或下一次Capture清除
    output logic         config_change_sticky,    // 运行中配置变化粘滞位
    output logic [63:0]  accepted_sample_times,    // 已成功纳入打包的数据时刻数
    output logic [63:0]  dropped_sample_times    // 因两级缓存均占用而丢弃的数据时刻数
);

    // IDLE等待一次合法start；ACTIVE持续收样；DRAIN发出最后一个EOC传输，
    // 并等待其被下游接收后才回到IDLE。
    localparam logic [1:0] ST_IDLE   = 2'd0;    // 空闲，等待并锁存下一次Capture配置
    localparam logic [1:0] ST_ACTIVE = 2'd1;    // 采样有效期，持续接收并打包ADC数据
    localparam logic [1:0] ST_DRAIN  = 2'd2;    // 停采后排出尾字和EOC，握手后才结束Capture

    logic [1:0] state;    // Packer主状态机当前状态
    // pack_data是正在组装的第二级缓冲，数据从低地址/低bit向高位依次填充。
    logic [255:0] pack_data;    // 尚未提交到输出寄存器的组包缓冲
    logic [5:0] pack_byte_count;    // pack_data中已占用的真实字节数
    // 当输出寄存器仍被背压、pack_data又刚好凑满32 Byte时置位。该标志
    // 保证完整的第二个字不会被后续样本覆盖。
    logic pack_full_pending;    // 第二个完整输出字等待进入输出寄存器
    // 防止DRAIN状态重复生成结束传输。
    logic eoc_loaded;    // DRAIN已装载一次EOC，防止反压期间重复生成

    // 当前样本的扩展结果和按模式选择后的待追加数据。
    logic [15:0] ch0_ext;    // CH0按SIGN_EXTEND扩展后的16 bit值
    logic [15:0] ch1_ext;    // CH1按SIGN_EXTEND扩展后的16 bit值
    logic [31:0] selected_word;    // 当前模式选择后的本拍追加数据，最多4 Byte
    logic [5:0] selected_bytes;    // 当前采样时刻占用字节数：双通道4，单通道2
    logic [255:0] pack_with_sample;    // 把当前样本追加到pack_data后的组合结果
    logic [5:0] next_byte_count;    // 接受当前样本后的组包字节计数
    logic output_take;    // 输出握手事件：tvalid=1且tready=1
    logic output_free;    // 输出寄存器当前为空或本拍将被取走

    // 组合构造“追加当前样本后的打包字”。双通道每次追加4 Byte，单通道
    // 每次追加2 Byte；可变part-select的起点由已使用字节数换算为bit位置。
    always @* begin
        if (SIGN_EXTEND) begin
            ch0_ext = {{4{adc_ch0[11]}}, adc_ch0};
            ch1_ext = {{4{adc_ch1[11]}}, adc_ch1};
        end else begin
            ch0_ext = {4'b0000, adc_ch0};
            ch1_ext = {4'b0000, adc_ch1};
        end

        // 双通道固定CH0在低16 bit、CH1在高16 bit。单通道不保留另一路
        // 的占位空间，因此是真正的紧凑16 bit格式。
        if (active_two_channel) begin
            selected_word  = {ch1_ext, ch0_ext};
            selected_bytes = 6'd4;
        end else begin
            selected_word  = active_single_channel_select ?
                             {16'd0, ch1_ext} : {16'd0, ch0_ext};
            selected_bytes = 6'd2;
        end

        pack_with_sample = pack_data;
        if (active_two_channel)
            pack_with_sample[pack_byte_count*8 +: 32] = selected_word;
        else
            pack_with_sample[pack_byte_count*8 +: 16] = selected_word[15:0];
        next_byte_count = pack_byte_count + selected_bytes;
    end

    // output_free在当前拍已完成握手时也为1，使模块能在同一时钟沿完成
    // “旧字被取走、下一字装入输出寄存器”，避免无谓空拍。
    assign output_take = m_axis_tvalid && m_axis_tready;
    assign output_free = !m_axis_tvalid || output_take;
    assign capture_active = (state != ST_IDLE);
    assign capture_ready = (state == ST_IDLE) && !m_axis_tvalid &&
                           m_axis_tready;

    // 主Capture状态机。stall指valid=1且ready=0的反压停顿；stall期间
    // m_axis_tdata、有效字节数和EOC标志必须保持不变，直到完成握手。
    always_ff @(posedge adc_clk or negedge adc_rst_n) begin
        if (!adc_rst_n) begin
            state                         <= ST_IDLE;
            pack_data                     <= 256'd0;
            pack_byte_count               <= 6'd0;
            pack_full_pending             <= 1'b0;
            eoc_loaded                    <= 1'b0;
            m_axis_tdata                  <= 256'd0;
            m_axis_valid_bytes            <= 6'd0;
            m_axis_end_of_capture         <= 1'b0;
            m_axis_tvalid                 <= 1'b0;
            active_two_channel            <= 1'b0;
            active_single_channel_select  <= 1'b0;
            active_capture_id             <= 64'd0;
            overflow_sticky               <= 1'b0;
            config_change_sticky          <= 1'b0;
            accepted_sample_times         <= 64'd0;
            dropped_sample_times          <= 64'd0;
        end else begin
            // ready/valid握手后默认撤销valid；下面的状态分支可以在同一拍装载
            // 下一字并重新置valid，实现连续吞吐。
            if (output_take)
                m_axis_tvalid <= 1'b0;

            if ((state != ST_IDLE) && capture_start)
                config_change_sticky <= 1'b1;

            case (state)
                ST_IDLE: begin
                    eoc_loaded <= 1'b0;
                    if (capture_start && capture_ready) begin
                        // Capture配置只在此处锁存。后续外部cfg变化只记错误，
                        // 不会改变正在进行的字节格式。
                        state                        <= ST_ACTIVE;
                        pack_data                    <= 256'd0;
                        pack_byte_count              <= 6'd0;
                        pack_full_pending            <= 1'b0;
                        active_two_channel           <= cfg_two_channel;
                        active_single_channel_select <= cfg_single_channel_select;
                        active_capture_id            <= cfg_capture_id;
                        overflow_sticky              <= 1'b0;
                        config_change_sticky         <= 1'b0;
                        accepted_sample_times        <= 64'd0;
                        dropped_sample_times         <= 64'd0;
                    end else if (capture_start) begin
                        // CDC FIFO尚未退出复位或未声明ready时拒绝过早START，
                        // 并以溢出粘滞位把该瞬时控制错误保留下来。
                        overflow_sticky <= 1'b1;
                    end
                end

                ST_ACTIVE: begin
                    // 运行中配置变化属于控制面使用错误。比较capture_id可同时
                    // 发现软件在未结束当前Capture时误启动了另一编号的Capture。
                    if ((cfg_two_channel != active_two_channel) ||
                        (cfg_single_channel_select != active_single_channel_select) ||
                        (cfg_capture_id != active_capture_id))
                        config_change_sticky <= 1'b1;

                    if (capture_stop) begin
                        // stop周期不再接收adc_valid；进入DRAIN后发送已积累的尾字。
                        state <= ST_DRAIN;
                    end else if (pack_full_pending) begin
                        // pack_data已是完整的第二输出字；第一个输出字受反压时
                        // 必须保持第二字不变，直到输出寄存器腾空。
                        if (output_free) begin
                            m_axis_tdata          <= pack_data;
                            m_axis_valid_bytes    <= 6'd32;
                            m_axis_end_of_capture <= 1'b0;
                            m_axis_tvalid         <= 1'b1;
                            pack_full_pending     <= 1'b0;
                            if (adc_valid) begin
                                // 发送pending整字的同时，把本周期新样本放到下一字
                                // 的最低位置，保证ADC连续输入不因一次正常握手而断档。
                                pack_data               <= 256'd0;
                                if (active_two_channel)
                                    pack_data[31:0]      <= selected_word;
                                else
                                    pack_data[15:0]      <= selected_word[15:0];
                                pack_byte_count          <= selected_bytes;
                                accepted_sample_times    <=
                                    accepted_sample_times + 1'b1;
                            end else begin
                                pack_data       <= 256'd0;
                                pack_byte_count <= 6'd0;
                            end
                        end else if (adc_valid) begin
                            // 输出寄存器和pack_data均占用时无法再保存样本。这里
                            // 明确计数而不是静默丢弃，供上层判定本次Capture失效。
                            overflow_sticky      <= 1'b1;
                            dropped_sample_times <= dropped_sample_times + 1'b1;
                        end
                    end else if (adc_valid) begin
                        accepted_sample_times <= accepted_sample_times + 1'b1;
                        if (next_byte_count == 6'd32) begin
                            if (output_free) begin
                                m_axis_tdata          <= pack_with_sample;
                                m_axis_valid_bytes    <= 6'd32;
                                m_axis_end_of_capture <= 1'b0;
                                m_axis_tvalid         <= 1'b1;
                                pack_data             <= 256'd0;
                                pack_byte_count       <= 6'd0;
                            end else begin
                                // 输出寄存器与pack_data构成两级弹性缓存。stall
                                // 结束前保留完整第二字，避免其末样本被后续数据覆盖。
                                pack_data         <= pack_with_sample;
                                pack_byte_count   <= 6'd32;
                                pack_full_pending <= 1'b1;
                            end
                        end else begin
                            pack_data       <= pack_with_sample;
                            pack_byte_count <= next_byte_count;
                        end
                    end
                end

                ST_DRAIN: begin
                    if (!eoc_loaded && output_free) begin
                        // pack_byte_count可能为0：当最后一个完整256 bit字已经
                        // 发送时，用零字节EOC单独结束Capture；DDR Writer识别该
                        // 标记但不会把它作为一个额外数据beat写入DDR。
                        m_axis_tdata          <= pack_data;
                        m_axis_valid_bytes    <= pack_byte_count;
                        m_axis_end_of_capture <= 1'b1;
                        m_axis_tvalid         <= 1'b1;
                        eoc_loaded            <= 1'b1;
                        pack_data             <= 256'd0;
                        pack_byte_count       <= 6'd0;
                        pack_full_pending     <= 1'b0;
                    end else if (eoc_loaded && output_take) begin
                        state      <= ST_IDLE;
                        eoc_loaded <= 1'b0;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
```
