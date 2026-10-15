# eth_classified_frame_dma_writer

- Category: `ethernet`
- Source: `E:\eth_storm_project\Packet Stream_AXI4-Full DMA Writer\Packet Stream_AXI4-Full DMA Writer\eth_classified_frame_dma_writer.v`
- SHA-256: `ecf886f2e4a438f4779cb963d74b8a00333c888144023cb6f265dfeed0c9d974`
- Extractor: `text`
- Tags: `dma, ethernet, rgmii, storm-filter`
- Duplicate sources:
  - none

```verilog
`timescale 1ns / 1ps

// =============================================================================
// 模块名称：eth_classified_frame_dma_writer
// 功能说明：分类以太网帧 DMA 写入顶层模块。
//   1. 连接描述符仲裁、环形缓冲区管理、数据打包、描述符生成和 S2MM 控制模块；
//   2. 通过 AXI DataMover 将帧数据和输出描述符写入配置的内存区域；
//   3. 对外提供写指针、完成脉冲、中断请求以及错误统计等状态信息。
//
// 数据流：三个分类 FWFT FIFO -> 固定优先级描述符仲裁（SV > GOOSE > OTHER）
//       -> 环形槽位申请 + 对应字节 FIFO 读取 -> 64 位 AXI4-Stream 打包
//       -> DataMover S2MM -> AXI4-Full 写主口 -> 外部存储器。
// 控制器对每帧先写固定大小槽位中的有效帧字节，再写 8 字节软件描述符，二者状态均成功后
// 才推进该分类环的写指针。该顶层只实现写向存储器的 S2MM 路径，不包含存储器读回路径。
//
// 时钟与复位：本文件内所有自研模块及 DataMover S2MM 接口共用 clk；自研逻辑使用高有效 rst，
// DataMover 的 aresetn 端口接 ~rst。三个输入数据/描述符 FIFO 均按 FWFT 语义连接。
// =============================================================================
module eth_classified_frame_dma_writer #(
    parameter integer DESC_W                 = 53,
    parameter integer CHANNEL_DEPTH          = 32,
    parameter integer FRAME_SLOT_BYTES       = 1536,
    parameter integer DESC_BYTES             = 8,
    parameter [3:0]   TAG_DATA               = 4'h1,
    parameter [3:0]   TAG_DESC               = 4'h2,
    parameter         ENABLE_DRE_REALIGN     = 1'b0
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         clear_error,

    // 三个环各自配置帧数据区基地址和软件描述符区基地址，共用槽位深度。
    input  wire [31:0]                  cfg_goose_data_base_addr,
    input  wire [31:0]                  cfg_sv_data_base_addr,
    input  wire [31:0]                  cfg_other_data_base_addr,
    input  wire [31:0]                  cfg_goose_desc_base_addr,
    input  wire [31:0]                  cfg_sv_desc_base_addr,
    input  wire [31:0]                  cfg_other_desc_base_addr,
    input  wire [31:0]                  cfg_ring_depth,

    // 外部消费者提供读指针，本模块维护并输出写指针；指针 bit31 为 wrap，bit[30:0] 为索引。
    input  wire [31:0]                  goose_rd_ptr,
    input  wire [31:0]                  sv_rd_ptr,
    input  wire [31:0]                  other_rd_ptr,
    output wire [31:0]                  goose_wr_ptr,
    output wire [31:0]                  sv_wr_ptr,
    output wire [31:0]                  other_wr_ptr,
    output wire                         goose_ring_full,
    output wire                         sv_ring_full,
    output wire                         other_ring_full,

    // 每个分类通道由一条 8 位帧数据 FIFO 和一条 DESC_W 位帧描述符 FIFO 组成；
    // 描述符给出本帧长度等元数据，数据 FIFO 按该长度精确弹出字节。
    input  wire [7:0]                   goose_data_dout,
    input  wire                         goose_data_empty,
    output wire                         goose_data_rd_en,
    input  wire [DESC_W-1:0]            goose_desc_dout,
    input  wire                         goose_desc_empty,
    output wire                         goose_desc_rd_en,

    input  wire [7:0]                   sv_data_dout,
    input  wire                         sv_data_empty,
    output wire                         sv_data_rd_en,
    input  wire [DESC_W-1:0]            sv_desc_dout,
    input  wire                         sv_desc_empty,
    output wire                         sv_desc_rd_en,

    input  wire [7:0]                   other_data_dout,
    input  wire                         other_data_empty,
    output wire                         other_data_rd_en,
    input  wire [DESC_W-1:0]            other_desc_dout,
    input  wire                         other_desc_empty,
    output wire                         other_desc_rd_en,

    // DataMover 转换后的 AXI4-Full 写地址、写数据和写响应通道，直接连接外部内存互连。
    output wire [31:0]                  m_axi_awaddr,
    output wire [7:0]                   m_axi_awlen,
    output wire [2:0]                   m_axi_awsize,
    output wire [1:0]                   m_axi_awburst,
    output wire [2:0]                   m_axi_awprot,
    output wire [3:0]                   m_axi_awcache,
    output wire [3:0]                   m_axi_awuser,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,

    output wire [63:0]                  m_axi_wdata,
    output wire [7:0]                   m_axi_wstrb,
    output wire                         m_axi_wlast,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,

    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready,

    // busy 表示 S2MM 控制器不在空闲态；frame_done_pulse 表示一帧已经成功提交写指针。
    output wire                         busy,
    output wire                         frame_done_pulse,

    // 其他类型帧完成中断：仅 OTHER 帧成功提交时置位，请求保持有效直到收到外部 ACK；
    // 若提交和 ACK 同拍，新的提交请求优先，GOOSE/SV 不触发此中断。
    input  wire                         data_irq_ack,
    output wire                         data_irq_req,

    // 错误状态与错误统计输出。
    output wire                         error,
    output wire                         error_pulse,
    output wire [7:0]                   error_code,
    output wire [31:0]                  error_count,
    output wire [31:0]                  param_error_count,
    output wire [31:0]                  tag_mismatch_count,
    output wire [31:0]                  data_status_error_count,
    output wire [31:0]                  desc_status_error_count,

    output wire [31:0]                  frame_count,
    output wire [31:0]                  last_data_addr,
    output wire [31:0]                  last_desc_addr,
    output wire [1:0]                   current_channel,
    output wire                         datamover_s2mm_err,
    output wire                         s2mm_wr_xfer_cmplt
);

    // --------------------------- 仲裁模块连接 ----------------------------
    // 仲裁器只在控制器 frame_ready 时弹出一个描述符；环已满的通道不会参与本轮选择。
    wire                     frame_valid;
    wire                     frame_ready;
    wire [1:0]               frame_channel;
    wire [15:0]              frame_len;
    wire [31:0]              frame_timestamp;
    wire [DESC_W-1:0]        frame_desc;
    wire [1:0]               frame_mac_class;

    // ------------------------ 环形缓冲区管理连接 --------------------------
    // alloc 预留一个槽位，commit 才推进写指针，abort 仅释放本次预留。
    wire                     ring_alloc_valid;
    wire                     ring_alloc_ready;
    wire [1:0]               ring_alloc_channel;
    wire [31:0]              ring_alloc_data_addr;
    wire [31:0]              ring_alloc_desc_addr;
    wire [31:0]              ring_alloc_entry_index;
    wire                     ring_commit_valid;
    wire                     ring_abort_valid;

    // -------------------------- 数据打包模块连接 --------------------------
    // packer 选择与描述符相同的分类数据 FIFO，并把 8 位字节流按低字节优先组成 64 位数据拍。
    wire                     packer_start_valid;
    wire                     packer_start_ready;
    wire [1:0]               packer_start_channel;
    wire [15:0]              packer_start_length;
    wire                     packer_abort;
    wire [63:0]              packer_axis_tdata;
    wire [7:0]               packer_axis_tkeep;
    wire                     packer_axis_tlast;
    wire                     packer_axis_tvalid;
    wire                     packer_axis_tready;
    wire                     packer_done_pulse;
    wire                     packer_active;

    // -------------------------- 描述符模块连接 ----------------------------
    // 描述符生成器使用控制器锁存的帧上下文，形成最终写入软件描述符环的 64 位记录。
    wire [1:0]               active_mac_class;
    wire [15:0]              active_frame_len;
    wire [31:0]              active_timestamp;
    wire [63:0]              desc_payload;

    // ------------------------- DataMover 接口连接 -------------------------
    // 同一组 S2MM 命令/数据/状态通道先完成帧数据事务，再完成描述符事务；TAG 用于核对返回状态。
    wire                     s2mm_cmd_tvalid;
    wire                     s2mm_cmd_tready;
    wire [71:0]              s2mm_cmd_tdata;
    wire                     s2mm_axis_tvalid;
    wire                     s2mm_axis_tready;
    wire [63:0]              s2mm_axis_tdata;
    wire [7:0]               s2mm_axis_tkeep;
    wire                     s2mm_axis_tlast;
    wire                     s2mm_sts_tvalid;
    wire                     s2mm_sts_tready;
    wire [7:0]               s2mm_sts_tdata;
    wire [0:0]               s2mm_sts_tkeep;
    wire                     s2mm_sts_tlast;

    wire                     s2mm_halt_cmplt;
    wire                     s2mm_addr_req_posted;
    wire                     s2mm_ld_nxt_len;
    wire [7:0]               s2mm_wr_len;
    wire [31:0]              s2mm_dbg_data;

    eth_classified_frame_arbiter #(
        .DESC_W(DESC_W)
    ) u_arbiter (
        .clk                (clk),
        .rst                (rst),
        .goose_ring_full    (goose_ring_full),
        .sv_ring_full       (sv_ring_full),
        .other_ring_full    (other_ring_full),
        .goose_desc_dout    (goose_desc_dout),
        .goose_desc_empty   (goose_desc_empty),
        .goose_desc_rd_en   (goose_desc_rd_en),
        .sv_desc_dout       (sv_desc_dout),
        .sv_desc_empty      (sv_desc_empty),
        .sv_desc_rd_en      (sv_desc_rd_en),
        .other_desc_dout    (other_desc_dout),
        .other_desc_empty   (other_desc_empty),
        .other_desc_rd_en   (other_desc_rd_en),
        .frame_valid        (frame_valid),
        .frame_ready        (frame_ready),
        .frame_channel      (frame_channel),
        .frame_mac_class    (frame_mac_class),
        .frame_len          (frame_len),
        .frame_timestamp    (frame_timestamp),
        .frame_desc         (frame_desc)
    );

    eth_classified_frame_ring_manager #(
        .CHANNEL_DEPTH       (CHANNEL_DEPTH),
        .FRAME_SLOT_BYTES    (FRAME_SLOT_BYTES),
        .DESC_BYTES          (DESC_BYTES)
    ) u_ring_manager (
        .clk                         (clk),
        .rst                         (rst),
        .cfg_goose_data_base_addr    (cfg_goose_data_base_addr),
        .cfg_sv_data_base_addr       (cfg_sv_data_base_addr),
        .cfg_other_data_base_addr    (cfg_other_data_base_addr),
        .cfg_goose_desc_base_addr    (cfg_goose_desc_base_addr),
        .cfg_sv_desc_base_addr       (cfg_sv_desc_base_addr),
        .cfg_other_desc_base_addr    (cfg_other_desc_base_addr),
        .cfg_ring_depth              (cfg_ring_depth),
        .goose_rd_ptr                (goose_rd_ptr),
        .sv_rd_ptr                   (sv_rd_ptr),
        .other_rd_ptr                (other_rd_ptr),
        .goose_wr_ptr                (goose_wr_ptr),
        .sv_wr_ptr                   (sv_wr_ptr),
        .other_wr_ptr                (other_wr_ptr),
        .goose_ring_full             (goose_ring_full),
        .sv_ring_full                (sv_ring_full),
        .other_ring_full             (other_ring_full),
        .alloc_valid                 (ring_alloc_valid),
        .alloc_ready                 (ring_alloc_ready),
        .alloc_channel               (ring_alloc_channel),
        .alloc_data_addr             (ring_alloc_data_addr),
        .alloc_desc_addr             (ring_alloc_desc_addr),
        .alloc_entry_index           (ring_alloc_entry_index),
        .commit_valid                (ring_commit_valid),
        .abort_valid                 (ring_abort_valid)
    );

    eth_classified_frame_data_packer u_data_packer (
        .clk                (clk),
        .rst                (rst),
        .abort              (packer_abort),
        .start_valid        (packer_start_valid),
        .start_ready        (packer_start_ready),
        .start_channel      (packer_start_channel),
        .start_length       (packer_start_length),
        .goose_data_dout    (goose_data_dout),
        .goose_data_empty   (goose_data_empty),
        .goose_data_rd_en   (goose_data_rd_en),
        .sv_data_dout       (sv_data_dout),
        .sv_data_empty      (sv_data_empty),
        .sv_data_rd_en      (sv_data_rd_en),
        .other_data_dout    (other_data_dout),
        .other_data_empty   (other_data_empty),
        .other_data_rd_en   (other_data_rd_en),
        .m_axis_tdata       (packer_axis_tdata),
        .m_axis_tkeep       (packer_axis_tkeep),
        .m_axis_tlast       (packer_axis_tlast),
        .m_axis_tvalid      (packer_axis_tvalid),
        .m_axis_tready      (packer_axis_tready),
        .done_pulse         (packer_done_pulse),
        .active             (packer_active)
    );

    eth_classified_frame_desc_builder u_desc_builder (
        .frame_mac_class    (active_mac_class),
        .frame_len          (active_frame_len),
        .frame_timestamp    (active_timestamp),
        .desc_payload       (desc_payload)
    );

    eth_classified_frame_s2mm_ctrl #(
        .FRAME_SLOT_BYTES   (FRAME_SLOT_BYTES),
        .DESC_BYTES         (DESC_BYTES),
        .TAG_DATA           (TAG_DATA),
        .TAG_DESC           (TAG_DESC),
        .ENABLE_DRE_REALIGN (ENABLE_DRE_REALIGN)
    ) u_s2mm_ctrl (
        .clk                        (clk),
        .rst                        (rst),
        .clear_error                (clear_error),
        .data_irq_ack               (data_irq_ack),
        .data_irq_req               (data_irq_req),
        .frame_valid               (frame_valid),
        .frame_ready               (frame_ready),
        .frame_channel             (frame_channel),
        .frame_mac_class           (frame_mac_class),
        .frame_len                 (frame_len),
        .frame_timestamp           (frame_timestamp),
        .ring_alloc_valid          (ring_alloc_valid),
        .ring_alloc_ready          (ring_alloc_ready),
        .ring_alloc_channel        (ring_alloc_channel),
        .ring_alloc_data_addr      (ring_alloc_data_addr),
        .ring_alloc_desc_addr      (ring_alloc_desc_addr),
        .ring_alloc_entry_index    (ring_alloc_entry_index),
        .ring_commit_valid         (ring_commit_valid),
        .ring_abort_valid          (ring_abort_valid),
        .packer_start_valid        (packer_start_valid),
        .packer_start_ready        (packer_start_ready),
        .packer_start_channel      (packer_start_channel),
        .packer_start_length       (packer_start_length),
        .packer_abort              (packer_abort),
        .packer_axis_tdata         (packer_axis_tdata),
        .packer_axis_tkeep         (packer_axis_tkeep),
        .packer_axis_tlast         (packer_axis_tlast),
        .packer_axis_tvalid        (packer_axis_tvalid),
        .packer_axis_tready        (packer_axis_tready),
        .desc_payload              (desc_payload),
        .m_axis_s2mm_cmd_tvalid    (s2mm_cmd_tvalid),
        .m_axis_s2mm_cmd_tready    (s2mm_cmd_tready),
        .m_axis_s2mm_cmd_tdata     (s2mm_cmd_tdata),
        .s_axis_s2mm_tvalid        (s2mm_axis_tvalid),
        .s_axis_s2mm_tready        (s2mm_axis_tready),
        .s_axis_s2mm_tdata         (s2mm_axis_tdata),
        .s_axis_s2mm_tkeep         (s2mm_axis_tkeep),
        .s_axis_s2mm_tlast         (s2mm_axis_tlast),
        .m_axis_s2mm_sts_tvalid    (s2mm_sts_tvalid),
        .m_axis_s2mm_sts_tready    (s2mm_sts_tready),
        .m_axis_s2mm_sts_tdata     (s2mm_sts_tdata),
        .m_axis_s2mm_sts_tkeep     (s2mm_sts_tkeep),
        .m_axis_s2mm_sts_tlast     (s2mm_sts_tlast),
        .busy                      (busy),
        .frame_done_pulse          (frame_done_pulse),
        .frame_count               (frame_count),
        .last_data_addr            (last_data_addr),
        .last_desc_addr            (last_desc_addr),
        .current_channel           (current_channel),
        .active_mac_class          (active_mac_class),
        .active_frame_len          (active_frame_len),
        .active_timestamp          (active_timestamp),
        .error                     (error),
        .error_pulse               (error_pulse),
        .error_code                (error_code),
        .error_count               (error_count),
        .param_error_count         (param_error_count),
        .tag_mismatch_count        (tag_mismatch_count),
        .data_status_error_count   (data_status_error_count),
        .desc_status_error_count   (desc_status_error_count)
    );

    // 下方实例为 Vivado 生成的 AXI DataMover IP。它把控制器提供的命令和 AXI4-Stream 负载
    // 转换为 AXI4-Full 写事务，并把每条命令的完成/错误状态返回控制器。
    // 实例模块名固定为 axi_datamover_rx，本地代码不提供该 IP 的 RTL 替代实现。
    axi_datamover_rx u_axi_datamover_rx (
        .m_axi_s2mm_aclk                   (clk),
        .m_axi_s2mm_aresetn                (~rst),
        .s2mm_halt                         (1'b0),
        .s2mm_halt_cmplt                   (s2mm_halt_cmplt),
        .s2mm_err                          (datamover_s2mm_err),
        .m_axis_s2mm_cmdsts_awclk          (clk),
        .m_axis_s2mm_cmdsts_aresetn        (~rst),
        .s_axis_s2mm_cmd_tvalid            (s2mm_cmd_tvalid),
        .s_axis_s2mm_cmd_tready            (s2mm_cmd_tready),
        .s_axis_s2mm_cmd_tdata             (s2mm_cmd_tdata),
        .m_axis_s2mm_sts_tvalid            (s2mm_sts_tvalid),
        .m_axis_s2mm_sts_tready            (s2mm_sts_tready),
        .m_axis_s2mm_sts_tdata             (s2mm_sts_tdata),
        .m_axis_s2mm_sts_tkeep             (s2mm_sts_tkeep),
        .m_axis_s2mm_sts_tlast             (s2mm_sts_tlast),
        .s2mm_allow_addr_req               (1'b1),
        .s2mm_addr_req_posted              (s2mm_addr_req_posted),
        .s2mm_wr_xfer_cmplt                (s2mm_wr_xfer_cmplt),
        .s2mm_ld_nxt_len                   (s2mm_ld_nxt_len),
        .s2mm_wr_len                       (s2mm_wr_len),
        .m_axi_s2mm_awaddr                 (m_axi_awaddr),
        .m_axi_s2mm_awlen                  (m_axi_awlen),
        .m_axi_s2mm_awsize                 (m_axi_awsize),
        .m_axi_s2mm_awburst                (m_axi_awburst),
        .m_axi_s2mm_awprot                 (m_axi_awprot),
        .m_axi_s2mm_awcache                (m_axi_awcache),
        .m_axi_s2mm_awuser                 (m_axi_awuser),
        .m_axi_s2mm_awvalid                (m_axi_awvalid),
        .m_axi_s2mm_awready                (m_axi_awready),
        .m_axi_s2mm_wdata                  (m_axi_wdata),
        .m_axi_s2mm_wstrb                  (m_axi_wstrb),
        .m_axi_s2mm_wlast                  (m_axi_wlast),
        .m_axi_s2mm_wvalid                 (m_axi_wvalid),
        .m_axi_s2mm_wready                 (m_axi_wready),
        .m_axi_s2mm_bresp                  (m_axi_bresp),
        .m_axi_s2mm_bvalid                 (m_axi_bvalid),
        .m_axi_s2mm_bready                 (m_axi_bready),
        .s_axis_s2mm_tdata                 (s2mm_axis_tdata),
        .s_axis_s2mm_tkeep                 (s2mm_axis_tkeep),
        .s_axis_s2mm_tlast                 (s2mm_axis_tlast),
        .s_axis_s2mm_tvalid                (s2mm_axis_tvalid),
        .s_axis_s2mm_tready                (s2mm_axis_tready),
        .s2mm_dbg_sel                      (4'd0),
        .s2mm_dbg_data                     (s2mm_dbg_data)
    );

    // 这些 DataMover 辅助/调试输出以及内部观察信号当前不参与控制，统一汇入占位线网。
    wire unused_top_signals = frame_desc[0] ^ packer_done_pulse ^
                              packer_active ^ s2mm_halt_cmplt ^
                              s2mm_addr_req_posted ^ s2mm_ld_nxt_len ^
                              s2mm_wr_len[0] ^ s2mm_dbg_data[0];

endmodule
```
