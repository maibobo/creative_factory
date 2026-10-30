# Vivado 2020.2: replace the CONV_DMA module-ref cell with ddr_axi_dma_bridge.
# Updates the Block Design and regenerates BD outputs/wrapper only.
# Does NOT launch simulation, synthesis, implementation, or bitstream generation.
# Run: vivado.bat -mode batch -source scripts/update_ddr_axi_dma_bridge_bd.tcl

set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set project_file [file join $project_dir RTDS_test_DDR4_64bit.xpr]
set source_file [file join $project_dir RTDS_test_DDR4_64bit.srcs sources_1 new ddr_axi_dma_bridge.v]
set bd_file [file join $project_dir RTDS_test_DDR4_64bit.srcs sources_1 bd design_1 design_1.bd]

foreach required [list $project_file $source_file $bd_file] {
    if {![file exists $required]} {
        error "Required migration input is missing: $required"
    }
}

if {[current_project -quiet] ne ""} {
    close_project
}
open_project $project_file

# Replace only the hand-written RTL source entry. Do not touch generated IP sources.
set old_sources [get_files -quiet -of_objects [get_filesets sources_1] *CONV_DMA.v]
if {[llength $old_sources] > 0} {
    remove_files $old_sources
}
set new_sources [get_files -quiet -of_objects [get_filesets sources_1] $source_file]
if {[llength $new_sources] == 0} {
    add_files -norecurse -fileset sources_1 $source_file
    set new_sources [get_files -quiet -of_objects [get_filesets sources_1] $source_file]
}
if {[llength $new_sources] != 1} {
    error "Expected exactly one ddr_axi_dma_bridge.v source; found: $new_sources"
}
set_property file_type Verilog [lindex $new_sources 0]
update_compile_order -fileset sources_1

# Keep the pre-existing INFO_EXCH module-reference refresh behavior.
set info_sources [get_files -quiet -of_objects [get_filesets sources_1] *INFO_EXCH.v]
foreach src $info_sources {
    set src_path [get_property NAME $src]
    remove_files $src
    add_files -norecurse -fileset sources_1 $src_path
}
update_compile_order -fileset sources_1

set bd_obj [get_files -quiet $bd_file]
if {[llength $bd_obj] != 1} {
    error "Expected exactly one design_1.bd file object; found: $bd_obj"
}
open_bd_design [lindex $bd_obj 0]

set old_cell_name CONV_DMA_0
set new_cell_name ddr_axi_dma_bridge_0
set old_cell [get_bd_cells -quiet $old_cell_name]
set new_cell [get_bd_cells -quiet $new_cell_name]

if {[llength $old_cell] > 0 && [llength $new_cell] > 0} {
    error "Both $old_cell_name and $new_cell_name exist; refusing an ambiguous BD migration."
}
if {[llength $old_cell] == 0 && [llength $new_cell] == 0} {
    error "Neither $old_cell_name nor $new_cell_name exists in design_1."
}

# Each pair maps an old module-ref pin to its new generic request-side name.
set pin_map {
    fdma_wstrb wr_byte_enable
    fdma_wdone wr_done_event
    fdma_werror wr_error
    fdma_waddr wr_addr
    fdma_wareq wr_req
    fdma_wsize wr_beat_count
    fdma_wbusy wr_busy
    fdma_wdata wr_data
    fdma_wvalid wr_data_accept_event
    fdma_wready wr_data_valid
    fdma_raddr rd_addr
    fdma_rareq rd_req
    fdma_rsize rd_beat_count
    fdma_rbusy rd_busy
    fdma_rdata rd_data
    fdma_rvalid rd_data_accept_event
    fdma_rready rd_data_ready
    M_AXI_ACLK M_AXI_ACLK
    M_AXI_ARESETN M_AXI_ARESETN
}

if {[llength $old_cell] > 0} {
    # Capture all non-cell endpoints before deleting the old module-ref cell.
    set saved_endpoints [dict create]
    foreach {old_pin_name new_pin_name} $pin_map {
        set old_pin [get_bd_pins -quiet "$old_cell_name/$old_pin_name"]
        if {[llength $old_pin] != 1} {
            error "Expected old BD pin $old_cell_name/$old_pin_name; found: $old_pin"
        }
        set old_net [get_bd_nets -quiet -of_objects $old_pin]
        if {[llength $old_net] != 1} {
            error "Old BD pin $old_cell_name/$old_pin_name is not connected to exactly one net."
        }
        set endpoints [list]
        foreach pin [get_bd_pins -quiet -of_objects $old_net] {
            if {[get_property NAME $pin] ne [get_property NAME $old_pin]} {
                lappend endpoints $pin
            }
        }
        foreach port [get_bd_ports -quiet -of_objects $old_net] {
            lappend endpoints $port
        }
        if {[llength $endpoints] == 0} {
            error "No external endpoint remains for old pin $old_cell_name/$old_pin_name."
        }
        dict set saved_endpoints $new_pin_name $endpoints
    }

    # Preserve the inferred M_AXI interface connection to the AXI interconnect.
    set old_intf_pin [get_bd_intf_pins -quiet "$old_cell_name/M_AXI"]
    if {[llength $old_intf_pin] != 1} {
        error "Expected inferred M_AXI interface pin on $old_cell_name."
    }
    set old_intf_net [get_bd_intf_nets -quiet -of_objects $old_intf_pin]
    if {[llength $old_intf_net] != 1} {
        error "The old M_AXI interface is not connected to exactly one interface net."
    }
    set intf_endpoints [list]
    foreach intf_pin [get_bd_intf_pins -quiet -of_objects $old_intf_net] {
        if {[get_property NAME $intf_pin] ne [get_property NAME $old_intf_pin]} {
            lappend intf_endpoints $intf_pin
        }
    }
    if {[llength $intf_endpoints] == 0} {
        error "No external interface endpoint remains for $old_cell_name/M_AXI."
    }

    delete_bd_objs $old_cell
    create_bd_cell -type module -reference ddr_axi_dma_bridge $new_cell_name
    set new_cell [get_bd_cells $new_cell_name]

    foreach {old_pin_name new_pin_name} $pin_map {
        set new_pin [get_bd_pins -quiet "$new_cell_name/$new_pin_name"]
        if {[llength $new_pin] != 1} {
            error "New module-ref pin is missing: $new_cell_name/$new_pin_name"
        }
        set endpoints [dict get $saved_endpoints $new_pin_name]
        set connect_args [concat $endpoints [list $new_pin]]
        connect_bd_net {*}$connect_args
    }

    set new_intf_pin [get_bd_intf_pins -quiet "$new_cell_name/M_AXI"]
    if {[llength $new_intf_pin] != 1} {
        error "New module reference did not infer the M_AXI interface."
    }
    set intf_connect_args [concat $intf_endpoints [list $new_intf_pin]]
    connect_bd_intf_net {*}$intf_connect_args
} else {
    # Idempotent rerun after a previous successful BD update.
    foreach {old_pin_name new_pin_name} $pin_map {
        if {[llength [get_bd_pins -quiet "$new_cell_name/$new_pin_name"]] != 1} {
            error "Existing migrated cell is missing pin $new_cell_name/$new_pin_name"
        }
    }
    if {[llength [get_bd_intf_pins -quiet "$new_cell_name/M_AXI"]] != 1} {
        error "Existing migrated cell is missing inferred M_AXI interface."
    }
}

# Retain the existing INFO_EXCH configuration and external status ports.
foreach {port pin direction width} {
    fdma_wstrb_0 ddr_axi_dma_bridge_0/wr_byte_enable I 8
    CPU_WR_DONE_EVENT INFO_EXCH_0/CPU_WR_DONE_EVENT I 1
    fdma_wdone_0 ddr_axi_dma_bridge_0/wr_done_event O 1
    fdma_werror_0 ddr_axi_dma_bridge_0/wr_error O 1
    RX_READY_BLOCKS INFO_EXCH_0/RX_READY_BLOCKS I 32
    RX_HEAD_SEQ INFO_EXCH_0/RX_HEAD_SEQ I 32
    RX_DROPPED_FRAMES INFO_EXCH_0/RX_DROPPED_FRAMES I 32
} {
    if {[llength [get_bd_ports -quiet $port]] == 0} {
        if {$width == 1} {
            create_bd_port -dir $direction $port
        } else {
            create_bd_port -dir $direction -from [expr {$width-1}] -to 0 $port
        }
    }
    set pin_obj [get_bd_pins -quiet $pin]
    if {[llength $pin_obj] != 1} {
        error "Required BD pin not found: $pin"
    }
    if {[llength [get_bd_nets -quiet -of_objects $pin_obj]] == 0} {
        connect_bd_net [get_bd_ports $port] $pin_obj
    }
}

set info_cell [get_bd_cells -quiet INFO_EXCH_0]
if {[llength $info_cell] != 1} {
    error "Expected INFO_EXCH_0 module reference."
}
set_property -dict [list CONFIG.VERSION {0x00002001} CONFIG.PROG_TIME {0x20260914} CONFIG.CH_BUF_LEN {0x00040000}] $info_cell

# Re-assign the existing AXI address range to the renamed module-ref address space.
foreach space [list "$new_cell_name/M_AXI" "xdma_0/M_AXI"] {
    set addr_space [get_bd_addr_spaces -quiet $space]
    if {[llength $addr_space] != 1} {
        error "Expected AXI address space $space."
    }
    assign_bd_address -force -offset 0 -range 4M -target_address_space $addr_space [get_bd_addr_segs M_AXI_MEM/Reg]
}

validate_bd_design
save_bd_design
generate_target all [lindex $bd_obj 0]
export_ip_user_files -of_objects [lindex $bd_obj 0] -no_script -sync -force
make_wrapper -files [lindex $bd_obj 0] -top
update_compile_order -fileset sources_1
close_project
puts "BD migration complete: $old_cell_name -> $new_cell_name"
puts "No simulation, synthesis, implementation, or bitstream generation was started."
