# 独立模块前仿入口：不依赖主工程BD，不运行综合和实现。
set root [file normalize [file join [file dirname [info script]] ../..]]
set selected [lindex $argv 0]
if {$selected ni {1g ring axi axi_tail rx_fifo regs tx}} {error "expected 1g/ring/axi"}
create_project -force module_test [file join $root regression v201_runs $selected project] -part xcku040-ffva1156-2-e
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]
add_files [glob $root/rtl/rtds_*.v]
if {$selected eq "regs"} {add_files [file join $root RTDS_test_DDR4_64bit.srcs sources_1 new INFO_EXCH.v]}
if {$selected in {axi axi_tail}} {
 add_files [file join $root RTDS_test_DDR4_64bit.srcs sources_1 new CONV_DMA.v]
 add_files [file join $root rtl ddr4 rtds_axi_ram_model.sv]
}
if {$selected eq "tx"} {
 add_files -norecurse [list [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v}]]
}
add_files -fileset sim_1 [file join $root regression batch_1g rtds_${selected}_test_if.sv]
add_files -fileset sim_1 [file join $root regression batch_1g tb_rtds_${selected}.sv]
set_property top tb_rtds_${selected} [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation -mode behavioral
close_sim
close_project
