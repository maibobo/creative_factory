# eth_storm_filter

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_filter.v`
- SHA-256: `314baba08316534646d4b7a9ef2bc68d978026d79fe7f4f383ecf2853d6bd7cc`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// 模块名称：eth_storm_filter
// 层级位置：位于 RGMII-to-GMII 转换之后、外部 DMA 读取逻辑之前，是接收过滤核心。
//
// 数据通路：
//   1) eth_storm_main_fsm 在 gmii_rx_clk 域接收并解析帧，执行地址、ACL、
//      长度、风暴、重复 CRC 等判定。一级数据 FIFO 中不保存前导码/SFD/FCS；
//      对单层 0x8100 VLAN 帧还会删除 TPID/TCI，仅保留内层 EtherType。
//   2) eth_storm_stat 在 gmii_rx_clk 域按描述符提交时刻更新窗口和丢弃统计。
//   3) eth_storm_crc_clean 在 gmii_rx_clk 域管理重复帧 CRC 表及窗口 epoch。
//   4) eth_storm_tx_fsm 内的异步一级 FIFO 完成 gmii_rx_clk -> clk_125m
//      跨时钟传输；随后路由器按 EtherType 分类送入 GOOSE/SV/Other 二级 FIFO。
//
// 一级数据与描述符成对使用：接收期间先写帧字节，判定结束后才提交 53 位描述符。
// 描述符的 pass 位为 0 时，125 MHz 路由器只排空对应数据，不向二级 FIFO 转发。
// =============================================================================

module eth_storm_filter #(
    parameter integer CLK_FREQ_HZ          = 125000000,
    parameter integer WINDOW_MS            = 10,
    parameter integer FRAME_MAX_PER_WIN    = 1000,
    parameter integer BYTE_MAX_PER_WIN     = 8000000,
    parameter integer MIN_FRAME_BYTES      = 60,
    parameter integer MAX_FRAME_BYTES      = 1514,
    parameter integer CRC_TABLE_DEPTH      = 1024,
    parameter integer DESC_DEPTH           = 32
)(
    input  wire        gmii_rx_clk,
    input  wire        clk_125m,
    input  wire        rst,

    input  wire        gmii_rxdv,
    input  wire [7:0]  gmii_rxd,
    input  wire        gmii_rxer,

    input  wire        cfg_filter_en,
    input  wire        cfg_dst_mac_en,
    input  wire [47:0] cfg_local_mac,
    input  wire        cfg_allow_broadcast,
    input  wire        cfg_allow_multicast,
    input  wire [47:0] cfg_multicast_mac,
    input  wire        cfg_multicast_mac_valid,
    input  wire        cfg_multicast_hash_clear,
    input  wire        cfg_whitelist_en,
    input  wire        cfg_blacklist_en,
    input  wire        cfg_dup_crc_en,
    input  wire        cfg_frame_storm_en,
    input  wire        cfg_byte_storm_en,
    input  wire        cfg_crc_check_en,
    input  wire [31:0] cfg_frame_max_per_win,
    input  wire [31:0] cfg_byte_max_per_win,
    input  wire [15:0] cfg_max_frame_bytes,
    input  wire [15:0] cfg_eth_type_goose,
    input  wire [15:0] cfg_eth_type_sv,
    input  wire [31:0] cfg_window_ms,
    input  wire        cfg_clear_stats,

    input  wire        cfg_white0_en,
    input  wire [47:0] cfg_white0_mac,
    input  wire        cfg_white1_en,
    input  wire [47:0] cfg_white1_mac,
    input  wire        cfg_white2_en,
    input  wire [47:0] cfg_white2_mac,
    input  wire        cfg_white3_en,
    input  wire [47:0] cfg_white3_mac,

    input  wire        cfg_black0_en,
    input  wire [47:0] cfg_black0_mac,
    input  wire        cfg_black1_en,
    input  wire [47:0] cfg_black1_mac,
    input  wire        cfg_black2_en,
    input  wire [47:0] cfg_black2_mac,
    input  wire        cfg_black3_en,
    input  wire [47:0] cfg_black3_mac,

    // GOOSE 二级 FIFO 读接口：由外部 fifo_to_axi_full/DMA 逻辑在 clk_125m 域读取
    input  wire        goose_data_rd_en,
    output wire [7:0]  goose_data_dout,
    output wire        goose_data_empty,
    input  wire        goose_desc_rd_en,
    output wire [52:0] goose_desc_dout,
    output wire        goose_desc_empty,

    // SV 二级 FIFO 读接口：数据 FIFO 与描述符 FIFO 相互独立
    input  wire        sv_data_rd_en,
    output wire [7:0]  sv_data_dout,
    output wire        sv_data_empty,
    input  wire        sv_desc_rd_en,
    output wire [52:0] sv_desc_dout,
    output wire        sv_desc_empty,

    // Other 二级 FIFO 读接口
    input  wire        other_data_rd_en,
    output wire [7:0]  other_data_dout,
    output wire        other_data_empty,
    input  wire        other_desc_rd_en,
    output wire [52:0] other_desc_dout,
    output wire        other_desc_empty,

    // clk_125m 域路由拥塞统计：仅统计已经通过接收过滤、但因目标二级 FIFO
    // 满或将满而未被路由的帧；不包含接收侧已经判定为丢弃的帧。
    output wire        route_drop_fifo_full_valid,
    output wire [1:0]  route_drop_fifo_full_class,
    output wire [31:0] stat_route_drop_fifo_full_cnt,
    output wire [31:0] stat_route_drop_goose_cnt,
    output wire [31:0] stat_route_drop_sv_cnt,
    output wire [31:0] stat_route_drop_other_cnt,

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

    // 计算 CRC 表地址宽度，并保证深度为 1 时仍至少保留 1 位地址。
    function integer clog2_min1;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2_min1 = 0;
            while (v > 0) begin
                clog2_min1 = clog2_min1 + 1;
                v = v >> 1;
            end
            if (clog2_min1 == 0)
                clog2_min1 = 1;
        end
    endfunction

    // CRC 表项格式为 {valid, epoch, crc[31:0]}；epoch 每个统计窗口翻转。
    localparam integer CRC_IDX_W = clog2_min1(CRC_TABLE_DEPTH);
    localparam integer CRC_EPOCH_W = 1;
    localparam integer CRC_ENTRY_W = 1 + CRC_EPOCH_W + 32;
    localparam integer DESC_W      = 1 + 16 + 2 + 2 + 32;

    // 一级 FIFO 写侧：由 gmii_rx_clk 域主状态机产生，由 tx_fsm 内异步 FIFO 接收。
    // DESC_W=53，格式为 {pass, stored_len, mac_class, eth_type_class, frame_time}。
    wire              pfifo_wr_en;
    wire [7:0]        pfifo_din;
    wire              pfifo_full;
    wire              desc_fifo_wr_en;
    wire [DESC_W-1:0] desc_fifo_din;
    wire              desc_fifo_full;

    // 统计窗口状态反馈给主状态机，用于计算“本帧提交后”的计数及风暴判定。
    wire [CRC_EPOCH_W-1:0] active_epoch;
    // 保留给测试平台/调试层次引用的别名；功能逻辑直接使用 active_epoch。
    wire [CRC_EPOCH_W-1:0] win_epoch = active_epoch;
    wire                   win_rollover;
    wire [31:0]            win_frame_cnt_g;
    wire [31:0]            win_byte_cnt_g;
    wire                   frame_storm_active_g;
    wire                   byte_storm_active_g;
    wire [31:0]            frame_time_cnt_g;

    // 主状态机在 W_COMMIT 且描述符 FIFO 可写时产生 commit_can_push；
    // 同周期由统计模块一次性提交本帧判定、窗口计数和丢弃原因。
    wire        commit_can_push;
    wire        dec_count_window_q;
    wire [31:0] frame_cnt_next_q;
    wire [31:0] byte_cnt_next_q;
    wire        frame_over_q;
    wire        byte_over_q;
    wire        dec_pass_q;
    wire [15:0] dec_drop_reason_q;

    // 重复帧 CRC RAM 的正常访问口；初始化/后台清理仲裁位于 crc_clean 模块。
    wire                         crc_ram_normal_rd_en;
    wire [CRC_IDX_W-1:0]         crc_ram_normal_raddr;
    wire                         crc_ram_normal_we;
    wire [CRC_IDX_W-1:0]         crc_ram_normal_waddr;
    wire [CRC_ENTRY_W-1:0]       crc_ram_normal_din;
    wire [CRC_ENTRY_W-1:0]       crc_ram_dout;
    wire                         crc_init_done;
    wire                         crc_clear_pause_req;

    // 两级 FIFO 与分类路由。一级 FIFO 写时钟为 gmii_rx_clk、读时钟为 clk_125m，
    // 三组二级 FIFO 及其拥塞统计全部工作在 clk_125m 域。
    eth_storm_tx_fsm #(
        .DESC_W(DESC_W)
    ) u_tx_fsm (
        .gmii_rx_clk       (gmii_rx_clk      ),
        .clk_125m          (clk_125m         ),
        .rst               (rst              ),

        .pfifo_wr_en       (pfifo_wr_en      ),
        .pfifo_din         (pfifo_din        ),
        .pfifo_full        (pfifo_full       ),

        .desc_fifo_wr_en   (desc_fifo_wr_en  ),
        .desc_fifo_din     (desc_fifo_din    ),
        .desc_fifo_full    (desc_fifo_full   ),

        .cfg_clear_stats   (cfg_clear_stats  ),

        .goose_data_rd_en  (goose_data_rd_en ),
        .goose_data_dout   (goose_data_dout  ),
        .goose_data_empty  (goose_data_empty ),
        .goose_desc_rd_en  (goose_desc_rd_en ),
        .goose_desc_dout   (goose_desc_dout  ),
        .goose_desc_empty  (goose_desc_empty ),

        .sv_data_rd_en     (sv_data_rd_en    ),
        .sv_data_dout      (sv_data_dout     ),
        .sv_data_empty     (sv_data_empty    ),
        .sv_desc_rd_en     (sv_desc_rd_en    ),
        .sv_desc_dout      (sv_desc_dout     ),
        .sv_desc_empty     (sv_desc_empty    ),

        .other_data_rd_en  (other_data_rd_en ),
        .other_data_dout   (other_data_dout  ),
        .other_data_empty  (other_data_empty ),
        .other_desc_rd_en  (other_desc_rd_en ),
        .other_desc_dout   (other_desc_dout  ),
        .other_desc_empty  (other_desc_empty ),

        .route_drop_fifo_full_valid    (route_drop_fifo_full_valid    ),
        .route_drop_fifo_full_class    (route_drop_fifo_full_class    ),
        .stat_route_drop_fifo_full_cnt (stat_route_drop_fifo_full_cnt ),
        .stat_route_drop_goose_cnt     (stat_route_drop_goose_cnt     ),
        .stat_route_drop_sv_cnt        (stat_route_drop_sv_cnt        ),
        .stat_route_drop_other_cnt     (stat_route_drop_other_cnt     )
    );

    // 统计模块只在描述符具备提交条件并发出写使能时记账，避免仅在判定完成时
    // 提前更新统计。
    eth_storm_stat #(
        .CLK_FREQ_HZ       (CLK_FREQ_HZ       ),
        .WINDOW_MS         (WINDOW_MS         )
    ) u_stat (
        .gmii_rx_clk       (gmii_rx_clk       ),
        .rst               (rst               ),
        .cfg_clear_stats   (cfg_clear_stats   ),
        .cfg_filter_en     (cfg_filter_en     ),
        .cfg_frame_storm_en(cfg_frame_storm_en),
        .cfg_byte_storm_en (cfg_byte_storm_en ),
        .cfg_window_ms     (cfg_window_ms     ),

        .commit_can_push   (commit_can_push   ),
        .dec_count_window_q(dec_count_window_q),
        .frame_cnt_next_q  (frame_cnt_next_q  ),
        .byte_cnt_next_q   (byte_cnt_next_q   ),
        .frame_over_q      (frame_over_q      ),
        .byte_over_q       (byte_over_q       ),
        .dec_pass_q        (dec_pass_q        ),
        .dec_drop_reason_q (dec_drop_reason_q ),

        .active_epoch      (active_epoch      ),
        .win_rollover      (win_rollover      ),
        .win_frame_cnt_g   (win_frame_cnt_g   ),
        .win_byte_cnt_g    (win_byte_cnt_g    ),
        .frame_storm_active_g(frame_storm_active_g),
        .byte_storm_active_g (byte_storm_active_g ),
        .frame_time_cnt_g  (frame_time_cnt_g  ),

        .drop_valid        (drop_valid        ),
        .drop_reason       (drop_reason       ),
        .stat_pass_cnt     (stat_pass_cnt     ),
        .stat_drop_crc_err_cnt(stat_drop_crc_err_cnt),
        .stat_drop_dup_crc_cnt(stat_drop_dup_crc_cnt),
        .stat_drop_frame_storm_cnt(stat_drop_frame_storm_cnt),
        .stat_drop_byte_storm_cnt (stat_drop_byte_storm_cnt ),
        .stat_drop_buf_full_cnt   (stat_drop_buf_full_cnt   ),
        .stat_drop_len_err_cnt    (stat_drop_len_err_cnt    ),
        .stat_drop_blacklist_cnt  (stat_drop_blacklist_cnt  ),
        .stat_drop_not_white_cnt  (stat_drop_not_white_cnt  ),
        .stat_drop_dst_miss_cnt   (stat_drop_dst_miss_cnt   ),
        .stat_win_frame_cnt       (stat_win_frame_cnt       ),
        .stat_win_byte_cnt        (stat_win_byte_cnt        ),
        .stat_last_drop_reason    (stat_last_drop_reason    ),
        .stat_frame_storm_active  (stat_frame_storm_active  ),
        .stat_byte_storm_active   (stat_byte_storm_active   )
    );

    // CRC 表以窗口 epoch 区分新旧记录，并由后台清理逻辑完成上电初始化/回卷清理。
    eth_storm_crc_clean #(
        .CRC_TABLE_DEPTH   (CRC_TABLE_DEPTH   ),
        .CRC_IDX_W         (CRC_IDX_W         ),
        .CRC_ENTRY_W       (CRC_ENTRY_W       )
    ) u_crc_clean (
        .gmii_rx_clk       (gmii_rx_clk       ),
        .rst               (rst               ),
        .win_rollover      (win_rollover      ),
        .win_epoch         (active_epoch      ),
        .crc_clear_pause_req(crc_clear_pause_req),

        .normal_rd_en      (crc_ram_normal_rd_en),
        .normal_raddr      (crc_ram_normal_raddr),
        .normal_we         (crc_ram_normal_we   ),
        .normal_waddr      (crc_ram_normal_waddr),
        .normal_din        (crc_ram_normal_din  ),
        .normal_dout       (crc_ram_dout        ),
        .crc_init_done     (crc_init_done       )
    );

    // GMII 接收、协议字段提取和过滤决策均位于 gmii_rx_clk 域。
    eth_storm_main_fsm #(
        .FRAME_MAX_PER_WIN (FRAME_MAX_PER_WIN ),
        .BYTE_MAX_PER_WIN  (BYTE_MAX_PER_WIN  ),
        .MIN_FRAME_BYTES   (MIN_FRAME_BYTES   ),
        .MAX_FRAME_BYTES   (MAX_FRAME_BYTES   ),
        .CRC_TABLE_DEPTH   (CRC_TABLE_DEPTH   ),
        .CRC_IDX_W         (CRC_IDX_W         ),
        .CRC_ENTRY_W       (CRC_ENTRY_W       )
    ) u_main_fsm (
        .gmii_rx_clk       (gmii_rx_clk       ),
        .rst               (rst               ),
        .gmii_rxdv         (gmii_rxdv         ),
        .gmii_rxd          (gmii_rxd          ),
        .gmii_rxer         (gmii_rxer         ),

        .cfg_filter_en     (cfg_filter_en     ),
        .cfg_dst_mac_en    (cfg_dst_mac_en    ),
        .cfg_local_mac     (cfg_local_mac     ),
        .cfg_allow_broadcast(cfg_allow_broadcast),
        .cfg_allow_multicast   (cfg_allow_multicast),
        .cfg_multicast_mac     (cfg_multicast_mac),
        .cfg_multicast_mac_valid(cfg_multicast_mac_valid),
        .cfg_multicast_hash_clear(cfg_multicast_hash_clear),
        .cfg_whitelist_en  (cfg_whitelist_en  ),
        .cfg_blacklist_en  (cfg_blacklist_en  ),
        .cfg_dup_crc_en    (cfg_dup_crc_en    ),
        .cfg_frame_storm_en(cfg_frame_storm_en),
        .cfg_byte_storm_en (cfg_byte_storm_en ),
        .cfg_crc_check_en  (cfg_crc_check_en  ),
        .cfg_frame_max_per_win(cfg_frame_max_per_win),
        .cfg_byte_max_per_win (cfg_byte_max_per_win ),
        .cfg_max_frame_bytes  (cfg_max_frame_bytes  ),
        .cfg_eth_type_goose   (cfg_eth_type_goose   ),
        .cfg_eth_type_sv      (cfg_eth_type_sv      ),

        .cfg_white0_en     (cfg_white0_en     ),
        .cfg_white0_mac    (cfg_white0_mac    ),
        .cfg_white1_en     (cfg_white1_en     ),
        .cfg_white1_mac    (cfg_white1_mac    ),
        .cfg_white2_en     (cfg_white2_en     ),
        .cfg_white2_mac    (cfg_white2_mac    ),
        .cfg_white3_en     (cfg_white3_en     ),
        .cfg_white3_mac    (cfg_white3_mac    ),
        .cfg_black0_en     (cfg_black0_en     ),
        .cfg_black0_mac    (cfg_black0_mac    ),
        .cfg_black1_en     (cfg_black1_en     ),
        .cfg_black1_mac    (cfg_black1_mac    ),
        .cfg_black2_en     (cfg_black2_en     ),
        .cfg_black2_mac    (cfg_black2_mac    ),
        .cfg_black3_en     (cfg_black3_en     ),
        .cfg_black3_mac    (cfg_black3_mac    ),

        .pfifo_full        (pfifo_full        ),
        .desc_fifo_full    (desc_fifo_full    ),
        .pfifo_wr_en       (pfifo_wr_en       ),
        .pfifo_din         (pfifo_din         ),
        .desc_fifo_wr_en   (desc_fifo_wr_en   ),
        .desc_fifo_din     (desc_fifo_din     ),

        .win_rollover      (win_rollover      ),
        .active_epoch      (active_epoch      ),
        .win_frame_cnt_g   (win_frame_cnt_g   ),
        .win_byte_cnt_g    (win_byte_cnt_g    ),
        .frame_storm_active_g(frame_storm_active_g),
        .byte_storm_active_g (byte_storm_active_g ),
        .frame_time_cnt_g  (frame_time_cnt_g  ),

        .crc_init_done     (crc_init_done     ),
        .crc_ram_dout      (crc_ram_dout      ),
        .crc_ram_normal_rd_en(crc_ram_normal_rd_en),
        .crc_ram_normal_raddr(crc_ram_normal_raddr),
        .crc_ram_normal_we (crc_ram_normal_we ),
        .crc_ram_normal_waddr(crc_ram_normal_waddr),
        .crc_ram_normal_din(crc_ram_normal_din),
        .crc_clear_pause_req(crc_clear_pause_req),

        .commit_can_push   (commit_can_push   ),
        .dec_count_window_q(dec_count_window_q),
        .frame_cnt_next_q  (frame_cnt_next_q  ),
        .byte_cnt_next_q   (byte_cnt_next_q   ),
        .frame_over_q      (frame_over_q      ),
        .byte_over_q       (byte_over_q       ),
        .dec_pass_q        (dec_pass_q        ),
        .dec_drop_reason_q (dec_drop_reason_q )
    );

endmodule
```
