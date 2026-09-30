set root [file normalize [file join [file dirname [info script]] ..]]
puts "GUI_OPEN_COMMANDS=[info commands *open*]"
puts "GUI_VIEW_COMMANDS=[info commands *view*]"
puts "GUI_RDI_OPEN_COMMANDS=[info commands ::rdi::*open*]"
set argv {tx}
source [file join $root scripts open_local_wave_session.tcl]
