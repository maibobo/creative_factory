open_checkpoint {F:/RTDS_test_DDR4_64bit_batch_dev/RTDS_test_DDR4_64bit.runs/impl_1/TOP_routed.dcp}

set pcie_ports [get_ports -quiet {pcie_diff_clk_p[0]}]
if {[llength $pcie_ports] != 1} {
    error "expected one top-level PCIe reference clock port"
}
if {[llength [get_clocks -quiet pcie_refclk_100m]] == 0} {
    create_clock -period 10.000 -name pcie_refclk_100m $pcie_ports
}

set sync_stage0 [get_cells -quiet -hier -regexp {.*u_rtds_ddr4_backend/ready_sync_reg\[0\]$}]
if {[llength $sync_stage0] != 1} {
    error "expected one ready synchronizer stage-0 cell, got [llength $sync_stage0]"
}
set sync_stage0_d [get_pins -of_objects $sync_stage0 -filter {REF_PIN_NAME == D}]
if {[llength $sync_stage0_d] != 1} {
    error "expected one ready synchronizer stage-0 D pin, got [llength $sync_stage0_d]"
}
set_false_path -to $sync_stage0_d

puts "RTDS_TIMING_CONSTRAINT_SMOKE_PASS pcie_ports=[llength $pcie_ports] sync_stage0=[llength $sync_stage0] sync_stage0_d=[llength $sync_stage0_d]"
close_design
exit 0
