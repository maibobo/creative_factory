#
# Final address map:
#   0x0000_0000 - 0x0000_7fff : Aurora -> CPU (RX), 32 KiB
#   0x0000_8000 - 0x0000_ffff : CPU -> Aurora (TX), 32 KiB
#
# Both masters see the same 64 KiB BRAM segment.  The AXI-Lite register
# segment remains at 0x4000_0000 and is intentionally not modified here.

set script_dir   [file dirname [file normalize [info script]]]
set project_path [file normalize [file join $script_dir .. RTDS_test.xpr]]
set bd_path      [file normalize [file join $script_dir .. RTDS_test.srcs sources_1 bd design_1 design_1.bd]]

if {![file exists $project_path]} {
  error "RTDS project not found: $project_path"
}
if {![file exists $bd_path]} {
  error "Block design not found: $bd_path"
}

open_project $project_path

# The checked-in project was created with Vivado 2020.1. Vivado 2020.2 locks
# those catalog IP revisions and refuses any BD edit until they are upgraded.
# Keep this explicit and reproducible instead of editing the BD JSON by hand.
set locked_ips [get_ips -quiet -filter {IS_LOCKED == 1}]
if {[llength $locked_ips] != 0} {
  puts "RTDS_64K_BD_CONFIG: upgrading locked IPs for Vivado 2020.2: $locked_ips"
  upgrade_ip $locked_ips
}

open_bd_design $bd_path

set bram_cell [get_bd_cells -quiet /blk_mem_gen_0]
if {[llength $bram_cell] != 1} {
  error "Expected exactly one /blk_mem_gen_0 cell"
}

# 64-bit x 8192 words = 64 KiB.  Port B depth follows port A for true dual
# port BRAM.  Keep all existing width, byte-enable and operating-mode options.
set_property -dict [list CONFIG.Write_Depth_A {8192}] $bram_cell
validate_bd_design

set memory_segment_name SEG_axi_bram_ctrl_0_Mem0
foreach address_space_name [list /CONV_DMA_0/M_AXI /xdma_0/M_AXI] {
  set address_space [get_bd_addr_spaces -quiet $address_space_name]
  if {[llength $address_space] != 1} {
    error "Address space not found: $address_space_name"
  }

  set mapped_segment [get_bd_addr_segs -quiet -of_objects $address_space \
    -filter "NAME =~ *$memory_segment_name"]
  if {[llength $mapped_segment] != 1} {
    error "Expected one BRAM segment in $address_space_name, got: $mapped_segment"
  }

  set_property offset 0x0000000000000000 $mapped_segment
  set_property range 64K $mapped_segment
}

validate_bd_design
save_bd_design

# The existing clock wizard already has a configured-but-disabled 100 MHz
# third output.  Enable it for the Aurora INIT_CLK; clk_out1 remains 250 MHz
# and clk_out2 remains 156.25 MHz.
set clk_ip [get_ips -quiet clk_wiz_0]
if {[llength $clk_ip] == 1} {
  set_property -dict [list \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000} \
  ] $clk_ip
  set clk_xci_path [file normalize [file join $script_dir .. RTDS_test.srcs sources_1 ip clk_wiz_0 clk_wiz_0.xci]]
  set clk_xci [get_files -quiet $clk_xci_path]
  if {[llength $clk_xci] != 1} {
    error "Clock wizard XCI not found in project: $clk_xci_path"
  }
  reset_target all $clk_xci
  generate_target all $clk_xci
} else {
  error "Expected exactly one clk_wiz_0 IP"
}

generate_target all [get_files $bd_path]
make_wrapper -files [get_files $bd_path] -top
update_compile_order -fileset sources_1

puts "RTDS_64K_BD_CONFIG: BRAM Write_Depth_A=[get_property CONFIG.Write_Depth_A $bram_cell]"
foreach address_space_name [list /CONV_DMA_0/M_AXI /xdma_0/M_AXI] {
  set address_space [get_bd_addr_spaces $address_space_name]
  set mapped_segment [get_bd_addr_segs -of_objects $address_space \
    -filter "NAME =~ *$memory_segment_name"]
  puts "RTDS_64K_BD_CONFIG: $address_space_name offset=[get_property OFFSET $mapped_segment] range=[get_property RANGE $mapped_segment]"
}
puts "RTDS_64K_BD_CONFIG: INFO_EXCH AXI-Lite mapping was not changed"

close_project
