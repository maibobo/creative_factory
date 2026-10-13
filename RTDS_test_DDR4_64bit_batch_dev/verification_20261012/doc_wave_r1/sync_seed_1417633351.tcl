set scope /tb_rtds_sync
log_wave -r ${scope}/*
set objects [get_objects -r ${scope}/*]
set fh [open {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/doc_wave_r1/sync_seed_1417633351.capture/recorded_signals.txt} w]
foreach obj $objects {puts $fh $obj}
close $fh
create_wave_config
set shown 0
foreach obj $objects {if {[regexp {(^/[^/]+/(clk|fdma_clk|user_clk|src_clk|clk_250m|rst_n|ticks|frames|beat)$)|(/bus/[^/]+$)|(/H/(clk|uclk|gclk|rst_n|pcie_up|channel_up|lane_up|ddr_reset_n|ddr_ready|hold_r|hold_b|tx_ready|fdma_rbusy|fdma_rareq|fdma_rdata|fdma_rvalid|fdma_rready|tx_valid|tx_data|tx_sof|tx_eof|done_event|cfg_byte|cfg_valid|cfg_pulses|tx_frames|tx_beats|gdata|gvalid|gsof|geof|configured|configured_id|tick_2us|gpio_50us)$)|(/U_ADAPTER/(tx_active|tx_recovering|tx_quiet_count|tx_user_quiet_fdma|tx_deliver_enable|link_up_fdma|tx_frame_done_fdma|tx_restart_pending)$)|(/U_DMA/(read_curr_st|M_AXI_RVALID|M_AXI_RREADY|M_AXI_RDATA)$)|(/U_DDR/(storage_ready|recovery_read_pending|recovery_read_abort|recovery_read_left|recovery_rvalid|recovery_rresp|recovery_rlast)$)} $obj]} {catch {add_wave $obj};incr shown}}
if {$shown==0} {add_wave ${scope}/*}
save_wave_config {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/doc_wave_r1/sync_seed_1417633351.capture/recommended.wcfg}
open_vcd {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/doc_wave_r1/sync_seed_1417633351.capture/trace.vcd}
log_vcd $objects
run all
close_vcd
puts "CAPTURE_DONE=sync_seed_1417633351"
quit
