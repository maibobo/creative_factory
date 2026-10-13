# 修改点 2026-10-13：只检查完整TOP的RTL展开，-rtl不做网表综合。
source [file join [file dirname [info script]] register_rx_vio_20261013.tcl]
set out [file join $root verification_20261013 vio_smoke]
file mkdir $out
set part [get_property PART [current_project]]
synth_design -rtl -top TOP -part $part -name rtl_vio -generic RX_VIO_TEST_ENABLE=1
set fh [open [file join $out rtl_elaboration_summary.txt] w]
puts $fh "RTL_ELABORATION_PASS RX_VIO_TEST_ENABLE=1"
puts $fh "part=$part"
puts $fh "generic=[get_property generic [get_filesets sources_1]]"
puts $fh "stim=[get_cells -hier -filter {REF_NAME == RTDS_RX_VIO_STIM}]"
puts $fh "vio=[get_cells -hier -filter {REF_NAME == vio_rtds_rx_start}]"
close $fh
puts "RTL_ELABORATION_PASS"
close_design
close_project
exit
