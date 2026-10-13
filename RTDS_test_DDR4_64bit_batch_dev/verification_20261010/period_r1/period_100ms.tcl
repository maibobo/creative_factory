set top /tb_period_100ms open_vcd period_100ms.vcd
set sigs [get_objects $top/*]
set sigs [lsearch -all -inline -not -exact $sigs $top/clk]
set sigs [concat $sigs [get_objects $top/bus/*]]
set sigs [lsearch -all -inline -not -exact $sigs $top/bus/clk]
log_wave $sigs
log_vcd $sigs
run all
close_vcd
quit
