# run_vivado_synth

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\scripts\run_vivado_synth.tcl`
- SHA-256: `c10f15e4628d45c544fb1bcfb3285fb2b1ed602bd17f834fba34d8615449dea8`
- Extractor: `text`
- Tags: `nvme, pcie, tcl, verification`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\scripts\run_vivado_synth.tcl

```tcl
# RTL顶层的Out-of-Context综合入口。
# OOC只检查RTL可综合性、资源估算和无板级I/O环境下的时序；没有MIG/XDC，
# 因此生成的timing_ooc.rpt不能作为最终板级收敛或接口时序结论。
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $project_dir build vivado_synth]

# 创建目标为XCKU040-FFVA1156-2-I的临时综合工程。
file mkdir $build_dir
create_project -force nvme_adc_pipeline_synth $build_dir -part xcku040-ffva1156-2-i
set_property target_language Verilog [current_project]

# 只加入rtl根目录；不加入rtl/stubs和sim，避免行为模型进入综合。
add_files -norecurse [glob [file join $project_dir rtl *.sv]]
set_property top nvme_adc_pipeline_top [get_filesets sources_1]
update_compile_order -fileset sources_1

# out_of_context模式不做顶层I/O Buffer插入，也不执行实现/place/route。
synth_design -top nvme_adc_pipeline_top -part xcku040-ffva1156-2-i \
    -mode out_of_context
# 三个输出分别保存资源、时序摘要和综合后网表检查点。
report_utilization -file [file join $build_dir utilization_ooc.rpt]
report_timing_summary -file [file join $build_dir timing_ooc.rpt]
write_checkpoint -force [file join $build_dir nvme_adc_pipeline_ooc.dcp]
close_project
```
