# TOP

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\TOP.v`
- SHA-256: `e1f5dd8e6270c3e069af821002e6fbd239da30204c8831d016340bb4acdfc7a4`
- Extractor: `text`
- Tags: `aurora, pcie, rtl, xdma`
- Duplicate sources:
  - E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.srcs\sources_1\new\TOP.v

```verilog
`timescale 1ns / 1ps

module TOP #(
        parameter integer AURORA_SIMULATION = 0
    )(
        input                   clk_p,
        input                   clk_n,

        input       [1:0]       pcie_mgt_rxn,
        input       [1:0]       pcie_mgt_rxp,
        output      [1:0]       pcie_mgt_txn,
        output      [1:0]       pcie_mgt_txp,
        input       [0:0]       pcie_diff_clk_n,
        input       [0:0]       pcie_diff_clk_p,
        input                   pcie_rst_n,
        output                  user_lnk_up,

        input                   GTHQ0_P,
        input                   GTHQ0_N,
        input                   aurora_rxp,
        input                   aurora_rxn,
        output                  aurora_txp,
        output                  aurora_txn,
        output                  sfp_tx_disable,
        output                  sfp_rs0,
        output                  sfp_rs1,

        output                  led
    );

    wire clk_250m;
    wire clk_156m;
    wire clk_100m;
    wire sys_rst;

    wire [63:0] aurora_tx_d;
    wire        aurora_tx_sof;
    wire        aurora_tx_eof;
    wire [2:0]  aurora_tx_rem;
    wire        aurora_tx_src_rdy;
    wire        aurora_tx_dst_rdy;

    wire [63:0] aurora_rx_d;
    wire        aurora_rx_sof;
    wire        aurora_rx_eof;
    wire [2:0]  aurora_rx_rem;
    wire        aurora_rx_src_rdy;
    wire        aurora_rx_dst_rdy;

    wire        aurora_user_clk;
    wire        aurora_user_rstn;
    wire        aurora_channel_up;
    wire        aurora_lane_up;

    wire [15:0] FPGA_TEMP_W;
    wire        FPGA_TEMP_BUSY_W;

    CLK_GEN u_clk_gen (
        .clk_p     (clk_p),
        .clk_n     (clk_n),
        .clk_250m  (clk_250m),
        .clk_156m  (clk_156m),
        .clk_100m  (clk_100m),
        .sys_rst   (sys_rst)
    );

    // Aurora owns its recovered/user clock. clk_100m is used only as the
    // free-running initialization clock required by the configured core.
    aurora_64b66b_top #(
        .SIMULATION       (AURORA_SIMULATION),
        .INIT_CLK_FREQ_HZ (100_000_000)
    ) u_aurora_64b66b_top (
        .clk_init       (clk_100m),
        .sys_rst        (sys_rst),
        .GTHQ0_P        (GTHQ0_P),
        .GTHQ0_N        (GTHQ0_N),
        .RXP            (aurora_rxp),
        .RXN            (aurora_rxn),
        .TXP            (aurora_txp),
        .TXN            (aurora_txn),
        .sfp_tx_disable (sfp_tx_disable),
        .sfp_rs0        (sfp_rs0),
        .sfp_rs1        (sfp_rs1),
        .tx_d           (aurora_tx_d),
        .tx_sof         (aurora_tx_sof),
        .tx_eof         (aurora_tx_eof),
        .tx_rem         (aurora_tx_rem),
        .tx_src_vld     (aurora_tx_src_rdy),
        .tx_dst_rdy     (aurora_tx_dst_rdy),
        .rx_d           (aurora_rx_d),
        .rx_sof         (aurora_rx_sof),
        .rx_eof         (aurora_rx_eof),
        .rx_rem         (aurora_rx_rem),
        .rx_src_vld     (aurora_rx_src_rdy),
        .rx_dst_rdy     (aurora_rx_dst_rdy),
        .user_clk       (aurora_user_clk),
        .channel_up     (aurora_channel_up),
        .lane_up        (aurora_lane_up),
        .user_rstn      (aurora_user_rstn)
    );

    PCIe u_pcie (
        .pcie_mgt_rxn        (pcie_mgt_rxn),
        .pcie_mgt_rxp        (pcie_mgt_rxp),
        .pcie_mgt_txn        (pcie_mgt_txn),
        .pcie_mgt_txp        (pcie_mgt_txp),
        .pcie_diff_clk_n     (pcie_diff_clk_n),
        .pcie_diff_clk_p     (pcie_diff_clk_p),
        .pcie_rst_n          (pcie_rst_n),
        .user_lnk_up         (user_lnk_up),
        .FPGA_TEMP_W         ({15'd0, FPGA_TEMP_BUSY_W, FPGA_TEMP_W}),
        .i_sys_clk           (clk_250m),
        .i_sys_rst           (sys_rst),
        .aurora_user_clk     (aurora_user_clk),
        .aurora_user_rstn    (aurora_user_rstn),
        .aurora_channel_up   (aurora_channel_up),
        .aurora_lane_up      (aurora_lane_up),
        .aurora_tx_d         (aurora_tx_d),
        .aurora_tx_sof       (aurora_tx_sof),
        .aurora_tx_eof       (aurora_tx_eof),
        .aurora_tx_rem       (aurora_tx_rem),
        .aurora_tx_src_rdy   (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy   (aurora_tx_dst_rdy),
        .aurora_rx_d         (aurora_rx_d),
        .aurora_rx_sof       (aurora_rx_sof),
        .aurora_rx_eof       (aurora_rx_eof),
        .aurora_rx_rem       (aurora_rx_rem),
        .aurora_rx_src_rdy   (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy   (aurora_rx_dst_rdy)
    );

    LED #(
        .SYS_CLK   (250000000),
        .LED_CYCLE (1000000)
    ) u_led (
        .i_sys_clk (clk_250m),
        .i_sys_rst (sys_rst),
        .o_led     (led)
    );

    TEMP_RD #(
        .SYS_CLK       (250000000),
        .RD_TEMP_CYCLE (1000)
    ) u_temp_rd (
        .sys_clk (clk_250m),
        .sys_rst (sys_rst),
        .busy    (FPGA_TEMP_BUSY_W),
        .temp    (FPGA_TEMP_W)
    );

    // clk_156m remains available for board-level diagnostics. The Aurora data
    // path intentionally uses aurora_user_clk from the core instead.

endmodule
```
