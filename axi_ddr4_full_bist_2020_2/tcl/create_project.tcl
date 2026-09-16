# Vivado 2020.2 project generator for the KU040 DDR4 BIST images.
# Usage: vivado -mode batch -source create_project.tcl -tclargs compat|gd2400|gd2133

proc require_profile {profile_name} {
    set supported_profiles {compat gd2400 gd2133}
    if {[lsearch -exact $supported_profiles $profile_name] < 0} {
        error "Unsupported build profile '$profile_name': expected compat, gd2400, or gd2133"
    }
}

proc configure_debug_ips {project_root} {
    create_ip -name vio -vendor xilinx.com -library ip -module_name vio_bist_ctrl
    set vio_ip [get_ips vio_bist_ctrl]
    set_property -dict [list \
        CONFIG.C_NUM_PROBE_IN {12} \
        CONFIG.C_NUM_PROBE_OUT {4} \
        CONFIG.C_PROBE_IN0_WIDTH {1} \
        CONFIG.C_PROBE_IN1_WIDTH {1} \
        CONFIG.C_PROBE_IN2_WIDTH {1} \
        CONFIG.C_PROBE_IN3_WIDTH {1} \
        CONFIG.C_PROBE_IN4_WIDTH {1} \
        CONFIG.C_PROBE_IN5_WIDTH {9} \
        CONFIG.C_PROBE_IN6_WIDTH {33} \
        CONFIG.C_PROBE_IN7_WIDTH {16} \
        CONFIG.C_PROBE_IN8_WIDTH {32} \
        CONFIG.C_PROBE_IN9_WIDTH {32} \
        CONFIG.C_PROBE_IN10_WIDTH {4} \
        CONFIG.C_PROBE_IN11_WIDTH {32} \
        CONFIG.C_PROBE_OUT0_WIDTH {1} \
        CONFIG.C_PROBE_OUT1_WIDTH {1} \
        CONFIG.C_PROBE_OUT2_WIDTH {3} \
        CONFIG.C_PROBE_OUT3_WIDTH {1} \
        CONFIG.C_PROBE_OUT0_INIT_VAL {0x0} \
        CONFIG.C_PROBE_OUT1_INIT_VAL {0x0} \
        CONFIG.C_PROBE_OUT2_INIT_VAL {0x0} \
        CONFIG.C_PROBE_OUT3_INIT_VAL {0x0}] $vio_ip

    create_ip -name ila -vendor xilinx.com -library ip -module_name ila_bist_status
    set ila_ip [get_ips ila_bist_status]
    set_property -dict [list \
        CONFIG.C_NUM_OF_PROBES {16} \
        CONFIG.C_DATA_DEPTH {4096} \
        CONFIG.C_PROBE0_WIDTH {1} \
        CONFIG.C_PROBE1_WIDTH {1} \
        CONFIG.C_PROBE2_WIDTH {6} \
        CONFIG.C_PROBE3_WIDTH {9} \
        CONFIG.C_PROBE4_WIDTH {33} \
        CONFIG.C_PROBE5_WIDTH {16} \
        CONFIG.C_PROBE6_WIDTH {2} \
        CONFIG.C_PROBE7_WIDTH {3} \
        CONFIG.C_PROBE8_WIDTH {4} \
        CONFIG.C_PROBE9_WIDTH {2} \
        CONFIG.C_PROBE10_WIDTH {5} \
        CONFIG.C_PROBE11_WIDTH {32} \
        CONFIG.C_PROBE12_WIDTH {32} \
        CONFIG.C_PROBE13_WIDTH {64} \
        CONFIG.C_PROBE14_WIDTH {64} \
        CONFIG.C_PROBE15_WIDTH {64}] $ila_ip

    generate_target all [get_ips vio_bist_ctrl]
    generate_target all [get_ips ila_bist_status]
}

proc configure_mig {project_root profile_name} {
    set recreate_tcl [file join $project_root tcl recreate_ddr4_axi_0.tcl]
    if {![file exists $recreate_tcl]} {
        error "Missing MIG recreation script: $recreate_tcl"
    }
    source $recreate_tcl
    set mig_ip [get_ips ddr4_axi_0]

    if {$profile_name eq "gd2400"} {
        set custom_csv [file normalize [file join $project_root ip gd_q3bfam_wj_2400.csv]]
        set_property CONFIG.C0.DDR4_isCustom {true} $mig_ip
        set_property CONFIG.C0.DDR4_CustomParts $custom_csv $mig_ip
        set_property CONFIG.C0.DDR4_MemoryPart {GDQ3BFAM-WJ-2400} $mig_ip
        set_property CONFIG.C0.DDR4_TimePeriod {833} $mig_ip
        set_property CONFIG.C0.DDR4_CasLatency {17} $mig_ip
        set_property CONFIG.C0.DDR4_CasWriteLatency {12} $mig_ip
    } elseif {$profile_name eq "gd2133"} {
        set custom_csv [file normalize [file join $project_root ip gd_q3bfam_wj_2133_fallback.csv]]
        set_property CONFIG.C0.DDR4_isCustom {true} $mig_ip
        set_property CONFIG.C0.DDR4_CustomParts $custom_csv $mig_ip
        set_property CONFIG.C0.DDR4_MemoryPart {GDQ3BFAM-WJ-2133} $mig_ip
        set_property CONFIG.C0.DDR4_TimePeriod {938} $mig_ip
        set_property CONFIG.C0.DDR4_CasLatency {15} $mig_ip
        set_property CONFIG.C0.DDR4_CasWriteLatency {11} $mig_ip
    }

    set_property CONFIG.C0.DDR4_AxiAddressWidth {32} $mig_ip
    set_property CONFIG.C0.DDR4_AxiDataWidth {64} $mig_ip
    set_property CONFIG.C0.DDR4_AxiIDWidth {4} $mig_ip
    set_property CONFIG.C0.DDR4_DataWidth {64} $mig_ip
    set_property CONFIG.C0.DDR4_InputClockPeriod {9996} $mig_ip
    generate_target all $mig_ip
}

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set profile_name [lindex $argv 0]
if {$profile_name eq ""} {
    set profile_name compat
}
require_profile $profile_name

set project_name "axi_ddr4_full_bist_${profile_name}"
set project_dir [file join $project_root prj $profile_name]
create_project -force $project_name $project_dir -part xcku040-ffva1156-2-i
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

add_files -norecurse [file join $project_root rtl axi_ddr_full_bist.v]
add_files -norecurse [file join $project_root rtl top_axi_ddr4_full_bist.v]
add_files -fileset constrs_1 -norecurse \
    [file join $project_root constr top_axi_ddr4_full_bist.xdc]
set_property top TOP_AXI_DDR4_FULL_BIST [current_fileset]
set_property top_lib xil_defaultlib [current_fileset]

configure_mig $project_root $profile_name
configure_debug_ips $project_root
update_compile_order -fileset sources_1

set report_dir [file join $project_root reports $profile_name]
file mkdir $report_dir
report_ip_status -name ip_status -file [file join $report_dir ip_status.rpt]
set_property source_mgmt_mode All [current_project]

puts "PROJECT_CREATE_PASS profile=$profile_name xpr=[file join $project_dir ${project_name}.xpr]"
close_project
