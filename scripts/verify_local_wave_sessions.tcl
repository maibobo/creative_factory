set root [file normalize [file join [file dirname [info script]] ..]]
puts "OPEN_FILES_COMMAND=[info commands open_files]"
puts "SHOW_OBJECTS_COMMAND=[info commands show_objects]"
if {[llength $argv] > 0} {set cases $argv} else {set cases {1g tx rx_fifo ring axi axi_tail regs}}
foreach selected $cases {
    set argv [list $selected verify]
    source [file join $root scripts open_local_wave_session.tcl]
    set folder [file join $root evidence local_wave_sessions $selected]
    set fh [open [file join $folder loaded_objects.txt] w]
    set objects [get_objects -r /tb_rtds_${selected}/*]
    foreach obj $objects {puts $fh $obj}
    close $fh
    puts "LOCAL_VERIFIED=$selected objects=[llength $objects]"
    close_sim
    close_project
}
puts "LOCAL_VERIFY_ALL_COMPLETE"
