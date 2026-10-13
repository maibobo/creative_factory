# 修改记录 2026-10-12：在布线后物理优化完成后生成最终报告和负裕量路径清单。
set rtds_out C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/reports/timing_fix_20261012/final_manual_implementation
file mkdir $rtds_out
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 20 -file $rtds_out/final_timing.rpt
report_timing -delay_type max -slack_lesser_than 0 -max_paths 100 -file $rtds_out/negative_max.rpt
report_timing -delay_type min -slack_lesser_than 0 -max_paths 100 -file $rtds_out/negative_min.rpt
report_route_status -file $rtds_out/route_status.rpt
report_drc -file $rtds_out/drc.rpt
report_exceptions -coverage -file $rtds_out/exceptions_coverage.rpt
write_checkpoint -force $rtds_out/TOP_routed_fixed.dcp
puts "RTDS_FINAL_TIMING_REPORT=$rtds_out/final_timing.rpt; evaluate all setup/hold/pulse-width endpoints, not just route_design WNS."
