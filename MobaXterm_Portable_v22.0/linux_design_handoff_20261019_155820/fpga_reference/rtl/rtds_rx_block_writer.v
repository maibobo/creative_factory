// 把连续接收拍的低32bit写入DDR：先到字在64bit低半，后到字在高半。
// 每次写一拍；收到无错误的最终写响应后才增加有效长度。奇数尾字仅使能低4字节。
// 250MHz下默认25000000拍为100ms；周期到期先完成剩余写入，再登记非空块为可读。
// 8块依次循环使用，CPU读完确认只释放最早待读块；读清通知不释放数据。
// 不能保存或写失败的字计入32bit饱和丢失计数，计数单位是字而非帧。
// 注释整理 2026-10-12：仅修改说明和排版，端口、表达式、状态条件及连接保持。

`timescale 1ns/1ps

// 模块参数与输入输出。
module RTDS_RX_BLOCK_WRITER #(
    parameter integer                             BLOCK_COUNT   = 8,                  // 循环使用的上行块数量
    parameter integer                             BLOCK_BYTES   = 262144,             // 每个上行块的字节容量
    parameter integer                             PERIOD_CYCLES = 25000000,           // 接收周期拍数，生产250MHz对应100ms
    parameter     [31:0]                       BASE_ADDR     = 32'h00100000           // 第一个上行块的DDR字节地址
) (
    input wire                                 clk,                                   // DDR/队列管理时钟 250MHz
    input wire                                 rst_n,                                 // 低有效全局复位输入
    input wire                                 enable,                                // 存储通路允许启动新帧；不取消已经接受的写事务
    input wire    [63:0]                       frame_data,                            // 未压缩接收拍，仅低32bit有业务意义
    input wire                                 frame_valid,                           // 当前数据拍有效，接受前保持
    output wire                                frame_ready,                           // 当前数据拍可被读取
    input wire                                 cpu_ack,                               // 控制域 CPU_REC_STATE 的0到1事件，一次只释放一个最早待处理块
    input wire                                 irq_clear,                             // 清通知；绝不释放块或改变最早待处理块内容
    output wire   [31:0]                       head_addr,                             // 最老完整块的DDR字节地址，CPU确认前保持
    output wire   [31:0]                       head_len,                              // 最早待处理块成功写入的有效字节数，0表示无块
    output wire   [31:0]                       head_seq,                              // 块完成顺序编号，空周期不递增
    output wire   [31:0]                       ready_blocks,                          // 完整待取块数，取值0~8
    output reg    [31:0]                       dropped_frames,                        // 累计32bit数据字丢失数；32bit饱和，复位清零
    output reg                                 irq,                                   // 最早可读块的中断通知，可由读取操作清除
    output wire   [7:0]                        fdma_wstrb,                            // 完整拍FF；计时周期末尾单字0F
    output wire   [63:0]                       fdma_waddr,                            // 当前冻结的64bit DDR字节地址
    output wire   [15:0]                       fdma_wsize,                            // 本事务64bit拍数，固定1
    output wire                                fdma_wareq,                            // 写请求，保持至busy接受
    input wire                                 fdma_wbusy,                            // FDMA已接收事务，包含B响应等待阶段
    output wire   [63:0]                       fdma_wdata,                            // 当前写拍数据，只有accept才前进
    output wire                                fdma_wvalid,                           // 源端有效，必须等待accept
    input wire                                 fdma_waccept,                          // 本拍实际写握手事件
    input wire                                 fdma_wdone,                            // 最终写响应完成事件；不能用最后数据拍替代
    input wire                                 fdma_werror,                           // 本事务有任一写错误；仅done时用于有效长度判定
    output wire   [3:0]                        dbg_state,                             // 当前写事务状态供调试观察
    // 修改点 2026-10-13：只增加观察输出，不改变计时、写事务和块登记规则。
    output wire debug_period_tick,                                                                      // 2026-10-13：只观察原周期事件
    output wire debug_block_committed                                                                   // 2026-10-13：只观察原成功块登记事件
);


    localparam integer                             INDEX_BITS = $clog2(BLOCK_COUNT) ;    // 由存储字数或块数计算的索引位宽


    localparam    [2:0]                        IDLE     = 3'd0                      ;    // 尚无正在进行的写事务
    localparam    [2:0]                        REQ      = 3'd1                      ;    // 等待FDMA接受写请求
    localparam    [2:0]                        DATA     = 3'd2                      ;    // 等待写数据握手
    localparam    [2:0]                        RESPONSE = 3'd3                      ;    // 等待最终写响应


    reg           [2:0]                        write_curr_st                        ;    // 当前写事务状态
    reg           [2:0]                        write_next_st                        ;    // 组合逻辑计算的下一写状态


    reg           [INDEX_BITS-1:0]             write_block                          ;    // 当前写入块编号
    reg           [INDEX_BITS-1:0]             read_block                           ;    // 最早可读且待CPU确认的块编号
    reg           [INDEX_BITS:0]               queued                               ;    // 完整待读块数量
    reg           [31:0]                       block_len [0:BLOCK_COUNT-1]          ;    // 各块成功写入字节长度表
    reg           [31:0]                       block_seq [0:BLOCK_COUNT-1]          ;    // 各块对应的完成顺序号表
    reg           [31:0]                       used_bytes                           ;    // 当前块已得到成功写响应的字节数
    reg           [31:0]                       publish_seq                          ;    // 下一个非空完成块使用的顺序号


    reg           [31:0]                       time_count                           ;    // 与写响应等待独立的接收周期计数
    reg                                        seal_pending                         ;    // 周期已结束，但尾字或写响应尚未处理完
    reg                                        half_valid                           ;    // 已有一个待配对的32bit字
    reg           [31:0]                       half_data                            ;    // 先到的低32bit字，配对时放写拍低半
    reg           [75:0]                       active_transfer                      ;    // 本次写拍的有效字节数、WSTRB和64bit数据


    wire                                       tick                                 ;    // 接收周期到期的单拍事件
    wire                                       take_word                            ;    // 输入valid和ready同拍成立，取得一字
    wire                                       reject_word                          ;    // 取得的字因未允许或无空间被舍弃
    wire                                       pair_start                           ;    // 已有半字时与新字组成完整写拍
    wire                                       tail_start                           ;    // 周期末把未配对单字组成0F尾拍
    wire                                       start_write                          ;    // 完整拍或尾拍需要发起写入
    wire                                       seal_done                            ;    // 周期所需写入和尾字已全部处理完


    wire                                       push_block                           ;    // 成功非空块登记为可读
    wire                                       pop_block                            ;    // CPU确认并释放最早可读块
    wire                                       write_success                        ;    // 最终done且无error的成功响应
    wire                                       write_failure                        ;    // 最终done且error的失败响应
    wire          [32:0]                       drop_sum                             ;    // 丢字33bit中间和，用于判断32bit饱和


    integer                                    len_index                            ;    // 复位清块长度表的循环索引
    integer                                    seq_index                            ;    // 复位清顺序号表的循环索引


    assign debug_period_tick = tick;           // 2026-10-13：测试源等原周期事件
    assign debug_block_committed = push_block;  // 2026-10-13：测试完成依据原真实块登记

    assign tick =
        (time_count == PERIOD_CYCLES-1)                                             ;    // 接收周期到期的单拍事件
    assign frame_ready =
        (write_curr_st == IDLE) && !seal_pending && !tick                           ;    // 当前数据拍可被读取
    assign take_word =
        frame_valid && frame_ready                                                  ;    // 输入valid和ready同拍成立，取得一字

    assign reject_word =
        take_word && (!enable || queued == BLOCK_COUNT || used_bytes >= BLOCK_BYTES);    // 取得的字因未允许或无空间被舍弃


    assign pair_start =
        take_word && !reject_word && half_valid                                     ;    // 已有半字时与新字组成完整写拍

    assign tail_start =
        (write_curr_st == IDLE) && seal_pending && half_valid                       ;    // 周期末把未配对单字组成0F尾拍
    assign start_write =
        pair_start || tail_start                                                    ;    // 完整拍或尾拍需要发起写入

    assign seal_done =
        (write_curr_st == IDLE) && seal_pending && !half_valid                      ;    // 周期所需写入和尾字已全部处理完


    assign push_block =
        seal_done && used_bytes != 32'd0                                            ;    // 成功非空块登记为可读

    assign pop_block =
        cpu_ack && queued != 0                                                      ;    // CPU确认并释放最早可读块

    assign write_success =
        write_curr_st == RESPONSE && fdma_wdone && !fdma_werror                     ;    // 最终done且无error的成功响应

    assign write_failure =
        write_curr_st == RESPONSE && fdma_wdone && fdma_werror                      ;    // 最终done且error的失败响应


    assign drop_sum = {1'b0,dropped_frames} + (reject_word ? 33'd1 :
                      write_failure ? {31'd0,active_transfer[75:74]} : 33'd0)       ;    // 丢字33bit中间和，用于判断32bit饱和


    assign ready_blocks =
        {{(31-INDEX_BITS){1'b0}},queued}                                            ;    // 完整待取块数，取值0~8

    assign head_addr =
        queued != 0 ? BASE_ADDR + read_block * BLOCK_BYTES : 32'd0                  ;    // 最老完整块的DDR字节地址，CPU确认前保持

    assign head_len =
        queued != 0 ? block_len[read_block] : 32'd0                                 ;    // 最早待处理块成功写入的有效字节数，0表示无块

    assign head_seq =
        queued != 0 ? block_seq[read_block] : 32'd0                                 ;    // 块完成顺序编号，空周期不递增


    assign fdma_waddr =
        {32'd0,BASE_ADDR} + write_block * BLOCK_BYTES + used_bytes                  ;    // 当前冻结的64bit DDR字节地址

    assign fdma_wsize =
        16'd1                                                                       ;    // 本事务64bit拍数，固定1

    assign fdma_wdata =
        active_transfer[63:0]                                                       ;    // 当前写拍数据，只有accept才前进

    assign fdma_wstrb =
        active_transfer[71:64]                                                      ;    // 完整拍FF；计时周期末尾单字0F

    assign fdma_wareq =
        write_curr_st == REQ                                                        ;    // 写请求，保持至busy接受

    assign fdma_wvalid =
        write_curr_st == DATA                                                       ;    // 源端有效，必须等待accept

    assign dbg_state =
        {1'b0,write_curr_st}                                                        ;    // 当前写事务状态供调试观察


    // 计算单拍写次态：请求被busy接受后给数据，数据accept后等最终done，响应结束才回空闲。
    always @(*) begin : calculate_write_next_st
        write_next_st = write_curr_st;
        case (write_curr_st)
            IDLE: if (start_write)
                write_next_st = REQ;
            REQ: if (fdma_wbusy)
                write_next_st = DATA;
            DATA: if (fdma_waccept)
                write_next_st = RESPONSE;
            RESPONSE: if (fdma_wdone)
                write_next_st = IDLE;
            default: write_next_st = IDLE;
        endcase
    end


    // 业务时钟沿保存写次态，低有效复位回IDLE。
    always @(posedge clk or negedge rst_n) begin : update_write_state
        if (!rst_n)
            write_curr_st <= IDLE;
        else
            write_curr_st <= write_next_st;
    end


    // 独立计接收周期，到PERIOD_CYCLES末拍归零，不因写响应延迟而停计时。
    always @(posedge clk or negedge rst_n) begin : update_time_count
        if (!rst_n)
            time_count <= 32'd0;
        else if (tick)
            time_count <= 32'd0;
        else
            time_count <= time_count + 32'd1;
    end


    // 周期到期置结束处理标志，直到剩余单字和全部写响应处理完才清除。
    always @(posedge clk or negedge rst_n) begin : update_seal_pending
        if (!rst_n)
            seal_pending <= 1'b0;
        else if (tick)
            seal_pending <= 1'b1;
        else if (seal_done)
            seal_pending <= 1'b0;
    end


    // 记录是否保存了一个待配对低32bit字；启动写拍后清标志，输入有效字时切换。
    always @(posedge clk or negedge rst_n) begin : update_half_valid
        if (!rst_n)
            half_valid <= 1'b0;
        else if (start_write)
            half_valid <= 1'b0;
        else if (take_word && !reject_word)
            half_valid <= 1'b1;
    end


    // 只在没有旧半字时保存新输入低32bit，供第二个字配对或周期末尾写入。
    always @(posedge clk or negedge rst_n) begin : update_half_data
        if (!rst_n)
            half_data <= 32'd0;
        else if (take_word && !reject_word && !half_valid)
            half_data <= frame_data[31:0];
    end


    // 开始写入时整体保存数据、WSTRB和有效字节数；双字为FF/8Byte，尾字为0F/4Byte。
    always @(posedge clk or negedge rst_n) begin : update_active_transfer
        if (!rst_n)
            active_transfer <= 76'd0;
        else if (pair_start)
            active_transfer <= {4'd8,8'hff,frame_data[31:0],half_data};
        else if (tail_start)
            active_transfer <= {4'd4,8'h0f,32'd0,half_data};
    end


    // 仅成功的最终响应增加有效字节数，块变可读后从0计下一块。
    always @(posedge clk or negedge rst_n) begin : update_used_bytes
        if (!rst_n)
            used_bytes <= 32'd0;
        else if (push_block)
            used_bytes <= 32'd0;
        else if (write_success)
            used_bytes <= used_bytes + {28'd0,active_transfer[75:72]};
    end


    // 非空块变可读后移动下一写块，利用有限位宽循环使用块编号。
    always @(posedge clk or negedge rst_n) begin : update_write_block
        if (!rst_n)
            write_block <= {INDEX_BITS{1'b0}};
        else if (push_block)
            write_block <= write_block + 1'b1;
    end


    // CPU确认现有可读块后移动最早待读块编号；读清通知不移动。
    always @(posedge clk or negedge rst_n) begin : update_read_block
        if (!rst_n)
            read_block <= {INDEX_BITS{1'b0}};
        else if (pop_block)
            read_block <= read_block + 1'b1;
    end


    // 按块变可读和CPU确认增减数量，两者同拍发生时数量不变。
    always @(posedge clk or negedge rst_n) begin : update_queued
        if (!rst_n)
            queued <= {(INDEX_BITS+1){1'b0}};
        else
            case ({push_block,pop_block})
            2'b10: queued <= queued + 1'b1;
            2'b01: queued <= queued - 1'b1;
            default: queued <= queued;
        endcase
    end


    // 每个非空块变可读后递增顺序号，空周期不占用编号。
    always @(posedge clk or negedge rst_n) begin : update_publish_seq
        if (!rst_n)
            publish_seq <= 32'd0;
        else if (push_block)
            publish_seq <= publish_seq + 32'd1;
    end


    // 块变可读时保存其成功写入长度，复位逐项清全部长度表。
    always @(posedge clk or negedge rst_n) begin : update_block_len
        if (!rst_n) begin
            for (len_index=0;len_index<BLOCK_COUNT;len_index=len_index+1) block_len[len_index]<=32'd0;
        end else if (push_block)
            block_len[write_block] <= used_bytes;
    end


    // 块变可读时保存其顺序编号，复位逐项清全部编号表。
    always @(posedge clk or negedge rst_n) begin : update_block_seq
        if (!rst_n) begin
            for (seq_index=0;seq_index<BLOCK_COUNT;seq_index=seq_index+1) block_seq[seq_index]<=32'd0;
        end else if (push_block)
            block_seq[write_block] <= publish_seq;
    end


    // 累加被拒绝或写失败的32bit字数，33bit中间和溢出时保持FFFFFFFF。
    always @(posedge clk or negedge rst_n) begin : update_dropped_words
        if (!rst_n)
            dropped_frames <= 32'd0;
        else
            dropped_frames <= drop_sum[32] ? 32'hffffffff : drop_sum[31:0];
    end


    // 从空变为有块时通知CPU；确认后依据剩余块保持通知，读清只清通知不释放块。
    always @(posedge clk or negedge rst_n) begin : update_irq
        if (!rst_n)
            irq <= 1'b0;
        else if (pop_block)
            irq <= (queued > 1) || push_block;
        else if (push_block && queued == 0)
            irq <= 1'b1;
        else if (irq_clear)
            irq <= 1'b0;
    end
endmodule
