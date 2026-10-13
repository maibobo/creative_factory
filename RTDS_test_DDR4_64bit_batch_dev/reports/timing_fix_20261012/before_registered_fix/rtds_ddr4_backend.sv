`timescale 1ns/1ps

`ifdef DDR4_REAL
  `ifdef DDR4_SIM_RAM
    `define RTDS_DDR_MODE_CONFLICT
  `endif
`endif
`ifndef DDR4_REAL
  `ifndef DDR4_SIM_RAM
    `define DDR4_SIM_RAM
  `endif
`endif

// DDR4 后端：DDR4_REAL（真实MIG）/ DDR4_SIM_RAM（行为RAM）二选一；
// 二者都未定义时默认 SIM_RAM；同时定义报错。统一提供超时与粘滞错误状态。
module rtds_ddr4_backend #(
    parameter integer AXI_ADDR_WIDTH = 32,
    parameter integer AXI_DATA_WIDTH = 64,
    parameter integer AXI_ID_WIDTH   = 5,
    parameter integer TIMEOUT_CYCLES = 65535
) (
    input  wire                          s_axi_aclk,    // AXI 从端时钟（控制/DDR 域）
    input  wire                          s_axi_aresetn,    // AXI 从端低有效复位
    input  wire                          ddr_sys_clk_i,    // MIG 系统时钟输入（仅 DDR4_REAL 使用）
    input  wire                          ddr_sys_rst_n,    // MIG 系统复位低有效（仅 DDR4_REAL 使用）
    input  wire                          clear_status,    // 软件写1清除两个粘滞错误状态
    input  wire [AXI_ID_WIDTH-1:0]       s_axi_awid,    // 写地址通道 ID
    input  wire [AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,    // 写地址通道起始字节地址
    input  wire [7:0]                    s_axi_awlen,    // 写突发拍数减一
    input  wire [2:0]                    s_axi_awsize,    // 写每拍字节数（3=8Byte/64bit）
    input  wire [1:0]                    s_axi_awburst,    // 写突发类型（1=INCR）
    input  wire [0:0]                    s_axi_awlock,    // 写锁定属性
    input  wire [3:0]                    s_axi_awcache,    // 写缓存属性
    input  wire [2:0]                    s_axi_awprot,    // 写保护属性
    input  wire [3:0]                    s_axi_awregion,    // 写 region（本设计未使用）
    input  wire [3:0]                    s_axi_awqos,    // 写 QoS（本设计未使用）
    input  wire                          s_axi_awvalid,    // 写地址有效
    output wire                          s_axi_awready,    // 写地址就绪
    input  wire [AXI_DATA_WIDTH-1:0]     s_axi_wdata,    // 写数据
    input  wire [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,    // 写字节使能
    input  wire                          s_axi_wlast,    // 写末拍标志
    input  wire                          s_axi_wvalid,    // 写数据有效
    output wire                          s_axi_wready,    // 写数据就绪
    output wire [AXI_ID_WIDTH-1:0]       s_axi_bid,    // 写响应 ID（回显 AWID）
    output wire [1:0]                    s_axi_bresp,    // 写响应码（00=OKAY）
    output wire                          s_axi_bvalid,    // 写响应有效
    input  wire                          s_axi_bready,    // 写响应就绪
    input  wire [AXI_ID_WIDTH-1:0]       s_axi_arid,    // 读地址通道 ID
    input  wire [AXI_ADDR_WIDTH-1:0]     s_axi_araddr,    // 读地址通道起始字节地址
    input  wire [7:0]                    s_axi_arlen,    // 读突发拍数减一
    input  wire [2:0]                    s_axi_arsize,    // 读每拍字节数
    input  wire [1:0]                    s_axi_arburst,    // 读突发类型
    input  wire [0:0]                    s_axi_arlock,    // 读锁定属性
    input  wire [3:0]                    s_axi_arcache,    // 读缓存属性
    input  wire [2:0]                    s_axi_arprot,    // 读保护属性
    input  wire [3:0]                    s_axi_arregion,    // 读 region（本设计未使用）
    input  wire [3:0]                    s_axi_arqos,    // 读 QoS（本设计未使用）
    input  wire                          s_axi_arvalid,    // 读地址有效
    output wire                          s_axi_arready,    // 读地址就绪
    output wire [AXI_ID_WIDTH-1:0]       s_axi_rid,    // 读响应 ID（回显 ARID）
    output wire [AXI_DATA_WIDTH-1:0]     s_axi_rdata,    // 读数据
    output wire [1:0]                    s_axi_rresp,    // 读响应码（00=OKAY）
    output wire                          s_axi_rlast,    // 读末拍标志
    output wire                          s_axi_rvalid,    // 读数据有效
    input  wire                          s_axi_rready,    // 读就绪
    output wire                          ddr_ready,    // 后端可接受事务状态（上电校准/模型就绪）
    output wire                          init_calib_complete,    // MIG 校准完成（真实模式）/模型就绪（仿真模式）
    output reg                           ddr_axi_response_error_sticky,    // B/R 响应非 OKAY 粘滞标志（clear_status 清除）
    output reg                           ddr_axi_timeout_sticky,    // 事务超时粘滞标志（clear_status 清除）
    output wire                          c0_ddr4_act_n,    // DDR4 行激活（低有效）
    output wire [16:0]                   c0_ddr4_adr,    // DDR4 地址（含行列复用）
    output wire [1:0]                    c0_ddr4_ba,    // DDR4 Bank 地址
    output wire [0:0]                    c0_ddr4_bg,    // DDR4 Bank 组地址
    output wire [0:0]                    c0_ddr4_cke,    // DDR4 CKE
    output wire [0:0]                    c0_ddr4_odt,    // DDR4 ODT
    output wire [0:0]                    c0_ddr4_cs_n,    // DDR4 片选（低有效）
    output wire [0:0]                    c0_ddr4_ck_t,    // DDR4 差分时钟正端
    output wire [0:0]                    c0_ddr4_ck_c,    // DDR4 差分时钟负端
    output wire                          c0_ddr4_reset_n,    // DDR4 复位（低有效）
    inout  wire [7:0]                    c0_ddr4_dm_dbi_n,    // DDR4 数据掩码/DBI（双向）
    inout  wire [63:0]                   c0_ddr4_dq,    // DDR4 数据总线（双向）
    inout  wire [7:0]                    c0_ddr4_dqs_c,    // DDR4 选通负端（双向）
    inout  wire [7:0]                    c0_ddr4_dqs_t    // DDR4 选通正端（双向）
);
`ifdef RTDS_DDR_MODE_CONFLICT
    initial $error("DDR4_REAL and DDR4_SIM_RAM are mutually exclusive");
`endif

    // 修改记录 2026-10-11：TC-F11的DDR中断恢复。每个方向最多接受一个AXI突发，
    // 保存已接受事务的ID和剩余拍数；存储侧复位后补齐SLVERR，避免上游永久等待。
    // 已经展示给上游的R/B响应在反压时保持；新事务等待旧错误响应结束。
    // 不复位CONV_DMA、INFO_EXCH和块队列，不把错误完成记成成功写入。
    wire storage_ready;   // 2026-10-11：物理后端校准和复位同步完成，与业务恢复完成分开
    wire mem_awready;   // 2026-10-11：存储侧写地址接收许可
    wire mem_wready;   // 2026-10-11：存储侧写数据接收许可
    wire mem_bvalid;   // 2026-10-11：存储侧写响应有效
    wire [AXI_ID_WIDTH-1:0] mem_bid;   // 2026-10-11：存储侧写响应ID
    wire [1:0] mem_bresp;   // 2026-10-11：存储侧写响应码
    wire mem_arready;   // 2026-10-11：存储侧读地址接收许可
    wire mem_rvalid;   // 2026-10-11：存储侧读响应有效
    wire [AXI_ID_WIDTH-1:0] mem_rid;   // 2026-10-11：存储侧读响应ID
    wire [AXI_DATA_WIDTH-1:0] mem_rdata;   // 2026-10-11：存储侧读数据
    wire [1:0] mem_rresp;   // 2026-10-11：存储侧读响应码
    wire mem_rlast;   // 2026-10-11：存储侧读末拍标志
    reg recovery_read_pending;   // 2026-10-11：已接受AR至上游接受最后R拍期间保持
    reg recovery_write_pending;   // 2026-10-11：已接受AW至上游接受B期间保持
    reg recovery_read_abort;   // 2026-10-11：此读突发经历存储不可用，剩余拍返回错误
    reg recovery_write_abort;   // 2026-10-11：此写突发经历存储不可用，剩余数据丢弃并返回错误
    reg [8:0] recovery_read_left;   // 2026-10-11：尚未装入上游响应寄存器的读拍数，支持256拍
    reg [8:0] recovery_write_left;   // 2026-10-11：尚未从上游接受的写拍数，支持256拍
    reg [AXI_ID_WIDTH-1:0] recovery_read_id;   // 2026-10-11：接受AR时保存ID
    reg [AXI_ID_WIDTH-1:0] recovery_write_id;   // 2026-10-11：接受AW时保存ID
    reg recovery_rvalid;   // 2026-10-11：上游读响应寄存器有效标志
    reg [AXI_DATA_WIDTH-1:0] recovery_rdata;   // 2026-10-11：反压期间保持的读数据
    reg [AXI_ID_WIDTH-1:0] recovery_rid;   // 2026-10-11：反压期间保持的读响应ID
    reg [1:0] recovery_rresp;   // 2026-10-11：反压期间保持的读响应码
    reg recovery_rlast;   // 2026-10-11：反压期间保持的读末拍标志
    reg recovery_bvalid;   // 2026-10-11：上游写响应寄存器有效标志
    reg [AXI_ID_WIDTH-1:0] recovery_bid;   // 2026-10-11：反压期间保持的写响应ID
    reg [1:0] recovery_bresp;   // 2026-10-11：反压期间保持的写响应码
    wire recovery_read_fault = recovery_read_abort || !storage_ready;   // 2026-10-11：已中断的读突发不能在校准恢复后继续使用旧数据
    wire recovery_write_fault = recovery_write_abort || !storage_ready;   // 2026-10-11：已中断的写突发不能在校准恢复后补写成成功
    wire recovery_rslot = !recovery_rvalid || s_axi_rready;   // 2026-10-11：读响应寄存器可接收下一拍
    wire recovery_rload = recovery_read_pending && (recovery_read_left != 0) && recovery_rslot && (recovery_read_fault || mem_rvalid);   // 2026-10-11：装入一拍真实或错误响应
    wire recovery_bload = recovery_write_pending && (recovery_write_left == 0) && !recovery_bvalid && (recovery_write_fault || mem_bvalid);   // 2026-10-11：收齐全部W后才产生一次B
    wire mem_awvalid = s_axi_aresetn && s_axi_awvalid && ddr_ready && !recovery_write_pending;   // 2026-10-11：一次只向存储侧提交一个写突发
    wire mem_arvalid = s_axi_aresetn && s_axi_arvalid && ddr_ready && !recovery_read_pending;   // 2026-10-11：一次只向存储侧提交一个读突发
    wire mem_wvalid = s_axi_aresetn && s_axi_wvalid && recovery_write_pending && (recovery_write_left != 0) && !recovery_write_fault;   // 2026-10-11：仅转发未中断的已接受AW对应数据
    wire mem_bready = s_axi_aresetn && recovery_write_pending && (recovery_write_left == 0) && !recovery_bvalid && !recovery_write_fault;   // 2026-10-11：真实写响应装入独立保持寄存器
    wire mem_rready = s_axi_aresetn && recovery_read_pending && (recovery_read_left != 0) && recovery_rslot && !recovery_read_fault;   // 2026-10-11：真实读响应装入独立保持寄存器
    assign ddr_ready = storage_ready && !recovery_read_abort && !recovery_write_abort;   // 2026-10-11：错误事务尚未处理完毕时禁止启动新业务
    assign s_axi_awready = s_axi_aresetn && ddr_ready && !recovery_write_pending && mem_awready;   // 2026-10-11：AW接收与实际存储侧接收同拍
    assign s_axi_arready = s_axi_aresetn && ddr_ready && !recovery_read_pending && mem_arready;   // 2026-10-11：AR接收与实际存储侧接收同拍
    assign s_axi_wready = s_axi_aresetn && recovery_write_pending && (recovery_write_left != 0) && (recovery_write_fault || mem_wready);   // 2026-10-11：中断后仍收完原突发W拍，但不再写存储
    assign s_axi_rvalid = recovery_rvalid;   // 2026-10-11：R响应有效在反压期间保持
    assign s_axi_rdata = recovery_rdata;   // 2026-10-11：R响应数据在反压期间保持
    assign s_axi_rid = recovery_rid;   // 2026-10-11：R响应ID在反压期间保持
    assign s_axi_rresp = recovery_rresp;   // 2026-10-11：R响应码在反压期间保持
    assign s_axi_rlast = recovery_rlast;   // 2026-10-11：R末拍标志在反压期间保持
    assign s_axi_bvalid = recovery_bvalid;   // 2026-10-11：B响应有效在反压期间保持
    assign s_axi_bid = recovery_bid;   // 2026-10-11：B响应ID在反压期间保持
    assign s_axi_bresp = recovery_bresp;   // 2026-10-11：B响应码在反压期间保持

    always @(posedge s_axi_aclk) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
        if (!s_axi_aresetn) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_read_pending <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_read_abort <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_read_left <= 9'd0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_read_id <= {AXI_ID_WIDTH{1'b0}};   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_rvalid <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_rdata <= {AXI_DATA_WIDTH{1'b0}};   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_rid <= {AXI_ID_WIDTH{1'b0}};   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_rresp <= 2'b00;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_rlast <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
        end else begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (s_axi_arvalid && s_axi_arready) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_read_pending <= 1'b1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_read_left <= {1'b0,s_axi_arlen} + 9'd1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_read_id <= s_axi_arid;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (recovery_read_pending && !storage_ready)   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_read_abort <= 1'b1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (recovery_rvalid && s_axi_rready) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_rvalid <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                if (recovery_rlast) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                    recovery_read_pending <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                    recovery_read_abort <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (recovery_rload) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_rvalid <= 1'b1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_rdata <= recovery_read_fault ? {AXI_DATA_WIDTH{1'b0}} : mem_rdata;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_rid <= recovery_read_fault ? recovery_read_id : mem_rid;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_rresp <= recovery_read_fault ? 2'b10 : mem_rresp;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_rlast <= (recovery_read_left == 9'd1);   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_read_left <= recovery_read_left - 9'd1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
        end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
    end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应

    always @(posedge s_axi_aclk) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
        if (!s_axi_aresetn) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_write_pending <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_write_abort <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_write_left <= 9'd0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_write_id <= {AXI_ID_WIDTH{1'b0}};   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_bvalid <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_bid <= {AXI_ID_WIDTH{1'b0}};   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            recovery_bresp <= 2'b00;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
        end else begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (s_axi_awvalid && s_axi_awready) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_pending <= 1'b1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_left <= {1'b0,s_axi_awlen} + 9'd1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_id <= s_axi_awid;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (recovery_write_pending && !storage_ready)   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_abort <= 1'b1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (s_axi_wvalid && s_axi_wready)   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_left <= recovery_write_left - 9'd1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (recovery_bvalid && s_axi_bready) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_bvalid <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_pending <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_write_abort <= 1'b0;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            if (recovery_bload) begin   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_bvalid <= 1'b1;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_bid <= recovery_write_fault ? recovery_write_id : mem_bid;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
                recovery_bresp <= recovery_write_fault ? 2'b10 : mem_bresp;   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
            end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
        end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应
    end   // 2026-10-11：维护已接受AXI事务，存储中断后按原长度和ID完成错误响应

    wire aw_hs = s_axi_awvalid && s_axi_awready;    // AW 通道握手成功一拍
    wire w_hs  = s_axi_wvalid  && s_axi_wready;    // W 通道握手成功一拍
    wire b_hs  = s_axi_bvalid  && s_axi_bready;    // B 通道握手成功一拍
    wire ar_hs = s_axi_arvalid && s_axi_arready;    // AR 通道握手成功一拍
    wire r_hs  = s_axi_rvalid  && s_axi_rready;    // R 通道握手成功一拍
    reg [7:0] outstanding_writes;    // 在途写事务计数（AW接受-B响应）
    reg [7:0] outstanding_reads;    // 在途读事务计数（AR接受-RLAST返回）
    reg [31:0] timeout_count;    // 看门狗空闲计数器
    reg ready_seen;    // 曾观察到 ddr_ready 的历史标志
    wire any_pending = (outstanding_writes != 0) || (outstanding_reads != 0);    // 存在未完成读写事务
    wire any_progress = aw_hs || w_hs || b_hs || ar_hs || r_hs;    // 五通道任一握手即有协议进展

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            outstanding_writes <= 0;
            outstanding_reads  <= 0;
            timeout_count      <= 0;
            ready_seen         <= 1'b0;
            ddr_axi_response_error_sticky <= 1'b0;
            ddr_axi_timeout_sticky        <= 1'b0;
        end else begin
            case ({aw_hs,b_hs})
                2'b10: outstanding_writes <= outstanding_writes + 1'b1;
                2'b01: if (outstanding_writes != 0)
                    outstanding_writes <= outstanding_writes - 1'b1;
                default: outstanding_writes <= outstanding_writes;
            endcase
            case ({ar_hs,(r_hs && s_axi_rlast)})
                2'b10: outstanding_reads <= outstanding_reads + 1'b1;
                2'b01: if (outstanding_reads != 0)
                    outstanding_reads <= outstanding_reads - 1'b1;
                default: outstanding_reads <= outstanding_reads;
            endcase

            if (ddr_ready)
                ready_seen <= 1'b1;

            if (clear_status) begin
                ddr_axi_response_error_sticky <= 1'b0;
                ddr_axi_timeout_sticky        <= 1'b0;
                timeout_count                 <= 0;
            end else begin
                if ((b_hs && (s_axi_bresp != 2'b00)) ||
                    (r_hs && (s_axi_rresp != 2'b00)))
                    ddr_axi_response_error_sticky <= 1'b1;
                if (ready_seen && !ddr_ready)
                    ddr_axi_timeout_sticky <= 1'b1;
                if (!any_pending || any_progress) begin
                    timeout_count <= 0;
                end else if (timeout_count >= TIMEOUT_CYCLES-1) begin
                    ddr_axi_timeout_sticky <= 1'b1;
                end else begin
                    timeout_count <= timeout_count + 1'b1;
                end
            end
        end
    end

`ifdef DDR4_SIM_RAM
    reg [1:0] sim_ready_pipe;    // 仿真模式就绪两拍同步管线

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || !ddr_sys_rst_n)
            sim_ready_pipe <= 2'b00;
        else
            sim_ready_pipe <= {sim_ready_pipe[0],1'b1};
    end
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign storage_ready = sim_ready_pipe[1];   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign init_calib_complete = sim_ready_pipe[1];

    wire ram_awready, ram_wready, ram_bvalid, ram_arready, ram_rlast, ram_rvalid;    // RAM 模型侧五通道握手线
    wire [AXI_ID_WIDTH-1:0] ram_bid, ram_rid;    // RAM 模型侧响应 ID
    wire [1:0] ram_bresp, ram_rresp;    // RAM 模型侧响应码
    wire [AXI_DATA_WIDTH-1:0] ram_rdata;    // RAM 模型侧读数据
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_awready = storage_ready && ram_awready;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_wready  = storage_ready && ram_wready;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_bvalid  = ram_bvalid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_bid     = ram_bid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_bresp   = ram_bresp;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_arready = storage_ready && ram_arready;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_rid     = ram_rid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign mem_rdata   = ram_rdata;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_rresp   = ram_rresp;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign mem_rlast   = ram_rlast;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_rvalid  = ram_rvalid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务

    rtds_axi_ram_model #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH), .DATA_WIDTH(AXI_DATA_WIDTH),
        .ID_WIDTH(AXI_ID_WIDTH), .MEM_BYTES(4194304)
    ) u_sim_ram (
        .aclk(s_axi_aclk), .aresetn(s_axi_aresetn && storage_ready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen), .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst), .s_axi_awvalid(mem_awvalid),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_awready(ram_awready), .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(mem_wvalid), .s_axi_wready(ram_wready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_bid(ram_bid), .s_axi_bresp(ram_bresp), .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(mem_bready), .s_axi_arid(s_axi_arid),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize), .s_axi_arburst(s_axi_arburst),
        .s_axi_arvalid(mem_arvalid), .s_axi_arready(ram_arready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_rid(ram_rid), .s_axi_rdata(ram_rdata), .s_axi_rresp(ram_rresp),
        .s_axi_rlast(ram_rlast), .s_axi_rvalid(ram_rvalid), .s_axi_rready(mem_rready)   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    );

    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_act_n = 1'b1;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_adr = 17'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_ba = 2'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_bg = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_cke = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_odt = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_cs_n = 1'd1;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_ck_t = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_ck_c = 1'd0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_reset_n = 1'b0;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dm_dbi_n = 8'hzz;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dq = 64'hzzzz_zzzz_zzzz_zzzz;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dqs_c = 8'hzz;
    // 行为RAM配置下不驱动真实DDR存储事务；固定电平/高阻隔离物理管脚。
    assign c0_ddr4_dqs_t = 8'hzz;
`else
    wire ui_clk;    // MIG ui_clk（约300MHz）
    wire ui_clk_sync_rst;    // MIG 时钟域复位请求（高有效）
    wire mig_calib_complete;    // MIG 校准完成标志
    reg [1:0] ui_reset_pipe;    // ui_clk 域复位释放管线
    // ui_axi_aresetn 来自 MIG 300MHz 用户时钟域。该两级触发器只承担单比特
    // 电平同步；禁止在第一级结果上承载业务含义或组合逻辑。
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] ready_sync;
    wire ui_axi_aresetn = ui_reset_pipe[1];    // 同步到控制域的 MIG 侧复位（低有效）
    // 修改记录 2026-10-11：为转换器两侧和MIG AXI接口建立共同复位范围。
    // 任一主机复位、DDR系统复位或UI不可用均立即复位；每侧运行16拍后释放。
    // 业务恢复计数留在接口外，不随存储侧复位丢失，继续向上游补齐错误响应。
    // 修改记录 2026-10-12：两侧16级管线异步进入复位、在各自时钟域同步释放；释放确认另经两级同步。
    // 修改点 2026-10-12：rtds_ddr4_recovery_cdc.xdc只排除本段管线的异步CLR和就绪首级D入口。
    // 修改点 2026-10-12：同步级之间的Q到D及MIG业务路径仍检查；事务恢复和16拍释放行为保持原样。
    wire converter_reset_n = s_axi_aresetn && ddr_sys_rst_n && ui_axi_aresetn;   // 2026-10-11：两个AXI时钟域共用的异步复位条件
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [15:0] converter_s_reset_pipe;   // 2026-10-11：业务时钟域复位释放管线
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [15:0] converter_m_reset_pipe;   // 2026-10-11：MIG时钟域复位释放管线
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] converter_ready_sync;   // 2026-10-11：MIG侧复位释放同步回业务域
    always @(posedge s_axi_aclk or negedge converter_reset_n) begin   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
        if (!converter_reset_n)   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
            converter_s_reset_pipe <= 16'd0;   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
        else   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
            converter_s_reset_pipe <= {converter_s_reset_pipe[14:0],1'b1};   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
    end   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
    always @(posedge ui_clk or negedge converter_reset_n) begin   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
        if (!converter_reset_n)   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
            converter_m_reset_pipe <= 16'd0;   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
        else   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
            converter_m_reset_pipe <= {converter_m_reset_pipe[14:0],1'b1};   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
    end   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
    always @(posedge s_axi_aclk or negedge converter_reset_n) begin   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
        if (!converter_reset_n)   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
            converter_ready_sync <= 2'b00;   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
        else   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
            converter_ready_sync <= {converter_ready_sync[0],converter_m_reset_pipe[15]};   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放
    end   // 2026-10-11：两侧AXI接口同时进入复位，各自在本时钟域延迟释放

    always @(posedge ui_clk) begin
        if (ui_clk_sync_rst || !mig_calib_complete)
            ui_reset_pipe <= 2'b00;
        else
            ui_reset_pipe <= {ui_reset_pipe[0],1'b1};
    end

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            ready_sync <= 2'b00;
        else
            ready_sync <= {ready_sync[0],ui_axi_aresetn};
    end
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign storage_ready = ready_sync[1] && converter_s_reset_pipe[15] && converter_ready_sync[1];   // 2026-10-11：校准和转换器两侧复位释放均完成后才允许访问
    // 软件可见的校准状态必须使用控制域同步结果，避免把 MIG 原始状态直接送入
    // 2026-10-11：校准状态单独保留；ddr_ready还要求接口复位及旧错误事务处理完成。
    assign init_calib_complete = ready_sync[1];

    wire cc_s_awready, cc_s_wready, cc_s_bvalid, cc_s_arready, cc_s_rlast, cc_s_rvalid;    // 时钟转换器从侧五通道握手线
    wire [AXI_ID_WIDTH-1:0] cc_s_bid, cc_s_rid;    // 时钟转换器从侧响应 ID
    wire [1:0] cc_s_bresp, cc_s_rresp;    // 时钟转换器从侧响应码
    wire [AXI_DATA_WIDTH-1:0] cc_s_rdata;    // 时钟转换器从侧读数据
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_awready = storage_ready && cc_s_awready;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_wready  = storage_ready && cc_s_wready;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_bid     = cc_s_bid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_bresp   = cc_s_bresp;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_bvalid  = cc_s_bvalid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_arready = storage_ready && cc_s_arready;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_rid     = cc_s_rid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign mem_rdata   = cc_s_rdata;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // 保留AXI响应码与事务标识，供上层关联完成状态。
    assign mem_rresp   = cc_s_rresp;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道字段连接；数据、地址或属性随所属事务保持，不自行重排字节。
    assign mem_rlast   = cc_s_rlast;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
    // AXI通道握手边界；仅在本级状态允许时接收或保持有效事务。
    assign mem_rvalid  = cc_s_rvalid;   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务

    wire [AXI_ID_WIDTH-1:0] m_awid, m_bid, m_arid, m_rid;    // MIG 侧写通道 ID/地址/属性组
    wire [AXI_ADDR_WIDTH-1:0] m_awaddr, m_araddr;    // MIG 侧读写地址
    wire [7:0] m_awlen, m_arlen;    // MIG 侧读写突发长度
    wire [2:0] m_awsize, m_arsize;    // MIG 侧读写每拍字节数
    wire [1:0] m_awburst, m_arburst;    // MIG 侧读写突发类型
    wire [0:0] m_awlock, m_arlock;    // MIG 侧读写锁定属性
    wire [3:0] m_awcache, m_arcache, m_awregion, m_arregion, m_awqos, m_arqos;    // MIG 侧读写缓存/region/QoS 属性
    wire [2:0] m_awprot, m_arprot;    // MIG 侧读写保护属性
    wire m_awvalid, m_awready, m_wlast, m_wvalid, m_wready;    // MIG 侧写通道握手组
    wire [AXI_DATA_WIDTH-1:0] m_wdata, m_rdata;    // MIG 侧读写数据
    wire [(AXI_DATA_WIDTH/8)-1:0] m_wstrb;    // MIG 侧写字节使能
    wire [1:0] m_bresp, m_rresp;    // MIG 侧读写响应码
    wire m_bvalid, m_bready, m_arvalid, m_arready, m_rlast, m_rvalid, m_rready;    // MIG 侧读通道握手组

    rtds_axi_clock_converter u_axi_clock_converter (
        .s_axi_aclk(s_axi_aclk),   // 2026-10-11：转换器业务侧时钟
        .s_axi_aresetn(converter_s_reset_pipe[15]),   // 2026-10-11：清空转换器业务侧旧事务缓存
        .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr), .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize), .s_axi_awburst(s_axi_awburst), .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache), .s_axi_awprot(s_axi_awprot), .s_axi_awregion(s_axi_awregion),
        .s_axi_awqos(s_axi_awqos), .s_axi_awvalid(mem_awvalid), .s_axi_awready(cc_s_awready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(mem_wvalid), .s_axi_wready(cc_s_wready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_bid(cc_s_bid), .s_axi_bresp(cc_s_bresp), .s_axi_bvalid(cc_s_bvalid), .s_axi_bready(mem_bready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_arid(s_axi_arid), .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize), .s_axi_arburst(s_axi_arburst), .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache), .s_axi_arprot(s_axi_arprot), .s_axi_arregion(s_axi_arregion),
        .s_axi_arqos(s_axi_arqos), .s_axi_arvalid(mem_arvalid), .s_axi_arready(cc_s_arready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .s_axi_rid(cc_s_rid), .s_axi_rdata(cc_s_rdata), .s_axi_rresp(cc_s_rresp),
        .s_axi_rlast(cc_s_rlast), .s_axi_rvalid(cc_s_rvalid), .s_axi_rready(mem_rready),   // 2026-10-11：存储侧经事务恢复逻辑连接；复位后旧响应不进入新事务
        .m_axi_aclk(ui_clk),   // 2026-10-11：转换器MIG侧时钟
        .m_axi_aresetn(converter_m_reset_pipe[15]),   // 2026-10-11：与MIG AXI接口采用相同复位
        .m_axi_awid(m_awid), .m_axi_awaddr(m_awaddr), .m_axi_awlen(m_awlen), .m_axi_awsize(m_awsize),
        .m_axi_awburst(m_awburst), .m_axi_awlock(m_awlock), .m_axi_awcache(m_awcache),
        .m_axi_awprot(m_awprot), .m_axi_awregion(m_awregion), .m_axi_awqos(m_awqos),
        .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready), .m_axi_wdata(m_wdata),
        .m_axi_wstrb(m_wstrb), .m_axi_wlast(m_wlast), .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
        .m_axi_bid(m_bid), .m_axi_bresp(m_bresp), .m_axi_bvalid(m_bvalid), .m_axi_bready(m_bready),
        .m_axi_arid(m_arid), .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen), .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst), .m_axi_arlock(m_arlock), .m_axi_arcache(m_arcache),
        .m_axi_arprot(m_arprot), .m_axi_arregion(m_arregion), .m_axi_arqos(m_arqos),
        .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready), .m_axi_rid(m_rid),
        .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp), .m_axi_rlast(m_rlast),
        .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready)
    );

    rtds_ddr4_mig u_ddr4_mig (
        .c0_init_calib_complete(mig_calib_complete), .dbg_clk(), .c0_sys_clk_i(ddr_sys_clk_i), .dbg_bus(),
        .c0_ddr4_adr(c0_ddr4_adr), .c0_ddr4_ba(c0_ddr4_ba), .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_cs_n(c0_ddr4_cs_n), .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n), .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c), .c0_ddr4_dqs_t(c0_ddr4_dqs_t), .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_bg(c0_ddr4_bg), .c0_ddr4_reset_n(c0_ddr4_reset_n), .c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_ck_c(c0_ddr4_ck_c), .c0_ddr4_ck_t(c0_ddr4_ck_t), .c0_ddr4_ui_clk(ui_clk),
        .c0_ddr4_ui_clk_sync_rst(ui_clk_sync_rst),   // 2026-10-11：保留MIG原有UI复位指示
        .c0_ddr4_aresetn(converter_m_reset_pipe[15]),   // 2026-10-11：与转换器MIG侧同步清空AXI在途事务
        .c0_ddr4_s_axi_awid(m_awid), .c0_ddr4_s_axi_awaddr(m_awaddr), .c0_ddr4_s_axi_awlen(m_awlen),
        .c0_ddr4_s_axi_awsize(m_awsize), .c0_ddr4_s_axi_awburst(m_awburst), .c0_ddr4_s_axi_awlock(m_awlock),
        .c0_ddr4_s_axi_awcache(m_awcache), .c0_ddr4_s_axi_awprot(m_awprot), .c0_ddr4_s_axi_awqos(m_awqos),
        .c0_ddr4_s_axi_awvalid(m_awvalid), .c0_ddr4_s_axi_awready(m_awready),
        .c0_ddr4_s_axi_wdata(m_wdata), .c0_ddr4_s_axi_wstrb(m_wstrb), .c0_ddr4_s_axi_wlast(m_wlast),
        .c0_ddr4_s_axi_wvalid(m_wvalid), .c0_ddr4_s_axi_wready(m_wready), .c0_ddr4_s_axi_bready(m_bready),
        .c0_ddr4_s_axi_bid(m_bid), .c0_ddr4_s_axi_bresp(m_bresp), .c0_ddr4_s_axi_bvalid(m_bvalid),
        .c0_ddr4_s_axi_arid(m_arid), .c0_ddr4_s_axi_araddr(m_araddr), .c0_ddr4_s_axi_arlen(m_arlen),
        .c0_ddr4_s_axi_arsize(m_arsize), .c0_ddr4_s_axi_arburst(m_arburst), .c0_ddr4_s_axi_arlock(m_arlock),
        .c0_ddr4_s_axi_arcache(m_arcache), .c0_ddr4_s_axi_arprot(m_arprot), .c0_ddr4_s_axi_arqos(m_arqos),
        .c0_ddr4_s_axi_arvalid(m_arvalid), .c0_ddr4_s_axi_arready(m_arready),
        .c0_ddr4_s_axi_rready(m_rready), .c0_ddr4_s_axi_rlast(m_rlast), .c0_ddr4_s_axi_rvalid(m_rvalid),
        .c0_ddr4_s_axi_rresp(m_rresp), .c0_ddr4_s_axi_rid(m_rid), .c0_ddr4_s_axi_rdata(m_rdata),
        .sys_rst(~ddr_sys_rst_n)
    );
`endif
endmodule
