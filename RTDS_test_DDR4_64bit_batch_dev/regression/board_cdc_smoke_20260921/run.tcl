set root F:/RTDS_test_DDR4_64bit_batch_dev
set out [file dirname [file normalize [info script]]]
create_project board_cdc_smoke $out/project -part xcku040-ffva1156-2-i
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]
add_files [glob $root/rtl/rtds_*.v]
add_files $root/RTDS_test_DDR4_64bit.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v
add_files [list "$root/external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v"]
add_files -fileset sim_1 $out/tb_board_cdc_smoke.sv
set_property top tb_board_cdc_smoke [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation -mode behavioral
close_sim
close_project
exit 0
