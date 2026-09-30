# 参考verified 1G design/constraints/aurora_8b10b_1p25g_design.xdc。
# GT通道由对应XCI生成约束；不把独立例程init_clk_in端口约束复制到集成顶层。
set_property LOC AF6 [get_ports aurora1g_refclk_p]
set_property LOC AF5 [get_ports aurora1g_refclk_n]
create_clock -name aurora1g_gt_refclk -period 8.000 [get_ports aurora1g_refclk_p]
# 10G参考时钟位置来自当前10G XCI，与1G的Quad X0Y0参考时钟分离。
set_property LOC T6 [get_ports GTHQ0_P]
set_property LOC T5 [get_ports GTHQ0_N]
create_clock -name aurora10g_gt_refclk -period 6.400 [get_ports GTHQ0_P]
