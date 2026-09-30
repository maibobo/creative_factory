# Configure the current fdma_aurora_brg project for the lightweight
# CONV_DMA/AXI-RAM integration simulation.
#
# Optional argument:
#   wave
#
# Example:
#   source {.../setup_integration_sim.tcl}
#   source {.../setup_integration_sim.tcl} 1
#
# This does not replace setup_vivado_sim.tcl. Run the original bridge
# regression first, then run this integration simulation as the next layer.

set script_dir     [file dirname [file normalize [info script]]]
set loop_root      [file normalize [file join $script_dir ..]]
set source_dir     [file join $loop_root new]
set integration_dir [file join $source_dir integration]
set project_dir    [file normalize [file join $loop_root .. ..]]
set workspace_root [file normalize [file join $project_dir ..]]
set project_xpr    [file join $project_dir fdma_aurora_brg.xpr]
set conv_dma_file  [file join $workspace_root RTDS_test RTDS_test.srcs sources_1 new CONV_DMA.v]

if {[current_project -quiet] eq ""} {
    open_project $project_xpr
}

set wave [expr {$argc >= 1 ? [lindex $argv 0] : "0"}]
if {$wave ni {0 1}} { error "wave must be 0 or 1" }
if {![file exists $conv_dma_file]} { error "missing CONV_DMA file: $conv_dma_file" }

set sim_files [list \
    [file join $source_dir fdma_aurora_pcie_conv_dma_wrapper.v] \
    [file join $integration_dir axi_ram_model.sv] \
    [file join $integration_dir tb_fdma_aurora_brg_conv_dma_integration.sv] \
    $conv_dma_file]

foreach sim_file $sim_files {
    if {[llength [get_files -quiet -of_objects [get_filesets sim_1] $sim_file]] == 0} {
        add_files -norecurse -fileset sim_1 $sim_file
    }
}

set sim_objects [get_files -of_objects [get_filesets sim_1] $sim_files]
set_property used_in_synthesis false $sim_objects
set_property used_in_implementation false $sim_objects
foreach sv_file [list \
    [file join $integration_dir axi_ram_model.sv] \
    [file join $integration_dir tb_fdma_aurora_brg_conv_dma_integration.sv]] {
    set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] $sv_file]
}

set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]
set_property top tb_fdma_aurora_brg_conv_dma_integration [get_filesets sim_1]
set_property xsim.simulate.log_all_signals [expr {$wave ? "true" : "false"}] [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "INTEGRATION_SIM_SETUP_DONE top=tb_fdma_aurora_brg_conv_dma_integration wave=$wave"
puts "NEXT_STEP: launch_simulation -simset sim_1 -mode behavioral; run all"
