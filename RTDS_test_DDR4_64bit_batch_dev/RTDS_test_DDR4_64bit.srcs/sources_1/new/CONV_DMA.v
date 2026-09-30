`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/21 10:31:02
// Design Name:
// Module Name: CONV_DMA
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module CONV_DMA #
	(
		parameter  integer		M_AXI_ID_WIDTH		 = 1	,
		parameter  integer		M_AXI_ID			 = 0	,
		parameter  integer		M_AXI_ADDR_WIDTH	= 64	,
		parameter  integer		M_AXI_DATA_WIDTH	= 64
	)
	(
    input wire [M_AXI_DATA_WIDTH/8-1:0] fdma_wstrb, // 与W数据同步保持，末尾单字仅低4Byte有效
    output reg fdma_wdone, // 全部写响应已返回的单周期事件
    output reg fdma_werror, // 本次事务响应/地址错误，与done配对
	input	wire	[M_AXI_ADDR_WIDTH-1 : 0]		fdma_waddr			,
	input											fdma_wareq			,
	input	wire	[15 : 0]						fdma_wsize			,
	output											fdma_wbusy			,

	input	wire	[M_AXI_DATA_WIDTH-1 :0]			fdma_wdata			,
	output	wire									fdma_wvalid			,
	input	wire									fdma_wready			,

	input	wire	[M_AXI_ADDR_WIDTH-1 : 0]		fdma_raddr			,
	input											fdma_rareq			,
	input	wire	[15 : 0]						fdma_rsize			,
	output											fdma_rbusy			,

	output	wire	[M_AXI_DATA_WIDTH-1 :0]			fdma_rdata			,
	output	wire									fdma_rvalid			,
	input	wire									fdma_rready			,

	input	wire									M_AXI_ACLK			,
	input	wire									M_AXI_ARESETN		,
	output	wire	[M_AXI_ID_WIDTH-1 : 0]			M_AXI_AWID			,//写地址ID，用来标志一组写信号
	output	wire	[M_AXI_ADDR_WIDTH-1 : 0]		M_AXI_AWADDR		,//写地址，给出一次写突发传输的写地址
	output	wire	[7 : 0]							M_AXI_AWLEN			,//突发长度，给出突发传输的次数
	output	wire	[2 : 0]							M_AXI_AWSIZE		,//突发大小，给出每次突发传输的字节数
	output	wire	[1 : 0]							M_AXI_AWBURST		,//突发类型
	output	wire									M_AXI_AWLOCK		,//总线锁信号，可提供操作的原子性
	output	wire	[3 : 0]							M_AXI_AWCACHE		,//内存类型，表明一次传输是怎样通过系统的
	output	wire	[2 : 0]							M_AXI_AWPROT		,//保护类型，表明一次传输的特权级及安全等级
	output	wire	[3 : 0]							M_AXI_AWQOS			,//质量服务QoS
	output	wire									M_AXI_AWVALID		,//有效信号，表明此通道的地址控制信号有效
	input	wire									M_AXI_AWREADY		,//表明“从”可以接收地址和对应的控制信号
	output	wire	[M_AXI_ID_WIDTH-1 : 0]			M_AXI_WID			,//写响应ID tag
	output	wire	[M_AXI_DATA_WIDTH-1 : 0]		M_AXI_WDATA			,//写数据
	output	wire	[M_AXI_DATA_WIDTH/8-1 : 0]		M_AXI_WSTRB			,//写数据有效的字节线，用来表明哪8bits数据是有效的
	output	wire									M_AXI_WLAST			,//表明此次传输是最后一个突发传输
	output	wire									M_AXI_WVALID		,//写有效，表明此次写有效
	input	wire									M_AXI_WREADY		,//表明从机可以接收写数据
	input	wire	[M_AXI_ID_WIDTH-1 : 0]			M_AXI_BID			,//写响应ID tag
	input	wire	[1 : 0]							M_AXI_BRESP			,//写响应，表明写传输的状态
	input	wire									M_AXI_BVALID		,//写响应有效
	output	wire									M_AXI_BREADY		, //表明主机能够接收写响应
	output	wire	[M_AXI_ID_WIDTH-1 : 0]			M_AXI_ARID			,

	output	wire	[M_AXI_ADDR_WIDTH-1 : 0]		M_AXI_ARADDR		,
	output	wire	[7 : 0]							M_AXI_ARLEN			,
	output	wire	[2 : 0]							M_AXI_ARSIZE		,
	output	wire	[1 : 0]							M_AXI_ARBURST		,
	output	wire									M_AXI_ARLOCK		,
	output	wire	[3 : 0]							M_AXI_ARCACHE		,
	output	wire	[2 : 0]							M_AXI_ARPROT		,
	output	wire	[3 : 0]							M_AXI_ARQOS			,
	output	wire									M_AXI_ARVALID		,
	input	wire									M_AXI_ARREADY		,
	input	wire	[M_AXI_ID_WIDTH-1 : 0]			M_AXI_RID			,
	input	wire	[M_AXI_DATA_WIDTH-1 : 0]		M_AXI_RDATA			,
	input	wire	[1 : 0]							M_AXI_RRESP			,
	input	wire									M_AXI_RLAST			,
	input	wire									M_AXI_RVALID		,
	output	wire									M_AXI_RREADY

		);
    localparam integer AXI_BYTES = M_AXI_DATA_WIDTH/8;
    localparam integer SIZE_BITS = $clog2(AXI_BYTES);
    localparam [2:0] W_IDLE=3'd0,W_PREP=3'd1,W_SEND=3'd2,W_RESP=3'd3;
    localparam [2:0] R_IDLE=3'd0,R_PREP=3'd1,R_ADDR=3'd2,R_DATA=3'd3;
    reg [2:0] write_curr_st,read_curr_st;
    reg [M_AXI_ADDR_WIDTH-1:0] wa,ra;
    reg [15:0] wleft,rleft; // 整个FDMA请求尚未完成的beat数
    reg [8:0] wb,rb,wbeat,rbeat; // 当前AXI burst长度和位置
    reg aw_pending,w_pending;
    wire whs,rhs;
    function [8:0] burst_beats;
        input [M_AXI_ADDR_WIDTH-1:0] address;
        input [15:0] remaining;
        reg [15:0] available;
        begin
            available=(16'd4096-{4'd0,address[11:0]})/AXI_BYTES;
            if (available > 16'd256)
                available=16'd256;
            if (remaining < available)
                available=remaining;
            burst_beats=available[8:0];
        end
    endfunction

    wire [8:0] write_len_minus_one;
    wire [8:0] read_len_minus_one;
    localparam [M_AXI_ID_WIDTH-1:0] AXI_FIXED_ID = M_AXI_ID[M_AXI_ID_WIDTH-1:0];
    localparam [2:0] AXI_SIZE = SIZE_BITS[2:0];
    // 生成当前事务计数/长度字段，计数推进仍由实际握手或提交事件决定。
    assign write_len_minus_one = wb - 9'd1;
    // 生成当前事务计数/长度字段，计数推进仍由实际握手或提交事件决定。
    assign read_len_minus_one = rb - 9'd1;
    // 向请求方指示当前事务占用状态，避免重复启动。
    assign fdma_wbusy=(write_curr_st != W_IDLE);
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWID=AXI_FIXED_ID;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_WID=AXI_FIXED_ID;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWADDR=wa;
    // AXI长度编码为突发拍数减一；跨4KiB拆分在地址状态机完成。
    assign M_AXI_AWLEN=write_len_minus_one[7:0];
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWSIZE=AXI_SIZE;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWBURST=2'b01;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWLOCK=1'b0;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWCACHE=4'b0010;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWPROT=3'd0;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_AWQOS=4'd0;
    // 地址未握手时持续提交AW，不依赖W通道先完成。
    assign M_AXI_AWVALID=(write_curr_st == W_SEND) && aw_pending;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_WDATA=fdma_wdata;
    // AXI逐字节写使能来自上行压缩器，避免尾拍高四字节被覆盖。
    assign M_AXI_WSTRB=fdma_wstrb;
    // WLAST不依赖WREADY，反压期间与数据一同保持。
    assign M_AXI_WLAST=(wbeat == wb-9'd1);
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign M_AXI_WVALID=(write_curr_st == W_SEND) && w_pending && fdma_wready;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign whs=M_AXI_WVALID && M_AXI_WREADY;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign fdma_wvalid=whs; // 历史命名：valid输出实际是数据接受脉冲
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign M_AXI_BREADY=(write_curr_st == W_RESP);

        // write_curr_st：写事务Moore状态；地址/数据可独立握手，只有最终B响应才离开忙状态。
    reg [2:0] write_next_st; // 完整组合次态，默认保持当前态
    // 两段式状态机：输出由当前态形成，只有实际握手才推进；非法态回空闲。

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

    always @(posedge M_AXI_ACLK) begin : register_write_state
        if (!M_AXI_ARESETN) begin
            write_curr_st <= W_IDLE;
        end else begin
            write_curr_st <= write_next_st;
        end
    end

    // wa：当前写突发地址；请求接受时冻结，每个B响应后推进，AW反压期间保持。

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

    // wleft：整次请求尚未收到写响应的拍数；每个B响应扣除当前突发长度。

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

    // wb：当前写突发拍数，范围1到256，并受4KiB剩余空间限制。

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

    // wbeat：当前突发已接受写拍的位置；末拍保持到真实W握手。

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

    // aw_pending：当前突发AW尚未被接受；AW与W可以任意先后完成。

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

    // w_pending：当前突发仍有W拍；末拍接受后撤销，随后等待AW与B。

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

    // fdma_wdone：仅最终 B 握手或非法请求完成时产生一拍；末个 W 拍不是完成条件。

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

    // fdma_werror：整个 FDMA 请求内任一 B 错误均保留，下一请求开始清零。

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


    // 向请求方指示当前事务占用状态，避免重复启动。
    assign fdma_rbusy=(read_curr_st != R_IDLE);
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign M_AXI_ARID=AXI_FIXED_ID;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARADDR=ra;
    // AXI长度编码为读突发拍数减一；保持与当前请求分段一致。
    assign M_AXI_ARLEN=read_len_minus_one[7:0];
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARSIZE=AXI_SIZE;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARBURST=2'b01;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARLOCK=1'b0;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARCACHE=4'b0010;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARPROT=3'd0;
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign M_AXI_ARQOS=4'd0;
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign M_AXI_ARVALID=(read_curr_st==R_ADDR);
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign M_AXI_RREADY=(read_curr_st==R_DATA) && fdma_rready;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign rhs=M_AXI_RVALID && M_AXI_RREADY;
    // 连接本级与上下游同一事务字段；保持原有时序和位宽语义。
    assign fdma_rdata=M_AXI_RDATA;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign fdma_rvalid=rhs; // 保留现有读桥的accept语义
        // read_curr_st：读事务Moore状态；按4KiB/256拍切分，收到当前突发全部拍后才推进地址。
    reg [2:0] read_next_st; // 完整组合次态，默认保持当前态
    // 两段式状态机：输出由当前态形成，只有实际握手才推进；非法态回空闲。

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

    always @(posedge M_AXI_ACLK) begin : register_read_state
        if (!M_AXI_ARESETN) begin
            read_curr_st <= R_IDLE;
        end else begin
            read_curr_st <= read_next_st;
        end
    end

    // ra：当前读突发地址；AR握手期间保持，本突发数据接收完才推进。

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

    // rleft：整次请求尚未完成的读拍数；当前突发最后一个实际接受拍后扣减。

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

    // rb：当前读突发拍数，使用与写方向相同的4KiB及最大突发规则。

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

    // rbeat：当前突发读拍位置；只统计真实R握手，不统计等待周期。

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
