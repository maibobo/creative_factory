
#set_property PACKAGE_PIN AC23 [get_ports clk]
#set_property IOSTANDARD LVCMOS33 [get_ports clk]
#set_property PACKAGE_PIN Y17 [get_ports led]
#set_property IOSTANDARD LVCMOS33 [get_ports led]


set_property PACKAGE_PIN AK17 [get_ports clk_p]
set_property PACKAGE_PIN AK16 [get_ports clk_n]
set_property IOSTANDARD DIFF_HSTL_I_12 [get_ports clk_p]
set_property IOSTANDARD DIFF_HSTL_I_12 [get_ports clk_n]
# 100 MHz板级差分主时钟；共享IBUFDS输出分别驱动clk_wiz与NO_BUFFER模式MIG。
create_clock -period 10.000 -name sys_clk_100m [get_ports clk_p]
set_property PACKAGE_PIN T23 [get_ports led]
set_property IOSTANDARD LVCMOS18 [get_ports led]






set_property PACKAGE_PIN Y6 [get_ports {pcie_diff_clk_p[0]}]
set_property PACKAGE_PIN K22 [get_ports pcie_rst_n]
set_property PACKAGE_PIN T22 [get_ports user_lnk_up]
set_property IOSTANDARD LVCMOS18 [get_ports user_lnk_up]
set_property PACKAGE_PIN AM6 [get_ports {pcie_mgt_txp[1]}]
set_property PACKAGE_PIN AN4 [get_ports {pcie_mgt_txp[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_rst_n]
