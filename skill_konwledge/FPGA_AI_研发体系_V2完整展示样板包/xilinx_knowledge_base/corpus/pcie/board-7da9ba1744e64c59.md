# board

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\tb\board.sv`
- SHA-256: `7da9ba1744e64c593b9436d5092b55c6d5a24a81ea9daefeb502798637b3c4ac`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```systemverilog
`timescale 1ps / 1ps

`include "board_common.vh"
`include "xdma_irq_monitor.sv"
`include "conv_dma_axi_monitor.sv"
`define SIMULATION

// RTDS_test-1ch 真实 Endpoint + Xilinx 官方 Root Port 大仿真顶层。
// 模块名必须保持 board，官方 TPI 使用 board.RP.tx_usrapp 的层级任务。
module board;
    import rtds_rootport_pkg::*;

    parameter REF_CLK_FREQ = 0;
    parameter C_DATA_WIDTH = 64;
    localparam integer REF_CLK_HALF_CYCLE = 5000; // 100 MHz，单位 ps
    localparam [4:0] LINK_WIDTH = 5'd2;
    localparam [2:0] LINK_SPEED = 3'h4;
    localparam [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b010;

    // ---------- 语义段 1：时钟、复位和 PCIe x2 串行互连 ----------
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

    // ---------- 语义段 2：真实 RTDS Endpoint 与官方 Root Port ----------
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

    // ---------- 语义段 3：LocalLink BFM、scoreboard 和集成断言 ----------
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

    task automatic init_c2h_descriptor(input [31:0] card_address);
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
            for (index = 0; index < FRAME_BYTES; index = index + 1)
                RP.tx_usrapp.DATA_STORE[HOST_DESTINATION + index] = 8'd0;
        end
    endtask

    task automatic wait_dma_completion(
        input [31:0] count_reg,
        input [31:0] status_reg,
        input [31:0] count_before,
        output bit completed
    );
        reg [31:0] count_value;
        reg [31:0] status_value;
        time start_time;
        begin
            completed  = 1'b0;
            count_value = count_before;
            start_time = $time;
            // 当前 timeunit 为 1 ps，因此 200 us = 200_000_000 个时间单位。
            while (!completed && (($time - start_time) < 200_000_000)) begin
                RP.tx_usrapp.TSK_XDMA_REG_READ(count_reg);
                count_value = RP.tx_usrapp.P_READ_DATA;
                if (count_value != count_before)
                    completed = 1'b1;
                else
                    RP.tx_usrapp.TSK_TX_CLK_EAT(20);
            end
            RP.tx_usrapp.TSK_XDMA_REG_READ(status_reg);
            status_value = RP.tx_usrapp.P_READ_DATA;
            if (!completed || status_value != 32'h0000_0006) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_DMA_COMPLETE: count_before=%0d count=%0d status=%h",
                       count_before, count_value, status_value);
            end else begin
                $display("[%t] RTDS_DMA_COMPLETE: count=%0d status=%h", $realtime, count_value, status_value);
            end
        end
    endtask

    task automatic run_h2c_512(input [31:0] card_address, input [7:0] seed, output bit passed);
        reg [31:0] count_before;
        bit completed;
        begin
            passed = 1'b0;
            init_h2c_descriptor(card_address, seed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_0004, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_4080, HOST_H2C_DESC, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_4084, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_READ(32'h0000_0048);
            count_before = RP.tx_usrapp.P_READ_DATA;
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_0004, 32'h00FF_FE7F, 4'hF);
            wait_dma_completion(32'h0000_0048, 32'h0000_0040, count_before, completed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_0004, 32'd0, 4'hF);
            passed = completed;
        end
    endtask

    task automatic run_c2h_512(input [31:0] card_address, output bit passed);
        reg [31:0] count_before;
        bit completed;
        begin
            passed = 1'b0;
            init_c2h_descriptor(card_address);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_1004, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_5080, HOST_C2H_DESC, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_5084, 32'd0, 4'hF);
            RP.tx_usrapp.TSK_XDMA_REG_READ(32'h0000_1048);
            count_before = RP.tx_usrapp.P_READ_DATA;
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_1004, 32'h00FF_FE7F, 4'hF);
            wait_dma_completion(32'h0000_1048, 32'h0000_1040, count_before, completed);
            RP.tx_usrapp.TSK_XDMA_REG_WRITE(32'h0000_1004, 32'd0, 4'hF);
            passed = completed;
        end
    endtask

    task automatic compare_host_destination(input [7:0] seed, output integer mismatches);
        integer index;
        begin
            mismatches = 0;
            for (index = 0; index < FRAME_BYTES; index = index + 1) begin
                if (RP.tx_usrapp.DATA_STORE[HOST_DESTINATION + index] !== pattern_byte(seed, index)) begin
                    mismatches = mismatches + 1;
                    if (mismatches <= 8)
                        $error("RTDS_HOST_COMPARE: byte[%0d] expected=%02x actual=%02x", index,
                               pattern_byte(seed, index),
                               RP.tx_usrapp.DATA_STORE[HOST_DESTINATION + index]);
                end
            end
            if (mismatches == 0)
                $display("[%t] RTDS_HOST_COMPARE_MATCH: 512 bytes", $realtime);
        end
    endtask

    // ---------- 语义段 7：rtds_minimum 最小闭环主用例 ----------
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
            if (read_value != 32'h0000_1001) begin test_error_count = test_error_count + 1; $error("RTDS_INFO_VERSION=%h", read_value); end
            bar_read32(user_bar, 32'h0004, read_value);
            if (read_value != 32'h2026_0506) begin test_error_count = test_error_count + 1; $error("RTDS_INFO_PROG_TIME=%h", read_value); end
            bar_read32(user_bar, 32'h0008, read_value);
            if (read_value != 32'h0000_8000) begin test_error_count = test_error_count + 1; $error("RTDS_INFO_BUFFER=%h", read_value); end
            bar_write32(user_bar, 32'h0024, 32'h0000_8000);
            bar_write32(user_bar, 32'h0028, FRAME_BYTES);
            bar_read32(user_bar, 32'h0024, read_value);
            if (read_value != 32'h0000_8000) begin test_error_count = test_error_count + 1; $error("RTDS_INFO_ADDR_RB=%h", read_value); end
            bar_read32(user_bar, 32'h0028, read_value);
            if (read_value != FRAME_BYTES) begin test_error_count = test_error_count + 1; $error("RTDS_INFO_LEN_RB=%h", read_value); end
            milestone_bar = (test_error_count == 0);

            // 基础 XDMA：host 0x400 -> card 0x8000 -> host 0x800。
            run_h2c_512(CARD_TX_BASE, 8'h31, h2c_ok);
            run_c2h_512(CARD_TX_BASE, c2h_ok);
            compare_host_destination(8'h31, mismatches);
            if (!h2c_ok || !c2h_ok || mismatches != 0)
                test_error_count = test_error_count + 1;
            else begin
                milestone_base_dma = 1'b1;
                $display("[%t] RTDS_BASE_DMA_PASS: H2C+C2H 512 bytes", $realtime);
            end

            // CPU->Aurora：复用刚写入 0x8000 的确定性数据，触发 INFO_EXCH 读启动。
            LL_BFM.clear_tx_capture;
            bar_write32(user_bar, 32'h0024, CARD_TX_BASE);
            bar_write32(user_bar, 32'h0028, FRAME_BYTES);
            bar_write32(user_bar, 32'h0020, 32'd0);
            bar_write32(user_bar, 32'h0020, 32'd1);
            bar_write32(user_bar, 32'h0020, 32'd0);
            LL_BFM.wait_and_compare_tx_512(8'h31, 40000, ll_mismatches);
            repeat (32) @(posedge i_sys_clk);
            if (ll_mismatches != 0 || !cpu_resp_seen_high || !cpu_resp_seen_low_after_high) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_CPU_TO_AURORA: mismatch=%0d resp_high=%b resp_low=%b",
                       ll_mismatches, cpu_resp_seen_high, cpu_resp_seen_low_after_high);
            end else begin
                milestone_cpu_to_aurora = 1'b1;
                $display("[%t] RTDS_CPU_TO_AURORA_PASS: 512 bytes", $realtime);
            end

            // Aurora->CPU：源端连续 64 拍，FPGA 不得反压；随后验证 IRQ、状态和 C2H。
            LL_BFM.send_rx_frame_512(8'hA5);
            irq_wait = 0;
            while (!EP.FPGA_CPU_irq_req && irq_wait < 50000) begin
                @(posedge i_sys_clk);
                irq_wait = irq_wait + 1;
            end
            if (!EP.FPGA_CPU_irq_req) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_IRQ_TIMEOUT: 200 us 内未看到 FPGA_CPU_irq_req");
            end

            bar_read32(user_bar, 32'h0018, read_value);
            if (read_value != CARD_RX_BASE) begin test_error_count = test_error_count + 1; $error("RTDS_RX_ADDR=%h", read_value); end
            bar_read32(user_bar, 32'h001C, read_value);
            if (read_value != FRAME_BYTES) begin test_error_count = test_error_count + 1; $error("RTDS_RX_LEN=%h", read_value); end
            bar_read32(user_bar, 32'h0010, read_value);
            if (read_value[0] != 1'b1) begin test_error_count = test_error_count + 1; $error("RTDS_INT_STATE=%h", read_value); end

            irq_wait = 0;
            while (EP.FPGA_CPU_irq_req && irq_wait < 50000) begin
                @(posedge i_sys_clk);
                irq_wait = irq_wait + 1;
            end
            if (EP.FPGA_CPU_irq_req) begin
                test_error_count = test_error_count + 1;
                $error("RTDS_IRQ_CLEAR_TIMEOUT: read-to-clear 后 IRQ 未撤销");
            end

            run_c2h_512(CARD_RX_BASE, c2h_ok);
            compare_host_destination(8'hA5, mismatches);
            bar_write32(user_bar, 32'h0014, 32'd1);
            bar_write32(user_bar, 32'h0014, 32'd0);
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
                $display("[%t] RTDS_AURORA_TO_CPU_PASS: 512 bytes irq_ack_seen=%b", $realtime,
                         EP.DUT.design_1_wrapper_inst.design_1_i.xdma_0.u_rtds_xdma_irq_monitor.seen_ack);
            end

            total_errors = test_error_count + assertion_error_count + ll_protocol_errors +
                           ll_rx_not_ready_errors +
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

    // ---------- 语义段 8：全局 2 ms 看门狗 ----------
    initial begin
        // 当前 timeunit 为 1 ps，因此 2 ms = 2_000_000_000 个时间单位。
        #2_000_000_000;
        $fatal(1, "RTDS_GLOBAL_TIMEOUT: rtds_minimum 超过 2 ms");
    end
endmodule
```
