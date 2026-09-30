#
# 本脚本只重建由 XCI 派生的生成物，不修改 XDMA/FIFO 的逻辑配置。
# 所有路径均从脚本位置推导，避免沿用工程中历史机器的绝对路径。
#
# 输出：重新生成的 IP/BD simulation target 及 audit 日志。
# 逻辑阶段：路径检查 → 打开工程 → IP 状态/必要重建 → BD validate → 配置审计。

set script_dir  [file dirname [file normalize [info script]]]
set sim_dir     [file normalize [file join $script_dir ..]]
set project_dir [file normalize [file join $sim_dir .. ..]]
set xpr_file    [file join $project_dir RTDS_test_DDR4_64bit.xpr]
set log_dir     [file join $sim_dir logs]

file mkdir $log_dir

proc fail {message} {
    puts "RTDS_AUDIT_ERROR: $message"
    error $message
}

proc expect_property {object property expected label} {
    if {[lsearch -exact [list_property $object] $property] < 0} {
        fail "$label 缺少属性 $property"
    }
    set actual [get_property $property $object]
    puts "RTDS_AUDIT_CONFIG: $label=$actual"
    if {$actual ne $expected} {
        fail "$label 期望为 $expected，实际为 $actual"
    }
}

puts "RTDS_AUDIT_BEGIN: Vivado=[version -short]"
puts "RTDS_AUDIT_PROJECT: $xpr_file"
open_project $xpr_file

# ---------- 语义段 1：修复 fifo_AURORA_DATA64 的派生输出 ----------
set fifo_ip [get_files -all -quiet */fifo_AURORA_DATA64.xci]
if {[llength $fifo_ip] != 1} {
    fail "未唯一找到 fifo_AURORA_DATA64.xci，数量=[llength $fifo_ip]"
}
set fifo_vhdl [file join $project_dir RTDS_test_DDR4_64bit.srcs sources_1 ip fifo_AURORA_DATA64 hdl fifo_generator_v13_2_vhsyn_rfs.vhd]
if {![file exists $fifo_vhdl]} {
    puts "RTDS_AUDIT_FIFO: reset_target all $fifo_ip"
    reset_target all $fifo_ip
    puts "RTDS_AUDIT_FIFO: generate_target all $fifo_ip"
    generate_target all $fifo_ip
} else {
    puts "RTDS_AUDIT_FIFO: 派生文件已存在，本轮不重复 reset/generate"
}
if {![file exists $fifo_vhdl]} {
    fail "FIFO 重建后仍缺失 $fifo_vhdl"
}
puts "RTDS_AUDIT_FIFO_OK: $fifo_vhdl"

# ---------- 语义段 2：检查全部 IP 和 Block Design ----------
report_ip_status -file [file join $log_dir ip_status.txt]
set locked_ips [get_ips -quiet -filter {IS_LOCKED == 1}]
if {[llength $locked_ips] != 0} {
    fail "存在锁定 IP: $locked_ips"
}

# sys_mon 是独立 IP，可直接按现有 XCI 刷新；XDMA 是 BD 子设计，稍后由父 BD 生成。
set sysmon_xci [get_files -all -quiet */sys_mon.xci]
if {[llength $sysmon_xci] == 1} {
    puts "RTDS_AUDIT_GENERATE: generate_target all $sysmon_xci"
    generate_target all $sysmon_xci
}

set bd_file [get_files -all -quiet */design_1.bd]
if {[llength $bd_file] != 1} {
    fail "未唯一找到 design_1.bd，数量=[llength $bd_file]"
}
open_bd_design $bd_file
validate_bd_design
puts "RTDS_AUDIT_GENERATE: generate_target all $bd_file"
generate_target all $bd_file
puts "RTDS_AUDIT_BD_OK: validate_bd_design 与 simulation target 已完成"

# ---------- 语义段 3：锁定本次大仿真的 XDMA 关键配置 ----------
set xdma_ip [get_ips -quiet design_1_xdma_0_0]
if {[llength $xdma_ip] != 1} {
    fail "未唯一找到 design_1_xdma_0_0，数量=[llength $xdma_ip]"
}
expect_property $xdma_ip CONFIG.xdma_rnum_chnl 1       "XDMA_H2C通道数"
expect_property $xdma_ip CONFIG.xdma_wnum_chnl 1       "XDMA_C2H通道数"
expect_property $xdma_ip CONFIG.pl_link_cap_max_link_speed 8.0_GT/s "PCIe速率"
expect_property $xdma_ip CONFIG.pl_link_cap_max_link_width X2       "PCIe宽度"
expect_property $xdma_ip CONFIG.axi_data_width 64_bit   "AXI数据宽度"
expect_property $xdma_ip CONFIG.axisten_freq 250        "AXI时钟MHz"
expect_property $xdma_ip CONFIG.axilite_master_en true  "AXI-Lite主接口"
expect_property $xdma_ip CONFIG.pf0_msi_enabled true    "PF0单向量MSI能力"
expect_property $xdma_ip CONFIG.pf0_msix_enabled false  "PF0 MSI-X关闭"

# ---------- 语义段 4：输出地址映射，作为 BAR/BRAM 测试依据 ----------
set address_report [file join $log_dir address_map.txt]
set address_fp [open $address_report w]
puts $address_fp "segment\toffset\trange"
foreach segment [lsort [get_bd_addr_segs -quiet]] {
    puts $address_fp "$segment\t[get_property OFFSET $segment]\t[get_property RANGE $segment]"
}
close $address_fp
puts "RTDS_AUDIT_ADDRESS_MAP: $address_report"

puts "RTDS_AUDIT_PASS"
close_project
exit 0
