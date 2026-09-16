`timescale 1ns / 1ps

// 验证专用 AXI4 RAM 模型。
// AW 与 W 通道使用独立接收缓存，刻意允许 W 先于 AW；稀疏 tag 存储保留完整
// 32-bit 地址，能够同时验证低地址、高地址和末地址而不会因仿真 RAM 取模而混叠。
module AXI4_RAM_MODEL #(
    parameter int ENTRY_COUNT = 8192
) (
    input  logic        aclk,
    input  logic        aresetn,
    input  logic        stall_all,
    input  logic        inject_data_error,
    input  logic        inject_bresp_error,

    input  logic [3:0]  s_axi_awid,
    input  logic [31:0] s_axi_awaddr,
    input  logic [7:0]  s_axi_awlen,
    input  logic [2:0]  s_axi_awsize,
    input  logic [1:0]  s_axi_awburst,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [63:0] s_axi_wdata,
    input  logic [7:0]  s_axi_wstrb,
    input  logic        s_axi_wlast,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [3:0]  s_axi_bid,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [3:0]  s_axi_arid,
    input  logic [31:0] s_axi_araddr,
    input  logic [7:0]  s_axi_arlen,
    input  logic [2:0]  s_axi_arsize,
    input  logic [1:0]  s_axi_arburst,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [3:0]  s_axi_rid,
    output logic [63:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rlast,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    output logic        w_before_aw_seen,
    output logic        boundary_error,
    output logic [31:0] maximum_address_seen
);

logic [28:0] address_tags [0:ENTRY_COUNT-1];
logic [63:0] data_words [0:ENTRY_COUNT-1];
logic valid_words [0:ENTRY_COUNT-1];
logic [63:0] write_buffer_data [0:15];
logic [7:0] write_buffer_strobe [0:15];

logic [31:0] cycle_count;
logic aw_received;
logic [31:0] write_base_addr;
logic [3:0] write_id;
logic [4:0] write_beat_count;
logic write_data_complete;
logic read_active;
logic [31:0] read_base_addr;
logic [3:0] read_id;
logic [4:0] read_beat_index;
logic data_error_used;
logic bresp_error_used;

integer reset_index;
integer commit_index;
integer lookup_index;

function automatic int find_entry(input logic [28:0] word_tag);
    int search_index;
    begin
        find_entry = -1;
        for (search_index = 0; search_index < ENTRY_COUNT; search_index++) begin
            if (valid_words[search_index] && (address_tags[search_index] == word_tag)) begin
                find_entry = search_index;
            end
        end
    end
endfunction

function automatic int find_free_entry();
    int search_index;
    begin
        find_free_entry = -1;
        for (search_index = 0; search_index < ENTRY_COUNT; search_index++) begin
            if (!valid_words[search_index] && (find_free_entry < 0)) begin
                find_free_entry = search_index;
            end
        end
    end
endfunction

function automatic logic [63:0] read_memory(input logic [31:0] byte_addr);
    int entry_index;
    begin
        entry_index = find_entry(byte_addr[31:3]);
        if (entry_index >= 0) begin
            read_memory = data_words[entry_index];
        end else begin
            read_memory = 64'd0;
        end
    end
endfunction

function automatic logic [63:0] read_memory_with_error(input logic [31:0] byte_addr);
    begin
        read_memory_with_error = read_memory(byte_addr) ^ 64'h0000_0000_0000_0001;
    end
endfunction

task automatic write_memory(
    input logic [31:0] byte_addr,
    input logic [63:0] write_value,
    input logic [7:0] byte_enable
);
    int entry_index;
    int byte_index;
    begin
        entry_index = find_entry(byte_addr[31:3]);
        if (entry_index < 0) begin
            entry_index = find_free_entry();
            if (entry_index < 0) begin
                $fatal(1, "AXI RAM sparse storage exhausted");
            end
            valid_words[entry_index] = 1'b1;
            address_tags[entry_index] = byte_addr[31:3];
            data_words[entry_index] = 64'd0;
        end
        for (byte_index = 0; byte_index < 8; byte_index++) begin
            if (byte_enable[byte_index]) begin
                data_words[entry_index][(byte_index * 8) +: 8] =
                    write_value[(byte_index * 8) +: 8];
            end
        end
    end
endtask

// 模型状态组共享复位和协议阶段；集中更新用于在一个位置检查通道独立性、
// burst 边界、错误注入和稀疏存储提交，不属于可综合 RTL 文件表。
always_ff @(posedge aclk) begin : axi_ram_protocol
    if (!aresetn) begin
        cycle_count <= 32'd0;
        aw_received <= 1'b0;
        write_base_addr <= 32'd0;
        write_id <= 4'd0;
        write_beat_count <= 5'd0;
        write_data_complete <= 1'b0;
        read_active <= 1'b0;
        read_base_addr <= 32'd0;
        read_id <= 4'd0;
        read_beat_index <= 5'd0;
        data_error_used <= 1'b0;
        bresp_error_used <= 1'b0;
        s_axi_awready <= 1'b0;
        s_axi_wready <= 1'b0;
        s_axi_bid <= 4'd0;
        s_axi_bresp <= 2'b00;
        s_axi_bvalid <= 1'b0;
        s_axi_arready <= 1'b0;
        s_axi_rid <= 4'd0;
        s_axi_rdata <= 64'd0;
        s_axi_rresp <= 2'b00;
        s_axi_rlast <= 1'b0;
        s_axi_rvalid <= 1'b0;
        w_before_aw_seen <= 1'b0;
        boundary_error <= 1'b0;
        maximum_address_seen <= 32'd0;
        for (reset_index = 0; reset_index < ENTRY_COUNT; reset_index++) begin
            valid_words[reset_index] <= 1'b0;
            address_tags[reset_index] <= 29'd0;
            data_words[reset_index] <= 64'd0;
        end
    end else begin
        cycle_count <= cycle_count + 32'd1;
        s_axi_awready <= !stall_all && !aw_received && !s_axi_bvalid &&
                         (cycle_count[3:0] >= 4'd8) && (cycle_count[1:0] != 2'b00);
        s_axi_wready <= !stall_all && !write_data_complete && !s_axi_bvalid &&
                        ((cycle_count[1:0] != 2'b10) || (cycle_count[4:0] < 5'd8));
        s_axi_arready <= !stall_all && !read_active && !s_axi_rvalid &&
                         (cycle_count[1:0] != 2'b01);

        if (s_axi_awvalid && s_axi_awready) begin
            aw_received <= 1'b1;
            write_base_addr <= s_axi_awaddr;
            write_id <= s_axi_awid;
            if ((s_axi_awlen != 8'd15) || (s_axi_awsize != 3'd3) ||
                (s_axi_awburst != 2'b01) ||
                ({1'b0, s_axi_awaddr[11:0]} + 13'd128 > 13'd4096)) begin
                boundary_error <= 1'b1;
            end
        end

        if (s_axi_wvalid && s_axi_wready) begin
            write_buffer_data[write_beat_count[3:0]] <= s_axi_wdata;
            write_buffer_strobe[write_beat_count[3:0]] <= s_axi_wstrb;
            if (!aw_received) begin
                w_before_aw_seen <= 1'b1;
            end
            if (s_axi_wlast) begin
                if (write_beat_count != 5'd15) begin
                    boundary_error <= 1'b1;
                end
                write_data_complete <= 1'b1;
            end else begin
                write_beat_count <= write_beat_count + 5'd1;
            end
        end

        if (aw_received && write_data_complete && !s_axi_bvalid) begin
            for (commit_index = 0; commit_index < 16; commit_index++) begin
                write_memory(
                    write_base_addr + (commit_index * 8),
                    write_buffer_data[commit_index],
                    write_buffer_strobe[commit_index]
                );
                if ((write_base_addr + (commit_index * 8)) > maximum_address_seen) begin
                    maximum_address_seen <= write_base_addr + (commit_index * 8);
                end
            end
            s_axi_bid <= write_id;
            if (inject_bresp_error && !bresp_error_used) begin
                s_axi_bresp <= 2'b10;
                bresp_error_used <= 1'b1;
            end else begin
                s_axi_bresp <= 2'b00;
            end
            s_axi_bvalid <= 1'b1;
        end

        if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            aw_received <= 1'b0;
            write_data_complete <= 1'b0;
            write_beat_count <= 5'd0;
        end

        if (s_axi_arvalid && s_axi_arready) begin
            read_active <= 1'b1;
            read_base_addr <= s_axi_araddr;
            read_id <= s_axi_arid;
            read_beat_index <= 5'd0;
            if ((s_axi_arlen != 8'd15) || (s_axi_arsize != 3'd3) ||
                (s_axi_arburst != 2'b01) ||
                ({1'b0, s_axi_araddr[11:0]} + 13'd128 > 13'd4096)) begin
                boundary_error <= 1'b1;
            end
        end

        if (read_active && !s_axi_rvalid && !stall_all) begin
            s_axi_rid <= read_id;
            s_axi_rdata <= read_memory(read_base_addr + {25'd0, read_beat_index[3:0], 3'b000});
            if (inject_data_error && !data_error_used) begin
                s_axi_rdata <= read_memory_with_error(
                    read_base_addr + {25'd0, read_beat_index[3:0], 3'b000}
                );
                data_error_used <= 1'b1;
            end
            s_axi_rresp <= 2'b00;
            s_axi_rlast <= (read_beat_index == 5'd15);
            s_axi_rvalid <= 1'b1;
        end

        if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            if (s_axi_rlast) begin
                read_active <= 1'b0;
                read_beat_index <= 5'd0;
            end else begin
                read_beat_index <= read_beat_index + 5'd1;
            end
        end
    end
end

endmodule
