# Read-only checkpoint analysis; never launches synthesis or implementation.
set root F:/RTDS_test_DDR4_64bit_batch_dev
set out [file dirname [file normalize [info script]]]
open_checkpoint $root/RTDS_test_DDR4_64bit.runs/impl_1/TOP_routed.dcp
set stage0 [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/ready_sync_reg\[0\]$}]
set stage1 [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/ready_sync_reg\[1\]$}]
foreach cell_list [list $stage0 $stage1] {
    if {[llength $cell_list] != 1} {error "Expected exactly one synchronizer cell"}
    set async_value [get_property ASYNC_REG $cell_list]
    puts "SYNC_ATTRIBUTE cell=$cell_list ASYNC_REG=$async_value"
    if {![string is boolean -strict $async_value]} {error "ASYNC_REG not boolean"}
    if {!$async_value} {error "ASYNC_REG missing"}
}
set d0 [get_pins -of_objects $stage0 -filter {REF_PIN_NAME == D}]
set q0 [get_pins -of_objects $stage0 -filter {REF_PIN_NAME == Q}]
set d1 [get_pins -of_objects $stage1 -filter {REF_PIN_NAME == D}]
set before [get_timing_paths -to $d0 -max_paths 1]
if {[llength $before] != 1} {error "Baseline failing path missing"}
puts "BASELINE_STAGE0_SLACK=[get_property SLACK $before]"
# Exercise the real XDC parser, not source or a copied Tcl fragment.
read_xdc $root/RTDS_test_DDR4_64bit.srcs/constrs_1/new/DDR4_PIN.xdc
if {[llength [get_timing_paths -to $d0 -max_paths 1]] != 0} {error "Stage0 exception inactive"}
set stage1_path [get_timing_paths -from $q0 -to $d1 -max_paths 1]
if {[llength $stage1_path] != 1} {error "Stage1 must remain timed"}
puts "STAGE1_SLACK=[get_property SLACK $stage1_path]"
report_timing_summary -max_paths 3 -file $out/timing_summary_after_xdc.rpt
report_exceptions -file $out/exceptions_after_xdc.rpt
report_timing -from $q0 -to $d1 -file $out/stage1_timing.rpt
puts "RTDS_XDC_READ_CHECK_PASS"
close_design
exit 0
