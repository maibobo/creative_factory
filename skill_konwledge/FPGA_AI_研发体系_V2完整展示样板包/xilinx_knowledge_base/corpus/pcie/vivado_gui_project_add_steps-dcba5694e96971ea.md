# vivado_gui_project_add_steps

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\vivado_gui_project_add_steps.md`
- SHA-256: `dcba5694e96971ea7501a41795693d087237359ec43419136e79f3dbbb78ee11`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# Vivado GUI 工程添加 integration 文件说明

## 1. 背景说明

上午已经跑通的 integration 仿真是“命令行 file-list XSim 仿真”：

```text
xvlog/xelab/xsim 直接读取 wrapper + CONV_DMA + AXI RAM model + TB
```

这种方式可以验证真实 RTL 连接、数据流和 testbench，但不要求 `.xpr` 工程已经收录这些文件。

本次做的是“Vivado GUI 工程收录”：

```text
把新增设计/仿真文件登记进 fdma_aurora_brg.xpr
```

这样在 Vivado GUI 的 Sources 面板中能看到文件，并且可以直接点击 `Run Behavioral Simulation`。

## 2. 路径变化时需要改哪里

如果工程路径变化，通常只需要改 Tcl 里的前三个路径变量：

```tcl
set project_xpr {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.xpr}
set loop_root   {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate}
set conv_dma    {E:/PCIE-CPU/RTDS_test/RTDS_test.srcs/sources_1/new/CONV_DMA.v}
```

说明：

- 如果 Vivado GUI 已经打开工程，可以不执行 `open_project`，但保留也无妨。
- 如果 `CONV_DMA.v` 后续复制到别的位置，只改 `set conv_dma`。
- 不建议复制 `CONV_DMA.v` 形成两个版本，当前方案是引用现有 PCIe 工程里的文件。

## 3. 推荐 Tcl 添加方式

已保存脚本：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\add_integration_sources_to_project.tcl
```

脚本作用：

- 添加 design source：
  - `fdma_aurora_pcie_conv_dma_wrapper.v`
- 添加 simulation sources：
  - `axi_ram_model.sv`
  - `tb_fdma_aurora_brg_conv_dma_integration.sv`
  - `CONV_DMA.v`
- 设置 `.sv` 文件为 `SystemVerilog`。
- 设置 `sim_1` top 为：
  - `tb_fdma_aurora_brg_conv_dma_integration`
- 启用 XPM 仿真库：
  - `XPM_CDC`
  - `XPM_FIFO`
- 保持 design top 为：
  - `fdma_aurora_brg_aurora_loop_hw`

脚本内容核心如下：

```tcl
set project_xpr {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.xpr}
set loop_root   {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate}
set conv_dma    {E:/PCIE-CPU/RTDS_test/RTDS_test.srcs/sources_1/new/CONV_DMA.v}

proc add_if_missing {fileset_name file_path} {
    if {![file exists $file_path]} {
        error "missing source file: $file_path"
    }
    set fs [get_filesets $fileset_name]
    set existing [get_files -quiet -of_objects $fs [list $file_path]]
    if {[llength $existing] == 0} {
        add_files -norecurse -fileset $fileset_name [list $file_path]
        puts "ADD_FILE fileset=$fileset_name path=$file_path"
    } else {
        puts "KEEP_FILE fileset=$fileset_name path=$file_path"
    }
}

if {[current_project -quiet] eq ""} {
    open_project $project_xpr
}

set design_top [get_property top [get_filesets sources_1]]

set wrapper_file "$loop_root/new/fdma_aurora_pcie_conv_dma_wrapper.v"
set axi_ram_file "$loop_root/new/integration/axi_ram_model.sv"
set tb_file      "$loop_root/new/integration/tb_fdma_aurora_brg_conv_dma_integration.sv"

add_if_missing sources_1 $wrapper_file

set sim_files [list $axi_ram_file $tb_file $conv_dma]
foreach f $sim_files {
    add_if_missing sim_1 $f
}

foreach f [list $axi_ram_file $tb_file] {
    set f_obj [get_files -quiet [list $f]]
    if {[llength $f_obj] == 0} {
        error "file was added but cannot be resolved for file_type: $f"
    }
    set_property file_type SystemVerilog $f_obj
}

set sim_file_objs {}
foreach f $sim_files {
    set f_obj [get_files -quiet -of_objects [get_filesets sim_1] [list $f]]
    if {[llength $f_obj] == 0} {
        error "sim file was added but cannot be resolved: $f"
    }
    foreach obj $f_obj {
        lappend sim_file_objs $obj
    }
}

set_property used_in_synthesis false $sim_file_objs
set_property used_in_implementation false $sim_file_objs

set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]

if {$design_top ne ""} {
    set_property top $design_top [get_filesets sources_1]
}
set_property top tb_fdma_aurora_brg_conv_dma_integration [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
```

注意：

- Vivado 2020.2 中本工程修改在执行 add/update 后已经写入 `.xpr`。
- 脚本末尾没有保留 `save_project`，因为该版本 batch 下会把 `save_project` 解析成需要 `name` 的保存为命令，导致报错。
- 脚本是幂等的：已经添加过的文件会显示 `KEEP_FILE`，不会重复添加。

## 4. Batch 执行命令

最终成功执行的命令：

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  -mode batch `
  -nojournal `
  -nolog `
  -notrace `
  -source "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\add_integration_sources_to_project.tcl"
```

成功输出关键行：

```text
KEEP_FILE fileset=sources_1 path=.../fdma_aurora_pcie_conv_dma_wrapper.v
KEEP_FILE fileset=sim_1 path=.../axi_ram_model.sv
KEEP_FILE fileset=sim_1 path=.../tb_fdma_aurora_brg_conv_dma_integration.sv
KEEP_FILE fileset=sim_1 path=.../CONV_DMA.v
INTEGRATION_SOURCES_ADDED
DESIGN_TOP=fdma_aurora_brg_aurora_loop_hw
SIM_TOP=tb_fdma_aurora_brg_conv_dma_integration
```

首次添加时 `KEEP_FILE` 会显示为 `ADD_FILE`，再次执行会显示 `KEEP_FILE`。

## 5. 实际添加过程用到的命令记录

### 5.1 检查工程中是否已收录新增文件

```powershell
Select-String -Path "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.xpr" `
  -Pattern "fdma_aurora_pcie_conv_dma_wrapper|tb_fdma_aurora_brg_conv_dma_integration|axi_ram_model|CONV_DMA.v|xpm_libraries"
```

作用：

- 检查 `.xpr` 中是否已有 wrapper、integration TB、AXI RAM model、`CONV_DMA.v`、XPM 配置。

### 5.2 检查 4 个待添加源文件是否存在

```powershell
Test-Path "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_pcie_conv_dma_wrapper.v"
Test-Path "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\integration\axi_ram_model.sv"
Test-Path "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\integration\tb_fdma_aurora_brg_conv_dma_integration.sv"
Test-Path "E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\CONV_DMA.v"
```

结果：

```text
True
True
True
True
```

### 5.3 检查 Vivado batch 工具是否存在

```powershell
Test-Path "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat"
```

结果：

```text
True
```

### 5.4 第一次 batch 执行

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  -mode batch `
  -source "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\add_integration_sources_to_project.tcl"
```

遇到的问题：

```text
ERROR: [Vivado 12-172] File or Directory 'E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1' does not exist
```

原因：

- Tcl 中 `add_files/get_files` 没有用 `[list $file_path]` 包住路径。
- 路径 `sources_1 - loop_validate` 中有空格，被 Vivado Tcl 拆成了多段。

修复：

```tcl
add_files -norecurse -fileset $fileset_name [list $file_path]
get_files -quiet -of_objects $fs [list $file_path]
```

### 5.5 第二次 batch 执行

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  -mode batch `
  -source "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\add_integration_sources_to_project.tcl"
```

输出显示文件已添加：

```text
ADD_FILE fileset=sources_1 path=.../fdma_aurora_pcie_conv_dma_wrapper.v
ADD_FILE fileset=sim_1 path=.../axi_ram_model.sv
ADD_FILE fileset=sim_1 path=.../tb_fdma_aurora_brg_conv_dma_integration.sv
ADD_FILE fileset=sim_1 path=.../CONV_DMA.v
```

随后遇到问题：

```text
WARNING: [Vivado 12-818] No files matched 'E:/PCIE-CPU/.../sources_1'
ERROR: [Common 17-55] 'set_property' expects at least one object.
```

原因：

- 后续 `set_property file_type SystemVerilog [get_files $f]` 仍然没用 list 包路径。

修复：

```tcl
set f_obj [get_files -quiet [list $f]]
set_property file_type SystemVerilog $f_obj
```

并且 simulation file object 也统一改为：

```tcl
set f_obj [get_files -quiet -of_objects [get_filesets sim_1] [list $f]]
```

### 5.6 第三次 batch 执行

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  -mode batch `
  -source "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\add_integration_sources_to_project.tcl"
```

输出显示工程已能识别这些文件：

```text
KEEP_FILE fileset=sources_1 path=.../fdma_aurora_pcie_conv_dma_wrapper.v
KEEP_FILE fileset=sim_1 path=.../axi_ram_model.sv
KEEP_FILE fileset=sim_1 path=.../tb_fdma_aurora_brg_conv_dma_integration.sv
KEEP_FILE fileset=sim_1 path=.../CONV_DMA.v
```

随后遇到问题：

```text
ERROR: [Common 17-163] Missing value for option 'name', please type 'save_project_as -help'
```

原因：

- Vivado 2020.2 batch 下 `save_project` 在该上下文中被解析成需要 `name` 的保存为操作。
- 但检查 `.xpr` 发现工程已经写入新增文件和属性。

修复：

- 从脚本末尾移除 `save_project`。
- 保留 `update_compile_order`。

### 5.7 最终成功 batch 执行

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  -mode batch `
  -nojournal `
  -nolog `
  -notrace `
  -source "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\add_integration_sources_to_project.tcl"
```

成功输出：

```text
INTEGRATION_SOURCES_ADDED
DESIGN_TOP=fdma_aurora_brg_aurora_loop_hw
SIM_TOP=tb_fdma_aurora_brg_conv_dma_integration
```

返回码：

```text
0
```

### 5.8 最终检查 `.xpr`

```powershell
Select-String -Path "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.xpr" `
  -Pattern "fdma_aurora_pcie_conv_dma_wrapper|tb_fdma_aurora_brg_conv_dma_integration|axi_ram_model|CONV_DMA.v|XPMLibraries|TopModule"
```

确认结果：

```text
XPMLibraries = XPM_CDC
XPMLibraries = XPM_FIFO
fdma_aurora_pcie_conv_dma_wrapper.v 已在 sources_1
CONV_DMA.v 已在 sim_1
axi_ram_model.sv 已在 sim_1
tb_fdma_aurora_brg_conv_dma_integration.sv 已在 sim_1
sources_1 TopModule = fdma_aurora_brg_aurora_loop_hw
sim_1 TopModule = tb_fdma_aurora_brg_conv_dma_integration
```

### 5.9 检查 `.xpr` 修改时间

```powershell
Get-Item "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.xpr" |
  Select-Object FullName,Length,LastWriteTime
```

确认 `.xpr` 已更新。

## 6. GUI 手动添加方法

如果不用 Tcl，也可以在 Vivado GUI 中手动添加。

### 6.1 添加 design source

1. 打开：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.xpr
```

2. 点击 `Add Sources`。
3. 选择 `Add or Create Design Sources`。
4. 添加：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_pcie_conv_dma_wrapper.v
```

5. 确认加入到 `sources_1`。

### 6.2 添加 simulation sources

1. 点击 `Add Sources`。
2. 选择 `Add or Create Simulation Sources`。
3. 添加：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\integration\axi_ram_model.sv
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\integration\tb_fdma_aurora_brg_conv_dma_integration.sv
E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\CONV_DMA.v
```

4. 确认加入到 `sim_1`。
5. 确认两个 `.sv` 文件类型为 `SystemVerilog`。

### 6.3 设置仿真顶层

1. 打开 `Flow Navigator -> Simulation Settings`。
2. 找到 simulation top。
3. 设置为：

```text
tb_fdma_aurora_brg_conv_dma_integration
```

或者在 Tcl Console 执行：

```tcl
set_property top tb_fdma_aurora_brg_conv_dma_integration [get_filesets sim_1]
```

### 6.4 设置 XPM 库

在 Tcl Console 执行：

```tcl
set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]
```

### 6.5 更新编译顺序

GUI：

```text
右键 Sources -> Update Compile Order
```

Tcl：

```tcl
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
```

## 7. GUI 里运行仿真

1. 打开工程：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.xpr
```

2. 确认 `Simulation Sources` 中有：

```text
axi_ram_model.sv
tb_fdma_aurora_brg_conv_dma_integration.sv
CONV_DMA.v
```

3. 确认 simulation top：

```text
tb_fdma_aurora_brg_conv_dma_integration
```

4. 点击：

```text
Run Simulation -> Run Behavioral Simulation
```

5. XSim 打开后执行：

```tcl
run all
```

6. 预期输出：

```text
TEST PASS: fdma_aurora_brg CONV_DMA integration
```

## 8. 当前工程最终状态

当前 `.xpr` 已确认包含：

```text
Design Sources:
  fdma_aurora_pcie_conv_dma_wrapper.v

Simulation Sources:
  CONV_DMA.v
  axi_ram_model.sv
  tb_fdma_aurora_brg_conv_dma_integration.sv

Project XPM Libraries:
  XPM_CDC
  XPM_FIFO

Design Top:
  fdma_aurora_brg_aurora_loop_hw

Simulation Top:
  tb_fdma_aurora_brg_conv_dma_integration
```
