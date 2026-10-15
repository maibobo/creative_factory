# eth_classified_frame_arbiter

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream_AXI4-Full DMA Writer\Packet Stream_AXI4-Full DMA Writer\eth_classified_frame_arbiter.v`
- SHA-256: `39207cf08d3c7e08de27d4ba240683d5e189330ab495b09eb00d909e7506139f`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// =============================================================================
// 模块名称：eth_classified_frame_arbiter
// 功能说明：
//   1. 对 SV、GOOSE 和其他类型帧描述符进行固定优先级仲裁，优先级为 SV > GOOSE > 其他；
//   2. 从选中的描述符中解析帧长度、MAC 分类和时间戳；
//   3. 仅在 frame_valid/frame_ready 握手成功时读出对应描述符 FIFO，避免提前弹出数据。
//
// 层级关系与接口约定：
//   - 位于三个分类描述符 FIFO 与 S2MM 控制器之间，不搬运帧字节；
//   - 描述符 FIFO 按 FWFT（首字直通）方式使用，empty=0 时 dout 已经是当前队首描述符；
//   - ring_full 会屏蔽对应通道请求，使已满通道保留队首描述符，其他未满通道仍可参与仲裁；
//   - 本模块为纯组合仲裁，选中结果直到真正握手前不会在模块内部锁存，握手时刻的
//     frame_channel/frame_desc 才是本次被控制器接收并从 FIFO 弹出的帧信息。
//
// 时钟与复位：当前实现不含时序状态，clk/rst 只作为预留端口接入 unused_clk_rst。
// =============================================================================
module eth_classified_frame_arbiter #(
    parameter integer DESC_W = 53
)(
    input  wire                      clk,
    input  wire                      rst,

    input  wire                      goose_ring_full,
    input  wire                      sv_ring_full,
    input  wire                      other_ring_full,

    input  wire [DESC_W-1:0]         goose_desc_dout,
    input  wire                      goose_desc_empty,
    output wire                      goose_desc_rd_en,

    input  wire [DESC_W-1:0]         sv_desc_dout,
    input  wire                      sv_desc_empty,
    output wire                      sv_desc_rd_en,

    input  wire [DESC_W-1:0]         other_desc_dout,
    input  wire                      other_desc_empty,
    output wire                      other_desc_rd_en,

    output wire                      frame_valid,
    input  wire                      frame_ready,
    output wire [1:0]                frame_channel,
    output wire [15:0]               frame_len,
    output wire [1:0]                frame_mac_class,
    output wire [31:0]               frame_timestamp,
    output wire [DESC_W-1:0]         frame_desc
);

    localparam [1:0] CH_NONE  = 2'd0;
    localparam [1:0] CH_GOOSE = 2'd1;
    localparam [1:0] CH_SV    = 2'd2;
    localparam [1:0] CH_OTHER = 2'd3;

    // 输入为分类模块产生的 53 位内部描述符；保留位 [33:32] 不参与本级仲裁和字段输出。
    // 输入描述符字段定义沿用原设计：
    // [52]    ：描述符有效标志
    // [51:36] ：帧长度
    // [35:34] ：MAC 分类
    // [31:0]  ：时间戳
    wire goose_req = (!goose_ring_full) && (!goose_desc_empty) && goose_desc_dout[52];
    wire sv_req    = (!sv_ring_full)    && (!sv_desc_empty)    && sv_desc_dout[52];
    wire other_req = (!other_ring_full) && (!other_desc_empty) && other_desc_dout[52];

    // 固定优先级由多路选择顺序直接实现：同一周期多个请求有效时只选择最高优先级通道。
    assign frame_channel = sv_req    ? CH_SV    :
                           goose_req ? CH_GOOSE :
                           other_req ? CH_OTHER : CH_NONE;

    assign frame_desc = sv_req    ? sv_desc_dout    :
                        goose_req ? goose_desc_dout :
                        other_req ? other_desc_dout : {DESC_W{1'b0}};

    assign frame_valid     = (frame_channel != CH_NONE);
    assign frame_len       = frame_desc[51:36];
    assign frame_timestamp = frame_desc[31:0];
    assign frame_mac_class = frame_desc[35:34];

    // 三个 rd_en 互斥，并且只在下游接收本次仲裁结果时脉冲一个周期。
    assign goose_desc_rd_en = frame_valid && frame_ready && (frame_channel == CH_GOOSE);
    assign sv_desc_rd_en    = frame_valid && frame_ready && (frame_channel == CH_SV);
    assign other_desc_rd_en = frame_valid && frame_ready && (frame_channel == CH_OTHER);

    // 当前仲裁逻辑为组合逻辑，保留时钟和复位端口，便于后续升级为寄存器化或轮询仲裁实现。
    wire unused_clk_rst = clk ^ rst;

endmodule
```
