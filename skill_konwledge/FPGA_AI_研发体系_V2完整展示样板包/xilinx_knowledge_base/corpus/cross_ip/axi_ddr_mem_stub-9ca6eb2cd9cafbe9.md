# axi_ddr_mem_stub

- Category: `cross_ip`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\stubs\axi_ddr_mem_stub.sv`
- SHA-256: `9ca6eb2cd9cafbe9a643768a9e2048ad727620207ecff74085f0b306705e6703`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ns/1ps

// 行为级AXI写内存桩，只用于验证Writer产生的地址、数据、WSTRB和Burst边界。
//
// 它不是MIG或DDR时序/性能模型：没有校准、刷新、Bank/Row调度、读通道，
// 也不模拟SmartConnect和NVMe IP并发访问。测试平台可分层读取mem字节数组
// 对比预期Payload。
module axi_ddr_mem_stub #(
    // 与DUT AXI写口匹配的地址和数据位宽。
    parameter integer AXI_ADDR_WIDTH = 64,
    parameter integer AXI_DATA_WIDTH = 256,
    // 行为数组下标0对应的AXI物理地址；默认0保持原有测试平台行为。
    parameter [AXI_ADDR_WIDTH-1:0] MEM_BASE_ADDR = {AXI_ADDR_WIDTH{1'b0}},
    // 行为内存字节数；越界写会在本Burst返回SLVERR。
    parameter integer MEM_BYTES = 64 * 1024
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]                   s_axi_awlen,
    input  wire [2:0]                   s_axi_awsize,
    input  wire [1:0]                   s_axi_awburst,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready,
    input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  wire                         s_axi_wlast,
    input  wire                         s_axi_wvalid,
    output wire                         s_axi_wready,
    output reg  [1:0]                   s_axi_bresp,
    output reg                          s_axi_bvalid,
    input  wire                         s_axi_bready,
    // 打开后由LFSR随机撤销AWREADY/WREADY，并随机延迟BVALID。
    input  wire                         stall_enable,
    // 在下一次AW握手时锁存，仅使该Burst的B响应返回SLVERR。
    input  wire                         inject_bresp_error_next
);

    localparam integer BEAT_BYTES = AXI_DATA_WIDTH / 8;

    // 字节寻址使WSTRB语义可直接验证；不是可综合DDR存储实现。
    reg [7:0] mem [0:MEM_BYTES-1];

    // 桩一次只接收一个写Burst，严格按AW -> 多拍W -> B执行。
    reg burst_active;
    reg [AXI_ADDR_WIDTH-1:0] write_addr;
    reg [8:0] beats_remaining;
    reg [15:0] lfsr;
    reg b_pending;
    reg [3:0] b_delay;
    reg inject_error_latched;
    integer i;

    // AW只有在前一Burst及其B响应完全结束后才接受；W仅在Burst活动时接受。
    assign s_axi_awready = !burst_active && !s_axi_bvalid && !b_pending &&
                           (!stall_enable || lfsr[0]);
    assign s_axi_wready  = burst_active && (!stall_enable || lfsr[1]);

    always @(posedge clk) begin
        if (!rst_n) begin
            burst_active   <= 1'b0;
            write_addr     <= {AXI_ADDR_WIDTH{1'b0}};
            beats_remaining <= 9'd0;
            s_axi_bresp    <= 2'b00;
            s_axi_bvalid   <= 1'b0;
            lfsr           <= 16'h1ACE;
            b_pending      <= 1'b0;
            b_delay        <= 4'd0;
            inject_error_latched <= 1'b0;
        end else begin
            // 伪随机序列只控制反压/响应延迟，不改变被写入的数据。
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
            if (s_axi_awvalid && s_axi_awready) begin
                // 记录首地址和AWLEN+1拍；只接受总线宽度匹配的INCR Burst。
                burst_active    <= 1'b1;
                write_addr      <= s_axi_awaddr;
                beats_remaining <= s_axi_awlen + 1'b1;
                s_axi_bresp     <= ((s_axi_awsize == $clog2(BEAT_BYTES)) &&
                                    (s_axi_awburst == 2'b01)) ? 2'b00 : 2'b10;
                inject_error_latched <= inject_bresp_error_next;
            end

            if (s_axi_wvalid && s_axi_wready) begin
                // 每个WSTRB位对应一个字节，低字节位于较低DDR地址。
                for (i = 0; i < BEAT_BYTES; i = i + 1) begin
                    if (s_axi_wstrb[i] &&
                        (write_addr >= MEM_BASE_ADDR) &&
                        ((write_addr - MEM_BASE_ADDR + i) < MEM_BYTES))
                        mem[write_addr - MEM_BASE_ADDR + i] <=
                            s_axi_wdata[i*8 +: 8];
                end

                if ((write_addr < MEM_BASE_ADDR) ||
                    ((write_addr + BEAT_BYTES) < write_addr) ||
                    ((write_addr - MEM_BASE_ADDR + BEAT_BYTES) > MEM_BYTES))
                    s_axi_bresp <= 2'b10;

                if (beats_remaining == 1) begin
                    // 期望计数最后一拍同时出现WLAST；不匹配时本Burst报错。
                    if (!s_axi_wlast)
                        s_axi_bresp <= 2'b10;
                    burst_active    <= 1'b0;
                    beats_remaining <= 9'd0;
                    b_pending       <= 1'b1;
                    b_delay         <= stall_enable ? {1'b0, lfsr[4:2]} : 4'd0;
                    if (inject_error_latched)
                        s_axi_bresp <= 2'b10;
                end else begin
                    // 非末拍提前出现WLAST同样作为协议错误记录到BRESP。
                    if (s_axi_wlast)
                        s_axi_bresp <= 2'b10;
                    beats_remaining <= beats_remaining - 1'b1;
                    write_addr      <= write_addr + BEAT_BYTES;
                end
            end

            // 可编程随机延迟用于验证Writer不会把最后一拍W误当作job完成。
            if (b_pending) begin
                if (b_delay == 0) begin
                    b_pending   <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                end else begin
                    b_delay <= b_delay - 1'b1;
                end
            end

            // BVALID保持到DUT拉高BREADY，符合AXI valid/ready稳定性要求。
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    initial begin
        if ((MEM_BYTES <= 0) ||
            ((MEM_BASE_ADDR + MEM_BYTES) < MEM_BASE_ADDR))
            $error("Invalid behavioral DDR address window");
    end

endmodule
```
