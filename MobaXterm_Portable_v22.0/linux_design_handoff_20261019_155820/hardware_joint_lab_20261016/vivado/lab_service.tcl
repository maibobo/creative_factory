# Single foreground/batch controller; accepts a bounded command vocabulary via files.
# No arbitrary Tcl evaluation and no programming/reset/clear commands.
if {$argc != 3} {error "Usage: lab_service.tcl JOB_DIRECTORY MATCHING_LTX REPORT_DIRECTORY"}
lassign $argv jobs ltx reports
source [file join [file dirname [info script]] rtds_lab.tcl]
set ::rtds_joint::report_dir $reports
file mkdir $jobs
proc reply {path text} {
    set f [open ${path}.tmp w]
    fconfigure $f -encoding utf-8
    puts $f $text
    close $f
    file rename -force ${path}.tmp $path
}
if {[catch {
    open_hw_manager
    connect_hw_server -url localhost:3121
    set targets [get_hw_targets]
    if {[llength $targets] != 1} {error "Expected one hardware target, found [llength $targets]; select the board manually"}
    current_hw_target [lindex $targets 0]
    open_hw_target
    set devices [get_hw_devices -filter {PART =~ xcku040*}]
    if {[llength $devices] != 1} {error "Expected one KU040, found [llength $devices]"}
    current_hw_device [lindex $devices 0]
    set_property PROBES.FILE $ltx [current_hw_device]
    set_property FULL_PROBES.FILE $ltx [current_hw_device]
    refresh_hw_device [current_hw_device]
    ::rtds_lab::inspect
} err opts]} {
    reply [file join $jobs service.error] $err
    puts stderr [dict get $opts -errorinfo]
    exit 1
}
reply [file join $jobs service.ready] "device=[current_hw_device]\nltx=$ltx"
set running 1
set idle_deadline [expr {[clock seconds]+1800}]
while {$running && [clock seconds] < $idle_deadline} {
    foreach req [lsort [glob -nocomplain -directory $jobs *.request]] {
        set f [open $req r]
        set words [split [string trim [read $f]]]
        close $f
        set command [lindex $words 0]
        set response [file rootname $req].response
        if {[catch {
            switch -- $command {
                inspect - inject {
                    if {[llength $words] != 1} {error "No arguments allowed"}
                    set result [::rtds_lab::$command]
                }
                snapshot {
                    set result [dict create path [::rtds_joint::snapshot]]
                }
                arm {
                    set test [lindex $words 1]
                    if {$test ni {dma_write dma_read fdma_up}} {error "Unsupported arm test"}
                    ::rtds_joint::arm $test
                    set result [dict create test $test armed 1]
                }
                save {
                    set kind [lindex $words 1]
                    if {$kind ni {native fdma}} {error "Unsupported save kind"}
                    set result [dict create path [::rtds_lab::save $kind]]
                }
                stop {set running 0; set result [dict create stopped 1]}
                default {error "Unsupported operation"}
            }
            set lines [list status=ok]
            dict for {key value} $result {lappend lines "$key=$value"}
            reply $response [join $lines \n]
        } err opts]} {
            reply $response "status=error\nerror=[string map [list \n { }] $err]"
            puts stderr [dict get $opts -errorinfo]
        }
        file rename $req ${req}.done
        set idle_deadline [expr {[clock seconds]+1800}]
    }
    after 100
}
close_hw_target
disconnect_hw_server
close_hw_manager
exit 0
