`timescale 1ns/1ps
// Shared 250 MHz source for the CPU 50 us GPIO and Aurora 1G 2 us frame events.
module RTDS_SYNC_TIMEBASE (
    input  wire clk_250m,
    input  wire rst_n,
    output reg  tick_toggle_2us,
    output reg  cpu_sync_50us
);
    reg [8:0]  count_2us;
    reg [13:0] count_50us;

    always @(posedge clk_250m or negedge rst_n) begin
        if (!rst_n) begin
            count_2us        <= 9'd0;
            count_50us       <= 14'd0;
            tick_toggle_2us <= 1'b0;
            cpu_sync_50us   <= 1'b0;
        end else begin
            count_2us <= (count_2us == 9'd499) ? 9'd0 : count_2us + 9'd1;
            count_50us <= (count_50us == 14'd12499) ? 14'd0 : count_50us + 14'd1;
            if (count_2us == 9'd0)
                tick_toggle_2us <= ~tick_toggle_2us;
            cpu_sync_50us <= (count_50us < 14'd6250);
        end
    end
endmodule
