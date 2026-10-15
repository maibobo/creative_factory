# nvme_mailbox_backend

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\nvme_mailbox_backend.sv`
- SHA-256: `e84b083bb9058d4f7818980a482303ab4750349dce97950f134be1560160f911`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\nvme_mailbox_backend.sv

```systemverilog
`timescale 1ns/1ps

// Control-plane mailbox between the PL scheduler and a MicroBlaze wrapper.
// Payload data is never copied through this block; DDR address and length are
// passed as descriptors. A board project can map the mb_* side to AXI-Lite,
// AXI BRAM, or a vendor-provided command FIFO without changing the scheduler.
module nvme_mailbox_backend #(
    // 描述符中的DDR物理地址宽度；本模块不解释或转换该地址。
    parameter integer AXI_ADDR_WIDTH = 64
) (
    input  wire                         clk,
    input  wire                         rst_n,

    // 调度器侧请求：valid/ready握手时完整描述符被锁存在mb_cmd_*寄存器。
    input  wire                         req_valid,
    output wire                         req_ready,
    input  wire [1:0]                   req_opcode,
    input  wire [AXI_ADDR_WIDTH-1:0]    req_ddr_addr,
    input  wire [31:0]                  req_byte_len,
    input  wire [63:0]                  req_slba,
    input  wire [15:0]                  req_user_tag,

    // 调度器侧完成：使用单表项保持寄存器承受调度器的短暂反压。
    output wire                         cpl_valid,
    input  wire                         cpl_ready,
    output wire [15:0]                  cpl_user_tag,
    output wire [15:0]                  cpl_status,

    // MicroBlaze侧命令邮箱。软件/包装器接受命令后拉高mb_cmd_ready；
    // Payload仍留在外部DDR，MicroBlaze只读取这些描述符字段。
    output reg                          mb_cmd_valid,
    input  wire                         mb_cmd_ready,
    output reg  [1:0]                   mb_cmd_opcode,
    output reg  [AXI_ADDR_WIDTH-1:0]    mb_cmd_ddr_addr,
    output reg  [31:0]                  mb_cmd_byte_len,
    output reg  [63:0]                  mb_cmd_slba,
    output reg  [15:0]                  mb_cmd_user_tag,

    // MicroBlaze侧完成邮箱。Tag原样返回，用于关联原项目级请求。
    input  wire                         mb_cpl_valid,
    output wire                         mb_cpl_ready,
    input  wire [15:0]                  mb_cpl_user_tag,
    input  wire [15:0]                  mb_cpl_status
);

    // 一个Completion的skid/holding寄存器；未被调度器消费前拒绝第二个完成。
    reg cpl_pending;
    reg [15:0] cpl_tag_reg;
    reg [15:0] cpl_status_reg;

    assign req_ready = !mb_cmd_valid;
    assign cpl_valid = cpl_pending;
    assign cpl_user_tag = cpl_tag_reg;
    assign cpl_status = cpl_status_reg;
    assign mb_cpl_ready = !cpl_pending;

    always @(posedge clk) begin
        if (!rst_n) begin
            mb_cmd_valid    <= 1'b0;
            mb_cmd_opcode   <= 2'd0;
            mb_cmd_ddr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            mb_cmd_byte_len <= 32'd0;
            mb_cmd_slba     <= 64'd0;
            mb_cmd_user_tag <= 16'd0;
            cpl_pending     <= 1'b0;
            cpl_tag_reg     <= 16'd0;
            cpl_status_reg  <= 16'd0;
        end else begin
            // 接收一条调度器请求并保持所有字段，直到MicroBlaze侧握手。
            if (req_valid && req_ready) begin
                mb_cmd_valid    <= 1'b1;
                mb_cmd_opcode   <= req_opcode;
                mb_cmd_ddr_addr <= req_ddr_addr;
                mb_cmd_byte_len <= req_byte_len;
                mb_cmd_slba     <= req_slba;
                mb_cmd_user_tag <= req_user_tag;
            end
            if (mb_cmd_valid && mb_cmd_ready)
                mb_cmd_valid <= 1'b0;

            // MicroBlaze完成与调度器完成可能不在同一拍，先锁存再独立握手。
            if (mb_cpl_valid && mb_cpl_ready) begin
                cpl_pending    <= 1'b1;
                cpl_tag_reg    <= mb_cpl_user_tag;
                cpl_status_reg <= mb_cpl_status;
            end
            if (cpl_valid && cpl_ready)
                cpl_pending <= 1'b0;
        end
    end

endmodule
```
