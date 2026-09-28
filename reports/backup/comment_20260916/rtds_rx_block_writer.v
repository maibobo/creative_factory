`timescale 1ns/1ps
// 单写者、单消费者的固定块队列。两个32bit有效字合成一个64bit写请求。
// 入队以成功写响应为依据；INT读清不释放块，CPU确认才释放队头。
module RTDS_RX_BLOCK_WRITER #(
    parameter integer BLOCK_COUNT = 8,
    parameter integer BLOCK_BYTES = 262144,
    parameter integer PERIOD_CYCLES = 25000000,
    parameter [31:0] BASE_ADDR = 32'h00100000
) (
    input wire clk, // DDR/队列管理时钟 250MHz
    input wire rst_n, // 主机低有效逻辑复位；配置和统计的唯一全局清除入口
    input wire enable, // 存储通路允许启动新帧；不取消已经接受的写事务
    input wire [63:0] frame_data, // 未压缩接收拍，仅低32bit有业务意义
    input wire frame_valid, // 完整帧有效，接受前数据保持
    output wire frame_ready, // 本拍可接受或明确丢弃整帧
    input wire cpu_ack, // 控制域 CPU_REC_STATE 的0到1事件，一次只释放一个队头
    input wire irq_clear, // 清通知；绝不释放块或改变队头内容
    output wire [31:0] head_addr, // 最老完整块的DDR字节地址，CPU确认前保持
    output wire [31:0] head_len, // 队头成功写入的有效字节数，0表示无块
    output wire [31:0] head_seq, // 非空块发布序号，空窗口不递增
    output wire [31:0] ready_blocks, // 完整待取块数，取值0~8
    output reg [31:0] dropped_frames, // 累计32bit数据字丢失数；32bit饱和，复位清零
    output reg irq, // 队头可读通知，读清后等待ACK或新队头
    output wire [7:0] fdma_wstrb, // 完整拍FF；窗口末尾单字0F
    output wire [63:0] fdma_waddr, // 当前冻结的64bit DDR字节地址
    output wire [15:0] fdma_wsize, // 本事务64bit拍数，固定1
    output wire fdma_wareq, // 写请求，保持至busy接受
    input wire fdma_wbusy, // FDMA已接收事务，包含B响应等待阶段
    output wire [63:0] fdma_wdata, // 当前写拍数据，只有accept才前进
    output wire fdma_wvalid, // 源端有效，必须等待accept
    input wire fdma_waccept, // 本拍实际写握手事件
    input wire fdma_wdone, // 最终写响应完成事件；不能用最后数据拍替代
    input wire fdma_werror, // 本事务有任一写错误；仅done时用于有效长度判定
    output wire [3:0] dbg_state // 写事务状态，观察其原生时钟域
);
    localparam integer INDEX_BITS = $clog2(BLOCK_COUNT);
    localparam [2:0] IDLE=3'd0, REQ=3'd1, DATA=3'd2, RESPONSE=3'd3;
    reg [2:0] write_curr_st, write_next_st;
    reg [INDEX_BITS-1:0] write_block, read_block;
    reg [INDEX_BITS:0] queued;
    reg [31:0] block_len [0:BLOCK_COUNT-1];
    reg [31:0] block_seq [0:BLOCK_COUNT-1];
    reg [31:0] used_bytes, time_count, publish_seq;
    reg seal_pending;
    reg half_valid;
    reg [31:0] half_data;
    // 一个事务描述向量共同锁存数据、字节使能和长度，在B响应前整体保持。
    reg [75:0] active_transfer; // [75:72]字节数，[71:64]WSTRB，[63:0]数据
    wire tick, take_word, reject_word, pair_start, tail_start, start_write;
    wire seal_done, push_block, pop_block, write_success, write_failure;
    wire [32:0] drop_sum;
    integer len_index, seq_index;
    // DDR域窗口结束事件；窗口内积压按实际写入时段归属。
    assign tick = (time_count == PERIOD_CYCLES-1);
    // 只在写状态空闲且未封存时取新字；封存边界不再追加。
    assign frame_ready = (write_curr_st == IDLE) && !seal_pending && !tick;
    // 本次接收拍已被DDR域消费，低32bit贡献一个有效字。
    assign take_word = frame_valid && frame_ready;
    // 未使能、八块全满或当前块满时丢弃新字，禁止覆盖未读数据。
    assign reject_word = take_word && (!enable || queued == BLOCK_COUNT || used_bytes >= BLOCK_BYTES);
    // 已有半拍且新字可接收时，将两个低32bit紧凑拼成64bit写拍。
    assign pair_start = take_word && !reject_word && half_valid;
    // 窗口封存时将独立剩余字写为低4Byte有效的尾拍。
    assign tail_start = (write_curr_st == IDLE) && seal_pending && half_valid;
    // 完整双字写拍或封存单字尾拍共同触发一次写事务。
    assign start_write = pair_start || tail_start;
    // 全部在途写事务及半拍已处理，才允许结束当前窗口。
    assign seal_done = (write_curr_st == IDLE) && seal_pending && !half_valid;
    // 只发布已有成功提交字节的非空块，空窗口不通知CPU。
    assign push_block = seal_done && used_bytes != 32'd0;
    // 只确认当前已有队头，空队列确认不能释放同拍新发布块。
    assign pop_block = cpu_ack && queued != 0;
    // 以成功写响应为提交点，不能在W末拍握手时提前发布。
    assign write_success = write_curr_st == RESPONSE && fdma_wdone && !fdma_werror;
    // 错误写响应计为数据字丢失，已提交长度保持。
    assign write_failure = write_curr_st == RESPONSE && fdma_wdone && fdma_werror;
    // 使用33bit中间和检测溢出，统计单位为32bit有效字。
    assign drop_sum = {1'b0,dropped_frames} + (reject_word ? 33'd1 :
                      write_failure ? {31'd0,active_transfer[75:74]} : 33'd0);
    // 将完整待取块数扩展为CPU可读32bit寄存器值。
    assign ready_blocks = {{(31-INDEX_BITS){1'b0}},queued};
    // 队头地址在CPU确认前保持；空队列返回0。
    assign head_addr = queued != 0 ? BASE_ADDR + read_block * BLOCK_BYTES : 32'd0;
    // 仅报告队头成功提交的有效字节数，尾拍按4Byte计。
    assign head_len = queued != 0 ? block_len[read_block] : 32'd0;
    // CPU读取当前队头发布序号，确认后切换至下一块。
    assign head_seq = queued != 0 ? block_seq[read_block] : 32'd0;
    // 上行地址由块基址与已成功提交长度构成，失败后不留下空洞。
    assign fdma_waddr = {32'd0,BASE_ADDR} + write_block * BLOCK_BYTES + used_bytes;
    // 上行压缩器每次提交一个64bit AXI写拍。
    assign fdma_wsize = 16'd1;
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign fdma_wdata = active_transfer[63:0];
    // 贯通有效字节掩码；双字FF，独立尾字0F。
    assign fdma_wstrb = active_transfer[71:64];
    // 组合接口映射；对应模块的状态机负责更新源寄存器及事务边界。
    assign fdma_wareq = write_curr_st == REQ;
    // 组合握手条件供本时钟域推进事务；未满足条件时保持当前传输。
    assign fdma_wvalid = write_curr_st == DATA;
    // 只提供调试或未使用接口观察，不参与业务数据提交。
    assign dbg_state = {1'b0,write_curr_st};

    // 两段式写状态机：W握手结束仅进入等待，最终B响应才提交数据。

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

    always @(posedge clk or negedge rst_n) begin : update_write_state
        if (!rst_n)
            write_curr_st <= IDLE;
        else
            write_curr_st <= write_next_st;
    end
    // 定时器不因写响应延迟而漂移；多个延期边界合并，不发布空占位块。

    always @(posedge clk or negedge rst_n) begin : update_time_count
        if (!rst_n)
            time_count <= 32'd0;
        else if (tick)
            time_count <= 32'd0;
        else
            time_count <= time_count + 32'd1;
    end

    always @(posedge clk or negedge rst_n) begin : update_seal_pending
        if (!rst_n)
            seal_pending <= 1'b0;
        else if (tick)
            seal_pending <= 1'b1;
        else if (seal_done)
            seal_pending <= 1'b0;
    end
    // 半拍只保存先到的数据字；边界时转成低四字节有效的尾拍。

    always @(posedge clk or negedge rst_n) begin : update_half_valid
        if (!rst_n)
            half_valid <= 1'b0;
        else if (start_write)
            half_valid <= 1'b0;
        else if (take_word && !reject_word)
            half_valid <= 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin : update_half_data
        if (!rst_n)
            half_data <= 32'd0;
        else if (take_word && !reject_word && !half_valid)
            half_data <= frame_data[31:0];
    end

    always @(posedge clk or negedge rst_n) begin : update_active_transfer
        if (!rst_n)
            active_transfer <= 76'd0;
        else if (pair_start)
            active_transfer <= {4'd8,8'hff,frame_data[31:0],half_data};
        else if (tail_start)
            active_transfer <= {4'd4,8'h0f,32'd0,half_data};
    end
    // 成功响应后才增加长度。失败不前移地址，下一事务覆盖未提交位置。

    always @(posedge clk or negedge rst_n) begin : update_used_bytes
        if (!rst_n)
            used_bytes <= 32'd0;
        else if (push_block)
            used_bytes <= 32'd0;
        else if (write_success)
            used_bytes <= used_bytes + {28'd0,active_transfer[75:72]};
    end

    always @(posedge clk or negedge rst_n) begin : update_write_block
        if (!rst_n)
            write_block <= {INDEX_BITS{1'b0}};
        else if (push_block)
            write_block <= write_block + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin : update_read_block
        if (!rst_n)
            read_block <= {INDEX_BITS{1'b0}};
        else if (pop_block)
            read_block <= read_block + 1'b1;
    end

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

    always @(posedge clk or negedge rst_n) begin : update_publish_seq
        if (!rst_n)
            publish_seq <= 32'd0;
        else if (push_block)
            publish_seq <= publish_seq + 32'd1;
    end

    always @(posedge clk or negedge rst_n) begin : update_block_len
        if (!rst_n) begin
            for (len_index=0;len_index<BLOCK_COUNT;len_index=len_index+1) block_len[len_index]<=32'd0;
        end else if (push_block)
            block_len[write_block] <= used_bytes;
    end

    always @(posedge clk or negedge rst_n) begin : update_block_seq
        if (!rst_n) begin
            for (seq_index=0;seq_index<BLOCK_COUNT;seq_index=seq_index+1) block_seq[seq_index]<=32'd0;
        end else if (push_block)
            block_seq[write_block] <= publish_seq;
    end

    always @(posedge clk or negedge rst_n) begin : update_dropped_words
        if (!rst_n)
            dropped_frames <= 32'd0;
        else
            dropped_frames <= drop_sum[32] ? 32'hffffffff : drop_sum[31:0];
    end
    // 新队头通知优先于读清；空队列ACK不消费同拍发布的新块。

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
