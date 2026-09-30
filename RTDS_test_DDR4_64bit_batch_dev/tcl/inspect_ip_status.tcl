open_project "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit/RTDS_test_DDR4_64bit.xpr"
foreach ip [get_ips] {
  puts "IP=[get_property NAME $ip] FILE=[get_property IP_FILE $ip] GEN=[get_property GENERATE_SYNTH_CHECKPOINT $ip]"
}
report_ip_status
close_project