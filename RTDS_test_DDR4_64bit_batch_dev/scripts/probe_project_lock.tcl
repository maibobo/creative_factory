# 快速探测工程是否可被批处理会话打开（无其他副作用）。
set root [file normalize [file join [file dirname [info script]] ..]]
if {[catch {open_project [file join $root RTDS_test_DDR4_64bit.xpr]} err]} {
    puts "PROBE_PROJECT_LOCKED: $err"
    exit 1
}
puts "PROBE_PROJECT_OPEN_OK"
close_project
exit 0
