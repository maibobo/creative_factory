interface demo_if(input logic clk);

    logic       rst_n;
    logic       req_valid;
    logic       req_ready;
    logic [7:0] req_data;
    logic       rsp_valid;
    logic [7:0] rsp_data;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input  rst_n;
        input  req_ready;
        output req_valid;
        output req_data;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input rst_n;
        input req_valid;
        input req_ready;
        input req_data;
        input rsp_valid;
        input rsp_data;
    endclocking

    modport driver_mp(clocking drv_cb);
    modport monitor_mp(clocking mon_cb);

    modport dut_mp(
        input  clk,
        input  rst_n,
        input  req_valid,
        output req_ready,
        input  req_data,
        output rsp_valid,
        output rsp_data
    );

endinterface
