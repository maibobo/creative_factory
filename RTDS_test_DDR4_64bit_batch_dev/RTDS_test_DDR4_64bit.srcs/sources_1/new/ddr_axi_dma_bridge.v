// 将上游读写请求转换为 AXI 存储突发；读写方向独立运行。
// 地址按字节计，读写长度按数据拍计；每段突发不超过256拍且不跨越4KiB边界。
// AW与W通道可独立握手；写请求必须等最终B响应，读计数只随实际R通道握手推进。
// wr_data_valid表示上游写数据有效；wr_data_accept_event表示AXI W通道已接受该拍。
// 命名整理 2026-10-30：统一模块、请求端口和状态变量名称；不改变协议及时序行为。

`timescale 1ns / 1ps

// 通用 AXI DMA 桥接模块。
module ddr_axi_dma_bridge #
    (
        parameter integer                             M_AXI_ID_WIDTH       = 1    ,      // 本AXI主机事务ID位宽
        parameter integer                             M_AXI_ID             = 0    ,      // 本AXI主机固定事务ID数值
        parameter integer                             M_AXI_ADDR_WIDTH    = 64    ,      // 本AXI主机字节地址位宽
        parameter integer                             M_AXI_DATA_WIDTH    = 64           // 本AXI主机数据位宽
    )
    (
    input wire    [M_AXI_DATA_WIDTH/8-1:0]     wr_byte_enable,                               // 与 wr_data 同拍传输的逐字节写使能
    output reg                                 wr_done_event,                               // 写请求结束单周期事件（最终B响应完成或请求被拒绝）
    output reg                                 wr_error,                              // 本次写请求的响应或地址错误，与 wr_done_event 配对
    input wire    [M_AXI_ADDR_WIDTH-1 : 0]     wr_addr          ,                     // 写起始字节地址
    input                                      wr_req          ,                     // 写请求，保持到busy接受
    input wire    [15 : 0]                     wr_beat_count          ,                     // 写请求的数据拍数
    output                                     wr_busy          ,                     // 写请求仍在处理，包含等待响应

    input wire    [M_AXI_DATA_WIDTH-1 :0]      wr_data          ,                     // 当前写数据
    output wire                                wr_data_accept_event         ,                     // AXI WVALID 与 WREADY 握手后产生的单周期接受事件
    input wire                                 wr_data_valid         ,                     // 上游写数据有效；未被 AXI 接受时需保持数据和有效

    input wire    [M_AXI_ADDR_WIDTH-1 : 0]     rd_addr          ,                     // 读起始字节地址
    input                                      rd_req          ,                     // 读请求，保持到busy接受
    input wire    [15 : 0]                     rd_beat_count          ,                     // 读请求的数据拍数
    output                                     rd_busy          ,                     // 读请求仍在处理

    output wire   [M_AXI_DATA_WIDTH-1 :0]      rd_data          ,                     // 当前读数据
    output wire                                rd_data_accept_event         ,                     // AXI RVALID 与 RREADY 握手后产生的单周期接受事件
    input wire                                 rd_data_ready         ,                     // 读数据接收许可

    input wire                                 M_AXI_ACLK          ,                     // 存储侧AXI对应接口时钟，使用域由连接关系确定
    input wire                                 M_AXI_ARESETN       ,                     // 存储侧AXI低有效复位或同步复位状态
    output wire   [M_AXI_ID_WIDTH-1 : 0]       M_AXI_AWID          ,                     // 写地址ID，用来标志一组写信号
    output wire   [M_AXI_ADDR_WIDTH-1 : 0]     M_AXI_AWADDR        ,                     // 写地址，给出一次写突发传输的写地址
    output wire   [7 : 0]                      M_AXI_AWLEN         ,                     // 写突发拍数减1，供 AXI AWLEN 使用
    output wire   [2 : 0]                      M_AXI_AWSIZE        ,                     // 每拍传输字节数的 log2 编码
    output wire   [1 : 0]                      M_AXI_AWBURST       ,                     // 固定为 INCR（逐拍递增）
    output wire                                M_AXI_AWLOCK        ,                     // 未使用，固定为 0
    output wire   [3 : 0]                      M_AXI_AWCACHE       ,                     // 内存类型，表明一次传输是怎样通过系统的
    output wire   [2 : 0]                      M_AXI_AWPROT        ,                     // 保护类型，表明一次传输的特权级及安全等级
    output wire   [3 : 0]                      M_AXI_AWQOS         ,                     // 质量服务QoS
    output wire                                M_AXI_AWVALID       ,                     // 有效信号，表明此通道的地址控制信号有效
    input wire                                 M_AXI_AWREADY       ,                     // 表明“从”可以接收地址和对应的控制信号
    output wire   [M_AXI_ID_WIDTH-1 : 0]       M_AXI_WID           ,                     // 写数据通道 ID
    output wire   [M_AXI_DATA_WIDTH-1 : 0]     M_AXI_WDATA         ,                     // 写数据
    output wire   [M_AXI_DATA_WIDTH/8-1 : 0]   M_AXI_WSTRB         ,                     // 逐字节写使能，每一位对应一个数据字节
    output wire                                M_AXI_WLAST         ,                     // 当前 AXI 写突发的最后一拍
    output wire                                M_AXI_WVALID        ,                     // 写数据有效，保持到 WREADY 接受
    input wire                                 M_AXI_WREADY        ,                     // 表明从机可以接收写数据
    input wire    [M_AXI_ID_WIDTH-1 : 0]       M_AXI_BID           ,                     // 写响应 ID
    input wire    [1 : 0]                      M_AXI_BRESP         ,                     // 写响应，表明写传输的状态
    input wire                                 M_AXI_BVALID        ,                     // 写响应有效
    output wire                                M_AXI_BREADY        ,                     // 表明主机能够接收写响应
    output wire   [M_AXI_ID_WIDTH-1 : 0]       M_AXI_ARID          ,                     // 存储侧AXI读地址事务ID

    output wire   [M_AXI_ADDR_WIDTH-1 : 0]     M_AXI_ARADDR        ,                     // 存储侧AXI读突发起始字节地址
    output wire   [7 : 0]                      M_AXI_ARLEN         ,                     // 存储侧AXI读地址突发拍数减1
    output wire   [2 : 0]                      M_AXI_ARSIZE        ,                     // 存储侧AXI读地址每拍字节数的log2编码
    output wire   [1 : 0]                      M_AXI_ARBURST       ,                     // 存储侧AXI读地址地址类型，INCR为逐拍递增
    output wire                                M_AXI_ARLOCK        ,                     // 存储侧AXI读地址通道lock属性
    output wire   [3 : 0]                      M_AXI_ARCACHE       ,                     // 存储侧AXI读地址通道cache属性
    output wire   [2 : 0]                      M_AXI_ARPROT        ,                     // 存储侧AXI读地址通道prot属性
    output wire   [3 : 0]                      M_AXI_ARQOS         ,                     // 存储侧AXI读地址通道qos属性
    output wire                                M_AXI_ARVALID       ,                     // 存储侧AXI读地址通道有效，保持到ready接受
    input wire                                 M_AXI_ARREADY       ,                     // 存储侧AXI读地址通道当前可接受
    input wire    [M_AXI_ID_WIDTH-1 : 0]       M_AXI_RID           ,                     // 存储侧AXI读数据事务ID
    input wire    [M_AXI_DATA_WIDTH-1 : 0]     M_AXI_RDATA         ,                     // 存储侧AXI读数据当前数据
    input wire    [1 : 0]                      M_AXI_RRESP         ,                     // 存储侧AXI读数据响应码，0为OKAY、2为SLVERR
    input wire                                 M_AXI_RLAST         ,                     // 存储侧AXI读数据最后一拍标志
    input wire                                 M_AXI_RVALID        ,                     // 存储侧AXI读数据通道有效，保持到ready接受
    output wire                                M_AXI_RREADY                              // 存储侧AXI读数据通道当前可接受

        );
    localparam integer                             AXI_BYTES = M_AXI_DATA_WIDTH/8         ;    // 每拍数据字节数
    localparam integer                             SIZE_BITS = $clog2(AXI_BYTES)          ;    // 每拍数据字节数的 log2 编码
    localparam    [2:0]                        WRITE_IDLE=3'd0                                ;    // 写状态机：空闲
    localparam    [2:0]                        WRITE_PREPARE=3'd1                                ;    // 写状态机：准备当前突发
    localparam    [2:0]                        WRITE_SEND=3'd2                                ;    // 写状态机：发送地址和数据
    localparam    [2:0]                        WRITE_RESPONSE=3'd3                                ;    // 写状态机：等待写响应
    localparam    [2:0]                        READ_IDLE=3'd0                                ;    // 读状态机：空闲
    localparam    [2:0]                        READ_PREPARE=3'd1                                ;    // 读状态机：准备当前突发
    localparam    [2:0]                        READ_ADDRESS=3'd2                                ;    // 读状态机：发送读地址
    localparam    [2:0]                        READ_DATA=3'd3                                ;    // 读状态机：接收读数据
    reg           [2:0]                        write_transaction_state                              ;    // 当前写事务状态
    reg           [2:0]                        read_transaction_state                               ;    // 当前读事务状态
    reg           [M_AXI_ADDR_WIDTH-1:0]       write_transaction_addr                                         ;    // 当前写突发的字节地址
    reg           [M_AXI_ADDR_WIDTH-1:0]       read_transaction_addr                                         ;    // 当前读突发的字节地址
    reg           [15:0]                       write_beats_remaining                                      ;    // 整个写请求尚未收到响应的拍数
    reg           [15:0]                       read_beats_remaining                                      ;    // 整个读请求尚未完成数据握手的拍数
    reg           [8:0]                        write_burst_beat_count                                         ;    // 当前写段拍数，1～256
    reg           [8:0]                        read_burst_beat_count                                         ;    // 当前读段拍数，1～256
    reg           [8:0]                        write_burst_beat_index                                      ;    // 当前写段已接受拍位置
    reg           [8:0]                        read_burst_beat_index                                      ;    // 当前读段已接受拍位置
    reg                                        write_address_pending                                 ;    // 当前段AW尚未接受
    reg                                        write_data_pending                                  ;    // 当前段W尚未收完
    wire                                       m_axi_w_handshake                                        ;    // AXI W实际接受事件
    wire                                       m_axi_r_handshake                                        ;    // AXI R实际接受事件
    function [8:0] burst_beats;
        input         [M_AXI_ADDR_WIDTH-1:0]       address                                ;    // 计算分段长度时使用的当前字节地址
        input         [15:0]                       remaining                              ;    // 整次请求剩余数据拍数
        reg           [15:0]                       available                              ;    // 当前地址距4KiB末端可容纳的拍数
        begin
            available=(16'd4096-{4'd0,address[11:0]})/AXI_BYTES;
            if (available > 16'd256)
                available=16'd256;
            if (remaining < available)
                available=remaining;
            burst_beats=available[8:0];
        end
    endfunction

    wire          [8:0]                        write_burst_len_minus_one                        ;    // 当前写段拍数减1，形成AXI AWLEN
    wire          [8:0]                        read_burst_len_minus_one                         ;    // 当前读段拍数减1，形成AXI ARLEN
    localparam    [M_AXI_ID_WIDTH-1:0]         AXI_FIXED_ID = M_AXI_ID[M_AXI_ID_WIDTH-1:0];    // 固定 AXI 事务 ID
    localparam    [2:0]                        AXI_SIZE = SIZE_BITS[2:0]                  ;    // AXI 每拍字节数编码

    assign write_burst_len_minus_one = write_burst_beat_count - 9'd1                                                ;    // 当前写段拍数减1，形成AXI AWLEN

    assign read_burst_len_minus_one = read_burst_beat_count - 9'd1                                                 ;    // 当前读段拍数减1，形成AXI ARLEN

    assign wr_busy=(write_transaction_state != WRITE_IDLE)                                           ;    // 写请求仍在处理，包含等待响应

    assign M_AXI_AWID=AXI_FIXED_ID                                                        ;    // 写地址ID，用来标志一组写信号

    assign M_AXI_WID=AXI_FIXED_ID                                                         ;    // 写数据通道 ID

    assign M_AXI_AWADDR=write_transaction_addr                                                                ;    // 写地址，给出一次写突发传输的写地址

    assign M_AXI_AWLEN=write_burst_len_minus_one[7:0]                                           ;    // 写突发拍数减1，供 AXI AWLEN 使用

    assign M_AXI_AWSIZE=AXI_SIZE                                                          ;    // 每拍传输字节数的 log2 编码

    assign M_AXI_AWBURST=2'b01                                                            ;    // 固定为 INCR（逐拍递增）

    assign M_AXI_AWLOCK=1'b0                                                              ;    // 未使用，固定为 0

    assign M_AXI_AWCACHE=4'b0010                                                          ;    // 内存类型，表明一次传输是怎样通过系统的

    assign M_AXI_AWPROT=3'd0                                                              ;    // 保护类型，表明一次传输的特权级及安全等级

    assign M_AXI_AWQOS=4'd0                                                               ;    // 质量服务QoS

    assign M_AXI_AWVALID=(write_transaction_state == WRITE_SEND) && write_address_pending                          ;    // 有效信号，表明此通道的地址控制信号有效

    assign M_AXI_WDATA=wr_data                                                         ;    // 写数据

    assign M_AXI_WSTRB=wr_byte_enable                                                         ;    // 逐字节写使能，每一位对应一个数据字节

    assign M_AXI_WLAST=(write_burst_beat_index == write_burst_beat_count-9'd1)                                                 ;    // 当前 AXI 写突发的最后一拍

    assign M_AXI_WVALID=(write_transaction_state == WRITE_SEND) && write_data_pending && wr_data_valid             ;    // 写数据有效，保持到 WREADY 接受

    assign m_axi_w_handshake=M_AXI_WVALID && M_AXI_WREADY                                               ;    // AXI W实际接受事件

    assign wr_data_accept_event=m_axi_w_handshake                                                                ;    // AXI WVALID 与 WREADY 握手后产生的单周期接受事件

    assign M_AXI_BREADY=(write_transaction_state == WRITE_RESPONSE)                                         ;    // 表明主机能够接收写响应


    reg           [2:0]                        write_next_state                              ;    // 完整组合次态，默认保持当前态


    // 计算写次态：校验请求后分段，AW/W独立处理，等B响应后继续下一段或结束。
    always @(*) begin : calculate_write_next_state
        write_next_state = write_transaction_state;

        if (! M_AXI_ARESETN) begin
            write_next_state = WRITE_IDLE ;
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                    if (wr_req) begin
                        if (wr_beat_count == 0 || ( wr_addr % AXI_BYTES ) != 0) begin
                        end else begin
                            write_next_state = WRITE_PREPARE ;
                        end
                    end
                end
                WRITE_PREPARE: begin
                    write_next_state = WRITE_SEND ;
                end
                WRITE_SEND: begin
                    if (! write_address_pending && ! write_data_pending) begin
                        write_next_state = WRITE_RESPONSE ;
                    end
                end
                WRITE_RESPONSE: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        if (write_beats_remaining == write_burst_beat_count) begin
                            write_next_state = WRITE_IDLE ;
                        end else begin
                            write_next_state = WRITE_PREPARE ;
                        end
                    end
                end
                default: begin
                    write_next_state = WRITE_IDLE ;
                end
            endcase
        end
        end


    // AXI时钟沿保存写次态，复位回WRITE_IDLE。
    always @(posedge M_AXI_ACLK) begin : register_write_state
        if (!M_AXI_ARESETN) begin
            write_transaction_state <= WRITE_IDLE;
        end else begin
            write_transaction_state <= write_next_state;
        end
    end


    // 接受新写请求时保存基址；每个B响应完成当前段后，地址增加该段字节数。
    always @ ( posedge M_AXI_ACLK ) begin : update_wa
        if (! M_AXI_ARESETN) begin
            write_transaction_addr <= {M_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                    if (wr_req) begin
                        if (wr_beat_count == 0 || ( wr_addr % AXI_BYTES ) != 0) begin
                        end else begin
                            write_transaction_addr <= wr_addr ;
                        end
                    end
                end
                WRITE_PREPARE: begin
                end
                WRITE_SEND: begin
                end
                WRITE_RESPONSE: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        if (write_beats_remaining == write_burst_beat_count) begin
                        end else begin
                            write_transaction_addr <= write_transaction_addr + write_burst_beat_count * AXI_BYTES ;
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end


    // 保存整次写请求尚未完成的拍数；收到B响应后扣除当前段，不能按W末拍提前扣除。
    always @ ( posedge M_AXI_ACLK ) begin : update_wleft
        if (! M_AXI_ARESETN) begin
            write_beats_remaining <= 16'd0;
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                    if (wr_req) begin
                        if (wr_beat_count == 0 || ( wr_addr % AXI_BYTES ) != 0) begin
                        end else begin
                            write_beats_remaining <= wr_beat_count ;
                        end
                    end
                end
                WRITE_PREPARE: begin
                end
                WRITE_SEND: begin
                end
                WRITE_RESPONSE: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        if (write_beats_remaining == write_burst_beat_count) begin
                        end else begin
                            write_beats_remaining <= write_beats_remaining - write_burst_beat_count ;
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end


    // 准备每段写长度：取剩余拍数、256拍上限和距4KiB边界拍数的最小值。
    always @ ( posedge M_AXI_ACLK ) begin : update_wb
        if (! M_AXI_ARESETN) begin
            write_burst_beat_count <= 9'd0;
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                end
                WRITE_PREPARE: begin
                    write_burst_beat_count <= burst_beats ( write_transaction_addr , write_beats_remaining ) ;
                end
                WRITE_SEND: begin
                end
                WRITE_RESPONSE: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 每个W握手推进段内拍位置，末拍后归零；没有握手时保持。
    always @ ( posedge M_AXI_ACLK ) begin : update_wbeat
        if (! M_AXI_ARESETN) begin
            write_burst_beat_index <= 9'd0;
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                end
                WRITE_PREPARE: begin
                    write_burst_beat_index <= 9'd0;
                end
                WRITE_SEND: begin
                    if (m_axi_w_handshake) begin
                        if (write_burst_beat_index == write_burst_beat_count - 9'd1) begin
                        end else begin
                            write_burst_beat_index <= write_burst_beat_index + 9'd1 ;
                        end
                    end
                end
                WRITE_RESPONSE: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 每段开始置AW待接受，实际AW握手后清除；不要求AW与W同拍到达。
    always @ ( posedge M_AXI_ACLK ) begin : update_aw_pending
        if (! M_AXI_ARESETN) begin
            write_address_pending <= 1'd0;
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                end
                WRITE_PREPARE: begin
                    write_address_pending <= 1'b1 ;
                end
                WRITE_SEND: begin
                    if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                        write_address_pending <= 1'b0 ;
                    end
                end
                WRITE_RESPONSE: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 每段开始置W待发送，最后一拍实际接受后清除，之后仍需等待AW/B。
    always @ ( posedge M_AXI_ACLK ) begin : update_w_pending
        if (! M_AXI_ARESETN) begin
            write_data_pending <= 1'd0;
        end else begin
            case (write_transaction_state)
                WRITE_IDLE: begin
                end
                WRITE_PREPARE: begin
                    write_data_pending <= 1'b1 ;
                end
                WRITE_SEND: begin
                    if (m_axi_w_handshake) begin
                        if (write_burst_beat_index == write_burst_beat_count - 9'd1) begin
                            write_data_pending <= 1'b0 ;
                        end
                    end
                end
                WRITE_RESPONSE: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 只在最后B握手或拒绝非法请求时给一次wr_done_event；W末拍不等于写成功。
    always @(posedge M_AXI_ACLK) begin : update_fdma_wdone
        if (!M_AXI_ARESETN) begin
            wr_done_event <= 1'b0;
        end else if (write_transaction_state == WRITE_IDLE && wr_req &&
                     (wr_beat_count == 0 || (wr_addr % AXI_BYTES) != 0)) begin
            wr_done_event <= 1'b1;
        end else if (write_transaction_state == WRITE_RESPONSE && M_AXI_BVALID && M_AXI_BREADY && write_beats_remaining == write_burst_beat_count) begin
            wr_done_event <= 1'b1;
        end else begin
            wr_done_event <= 1'b0;
        end
    end


    // 新写请求清上一任务错误；本请求任一B非OKAY后保持wr_error直到下一请求。
    always @(posedge M_AXI_ACLK) begin : update_fdma_werror
        if (!M_AXI_ARESETN) begin
            wr_error <= 1'b0;
        end else if (write_transaction_state == WRITE_IDLE && wr_req) begin
            wr_error <= (wr_beat_count == 0 || (wr_addr % AXI_BYTES) != 0);
        end else if (write_transaction_state == WRITE_RESPONSE && M_AXI_BVALID && M_AXI_BREADY &&
                     (M_AXI_BRESP != 2'b00 || M_AXI_BID != AXI_FIXED_ID)) begin
            wr_error <= 1'b1;
        end
    end


    assign rd_busy=(read_transaction_state != READ_IDLE)                                            ;    // 读请求仍在处理

    assign M_AXI_ARID=AXI_FIXED_ID                                                        ;    // 存储侧AXI读地址事务ID

    assign M_AXI_ARADDR=read_transaction_addr                                                                ;    // 存储侧AXI读突发起始字节地址

    assign M_AXI_ARLEN=read_burst_len_minus_one[7:0]                                            ;    // 存储侧AXI读地址突发拍数减1

    assign M_AXI_ARSIZE=AXI_SIZE                                                          ;    // 存储侧AXI读地址每拍字节数的log2编码

    assign M_AXI_ARBURST=2'b01                                                            ;    // 存储侧AXI读地址地址类型，INCR为逐拍递增

    assign M_AXI_ARLOCK=1'b0                                                              ;    // 存储侧AXI读地址通道lock属性

    assign M_AXI_ARCACHE=4'b0010                                                          ;    // 存储侧AXI读地址通道cache属性

    assign M_AXI_ARPROT=3'd0                                                              ;    // 存储侧AXI读地址通道prot属性

    assign M_AXI_ARQOS=4'd0                                                               ;    // 存储侧AXI读地址通道qos属性

    assign M_AXI_ARVALID=(read_transaction_state==READ_ADDRESS)                                           ;    // 存储侧AXI读地址通道有效，保持到ready接受

    assign M_AXI_RREADY=(read_transaction_state==READ_DATA) && rd_data_ready                             ;    // 存储侧AXI读数据通道当前可接受

    assign m_axi_r_handshake=M_AXI_RVALID && M_AXI_RREADY                                               ;    // AXI R实际接受事件

    assign rd_data=M_AXI_RDATA                                                         ;    // 当前读数据

    assign rd_data_accept_event=m_axi_r_handshake                                                                ;    // AXI RVALID 与 RREADY 握手后产生的单周期接受事件

    reg           [2:0]                        read_next_state                               ;    // 完整组合次态，默认保持当前态


    // 计算读次态：分段提交AR，收到该段规定的全部R拍后继续或结束。
    always @(*) begin : calculate_read_next_state
        read_next_state = read_transaction_state;

        if (! M_AXI_ARESETN) begin
            read_next_state = READ_IDLE ;
        end else begin
            case (read_transaction_state)
                READ_IDLE: begin
                    if (rd_req && rd_beat_count != 0) begin
                        read_next_state = READ_PREPARE ;
                    end
                end
                READ_PREPARE: begin
                    read_next_state = READ_ADDRESS ;
                end
                READ_ADDRESS: begin
                    if (M_AXI_ARREADY) begin
                        read_next_state = READ_DATA ;
                    end
                end
                READ_DATA: begin
                    if (m_axi_r_handshake) begin
                        if (read_burst_beat_index == read_burst_beat_count - 9'd1) begin
                            if (read_beats_remaining == read_burst_beat_count) begin
                                read_next_state = READ_IDLE ;
                            end else begin
                                read_next_state = READ_PREPARE ;
                            end
                        end
                    end
                end
                default: begin
                    read_next_state = READ_IDLE ;
                end
            endcase
        end
        end


    // AXI时钟沿保存读次态，复位回READ_IDLE。
    always @(posedge M_AXI_ACLK) begin : register_read_state
        if (!M_AXI_ARESETN) begin
            read_transaction_state <= READ_IDLE;
        end else begin
            read_transaction_state <= read_next_state;
        end
    end


    // 接受读请求时保存地址；当前读段收齐后增加已读字节数，AR等待期间地址保持。
    always @ ( posedge M_AXI_ACLK ) begin : update_ra
        if (! M_AXI_ARESETN) begin
            read_transaction_addr <= {M_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            case (read_transaction_state)
                READ_IDLE: begin
                    if (rd_req && rd_beat_count != 0) begin
                        read_transaction_addr <= rd_addr ;
                    end
                end
                READ_PREPARE: begin
                end
                READ_ADDRESS: begin
                end
                READ_DATA: begin
                    if (m_axi_r_handshake) begin
                        if (read_burst_beat_index == read_burst_beat_count - 9'd1) begin
                            if (read_beats_remaining == read_burst_beat_count) begin
                            end else begin
                                read_transaction_addr <= read_transaction_addr + read_burst_beat_count * AXI_BYTES ;
                            end
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end


    // 保存整次读尚未完成的拍数；当前段最后R实际接受后扣减。
    always @ ( posedge M_AXI_ACLK ) begin : update_rleft
        if (! M_AXI_ARESETN) begin
            read_beats_remaining <= 16'd0;
        end else begin
            case (read_transaction_state)
                READ_IDLE: begin
                    if (rd_req && rd_beat_count != 0) begin
                        read_beats_remaining <= rd_beat_count ;
                    end
                end
                READ_PREPARE: begin
                end
                READ_ADDRESS: begin
                end
                READ_DATA: begin
                    if (m_axi_r_handshake) begin
                        if (read_burst_beat_index == read_burst_beat_count - 9'd1) begin
                            if (read_beats_remaining == read_burst_beat_count) begin
                            end else begin
                                read_beats_remaining <= read_beats_remaining - read_burst_beat_count ;
                            end
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end


    // 准备每段读长度，采用与写方向相同的256拍和4KiB限制。
    always @ ( posedge M_AXI_ACLK ) begin : update_rb
        if (! M_AXI_ARESETN) begin
            read_burst_beat_count <= 9'd0;
        end else begin
            case (read_transaction_state)
                READ_IDLE: begin
                end
                READ_PREPARE: begin
                    read_burst_beat_count <= burst_beats ( read_transaction_addr , read_beats_remaining ) ;
                end
                READ_ADDRESS: begin
                end
                READ_DATA: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 只在R有效与ready同拍成立时推进段内读位置，不把等待周期计成数据拍。
    always @ ( posedge M_AXI_ACLK ) begin : update_rbeat
        if (! M_AXI_ARESETN) begin
            read_burst_beat_index <= 9'd0;
        end else begin
            case (read_transaction_state)
                READ_IDLE: begin
                end
                READ_PREPARE: begin
                    read_burst_beat_index <= 9'd0;
                end
                READ_ADDRESS: begin
                end
                READ_DATA: begin
                    if (m_axi_r_handshake) begin
                        if (read_burst_beat_index == read_burst_beat_count - 9'd1) begin
                        end else begin
                            read_burst_beat_index <= read_burst_beat_index + 9'd1 ;
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end

endmodule
