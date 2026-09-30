# 参考verified 1G design/constraints/aurora_8b10b_1p25g_design.xdc。
# GT通道由对应XCI生成约束；不把独立例程init_clk_in端口约束复制到集成顶层。
set_property LOC AB6 [get_ports aurora1g_refclk_p]
set_property LOC AB5 [get_ports aurora1g_refclk_n]
create_clock -name aurora1g_gt_refclk -period 8.000 [get_ports aurora1g_refclk_p]
# RPT205-1-001 pin workbook, Sheet1 rows 78/77: board 156.25MHz reference.
# Board wiring, rather than the imported example XCI location, defines these pins.
set_property LOC V6 [get_ports GTHQ0_P]
set_property LOC V5 [get_ports GTHQ0_N]
create_clock -name aurora10g_gt_refclk -period 6.400 [get_ports GTHQ0_P]

# RPT205 optical port 1, BANK225, lane 0 (RD1/TD1).
set_property PACKAGE_PIN AH2 [get_ports aurora1g_rxp]
set_property PACKAGE_PIN AH1 [get_ports aurora1g_rxn]
set_property PACKAGE_PIN AH6 [get_ports aurora1g_txp]
set_property PACKAGE_PIN AH5 [get_ports aurora1g_txn]
# RPT205 optical port 5, BANK226, lane 0 (RD5/TD5).
set_property PACKAGE_PIN Y2 [get_ports aurora_rxp]
set_property PACKAGE_PIN Y1 [get_ports aurora_rxn]
set_property PACKAGE_PIN AA4 [get_ports aurora_txp]
set_property PACKAGE_PIN AA3 [get_ports aurora_txn]
