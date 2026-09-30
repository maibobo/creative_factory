# 在独立远程开发工程生成IP仿真输出并补充约束；不启动综合/实现。
set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root RTDS_test_DDR4_64bit.xpr]
set constraints [file join $root rtl aurora1g_board.xdc]
if {[llength [get_files -quiet $constraints]] == 0} {add_files -fileset constrs_1 $constraints}
foreach ipfile [get_files -all *.xci] {
    if {[get_property IS_ENABLED $ipfile] && ![string match */bd/* $ipfile] && ![regexp {/ip_[0-9]+/} $ipfile]} {
        generate_target simulation [list $ipfile]
    }
}
set wrapper [file join $root RTDS_test_DDR4_64bit.srcs sources_1 bd design_1 hdl design_1_wrapper.v]
set generated [make_wrapper -files [get_files design_1.bd] -top]
if {[llength $generated] != 1} {error "Expected one design_1 wrapper"}
if {[file normalize $generated] ne [file normalize $wrapper]} {file copy -force $generated $wrapper}
update_compile_order -fileset sources_1
report_ip_status -file [file join $root reports v201_ip_status.txt]
close_project
