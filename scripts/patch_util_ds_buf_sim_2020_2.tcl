# 使用当前BD实体，不再从历史兼容备份恢复旧版实体。
# 与生成包装层一起检查四个曾缺失端口；重复执行仅同步相同内容。
set root [file normalize [file join [file dirname [info script]] ..]]
set relative [file join bd design_1 ip design_1_util_ds_buf_0]
set src [file join $root RTDS_test_DDR4_64bit.srcs sources_1 $relative util_ds_buf.vhd]
set dst [file join $root RTDS_test_DDR4_64bit.ip_user_files $relative util_ds_buf.vhd]
set wrapper [file join $root RTDS_test_DDR4_64bit.ip_user_files $relative sim design_1_util_ds_buf_0.vhd]
foreach f [list $src $dst $wrapper] {if {![file exists $f]} {error "Required generated file missing: $f"}}
set h [open $src r];set entity [read $h];close $h
set h [open $wrapper r];set wrapper_text [read $h];close $h
foreach port {BUFG_PS_I BUFG_PS_O OBUFDS_GTE5_ADV_RXRECCLKSEL OBUFDS_GTME5_ADV_RXRECCLKSEL} {
 if {![regexp -nocase "\\m${port}\\M" $entity] || ![regexp -nocase "\\m${port}\\M" $wrapper_text]} {error "util_ds_buf source/wrapper version mismatch at $port"}
}
set h [open $dst r];set previous [read $h];close $h
if {$entity ne $previous} {
 set backup [file join $root reports util_ds_buf_before_current_[clock seconds].vhd]
 file copy $dst $backup
 file copy -force $src $dst
 puts "UTIL_DS_BUF_CURRENT_ENTITY_COPIED; preserved=$backup"
} else {puts "UTIL_DS_BUF_CURRENT_ENTITY_ALREADY_MATCHED"}
