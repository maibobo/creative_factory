`timescale 1ns / 1ps

// CONV_DMA 的 AXI 响应监视器。
// 输入：CONV_DMA AXI B/R response valid 与 response code。
// 输出：response_error_count 和明确的仿真错误日志；不向 DUT 反馈。
// 作用：覆盖 FDMA→AXI 转换后的地址/互连/从设备错误。
// 失败定位：BRESP 查写地址/写 burst，RRESP 查读地址/读 burst；任何非 OKAY
// 都属于真实数据面失败，不能加入 warning 白名单。
module conv_dma_axi_monitor (
    input       M_AXI_ACLK,
    input       M_AXI_ARESETN,
    input [1:0] M_AXI_BRESP,
    input       M_AXI_BVALID,
    input [1:0] M_AXI_RRESP,
    input       M_AXI_RVALID
);
    // ---------- 语义段 1：确定性初始化 ----------
    // 输入：无；输出：错误计数从零开始。
    integer response_error_count;
    initial response_error_count = 0;

    // ---------- 语义段 2：逐拍采样 AXI response ----------
    // 输入：复位结束后的 BVALID/BRESP、RVALID/RRESP；输出：错误计数和 $error。
    // 失败定位：根据日志 WRITE/READ 类型回看同一事务的 AW/W 或 AR/R 波形。

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
