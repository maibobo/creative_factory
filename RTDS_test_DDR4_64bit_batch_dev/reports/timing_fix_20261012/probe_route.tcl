set root C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev
set out $root/reports/timing_fix_20261012/probe
file mkdir $out
set_param general.maxThreads 4
open_checkpoint $root/RTDS_test_DDR4_64bit.runs/impl_1/TOP_routed.dcp
set pipes [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_(s|m)_reset_pipe_reg\[[0-9]+\]$}]
set ready [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[[01]\]$}]
set clrs [get_pins -of_objects [concat $pipes $ready] -filter {REF_PIN_NAME == CLR}]
set d0 [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[0\]$}] -filter {REF_PIN_NAME == D}]
if {[llength $pipes] != 32 || [llength $ready] != 2 || [llength $clrs] != 34 || [llength $d0] != 1} {error "CDC_TARGET_COUNT pipes=[llength $pipes] ready=[llength $ready] clr=[llength $clrs] d0=[llength $d0]"}
foreach c [concat $pipes $ready] {if {[get_property ASYNC_REG $c] != 1} {error "ASYNC_REG missing: $c"}}
set f [open $out/cdc_targets.txt w]
puts $f "reset_pipeline_cells=32 ready_sync_cells=2 asynchronous_clear_pins=34 first_stage_D_pins=1"
puts $f "CLR targets: $clrs"
puts $f "first D: $d0"
close $f
read_xdc $root/rtl/rtds_ddr4_recovery_cdc.xdc
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file $out/after_cdc_timing.rpt
report_timing -delay_type max -slack_lesser_than 0 -max_paths 50 -file $out/remaining_setup.rpt
report_exceptions -coverage -file $out/exceptions_coverage.rpt
puts "CDC_CONSTRAINTS_APPLIED"
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file $out/final_timing.rpt
report_timing -delay_type max -slack_lesser_than 0 -max_paths 100 -file $out/final_negative_setup.rpt
report_timing -delay_type min -slack_lesser_than 0 -max_paths 100 -file $out/final_negative_hold.rpt
report_route_status -file $out/route_status.rpt
report_drc -file $out/drc.rpt
write_checkpoint -force $out/TOP_routed_fixed.dcp
set f [open $out/complete.txt w]
puts $f "Probe complete"
close $f
exit
