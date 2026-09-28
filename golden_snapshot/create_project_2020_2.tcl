set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set prj_dir    [file join $root_dir prj]
set prj_name   axi_ddr4_min_2020_2
set part_name  xcku040-ffva1156-2-i

file mkdir $prj_dir
create_project -force $prj_name $prj_dir -part $part_name

set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property target_simulator XSim [current_project]

add_files -norecurse [list \
    [file join $root_dir rtl axi_ddr_bist.v] \
    [file join $root_dir rtl top_axi_ddr4_bist.v]]
set_property top top_axi_ddr4_bist [current_fileset]

add_files -fileset constrs_1 -norecurse \
    [file join $root_dir constr top_axi_ddr4_bist.xdc]
set_property target_constrs_file \
    [file join $root_dir constr top_axi_ddr4_bist.xdc] \
    [get_filesets constrs_1]

create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 \
    -module_name ddr4_axi_0

set_property -dict [list \
    CONFIG.C0.DDR4_TimePeriod {833} \
    CONFIG.C0.DDR4_InputClockPeriod {9996} \
    CONFIG.C0.DDR4_PhyClockRatio {4:1} \
    CONFIG.C0.DDR4_MemoryType {Components} \
    CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E} \
    CONFIG.C0.DDR4_MemoryVoltage {1.2V} \
    CONFIG.C0.DDR4_DataWidth {64} \
    CONFIG.C0.DDR4_DataMask {DM_NO_DBI} \
    CONFIG.C0.DDR4_CasLatency {16} \
    CONFIG.C0.DDR4_CasWriteLatency {12} \
    CONFIG.C0.DDR4_AxiSelection {true} \
    CONFIG.C0.DDR4_AxiDataWidth {64} \
    CONFIG.C0.DDR4_AxiAddressWidth {32} \
    CONFIG.C0.DDR4_AxiIDWidth {4} \
    CONFIG.C0.DDR4_AxiNarrowBurst {false} \
    CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG} \
    CONFIG.System_Clock {Differential} \
    CONFIG.Reference_Clock {Differential}] [get_ips ddr4_axi_0]

generate_target all [get_files ddr4_axi_0.xci]
export_ip_user_files -of_objects [get_files ddr4_axi_0.xci] \
    -no_script -sync -force -quiet

update_compile_order -fileset sources_1
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
close_project

open_project [file join $prj_dir ${prj_name}.xpr]

puts "PROJECT_CREATED=[file join $prj_dir ${prj_name}.xpr]"
puts "VIVADO_VERSION=[version -short]"
puts "PART=[get_property PART [current_project]]"
puts "DDR4_INTERFACE=AXI4"
puts "DDR4_MEMORY_PART=[get_property CONFIG.C0.DDR4_MemoryPart [get_ips ddr4_axi_0]]"
puts "DDR4_AXI_DATA_WIDTH=[get_property CONFIG.C0.DDR4_AxiDataWidth [get_ips ddr4_axi_0]]"
