# Local, isolated module simulations. Vivado 2020.2.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root evidence local_wave_sessions]
file mkdir $out
foreach selected {1g tx rx_fifo ring axi axi_tail regs} {
    set case_dir [file join $out $selected]
    file mkdir $case_dir
    create_project -force wave_$selected [file join $case_dir project] -part xcku040-ffva1156-2-e
    set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]
    add_files [glob $root/rtl/rtds_*.v]
    if {$selected eq "regs"} {add_files [file join $root RTDS_test_DDR4_64bit.srcs sources_1 new INFO_EXCH.v]}
    if {$selected in {axi axi_tail}} {
        add_files [file join $root RTDS_test_DDR4_64bit.srcs sources_1 new CONV_DMA.v]
        add_files [file join $root rtl ddr4 rtds_axi_ram_model.sv]
    }
    if {$selected eq "tx"} {add_files -norecurse [list [file join $root {external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v}]]}
    add_files -fileset sim_1 [file join $root regression batch_1g rtds_${selected}_test_if.sv]
    add_files -fileset sim_1 [file join $root regression batch_1g tb_rtds_${selected}.sv]
    set_property top tb_rtds_${selected} [get_filesets sim_1]
    set_property xsim.elaborate.debug_level all [get_filesets sim_1]
    set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
    update_compile_order -fileset sim_1
    set fh [open [file join $case_dir files.txt] w]
    foreach src [get_files -compile_order sources -used_in simulation -of_objects [get_filesets sim_1]] {puts $fh [file normalize $src]}
    close $fh
    launch_simulation -mode behavioral
    log_wave -r /tb_rtds_${selected}/*
    open_vcd [file join $case_dir ${selected}.vcd]
    log_vcd [get_objects -r /tb_rtds_${selected}/*]
    # The database records all traceable HDL objects, including XPM internals.
    run all
    close_vcd
    if {[string length [current_wave_config]] > 0} {close_wave_config [current_wave_config]}
    create_wave_config ${selected}_complete
    foreach spec [list [list 01_TESTBENCH /tb_rtds_${selected}/*] [list 02_INTERFACE /tb_rtds_${selected}/bus/*] [list 03_DUT /tb_rtds_${selected}/U_DUT/*]] {
        lassign $spec label pattern
        set group [add_wave_group $label]
        add_wave -into $group [get_objects $pattern]
    }
    set group [add_wave_group 04_ALL_HIERARCHY]
    add_wave -r -into $group /tb_rtds_${selected}/*
    save_wave_config [file join $case_dir ${selected}.wcfg]
    set sim_dir [file join $case_dir project wave_${selected}.sim sim_1 behav xsim]
    close_sim
    file copy -force [file join $sim_dir tb_rtds_${selected}_behav.wdb] [file join $case_dir ${selected}.wdb]
    file copy -force [file join $sim_dir simulate.log] [file join $case_dir simulation.log]
    close_project
    puts "LOCAL_CASE_COMPLETE=$selected"
}
puts "LOCAL_ALL_COMPLETE"
