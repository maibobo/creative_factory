# 快速回归入口：保留所有断言、scoreboard 与语义日志，但不建立大规模 WDB。
# 出现失败时再使用 run.tcl 复现并采集分组波形，避免每次通过用例都记录
# 4 KiB DATA_STORE、PCIe TLP 与 XDMA 内部总线。
#
# 输入：已展开的 FastMode board snapshot。
# 输出：功能日志和 summary，不输出最终波形证据。
# 失败定位：功能失败改用同源 WaveMode 重跑；snapshot 过期必须先重新 xelab。
# ---------- 语义段 1：选择用例并运行全部仿真 ----------
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir select_rtds_minimum.tcl]
puts "RTDS_FAST_MODE: assertions=on scoreboard=on waves=off"
run all
# ---------- 语义段 2：用例主动完成后退出批处理 ----------
# 若走到 2 ms watchdog，结合最后 milestone 定位未前进阶段。
quit
