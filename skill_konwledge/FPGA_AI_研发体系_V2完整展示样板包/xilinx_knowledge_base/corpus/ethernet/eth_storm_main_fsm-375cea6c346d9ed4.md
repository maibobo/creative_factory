# eth_storm_main_fsm

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_main_fsm.v`
- SHA-256: `375cea6c346d9ed48ff39802f7580f6cb9737f00c46def72676aafe27be91869`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// 模块名称：eth_storm_main_fsm
// 时钟域  ：gmii_rx_clk；复位 rst 为高有效异步复位。
// 上下游  ：从 rgmii_to_gmii 接收 8 位 GMII 字节流，向一级异步数据 FIFO 和
//           描述符 FIFO 写入结果，并与统计模块、重复 CRC 表协同工作。
//
// 处理流程：
//   W_IDLE/W_PREAMBLE   识别至少连续 7 个 0x55 和随后 1 个 0xD5；
//   W_RECV              解析 DA、SA、EtherType/单层 VLAN，缓存并写帧数据；
//   W_DISCARD_RECV      发生一级 FIFO 拥塞或超长后继续接收/解析，但不再写数据；
//   W_ACL_CHK           锁存目的地址、黑白名单和报文类型分类；
//   W_CRC_RD/W_CRC_CHK  查询当前窗口的重复 CRC 表；
//   W_DECIDE/W_COMMIT   按固定优先级生成唯一丢弃原因，并提交 53 位描述符。
//
// 协议字段直接从当前 GMII 字节解析。末尾 4 字节延迟链仅用于截留 FCS；若检测到
// 单层 TPID=0x8100，还会在写 FIFO 时删除 TPID/TCI。因此 dec_len 表示线侧帧长
// （不含 FCS、仍含 VLAN 4 字节），dec_store_len 表示一级 FIFO 中实际保存的长度。
// =============================================================================

module eth_storm_main_fsm #(
    parameter integer FRAME_MAX_PER_WIN = 1000,
    parameter integer BYTE_MAX_PER_WIN  = 8000000,
    parameter integer MIN_FRAME_BYTES   = 60,
    parameter integer MAX_FRAME_BYTES   = 1514,
    parameter integer CRC_TABLE_DEPTH   = 1024,
    parameter integer CRC_IDX_W         = 10,
    parameter integer CRC_ENTRY_W       = 34
)(
    // GMII 接收时钟、复位及逐字节接收接口
    input  wire        gmii_rx_clk,
    input  wire        rst,

    input  wire        gmii_rxdv,
    input  wire [7:0]  gmii_rxd,
    input  wire        gmii_rxer,

    // 过滤总开关、各功能开关及运行时阈值；阈值为 0 时使用模块参数默认值
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

    // 源 MAC 白名单和黑名单各 4 项；对应功能使能后才参与最终判定
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

    // 一级异步 FIFO 的 gmii_rx_clk 写侧。数据先写入，帧结束并完成判定后写描述符。
    input  wire        pfifo_full,
    input  wire        desc_fifo_full,
    output reg         pfifo_wr_en,
    output reg  [7:0]  pfifo_din,
    output reg         desc_fifo_wr_en,
    output wire [52:0] desc_fifo_din,

    // 当前统计窗口状态，由 eth_storm_stat 在同一 gmii_rx_clk 域提供
    input  wire        win_rollover,
    input  wire [0:0]  active_epoch,
    input  wire [31:0] win_frame_cnt_g,
    input  wire [31:0] win_byte_cnt_g,
    input  wire        frame_storm_active_g,
    input  wire        byte_storm_active_g,
    input  wire [31:0] frame_time_cnt_g,

    // 重复帧 CRC 表正常访问口；crc_clean 负责与后台初始化/清理访问仲裁
    input  wire                     crc_init_done,
    input  wire [CRC_ENTRY_W-1:0]   crc_ram_dout,
    output wire                     crc_ram_normal_rd_en,
    output wire [CRC_IDX_W-1:0]     crc_ram_normal_raddr,
    output wire                     crc_ram_normal_we,
    output wire [CRC_IDX_W-1:0]     crc_ram_normal_waddr,
    output wire [CRC_ENTRY_W-1:0]   crc_ram_normal_din,
    output wire                     crc_clear_pause_req,

    // 提交给统计模块的判定快照；仅 commit_can_push 有效时才允许记账
    output wire        commit_can_push,
    output reg         dec_count_window_q,
    output reg  [31:0] frame_cnt_next_q,
    output reg  [31:0] byte_cnt_next_q,
    output reg         frame_over_q,
    output reg         byte_over_q,
    output reg         dec_pass_q,
    output reg  [15:0] dec_drop_reason_q
);

    // 四项 ACL 采用并行精确匹配，比较对象是解析出的源 MAC。
    function acl_white_match;
        input [47:0] mac;
        begin
            acl_white_match = (cfg_white0_en && (mac == cfg_white0_mac)) |
                              (cfg_white1_en && (mac == cfg_white1_mac)) |
                              (cfg_white2_en && (mac == cfg_white2_mac)) |
                              (cfg_white3_en && (mac == cfg_white3_mac));
        end
    endfunction

    function acl_black_match;
        input [47:0] mac;
        begin
            acl_black_match = (cfg_black0_en && (mac == cfg_black0_mac)) |
                              (cfg_black1_en && (mac == cfg_black1_mac)) |
                              (cfg_black2_en && (mac == cfg_black2_mac)) |
                              (cfg_black3_en && (mac == cfg_black3_mac));
        end
    endfunction

    localparam [15:0] MIN_FRAME_BYTES_16 = MIN_FRAME_BYTES;
    localparam [15:0] MAX_FRAME_BYTES_16 = MAX_FRAME_BYTES;
    localparam integer CRC_EPOCH_W = 1;

    // 丢弃原因采用 one-hot 位定义，但组合判定按下列顺序只选择一个原因。
    localparam [15:0] DROP_NONE        = 16'h0000;
    localparam [15:0] DROP_CRC_ERR     = 16'h0001;
    localparam [15:0] DROP_DUP_CRC     = 16'h0002;
    localparam [15:0] DROP_FRAME_STORM = 16'h0004;
    localparam [15:0] DROP_BYTE_STORM  = 16'h0008;
    localparam [15:0] DROP_BUF_FULL    = 16'h0010;
    localparam [15:0] DROP_LEN_ERR     = 16'h0020;
    localparam [15:0] DROP_BLACKLIST   = 16'h0040;
    localparam [15:0] DROP_NOT_WHITE   = 16'h0080;
    localparam [15:0] DROP_DST_MISS    = 16'h0100;

    // 接收/判定状态编码。
    localparam [3:0] W_IDLE            = 4'd0;
    localparam [3:0] W_PREAMBLE        = 4'd1;
    localparam [3:0] W_RECV            = 4'd2;
    localparam [3:0] W_DISCARD_RECV    = 4'd3;
    localparam [3:0] W_ACL_CHK         = 4'd4;
    localparam [3:0] W_CRC_RD          = 4'd5;
    localparam [3:0] W_CRC_CHK         = 4'd6;
    localparam [3:0] W_DECIDE          = 4'd7;
    localparam [3:0] W_COMMIT          = 4'd8;

    localparam [1:0] MAC_CLASS_UNICAST   = 2'd0;
    localparam [1:0] MAC_CLASS_BROADCAST = 2'd1;
    localparam [1:0] MAC_CLASS_MULTICAST = 2'd2;
    localparam [1:0] MAC_CLASS_RESERVED  = 2'd3;

    localparam [1:0] ETH_TYPE_CLASS_OTHER    = 2'd0;
    localparam [1:0] ETH_TYPE_CLASS_GOOSE    = 2'd1;
    localparam [1:0] ETH_TYPE_CLASS_SV       = 2'd2;
    localparam [1:0] ETH_TYPE_CLASS_RESERVED = 2'd3;

    localparam [15:0] ETH_TPID_VLAN  = 16'h8100;

    localparam [31:0] CRC32_ETH_RESIDUE = 32'h2144_DF1C;

    reg [3:0]  w_state;
    reg [2:0]  preamble_cnt;   // SFD 前已经连续收到的 0x55 个数，饱和到 7

    // 接收期字节计数和 4 字节延迟链。hold0 最早、hold3 最新；帧结束时恰为 FCS。
    reg [31:0] rx_total_cnt;
    reg [15:0] rx_byte_cnt;       // SFD 后当前 GMII 字节序号，仅用于字段解析
    reg [2:0]  hold_cnt;
    reg [7:0]  hold0;
    reg [7:0]  hold1;
    reg [7:0]  hold2;
    reg [7:0]  hold3;

    // wr_* 为正在接收帧的现场信息；长度/错误标志在接收期间累积。
    reg [15:0] wr_len_seen;
    reg [15:0] wr_len_stored;
    reg        wr_len_err;
    reg        wr_buf_full_err;
    reg        wr_desc_full_err;
    reg        wr_rx_error_seen;
    reg        wr_meta_valid;
    reg [47:0] wr_dst_mac;
    reg [47:0] wr_src_mac;
    reg [15:0] wr_eth_type;
    reg        wr_vlan_tag_present;
    reg [7:0]  wr_tpid_hi;
    reg [31:0] wr_frame_time;

    // dec_* 为帧结束后的判定快照，后续多周期 ACL/CRC/风暴判定不再依赖 wr_*。
    reg [15:0] dec_len;
    reg [15:0] dec_store_len;
    reg [31:0] dec_crc;
    reg        dec_crc_ok;
    reg        dec_len_err;
    reg        dec_buf_full_err;
    reg        dec_desc_full_err;
    reg        dec_meta_valid;
    reg [47:0] dec_dst_mac;
    reg [5:0]  dec_dst_hash_idx;
    reg [47:0] dec_src_mac;
    reg [15:0] dec_eth_type;
    reg        dec_vlan_tag_present;
    reg [1:0]  dec_mac_class;
    reg [1:0]  dec_eth_type_class;
    reg [31:0] dec_frame_time;

    // 地址与 ACL 比较结果在 W_ACL_CHK 锁存。
    reg        acl_white_hit_q;
    reg        acl_black_hit_q;
    reg        dst_mac_hit_q;

    // 重复 CRC 查询使用“有效位 + 1 位窗口 epoch + 32 位 FCS”进行精确确认；
    // 低位折叠值只负责索引，索引冲突不会直接被判为重复帧。
    reg [CRC_IDX_W-1:0]   dec_crc_idx;
    reg [CRC_EPOCH_W-1:0] dec_epoch;
    reg [CRC_ENTRY_W-1:0] crc_rd_q;
    reg                   crc_dup_hit_q;
    reg                   crc_check_allowed_q;

    reg [1:0]  dec_mac_class_q;
    reg [1:0]  dec_eth_type_class_q;
    reg [31:0] dec_frame_time_q;

    // 本帧对应的窗口计数候选值、越限结果和最终判定。
    reg [31:0] frame_cnt_next;
    reg [31:0] byte_cnt_next;
    reg        frame_over_new;
    reg        byte_over_new;
    reg        frame_over;
    reg        byte_over;
    reg [15:0] dec_drop_reason;
    reg        dec_pass;
    reg        dec_count_window;

    // 软件配置值为 0 时回退到参数默认值；若回退后的有效风暴阈值仍为 0，
    // 对应的 frame_over_new/byte_over_new 才恒为不越限。
    wire [15:0] eff_max_frame_bytes = (cfg_max_frame_bytes == 16'd0) ? MAX_FRAME_BYTES_16 : cfg_max_frame_bytes;
    wire [31:0] eff_frame_max = (cfg_frame_max_per_win == 32'd0) ? FRAME_MAX_PER_WIN : cfg_frame_max_per_win;
    wire [31:0] eff_byte_max  = (cfg_byte_max_per_win  == 32'd0) ? BYTE_MAX_PER_WIN  : cfg_byte_max_per_win;

    // 长度上限以线侧去 FCS 长度判断。VLAN 帧允许比去标签后的配置长度多 4 字节；
    // hold_byte_is_vlan_tag 标识即将从延迟链释放的 TPID/TCI 四个字节。
    wire [15:0] rx_len_plus1 = wr_len_seen + 16'd1;
    wire        wr_vlan_len_active = wr_vlan_tag_present;
    wire        hold_byte_is_vlan_tag = wr_vlan_tag_present &&
                                        (wr_len_seen >= 16'd12) &&
                                        (wr_len_seen <= 16'd15);
    wire [16:0] eff_max_seen_bytes = {1'b0, eff_max_frame_bytes} +
                                     ((wr_vlan_len_active && (eff_max_frame_bytes <= 16'hFFFB)) ? 17'd4 : 17'd0);
    wire [16:0] dec_eff_max_seen_bytes = {1'b0, eff_max_frame_bytes} +
                                         ((dec_vlan_tag_present && (eff_max_frame_bytes <= 16'hFFFB)) ? 17'd4 : 17'd0);
    wire        rx_len_over_next = (wr_len_seen == 16'hFFFF) ||
                                   ((eff_max_frame_bytes != 16'd0) && ({1'b0, rx_len_plus1} > eff_max_seen_bytes));
    wire        dec_len_over_max = (eff_max_frame_bytes != 16'd0) &&
                                   ({1'b0, dec_len} > dec_eff_max_seen_bytes);

    // 目的地址允许条件：本机单播，或已允许的广播，或组地址位有效且命中 64 位
    // 组播 Hash 表。以太网组地址位是首个线上 MAC 字节的 bit0，对应 dec_dst_mac[40]；
    // 广播单独判断，不进入组播 Hash 查询。
    wire dst_is_broadcast = (dec_dst_mac == 48'hFFFF_FFFF_FFFF);
    wire dst_is_multicast_addr = dec_dst_mac[40] && !dst_is_broadcast;
    wire dst_multicast_hash_hit;
    wire dst_is_multicast = cfg_allow_multicast &&
                            dst_is_multicast_addr &&
                            dst_multicast_hash_hit;
    wire dst_mac_match = (dec_dst_mac == cfg_local_mac) ||
                         (cfg_allow_broadcast && dst_is_broadcast) ||
                         dst_is_multicast;

    wire [1:0] dec_mac_class_wire = dst_is_broadcast ? MAC_CLASS_BROADCAST :
                                    (dst_is_multicast_addr ? MAC_CLASS_MULTICAST : MAC_CLASS_UNICAST);
    wire [1:0] dec_eth_type_class_wire = (dec_eth_type == cfg_eth_type_goose) ? ETH_TYPE_CLASS_GOOSE :
                                         ((dec_eth_type == cfg_eth_type_sv) ? ETH_TYPE_CLASS_SV : ETH_TYPE_CLASS_OTHER);

    // 接收到的四个 FCS 字节按线路字节序重组为 32 位值，并折叠生成 CRC 表索引。
    wire [15:0] dec_crc_hash16 = dec_crc[15:0] ^ dec_crc[31:16];
    wire [31:0] rx_fcs_wire    = {hold3, hold2, hold1, hold0};
    wire [15:0] rx_fcs_hash16  = rx_fcs_wire[15:0] ^ rx_fcs_wire[31:16];

    wire        fcs_crc_init;
    wire        fcs_crc_en;
    wire [31:0] fcs_crc_result;

    // 在合法 SFD 周期初始化 CRC；随后对 DA 至 FCS 的所有有效字节递推。
    // 启用 FCS 检查时，包含 FCS 的结果必须等于以太网固定 residue。
    assign fcs_crc_init = (w_state == W_PREAMBLE) && gmii_rxdv &&
                          (preamble_cnt == 3'd7) && (gmii_rxd == 8'hD5);
    assign fcs_crc_en   = ((w_state == W_RECV) || (w_state == W_DISCARD_RECV)) && gmii_rxdv;

    crc32_d8 u_fcs_crc32_d8 (
        .clk        (gmii_rx_clk   ),
        .rst_p      (rst           ),
        .data       (gmii_rxd      ),
        .crc_init   (fcs_crc_init  ),
        .crc_en     (fcs_crc_en    ),
        .crc_result (fcs_crc_result)
    );

    // 另一路 CRC 仅覆盖目的 MAC 的 6 个线上字节，其结果高 6 位作为 64 位组播表索引。
    wire        dst_mac_crc_init = fcs_crc_init;
    wire        dst_mac_crc_en = ((w_state == W_RECV) ||
                                  (w_state == W_DISCARD_RECV)) &&
                                 gmii_rxdv && (rx_byte_cnt < 16'd6);
    wire [31:0] dst_mac_crc_result;

    crc32_d8 u_dst_mac_crc32_d8 (
        .clk        (gmii_rx_clk      ),
        .rst_p      (rst              ),
        .data       (gmii_rxd         ),
        .crc_init   (dst_mac_crc_init ),
        .crc_en     (dst_mac_crc_en   ),
        .crc_result (dst_mac_crc_result)
    );

    eth_storm_multicast_hash u_multicast_hash (
        .gmii_rx_clk              (gmii_rx_clk),
        .rst                      (rst),
        .cfg_multicast_mac        (cfg_multicast_mac),
        .cfg_multicast_mac_valid  (cfg_multicast_mac_valid),
        .cfg_multicast_hash_clear (cfg_multicast_hash_clear),
        .lookup_hash_index        (dec_dst_hash_idx),
        .lookup_hash_hit          (dst_multicast_hash_hit)
    );

    // “提交”以描述符具备可写条件为准：状态机据此发出描述符写使能、更新统计，
    // 并在通过且启用重复检测时把本帧 FCS 写入当前 epoch 的 CRC 表。
    assign commit_can_push = (w_state == W_COMMIT) && (!desc_fifo_full);

    assign crc_ram_normal_rd_en = (w_state == W_CRC_RD);
    assign crc_ram_normal_raddr = dec_crc_idx;
    assign crc_ram_normal_we    = commit_can_push && dec_pass_q && cfg_filter_en && cfg_dup_crc_en && crc_init_done;
    assign crc_ram_normal_waddr = dec_crc_idx;
    assign crc_ram_normal_din   = {1'b1, dec_epoch, dec_crc};

    // 从发起 CRC 读到最终提交期间暂停后台清理，保证一次读判定/写回不被插入。
    assign crc_clear_pause_req  = (w_state == W_CRC_RD) || (w_state == W_CRC_CHK) ||
                                  crc_ram_normal_we || (w_state == W_DECIDE) || (w_state == W_COMMIT);

    // 53 位内部描述符：
    // [52] pass；[51:36] FIFO 实存字节数；[35:34] MAC 类别；
    // [33:32] EtherType 类别；[31:0] 帧起始时间戳。
    assign desc_fifo_din = {dec_pass_q, dec_store_len, dec_mac_class_q, dec_eth_type_class_q, dec_frame_time_q};

    // 组合决策顺序固定且只输出一个丢弃原因：
    // CRC/接收/短帧错误 > 目的 MAC 不匹配 > 黑名单 > 未命中白名单 > 一级 FIFO 满 >
    // 长度错误 > 帧数风暴 > 字节数风暴 > 重复 CRC > 通过。
    // 窗口计数只排除 dec_crc_ok=0 及目的地址/ACL 拒绝；后续因一级拥塞、超长、
    // 风暴或重复 CRC 丢弃的帧仍计入窗口，用于维持线侧流量统计语义。
    always @(*) begin
        frame_cnt_next = (win_rollover ? 32'd0 : win_frame_cnt_g) + 32'd1;
        byte_cnt_next  = (win_rollover ? 32'd0 : win_byte_cnt_g) + {16'd0, dec_len};

        frame_over_new = (eff_frame_max != 32'd0) && (frame_cnt_next > eff_frame_max);
        byte_over_new  = (eff_byte_max  != 32'd0) && (byte_cnt_next  > eff_byte_max);

        frame_over = cfg_filter_en && cfg_frame_storm_en &&
                     ((win_rollover ? 1'b0 : frame_storm_active_g) || frame_over_new);
        byte_over  = cfg_filter_en && cfg_byte_storm_en &&
                     ((win_rollover ? 1'b0 : byte_storm_active_g) || byte_over_new);

        dec_count_window = dec_crc_ok &&
                           (!(cfg_filter_en && cfg_dst_mac_en && dec_meta_valid && !dst_mac_hit_q)) &&
                           (!(cfg_filter_en && cfg_blacklist_en && dec_meta_valid && acl_black_hit_q)) &&
                           (!(cfg_filter_en && cfg_whitelist_en && dec_meta_valid && !acl_white_hit_q));

        dec_pass        = 1'b0;
        dec_drop_reason = DROP_NONE;

        if (!dec_crc_ok)
            dec_drop_reason = DROP_CRC_ERR;
        else if (cfg_filter_en && cfg_dst_mac_en && dec_meta_valid && !dst_mac_hit_q)
            dec_drop_reason = DROP_DST_MISS;
        else if (cfg_filter_en && cfg_blacklist_en && dec_meta_valid && acl_black_hit_q)
            dec_drop_reason = DROP_BLACKLIST;
        else if (cfg_filter_en && cfg_whitelist_en && dec_meta_valid && !acl_white_hit_q)
            dec_drop_reason = DROP_NOT_WHITE;
        else if (dec_buf_full_err || dec_desc_full_err)
            dec_drop_reason = DROP_BUF_FULL;
        else if (dec_len_err || dec_len_over_max)
            dec_drop_reason = DROP_LEN_ERR;
        else if (frame_over)
            dec_drop_reason = DROP_FRAME_STORM;
        else if (byte_over)
            dec_drop_reason = DROP_BYTE_STORM;
        else if (cfg_filter_en && cfg_dup_crc_en && crc_dup_hit_q)
            dec_drop_reason = DROP_DUP_CRC;
        else
            dec_pass = 1'b1;
    end

    // 主状态机。pfifo_wr_en 与 desc_fifo_wr_en 默认每拍拉低，仅在实际写入拍置高。
    always @(posedge gmii_rx_clk or posedge rst) begin
        if (rst) begin
            w_state <= W_IDLE;
            preamble_cnt <= 3'd0;
            pfifo_wr_en <= 1'b0;
            pfifo_din   <= 8'd0;
            desc_fifo_wr_en <= 1'b0;

            rx_total_cnt <= 32'd0;
            rx_byte_cnt  <= 16'd0;
            hold_cnt     <= 3'd0;
            hold0        <= 8'd0;
            hold1        <= 8'd0;
            hold2        <= 8'd0;
            hold3        <= 8'd0;

            wr_len_seen      <= 16'd0;
            wr_len_stored    <= 16'd0;
            wr_len_err       <= 1'b0;
            wr_buf_full_err  <= 1'b0;
            wr_desc_full_err <= 1'b0;
            wr_rx_error_seen <= 1'b0;
            wr_meta_valid    <= 1'b0;
            wr_dst_mac       <= 48'd0;
            wr_src_mac       <= 48'd0;
            wr_eth_type      <= 16'd0;
            wr_vlan_tag_present <= 1'b0;
            wr_tpid_hi       <= 8'd0;
            wr_frame_time    <= 32'd0;

            dec_len           <= 16'd0;
            dec_store_len     <= 16'd0;
            dec_crc           <= 32'd0;
            dec_crc_ok        <= 1'b0;
            dec_len_err       <= 1'b0;
            dec_buf_full_err  <= 1'b0;
            dec_desc_full_err <= 1'b0;
            dec_meta_valid    <= 1'b0;
            dec_dst_mac       <= 48'd0;
            dec_dst_hash_idx  <= 6'd0;
            dec_src_mac       <= 48'd0;
            dec_eth_type      <= 16'd0;
            dec_vlan_tag_present <= 1'b0;
            dec_mac_class     <= MAC_CLASS_RESERVED;
            dec_eth_type_class <= ETH_TYPE_CLASS_RESERVED;
            dec_frame_time    <= 32'd0;

            acl_white_hit_q <= 1'b0;
            acl_black_hit_q <= 1'b0;
            dst_mac_hit_q   <= 1'b0;

            dec_crc_idx <= {CRC_IDX_W{1'b0}};
            dec_epoch   <= {CRC_EPOCH_W{1'b0}};
            crc_rd_q    <= {CRC_ENTRY_W{1'b0}};
            crc_dup_hit_q <= 1'b0;
            crc_check_allowed_q <= 1'b0;

            dec_pass_q           <= 1'b0;
            dec_drop_reason_q    <= DROP_NONE;
            frame_cnt_next_q     <= 32'd0;
            byte_cnt_next_q      <= 32'd0;
            frame_over_q         <= 1'b0;
            byte_over_q          <= 1'b0;
            dec_count_window_q   <= 1'b0;
            dec_mac_class_q       <= MAC_CLASS_RESERVED;
            dec_eth_type_class_q  <= ETH_TYPE_CLASS_RESERVED;
            dec_frame_time_q      <= 32'd0;
        end else begin
            pfifo_wr_en <= 1'b0;
            desc_fifo_wr_en <= 1'b0;

            case (w_state)
                // 清空上一帧接收现场；检测到任意有效字节后进入前导码识别。
                W_IDLE: begin
                    rx_total_cnt <= 32'd0;
                    rx_byte_cnt  <= 16'd0;
                    hold_cnt     <= 3'd0;
                    hold0        <= 8'd0;
                    hold1        <= 8'd0;
                    hold2        <= 8'd0;
                    hold3        <= 8'd0;
                    preamble_cnt <= 3'd0;

                    wr_len_seen      <= 16'd0;
                    wr_len_stored    <= 16'd0;
                    wr_len_err       <= 1'b0;
                    wr_buf_full_err  <= 1'b0;
                    wr_desc_full_err <= 1'b0;
                    wr_rx_error_seen <= 1'b0;
                    wr_meta_valid    <= 1'b0;
                    wr_dst_mac       <= 48'd0;
                    wr_src_mac       <= 48'd0;
                    wr_eth_type      <= 16'd0;
                    wr_vlan_tag_present <= 1'b0;
                    wr_tpid_hi       <= 8'd0;
                    wr_frame_time    <= 32'd0;

                    if (gmii_rxdv) begin
                        wr_rx_error_seen <= gmii_rxer;
                        if (gmii_rxd == 8'h55)
                            preamble_cnt <= 3'd1;
                        else
                            preamble_cnt <= 3'd0;
                        w_state <= W_PREAMBLE;
                    end
                end

                // 必须先累计 7 个连续 0x55，再接受 0xD5。序列中断但 RX_DV 仍为高时
                // 从 0 重新计数；RX_DV 提前结束则按无有效帧内容进入后续丢弃判定。
                W_PREAMBLE: begin
                    if (!gmii_rxdv) begin
                        dec_len           <= 16'd0;
                        dec_store_len     <= 16'd0;
                        dec_crc           <= 32'd0;
                        dec_crc_ok        <= 1'b0;
                        dec_len_err       <= 1'b1;
                        dec_buf_full_err  <= 1'b0;
                        dec_desc_full_err <= 1'b0;
                        dec_meta_valid    <= 1'b0;
                        dec_dst_mac       <= 48'd0;
                        dec_dst_hash_idx  <= 6'd0;
                        dec_src_mac       <= 48'd0;
                        dec_eth_type      <= 16'd0;
                        dec_vlan_tag_present <= 1'b0;
                        dec_mac_class     <= MAC_CLASS_RESERVED;
                        dec_eth_type_class <= ETH_TYPE_CLASS_RESERVED;
                        dec_frame_time    <= wr_frame_time;
                        dec_crc_idx       <= {CRC_IDX_W{1'b0}};
                        dec_epoch         <= active_epoch;
                        preamble_cnt      <= 3'd0;
                        w_state <= W_ACL_CHK;
                    end else begin
                        if (gmii_rxer)
                            wr_rx_error_seen <= 1'b1;

                        if (gmii_rxd == 8'h55) begin
                            if (preamble_cnt != 3'd7)
                                preamble_cnt <= preamble_cnt + 3'd1;
                            else
                                preamble_cnt <= 3'd7;
                        end else if ((gmii_rxd == 8'hD5) && (preamble_cnt == 3'd7)) begin
                            rx_total_cnt  <= 32'd0;
                            rx_byte_cnt   <= 16'd0;
                            hold_cnt      <= 3'd0;
                            preamble_cnt  <= 3'd0;
                            wr_frame_time <= frame_time_cnt_g;

                            // SFD 到达时一级任一 FIFO 已满，则整帧走只接收不写入路径；
                            // 仍继续解析至帧尾，以便形成长度为 0 的丢弃描述符和统计事件。
                            if (desc_fifo_full || pfifo_full) begin
                                wr_desc_full_err <= desc_fifo_full;
                                wr_buf_full_err  <= pfifo_full;
                                w_state <= W_DISCARD_RECV;
                            end else begin
                                w_state <= W_RECV;
                            end
                        end else begin
                            preamble_cnt <= 3'd0;
                        end
                    end
                end

                // 正常接收路径：当前字节用于字段解析，延迟 4 字节后的 hold0 才可能
                // 写入数据 FIFO，从而让帧结束时最后四个 FCS 字节自然留在延迟链中。
                W_RECV: begin
                    if (gmii_rxdv) begin
                        if (gmii_rxer)
                            wr_rx_error_seen <= 1'b1;

                        rx_total_cnt <= rx_total_cnt + 32'd1;

                        if (desc_fifo_full)
                            wr_desc_full_err <= 1'b1;
                        if (pfifo_full)
                            wr_buf_full_err <= 1'b1;

                        // 字段解析使用当前 GMII 字节；hold0 只承担延迟释放、去 FCS 和
                        // 删除 VLAN TPID/TCI，不参与字段位置判断。
                        case (rx_byte_cnt)
                            16'd0:  wr_dst_mac[47:40] <= gmii_rxd;
                            16'd1:  wr_dst_mac[39:32] <= gmii_rxd;
                            16'd2:  wr_dst_mac[31:24] <= gmii_rxd;
                            16'd3:  wr_dst_mac[23:16] <= gmii_rxd;
                            16'd4:  wr_dst_mac[15:8]  <= gmii_rxd;
                            16'd5:  wr_dst_mac[7:0]   <= gmii_rxd;
                            16'd6:  wr_src_mac[47:40] <= gmii_rxd;
                            16'd7:  wr_src_mac[39:32] <= gmii_rxd;
                            16'd8:  wr_src_mac[31:24] <= gmii_rxd;
                            16'd9:  wr_src_mac[23:16] <= gmii_rxd;
                            16'd10: wr_src_mac[15:8]  <= gmii_rxd;
                            16'd11: wr_src_mac[7:0]   <= gmii_rxd;
                            16'd12: wr_tpid_hi        <= gmii_rxd;
                            16'd13: begin
                                if ({wr_tpid_hi, gmii_rxd} == ETH_TPID_VLAN) begin
                                    wr_vlan_tag_present <= 1'b1;
                                end else begin
                                    wr_eth_type   <= {wr_tpid_hi, gmii_rxd};
                                    wr_meta_valid <= 1'b1;
                                end
                            end
                            16'd16: begin
                                if (wr_vlan_tag_present)
                                    wr_eth_type[15:8] <= gmii_rxd;
                            end
                            16'd17: begin
                                if (wr_vlan_tag_present) begin
                                    wr_eth_type[7:0] <= gmii_rxd;
                                    wr_meta_valid    <= 1'b1;
                                end
                            end
                            default: begin end
                        endcase

                        if (rx_byte_cnt != 16'hFFFF)
                            rx_byte_cnt <= rx_byte_cnt + 16'd1;

                        if (hold_cnt < 3'd4) begin
                            case (hold_cnt)
                                3'd0: hold0 <= gmii_rxd;
                                3'd1: hold1 <= gmii_rxd;
                                3'd2: hold2 <= gmii_rxd;
                                3'd3: hold3 <= gmii_rxd;
                                default: begin end
                            endcase
                            hold_cnt <= hold_cnt + 3'd1;

                            if (desc_fifo_full || pfifo_full)
                                w_state <= W_DISCARD_RECV;
                        end else begin
                            // wr_len_seen 对延迟链释放的每个线侧字节计数，所以表示
                            // DA..payload 长度（不含 FCS、仍含 VLAN TPID/TCI），删除 VLAN
                            // 标签时也不能暂停；wr_len_stored 只在字节真正写入 FIFO 时增加。
                            if (rx_len_over_next)
                                wr_len_err <= 1'b1;

                            if ((!desc_fifo_full) && (!pfifo_full) && (!rx_len_over_next) &&
                                (!hold_byte_is_vlan_tag)) begin
                                pfifo_din     <= hold0;
                                pfifo_wr_en   <= 1'b1;
                                wr_len_stored <= wr_len_stored + 16'd1;
                            end

                            if (wr_len_seen != 16'hFFFF)
                                wr_len_seen <= wr_len_seen + 16'd1;

                            hold0 <= hold1;
                            hold1 <= hold2;
                            hold2 <= hold3;
                            hold3 <= gmii_rxd;

                            if (desc_fifo_full || pfifo_full || rx_len_over_next) begin
                                w_state <= W_DISCARD_RECV;
                            end
                        end
                    end else begin
                        // RX_DV 结束后，hold0..hold3 即接收到的 FCS，不写数据 FIFO。
                        // CRC 检查可由配置关闭，但 GMII RX_ER 和最小帧长始终参与 crc_ok。
                        dec_len           <= wr_len_seen;
                        dec_store_len     <= wr_len_stored;
                        dec_crc           <= rx_fcs_wire;
                        dec_crc_ok        <= (!wr_rx_error_seen) &&
                                             (wr_len_seen >= MIN_FRAME_BYTES_16) &&
                                             (!cfg_crc_check_en || (fcs_crc_result == CRC32_ETH_RESIDUE));
                        dec_len_err       <= wr_len_err || (wr_len_seen < MIN_FRAME_BYTES_16);
                        dec_buf_full_err  <= wr_buf_full_err;
                        dec_desc_full_err <= wr_desc_full_err;
                        dec_meta_valid    <= wr_meta_valid;
                        dec_dst_mac       <= wr_dst_mac;
                        dec_dst_hash_idx  <= dst_mac_crc_result[31:26];
                        dec_src_mac       <= wr_src_mac;
                        dec_eth_type      <= wr_eth_type;
                        dec_vlan_tag_present <= wr_vlan_tag_present;
                        dec_mac_class     <= MAC_CLASS_RESERVED;
                        dec_eth_type_class <= ETH_TYPE_CLASS_RESERVED;
                        dec_frame_time    <= wr_frame_time;
                        dec_crc_idx       <= rx_fcs_hash16[CRC_IDX_W-1:0];
                        dec_epoch         <= active_epoch;
                        w_state <= W_ACL_CHK;
                    end
                end

                // 进入本状态后不再写一级数据 FIFO，但继续推进字段解析、长度、FCS CRC
                // 和接收错误记录。最终描述符中的 stored_len 仅覆盖已成功保存的前缀，
                // 125 MHz 路由器据此精确排空，不会把下一帧数据当成本帧内容。
                W_DISCARD_RECV: begin
                    if (gmii_rxdv) begin
                        if (gmii_rxer)
                            wr_rx_error_seen <= 1'b1;

                        rx_total_cnt <= rx_total_cnt + 32'd1;

                        // 即使不再写 FIFO，仍从当前 GMII 字节提取 DA/SA/EtherType/VLAN。
                        case (rx_byte_cnt)
                            16'd0:  wr_dst_mac[47:40] <= gmii_rxd;
                            16'd1:  wr_dst_mac[39:32] <= gmii_rxd;
                            16'd2:  wr_dst_mac[31:24] <= gmii_rxd;
                            16'd3:  wr_dst_mac[23:16] <= gmii_rxd;
                            16'd4:  wr_dst_mac[15:8]  <= gmii_rxd;
                            16'd5:  wr_dst_mac[7:0]   <= gmii_rxd;
                            16'd6:  wr_src_mac[47:40] <= gmii_rxd;
                            16'd7:  wr_src_mac[39:32] <= gmii_rxd;
                            16'd8:  wr_src_mac[31:24] <= gmii_rxd;
                            16'd9:  wr_src_mac[23:16] <= gmii_rxd;
                            16'd10: wr_src_mac[15:8]  <= gmii_rxd;
                            16'd11: wr_src_mac[7:0]   <= gmii_rxd;
                            16'd12: wr_tpid_hi        <= gmii_rxd;
                            16'd13: begin
                                if ({wr_tpid_hi, gmii_rxd} == ETH_TPID_VLAN) begin
                                    wr_vlan_tag_present <= 1'b1;
                                end else begin
                                    wr_eth_type   <= {wr_tpid_hi, gmii_rxd};
                                    wr_meta_valid <= 1'b1;
                                end
                            end
                            16'd16: begin
                                if (wr_vlan_tag_present)
                                    wr_eth_type[15:8] <= gmii_rxd;
                            end
                            16'd17: begin
                                if (wr_vlan_tag_present) begin
                                    wr_eth_type[7:0] <= gmii_rxd;
                                    wr_meta_valid    <= 1'b1;
                                end
                            end
                            default: begin end
                        endcase

                        if (rx_byte_cnt != 16'hFFFF)
                            rx_byte_cnt <= rx_byte_cnt + 16'd1;

                        if (hold_cnt < 3'd4) begin
                            case (hold_cnt)
                                3'd0: hold0 <= gmii_rxd;
                                3'd1: hold1 <= gmii_rxd;
                                3'd2: hold2 <= gmii_rxd;
                                3'd3: hold3 <= gmii_rxd;
                                default: begin end
                            endcase
                            hold_cnt <= hold_cnt + 3'd1;
                        end else begin
                            if (rx_len_over_next)
                                wr_len_err <= 1'b1;

                            if (wr_len_seen != 16'hFFFF)
                                wr_len_seen <= wr_len_seen + 16'd1;

                            hold0 <= hold1;
                            hold1 <= hold2;
                            hold2 <= hold3;
                            hold3 <= gmii_rxd;
                        end
                    end else begin
                        dec_len           <= wr_len_seen;
                        dec_store_len     <= wr_len_stored;
                        dec_crc           <= rx_fcs_wire;
                        dec_crc_ok        <= (!wr_rx_error_seen) &&
                                             (wr_len_seen >= MIN_FRAME_BYTES_16) &&
                                             (!cfg_crc_check_en || (fcs_crc_result == CRC32_ETH_RESIDUE));
                        dec_len_err       <= wr_len_err || (wr_len_seen < MIN_FRAME_BYTES_16) ||
                                             ((eff_max_frame_bytes != 16'd0) && ({1'b0, wr_len_seen} > eff_max_seen_bytes));
                        dec_buf_full_err  <= wr_buf_full_err;
                        dec_desc_full_err <= wr_desc_full_err;
                        dec_meta_valid    <= wr_meta_valid;
                        dec_dst_mac       <= wr_dst_mac;
                        dec_dst_hash_idx  <= dst_mac_crc_result[31:26];
                        dec_src_mac       <= wr_src_mac;
                        dec_eth_type      <= wr_eth_type;
                        dec_vlan_tag_present <= wr_vlan_tag_present;
                        dec_mac_class     <= MAC_CLASS_RESERVED;
                        dec_eth_type_class <= ETH_TYPE_CLASS_RESERVED;
                        dec_frame_time    <= wr_frame_time;
                        dec_crc_idx       <= rx_fcs_hash16[CRC_IDX_W-1:0];
                        dec_epoch         <= active_epoch;
                        w_state <= W_ACL_CHK;
                    end
                end

                // 并行锁存源 MAC 黑白名单、目的地址结果及 MAC/EtherType 分类。
                W_ACL_CHK: begin
                    acl_white_hit_q <= dec_meta_valid ? acl_white_match(dec_src_mac) : 1'b0;
                    acl_black_hit_q <= dec_meta_valid ? acl_black_match(dec_src_mac) : 1'b0;
                    dst_mac_hit_q   <= dec_meta_valid ? dst_mac_match : 1'b0;
                    dec_mac_class   <= dec_meta_valid ? dec_mac_class_wire : MAC_CLASS_RESERVED;
                    dec_eth_type_class <= dec_meta_valid ? dec_eth_type_class_wire : ETH_TYPE_CLASS_RESERVED;
                    dec_crc_idx     <= dec_crc_hash16[CRC_IDX_W-1:0];
                    w_state <= W_CRC_RD;
                end

                // 发出同步 RAM 读请求，同时锁存本帧是否具备重复 CRC 检查资格。
                W_CRC_RD: begin
                    crc_check_allowed_q <= cfg_filter_en && cfg_dup_crc_en && crc_init_done &&
                                           dec_crc_ok && (!dec_len_err) && (!dec_buf_full_err) && (!dec_desc_full_err);
                    w_state <= W_CRC_CHK;
                end

                // RAM 表项需 valid、epoch 和完整 32 位 FCS 三者均匹配才算重复。
                W_CRC_CHK: begin
                    crc_rd_q <= crc_ram_dout;
                    crc_dup_hit_q <= crc_check_allowed_q &&
                                     crc_ram_dout[CRC_ENTRY_W-1] &&
                                     (crc_ram_dout[32] == dec_epoch) &&
                                     (crc_ram_dout[31:0] == dec_crc);
                    w_state <= W_DECIDE;
                end

                // 锁存组合判定以及“提交后”窗口计数，供下一状态原子提交。
                W_DECIDE: begin
                    frame_cnt_next_q   <= frame_cnt_next;
                    byte_cnt_next_q    <= byte_cnt_next;
                    frame_over_q       <= frame_over;
                    byte_over_q        <= byte_over;
                    dec_count_window_q <= dec_count_window;
                    dec_pass_q         <= dec_pass;
                    dec_drop_reason_q     <= dec_drop_reason;
                    dec_mac_class_q       <= dec_mac_class;
                    dec_eth_type_class_q  <= dec_eth_type_class;
                    dec_frame_time_q      <= dec_frame_time;
                    w_state <= W_COMMIT;
                end

                // 描述符 FIFO 暂满时停留等待；可写拍同时触发描述符、统计及 CRC 写回。
                W_COMMIT: begin
                    if (!desc_fifo_full) begin
                        desc_fifo_wr_en <= 1'b1;
                        w_state <= W_IDLE;
                    end
                end

                default: begin
                    w_state <= W_IDLE;
                end
            endcase
        end
    end

endmodule
```
