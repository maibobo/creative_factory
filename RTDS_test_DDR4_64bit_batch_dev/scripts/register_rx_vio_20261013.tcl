# 修改点 2026-10-13：登记最小VIO和测试源。仅生成IP输出文件，不启动综合或实现。
set root [file normalize [file join [file dirname [info script]] ..]]
set xpr [file join $root RTDS_test_DDR4_64bit.xpr]
if {[current_project -quiet] eq ""} {open_project $xpr}
if {[file normalize [get_property DIRECTORY [current_project]]] ne $root} {
    error "Please open the RTDS_test_DDR4_64bit_batch_dev project before sourcing this script"
}
set rtl [file join $root rtl rtds_rx_vio_stim.v]
if {[llength [get_files -quiet $rtl]] == 0} {add_files -norecurse $rtl}
if {[llength [get_ips -quiet vio_rtds_rx_start]] == 0} {
    set xci [file join $root RTDS_test_DDR4_64bit.srcs sources_1 ip vio_rtds_rx_start vio_rtds_rx_start.xci]
    if {[file exists $xci]} {
        read_ip $xci
    } else {
        create_ip -name vio -vendor xilinx.com -library ip -version 3.0 -module_name vio_rtds_rx_start -dir [file join $root RTDS_test_DDR4_64bit.srcs sources_1 ip]
    }
}
set_property -dict [list CONFIG.C_NUM_PROBE_IN {4} CONFIG.C_NUM_PROBE_OUT {1} CONFIG.C_PROBE_IN0_WIDTH {1} CONFIG.C_PROBE_IN1_WIDTH {2} CONFIG.C_PROBE_IN2_WIDTH {4} CONFIG.C_PROBE_IN3_WIDTH {4} CONFIG.C_PROBE_OUT0_WIDTH {1} CONFIG.C_PROBE_OUT0_INIT_VAL {0x0}] [get_ips vio_rtds_rx_start]
set_property GENERATE_SYNTH_CHECKPOINT false [get_files [get_property IP_FILE [get_ips vio_rtds_rx_start]]]
generate_target all [get_ips vio_rtds_rx_start]
set oldGenerics [get_property generic [get_filesets sources_1]]
set newGenerics {}
foreach item $oldGenerics {if {![string match RX_VIO_TEST_ENABLE=* $item]} {lappend newGenerics $item}}
lappend newGenerics RX_VIO_TEST_ENABLE=1
set_property generic $newGenerics [get_filesets sources_1]
update_compile_order -fileset sources_1
puts "RX_VIO_REGISTERED: test generic=1; synthesis/implementation were not launched"
