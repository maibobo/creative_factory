set root [file normalize [file join [file dirname [info script]] ..]]
foreach selected {byte1_1g tx_boundaries ready_recovery regs_multiblock period_100ms} {
  set argv [list $selected]
  source [file join $root scripts open_new_case_wave.tcl]
  set objects [get_objects -r /tb_${selected}/*]
  if {[llength $objects] < 10} {error "no saved HDL objects for $selected"}
  set config [current_wave_config]
  if {[string length $config] == 0} {error "no saved wave config for $selected"}
  puts "NEW_WAVE_VERIFIED=$selected objects=[llength $objects] config=$config"
  close_sim
  close_project
}
puts "NEW_WAVE_VERIFY_COMPLETE (read-only saved databases, no run)"
exit
