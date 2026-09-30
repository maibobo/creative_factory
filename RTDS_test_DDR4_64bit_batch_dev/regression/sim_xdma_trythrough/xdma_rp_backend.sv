// 快速行为后端：卡端容量4MiB，Host数组模拟H2C/C2H，不产生PCIe TLP。
// fdma_wdone 由数组写入完成形成；真实AXI写响应由独立AXI/Root Port用例检验。
`timescale 1ns / 1ps

// Behavioral backend for the fast regression profile. Its public tasks match
// the Root-Port API used by the testbench; the vendor XDMA TPI backend can
// replace this module without changing test intent or scoreboards.
module xdma_rp_backend #(
        parameter integer MEM_BYTES = 4 * 1024 * 1024,
        parameter integer HOST_BYTES = 128 * 1024,
        parameter [31:0] CARD_ADDR_HI = 0
    )(
        input              clk,
        input              rstn,

        input      [63:0]  fdma_raddr,
        input              fdma_rareq,
        input      [15:0]  fdma_rsize,
        output reg         fdma_rbusy,
        output reg [63:0]  fdma_rdata,
        output reg         fdma_rvalid,
        input              fdma_rready,

        input      [63:0]  fdma_waddr,
        input              fdma_wareq,
        input      [15:0]  fdma_wsize,
        output reg         fdma_wbusy,
        input      [63:0]  fdma_wdata,
        input      [7:0] fdma_wstrb, // 实际字节写使能
        input              fdma_wvalid,
        output reg         fdma_wready,

        output reg fdma_wdone,
        output wire fdma_werror,
        output reg [31:0]  backend_error_count
    );
    import rtds_test_pkg::*;
    // 行为后端完成事件：数据数组实际写入后才可向块管理器提交。
    assign fdma_werror = 1'b0;

    always @(posedge clk) begin
        if (!rstn) begin
            fdma_wdone <= 1'b0;
        end else begin
            fdma_wdone <= fdma_wvalid && fdma_wready && fdma_wbusy && wr_words_left == 1;
        end
    end

    localparam integer MEM_WORDS = MEM_BYTES / 8;
    localparam integer HOST_WORDS = HOST_BYTES / 8;
    logic [63:0] card_mem [0:MEM_WORDS-1];
    logic [63:0] host_mem [0:HOST_WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            card_mem[i] = 64'd0;
        for (i = 0; i < HOST_WORDS; i = i + 1)
            host_mem[i] = 64'd0;
    end

    reg [31:0] rd_word_index;
    reg [15:0] rd_words_left;
    reg [31:0] wr_word_index;
    reg [15:0] wr_words_left;
    reg        read_stall_enable;
    reg        write_stall_enable;
    reg        write_block_enable;

    task automatic set_fdma_stalls(input bit read_enable, input bit write_enable);
        begin
            read_stall_enable = read_enable;
            write_stall_enable = write_enable;
        end
    endtask

    task automatic set_write_block(input bit enable);
        write_block_enable = enable;
    endtask

    task automatic record_backend_error(input string message);
        begin
            backend_error_count = backend_error_count + 1;
            $error("XDMA_BACKEND: %s", message);
        end
    endtask

    always @(posedge clk) begin
        if (!rstn) begin
            fdma_rbusy        <= 1'b0;
            fdma_rdata        <= 64'd0;
            fdma_rvalid       <= 1'b0;
            rd_word_index     <= 32'd0;
            rd_words_left     <= 16'd0;
            read_stall_enable <= 1'b0;
        end else if (!fdma_rbusy) begin
            fdma_rvalid <= 1'b0;
            if (fdma_rareq) begin
                if (fdma_raddr[63:32] != CARD_ADDR_HI)
                    record_backend_error("FDMA read used unexpected upper address bits");
                if ((fdma_rsize == 0) ||
                    ((fdma_raddr[31:0] + fdma_rsize * 8) > MEM_BYTES))
                    record_backend_error("FDMA read was outside 4-MiB card memory");
                fdma_rbusy    <= 1'b1;
                rd_word_index <= fdma_raddr[31:3];
                rd_words_left <= fdma_rsize;
            end
        end else begin
            if (!fdma_rvalid && (rd_words_left != 0) &&
                (!read_stall_enable || ($urandom_range(0, 3) != 0))) begin
                fdma_rdata  <= card_mem[rd_word_index];
                fdma_rvalid <= 1'b1;
            end else if (fdma_rvalid && fdma_rready) begin
                if (rd_words_left == 1) begin
                    fdma_rvalid   <= 1'b0;
                    fdma_rbusy    <= 1'b0;
                    rd_words_left <= 16'd0;
                end else begin
                    rd_word_index <= rd_word_index + 1;
                    rd_words_left <= rd_words_left - 1;
                    if (!read_stall_enable || ($urandom_range(0, 3) != 0)) begin
                        fdma_rdata  <= card_mem[rd_word_index + 1];
                        fdma_rvalid <= 1'b1;
                    end else begin
                        fdma_rvalid <= 1'b0;
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            fdma_wbusy         <= 1'b0;
            fdma_wready        <= 1'b0;
            wr_word_index      <= 32'd0;
            wr_words_left      <= 16'd0;
            write_stall_enable <= 1'b0;
            write_block_enable <= 1'b0;
            backend_error_count <= 32'd0;
        end else if (!fdma_wbusy) begin
            fdma_wready <= 1'b0;
            if (fdma_wareq) begin
                if (fdma_waddr[63:32] != CARD_ADDR_HI)
                    record_backend_error("FDMA write used unexpected upper address bits");
                if ((fdma_wsize == 0) ||
                    ((fdma_waddr[31:0] + fdma_wsize * 8) > MEM_BYTES))
                    record_backend_error("FDMA write was outside 4-MiB card memory");
                fdma_wbusy    <= 1'b1;
                wr_word_index <= fdma_waddr[31:3];
                wr_words_left <= fdma_wsize;
            end
        end else begin
            fdma_wready <= !write_block_enable &&
                           (!write_stall_enable || ($urandom_range(0, 3) != 0));
            if (fdma_wvalid && fdma_wready) begin
                for(integer byte_lane=0;byte_lane<8;byte_lane=byte_lane+1)
                    if(fdma_wstrb[byte_lane])
                        card_mem[wr_word_index][byte_lane*8+:8] <= fdma_wdata[byte_lane*8+:8];
                if (wr_words_left == 1) begin
                    fdma_wbusy     <= 1'b0;
                    fdma_wready    <= 1'b0;
                    wr_words_left  <= 16'd0;
                end else begin
                    wr_word_index <= wr_word_index + 1;
                    wr_words_left <= wr_words_left - 1;
                end
            end
        end
    end

    task automatic host_fill_pattern(
        input [63:0] host_addr,
        input integer length_bytes,
        input [7:0] tag,
        input integer first_frame
    );
        integer word_offset;
        integer host_index;
        begin
            host_index = host_addr[31:3];
            for (word_offset = 0; word_offset < length_bytes / 8; word_offset = word_offset + 1)
                host_mem[host_index + word_offset] = make_pattern(
                    tag, first_frame + (word_offset / 2), word_offset % 2);
        end
    endtask

    task automatic h2c_transfer(
        input [63:0] host_addr,
        input [63:0] card_addr,
        input integer length_bytes
    );
        integer word_offset;
        integer host_index;
        integer card_index;
        begin
            host_index = host_addr[31:3];
            card_index = card_addr[31:3];
            if ((card_addr[2:0] != 0) || (host_addr[2:0] != 0) ||
                ((card_addr[31:0] + length_bytes) > MEM_BYTES))
                record_backend_error("invalid H2C transfer range/alignment");
            for (word_offset = 0; word_offset < length_bytes / 8; word_offset = word_offset + 1)
                card_mem[card_index + word_offset] = host_mem[host_index + word_offset];
        end
    endtask

    task automatic c2h_transfer(
        input [63:0] card_addr,
        input [63:0] host_addr,
        input integer length_bytes
    );
        integer word_offset;
        integer host_index;
        integer card_index;
        begin
            host_index = host_addr[31:3];
            card_index = card_addr[31:3];
            if ((card_addr[2:0] != 0) || (host_addr[2:0] != 0) ||
                ((card_addr[31:0] + length_bytes) > MEM_BYTES))
                record_backend_error("invalid C2H transfer range/alignment");
            for (word_offset = 0; word_offset < length_bytes / 8; word_offset = word_offset + 1)
                host_mem[host_index + word_offset] = card_mem[card_index + word_offset];
        end
    endtask

    task automatic compare_host_pattern(
        input [63:0] host_addr,
        input integer length_bytes,
        input [7:0] tag,
        input integer first_frame,
        output integer mismatches
    );
        integer word_offset;
        integer host_index;
        logic [63:0] expected;
        begin
            mismatches = 0;
            host_index = host_addr[31:3];
            for (word_offset = 0; word_offset < length_bytes / 8; word_offset = word_offset + 1) begin
                expected = make_pattern(tag, first_frame + (word_offset / 2), word_offset % 2);
                if (host_mem[host_index + word_offset] !== expected) begin
                    mismatches = mismatches + 1;
                    if (mismatches <= 4)
                        $error("HOST_COMPARE addr=%h expected=%h actual=%h",
                               host_addr + word_offset * 8, expected,
                               host_mem[host_index + word_offset]);
                end
            end
        end
    endtask
endmodule
