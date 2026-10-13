set top /tb_ready_recovery
open_vcd ready_recovery.vcd
log_wave -r $top/*
log_vcd [get_objects -r $top/*]
run all
close_vcd
quit
