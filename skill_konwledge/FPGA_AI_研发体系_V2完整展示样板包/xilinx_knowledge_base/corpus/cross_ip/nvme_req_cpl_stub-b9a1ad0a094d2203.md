# nvme_req_cpl_stub

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\stubs\nvme_req_cpl_stub.sv`
- SHA-256: `b9a1ad0a094d2203d17caf8c66c9208823068d709234cb80ab4da8cd6435a876`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\stubs\nvme_req_cpl_stub.sv

```systemverilog
`timescale 1ns/1ps

// 抽象NVMe req/cpl行为桩。
//
// 本模块不读取DDR、不生成PCIe TLP，也不实现SQ/CQ、PRP或SSD介质行为；
// 它只在请求握手后等待固定周期并返回Tag/Status，用于验证项目级调度器。
// 三个故障注入口在请求握手时锁存，可分别覆盖错误完成、永久无完成和错Tag。
module nvme_req_cpl_stub #(
    // 请求描述符中的DDR地址宽度。
    parameter integer AXI_ADDR_WIDTH = 64,
    // 正常请求从握手到产生Completion之间的clk周期数。
    parameter integer COMPLETE_LATENCY = 32
) (
    input  wire                         clk,
    input  wire                         rst_n,

    // 抽象请求通道；Stub只允许一个请求在途。
    input  wire                         req_valid,
    output wire                         req_ready,
    input  wire [1:0]                   req_opcode,
    input  wire [AXI_ADDR_WIDTH-1:0]    req_ddr_addr,
    input  wire [31:0]                  req_byte_len,
    input  wire [63:0]                  req_slba,
    input  wire [15:0]                  req_user_tag,

    // 抽象完成通道；cpl_valid会保持到调度器通过cpl_ready接受。
    output reg                          cpl_valid,
    input  wire                         cpl_ready,
    output reg  [15:0]                  cpl_user_tag,
    output reg  [15:0]                  cpl_status,

    // “next”注入信号只作用于下一条成功握手的请求。
    input  wire                         inject_fail_next,
    input  wire                         inject_timeout_next,
    input  wire                         inject_bad_tag_next,

    // 诊断计数和最后请求快照，供测试平台核对操作顺序与字段。
    output reg  [31:0]                  request_count,
    output reg  [31:0]                  write_count,
    output reg  [31:0]                  read_count,
    output reg  [31:0]                  flush_count,
    output reg  [1:0]                   last_opcode,
    output reg  [AXI_ADDR_WIDTH-1:0]    last_ddr_addr,
    output reg  [31:0]                  last_byte_len,
    output reg  [63:0]                  last_slba,
    output reg  [15:0]                  last_user_tag
);

    reg busy;
    reg timeout_pending;
    reg fail_pending;
    reg bad_tag_pending;
    integer latency_count;

    // busy或尚未消费的Completion均会反压新请求。
    assign req_ready = !busy && !cpl_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            busy               <= 1'b0;
            timeout_pending    <= 1'b0;
            fail_pending       <= 1'b0;
            bad_tag_pending    <= 1'b0;
            latency_count      <= 0;
            cpl_valid          <= 1'b0;
            cpl_user_tag       <= 16'd0;
            cpl_status         <= 16'd0;
            request_count      <= 32'd0;
            write_count        <= 32'd0;
            read_count         <= 32'd0;
            flush_count        <= 32'd0;
            last_opcode        <= 2'd0;
            last_ddr_addr      <= {AXI_ADDR_WIDTH{1'b0}};
            last_byte_len      <= 32'd0;
            last_slba          <= 64'd0;
            last_user_tag      <= 16'd0;
        end else begin
            // Completion被接收后释放输出保持寄存器。
            if (cpl_valid && cpl_ready)
                cpl_valid <= 1'b0;

            if (req_valid && req_ready) begin
                // 原子锁存请求字段及本次故障模式；后续req输入变化不影响结果。
                busy            <= 1'b1;
                timeout_pending <= inject_timeout_next;
                fail_pending    <= inject_fail_next;
                bad_tag_pending <= inject_bad_tag_next;
                latency_count   <= COMPLETE_LATENCY;
                request_count   <= request_count + 1'b1;
                last_opcode     <= req_opcode;
                last_ddr_addr   <= req_ddr_addr;
                last_byte_len   <= req_byte_len;
                last_slba       <= req_slba;
                last_user_tag   <= req_user_tag;
                case (req_opcode)
                    2'd0: write_count <= write_count + 1'b1;
                    2'd1: read_count  <= read_count + 1'b1;
                    2'd2: flush_count <= flush_count + 1'b1;
                    default: begin end
                endcase
            end

            if (busy) begin
                if (timeout_pending) begin
                    // 超时注入故意永久保持busy且不产生Completion，
                    // 由DUT的COMMAND_TIMEOUT_CYCLES而不是Stub自行恢复。
                    busy <= 1'b1;
                end else if (latency_count == 0) begin
                    // bad_tag通过翻转最低位制造不匹配；fail使用非零状态0x0002。
                    busy         <= 1'b0;
                    cpl_valid    <= 1'b1;
                    cpl_user_tag <= bad_tag_pending ?
                                    (last_user_tag ^ 16'h0001) :
                                    last_user_tag;
                    cpl_status   <= fail_pending ? 16'h0002 : 16'd0;
                end else begin
                    latency_count <= latency_count - 1;
                end
            end
        end
    end

endmodule
```
