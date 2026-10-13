set top /tb_byte1_1g
open_vcd byte1_1g.vcd
log_wave -r $top/*
log_vcd [get_objects -r $top/*]
run all
close_vcd
quit
