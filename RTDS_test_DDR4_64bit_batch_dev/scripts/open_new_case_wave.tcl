set root [file normalize [file join [file dirname [info script]] ..]]
set case [lindex $argv 0]
if {$case ni {byte1_1g tx_boundaries ready_recovery regs_multiblock period_100ms}} {error "unknown case"}
set folder [file join $root evidence local_wave_sessions $case]
open_project -read_only [file join $folder project wave_${case}.xpr]
open_wave_database [file join $folder ${case}.wdb]
open_wave_config [file join $folder ${case}.wcfg]
puts "SAVED_WAVE_OPENED=$case (no simulation run)"
