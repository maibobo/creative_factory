# rtds_pcie_ep_sim_wrapper

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\rtds_pcie_ep_sim_wrapper.sv`
- SHA-256: `ad94b06968baab30c6e961f8c5b66d621f13a17156d9a8f37067ec6a49b25bcb`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ps / 1ps

// 仿真专用 Endpoint 兼容层。
//
// 真实 DUT 仍是未修改的 PCIe 模块。Xilinx 官方 pci_exp_usrapp_tx.v 中有几个
// example-only compare task，会在 elaboration 时无条件解析 board.EP.m_axi_*；这些
// task 不属于 rtds_minimum 的数据校验路径。本层只提供同名占位观察信号，使官方
// RP/TPI 的枚举、BAR 和 XDMA task 可以原样复用。rtds_minimum 的数据正确性由
// Host DATA_STORE、真实 CONV_DMA AXI monitor 和 LocalLink scoreboard 判断。
module rtds_pcie_ep_sim_wrapper (
    input       [1:0] pcie_mgt_rxn,
    input       [1:0] pcie_mgt_rxp,
    output      [1:0] pcie_mgt_txn,
    output      [1:0] pcie_mgt_txp,
    input       [0:0] pcie_diff_clk_n,
    input       [0:0] pcie_diff_clk_p,
    input             pcie_rst_n,
    output            user_lnk_up,

    input      [31:0] FPGA_TEMP_W,
    input             i_sys_clk,
    input             i_sys_rst,

    input             aurora_user_clk,
    input             aurora_user_rstn,
    input             aurora_channel_up,
    input             aurora_lane_up,

    output     [63:0] aurora_tx_d,
    output            aurora_tx_sof,
    output            aurora_tx_eof,
    output     [2:0]  aurora_tx_rem,
    output            aurora_tx_src_rdy,
    input             aurora_tx_dst_rdy,

    input      [63:0] aurora_rx_d,
    input             aurora_rx_sof,
    input             aurora_rx_eof,
    input      [2:0]  aurora_rx_rem,
    input             aurora_rx_src_rdy,
    output            aurora_rx_dst_rdy
);

    // ---------- 语义段 1：真实生产 PCIe 模块，端口逐项透明传递 ----------
    PCIe DUT (
        .pcie_mgt_rxn       (pcie_mgt_rxn),
        .pcie_mgt_rxp       (pcie_mgt_rxp),
        .pcie_mgt_txn       (pcie_mgt_txn),
        .pcie_mgt_txp       (pcie_mgt_txp),
        .pcie_diff_clk_n    (pcie_diff_clk_n),
        .pcie_diff_clk_p    (pcie_diff_clk_p),
        .pcie_rst_n         (pcie_rst_n),
        .user_lnk_up        (user_lnk_up),
        .FPGA_TEMP_W        (FPGA_TEMP_W),
        .i_sys_clk          (i_sys_clk),
        .i_sys_rst          (i_sys_rst),
        .aurora_user_clk    (aurora_user_clk),
        .aurora_user_rstn   (aurora_user_rstn),
        .aurora_channel_up  (aurora_channel_up),
        .aurora_lane_up     (aurora_lane_up),
        .aurora_tx_d        (aurora_tx_d),
        .aurora_tx_sof      (aurora_tx_sof),
        .aurora_tx_eof      (aurora_tx_eof),
        .aurora_tx_rem      (aurora_tx_rem),
        .aurora_tx_src_rdy  (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy  (aurora_tx_dst_rdy),
        .aurora_rx_d        (aurora_rx_d),
        .aurora_rx_sof      (aurora_rx_sof),
        .aurora_rx_eof      (aurora_rx_eof),
        .aurora_rx_rem      (aurora_rx_rem),
        .aurora_rx_src_rdy  (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy  (aurora_rx_dst_rdy)
    );

    // ---------- 语义段 2：把大仿真断言使用的真实内部信号提升到 wrapper ----------
    wire [63:0] fdma_raddr = DUT.fdma_raddr;
    wire        fdma_rareq = DUT.fdma_rareq;
    wire        fdma_rbusy = DUT.fdma_rbusy;
    wire [15:0] fdma_rsize = DUT.fdma_rsize;
    wire [63:0] fdma_waddr = DUT.fdma_waddr;
    wire        fdma_wareq = DUT.fdma_wareq;
    wire        fdma_wbusy = DUT.fdma_wbusy;
    wire [15:0] fdma_wsize = DUT.fdma_wsize;

    wire CLEAR_INTER_R       = DUT.CLEAR_INTER_R;
    wire CPU_WR_DONE_resp    = DUT.CPU_WR_DONE_resp;
    wire FPGA_CPU_irq_req    = DUT.FPGA_CPU_irq_req;
    wire link_down_sticky    = DUT.link_down_sticky;
    wire length_error_sticky = DUT.length_error_sticky;
    wire fdma_timeout_sticky = DUT.fdma_timeout_sticky;
    wire tx_underflow_sticky = DUT.tx_underflow_sticky;
    wire rx_overrun_sticky   = DUT.rx_overrun_sticky;
    wire rx_overflow_sticky  = DUT.rx_overflow_sticky;

    // ---------- 语义段 3：官方 example-only AXI compare task 的名称兼容 ----------
    // 这些信号不连接测试判定，也不会被 rtds_minimum task 读取。位宽取官方 task
    // 可解析的最大值，避免其未选中的 128/256/512-bit case 出现越界引用。
    wire         user_clk     = i_sys_clk;
    wire         m_axi_wvalid = 1'b0;
    wire         m_axi_wready = 1'b0;
    wire [511:0] m_axi_wdata  = 512'd0;
    wire  [63:0] m_axi_wstrb  = 64'd0;

endmodule
```
