# XSim 波形分组。使用 catch 是为了兼容 Xilinx 2020.2 生成层级的小差异；
# 关键对象若存在就加入，缺失对象不会阻断批处理仿真。
#
# 输入：已展开 board 层次；输出：WCFG 分组和显式 log_wave 的精选 WDB 对象。
# 作用：按 Reset/Link、RP TLP、DMA/CQ、Endpoint AXI、FDMA、Aurora LL、IRQ、
# Result 分组，不递归记录 HOST_MEMORY 或完整加密层次。
# 失败定位：某组为空先查对象层级；Simtcl warning 不得用模糊 catch/白名单隐藏；
# packed vector 位选择应记录完整向量后在 Viewer 内展开。

proc rtds_add_wave {group object {radix hex}} {
    set objects [get_objects -quiet $object]
    if {[llength $objects] > 0} {
        # add_wave 保存分组/显示配置；log_wave 才明确要求 XSim 将对象写入 WDB。
        # 两者均只作用于本文件列出的精选对象，不递归记录完整 XDMA/PCIe 层次。
        catch {add_wave -group $group -radix $radix $objects}
        catch {log_wave $objects}
    }
}

# 顶层波形采用“事务/状态摘要”原则：记录握手、地址、长度、计数和错误，
# 不把整个加密 PCIe/XDMA 层次或 HOST_MEMORY 数组递归写入 WDB。这样 WDB
# 仍能定位问题，同时避免波形模式把静态展开和运行时间放大到不可维护。

# ---------- 语义段 1：复位与链路训练 ----------
rtds_add_wave "01_Reset_Link" /board/rp_sys_clk_p bin
rtds_add_wave "01_Reset_Link" /board/rp_sys_clk_n bin
rtds_add_wave "01_Reset_Link" /board/ep_sys_clk_p bin
rtds_add_wave "01_Reset_Link" /board/ep_sys_clk_n bin
rtds_add_wave "01_Reset_Link" /board/i_sys_clk bin
rtds_add_wave "01_Reset_Link" /board/aurora_user_clk bin
rtds_add_wave "01_Reset_Link" /board/sys_rst_n bin
rtds_add_wave "01_Reset_Link" /board/ep_user_lnk_up bin
rtds_add_wave "01_Reset_Link" /board/RP/user_lnk_up bin
rtds_add_wave "01_Reset_Link" /board/RP/cfg_negotiated_width unsigned
rtds_add_wave "01_Reset_Link" /board/RP/cfg_current_speed unsigned
rtds_add_wave "01_Reset_Link" /board/RP/pcie3_uscale_rp_top_i/pcie3_uscale_core_top_inst/cfg_ltssm_state
rtds_add_wave "01_Reset_Link" /board/aurora_user_rstn bin
rtds_add_wave "01_Reset_Link" /board/aurora_channel_up bin
rtds_add_wave "01_Reset_Link" /board/aurora_lane_up bin
foreach signal {ep_pci_exp_txp ep_pci_exp_txn rp_pci_exp_txp rp_pci_exp_txn} {
    rtds_add_wave "01_Reset_Link" /board/$signal bin
}

# ---------- 语义段 2：Root Port TLP 与 Host TPI ----------
foreach signal {s_axis_rq_tvalid s_axis_rq_tready s_axis_rq_tlast s_axis_rq_tkeep s_axis_rq_tdata s_axis_rq_tuser
                m_axis_rc_tvalid m_axis_rc_tready m_axis_rc_tlast m_axis_rc_tkeep m_axis_rc_tdata m_axis_rc_tuser
                m_axis_cq_tvalid m_axis_cq_tready m_axis_cq_tlast m_axis_cq_tkeep m_axis_cq_tdata m_axis_cq_tuser
                s_axis_cc_tvalid s_axis_cc_tready s_axis_cc_tlast s_axis_cc_tkeep s_axis_cc_tdata s_axis_cc_tuser} {
    rtds_add_wave "02_RP_TLP" /board/RP/$signal
}
# CQ tuser 完整向量已经由上面的 foreach 记录，其中包含首末字节使能及
# SOP/包上下文。XSim 2020.2 batch 对 packed slice 的 log_wave 会产生
# Simtcl 6-197/6-55，因此不再重复添加位切片；查看器中按位展开完整向量即可。
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/testname ascii
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/xdma_bar unsigned
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/P_READ_DATA
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/P_READ_DATA_VALID bin
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/desc_count unsigned
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/h2c_status
rtds_add_wave "03_TPI" /board/RP/tx_usrapp/c2h_status
# DATA_STORE/HOST_MEMORY 都是大数组，不纳入默认 WDB；逐字节正确性由 scoreboard
# 证明，波形只记录地址、长度、包数、有效字节和协议错误。

# ---------- 语义段 2A：DMA 本地活动计数（用于替代高频 PCIe 轮询） ----------
foreach signal {dma_axi_write_bytes dma_axi_write_responses dma_axi_read_bytes
                dma_axi_read_bursts dma_axi_response_errors dma_monitor_clear} {
    rtds_add_wave "03_DMA_Progress" /board/$signal unsigned
}

# ---------- 语义段 2B：CQ posted-write 主机内存接收证据 ----------
foreach signal {cq_host_write_bytes cq_ignored_write_bytes cq_memory_write_packets
                cq_last_write_address cq_host_protocol_errors cq_monitor_clear} {
    rtds_add_wave "03_CQ_Host" /board/$signal unsigned
}
foreach signal {memory_write_active next_payload_address expected_payload_bytes packet_payload_bytes} {
    rtds_add_wave "03_CQ_Host" /board/CQ_HOST/$signal unsigned
}
# monitor 的 ready/valid/last 只记录包级上下文；实际 512 B 数据由 scoreboard
# 逐字节比较，避免把每个数据 beat 的完整数组复制进波形数据库。
foreach signal {tvalid tready tlast tkeep} {
    rtds_add_wave "03_CQ_Host" /board/RP/m_axis_cq_$signal
}

# ---------- 语义段 3：Endpoint XDMA AXI-MM 与 AXI-Lite ----------
set xdma_ep /board/EP/DUT/design_1_wrapper_inst/design_1_i/xdma_0
foreach signal {axi_aclk axi_aresetn
                m_axi_awaddr m_axi_awlen m_axi_awvalid m_axi_awready
                m_axi_wdata m_axi_wstrb m_axi_wlast m_axi_wvalid m_axi_wready
                m_axi_bresp m_axi_bvalid m_axi_bready
                m_axi_araddr m_axi_arlen m_axi_arvalid m_axi_arready
                m_axi_rdata m_axi_rresp m_axi_rlast m_axi_rvalid m_axi_rready
                m_axil_awaddr m_axil_awvalid m_axil_awready
                m_axil_wdata m_axil_wstrb m_axil_wvalid m_axil_wready
                m_axil_bresp m_axil_bvalid m_axil_bready
                m_axil_araddr m_axil_arvalid m_axil_arready
                m_axil_rdata m_axil_rresp m_axil_rvalid m_axil_rready} {
    rtds_add_wave "04_Endpoint_AXI" $xdma_ep/$signal
}

# ---------- 语义段 4：RTDS adapter 与 FDMA ----------
foreach signal {fdma_raddr fdma_rareq fdma_rbusy fdma_rsize
                fdma_waddr fdma_wareq fdma_wbusy fdma_wsize
                FPGA_CPU_irq_req CPU_WR_DONE_resp CLEAR_INTER_R
                rx_overflow_sticky rx_overrun_sticky tx_underflow_sticky
                fdma_timeout_sticky length_error_sticky link_down_sticky} {
    rtds_add_wave "04_RTDS_FDMA" /board/EP/$signal
}
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/fdma_rvalid bin
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/fdma_rready bin
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/CPU_REC_STATE_R bin
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/CPU_REC_STATE_W bin
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/rx_pending bin
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/fdma_w_source_valid bin
rtds_add_wave "04_RTDS_FDMA" /board/EP/DUT/fdma_w_accept bin
# 写方向不可把“数据源 valid”误认为外部可反压的 Aurora ready；这里同时
# 展示 wareq/wbusy/waddr/wsize 和 accept，便于确认 FDMA 请求及真实握手。

# ---------- 语义段 5：Aurora LocalLink（RX 为不可反压连续源） ----------
foreach signal {aurora_tx_d aurora_tx_sof aurora_tx_eof aurora_tx_rem aurora_tx_src_rdy aurora_tx_dst_rdy
                aurora_rx_d aurora_rx_sof aurora_rx_eof aurora_rx_rem aurora_rx_src_rdy aurora_rx_dst_rdy} {
    rtds_add_wave "05_Aurora_LL" /board/$signal
}
rtds_add_wave "05_Aurora_LL" /board/LL_BFM/tx_capture_count unsigned
rtds_add_wave "05_Aurora_LL" /board/LL_BFM/rx_not_ready_errors unsigned

# ---------- 语义段 6：XDMA IRQ 与测试里程碑 ----------
set irq_mon /board/EP/DUT/design_1_wrapper_inst/design_1_i/xdma_0/u_rtds_xdma_irq_monitor
foreach signal {usr_irq_req usr_irq_ack msi_enable seen_req seen_ack seen_msi_enable} {
    rtds_add_wave "06_XDMA_IRQ" $irq_mon/$signal
}
# 状态机生命周期：CPU_WR_DONE_resp 应出现 0->1->0，CLEAR_INTER_R 清除
# sticky 状态，CPU_REC_STATE_R/W 完成接收路径释放/重新武装。
foreach signal {FPGA_CPU_irq_req CPU_WR_DONE_resp CLEAR_INTER_R CPU_REC_STATE_R CPU_REC_STATE_W} {
    if {$signal eq "CPU_REC_STATE_R" || $signal eq "CPU_REC_STATE_W"} {
        rtds_add_wave "06_XDMA_IRQ" /board/EP/DUT/$signal bin
    } else {
        rtds_add_wave "06_XDMA_IRQ" /board/EP/$signal bin
    }
}
foreach signal {milestone_link milestone_bar milestone_msi milestone_irq_route milestone_base_dma milestone_cpu_to_aurora milestone_aurora_to_cpu test_error_count} {
    rtds_add_wave "07_Result" /board/$signal
}
