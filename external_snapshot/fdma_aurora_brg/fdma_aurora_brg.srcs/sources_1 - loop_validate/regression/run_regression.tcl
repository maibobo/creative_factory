# Run one registered testcase under Vivado/XSim.
# Arguments:
#   testcase six_digit_decimal_seed wave(0|1) verbose(0..2) log_dir ?project_xpr? ?loop_root? ?output_stem? ?vcd_mode? ?vcd_signal_file? ?vcd_start? ?vcd_stop? ?dump_hierarchy?
#
# 说明：
# - 前 5 个参数保持旧脚本兼容。
# - project_xpr/loop_root 用于 Python 并行回归给每个 job 指向独立工程副本。
# - output_stem 用于 retry attempt 日志区分；未传时保持旧的 testcase_seed 命名。
# - vcd_mode=none|selected；selected 只导出 vcd_signal_file 里匹配到的信号。
# - vcd_start/vcd_stop 可选。为空表示 selected VCD 覆盖完整仿真。
if {$argc < 5} {
    error "usage: run_regression.tcl <testcase> <seed_dec> <wave> <verbose> <log_dir> ?project_xpr? ?loop_root? ?output_stem? ?vcd_mode? ?vcd_signal_file? ?vcd_start? ?vcd_stop? ?dump_hierarchy?>"
}
puts "REGRESSION_SCRIPT path=[file normalize [info script]] revision=selected_vcd_v1"
set testcase [lindex $argv 0]
set seed_dec [lindex $argv 1]
set wave      [lindex $argv 2]
set verbose   [lindex $argv 3]
set log_dir   [file normalize [lindex $argv 4]]
if {$argc >= 8} {
    set output_stem [file tail [lindex $argv 7]]
} else {
    set output_stem ${testcase}_${seed_dec}
}
set vcd_mode [expr {$argc >= 9 ? [lindex $argv 8] : "none"}]
set vcd_signal_file [expr {$argc >= 10 ? [lindex $argv 9] : ""}]
set vcd_start [expr {$argc >= 11 ? [lindex $argv 10] : ""}]
set vcd_stop [expr {$argc >= 12 ? [lindex $argv 11] : ""}]
set dump_hierarchy [expr {$argc >= 13 ? [lindex $argv 12] : "0"}]

proc collect_wdb_files {root start_time} {
    set result {}
    if {![file isdirectory $root]} {
        return $result
    }
    foreach item [glob -nocomplain -directory $root *] {
        if {[file isdirectory $item]} {
            set nested [collect_wdb_files $item $start_time]
            foreach n $nested { lappend result $n }
        } elseif {[string match -nocase *.wdb [file tail $item]]} {
            if {[file mtime $item] >= $start_time} {
                lappend result $item
            }
        }
    }
    return $result
}

proc select_latest_nonempty_wdb {files} {
    set best {}
    set best_time -1
    foreach f $files {
        set size [file size $f]
        set mtime [file mtime $f]
        puts "WAVE_CANDIDATE path=$f size=$size mtime=$mtime"
        if {$size > 0 && $mtime >= $best_time} {
            set best $f
            set best_time $mtime
        }
    }
    return $best
}

proc normalize_vcd_time {value} {
    set value [string trim $value]
    regsub -all {\s+} $value {} value
    return $value
}

proc vcd_run_duration {start_time stop_time} {
    if {$stop_time eq ""} {
        return ""
    }
    if {$start_time eq ""} {
        set start_time "0"
    }
    if {[regexp {^([0-9]+)([a-zA-Z]+)$} $start_time -> start_num start_unit] &&
        [regexp {^([0-9]+)([a-zA-Z]+)$} $stop_time -> stop_num stop_unit] &&
        $start_unit eq $stop_unit} {
        set duration_num [expr {$stop_num - $start_num}]
        if {$duration_num <= 0} {
            error "vcd_stop must be greater than vcd_start: start=$start_time stop=$stop_time"
        }
        return ${duration_num}${start_unit}
    }
    return $stop_time
}

proc active_signal_patterns {signal_file} {
    set patterns {}
    set chan [open $signal_file r]
    while {[gets $chan line] >= 0} {
        regsub {#.*$} $line {} line
        set line [string trim $line]
        if {$line ne ""} {
            lappend patterns $line
        }
    }
    close $chan
    return $patterns
}

proc hierarchy_objects {pattern recursive} {
    if {$recursive} {
        return [get_objects -quiet -r $pattern]
    }
    return [get_objects -quiet $pattern]
}

proc write_hierarchy_report {top_name output_path} {
    set top_path /$top_name
    set lines {}
    lappend lines "TOP      = $top_path"

    set candidates [list \
        [list HARNESS ${top_path}/h] \
        [list DUT     ${top_path}/h/dut] \
        [list TX      ${top_path}/h/dut/u_fdma_aurora_brg_tx] \
        [list RX      ${top_path}/h/dut/u_fdma_aurora_brg_rx] \
        [list LOOP    ${top_path}/h/dut/u_fdma_aurora_brg_top]]
    foreach item $candidates {
        set label [lindex $item 0]
        set path [lindex $item 1]
        set objects [get_objects -quiet $path]
        if {[llength $objects] > 0} {
            lappend lines [format "%-8s = %s" $label $path]
        } else {
            lappend lines [format "%-8s = MISSING %s" $label $path]
        }
    }

    lappend lines ""
    lappend lines "TOP_CHILDREN"
    foreach child [get_objects -quiet ${top_path}/*] {
        lappend lines "  $child"
    }

    set chan [open $output_path w]
    foreach line $lines {
        puts $chan $line
        puts "HIERARCHY $line"
    }
    close $chan
    puts "HIERARCHY_REPORT=$output_path"
}

proc xsim_log_selected_vcd {signal_file vcd_path check_path} {
    set signal_count 0
    set missing_count 0
    set check_lines {}
    open_vcd $vcd_path

    foreach raw_pattern [active_signal_patterns $signal_file] {
        set recursive 0
        if {[regexp {^-recursive\s+(.+)$} $raw_pattern -> pattern]} {
            set recursive 1
            set pattern [string trim $pattern]
        } else {
            set pattern $raw_pattern
        }

        set objects [hierarchy_objects $pattern $recursive]
        if {[llength $objects] == 0} {
            incr missing_count
            set line "FAIL pattern=$pattern recursive=$recursive matched=0"
            lappend check_lines $line
            puts "SELECTED_VCD_WARN $line"
            continue
        }

        if {$recursive} {
            log_vcd -r $objects
        } else {
            log_vcd $objects
        }
        incr signal_count [llength $objects]
        set line "OK pattern=$pattern recursive=$recursive matched=[llength $objects]"
        lappend check_lines $line
        puts "SELECTED_VCD_LOGGED $line"
    }

    set chan [open $check_path w]
    foreach line $check_lines { puts $chan $line }
    close $chan

    if {$signal_count == 0} {
        close_vcd
        error "selected VCD signal file matched zero objects: $signal_file"
    }
    puts "SELECTED_VCD_READY file=$vcd_path matched_objects=$signal_count missing_patterns=$missing_count check=$check_path"
}

if {![regexp {^[0-9]{6}$} $seed_dec] || $seed_dec eq "000000"} {
    error "seed must be six decimal digits in 000001..999999: $seed_dec"
}
if {$wave ni {0 1}} { error "wave must be 0 or 1" }
if {$verbose ni {0 1 2}} { error "verbose must be 0, 1, or 2" }
if {$vcd_mode ni {none selected}} { error "vcd_mode must be none or selected" }
if {$vcd_mode eq "selected" && $vcd_signal_file eq ""} { error "vcd_mode=selected requires vcd_signal_file" }
if {$vcd_signal_file ne ""} { set vcd_signal_file [file normalize $vcd_signal_file] }
if {$vcd_mode eq "selected" && ![file exists $vcd_signal_file]} { error "selected VCD signal file not found: $vcd_signal_file" }

file mkdir $log_dir
set script_dir  [file dirname [file normalize [info script]]]
if {$argc >= 7} {
    set loop_root [file normalize [lindex $argv 6]]
} else {
    set loop_root [file normalize [file join $script_dir ..]]
}
set source_dir  [file join $loop_root new]
set tc_dir      [file join $source_dir tc]
if {$argc >= 6} {
    set project_xpr [file normalize [lindex $argv 5]]
    set project_dir [file dirname $project_xpr]
} else {
    set project_dir [file normalize [file join $loop_root .. ..]]
    set project_xpr [file join $project_dir fdma_aurora_brg.xpr]
}
set project_name [file rootname [file tail $project_xpr]]
set tc_list     [file join $tc_dir tc_list]

if {![file exists $tc_list]} { error "testcase registry not found: $tc_list" }

# Load the legal testcase registry. Each nonblank line contains one name.
set registered_tests {}
set list_chan [open $tc_list r]
while {[gets $list_chan line] >= 0} {
    regsub {#.*$} $line {} line
    set line [string trim $line]
    if {$line ne ""} { lappend registered_tests $line }
}
close $list_chan
if {[lsearch -exact $registered_tests $testcase] < 0} {
    error "testcase is not registered in tc_list: $testcase"
}
set testcase_file [file join $tc_dir ${testcase}.sv]
if {![file exists $testcase_file]} { error "testcase source not found: $testcase_file" }
if {![file exists $project_xpr]} { error "Vivado project not found: $project_xpr" }

open_project $project_xpr

# Batch runs only need common verification files plus the selected testcase.
# Other registered testcase files are disabled if they already exist in sim_1,
# which keeps XSim command lines shorter as the testcase list grows.
set sim_files [list \
    [file join $tc_dir tc_if.sv] \
    [file join $tc_dir tc_base.sv] \
    [file join $source_dir harness aurora_loop_harness.sv] \
    [file join $source_dir harness brg_harness.sv] \
    $testcase_file]

set sim_objects {}
set disabled_tc_objects {}
foreach sim_file $sim_files {
    set wanted [file normalize $sim_file]
    set found {}
    foreach candidate [get_files -quiet -of_objects [get_filesets sim_1]] {
        if {[file normalize [get_property NAME $candidate]] eq $wanted} {
            set found $candidate
            break
        }
    }
    if {$found eq {}} {
        set found [add_files -norecurse -fileset sim_1 $sim_file]
    }
    lappend sim_objects $found
}

foreach tc_name $registered_tests {
    if {$tc_name eq $testcase} { continue }
    set other_file [file normalize [file join $tc_dir ${tc_name}.sv]]
    foreach candidate [get_files -quiet -of_objects [get_filesets sim_1]] {
        if {[file normalize [get_property NAME $candidate]] eq $other_file} {
            lappend disabled_tc_objects $candidate
            break
        }
    }
}

set_property file_type SystemVerilog $sim_objects
set_property used_in_synthesis false $sim_objects
set_property used_in_implementation false $sim_objects
set_property used_in_simulation true $sim_objects
if {[llength $disabled_tc_objects] > 0} {
    set_property used_in_simulation false $disabled_tc_objects
}

set top_name ${testcase}_top
set_property top $top_name [get_filesets sim_1]
set_property -dict [list xsim.simulate.xsim.more_options \
    "-testplusarg SEED=$seed_dec -testplusarg VERBOSE=$verbose"] [get_filesets sim_1]
set_property xsim.simulate.log_all_signals [expr {$wave ? "true" : "false"}] [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "REGRESSION_START testcase=$testcase seed=$seed_dec wave=$wave verbose=$verbose top=$top_name project=$project_xpr loop_root=$loop_root output_stem=$output_stem vcd_mode=$vcd_mode vcd_signal_file=$vcd_signal_file vcd_start=$vcd_start vcd_stop=$vcd_stop dump_hierarchy=$dump_hierarchy"
set sim_dir [file join $project_dir ${project_name}.sim sim_1 behav xsim]
set sim_log [file join $sim_dir simulate.log]
set copied_log [file join $log_dir ${output_stem}_simulate.log]
set wave_target [file join $log_dir ${output_stem}_behav.wdb]
set hierarchy_report [file join $log_dir ${output_stem}_hierarchy.txt]
set signal_check_report [file join $log_dir ${output_stem}_signal_check.txt]
set selected_vcd [file join $log_dir ${output_stem}_selected.vcd]
set wave_status "NOT_REQUESTED"
set wave_error ""
set wave_source ""

puts "WAVE_REQUEST wave=$wave"
puts "WAVE_CONFIG log_all_signals=[get_property xsim.simulate.log_all_signals [get_filesets sim_1]]"
puts "WAVE_EXPECTED_TARGET=$wave_target"
puts "SELECTED_VCD_TARGET=$selected_vcd"
puts "WAVE_SEARCH_ROOT=$project_dir"
puts "SIM_WORK_DIR=$sim_dir"
puts "PWD=[pwd]"

if {[file exists $sim_log]} { file delete -force $sim_log }
if {[file exists $selected_vcd]} { file delete -force $selected_vcd }
if {[file exists $signal_check_report]} { file delete -force $signal_check_report }
if {[file exists $hierarchy_report]} { file delete -force $hierarchy_report }
# Remove prior generated databases so a wave-enabled run can never copy stale data.
if {[file isdirectory $sim_dir]} {
    foreach old_wdb [glob -nocomplain -directory $sim_dir *.wdb] {
        file delete -force $old_wdb
    }
}
set sim_start_time [clock seconds]
launch_simulation -simset sim_1 -mode behavioral
if {$dump_hierarchy eq "1" || $vcd_mode eq "selected"} {
    write_hierarchy_report $top_name $hierarchy_report
}
if {$wave == 1} {
    set log_wave_failed [catch {log_wave -recursive /*} log_wave_message]
    if {$log_wave_failed} {
        set wave_status "COPY_FAILED"
        set wave_error "log_wave failed: $log_wave_message"
        puts "WAVE_LOG_CMD=FAIL message=$log_wave_message"
        puts stderr "WAVE_LOG_CMD=FAIL message=$log_wave_message"
    } else {
        puts "WAVE_LOG_CMD=PASS command={log_wave -recursive /*}"
    }
}
set run_failed 0
set run_message ""
if {$vcd_mode eq "selected"} {
    set start_time [normalize_vcd_time $vcd_start]
    set stop_time [normalize_vcd_time $vcd_stop]
    if {$start_time ne "" && $start_time ne "0" && $start_time ne "0ns"} {
        puts "SELECTED_VCD_PRERUN until=$start_time"
        if {[catch {run $start_time} run_message]} { set run_failed 1 }
    }
    if {!$run_failed} {
        if {[catch {xsim_log_selected_vcd $vcd_signal_file $selected_vcd $signal_check_report} run_message]} {
            set run_failed 1
        }
    }
    if {!$run_failed} {
        set duration [vcd_run_duration $start_time $stop_time]
        if {$duration ne ""} {
            puts "SELECTED_VCD_WINDOW start=$start_time stop=$stop_time run_duration=$duration"
            if {[catch {run $duration} run_message]} { set run_failed 1 }
            catch {close_vcd}
            if {!$run_failed} {
                if {[catch {run all} run_message]} { set run_failed 1 }
            }
        } else {
            puts "SELECTED_VCD_FULL_RUN file=$selected_vcd"
            if {[catch {run all} run_message]} { set run_failed 1 }
            catch {close_vcd}
        }
    }
} else {
    set run_failed [catch {run all} run_message]
}
close_sim

if {![file exists $sim_log]} { error "simulation log was not generated: $sim_log" }
file copy -force $sim_log $copied_log
set in_chan [open $sim_log r]
set sim_text [read $in_chan]
close $in_chan

if {$wave == 1} {
    set wdb_files [collect_wdb_files $project_dir $sim_start_time]
    set selected_wdb [select_latest_nonempty_wdb $wdb_files]
    if {$selected_wdb eq ""} {
        set wave_status "MISSING"
        set wave_error "no nonempty WDB found"
        puts "WAVE_RESULT=FAIL"
        puts "WAVE_MISSING testcase=$testcase seed=$seed_dec"
        puts "WAVE_SEARCH_ROOT=$project_dir"
        puts "WAVE_EXPECTED_TARGET=$wave_target"
        puts "WAVE_HINT=inspect Vivado log and retained work project"
        puts stderr "WAVE_RESULT=FAIL"
        puts stderr "WAVE_MISSING testcase=$testcase seed=$seed_dec"
    } else {
        set wave_source $selected_wdb
        puts "WAVE_COPY source=$wave_source target=$wave_target"
        set copy_failed [catch {file copy -force $wave_source $wave_target} copy_message]
        if {$copy_failed} {
            set wave_status "COPY_FAILED"
            set wave_error $copy_message
            puts "WAVE_RESULT=FAIL"
            puts "WAVE_COPY_FAILED testcase=$testcase seed=$seed_dec message=$copy_message"
            puts stderr "WAVE_RESULT=FAIL"
            puts stderr "WAVE_COPY_FAILED testcase=$testcase seed=$seed_dec message=$copy_message"
        } elseif {![file exists $wave_target] || ![file isfile $wave_target] || [file size $wave_target] <= 0} {
            set wave_status "EMPTY"
            set wave_error "copied WDB missing or empty"
            puts "WAVE_RESULT=FAIL"
            puts "WAVE_COPY_FAILED testcase=$testcase seed=$seed_dec message=$wave_error"
            puts stderr "WAVE_RESULT=FAIL"
            puts stderr "WAVE_COPY_FAILED testcase=$testcase seed=$seed_dec message=$wave_error"
        } else {
            set wave_status "GENERATED"
            puts "WAVE_RESULT=PASS target=$wave_target size=[file size $wave_target]"
        }
    }
}
if {$vcd_mode eq "selected"} {
    if {![file exists $selected_vcd] || ![file isfile $selected_vcd] || [file size $selected_vcd] <= 0} {
        puts "SELECTED_VCD_RESULT=FAIL target=$selected_vcd"
        puts stderr "SELECTED_VCD_RESULT=FAIL target=$selected_vcd"
    } else {
        puts "SELECTED_VCD_RESULT=PASS target=$selected_vcd size=[file size $selected_vcd]"
    }
}
if {$run_failed} { error "simulation command failed: $run_message; inspect $copied_log" }
if {![string match "*TEST_PASS: $testcase*" $sim_text]} {
    error "testcase failed or did not complete; inspect $copied_log"
}
puts "REGRESSION_PASS testcase=$testcase seed=$seed_dec log=$copied_log"
if {$wave == 1 && $wave_status ne "GENERATED"} {
    puts "REGRESSION_ARTIFACT_FAIL testcase=$testcase seed=$seed_dec wave=1 wave_status=$wave_status expected=$wave_target source=$wave_source error=$wave_error"
    close_project
    exit 3
}
close_project
exit 0
