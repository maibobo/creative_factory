# Configure the current fdma_aurora_brg project for interactive XSim use.
# Optional arguments:
#   testcase seed verbose wave
#
# 示例：
#   source {.../setup_vivado_sim.tcl}
#   source {.../setup_vivado_sim.tcl} tc_brg_tx_fifo_waterline 123456 1 1
#
# 说明：
# - 这个脚本适合 Vivado GUI Tcl Console 调试，不会自动 run all，也不会退出 Vivado。
# - seed 为 6 位十进制；传 0 表示让 testbench 使用默认 seed。
# - verbose: 0=摘要，1=帧/突发计划，2=逐握手。
# - wave: 0=不全量 dump，1=打开 xsim.simulate.log_all_signals。
set script_dir  [file dirname [file normalize [info script]]] ;# regression directory
set loop_root   [file normalize [file join $script_dir ..]]    ;# sources_1 - loop_validate
set source_dir  [file join $loop_root new]                     ;# active RTL/verification root
set tc_dir      [file join $source_dir tc]                     ;# testcase directory
set project_dir [file normalize [file join $loop_root .. ..]]  ;# fdma_aurora_brg project root
set project_xpr [file join $project_dir fdma_aurora_brg.xpr]   ;# project file

# Open the project only when the script was launched outside an existing GUI project.
if {[current_project -quiet] eq ""} {
    open_project $project_xpr
}

# Read the single-name-per-line testcase registry.
set registered_tests {}                                       ;# Legal testcase names.
set list_chan [open [file join $tc_dir tc_list] r]             ;# Open registry for reading.
while {[gets $list_chan line] >= 0} {                          ;# Process every text line.
    regsub {#.*$} $line {} line                               ;# Remove optional comments.
    set line [string trim $line]                               ;# Remove surrounding whitespace.
    if {$line ne ""} { lappend registered_tests $line }        ;# Preserve nonblank names in order.
}
close $list_chan                                               ;# Release the registry file handle.

# Select the requested testcase or the default no-backpressure smoke test.
set testcase [expr {$argc >= 1 ? [lindex $argv 0] : "tc_aurora_loop_nobp"}]
set seed     [expr {$argc >= 2 ? [lindex $argv 1] : "0"}]
set verbose  [expr {$argc >= 3 ? [lindex $argv 2] : "1"}]
set wave     [expr {$argc >= 4 ? [lindex $argv 3] : "0"}]
if {[lsearch -exact $registered_tests $testcase] < 0} {
    error "unknown testcase '$testcase'; inspect [file join $tc_dir tc_list]"
}
if {![regexp {^[0-9]+$} $seed] || ($seed ne "0" && ![regexp {^[0-9]{6}$} $seed])} {
    error "seed must be 0 or six decimal digits in 000001..999999: $seed"
}
if {$seed eq "000000"} { error "seed must not be 000000; use 0 for DEFAULT_SEED" }
if {$verbose ni {0 1 2}} { error "verbose must be 0, 1, or 2" }
if {$wave ni {0 1}} { error "wave must be 0 or 1" }

# Build the complete simulation-source list shared by GUI and batch runs.
set sim_files [list \
    [file join $tc_dir tc_if.sv] \
    [file join $tc_dir tc_base.sv] \
    [file join $source_dir harness aurora_loop_harness.sv] \
    [file join $source_dir harness brg_harness.sv]]
foreach tc_name $registered_tests {                            ;# Add every registered testcase file.
    lappend sim_files [file join $tc_dir ${tc_name}.sv]
}

# Add only missing files so repeated sourcing is harmless.
foreach sim_file $sim_files {
    if {[llength [get_files -quiet -of_objects [get_filesets sim_1] $sim_file]] == 0} {
        add_files -norecurse -fileset sim_1 $sim_file          ;# Register as a simulation source.
    }
}
set sim_objects [get_files -of_objects [get_filesets sim_1] $sim_files] ;# Resolve file objects.
set_property file_type SystemVerilog $sim_objects              ;# Enable class/interface/package syntax.
set_property used_in_synthesis false $sim_objects              ;# Testbench code is simulation-only.
set_property used_in_implementation false $sim_objects         ;# Exclude testbench from implementation.
set_property top ${testcase}_top [get_filesets sim_1]          ;# Select the only elaboration root.
set more_options "-testplusarg SEED=$seed -testplusarg VERBOSE=$verbose"
set_property -dict [list xsim.simulate.xsim.more_options $more_options] [get_filesets sim_1]
set_property xsim.simulate.log_all_signals [expr {$wave ? "true" : "false"}] [get_filesets sim_1]
update_compile_order -fileset sim_1                            ;# Recompute package/type dependencies.
puts "SIM_SETUP_DONE testcase=$testcase top=${testcase}_top seed=$seed verbose=$verbose wave=$wave"
puts "NEXT_STEP: launch_simulation -simset sim_1 -mode behavioral; run all"
