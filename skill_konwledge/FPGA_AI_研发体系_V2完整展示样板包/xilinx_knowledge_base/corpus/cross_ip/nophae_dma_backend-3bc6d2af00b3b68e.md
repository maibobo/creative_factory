# nophae_dma_backend

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\nophae_dma_backend.sv`
- SHA-256: `3bc6d2af00b3b68e8393db1660d1b11b76ed7e3af322e67459cf6af48da1c116`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\nophae_dma_backend.sv

```systemverilog
`timescale 1ns/1ps

// 把项目级req/cpl描述符转换为现有Vitis源码已经实际使用的NoPHAE
// s_axi_ctrl寄存器访问。该模块不重写NoPHAE内部协议逻辑，只复现：
//
//   test_seq():
//     poll 0x54 dma_ready
//     write 0x4c src, 0x50 dst, 0x48 LBA数量, 0x44方向/启动
//     poll 0xc8 dma_done
//
//   flush():
//     read 0xc0 cmd_ccnt
//     write0x08 debug_lock=2，写原生命令字段，write 0x8c cmd_wr=1
//     write0x08 debug_lock=0，poll 0xc0直到计数变化
//
// Vitis向dma_srcaddr/dma_dstaddr写的是相对NoPHAE DDR窗口的32 bit偏移，
// 而ADC Writer在SmartConnect上发出的是DDR AXI物理地址。本模块显式执行
// physical_addr - DDR_AXI_BASE_ADDR，禁止再把两种地址域混为一个字段。
//
// 前置条件：PCIe/NVMe已初始化且I/O队列已经建立。现有start_transfer()
// 在写FDMA START之前调用create_queues(2,8)，与该前置条件匹配。
module nophae_dma_backend #(
    parameter integer AXI_ADDR_WIDTH = 32,    // Scheduler提供的DDR地址位宽
    parameter integer CTRL_ADDR_WIDTH = 40,    // NoPHAE控制面AXI-Lite地址位宽
    parameter [CTRL_ADDR_WIDTH-1:0] CTRL_BASE_ADDR = 40'h00_1000_0000,    // NoPHAE控制基址
    parameter [63:0] DDR_AXI_BASE_ADDR = 64'h0000_0000_8000_0000,    // NoPHAE DDR窗口物理基址
    parameter [63:0] DDR_WINDOW_BYTES  = 64'h0000_0000_8000_0000,    // NoPHAE DMA可访问窗口大小
    parameter integer LBA_BYTES = 512,    // SSD逻辑块字节数
    parameter integer COMMAND_TIMEOUT_CYCLES = 125_000_000,    // 高层DMA/Flush总超时周期数
    parameter integer AXIL_TIMEOUT_CYCLES = 4096    // 单次AXI-Lite事务超时周期数
) (
    input  wire                         clk,    // Backend和AXI-Lite微引擎时钟
    input  wire                         rst_n,    // 低有效同步复位
    input  wire                         enable,    // FDMA任务活动期允许执行请求

    input  wire                         req_valid,    // Scheduler抽象请求有效
    output wire                         req_ready,    // Backend无流程和Completion占用
    input  wire [1:0]                   req_opcode,    // WRITE/READ/FLUSH抽象操作码
    input  wire [AXI_ADDR_WIDTH-1:0]    req_ddr_addr,    // DDR物理地址
    input  wire [31:0]                  req_byte_len,    // DMA字节数
    input  wire [63:0]                  req_slba,    // SSD起始LBA
    input  wire [15:0]                  req_user_tag,    // 项目应用层Tag

    output wire                         cpl_valid,    // Backend Completion有效
    input  wire                         cpl_ready,    // Scheduler接受Completion
    output wire [15:0]                  cpl_user_tag,    // 原样回送的请求Tag
    output wire [15:0]                  cpl_status,    // 0=成功，非0=Backend本地错误

    // AXI4-Lite Master，接NoPHAE实例的32 bit s_axi_ctrl。
    output wire [CTRL_ADDR_WIDTH-1:0]   m_axi_awaddr,    // NoPHAE寄存器写地址
    output wire [2:0]                   m_axi_awprot,    // 固定普通非安全数据访问
    output wire                         m_axi_awvalid,    // AXI-Lite写地址有效
    input  wire                         m_axi_awready,    // NoPHAE接受写地址
    output wire [31:0]                  m_axi_wdata,    // NoPHAE寄存器写数据
    output wire [3:0]                   m_axi_wstrb,    // 固定全字节写使能
    output wire                         m_axi_wvalid,    // AXI-Lite写数据有效
    input  wire                         m_axi_wready,    // NoPHAE接受写数据
    input  wire [1:0]                   m_axi_bresp,    // AXI-Lite写响应
    input  wire                         m_axi_bvalid,    // AXI-Lite写响应有效
    output wire                         m_axi_bready,    // 微引擎等待写响应
    output wire [CTRL_ADDR_WIDTH-1:0]   m_axi_araddr,    // NoPHAE寄存器读地址
    output wire [2:0]                   m_axi_arprot,    // 固定普通非安全数据访问
    output wire                         m_axi_arvalid,    // AXI-Lite读地址有效
    input  wire                         m_axi_arready,    // NoPHAE接受读地址
    input  wire [31:0]                  m_axi_rdata,    // NoPHAE寄存器读数据
    input  wire [1:0]                   m_axi_rresp,    // AXI-Lite读响应
    input  wire                         m_axi_rvalid,    // AXI-Lite读数据有效
    output wire                         m_axi_rready,    // 微引擎等待读数据

    output wire                         busy,    // 高层流程、微事务或待取Completion占用
    output reg                          error_sticky,    // 任一请求错误粘滞位，复位前保持
    output reg                          timeout_sticky,    // 高层或AXI-Lite超时粘滞位
    output reg  [15:0]                  last_status,    // 最近请求完成状态
    output reg  [31:0]                  completed_command_count    // 成功完成的高层请求数
);

    localparam [1:0] NVME_OP_WRITE = 2'd0;    // DDR到SSD的数据写
    localparam [1:0] NVME_OP_READ  = 2'd1;    // SSD到DDR的数据读
    localparam [1:0] NVME_OP_FLUSH = 2'd2;    // NVMe Flush命令

    // Backend本地状态码；0表示NoPHAE寄存器序列正常完成。
    localparam [15:0] STS_BAD_OPCODE     = 16'hE001;    // 不支持的抽象操作码
    localparam [15:0] STS_BAD_LENGTH     = 16'hE002;    // 长度为0或非LBA整数倍
    localparam [15:0] STS_BAD_DDR_RANGE  = 16'hE003;    // DDR地址不在NoPHAE窗口
    localparam [15:0] STS_BAD_LBA_RANGE  = 16'hE004;    // 当前32 bit NoPHAE LBA字段溢出
    localparam [15:0] STS_AXIL_RESPONSE  = 16'hE005;    // NoPHAE AXI-Lite返回非OKAY
    localparam [15:0] STS_AXIL_TIMEOUT   = 16'hE006;    // 单次AXI-Lite事务超时
    localparam [15:0] STS_CMD_TIMEOUT    = 16'hE007;    // 整个高层请求超时
    localparam [15:0] STS_DISABLED       = 16'hE008;    // 请求执行期间enable撤销

    // Vitis type_define.h中的NoPHAE寄存器偏移。
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DEBUG_LOCK =
        CTRL_BASE_ADDR + 40'h008;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DMA_TYPE =    // DMA方向/启动寄存器
        CTRL_BASE_ADDR + 40'h044;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DMA_LEN =    // DMA传输LBA数量寄存器
        CTRL_BASE_ADDR + 40'h048;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DMA_SRC =    // DMA源Offset或SLBA寄存器
        CTRL_BASE_ADDR + 40'h04C;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DMA_DST =    // DMA目的SLBA或Offset寄存器
        CTRL_BASE_ADDR + 40'h050;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DMA_READY =    // 高层DMA可启动状态寄存器
        CTRL_BASE_ADDR + 40'h054;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_CODE =    // 原生NVMe命令码寄存器
        CTRL_BASE_ADDR + 40'h060;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_PRP1_L =    // 原生命令PRP1低32位
        CTRL_BASE_ADDR + 40'h06C;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_PRP2_L =    // 原生命令PRP2低32位
        CTRL_BASE_ADDR + 40'h074;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_DW10 =    // 原生命令DW10
        CTRL_BASE_ADDR + 40'h078;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_DW11 =    // 原生命令DW11
        CTRL_BASE_ADDR + 40'h07C;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_DW12 =    // 原生命令DW12
        CTRL_BASE_ADDR + 40'h080;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_DW13 =    // 原生命令DW13
        CTRL_BASE_ADDR + 40'h084;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_WR =    // 原生命令提交触发寄存器
        CTRL_BASE_ADDR + 40'h08C;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_CMD_CCNT =    // 原生命令完成计数寄存器
        CTRL_BASE_ADDR + 40'h0C0;
    localparam [CTRL_ADDR_WIDTH-1:0] REG_DMA_DONE =    // 高层DMA完成状态寄存器
        CTRL_BASE_ADDR + 40'h0C8;

    localparam [1:0] FLOW_NONE  = 2'd0;    // 无高层请求
    localparam [1:0] FLOW_DATA  = 2'd1;    // 执行Vitis test_seq式DMA寄存器序列
    localparam [1:0] FLOW_FLUSH = 2'd2;    // 执行Vitis flush式原生命令序列
    localparam [1:0] SEQ_IDLE   = 2'd0;    // 无AXI-Lite微事务
    localparam [1:0] SEQ_ISSUE  = 2'd1;    // 向微引擎发出当前seq_step事务
    localparam [1:0] SEQ_WAIT   = 2'd2;    // 等待微引擎响应并判定推进/重试

    reg [1:0] flow;    // 当前高层流程类型
    reg [1:0] seq_state;    // 高层序列器微事务状态
    reg [4:0] seq_step;    // 当前NoPHAE寄存器访问步骤编号
    reg [31:0] command_age;    // 当前高层请求持续周期计数
    reg [15:0] active_tag;    // 当前唯一在途请求的项目Tag
    reg active_is_write;    // 当前DATA流程方向：1=DDR到SSD
    reg [31:0] active_ddr_offset;    // 物理DDR地址减窗口基址后的32 bit偏移
    reg [31:0] active_lba;    // NoPHAE寄存器可表示的32 bit SLBA
    reg [31:0] active_lba_count;    // DMA字节数换算后的LBA数量
    reg [31:0] flush_count_before;    // Flush提交前的NoPHAE命令完成计数

    reg cpl_pending;    // 有一个Completion等待Scheduler取走
    reg [15:0] cpl_tag_reg;    // 待取Completion Tag
    reg [15:0] cpl_status_reg;    // 待取Completion状态

    wire [63:0] req_ddr_addr_64 = req_ddr_addr;    // 请求DDR地址统一零扩展到64 bit
    wire [63:0] req_ddr_end_64 =    // 请求DDR末地址，用于窗口与溢出检查
        req_ddr_addr_64 + {32'd0, req_byte_len};
    wire [63:0] ddr_window_end_64 =    // NoPHAE DMA窗口末地址
        DDR_AXI_BASE_ADDR + DDR_WINDOW_BYTES;
    wire [63:0] req_ddr_offset_64 =    // NoPHAE寄存器要求的相对DDR窗口偏移
        req_ddr_addr_64 - DDR_AXI_BASE_ADDR;

    assign req_ready = enable && (flow == FLOW_NONE) &&
                       (seq_state == SEQ_IDLE) && !cpl_pending;
    assign cpl_valid = cpl_pending;
    assign cpl_user_tag = cpl_tag_reg;
    assign cpl_status = cpl_status_reg;
    assign busy = (flow != FLOW_NONE) || (seq_state != SEQ_IDLE) ||
                  cpl_pending;

    // 一个通用、单事务在途的AXI4-Lite Master微引擎。
    wire bus_cmd_valid = (seq_state == SEQ_ISSUE);    // 当前seq_step微事务有效
    reg bus_cmd_write;    // 当前微事务方向：1=写，0=读
    reg [CTRL_ADDR_WIDTH-1:0] bus_cmd_addr;    // 当前微事务NoPHAE寄存器地址
    reg [31:0] bus_cmd_wdata;    // 当前微事务写数据
    wire bus_cmd_ready;    // AXI-Lite微引擎空闲
    wire bus_rsp_valid;    // AXI-Lite微引擎已有响应
    wire bus_rsp_ready = (seq_state == SEQ_WAIT);    // 序列器正在等待响应
    wire bus_rsp_error;    // 微事务非OKAY或超时
    wire bus_rsp_timeout;    // 微事务因AXIL_TIMEOUT_CYCLES超时
    wire [31:0] bus_rsp_rdata;    // 微事务读数据
    wire abort_bus =    // 高层命令超时或执行期间Backend被禁用
        ((flow != FLOW_NONE) &&
         (command_age == COMMAND_TIMEOUT_CYCLES-1)) ||
        ((flow != FLOW_NONE) && !enable);

    // seq_step到AXI-Lite事务的唯一译码。轮询步骤在读值未满足时原步重试。
    always @* begin
        bus_cmd_write = 1'b0;
        bus_cmd_addr  = REG_DMA_READY;
        bus_cmd_wdata = 32'd0;
        if (flow == FLOW_DATA) begin
            case (seq_step)
                5'd0: begin
                    bus_cmd_write = 1'b0;
                    bus_cmd_addr  = REG_DMA_READY;
                end
                5'd1: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_DMA_SRC;
                    bus_cmd_wdata = active_is_write ?
                                    active_ddr_offset : active_lba;
                end
                5'd2: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_DMA_DST;
                    bus_cmd_wdata = active_is_write ?
                                    active_lba : active_ddr_offset;
                end
                5'd3: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_DMA_LEN;
                    bus_cmd_wdata = active_lba_count;
                end
                5'd4: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_DMA_TYPE;
                    bus_cmd_wdata = active_is_write ? 32'd1 : 32'd0;
                end
                default: begin
                    bus_cmd_write = 1'b0;
                    bus_cmd_addr  = REG_DMA_DONE;
                end
            endcase
        end else if (flow == FLOW_FLUSH) begin
            case (seq_step)
                5'd0: begin
                    bus_cmd_write = 1'b0;
                    bus_cmd_addr  = REG_CMD_CCNT;
                end
                5'd1: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_DEBUG_LOCK;
                    bus_cmd_wdata = 32'd2;
                end
                5'd2: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_CODE;
                    // cmd(0x10000, nid=1, ...) => (1<<24)+0x10000。
                    bus_cmd_wdata = 32'h0101_0000;
                end
                5'd3: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_PRP1_L;
                end
                5'd4: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_PRP2_L;
                end
                5'd5: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_DW10;
                end
                5'd6: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_DW11;
                end
                5'd7: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_DW12;
                end
                5'd8: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_DW13;
                end
                5'd9: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_CMD_WR;
                    bus_cmd_wdata = 32'd1;
                end
                5'd10: begin
                    bus_cmd_write = 1'b1;
                    bus_cmd_addr  = REG_DEBUG_LOCK;
                    bus_cmd_wdata = 32'd0;
                end
                default: begin
                    bus_cmd_write = 1'b0;
                    bus_cmd_addr  = REG_CMD_CCNT;
                end
            endcase
        end
    end

    // 高层序列器：一次只保存一个项目Tag，与NoPHAE“一条高层DMA在途”
    // 的软件用法一致；NoPHAE没有Tag字段，完成时由本模块回送保存的Tag。
    always @(posedge clk) begin
        if (!rst_n) begin
            flow                    <= FLOW_NONE;
            seq_state               <= SEQ_IDLE;
            seq_step                <= 5'd0;
            command_age             <= 32'd0;
            active_tag              <= 16'd0;
            active_is_write         <= 1'b0;
            active_ddr_offset       <= 32'd0;
            active_lba              <= 32'd0;
            active_lba_count        <= 32'd0;
            flush_count_before      <= 32'd0;
            cpl_pending             <= 1'b0;
            cpl_tag_reg             <= 16'd0;
            cpl_status_reg          <= 16'd0;
            error_sticky            <= 1'b0;
            timeout_sticky          <= 1'b0;
            last_status             <= 16'd0;
            completed_command_count <= 32'd0;
        end else begin
            if (cpl_pending && cpl_ready)
                cpl_pending <= 1'b0;

            if ((flow != FLOW_NONE) && !enable) begin
                flow           <= FLOW_NONE;
                seq_state      <= SEQ_IDLE;
                command_age    <= 32'd0;
                cpl_pending    <= 1'b1;
                cpl_tag_reg    <= active_tag;
                cpl_status_reg <= STS_DISABLED;
                last_status    <= STS_DISABLED;
                error_sticky   <= 1'b1;
            end else if ((flow != FLOW_NONE) &&
                         (command_age == COMMAND_TIMEOUT_CYCLES-1)) begin
                flow           <= FLOW_NONE;
                seq_state      <= SEQ_IDLE;
                command_age    <= 32'd0;
                cpl_pending    <= 1'b1;
                cpl_tag_reg    <= active_tag;
                cpl_status_reg <= STS_CMD_TIMEOUT;
                last_status    <= STS_CMD_TIMEOUT;
                error_sticky   <= 1'b1;
                timeout_sticky <= 1'b1;
            end else begin
                if (flow != FLOW_NONE)
                    command_age <= command_age + 1'b1;
                else
                    command_age <= 32'd0;

                if (req_valid && req_ready) begin
                    active_tag <= req_user_tag;
                    if ((req_opcode != NVME_OP_WRITE) &&
                        (req_opcode != NVME_OP_READ) &&
                        (req_opcode != NVME_OP_FLUSH)) begin
                        cpl_pending    <= 1'b1;
                        cpl_tag_reg    <= req_user_tag;
                        cpl_status_reg <= STS_BAD_OPCODE;
                        last_status    <= STS_BAD_OPCODE;
                        error_sticky   <= 1'b1;
                    end else if ((req_opcode != NVME_OP_FLUSH) &&
                                 ((req_byte_len == 0) ||
                                  ((req_byte_len % LBA_BYTES) != 0))) begin
                        cpl_pending    <= 1'b1;
                        cpl_tag_reg    <= req_user_tag;
                        cpl_status_reg <= STS_BAD_LENGTH;
                        last_status    <= STS_BAD_LENGTH;
                        error_sticky   <= 1'b1;
                    end else if ((req_opcode != NVME_OP_FLUSH) &&
                                 ((req_ddr_addr_64 < DDR_AXI_BASE_ADDR) ||
                                  (req_ddr_end_64 < req_ddr_addr_64) ||
                                  (req_ddr_end_64 > ddr_window_end_64) ||
                                  (req_ddr_offset_64[63:32] != 0))) begin
                        cpl_pending    <= 1'b1;
                        cpl_tag_reg    <= req_user_tag;
                        cpl_status_reg <= STS_BAD_DDR_RANGE;
                        last_status    <= STS_BAD_DDR_RANGE;
                        error_sticky   <= 1'b1;
                    end else if ((req_opcode != NVME_OP_FLUSH) &&
                                 (req_slba[63:32] != 0)) begin
                        cpl_pending    <= 1'b1;
                        cpl_tag_reg    <= req_user_tag;
                        cpl_status_reg <= STS_BAD_LBA_RANGE;
                        last_status    <= STS_BAD_LBA_RANGE;
                        error_sticky   <= 1'b1;
                    end else begin
                        active_is_write   <= (req_opcode == NVME_OP_WRITE);
                        active_ddr_offset <= req_ddr_offset_64[31:0];
                        active_lba        <= req_slba[31:0];
                        active_lba_count  <= req_byte_len / LBA_BYTES;
                        flow              <= (req_opcode == NVME_OP_FLUSH) ?
                                             FLOW_FLUSH : FLOW_DATA;
                        seq_step          <= 5'd0;
                        seq_state         <= SEQ_ISSUE;
                        command_age       <= 32'd0;
                    end
                end else if ((seq_state == SEQ_ISSUE) &&
                             bus_cmd_valid && bus_cmd_ready) begin
                    seq_state <= SEQ_WAIT;
                end else if ((seq_state == SEQ_WAIT) && bus_rsp_valid) begin
                    if (bus_rsp_error) begin
                        flow           <= FLOW_NONE;
                        seq_state      <= SEQ_IDLE;
                        cpl_pending    <= 1'b1;
                        cpl_tag_reg    <= active_tag;
                        cpl_status_reg <= bus_rsp_timeout ?
                                          STS_AXIL_TIMEOUT :
                                          STS_AXIL_RESPONSE;
                        last_status    <= bus_rsp_timeout ?
                                          STS_AXIL_TIMEOUT :
                                          STS_AXIL_RESPONSE;
                        error_sticky   <= 1'b1;
                        if (bus_rsp_timeout)
                            timeout_sticky <= 1'b1;
                    end else if (flow == FLOW_DATA) begin
                        if ((seq_step == 0) &&
                            (bus_rsp_rdata != 32'd1)) begin
                            seq_state <= SEQ_ISSUE;
                        end else if ((seq_step >= 5) &&
                                     (bus_rsp_rdata != 32'd1)) begin
                            seq_step  <= 5'd5;
                            seq_state <= SEQ_ISSUE;
                        end else if (seq_step >= 5) begin
                            flow                    <= FLOW_NONE;
                            seq_state               <= SEQ_IDLE;
                            cpl_pending             <= 1'b1;
                            cpl_tag_reg             <= active_tag;
                            cpl_status_reg          <= 16'd0;
                            last_status             <= 16'd0;
                            completed_command_count <=
                                completed_command_count + 1'b1;
                        end else begin
                            seq_step  <= seq_step + 1'b1;
                            seq_state <= SEQ_ISSUE;
                        end
                    end else if (flow == FLOW_FLUSH) begin
                        if (seq_step == 0) begin
                            flush_count_before <= bus_rsp_rdata;
                            seq_step           <= 5'd1;
                            seq_state          <= SEQ_ISSUE;
                        end else if ((seq_step >= 11) &&
                                     (bus_rsp_rdata ==
                                      flush_count_before)) begin
                            seq_step  <= 5'd11;
                            seq_state <= SEQ_ISSUE;
                        end else if (seq_step >= 11) begin
                            flow                    <= FLOW_NONE;
                            seq_state               <= SEQ_IDLE;
                            cpl_pending             <= 1'b1;
                            cpl_tag_reg             <= active_tag;
                            cpl_status_reg          <= 16'd0;
                            last_status             <= 16'd0;
                            completed_command_count <=
                                completed_command_count + 1'b1;
                        end else begin
                            seq_step  <= seq_step + 1'b1;
                            seq_state <= SEQ_ISSUE;
                        end
                    end
                end
            end
        end
    end

    initial begin
        if ((AXI_ADDR_WIDTH < 32) || (AXI_ADDR_WIDTH > 64))
            $error("AXI_ADDR_WIDTH must be in the range 32..64");
        if ((LBA_BYTES != 512) && (LBA_BYTES != 4096))
            $error("LBA_BYTES must be 512 or 4096");
        if ((COMMAND_TIMEOUT_CYCLES < 16) ||
            (COMMAND_TIMEOUT_CYCLES > 32'hFFFF_FFFF))
            $error("Invalid COMMAND_TIMEOUT_CYCLES");
        if ((AXIL_TIMEOUT_CYCLES < 4) ||
            (AXIL_TIMEOUT_CYCLES > 32'hFFFF_FFFF))
            $error("Invalid AXIL_TIMEOUT_CYCLES");
        if ((DDR_WINDOW_BYTES == 0) ||
            ((DDR_AXI_BASE_ADDR + DDR_WINDOW_BYTES) <
             DDR_AXI_BASE_ADDR))
            $error("Invalid DDR window");
    end

    // ---------------------------------------------------------------------
    // AXI4-Lite单事务微引擎
    // ---------------------------------------------------------------------
    reg bus_busy_reg;    // 一个AXI-Lite读或写事务正在执行
    reg bus_write_reg;    // 当前微事务方向快照
    reg [CTRL_ADDR_WIDTH-1:0] bus_addr_reg;    // 当前微事务地址快照
    reg [31:0] bus_wdata_reg;    // 当前微事务写数据快照
    reg awvalid_reg;    // 写地址尚未握手
    reg wvalid_reg;    // 写数据尚未握手
    reg arvalid_reg;    // 读地址尚未握手
    reg [31:0] bus_age;    // 当前AXI-Lite微事务等待周期数
    reg bus_rsp_valid_reg;    // 微引擎响应等待序列器取走
    reg bus_rsp_error_reg;    // 微引擎响应错误
    reg bus_rsp_timeout_reg;    // 微引擎响应由超时产生
    reg [31:0] bus_rsp_rdata_reg;    // 微引擎读数据响应

    assign bus_cmd_ready = !bus_busy_reg && !bus_rsp_valid_reg;
    assign bus_rsp_valid = bus_rsp_valid_reg;
    assign bus_rsp_error = bus_rsp_error_reg;
    assign bus_rsp_timeout = bus_rsp_timeout_reg;
    assign bus_rsp_rdata = bus_rsp_rdata_reg;

    assign m_axi_awaddr  = bus_addr_reg;
    assign m_axi_awprot  = 3'b000;
    assign m_axi_awvalid = awvalid_reg;
    assign m_axi_wdata   = bus_wdata_reg;
    assign m_axi_wstrb   = 4'hF;
    assign m_axi_wvalid  = wvalid_reg;
    assign m_axi_bready  = bus_busy_reg && bus_write_reg;
    assign m_axi_araddr  = bus_addr_reg;
    assign m_axi_arprot  = 3'b000;
    assign m_axi_arvalid = arvalid_reg;
    assign m_axi_rready  = bus_busy_reg && !bus_write_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            bus_busy_reg        <= 1'b0;
            bus_write_reg       <= 1'b0;
            bus_addr_reg        <= {CTRL_ADDR_WIDTH{1'b0}};
            bus_wdata_reg       <= 32'd0;
            awvalid_reg         <= 1'b0;
            wvalid_reg          <= 1'b0;
            arvalid_reg         <= 1'b0;
            bus_age             <= 32'd0;
            bus_rsp_valid_reg   <= 1'b0;
            bus_rsp_error_reg   <= 1'b0;
            bus_rsp_timeout_reg <= 1'b0;
            bus_rsp_rdata_reg   <= 32'd0;
        end else if (abort_bus) begin
            bus_busy_reg        <= 1'b0;
            awvalid_reg         <= 1'b0;
            wvalid_reg          <= 1'b0;
            arvalid_reg         <= 1'b0;
            bus_age             <= 32'd0;
            bus_rsp_valid_reg   <= 1'b0;
            bus_rsp_error_reg   <= 1'b0;
            bus_rsp_timeout_reg <= 1'b0;
        end else begin
            if (bus_rsp_valid_reg && bus_rsp_ready)
                bus_rsp_valid_reg <= 1'b0;

            if (bus_cmd_valid && bus_cmd_ready) begin
                bus_busy_reg        <= 1'b1;
                bus_write_reg       <= bus_cmd_write;
                bus_addr_reg        <= bus_cmd_addr;
                bus_wdata_reg       <= bus_cmd_wdata;
                awvalid_reg         <= bus_cmd_write;
                wvalid_reg          <= bus_cmd_write;
                arvalid_reg         <= !bus_cmd_write;
                bus_age             <= 32'd0;
                bus_rsp_error_reg   <= 1'b0;
                bus_rsp_timeout_reg <= 1'b0;
                bus_rsp_rdata_reg   <= 32'd0;
            end else if (bus_busy_reg) begin
                if (awvalid_reg && m_axi_awready)
                    awvalid_reg <= 1'b0;
                if (wvalid_reg && m_axi_wready)
                    wvalid_reg <= 1'b0;
                if (arvalid_reg && m_axi_arready)
                    arvalid_reg <= 1'b0;

                if (bus_write_reg && m_axi_bvalid && m_axi_bready) begin
                    bus_busy_reg        <= 1'b0;
                    awvalid_reg         <= 1'b0;
                    wvalid_reg          <= 1'b0;
                    bus_rsp_valid_reg   <= 1'b1;
                    bus_rsp_error_reg   <= (m_axi_bresp != 2'b00);
                    bus_rsp_timeout_reg <= 1'b0;
                    bus_age             <= 32'd0;
                end else if (!bus_write_reg &&
                             m_axi_rvalid && m_axi_rready) begin
                    bus_busy_reg        <= 1'b0;
                    arvalid_reg         <= 1'b0;
                    bus_rsp_valid_reg   <= 1'b1;
                    bus_rsp_error_reg   <= (m_axi_rresp != 2'b00);
                    bus_rsp_timeout_reg <= 1'b0;
                    bus_rsp_rdata_reg   <= m_axi_rdata;
                    bus_age             <= 32'd0;
                end else if (bus_age == AXIL_TIMEOUT_CYCLES-1) begin
                    bus_busy_reg        <= 1'b0;
                    awvalid_reg         <= 1'b0;
                    wvalid_reg          <= 1'b0;
                    arvalid_reg         <= 1'b0;
                    bus_rsp_valid_reg   <= 1'b1;
                    bus_rsp_error_reg   <= 1'b1;
                    bus_rsp_timeout_reg <= 1'b1;
                    bus_age             <= 32'd0;
                end else begin
                    bus_age <= bus_age + 1'b1;
                end
            end
        end
    end

endmodule
```
