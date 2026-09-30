set root_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root_dir RTDS_test.xpr]
open_bd_design [file join $root_dir RTDS_test.srcs sources_1 bd design_1 design_1.bd]
puts "PROJECT=[current_project] PART=[get_property PART [current_project]]"
puts "TOP=[get_property top [get_filesets sources_1]]"
puts "=== CELLS ==="
foreach c [lsort [get_bd_cells]] {
  puts "$c | [get_property VLNV [get_bd_cells $c]]"
}
puts "=== AXI_INTERCONNECT ==="
foreach p [lsort [get_bd_intf_pins axi_interconnect_0/*]] {
  puts "$p | MODE=[get_property MODE $p] VLNV=[get_property VLNV $p]"
}
puts "=== PORTS ==="
foreach p [lsort [get_bd_ports]] {
  puts "$p | DIR=[get_property DIR $p] LEFT=[get_property LEFT $p] RIGHT=[get_property RIGHT $p]"
}
puts "=== ADDRESS ==="
foreach s [get_bd_addr_segs] {
  puts "$s | OFFSET=[get_property OFFSET $s] RANGE=[get_property RANGE $s]"
}
close_project