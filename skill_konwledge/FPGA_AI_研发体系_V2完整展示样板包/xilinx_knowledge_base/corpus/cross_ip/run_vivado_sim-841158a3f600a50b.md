# run_vivado_sim

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\scripts\run_vivado_sim.tcl`
- SHA-256: `841158a3f600a50b48926baefdf189beda746a860efc78e526f2c0019b15fd89`
- Extractor: `text`
- Tags: `nvme, pcie, tcl, verification`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\scripts\run_vivado_sim.tcl

```tcl
# 单次系统级行为仿真入口。
# 该脚本创建临时Vivado Project Mode目录，但不生成需要长期维护的板级.xpr。
# 顶层固定为tb_nvme_adc_pipeline；DDR和NVMe均使用rtl/stubs中的行为桩。
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $project_dir build vivado_sim]

# -force保证重复运行时重建同名临时工程；目标器件与计划中的KU040一致。
file mkdir $build_dir
create_project -force nvme_adc_pipeline_sim $build_dir -part xcku040-ffva1156-2-i
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# sources_1加入全部顶层RTL和仿真桩；sim_1只加入本次testbench。
add_files -norecurse [glob [file join $project_dir rtl *.sv]]
add_files -norecurse [glob [file join $project_dir rtl stubs *.sv]]
add_files -fileset sim_1 -norecurse [file join $project_dir sim tb_nvme_adc_pipeline.sv]
set_property top tb_nvme_adc_pipeline [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]

# 先刷新设计/仿真编译顺序，再运行到testbench主动$finish或$fatal。
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation
close_sim
close_project
```
