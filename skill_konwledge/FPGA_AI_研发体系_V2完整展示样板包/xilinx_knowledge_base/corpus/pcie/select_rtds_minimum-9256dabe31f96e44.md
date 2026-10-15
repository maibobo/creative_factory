# select_rtds_minimum

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\scripts\select_rtds_minimum.tcl`
- SHA-256: `9256dabe31f96e44e1ba66aef53f3cc21fb22a2a8e80b050953414ab7e855c3f`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```tcl
# ---------- 语义段 1：Vivado 2020.2 Windows TESTNAME 兼容层 ----------
# 正常 XSim 应通过 `-testplusarg TESTNAME=rtds_minimum` 向官方
# USRAPP 传递用例名。本机 2020.2 的 bat/loader 会错误拆分含等号
# 的参数。本脚本只在仿真运行期强制官方 testname 寄存器，
# 不修改 RP 的链路、枚举、BAR 或 XDMA TPI 逻辑。

set rtds_testname_object [get_objects -quiet /board/RP/tx_usrapp/testname]
if {[llength $rtds_testname_object] == 0} {
    error "RTDS_TEST_SELECT_ERROR: /board/RP/tx_usrapp/testname 不可见"
}

# 256-bit Verilog 字符串 "rtds_minimum"；ASCII 字节右对齐。
set rtds_testname_hex 0000000000000000000000000000000000000000727464735f6d696e696d756d
set rtds_testname_force [add_force -radix hex $rtds_testname_object $rtds_testname_hex]
puts "RTDS_TEST_SELECT_COMPAT: forced TESTNAME=rtds_minimum"
```
