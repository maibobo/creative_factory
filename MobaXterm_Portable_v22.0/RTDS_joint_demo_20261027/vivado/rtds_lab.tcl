# RTDS lab extensions, Vivado 2020.2. Sourcing this file defines commands only.
source [file join [file dirname [info script]] pcie_joint_debug_base.tcl]
namespace eval ::rtds_lab {
    variable rx_path u_pcie/G_RX_VIO.U_VIO_RX_START
    variable link_path u_pcie/U_PCIE_LINK_DEBUG/vio
}
proc ::rtds_lab::vio {path} {
    set matches {}
    foreach c [get_hw_vios -of_objects [current_hw_device]] {
        if {[get_property CELL_NAME $c] eq $path} {lappend matches $c}
    }
    if {[llength $matches] != 1} {error "Expected exactly one VIO at $path; check device and matching LTX"}
    return [lindex $matches 0]
}
proc ::rtds_lab::inputs {path} {
    set c [vio $path]
    refresh_hw_vio $c
    set result [dict create]
    foreach p [get_hw_probes -of_objects $c] {
        if {[lsearch -exact [list_property $p] INPUT_VALUE] >= 0} {
            dict set result [file tail [get_property NAME $p]] [::rtds_joint::hexint [get_property INPUT_VALUE $p]]
        }
    }
    return $result
}
proc ::rtds_lab::state {} {
    variable rx_path
    variable link_path
    set v [inputs $rx_path]
    set result [dict create busy [dict get $v rx_test_busy_r] accepted [dict get $v rx_test_accepted_r] \
        rx_status [dict get $v rx_test_status_r] blocks [dict get $v rx_test_blocks_r]]
    set link [inputs $link_path]
    dict set result live [dict get $link live_vio]
    return $result
}
proc ::rtds_lab::healthy {s} {
    if {([dict get $s rx_status] & 7) != 3} {error "RX not ready or fault latched: $s"}
    if {([dict get $s live] & 255) != 191} {error "PCIe/DDR/observer live state is not healthy: $s"}
}
proc ::rtds_lab::inspect {} {
    set s [state]
    healthy $s
    if {[dict get $s busy] != 0} {error "VIO generator is busy: $s"}
    puts "VIO_INSPECT=$s"
    return $s
}
proc ::rtds_lab::inject {} {
    variable rx_path
    set before [inspect]
    set n [dict get $before blocks]
    if {$n >= 8} {error "Queue full; injection refused"}
    set c [vio $rx_path]
    set p [::rtds_joint::probe $c rx_test_start]
    # Target only the test-start probe. No history clear or functional reset.
    set_property OUTPUT_VALUE 0 $p
    commit_hw_vio $p
    set_property OUTPUT_VALUE 1 $p
    commit_hw_vio $p
    set deadline [expr {[clock milliseconds]+2000}]
    while {[clock milliseconds] < $deadline} {
        after 20
        set s [state]
        healthy $s
        if {[dict get $s blocks] == $n+1 && [dict get $s busy] == 0 && [dict get $s accepted] == 2} {
            puts "VIO_INJECTION_COMPLETE=$s"
            return $s
        }
    }
    error "VIO injection timeout; no retry/reset performed; last=$s"
}
proc ::rtds_lab::save {kind} {
    set c [::rtds_joint::core $kind]
    wait_on_hw_ila -timeout 10 $c
    set data [upload_hw_ila_data $c]
    set dir $::rtds_joint::report_dir
    file mkdir $dir
    set base [file join $dir ${kind}_[clock format [clock seconds] -format %Y%m%d_%H%M%S]_[clock clicks -milliseconds]]
    write_hw_ila_data -csv_file ${base}.csv $data
    write_hw_ila_data ${base}.ila $data
    # No display call: works in batch and leaves local captures off the foreground.
    puts "ILA_SAVED=${base}.csv AND ${base}.ila"
    return ${base}.csv
}
puts {RTDS lab loaded: ::rtds_lab::inspect ; ::rtds_lab::inject ; ::rtds_lab::save native|fdma ; use ::rtds_joint::arm and ::rtds_joint::snapshot. No hardware action on load.}
