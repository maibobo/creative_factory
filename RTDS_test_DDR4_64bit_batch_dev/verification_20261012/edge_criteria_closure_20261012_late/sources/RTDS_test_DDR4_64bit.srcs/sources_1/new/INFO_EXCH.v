// 软件寄存器接口：接收AXI-Lite访问，提供版本、状态和业务命令。
// 软件写0x24/0x28设置下行地址和长度，写0x20启动，忙时不允许改参数。
// 读0x10清通知和相关错误；写0x14=1只确认一次CPU已读完的上行块。
// AXI请求在S_AXI_ACLK处理，低有效复位清命令和握手状态；常量版本不随复位改变。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns / 1ps

// 模块参数与输入输出。
module INFO_EXCH#
    (

        parameter integer                             VERSION             = 32'h0000_2001,      // 软件只读版本常量
        parameter integer                             PROG_TIME           = 32'h2026_0914,      // 软件只读构建标识常量
        parameter integer                             CH_BUF_LEN          = 32'h0004_0000,      // 单个上行块的字节容量常量


        parameter integer                             C_S_AXI_DATA_WIDTH  = 32,                 // 本模块C_S_AXI_DATA_WIDTH固定配置/状态编码

        parameter integer                             C_S_AXI_ADDR_WIDTH  = 32                  // 本模块C_S_AXI_ADDR_WIDTH固定配置/状态编码
    )
    (

        input wire                                 CPU_WR_DONE_EVENT,                           // 下行成功、拒绝或中止的命令结束事件
        input wire    [C_S_AXI_DATA_WIDTH-1 : 0]   FPGA_TEMP_W             ,                    // 温度原始码和busy组合状态

        input wire    [0 : 0]                      INT_STATE_W             ,                    // 当前待读块的通知状态
        input wire    [0 : 0]                      CPU_REC_STATE_W         ,                    // CPU确认状态返回寄存器侧
        input wire    [C_S_AXI_DATA_WIDTH-1 : 0]   FPGA_CPU_START_ADDR     ,                    // 最早待读块的DDR字节地址
        input wire    [C_S_AXI_DATA_WIDTH-1 : 0]   FPGA_CPU_LEN            ,                    // 最早待读块成功写入的字节长度
        input wire    [0 : 0]                      CPU_WR_DONE_resp        ,                    // 下行业务任务响应忙状态
        input wire    [C_S_AXI_DATA_WIDTH-1 : 0]   DDR_STATUS_W            ,                    // DDR就绪、校准和错误状态输入
        input wire    [31:0]                       RX_READY_BLOCKS,                             // 完整待读块数量
        input wire    [31:0]                       RX_HEAD_SEQ,                                 // 最早待读块的顺序编号
        input wire    [31:0]                       RX_DROPPED_FRAMES,                           // 累计丢失32bit字数，端口名保留历史命名

        output                                     r_INT_STATE             ,                    // 软件读0x10形成的清通知输出
        output                                     r_CLEAR_INTER           ,                    // 软件读0x10形成的清相关错误输出
        output                                     r_CPU_REC_STATE         ,                    // 软件写0x14形成的一拍读完确认
        output                                     r_RD_START              ,                    // 0x20忙位0到1形成的一拍下行启动
        output        [C_S_AXI_DATA_WIDTH-1 : 0]   r_CPU_FPGA_START_ADDR   ,                    // 保存的下行起始DDR字节地址输出
        output        [C_S_AXI_DATA_WIDTH-1 : 0]   r_CPU_FPGA_LEN          ,                    // 保存的下行字节长度输出


        input wire                                 S_AXI_ACLK,                                  // 对应接口时钟，使用域由连接关系确定

        input wire                                 S_AXI_ARESETN,                               // 业务AXI低有效复位

        input wire    [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_AWADDR,                                // 写突发起始字节地址


        input wire    [2 : 0]                      S_AXI_AWPROT,                                // 写地址通道prot属性


        input wire                                 S_AXI_AWVALID,                               // 写地址通道有效，保持到ready接受


        output wire                                S_AXI_AWREADY,                               // 写地址通道当前可接受

        input wire    [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_WDATA,                                 // 写数据当前数据


        input wire    [(C_S_AXI_DATA_WIDTH/8)-1 : 0]S_AXI_WSTRB,                                // 写数据逐字节使能，尾字仅低4位


        input wire                                 S_AXI_WVALID,                                // 写数据通道有效，保持到ready接受


        output wire                                S_AXI_WREADY,                                // 写数据通道当前可接受


        output wire   [1 : 0]                      S_AXI_BRESP,                                 // 写响应响应码，0为OKAY、2为SLVERR


        output wire                                S_AXI_BVALID,                                // 写响应通道有效，保持到ready接受


        input wire                                 S_AXI_BREADY,                                // 写响应通道当前可接受

        input wire    [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_ARADDR,                                // 读突发起始字节地址


        input wire    [2 : 0]                      S_AXI_ARPROT,                                // 读地址通道prot属性


        input wire                                 S_AXI_ARVALID,                               // 读地址通道有效，保持到ready接受


        output wire                                S_AXI_ARREADY,                               // 读地址通道当前可接受

        output wire   [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_RDATA,                                 // 读数据当前数据


        output wire   [1 : 0]                      S_AXI_RRESP,                                 // 读数据响应码，0为OKAY、2为SLVERR


        output wire                                S_AXI_RVALID,                                // 读数据通道有效，保持到ready接受


        input wire                                 S_AXI_RREADY                                 // 读数据通道当前可接受
    );


    reg           [C_S_AXI_ADDR_WIDTH-1 : 0]   axi_awaddr                                ;    // 写突发起始字节地址
    reg                                        axi_awready                               ;    // 写地址通道当前可接受
    reg                                        axi_wready                                ;    // 写数据通道当前可接受
    reg           [1 : 0]                      axi_bresp                                 ;    // 写响应响应码，0为OKAY、2为SLVERR
    reg                                        axi_bvalid                                ;    // 写响应通道有效，保持到ready接受
    reg           [C_S_AXI_ADDR_WIDTH-1 : 0]   axi_araddr                                ;    // 读突发起始字节地址
    reg                                        axi_arready                               ;    // 读地址通道当前可接受
    reg           [C_S_AXI_DATA_WIDTH-1 : 0]   axi_rdata                                 ;    // 读数据当前数据
    reg           [1 : 0]                      axi_rresp                                 ;    // 读数据响应码，0为OKAY、2为SLVERR
    reg                                        axi_rvalid                                ;    // 读数据通道有效，保持到ready接受


    localparam integer                             ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;    // 本模块ADDR_LSB固定配置/状态编码
    localparam integer                             OPT_MEM_ADDR_BITS = 14                ;    // 本模块OPT_MEM_ADDR_BITS固定配置/状态编码


    reg           [0 : 0]                      INT_STATE_R                               ;    // 读取0x10形成的单拍清通知

    reg                                        CLEAR_INTER_R                             ;    // 读取0x10形成的单拍清相关错误
    reg           [C_S_AXI_DATA_WIDTH-1 : 0]   CPU_WR_DONE                               ;    // 下行命令忙状态，结束事件清零
    reg           [C_S_AXI_DATA_WIDTH-1 : 0]   CPU_REC_STATE                             ;    // 写1形成的单拍CPU读完确认
    reg           [C_S_AXI_DATA_WIDTH-1 : 0]   CPU_FPGA_START_ADDR                       ;    // 软件配置的下行DDR起始字节地址
    reg           [C_S_AXI_DATA_WIDTH-1 : 0]   CPU_FPGA_LEN                              ;    // 软件配置的下行字节长度

    wire                                       slv_reg_rden                              ;    // 本次AXI-Lite读可以保存返回数据
    wire                                       slv_reg_wren                              ;    // 本次AXI-Lite写已满足地址和数据接受条件
    reg           [C_S_AXI_DATA_WIDTH-1:0]     reg_data_out                              ;    // 按保存地址译码的寄存器读值
    integer                                    byte_index                                ;    // 按WSTRB逐字节操作的循环索引
    reg                                        aw_en                                     ;    // 当前是否允许接受下一次寄存器写


    assign S_AXI_AWREADY= axi_awready                                                    ;    // 写地址通道当前可接受

    assign S_AXI_WREADY = axi_wready                                                     ;    // 写数据通道当前可接受

    assign S_AXI_BRESP  = axi_bresp                                                      ;    // 写响应响应码，0为OKAY、2为SLVERR

    assign S_AXI_BVALID = axi_bvalid                                                     ;    // 写响应通道有效，保持到ready接受

    assign S_AXI_ARREADY= axi_arready                                                    ;    // 读地址通道当前可接受

    assign S_AXI_RDATA  = axi_rdata                                                      ;    // 读数据当前数据

    assign S_AXI_RRESP  = axi_rresp                                                      ;    // 读数据响应码，0为OKAY、2为SLVERR

    assign S_AXI_RVALID = axi_rvalid                                                     ;    // 读数据通道有效，保持到ready接受


    // AW和W同时有效且允许新写时给一次地址接受；等待B完成后才重新开放写入口。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_awready
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0 ;
        end else begin
            if (~ axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1 ;
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_awready <= 1'b0 ;
                end else begin
                    axi_awready <= 1'b0 ;
                end
            end
        end
    end


    // 保存写入口许可：接受本次AW/W后关闭，B被软件接受后重新开放。
    always @ ( posedge S_AXI_ACLK ) begin : update_aw_en
        if (S_AXI_ARESETN == 1'b0) begin
            aw_en <= 1'b1 ;
        end else begin
            if (~ axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                aw_en <= 1'b0 ;
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    aw_en <= 1'b1 ;
                end
            end
        end
    end


    // 写请求接受时锁存AW地址，后续软件改变AWADDR不影响这次寄存器选择。
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_awaddr <= 0;
        end
      else
        begin
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin

              axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end


    // AW/W同时有效且入口开放时给一次W接受；其余周期撤销，避免重复写。
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_wready <= 1'b0;
        end
      else
        begin
          if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
            begin


              axi_wready <= 1'b1;
            end
          else
            begin
              axi_wready <= 1'b0;
            end
        end
    end


    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID     ;    // 本次AXI-Lite写已满足地址和数据接受条件


    // 有效写0x14、byte0使能且bit0为1时生成单拍读完确认，下一拍自动回0。
    always @(posedge S_AXI_ACLK) begin : update_CPU_REC_STATE
        if (!S_AXI_ARESETN)
            CPU_REC_STATE <= 32'd0;
        else
            CPU_REC_STATE <= (slv_reg_wren && axi_awaddr[15:0]==16'h0014 &&
             S_AXI_WSTRB[0] && S_AXI_WDATA[0]) ? 32'd1 : 32'd0;
    end


    // 0x20接受一次启动并保持忙；结束事件优先清忙，忙期间重复启动不产生新任务。
    always @(posedge S_AXI_ACLK) begin : update_CPU_WR_DONE
        if (!S_AXI_ARESETN)
            CPU_WR_DONE <= 32'd0;
        else if (CPU_WR_DONE_EVENT)
            CPU_WR_DONE <= 32'd0;
        else if (!CPU_WR_DONE[0] && slv_reg_wren && axi_awaddr[15:0]==16'h0020 &&
                 S_AXI_WSTRB[0] && S_AXI_WDATA[0])
                     CPU_WR_DONE <= 32'd1;
    end

    integer                                    byte_index_CPU_FPGA_START_ADDR            ;    // 按写字节使能更新起始地址的循环索引


    // 仅空闲时按WSTRB更新0x24下行地址，复位为0x8000；忙时保持。
    always @ ( posedge S_AXI_ACLK ) begin : update_CPU_FPGA_START_ADDR
        if (S_AXI_ARESETN == 1'b0) begin
            CPU_FPGA_START_ADDR <= 32'd32 * 1024 ;
        end else begin
            if (slv_reg_wren && !CPU_WR_DONE[0]) begin
                case (axi_awaddr [ 15 : 0 ])
                    16'h0014: begin
                    end
                    16'h0020: begin
                    end
                    16'h0024: begin
                        for (byte_index_CPU_FPGA_START_ADDR = 0; byte_index_CPU_FPGA_START_ADDR <= ( C_S_AXI_DATA_WIDTH / 8 ) - 1; byte_index_CPU_FPGA_START_ADDR = byte_index_CPU_FPGA_START_ADDR + 1) begin
                            if (S_AXI_WSTRB [ byte_index_CPU_FPGA_START_ADDR ] == 1) begin
                                CPU_FPGA_START_ADDR [ ( byte_index_CPU_FPGA_START_ADDR * 8 ) +: 8 ] <= S_AXI_WDATA [ ( byte_index_CPU_FPGA_START_ADDR * 8 ) +: 8 ] ;
                            end
                        end
                    end
                    16'h0028: begin
                    end
                    default: begin
                        CPU_FPGA_START_ADDR <= CPU_FPGA_START_ADDR ;
                    end
                endcase
            end
        end
    end

    integer                                    byte_index_CPU_FPGA_LEN                   ;    // 按写字节使能更新长度的循环索引


    // 仅空闲时按WSTRB更新0x28长度，复位为32KiB；忙时保持。
    always @ ( posedge S_AXI_ACLK ) begin : update_CPU_FPGA_LEN
        if (S_AXI_ARESETN == 1'b0) begin
            CPU_FPGA_LEN <= 32'd32 * 1024 ;
        end else begin
            if (slv_reg_wren && !CPU_WR_DONE[0]) begin
                case (axi_awaddr [ 15 : 0 ])
                    16'h0014: begin
                    end
                    16'h0020: begin
                    end
                    16'h0024: begin
                    end
                    16'h0028: begin
                        for (byte_index_CPU_FPGA_LEN = 0; byte_index_CPU_FPGA_LEN <= ( C_S_AXI_DATA_WIDTH / 8 ) - 1; byte_index_CPU_FPGA_LEN = byte_index_CPU_FPGA_LEN + 1) begin
                            if (S_AXI_WSTRB [ byte_index_CPU_FPGA_LEN ] == 1) begin
                                CPU_FPGA_LEN [ ( byte_index_CPU_FPGA_LEN * 8 ) +: 8 ] <= S_AXI_WDATA [ ( byte_index_CPU_FPGA_LEN * 8 ) +: 8 ] ;
                            end
                        end
                    end
                    default: begin
                        CPU_FPGA_LEN <= CPU_FPGA_LEN ;
                    end
                endcase
            end
        end
    end


    // 本次AW/W接受后保持BVALID，直到BREADY接受；复位撤销。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_bvalid
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0 ;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~ axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1 ;
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0 ;
                end
            end
        end
    end


    // 寄存器写响应固定OKAY，B响应形成时更新为0。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_bresp
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bresp <= 2'b0 ;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~ axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bresp <= 2'b0 ;
            end
        end
    end


    // AR有效时给一个接受脉冲，下一周期撤销。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_arready
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0 ;
        end else begin
            if (~ axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1 ;
            end else begin
                axi_arready <= 1'b0 ;
            end
        end
    end


    // AR接受时保存读地址，供后续译码和数据返回使用。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_araddr
        if (S_AXI_ARESETN == 1'b0) begin
            axi_araddr <= 32'b0 ;
        end else begin
            if (~ axi_arready && S_AXI_ARVALID) begin
                axi_araddr <= S_AXI_ARADDR ;
            end
        end
    end


    // 读请求被接受后保持RVALID，直到软件RREADY接受。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_rvalid
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0 ;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~ axi_rvalid) begin
                axi_rvalid <= 1'b1 ;
            end else begin
                if (axi_rvalid && S_AXI_RREADY) begin
                    axi_rvalid <= 1'b0 ;
                end
            end
        end
    end


    // 寄存器读响应固定OKAY，复位和读响应形成时置0。
    always @ ( posedge S_AXI_ACLK ) begin : update_axi_rresp
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rresp <= 0 ;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~ axi_rvalid) begin
                axi_rresp <= 2'b0 ;
            end
        end
    end


    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid                      ;    // 本次AXI-Lite读可以保存返回数据


    // 按已保存的低16bit读地址选择版本、命令和状态；未定义偏移返回0。
    always @(*)
    begin


          case ( axi_araddr[15:0] )
            16'h0000    : reg_data_out  = VERSION               ;
            16'h0004    : reg_data_out  = PROG_TIME         ;
            16'h0008    : reg_data_out  = CH_BUF_LEN            ;
            16'h000C    : reg_data_out  = FPGA_TEMP_W           ;

            16'h0010    : reg_data_out  = INT_STATE_W           ;
            16'h0014 : reg_data_out = CPU_REC_STATE     ;
            16'h0018    : reg_data_out  = FPGA_CPU_START_ADDR   ;
            16'h001C    : reg_data_out  = FPGA_CPU_LEN          ;

            16'h0020 : reg_data_out = CPU_WR_DONE       ;
            16'h0024    : reg_data_out  = CPU_FPGA_START_ADDR   ;
            16'h0028    : reg_data_out  = CPU_FPGA_LEN          ;
            16'h002C    : reg_data_out  = DDR_STATUS_W          ;
            16'h0030: reg_data_out = RX_READY_BLOCKS;
            16'h0034: reg_data_out = RX_HEAD_SEQ;
            16'h0038: reg_data_out = RX_DROPPED_FRAMES;


            default : reg_data_out = 0;
          endcase
    end


    // 读请求有效时把译码结果保存到AXI返回寄存器，未产生新读时保持。
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_rdata  <= 0;
        end
      else
        begin


          if (slv_reg_rden)
            begin
              axi_rdata <= reg_data_out;
            end
        end
    end


    // 真实AR握手读取0x10时给单拍清通知，不释放待读数据块。
    always @ ( posedge S_AXI_ACLK ) begin : update_INT_STATE_R
        if (S_AXI_ARESETN == 1'b0) begin
            INT_STATE_R <= 1'b0 ;
        end else begin
            if (S_AXI_ARREADY && S_AXI_ARVALID && ( S_AXI_ARADDR [ 15 : 0 ] == 16'h0010 )) begin
                INT_STATE_R <= 1'b1 ;
            end else begin
                INT_STATE_R <= 1'b0 ;
            end
        end
    end


    // 读取0x10时给单拍清相关错误请求；与CPU读完确认分别处理。
    always @ ( posedge S_AXI_ACLK ) begin : update_CLEAR_INTER_R
        if (S_AXI_ARESETN == 1'b0) begin
            CLEAR_INTER_R <= 1'b0 ;
        end else begin
            if (S_AXI_ARREADY && S_AXI_ARVALID && ( S_AXI_ARADDR [ 15 : 0 ] == 16'h0010 )) begin
                CLEAR_INTER_R <= 1'b1 ;
            end else begin
                CLEAR_INTER_R <= 1'b0 ;
            end
        end
    end


    reg                                        CPU_WR_DONE_d                             ;    // 上一拍下行命令忙位
    wire                                       CPU_WR_DONE_pos                           ;    // 下行忙位0到1的启动事件


    // 延迟保存0x20忙位，用0到1变化生成下行启动单拍。
    always @( posedge S_AXI_ACLK )
    begin
        if ( S_AXI_ARESETN == 1'b0 )
        begin
            CPU_WR_DONE_d   <= 1'b0;
        end
        else
        begin
            CPU_WR_DONE_d   <= CPU_WR_DONE[0];
        end
    end


    assign CPU_WR_DONE_pos = (CPU_WR_DONE[0] && (!CPU_WR_DONE_d)) ? 1'b1 : 1'b0          ;    // 下行忙位0到1的启动事件


    assign r_INT_STATE              = INT_STATE_R                                        ;    // 软件读0x10形成的清通知输出

    assign r_CLEAR_INTER            = CLEAR_INTER_R                                      ;    // 软件读0x10形成的清相关错误输出

    assign r_CPU_REC_STATE          = CPU_REC_STATE[0]                                   ;    // 软件写0x14形成的一拍读完确认

    assign r_RD_START               = CPU_WR_DONE_pos                                    ;    // 0x20忙位0到1形成的一拍下行启动

    assign r_CPU_FPGA_START_ADDR    = CPU_FPGA_START_ADDR                                ;    // 保存的下行起始DDR字节地址输出

    assign r_CPU_FPGA_LEN           = CPU_FPGA_LEN                                       ;    // 保存的下行字节长度输出


    endmodule
