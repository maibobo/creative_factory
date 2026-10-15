module DEMO_ASSERTIONS (
    input logic       clk,
    input logic       rst_n,
    input logic       req_valid,
    input logic       req_ready,
    input logic [7:0] req_data,
    input logic       rsp_valid,
    input logic [7:0] rsp_data
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    property p_response_one_cycle_later;
        @(posedge clk) disable iff (!rst_n)
        (req_valid && req_ready) |=>
            (rsp_valid && (rsp_data == ($past(req_data) + 8'd1)));
    endproperty

    property p_no_spurious_response;
        @(posedge clk) disable iff (!rst_n)
        rsp_valid |-> $past(req_valid && req_ready);
    endproperty

    property p_control_known;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown({req_valid, req_ready, rsp_valid});
    endproperty

    a_response_one_cycle_later: assert property (p_response_one_cycle_later)
        else `uvm_error("DEMO/SVA/RESPONSE", "response data or latency mismatch")

    a_no_spurious_response: assert property (p_no_spurious_response)
        else `uvm_error("DEMO/SVA/SPURIOUS", "response observed without prior request")

    a_control_known: assert property (p_control_known)
        else `uvm_error("DEMO/SVA/X_CONTROL", "X/Z detected on protocol control")

    c_request_accepted: cover property (
        @(posedge clk) disable iff (!rst_n) req_valid && req_ready
    );

endmodule
