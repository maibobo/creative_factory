# conv_dma_axi_monitor

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\conv_dma_axi_monitor.sv`
- SHA-256: `3e8bd773c1168bc818cb8adf350fb0b0d74ca855e26269c2eb943c2e070ef876`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns / 1ps

// CONV_DMA 的 AXI 响应监视器：任何非 OKAY 响应都表示地址或互连错误。
module conv_dma_axi_monitor (
    input       M_AXI_ACLK,
    input       M_AXI_ARESETN,
    input [1:0] M_AXI_BRESP,
    input       M_AXI_BVALID,
    input [1:0] M_AXI_RRESP,
    input       M_AXI_RVALID
);
    integer response_error_count;
    initial response_error_count = 0;

    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN) begin
            if (M_AXI_BVALID && M_AXI_BRESP != 2'b00) begin
                response_error_count = response_error_count + 1;
                $error("RTDS_AXI_BRESP: CONV_DMA 收到非 OKAY 写响应 %b", M_AXI_BRESP);
            end
            if (M_AXI_RVALID && M_AXI_RRESP != 2'b00) begin
                response_error_count = response_error_count + 1;
                $error("RTDS_AXI_RRESP: CONV_DMA 收到非 OKAY 读响应 %b", M_AXI_RRESP);
            end
        end
    end
endmodule

bind CONV_DMA conv_dma_axi_monitor u_rtds_conv_dma_axi_monitor (
    .M_AXI_ACLK   (M_AXI_ACLK),
    .M_AXI_ARESETN(M_AXI_ARESETN),
    .M_AXI_BRESP  (M_AXI_BRESP),
    .M_AXI_BVALID (M_AXI_BVALID),
    .M_AXI_RRESP  (M_AXI_RRESP),
    .M_AXI_RVALID (M_AXI_RVALID)
);
```
