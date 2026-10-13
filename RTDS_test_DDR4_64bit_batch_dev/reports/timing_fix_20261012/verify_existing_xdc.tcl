# 修改记录 2026-10-12：只验证当前已登记XDC实际生效，不执行综合、实现或物理优化。
set root C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev
set out $root/reports/timing_fix_20261012/registered_xdc_verification
file mkdir $out
set_param general.maxThreads 4
open_checkpoint $root/RTDS_test_DDR4_64bit.runs/impl_1/TOP_routed.dcp
read_xdc $root/RTDS_test_DDR4_64bit.srcs/constrs_1/new/DDR4_PIN.xdc
source $root/reports/timing_fix_20261012/verify_loaded_cdc.tcl
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file $out/after_registered_xdc.rpt
puts "REGISTERED_XDC_VERIFIED_NO_IMPLEMENTATION_LAUNCHED"
exit
