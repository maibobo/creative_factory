# Attach to an EXISTING, already connected Vivado GUI.
# One lightweight file poll per second; no new GUI, hw_server, reset or programming.
source [file join [file dirname [info script]] rtds_lab.tcl]
namespace eval ::rtds_gui {
    variable active
    if {![info exists active]} {set active 0}
    variable timer
    if {![info exists timer]} {set timer ""}
    variable jobs
    variable root [file normalize [file join [file dirname [info script]] ..]]
}
proc ::rtds_gui::reply {path contents} {
    set f [open "$path.tmp" w]
    fconfigure $f -encoding utf-8
    puts $f $contents
    close $f
    file rename -force "$path.tmp" $path
}
proc ::rtds_gui::save {kind} {
    if {$kind ni {native fdma}} {error "Unsupported capture kind"}
    set c [::rtds_joint::core $kind]
    wait_on_hw_ila -timeout 10 $c
    set data [upload_hw_ila_data $c]
    file mkdir $::rtds_joint::report_dir
    set base [file join $::rtds_joint::report_dir [format "gui_%s_%s_%s" $kind \
        [clock format [clock seconds] -format %Y%m%d_%H%M%S] [clock clicks -milliseconds]]]
    write_hw_ila_data -csv_file "$base.csv" $data
    write_hw_ila_data "$base.ila" $data
    display_hw_ila_data $data
    puts "GUI_CAPTURE_SAVED=$base.csv"
    return "$base.csv"
}
proc ::rtds_gui::execute {words} {
    set command [lindex $words 0]
    set n [llength $words]
    switch -- $command {
        inspect - inject {
            if {$n != 1} {error "No arguments allowed"}
            return [::rtds_lab::$command]
        }
        snapshot {
            if {$n != 1} {error "No arguments allowed"}
            return [dict create path [::rtds_joint::snapshot]]
        }
        arm {
            if {$n != 2 || [lindex $words 1] ni {dma_write dma_read fdma_up}} {error "Unsupported arm operation"}
            ::rtds_joint::arm [lindex $words 1]
            return [dict create armed 1 test [lindex $words 1]]
        }
        save {
            if {$n != 2} {error "Expected capture kind"}
            return [dict create path [save [lindex $words 1]]]
        }
        stop {
            if {$n != 1} {error "No arguments allowed"}
            stop
            return [dict create stopped 1]
        }
        default {error "Unsupported command; arbitrary Tcl evaluation is forbidden"}
    }
}
proc ::rtds_gui::poll {} {
    variable active
    variable timer
    variable jobs
    if {!$active} {return}
    set timer ""
    # Claim before executing: an interrupted/uncertain action is never requeued.
    foreach req [lsort [glob -nocomplain -directory $jobs *.request]] {
        set working "[file rootname $req].working"
        set response "[file rootname $req].response"
        if {[catch {file rename $req $working} problem]} {
            puts "GUI_BRIDGE_CLAIM_FAILED=$problem"
            break
        }
        set f [open $working r]
        set raw [string trim [read $f 256]]
        close $f
        set words [regexp -all -inline {\S+} $raw]
        puts "GUI_ACTION_BEGIN=$raw"
        if {[catch {set result [execute $words]} problem options]} {
            set text "status=error\nerror=[string map [list \n { } \r { }] $problem]"
            puts "GUI_ACTION_FAILED=$problem"
        } else {
            set lines [list status=ok]
            dict for {key value} $result {lappend lines "$key=$value"}
            set text [join $lines \n]
            puts "GUI_ACTION_DONE=$result"
        }
        reply $response $text
        file rename $working "[file rootname $req].done"
        # Execute at most one request per callback; let the GUI handle events.
        break
    }
    if {$active} {set timer [after 1000 ::rtds_gui::poll]}
}
proc ::rtds_gui::start {} {
    variable active
    variable timer
    variable jobs
    variable root
    if {$active} {
        puts "GUI_BRIDGE_ALREADY_READY=$jobs"
        return $jobs
    }
    # Only inspect the user's selected device; do not connect or change its LTX.
    set device [current_hw_device]
    if {$device eq ""} {error "Connect the existing Hardware Manager to the board first"}
    ::rtds_lab::inspect
    set session [format "gui_%s_%s" [clock format [clock seconds] -format %Y%m%d_%H%M%S] [clock clicks -milliseconds]]
    set jobs [file join $root jobs $session]
    file mkdir $jobs
    set ::rtds_joint::report_dir [file join $root captures $session]
    set active 1
    reply [file join $jobs service.ready] "mode=existing_gui\ndevice=$device\nsession=$session"
    set timer [after 1000 ::rtds_gui::poll]
    puts "GUI_BRIDGE_READY=$jobs"
    puts {Use this GUI to observe VIO and ILA. Do not manually inject/rearm while an automated experiment is running. ::rtds_gui::stop stops ONLY this bridge, leaving the GUI connected.}
    return $jobs
}
proc ::rtds_gui::stop {} {
    variable active
    variable timer
    variable jobs
    set active 0
    if {$timer ne ""} {after cancel $timer; set timer ""}
    if {[info exists jobs] && [file exists [file join $jobs service.ready]]} {
        file rename [file join $jobs service.ready] [file join $jobs service.stopped]
    }
    puts {GUI_BRIDGE_STOPPED. Hardware connection and GUI are unchanged.}
}
puts {GUI bridge loaded without hardware actions. Run ::rtds_gui::start in this Tcl Console to attach.}
