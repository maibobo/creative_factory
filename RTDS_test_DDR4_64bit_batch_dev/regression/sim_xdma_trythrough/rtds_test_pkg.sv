// 快速前仿参考模式：tag区分方向，frame_index和beat_index检测丢帧/重拍/错序。
// 本包只定义验证数据，不定义 DUT 控制状态；下行每帧2个64bit拍；上行每拍只保留低32bit。
`timescale 1ns / 1ps
package rtds_test_pkg;
    function automatic logic [63:0] make_pattern(
        input logic [7:0] tag,
        input integer frame_index,
        input integer beat_index
    );
        make_pattern = {tag, 8'hA5, frame_index[15:0],
                        beat_index[15:0], 16'h5AA5};
    endfunction
endpackage
