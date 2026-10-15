# run_vivado_test

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\scripts\run_vivado_test.tcl`
- SHA-256: `85a2eb69e3d3f0f7187d52023a2e52361a7e64aff5baf200bd426bcfd041adac`
- Extractor: `text`
- Tags: `nvme, pcie, tcl, verification`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\scripts\run_vivado_test.tcl

```tcl
# 通用单testbench运行器。
# 调用形式：
#   vivado.bat -mode batch -source run_vivado_test.tcl -tclargs <testbench_top>
# 每个testbench使用独立build/regression/<top>目录，避免并行或重复运行互相覆盖。
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $script_dir ..]]

if {[llength $argv] < 1} {
    error "Usage: vivado -mode batch -source run_vivado_test.tcl -tclargs <testbench_top>"
}

# testbench名称同时决定sim/<top>.sv路径和Vivado仿真顶层。
set test_top [lindex $argv 0]
set test_file [file join $project_dir sim ${test_top}.sv]
if {![file exists $test_file]} {
    error "Testbench not found: $test_file"
}

# 临时工程目标器件固定为XCKU040；该脚本不加载MIG、XDC或供应商IP。
set build_dir [file join $project_dir build regression $test_top]
file mkdir $build_dir
create_project -force ${test_top}_project $build_dir -part xcku040-ffva1156-2-i
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 所有设计RTL和行为Stub共同编译，只把指定testbench放入sim_1。
add_files -norecurse [glob [file join $project_dir rtl *.sv]]
add_files -norecurse [glob [file join $project_dir rtl stubs *.sv]]
add_files -fileset sim_1 -norecurse $test_file
set_property top $test_top [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]

# runtime=all依赖testbench打印TEST_PASS后调用$finish；死锁由各TB超时$fatal终止。
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation
close_sim
close_project
```
