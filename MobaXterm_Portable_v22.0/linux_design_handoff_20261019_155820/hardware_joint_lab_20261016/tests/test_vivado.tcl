# Offline Tcl behavior tests. All hardware access functions below are stubs.
source [file join [file dirname [info script]] .. vivado rtds_lab.tcl]
proc assert {condition message} {
    if {![uplevel 1 [list expr $condition]]} {error $message}
}
rename ::rtds_lab::state ::rtds_lab::state_real
proc ::rtds_lab::state {} {return $::fake_state}
rename ::rtds_lab::vio ::rtds_lab::vio_real
proc ::rtds_lab::vio {path} {return fake_vio}
rename ::rtds_joint::probe ::rtds_joint::probe_real
proc ::rtds_joint::probe {core suffix} {return $suffix}
proc set_property {name value object} {
    assert {$name eq "OUTPUT_VALUE"} "Unexpected hardware property write"
    set ::fake_output $value
}
proc commit_hw_vio {probe} {
    assert {$probe eq "rx_test_start"} "Unexpected output probe"
    lappend ::commits $::fake_output
    if {$::fake_output == 1} {
        dict incr ::fake_state blocks
        dict set ::fake_state accepted 2
    }
}
set fake_state [dict create busy 0 accepted 0 rx_status 3 blocks 0 live 191]
set commits {}
set result [::rtds_lab::inject]
assert {$commits eq {0 1}} "Injection must commit exactly 0 then 1"
assert {[dict get $result blocks] == 1} "Expected one committed block"
set before $commits
dict set fake_state blocks 8
assert {[catch {::rtds_lab::inject}]} "Full queue must refuse injection"
assert {$commits eq $before} "Full queue changed VIO"
dict set fake_state blocks 0
dict set fake_state busy 1
assert {[catch {::rtds_lab::inject}]} "Busy generator must refuse injection"
dict set fake_state busy 0
dict set fake_state rx_status 7
assert {[catch {::rtds_lab::inject}]} "Fault must refuse injection"
dict set fake_state rx_status 3
dict set fake_state live 183
assert {[catch {::rtds_lab::inspect}]} "Link-down must fail inspect"
assert {$commits eq $before} "Failed preconditions changed VIO"
puts "TCL_OFFLINE_TESTS=PASS (source-only load, edge order, full/busy/fault/link refusal)"
exit 0
