# Add the CONV_DMA integration wrapper/testbench files to the Vivado project.
# This script is idempotent: existing files are not added twice.

set project_xpr {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.xpr}
set loop_root   {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate}
set conv_dma    {E:/PCIE-CPU/RTDS_test/RTDS_test.srcs/sources_1/new/CONV_DMA.v}

proc add_if_missing {fileset_name file_path} {
    if {![file exists $file_path]} {
        error "missing source file: $file_path"
    }
    set fs [get_filesets $fileset_name]
    set existing [get_files -quiet -of_objects $fs [list $file_path]]
    if {[llength $existing] == 0} {
        add_files -norecurse -fileset $fileset_name [list $file_path]
        puts "ADD_FILE fileset=$fileset_name path=$file_path"
    } else {
        puts "KEEP_FILE fileset=$fileset_name path=$file_path"
    }
}

if {[current_project -quiet] eq ""} {
    open_project $project_xpr
}

set design_top [get_property top [get_filesets sources_1]]

set wrapper_file "$loop_root/new/fdma_aurora_pcie_conv_dma_wrapper.v"
set axi_ram_file "$loop_root/new/integration/axi_ram_model.sv"
set tb_file      "$loop_root/new/integration/tb_fdma_aurora_brg_conv_dma_integration.sv"

add_if_missing sources_1 $wrapper_file

set sim_files [list $axi_ram_file $tb_file $conv_dma]
foreach f $sim_files {
    add_if_missing sim_1 $f
}

foreach f [list $axi_ram_file $tb_file] {
    set f_obj [get_files -quiet [list $f]]
    if {[llength $f_obj] == 0} {
        error "file was added but cannot be resolved for file_type: $f"
    }
    set_property file_type SystemVerilog $f_obj
}

set sim_file_objs {}
foreach f $sim_files {
    set f_obj [get_files -quiet -of_objects [get_filesets sim_1] [list $f]]
    if {[llength $f_obj] == 0} {
        error "sim file was added but cannot be resolved: $f"
    }
    foreach obj $f_obj {
        lappend sim_file_objs $obj
    }
}

set_property used_in_synthesis false $sim_file_objs
set_property used_in_implementation false $sim_file_objs

set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]

if {$design_top ne ""} {
    set_property top $design_top [get_filesets sources_1]
}
set_property top tb_fdma_aurora_brg_conv_dma_integration [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INTEGRATION_SOURCES_ADDED"
puts "DESIGN_TOP=$design_top"
puts "SIM_TOP=[get_property top [get_filesets sim_1]]"
