# XSim GUI入口：仿真前递归记录并显示指定测试顶层的全部可追踪信号。
if {![info exists ::env(RTDS_WAVE_TOP)]} {
    error "缺少环境变量RTDS_WAVE_TOP"
}
set top_scope /$::env(RTDS_WAVE_TOP)
if {[string length [current_wave_config]] == 0} {
    create_wave_config
}
log_wave -r ${top_scope}/*
add_wave -r ${top_scope}/*
run all
puts "RTDS_FULL_WAVE_READY=$top_scope"
