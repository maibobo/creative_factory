// 快速前仿参考模式：tag区分方向，frame_index和beat_index检测丢帧/重拍/错序。
// 本包只定义验证数据，不定义 DUT 控制状态；下行每帧2个64bit拍；上行每拍只保留低32bit。
`timescale 1ns / 1ps
package rtds_test_pkg;
    function automatic logic [63:0] phase2_mask;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        integer seed_value;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        logic[31:0] a,b;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        if(!$value$plusargs("SEED=%d",seed_value)) seed_value=20261011;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        a=32'(seed_value)^32'h6d2b79f5;a=a^(a<<13);a=a^(a>>17);a=a^(a<<5);   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        b=a*32'h9e3779b9;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
        return {a,b}&64'hffffffffffff0000;   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    endfunction   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    function automatic logic [63:0] make_pattern(
        input logic [7:0] tag,
        input integer frame_index,
        input integer beat_index
    );
        make_pattern = {tag, 8'hA5, frame_index[15:0],
                        beat_index[15:0], 16'h5AA5} ^ phase2_mask();   // 2026-10-11：随机种子回归：改变激励时序或数据，保留原检查判据
    endfunction
endpackage
