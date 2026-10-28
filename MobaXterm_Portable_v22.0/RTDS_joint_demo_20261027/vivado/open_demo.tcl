# Run from the existing Vivado GUI Tcl Console, in its interactive Windows session.
set demo_root [file normalize [file join [file dirname [info script]] ..]]
set demo_events [file join $demo_root events live_20261027.jsonl]
source [file join $demo_root vivado gui_bridge.tcl]
file mkdir [file dirname $demo_events]

source [file join $demo_root vivado open_notice.tcl]

set demo_editor ""
if {[info exists ::env(LOCALAPPDATA)]} {
    set candidate [file join $::env(LOCALAPPDATA) Programs {Microsoft VS Code} Code.exe]
    if {[file exists $candidate]} {set demo_editor [list $candidate]}
}
if {$demo_editor eq "" && [info exists ::env(ProgramFiles)]} {
    set candidate [file join $::env(ProgramFiles) {Microsoft VS Code} Code.exe]
    if {[file exists $candidate]} {set demo_editor [list $candidate]}
}
if {$demo_editor eq ""} {set demo_editor [auto_execok code]}
set demo_python_source [file join $demo_root arm rtds_lab.py]
set demo_c_source [file join $demo_root arm rtds_dma.c]
set demo_runner_source [file join $demo_root pc demo_runner.py]
if {$demo_editor ne ""} {
    if {[catch {exec {*}$demo_editor --new-window $demo_python_source $demo_c_source $demo_runner_source &} demo_error]} {
        puts "DEMO_EDITOR_FAILED=$demo_error"
    } else {
        puts "DEMO_EDITOR_STARTED=$demo_editor"
    }
} else {
    puts "DEMO_EDITOR_NOT_FOUND=Open the demo arm directory in your existing VS Code window"
}

set demo_jobs [::rtds_demo_gui::start]
puts "DEMO_READY_JOBS=$demo_jobs"
