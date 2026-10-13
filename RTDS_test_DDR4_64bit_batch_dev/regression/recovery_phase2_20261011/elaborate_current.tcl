# 2026-10-11：在当前工程只读上下文做RTL展开，不启动综合、实现或bitstream。
set root [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
file mkdir $out
open_project -read_only [file join $root RTDS_test_DDR4_64bit.xpr]
set result [open [file join $out rtl_elaboration_results.txt] w]
foreach top {rtds_ddr4_backend TOP} {
    set rc [catch {synth_design -rtl -top $top -part xcku040-ffva1156-2-i -verilog_define DDR4_REAL} msg]
    puts $result "$top rc=$rc message=$msg"
    flush $result
    if {$rc == 0} {
        puts "PHASE2_RTL_ELABORATE_PASS top=$top"
        catch {report_cdc -details -file [file join $out ${top}_cdc.rpt]}
        close_design
    } else {
        puts "PHASE2_RTL_ELABORATE_FAIL top=$top message=$msg"
        catch {close_design}
    }
}
close $result
close_project
