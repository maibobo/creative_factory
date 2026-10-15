`timescale 1ns/1ps

module demo_tb;

    import uvm_pkg::*;
    import demo_pkg::*;
    `include "uvm_macros.svh"

    logic clk;

    demo_if vif(clk);

    DEMO_DUT U_DEMO_DUT (
        .clk      (clk),
        .rst_n    (vif.rst_n),
        .req_valid(vif.req_valid),
        .req_ready(vif.req_ready),
        .req_data (vif.req_data),
        .rsp_valid(vif.rsp_valid),
        .rsp_data (vif.rsp_data)
    );

    DEMO_ASSERTIONS U_DEMO_ASSERTIONS (
        .clk      (clk),
        .rst_n    (vif.rst_n),
        .req_valid(vif.req_valid),
        .req_ready(vif.req_ready),
        .req_data (vif.req_data),
        .rsp_valid(vif.rsp_valid),
        .rsp_data (vif.rsp_data)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #5ns clk = ~clk;
        end
    end

    initial begin
        vif.rst_n = 1'b0;
        repeat (5) begin
            @(negedge clk);
        end
        vif.rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(demo_driver_vif_t)::set(
            null,
            "uvm_test_top",
            "drv_vif",
            vif
        );
        uvm_config_db#(demo_monitor_vif_t)::set(
            null,
            "uvm_test_top",
            "mon_vif",
            vif
        );
        run_test("demo_test");
    end

    // 全局 watchdog 是唯一绝对时间终止机制；组件不调用 $finish。
    initial begin
        repeat (2000) begin
            @(posedge clk);
        end
        `uvm_fatal("DEMO/WATCHDOG", "global watchdog expired")
    end

endmodule
