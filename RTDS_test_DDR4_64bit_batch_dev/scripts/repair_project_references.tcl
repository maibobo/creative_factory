# 修复工程引用；保留用户新增的两个 register slice IP，不执行综合。
set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root RTDS_test_DDR4_64bit.xpr]
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]
set f [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/ip/aurora_64b66b_0/aurora_64b66b_0.xci}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/imports/aurora_64b66b_0_ex/imports/aurora_64b66b_0_cdc_sync_exdes.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/imports/aurora_64b66b_0_ex/imports/aurora_64b66b_0_example_axi_to_ll.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/imports/aurora_64b66b_0_ex/imports/aurora_64b66b_0_example_ll_to_axi.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/imports/aurora_64b66b_0_ex/imports/aurora_64b66b_0_exdes.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/imports/aurora_64b66b_0_ex/aurora_64b66b_0_ex.srcs/sources_1/new/aurora_64b66b_top.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_1g_periodic_tx.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_fpga_1g_init.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_fpga_bit_cdc.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_fpga_cfg_cdc.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_fpga_count_cdc.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_fpga_reset_sync.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_rx_block_writer.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {rtl/rtds_rx_frame_fifo.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/aurora1g_verified/rtl/aurora_8b10b_1p25g_axi_to_ll_exdes.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/aurora1g_verified/rtl/aurora_8b10b_1p25g_design.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/aurora1g_verified/rtl/aurora_8b10b_1p25g_ll_to_axi_exdes.v}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
set f [file join $root {external_snapshot/aurora1g_verified/ip/aurora_8b10b_1p25g.xci}]
if {![file exists $f]} {error "Missing required source: $f"}
if {[llength [get_files -quiet [list $f]]] == 0} {add_files -norecurse -fileset sources_1 [list $f]}
update_compile_order -fileset sources_1
foreach f [get_files -all *.xci] {
 if {[string match *aurora* $f] && ![regexp {/ip_[0-9]+/} $f]} {generate_target simulation [list $f]}
}
report_compile_order -fileset sources_1 -used_in synthesis -file [file join $root reports v201_source_order.txt]
report_ip_status -file [file join $root reports v201_ip_status.txt]
close_project
