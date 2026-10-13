set top /tb_tx_boundaries
open_vcd tx_boundaries.vcd
log_wave -r $top/*
log_vcd -r $top/*
run all
close_vcd
quit
