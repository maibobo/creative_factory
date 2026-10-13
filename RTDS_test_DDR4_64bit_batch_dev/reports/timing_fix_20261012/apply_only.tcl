# 修改记录 2026-10-12：保存CDC定点约束和完整时序优化设置；不启动综合或实现。
set root C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev
set out $root/reports/timing_fix_20261012
open_project $root/RTDS_test_DDR4_64bit.xpr
set xdc $root/rtl/rtds_ddr4_recovery_cdc.xdc
if {[llength [get_files -quiet $xdc]] == 0} {add_files -fileset constrs_1 -norecurse $xdc}
set_property USED_IN_SYNTHESIS false [get_files $xdc]
set_property USED_IN_IMPLEMENTATION true [get_files $xdc]
set_property PROCESSING_ORDER LATE [get_files $xdc]
# 修改点 2026-10-12：MIG内部33个300MHz建立时间端点保留真实时序要求。
# Explore改善布局和布线；布线后AggressiveExplore处理剩余真实建立/保持时间路径。
set run [get_runs impl_1]
set_property STRATEGY Performance_ExplorePostRoutePhysOpt $run
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore $run
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true $run
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $run
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore $run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true $run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $run
set f [open $out/applied_project_settings.txt w]
foreach p {STRATEGY STEPS.PLACE_DESIGN.ARGS.DIRECTIVE STEPS.PHYS_OPT_DESIGN.IS_ENABLED STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE} {puts $f "$p=[get_property $p $run]"}
foreach p {USED_IN_SYNTHESIS USED_IN_IMPLEMENTATION PROCESSING_ORDER} {puts $f "$p=[get_property $p [get_files $xdc]]"}
close $f
close_project
puts "TIMING_FIX_SAVED_NO_RUN_LAUNCHED"
exit
