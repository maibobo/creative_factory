`timescale 1ns/1ps
// Pure observer: no PCIe/DDR control outputs. board_clk must run without PCIe.
module rtds_pcie_link_observer #(
    parameter integer HB_BIT = 12,
    parameter integer WATCHDOG_CYCLES = 250000
)(
    input wire board_clk,
    input wire board_reset,
    input wire clear_history,
    input wire pcie_clk,
    input wire perst_n,
    input wire qpll1_lock,
    input wire user_lnk_up,
    input wire axi_aresetn,
    input wire ddr_ready,
    input wire [5:0] ltssm,
    input wire [2:0] speed,
    input wire [3:0] width,
    output wire [7:0] live_status,
    output reg [3:0] history,
    output reg [15:0] link_up_count,
    output reg [15:0] link_down_count,
    output reg [15:0] perst_assert_count,
    output wire native_event,
    output reg [31:0] native_ticks,
    output wire perst_native,
    output wire qpll_native
);
    initial begin
        history = 0; link_up_count = 0; link_down_count = 0;
        perst_assert_count = 0; native_ticks = 0;
    end
    // PCIe clock may stop during reset: this heartbeat is observed by board_clk.
    reg [HB_BIT:0] heartbeat = 0;
    always @(posedge pcie_clk) heartbeat <= heartbeat + 1'b1;

    // Each bit below is an independent single-bit status, not an encoded bus.
    (* ASYNC_REG = "TRUE" *) reg [5:0] board_meta = 0, board_sync = 0;
    wire [5:0] board_async = {ddr_ready, axi_aresetn, user_lnk_up,
                              heartbeat[HB_BIT], qpll1_lock, perst_n};
    always @(posedge board_clk) begin
        board_meta <= board_async;
        board_sync <= board_meta;
    end
    localparam integer W = (WATCHDOG_CYCLES < 2) ? 1 : $clog2(WATCHDOG_CYCLES+1);
    reg [W-1:0] watchdog = 0;
    reg heartbeat_prev = 0;
    reg clock_alive = 0;
    reg [4:0] settle = 0;
    reg link_prev = 0, perst_prev = 0;
    // [0] PERST released [1] QPLL locked [2] PCIe clock alive [3] link up
    // [4] AXI reset released [5] DDR ready [6] board reset [7] observer settled
    assign live_status = {settle[4], board_reset, board_sync[5:3],
                          clock_alive, board_sync[1:0]};
    always @(posedge board_clk) begin
        if (board_reset) begin
            watchdog <= 0;
            heartbeat_prev <= board_sync[2];
            clock_alive <= 0;
            settle <= 0;
            history <= 0;
            link_up_count <= 0;
            link_down_count <= 0;
            perst_assert_count <= 0;
            link_prev <= board_sync[3];
            perst_prev <= board_sync[0];
        end else begin
            if (!settle[4]) settle <= settle + 1'b1;
            heartbeat_prev <= board_sync[2];
            link_prev <= board_sync[3];
            perst_prev <= board_sync[0];
            if (board_sync[2] != heartbeat_prev) begin
                watchdog <= 0;
                clock_alive <= 1;
            end else if (watchdog < WATCHDOG_CYCLES) begin
                watchdog <= watchdog + 1'b1;
            end else clock_alive <= 0;
            if (clear_history) begin
                history <= 0;
                link_up_count <= 0;
                link_down_count <= 0;
                perst_assert_count <= 0;
            end else if (settle[4]) begin
                // [0] observed PERST low [1] ever QPLL lock
                // [2] ever PCIe clock activity [3] ever link up
                history <= history | {board_sync[3], clock_alive,
                                      board_sync[1], !board_sync[0]};
                if (board_sync[3] && !link_prev && link_up_count != 16'hffff)
                    link_up_count <= link_up_count + 1'b1;
                if (!board_sync[3] && link_prev && link_down_count != 16'hffff)
                    link_down_count <= link_down_count + 1'b1;
                if (!board_sync[0] && perst_prev && perst_assert_count != 16'hffff)
                    perst_assert_count <= perst_assert_count + 1'b1;
            end
        end
    end
    // Keep LTSSM/speed/width in their native PCIe domain. Do not synchronize bits.
    (* ASYNC_REG = "TRUE" *) reg [1:0] native_meta = 0, native_sync = 0;
    always @(posedge pcie_clk) begin
        native_meta <= {qpll1_lock, perst_n};
        native_sync <= native_meta;
    end
    assign perst_native = native_sync[0];
    assign qpll_native = native_sync[1];
    wire [16:0] native_bundle = {ltssm, speed, width, user_lnk_up,
                                axi_aresetn, native_sync};
    reg [16:0] native_prev = 0;
    reg native_first = 1;
    assign native_event = native_first || (native_bundle != native_prev);
    // Deliberately no PERST/axi_aresetn reset: retain observations across link reset.
    always @(posedge pcie_clk) begin
        native_ticks <= native_ticks + 1'b1;
        native_prev <= native_bundle;
        native_first <= 0;
    end
endmodule

