set root [file normalize [file join [file dirname [info script]] ..]]
set selected [lindex $argv 0]
if {$selected ni {1g tx rx_fifo ring axi axi_tail regs}} {error "Select 1g, tx, rx_fifo, ring, axi, axi_tail or regs"}
set folder [file join $root evidence local_wave_sessions $selected]
open_project -read_only [file join $folder project wave_${selected}.xpr]
open_wave_database [file join $folder ${selected}.wdb]
open_wave_config [file join $folder ${selected}.wcfg]
if {[llength [get_objects -r /tb_rtds_${selected}/*]] == 0} {error "Wave database has no testbench objects"}
if {[lindex $argv 1] ne "verify"} {
    current_scope /tb_rtds_${selected}/U_DUT
    puts "SOURCE_NAVIGATION=Use Go To Source Code from a signal, or open a file from Simulation Sources."
}
puts "LOCAL_WAVE_READY=$selected"
