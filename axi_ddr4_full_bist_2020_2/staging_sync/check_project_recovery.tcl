# 崩溃后工程只读体检；不启动 run、不生成 bitstream、不删除任何目录。
set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set xpr_path [file join $project_root prj compat axi_ddr4_full_bist_compat.xpr]
if {[catch {open_project $xpr_path} msg]} {
    puts "PROJECT_OPEN_FAIL $msg"
    exit 2
}
puts "PROJECT_OPEN_PASS"
puts "PROJECT_PART=[get_property PART [current_project]]"
puts "PROJECT_DIR=[get_property DIRECTORY [current_project]]"
foreach run_obj [get_runs] {
    puts "RUN [get_property NAME $run_obj] STATUS=[get_property STATUS $run_obj] PROGRESS=[get_property PROGRESS $run_obj]"
}
# Vivado 2020.2 的 IP 对象属性集合不统一；工程可打开和 run 状态是本体检验重点。
close_project
puts "PROJECT_RECOVERY_CHECK_PASS"
