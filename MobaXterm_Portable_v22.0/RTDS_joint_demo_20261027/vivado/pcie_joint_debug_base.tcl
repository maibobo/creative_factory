# RTDS 2026-10-15. Source only defines commands: no hardware actions on load.
# This helper never programs FPGA/Flash, boots, resets functionality, or writes VIO.
namespace eval ::rtds_joint {
    variable report_dir
    if {![info exists report_dir]} {set report_dir C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/reports/joint_debug_20261015}
    variable paths [dict create native u_pcie/U_PCIE_LINK_DEBUG/ila fdma u_pcie/ila_FDMA_inst temp u_temp_rd/ila_temp_inst phy ila_pcie_phy]
    variable widths [dict create ila_ltssm 6 ila_flags_1 1 ila_flags_2 1 ila_flags_3 1 ila_flags_4 1 ila_speed 3 ila_width 4 ila_flags 1 ila_ticks 32 ila_errors 9 ila_axi 216 fdma_raddr 32 fdma_rareq 1 fdma_rbusy 1 fdma_rdata 64 fdma_rsize 16 fdma_rvalid 1 fdma_waddr 32 fdma_wareq 1 fdma_wbusy 1 fdma_wdata 64 fdma_wsize 16 fdma_w_source_valid 1 adapter_rx_state_dbg 4 adapter_tx_state_dbg 4 den_in 1 dwe_in 1 cnt_time 32 daddr_in 8 temp 16 busy 1]
}
proc ::rtds_joint::core {kind} {
    variable paths
    if {![dict exists $paths $kind]} {error "Unknown ILA kind: $kind"}
    set target [dict get $paths $kind]
    set matches {}
    foreach c [get_hw_ilas -of_objects [current_hw_device]] {
        if {[get_property CELL_NAME $c] eq $target} {lappend matches $c}
    }
    if {[llength $matches] != 1} {error "Expected one ILA at $target; found [llength $matches]. Check device and LTX."}
    return [lindex $matches 0]
}
proc ::rtds_joint::probe {c suffix} {
    set matches {}
    foreach p [get_hw_probes -of_objects $c] {
        if {[file tail [get_property NAME $p]] eq $suffix} {lappend matches $p}
    }
    if {[llength $matches] != 1} {error "Expected one probe $suffix on $c; found [llength $matches]"}
    return [lindex $matches 0]
}
proc ::rtds_joint::require_setting {object property value} {
    # Fixed hardware capabilities may be read-only (e.g. BASIC_ONLY without
    # an advanced trigger engine). An already correct value needs no write.
    if {[get_property $property $object] eq $value} {return}
    set_property $property $value $object
    if {[get_property $property $object] ne $value} {
        error "ILA setting did not take effect: $property=$value on $object"
    }
}
proc ::rtds_joint::configure {kind} {
    variable widths
    set c [core $kind]
    # Validate probe names before changing analyzer settings.
    set config {}
    foreach p [get_hw_probes -of_objects $c] {
        set tail [file tail [get_property NAME $p]]
        if {[string match pcie_diag_phy_value_* $tail]} {set width 1} else {
            if {![dict exists $widths $tail]} {error "Unknown probe $tail; this helper requires the matching 2026-10-14 LTX."}
            set width [dict get $widths $tail]
        }
        lappend config [list $p $width]
    }
    reset_hw_ila $c
    require_setting $c CONTROL.CAPTURE_MODE ALWAYS
    require_setting $c CONTROL.DATA_DEPTH [expr {$kind in {fdma temp} ? 1024 : 2048}]
    require_setting $c CONTROL.TRIGGER_MODE BASIC_ONLY
    require_setting $c CONTROL.TRIGGER_CONDITION AND
    require_setting $c CONTROL.TRIGGER_POSITION 128
    foreach item $config {
        lassign $item p width
        set_property TRIGGER_COMPARE_VALUE "eq${width}'b[string repeat X $width]" $p
    }
    return $c
}
proc ::rtds_joint::arm {test} {
    switch -- $test {
        fdma_up {set kind fdma;set suffix fdma_wareq;set value {eq1'b1}}
        fdma_down {set kind fdma;set suffix fdma_rareq;set value {eq1'b1}}
        temp {set kind temp;set suffix den_in;set value {eq1'b1}}
        dma_write - dma_read {
            set kind native;set suffix ila_axi
            set bits [string repeat X 216]
            if {$test eq "dma_write"} {set indices {0 1}} else {set indices {6 7}}
            foreach bit $indices {set i [expr {215-$bit}];set bits [string replace $bits $i $i 1]}
            set value "eq216'b$bits"
        }
        default {error "Use arm fdma_up, fdma_down, dma_write, dma_read, or temp"}
    }
    set c [configure $kind]
    set p [probe $c $suffix]
    set_property TRIGGER_COMPARE_VALUE $value $p
    run_hw_ila $c
    puts "ARMED: $test, CELL=[get_property CELL_NAME $c]. Perform the manual VIO/software action now."
    return $c
}
proc ::rtds_joint::now {kind} {
    set c [configure $kind]
    run_hw_ila -trigger_now $c
    puts "IMMEDIATE: $kind. Wait for capture completion before save."
    return $c
}
proc ::rtds_joint::save {kind} {
    variable report_dir
    set c [core $kind]
    # Call after GUI capture completion. Do not arm another acquisition first.
    set data [upload_hw_ila_data $c]
    display_hw_ila_data $data
    file mkdir $report_dir
    set base [file join $report_dir ${kind}_[clock format [clock seconds] -format %Y%m%d_%H%M%S]_[clock clicks -milliseconds]]
    write_hw_ila_data -csv_file ${base}.csv $data
    write_hw_ila_data ${base}.ila $data
    puts "ILA_SAVED=${base}.csv AND ${base}.ila"
    return ${base}.csv
}
proc ::rtds_joint::hexint {value} {
    set value [string trim $value]
    if {[string match -nocase 0x* $value]} {set value [string range $value 2 end]}
    if {![regexp {^[0-9a-fA-F]+$} $value]} {error "Not a known hexadecimal input: $value"}
    return [expr "0x$value"]
}
proc ::rtds_joint::field {number hi lo} {
    return [expr {($number >> $lo) & ((1 << ($hi-$lo+1))-1)}]
}
proc ::rtds_joint::snapshot {} {
    variable report_dir
    set lines [list "TIME=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]" "DEVICE=[current_hw_device]"]
    set values [dict create]
    set d [current_hw_device]
    foreach prop {PROGRAM.FILE PROBES.FILE FULL_PROBES.FILE} {
        if {[lsearch -exact [list_property $d] $prop]>=0} {lappend lines "$prop=[get_property $prop $d]"}
    }
    lappend lines {NOTE: PROGRAM.FILE is a host-side setting, not proof of Flash identity. VIO inputs below are sequential JTAG reads.}
    foreach c [get_hw_vios -of_objects $d] {
        set cell [get_property CELL_NAME $c]
        if {$cell ni {u_pcie/G_RX_VIO.U_VIO_RX_START u_pcie/U_PCIE_LINK_DEBUG/vio}} {continue}
        lappend lines "VIO=$c CELL=$cell"
        if {[catch {refresh_hw_vio $c} err]} {lappend lines "REFRESH_ERROR=$err";continue}
        foreach p [get_hw_probes -of_objects $c] {
            set name [get_property NAME $p]
            if {[lsearch -exact [list_property $p] INPUT_VALUE]>=0} {
                set raw [get_property INPUT_VALUE $p]
                lappend lines "INPUT=$name VALUE=$raw"
                if {![catch {hexint $raw} n]} {dict set values [file tail $name] $n}
            } elseif {[lsearch -exact [list_property $p] OUTPUT_VALUE]>=0} {
                lappend lines "OUTPUT_SETTING=$name VALUE=[get_property OUTPUT_VALUE $p]"
            }
        }
    }
    if {[dict exists $values live_vio]} {
        set n [dict get $values live_vio]
        lappend lines "LIVE: perst=[field $n 0 0] qpll=[field $n 1 1] clock_alive=[field $n 2 2] link=[field $n 3 3] axi_reset_released=[field $n 4 4] ddr=[field $n 5 5] board_reset=[field $n 6 6] settled=[field $n 7 7] irq_req=[field $n 8 8]"
    }
    if {[dict exists $values snapshot_vio_1]} {
        set n [dict get $values snapshot_vio_1]
        lappend lines "NATIVE: LTSSM=[format %02X [field $n 5 0]] speed=[field $n 8 6] width=[field $n 12 9] link=[field $n 13 13] axi_reset_released=[field $n 14 14] local_error_valid=[field $n 22 22] local_error=[field $n 21 17] cor=[field $n 23 23] nonfatal=[field $n 24 24] fatal=[field $n 25 25]"
    }
    if {[dict exists $values snapshot_vio_3]} {
        set n [dict get $values snapshot_vio_3]
        lappend lines "COUNTS: AW=[field $n 31 0] AR=[field $n 63 32] COR_CYCLES=[field $n 79 64] NONFATAL_CYCLES=[field $n 95 80] FATAL_CYCLES=[field $n 111 96] LOCAL_VALID_CYCLES=[field $n 127 112]"
    }
    if {[dict exists $values snapshot_vio]} {
        set n [dict get $values snapshot_vio]
        lappend lines "EXTRA: ticks=[field $n 31 0] transitions=[field $n 47 32] B_ERROR_RESPONSES=[field $n 63 48] R_ERROR_BEATS=[field $n 79 64] dwell_cycles=[field $n 111 80]"
    }
    if {[dict exists $values rx_test_status_r]} {
        set n [dict get $values rx_test_status_r]
        lappend lines "RX_TEST: ddr=[field $n 0 0] link=[field $n 1 1] fault=[field $n 2 2] notify=[field $n 3 3]"
    }
    file mkdir $report_dir
    set path [file join $report_dir vio_[clock format [clock seconds] -format %Y%m%d_%H%M%S]_[clock clicks -milliseconds].txt]
    set f [open $path w];fconfigure $f -encoding utf-8
    foreach line $lines {puts $line;puts $f $line}
    close $f
    puts "VIO_SNAPSHOT_SAVED=$path"
    return $path
}
puts {RTDS helper loaded. No hardware action performed. Commands: ::rtds_joint::snapshot ; ::rtds_joint::arm fdma_up|fdma_down|dma_write|dma_read|temp ; ::rtds_joint::now native|phy ; ::rtds_joint::save native|fdma|temp|phy}
