set scope /tb_backend_edge_recovery
log_wave -r ${scope}/*
set objects [get_objects -r ${scope}/*]
set fh [open {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/edge_criteria_closure_20261012_early/backend_edge_recovery_seed_1417633351.capture/recorded_signals.txt} w]
foreach obj $objects {puts $fh $obj}
close $fh
create_wave_config
foreach obj $objects {if {[regexp {(^/[^/]+/(clk|M_AXI_ACLK|fdma_clk|user_clk|src_clk|clk_250m|rst_n|frames|beat|tick_toggle_2us|cpu_sync_50us)$)|(/(bus|B)/[^/]+$)|(/H/[^/]+$)|(/U_ADAPTER/(tx_active|tx_recovering|tx_quiet_count|tx_user_quiet_fdma|tx_deliver_enable|link_up_fdma|tx_frame_done_fdma|tx_restart_pending)$)|(/U_DMA/(read_curr_st|M_AXI_RVALID|M_AXI_RREADY|M_AXI_RDATA)$)|(/U_DDR/(storage_ready|recovery_read_pending|recovery_read_abort|recovery_read_left|recovery_rvalid|recovery_rdata|recovery_rid|recovery_rresp|recovery_rlast|recovery_write_pending|recovery_write_abort|recovery_write_left|recovery_bvalid|recovery_bid|recovery_bresp)$)|(/U_DUT/(time_count|tick|state|half_valid|used_bytes|publish_seq)$)} $obj]} {catch {add_wave $obj}}}
save_wave_config {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/edge_criteria_closure_20261012_early/backend_edge_recovery_seed_1417633351.capture/recommended.wcfg}
open_vcd {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/edge_criteria_closure_20261012_early/backend_edge_recovery_seed_1417633351.capture/trace.vcd}
log_vcd $objects
run all
close_vcd
puts "CAPTURE_DONE=backend_edge_recovery_seed_1417633351"
quit
