# 报告证据记录入口：在仿真开始前递归记录测试顶层全部可追踪信号。
foreach required {RTDS_WAVE_TOP RTDS_VCD_PATH RTDS_WCFG_PATH} {
    if {![info exists ::env($required)]} {
        error "missing environment variable $required"
    }
}

set top_scope /$::env(RTDS_WAVE_TOP)
if {[string length [current_wave_config]] == 0} {
    create_wave_config
}
log_wave -r ${top_scope}/*
add_wave -r ${top_scope}/*
open_vcd $::env(RTDS_VCD_PATH)
log_vcd [get_objects -r ${top_scope}/*]
run all
close_vcd
catch {file delete -force $::env(RTDS_WCFG_PATH)}
if {[catch {save_wave_config $::env(RTDS_WCFG_PATH)} save_error]} {
    puts "RTDS_EVIDENCE_WCFG_WARNING=$save_error"
}
puts "RTDS_EVIDENCE_RECORDED=$top_scope"
exit
