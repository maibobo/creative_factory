`timescale 1ps / 1ps

// XDMA AXI-MM 活动监视器：用 Endpoint 本地 AXI 握手判断 DMA 数据面是否前进。
// 这些计数只用于仿真等待/诊断；DMA 完成后仍会通过 PCIe 读取
// descriptor count 和 status，因此不会绕过软件可见的 XDMA 完成语义。
// 输入：XDMA 本地 AXI AW/W/B/AR/R 有效握手和 clear_counters。
// 输出：写/读字节、响应、burst 和 response error 计数。
// 失败定位：长时间无计数说明 DMA 数据面未启动；有字节无 response 查 AXI 从端；
// response_error 非零直接判失败；最终仍以 descriptor count/status 收口。
module xdma_axi_activity_monitor (
    input             axi_aclk,
    input             axi_aresetn,
    input             clear_counters,

    input      [7:0]  m_axi_wstrb,
    input             m_axi_wvalid,
    input             m_axi_wready,
    input      [1:0]  m_axi_bresp,
    input             m_axi_bvalid,
    input             m_axi_bready,

    input      [1:0]  m_axi_rresp,
    input             m_axi_rlast,
    input             m_axi_rvalid,
    input             m_axi_rready,

    output reg [31:0] write_bytes,
    output reg [31:0] write_responses,
    output reg [31:0] read_bytes,
    output reg [31:0] read_bursts,
    output reg [31:0] response_errors
);
    integer lane;
    reg [4:0] valid_write_bytes;

    // ---------- 语义段 1：按 WSTRB 计算本拍有效字节 ----------
    // 输入：m_axi_wstrb；输出：write_bytes_this_beat。
    // 失败定位：C2H/H2C 字节数差异先核对 strobe，而不是固定按 8 B 计数。

    always @* begin
        valid_write_bytes = 5'd0;
        for (lane = 0; lane < 8; lane = lane + 1)
            valid_write_bytes = valid_write_bytes + m_axi_wstrb[lane];
    end

    // ---------- 语义段 2：AXI 活动计数和清除 ----------
    // 输入：五通道真实握手；输出：事务级进度计数。
    // 失败定位：定位到停止增长的通道，再查看对应 ready/valid/last/resp。

    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn || clear_counters) begin
            write_bytes     <= 32'd0;
            write_responses <= 32'd0;
            read_bytes      <= 32'd0;
            read_bursts     <= 32'd0;
            response_errors <= 32'd0;
        end else begin
            if (m_axi_wvalid && m_axi_wready)
                write_bytes <= write_bytes + valid_write_bytes;

            if (m_axi_bvalid && m_axi_bready) begin
                write_responses <= write_responses + 1;
                if (m_axi_bresp != 2'b00) begin
                    response_errors <= response_errors + 1;
                    $error("RTDS_XDMA_AXI_BRESP: H2C AXI 写响应=%b", m_axi_bresp);
                end
            end

            // 本设计 AXI 数据宽度为 64 bit，512 B 用例全部按 8 B 对齐。
            if (m_axi_rvalid && m_axi_rready) begin
                read_bytes <= read_bytes + 8;
                if (m_axi_rlast)
                    read_bursts <= read_bursts + 1;
                if (m_axi_rresp != 2'b00) begin
                    response_errors <= response_errors + 1;
                    $error("RTDS_XDMA_AXI_RRESP: C2H AXI 读响应=%b", m_axi_rresp);
                end
            end
        end
    end
endmodule
