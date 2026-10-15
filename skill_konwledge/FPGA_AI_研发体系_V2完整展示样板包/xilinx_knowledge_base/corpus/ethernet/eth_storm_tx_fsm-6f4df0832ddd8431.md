# eth_storm_tx_fsm

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_tx_fsm.v`
- SHA-256: `6f4df0832ddd8431fbfac99e39103ad8488cf00bc04260b57aa41171ac66ddc0`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// 模块名称：eth_storm_tx_fsm
// 层级位置：eth_storm_filter 内的数据缓冲和分类输出子系统。
//
// 两级缓冲结构：
//   一级：公共帧数据 FIFO + 公共描述符 FIFO，写侧为 gmii_rx_clk，读侧为
//         clk_125m；两个异步 FWFT FIFO 共同完成接收域到本地处理域的跨时钟传输。
//   路由：先读取 53 位描述符；接收侧 pass=0 的帧仅从公共数据 FIFO 排空，
//         pass=1 的帧按 EtherType 类别选择 GOOSE、SV 或 Other。
//   二级：三路各自包含一个 8 位数据 FIFO 和一个 53 位描述符 FIFO，均工作在
//         clk_125m。每帧完整数据先写入，随后才写对应描述符。
//   输出：直接导出六个 FIFO 的读接口，供外部 fifo_to_axi_full/DMA 读取。
//
// 二级目标在准入检查时已满/将满时不反压公共 FIFO，而是排空该帧并记录路由
// 拥塞丢弃；因此单个分类通道拥塞不会永久阻塞其他分类。旧的逐通道发送状态机
// eth_storm_channel_tx_fsm 不参与当前结构。
// =============================================================================

module eth_storm_tx_fsm #(
    parameter integer DESC_W = 53
)(
    input  wire                  gmii_rx_clk,
    input  wire                  clk_125m,
    input  wire                  rst,
    input  wire                  cfg_clear_stats,

    // 一级公共 FIFO 写侧，信号均来自 gmii_rx_clk 域接收/判定状态机
    input  wire                  pfifo_wr_en,
    input  wire [7:0]            pfifo_din,
    output wire                  pfifo_full,

    input  wire                  desc_fifo_wr_en,
    input  wire [DESC_W-1:0]     desc_fifo_din,
    output wire                  desc_fifo_full,

    // GOOSE 二级 FIFO 读侧，外部读取逻辑与本模块同处 clk_125m 域
    input  wire                  goose_data_rd_en,
    output wire [7:0]            goose_data_dout,
    output wire                  goose_data_empty,
    input  wire                  goose_desc_rd_en,
    output wire [DESC_W-1:0]     goose_desc_dout,
    output wire                  goose_desc_empty,

    // SV 二级 FIFO 读侧
    input  wire                  sv_data_rd_en,
    output wire [7:0]            sv_data_dout,
    output wire                  sv_data_empty,
    input  wire                  sv_desc_rd_en,
    output wire [DESC_W-1:0]     sv_desc_dout,
    output wire                  sv_desc_empty,

    // Other 二级 FIFO 读侧
    input  wire                  other_data_rd_en,
    output wire [7:0]            other_data_dout,
    output wire                  other_data_empty,
    input  wire                  other_desc_rd_en,
    output wire [DESC_W-1:0]     other_desc_dout,
    output wire                  other_desc_empty,

    // clk_125m 域的路由拥塞单拍事件及累计计数
    output wire                  route_drop_fifo_full_valid,
    output wire [1:0]            route_drop_fifo_full_class,
    output wire [31:0]           stat_route_drop_fifo_full_cnt,
    output wire [31:0]           stat_route_drop_goose_cnt,
    output wire [31:0]           stat_route_drop_sv_cnt,
    output wire [31:0]           stat_route_drop_other_cnt
);

    // -------------------------------------------------------------------------
    // 一级公共异步 FIFO：gmii_rx_clk -> clk_125m。
    // 两个 FIFO 均按 FWFT（首字直通）方式使用：empty=0 时 dout 已是队首内容，
    // 路由器在读取使能拍直接锁存描述符或消费当前数据字节。
    // -------------------------------------------------------------------------
    wire [7:0]            common_data_dout;
    wire                  common_data_empty;
    wire                  common_data_rd_en;

    eth_storm_frame_fifo u_common_frame_fifo (
        .rst      (rst                ),
        .wr_clk   (gmii_rx_clk        ),
        .rd_clk   (clk_125m           ),
        .din      (pfifo_din          ),
        .wr_en    (pfifo_wr_en        ),
        .rd_en    (common_data_rd_en  ),
        .dout     (common_data_dout   ),
        .full     (pfifo_full         ),
        .empty    (common_data_empty  )
    );

    wire [DESC_W-1:0]     common_desc_dout;
    wire                  common_desc_empty;
    wire                  common_desc_rd_en;

    eth_storm_desc_fifo u_common_desc_fifo (
        .rst      (rst                ),
        .wr_clk   (gmii_rx_clk        ),
        .rd_clk   (clk_125m           ),
        .din      (desc_fifo_din      ),
        .wr_en    (desc_fifo_wr_en    ),
        .rd_en    (common_desc_rd_en  ),
        .dout     (common_desc_dout   ),
        .full     (desc_fifo_full     ),
        .empty    (common_desc_empty  )
    );

    // -------------------------------------------------------------------------
    // 二级 GOOSE/SV/Other FIFO 对。这六个模块由 Vivado FIFO Generator 生成，
    // 当前 RTL 只负责例化。数据 FIFO 的 prog_full 阈值供路由器做整帧准入判断，
    // 描述符 FIFO 的 full 也在准入时检查，以便完整帧写完后提交对应描述符。
    // -------------------------------------------------------------------------
    wire [7:0]          route_data_din;
    wire [DESC_W-1:0]   route_desc_din;

    wire                goose_data_wr_en;
    wire                goose_data_full;
    wire                goose_data_prog_full;

    wire                goose_desc_wr_en;
    wire                goose_desc_full;

    eth_storm_channel_data_fifo u_goose_data_fifo (
        .clk       (clk_125m             ),
        .srst      (rst                  ),
        .din       (route_data_din       ),
        .wr_en     (goose_data_wr_en     ),
        .rd_en     (goose_data_rd_en     ),
        .dout      (goose_data_dout      ),
        .full      (goose_data_full      ),
        .empty     (goose_data_empty     ),
        .prog_full (goose_data_prog_full )
    );

    eth_storm_channel_desc_fifo u_goose_desc_fifo (
        .clk       (clk_125m             ),
        .srst      (rst                  ),
        .din       (route_desc_din       ),
        .wr_en     (goose_desc_wr_en     ),
        .rd_en     (goose_desc_rd_en     ),
        .dout      (goose_desc_dout      ),
        .full      (goose_desc_full      ),
        .empty     (goose_desc_empty     )
    );

    wire                sv_data_wr_en;
    wire                sv_data_full;
    wire                sv_data_prog_full;

    wire                sv_desc_wr_en;
    wire                sv_desc_full;

    eth_storm_channel_data_fifo u_sv_data_fifo (
        .clk       (clk_125m          ),
        .srst      (rst               ),
        .din       (route_data_din    ),
        .wr_en     (sv_data_wr_en     ),
        .rd_en     (sv_data_rd_en     ),
        .dout      (sv_data_dout      ),
        .full      (sv_data_full      ),
        .empty     (sv_data_empty     ),
        .prog_full (sv_data_prog_full )
    );

    eth_storm_channel_desc_fifo u_sv_desc_fifo (
        .clk       (clk_125m          ),
        .srst      (rst               ),
        .din       (route_desc_din    ),
        .wr_en     (sv_desc_wr_en     ),
        .rd_en     (sv_desc_rd_en     ),
        .dout      (sv_desc_dout      ),
        .full      (sv_desc_full      ),
        .empty     (sv_desc_empty     )
    );

    wire                other_data_wr_en;
    wire                other_data_full;
    wire                other_data_prog_full;

    wire                other_desc_wr_en;
    wire                other_desc_full;

    eth_storm_channel_data_fifo u_other_data_fifo (
        .clk       (clk_125m             ),
        .srst      (rst                  ),
        .din       (route_data_din       ),
        .wr_en     (other_data_wr_en     ),
        .rd_en     (other_data_rd_en     ),
        .dout      (other_data_dout      ),
        .full      (other_data_full      ),
        .empty     (other_data_empty     ),
        .prog_full (other_data_prog_full )
    );

    eth_storm_channel_desc_fifo u_other_desc_fifo (
        .clk       (clk_125m             ),
        .srst      (rst                  ),
        .din       (route_desc_din       ),
        .wr_en     (other_desc_wr_en     ),
        .rd_en     (other_desc_rd_en     ),
        .dout      (other_desc_dout      ),
        .full      (other_desc_full      ),
        .empty     (other_desc_empty     )
    );

    // -------------------------------------------------------------------------
    // 公共 FIFO 到分类 FIFO 的路由器。三路共用 route_data_din/route_desc_din，
    // 由互斥写使能选择唯一目标；接收侧丢弃与路由拥塞丢弃都只排空一级数据。
    // -------------------------------------------------------------------------
    eth_storm_type_router #(
        .DESC_W(DESC_W)
    ) u_type_router (
        .clk                    (clk_125m             ),
        .rst                    (rst                  ),
        .cfg_clear_stats        (cfg_clear_stats      ),

        .common_data_dout       (common_data_dout     ),
        .common_data_empty      (common_data_empty    ),
        .common_data_rd_en      (common_data_rd_en    ),
        .common_desc_dout       (common_desc_dout     ),
        .common_desc_empty      (common_desc_empty    ),
        .common_desc_rd_en      (common_desc_rd_en    ),

        .goose_data_full        (goose_data_full      ),
        .goose_data_prog_full   (goose_data_prog_full ),
        .goose_desc_full        (goose_desc_full      ),
        .goose_data_wr_en       (goose_data_wr_en     ),
        .goose_desc_wr_en       (goose_desc_wr_en     ),

        .sv_data_full           (sv_data_full         ),
        .sv_data_prog_full      (sv_data_prog_full    ),
        .sv_desc_full           (sv_desc_full         ),
        .sv_data_wr_en          (sv_data_wr_en        ),
        .sv_desc_wr_en          (sv_desc_wr_en        ),

        .other_data_full        (other_data_full      ),
        .other_data_prog_full   (other_data_prog_full ),
        .other_desc_full        (other_desc_full      ),
        .other_data_wr_en       (other_data_wr_en     ),
        .other_desc_wr_en       (other_desc_wr_en     ),

        .route_data_din         (route_data_din       ),
        .route_desc_din         (route_desc_din       ),

        .route_drop_fifo_full_valid    (route_drop_fifo_full_valid    ),
        .route_drop_fifo_full_class    (route_drop_fifo_full_class    ),
        .stat_route_drop_fifo_full_cnt (stat_route_drop_fifo_full_cnt ),
        .stat_route_drop_goose_cnt     (stat_route_drop_goose_cnt     ),
        .stat_route_drop_sv_cnt        (stat_route_drop_sv_cnt        ),
        .stat_route_drop_other_cnt     (stat_route_drop_other_cnt     )
    );

endmodule
```
