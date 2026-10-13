// 将FDMA读写请求转换成AXI存储突发，读写方向独立运行。
// 地址按字节计，fdma_size按数据拍计；突发受256拍和4KiB边界限制。
// AW与W允许独立接受，写完成必须等最终B响应；读计数只随实际R握手推进。
// 本模块fdma_wready输入表示源数据有效，fdma_wvalid输出表示当前拍已接受。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module CONV_DMA #
    (
        parameter integer                             M_AXI_ID_WIDTH       = 1    ,      // 本AXI主机事务ID位宽
        parameter integer                             M_AXI_ID             = 0    ,      // 本AXI主机固定事务ID数值
        parameter integer                             M_AXI_ADDR_WIDTH    = 64    ,      // 本AXI主机字节地址位宽
        parameter integer                             M_AXI_DATA_WIDTH    = 64           // 本AXI主机数据位宽
    )
    (
    input wire    [M_AXI_DATA_WIDTH/8-1:0]     fdma_wstrb,                               // 与W数据同步保持，末尾单字仅低4Byte有效
    output reg                                 fdma_wdone,                               // 全部写响应已返回的单周期事件
    output reg                                 fdma_werror,                              // 本次事务响应/地址错误，与done配对
    input wire    [M_AXI_ADDR_WIDTH-1 : 0]     fdma_waddr          ,                     // 写起始字节地址
    input                                      fdma_wareq          ,                     // 写请求，保持到busy接受
    input wire    [15 : 0]                     fdma_wsize          ,                     // 写请求64bit拍数
    output                                     fdma_wbusy          ,                     // 写请求仍在处理，包含等待响应

    input wire    [M_AXI_DATA_WIDTH-1 :0]      fdma_wdata          ,                     // 当前写数据
    output wire                                fdma_wvalid         ,                     // 历史命名：valid输出实际是数据接受脉冲
    input wire                                 fdma_wready         ,                     // 写接受/有效信号，方向含义见模块头

    input wire    [M_AXI_ADDR_WIDTH-1 : 0]     fdma_raddr          ,                     // 读起始字节地址
    input                                      fdma_rareq          ,                     // 读请求，保持到busy接受
    input wire    [15 : 0]                     fdma_rsize          ,                     // 读请求64bit拍数
    output                                     fdma_rbusy          ,                     // 读请求仍在处理

    output wire   [M_AXI_DATA_WIDTH-1 :0]      fdma_rdata          ,                     // 当前读数据
    output wire                                fdma_rvalid         ,                     // 保留现有读桥的accept语义
    input wire                                 fdma_rready         ,                     // 读数据接收许可

    input wire                                 M_AXI_ACLK          ,                     // MIG用户域对应接口时钟，使用域由连接关系确定
    input wire                                 M_AXI_ARESETN       ,                     // MIG用户域低有效复位或同步复位状态
    output wire   [M_AXI_ID_WIDTH-1 : 0]       M_AXI_AWID          ,                     // 写地址ID，用来标志一组写信号
    output wire   [M_AXI_ADDR_WIDTH-1 : 0]     M_AXI_AWADDR        ,                     // 写地址，给出一次写突发传输的写地址
    output wire   [7 : 0]                      M_AXI_AWLEN         ,                     // 突发长度，给出突发传输的次数
    output wire   [2 : 0]                      M_AXI_AWSIZE        ,                     // 突发大小，给出每次突发传输的字节数
    output wire   [1 : 0]                      M_AXI_AWBURST       ,                     // 突发类型
    output wire                                M_AXI_AWLOCK        ,                     // 总线锁信号，可提供操作的原子性
    output wire   [3 : 0]                      M_AXI_AWCACHE       ,                     // 内存类型，表明一次传输是怎样通过系统的
    output wire   [2 : 0]                      M_AXI_AWPROT        ,                     // 保护类型，表明一次传输的特权级及安全等级
    output wire   [3 : 0]                      M_AXI_AWQOS         ,                     // 质量服务QoS
    output wire                                M_AXI_AWVALID       ,                     // 有效信号，表明此通道的地址控制信号有效
    input wire                                 M_AXI_AWREADY       ,                     // 表明“从”可以接收地址和对应的控制信号
    output wire   [M_AXI_ID_WIDTH-1 : 0]       M_AXI_WID           ,                     // 写响应ID tag
    output wire   [M_AXI_DATA_WIDTH-1 : 0]     M_AXI_WDATA         ,                     // 写数据
    output wire   [M_AXI_DATA_WIDTH/8-1 : 0]   M_AXI_WSTRB         ,                     // 写数据有效的字节线，用来表明哪8bits数据是有效的
    output wire                                M_AXI_WLAST         ,                     // 表明此次传输是最后一个突发传输
    output wire                                M_AXI_WVALID        ,                     // 写有效，表明此次写有效
    input wire                                 M_AXI_WREADY        ,                     // 表明从机可以接收写数据
    input wire    [M_AXI_ID_WIDTH-1 : 0]       M_AXI_BID           ,                     // 写响应ID tag
    input wire    [1 : 0]                      M_AXI_BRESP         ,                     // 写响应，表明写传输的状态
    input wire                                 M_AXI_BVALID        ,                     // 写响应有效
    output wire                                M_AXI_BREADY        ,                     // 表明主机能够接收写响应
    output wire   [M_AXI_ID_WIDTH-1 : 0]       M_AXI_ARID          ,                     // MIG用户域读地址事务ID

    output wire   [M_AXI_ADDR_WIDTH-1 : 0]     M_AXI_ARADDR        ,                     // MIG用户域读突发起始字节地址
    output wire   [7 : 0]                      M_AXI_ARLEN         ,                     // MIG用户域读地址突发拍数减1
    output wire   [2 : 0]                      M_AXI_ARSIZE        ,                     // MIG用户域读地址每拍字节数的log2编码
    output wire   [1 : 0]                      M_AXI_ARBURST       ,                     // MIG用户域读地址地址类型，INCR为逐拍递增
    output wire                                M_AXI_ARLOCK        ,                     // MIG用户域读地址通道lock属性
    output wire   [3 : 0]                      M_AXI_ARCACHE       ,                     // MIG用户域读地址通道cache属性
    output wire   [2 : 0]                      M_AXI_ARPROT        ,                     // MIG用户域读地址通道prot属性
    output wire   [3 : 0]                      M_AXI_ARQOS         ,                     // MIG用户域读地址通道qos属性
    output wire                                M_AXI_ARVALID       ,                     // MIG用户域读地址通道有效，保持到ready接受
    input wire                                 M_AXI_ARREADY       ,                     // MIG用户域读地址通道当前可接受
    input wire    [M_AXI_ID_WIDTH-1 : 0]       M_AXI_RID           ,                     // MIG用户域读数据事务ID
    input wire    [M_AXI_DATA_WIDTH-1 : 0]     M_AXI_RDATA         ,                     // MIG用户域读数据当前数据
    input wire    [1 : 0]                      M_AXI_RRESP         ,                     // MIG用户域读数据响应码，0为OKAY、2为SLVERR
    input wire                                 M_AXI_RLAST         ,                     // MIG用户域读数据最后一拍标志
    input wire                                 M_AXI_RVALID        ,                     // MIG用户域读数据通道有效，保持到ready接受
    output wire                                M_AXI_RREADY                              // MIG用户域读数据通道当前可接受

        );
    localparam integer                             AXI_BYTES = M_AXI_DATA_WIDTH/8         ;    // 本模块AXI_BYTES固定配置/状态编码
    localparam integer                             SIZE_BITS = $clog2(AXI_BYTES)          ;    // 本模块SIZE_BITS固定配置/状态编码
    localparam    [2:0]                        W_IDLE=3'd0                                ;    // 本模块W_IDLE固定配置/状态编码
    localparam    [2:0]                        W_PREP=3'd1                                ;    // 本模块W_PREP固定配置/状态编码
    localparam    [2:0]                        W_SEND=3'd2                                ;    // 本模块W_SEND固定配置/状态编码
    localparam    [2:0]                        W_RESP=3'd3                                ;    // 本模块W_RESP固定配置/状态编码
    localparam    [2:0]                        R_IDLE=3'd0                                ;    // 本模块R_IDLE固定配置/状态编码
    localparam    [2:0]                        R_PREP=3'd1                                ;    // 本模块R_PREP固定配置/状态编码
    localparam    [2:0]                        R_ADDR=3'd2                                ;    // 本模块R_ADDR固定配置/状态编码
    localparam    [2:0]                        R_DATA=3'd3                                ;    // 本模块R_DATA固定配置/状态编码
    reg           [2:0]                        write_curr_st                              ;    // 当前写事务状态
    reg           [2:0]                        read_curr_st                               ;    // 当前读事务状态
    reg           [M_AXI_ADDR_WIDTH-1:0]       wa                                         ;    // 当前写突发的字节地址
    reg           [M_AXI_ADDR_WIDTH-1:0]       ra                                         ;    // 当前读突发的字节地址
    reg           [15:0]                       wleft                                      ;    // 整次FDMA写尚未响应完成的拍数
    reg           [15:0]                       rleft                                      ;    // 整次FDMA读尚未接受完成的拍数
    reg           [8:0]                        wb                                         ;    // 当前写段拍数，1～256
    reg           [8:0]                        rb                                         ;    // 当前读段拍数，1～256
    reg           [8:0]                        wbeat                                      ;    // 当前写段已接受拍位置
    reg           [8:0]                        rbeat                                      ;    // 当前读段已接受拍位置
    reg                                        aw_pending                                 ;    // 当前段AW尚未接受
    reg                                        w_pending                                  ;    // 当前段W尚未收完
    wire                                       whs                                        ;    // AXI W实际接受事件
    wire                                       rhs                                        ;    // AXI R实际接受事件
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

    wire          [8:0]                        write_len_minus_one                        ;    // 当前写段拍数减1，形成AXI AWLEN
    wire          [8:0]                        read_len_minus_one                         ;    // 当前读段拍数减1，形成AXI ARLEN
    localparam    [M_AXI_ID_WIDTH-1:0]         AXI_FIXED_ID = M_AXI_ID[M_AXI_ID_WIDTH-1:0];    // 本模块AXI_FIXED_ID固定配置/状态编码
    localparam    [2:0]                        AXI_SIZE = SIZE_BITS[2:0]                  ;    // 本模块AXI_SIZE固定配置/状态编码

    assign write_len_minus_one = wb - 9'd1                                                ;    // 当前写段拍数减1，形成AXI AWLEN

    assign read_len_minus_one = rb - 9'd1                                                 ;    // 当前读段拍数减1，形成AXI ARLEN

    assign fdma_wbusy=(write_curr_st != W_IDLE)                                           ;    // 写请求仍在处理，包含等待响应

    assign M_AXI_AWID=AXI_FIXED_ID                                                        ;    // 写地址ID，用来标志一组写信号

    assign M_AXI_WID=AXI_FIXED_ID                                                         ;    // 写响应ID tag

    assign M_AXI_AWADDR=wa                                                                ;    // 写地址，给出一次写突发传输的写地址

    assign M_AXI_AWLEN=write_len_minus_one[7:0]                                           ;    // 突发长度，给出突发传输的次数

    assign M_AXI_AWSIZE=AXI_SIZE                                                          ;    // 突发大小，给出每次突发传输的字节数

    assign M_AXI_AWBURST=2'b01                                                            ;    // 突发类型

    assign M_AXI_AWLOCK=1'b0                                                              ;    // 总线锁信号，可提供操作的原子性

    assign M_AXI_AWCACHE=4'b0010                                                          ;    // 内存类型，表明一次传输是怎样通过系统的

    assign M_AXI_AWPROT=3'd0                                                              ;    // 保护类型，表明一次传输的特权级及安全等级

    assign M_AXI_AWQOS=4'd0                                                               ;    // 质量服务QoS

    assign M_AXI_AWVALID=(write_curr_st == W_SEND) && aw_pending                          ;    // 有效信号，表明此通道的地址控制信号有效

    assign M_AXI_WDATA=fdma_wdata                                                         ;    // 写数据

    assign M_AXI_WSTRB=fdma_wstrb                                                         ;    // 写数据有效的字节线，用来表明哪8bits数据是有效的

    assign M_AXI_WLAST=(wbeat == wb-9'd1)                                                 ;    // 表明此次传输是最后一个突发传输

    assign M_AXI_WVALID=(write_curr_st == W_SEND) && w_pending && fdma_wready             ;    // 写有效，表明此次写有效

    assign whs=M_AXI_WVALID && M_AXI_WREADY                                               ;    // AXI W实际接受事件

    assign fdma_wvalid=whs                                                                ;    // 历史命名：valid输出实际是数据接受脉冲

    assign M_AXI_BREADY=(write_curr_st == W_RESP)                                         ;    // 表明主机能够接收写响应


    reg           [2:0]                        write_next_st                              ;    // 完整组合次态，默认保持当前态


    // 计算写次态：校验请求后分段，AW/W独立处理，等B响应后继续下一段或结束。
    always @(*) begin : calculate_write_next_st
        write_next_st = write_curr_st;

        if (! M_AXI_ARESETN) begin
            write_next_st = W_IDLE ;
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                    if (fdma_wareq) begin
                        if (fdma_wsize == 0 || ( fdma_waddr % AXI_BYTES ) != 0) begin
                        end else begin
                            write_next_st = W_PREP ;
                        end
                    end
                end
                W_PREP: begin
                    write_next_st = W_SEND ;
                end
                W_SEND: begin
                    if (! aw_pending && ! w_pending) begin
                        write_next_st = W_RESP ;
                    end
                end
                W_RESP: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        if (wleft == wb) begin
                            write_next_st = W_IDLE ;
                        end else begin
                            write_next_st = W_PREP ;
                        end
                    end
                end
                default: begin
                    write_next_st = W_IDLE ;
                end
            endcase
        end
        end


    // AXI时钟沿保存写次态，复位回W_IDLE。
    always @(posedge M_AXI_ACLK) begin : register_write_state
        if (!M_AXI_ARESETN) begin
            write_curr_st <= W_IDLE;
        end else begin
            write_curr_st <= write_next_st;
        end
    end


    // 接受新写请求时保存基址；每个B响应完成当前段后，地址增加该段字节数。
    always @ ( posedge M_AXI_ACLK ) begin : update_wa
        if (! M_AXI_ARESETN) begin
            wa <= {M_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                    if (fdma_wareq) begin
                        if (fdma_wsize == 0 || ( fdma_waddr % AXI_BYTES ) != 0) begin
                        end else begin
                            wa <= fdma_waddr ;
                        end
                    end
                end
                W_PREP: begin
                end
                W_SEND: begin
                end
                W_RESP: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        if (wleft == wb) begin
                        end else begin
                            wa <= wa + wb * AXI_BYTES ;
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
            wleft <= 16'd0;
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                    if (fdma_wareq) begin
                        if (fdma_wsize == 0 || ( fdma_waddr % AXI_BYTES ) != 0) begin
                        end else begin
                            wleft <= fdma_wsize ;
                        end
                    end
                end
                W_PREP: begin
                end
                W_SEND: begin
                end
                W_RESP: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        if (wleft == wb) begin
                        end else begin
                            wleft <= wleft - wb ;
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
            wb <= 9'd0;
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                end
                W_PREP: begin
                    wb <= burst_beats ( wa , wleft ) ;
                end
                W_SEND: begin
                end
                W_RESP: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 每个W握手推进段内拍位置，末拍后归零；没有握手时保持。
    always @ ( posedge M_AXI_ACLK ) begin : update_wbeat
        if (! M_AXI_ARESETN) begin
            wbeat <= 9'd0;
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                end
                W_PREP: begin
                    wbeat <= 9'd0;
                end
                W_SEND: begin
                    if (whs) begin
                        if (wbeat == wb - 9'd1) begin
                        end else begin
                            wbeat <= wbeat + 9'd1 ;
                        end
                    end
                end
                W_RESP: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 每段开始置AW待接受，实际AW握手后清除；不要求AW与W同拍到达。
    always @ ( posedge M_AXI_ACLK ) begin : update_aw_pending
        if (! M_AXI_ARESETN) begin
            aw_pending <= 1'd0;
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                end
                W_PREP: begin
                    aw_pending <= 1'b1 ;
                end
                W_SEND: begin
                    if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                        aw_pending <= 1'b0 ;
                    end
                end
                W_RESP: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 每段开始置W待发送，最后一拍实际接受后清除，之后仍需等待AW/B。
    always @ ( posedge M_AXI_ACLK ) begin : update_w_pending
        if (! M_AXI_ARESETN) begin
            w_pending <= 1'd0;
        end else begin
            case (write_curr_st)
                W_IDLE: begin
                end
                W_PREP: begin
                    w_pending <= 1'b1 ;
                end
                W_SEND: begin
                    if (whs) begin
                        if (wbeat == wb - 9'd1) begin
                            w_pending <= 1'b0 ;
                        end
                    end
                end
                W_RESP: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 只在最后B握手或拒绝非法请求时给一次fdma_wdone；W末拍不等于写成功。
    always @(posedge M_AXI_ACLK) begin : update_fdma_wdone
        if (!M_AXI_ARESETN) begin
            fdma_wdone <= 1'b0;
        end else if (write_curr_st == W_IDLE && fdma_wareq &&
                     (fdma_wsize == 0 || (fdma_waddr % AXI_BYTES) != 0)) begin
            fdma_wdone <= 1'b1;
        end else if (write_curr_st == W_RESP && M_AXI_BVALID && M_AXI_BREADY && wleft == wb) begin
            fdma_wdone <= 1'b1;
        end else begin
            fdma_wdone <= 1'b0;
        end
    end


    // 新写请求清上一任务错误；本请求任一B非OKAY后保持fdma_werror直到下一请求。
    always @(posedge M_AXI_ACLK) begin : update_fdma_werror
        if (!M_AXI_ARESETN) begin
            fdma_werror <= 1'b0;
        end else if (write_curr_st == W_IDLE && fdma_wareq) begin
            fdma_werror <= (fdma_wsize == 0 || (fdma_waddr % AXI_BYTES) != 0);
        end else if (write_curr_st == W_RESP && M_AXI_BVALID && M_AXI_BREADY &&
                     (M_AXI_BRESP != 2'b00 || M_AXI_BID != AXI_FIXED_ID)) begin
            fdma_werror <= 1'b1;
        end
    end


    assign fdma_rbusy=(read_curr_st != R_IDLE)                                            ;    // 读请求仍在处理

    assign M_AXI_ARID=AXI_FIXED_ID                                                        ;    // MIG用户域读地址事务ID

    assign M_AXI_ARADDR=ra                                                                ;    // MIG用户域读突发起始字节地址

    assign M_AXI_ARLEN=read_len_minus_one[7:0]                                            ;    // MIG用户域读地址突发拍数减1

    assign M_AXI_ARSIZE=AXI_SIZE                                                          ;    // MIG用户域读地址每拍字节数的log2编码

    assign M_AXI_ARBURST=2'b01                                                            ;    // MIG用户域读地址地址类型，INCR为逐拍递增

    assign M_AXI_ARLOCK=1'b0                                                              ;    // MIG用户域读地址通道lock属性

    assign M_AXI_ARCACHE=4'b0010                                                          ;    // MIG用户域读地址通道cache属性

    assign M_AXI_ARPROT=3'd0                                                              ;    // MIG用户域读地址通道prot属性

    assign M_AXI_ARQOS=4'd0                                                               ;    // MIG用户域读地址通道qos属性

    assign M_AXI_ARVALID=(read_curr_st==R_ADDR)                                           ;    // MIG用户域读地址通道有效，保持到ready接受

    assign M_AXI_RREADY=(read_curr_st==R_DATA) && fdma_rready                             ;    // MIG用户域读数据通道当前可接受

    assign rhs=M_AXI_RVALID && M_AXI_RREADY                                               ;    // AXI R实际接受事件

    assign fdma_rdata=M_AXI_RDATA                                                         ;    // 当前读数据

    assign fdma_rvalid=rhs                                                                ;    // 保留现有读桥的accept语义

    reg           [2:0]                        read_next_st                               ;    // 完整组合次态，默认保持当前态


    // 计算读次态：分段提交AR，收到该段规定的全部R拍后继续或结束。
    always @(*) begin : calculate_read_next_st
        read_next_st = read_curr_st;

        if (! M_AXI_ARESETN) begin
            read_next_st = R_IDLE ;
        end else begin
            case (read_curr_st)
                R_IDLE: begin
                    if (fdma_rareq && fdma_rsize != 0) begin
                        read_next_st = R_PREP ;
                    end
                end
                R_PREP: begin
                    read_next_st = R_ADDR ;
                end
                R_ADDR: begin
                    if (M_AXI_ARREADY) begin
                        read_next_st = R_DATA ;
                    end
                end
                R_DATA: begin
                    if (rhs) begin
                        if (rbeat == rb - 9'd1) begin
                            if (rleft == rb) begin
                                read_next_st = R_IDLE ;
                            end else begin
                                read_next_st = R_PREP ;
                            end
                        end
                    end
                end
                default: begin
                    read_next_st = R_IDLE ;
                end
            endcase
        end
        end


    // AXI时钟沿保存读次态，复位回R_IDLE。
    always @(posedge M_AXI_ACLK) begin : register_read_state
        if (!M_AXI_ARESETN) begin
            read_curr_st <= R_IDLE;
        end else begin
            read_curr_st <= read_next_st;
        end
    end


    // 接受读请求时保存地址；当前读段收齐后增加已读字节数，AR等待期间地址保持。
    always @ ( posedge M_AXI_ACLK ) begin : update_ra
        if (! M_AXI_ARESETN) begin
            ra <= {M_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            case (read_curr_st)
                R_IDLE: begin
                    if (fdma_rareq && fdma_rsize != 0) begin
                        ra <= fdma_raddr ;
                    end
                end
                R_PREP: begin
                end
                R_ADDR: begin
                end
                R_DATA: begin
                    if (rhs) begin
                        if (rbeat == rb - 9'd1) begin
                            if (rleft == rb) begin
                            end else begin
                                ra <= ra + rb * AXI_BYTES ;
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
            rleft <= 16'd0;
        end else begin
            case (read_curr_st)
                R_IDLE: begin
                    if (fdma_rareq && fdma_rsize != 0) begin
                        rleft <= fdma_rsize ;
                    end
                end
                R_PREP: begin
                end
                R_ADDR: begin
                end
                R_DATA: begin
                    if (rhs) begin
                        if (rbeat == rb - 9'd1) begin
                            if (rleft == rb) begin
                            end else begin
                                rleft <= rleft - rb ;
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
            rb <= 9'd0;
        end else begin
            case (read_curr_st)
                R_IDLE: begin
                end
                R_PREP: begin
                    rb <= burst_beats ( ra , rleft ) ;
                end
                R_ADDR: begin
                end
                R_DATA: begin
                end
                default: begin
                end
            endcase
        end
    end


    // 只在R有效与ready同拍成立时推进段内读位置，不把等待周期计成数据拍。
    always @ ( posedge M_AXI_ACLK ) begin : update_rbeat
        if (! M_AXI_ARESETN) begin
            rbeat <= 9'd0;
        end else begin
            case (read_curr_st)
                R_IDLE: begin
                end
                R_PREP: begin
                    rbeat <= 9'd0;
                end
                R_ADDR: begin
                end
                R_DATA: begin
                    if (rhs) begin
                        if (rbeat == rb - 9'd1) begin
                        end else begin
                            rbeat <= rbeat + 9'd1 ;
                        end
                    end
                end
                default: begin
                end
            endcase
        end
    end

endmodule
