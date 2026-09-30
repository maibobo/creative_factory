open_project "C:/project/RTDS/DDR/RTDS_test_DDR4_64bit/RTDS_test_DDR4_64bit.xpr"
cd "C:/Xilinx/Vivado/2020.2/scripts/ipintegrator"
open_bd_design [get_files -quiet */design_1.bd]
set c [get_bd_cells util_ds_buf]
puts "SIM_DEVICE=[get_property -quiet CONFIG.C_SIM_DEVICE $c]"
puts "BUF_TYPE=[get_property -quiet CONFIG.C_BUF_TYPE $c]"
report_property $c
close_project