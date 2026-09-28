`timescale 1ns / 1ps

// XDMA 的 usr_irq_ack/msi_enable 未导出到 BD 顶层；bind monitor 只观察，
// 不修改 design_1 或生产 RTL 端口。
// 输入：XDMA 内部 usr_irq_req/ack、msi_enable 和 AXI 时钟复位。
// 输出：seen_req/seen_ack/seen_msi_enable 生命周期证据。
// 失败定位：req 未见查 Adapter/BD 路由；req 有而 ack 无查 MSI 配置和 XDMA；
// ack 只证明 XDMA 接受消息，不等同于主机软件 ISR 已执行。
module xdma_irq_monitor (
    input             axi_aclk,
    input             axi_aresetn,
    input      [0:0]  usr_irq_req,
    input      [0:0]  usr_irq_ack,
    input             msi_enable
);
    reg seen_req;
    reg seen_ack;
    reg seen_msi_enable;

    // ---------- 语义段 1：观测状态初始化 ----------
    // 输入：无；输出：seen_* 从零开始，防止跨用例历史污染。
    initial begin
        seen_req        = 1'b0;
        seen_ack        = 1'b0;
        seen_msi_enable = 1'b0;
    end

    // ---------- 语义段 2：IRQ/MSI 证据锁存 ----------
    // 输入：复位后的 req/ack/enable；输出：一旦出现即保持的 seen_*。
    // 失败定位：最终门禁分别检查三项，可区分未配置、未请求和未接受。

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            seen_req <= 1'b0;
            seen_ack <= 1'b0;
        end else begin
            if (usr_irq_req[0])
                seen_req <= 1'b1;
            if (usr_irq_ack[0])
                seen_ack <= 1'b1;
            if (msi_enable)
                seen_msi_enable <= 1'b1;
        end
    end
endmodule

bind design_1_xdma_0_0 xdma_irq_monitor u_rtds_xdma_irq_monitor (
    .axi_aclk   (axi_aclk),
    .axi_aresetn(axi_aresetn),
    .usr_irq_req(usr_irq_req),
    .usr_irq_ack(usr_irq_ack),
    .msi_enable (msi_enable)
);
