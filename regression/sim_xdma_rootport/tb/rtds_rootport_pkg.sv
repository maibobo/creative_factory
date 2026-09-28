`timescale 1ns / 1ps

// 大仿真公共常量和参考数据函数。
// 输入：pattern_byte 的 seed/index；输出：期望字节。
// 作用：集中定义 Host descriptor/data 和卡端 RX/TX 地址，避免用例散落魔数。
// 失败定位：多个方向在同一字节索引同时 mismatch 时先核对本包常量/模式，
// 单一路径 mismatch 则继续查对应数据通路。
package rtds_rootport_pkg;
    // ---------- 语义段 1：验证地址与固定帧长 ----------
    // 输入：无；输出：供 board/scoreboard 使用的唯一地址约定。
    localparam integer FRAME_BYTES       = 16;
    localparam integer HOST_H2C_DESC     = 16'h0100;
    localparam integer HOST_C2H_DESC     = 16'h0300;
    localparam integer HOST_SOURCE       = 16'h0400;
    localparam integer HOST_DESTINATION  = 16'h0800;
    localparam integer CARD_TX_BASE      = 32'h0000_8000;
    localparam integer CARD_RX_BASE      = 32'h0010_0000;

    // ---------- 语义段 2：确定性参考数据 ----------
    // 输入：seed、字节序号；输出：可复算字节，不依赖额外内存模型。
    // 失败定位：首个 mismatch 的 index 可直接映射到 64-bit beat 和 byte lane。
    // 每个字节都与序号相关，能同时发现丢拍、重拍、错序和端序错误。
    function automatic [7:0] pattern_byte(input [7:0] seed, input integer index);
        pattern_byte = seed + (index * 8'd37) + (index >> 3);
    endfunction
endpackage
