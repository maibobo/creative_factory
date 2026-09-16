# 快速时序迭代入口：只运行默认 2 burst（32-word）随机背压冒烟。
# 完整模式与 4096-word 回归保留给功能改动或最终签核，不在每轮时序优化中重复执行。

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
set vivado_bin [file join $::env(XILINX_VIVADO) bin]
set sim_work [file join $project_root sim_work_smoke]
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
run_checked [list $xvlog --sv --log xvlog_smoke.log $model_file $tb_file]
run_checked [list $xelab --log xelab_smoke.log --debug typical \
    -top TB_AXI_DDR_FULL_BIST -snapshot tb_smoke]
run_checked [list $xsim tb_smoke --runall --wdb smoke.wdb --log xsim_smoke.log]
puts "SMOKE_ONLY_PASS"
