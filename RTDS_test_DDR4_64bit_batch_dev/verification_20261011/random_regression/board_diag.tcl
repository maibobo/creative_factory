run 5 us
foreach s {received cfg cfgv configured done req busy rv ready valid core_reset gt_reset dut.tx_active dut.tx_recovering dut.tx_restart_pending dut.link_up_fdma} {
    set path /tb_board_cdc_smoke/[string map {. /} $s]
    puts "SMOKE_DIAG $s=[get_value $path]"
}
quit
