-makelib ies_lib/xilinx_vip -sv \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "C:/Xilinx/Vivado/2020.2/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib ies_lib/xpm -sv \
  "C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
  "C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/gtwizard_ultrascale_v1_7_9 \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_bit_sync.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gte4_drp_arb.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_delay_powergood.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_delay_powergood.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe3_cpll_cal.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe3_cal_freqcnt.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_rx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_tx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gthe4_cal_freqcnt.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_rx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_tx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtye4_cal_freqcnt.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_rx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_tx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_reset.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userclk_rx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userclk_tx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userdata_rx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_gtwiz_userdata_tx.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_reset_sync.v" \
  "../../../ipstatic/hdl/gtwizard_ultrascale_v1_7_reset_inv_sync.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/ip_0/sim/gtwizard_ultrascale_v1_7_gthe3_channel.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/ip_0/sim/aurora_8b10b_1p25g_gt_gthe3_channel_wrapper.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/ip_0/sim/aurora_8b10b_1p25g_gt_gtwizard_gthe3.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/ip_0/sim/aurora_8b10b_1p25g_gt_gtwizard_top.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/ip_0/sim/aurora_8b10b_1p25g_gt.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_reset_logic.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g_core.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_support.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_support_reset_logic.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_clock_module.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_aurora_lane_4byte.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_axi_to_ll.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_channel_err_detect.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_channel_init_sm.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_chbond_count_dec_4byte.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_crc_top.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_err_detect_4byte.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_global_logic.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_hotplug.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_idle_and_ver_gen.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_lane_init_sm_4byte.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_left_align_control.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_left_align_mux.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_ll_to_axi.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_output_mux.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_output_switch_control.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_rx_ll.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_rx_ll_deframer.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_rx_ll_pdu_datapath.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_rxcrc.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_sideband_output.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_standard_cc_module.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_storage_ce_control.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_storage_count_control.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_storage_mux.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_storage_switch_control.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_sym_dec_4byte.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_sym_gen_4byte.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_cdc_sync.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/gt/aurora_8b10b_1p25g_transceiver_wrapper.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_tx_ll.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_tx_ll_control.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_tx_ll_datapath.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_txcrc.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g/src/aurora_8b10b_1p25g_valid_data_counter.v" \
  "../../../../../aurora_8b10b_1p25g_design.gen/sources_1/ip/aurora_8b10b_1p25g/aurora_8b10b_1p25g.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

