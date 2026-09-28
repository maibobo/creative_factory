open_project "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit/RTDS_test_DDR4_64bit.xpr"
set regen_ips [get_ips -quiet design_1_*]
puts "REFRESH_IP_COUNT=[llength $regen_ips]"
foreach ip $regen_ips {
  puts "REFRESH_IP=[get_property NAME $ip]"
  reset_target all $ip
  generate_target all $ip
}
export_ip_user_files -of_objects $regen_ips -no_script -sync -force -quiet
puts "RTDS_BD_IP_PRODUCTS_REFRESH_PASS"
close_project