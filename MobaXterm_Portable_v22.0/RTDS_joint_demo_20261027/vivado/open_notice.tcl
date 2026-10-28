# Relaunch the read-only notice window from the interactive Vivado desktop.
set demo_root [file normalize [file join [file dirname [info script]] ..]]
set demo_events [file join $demo_root events live_20261027.jsonl]
set demo_error_log [file join $demo_root events notice_window_error.log]
set demo_python {C:/Program Files/Python312/pythonw.exe}
array set demo_saved_env {}
foreach key {TCL_LIBRARY TK_LIBRARY PYTHONHOME PYTHONPATH} {
    if {[info exists ::env($key)]} {
        set demo_saved_env($key) $::env($key)
        unset ::env($key)
    }
}
set demo_launch_result [catch {
    exec $demo_python [file join $demo_root pc notice_window.py] --events $demo_events > $demo_error_log 2>@1 &
} demo_launch_message]
foreach key [array names demo_saved_env] {set ::env($key) $demo_saved_env($key)}
if {$demo_launch_result} {
    puts "DEMO_NOTICE_WINDOW_FAILED=$demo_launch_message"
} else {
    puts "DEMO_NOTICE_WINDOW_RELAUNCHED=$demo_error_log"
}
