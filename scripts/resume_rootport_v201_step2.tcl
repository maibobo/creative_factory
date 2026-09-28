# 续跑 XDMA Root Port 集成前仿：不重新 export（避免覆盖 gthe3 仿真源码补丁），
# 直接在工作目录依次执行已生成的 compile/elaborate/simulate 三步。
# 前置（已由 resume_rootport_v201.tcl 完成）：export_ip_user_files 刷新 + scripts_only 生成 + util_ds_buf 实体同步。
# 本轮修复：① board.sv DUT 层次引用（rx_ready_blocks）；② gthe3.v part-select 兼容补丁（scripts\patch_gtwizard_gthe3_20260916.py）。
set root [file normalize [file join [file dirname [info script]] ..]]
set work [file join $root RTDS_test_DDR4_64bit.sim sim_xdma_rootport behav xsim]
cd $work
foreach step {compile elaborate simulate} {
    puts "V201_STEP2_BEGIN $step"
    set failed [catch {exec cmd /c ${step}.bat 2>@1} output]
    puts $output
    if {$failed || [regexp -nocase {ERROR:|FATAL:|RTDS_ROOTPORT_FAIL} $output]} {error "V201 step2 $step failed; inspect output"}
}
puts "V201_STEP2_ALL_OK"
exit 0
