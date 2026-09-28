# 只读波形查看入口。
# 输入：两个 Tcl 参数，分别为最终 WDB 和配套 WCFG。
# 输出：Vivado Waveform Viewer 中的数据库和语义分组。
# 作用：只执行 open_wave_database/open_wave_config，不重新运行仿真。
# 失败定位：参数数目、WDB 缺失、WCFG 缺失分别在打开前明确报错。
#
# ---------- 语义段 1：参数和文件完整性检查 ----------
if {$argc != 2} {
    error "Usage: open_final_wdb.tcl <wdb_path> <wcfg_path>"
}

set wdb_path [file normalize [lindex $argv 0]]
set wcfg_path [file normalize [lindex $argv 1]]
if {![file exists $wdb_path]} {
    error "WDB not found: $wdb_path"
}
if {![file exists $wcfg_path]} {
    error "WCFG not found: $wcfg_path"
}

# ---------- 语义段 2：按固定顺序加载数据库和显示配置 ----------
# 先开 WDB 再开 WCFG；顺序反转会导致分组无法绑定对象。
# 成功输出两个 RTDS_FINAL_*_OPENED 原句，便于确认没有误开旧归档。
open_wave_database $wdb_path
open_wave_config $wcfg_path
puts "RTDS_FINAL_WDB_OPENED: $wdb_path"
puts "RTDS_FINAL_WCFG_OPENED: $wcfg_path"
