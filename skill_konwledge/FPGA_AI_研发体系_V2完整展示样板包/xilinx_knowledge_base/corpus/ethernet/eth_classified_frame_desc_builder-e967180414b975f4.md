# eth_classified_frame_desc_builder

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream_AXI4-Full DMA Writer\Packet Stream_AXI4-Full DMA Writer\eth_classified_frame_desc_builder.v`
- SHA-256: `e967180414b975f48583a6801bb7feb1902134d0fd901cc783bf14a636ba2b47`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// =============================================================================
// 模块名称：eth_classified_frame_desc_builder
// 功能说明：按照固定字段格式生成 64 位软件可见输出描述符，供报文数据写入成功后写入描述符区。
// 层级关系：输入来自 S2MM 控制器锁存的当前帧上下文，输出送回控制器的描述符数据通道。
// 本模块是无时钟、无复位的纯组合拼接逻辑；描述符何时写入内存由 S2MM 状态机决定。
// 写入顺序上，只有帧数据命令、数据流和数据状态均成功后，控制器才发送该描述符。
// =============================================================================
module eth_classified_frame_desc_builder (
    input  wire [15:0]                  frame_len,
    input  wire [1:0]                   frame_mac_class,
    input  wire [31:0]                  frame_timestamp,
    output wire [63:0]                  desc_payload
);

    // 软件可见描述符固定占 8 字节，位域如下：
    // [63]    ：有效标志，当前生成值固定为 1
    // [62:61] ：MAC 分类，00=单播，01=广播，10=组播，11=非法/保留
    // [60:48] ：保留字段
    // [47:32] ：帧长度
    // [31:0]  ：时间戳
    // 拼接不改变时间戳和长度的位序，保留字段固定清零。
    assign desc_payload = {1'b1, frame_mac_class, 13'd0,
                           frame_len, frame_timestamp};

endmodule
```
