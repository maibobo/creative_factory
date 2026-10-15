module ASIC_RTL_TEMPLATE #(
    parameter DATA_W = 8,
    parameter COUNT_W = 8
) (
    input  wire                 clk_core,
    input  wire                 rst_core_n,
    input  wire                 req_valid,
    output wire                 req_ready,
    input  wire [DATA_W-1:0]    req_data,
    output wire                 rsp_valid,
    input  wire                 rsp_ready,
    output wire [DATA_W-1:0]    rsp_data,
    output reg  [COUNT_W-1:0]   accept_count
);

localparam [1:0] MAIN_IDLE = 2'b00;
localparam [1:0] MAIN_RESP = 2'b01;

reg [1:0]        main_curr_st;
reg [1:0]        main_next_st;
reg [DATA_W-1:0] req_data_hold;

wire req_fire;
wire rsp_fire;

// 请求/响应握手事件：两个事件是状态推进和数据保存的共同条件。
assign req_ready = (main_curr_st == MAIN_IDLE);
assign rsp_valid = (main_curr_st == MAIN_RESP);
assign req_fire  = req_valid & req_ready;
assign rsp_fire  = rsp_valid & rsp_ready;
assign rsp_data  = req_data_hold + {{(DATA_W-1){1'b0}}, 1'b1};

// 主状态转移：组合过程只有 main_next_st 一个左值根对象，
// 默认保持用于覆盖所有输入组合并避免锁存器。
always @(*) begin : p_main_next_st
    main_next_st = main_curr_st;
    case (main_curr_st)
        MAIN_IDLE: begin
            if (req_fire) begin
                main_next_st = MAIN_RESP;
            end
        end
        MAIN_RESP: begin
            if (rsp_fire) begin
                main_next_st = MAIN_IDLE;
            end
        end
        default: begin
            main_next_st = MAIN_IDLE;
        end
    endcase
end

// 主状态寄存器：rst_core_n 必须由集成层批准的复位同步单元产生，
// 其语义是低有效异步置位、相对 clk_core 同步释放。
always @(posedge clk_core or negedge rst_core_n) begin : p_main_curr_st
    if (!rst_core_n) begin
        main_curr_st <= MAIN_IDLE;
    end else begin
        main_curr_st <= main_next_st;
    end
end

// 请求数据快照：只在请求真正握手时更新，响应期间保持稳定。
always @(posedge clk_core or negedge rst_core_n) begin : p_req_data_hold
    if (!rst_core_n) begin
        req_data_hold <= {DATA_W{1'b0}};
    end else if (req_fire) begin
        req_data_hold <= req_data;
    end
end

// 接受计数：该寄存器独立于数据快照，使用单独的时序过程。
always @(posedge clk_core or negedge rst_core_n) begin : p_accept_count
    if (!rst_core_n) begin
        accept_count <= {COUNT_W{1'b0}};
    end else if (req_fire) begin
        accept_count <= accept_count + {{(COUNT_W-1){1'b0}}, 1'b1};
    end
end

endmodule

/*
集成层 CDC 例化形式（文档占位，不是可签核模块名）：

<APPROVED_BIT_SYNC> U_<APPROVED_BIT_SYNC> (
    .clk_dst   (clk_core),
    .rst_dst_n (rst_core_n),
    .data_src  (status_async),
    .data_dst  (status_core)
);

实际模块名、端口和路径必须从 config/approved_cells.json 中状态为 approved
且 profiles 包含 asic_signoff 的 bit_sync 条目替换。不得把此占位复制为自制同步器。

允许的状态机多目标例外也应写成一个完整语义段：只有共享同一时钟、复位、
主使能和 state 分支的紧密寄存器组才可合并，并在块前说明分组不变量；本模板
的可执行主体采用默认的“一个 always 一个左值根对象”。
*/
