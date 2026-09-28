set root_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root_dir RTDS_test_DDR4_64bit.xpr]

if {![llength [get_ips -quiet rtds_axi_clock_converter]]} {
  create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name rtds_axi_clock_converter
}
set cc [get_ips rtds_axi_clock_converter]
set_property -dict [list \
  CONFIG.PROTOCOL {AXI4} \
  CONFIG.ADDR_WIDTH {32} \
  CONFIG.DATA_WIDTH {64} \
  CONFIG.ID_WIDTH {5} \
  CONFIG.ACLK_ASYNC {1} \
  CONFIG.SYNCHRONIZATION_STAGES {2}] $cc
generate_target all [get_files rtds_axi_clock_converter.xci]

if {![llength [get_ips -quiet rtds_ddr4_mig]]} {
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name rtds_ddr4_mig
}
set mig [get_ips rtds_ddr4_mig]
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
  CONFIG.C0.DDR4_AxiIDWidth {5} \
  CONFIG.C0.DDR4_AxiNarrowBurst {false} \
  CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG} \
  CONFIG.System_Clock {No_Buffer} \
  CONFIG.Reference_Clock {Differential}] $mig
generate_target all [get_files rtds_ddr4_mig.xci]
export_ip_user_files -of_objects [get_files rtds_ddr4_mig.xci] -no_script -sync -force -quiet
update_compile_order -fileset sources_1
puts "CC_DATA=[get_property CONFIG.DATA_WIDTH $cc] CC_ID=[get_property CONFIG.ID_WIDTH $cc]"
puts "MIG_DATA=[get_property CONFIG.C0.DDR4_AxiDataWidth $mig] MIG_ADDR=[get_property CONFIG.C0.DDR4_AxiAddressWidth $mig] MIG_ID=[get_property CONFIG.C0.DDR4_AxiIDWidth $mig] SYSCLK=[get_property CONFIG.System_Clock $mig]"
close_project
puts "DDR4_IP_GENERATION_PASS"