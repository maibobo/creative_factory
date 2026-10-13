# 修改记录 2026-10-12：在用户当前Vivado工程会话中保存时序优化设置，不启动任何run。
set rtds_root C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev
if {[llength [get_projects -quiet]] != 1} {error "Open the RTDS project before sourcing this script"}
if {![string equal -nocase [file normalize [get_property DIRECTORY [current_project]]] [file normalize $rtds_root]]} {error "Wrong project directory; no changes applied"}
set rtds_run [get_runs impl_1]
set_property STRATEGY Performance_ExplorePostRoutePhysOpt $rtds_run
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore $rtds_run
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true $rtds_run
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $rtds_run
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore $rtds_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true $rtds_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $rtds_run
# 修改点 2026-10-12：按用户要求不安装额外加载检查；仅清除本次自己的旧检查hook。
if {[string equal [get_property STEPS.INIT_DESIGN.TCL.POST $rtds_run] $rtds_root/reports/timing_fix_20261012/verify_loaded_cdc.tcl]} {
    set_property STEPS.INIT_DESIGN.TCL.POST {} $rtds_run
}
# 修改点 2026-10-12：生成布线后物理优化的最终报告，不能只查看route阶段旧报告。
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST $rtds_root/reports/timing_fix_20261012/report_final_timing.tcl $rtds_run
set rtds_f [open $rtds_root/reports/timing_fix_20261012/gui_applied_settings.txt w]
foreach rtds_p {STRATEGY STEPS.PLACE_DESIGN.ARGS.DIRECTIVE STEPS.PHYS_OPT_DESIGN.IS_ENABLED STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE STEPS.INIT_DESIGN.TCL.POST STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST} {
    puts $rtds_f "$rtds_p=[get_property $rtds_p $rtds_run]"
    puts "$rtds_p=[get_property $rtds_p $rtds_run]"
}
close $rtds_f
puts "RTDS_SETTINGS_APPLIED_IN_CURRENT_GUI; no run launched. Reset the completed implementation and run through post_route_phys_opt_design."
