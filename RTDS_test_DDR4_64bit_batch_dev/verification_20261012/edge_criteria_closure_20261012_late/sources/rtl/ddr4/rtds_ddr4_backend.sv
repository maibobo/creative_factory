// DDR接口封装：DDR4_REAL连接实际MIG，DDR4_SIM_RAM连接行为RAM，二者只能选一。
// 业务AXI与MIG用户时钟之间通过时钟转换IP连接，存储复位在两侧分别同步释放。
// 已接受AR/AW后保存ID和拍数；存储失效时补齐错误R，或收完并丢弃剩余W后返回错误B。
// 已经展示的R/B在反压期间保持，不能因为后来失效而改写；业务全局复位仍会清恢复记录。
// 本模块是项目自写RTL，MIG和Clock Converter为厂商IP；RAM配置不代表DDR物理时序。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。
// 功能修改 2026-10-11：记录原ID/拍数，DDR失效后补齐错误响应并保持已展示R/B。
// 设计修改 2026-10-12：恢复同步链属性与定点约束；当前生效约束段在DDR4_PIN.xdc。

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

// 模块参数与输入输出。
module rtds_ddr4_backend #(
    parameter integer                             AXI_ADDR_WIDTH = 32,                // AXI字节地址位宽
    parameter integer                             AXI_DATA_WIDTH = 64,                // AXI数据位宽
    parameter integer                             AXI_ID_WIDTH   = 5,                 // AXI事务ID位宽
    parameter integer                             TIMEOUT_CYCLES = 65535              // 无进展等待的诊断阈值拍数
) (
    input wire                                 s_axi_aclk,                            // AXI 从端时钟（控制/DDR 域）
    input wire                                 s_axi_aresetn,                         // 业务AXI低有效复位
    input wire                                 ddr_sys_clk_i,                         // MIG 系统时钟输入（仅 DDR4_REAL 使用）
    input wire                                 ddr_sys_rst_n,                         // DDR系统低有效复位
    input wire                                 clear_status,                          // 软件读0x10形成的清诊断请求，不清事务记录
    input wire    [AXI_ID_WIDTH-1:0]           s_axi_awid,                            // 写地址通道 ID
    input wire    [AXI_ADDR_WIDTH-1:0]         s_axi_awaddr,                          // 写地址通道起始字节地址
    input wire    [7:0]                        s_axi_awlen,                           // 写突发拍数减一
    input wire    [2:0]                        s_axi_awsize,                          // 写每拍字节数（3=8Byte/64bit）
    input wire    [1:0]                        s_axi_awburst,                         // 写突发类型（1=INCR）
    input wire    [0:0]                        s_axi_awlock,                          // 写锁定属性
    input wire    [3:0]                        s_axi_awcache,                         // 写缓存属性
    input wire    [2:0]                        s_axi_awprot,                          // 写保护属性
    input wire    [3:0]                        s_axi_awregion,                        // 写 region（本设计未使用）
    input wire    [3:0]                        s_axi_awqos,                           // 写 QoS（本设计未使用）
    input wire                                 s_axi_awvalid,                         // 写地址有效
    output wire                                s_axi_awready,                         // 写地址就绪
    input wire    [AXI_DATA_WIDTH-1:0]         s_axi_wdata,                           // 写数据
    input wire    [(AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb,                           // 写字节使能
    input wire                                 s_axi_wlast,                           // 写末拍标志
    input wire                                 s_axi_wvalid,                          // 写数据有效
    output wire                                s_axi_wready,                          // 写数据就绪
    output wire   [AXI_ID_WIDTH-1:0]           s_axi_bid,                             // 写响应 ID（回显 AWID）
    output wire   [1:0]                        s_axi_bresp,                           // 写响应码（00=OKAY）
    output wire                                s_axi_bvalid,                          // 写响应有效
    input wire                                 s_axi_bready,                          // 写响应就绪
    input wire    [AXI_ID_WIDTH-1:0]           s_axi_arid,                            // 读地址通道 ID
    input wire    [AXI_ADDR_WIDTH-1:0]         s_axi_araddr,                          // 读地址通道起始字节地址
    input wire    [7:0]                        s_axi_arlen,                           // 读突发拍数减一
    input wire    [2:0]                        s_axi_arsize,                          // 读每拍字节数
    input wire    [1:0]                        s_axi_arburst,                         // 读突发类型
    input wire    [0:0]                        s_axi_arlock,                          // 读锁定属性
    input wire    [3:0]                        s_axi_arcache,                         // 读缓存属性
    input wire    [2:0]                        s_axi_arprot,                          // 读保护属性
    input wire    [3:0]                        s_axi_arregion,                        // 读 region（本设计未使用）
    input wire    [3:0]                        s_axi_arqos,                           // 读 QoS（本设计未使用）
    input wire                                 s_axi_arvalid,                         // 读地址有效
    output wire                                s_axi_arready,                         // 读地址就绪
    output wire   [AXI_ID_WIDTH-1:0]           s_axi_rid,                             // 读响应 ID（回显 ARID）
    output wire   [AXI_DATA_WIDTH-1:0]         s_axi_rdata,                           // 读数据
    output wire   [1:0]                        s_axi_rresp,                           // 读响应码（00=OKAY）
    output wire                                s_axi_rlast,                           // 读末拍标志
    output wire                                s_axi_rvalid,                          // 读数据有效
    input wire                                 s_axi_rready,                          // 读就绪
    output wire                                ddr_ready,                             // 存储接口可用且旧读写错误事务已结束，可接收新业务
    output wire                                init_calib_complete,                   // MIG 校准完成（真实模式）/模型就绪（仿真模式）
    output reg                                 ddr_axi_response_error_sticky,         // B/R 响应非 OKAY 保持至清除的标志（clear_status 清除）
    output reg                                 ddr_axi_timeout_sticky,                // 事务超时保持至清除的标志（clear_status 清除）
    output wire                                c0_ddr4_act_n,                         // DDR4行激活控制，低有效
    output wire   [16:0]                       c0_ddr4_adr,                           // DDR4行列复用地址
    output wire   [1:0]                        c0_ddr4_ba,                            // DDR4Bank地址
    output wire   [0:0]                        c0_ddr4_bg,                            // DDR4Bank组地址
    output wire   [0:0]                        c0_ddr4_cke,                           // DDR4时钟使能输出
    output wire   [0:0]                        c0_ddr4_odt,                           // DDR4片内终端电阻控制输出
    output wire   [0:0]                        c0_ddr4_cs_n,                          // DDR4片选，低有效
    output wire   [0:0]                        c0_ddr4_ck_t,                          // DDR4差分时钟正端
    output wire   [0:0]                        c0_ddr4_ck_c,                          // DDR4差分时钟负端
    output wire                                c0_ddr4_reset_n,                       // DDR4 复位（低有效）
    inout wire    [7:0]                        c0_ddr4_dm_dbi_n,                      // DDR4双向字节掩码/DBI
    inout wire    [63:0]                       c0_ddr4_dq,                            // DDR4双向数据线
    inout wire    [7:0]                        c0_ddr4_dqs_c,                         // DDR4双向选通负端
    inout wire    [7:0]                        c0_ddr4_dqs_t                          // DDR4双向选通正端
);
`ifdef RTDS_DDR_MODE_CONFLICT
    initial $error("DDR4_REAL and DDR4_SIM_RAM are mutually exclusive");
`endif


    // 存储侧AXI通道连接；业务侧恢复状态另行保存。
    wire                                       storage_ready                                  ;    // 模型或MIG校准与存储接口实际可用
    wire                                       mem_awready                                    ;    // 存储侧写地址接收许可
    wire                                       mem_wready                                     ;    // 存储侧写数据接收许可
    wire                                       mem_bvalid                                     ;    // 存储侧写响应有效
    wire          [AXI_ID_WIDTH-1:0]           mem_bid                                        ;    // 存储侧写响应ID
    wire          [1:0]                        mem_bresp                                      ;    // 存储侧写响应码
    wire                                       mem_arready                                    ;    // 存储侧读地址接收许可
    wire                                       mem_rvalid                                     ;    // 存储侧读响应有效
    wire          [AXI_ID_WIDTH-1:0]           mem_rid                                        ;    // 存储侧读响应ID
    wire          [AXI_DATA_WIDTH-1:0]         mem_rdata                                      ;    // 存储侧读数据
    wire          [1:0]                        mem_rresp                                      ;    // 存储侧读响应码
    wire                                       mem_rlast                                      ;    // 存储侧读末拍标志

    // 2026-10-11修改：已接受事务的长度、ID和中断状态。
    reg                                        recovery_read_pending                          ;    // AR已接受，最后R尚未被业务侧接受
    reg                                        recovery_write_pending                         ;    // AW已接受，B尚未被业务侧接受
    reg                                        recovery_read_abort                            ;    // 旧读发生存储失效，剩余拍须返回错误
    reg                                        recovery_write_abort                           ;    // 旧写发生存储失效，剩余W不再进入存储
    reg           [8:0]                        recovery_read_left                             ;    // 尚未装入业务响应寄存器的读拍数，9bit支持256拍
    reg           [8:0]                        recovery_write_left                            ;    // 原突发尚未从业务侧接受的写拍数，9bit支持256拍
    reg           [AXI_ID_WIDTH-1:0]           recovery_read_id                               ;    // AR接受时保存的原ID
    reg           [AXI_ID_WIDTH-1:0]           recovery_write_id                              ;    // AW接受时保存的原ID

    // 业务侧R/B响应保持寄存器；反压时字段不能改变。
    reg                                        recovery_rvalid                                ;    // 上游读响应寄存器有效标志
    reg           [AXI_DATA_WIDTH-1:0]         recovery_rdata                                 ;    // 反压期间保持的读数据
    reg           [AXI_ID_WIDTH-1:0]           recovery_rid                                   ;    // 反压期间保持的读响应ID
    reg           [1:0]                        recovery_rresp                                 ;    // 反压期间保持的读响应码
    reg                                        recovery_rlast                                 ;    // 反压期间保持的读末拍标志
    reg                                        recovery_bvalid                                ;    // 上游写响应寄存器有效标志
    reg           [AXI_ID_WIDTH-1:0]           recovery_bid                                   ;    // 反压期间保持的写响应ID
    reg           [1:0]                        recovery_bresp                                 ;    // 反压期间保持的写响应码
    wire                                       recovery_read_fault =
        recovery_read_abort || !storage_ready                                                 ;    // 旧读已标记失效或存储当前不可用
    wire                                       recovery_write_fault =
        recovery_write_abort || !storage_ready                                                ;    // 旧写已标记失效或存储当前不可用
    wire                                       recovery_rslot =
        !recovery_rvalid || s_axi_rready                                                      ;    // R保持寄存器为空或旧拍正在被接受，可装下一拍
    wire                                       recovery_rload =
        recovery_read_pending && (recovery_read_left != 0) && recovery_rslot &&
        (recovery_read_fault || mem_rvalid)                                                   ;    // 可以装入真实R或补齐的错误R
    wire                                       recovery_bload =
        recovery_write_pending && (recovery_write_left == 0) && !recovery_bvalid &&
        (recovery_write_fault || mem_bvalid)                                                  ;    // 全部原W已接收且可以装入一次B
    wire                                       mem_awvalid =
        s_axi_aresetn && s_axi_awvalid && ddr_ready && !recovery_write_pending                ;    // 一次只向存储侧提交一个写突发
    wire                                       mem_arvalid =
        s_axi_aresetn && s_axi_arvalid && ddr_ready && !recovery_read_pending                 ;    // 一次只向存储侧提交一个读突发
    wire                                       mem_wvalid =
        s_axi_aresetn && s_axi_wvalid && recovery_write_pending &&
        (recovery_write_left != 0) && !recovery_write_fault                                   ;    // 仅转发未中断的已接受AW对应数据
    wire                                       mem_bready =
        s_axi_aresetn && recovery_write_pending && (recovery_write_left == 0) &&
        !recovery_bvalid && !recovery_write_fault                                             ;    // 真实写响应装入独立保持寄存器
    wire                                       mem_rready =
        s_axi_aresetn && recovery_read_pending && (recovery_read_left != 0) &&
        recovery_rslot && !recovery_read_fault                                                ;    // 真实读响应装入独立保持寄存器

    assign ddr_ready = storage_ready && !recovery_read_abort && !recovery_write_abort         ;    // 存储接口可用且旧读写错误事务已结束，可接收新业务
    assign s_axi_awready =
        s_axi_aresetn && ddr_ready && !recovery_write_pending && mem_awready                  ;    // 写地址就绪

    assign s_axi_arready = s_axi_aresetn && ddr_ready && !recovery_read_pending && mem_arready;    // 读地址就绪
    assign s_axi_wready =
        s_axi_aresetn && recovery_write_pending && (recovery_write_left != 0) &&
        (recovery_write_fault || mem_wready)                                                  ;    // 写数据就绪

    assign s_axi_rvalid = recovery_rvalid                                                     ;    // 读数据有效
    assign s_axi_rdata = recovery_rdata                                                       ;    // 读数据
    assign s_axi_rid = recovery_rid                                                           ;    // 读响应 ID（回显 ARID）
    assign s_axi_rresp = recovery_rresp                                                       ;    // 读响应码（00=OKAY）
    assign s_axi_rlast = recovery_rlast                                                       ;    // 读末拍标志
    assign s_axi_bvalid = recovery_bvalid                                                     ;    // 写响应有效
    assign s_axi_bid = recovery_bid                                                           ;    // 写响应 ID（回显 AWID）
    assign s_axi_bresp = recovery_bresp                                                       ;    // 写响应码（00=OKAY）


    // AR接受时保存ID和拍数；存储失效后尚未装载的R改为零数据SLVERR。已展示R保持，最后R被接受后清旧读记录。
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            recovery_read_pending <= 1'b0;
            recovery_read_abort <= 1'b0;
            recovery_read_left <= 9'd0;
            recovery_read_id <= {AXI_ID_WIDTH{1'b0}};
            recovery_rvalid <= 1'b0;
            recovery_rdata <= {AXI_DATA_WIDTH{1'b0}};
            recovery_rid <= {AXI_ID_WIDTH{1'b0}};
            recovery_rresp <= 2'b00;
            recovery_rlast <= 1'b0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                recovery_read_pending <= 1'b1;
                recovery_read_left <= {1'b0,s_axi_arlen} + 9'd1;
                recovery_read_id <= s_axi_arid;
            end
            if (recovery_read_pending && !storage_ready)
                recovery_read_abort <= 1'b1;
            if (recovery_rvalid && s_axi_rready) begin
                recovery_rvalid <= 1'b0;
                if (recovery_rlast) begin
                    recovery_read_pending <= 1'b0;
                    recovery_read_abort <= 1'b0;
                end
            end
            if (recovery_rload) begin
                recovery_rvalid <= 1'b1;
                recovery_rdata <= recovery_read_fault ? {AXI_DATA_WIDTH{1'b0}} : mem_rdata;
                recovery_rid <= recovery_read_fault ? recovery_read_id : mem_rid;
                recovery_rresp <= recovery_read_fault ? 2'b10 : mem_rresp;
                recovery_rlast <= (recovery_read_left == 9'd1);
                recovery_read_left <= recovery_read_left - 9'd1;
            end
        end
    end


    // AW接受时保存ID和拍数；失效后接收并丢弃剩余W，收齐后只给一次错误B。已展示B保持到接受。
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            recovery_write_pending <= 1'b0;
            recovery_write_abort <= 1'b0;
            recovery_write_left <= 9'd0;
            recovery_write_id <= {AXI_ID_WIDTH{1'b0}};
            recovery_bvalid <= 1'b0;
            recovery_bid <= {AXI_ID_WIDTH{1'b0}};
            recovery_bresp <= 2'b00;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                recovery_write_pending <= 1'b1;
                recovery_write_left <= {1'b0,s_axi_awlen} + 9'd1;
                recovery_write_id <= s_axi_awid;
            end
            if (recovery_write_pending && !storage_ready)
                recovery_write_abort <= 1'b1;
            if (s_axi_wvalid && s_axi_wready)
                recovery_write_left <= recovery_write_left - 9'd1;
            if (recovery_bvalid && s_axi_bready) begin
                recovery_bvalid <= 1'b0;
                recovery_write_pending <= 1'b0;
                recovery_write_abort <= 1'b0;
            end
            if (recovery_bload) begin
                recovery_bvalid <= 1'b1;
                recovery_bid <= recovery_write_fault ? recovery_write_id : mem_bid;
                recovery_bresp <= recovery_write_fault ? 2'b10 : mem_bresp;
            end
        end
    end

    wire                                       aw_hs = s_axi_awvalid && s_axi_awready         ;    // AXI写地址接受事件
    wire                                       w_hs  = s_axi_wvalid  && s_axi_wready          ;    // AXI写数据接受事件
    wire                                       b_hs  = s_axi_bvalid  && s_axi_bready          ;    // AXI写响应接受事件
    wire                                       ar_hs = s_axi_arvalid && s_axi_arready         ;    // AXI读地址接受事件
    wire                                       r_hs  = s_axi_rvalid  && s_axi_rready          ;    // AXI读数据接受事件

    // 未结束事务数量和超时诊断。
    reg           [7:0]                        outstanding_writes                             ;    // AW接受后尚未接受B的事务数
    reg           [7:0]                        outstanding_reads                              ;    // AR接受后尚未收完最后R的事务数
    reg           [31:0]                       timeout_count                                  ;    // 在途事务连续无握手进展的拍数
    reg                                        ready_seen                                     ;    // 曾经观察到业务DDR就绪
    wire                                       any_pending =
        (outstanding_writes != 0) || (outstanding_reads != 0)                                 ;    // 存在尚未结束的读或写事务
    wire                                       any_progress =
        aw_hs || w_hs || b_hs || ar_hs || r_hs                                                ;    // AXI五通道任一实际握手发生


    // 按地址接受和最终响应维护未完成事务数；无进展达到阈值或存储ready下降时保持错误，clear_status清诊断。
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

    // 行为RAM分支的就绪与接口连接。
    reg           [1:0]                        sim_ready_pipe                                 ;    // RAM配置复位解除后的两拍就绪管线


    // RAM模式等待业务和DDR系统复位解除，再连续两拍给出存储ready。
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || !ddr_sys_rst_n)
            sim_ready_pipe <= 2'b00;
        else
            sim_ready_pipe <= {sim_ready_pipe[0],1'b1};
    end

    // 存储侧AXI通道连接；业务侧恢复状态另行保存。
    assign storage_ready = sim_ready_pipe[1]                                                  ;    // 模型或MIG校准与存储接口实际可用

    assign init_calib_complete = sim_ready_pipe[1]                                            ;    // MIG 校准完成（真实模式）/模型就绪（仿真模式）

    wire                                       ram_awready                                    ;    // RAM 模型侧五通道握手线
    wire                                       ram_wready                                     ;    // 行为RAM侧写数据通道当前可接受
    wire                                       ram_bvalid                                     ;    // 行为RAM侧写响应通道有效，保持到ready接受
    wire                                       ram_arready                                    ;    // 行为RAM侧读地址通道当前可接受
    wire                                       ram_rlast                                      ;    // 行为RAM侧读数据最后一拍标志
    wire                                       ram_rvalid                                     ;    // 行为RAM侧读数据通道有效，保持到ready接受
    wire          [AXI_ID_WIDTH-1:0]           ram_bid                                        ;    // RAM 模型侧响应 ID
    wire          [AXI_ID_WIDTH-1:0]           ram_rid                                        ;    // 行为RAM侧读数据事务ID
    wire          [1:0]                        ram_bresp                                      ;    // RAM 模型侧响应码
    wire          [1:0]                        ram_rresp                                      ;    // 行为RAM侧读数据响应码，0为OKAY、2为SLVERR
    wire          [AXI_DATA_WIDTH-1:0]         ram_rdata                                      ;    // RAM 模型侧读数据

    assign mem_awready = storage_ready && ram_awready                                         ;    // 存储侧写地址接收许可

    assign mem_wready  = storage_ready && ram_wready                                          ;    // 存储侧写数据接收许可

    assign mem_bvalid  = ram_bvalid                                                           ;    // 存储侧写响应有效

    assign mem_bid     = ram_bid                                                              ;    // 存储侧写响应ID

    assign mem_bresp   = ram_bresp                                                            ;    // 存储侧写响应码

    assign mem_arready = storage_ready && ram_arready                                         ;    // 存储侧读地址接收许可

    assign mem_rid     = ram_rid                                                              ;    // 存储侧读响应ID

    assign mem_rdata   = ram_rdata                                                            ;    // 存储侧读数据

    assign mem_rresp   = ram_rresp                                                            ;    // 存储侧读响应码

    assign mem_rlast   = ram_rlast                                                            ;    // 存储侧读末拍标志

    assign mem_rvalid  = ram_rvalid                                                           ;    // 存储侧读响应有效

    rtds_axi_ram_model #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .ID_WIDTH(AXI_ID_WIDTH),
        .MEM_BYTES(4194304)
    ) u_sim_ram (
        .aclk(s_axi_aclk),
        .aresetn(s_axi_aresetn && storage_ready),
        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awvalid(mem_awvalid),
        .s_axi_awready(ram_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(mem_wvalid),
        .s_axi_wready(ram_wready),
        .s_axi_bid(ram_bid),
        .s_axi_bresp(ram_bresp),
        .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(mem_bready),
        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arvalid(mem_arvalid),
        .s_axi_arready(ram_arready),
        .s_axi_rid(ram_rid),
        .s_axi_rdata(ram_rdata),
        .s_axi_rresp(ram_rresp),
        .s_axi_rlast(ram_rlast),
        .s_axi_rvalid(ram_rvalid),
        .s_axi_rready(mem_rready)
    );


    assign c0_ddr4_act_n = 1'b1                                                               ;    // DDR4行激活控制，低有效

    assign c0_ddr4_adr = 17'd0                                                                ;    // DDR4行列复用地址

    assign c0_ddr4_ba = 2'd0                                                                  ;    // DDR4Bank地址

    assign c0_ddr4_bg = 1'd0                                                                  ;    // DDR4Bank组地址

    assign c0_ddr4_cke = 1'd0                                                                 ;    // DDR4时钟使能输出

    assign c0_ddr4_odt = 1'd0                                                                 ;    // DDR4片内终端电阻控制输出

    assign c0_ddr4_cs_n = 1'd1                                                                ;    // DDR4片选，低有效

    assign c0_ddr4_ck_t = 1'd0                                                                ;    // DDR4差分时钟正端

    assign c0_ddr4_ck_c = 1'd0                                                                ;    // DDR4差分时钟负端

    assign c0_ddr4_reset_n = 1'b0                                                             ;    // DDR4 复位（低有效）

    assign c0_ddr4_dm_dbi_n = 8'hzz                                                           ;    // DDR4双向字节掩码/DBI

    assign c0_ddr4_dq = 64'hzzzz_zzzz_zzzz_zzzz                                               ;    // DDR4双向数据线

    assign c0_ddr4_dqs_c = 8'hzz                                                              ;    // DDR4双向选通负端

    assign c0_ddr4_dqs_t = 8'hzz                                                              ;    // DDR4双向选通正端
`else

    // 真实MIG分支的时钟、校准和复位。
    wire                                       ui_clk                                         ;    // MIG输出的用户时钟
    wire                                       ui_clk_sync_rst                                ;    // MIG用户域高有效复位请求
    wire                                       mig_calib_complete                             ;    // 真实MIG校准完成
    reg           [1:0]                        ui_reset_pipe                                  ;    // MIG用户域两拍接口复位解除管线


    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] ready_sync                       ;    // MIG接口可用标志同步到业务域的管线
    wire                                       ui_axi_aresetn = ui_reset_pipe[1]              ;    // MIG用户域接口已同步解除复位


    wire                                       converter_reset_n =
        s_axi_aresetn && ddr_sys_rst_n && ui_axi_aresetn                                      ;    // 存储侧共同低有效复位条件
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [15:0] converter_s_reset_pipe          ;    // 业务侧转换器16拍复位解除管线
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [15:0] converter_m_reset_pipe          ;    // MIG侧转换器16拍复位解除管线
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] converter_ready_sync             ;    // MIG侧转换器复位解除确认同步回业务域


    // 业务时钟域异步进入转换器复位，连续16个业务时钟后解除本侧复位。
    always @(posedge s_axi_aclk or negedge converter_reset_n) begin
        if (!converter_reset_n)
            converter_s_reset_pipe <= 16'd0;
        else
            converter_s_reset_pipe <= {converter_s_reset_pipe[14:0],1'b1};
    end


    // MIG用户时钟域异步进入转换器复位，连续16个UI时钟后解除本侧复位。
    always @(posedge ui_clk or negedge converter_reset_n) begin
        if (!converter_reset_n)
            converter_m_reset_pipe <= 16'd0;
        else
            converter_m_reset_pipe <= {converter_m_reset_pipe[14:0],1'b1};
    end


    // 把MIG侧复位解除确认同步回业务域；任一共同复位条件失效时清同步管线。
    always @(posedge s_axi_aclk or negedge converter_reset_n) begin
        if (!converter_reset_n)
            converter_ready_sync <= 2'b00;
        else
            converter_ready_sync <= {converter_ready_sync[0],converter_m_reset_pipe[15]};
    end


    // MIG未校准或UI要求复位时保持接口复位，校准后在UI域两拍解除。
    always @(posedge ui_clk) begin
        if (ui_clk_sync_rst || !mig_calib_complete)
            ui_reset_pipe <= 2'b00;
        else
            ui_reset_pipe <= {ui_reset_pipe[0],1'b1};
    end


    // 把UI接口可用标志同步到业务时钟域；业务全局复位清该同步状态。
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            ready_sync <= 2'b00;
        else
            ready_sync <= {ready_sync[0],ui_axi_aresetn};
    end

    // 存储侧AXI通道连接；业务侧恢复状态另行保存。
    assign storage_ready =
        ready_sync[1] && converter_s_reset_pipe[15] && converter_ready_sync[1]                ;    // 模型或MIG校准与存储接口实际可用


    assign init_calib_complete = ready_sync[1]                                                ;    // MIG 校准完成（真实模式）/模型就绪（仿真模式）

    // Clock Converter业务侧AXI字段。
    wire                                       cc_s_awready                                   ;    // 时钟转换器从侧五通道握手线
    wire                                       cc_s_wready                                    ;    // 时钟转换器业务侧写数据通道当前可接受
    wire                                       cc_s_bvalid                                    ;    // 时钟转换器业务侧写响应通道有效，保持到ready接受
    wire                                       cc_s_arready                                   ;    // 时钟转换器业务侧读地址通道当前可接受
    wire                                       cc_s_rlast                                     ;    // 时钟转换器业务侧读数据最后一拍标志
    wire                                       cc_s_rvalid                                    ;    // 时钟转换器业务侧读数据通道有效，保持到ready接受
    wire          [AXI_ID_WIDTH-1:0]           cc_s_bid                                       ;    // 时钟转换器从侧响应 ID
    wire          [AXI_ID_WIDTH-1:0]           cc_s_rid                                       ;    // 时钟转换器业务侧读数据事务ID
    wire          [1:0]                        cc_s_bresp                                     ;    // 时钟转换器从侧响应码
    wire          [1:0]                        cc_s_rresp                                     ;    // 时钟转换器业务侧读数据响应码，0为OKAY、2为SLVERR
    wire          [AXI_DATA_WIDTH-1:0]         cc_s_rdata                                     ;    // 时钟转换器从侧读数据

    assign mem_awready = storage_ready && cc_s_awready                                        ;    // 存储侧写地址接收许可

    assign mem_wready  = storage_ready && cc_s_wready                                         ;    // 存储侧写数据接收许可

    assign mem_bid     = cc_s_bid                                                             ;    // 存储侧写响应ID

    assign mem_bresp   = cc_s_bresp                                                           ;    // 存储侧写响应码

    assign mem_bvalid  = cc_s_bvalid                                                          ;    // 存储侧写响应有效

    assign mem_arready = storage_ready && cc_s_arready                                        ;    // 存储侧读地址接收许可

    assign mem_rid     = cc_s_rid                                                             ;    // 存储侧读响应ID

    assign mem_rdata   = cc_s_rdata                                                           ;    // 存储侧读数据

    assign mem_rresp   = cc_s_rresp                                                           ;    // 存储侧读响应码

    assign mem_rlast   = cc_s_rlast                                                           ;    // 存储侧读末拍标志

    assign mem_rvalid  = cc_s_rvalid                                                          ;    // 存储侧读响应有效

    // MIG用户时钟域AXI字段。
    wire          [AXI_ID_WIDTH-1:0]           m_awid                                         ;    // MIG 侧写通道 ID/地址/属性组
    wire          [AXI_ID_WIDTH-1:0]           m_bid                                          ;    // MIG用户域写响应事务ID
    wire          [AXI_ID_WIDTH-1:0]           m_arid                                         ;    // MIG用户域读地址事务ID
    wire          [AXI_ID_WIDTH-1:0]           m_rid                                          ;    // MIG用户域读数据事务ID
    wire          [AXI_ADDR_WIDTH-1:0]         m_awaddr                                       ;    // MIG 侧读写地址
    wire          [AXI_ADDR_WIDTH-1:0]         m_araddr                                       ;    // MIG用户域读突发起始字节地址
    wire          [7:0]                        m_awlen                                        ;    // MIG 侧读写突发长度
    wire          [7:0]                        m_arlen                                        ;    // MIG用户域读地址突发拍数减1
    wire          [2:0]                        m_awsize                                       ;    // MIG 侧读写每拍字节数
    wire          [2:0]                        m_arsize                                       ;    // MIG用户域读地址每拍字节数的log2编码
    wire          [1:0]                        m_awburst                                      ;    // MIG 侧读写突发类型
    wire          [1:0]                        m_arburst                                      ;    // MIG用户域读地址地址类型，INCR为逐拍递增
    wire          [0:0]                        m_awlock                                       ;    // MIG 侧读写锁定属性
    wire          [0:0]                        m_arlock                                       ;    // MIG用户域读地址通道lock属性
    wire          [3:0]                        m_awcache                                      ;    // MIG 侧读写缓存/region/QoS 属性
    wire          [3:0]                        m_arcache                                      ;    // MIG用户域读地址通道cache属性
    wire          [3:0]                        m_awregion                                     ;    // MIG用户域写地址通道region属性
    wire          [3:0]                        m_arregion                                     ;    // MIG用户域读地址通道region属性
    wire          [3:0]                        m_awqos                                        ;    // MIG用户域写地址通道qos属性
    wire          [3:0]                        m_arqos                                        ;    // MIG用户域读地址通道qos属性
    wire          [2:0]                        m_awprot                                       ;    // MIG 侧读写保护属性
    wire          [2:0]                        m_arprot                                       ;    // MIG用户域读地址通道prot属性
    wire                                       m_awvalid                                      ;    // MIG 侧写通道握手组
    wire                                       m_awready                                      ;    // MIG用户域写地址通道当前可接受
    wire                                       m_wlast                                        ;    // MIG用户域写数据最后一拍标志
    wire                                       m_wvalid                                       ;    // MIG用户域写数据通道有效，保持到ready接受
    wire                                       m_wready                                       ;    // MIG用户域写数据通道当前可接受
    wire          [AXI_DATA_WIDTH-1:0]         m_wdata                                        ;    // MIG 侧读写数据
    wire          [AXI_DATA_WIDTH-1:0]         m_rdata                                        ;    // MIG用户域读数据当前数据
    wire          [(AXI_DATA_WIDTH/8)-1:0]     m_wstrb                                        ;    // MIG 侧写字节使能
    wire          [1:0]                        m_bresp                                        ;    // MIG 侧读写响应码
    wire          [1:0]                        m_rresp                                        ;    // MIG用户域读数据响应码，0为OKAY、2为SLVERR
    wire                                       m_bvalid                                       ;    // MIG 侧读通道握手组
    wire                                       m_bready                                       ;    // MIG用户域写响应通道当前可接受
    wire                                       m_arvalid                                      ;    // MIG用户域读地址通道有效，保持到ready接受
    wire                                       m_arready                                      ;    // MIG用户域读地址通道当前可接受
    wire                                       m_rlast                                        ;    // MIG用户域读数据最后一拍标志
    wire                                       m_rvalid                                       ;    // MIG用户域读数据通道有效，保持到ready接受
    wire                                       m_rready                                       ;    // MIG用户域读数据通道当前可接受

    rtds_axi_clock_converter u_axi_clock_converter (
        .s_axi_aclk(s_axi_aclk),
        .s_axi_aresetn(converter_s_reset_pipe[15]),
        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awregion(s_axi_awregion),
        .s_axi_awqos(s_axi_awqos),
        .s_axi_awvalid(mem_awvalid),
        .s_axi_awready(cc_s_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(mem_wvalid),
        .s_axi_wready(cc_s_wready),
        .s_axi_bid(cc_s_bid),
        .s_axi_bresp(cc_s_bresp),
        .s_axi_bvalid(cc_s_bvalid),
        .s_axi_bready(mem_bready),
        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arregion(s_axi_arregion),
        .s_axi_arqos(s_axi_arqos),
        .s_axi_arvalid(mem_arvalid),
        .s_axi_arready(cc_s_arready),
        .s_axi_rid(cc_s_rid),
        .s_axi_rdata(cc_s_rdata),
        .s_axi_rresp(cc_s_rresp),
        .s_axi_rlast(cc_s_rlast),
        .s_axi_rvalid(cc_s_rvalid),
        .s_axi_rready(mem_rready),
        .m_axi_aclk(ui_clk),
        .m_axi_aresetn(converter_m_reset_pipe[15]),
        .m_axi_awid(m_awid),
        .m_axi_awaddr(m_awaddr),
        .m_axi_awlen(m_awlen),
        .m_axi_awsize(m_awsize),
        .m_axi_awburst(m_awburst),
        .m_axi_awlock(m_awlock),
        .m_axi_awcache(m_awcache),
        .m_axi_awprot(m_awprot),
        .m_axi_awregion(m_awregion),
        .m_axi_awqos(m_awqos),
        .m_axi_awvalid(m_awvalid),
        .m_axi_awready(m_awready),
        .m_axi_wdata(m_wdata),
        .m_axi_wstrb(m_wstrb),
        .m_axi_wlast(m_wlast),
        .m_axi_wvalid(m_wvalid),
        .m_axi_wready(m_wready),
        .m_axi_bid(m_bid),
        .m_axi_bresp(m_bresp),
        .m_axi_bvalid(m_bvalid),
        .m_axi_bready(m_bready),
        .m_axi_arid(m_arid),
        .m_axi_araddr(m_araddr),
        .m_axi_arlen(m_arlen),
        .m_axi_arsize(m_arsize),
        .m_axi_arburst(m_arburst),
        .m_axi_arlock(m_arlock),
        .m_axi_arcache(m_arcache),
        .m_axi_arprot(m_arprot),
        .m_axi_arregion(m_arregion),
        .m_axi_arqos(m_arqos),
        .m_axi_arvalid(m_arvalid),
        .m_axi_arready(m_arready),
        .m_axi_rid(m_rid),
        .m_axi_rdata(m_rdata),
        .m_axi_rresp(m_rresp),
        .m_axi_rlast(m_rlast),
        .m_axi_rvalid(m_rvalid),
        .m_axi_rready(m_rready)
    );

    rtds_ddr4_mig u_ddr4_mig (
        .c0_init_calib_complete(mig_calib_complete),
        .dbg_clk(),
        .c0_sys_clk_i(ddr_sys_clk_i),
        .dbg_bus(),
        .c0_ddr4_adr(c0_ddr4_adr),
        .c0_ddr4_ba(c0_ddr4_ba),
        .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_cs_n(c0_ddr4_cs_n),
        .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
        .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_bg(c0_ddr4_bg),
        .c0_ddr4_reset_n(c0_ddr4_reset_n),
        .c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_ck_c(c0_ddr4_ck_c),
        .c0_ddr4_ck_t(c0_ddr4_ck_t),
        .c0_ddr4_ui_clk(ui_clk),
        .c0_ddr4_ui_clk_sync_rst(ui_clk_sync_rst),
        .c0_ddr4_aresetn(converter_m_reset_pipe[15]),
        .c0_ddr4_s_axi_awid(m_awid),
        .c0_ddr4_s_axi_awaddr(m_awaddr),
        .c0_ddr4_s_axi_awlen(m_awlen),
        .c0_ddr4_s_axi_awsize(m_awsize),
        .c0_ddr4_s_axi_awburst(m_awburst),
        .c0_ddr4_s_axi_awlock(m_awlock),
        .c0_ddr4_s_axi_awcache(m_awcache),
        .c0_ddr4_s_axi_awprot(m_awprot),
        .c0_ddr4_s_axi_awqos(m_awqos),
        .c0_ddr4_s_axi_awvalid(m_awvalid),
        .c0_ddr4_s_axi_awready(m_awready),
        .c0_ddr4_s_axi_wdata(m_wdata),
        .c0_ddr4_s_axi_wstrb(m_wstrb),
        .c0_ddr4_s_axi_wlast(m_wlast),
        .c0_ddr4_s_axi_wvalid(m_wvalid),
        .c0_ddr4_s_axi_wready(m_wready),
        .c0_ddr4_s_axi_bready(m_bready),
        .c0_ddr4_s_axi_bid(m_bid),
        .c0_ddr4_s_axi_bresp(m_bresp),
        .c0_ddr4_s_axi_bvalid(m_bvalid),
        .c0_ddr4_s_axi_arid(m_arid),
        .c0_ddr4_s_axi_araddr(m_araddr),
        .c0_ddr4_s_axi_arlen(m_arlen),
        .c0_ddr4_s_axi_arsize(m_arsize),
        .c0_ddr4_s_axi_arburst(m_arburst),
        .c0_ddr4_s_axi_arlock(m_arlock),
        .c0_ddr4_s_axi_arcache(m_arcache),
        .c0_ddr4_s_axi_arprot(m_arprot),
        .c0_ddr4_s_axi_arqos(m_arqos),
        .c0_ddr4_s_axi_arvalid(m_arvalid),
        .c0_ddr4_s_axi_arready(m_arready),
        .c0_ddr4_s_axi_rready(m_rready),
        .c0_ddr4_s_axi_rlast(m_rlast),
        .c0_ddr4_s_axi_rvalid(m_rvalid),
        .c0_ddr4_s_axi_rresp(m_rresp),
        .c0_ddr4_s_axi_rid(m_rid),
        .c0_ddr4_s_axi_rdata(m_rdata),
        .sys_rst(~ddr_sys_rst_n)
    );
`endif
endmodule
