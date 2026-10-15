# eth_storm_type_router

- Category: `ethernet`
- Source: `E:\eth_storm_project\rgmii_eth_storm_filter_coding\eth_storm_type_router.v`
- SHA-256: `c0e2c5c948ae3fa854a0e7b0280ea153c2de727ca4611137df3a90fc76428510`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps
// =============================================================================
// 模块名称：eth_storm_type_router
// 时钟域  ：clk（当前层级接入 clk_125m）；复位 rst 为高有效异步复位。
// 上下游  ：读取一级公共数据/描述符 FIFO，将通过帧写入 GOOSE、SV 或 Other
//           二级数据/描述符 FIFO；每个使能有效拍对应一次 FIFO 读或写，搬运时可连续有效。
//
// 路由规则：
//   - 先从 FWFT 公共描述符 FIFO 锁存 {pass, len, mac_class,
//     eth_type_class, time}，再严格消费 len 个公共数据 FIFO 字节。
//   - pass=0 表示接收侧已经丢弃：仅排空该帧已保存的数据，不写任何二级 FIFO。
//   - pass=1 且目标数据 FIFO full/prog_full 或描述符 FIFO full：本帧不等待空间，
//     同样只排空公共数据，并在本时钟域产生一次路由拥塞统计事件。
//   - pass=1 且目标可接收：先连续写完整帧数据，最后再写 53 位描述符，从而让
//     下游看到描述符时，对应数据已经全部进入同一路二级 FIFO。
//
// 准入判断发生在 R_CHECK。若已经准入后 target_data_full 意外拉高，R_COPY 会暂停
// 读取公共 FIFO，等待 full 解除后继续当前帧；prog_full 应配置为在准入时为一帧
// 最大长度预留容量。
// =============================================================================

module eth_storm_type_router #(
    parameter integer DESC_W = 53
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  cfg_clear_stats,

    // 一级公共帧数据 FIFO（FWFT）：empty=0 时 dout 即为当前待消费字节
    input  wire [7:0]            common_data_dout,
    input  wire                  common_data_empty,
    output reg                   common_data_rd_en,

    // 一级公共描述符 FIFO（FWFT）：先取描述符，再按其中长度消费数据
    input  wire [DESC_W-1:0]     common_desc_dout,
    input  wire                  common_desc_empty,
    output reg                   common_desc_rd_en,

    // GOOSE 二级 FIFO 状态与写控制
    input  wire                  goose_data_full,
    input  wire                  goose_data_prog_full,
    input  wire                  goose_desc_full,
    output reg                   goose_data_wr_en,
    output reg                   goose_desc_wr_en,

    // SV 二级 FIFO 状态与写控制
    input  wire                  sv_data_full,
    input  wire                  sv_data_prog_full,
    input  wire                  sv_desc_full,
    output reg                   sv_data_wr_en,
    output reg                   sv_desc_wr_en,

    // Other 二级 FIFO 状态与写控制
    input  wire                  other_data_full,
    input  wire                  other_data_prog_full,
    input  wire                  other_desc_full,
    output reg                   other_data_wr_en,
    output reg                   other_desc_wr_en,

    // 三组目标 FIFO 共用输入数据总线，由互斥的分类写使能选中唯一一路
    output wire [7:0]            route_data_din,
    output wire [DESC_W-1:0]     route_desc_din,

    // 本地 clk 域路由拥塞事件和计数；class 编码与 EtherType 分类编码一致
    output reg                   route_drop_fifo_full_valid,
    output reg  [1:0]            route_drop_fifo_full_class,
    output reg  [31:0]           stat_route_drop_fifo_full_cnt,
    output reg  [31:0]           stat_route_drop_goose_cnt,
    output reg  [31:0]           stat_route_drop_sv_cnt,
    output reg  [31:0]           stat_route_drop_other_cnt
);

    // 状态流程：取描述符 -> 准入检查 -> 搬运/排空数据 -> 提交描述符。
    localparam [2:0] R_IDLE      = 3'd0;
    localparam [2:0] R_CHECK     = 3'd1;
    localparam [2:0] R_COPY      = 3'd2;
    localparam [2:0] R_COMMIT    = 3'd3;
    localparam [2:0] R_ZERO_SKIP = 3'd4;

    localparam [1:0] ETH_TYPE_CLASS_OTHER = 2'd0;
    localparam [1:0] ETH_TYPE_CLASS_GOOSE = 2'd1;
    localparam [1:0] ETH_TYPE_CLASS_SV    = 2'd2;

    // 当前描述符快照。cur_rx_pass 是接收侧结果，cur_route_forward 是本级准入结果。
    reg [2:0]              r_state;
    reg [DESC_W-1:0]       cur_desc;
    reg                    cur_rx_pass;
    reg                    cur_route_forward;
    reg [15:0]             cur_len;
    reg [15:0]             cur_ptr;
    reg [1:0]              cur_eth_type_class;

    // 53 位描述符格式：
    // {pass[52], len[51:36], mac_class[35:34], eth_type_class[33:32], time[31:0]}
    wire                    desc_pass_l           = common_desc_dout[52];
    wire [15:0]             desc_len_l            = common_desc_dout[51:36];
    wire [1:0]              desc_eth_type_class_l = common_desc_dout[33:32];

    // 根据当前 EtherType 分类选择唯一目标；保留值也由 default 路由到 Other。
    wire target_data_prog_full =
        (cur_eth_type_class == ETH_TYPE_CLASS_GOOSE) ? goose_data_prog_full :
        (cur_eth_type_class == ETH_TYPE_CLASS_SV)    ? sv_data_prog_full    :
                                                       other_data_prog_full;

    wire target_data_full =
        (cur_eth_type_class == ETH_TYPE_CLASS_GOOSE) ? goose_data_full :
        (cur_eth_type_class == ETH_TYPE_CLASS_SV)    ? sv_data_full    :
                                                       other_data_full;

    wire target_desc_full =
        (cur_eth_type_class == ETH_TYPE_CLASS_GOOSE) ? goose_desc_full :
        (cur_eth_type_class == ETH_TYPE_CLASS_SV)    ? sv_desc_full    :
                                                       other_desc_full;

    wire target_congested = target_data_full |
                            target_data_prog_full |
                            target_desc_full;

    // 只有“接收侧已通过且本级目标拥塞”才属于路由拥塞丢弃。
    wire routed_drop_due_to_fifo_full = cur_rx_pass & target_congested;

    assign route_data_din = common_data_dout;
    assign route_desc_din = cur_desc;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_state                         <= R_IDLE;
            cur_desc                        <= {DESC_W{1'b0}};
            cur_rx_pass                     <= 1'b0;
            cur_route_forward               <= 1'b0;
            cur_len                         <= 16'd0;
            cur_ptr                         <= 16'd0;
            cur_eth_type_class              <= ETH_TYPE_CLASS_OTHER;

            common_data_rd_en               <= 1'b0;
            common_desc_rd_en               <= 1'b0;
            goose_data_wr_en                <= 1'b0;
            goose_desc_wr_en                <= 1'b0;
            sv_data_wr_en                   <= 1'b0;
            sv_desc_wr_en                   <= 1'b0;
            other_data_wr_en                <= 1'b0;
            other_desc_wr_en                <= 1'b0;

            route_drop_fifo_full_valid      <= 1'b0;
            route_drop_fifo_full_class      <= ETH_TYPE_CLASS_OTHER;
            stat_route_drop_fifo_full_cnt   <= 32'd0;
            stat_route_drop_goose_cnt       <= 32'd0;
            stat_route_drop_sv_cnt          <= 32'd0;
            stat_route_drop_other_cnt       <= 32'd0;
        end else begin
            // FIFO 读写使能默认每拍清零，在每个传输拍拉高且可连续有效；
            // route_drop_fifo_full_valid 则只在准入失败拍产生一次事件。
            common_data_rd_en          <= 1'b0;
            common_desc_rd_en          <= 1'b0;
            goose_data_wr_en           <= 1'b0;
            goose_desc_wr_en           <= 1'b0;
            sv_data_wr_en              <= 1'b0;
            sv_desc_wr_en              <= 1'b0;
            other_data_wr_en           <= 1'b0;
            other_desc_wr_en           <= 1'b0;
            route_drop_fifo_full_valid <= 1'b0;

            if (cfg_clear_stats) begin
                stat_route_drop_fifo_full_cnt <= 32'd0;
                stat_route_drop_goose_cnt     <= 32'd0;
                stat_route_drop_sv_cnt        <= 32'd0;
                stat_route_drop_other_cnt     <= 32'd0;
            end

            case (r_state)
                // FWFT 描述符非空时，在弹出拍直接锁存队首全部字段。
                R_IDLE: begin
                    cur_ptr           <= 16'd0;
                    cur_route_forward <= 1'b0;

                    if (!common_desc_empty) begin
                        common_desc_rd_en  <= 1'b1;
                        cur_desc           <= common_desc_dout;
                        cur_rx_pass         <= desc_pass_l;
                        cur_len             <= desc_len_l;
                        cur_eth_type_class  <= desc_eth_type_class_l;

                        // 长度为 0 的描述符没有对应数据，消费描述符后不进入任何分类 FIFO。
                        if (desc_len_l != 16'd0)
                            r_state <= R_CHECK;
                        else
                            r_state <= R_ZERO_SKIP;
                    end
                end

                R_ZERO_SKIP: begin
                    // 默认赋值已将 common_desc_rd_en 拉低；留出一拍完成本次弹出。
                    r_state <= R_IDLE;
                end

                R_CHECK: begin
                    // 本拍一次性决定是否转发。接收侧丢弃，或通过帧的目标二级 FIFO
                    // 已满/将满时，都不进入等待空间状态，而是转到 R_COPY 排空数据。
                    if (!cur_rx_pass || target_congested)
                        cur_route_forward <= 1'b0;
                    else
                        cur_route_forward <= 1'b1;

                    if (routed_drop_due_to_fifo_full) begin
                        route_drop_fifo_full_valid <= 1'b1;
                        route_drop_fifo_full_class <= cur_eth_type_class;

                        if (!cfg_clear_stats) begin
                            stat_route_drop_fifo_full_cnt <= stat_route_drop_fifo_full_cnt + 32'd1;
                            case (cur_eth_type_class)
                                ETH_TYPE_CLASS_GOOSE: stat_route_drop_goose_cnt <= stat_route_drop_goose_cnt + 32'd1;
                                ETH_TYPE_CLASS_SV:    stat_route_drop_sv_cnt    <= stat_route_drop_sv_cnt    + 32'd1;
                                default:              stat_route_drop_other_cnt <= stat_route_drop_other_cnt + 32'd1;
                            endcase
                        end
                    end

                    r_state <= R_COPY;
                end

                R_COPY: begin
                    // 未准入帧只读公共数据 FIFO；已准入帧在同拍读一个公共字节并写入
                    // 唯一目标数据 FIFO。cur_ptr 从 0 数到 cur_len-1，保证严格消费描述符
                    // 声明的字节数。target_data_full 是搬运过程中的溢出保护：full 为高时
                    // 不读源 FIFO，也不写目标 FIFO，保持当前帧位置不变。
                    if (!common_data_empty &&
                        (!cur_route_forward || !target_data_full)) begin

                        common_data_rd_en <= 1'b1;

                        if (cur_route_forward) begin
                            case (cur_eth_type_class)
                                ETH_TYPE_CLASS_GOOSE: goose_data_wr_en <= 1'b1;
                                ETH_TYPE_CLASS_SV:    sv_data_wr_en    <= 1'b1;
                                default:              other_data_wr_en <= 1'b1;
                            endcase
                        end

                        if (cur_ptr == cur_len - 16'd1) begin
                            cur_ptr <= 16'd0;
                            if (cur_route_forward)
                                r_state <= R_COMMIT;
                            else
                                r_state <= R_IDLE;
                        end else begin
                            cur_ptr <= cur_ptr + 16'd1;
                        end
                    end
                end

                R_COMMIT: begin
                    // 仅在完整帧数据已经写完且目标描述符 FIFO 可写时提交描述符。
                    // 若 full 暂时为高则停留在本状态，数据不会重复写入。
                    if (!target_desc_full) begin
                        case (cur_eth_type_class)
                            ETH_TYPE_CLASS_GOOSE: goose_desc_wr_en <= 1'b1;
                            ETH_TYPE_CLASS_SV:    sv_desc_wr_en    <= 1'b1;
                            default:              other_desc_wr_en <= 1'b1;
                        endcase
                        r_state <= R_IDLE;
                    end
                end

                default: begin
                    r_state <= R_IDLE;
                end
            endcase
        end
    end

endmodule
```
