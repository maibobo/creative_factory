`timescale 1ns / 1ps
// File: cdc_sync.v

// 两级触发器单比特同步器。
// src_clk/src_rstn 用于标明源时钟域；本模块实际只使用 dst_clk/dst_rstn 时钟逻辑。
// cdc_sync 模块入口；提供单比特跨时钟域两级同步，主要用于把 Aurora 链路状态安全送入 FDMA 时钟域。
module cdc_sync (
    input  wire src_clk,      // 源时钟，本模块中有意不使用。
    input  wire src_rstn,     // 源复位，本模块中有意不使用。
    input  wire src_signal,   // 源时钟域的稳定单比特电平。
    input  wire dst_clk,      // 目标 时钟.
    input  wire dst_rstn,     // 低有效目标端复位。
    output wire dst_signal    // 已同步到 dst_clk 的电平。
);
    // 第一级可能进入亚稳态；下游逻辑只使用 sync_reg2。
    reg sync_reg1;
    reg sync_reg2;

    // 时序 always 块在指定时钟/复位边沿更新寄存器状态。
    always @(posedge dst_clk or negedge dst_rstn) begin
        // 复位有效或链路失锁时清空寄存器、计数器和状态机。
        if (!dst_rstn) begin
            sync_reg1 <= 1'b0;
            sync_reg2 <= 1'b0;
        end else begin
            sync_reg1 <= src_signal;
            sync_reg2 <= sync_reg1;
        end
    end

    assign dst_signal = sync_reg2;
endmodule