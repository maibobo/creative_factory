# Backward-compatible entry point; the migration is implemented in the dedicated BD Tcl.
set _refresh_dir [file dirname [file normalize [info script]]]
source [file join $_refresh_dir update_ddr_axi_dma_bridge_bd.tcl]
