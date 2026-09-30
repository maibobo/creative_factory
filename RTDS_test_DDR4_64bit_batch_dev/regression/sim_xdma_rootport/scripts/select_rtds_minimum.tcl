# ---------- 语义段 1：Vivado 2020.2 Windows TESTNAME 兼容层 ----------
# FastMode 的 debug-off snapshot 不允许 Tcl get_objects/add_force。
# 用例映射已隔离在自定义 tb/tests.vh：官方 AXI-MM 默认 dma_test0
# 输入：无；输出：一条兼容层日志。
# 失败定位：未进入用例应查 tests.vh include/testname，而不是 Tcl 层级 force。
puts "RTDS_TEST_SELECT_COMPAT: tests.vh maps isolated AXI-MM default to rtds_minimum"
