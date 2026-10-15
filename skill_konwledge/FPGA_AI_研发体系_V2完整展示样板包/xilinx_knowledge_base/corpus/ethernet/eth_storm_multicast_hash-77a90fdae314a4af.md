# eth_storm_multicast_hash

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_multicast_hash.v`
- SHA-256: `77a90fdae314a4aff5e35f82b8555bdda1d106b7e61eaf160da33763cf4e7bc9`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// Module : eth_storm_multicast_hash
// 位置   : GMII 接收主状态机内部，为目的 MAC 过滤提供可编程组播 Hash 命中表。
// 功能   : 将一个 48 bit 组播 MAC 按网络字节顺序送入 CRC32，取最终结果[31:26]
//          作为 64 项索引并将对应表位置 1。Hash 表由两个 32 bit 寄存器组成，
//          多次配置会累积置位；cfg_multicast_hash_clear 一次清空全部 64 bit。
// 时序   : 配置状态机工作在 gmii_rx_clk 域，rst 为高有效异步复位。
// 握手   : 仅在 CFG_IDLE 检测 cfg_multicast_mac_valid 的上升沿并锁存 MAC；
//          valid 需要先回到 0 才能触发下一次写入。查表端为组合读、无等待周期。
// =============================================================================

module eth_storm_multicast_hash (
    // 接收处理时钟与高有效异步复位
    input  wire        gmii_rx_clk,
    input  wire        rst,

    // 软件配置入口：valid 上升沿提交一个 MAC，clear 的优先级最高
    input  wire [47:0] cfg_multicast_mac,
    input  wire        cfg_multicast_mac_valid,
    input  wire        cfg_multicast_hash_clear,

    // 接收帧目的 MAC 的 CRC 高 6 bit 索引及组合命中结果
    input  wire [5:0]  lookup_hash_index,
    output wire        lookup_hash_hit
);

    localparam [1:0] CFG_IDLE = 2'd0;
    localparam [1:0] CFG_FEED = 2'd1;
    localparam [1:0] CFG_SET  = 2'd2;

    reg [1:0]  cfg_state;
    reg [47:0] cfg_mac_latched;
    reg [2:0]  cfg_byte_index;
    reg        cfg_valid_d;
    reg [31:0] multicast_hash_table_lo;
    reg [31:0] multicast_hash_table_hi;

    wire       cfg_valid_rise;
    wire [7:0] cfg_crc_data;
    wire       cfg_crc_init;
    wire       cfg_crc_en;
    wire [31:0] cfg_crc_result;

    assign cfg_valid_rise = cfg_multicast_mac_valid && !cfg_valid_d;

    // 按 MAC[47:40] 到 MAC[7:0] 的顺序，每拍向 CRC 单元送入一个字节。
    assign cfg_crc_data = (cfg_byte_index == 3'd0) ? cfg_mac_latched[47:40] :
                          (cfg_byte_index == 3'd1) ? cfg_mac_latched[39:32] :
                          (cfg_byte_index == 3'd2) ? cfg_mac_latched[31:24] :
                          (cfg_byte_index == 3'd3) ? cfg_mac_latched[23:16] :
                          (cfg_byte_index == 3'd4) ? cfg_mac_latched[15:8]  :
                                                   cfg_mac_latched[7:0];

    // 接受新 MAC 的同一上升沿初始化 CRC；随后 CFG_FEED 连续计算 6 个字节。
    assign cfg_crc_init = (cfg_state == CFG_IDLE) && cfg_valid_rise &&
                          !cfg_multicast_hash_clear;
    assign cfg_crc_en   = (cfg_state == CFG_FEED);

    // crc[31] 选择高/低 32 bit，crc[30:26] 选择其中一位。
    assign lookup_hash_hit = lookup_hash_index[5] ?
                             multicast_hash_table_hi[lookup_hash_index[4:0]] :
                             multicast_hash_table_lo[lookup_hash_index[4:0]];

    crc32_d8 u_cfg_multicast_crc32_d8 (
        .clk        (gmii_rx_clk  ),
        .rst_p      (rst          ),
        .data       (cfg_crc_data ),
        .crc_init   (cfg_crc_init ),
        .crc_en     (cfg_crc_en   ),
        .crc_result (cfg_crc_result)
    );

    always @(posedge gmii_rx_clk or posedge rst) begin
        if (rst) begin
            cfg_state            <= CFG_IDLE;
            cfg_mac_latched      <= 48'd0;
            cfg_byte_index       <= 3'd0;
            cfg_valid_d          <= 1'b0;
            multicast_hash_table_lo <= 32'd0;
            multicast_hash_table_hi <= 32'd0;
        end else begin
            cfg_valid_d <= cfg_multicast_mac_valid;

            if (cfg_multicast_hash_clear) begin
                // 清表同时终止尚未完成的配置过程。
                cfg_state            <= CFG_IDLE;
                cfg_mac_latched      <= 48'd0;
                cfg_byte_index       <= 3'd0;
                multicast_hash_table_lo <= 32'd0;
                multicast_hash_table_hi <= 32'd0;
            end else begin
                case (cfg_state)
                    CFG_IDLE: begin
                        // 空闲态只接受 valid 的新上升沿，MAC 在此完整锁存。
                        cfg_byte_index <= 3'd0;
                        if (cfg_valid_rise) begin
                            cfg_mac_latched <= cfg_multicast_mac;
                            cfg_state       <= CFG_FEED;
                        end
                    end

                    CFG_FEED: begin
                        // crc_en 在该状态恒为 1；索引 0~5 各对应一个 MAC 字节。
                        if (cfg_byte_index == 3'd5) begin
                            cfg_byte_index <= 3'd0;
                            cfg_state      <= CFG_SET;
                        end else begin
                            cfg_byte_index <= cfg_byte_index + 3'd1;
                        end
                    end

                    CFG_SET: begin
                        // 最后一个字节已在前一拍计入，此处用最终 CRC 累积置位。
                        if (cfg_crc_result[31])
                            multicast_hash_table_hi[cfg_crc_result[30:26]] <= 1'b1;
                        else
                            multicast_hash_table_lo[cfg_crc_result[30:26]] <= 1'b1;
                        cfg_state <= CFG_IDLE;
                    end

                    default: begin
                        cfg_state <= CFG_IDLE;
                    end
                endcase
            end
        end
    end

endmodule
```
