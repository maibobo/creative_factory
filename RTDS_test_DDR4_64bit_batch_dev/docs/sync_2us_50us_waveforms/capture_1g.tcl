set out {C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev/docs/sync_2us_50us_waveforms/one_g.vcd}
open_vcd $out
log_vcd -level 0 [get_objects /tb_rtds_1g/*]
run all
flush_vcd
close_vcd
quit
