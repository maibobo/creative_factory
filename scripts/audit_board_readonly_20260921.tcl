# Inspect the user's completed implementation without modifying project/runs.
set root F:/RTDS_test_DDR4_64bit_batch_dev
set out $root/reports/board_audit_20260921
file mkdir $out
open_checkpoint $root/RTDS_test_DDR4_64bit.runs/impl_1/TOP_routed.dcp
report_cdc -details -file $out/cdc.rpt
report_clock_interaction -file $out/clock_interaction.rpt
set fh [open $out/synchronizer_properties.txt w]
foreach c [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/ready_sync_reg\[[01]\]$}] {
    puts $fh "$c ASYNC_REG=[get_property ASYNC_REG $c]"
}
close $fh
puts "BOARD_READONLY_AUDIT_COMPLETE"
close_design
exit 0
