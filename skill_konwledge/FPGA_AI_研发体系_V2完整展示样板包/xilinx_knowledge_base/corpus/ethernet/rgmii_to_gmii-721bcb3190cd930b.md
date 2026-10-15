# rgmii_to_gmii

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\rgmii_to_gmii.v`
- SHA-256: `721bcb3190cd930bcbca68091dc3af584f0bccfb6896a06f286ea0ac84d03aa3`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
// =============================================================================
// Module : rgmii_to_gmii
// 位置   : 以太网风暴过滤顶层的接收前端，上游连接 PHY 的 RGMII 接口，
//          下游向 eth_storm_filter 提供单沿、8 bit 的 GMII 接收信号。
// 功能   : 通过 Xilinx IDDR 在 RGMII 时钟双沿采样 4 bit 数据和 RX_CTL；
//          上升沿数据组成 gmii_rxd[3:0]，下降沿数据组成 gmii_rxd[7:4]。
//          RX_CTL 上升沿为 RX_DV，下降沿为 RX_DV XOR RX_ER，末端异或恢复 RX_ER。
// 时序   : rgmii_rx_clk 经 BUFG 输出为 gmii_rx_clk；IDDR 采用
//          SAME_EDGE_PIPELINED，使同一 RGMII 字节的双沿采样值在同一边沿对齐输出。
//          rst_p 高有效并接入 IDDR 的同步复位端；时钟缓冲本身不受该复位控制。
// 接口   : 数据通路没有 ready/valid 反压，gmii_rxdv 指示每拍 gmii_rxd 是否有效。
// =============================================================================

module rgmii_to_gmii(
  rst_p,

  rgmii_rx_clk,
  rgmii_rxd,
  rgmii_rxdv,

  gmii_rx_clk,
  gmii_rxdv,
  gmii_rxd,
  gmii_rxer
);


  input         rst_p;

  input         rgmii_rx_clk;
  input  [3:0]  rgmii_rxd;
  input         rgmii_rxdv;

  output        gmii_rx_clk;
  output [7:0]  gmii_rxd;
  output        gmii_rxdv;
  output        gmii_rxer;

  wire          gmii_rxer_r;


  // 接收时钟进入全局时钟网络，作为后续 GMII 接收处理时钟。
  //assign gmii_rx_clk = rgmii_rx_clk;
	BUFG BUFG_inst (
      .O(gmii_rx_clk), // 缓冲后的 GMII 接收时钟
      .I(rgmii_rx_clk)  // PHY 提供的 RGMII 接收时钟
   );

// 以下 BUFR 是保留的 7 系列器件备选时钟缓冲方案，当前被注释掉。
/* 	BUFR #(
      .BUFR_DIVIDE("BYPASS"),   // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8"
      .SIM_DEVICE("7SERIES")  // Must be set to "7SERIES"
   )
   BUFR_inst (
      .O(gmii_rx_clk),     // 1-bit output: Clock output port
      .CE(1'b0),   // 1-bit input: Active high, clock enable (Divided modes only)
      .CLR(1'b0), // 1-bit input: Active high, asynchronous clear (Divided modes only)
      .I(rgmii_rx_clk)      // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
   ); */

  // 四个数据引脚各用一个 IDDR，同时还原一个 GMII 字节的低、高半字节。
  genvar i;
  generate
    for(i=0;i<4;i=i+1)
    begin: rgmii_rxd_i
      IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // 双沿结果在同一上升沿流水对齐
        .INIT_Q1(1'b0   ),  // 上升沿采样输出初值
        .INIT_Q2(1'b0   ),  // 下降沿采样输出初值
        .SRTYPE ("SYNC" )   // 置位/复位相对采样时钟同步生效
      ) IDDR_rxd (
        .Q1   (gmii_rxd[i]   ), // 上升沿采样值，对应字节低半部
        .Q2   (gmii_rxd[i+4] ), // 下降沿采样值，对应字节高半部
        .C    (rgmii_rx_clk  ), // RGMII 双沿采样时钟
        .CE   (1'b1          ), // 始终允许采样
        .D    (rgmii_rxd[i]  ), // 单根 RGMII DDR 数据引脚
        .R    (rst_p         ), // 高有效同步复位
        .S    (1'b0          )  // 不使用同步置位
      );
    end
  endgenerate

  // RX_CTL 采用与数据相同的 IDDR 模式，保证控制与还原后的字节对齐。
  IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // 双沿结果在同一上升沿流水对齐
    .INIT_Q1(1'b0   ),  // RX_DV 输出初值
    .INIT_Q2(1'b0   ),  // 编码控制输出初值
    .SRTYPE ("SYNC" )   // 置位/复位相对采样时钟同步生效
  ) IDDR_rxdv (
    .Q1   (gmii_rxdv), // 上升沿采样：RX_DV
    .Q2   (gmii_rxer_r), // 下降沿采样：RX_DV XOR RX_ER
    .C    (rgmii_rx_clk ), // RGMII 双沿采样时钟
    .CE   (1'b1         ), // 始终允许采样
    .D    (rgmii_rxdv   ), // PHY 的 RGMII RX_CTL 引脚
    .R    (rst_p        ), // 高有效同步复位
    .S    (1'b0         )  // 不使用同步置位
  );

    // 由 RGMII 控制编码关系恢复独立的 GMII 接收错误指示。
    assign gmii_rxer = gmii_rxer_r^gmii_rxdv;
endmodule
```
