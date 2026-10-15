# eth_classified_frame_ring_manager

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream_AXI4-Full DMA Writer\Packet Stream_AXI4-Full DMA Writer\eth_classified_frame_ring_manager.v`
- SHA-256: `453ac88e9d56cbc62582e83fef87c56a9196168a87395eaf8845735d0cadfcce`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// =============================================================================
// 模块名称：eth_classified_frame_ring_manager
// 功能说明：管理三个分类通道的环形缓冲区写端状态。
//   1. 维护生产者写指针并判断环形缓冲区是否已满；
//   2. 为待写帧分配一个槽位，并计算数据区和描述符区地址；
//   3. 每次仅保留一个未决槽位，写入成功时提交写指针，失败时中止本次分配。
//
// 层级关系与指针约定：
//   - 位于 S2MM 控制器与软件/寄存器侧读指针之间，三个分类通道各自拥有独立环；
//   - 写指针由本模块产生，读指针由外部消费者提供；[30:0] 为槽位索引，[31] 为回绕位；
//   - 索引相等且回绕位不同表示“满”，写指针只有在 commit_valid 时才向前推进；
//   - alloc 只做预留，abort_valid 释放未决预留但不改变写指针，因而软件只会看到已提交槽位。
//
// 地址布局：每个槽位的数据地址为 data_base + index * FRAME_SLOT_BYTES，描述符地址为
// desc_base + index * DESC_BYTES；回绕位不参与地址计算。全部状态均在 clk 上升沿更新，rst 高有效。
// =============================================================================
module eth_classified_frame_ring_manager #(
    parameter integer CHANNEL_DEPTH     = 32,
    parameter integer FRAME_SLOT_BYTES  = 1536,
    parameter integer DESC_BYTES        = 8
)(
    input  wire                         clk,
    input  wire                         rst,

    input  wire [31:0]                  cfg_goose_data_base_addr,
    input  wire [31:0]                  cfg_sv_data_base_addr,
    input  wire [31:0]                  cfg_other_data_base_addr,
    input  wire [31:0]                  cfg_goose_desc_base_addr,
    input  wire [31:0]                  cfg_sv_desc_base_addr,
    input  wire [31:0]                  cfg_other_desc_base_addr,
    input  wire [31:0]                  cfg_ring_depth,

    input  wire [31:0]                  goose_rd_ptr,
    input  wire [31:0]                  sv_rd_ptr,
    input  wire [31:0]                  other_rd_ptr,
    output wire [31:0]                  goose_wr_ptr,
    output wire [31:0]                  sv_wr_ptr,
    output wire [31:0]                  other_wr_ptr,
    output wire                         goose_ring_full,
    output wire                         sv_ring_full,
    output wire                         other_ring_full,

    input  wire                         alloc_valid,
    output wire                         alloc_ready,
    input  wire [1:0]                   alloc_channel,
    output wire [31:0]                  alloc_data_addr,
    output wire [31:0]                  alloc_desc_addr,
    output wire [31:0]                  alloc_entry_index,

    input  wire                         commit_valid,
    input  wire                         abort_valid
);

    localparam [1:0] CH_NONE  = 2'd0;
    localparam [1:0] CH_GOOSE = 2'd1;
    localparam [1:0] CH_SV    = 2'd2;
    localparam [1:0] CH_OTHER = 2'd3;

    localparam [30:0] CHANNEL_DEPTH_DEFAULT = CHANNEL_DEPTH;
    localparam [31:0] FRAME_SLOT_BYTES_U32  = FRAME_SLOT_BYTES;
    localparam [31:0] DESC_BYTES_U32        = DESC_BYTES;

    reg [31:0] goose_wr_ptr_r;
    reg [31:0] sv_wr_ptr_r;
    reg [31:0] other_wr_ptr_r;

    // 环满标志采用寄存器输出，在指针/满状态计算与下游仲裁、描述符 FIFO 读使能之间形成时序边界。
    reg        goose_ring_full_r;
    reg        sv_ring_full_r;
    reg        other_ring_full_r;

    // 同一时刻只允许一个 DMA 帧持有预留槽位；active_* 保存该事务的通道和申请时环深度。
    reg        slot_active;
    reg [1:0]  active_channel;
    reg [30:0] active_depth;

    // 配置值为 0 时使用参数 CHANNEL_DEPTH；一次申请成功后将有效深度锁存在 active_depth，
    // 保证事务进行期间外部配置变化不会改变该次提交的回绕位置。
    wire [30:0] cfg_ring_depth_raw = cfg_ring_depth[30:0];
    wire [30:0] cfg_ring_depth_eff = (cfg_ring_depth_raw == 31'd0) ?
                                       CHANNEL_DEPTH_DEFAULT : cfg_ring_depth_raw;

    assign goose_wr_ptr = goose_wr_ptr_r;
    assign sv_wr_ptr    = sv_wr_ptr_r;
    assign other_wr_ptr = other_wr_ptr_r;

    assign goose_ring_full = goose_ring_full_r;
    assign sv_ring_full    = sv_ring_full_r;
    assign other_ring_full = other_ring_full_r;

    // ---------------------------------------------------------------------
    // 通道选择采用显式多路选择逻辑。
    // 不将模块级信号依赖隐藏在函数中，使仿真和综合能够直接感知写指针、满标志和基地址变化；
    // 即使连续帧的 alloc_channel 不变，也能正确更新对应选择结果。
    // ---------------------------------------------------------------------
    wire alloc_channel_full;
    wire [31:0] selected_data_base;
    wire [31:0] selected_desc_base;

    assign alloc_channel_full =
        (alloc_channel == CH_GOOSE) ? goose_ring_full_r :
        (alloc_channel == CH_SV)    ? sv_ring_full_r    :
        (alloc_channel == CH_OTHER) ? other_ring_full_r :
                                      1'b1;

    assign alloc_entry_index =
        (alloc_channel == CH_GOOSE) ? {1'b0, goose_wr_ptr_r[30:0]} :
        (alloc_channel == CH_SV)    ? {1'b0, sv_wr_ptr_r[30:0]}    :
        (alloc_channel == CH_OTHER) ? {1'b0, other_wr_ptr_r[30:0]} :
                                      32'd0;

    assign selected_data_base =
        (alloc_channel == CH_GOOSE) ? cfg_goose_data_base_addr :
        (alloc_channel == CH_SV)    ? cfg_sv_data_base_addr    :
        (alloc_channel == CH_OTHER) ? cfg_other_data_base_addr :
                                      32'd0;

    assign selected_desc_base =
        (alloc_channel == CH_GOOSE) ? cfg_goose_desc_base_addr :
        (alloc_channel == CH_SV)    ? cfg_sv_desc_base_addr    :
        (alloc_channel == CH_OTHER) ? cfg_other_desc_base_addr :
                                      32'd0;

    function [31:0] ring_ptr_next;
        input [31:0] ptr;
        input [30:0] depth;
        reg   [30:0] depth_minus_one;
        begin
            // 到达最后一个有效索引后回到 0 并翻转 wrap；深度为 0 已在上游替换为默认值。
            if (depth <= 31'd1) begin
                ring_ptr_next = {~ptr[31], 31'd0};
            end else begin
                depth_minus_one = depth - 31'd1;
                if (ptr[30:0] >= depth_minus_one)
                    ring_ptr_next = {~ptr[31], 31'd0};
                else
                    ring_ptr_next = {ptr[31], ptr[30:0] + 31'd1};
            end
        end
    endfunction

    // ---------------------------------------------------------------------
    // 环满标志下一状态计算。
    // 当某通道在本周期提交槽位时，使用提交后的写指针计算满状态，避免寄存器化满标志比写指针慢一拍，
    // 从而防止“本次提交刚好填满环形缓冲区”时仍额外接受一次分配。
    // 未提交的通道使用当前写指针；读指针变化会在下一上升沿反映到寄存器化满标志中，
    // 最多只会让已满缓冲区晚一拍重新开放，不会引起写溢出。
    // ---------------------------------------------------------------------
    // 时序控制中 abort_valid 优先于 commit_valid，因此中止请求也必须禁止使用推测的提交后写指针。
    wire goose_commit = commit_valid && !abort_valid && slot_active &&
                        (active_channel == CH_GOOSE);
    wire sv_commit    = commit_valid && !abort_valid && slot_active &&
                        (active_channel == CH_SV);
    wire other_commit = commit_valid && !abort_valid && slot_active &&
                        (active_channel == CH_OTHER);

    wire [31:0] goose_wr_ptr_full_next = goose_commit ?
                                          ring_ptr_next(goose_wr_ptr_r, active_depth) :
                                          goose_wr_ptr_r;
    wire [31:0] sv_wr_ptr_full_next    = sv_commit ?
                                          ring_ptr_next(sv_wr_ptr_r, active_depth) :
                                          sv_wr_ptr_r;
    wire [31:0] other_wr_ptr_full_next = other_commit ?
                                          ring_ptr_next(other_wr_ptr_r, active_depth) :
                                          other_wr_ptr_r;

    wire goose_ring_full_next =
        (goose_wr_ptr_full_next[30:0] == goose_rd_ptr[30:0]) &&
        (goose_wr_ptr_full_next[31]   != goose_rd_ptr[31]);

    wire sv_ring_full_next =
        (sv_wr_ptr_full_next[30:0] == sv_rd_ptr[30:0]) &&
        (sv_wr_ptr_full_next[31]   != sv_rd_ptr[31]);

    wire other_ring_full_next =
        (other_wr_ptr_full_next[30:0] == other_rd_ptr[30:0]) &&
        (other_wr_ptr_full_next[31]   != other_rd_ptr[31]);

    // 先以 64 位计算偏移，再取低 32 位与 32 位基地址相加；输出对应当前 alloc_channel 的
    // 队尾槽位，控制器会在 alloc_valid/alloc_ready 同拍将这两个地址锁存。
    wire [63:0] data_offset = {32'd0, alloc_entry_index} *
                              {32'd0, FRAME_SLOT_BYTES_U32};
    wire [63:0] desc_offset = {32'd0, alloc_entry_index} *
                              {32'd0, DESC_BYTES_U32};

    assign alloc_data_addr = selected_data_base + data_offset[31:0];
    assign alloc_desc_addr = selected_desc_base + desc_offset[31:0];
    // 无未决槽位且所选通道未满时才接受新申请；CH_NONE 被视为不可分配。
    assign alloc_ready     = (!slot_active) && (!alloc_channel_full);

    always @(posedge clk) begin
        if (rst) begin
            goose_wr_ptr_r     <= 32'd0;
            sv_wr_ptr_r        <= 32'd0;
            other_wr_ptr_r     <= 32'd0;
            goose_ring_full_r  <= 1'b0;
            sv_ring_full_r     <= 1'b0;
            other_ring_full_r  <= 1'b0;
            slot_active        <= 1'b0;
            active_channel <= CH_NONE;
            active_depth   <= CHANNEL_DEPTH_DEFAULT;
        end else begin
            // 每周期更新环满寄存器；*_full_next 已包含本上升沿可能发生的提交影响。
            goose_ring_full_r <= goose_ring_full_next;
            sv_ring_full_r    <= sv_ring_full_next;
            other_ring_full_r <= other_ring_full_next;

            // 中止优先于提交：两者同拍出现时只释放预留，不推进任何通道的写指针。
            if (abort_valid) begin
                slot_active    <= 1'b0;
                active_channel <= CH_NONE;
            end else if (commit_valid && slot_active) begin
                case (active_channel)
                    CH_GOOSE: goose_wr_ptr_r <= goose_wr_ptr_full_next;
                    CH_SV:    sv_wr_ptr_r    <= sv_wr_ptr_full_next;
                    CH_OTHER: other_wr_ptr_r <= other_wr_ptr_full_next;
                    default:  ;
                endcase
                slot_active    <= 1'b0;
                active_channel <= CH_NONE;
            end else if (alloc_valid && alloc_ready) begin
                // 申请只锁定槽位归属；待帧数据与软件描述符均写入成功后才由 commit 生效。
                slot_active    <= 1'b1;
                active_channel <= alloc_channel;
                active_depth   <= cfg_ring_depth_eff;
            end
        end
    end

endmodule
```
