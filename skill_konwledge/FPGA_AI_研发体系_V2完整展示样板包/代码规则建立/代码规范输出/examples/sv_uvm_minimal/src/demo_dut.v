module DEMO_DUT (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       req_valid,
    output wire       req_ready,
    input  wire [7:0] req_data,
    output reg        rsp_valid,
    output reg  [7:0] rsp_data
);

wire req_fire;

assign req_ready = 1'b1;
assign req_fire  = req_valid & req_ready;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rsp_valid <= 1'b0;
    end else begin
        rsp_valid <= req_fire;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rsp_data <= 8'b0;
    end else if (req_fire) begin
        rsp_data <= req_data + 8'd1;
    end
end

endmodule
