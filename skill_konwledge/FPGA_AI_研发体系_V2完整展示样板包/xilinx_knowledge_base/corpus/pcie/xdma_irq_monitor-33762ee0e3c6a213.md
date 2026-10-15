# xdma_irq_monitor

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\xdma_irq_monitor.sv`
- SHA-256: `33762ee0e3c6a2132e80cc9db3f42706ccfe52f1c97ac0d7415105b8dea18c62`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

// XDMA 的 usr_irq_ack/msi_enable 未导出到 BD 顶层；bind monitor 只观察，
// 不修改 design_1 或生产 RTL 端口。
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

    initial begin
        seen_req        = 1'b0;
        seen_ack        = 1'b0;
        seen_msi_enable = 1'b0;
    end

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            seen_req <= 1'b0;
            seen_ack <= 1'b0;
        end else begin
            if (usr_irq_req[0]) seen_req <= 1'b1;
            if (usr_irq_ack[0]) seen_ack <= 1'b1;
            if (msi_enable)     seen_msi_enable <= 1'b1;
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
```
