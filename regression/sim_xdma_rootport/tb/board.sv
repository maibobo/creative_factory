`timescale 1ps / 1ps

`include "board_common.vh"
`include "xdma_irq_monitor.sv"
`include "conv_dma_axi_monitor.sv"
`include "xdma_axi_activity_monitor.sv"
`define SIMULATION

// RTDS_test-1ch 真实 Endpoint + Xilinx 官方 Root Port 大仿真顶层。
// 模块名必须保持 board，官方 TPI 使用 board.RP.tx_usrapp 的层级任务。
// 输入：内部产生的 PCIe/系统/Aurora 时钟和用例数据模式；无板级外部端口。
// 输出：官方 RP 与真实 EP 的串行事务、BFM 激励、scoreboard/断言和语义日志。
// 作用：依次完成链路、枚举、BAR、MSI、基础 H2C/C2H、CPU→Aurora、
// Aurora→CPU、IRQ/read-clear，并统一输出 RTDS_ROOTPORT_RESULT/PASS。
// 失败定位：先看 milestone/test_error_count，再按语义段进入 BAR、DMA、CQ Host、
// LL BFM 或 IRQ monitor；全局 2 ms watchdog 只说明某阶段未前进。
module board;
    timeunit 1ps;
    timeprecision 1ps;

    import rtds_rootport_pkg::*;

    parameter REF_CLK_FREQ = 0;
    parameter C_DATA_WIDTH = 64;
    localparam integer REF_CLK_HALF_CYCLE = 5000; // 100 MHz，单位 ps
    localparam [4:0] LINK_WIDTH = 5'd2;
    localparam [2:0] LINK_SPEED = 3'h4;
    localparam [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b010;

    // ---------- 语义段 1：时钟、复位和 PCIe x2 串行互连 ----------
    // 输入：测试台内部时间基准；输出：100/250/156.25 MHz、复位和 RP↔EP x2。
    // 失败定位：link 不起先查差分时钟/复位释放，再看 LTSSM，不进入 DMA 排查。
    reg sys_rst_n;
    reg i_sys_clk;
    reg aurora_user_clk;
    reg aurora_user_rstn;
    reg aurora_channel_up;
    reg aurora_lane_up;

    wire rp_sys_clk_p;
    wire rp_sys_clk_n;
    wire ep_sys_clk_p;
    wire ep_sys_clk_n;

    wire [1:0] ep_pci_exp_txp;
    wire [1:0] ep_pci_exp_txn;
    wire [1:0] rp_pci_exp_txp;
    wire [1:0] rp_pci_exp_txn;
    wire       ep_user_lnk_up;

    // 串行线跳变计数仅用于链路训练诊断：若某一方向长期为零，可快速定位
    // 对端仍处于复位、GT 未发送训练序列或串行连接未生效。计数不参与判定。
    integer ep_tx_transition_count;
    integer rp_tx_transition_count;

    initial begin
        ep_tx_transition_count = 0;
        rp_tx_transition_count = 0;
    end

    always @(ep_pci_exp_txp)
        ep_tx_transition_count = ep_tx_transition_count + 1;

    always @(rp_pci_exp_txp)
        rp_tx_transition_count = rp_tx_transition_count + 1;

    sys_clk_gen_ds #(.halfcycle(REF_CLK_HALF_CYCLE), .offset(0)) CLK_GEN_RP (
        .sys_clk_p(rp_sys_clk_p), .sys_clk_n(rp_sys_clk_n)
    );
    sys_clk_gen_ds #(.halfcycle(REF_CLK_HALF_CYCLE), .offset(0)) CLK_GEN_EP (
        .sys_clk_p(ep_sys_clk_p), .sys_clk_n(ep_sys_clk_n)
    );

    initial begin
        i_sys_clk = 1'b0;
        forever #2000 i_sys_clk = ~i_sys_clk; // 250 MHz
    end

    initial begin
        aurora_user_clk = 1'b0;
        forever #3200 aurora_user_clk = ~aurora_user_clk; // 156.25 MHz
    end

    initial begin
        sys_rst_n         = 1'b0;
        aurora_user_rstn  = 1'b0;
        aurora_channel_up = 1'b0;
        aurora_lane_up    = 1'b0;
        $display("[%t] RTDS_RESET: PCIe 系统复位已拉低", $realtime);
        repeat (500) @(posedge rp_sys_clk_p); // 5 us
        sys_rst_n = 1'b1;
        $display("[%t] RTDS_RESET: PCIe 系统复位已释放", $realtime);
        repeat (16) @(posedge aurora_user_clk);
        aurora_user_rstn = 1'b1;
        repeat (16) @(posedge aurora_user_clk);
        aurora_channel_up = 1'b1;
        aurora_lane_up    = 1'b1;
        $display("[%t] RTDS_AURORA_BOUNDARY: LL 用户时钟域已就绪（轻量 BFM，无 GT 模型）", $realtime);
    end

    // ---------- 语义段 1A：时间基准自检 ----------
    // 仿真顶层所有裸延时均按 1 ps 解释。这里实测 10 个 250 MHz 周期，
    // 避免导出脚本或第三方模拟器错误覆盖 timescale 后，把 200 us 误跑成更长时间。
    initial begin : TIMEBASE_SELF_CHECK
        time start_time;
        $printtimescale(board);
        wait (sys_rst_n === 1'b1);
        @(posedge i_sys_clk);
        start_time = $time;
        repeat (10) @(posedge i_sys_clk);
        if (($time - start_time) != 40_000)
            $fatal(1, "RTDS_TIMEBASE_FAIL: 10 个 250 MHz 周期=%0t，期望 40000 ps",
                   $time - start_time);
        else
            $display("[%t] RTDS_TIMEBASE_PASS: 10 个 250 MHz 周期=40000 ps", $realtime);
    end

    // ---------- 语义段 2：真实 RTDS Endpoint 与官方 Root Port ----------
    // 输入：上述时钟复位和串行连线；输出：真实 EP、官方 RP/TPI 层次。
    // 失败定位：枚举/BAR 失败归 RP/TPI/EP 配置；Adapter/LL 尚未参与该阶段。
    wire [63:0] aurora_tx_d;
    wire        aurora_tx_sof;
    wire        aurora_tx_eof;
    wire [2:0]  aurora_tx_rem;
    wire        aurora_tx_src_rdy;
    wire        aurora_tx_dst_rdy;
    wire [63:0] aurora_rx_d;
    wire        aurora_rx_sof;
    wire        aurora_rx_eof;
    wire [2:0]  aurora_rx_rem;
    wire        aurora_rx_src_rdy;
    wire        aurora_rx_dst_rdy;

    rtds_pcie_ep_sim_wrapper EP (
        .pcie_mgt_rxn       (rp_pci_exp_txn),
        .pcie_mgt_rxp       (rp_pci_exp_txp),
        .pcie_mgt_txn       (ep_pci_exp_txn),
        .pcie_mgt_txp       (ep_pci_exp_txp),
        .pcie_diff_clk_n    (ep_sys_clk_n),
        .pcie_diff_clk_p    (ep_sys_clk_p),
        .pcie_rst_n         (sys_rst_n),
        .user_lnk_up        (ep_user_lnk_up),
        .FPGA_TEMP_W        (32'd0),
        .i_sys_clk          (i_sys_clk),
        .i_sys_rst          (!sys_rst_n),
        .aurora_user_clk    (aurora_user_clk),
        .aurora_user_rstn   (aurora_user_rstn),
        .aurora_channel_up  (aurora_channel_up),
        .aurora_lane_up     (aurora_lane_up),
        .aurora_tx_d        (aurora_tx_d),
        .aurora_tx_sof      (aurora_tx_sof),
        .aurora_tx_eof      (aurora_tx_eof),
        .aurora_tx_rem      (aurora_tx_rem),
        .aurora_tx_src_rdy  (aurora_tx_src_rdy),
        .aurora_tx_dst_rdy  (aurora_tx_dst_rdy),
        .aurora_rx_d        (aurora_rx_d),
        .aurora_rx_sof      (aurora_rx_sof),
        .aurora_rx_eof      (aurora_rx_eof),
        .aurora_rx_rem      (aurora_rx_rem),
        .aurora_rx_src_rdy  (aurora_rx_src_rdy),
        .aurora_rx_dst_rdy  (aurora_rx_dst_rdy)
    );

    xilinx_pcie3_uscale_rp #(
        // 官方 example 默认按 x8 生成；本项目 Endpoint 是 Gen3 x2。
        // 必须在实例参数处明确锁定 x2，避免仅靠端口截断得到“碰巧协商为 x2”。
        .PL_LINK_CAP_MAX_LINK_SPEED  (LINK_SPEED),
        .PL_LINK_CAP_MAX_LINK_WIDTH  (LINK_WIDTH[3:0]),
        .PF0_DEV_CAP_MAX_PAYLOAD_SIZE(PF0_DEV_CAP_MAX_PAYLOAD_SIZE)
    ) RP (
        .sys_clk_n  (rp_sys_clk_n),
        .sys_clk_p  (rp_sys_clk_p),
        .sys_rst_n  (sys_rst_n),
        .pci_exp_txn(rp_pci_exp_txn),
        .pci_exp_txp(rp_pci_exp_txp),
        .pci_exp_rxn(ep_pci_exp_txn),
        .pci_exp_rxp(ep_pci_exp_txp)
    );

    // ---------- 语义段 2A：RP CQ posted-write Host memory sink ----------
    // 官方 DATA_STORE 是 Host 发包数据源，不是会被 C2H 自动更新的 RAM。
    // Endpoint 的 C2H Memory Write 从 RP m_axis_cq 流进入本 monitor。
    reg         cq_monitor_clear;
    wire [31:0] cq_host_write_bytes;
    wire [31:0] cq_ignored_write_bytes;
    wire [31:0] cq_memory_write_packets;
    wire [31:0] cq_host_protocol_errors;
    wire [63:0] cq_last_write_address;

    pcie_cq_host_memory_monitor CQ_HOST (
        .user_clk           (RP.user_clk),
        .user_reset         (RP.user_reset),
        .clear_capture      (cq_monitor_clear),
        .cq_tdata           (RP.m_axis_cq_tdata),
        .cq_tuser           (RP.m_axis_cq_tuser),
        .cq_tkeep           (RP.m_axis_cq_tkeep),
        .cq_tlast           (RP.m_axis_cq_tlast),
        .cq_tvalid          (RP.m_axis_cq_tvalid),
        .cq_tready          (RP.m_axis_cq_tready),
        .host_write_bytes   (cq_host_write_bytes),
        .ignored_write_bytes(cq_ignored_write_bytes),
        .memory_write_packets(cq_memory_write_packets),
        .protocol_errors    (cq_host_protocol_errors),
        .last_write_address (cq_last_write_address)
    );

    // ---------- 语义段 2B：XDMA AXI 本地前进监视 ----------
    // 高频通过 PCIe 读 descriptor count 会为每次轮询生成完整 TLP/
    // Completion，在串行 PCIe 模型中代价很高。先等本地 AXI 数据面
    // 完成，再只做少量 PCIe 完成寄存器读，保留原验证语义。
    reg         dma_monitor_clear;
    wire [31:0] dma_axi_write_bytes;
    wire [31:0] dma_axi_write_responses;
    wire [31:0] dma_axi_read_bytes;
    wire [31:0] dma_axi_read_bursts;
    wire [31:0] dma_axi_response_errors;

    xdma_axi_activity_monitor XDMA_AXI_MON (
        .axi_aclk         (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.axi_aclk),
        .axi_aresetn      (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.axi_aresetn),
        .clear_counters   (dma_monitor_clear),
        .m_axi_wstrb      (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_wstrb),
        .m_axi_wvalid     (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_wvalid),
        .m_axi_wready     (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_wready),
        .m_axi_bresp      (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_bresp),
        .m_axi_bvalid     (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_bvalid),
        .m_axi_bready     (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_bready),
        .m_axi_rresp      (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_rresp),
        .m_axi_rlast      (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_rlast),
        .m_axi_rvalid     (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_rvalid),
        .m_axi_rready     (EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.m_axi_rready),
        .write_bytes      (dma_axi_write_bytes),
        .write_responses  (dma_axi_write_responses),
        .read_bytes       (dma_axi_read_bytes),
        .read_bursts      (dma_axi_read_bursts),
        .response_errors  (dma_axi_response_errors)
    );

    // ---------- 语义段 3：LocalLink BFM、scoreboard 和集成断言 ----------
    // 输入：真实 EP 的 LL/FDMA/状态；输出：RX 激励、TX 比较及协议错误计数。
    // 失败定位：功能日志 PASS 前任何 assertion/scoreboard mismatch 均立即归零失败。
    wire [31:0] ll_tx_stall_cycles;
    wire [31:0] ll_rx_not_ready_errors;
    wire [31:0] ll_protocol_errors;
    wire [31:0] assertion_error_count;

    aurora_ll_peer_bfm LL_BFM (
        .user_clk          (aurora_user_clk),
        .user_rstn         (aurora_user_rstn),
        .link_up           (aurora_channel_up && aurora_lane_up),
        .tx_d              (aurora_tx_d),
        .tx_sof            (aurora_tx_sof),
        .tx_eof            (aurora_tx_eof),
        .tx_rem            (aurora_tx_rem),
        .tx_src_rdy        (aurora_tx_src_rdy),
        .tx_dst_rdy        (aurora_tx_dst_rdy),
        .rx_d              (aurora_rx_d),
        .rx_sof            (aurora_rx_sof),
        .rx_eof            (aurora_rx_eof),
        .rx_rem            (aurora_rx_rem),
        .rx_src_rdy        (aurora_rx_src_rdy),
        .rx_dst_rdy        (aurora_rx_dst_rdy),
        .tx_stall_cycles   (ll_tx_stall_cycles),
        .rx_not_ready_errors(ll_rx_not_ready_errors),
        .protocol_errors   (ll_protocol_errors)
    );

    rtds_rootport_assertions ASSERTIONS (
        .fdma_clk          (i_sys_clk),
        .fdma_rstn         (sys_rst_n),
        .fdma_raddr        (EP.fdma_raddr),
        .fdma_rareq        (EP.fdma_rareq),
        .fdma_rbusy        (EP.fdma_rbusy),
        .fdma_rsize        (EP.fdma_rsize),
        .fdma_waddr        (EP.fdma_waddr),
        .fdma_wareq        (EP.fdma_wareq),
        .fdma_wbusy        (EP.fdma_wbusy),
        .fdma_wsize        (EP.fdma_wsize),
        .user_clk          (aurora_user_clk),
        .user_rstn         (aurora_user_rstn),
        .link_up           (aurora_channel_up && aurora_lane_up),
        .tx_d              (aurora_tx_d),
        .tx_sof            (aurora_tx_sof),
        .tx_eof            (aurora_tx_eof),
        .tx_rem            (aurora_tx_rem),
        .tx_src_rdy        (aurora_tx_src_rdy),
        .tx_dst_rdy        (aurora_tx_dst_rdy),
        .rx_src_rdy        (aurora_rx_src_rdy),
        .rx_dst_rdy        (aurora_rx_dst_rdy),
        .clear_inter       (EP.CLEAR_INTER_R),
        .sticky_status     ({EP.link_down_sticky, EP.length_error_sticky,
                             EP.fdma_timeout_sticky, EP.tx_underflow_sticky,
                             EP.rx_overrun_sticky, EP.rx_overflow_sticky}),
        .assertion_error_count(assertion_error_count)
    );

    // ---------- 语义段 4：测试状态和异步生命周期观测 ----------
    // 输入：各 monitor/断言状态；输出：milestone、错误累计和等待条件。
    // 失败定位：用于区分“尚未发生”与“发生后数据错误”，不驱动 DUT。
    integer test_error_count;
    integer user_bar;
    reg cpu_resp_seen_high;
    reg cpu_resp_seen_low_after_high;
    reg milestone_link;
    reg milestone_bar;
    reg milestone_msi;
    reg milestone_irq_route;
    reg milestone_base_dma;
    reg milestone_cpu_to_aurora;
    reg milestone_aurora_to_cpu;

    initial begin
        test_error_count             = 0;
        user_bar                    = -1;
        cpu_resp_seen_high           = 1'b0;
        cpu_resp_seen_low_after_high = 1'b0;
        milestone_link               = 1'b0;
        milestone_bar                = 1'b0;
        milestone_msi                = 1'b0;
        milestone_irq_route          = 1'b0;
        milestone_base_dma           = 1'b0;
        milestone_cpu_to_aurora      = 1'b0;
        milestone_aurora_to_cpu      = 1'b0;
        dma_monitor_clear            = 1'b0;
        cq_monitor_clear             = 1'b0;
    end

    always @(posedge i_sys_clk) begin
        if (!sys_rst_n) begin
            cpu_resp_seen_high           <= 1'b0;
            cpu_resp_seen_low_after_high <= 1'b0;
        end else begin
            if (EP.CPU_WR_DONE_resp)
                cpu_resp_seen_high <= 1'b1;
            if (cpu_resp_seen_high && !EP.CPU_WR_DONE_resp)
                cpu_resp_seen_low_after_high <= 1'b1;
        end
    end

    // ---------- 语义段 5：TPI BAR 访问封装 ----------
    // 输入：BAR index/offset/write data；输出：真实 PCIe read completion 或 write。
    // 失败定位：超时查 P_READ_DATA_VALID、BAR 基址和 TLP，而不是 INFO 内部寄存器。
    task automatic bar_read32(input integer bar_index, input [31:0] offset, output [31:0] value);
        integer wait_cycles;
        begin
            RP.tx_usrapp.P_READ_DATA = 32'hFFFF_FFFF;
            // 官方 TPI 要求 WAIT 必须紧跟在 BAR_READ 之后串行调用。
            // 若两者 fork 并行，WAIT 清 P_READ_DATA_VALID 时会与发包过程竞争。
            // 官方 WAIT 另有固定 60 us 上限；RTDS AXI-Lite BAR 在 posted write
            // 排空后的实测响应可超过该上限，因此本兼容层保持串行语义，
            // 但把用户 BAR 的等待扩展到 200 us。不修改官方 RP/TPI 源码。
            RP.tx_usrapp.TSK_TX_BAR_READ(bar_index[2:0], offset,
                                         RP.tx_usrapp.DEFAULT_TAG,
                                         RP.tx_usrapp.DEFAULT_TC);
            RP.tx_usrapp.P_READ_DATA_VALID = 1'b0;
            wait_cycles = 0;
            while (RP.tx_usrapp.P_READ_DATA_VALID !== 1'b1 && wait_cycles < 50000) begin
                @(posedge RP.tx_usrapp.user_clk);
                wait_cycles = wait_cycles + 1;
            end
            if (RP.tx_usrapp.P_READ_DATA_VALID !== 1'b1) begin
                value = 32'hDEAD_DEAD;
                test_error_count = test_error_count + 1;
                $fatal(1, "RTDS_BAR_READ_TIMEOUT: bar=%0d offset=%h wait_cycles=%0d",
                       bar_index, offset, wait_cycles);
            end
            value = RP.tx_usrapp.P_READ_DATA;
            RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
            RP.tx_usrapp.TSK_TX_CLK_EAT(10);
            $display("[%t] RTDS_BAR_READ: bar=%0d offset=%h data=%h wait_cycles=%0d",
                     $realtime, bar_index, offset, value, wait_cycles);
        end
    endtask

    task automatic bar_write32(input integer bar_index, input [31:0] offset, input [31:0] value);
        begin
            RP.tx_usrapp.TSK_TX_BAR_WRITE(bar_index[2:0], offset,
                                          RP.tx_usrapp.DEFAULT_TAG,
                                          RP.tx_usrapp.DEFAULT_TC, value);
            RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
            RP.tx_usrapp.TSK_TX_CLK_EAT(20);
            $display("[%t] RTDS_BAR_WRITE: bar=%0d offset=%h data=%h", $realtime, bar_index, offset, value);
        end
    endtask

    // ---------- 语义段 6A：沿 PCIe capability 链发现并配置单向量 MSI ----------
    // RTDS_test-1ch 的 XDMA 配置是 MSI enabled、MSI-X disabled。官方 BAR_INIT
    // 不负责打开 MSI；这里模拟 Host 驱动写 message address/data 和 MSI Enable。
    task automatic configure_endpoint_msi(output bit enabled);
        reg [31:0] capability_data;
        reg [7:0]  capability_pointer;
        reg [7:0]  msi_pointer;
        integer    capability_hops;
        begin
            enabled             = 1'b0;
            capability_pointer  = 8'd0;
            msi_pointer         = 8'd0;

            RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_READ(
                RP.tx_usrapp.DEFAULT_TAG, 12'h034, 4'hF);
            RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
            RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
            capability_pointer = RP.tx_usrapp.P_READ_DATA[7:0] & 8'hFC;

            for (capability_hops = 0;
                 capability_hops < 16 && capability_pointer != 0 && msi_pointer == 0;
                 capability_hops = capability_hops + 1) begin
                RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_READ(
                    RP.tx_usrapp.DEFAULT_TAG, {4'd0, capability_pointer}, 4'hF);
                RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
                RP.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                capability_data = RP.tx_usrapp.P_READ_DATA;
                if (capability_data[7:0] == 8'h05)
                    msi_pointer = capability_pointer;
                else
                    capability_pointer = capability_data[15:8] & 8'hFC;
            end

            if (msi_pointer == 0) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_MSI_CONFIG: capability 链中未找到 MSI capability");
            end else begin
                // capability_data 保留 MSI header/control；bit 23 表示 64-bit capable。
                RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(
                    RP.tx_usrapp.DEFAULT_TAG, msi_pointer + 12'h004,
                    32'hFEE0_0000, 4'hF);
                RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
                RP.tx_usrapp.TSK_TX_CLK_EAT(100);

                if (capability_data[23]) begin
                    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(
                        RP.tx_usrapp.DEFAULT_TAG, msi_pointer + 12'h008,
                        32'h0000_0000, 4'hF);
                    RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
                    RP.tx_usrapp.TSK_TX_CLK_EAT(100);
                    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(
                        RP.tx_usrapp.DEFAULT_TAG, msi_pointer + 12'h00C,
                        32'h0000_0045, 4'h3);
                end else begin
                    RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(
                        RP.tx_usrapp.DEFAULT_TAG, msi_pointer + 12'h008,
                        32'h0000_0045, 4'h3);
                end
                RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
                RP.tx_usrapp.TSK_TX_CLK_EAT(100);

                RP.tx_usrapp.TSK_TX_TYPE0_CONFIGURATION_WRITE(
                    RP.tx_usrapp.DEFAULT_TAG, {4'd0, msi_pointer},
                    capability_data | 32'h0001_0000, 4'hC);
                RP.tx_usrapp.DEFAULT_TAG = RP.tx_usrapp.DEFAULT_TAG + 1;
                RP.tx_usrapp.TSK_TX_CLK_EAT(1000);

                enabled = EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.msi_enable;
                if (!enabled) begin
                    test_error_count = test_error_count + 1;
                    $error("RTDS_MSI_CONFIG: 写 MSI Enable 后 XDMA msi_enable 仍为 0");
                end else begin
                    milestone_msi = 1'b1;
                    $display("[%t] RTDS_MSI_CONFIG_PASS: cap=0x%02h address=FEE00000 data=0045",
                             $realtime, msi_pointer);
                end
            end
        end
    endtask

    // ---------- 语义段 6B：打开 XDMA IRQ block 的 user interrupt 0 路由 ----------
    // PCIe 配置空间 MSI Enable 与 XDMA 内部 user interrupt enable mask 是两级门控。
    // 0x2004 是 IRQ block 的 RW enable mask；bit0 对应唯一的 usr_irq_req[0]。
    task automatic configure_xdma_user_irq(output bit enabled);
        reg [31:0] irq_enable_mask;
        begin
            enabled = 1'b0;
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_2004, 32'h0000_0001, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_READ (32'h0000_2004);
            irq_enable_mask = RP.tx_usrapp.P_READ_DATA;
            if (irq_enable_mask[0] !== 1'b1) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_XDMA_USER_IRQ_ENABLE: 0x2004 readback=%h", irq_enable_mask);
            end else begin
                enabled = 1'b1;
                milestone_irq_route = 1'b1;
                $display("[%t] RTDS_XDMA_USER_IRQ_ENABLE_PASS: mask=%h vector=0",
                         $realtime, irq_enable_mask);
            end
        end
    endtask

    // ---------- 语义段 6C：主机内存、描述符和 DMA engine 封装 ----------
    task automatic host_write32(input integer address, input [31:0] value);
        begin
            RP.tx_usrapp.DATA_STORE[address+0] = value[7:0];
            RP.tx_usrapp.DATA_STORE[address+1] = value[15:8];
            RP.tx_usrapp.DATA_STORE[address+2] = value[23:16];
            RP.tx_usrapp.DATA_STORE[address+3] = value[31:24];
        end
    endtask

    task automatic init_h2c_descriptor(input [31:0] card_address, input [7:0] seed);
        integer index;
        begin
            host_write32(HOST_H2C_DESC +  0, 32'hAD4B_0013);
            host_write32(HOST_H2C_DESC +  4, FRAME_BYTES);
            host_write32(HOST_H2C_DESC +  8, HOST_SOURCE);
            host_write32(HOST_H2C_DESC + 12, 32'd0);
            host_write32(HOST_H2C_DESC + 16, card_address);
            host_write32(HOST_H2C_DESC + 20, 32'd0);
            host_write32(HOST_H2C_DESC + 24, 32'd0);
            host_write32(HOST_H2C_DESC + 28, 32'd0);
            for (index = 0; index < FRAME_BYTES; index = index + 1)
                RP.tx_usrapp.DATA_STORE[HOST_SOURCE + index] = pattern_byte(seed, index);
        end
    endtask

    task automatic init_c2h_descriptor(input [31:0] card_address, input [7:0] seed);
        integer index;
        begin
            host_write32(HOST_C2H_DESC +  0, 32'hAD4B_0013);
            host_write32(HOST_C2H_DESC +  4, FRAME_BYTES);
            host_write32(HOST_C2H_DESC +  8, card_address);
            host_write32(HOST_C2H_DESC + 12, 32'd0);
            host_write32(HOST_C2H_DESC + 16, HOST_DESTINATION);
            host_write32(HOST_C2H_DESC + 20, 32'd0);
            host_write32(HOST_C2H_DESC + 24, 32'd0);
            host_write32(HOST_C2H_DESC + 28, 32'd0);
            // CQ Host sink 才是 C2H 的目标内存；官方 DATA_STORE 只保留描述符。
            // 用期望值取反作为 sentinel，可明确区分未收到 TLP 与数据内容错误。
            for (index = 0; index < FRAME_BYTES; index = index + 1)
                CQ_HOST.HOST_MEMORY[HOST_DESTINATION + index] = ~pattern_byte(seed, index);
        end
    endtask

    // ---------- 语义段 6D：本地 AXI 事件等待 + 稀疏 PCIe 完成确认 ----------
    task automatic clear_dma_activity_monitor;
        begin
            dma_monitor_clear = 1'b1;
            repeat (2) @(posedge EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.axi_aclk);
            dma_monitor_clear = 1'b0;
            @(posedge EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.axi_aclk);
        end
    endtask

    task automatic clear_cq_host_monitor;
        begin
            cq_monitor_clear = 1'b1;
            repeat (2) @(posedge RP.user_clk);
            cq_monitor_clear = 1'b0;
            @(posedge RP.user_clk);
        end
    endtask

    task automatic wait_h2c_axi_activity(output bit completed);
        integer wait_cycles;
        begin
            completed = 1'b0;
            wait_cycles = 0;
            while ((dma_axi_write_bytes < FRAME_BYTES || dma_axi_write_responses == 0) &&
                   wait_cycles < 50000) begin
                @(posedge EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.axi_aclk);
                wait_cycles = wait_cycles + 1;
            end
            completed = (dma_axi_write_bytes >= FRAME_BYTES && dma_axi_write_responses != 0 &&
                         dma_axi_response_errors == 0);
            if (!completed) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_H2C_AXI_TIMEOUT: cycles=%0d bytes=%0d bresp=%0d errors=%0d",
                       wait_cycles, dma_axi_write_bytes, dma_axi_write_responses,
                       dma_axi_response_errors);
            end else begin
                $display("[%t] RTDS_H2C_AXI_PASS: bytes=%0d bresp=%0d wait_cycles=%0d",
                         $realtime, dma_axi_write_bytes, dma_axi_write_responses, wait_cycles);
            end
        end
    endtask

    task automatic wait_c2h_axi_activity(output bit completed);
        integer wait_cycles;
        begin
            completed = 1'b0;
            wait_cycles = 0;
            while ((dma_axi_read_bytes < FRAME_BYTES || dma_axi_read_bursts == 0) &&
                   wait_cycles < 50000) begin
                @(posedge EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.axi_aclk);
                wait_cycles = wait_cycles + 1;
            end
            completed = (dma_axi_read_bytes >= FRAME_BYTES && dma_axi_read_bursts != 0 &&
                         dma_axi_response_errors == 0);
            if (!completed) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_C2H_AXI_TIMEOUT: cycles=%0d bytes=%0d bursts=%0d errors=%0d",
                       wait_cycles, dma_axi_read_bytes, dma_axi_read_bursts,
                       dma_axi_response_errors);
            end else begin
                $display("[%t] RTDS_C2H_AXI_PASS: bytes=%0d bursts=%0d wait_cycles=%0d",
                         $realtime, dma_axi_read_bytes, dma_axi_read_bursts, wait_cycles);
            end
        end
    endtask

    task automatic wait_host_destination(input [7:0] seed, output bit completed);
        integer wait_cycles;
        reg [7:0] expected_last;
        begin
            wait_cycles = 0;
            expected_last = pattern_byte(seed, FRAME_BYTES - 1);
            while ((cq_host_write_bytes < FRAME_BYTES ||
                    CQ_HOST.HOST_MEMORY[HOST_DESTINATION + FRAME_BYTES - 1] !== expected_last) &&
                   wait_cycles < 50000) begin
                @(posedge RP.user_clk);
                wait_cycles = wait_cycles + 1;
            end
            completed = (cq_host_write_bytes >= FRAME_BYTES &&
                         CQ_HOST.HOST_MEMORY[HOST_DESTINATION + FRAME_BYTES - 1] === expected_last &&
                         cq_host_protocol_errors == 0);
            if (!completed) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_C2H_HOST_DRAIN_TIMEOUT: cycles=%0d bytes=%0d packets=%0d last_addr=%h last_expected=%02x last_actual=%02x cq_errors=%0d",
                       wait_cycles, cq_host_write_bytes, cq_memory_write_packets,
                       cq_last_write_address, expected_last,
                       CQ_HOST.HOST_MEMORY[HOST_DESTINATION + FRAME_BYTES - 1],
                       cq_host_protocol_errors);
            end else begin
                // 末字节到达后再留少量 RP 时钟，使同一批 posted writes 排空。
                repeat (32) @(posedge RP.user_clk);
                $display("[%t] RTDS_C2H_HOST_DRAIN_PASS: wait_cycles=%0d bytes=%0d packets=%0d",
                         $realtime, wait_cycles, cq_host_write_bytes,
                         cq_memory_write_packets);
            end
        end
    endtask

    task automatic check_dma_completion_sparse(
        input [31:0] count_reg,
        input [31:0] status_reg,
        output bit completed
    );
        reg [31:0] count_value;
        reg [31:0] status_value;
        integer attempt;
        begin
            completed  = 1'b0;
            count_value = 32'd0;
            attempt = 0;
            // engine 停止/重启后 completed descriptor count 不保证单调递增；
            // 计划约定的完成值是“本次 1 个描述符完成”，即 count==1。
            while (!completed && attempt < 4) begin
                RP.tx_usrapp.TSK_XDMA_REG_READ(count_reg);
                count_value = RP.tx_usrapp.P_READ_DATA;
                attempt = attempt + 1;
                if (count_value == 32'd1)
                    completed = 1'b1;
                else
                    RP.tx_usrapp.TSK_TX_CLK_EAT(500);
            end
            RP.tx_usrapp.TSK_XDMA_REG_READ(status_reg);
            status_value = RP.tx_usrapp.P_READ_DATA;
            if (!completed || status_value != 32'h0000_0006) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_DMA_COMPLETE: expected_count=1 count=%0d status=%h",
                       count_value, status_value);
            end else begin
                $display("[%t] RTDS_DMA_COMPLETE: count=%0d status=%h reads=%0d",
                         $realtime, count_value, status_value, attempt);
            end
        end
    endtask

    task automatic run_h2c_16(input [31:0] card_address, input [7:0] seed, output bit passed);
        bit axi_completed;
        bit register_completed;
        begin
            passed = 1'b0;
            $display("[%t] RTDS_STAGE_BEGIN: BASE_H2C card=%h bytes=%0d",
                     $realtime, card_address, FRAME_BYTES);
            clear_dma_activity_monitor;
            init_h2c_descriptor(card_address, seed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_0004, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_4080, HOST_H2C_DESC, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_4084, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_0004, 32'h00FF_FE7F, 4'hF);
            wait_h2c_axi_activity(axi_completed);
            check_dma_completion_sparse(32'h0000_0048, 32'h0000_0040,
                                        register_completed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_0004, 32'd0, 4'hF);
            passed = axi_completed && register_completed && dma_axi_response_errors == 0;
        end
    endtask

    task automatic run_c2h_16(input [31:0] card_address, input [7:0] seed, output bit passed);
        bit axi_completed;
        bit host_completed;
        bit register_completed;
        begin
            passed = 1'b0;
            $display("[%t] RTDS_STAGE_BEGIN: BASE_C2H card=%h bytes=%0d",
                     $realtime, card_address, FRAME_BYTES);
            clear_dma_activity_monitor;
            clear_cq_host_monitor;
            init_c2h_descriptor(card_address, seed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_1004, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_5080, HOST_C2H_DESC, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_5084, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_1004, 32'h00FF_FE7F, 4'hF);
            wait_c2h_axi_activity(axi_completed);
            wait_host_destination(seed, host_completed);
            check_dma_completion_sparse(32'h0000_1048, 32'h0000_1040,
                                        register_completed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_1004, 32'd0, 4'hF);
            passed = axi_completed && host_completed && register_completed &&
                     dma_axi_response_errors == 0;
        end
    endtask

    task automatic compare_host_destination(input [7:0] seed, output integer mismatches);
        integer index;
        begin
            mismatches = 0;
            for (index = 0; index < FRAME_BYTES; index = index + 1) begin
                if (CQ_HOST.HOST_MEMORY[HOST_DESTINATION + index] !== pattern_byte(seed, index)) begin
                    mismatches = mismatches + 1;
                    if (mismatches <= 8)
                        $error("RTDS_HOST_COMPARE: byte[%0d] expected=%02x actual=%02x", index,
                               pattern_byte(seed, index),
                               CQ_HOST.HOST_MEMORY[HOST_DESTINATION + index]);
                end
            end
            if (mismatches == 0)
                $display("[%t] RTDS_HOST_COMPARE_MATCH: 16 bytes", $realtime);
        end
    endtask

    // ---------- 语义段 7：rtds_minimum 最小闭环主用例 ----------
    // 输入：固定地址/seed、官方枚举结果和各 monitor；输出：阶段 PASS 与总结果。
    // 失败定位：每步只在本阶段置 milestone，日志最后一个 milestone 即断点入口。
    task automatic run_rtds_minimum;
        integer bar_index;
        integer mismatches;
        integer ll_mismatches;
        integer irq_wait;
        reg [31:0] read_value;
        bit h2c_ok;
        bit c2h_ok;
        bit msi_ok;
        bit irq_route_ok;
        integer total_errors;
        begin
            $display("[%t] RTDS_TEST_BEGIN: rtds_minimum", $realtime);
            LL_BFM.set_tx_backpressure(1'b0);

            // 链路已由官方 TSK_SYSTEM_INITIALIZATION/TSK_BAR_INIT 完成，这里锁定结果。
            // RP 该观测口的编码 4 表示 Gen3/8.0 GT/s（官方日志也以 4 报告 Gen3）。
            if (!ep_user_lnk_up || RP.cfg_negotiated_width != 4'd2 || RP.cfg_current_speed != 3'd4) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_LINK: up=%b width=%0d speed=%0d", ep_user_lnk_up,
                       RP.cfg_negotiated_width, RP.cfg_current_speed);
            end else begin
                milestone_link = 1'b1;
                $display("[%t] RTDS_LINK_PASS: Gen3 x2 Device=8032 Vendor=10EE", $realtime);
            end

            // XDMA control BAR 已由官方 TSK_XDMA_FIND_BAR 找到；另一内存 BAR 是用户 AXI-Lite BAR。
            user_bar = -1;
            for (bar_index = 0; bar_index < 6; bar_index = bar_index + 1) begin
                if (bar_index != RP.tx_usrapp.xdma_bar &&
                    (RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[bar_index] == 2'b10 ||
                     RP.tx_usrapp.BAR_INIT_P_BAR_ENABLED[bar_index] == 2'b11) && user_bar < 0)
                    user_bar = bar_index;
            end
            if (user_bar < 0) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_BAR: 未找到用户 AXI-Lite BAR");
            end else begin
                $display("[%t] RTDS_BAR_MAP: user_bar=%0d xdma_bar=%0d", $realtime,
                         user_bar, RP.tx_usrapp.xdma_bar);
            end

            // 官方通用初始化不打开 MSI；按 capability 链模拟 Host 驱动配置。
            configure_endpoint_msi(msi_ok);
            // Host 打开 MSI 后，还要打开 XDMA IRQ block 的 user IRQ bit0 门控。
            configure_xdma_user_irq(irq_route_ok);

            bar_read32(user_bar, 32'h0000, read_value);
            if (read_value != 32'h0000_2001) begin
                test_error_count = test_error_count + 1; $error("RTDS_INFO_VERSION=%h", read_value); end
            bar_read32(user_bar, 32'h0004, read_value);
            if (read_value != 32'h2026_0914) begin
                test_error_count = test_error_count + 1; $error("RTDS_INFO_PROG_TIME=%h", read_value); end
            bar_read32(user_bar, 32'h0008, read_value);
            if (read_value != 32'h0004_0000) begin
                test_error_count = test_error_count + 1; $error("RTDS_INFO_BUFFER=%h", read_value); end
            bar_write32(user_bar, 32'h0024, 32'h0000_8000);
            bar_write32(user_bar, 32'h0028, FRAME_BYTES);
            bar_read32(user_bar, 32'h0024, read_value);
            if (read_value != 32'h0000_8000) begin
                test_error_count = test_error_count + 1; $error("RTDS_INFO_ADDR_RB=%h", read_value); end
            bar_read32(user_bar, 32'h0028, read_value);
            if (read_value != FRAME_BYTES) begin
                test_error_count = test_error_count + 1; $error("RTDS_INFO_LEN_RB=%h", read_value); end
            milestone_bar = (test_error_count == 0);

            // 基础 XDMA：host 0x400 -> card 0x8000 -> host 0x800。
            run_h2c_16(CARD_TX_BASE, 8'h31, h2c_ok);
            run_c2h_16(CARD_TX_BASE, 8'h31, c2h_ok);
            compare_host_destination(8'h31, mismatches);
            if (!h2c_ok || !c2h_ok || mismatches != 0)
                test_error_count = test_error_count + 1;
            else begin
                milestone_base_dma = 1'b1;
                $display("[%t] RTDS_BASE_DMA_PASS: H2C+C2H 16 bytes", $realtime);
            end

            // CPU->Aurora：复用刚写入 0x8000 的确定性数据，触发 INFO_EXCH 读启动。
            $display("[%t] RTDS_STAGE_BEGIN: CPU_TO_AURORA bytes=%0d", $realtime, FRAME_BYTES);
            LL_BFM.clear_tx_capture;
            bar_write32(user_bar, 32'h0024, CARD_TX_BASE);
            bar_write32(user_bar, 32'h0028, FRAME_BYTES);
            bar_write32(user_bar, 32'h0020, 32'd0);
            bar_write32(user_bar, 32'h0020, 32'd1);
            bar_write32(user_bar, 32'h0020, 32'd0);
            LL_BFM.wait_and_compare_tx_16(8'h31, 40000, ll_mismatches);
            repeat (32) @(posedge i_sys_clk);
            if (ll_mismatches != 0 || !cpu_resp_seen_high || !cpu_resp_seen_low_after_high) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_CPU_TO_AURORA: mismatch=%0d resp_high=%b resp_low=%b",
                       ll_mismatches, cpu_resp_seen_high, cpu_resp_seen_low_after_high);
            end else begin
                milestone_cpu_to_aurora = 1'b1;
                $display("[%t] RTDS_CPU_TO_AURORA_PASS: 16 bytes", $realtime);
            end

            bar_read32(user_bar,32'h0020,read_value);
            if(read_value!=0)
                $fatal(1,"V201/DOORBELL_NOT_CLEARED");
            // Aurora->CPU：源端连续4拍，每拍仅低32bit有效，FPGA 不得反压；随后验证 IRQ、状态和 C2H。
            $display("[%t] RTDS_STAGE_BEGIN: AURORA_TO_CPU_INJECT bytes=%0d", $realtime, FRAME_BYTES);
            LL_BFM.send_rx_frame_16(8'hA5);
            $display("[%t] RTDS_STAGE_END: AURORA_TO_CPU_INJECT beats=4", $realtime);
            $display("[%t] RTDS_STAGE_BEGIN: WAIT_USER_IRQ max_cycles=50000", $realtime);
            irq_wait = 0;
            while (!EP.FPGA_CPU_irq_req && irq_wait < 50000) begin
                @(posedge i_sys_clk);
                irq_wait = irq_wait + 1;
            end
            if (!EP.FPGA_CPU_irq_req) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_IRQ_TIMEOUT: 200 us 内未看到 FPGA_CPU_irq_req");
                $display("RTDS_RX_RING_DIAG count=%0d drop=%0d", EP.DUT.u_pcie_fdma_aurora_brg_adapter.rx_ready_blocks, EP.DUT.u_pcie_fdma_aurora_brg_adapter.rx_dropped_frames);
            end else begin
                $display("[%t] RTDS_USER_IRQ_ASSERT_PASS: wait_cycles=%0d", $realtime, irq_wait);
            end

            bar_read32(user_bar,32'h0030,read_value);
            if(read_value!=1)
                $fatal(1,"V201/READY_COUNT");
            bar_read32(user_bar,32'h0034,read_value);
            if(read_value!=0)
                $fatal(1,"V201/SEQ");
            bar_read32(user_bar,32'h0038,read_value);
            if(read_value!=0)
                $fatal(1,"V201/DROP");
            bar_read32(user_bar, 32'h0018, read_value);
            if (read_value != CARD_RX_BASE) begin
                test_error_count = test_error_count + 1; $error("RTDS_RX_ADDR=%h", read_value); end
            bar_read32(user_bar, 32'h001C, read_value);
            if (read_value != FRAME_BYTES) begin
                test_error_count = test_error_count + 1; $error("RTDS_RX_LEN=%h", read_value); end
            bar_read32(user_bar, 32'h0010, read_value);
            if (read_value[0] != 1'b1) begin
                test_error_count = test_error_count + 1; $error("RTDS_INT_STATE=%h", read_value); end

            irq_wait = 0;
            while (EP.FPGA_CPU_irq_req && irq_wait < 50000) begin
                @(posedge i_sys_clk);
                irq_wait = irq_wait + 1;
            end
            if (EP.FPGA_CPU_irq_req) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_IRQ_CLEAR_TIMEOUT: read-to-clear 后 IRQ 未撤销");
            end

            run_c2h_16(CARD_RX_BASE, 8'hA5, c2h_ok);
            compare_host_destination(8'hA5, mismatches);
            bar_write32(user_bar, 32'h0014, 32'd1);
            bar_read32(user_bar, 32'h0014, read_value);
            if(read_value!=0)
                $fatal(1,"V201/ACK_NOT_CLEARED");
            repeat (32) @(posedge i_sys_clk);

            if (!c2h_ok || mismatches != 0 || ll_rx_not_ready_errors != 0 ||
                !EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_req ||
                !EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_msi_enable ||
                !EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_ack) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_AURORA_TO_CPU: c2h=%b mismatch=%0d rx_not_ready=%0d irq_req=%b msi=%b irq_ack=%b",
                       c2h_ok, mismatches, ll_rx_not_ready_errors,
                       EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_req,
                       EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_msi_enable,
                       EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_ack);
            end else begin
                milestone_aurora_to_cpu = 1'b1;
                $display("[%t] RTDS_AURORA_TO_CPU_PASS: 16 bytes irq_ack_seen=%b", $realtime,
                         EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_ack);
            end

            total_errors = test_error_count + assertion_error_count + ll_protocol_errors +
                           ll_rx_not_ready_errors + dma_axi_response_errors +
                           cq_host_protocol_errors +
                           EP.DUT.design_1_wrapper_inst.design_1_i.CONV_DMA_0.inst.u_rtds_conv_dma_axi_monitor.response_error_count;
            $display("RTDS_ROOTPORT_RESULT link=%0d bar=%0d msi=%0d irq_route=%0d base_dma=%0d cpu_to_aurora=%0d aurora_to_cpu=%0d irq_ack=%0d stalls=%0d errors=%0d",
                     milestone_link, milestone_bar, milestone_msi, milestone_irq_route, milestone_base_dma,
                     milestone_cpu_to_aurora, milestone_aurora_to_cpu,
                     EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_ack,
                     ll_tx_stall_cycles, total_errors);
            if (total_errors == 0 && milestone_link && milestone_bar && milestone_msi && milestone_irq_route && milestone_base_dma &&
                milestone_cpu_to_aurora && milestone_aurora_to_cpu) begin
                $display("RTDS_ROOTPORT_PASS");
                #100000;
                $finish;
            end else begin
                $display("RTDS_ROOTPORT_FAIL");
                #100000;
                $fatal(1, "rtds_minimum failed");
            end
        end
    endtask

    // ---------- 语义段 7A：链路训练诊断（LTSSM 打印 + 300us 链路看门狗） ----------
    // 2026-09-18 增加：simulate 首跑链路未训练、2ms 全局看门狗超时后定位用。
    // 每 5us 打印 RP/EP 两侧 LTSSM、EP user_lnk_up 与串行线跳变计数；
    // EP LTSSM 直接观察 XDMA 仿真模型实例的输出口，不修改自动生成 IP 文件。
    // 串行 GT 仿真链路通常
    // 在数十 us 内完成训练，300us 仍未 up 则提前 fatal 并携带最后 LTSSM 值，
    // 避免空跑到 2ms（约 80 分钟墙钟）。链路 up 后本看门狗自动失效。
    initial begin : LTSSM_DIAG
        integer diag_cycles;
        wait (sys_rst_n === 1'b1);
        diag_cycles = 0;
        while (!ep_user_lnk_up && diag_cycles < 300) begin
            repeat (500) @(posedge rp_sys_clk_p); // 5 us @100MHz
            diag_cycles = diag_cycles + 1;
            $display("[%t] RTDS_LTSSM_DIAG t=%0dus rp_ltssm=%b ep_ltssm=%b lnk_up=%b phy=%b width=%0d speed=%0d rp_tx_toggle=%0d ep_tx_toggle=%0d",
                     $realtime, diag_cycles * 5, RP.cfg_ltssm_state,
                     EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.inst.cfg_ltssm_state,
                     ep_user_lnk_up, RP.cfg_phy_link_status,
                     RP.cfg_negotiated_width, RP.cfg_current_speed,
                     rp_tx_transition_count, ep_tx_transition_count);
        end
        if (!ep_user_lnk_up)
            $fatal(1, "RTDS_LTSSM_STUCK: 300us 内链路未训练完成，最后 ltssm=%b", RP.cfg_ltssm_state);
        else
            $display("[%t] RTDS_LTSSM_UP: 链路训练完成", $realtime);
    end

    // ---------- 语义段 8：全局 2 ms 看门狗 ----------
    // 输入：仿真时间；输出：RTDS_TIMEOUT 和 $finish。
    // 失败定位：结合最后 milestone 判断卡住阶段；它不是性能通过判据。
    initial begin
        // 采用 250 MHz 实际时钟计数，不依赖任何模块或启动参数的 timescale。
        // 500000 周期 = 2 ms；若仿真出现真正的零时间事件风暴，外部
        // maxdeltaid/墙钟看门狗会负责终止，因为此处的时钟也无法前进。
        wait (sys_rst_n === 1'b1);
        repeat (500_000) @(posedge i_sys_clk);
        $fatal(1, "RTDS_GLOBAL_TIMEOUT: rtds_minimum 超过 2 ms");
    end
endmodule
