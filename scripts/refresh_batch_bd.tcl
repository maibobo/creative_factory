# 仅供后续手工执行：刷新模块引用和 BD 输出，不启动仿真、综合、实现。
# 调用固定 Vivado 2020.2；本轮没有执行本脚本。
set project_dir [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $project_dir RTDS_test_DDR4_64bit.xpr]
update_compile_order -fileset sources_1
puts "MODULE_FILES=[get_files -all *CONV_DMA.v] [get_files -all *INFO_EXCH.v]"
foreach src [list [get_files *CONV_DMA.v] [get_files *INFO_EXCH.v]] {
    set name $src
    remove_files $src
    add_files $name
}
update_compile_order -fileset sources_1
open_bd_design [get_files design_1.bd]
# update_module_reference接收IP对象，不能传入BD cell对象。
foreach pattern {*CONV_DMA* *INFO_EXCH*} {
    set refs [get_ips -all $pattern]
    puts "REFRESH_IP=$refs"
    update_module_reference $refs
}
foreach {port pin direction width} {
    fdma_wstrb_0 CONV_DMA_0/fdma_wstrb I 8
    CPU_WR_DONE_EVENT INFO_EXCH_0/CPU_WR_DONE_EVENT I 1
    fdma_wdone_0 CONV_DMA_0/fdma_wdone O 1
    fdma_werror_0 CONV_DMA_0/fdma_werror O 1
    RX_READY_BLOCKS INFO_EXCH_0/RX_READY_BLOCKS I 32
    RX_HEAD_SEQ INFO_EXCH_0/RX_HEAD_SEQ I 32
    RX_DROPPED_FRAMES INFO_EXCH_0/RX_DROPPED_FRAMES I 32
} {
    if {[llength [get_bd_ports -quiet $port]] == 0} {
        if {$width == 1} {create_bd_port -dir $direction $port} else {
            create_bd_port -dir $direction -from [expr {$width-1}] -to 0 $port
        }
    }
    if {[llength [get_bd_nets -quiet -of_objects [get_bd_pins $pin]]] == 0} {
        connect_bd_net [get_bd_ports $port] [get_bd_pins $pin]
    }
}
set_property -dict [list CONFIG.VERSION {0x00002001} CONFIG.PROG_TIME {0x20260914} CONFIG.CH_BUF_LEN {0x00040000}] [get_bd_cells INFO_EXCH_0]
foreach space {CONV_DMA_0/M_AXI xdma_0/M_AXI} {
    assign_bd_address -force -offset 0 -range 4M -target_address_space [get_bd_addr_spaces $space] [get_bd_addr_segs M_AXI_MEM/Reg]
}
validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
export_ip_user_files -of_objects [get_files design_1.bd] -no_script -sync -force
make_wrapper -files [get_files design_1.bd] -top
update_compile_order -fileset sources_1
close_project
