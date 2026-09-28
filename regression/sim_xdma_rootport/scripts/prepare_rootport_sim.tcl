# RTDS_test-1ch XDMA Root Port 大仿真：建立独立 simulation fileset 并导出 XSim 脚本。
# 本脚本不保存工程；自定义 testbench 只存在于本次内存会话和 work/export 中。
#
# 输入：真实 RTDS_test_DDR4_64bit.xpr、vendor/xdma_rp_2020_2 和 tb/ 自定义验证文件。
# 输出：内存 simulation fileset、正确编译顺序及 work/export XSim 脚本。
# 逻辑阶段：路径检查 → 打开工程/生成 target → 加 RP/TB → 设置 include/top
# → update_compile_order → export_simulation。
# 失败定位：缺 vendor 文件查 manifest；DUT 层级错误查真实工程 source；
# export 后绝不使用工程遗留绝对路径。

set script_dir  [file dirname [file normalize [info script]]]
set sim_dir     [file normalize [file join $script_dir ..]]
set project_dir [file normalize [file join $sim_dir .. ..]]
set xpr_file    [file join $project_dir RTDS_test_DDR4_64bit.xpr]
set tb_dir      [file join $sim_dir tb]
set vendor_dir  [file join $sim_dir vendor xdma_rp_2020_2]
set export_dir  [file join $sim_dir work export]
set log_dir     [file join $sim_dir logs]

file mkdir $export_dir
file mkdir $log_dir

proc fail {message} {
    puts "RTDS_PREPARE_ERROR: $message"
    error $message
}

puts "RTDS_PREPARE_BEGIN: Vivado=[version -short]"
open_project $xpr_file

# ---------- 语义段 1：新建仅用于大仿真的 fileset ----------
set simset_name sim_xdma_rootport
set old_simset [get_filesets -quiet $simset_name]
if {[llength $old_simset] != 0} {
    set base_simset [get_filesets -quiet sim_1]
    if {[llength $base_simset] == 1} {
        current_fileset -simset $base_simset
    }
    delete_fileset $old_simset
}
create_fileset -simset $simset_name
set simset [get_filesets $simset_name]
set_property SOURCE_SET sources_1 $simset
set_property TOP board $simset
set_property TOP_LIB xil_defaultlib $simset
set_property INCLUDE_DIRS [list $tb_dir $vendor_dir] $simset
set_property VERILOG_DEFINE [list XILINX_SIMULATOR] $simset
# typical 保留本用例所需的层级观测；all 会显著放大完整 XDMA/PCIe 展开映像。
set_property XSIM.ELABORATE.DEBUG_LEVEL typical $simset
set_property XSIM.SIMULATE.RUNTIME 2ms $simset
current_fileset -simset $simset

# ---------- 语义段 2：按包、官方 RP、监视器、顶层的依赖顺序加入 ----------
set sim_sources [list \
    [file join $tb_dir rtds_rootport_pkg.sv] \
    [file join $vendor_dir pci_exp_usrapp_cfg.v] \
    [file join $vendor_dir pci_exp_usrapp_com.v] \
    [file join $vendor_dir pci_exp_usrapp_rx.v] \
    [file join $vendor_dir pci_exp_usrapp_tx.v] \
    [file join $vendor_dir pcie3_uscale_rp_core_top.v] \
    [file join $vendor_dir pcie3_uscale_rp_top.v] \
    [file join $vendor_dir sys_clk_gen.v] \
    [file join $vendor_dir sys_clk_gen_ds.v] \
    [file join $vendor_dir xilinx_pcie_uscale_rp.v] \
    [file join $tb_dir rtds_pcie_ep_sim_wrapper.sv] \
    [file join $tb_dir aurora_ll_peer_bfm.sv] \
    [file join $tb_dir pcie_cq_host_memory_monitor.sv] \
    [file join $tb_dir rtds_rootport_assertions.sv] \
    [file join $tb_dir board.sv] \
]

foreach source $sim_sources {
    if {![file exists $source]} {
        fail "仿真源文件不存在: $source"
    }
}
add_files -fileset $simset -norecurse $sim_sources
update_compile_order -fileset $simset

# ---------- 语义段 3：保存实际编译依赖清单 ----------
set order_fp [open [file join $log_dir compile_order.txt] w]
foreach source [get_files -compile_order sources -used_in simulation -of_objects $simset] {
    puts $order_fp $source
}
close $order_fp

# ---------- 语义段 4：导出到独立 work 目录，不使用旧 2020.1 脚本 ----------
file delete -force $export_dir
file mkdir $export_dir
export_simulation -of_objects $simset -simulator xsim -directory $export_dir -force -absolute_path
set launcher_files [glob -nocomplain -directory $export_dir */board.sh */*/board.sh]
if {[llength $launcher_files] == 0} {
    fail "export_simulation 未生成 board.sh"
}
puts "RTDS_PREPARE_EXPORT: $export_dir"
puts "RTDS_PREPARE_PASS"

close_project
exit 0
