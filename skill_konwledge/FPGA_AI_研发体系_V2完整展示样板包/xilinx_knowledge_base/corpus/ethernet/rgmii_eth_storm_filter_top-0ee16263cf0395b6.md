# rgmii_eth_storm_filter_top

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\rgmii_eth_storm_filter_top.v`
- SHA-256: `0ee16263cf0395b653f968302e075a61c50823d4bcc476b62a499be0e67fd651`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// 模块名称：rgmii_eth_storm_filter_top
// 层级位置：RGMII 接收与以太网风暴过滤顶层封装；当前顶层不包含 DMA Writer。
//
// 数据/时钟关系：
//   1) clk_wiz 处理 PHY 输入的 rgmii_rx_clk，输出 rgmii_rx_clk_o 和 locked；
//   2) rgmii_to_gmii 用 DDR 采样把 4 位 RGMII 数据及 RX_CTL 还原为 8 位 GMII，
//      其输出 gmii_rx_clk 驱动接收解析、过滤、CRC 和接收侧统计；
//   3) eth_storm_filter 通过内部一级异步 FIFO 把帧数据/描述符从 gmii_rx_clk
//      跨到外部输入的 clk_125m，再完成 GOOSE/SV/Other 分类和二级缓冲；
//   4) 三路数据/描述符 FIFO 读接口供外部 fifo_to_axi_full/DMA 模块消费。
//
// sys_rst 或 RGMII 时钟处理 IP 未锁定都会产生高有效 rst，并复位整条接收通路。
// =============================================================================

module rgmii_eth_storm_filter_top #(
    parameter integer CLK_FREQ_HZ          = 125000000,
    parameter integer WINDOW_MS            = 10,
    parameter integer FRAME_MAX_PER_WIN    = 1000,
    parameter integer BYTE_MAX_PER_WIN     = 8000000,
    parameter integer MIN_FRAME_BYTES      = 60,
    parameter integer MAX_FRAME_BYTES      = 1514,
    parameter integer CRC_TABLE_DEPTH      = 1024,
    parameter integer DESC_DEPTH           = 32
)(
    // -------------------------------------------------------------------------
    // 本地处理时钟与系统复位；clk_125m 由顶层外部直接提供
    // -------------------------------------------------------------------------
    input  wire        clk_125m,
    input  wire        sys_rst,              // 高有效复位

    // -------------------------------------------------------------------------
    // RGMII PHY 接收接口
    // -------------------------------------------------------------------------
    input  wire        rgmii_rx_clk,
    input  wire [3:0]  rgmii_rxd,
    input  wire        rgmii_rxdv,

    // -------------------------------------------------------------------------
    // 运行时过滤配置
    // -------------------------------------------------------------------------
    input  wire        cfg_filter_en,
    input  wire        cfg_dst_mac_en,
    input  wire [47:0] cfg_local_mac,
    input  wire        cfg_allow_broadcast,
    input  wire        cfg_allow_multicast,
    input  wire [47:0] cfg_multicast_mac,       // 待加入64bit Hash表的组播MAC
    input  wire        cfg_multicast_mac_valid, // 上升沿触发一次MAC Hash写入
    input  wire        cfg_multicast_hash_clear,// 高有效，清空全部64bit Hash表
    input  wire        cfg_whitelist_en,
    input  wire        cfg_blacklist_en,
    input  wire        cfg_dup_crc_en,
    input  wire        cfg_frame_storm_en,
    input  wire        cfg_byte_storm_en,
    input  wire        cfg_crc_check_en,
    input  wire [31:0] cfg_frame_max_per_win,
    input  wire [31:0] cfg_byte_max_per_win,
    input  wire [15:0] cfg_max_frame_bytes,
    input  wire [15:0] cfg_eth_type_goose, // 软件寄存器配置的 GOOSE EtherType
    input  wire [15:0] cfg_eth_type_sv,    // 软件寄存器配置的 SV EtherType
    input  wire [31:0] cfg_window_ms,      // 风暴统计窗口，单位 ms；0 使用参数 WINDOW_MS
    input  wire        cfg_clear_stats,

    // 源 MAC 白名单，固定 4 条
    input  wire        cfg_white0_en,
    input  wire [47:0] cfg_white0_mac,
    input  wire        cfg_white1_en,
    input  wire [47:0] cfg_white1_mac,
    input  wire        cfg_white2_en,
    input  wire [47:0] cfg_white2_mac,
    input  wire        cfg_white3_en,
    input  wire [47:0] cfg_white3_mac,

    // 源 MAC 黑名单，固定 4 条
    input  wire        cfg_black0_en,
    input  wire [47:0] cfg_black0_mac,
    input  wire        cfg_black1_en,
    input  wire [47:0] cfg_black1_mac,
    input  wire        cfg_black2_en,
    input  wire [47:0] cfg_black2_mac,
    input  wire        cfg_black3_en,
    input  wire [47:0] cfg_black3_mac,

    // -------------------------------------------------------------------------
    // 本地 clk_125m 域 FIFO 输出接口，供外部 fifo_to_axi_full/DMA 模块读取。
    // 每路数据 FIFO 与描述符 FIFO 独立握手；53 位描述符格式为：
    // {pass[52], len[51:36], mac_class[35:34], eth_type_class[33:32], time[31:0]}。
    // -------------------------------------------------------------------------

    input  wire        goose_data_rd_en,
    output wire [7:0]  goose_data_dout,
    output wire        goose_data_empty,
    input  wire        goose_desc_rd_en,
    output wire [52:0] goose_desc_dout,
    output wire        goose_desc_empty,

    input  wire        sv_data_rd_en,
    output wire [7:0]  sv_data_dout,
    output wire        sv_data_empty,
    input  wire        sv_desc_rd_en,
    output wire [52:0] sv_desc_dout,
    output wire        sv_desc_empty,

    input  wire        other_data_rd_en,
    output wire [7:0]  other_data_dout,
    output wire        other_data_empty,
    input  wire        other_desc_rd_en,
    output wire [52:0] other_desc_dout,
    output wire        other_desc_empty,

    // clk_125m 域分类 FIFO 拥塞丢弃统计：仅覆盖接收侧已经通过、但目标二级
    // FIFO 满/将满而被路由器排空的帧；class：0=Other、1=GOOSE、2=SV。
    output wire        route_drop_fifo_full_valid,
    output wire [1:0]  route_drop_fifo_full_class,
    output wire [31:0] stat_route_drop_fifo_full_cnt,
    output wire [31:0] stat_route_drop_goose_cnt,
    output wire [31:0] stat_route_drop_sv_cnt,
    output wire [31:0] stat_route_drop_other_cnt,

    // -------------------------------------------------------------------------
    // gmii_rx_clk 域丢弃事件与统计输出；drop_valid 为描述符提交拍的单拍脉冲
    // -------------------------------------------------------------------------
    output wire        drop_valid,
    output wire [15:0] drop_reason,
    output wire [31:0] stat_pass_cnt,
    output wire [31:0] stat_drop_crc_err_cnt,
    output wire [31:0] stat_drop_dup_crc_cnt,
    output wire [31:0] stat_drop_frame_storm_cnt,
    output wire [31:0] stat_drop_byte_storm_cnt,
    output wire [31:0] stat_drop_buf_full_cnt,
    output wire [31:0] stat_drop_len_err_cnt,
    output wire [31:0] stat_drop_blacklist_cnt,
    output wire [31:0] stat_drop_not_white_cnt,
    output wire [31:0] stat_drop_dst_miss_cnt,
    output wire [31:0] stat_win_frame_cnt,
    output wire [31:0] stat_win_byte_cnt,
    output wire [15:0] stat_last_drop_reason,
    output wire        stat_frame_storm_active,
    output wire        stat_byte_storm_active

);

    // -------------------------------------------------------------------------
    // 内部 GMII 信号：由 RGMII DDR 采样模块产生
    // -------------------------------------------------------------------------
    wire        gmii_rx_clk;
    wire        gmii_rxdv;
    wire [7:0]  gmii_rxd;
    wire        gmii_rxer;
    wire        rgmii_rx_clk_o;

    // 全局接收通路复位：外部系统复位或 RGMII 时钟处理 IP 失锁均保持复位。
    // 当前顶层直接接收 clk_125m，不存在本地 125 MHz 时钟 IP 的 locked 信号。
    wire rst;
    wire rgmii_rx_clk_locked;
    assign rst = sys_rst | (~rgmii_rx_clk_locked);


    // -------------------------------------------------------------------------
    // clk_wiz：对 PHY 提供的 RGMII RX 时钟进行处理，并输出锁定状态。
    // -------------------------------------------------------------------------
    clk_wiz u_rgmii_rx_clk_wiz (
        // 处理后的 RGMII 接收时钟
        .rgmii_rx_clk_o (rgmii_rx_clk_o),
        // 时钟稳定锁定指示
        .locked         (rgmii_rx_clk_locked),
        // PHY 输入的 RGMII 接收时钟
        .rgmii_rx_clk   (rgmii_rx_clk)
    );

    // -------------------------------------------------------------------------
    // RGMII 转 GMII：DDR 上/下沿各采 4 位组成 8 位数据，同时由 RX_CTL
    // 的两沿值还原 GMII RX_DV 和 RX_ER。
    // -------------------------------------------------------------------------
    rgmii_to_gmii u_rgmii_to_gmii (
        .rst_p       (rst),

        .rgmii_rx_clk(rgmii_rx_clk_o),
        .rgmii_rxd   (rgmii_rxd),
        .rgmii_rxdv  (rgmii_rxdv),

        .gmii_rx_clk (gmii_rx_clk),
        .gmii_rxdv   (gmii_rxdv),
        .gmii_rxd    (gmii_rxd),
        .gmii_rxer   (gmii_rxer)
    );

    // -------------------------------------------------------------------------
    // 以太网风暴过滤核心：接收侧使用 gmii_rx_clk，分类侧使用 clk_125m，
    // 两个时钟域之间只通过模块内部一级异步数据/描述符 FIFO 传递帧结果。
    // -------------------------------------------------------------------------
    eth_storm_filter #(
        .CLK_FREQ_HZ       (CLK_FREQ_HZ),
        .WINDOW_MS         (WINDOW_MS),
        .FRAME_MAX_PER_WIN (FRAME_MAX_PER_WIN),
        .BYTE_MAX_PER_WIN  (BYTE_MAX_PER_WIN),
        .MIN_FRAME_BYTES   (MIN_FRAME_BYTES),
        .MAX_FRAME_BYTES   (MAX_FRAME_BYTES),
        .CRC_TABLE_DEPTH   (CRC_TABLE_DEPTH),
        .DESC_DEPTH        (DESC_DEPTH)
    ) u_eth_storm_filter (
        .gmii_rx_clk           (gmii_rx_clk),
        .clk_125m              (clk_125m),
        .rst                   (rst),

        .gmii_rxdv             (gmii_rxdv),
        .gmii_rxd              (gmii_rxd),
        .gmii_rxer             (gmii_rxer),

        .cfg_filter_en         (cfg_filter_en),
        .cfg_dst_mac_en        (cfg_dst_mac_en),
        .cfg_local_mac         (cfg_local_mac),
        .cfg_allow_broadcast   (cfg_allow_broadcast),
        .cfg_allow_multicast   (cfg_allow_multicast),
        .cfg_multicast_mac     (cfg_multicast_mac),
        .cfg_multicast_mac_valid(cfg_multicast_mac_valid),
        .cfg_multicast_hash_clear(cfg_multicast_hash_clear),
        .cfg_whitelist_en      (cfg_whitelist_en),
        .cfg_blacklist_en      (cfg_blacklist_en),
        .cfg_dup_crc_en        (cfg_dup_crc_en),
        .cfg_frame_storm_en    (cfg_frame_storm_en),
        .cfg_byte_storm_en     (cfg_byte_storm_en),
        .cfg_crc_check_en      (cfg_crc_check_en),
        .cfg_frame_max_per_win (cfg_frame_max_per_win),
        .cfg_byte_max_per_win  (cfg_byte_max_per_win),
        .cfg_max_frame_bytes   (cfg_max_frame_bytes),
        .cfg_eth_type_goose    (cfg_eth_type_goose),
        .cfg_eth_type_sv       (cfg_eth_type_sv),
        .cfg_window_ms         (cfg_window_ms),
        .cfg_clear_stats       (cfg_clear_stats),

        .cfg_white0_en         (cfg_white0_en),
        .cfg_white0_mac        (cfg_white0_mac),
        .cfg_white1_en         (cfg_white1_en),
        .cfg_white1_mac        (cfg_white1_mac),
        .cfg_white2_en         (cfg_white2_en),
        .cfg_white2_mac        (cfg_white2_mac),
        .cfg_white3_en         (cfg_white3_en),
        .cfg_white3_mac        (cfg_white3_mac),

        .cfg_black0_en         (cfg_black0_en),
        .cfg_black0_mac        (cfg_black0_mac),
        .cfg_black1_en         (cfg_black1_en),
        .cfg_black1_mac        (cfg_black1_mac),
        .cfg_black2_en         (cfg_black2_en),
        .cfg_black2_mac        (cfg_black2_mac),
        .cfg_black3_en         (cfg_black3_en),
        .cfg_black3_mac        (cfg_black3_mac),

        .goose_data_rd_en     (goose_data_rd_en),
        .goose_data_dout      (goose_data_dout),
        .goose_data_empty     (goose_data_empty),
        .goose_desc_rd_en     (goose_desc_rd_en),
        .goose_desc_dout      (goose_desc_dout),
        .goose_desc_empty     (goose_desc_empty),

        .sv_data_rd_en        (sv_data_rd_en),
        .sv_data_dout         (sv_data_dout),
        .sv_data_empty        (sv_data_empty),
        .sv_desc_rd_en        (sv_desc_rd_en),
        .sv_desc_dout         (sv_desc_dout),
        .sv_desc_empty        (sv_desc_empty),

        .other_data_rd_en     (other_data_rd_en),
        .other_data_dout      (other_data_dout),
        .other_data_empty     (other_data_empty),
        .other_desc_rd_en     (other_desc_rd_en),
        .other_desc_dout      (other_desc_dout),
        .other_desc_empty     (other_desc_empty),

        .route_drop_fifo_full_valid    (route_drop_fifo_full_valid),
        .route_drop_fifo_full_class    (route_drop_fifo_full_class),
        .stat_route_drop_fifo_full_cnt (stat_route_drop_fifo_full_cnt),
        .stat_route_drop_goose_cnt     (stat_route_drop_goose_cnt),
        .stat_route_drop_sv_cnt        (stat_route_drop_sv_cnt),
        .stat_route_drop_other_cnt     (stat_route_drop_other_cnt),

        .drop_valid            (drop_valid),
        .drop_reason           (drop_reason),
        .stat_pass_cnt         (stat_pass_cnt),
        .stat_drop_crc_err_cnt (stat_drop_crc_err_cnt),
        .stat_drop_dup_crc_cnt (stat_drop_dup_crc_cnt),
        .stat_drop_frame_storm_cnt(stat_drop_frame_storm_cnt),
        .stat_drop_byte_storm_cnt (stat_drop_byte_storm_cnt),
        .stat_drop_buf_full_cnt   (stat_drop_buf_full_cnt),
        .stat_drop_len_err_cnt    (stat_drop_len_err_cnt),
        .stat_drop_blacklist_cnt  (stat_drop_blacklist_cnt),
        .stat_drop_not_white_cnt  (stat_drop_not_white_cnt),
        .stat_drop_dst_miss_cnt   (stat_drop_dst_miss_cnt),
        .stat_win_frame_cnt       (stat_win_frame_cnt),
        .stat_win_byte_cnt        (stat_win_byte_cnt),
        .stat_last_drop_reason    (stat_last_drop_reason),
        .stat_frame_storm_active  (stat_frame_storm_active),
        .stat_byte_storm_active   (stat_byte_storm_active)
    );

endmodule
```
