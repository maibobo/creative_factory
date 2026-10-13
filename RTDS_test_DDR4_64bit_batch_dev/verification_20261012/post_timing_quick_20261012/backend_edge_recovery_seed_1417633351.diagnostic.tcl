set scope /tb_backend_edge_recovery
log_wave -r ${scope}/*
set objs [get_objects -r ${scope}/*]
set f [open {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/post_timing_quick_20261012/backend_edge_recovery_seed_1417633351.capture/recorded_signals.txt} w]
foreach obj $objs {puts $f $obj}
close $f
create_wave_config
foreach obj $objs {if {[regexp {(^/tb_backend_edge_recovery/clk$)|(^/tb_backend_edge_recovery/B/[^/]+$)|(/U_DDR/(storage_ready|sim_ready_pipe|recovery_read_pending|recovery_read_abort|recovery_read_left|recovery_rload|recovery_rvalid|recovery_rdata|recovery_rresp|recovery_rlast|recovery_write_abort|recovery_write_left|mem_wvalid)$)} $obj]} {catch {add_wave $obj}}}
save_wave_config {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/post_timing_quick_20261012/backend_edge_recovery_seed_1417633351.capture/recommended.wcfg}
open_vcd {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/verification_20261012/post_timing_quick_20261012/backend_edge_recovery_seed_1417633351.capture/trace.vcd}
log_vcd $objs
run all
close_vcd
quit
