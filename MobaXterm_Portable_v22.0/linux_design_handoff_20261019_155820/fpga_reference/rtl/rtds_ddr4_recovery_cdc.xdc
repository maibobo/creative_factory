# 修改记录 2026-10-12：DDR事务恢复新增同步器的定点CDC约束。
# converter_reset_n异步置位复位；s/m管线分别经过16个目的时钟沿释放。
# 此例外只针对同步器的异步CLR入口；同步释放链的Q->D路径仍正常检查。
# converter_ready_sync[0]是MIG接口复位释放确认的第一级电平同步器。
# 仅排除首级D的异步采样；[0]/Q->[1]/D及全部业务路径仍正常检查。
# 不建立整组时钟异步例外，不改变MIG内部时钟周期或协议路径要求。
set_false_path -to [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_(s|m)_reset_pipe_reg\[[0-9]+\]$}] -filter {REF_PIN_NAME == CLR}]
set_false_path -to [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[[01]\]$}] -filter {REF_PIN_NAME == CLR}]
set_false_path -to [get_pins -of_objects [get_cells -hier -regexp {^u_pcie/u_rtds_ddr4_backend/converter_ready_sync_reg\[0\]$}] -filter {REF_PIN_NAME == D}]
