# Recreate the AXI64 DDR4 MIG used by both compatibility and GD timing profiles.
# The values are the minimal user-configured set exported by Vivado 2020.2 from
# the read-only axi_ddr4_min_2020_2 XCI; all output products are regenerated locally.

set existing_mig [get_ips -quiet ddr4_axi_0]
if {$existing_mig ne ""} {
    error "ddr4_axi_0 already exists in the current project"
}

create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 \
    -module_name ddr4_axi_0

set mig_ip [get_ips ddr4_axi_0]
set_property -dict [list \
    CONFIG.C0.DDR4_TimePeriod {833} \
    CONFIG.C0.DDR4_InputClockPeriod {9996} \
    CONFIG.C0.DDR4_PhyClockRatio {4:1} \
    CONFIG.C0.DDR4_MemoryType {Components} \
    CONFIG.C0.DDR4_MemoryPart {MT40A512M16HA-083E} \
    CONFIG.C0.DDR4_MemoryVoltage {1.2V} \
    CONFIG.C0.DDR4_DataWidth {64} \
    CONFIG.C0.DDR4_DataMask {DM_NO_DBI} \
    CONFIG.C0.DDR4_AxiSelection {true} \
    CONFIG.C0.DDR4_CasLatency {16} \
    CONFIG.C0.DDR4_CasWriteLatency {12} \
    CONFIG.C0.DDR4_AxiDataWidth {64} \
    CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG} \
    CONFIG.C0.DDR4_AxiNarrowBurst {false} \
    CONFIG.C0.DDR4_AxiAddressWidth {32} \
    CONFIG.C0.DDR4_AxiIDWidth {4} \
    CONFIG.System_Clock {Differential} \
    CONFIG.Reference_Clock {Differential}] $mig_ip
