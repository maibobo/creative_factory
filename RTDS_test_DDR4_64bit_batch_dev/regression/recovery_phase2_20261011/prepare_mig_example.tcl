# 2026-10-11：仅在独立副本生成MIG示例仿真模型，不启动综合或实现。
set root [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
file mkdir $out
set src [file join $root RTDS_test_DDR4_64bit.srcs sources_1 ip rtds_ddr4_mig rtds_ddr4_mig.xci]
set copydir [file join $out ip_copy rtds_ddr4_mig]
file mkdir $copydir
file copy -force $src [file join $copydir rtds_ddr4_mig.xci]
create_project mig_model_probe [file join $out probe] -part xcku040-ffva1156-2-i -force
add_files -norecurse [list [file join $copydir rtds_ddr4_mig.xci]]
set ip [get_ips rtds_ddr4_mig]
puts "MIG_PROBE_IP=$ip"
if {[catch {open_example_project -force -dir [file join $out example] $ip} msg]} {
    puts "MIG_EXAMPLE_FAIL=$msg"
    error $msg
}
puts "MIG_EXAMPLE_PASS"
close_project
