`timescale 1ns/1ps
// 功能：在DDR时钟域读取接收数据，每拍使用输入的低32位有效字。
// 两个有效字组成一个64位FDMA写拍；周期末剩一个字时写低四字节有效的尾拍。
// 写事务必须等最终响应成功才增加块长度，失败的事务计入丢失字数。
// 非空块完成后保存地址、有效长度和顺序编号，供CPU读取；cpu_ack才移走该块。
// 周期计数独立于写响应延迟；收尾期间暂停接收新字并完成已有写入。
module RTDS_RX_BLOCK_WRITER #(
    parameter integer  BLOCK_COUNT   = 8,              // 循环使用的DDR数据块数量。
    parameter integer  BLOCK_BYTES   = 262144,         // 每个数据块的最大字节数。
    parameter integer  PERIOD_CYCLES = 25000000,       // 一次接收周期包含的DDR时钟拍数。
    parameter [31:0]   BASE_ADDR     = 32'h00100000    // 第一块数据在DDR中的字节地址。
) (
    input  wire          clk,               // DDR/队列管理时钟 250MHz
    input  wire          rst_n,             // 主机低有效逻辑复位；配置和统计的唯一全局清除入口
    input  wire          enable,            // 存储通路允许启动新帧；不取消已经接受的写事务
    input  wire [63:0]   frame_data,        // 未压缩接收拍，仅低32bit有业务意义
    input  wire          frame_valid,       // 当前数据拍有效，接受前保持
    output wire          frame_ready,       // 当前数据拍可被读取
    input  wire          cpu_ack,           // 控制域 CPU_REC_STATE 的0到1事件，一次只释放一个最早待处理块
    input  wire          irq_clear,         // 清通知；绝不释放块或改变最早待处理块内容
    output wire [31:0]   head_addr,         // 最老完整块的DDR字节地址，CPU确认前保持
    output wire [31:0]   head_len,          // 最早待处理块成功写入的有效字节数，0表示无块
    output wire [31:0]   head_seq,          // 块完成顺序编号，空周期不递增
    output wire [31:0]   ready_blocks,      // 完整待取块数，取值0~8
    output reg  [31:0]   dropped_frames,    // 累计32bit数据字丢失数；32bit饱和，复位清零
    output reg           irq,               // 最早可读块的中断通知，可由读取操作清除
    output wire [7:0]    fdma_wstrb,        // 完整拍FF；计时周期末尾单字0F
    output wire [63:0]   fdma_waddr,        // 当前冻结的64bit DDR字节地址
    output wire [15:0]   fdma_wsize,        // 本事务64bit拍数，固定1
    output wire          fdma_wareq,        // 写请求，保持至busy接受
    input  wire          fdma_wbusy,        // FDMA已接收事务，包含B响应等待阶段
    output wire [63:0]   fdma_wdata,        // 当前写拍数据，只有accept才前进
    output wire          fdma_wvalid,       // 源端有效，必须等待accept
    input  wire          fdma_waccept,      // 本拍实际写握手事件
    input  wire          fdma_wdone,        // 最终写响应完成事件；不能用最后数据拍替代
    input  wire          fdma_werror,       // 本事务有任一写错误；仅done时用于有效长度判定
    output wire [3:0]    dbg_state          // 写事务状态，观察其原生时钟域
);

    // 块指针位宽由块数决定。
    localparam integer INDEX_BITS = $clog2(BLOCK_COUNT);

    // 状态机编码。
    localparam [2:0] IDLE     = 3'd0;    // 尚无正在进行的写事务。
    localparam [2:0] REQ      = 3'd1;    // 等待FDMA接受写请求。
    localparam [2:0] DATA     = 3'd2;    // 等待写数据握手。
    localparam [2:0] RESPONSE = 3'd3;    // 等待最终写响应。

    // 写事务状态。
    reg     [2:0]  write_curr_st                                                                     ;    // 当前FDMA写事务状态。
    reg     [2:0]  write_next_st                                                                     ;    // 组合逻辑计算的下一写状态。

    // 块位置和元数据。
    reg     [INDEX_BITS-1:0]  write_block                                                            ;    // 当前写入的数据块编号。
    reg     [INDEX_BITS-1:0]  read_block                                                             ;    // 最早可读数据块编号。
    reg     [INDEX_BITS:0]    queued                                                                 ;    // 已经完成且等待CPU确认的块数。
    reg     [31:0]            block_len [0:BLOCK_COUNT-1]                                            ;    // 每个块成功写入的有效字节数。
    reg     [31:0]            block_seq [0:BLOCK_COUNT-1]                                            ;    // 每个块对应的完成顺序编号。
    reg     [31:0]            used_bytes                                                             ;    // 当前块已得到成功响应的字节数。
    reg     [31:0]            publish_seq                                                            ;    // 下一个非空块使用的顺序编号。

    // 周期收尾与数据拼接。
    reg     [31:0]  time_count                                                                       ;    // 与写响应无关的周期计数。
    reg             seal_pending                                                                     ;    // 周期已结束但剩余写入尚未完成。
    reg             half_valid                                                                       ;    // 已有一个待配对的32位字。
    reg     [31:0]  half_data                                                                        ;    // 等待配对或作为尾拍写入的32位字。
    reg     [75:0]  active_transfer                                                                  ;    // 当前事务的字节数、字节使能和数据。

    // 输入接收和写入条件。
    wire      tick                                                                                   ;    // 周期计数到末尾的事件。
    wire      take_word                                                                              ;    // 本拍已经读取一个输入数据字。
    wire      reject_word                                                                            ;    // 输入字因未使能或空间不足被舍弃。
    wire      pair_start                                                                             ;    // 两个32位字组成完整写拍。
    wire      tail_start                                                                             ;    // 剩余单字组成低四字节有效的尾拍。
    wire      start_write                                                                            ;    // 完整拍或尾拍启动写事务。
    wire      seal_done                                                                              ;    // 当前周期所需写入全部处理完毕。

    // 块状态和写响应条件。
    wire            push_block                                                                       ;    // 非空块完成并变为可读。
    wire            pop_block                                                                        ;    // CPU确认已有可读块。
    wire            write_success                                                                    ;    // 最终写响应成功。
    wire            write_failure                                                                    ;    // 最终写响应失败。
    wire    [32:0]  drop_sum                                                                         ;    // 丢失字数的33位中间计算值。

    // 块表复位循环变量。
    integer   len_index;    // 复位时逐项清除块长度。
    integer   seq_index;    // 复位时逐项清除块编号。


    // 输入接收及写事务启动条件。

    // 周期和输入判断。
    assign tick = (time_count == PERIOD_CYCLES-1)                                                    ;    // 计数到设定周期末尾时产生单拍事件。
    assign frame_ready = (write_curr_st == IDLE) && !seal_pending && !tick                           ;    // 仅在写状态空闲且当前周期无需收尾时接收新字。
    assign take_word = frame_valid && frame_ready                                                    ;    // 输入有效且本模块允许接收时记录一个数据字。
    assign reject_word = take_word && (!enable || queued == BLOCK_COUNT || used_bytes >= BLOCK_BYTES);    // 未使能或无可用空间时舍弃当前数据字。

    // 完整拍与尾拍启动。
    assign pair_start = take_word && !reject_word && half_valid                                      ;    // 缓存中已有一个字时把新字组成完整写拍。
    assign tail_start = (write_curr_st == IDLE) && seal_pending && half_valid                        ;    // 周期收尾时把剩余单字组成四字节写拍。
    assign start_write = pair_start || tail_start                                                    ;    // 完整写拍或单字尾拍均可启动写事务。
    assign seal_done = (write_curr_st == IDLE) && seal_pending && !half_valid                        ;    // 写状态空闲且无剩余单字时完成本周期收尾。


    // 块完成、写响应和计数条件。

    // 写响应与块状态。
    assign push_block = seal_done && used_bytes != 32'd0                                             ;    // 本周期收尾且已有成功写入数据时标记当前块可读。
    assign pop_block = cpu_ack && queued != 0                                                        ;    // CPU确认且已有可读块时移走最早的块。
    assign write_success = write_curr_st == RESPONSE && fdma_wdone && !fdma_werror                   ;    // 收到无错误的最终写响应后确认本次写入。
    assign write_failure = write_curr_st == RESPONSE && fdma_wdone && fdma_werror                    ;    // 收到错误的最终写响应后统计本次丢失。

    // 丢失计数中间值。
    assign drop_sum = {1'b0,dropped_frames} + (reject_word ? 33'd1 :
                      write_failure ? {31'd0,active_transfer[75:74]} : 33'd0)                        ;    // 用33位中间值累加新丢失的数据字以判断溢出。


    // CPU读取的块信息。

    // 可读状态。
    assign ready_blocks = {{(31-INDEX_BITS){1'b0}},queued}                                           ;    // 把可读块计数扩展为32位状态值。
    assign head_addr = queued != 0 ? BASE_ADDR + read_block * BLOCK_BYTES : 32'd0                    ;    // 返回最早可读块的DDR地址，空时返回零。
    assign head_len = queued != 0 ? block_len[read_block] : 32'd0                                    ;    // 返回最早可读块的有效字节数，空时返回零。
    assign head_seq = queued != 0 ? block_seq[read_block] : 32'd0                                    ;    // 返回最早可读块的顺序编号，空时返回零。


    // FDMA写接口输出。

    // 写地址、数据及状态。
    assign fdma_waddr = {32'd0,BASE_ADDR} + write_block * BLOCK_BYTES + used_bytes                   ;    // 以块基址和已确认字节数确定下次写地址。
    assign fdma_wsize = 16'd1                                                                        ;    // 每次FDMA事务固定写入一个64位数据拍。
    assign fdma_wdata = active_transfer[63:0]                                                        ;    // 将已锁定事务中的数据送往FDMA。
    assign fdma_wstrb = active_transfer[71:64]                                                       ;    // 将已锁定事务中的字节使能送往FDMA。
    assign fdma_wareq = write_curr_st == REQ                                                         ;    // 请求状态持续发出FDMA写请求。
    assign fdma_wvalid = write_curr_st == DATA                                                       ;    // 数据状态持续提供有效写拍。
    assign dbg_state = {1'b0,write_curr_st}                                                          ;    // 扩展当前写状态供调试读取。


    // 写事务状态控制。
    // 根据请求接受、数据握手及最终响应计算写次态。
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

    // 在DDR时钟沿锁定写次态。
    always @(posedge clk or negedge rst_n) begin : update_write_state
        if (!rst_n)
            write_curr_st <= IDLE;
        else
            write_curr_st <= write_next_st;
    end


    // 接收周期与剩余单字处理。
    // 独立于写事务持续计算接收周期。
    always @(posedge clk or negedge rst_n) begin : update_time_count
        if (!rst_n)
            time_count <= 32'd0;
        else if (tick)
            time_count <= 32'd0;
        else
            time_count <= time_count + 32'd1;
    end

    // 保存周期结束状态，直到剩余写入处理完。
    always @(posedge clk or negedge rst_n) begin : update_seal_pending
        if (!rst_n)
            seal_pending <= 1'b0;
        else if (tick)
            seal_pending <= 1'b1;
        else if (seal_done)
            seal_pending <= 1'b0;
    end

    // 记录是否已有一个待配对的32位字。
    always @(posedge clk or negedge rst_n) begin : update_half_valid
        if (!rst_n)
            half_valid <= 1'b0;
        else if (start_write)
            half_valid <= 1'b0;
        else if (take_word && !reject_word)
            half_valid <= 1'b1;
    end

    // 保存待配对的32位字。
    always @(posedge clk or negedge rst_n) begin : update_half_data
        if (!rst_n)
            half_data <= 32'd0;
        else if (take_word && !reject_word && !half_valid)
            half_data <= frame_data[31:0];
    end

    // 启动写入时锁定数据、有效字节数和字节使能。
    always @(posedge clk or negedge rst_n) begin : update_active_transfer
        if (!rst_n)
            active_transfer <= 76'd0;
        else if (pair_start)
            active_transfer <= {4'd8,8'hff,frame_data[31:0],half_data};
        else if (tail_start)
            active_transfer <= {4'd4,8'h0f,32'd0,half_data};
    end


    // 块地址、长度和顺序编号维护。
    // 最终写响应成功后增加当前块有效长度。
    always @(posedge clk or negedge rst_n) begin : update_used_bytes
        if (!rst_n)
            used_bytes <= 32'd0;
        else if (push_block)
            used_bytes <= 32'd0;
        else if (write_success)
            used_bytes <= used_bytes + {28'd0,active_transfer[75:72]};
    end

    // 非空块完成后移动写块编号。
    always @(posedge clk or negedge rst_n) begin : update_write_block
        if (!rst_n)
            write_block <= {INDEX_BITS{1'b0}};
        else if (push_block)
            write_block <= write_block + 1'b1;
    end

    // CPU确认后移动最早可读块编号。
    always @(posedge clk or negedge rst_n) begin : update_read_block
        if (!rst_n)
            read_block <= {INDEX_BITS{1'b0}};
        else if (pop_block)
            read_block <= read_block + 1'b1;
    end

    // 按块完成和CPU确认维护可读块数量。
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

    // 每完成一个非空块便增加顺序编号。
    always @(posedge clk or negedge rst_n) begin : update_publish_seq
        if (!rst_n)
            publish_seq <= 32'd0;
        else if (push_block)
            publish_seq <= publish_seq + 32'd1;
    end

    // 块完成时保存其实际有效长度。
    always @(posedge clk or negedge rst_n) begin : update_block_len
        if (!rst_n) begin
            for (len_index=0;len_index<BLOCK_COUNT;len_index=len_index+1) block_len[len_index]<=32'd0;
        end else if (push_block)
            block_len[write_block] <= used_bytes;
    end

    // 块完成时保存其顺序编号。
    always @(posedge clk or negedge rst_n) begin : update_block_seq
        if (!rst_n) begin
            for (seq_index=0;seq_index<BLOCK_COUNT;seq_index=seq_index+1) block_seq[seq_index]<=32'd0;
        end else if (push_block)
            block_seq[write_block] <= publish_seq;
    end


    // 丢失统计与CPU中断。
    // 累加丢失的数据字并在最大值处保持。
    always @(posedge clk or negedge rst_n) begin : update_dropped_words
        if (!rst_n)
            dropped_frames <= 32'd0;
        else
            dropped_frames <= drop_sum[32] ? 32'hffffffff : drop_sum[31:0];
    end

    // 按新块、CPU确认和清除请求更新中断。
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
