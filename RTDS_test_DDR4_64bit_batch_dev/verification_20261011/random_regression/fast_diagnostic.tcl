set p /tb_xdma_rtds_trythrough
foreach t {200 400 1000 4000} {
    run $t ns
    foreach n {cpu_fpga_start_addr cpu_fpga_len cpu_wr_done_shadow rd_start cpu_wr_done_resp cpu_wr_done_event fdma_rareq fdma_rbusy fdma_rready fdma_rvalid dut/tx_active dut/tx_recovering dut/tx_start_valid dut/tx_config_valid dut/link_up_fdma dut/tx_user_quiet_fdma dut/tx_quiet_count} {
        set o [get_objects -quiet $p/$n]
        if {[llength $o]} {puts "FAST_DIAG t=[current_time] $n=[get_value -radix hex $o]"}
    }
}
quit
