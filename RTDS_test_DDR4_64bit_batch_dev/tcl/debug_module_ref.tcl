set root_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root_dir RTDS_test.xpr]
update_compile_order -fileset sources_1
open_bd_design [file join $root_dir RTDS_test.srcs sources_1 bd design_1 design_1.bd]
puts "IPS=[get_ips -quiet *INFO*]"
puts "CELL=[get_bd_cells -quiet INFO_EXCH_0]"
foreach arg [list {INFO_EXCH_0} {/INFO_EXCH_0} [get_ips -quiet *INFO*]] {
  puts "TRY=$arg"
  if {[catch {update_module_reference $arg} msg opts]} {
    puts "ERR=$msg"
    puts "OPTS=$opts"
  } else { puts "OK=$msg" }
}
close_project