set top /tb_regs_multiblock
open_vcd regs_multiblock.vcd
log_wave -r $top/*
log_vcd [get_objects -r $top/*]
run all
close_vcd
quit
