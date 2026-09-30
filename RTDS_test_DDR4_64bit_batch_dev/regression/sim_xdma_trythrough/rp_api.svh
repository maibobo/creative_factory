// 快速验证用虚拟BAR API：本文件不实例化INFO_EXCH；真实寄存器读写由Root Port验证。
// The behavioral backend implements the same operations as the intended
// vendor XDMA TPI: BAR register access plus H2C/C2H memory transfers.

reg cpu_wr_done_shadow;
// 虚拟BAR只用于adapter驱动，真实INFO_EXCH门铃以regs/Root Port验证为准。
always @(posedge fdma_clk) begin
    if(cpu_wr_done_event) cpu_wr_done_shadow<=1'b0;
end

task automatic rp_init_and_enumerate;
    integer timeout;
    begin : rp_init_block
        timeout = 0;
        while (!(pcie_link_up && aurora_channel_up && aurora_lane_up)) begin
            @(posedge fdma_clk);
            timeout = timeout + 1;
            if (timeout > 2000) begin
                test_error_count = test_error_count + 1;
                $error("RP_INIT timeout waiting for PCIe/Aurora links");
                disable rp_init_block;
            end
        end
        repeat (10) @(posedge fdma_clk);
        $display("RP_API: enumeration/link initialization complete");
    end
endtask

task automatic bar_write32(input [31:0] offset, input [31:0] value);
    begin
        @(negedge fdma_clk);
        case (offset[15:0])
            16'h0014: begin
                cpu_rec_state_r = value[0];
                @(negedge fdma_clk); cpu_rec_state_r=1'b0;
            end
            16'h0020: begin
                if (value[0] && !cpu_wr_done_shadow) begin
                    cpu_wr_done_shadow=1'b1;
                    rd_start = 1'b1;
                    @(negedge fdma_clk);
                    rd_start = 1'b0;
                end

            end
            16'h0024: if(!cpu_wr_done_shadow) cpu_fpga_start_addr = value;
            16'h0028: if(!cpu_wr_done_shadow) cpu_fpga_len = value;
            default: begin
                test_error_count = test_error_count + 1;
                $error("BAR_WRITE unsupported offset %h", offset);
            end
        endcase
    end
endtask

task automatic bar_read32(input [31:0] offset, output [31:0] value);
    begin
        @(negedge fdma_clk);
        case (offset[15:0])
            16'h0000: value = 32'h0000_2001;
            16'h0008: value = 32'h0004_0000;
            16'h0010: value = {31'd0, int_state_w};
            16'h0014: value = 32'd0;
            16'h0018: value = fpga_cpu_start_addr;
            16'h001C: value = fpga_cpu_len;
            16'h0020: value = {31'd0, cpu_wr_done_shadow};
            16'h0024: value = cpu_fpga_start_addr;
            16'h0028: value = cpu_fpga_len;
            16'h0030: value = rx_ready_blocks;
            16'h0034: value = rx_head_seq;
            16'h0038: value = rx_dropped_frames;
            default: value = 32'd0;
        endcase
        if (offset[15:0] == 16'h0010) begin
            int_state_clear = 1'b1;
            clear_inter = 1'b1;
            @(negedge fdma_clk);
            int_state_clear = 1'b0;
            clear_inter = 1'b0;
        end
    end
endtask

task automatic h2c_transfer(
    input [63:0] host_addr,
    input [63:0] card_addr,
    input integer length_bytes
);
    u_backend.h2c_transfer(host_addr, card_addr, length_bytes);
endtask

task automatic c2h_transfer(
    input [63:0] card_addr,
    input [63:0] host_addr,
    input integer length_bytes
);
    u_backend.c2h_transfer(card_addr, host_addr, length_bytes);
endtask

task automatic wait_user_irq(input integer timeout_cycles);
    integer timeout;
    begin : wait_irq_block
        for (timeout = 0; timeout < timeout_cycles; timeout = timeout + 1) begin
            @(posedge fdma_clk);
            if (fpga_cpu_irq_req)
                disable wait_irq_block;
        end
        if (!fpga_cpu_irq_req) begin
            test_error_count = test_error_count + 1;
            $error("RP_API timeout waiting for user IRQ");
        end
    end
endtask

task automatic wait_cpu_tx_complete(input integer timeout_cycles);
    integer timeout;
    bit response_seen;
    begin : wait_tx_block
        response_seen = 0;
        for (timeout = 0; timeout < timeout_cycles; timeout = timeout + 1) begin
            @(posedge fdma_clk);
            if (cpu_wr_done_resp)
                response_seen = 1;
            if (response_seen && !cpu_wr_done_resp)
                disable wait_tx_block;
        end
        if (!response_seen || cpu_wr_done_resp) begin
            test_error_count = test_error_count + 1;
            $error("RP_API timeout waiting for CPU_WR_DONE response lifecycle");
        end
    end
endtask

task automatic clear_irq_by_read;
    reg [31:0] value;
    begin
        bar_read32(32'h0010, value);
        repeat (2) @(posedge fdma_clk);
        if (fpga_cpu_irq_req || int_state_w) begin
            test_error_count = test_error_count + 1;
            $error("INT_STATE read did not clear IRQ/INT_STATE");
        end
    end
endtask

task automatic cpu_rec_acknowledge;
    begin
        bar_write32(32'h0014, 32'd1);
        repeat(3) @(posedge fdma_clk);
        if(cpu_rec_state_r) $fatal(1,"FAST/ACK_NOT_CLEARED");
    end
endtask
