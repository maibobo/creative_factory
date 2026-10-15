# nvme_request_scheduler

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\rtl\nvme_request_scheduler.sv`
- SHA-256: `08b2bba1758fae1ce52491e5839d4bbaf93c72c74bd353580c313530adcbf65e`
- Extractor: `text`
- Tags: `ddr, nvme, pcie, rtl`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\nvme_request_scheduler.sv

```systemverilog
`timescale 1ns/1ps

// 项目级NVMe请求调度器。
//
// 调度器只产生抽象的req/cpl握手，不依赖供应商寄存器、SQE或Doorbell格式。
// 当前只允许一个项目级请求在途；供应商IP仍可把一个大请求按MDTS拆成多条
// NVMe SQE并在内部流水处理。
//
// 一次Capture收尾的持久化顺序固定为：
//   所有Payload Write完成 -> Flush1 -> Commit页Write -> Flush2 -> capture_done
// Flush1保证Payload先持久化，Flush2保证描述本次采集有效性的Commit页持久化。
module nvme_request_scheduler #(
    parameter integer AXI_ADDR_WIDTH = 64,    // DDR缓冲地址位宽
    parameter integer LBA_BYTES = 512,    // SSD当前LBA格式的逻辑块字节数
    parameter integer COMMAND_TIMEOUT_CYCLES = 125_000_000,    // 单请求完成超时周期数
    parameter [63:0] BASE_SLBA = 64'd2048    // 复位后的Raw数据起始LBA
) (
    input  wire                         clk,    // Scheduler系统时钟
    input  wire                         rst_n,    // 低有效同步复位
    input  wire                         nvme_init_done,    // NoPHAE初始化完成
    input  wire                         pcie_link_up,    // PCIe链路可用
    input  wire                         ecqe_error_valid,    // NoPHAE错误完成事件有效
    input  wire [15:0]                  ecqe_error_status,    // NoPHAE错误完成状态
    // ADC格式、分段所有权等外部数据完整性错误；置位后不再提交新命令。
    input  wire                         external_fatal_error,    // 上游格式、FIFO或Manager致命错误汇总
    // 每次FDMA兼容Capture开始前装载本次Raw LBA起点。
    input  wire                         session_start,    // 新Capture会话起点装载脉冲
    input  wire [63:0]                  session_base_slba,    // 本次Capture的Raw起始LBA

    // 来自segment_buffer_manager的首个READY Payload描述符。
    input  wire                         ready_valid,    // Manager已有READY Payload描述符
    output reg                          ready_accept,    // Payload请求已被NoPHAE接受的单拍确认
    input  wire [15:0]                  ready_tag,    // Payload应用层Tag
    input  wire [AXI_ADDR_WIDTH-1:0]    ready_ddr_addr,    // Payload所在DDR物理地址
    input  wire [63:0]                  ready_payload_bytes,    // 真实Payload长度，用于入口合法性检查
    input  wire [31:0]                  ready_dma_bytes,    // 对齐后的DMA长度，用于请求及SLBA推进

    // 返回给segment_buffer_manager的Payload完成；Flush/Commit不占用普通分段。
    output reg                          manager_completion_valid,    // 返回Manager的Payload完成单拍
    output reg  [15:0]                  manager_completion_tag,    // 返回的Payload Tag
    output reg  [15:0]                  manager_completion_status,    // 0=成功，非0=错误

    // Writer在尾段和Commit页都写入DDR后提出Capture收尾请求。
    input  wire                         commit_valid,    // Writer已准备好Capture Commit页
    output reg                          commit_ready,    // Scheduler锁存Commit上下文的单拍握手
    input  wire [AXI_ADDR_WIDTH-1:0]    commit_ddr_addr,    // 固定4 KiB Commit页DDR地址
    input  wire [31:0]                  commit_dma_bytes,    // Commit页DMA字节数
    input  wire [63:0]                  commit_capture_id,    // Commit页所属Capture编号
    input  wire                         commit_error,    // Writer汇总的Capture写入错误

    // 与可替换NVMe后端之间的统一请求通道。WRITE使用DDR地址/长度/SLBA；
    // FLUSH的地址和长度为零，语义由opcode确定。
    output wire                         nvme_req_valid,    // 当前抽象NoPHAE请求有效
    input  wire                         nvme_req_ready,    // 后端可以接受当前请求
    output wire [1:0]                   nvme_req_opcode,    // WRITE/READ/FLUSH抽象操作码
    output wire [AXI_ADDR_WIDTH-1:0]    nvme_req_ddr_addr,    // DMA DDR地址，FLUSH时为0
    output wire [31:0]                  nvme_req_byte_len,    // DMA字节数，FLUSH时为0
    output wire [63:0]                  nvme_req_slba,    // 当前SSD起始LBA
    output wire [15:0]                  nvme_req_user_tag,    // Completion匹配用应用层Tag

    // 后端完成通道。user_tag必须与当前等待的请求一致，错误Tag会触发fatal。
    input  wire                         nvme_cpl_valid,    // 后端Completion有效
    output wire                         nvme_cpl_ready,    // Scheduler正等待一个Completion
    input  wire [15:0]                  nvme_cpl_user_tag,    // 后端返回的应用层Tag
    input  wire [15:0]                  nvme_cpl_status,    // 0=成功，非0=失败

    output reg                          capture_done,    // 第二次Flush成功后的单拍Capture完成
    output reg  [63:0]                  last_capture_id,    // 最近成功持久化的Capture编号
    output reg                          fatal_error,    // 致命错误锁存，进入HALT后保持
    output reg                          timeout_sticky,    // 请求超时粘滞位
    output reg                          link_down_sticky,    // 运行期间PCIe掉线粘滞位
    output reg  [31:0]                  submitted_requests,    // 已被后端接受的项目级请求数
    output reg  [31:0]                  completed_requests    // 已收到Completion的项目级请求数
);

    // READ保留给统一后端接口；当前Capture写入状态机只发出WRITE和FLUSH。
    localparam [1:0] NVME_OP_WRITE = 2'd0;    // 从DDR向SSD写入
    localparam [1:0] NVME_OP_READ  = 2'd1;    // 接口保留，当前状态机不发READ
    localparam [1:0] NVME_OP_FLUSH = 2'd2;    // 请求SSD完成持久化屏障

    // SEND状态保持请求字段稳定直到req_valid&&req_ready；
    // WAIT状态只等待对应Completion，不接受下一条项目级命令。
    localparam [3:0] ST_IDLE        = 4'd0;    // 等待Payload或Capture Commit请求
    localparam [3:0] ST_SEND_DATA   = 4'd1;    // 保持Payload请求直到后端接受
    localparam [3:0] ST_WAIT_DATA   = 4'd2;    // 等待Payload写Completion
    localparam [3:0] ST_SEND_FLUSH1 = 4'd3;    // 提交Payload后的第一次Flush
    localparam [3:0] ST_WAIT_FLUSH1 = 4'd4;    // 等待第一次Flush完成
    localparam [3:0] ST_SEND_COMMIT = 4'd5;    // 提交Commit页WRITE
    localparam [3:0] ST_WAIT_COMMIT = 4'd6;    // 等待Commit页WRITE完成
    localparam [3:0] ST_SEND_FLUSH2 = 4'd7;    // 提交Commit后的第二次Flush
    localparam [3:0] ST_WAIT_FLUSH2 = 4'd8;    // 等待第二次Flush并结束Capture
    localparam [3:0] ST_HALT        = 4'd15;    // 致命错误冻结状态，复位前不退出

    // 高位保留Tag专用于Capture收尾命令，避免与普通segment Tag混淆。
    localparam [15:0] TAG_FLUSH1 = 16'hFFFC;    // 第一次Flush专用Tag
    localparam [15:0] TAG_COMMIT = 16'hFFFD;    // Commit页WRITE专用Tag
    localparam [15:0] TAG_FLUSH2 = 16'hFFFE;    // 第二次Flush专用Tag

    reg [3:0] state;    // Scheduler当前状态
    reg [15:0] data_tag;    // 当前Payload请求Tag
    reg [AXI_ADDR_WIDTH-1:0] data_addr;    // 当前Payload DDR地址
    reg [31:0] data_dma_bytes;    // 当前Payload对齐DMA长度
    reg [63:0] data_payload_bytes;    // 入口检查后当前未再读取，作为遗留诊断上下文保留
    reg [AXI_ADDR_WIDTH-1:0] commit_addr_latched;    // 已握手Commit页DDR地址
    reg [31:0] commit_bytes_latched;    // 已握手Commit页DMA长度
    reg [63:0] commit_id_latched;    // 已握手Commit所属Capture编号
    reg [63:0] next_slba;    // 下一条WRITE使用的连续Raw LBA
    reg [31:0] command_age;    // 当前WAIT状态已等待的系统时钟周期数

    // 组合分类用于统一产生req_valid、cpl_ready和超时计数条件。
    wire send_state = (state == ST_SEND_DATA) ||    // 任一请求发送状态
                      (state == ST_SEND_FLUSH1) ||
                      (state == ST_SEND_COMMIT) ||
                      (state == ST_SEND_FLUSH2);
    wire wait_state = (state == ST_WAIT_DATA) ||    // 任一Completion等待状态
                      (state == ST_WAIT_FLUSH1) ||
                      (state == ST_WAIT_COMMIT) ||
                      (state == ST_WAIT_FLUSH2);
    wire completion_handshake = nvme_cpl_valid && nvme_cpl_ready;    // Completion握手事件
    wire abort_event =    // 链路、ECQE或上游完整性错误的统一终止条件
        (nvme_init_done && !pcie_link_up) ||
        ecqe_error_valid ||
        external_fatal_error;
    wire timeout_event =    // WAIT计数到上限且本拍没有Completion
        wait_state && !completion_handshake &&
        (command_age == COMMAND_TIMEOUT_CYCLES-1);
    wire [15:0] abort_status =    // 返回Manager的项目内错误状态编码
        ecqe_error_valid ?
            ((ecqe_error_status == 16'd0) ? 16'hFFFC :
                                                ecqe_error_status) :
        external_fatal_error ? 16'hFFFB : 16'hFFFA;

    // NVMe尚未初始化、PCIe掉线或已经锁存fatal时，禁止再提交新请求。
    assign nvme_req_valid = send_state && nvme_init_done &&
                            pcie_link_up && !fatal_error;
    assign nvme_cpl_ready = wait_state && !fatal_error;

    // 状态机复用一组req端口：Payload/Commit均为WRITE，两个屏障为FLUSH。
    assign nvme_req_opcode =
        (state == ST_SEND_DATA || state == ST_SEND_COMMIT) ?
        NVME_OP_WRITE : NVME_OP_FLUSH;
    assign nvme_req_ddr_addr =
        (state == ST_SEND_DATA) ? data_addr :
        (state == ST_SEND_COMMIT) ? commit_addr_latched :
        {AXI_ADDR_WIDTH{1'b0}};
    assign nvme_req_byte_len =
        (state == ST_SEND_DATA) ? data_dma_bytes :
        (state == ST_SEND_COMMIT) ? commit_bytes_latched : 32'd0;
    assign nvme_req_slba = next_slba;
    assign nvme_req_user_tag =
        (state == ST_SEND_DATA) ? data_tag :
        (state == ST_SEND_FLUSH1) ? TAG_FLUSH1 :
        (state == ST_SEND_COMMIT) ? TAG_COMMIT : TAG_FLUSH2;

    // 当前Raw LBA路径只支持常见的512 B或4 KiB逻辑块格式。
    initial begin
        if ((LBA_BYTES != 512) && (LBA_BYTES != 4096))
            $error("LBA_BYTES must be 512 or 4096");
        if (COMMAND_TIMEOUT_CYCLES < 16)
            $error("COMMAND_TIMEOUT_CYCLES is too small");
        if (COMMAND_TIMEOUT_CYCLES > 32'hFFFF_FFFF)
            $error("COMMAND_TIMEOUT_CYCLES exceeds the 32-bit watchdog");
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state                       <= ST_IDLE;
            ready_accept                <= 1'b0;
            manager_completion_valid    <= 1'b0;
            manager_completion_tag      <= 16'd0;
            manager_completion_status   <= 16'd0;
            commit_ready                <= 1'b0;
            data_tag                    <= 16'd0;
            data_addr                   <= {AXI_ADDR_WIDTH{1'b0}};
            data_dma_bytes              <= 32'd0;
            data_payload_bytes          <= 64'd0;
            commit_addr_latched         <= {AXI_ADDR_WIDTH{1'b0}};
            commit_bytes_latched        <= 32'd0;
            commit_id_latched           <= 64'd0;
            next_slba                   <= BASE_SLBA;
            command_age                 <= 32'd0;
            capture_done                <= 1'b0;
            last_capture_id             <= 64'd0;
            fatal_error                 <= 1'b0;
            timeout_sticky              <= 1'b0;
            link_down_sticky            <= 1'b0;
            submitted_requests          <= 32'd0;
            completed_requests          <= 32'd0;
        end else begin
            // 下列握手/事件输出均为单周期脉冲，每拍先清零再由当前状态置位。
            ready_accept             <= 1'b0;
            manager_completion_valid <= 1'b0;
            commit_ready             <= 1'b0;
            capture_done             <= 1'b0;

            // 外部完整性错误、Link Down和ECQE的优先级高于正常Completion。
            // 若Payload已经INFLIGHT，先把它送入ERROR_HOLD，再进入不可恢复HALT；
            // 这样不会留下一个表面正常、实际上永远无法释放的分段。
            if (abort_event) begin
                fatal_error <= 1'b1;
                state       <= ST_HALT;
                command_age <= 32'd0;
                if (nvme_init_done && !pcie_link_up)
                    link_down_sticky <= 1'b1;
                if (state == ST_WAIT_DATA) begin
                    manager_completion_valid  <= 1'b1;
                    manager_completion_tag    <= data_tag;
                    manager_completion_status <= abort_status;
                end
            end else if (timeout_event) begin
                // Completion与超时同拍时由completion_handshake抑制timeout_event，
                // 防止成功完成在watchdog边界被误判成超时。
                timeout_sticky <= 1'b1;
                fatal_error    <= 1'b1;
                state          <= ST_HALT;
                command_age    <= 32'd0;
                if (state == ST_WAIT_DATA) begin
                    manager_completion_valid  <= 1'b1;
                    manager_completion_tag    <= data_tag;
                    manager_completion_status <= 16'hFFFE;
                end
            end else if (session_start && (state != ST_IDLE)) begin
                // 新Capture只能在上一Capture完整Flush/Commit/Flush结束后开始。
                fatal_error <= 1'b1;
                state       <= ST_HALT;
                command_age <= 32'd0;
            end else begin
                if (wait_state && !completion_handshake)
                    command_age <= command_age + 1'b1;
                else
                    command_age <= 32'd0;

                if (session_start)
                    next_slba <= session_base_slba;

            case (state)
                ST_IDLE: begin
                    // READY Payload优先于Commit，确保停止采集后先排空全部数据段。
                    if (!fatal_error && nvme_init_done && pcie_link_up) begin
                        if (ready_valid) begin
                            // 只接受非零、DDR地址和DMA长度均4 KiB对齐的请求。
                            // payload_bytes可能小于dma_bytes，差额是尾段零填充。
                            data_tag           <= ready_tag;
                            data_addr          <= ready_ddr_addr;
                            data_dma_bytes     <= ready_dma_bytes;
                            data_payload_bytes <= ready_payload_bytes;
                            if ((ready_dma_bytes == 0) ||
                                ((ready_dma_bytes % 4096) != 0) ||
                                ((ready_ddr_addr % 4096) != 0) ||
                                (ready_payload_bytes == 0) ||
                                (ready_payload_bytes > ready_dma_bytes)) begin
                                fatal_error <= 1'b1;
                                state       <= ST_HALT;
                            end else
                                state <= ST_SEND_DATA;
                        end else if (commit_valid) begin
                            commit_addr_latched  <= commit_ddr_addr;
                            commit_bytes_latched <= commit_dma_bytes;
                            commit_id_latched    <= commit_capture_id;
                            commit_ready         <= 1'b1;
                            if (commit_error || (commit_dma_bytes == 0) ||
                                ((commit_dma_bytes % 4096) != 0) ||
                                ((commit_ddr_addr % 4096) != 0)) begin
                                fatal_error <= 1'b1;
                                state       <= ST_HALT;
                            end else begin
                                state <= ST_SEND_FLUSH1;
                            end
                        end
                    end
                end

                ST_SEND_DATA: begin
                    // 请求握手后才把分段标记为INFLIGHT并推进连续Raw LBA写指针。
                    if (nvme_req_valid && nvme_req_ready) begin
                        ready_accept       <= 1'b1;
                        submitted_requests <= submitted_requests + 1'b1;
                        next_slba          <= next_slba +
                                              (data_dma_bytes / LBA_BYTES);
                        state              <= ST_WAIT_DATA;
                    end
                end

                ST_WAIT_DATA: begin
                    // Tag匹配且status=0才释放对应分段；任何异常都冻结后续提交。
                    if (nvme_cpl_valid && nvme_cpl_ready) begin
                        completed_requests        <= completed_requests + 1'b1;
                        manager_completion_valid  <= 1'b1;
                        manager_completion_tag    <= data_tag;
                        manager_completion_status <=
                            (nvme_cpl_user_tag == data_tag) ?
                            nvme_cpl_status : 16'hFFFF;
                        if ((nvme_cpl_user_tag != data_tag) ||
                            (nvme_cpl_status != 16'd0)) begin
                            fatal_error <= 1'b1;
                            state       <= ST_HALT;
                        end else
                            state <= ST_IDLE;
                    end
                end

                ST_SEND_FLUSH1: begin
                    // 第一次Flush建立“Payload先于Commit持久化”的顺序屏障。
                    if (nvme_req_valid && nvme_req_ready) begin
                        submitted_requests <= submitted_requests + 1'b1;
                        state <= ST_WAIT_FLUSH1;
                    end
                end

                ST_WAIT_FLUSH1: begin
                    if (nvme_cpl_valid && nvme_cpl_ready) begin
                        completed_requests <= completed_requests + 1'b1;
                        if ((nvme_cpl_user_tag != TAG_FLUSH1) ||
                            (nvme_cpl_status != 16'd0)) begin
                            fatal_error <= 1'b1;
                            state       <= ST_HALT;
                        end else
                            state <= ST_SEND_COMMIT;
                    end
                end

                ST_SEND_COMMIT: begin
                    // Commit页也是普通WRITE，占用其自己的4 KiB对齐DDR缓冲区。
                    if (nvme_req_valid && nvme_req_ready) begin
                        submitted_requests <= submitted_requests + 1'b1;
                        next_slba <= next_slba +
                                     (commit_bytes_latched / LBA_BYTES);
                        state <= ST_WAIT_COMMIT;
                    end
                end

                ST_WAIT_COMMIT: begin
                    if (nvme_cpl_valid && nvme_cpl_ready) begin
                        completed_requests <= completed_requests + 1'b1;
                        if ((nvme_cpl_user_tag != TAG_COMMIT) ||
                            (nvme_cpl_status != 16'd0)) begin
                            fatal_error <= 1'b1;
                            state       <= ST_HALT;
                        end else
                            state <= ST_SEND_FLUSH2;
                    end
                end

                ST_SEND_FLUSH2: begin
                    // 第二次Flush使Commit标记本身具备掉电后的持久化含义。
                    if (nvme_req_valid && nvme_req_ready) begin
                        submitted_requests <= submitted_requests + 1'b1;
                        state <= ST_WAIT_FLUSH2;
                    end
                end

                ST_WAIT_FLUSH2: begin
                    // 只有完整的Payload/Flush/Commit/Flush链路成功才上报Capture完成。
                    if (nvme_cpl_valid && nvme_cpl_ready) begin
                        completed_requests <= completed_requests + 1'b1;
                        if ((nvme_cpl_user_tag != TAG_FLUSH2) ||
                            (nvme_cpl_status != 16'd0)) begin
                            fatal_error <= 1'b1;
                            state       <= ST_HALT;
                        end else begin
                            last_capture_id <= commit_id_latched;
                            capture_done    <= 1'b1;
                            state           <= ST_IDLE;
                        end
                    end
                end

                ST_HALT: state <= ST_HALT;

                default: begin
                    fatal_error <= 1'b1;
                    state       <= ST_HALT;
                end
            endcase
            end
        end
    end

endmodule
```
