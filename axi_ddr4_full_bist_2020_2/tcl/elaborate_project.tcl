# Elaborate one generated profile without mapping or implementation.
# Usage: vivado -mode batch -source elaborate_project.tcl -tclargs compat|gd2400|gd2133

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set profile_name [lindex $argv 0]
if {$profile_name eq ""} {
    error "Missing elaborate profile"
}

set project_name "axi_ddr4_full_bist_${profile_name}"
set project_dir [file join $project_root prj $profile_name]
set generated_dir [file join $project_dir ${project_name}.gen sources_1 ip]
set report_dir [file join $project_root reports $profile_name]
file mkdir $report_dir

create_project -in_memory -part xcku040-ffva1156-2-i
set_property verilog_define {XILINX_SIMULATOR} [current_fileset]
read_verilog [file join $project_root rtl axi_ddr_full_bist.v]
read_verilog [file join $project_root rtl top_axi_ddr4_full_bist.v]
read_verilog [file join $generated_dir vio_bist_ctrl sim vio_bist_ctrl.v]
read_verilog [file join $generated_dir ila_bist_status sim ila_bist_status.v]
read_verilog -sv [file join $generated_dir ddr4_axi_0 sim ddr4_axi_0_stub.sv]
synth_design -rtl -name rtl_1 -top TOP_AXI_DDR4_FULL_BIST -part xcku040-ffva1156-2-i
report_compile_order -used_in synthesis -file [file join $report_dir compile_order.rpt]
puts "RTL_ELABORATE_PASS profile=$profile_name"
close_design
close_project
