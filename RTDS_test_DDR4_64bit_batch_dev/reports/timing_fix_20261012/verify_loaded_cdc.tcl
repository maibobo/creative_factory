# 修改记录 2026-10-12：实现网表上验证CDC约束已加载；失配直接停止，避免无效重跑。
set rtds_out C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/reports/timing_fix_20261012/loaded_constraint_check
file mkdir $rtds_out
# 修改点 2026-10-12：read_xdc后显式刷新时序图，避免查询仍使用旧检查结果。
update_timing
set rtds_pipes [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_(s|m)_reset_pipe_reg\[[0-9]+\]$}]
set rtds_sync [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[[01]\]$}]
set rtds_clr [get_pins -of_objects [concat $rtds_pipes $rtds_sync] -filter {REF_PIN_NAME == CLR}]
if {[llength $rtds_pipes] != 32 || [llength $rtds_sync] != 2 || [llength $rtds_clr] != 34} {error "RTDS_CDC_TARGET_COUNT_FAIL"}
foreach rtds_cell [concat $rtds_pipes $rtds_sync] {if {[get_property ASYNC_REG $rtds_cell] != 1} {error "RTDS_ASYNC_REG_MISSING: $rtds_cell"}}
set rtds_q0 [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[0\]$}] -filter {REF_PIN_NAME == Q}]
set rtds_d1 [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[1\]$}] -filter {REF_PIN_NAME == D}]
set rtds_d0 [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[0\]$}] -filter {REF_PIN_NAME == D}]
set rtds_mq [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_m_reset_pipe_reg\[15\]$}] -filter {REF_PIN_NAME == Q}]
if {[llength [get_timing_paths -quiet -from $rtds_mq -to $rtds_d0 -max_paths 1]] != 0} {error "RTDS_FIRST_STAGE_EXCEPTION_NOT_LOADED"}
if {[llength [get_timing_paths -quiet -to $rtds_clr -max_paths 1]] != 0} {error "RTDS_RESET_ENTRY_EXCEPTION_NOT_LOADED"}
if {[llength [get_timing_paths -quiet -from $rtds_q0 -to $rtds_d1 -max_paths 1]] != 1} {error "RTDS_SECOND_STAGE_NOT_TIMED"}
report_timing -from $rtds_q0 -to $rtds_d1 -max_paths 1 -file $rtds_out/second_stage_timed.rpt
set rtds_f [open $rtds_out/constraint_check.txt w]
puts $rtds_f "RTDS_CDC_CONSTRAINT_CHECK_PASS reset_CLR=34 first_stage_D=1 second_stage_normally_timed=1"
close $rtds_f
puts "RTDS_CDC_CONSTRAINT_CHECK_PASS"
