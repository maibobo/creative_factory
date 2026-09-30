set root F:/RTDS_test_DDR4_64bit_batch_dev
open_project $root/RTDS_test_DDR4_64bit.xpr
set ip10 [get_ips aurora_64b66b_0]
set_property CONFIG.C_REFCLK_SOURCE MGTREFCLK0_of_Quad_X0Y2 $ip10
if {[get_property CONFIG.C_REFCLK_SOURCE $ip10] ne "MGTREFCLK0_of_Quad_X0Y2"} {
    error "10G reference clock selection was not applied"
}
generate_target all $ip10
puts "AURORA10G_REFCLK=[get_property CONFIG.C_REFCLK_SOURCE $ip10]"
report_ip_status -file $root/reports/board_audit_20260921/ip_status_final.rpt
puts "RPT205_REFCLK_COMPLETE_NO_RUNS_LAUNCHED"
close_project
exit 0
