open_project "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit/RTDS_test_DDR4_64bit.xpr"
set aurora_ip [get_ips -quiet aurora_64b66b_0]
if {[llength $aurora_ip] != 1} { error "aurora_64b66b_0 IP not found" }
generate_target all $aurora_ip
export_ip_user_files -of_objects $aurora_ip -no_script -sync -force -quiet
puts "RTDS_AURORA_OUTPUT_PRODUCTS_PASS"
save_project
close_project