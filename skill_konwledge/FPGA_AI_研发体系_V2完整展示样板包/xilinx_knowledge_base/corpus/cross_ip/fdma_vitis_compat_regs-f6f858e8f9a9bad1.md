# fdma_vitis_compat_regs

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\fdma_vitis_compat_regs.sv`
- SHA-256: `f6f858e8f9a9bad13e515f783bc88d77d04c63f63c404125899c18c6a55d0b7b`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\fdma_vitis_compat_regs.sv

```systemverilog
`timescale 1ns/1ps

// 现有Vitis程序已经固定访问0x9000_0000~0x9000_003c。本模块实现同一
// AXI4-Lite寄存器ABI，并在0x40以后增加不影响旧ELF的诊断寄存器。
//
// 旧软件的start_transfer()会先create_queues(2,8)，再写SIZE_L/H和START，
// 随后轮询WDATA_DONE、NVME_SEND_DONE。因此START只产生一次任务脉冲，
// 两个DONE均为Sticky，下一次合法START清除；错误也形成“终态DONE”，避免
// 无超时的旧软件永久卡死，真实成败由扩展STATUS/LAST_ERROR区分。
module fdma_vitis_compat_regs #(
    parameter integer AXIL_ADDR_WIDTH = 40,    // AXI-Lite控制地址位宽
    parameter [AXIL_ADDR_WIDTH-1:0] AXIL_BASE_ADDR =    // 兼容旧Vitis软件的FDMA寄存器基址
        40'h00_9000_0000,    // 兼容旧Vitis软件的FDMA寄存器基址
    parameter integer FDMA_DATA_WIDTH = 256,    // 软件读取的数据通路位宽
    // 默认保护前1 MiB LBA（512 MiB）；可在明确允许破坏LBA0的测试工程覆盖为0。
    parameter [31:0] MIN_START_SLBA = 32'd1_048_576    // SLBA写保护下界
) (
    input  wire                         clk,    // AXI-Lite及Capture控制系统时钟
    input  wire                         rst_n,    // 低有效同步复位

    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axi_awaddr,    // MicroBlaze写地址
    input  wire [2:0]                  s_axi_awprot,    // 写保护属性，当前仅作未使用汇总
    input  wire                        s_axi_awvalid,    // 写地址有效
    output wire                        s_axi_awready,    // 可缓存写地址
    input  wire [31:0]                 s_axi_wdata,    // 写数据
    input  wire [3:0]                  s_axi_wstrb,    // 写字节使能
    input  wire                        s_axi_wvalid,    // 写数据有效
    output wire                        s_axi_wready,    // 可缓存写数据
    output reg  [1:0]                  s_axi_bresp,    // 写响应，当前合法访问返回OKAY
    output reg                         s_axi_bvalid,    // 写响应有效
    input  wire                        s_axi_bready,    // MicroBlaze接受写响应
    input  wire [AXIL_ADDR_WIDTH-1:0]  s_axi_araddr,    // MicroBlaze读地址
    input  wire [2:0]                  s_axi_arprot,    // 读保护属性，当前仅作未使用汇总
    input  wire                        s_axi_arvalid,    // 读地址有效
    output wire                        s_axi_arready,    // 可接受读地址
    output reg  [31:0]                 s_axi_rdata,    // 寄存器读数据
    output reg  [1:0]                  s_axi_rresp,    // 读响应，当前返回OKAY
    output reg                         s_axi_rvalid,    // 读数据有效
    input  wire                        s_axi_rready,    // MicroBlaze接受读数据

    input  wire                        local_capture_done_pulse,    // ADC侧停止并排空完成
    input  wire                        capture_cancelled_pulse,    // 未启采即取消
    input  wire                        nvme_capture_done_pulse,    // 第二次Flush完成
    input  wire                        pipeline_fatal_error,    // 全链路不可恢复错误
    input  wire                        adc_fifo_full,    // ADC CDC FIFO满诊断
    input  wire                        adc_fifo_prog_full,    // ADC CDC FIFO预满诊断
    input  wire [63:0]                 accepted_sample_times,    // Packer已接受的数据时刻数
    input  wire [63:0]                 dropped_sample_times,    // Packer已丢弃的数据时刻数
    input  wire [15:0]                 backend_last_status,    // NoPHAE Backend最近状态

    output reg                         transfer_start_pulse,    // 合法START写形成的单拍
    output reg                         transfer_stop_pulse,    // 活动期写START=0形成的单拍
    output reg                         transfer_active,    // 从合法START到最终完成/错误的任务活动位
    output wire                        backend_enable,    // 任务活动期允许NoPHAE Backend运行
    output reg  [63:0]                 transfer_size_bytes,    // START时锁存的目标字节数
    output reg  [63:0]                 transfer_capture_id,    // START时分配的Capture编号
    output reg                         cfg_two_channel,    // 软件配置的单双通道模式
    output reg                         cfg_single_channel_select,    // 软件配置的单通道选择
    output wire [63:0]                 session_base_slba,    // SLBA使能后零扩展的Raw起始LBA
    output reg  [15:0]                 last_error    // 最近一次任务或启动校验错误
);

    localparam [7:0] OFS_START        = 8'h00;    // 启停命令/活动状态
    localparam [7:0] OFS_BURST_LEN    = 8'h04;    // 旧软件兼容的Burst配置镜像
    localparam [7:0] OFS_WTRANS_TIME  = 8'h08;    // START到ADC本地完成周期数
    localparam [7:0] OFS_RTRANS_TIME  = 8'h0C;    // ADC本地完成到NVMe最终完成周期数
    localparam [7:0] OFS_PATTERN      = 8'h10;    // 旧软件兼容的测试Pattern镜像
    localparam [7:0] OFS_MEM_SIZE     = 8'h14;    // 旧软件兼容的内存大小镜像
    localparam [7:0] OFS_DATA_WIDTH   = 8'h18;    // 只读FDMA数据位宽
    localparam [7:0] OFS_SIZE_L       = 8'h1C;    // 目标字节数低32位
    localparam [7:0] OFS_SIZE_H       = 8'h20;    // 目标字节数高32位
    localparam [7:0] OFS_WDATA_DONE   = 8'h24;    // ADC本地阶段完成粘滞位
    localparam [7:0] OFS_TIME_L       = 8'h28;    // 总活动周期低32位
    localparam [7:0] OFS_TIME_H       = 8'h2C;    // 总活动周期高32位
    localparam [7:0] OFS_START_LBA    = 8'h30;    // 软件配置的Raw起始LBA
    localparam [7:0] OFS_FIFO_FULL    = 8'h34;    // FIFO满/预满状态
    localparam [7:0] OFS_NVME_DONE    = 8'h38;    // SSD持久化完成粘滞位
    localparam [7:0] OFS_SLBA_ENABLE  = 8'h3C;    // 是否采用START_LBA

    // 向后兼容扩展：旧ELF不会访问，调试器或后续软件可直接读取。
    localparam [7:0] OFS_CAPTURE_CFG  = 8'h40;    // 单双通道与单通道选择
    localparam [7:0] OFS_CAPTURE_ID_L = 8'h44;    // Capture编号计数器低32位
    localparam [7:0] OFS_CAPTURE_ID_H = 8'h48;    // Capture编号计数器高32位
    localparam [7:0] OFS_STATUS       = 8'h4C;    // 任务、完成、FIFO与错误汇总
    localparam [7:0] OFS_ACCEPTED_L   = 8'h50;    // 已接受数据时刻数低32位
    localparam [7:0] OFS_ACCEPTED_H   = 8'h54;    // 已接受数据时刻数高32位
    localparam [7:0] OFS_DROPPED_L    = 8'h58;    // 已丢弃数据时刻数低32位
    localparam [7:0] OFS_DROPPED_H    = 8'h5C;    // 已丢弃数据时刻数高32位
    localparam [7:0] OFS_LAST_ERROR   = 8'h60;    // FDMA任务最近错误码
    localparam [7:0] OFS_BACKEND_STS  = 8'h64;    // Backend最近状态码

    localparam [15:0] ERR_START_WHILE_ACTIVE = 16'hD001;    // 活动任务期间重复START
    localparam [15:0] ERR_ZERO_SIZE          = 16'hD002;    // 目标字节数为0
    localparam [15:0] ERR_SIZE_ALIGNMENT     = 16'hD003;    // 目标字节数不满足样本粒度
    localparam [15:0] ERR_PROTECTED_LBA      = 16'hD004;    // 起始LBA落入保护区
    localparam [15:0] ERR_PIPELINE_NOT_CLEAN = 16'hD005;    // 启动前已有Pipeline fatal
    localparam [15:0] ERR_CANCELLED_BY_SOFTWARE = 16'hD006;    // 软件在实际启采前取消
    localparam [15:0] ERR_PIPELINE_FATAL     = 16'hD100;    // 活动任务期间Pipeline fatal

    reg [31:0] burst_len_reg;    // 旧ABI可读写镜像，当前不控制Writer Burst
    reg [31:0] pattern_start_reg;    // 旧ABI测试Pattern镜像，当前数据源为ADC
    reg [31:0] mem_size_reg;    // 旧ABI内存大小镜像，当前不参与地址判定
    reg [31:0] size_low_reg;    // 软件目标字节数低32位
    reg [31:0] size_high_reg;    // 软件目标字节数高32位
    reg [31:0] start_lba_reg;    // 软件Raw起始LBA
    reg slba_enable_reg;    // START_LBA是否生效
    reg [63:0] capture_id_counter;    // 自动递增Capture编号种子
    reg wdata_done_reg;    // ADC本地阶段完成粘滞位，新任务清除
    reg nvme_done_reg;    // SSD持久化完成粘滞位，新任务清除
    reg local_phase_done;    // 本任务已观察到ADC本地完成
    reg [31:0] wtrans_time_reg;    // START到本地完成周期数低32位
    reg [31:0] rtrans_time_reg;    // 本地完成到最终完成周期差
    reg [63:0] time_count_reg;    // 任务完成/错误时锁存的活动周期数
    reg [63:0] active_cycle_count;    // 当前任务活动周期计数器
    reg [63:0] local_done_cycle;    // 本地完成时的活动周期快照

    assign backend_enable = transfer_active;
    assign session_base_slba =
        slba_enable_reg ? {32'd0, start_lba_reg} : 64'd0;

    function automatic [31:0] merge_wstrb;
        input [31:0] previous;    // 写入前的完整寄存器值
        input [31:0] update;    // AXI-Lite本次写数据
        input [3:0] strobe;    // 每个字节是否允许更新
        integer byte_index;    // 四个字节的组合循环索引
        begin
            merge_wstrb = previous;
            for (byte_index = 0; byte_index < 4;
                 byte_index = byte_index + 1)
                if (strobe[byte_index])
                    merge_wstrb[byte_index*8 +: 8] =
                        update[byte_index*8 +: 8];
        end
    endfunction

    reg aw_hold_valid;    // 已独立接收但尚未配对的AW有效
    reg [AXIL_ADDR_WIDTH-1:0] aw_hold_addr;    // 独立接收的AW地址
    reg w_hold_valid;    // 已独立接收但尚未配对的W有效
    reg [31:0] w_hold_data;    // 独立接收的W数据
    reg [3:0] w_hold_strb;    // 独立接收的W字节使能

    wire aw_fire = s_axi_awvalid && s_axi_awready;    // AW握手事件
    wire w_fire  = s_axi_wvalid && s_axi_wready;    // W握手事件
    wire have_aw = aw_hold_valid || aw_fire;    // 本拍已有可配对AW
    wire have_w  = w_hold_valid || w_fire;    // 本拍已有可配对W
    wire write_commit = !s_axi_bvalid && have_aw && have_w;    // AW/W配对后的寄存器写事件
    wire [AXIL_ADDR_WIDTH-1:0] write_addr =    // 当前配对写事务的地址
        aw_hold_valid ? aw_hold_addr : s_axi_awaddr;
    wire [31:0] write_data =    // 当前配对写事务的数据
        w_hold_valid ? w_hold_data : s_axi_wdata;
    wire [3:0] write_strb =    // 当前配对写事务的字节使能
        w_hold_valid ? w_hold_strb : s_axi_wstrb;
    wire [7:0] write_offset = write_addr[7:0];    // 寄存器页内字节偏移

    assign s_axi_awready = !aw_hold_valid && !s_axi_bvalid;
    assign s_axi_wready  = !w_hold_valid && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;

    wire [63:0] requested_size = {size_high_reg, size_low_reg};    // 合并后的64 bit目标字节数
    wire [63:0] sample_bytes = cfg_two_channel ? 64'd4 : 64'd2;    // 每数据时刻保存字节数
    wire requested_size_aligned =    // 目标长度能否整除当前样本粒度
        ((requested_size % sample_bytes) == 0);
    wire start_lba_allowed =    // 未启用SLBA或起点不落入保护区
        !slba_enable_reg || (start_lba_reg >= MIN_START_SLBA);

    always @(posedge clk) begin
        if (!rst_n) begin
            aw_hold_valid             <= 1'b0;
            aw_hold_addr              <= {AXIL_ADDR_WIDTH{1'b0}};
            w_hold_valid              <= 1'b0;
            w_hold_data               <= 32'd0;
            w_hold_strb               <= 4'd0;
            s_axi_bresp               <= 2'b00;
            s_axi_bvalid              <= 1'b0;
            s_axi_rdata               <= 32'd0;
            s_axi_rresp               <= 2'b00;
            s_axi_rvalid              <= 1'b0;
            burst_len_reg             <= 32'h0002_0000;
            pattern_start_reg         <= 32'd0;
            mem_size_reg              <= 32'h4000_0000;
            size_low_reg              <= 32'd0;
            size_high_reg             <= 32'd0;
            start_lba_reg             <= 32'd0;
            slba_enable_reg           <= 1'b0;
            capture_id_counter        <= 64'd0;
            transfer_start_pulse      <= 1'b0;
            transfer_stop_pulse       <= 1'b0;
            transfer_active           <= 1'b0;
            transfer_size_bytes       <= 64'd0;
            transfer_capture_id       <= 64'd0;
            cfg_two_channel           <= 1'b1;
            cfg_single_channel_select <= 1'b0;
            wdata_done_reg            <= 1'b0;
            nvme_done_reg             <= 1'b0;
            local_phase_done          <= 1'b0;
            wtrans_time_reg           <= 32'd0;
            rtrans_time_reg           <= 32'd0;
            time_count_reg            <= 64'd0;
            active_cycle_count        <= 64'd0;
            local_done_cycle          <= 64'd0;
            last_error                <= 16'd0;
        end else begin
            transfer_start_pulse <= 1'b0;
            transfer_stop_pulse  <= 1'b0;

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (aw_fire)
                aw_hold_addr <= s_axi_awaddr;
            if (w_fire) begin
                w_hold_data <= s_axi_wdata;
                w_hold_strb <= s_axi_wstrb;
            end

            if (write_commit) begin
                aw_hold_valid <= 1'b0;
                w_hold_valid  <= 1'b0;
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= 2'b00;
                case (write_offset)
                    OFS_START: begin
                        if (write_data[0]) begin
                            if (transfer_active) begin
                                last_error <= ERR_START_WHILE_ACTIVE;
                            end else if (pipeline_fatal_error) begin
                                last_error    <= ERR_PIPELINE_NOT_CLEAN;
                                wdata_done_reg <= 1'b1;
                                nvme_done_reg  <= 1'b1;
                            end else if (requested_size == 0) begin
                                last_error    <= ERR_ZERO_SIZE;
                                wdata_done_reg <= 1'b1;
                                nvme_done_reg  <= 1'b1;
                            end else if (!requested_size_aligned) begin
                                last_error    <= ERR_SIZE_ALIGNMENT;
                                wdata_done_reg <= 1'b1;
                                nvme_done_reg  <= 1'b1;
                            end else if (!start_lba_allowed) begin
                                last_error    <= ERR_PROTECTED_LBA;
                                wdata_done_reg <= 1'b1;
                                nvme_done_reg  <= 1'b1;
                            end else begin
                                transfer_active      <= 1'b1;
                                transfer_start_pulse <= 1'b1;
                                transfer_size_bytes  <= requested_size;
                                capture_id_counter   <=
                                    capture_id_counter + 1'b1;
                                transfer_capture_id  <=
                                    capture_id_counter + 1'b1;
                                wdata_done_reg       <= 1'b0;
                                nvme_done_reg        <= 1'b0;
                                local_phase_done     <= 1'b0;
                                wtrans_time_reg      <= 32'd0;
                                rtrans_time_reg      <= 32'd0;
                                time_count_reg       <= 64'd0;
                                active_cycle_count   <= 64'd0;
                                local_done_cycle     <= 64'd0;
                                last_error           <= 16'd0;
                            end
                        end else if (transfer_active) begin
                            transfer_stop_pulse <= 1'b1;
                        end
                    end
                    OFS_BURST_LEN:    // 保留旧软件写入值，不改变现有Writer固定Burst
                        burst_len_reg <= merge_wstrb(
                            burst_len_reg, write_data, write_strb);
                    OFS_PATTERN:    // 保留旧软件测试Pattern写入值
                        pattern_start_reg <= merge_wstrb(
                            pattern_start_reg, write_data, write_strb);
                    OFS_MEM_SIZE:    // 保留旧软件内存大小写入值
                        mem_size_reg <= merge_wstrb(
                            mem_size_reg, write_data, write_strb);
                    OFS_SIZE_L:    // 更新目标字节数低32位
                        size_low_reg <= merge_wstrb(
                            size_low_reg, write_data, write_strb);
                    OFS_SIZE_H:    // 更新目标字节数高32位
                        size_high_reg <= merge_wstrb(
                            size_high_reg, write_data, write_strb);
                    OFS_START_LBA:    // 更新Raw起始LBA
                        start_lba_reg <= merge_wstrb(
                            start_lba_reg, write_data, write_strb);
                    OFS_SLBA_ENABLE:    // 选择是否采用软件START_LBA
                        slba_enable_reg <= write_data[0];
                    OFS_CAPTURE_CFG: begin    // 更新下次Capture的通道格式
                        cfg_two_channel <= write_data[0];
                        cfg_single_channel_select <= write_data[1];
                    end
                    OFS_CAPTURE_ID_L:    // 更新Capture编号种子低32位
                        capture_id_counter[31:0] <= merge_wstrb(
                            capture_id_counter[31:0],
                            write_data, write_strb);
                    OFS_CAPTURE_ID_H:    // 更新Capture编号种子高32位
                        capture_id_counter[63:32] <= merge_wstrb(
                            capture_id_counter[63:32],
                            write_data, write_strb);
                    default: begin end
                endcase
            end else begin
                if (aw_fire)
                    aw_hold_valid <= 1'b1;
                if (w_fire)
                    w_hold_valid <= 1'b1;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                case (s_axi_araddr[7:0])
                    OFS_START:        s_axi_rdata <=
                        transfer_active ? 32'd1 : 32'd0;
                    OFS_BURST_LEN:    s_axi_rdata <= burst_len_reg;
                    OFS_WTRANS_TIME:  s_axi_rdata <= wtrans_time_reg;
                    OFS_RTRANS_TIME:  s_axi_rdata <= rtrans_time_reg;
                    OFS_PATTERN:      s_axi_rdata <= pattern_start_reg;
                    OFS_MEM_SIZE:     s_axi_rdata <= mem_size_reg;
                    OFS_DATA_WIDTH:   s_axi_rdata <= FDMA_DATA_WIDTH;
                    OFS_SIZE_L:       s_axi_rdata <= size_low_reg;
                    OFS_SIZE_H:       s_axi_rdata <= size_high_reg;
                    OFS_WDATA_DONE:   s_axi_rdata <=
                        {31'd0, wdata_done_reg};
                    OFS_TIME_L:       s_axi_rdata <= time_count_reg[31:0];
                    OFS_TIME_H:       s_axi_rdata <= time_count_reg[63:32];
                    OFS_START_LBA:    s_axi_rdata <= start_lba_reg;
                    OFS_FIFO_FULL:    s_axi_rdata <=
                        {30'd0, adc_fifo_prog_full, adc_fifo_full};
                    OFS_NVME_DONE:    s_axi_rdata <=
                        {31'd0, nvme_done_reg};
                    OFS_SLBA_ENABLE:  s_axi_rdata <=
                        {31'd0, slba_enable_reg};
                    OFS_CAPTURE_CFG:  s_axi_rdata <=
                        {30'd0, cfg_single_channel_select,
                         cfg_two_channel};
                    OFS_CAPTURE_ID_L: s_axi_rdata <=
                        transfer_capture_id[31:0];
                    OFS_CAPTURE_ID_H: s_axi_rdata <=
                        transfer_capture_id[63:32];
                    OFS_STATUS:       s_axi_rdata <= {
                        24'd0,
                        (last_error != 0),
                        pipeline_fatal_error,
                        adc_fifo_prog_full,
                        adc_fifo_full,
                        local_phase_done,
                        nvme_done_reg,
                        wdata_done_reg,
                        transfer_active
                    };
                    OFS_ACCEPTED_L:   s_axi_rdata <=
                        accepted_sample_times[31:0];
                    OFS_ACCEPTED_H:   s_axi_rdata <=
                        accepted_sample_times[63:32];
                    OFS_DROPPED_L:    s_axi_rdata <=
                        dropped_sample_times[31:0];
                    OFS_DROPPED_H:    s_axi_rdata <=
                        dropped_sample_times[63:32];
                    OFS_LAST_ERROR:   s_axi_rdata <= {16'd0, last_error};
                    OFS_BACKEND_STS:  s_axi_rdata <=
                        {16'd0, backend_last_status};
                    default:          s_axi_rdata <= 32'd0;
                endcase
            end

            if (transfer_active)
                active_cycle_count <= active_cycle_count + 1'b1;

            if (local_capture_done_pulse && transfer_active) begin
                wdata_done_reg   <= 1'b1;
                local_phase_done <= 1'b1;
                local_done_cycle <= active_cycle_count;
                wtrans_time_reg  <= active_cycle_count[31:0];
                time_count_reg   <= active_cycle_count;
            end

            // 尚未真正启动ADC采集时收到STOP不会产生Commit；把它转换成
            // 明确的错误终态，保证旧软件的两个无超时done轮询都能退出。
            if (capture_cancelled_pulse && transfer_active) begin
                transfer_active  <= 1'b0;
                wdata_done_reg   <= 1'b1;
                nvme_done_reg    <= 1'b1;
                local_phase_done <= 1'b1;
                last_error       <= ERR_CANCELLED_BY_SOFTWARE;
                time_count_reg   <= active_cycle_count;
            end

            if (nvme_capture_done_pulse && transfer_active) begin
                transfer_active <= 1'b0;
                nvme_done_reg   <= 1'b1;
                if (active_cycle_count >= local_done_cycle)
                    rtrans_time_reg <=
                        (active_cycle_count - local_done_cycle);
            end

            if (pipeline_fatal_error && transfer_active) begin
                transfer_active  <= 1'b0;
                wdata_done_reg   <= 1'b1;
                nvme_done_reg    <= 1'b1;
                local_phase_done <= 1'b1;
                last_error       <= (backend_last_status != 0) ?
                                    backend_last_status :
                                    ERR_PIPELINE_FATAL;
                time_count_reg   <= active_cycle_count;
            end
        end
    end

    initial begin
        if (FDMA_DATA_WIDTH != 256)
            $error("The Vitis-compatible ADC path currently uses 256-bit data");
    end

    wire unused = &{1'b0, s_axi_awprot, s_axi_arprot,    // 仅消除未使用输入告警，不参与功能
                    AXIL_BASE_ADDR[0]};

endmodule
```
