`timescale 1ps / 1ps

// PCIe Root Port CQ 主机内存接收模型。
//
// Xilinx 官方 Root Port example 的 DATA_STORE 只给 Host 发起的描述符读取、
// H2C 和 BAR 写事务提供数据，并不会被 Endpoint 发来的 posted Memory Write
// 自动更新。C2H 数据在 RP 侧表现为 m_axis_cq_* 上的 Memory Write Request。
// 本模块按官方 256-bit、DWORD-aligned CQ 描述符格式提取地址和 payload，
// 建立大仿真专用的轻量 Host memory sink；不修改官方 RP/TPI 主逻辑。
// 输入：RP m_axis_cq_* 握手流和 scoreboard 清除命令。
// 输出：独立 HOST_MEMORY、写入字节/包/地址计数和协议错误。
// 失败定位：C2H descriptor/status 正常但目标数据不变时先查 CQ tvalid/tready；
// 包计数有而字节少查 tkeep/byte-enable；ignored bytes 查主机地址窗口。
module pcie_cq_host_memory_monitor #(
    parameter integer HOST_MEMORY_BYTES = 4096
) (
    input              user_clk,
    input              user_reset,
    input              clear_capture,
    input      [255:0] cq_tdata,
    input       [84:0] cq_tuser,
    input        [7:0] cq_tkeep,
    input              cq_tlast,
    input              cq_tvalid,
    input              cq_tready,
    output reg  [31:0] host_write_bytes,
    output reg  [31:0] ignored_write_bytes,
    output reg  [31:0] memory_write_packets,
    output reg  [31:0] protocol_errors,
    output reg  [63:0] last_write_address
);
    // ---------- 语义段 1：可由 scoreboard 逐字节访问的 Host 内存 ----------
    // 输入：CQ payload 写入；输出：HOST_MEMORY 字节数组。
    // 作用：代替官方 DATA_STORE 不具备的 C2H posted-write 落点。
    // 失败定位：只比较有效地址内字节，越界写计入 ignored/protocol error。
    reg [7:0] HOST_MEMORY [0:HOST_MEMORY_BYTES-1];

    // ---------- 语义段 2：跨 CQ beat 保存当前 Memory Write 上下文 ----------
    // 输入：首 beat descriptor；输出：活动标志、下一地址、期望/已收 payload。
    // 失败定位：多 beat 地址错位时检查本上下文是否在 tlast 正确关闭。
    reg        memory_write_active;
    reg [63:0] next_payload_address;
    reg [31:0] expected_payload_bytes;
    reg [31:0] packet_payload_bytes;

    integer lane;
    integer byte_lane;
    integer accepted_this_beat;
    integer ignored_this_beat;
    reg [63:0] address_work;
    reg [31:0] payload_bytes_work;
    reg [31:0] expected_bytes_work;

    initial begin
        host_write_bytes      = 32'd0;
        ignored_write_bytes   = 32'd0;
        memory_write_packets  = 32'd0;
        protocol_errors       = 32'd0;
        last_write_address    = 64'd0;
        memory_write_active   = 1'b0;
        next_payload_address  = 64'd0;
        expected_payload_bytes = 32'd0;
        packet_payload_bytes  = 32'd0;
    end

    // ---------- 语义段 3：解码 CQ Memory Write 并按地址落入 Host sink ----------
    // 输入：每个 tvalid&&tready CQ beat；输出：HOST_MEMORY 和事务统计。
    // 失败定位：非 Memory Write、长度/keep 不一致或提前/缺失 tlast 计协议错误。
    // CQ SOP 位为 tuser[40]；请求类型 tdata[78:75]=4'b0001 表示 Memory Write。
    // 第一个 256-bit beat 的低 128 bit 是 CQ descriptor，payload 从 DW4 开始；
    // 后续 beat 的 payload 从 DW0 开始。tkeep 每一位对应一个有效 DWORD。

    always @(posedge user_clk) begin
        if (user_reset) begin
            host_write_bytes       <= 32'd0;
            ignored_write_bytes    <= 32'd0;
            memory_write_packets   <= 32'd0;
            protocol_errors        <= 32'd0;
            last_write_address     <= 64'd0;
            memory_write_active    <= 1'b0;
            next_payload_address   <= 64'd0;
            expected_payload_bytes <= 32'd0;
            packet_payload_bytes   <= 32'd0;
        end else if (clear_capture) begin
            host_write_bytes       <= 32'd0;
            ignored_write_bytes    <= 32'd0;
            memory_write_packets   <= 32'd0;
            protocol_errors        <= 32'd0;
            last_write_address     <= 64'd0;
            memory_write_active    <= 1'b0;
            next_payload_address   <= 64'd0;
            expected_payload_bytes <= 32'd0;
            packet_payload_bytes   <= 32'd0;
        end else if (cq_tvalid && cq_tready) begin
            accepted_this_beat = 0;
            ignored_this_beat  = 0;

            if (cq_tuser[40]) begin
                if (memory_write_active) begin
                    protocol_errors <= protocol_errors + 1'b1;
                    $error("RTDS_CQ_HOST_PROTOCOL: 新 SOP 到达时上一 Memory Write 尚未结束");
                end

                if (cq_tdata[78:75] == 4'b0001) begin
                    address_work = {cq_tdata[63:2], 2'b00};
                    // PCIe Length=0 编码表示 1024 DW；本用例为 128 DW/512 B。
                    expected_bytes_work = (cq_tdata[74:64] == 11'd0) ?
                                          32'd4096 : (cq_tdata[74:64] * 4);
                    payload_bytes_work = 0;
                    memory_write_packets <= memory_write_packets + 1'b1;

                    for (lane = 4; lane < 8; lane = lane + 1) begin
                        if (cq_tkeep[lane]) begin
                            for (byte_lane = 0; byte_lane < 4; byte_lane = byte_lane + 1) begin
                                if (address_work < HOST_MEMORY_BYTES) begin
                                    HOST_MEMORY[address_work] <=
                                        cq_tdata[lane*32 + byte_lane*8 +: 8];
                                    accepted_this_beat = accepted_this_beat + 1;
                                end else begin
                                    // MSI 等合法 posted write 位于 Host 数据窗口之外，单独计数但不报错。
                                    ignored_this_beat = ignored_this_beat + 1;
                                end
                                last_write_address = address_work;
                                address_work = address_work + 1'b1;
                                payload_bytes_work = payload_bytes_work + 1'b1;
                            end
                        end
                    end

                    next_payload_address   <= address_work;
                    expected_payload_bytes <= expected_bytes_work;
                    packet_payload_bytes   <= payload_bytes_work;
                    memory_write_active    <= !cq_tlast;
                    if (cq_tlast && payload_bytes_work != expected_bytes_work) begin
                        protocol_errors <= protocol_errors + 1'b1;
                        $error("RTDS_CQ_HOST_LENGTH: expected=%0d captured=%0d",
                               expected_bytes_work, payload_bytes_work);
                    end
                end else begin
                    memory_write_active <= 1'b0;
                end
            end else if (memory_write_active) begin
                address_work = next_payload_address;
                payload_bytes_work = packet_payload_bytes;
                for (lane = 0; lane < 8; lane = lane + 1) begin
                    if (cq_tkeep[lane]) begin
                        for (byte_lane = 0; byte_lane < 4; byte_lane = byte_lane + 1) begin
                            if (address_work < HOST_MEMORY_BYTES) begin
                                HOST_MEMORY[address_work] <=
                                    cq_tdata[lane*32 + byte_lane*8 +: 8];
                                accepted_this_beat = accepted_this_beat + 1;
                            end else begin
                                ignored_this_beat = ignored_this_beat + 1;
                            end
                            last_write_address = address_work;
                            address_work = address_work + 1'b1;
                            payload_bytes_work = payload_bytes_work + 1'b1;
                        end
                    end
                end
                next_payload_address <= address_work;
                packet_payload_bytes <= payload_bytes_work;
                if (cq_tlast) begin
                    memory_write_active <= 1'b0;
                    if (payload_bytes_work != expected_payload_bytes) begin
                        protocol_errors <= protocol_errors + 1'b1;
                        $error("RTDS_CQ_HOST_LENGTH: expected=%0d captured=%0d",
                               expected_payload_bytes, payload_bytes_work);
                    end
                end
            end

            host_write_bytes    <= host_write_bytes + accepted_this_beat;
            ignored_write_bytes <= ignored_write_bytes + ignored_this_beat;
        end
    end
endmodule
