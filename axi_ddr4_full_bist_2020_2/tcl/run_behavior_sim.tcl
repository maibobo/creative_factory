# XSim behavior regression driver. It keeps generated simulator products under sim_work.

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set vivado_bin [file join $::env(XILINX_VIVADO) bin]
set sim_work [file join $project_root sim_work]
file mkdir $sim_work
cd $sim_work

set xvlog [file join $vivado_bin xvlog.bat]
set xelab [file join $vivado_bin xelab.bat]
set xsim [file join $vivado_bin xsim.bat]
set rtl_file [file join $project_root rtl axi_ddr_full_bist.v]
set model_file [file join $project_root sim axi4_ram_model.sv]
set tb_file [file join $project_root sim tb_axi_ddr_full_bist.sv]

proc run_checked {command_words} {
    puts "RUN [join $command_words { }]"
    if {[catch {exec {*}$command_words 2>@1} command_output]} {
        puts $command_output
        error "Command failed: [join $command_words { }]"
    }
    puts $command_output
}

run_checked [list $xvlog --log xvlog_rtl.log $rtl_file]
run_checked [list $xvlog --sv --log xvlog_smoke32.log -d TB_EXTENDED $model_file $tb_file]
run_checked [list $xelab --log xelab_smoke32.log --debug typical \
    -top TB_AXI_DDR_FULL_BIST -snapshot tb_smoke32]
run_checked [list $xsim tb_smoke32 --runall --wdb smoke32.wdb --log xsim_smoke32.log]

run_checked [list $xvlog --sv --log xvlog_smoke4096.log -d TB_SMOKE_4096 $model_file $tb_file]
run_checked [list $xelab --log xelab_smoke4096.log --debug typical \
    -top TB_AXI_DDR_FULL_BIST -snapshot tb_smoke4096]
run_checked [list $xsim tb_smoke4096 --runall --wdb smoke4096.wdb --log xsim_smoke4096.log]

puts "BEHAVIOR_REGRESSION_PASS"
