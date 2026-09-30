set root F:/RTDS_test_DDR4_64bit_batch_dev
set out [file dirname [file normalize [info script]]]
file mkdir $out/smoke
cd $out/smoke
create_project smoke $out/smoke/project -part xcku040-ffva1156-2-i
add_files -fileset sim_1 [list $root/rtl/ddr4/rtds_axi_ram_model.sv $root/rtl/ddr4/rtds_ddr4_backend.sv $root/sim/ddr4_backend/tb_rtds_ddr4_backend_smoke.sv]
set_property top tb_rtds_ddr4_backend_smoke [get_filesets sim_1]
set_property verilog_define DDR4_SIM_RAM [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
close_sim
close_project
exit 0
