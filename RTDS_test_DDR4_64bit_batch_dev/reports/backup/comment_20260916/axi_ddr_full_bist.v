`timescale 1ns / 1ps

// AXI4 DDR4 全空间自检主控。
// 所有数据事务均使用 16-beat INCR burst；地址游标采用 33 bit，因而能在
// 0xFFFF_FF80 完成最后一个 burst 后显式到达 0x1_0000_0000，而不会静默回绕。
module AXI_DDR_FULL_BIST #(
    // 接口宽度与测试范围参数。FULL_SPACE_LIMIT 比 AXI 地址多一位，专门表示
    // 4 GiB 末端后的 0x1_0000_0000，不能缩成 32 bit。
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH = 4,
    parameter [32:0] FULL_SPACE_LIMIT = 33'h1_0000_0000,
    parameter [31:0] SMOKE_BURST_COUNT = 32'd256,
    parameter [31:0] STRESS_BURST_COUNT = 32'd33554432,
    parameter [63:0] HOLD_CYCLES = 64'd180000000000,
    parameter [31:0] TIMEOUT_CYCLES = 32'd30000000
) (
    // 控制输入在 ui_clk 域使用；start/restart 由下方边沿检测转换为单周期事件。
    input  wire                      aclk,
    input  wire                      aresetn,
    input  wire                      start,
    input  wire                      restart,
    input  wire [2:0]                test_mode,
    input  wire                      repeat_enable,

    // VIO/LED/ILA 使用的运行状态。done/pass/fail 保持到下一次 start/restart。
    output reg                       busy,
    output reg                       done,
    output reg                       pass,
    output reg                       fail,
    output reg  [8:0]                phase,
    output reg  [32:0]               current_addr_ext,
    output reg  [15:0]               progress,
    // 统计与首错现场用于验收记录；计数单位是 AXI burst，不是 64-bit beat。
    output reg  [31:0]               write_transaction_count,
    output reg  [31:0]               read_transaction_count,
    output reg  [63:0]               elapsed_cycle_count,
    output reg  [31:0]               timeout_count,
    output reg  [31:0]               error_count,
    output reg  [ADDR_WIDTH-1:0]     first_error_addr,
    output reg  [DATA_WIDTH-1:0]     first_expected_data,
    output reg  [DATA_WIDTH-1:0]     first_actual_data,
    output reg  [3:0]                last_axi_response,

    // AXI4 写地址通道：固定 16 beat、8 byte/beat、INCR burst。
    output wire [ID_WIDTH-1:0]       m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output wire [7:0]                m_axi_awlen,
    output wire [2:0]                m_axi_awsize,
    output wire [1:0]                m_axi_awburst,
    output wire [0:0]                m_axi_awlock,
    output wire [3:0]                m_axi_awcache,
    output wire [2:0]                m_axi_awprot,
    output wire [3:0]                m_axi_awqos,
    output reg                       m_axi_awvalid,
    input  wire                      m_axi_awready,

    // AXI4 写数据通道：WSTRB 模式会只更新指定 byte lane，其余模式全字节有效。
    output reg  [DATA_WIDTH-1:0]     m_axi_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output reg                       m_axi_wlast,
    output reg                       m_axi_wvalid,
    input  wire                      m_axi_wready,

    // AXI4 写响应通道：BID 或 BRESP 非期望值均计为一次错误。
    input  wire [ID_WIDTH-1:0]       m_axi_bid,
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output reg                       m_axi_bready,

    // AXI4 读地址通道与写通道采用相同 burst 几何，便于一一回读比较。
    output wire [ID_WIDTH-1:0]       m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]     m_axi_araddr,
    output wire [7:0]                m_axi_arlen,
    output wire [2:0]                m_axi_arsize,
    output wire [1:0]                m_axi_arburst,
    output wire [0:0]                m_axi_arlock,
    output wire [3:0]                m_axi_arcache,
    output wire [2:0]                m_axi_arprot,
    output wire [3:0]                m_axi_arqos,
    output reg                       m_axi_arvalid,
    input  wire                      m_axi_arready,

    // AXI4 读数据通道：每拍先采样，下一状态再比较，切断 300 MHz 长组合路径。
    input  wire [ID_WIDTH-1:0]       m_axi_rid,
    input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rlast,
    input  wire                      m_axi_rvalid,
    output reg                       m_axi_rready
);

// 一个 burst 为 16×64 bit=128 byte；所有发生器地址按 128 byte 对齐，
// 因而天然不会跨越 4 KiB AXI 边界。
localparam integer BYTE_LANES = DATA_WIDTH / 8;
localparam [7:0] BURST_BEATS_MINUS_ONE = 8'd15;
localparam [32:0] BURST_BYTES = 33'd128;

// 主状态按 AXI 五通道拆分。READ_CHECK 是读流水检查级，HOLD 只服务保持测试。
localparam [3:0] BIST_IDLE       = 4'd0;
localparam [3:0] BIST_PREPARE    = 4'd1;
localparam [3:0] BIST_WRITE_DATA = 4'd2;
localparam [3:0] BIST_WRITE_RESP = 4'd3;
localparam [3:0] BIST_READ_ADDR  = 4'd4;
localparam [3:0] BIST_READ_DATA  = 4'd5;
localparam [3:0] BIST_HOLD       = 4'd6;
localparam [3:0] BIST_DONE       = 4'd7;
localparam [3:0] BIST_READ_CHECK = 4'd8;
// W 通道 burst 首拍发射级：把"burst 地址推进→模式译码→数据族生成"拆到
// 两个时钟沿，是 WDATA 300 MHz 时序收敛的结构性流水级。
localparam [3:0] BIST_WRITE_FIRST = 4'd9;

// 模式/阶段/突发游标在一次测试期间保持同步；active_* 在启动时锁存，
// 防止操作者在 VIO 中途修改 test_mode/repeat 而改变正在执行的序列。
reg [3:0] bist_curr_st;
reg [2:0] active_mode;
reg       active_repeat;
reg [31:0] burst_index;
reg [31:0] burst_count;
reg [4:0] beat_index;
// AW 与 W 可以独立握手，两个完成标志确保只有两者都完成后才等待 BRESP。
reg       aw_complete;
reg       w_complete;
reg       start_delay;
reg       restart_delay;
// watchdog 只在 busy 且没有任何 AXI 握手时递增；hold_count 则允许模式7
// 有意静默保持，不把保持时间误判成总线超时。
reg [31:0] watchdog_count;
reg [63:0] hold_count;
// 读返回流水寄存器把“接收 R beat”和“数据/协议检查”分到相邻周期。
reg [ADDR_WIDTH-1:0] read_sample_addr;
reg [DATA_WIDTH-1:0] read_sample_expected;
reg [DATA_WIDTH-1:0] read_sample_actual;
reg [1:0] read_sample_resp;
reg read_sample_protocol_error;
reg read_sample_is_last;
// 当前 burst 的终点标志提前寄存，完成响应时只读取单 bit 状态。
reg current_burst_is_last;
// W 通道预取地址：保存"当前送上 WDATA 的 beat 之后的下一个 beat"字节地址。
// 与 BIST_WRITE_FIRST 配合构成"地址预取一拍 + 数据生成一拍"两级流水，
// 使 m_axi_wdata 的 D 端不再串联 33-bit 地址加法与 write_data() 译码
// （历史 WNS -0.071 的 11 条失败路径即该单拍长组合链）。
reg [32:0] w_next_addr;
// WDATA 预取寄存器：在当前 beat 发送期间准备下一 beat，AXI stall 时保持不变。
reg [DATA_WIDTH-1:0] w_next_data;
// 只依赖 mode/phase 的数据族先译码寄存，避免 phase 直接扇出到 WDATA 选择树。
reg [DATA_WIDTH-1:0] phase_pattern_data;
reg                  phase_invert_data;

// 事件、握手和派生属性统一在此声明，时序过程只使用明确的单周期条件。
wire start_event;
wire restart_event;
wire aw_fire;
wire w_fire;
wire b_fire;
wire ar_fire;
wire r_fire;
wire protocol_progress;
wire expected_rlast;
wire write_error;
wire [32:0] beat_addr_ext;
wire [63:0] expected_read_data;
wire [63:0] selected_write_data;
wire [7:0] selected_write_strobe;
wire phase_is_write;
wire direction_reverse;
wire phase_is_final;

// VIO 电平转单周期上升沿事件；各 fire 信号严格遵循 VALID&&READY。
assign start_event = start & ~start_delay;
assign restart_event = restart & ~restart_delay;
assign aw_fire = m_axi_awvalid & m_axi_awready;
assign w_fire = m_axi_wvalid & m_axi_wready;
assign b_fire = m_axi_bvalid & m_axi_bready;
assign ar_fire = m_axi_arvalid & m_axi_arready;
assign r_fire = m_axi_rvalid & m_axi_rready;
// 任一 AXI 通道前进都清 watchdog，避免正常背压期间过早超时。
assign protocol_progress = aw_fire | w_fire | b_fire | ar_fire | r_fire;
assign expected_rlast = (beat_index == 5'd15);
assign write_error = (m_axi_bid != {ID_WIDTH{1'b0}}) | (m_axi_bresp != 2'b00);
// beat 地址=burst 基址+beat_index×8；数据函数用这个字节地址生成可复算期望值。
assign beat_addr_ext = current_addr_ext + {25'd0, beat_index[3:0], 3'b000};
assign expected_read_data = expected_data(active_mode, phase, beat_addr_ext[31:0]);
assign selected_write_data = write_data(active_mode, phase, beat_addr_ext[31:0]);
assign selected_write_strobe = write_strobe(active_mode, phase);
assign phase_is_write = is_write_phase(active_mode, phase);
assign direction_reverse = is_reverse_phase(active_mode, phase);
assign phase_is_final = is_final_phase(active_mode, phase);
// 单主机 BIST 固定使用 AXI ID 0；cache/prot/qos 采用普通非特权数据访问属性。
assign m_axi_awid = {ID_WIDTH{1'b0}};
assign m_axi_awlen = BURST_BEATS_MINUS_ONE;
assign m_axi_awsize = 3'd3;
assign m_axi_awburst = 2'b01;
assign m_axi_awlock = 1'b0;
assign m_axi_awcache = 4'b0011;
assign m_axi_awprot = 3'b000;
assign m_axi_awqos = 4'b0000;
assign m_axi_arid = {ID_WIDTH{1'b0}};
assign m_axi_arlen = BURST_BEATS_MINUS_ONE;
assign m_axi_arsize = 3'd3;
assign m_axi_arburst = 2'b01;
assign m_axi_arlock = 1'b0;
assign m_axi_arcache = 4'b0011;
assign m_axi_arprot = 3'b000;
assign m_axi_arqos = 4'b0000;

// 模式阶段定义：每个阶段要么只写，要么只读；读阶段始终在相应写阶段之后。
// 这种安排保证地址别名测试先写完所有稀疏位置，再统一回读，能够发现后写地址
// 对先写地址造成的覆盖，而不是只验证“刚写即读”。
function is_write_phase;
    input [2:0] mode_value;
    input [8:0] phase_value;
    begin
        case (mode_value)
            3'd0: is_write_phase = (phase_value == 9'd0);
            3'd1: is_write_phase = ~phase_value[0];
            3'd2: is_write_phase = ~phase_value[0];
            3'd3: is_write_phase = (phase_value == 9'd0);
            3'd4: is_write_phase = (phase_value == 9'd0);
            3'd5: is_write_phase = (phase_value == 9'd0) | (phase_value == 9'd2);
            3'd6: is_write_phase = (phase_value == 9'd0) |
                                           (phase_value == 9'd2) |
                                           (phase_value == 9'd4);
            default: is_write_phase = (phase_value == 9'd0);
        endcase
    end
endfunction

function is_reverse_phase;
    input [2:0] mode_value;
    input [8:0] phase_value;
    begin
        case (mode_value)
            3'd5: is_reverse_phase = (phase_value >= 9'd2);
            3'd6: is_reverse_phase = (phase_value == 9'd3) | (phase_value == 9'd4);
            default: is_reverse_phase = 1'b0;
        endcase
    end
endfunction

// 每种 mode 的最后阶段不同；只有完成该阶段最后一个读/写响应后才置 done。
function is_final_phase;
    input [2:0] mode_value;
    input [8:0] phase_value;
    begin
        case (mode_value)
            3'd0: is_final_phase = (phase_value == 9'd1);
            3'd1: is_final_phase = (phase_value == 9'd263);
            3'd2: is_final_phase = (phase_value == 9'd17);
            3'd3: is_final_phase = (phase_value == 9'd1);
            3'd4: is_final_phase = (phase_value == 9'd1);
            3'd5: is_final_phase = (phase_value == 9'd3);
            3'd6: is_final_phase = (phase_value == 9'd5);
            default: is_final_phase = (phase_value == 9'd1);
        endcase
    end
endfunction

// 数据线模式包含 00/FF/AA/55、64 个 Walking-1 和 64 个 Walking-0 样本。
// 每个样本使用相邻的写、读阶段，9-bit phase 能完整表示 264 个阶段。
function [63:0] line_pattern;
    input [7:0] pattern_index;
    reg [5:0] bit_index;
    begin
        bit_index = 6'd0;
        case (pattern_index)
            7'd0: line_pattern = 64'h0000_0000_0000_0000;
            7'd1: line_pattern = 64'hFFFF_FFFF_FFFF_FFFF;
            7'd2: line_pattern = 64'hAAAA_AAAA_AAAA_AAAA;
            7'd3: line_pattern = 64'h5555_5555_5555_5555;
            default: begin
                if (pattern_index < 8'd68) begin
                    bit_index = pattern_index - 8'd4;
                    line_pattern = 64'h0000_0000_0000_0001 << bit_index;
                end else begin
                    bit_index = pattern_index - 8'd68;
                    line_pattern = ~(64'h0000_0000_0000_0001 << bit_index);
                end
            end
        endcase
    end
endfunction

// 地址相关模式把 byte address 与其反码同时写入，既检查数据又暴露地址别名。
function [63:0] address_pattern;
    input [31:0] byte_addr;
    begin
        address_pattern = {~byte_addr, byte_addr};
    end
endfunction

// 确定性 PRBS-like 混合函数只依赖地址，无需片上存储期望数组即可回读复算。
function [63:0] prbs_pattern;
    input [31:0] byte_addr;
    reg [63:0] mixed_value;
    begin
        mixed_value = {byte_addr ^ 32'hA5C3_7E19, ~byte_addr};
        mixed_value = mixed_value ^ (mixed_value << 13);
        mixed_value = mixed_value ^ (mixed_value >> 7);
        prbs_pattern = mixed_value ^ (mixed_value << 17);
    end
endfunction

// 写数据总入口按 mode/phase 选择数据族。该函数位于 WDATA 数据锥中，
// 已按"BIST_WRITE_FIRST 地址预取一拍 + 本级数据生成一拍"分级流水：
// 调用点的 byte_addr 均来自寄存器（current_addr_ext/w_next_addr），
// 不再与 33-bit 地址加法串联，也不使用假约束。
function [63:0] write_data;
    input [2:0] mode_value;
    input [8:0] phase_value;
    input [31:0] byte_addr;
    reg [7:0] lane_value;
    begin
        lane_value = 8'h00;
        case (mode_value)
            3'd0: write_data = address_pattern(byte_addr);
            3'd1: write_data = line_pattern(phase_value[8:1]);
            3'd2: begin
                if (phase_value == 9'd0) begin
                    write_data = 64'h0000_0000_0000_0000;
                end else begin
                    lane_value = 8'hA0 + {5'd0, phase_value[4:1]};
                    write_data = {8{lane_value}};
                end
            end
            3'd3: write_data = address_pattern(byte_addr) ^ 64'h3C96_5AA5_C369_A55A;
            3'd4: write_data = address_pattern(byte_addr) ^ 64'h5AA5_C33C_A55A_69C3;
            3'd5: begin
                if (phase_value < 9'd2) begin
                    write_data = address_pattern(byte_addr);
                end else begin
                    write_data = ~address_pattern(byte_addr);
                end
            end
            3'd6: begin
                if ((phase_value == 9'd0) | (phase_value == 9'd1) |
                    (phase_value == 9'd4) | (phase_value == 9'd5)) begin
                    write_data = 64'h0000_0000_0000_0000;
                end else begin
                    write_data = 64'hFFFF_FFFF_FFFF_FFFF;
                end
            end
            default: write_data = prbs_pattern(byte_addr);
        endcase
    end
endfunction

// 阶段相关但与地址无关的数据只在 phase 切换时计算一次。
// mode0/3/4/5/7 的返回值仅作占位，地址相关模式由 write_data_predecoded 处理。
function [63:0] phase_pattern;
    input [2:0] mode_value;
    input [8:0] phase_value;
    begin
        case (mode_value)
            3'd1: phase_pattern = line_pattern(phase_value[8:1]);
            3'd2: begin
                if (phase_value == 9'd0) begin
                    phase_pattern = 64'h0000_0000_0000_0000;
                end else begin
                    phase_pattern = {8{8'hA0 + {5'd0, phase_value[4:1]}}};
                end
            end
            3'd6: begin
                if ((phase_value == 9'd0) | (phase_value == 9'd1) |
                    (phase_value == 9'd4) | (phase_value == 9'd5)) begin
                    phase_pattern = 64'h0000_0000_0000_0000;
                end else begin
                    phase_pattern = 64'hFFFF_FFFF_FFFF_FFFF;
                end
            end
            default: phase_pattern = 64'h0000_0000_0000_0000;
        endcase
    end
endfunction

// 使用已寄存的 phase_pattern_data 和 phase_invert_data 生成当前地址的数据。
// 该函数不再读取 9-bit phase，因而 phase→WDATA 的长组合扇出被切断。
function [63:0] write_data_predecoded;
    input [2:0] mode_value;
    input [63:0] phase_data_value;
    input        invert_value;
    input [31:0] byte_addr;
    begin
        case (mode_value)
            3'd0: write_data_predecoded = address_pattern(byte_addr);
            3'd1: write_data_predecoded = phase_data_value;
            3'd2: write_data_predecoded = phase_data_value;
            3'd3: write_data_predecoded =
                address_pattern(byte_addr) ^ 64'h3C96_5AA5_C369_A55A;
            3'd4: write_data_predecoded =
                address_pattern(byte_addr) ^ 64'h5AA5_C33C_A55A_69C3;
            3'd5: begin
                if (invert_value) begin
                    write_data_predecoded = ~address_pattern(byte_addr);
                end else begin
                    write_data_predecoded = address_pattern(byte_addr);
                end
            end
            3'd6: write_data_predecoded = phase_data_value;
            default: write_data_predecoded = prbs_pattern(byte_addr);
        endcase
    end
endfunction

// mode2 的偶数 phase 执行局部写；lane_index 将八个 WSTRB 位逐个覆盖。
function [7:0] write_strobe;
    input [2:0] mode_value;
    input [8:0] phase_value;
    reg [3:0] lane_index;
    begin
        write_strobe = 8'hFF;
        lane_index = 4'd0;
        if ((mode_value == 3'd2) & (phase_value >= 9'd2)) begin
            lane_index = (phase_value - 9'd2) >> 1;
            write_strobe = 8'h01 << lane_index[2:0];
        end
    end
endfunction

// 除 WSTRB 外期望值与写值相同；WSTRB 模式必须累计此前已写 lane，
// 同时确认未选中字节保持原值。
function [63:0] expected_data;
    input [2:0] mode_value;
    input [8:0] phase_value;
    input [31:0] byte_addr;
    integer lane_iter;
    integer completed_lanes;
    reg [63:0] accumulated_value;
    begin
        if (mode_value != 3'd2) begin
            expected_data = write_data(mode_value, phase_value, byte_addr);
        end else begin
            accumulated_value = 64'h0000_0000_0000_0000;
            completed_lanes = 0;
            if (phase_value >= 9'd3) begin
                completed_lanes = ((phase_value - 9'd3) >> 1) + 1;
            end
            for (lane_iter = 0; lane_iter < 8; lane_iter = lane_iter + 1) begin
                if (lane_iter < completed_lanes) begin
                    accumulated_value[(lane_iter * 8) +: 8] = 8'hA1 + lane_iter;
                end
            end
            expected_data = accumulated_value;
        end
    end
endfunction

// 稀疏地址从 0 和 128 B 的二次幂偏移构成，用于检测地址线短路/高位别名。
function [32:0] sparse_address;
    input [31:0] index_value;
    begin
        if (index_value == 32'd0) begin
            sparse_address = 33'd0;
        end else begin
            sparse_address = 33'h0000_00080 << (index_value - 32'd1);
        end
    end
endfunction

// 定向边界覆盖 burst、2 KiB、4 KiB、候选行边界和 DDR 最末 128 B。
function [32:0] boundary_address;
    input [31:0] index_value;
    begin
        case (index_value[2:0])
            3'd0: boundary_address = 33'h0_0000_0000;
            3'd1: boundary_address = 33'h0_0000_0080;
            3'd2: boundary_address = 33'h0_0000_0780;
            3'd3: boundary_address = 33'h0_0000_0F80;
            3'd4: boundary_address = 33'h0_0000_3F80;
            default: boundary_address = 33'h0_FFFF_FF80;
        endcase
    end
endfunction

// 返回每个 phase 的 burst 数；全空间计数由 33-bit byte 上界右移7得到。
function [31:0] mode_burst_count;
    input [2:0] mode_value;
    begin
        case (mode_value)
            3'd0: mode_burst_count = SMOKE_BURST_COUNT;
            3'd1: mode_burst_count = 32'd1;
            3'd2: mode_burst_count = 32'd1;
            3'd3: mode_burst_count = 32'd26;
            3'd4: mode_burst_count = 32'd6;
            3'd5: mode_burst_count = FULL_SPACE_LIMIT[32:7];
            3'd6: mode_burst_count = FULL_SPACE_LIMIT[32:7];
            default: mode_burst_count = STRESS_BURST_COUNT;
        endcase
    end
endfunction

// 反向阶段从末 burst 基址开始，其余阶段从0开始；地址始终保持33 bit。
function [32:0] phase_start_address;
    input [2:0] mode_value;
    input reverse_value;
    begin
        if (reverse_value) begin
            phase_start_address = FULL_SPACE_LIMIT - BURST_BYTES;
        end else if (mode_value == 3'd7) begin
            phase_start_address = 33'd0;
        end else begin
            phase_start_address = 33'd0;
        end
    end
endfunction

// 稀疏/边界模式按表取址；连续模式直接沿用递增或递减游标。
function [32:0] active_burst_address;
    input [2:0] mode_value;
    input [31:0] index_value;
    input [32:0] sequential_addr;
    begin
        case (mode_value)
            3'd3: active_burst_address = sparse_address(index_value);
            3'd4: active_burst_address = boundary_address(index_value);
            default: active_burst_address = sequential_addr;
        endcase
    end
endfunction

// 所有模式统一用 burst 序号判断阶段终点。FULL_SPACE_LIMIT 保持 33 bit，
// mode_burst_count 先精确得到 4 GiB / 128 B = 33,554,432 个 burst；因此
// 最后一个序号比较不会发生 32-bit 地址回绕，也不需要在 300 MHz 通路内
// 再执行模式选择、33-bit 地址加法和终点比较。
function is_phase_burst_last;
    input [31:0] index_value;
    input [31:0] count_value;
    begin
        is_phase_burst_last = (index_value == (count_value - 32'd1));
    end
endfunction

// 进度采用固定比例映射，避免在可综合通路中引入可变除法器。
// 全空间和压力模式直接使用 33-bit 地址的高 16 位表示 0..65535。
function [15:0] progress_value;
    input [2:0] mode_value;
    input reverse_value;
    input [31:0] index_value;
    input [32:0] address_value;
    begin
        case (mode_value)
            3'd0: progress_value = index_value[7:0] << 8;
            3'd1: progress_value = 16'hFFFF;
            3'd2: progress_value = 16'hFFFF;
            // 稀疏地址和边界模式的项数固定，使用查表避免在 300 MHz 状态通路中
            // 推断组合乘法器。末项仍由状态机完成条件明确置为 16'hFFFF。
            3'd3: begin
                case (index_value[4:0])
                    5'd0:  progress_value = 16'd0;
                    5'd1:  progress_value = 16'd2520;
                    5'd2:  progress_value = 16'd5040;
                    5'd3:  progress_value = 16'd7560;
                    5'd4:  progress_value = 16'd10080;
                    5'd5:  progress_value = 16'd12600;
                    5'd6:  progress_value = 16'd15120;
                    5'd7:  progress_value = 16'd17640;
                    5'd8:  progress_value = 16'd20160;
                    5'd9:  progress_value = 16'd22680;
                    5'd10: progress_value = 16'd25200;
                    5'd11: progress_value = 16'd27720;
                    5'd12: progress_value = 16'd30240;
                    5'd13: progress_value = 16'd32760;
                    5'd14: progress_value = 16'd35280;
                    5'd15: progress_value = 16'd37800;
                    5'd16: progress_value = 16'd40320;
                    5'd17: progress_value = 16'd42840;
                    5'd18: progress_value = 16'd45360;
                    5'd19: progress_value = 16'd47880;
                    5'd20: progress_value = 16'd50400;
                    5'd21: progress_value = 16'd52920;
                    5'd22: progress_value = 16'd55440;
                    5'd23: progress_value = 16'd57960;
                    5'd24: progress_value = 16'd60480;
                    default: progress_value = 16'd63000;
                endcase
            end
            3'd4: begin
                case (index_value[2:0])
                    3'd0: progress_value = 16'd0;
                    3'd1: progress_value = 16'd10922;
                    3'd2: progress_value = 16'd21844;
                    3'd3: progress_value = 16'd32766;
                    3'd4: progress_value = 16'd43688;
                    3'd5: progress_value = 16'd54610;
                    default: progress_value = 16'hFFFF;
                endcase
            end
            default: begin
                if (reverse_value) begin
                    progress_value = 16'hFFFF - address_value[31:16];
                end else begin
                    progress_value = address_value[31:16];
                end
            end
        endcase
    end
endfunction

// 状态相关寄存器共享同一 ui_clk、复位、状态分支及 AXI 握手不变量。
// 依照 CUSTOM-RTL-001 的状态机例外集中更新，便于逐状态核对 AW/W 独立握手、
// burst 末端、错误现场和阶段切换，拆成独立过程会复制同一 case 并增加漏改风险。
always @(posedge aclk) begin : bist_state_registers
    if (!aresetn) begin
        // 同步低有效 AXI 复位：清除所有有效/就绪输出和可见状态，禁止复位期事务。
        bist_curr_st <= BIST_IDLE;
        active_mode <= 3'd0;
        active_repeat <= 1'b0;
        busy <= 1'b0;
        done <= 1'b0;
        pass <= 1'b0;
        fail <= 1'b0;
        phase <= 9'd0;
        current_addr_ext <= 33'd0;
        progress <= 16'd0;
        burst_index <= 32'd0;
        burst_count <= 32'd0;
        beat_index <= 5'd0;
        aw_complete <= 1'b0;
        w_complete <= 1'b0;
        start_delay <= 1'b0;
        restart_delay <= 1'b0;
        watchdog_count <= 32'd0;
        hold_count <= 64'd0;
        read_sample_addr <= {ADDR_WIDTH{1'b0}};
        read_sample_expected <= {DATA_WIDTH{1'b0}};
        read_sample_actual <= {DATA_WIDTH{1'b0}};
        read_sample_resp <= 2'b00;
        read_sample_protocol_error <= 1'b0;
        read_sample_is_last <= 1'b0;
        current_burst_is_last <= 1'b0;
        w_next_addr <= 33'd0;
        w_next_data <= {DATA_WIDTH{1'b0}};
        phase_pattern_data <= {DATA_WIDTH{1'b0}};
        phase_invert_data <= 1'b0;
        write_transaction_count <= 32'd0;
        read_transaction_count <= 32'd0;
        elapsed_cycle_count <= 64'd0;
        timeout_count <= 32'd0;
        error_count <= 32'd0;
        first_error_addr <= {ADDR_WIDTH{1'b0}};
        first_expected_data <= {DATA_WIDTH{1'b0}};
        first_actual_data <= {DATA_WIDTH{1'b0}};
        last_axi_response <= 4'd0;
        m_axi_awaddr <= {ADDR_WIDTH{1'b0}};
        m_axi_awvalid <= 1'b0;
        m_axi_wdata <= {DATA_WIDTH{1'b0}};
        m_axi_wstrb <= {BYTE_LANES{1'b0}};
        m_axi_wlast <= 1'b0;
        m_axi_wvalid <= 1'b0;
        m_axi_bready <= 1'b0;
        m_axi_araddr <= {ADDR_WIDTH{1'b0}};
        m_axi_arvalid <= 1'b0;
        m_axi_rready <= 1'b0;
    end else begin
        // 每拍保存 VIO 控制电平，供下一拍上升沿检测；长按不会重复触发。
        start_delay <= start;
        restart_delay <= restart;

        // 运行计时与协议 watchdog。AXI 有握手即视为取得进展；空闲时归零。
        if (busy) begin
            elapsed_cycle_count <= elapsed_cycle_count + 64'd1;
            if (protocol_progress) begin
                watchdog_count <= 32'd0;
            end else begin
                watchdog_count <= watchdog_count + 32'd1;
            end
        end else begin
            watchdog_count <= 32'd0;
        end

        // 超时优先级高于状态机：冻结首错附近地址、撤销全部 AXI 请求并结束。
        if (busy & (watchdog_count >= TIMEOUT_CYCLES)) begin
            timeout_count <= timeout_count + 32'd1;
            error_count <= error_count + 32'd1;
            fail <= 1'b1;
            pass <= 1'b0;
            done <= 1'b1;
            busy <= 1'b0;
            first_error_addr <= current_addr_ext[31:0];
            first_expected_data <= expected_read_data;
            first_actual_data <= m_axi_rdata;
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
            bist_curr_st <= BIST_DONE;
        // restart 可从任意非超时状态重新初始化；start 仅在 IDLE 接受。
        end else if (restart_event | ((bist_curr_st == BIST_IDLE) & start_event)) begin
            active_mode <= test_mode;
            active_repeat <= repeat_enable;
            busy <= 1'b1;
            done <= 1'b0;
            pass <= 1'b0;
            fail <= 1'b0;
            phase <= 9'd0;
            current_addr_ext <= 33'd0;
            progress <= 16'd0;
            burst_index <= 32'd0;
            burst_count <= mode_burst_count(test_mode);
            current_burst_is_last <= 1'b0;
            w_next_addr <= 33'd0;
            w_next_data <= {DATA_WIDTH{1'b0}};
            phase_pattern_data <= {DATA_WIDTH{1'b0}};
            phase_invert_data <= 1'b0;
            beat_index <= 5'd0;
            aw_complete <= 1'b0;
            w_complete <= 1'b0;
            write_transaction_count <= 32'd0;
            read_transaction_count <= 32'd0;
            elapsed_cycle_count <= 64'd0;
            timeout_count <= 32'd0;
            error_count <= 32'd0;
            first_error_addr <= {ADDR_WIDTH{1'b0}};
            first_expected_data <= {DATA_WIDTH{1'b0}};
            first_actual_data <= {DATA_WIDTH{1'b0}};
            last_axi_response <= 4'd0;
            m_axi_awvalid <= 1'b0;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
            bist_curr_st <= BIST_PREPARE;
        end else begin
            case (bist_curr_st)
                BIST_IDLE: begin
                    // 等待单周期 start_event；完成状态不会自行重新开始。
                    busy <= 1'b0;
                end

                BIST_PREPARE: begin
                    // 新 phase 统一重置 burst/beat 游标，锁存首地址及末 burst 标志。
                    // 写 phase 同时发起 AW 和首个 W beat；读 phase 只发起 AR。
                    current_addr_ext <= active_burst_address(
                        active_mode,
                        32'd0,
                        phase_start_address(active_mode, direction_reverse)
                    );
                    burst_index <= 32'd0;
                    // 将阶段末突发判断提前寄存，避免 32-bit 终点比较直接驱动
                    // 大量状态寄存器 CE，降低 300 MHz 域的扇出和组合级数。
                    current_burst_is_last <= is_phase_burst_last(32'd0, burst_count);
                    phase_pattern_data <= phase_pattern(active_mode, phase);
                    phase_invert_data <= (active_mode == 3'd5) & (phase >= 9'd2);
                    beat_index <= 5'd0;
                    aw_complete <= 1'b0;
                    w_complete <= 1'b0;
                    if (phase_is_write) begin
                        // 写 phase 的 AW/W 发射推迟到 BIST_WRITE_FIRST 拍：该拍
                        // 数据与地址源（current_addr_ext/phase）均为寄存器输出，
                        // 避免 phase_start_address 译码、地址加法与 write_data()
                        // 在同一拍串联直达 m_axi_wdata/m_axi_awaddr。
                        bist_curr_st <= BIST_WRITE_FIRST;
                    end else begin
                        m_axi_araddr <= active_burst_address(
                            active_mode,
                            32'd0,
                            phase_start_address(active_mode, direction_reverse)
                        );
                        m_axi_arvalid <= 1'b1;
                        bist_curr_st <= BIST_READ_ADDR;
                    end
                end

                BIST_WRITE_FIRST: begin
                    // burst 首拍发射级：AW 地址与首个 W beat 数据均取自上一拍已
                    // 寄存的 current_addr_ext；同时把 beat1 地址和数据预取到寄存器。
                    // phase_pattern_data 已在 BIST_PREPARE 锁存，地址相关函数只处理
                    // 当前寄存器地址，切断 phase→WDATA 的长组合链。
                    m_axi_awaddr <= current_addr_ext[ADDR_WIDTH-1:0];
                    m_axi_awvalid <= 1'b1;
                    m_axi_wdata <= write_data_predecoded(
                        active_mode,
                        phase_pattern_data,
                        phase_invert_data,
                        current_addr_ext[31:0]
                    );
                    m_axi_wstrb <= write_strobe(active_mode, phase);
                    m_axi_wlast <= 1'b0;
                    m_axi_wvalid <= 1'b1;
                    w_next_addr <= current_addr_ext + 33'd8;
                    w_next_data <= write_data_predecoded(
                        active_mode,
                        phase_pattern_data,
                        phase_invert_data,
                        current_addr_ext[31:0] + 32'd8
                    );
                    beat_index <= 5'd0;
                    bist_curr_st <= BIST_WRITE_DATA;
                end

                BIST_WRITE_DATA: begin
                    // AW/W 相互独立：任一通道先握手都不会阻塞另一个通道。
                    // WDATA 采用真正的数据预取流水：本拍打出的数据直接取
                    // w_next_data（寄存器到寄存器），stall 期间所有输出保持稳定。
                    if (aw_fire) begin
                        m_axi_awvalid <= 1'b0;
                        aw_complete <= 1'b1;
                    end
                    if (w_fire) begin
                        if (beat_index == 5'd15) begin
                            m_axi_wvalid <= 1'b0;
                            m_axi_wlast <= 1'b0;
                            w_complete <= 1'b1;
                        end else begin
                            beat_index <= beat_index + 5'd1;
                            m_axi_wdata <= w_next_data;
                            w_next_addr <= w_next_addr + 33'd8;
                            w_next_data <= write_data_predecoded(
                                active_mode,
                                phase_pattern_data,
                                phase_invert_data,
                                w_next_addr[31:0] + 32'd8
                            );
                            m_axi_wlast <= (beat_index == 5'd14);
                        end
                    end
                    // 地址和全部16个数据 beat 均完成后才拉高 BREADY 等待最终写响应。
                    if ((aw_complete | aw_fire) & (w_complete | (w_fire & expected_rlast))) begin
                        m_axi_bready <= 1'b1;
                        bist_curr_st <= BIST_WRITE_RESP;
                    end
                end

                BIST_WRITE_RESP: begin
                    // BRESP 是写完成边界：事务计数、错误记录、换 burst/phase 都在此发生。
                    if (b_fire) begin
                        m_axi_bready <= 1'b0;
                        write_transaction_count <= write_transaction_count + 32'd1;
                        last_axi_response <= {2'b00, m_axi_bresp};
                        if (write_error) begin
                            error_count <= error_count + 32'd1;
                            fail <= 1'b1;
                            if (error_count == 32'd0) begin
                                first_error_addr <= current_addr_ext[31:0];
                                first_expected_data <= selected_write_data;
                                first_actual_data <= 64'd0;
                            end
                        end

                        // 末 burst 根据模式进入保持、结束或下一 phase；普通 burst 则更新地址。
                        if (current_burst_is_last) begin
                            if ((active_mode == 3'd7) & (phase == 9'd0)) begin
                                hold_count <= 64'd0;
                                phase <= 9'd1;
                                bist_curr_st <= BIST_HOLD;
                            end else if (phase_is_final) begin
                                done <= 1'b1;
                                pass <= ~(fail | write_error);
                                busy <= 1'b0;
                                bist_curr_st <= BIST_DONE;
                            end else begin
                                phase <= phase + 9'd1;
                                bist_curr_st <= BIST_PREPARE;
                            end
                        end else begin
                            // 非末 burst 只更新游标与下一 burst 基址 current_addr_ext
                            // （33-bit ±128 或稀疏/边界查表，无 write_data 串联）；
                            // AW 与首个 W beat 推迟到 BIST_WRITE_FIRST 拍发射，
                            // 消除 burst_index→地址加法→模式译码→数据生成长链。
                            burst_index <= burst_index + 32'd1;
                            current_burst_is_last <= is_phase_burst_last(
                                burst_index + 32'd1,
                                burst_count
                            );
                            if (active_mode == 3'd3) begin
                                current_addr_ext <= sparse_address(burst_index + 32'd1);
                            end else if (active_mode == 3'd4) begin
                                current_addr_ext <= boundary_address(burst_index + 32'd1);
                            end else if (direction_reverse) begin
                                current_addr_ext <= current_addr_ext - BURST_BYTES;
                            end else begin
                                current_addr_ext <= current_addr_ext + BURST_BYTES;
                            end
                            aw_complete <= 1'b0;
                            w_complete <= 1'b0;
                            if (burst_count > 32'd1) begin
                                progress <= progress_value(
                                    active_mode,
                                    direction_reverse,
                                    burst_index + 32'd1,
                                    current_addr_ext
                                );
                            end
                            bist_curr_st <= BIST_WRITE_FIRST;
                        end
                    end
                end

                BIST_READ_ADDR: begin
                    // AR 握手后才允许接收 R；beat_index 从0对应第一个返回 beat。
                    if (ar_fire) begin
                        m_axi_arvalid <= 1'b0;
                        beat_index <= 5'd0;
                        m_axi_rready <= 1'b1;
                        bist_curr_st <= BIST_READ_DATA;
                    end
                end

                BIST_READ_DATA: begin
                    if (r_fire) begin
                        // 先寄存本拍 AXI R 数据和期望值，下一拍再比较及记录错误。
                        // 该流水级切断 beat_index→地址加法→模式译码→64-bit 比较→
                        // 首错寄存器使能的 300 MHz 长组合路径；吞吐降低但测试覆盖不变。
                        read_sample_addr <= beat_addr_ext[31:0];
                        read_sample_expected <= expected_read_data;
                        read_sample_actual <= m_axi_rdata;
                        read_sample_resp <= m_axi_rresp;
                        read_sample_protocol_error <=
                            (m_axi_rid != {ID_WIDTH{1'b0}}) |
                            (m_axi_rlast != expected_rlast);
                        read_sample_is_last <= expected_rlast;
                        last_axi_response <= {m_axi_rresp, 2'b00};
                        m_axi_rready <= 1'b0;
                        bist_curr_st <= BIST_READ_CHECK;
                    end
                end

                BIST_READ_CHECK: begin
                    // 检查上一拍锁存的数据、响应、ID及 RLAST。首错寄存器只写一次，
                    // error_count 则累计全部错误，便于区分偶发错误与总线系统性错误。
                    if (read_sample_protocol_error |
                        (read_sample_resp != 2'b00) |
                        (read_sample_actual != read_sample_expected)) begin
                            error_count <= error_count + 32'd1;
                            fail <= 1'b1;
                            if (error_count == 32'd0) begin
                                first_error_addr <= read_sample_addr;
                                first_expected_data <= read_sample_expected;
                                first_actual_data <= read_sample_actual;
                            end
                    end
                    // burst 末拍完成后才增加读事务计数并换 burst/phase；非末拍重新拉高 RREADY。
                    if (read_sample_is_last) begin
                            read_transaction_count <= read_transaction_count + 32'd1;
                            if (current_burst_is_last) begin
                                if (phase_is_final) begin
                                    if ((active_mode == 3'd7) & active_repeat) begin
                                        phase <= 9'd0;
                                        bist_curr_st <= BIST_PREPARE;
                                    end else begin
                                        done <= 1'b1;
                                        pass <= ~(fail |
                                            read_sample_protocol_error |
                                            (read_sample_resp != 2'b00) |
                                            (read_sample_actual != read_sample_expected));
                                        busy <= 1'b0;
                                        bist_curr_st <= BIST_DONE;
                                    end
                                end else begin
                                    phase <= phase + 9'd1;
                                    bist_curr_st <= BIST_PREPARE;
                                end
                            end else begin
                                burst_index <= burst_index + 32'd1;
                                current_burst_is_last <= is_phase_burst_last(
                                    burst_index + 32'd1,
                                    burst_count
                                );
                                if (active_mode == 3'd3) begin
                                    current_addr_ext <= sparse_address(burst_index + 32'd1);
                                end else if (active_mode == 3'd4) begin
                                    current_addr_ext <= boundary_address(burst_index + 32'd1);
                                end else if (direction_reverse) begin
                                    current_addr_ext <= current_addr_ext - BURST_BYTES;
                                end else begin
                                    current_addr_ext <= current_addr_ext + BURST_BYTES;
                                end
                                m_axi_araddr <= active_burst_address(
                                    active_mode,
                                    burst_index + 32'd1,
                                    direction_reverse ?
                                        current_addr_ext - BURST_BYTES :
                                        current_addr_ext + BURST_BYTES
                                );
                                m_axi_arvalid <= 1'b1;
                                if (burst_count > 32'd1) begin
                                    progress <= progress_value(
                                        active_mode,
                                        direction_reverse,
                                        burst_index + 32'd1,
                                        current_addr_ext
                                    );
                                end
                                bist_curr_st <= BIST_READ_ADDR;
                            end
                        end else begin
                            beat_index <= beat_index + 5'd1;
                            m_axi_rready <= 1'b1;
                            bist_curr_st <= BIST_READ_DATA;
                        end
                end

                BIST_HOLD: begin
                    // 保持期不发 AXI 事务；计数到期后进入下一 phase 回读原测试区。
                    if (hold_count >= HOLD_CYCLES) begin
                        bist_curr_st <= BIST_PREPARE;
                    end else begin
                        hold_count <= hold_count + 64'd1;
                    end
                end

                BIST_DONE: begin
                    // 结果保持态，等待 restart；pass/fail/首错现场均保持稳定供 VIO 读取。
                    done <= 1'b1;
                    busy <= 1'b0;
                end

                default: begin
                    // 非法状态安全回到 IDLE，并撤销 busy；复位值已保证 AXI valid 为0。
                    bist_curr_st <= BIST_IDLE;
                    busy <= 1'b0;
                end
            endcase
        end
    end
end

endmodule
