# RTDS_test_XDMA_RootPort另一台电脑运行与回归步骤

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort另一台电脑运行与回归步骤.md`
- SHA-256: `c7552963494fd3635750e0df9cb430e33fcecfd51d5825744ac7b93bc1add966`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test-1ch XDMA Root Port 在另一台电脑运行与回归步骤

## 1. 目的和固定版本

本说明用于把已经搭建好的 `RTDS_test-1ch/regression/sim_xdma_rootport` 带到另一台性能更好的 Windows 电脑，完成 Vivado 2020.2 的 clean 编译、XSim elaboration、`rtds_minimum` 运行和日志回归。

必须使用：

```text
D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat
```

配套命令会使用同目录的 `xvlog.bat`、`xvhdl.bat`、`xelab.bat` 和 `xsim.bat`。不要混用 2020.1、2021.x 或 PATH 中的其他 Vivado。

建议机器至少 16 GB 内存、8 个逻辑处理器和本地 SSD。当前 4 线程/8 GB 电脑曾在 `xelab --mt auto` 的 native module 编译阶段触发 `XSIM 43-3294 EXCEPTION_ACCESS_VIOLATION`，Windows 退出码为 `0xC0000374`；这属于 XSim 2020.2 主机端堆损坏，不是 RTL 语法错误。

## 2. 迁移前准备

复制整个 `PCIE-CPU` 目录，至少必须包含：

```text
PCIE-CPU/
├─ RTDS_test-1ch/
│  ├─ RTDS_test.xpr
│  ├─ RTDS_test.srcs/
│  ├─ RTDS_test.gen/
│  ├─ RTDS_test.ip_user_files/
│  └─ regression/sim_xdma_rootport/
└─ docs/
```

`sim_xdma_rootport/vendor/xdma_rp_2020_2` 已经隔离了运行所需的官方 Root Port/TPI 文件，所以另一台电脑运行时不需要从 `xdma_0_ex` 再复制依赖。为便于审计，仍建议把整个工作区一起带走。

以下内容不能当作跨电脑的可靠缓存：

- `work/export/xsim/xsim.dir` snapshot。
- `.Xil`、Vivado 临时目录和本机绝对路径导出的 `vlog.prj/vhdl.prj`。
- 其他 Vivado 版本生成的 IP target。

第一次在新电脑运行必须重新 audit、prepare、compile 和 elaborate。脚本会在自身 `work/export` 范围内重新导出，不需要手工删除工程目录。

如果新电脑的工作区不是 `E:\PCIE-CPU`，Tcl 脚本仍会按自身位置推导工程路径；必须在新电脑重新执行 prepare，不能使用原电脑导出的绝对路径 `.prj` 文件。Vivado 安装路径若不同，通过 `-VivadoBin` 传入对方 `bin` 目录，不需要改脚本源码。

### 2.1 远程 SSH 主机提供 PowerShell 信息

远方人员先使用将要运行 Vivado 的同一 Windows 账号执行以下命令，把原始输出回传：

```powershell
whoami
$PSVersionTable.PSVersion
Get-Command powershell.exe -All | Select-Object Source, Version
Get-Command pwsh.exe -All -ErrorAction SilentlyContinue |
  Select-Object Source, Version
```

如果声称安装了 PowerShell 7，但 `Get-Command pwsh.exe` 没有结果，再执行：

```powershell
Get-ChildItem `
  "C:\Program Files\PowerShell", `
  "C:\Program Files (x86)\PowerShell", `
  "$env:LOCALAPPDATA" `
  -Recurse -Filter pwsh.exe -ErrorAction SilentlyContinue |
  Select-Object FullName, Length, LastWriteTime
```

回传时最关键的是 `pwsh.exe` 绝对路径，以及以下试运行的原始输出：

```powershell
& "<上一步找到的绝对路径\pwsh.exe>" `
  -NoProfile -NonInteractive -Command `
  '$PSVersionTable.PSVersion; [Console]::OutputEncoding'
```

如果 `pwsh.exe` 仅安装在另一个用户的私有目录，SSH 账号可能看不到或不能执行。最稳定的配置是以 all-users 方式安装到：

```text
C:\Program Files\PowerShell\7\pwsh.exe
```

必要时由管理员授予 SSH 账号读取/执行权限：

```powershell
icacls "C:\Program Files\PowerShell\7" /grant `
  "DESKTOP-H0AB0MD\vivadoagent:(OI)(CI)RX" /T
```

配好后用 SSH 账号本身验证，不要只在管理员桌面验证：

```powershell
ssh vivado-srv '"C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command "$PSVersionTable.PSVersion"'
```

本回归不强制依赖 PowerShell 7。Windows PowerShell 5.1 可以使用，但含中文注释的 `.ps1` 必须保存为 UTF-8 BOM，文件头三个字节应为 `EF BB BF`，否则 PS 5.1 可能把 UTF-8 中文误当 ANSI，导致注释吞掉换行并改变脚本语义。

## 3. 命令行 clean 回归（推荐）

### 3.1 检查环境

在 PowerShell 中执行：

```powershell
Test-Path "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat"
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" -version
Get-CimInstance Win32_ComputerSystem |
  Select-Object NumberOfLogicalProcessors, TotalPhysicalMemory
```

版本输出必须是 `Vivado v2020.2`。

### 3.2 第一次完整运行

```powershell
Set-Location "E:\PCIE-CPU\RTDS_test-1ch\regression\sim_xdma_rootport"

powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -VivadoBin "D:\Xilinx_2020_2\Vivado\2020.2\bin" `
  -XelabMt off `
  -XelabDebug typical
```

`-XelabMt off` 是稳定优先配置。另一台电脑有 16 GB 以上内存、8 个以上逻辑处理器时，可在完成一次稳定单线程运行后再试：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -VivadoBin "D:\Xilinx_2020_2\Vivado\2020.2\bin" `
  -XelabMt auto `
  -XelabDebug typical
```

不要在第一次运行时使用任何 `-Skip*` 参数。

### 3.3 在第二个 PowerShell 窗口看进度

展开阶段：

```powershell
Get-Content `
  "E:\PCIE-CPU\RTDS_test-1ch\regression\sim_xdma_rootport\logs\xelab.log" `
  -Wait
```

当 snapshot 完成并进入仿真后，另一个窗口执行：

```powershell
while (-not (Test-Path `
  "E:\PCIE-CPU\RTDS_test-1ch\regression\sim_xdma_rootport\logs\simulate.log")) {
  Start-Sleep -Seconds 5
}
Get-Content `
  "E:\PCIE-CPU\RTDS_test-1ch\regression\sim_xdma_rootport\logs\simulate.log" `
  -Wait
```

看到以下里程碑才算进入正确用例，而不是误跑官方默认 `dma_test0`：

```text
Running test {rtds_minimum}
RTDS_LINK_PASS: Gen3 x2
RTDS_MSI_CONFIG_PASS
RTDS_XDMA_USER_IRQ_ENABLE_PASS
RTDS_BASE_DMA_PASS: H2C+C2H 512 bytes
RTDS_CPU_TO_AURORA_PASS: 512 bytes
RTDS_AURORA_TO_CPU_PASS: 512 bytes irq_ack_seen=1
RTDS_ROOTPORT_RESULT ... errors=0
RTDS_ROOTPORT_PASS
```

### 3.4 查看机器可读结果

```powershell
$root = "E:\PCIE-CPU\RTDS_test-1ch\regression\sim_xdma_rootport"
Get-Content "$root\logs\summary.json"
Select-String -Path "$root\logs\simulate.log" -Pattern `
  "RTDS_.*PASS|RTDS_ROOTPORT_RESULT|ERROR|FATAL|MISMATCH|TIMEOUT"
```

完整 PASS 要求 `summary.json` 的 `passed` 为 `true`，所有 milestone 为 `true`，且没有未白名单 warning 或 fatal 行。

### 3.5 复用 snapshot 的快速复跑

只有源码、include、宏、参数、bind、IP 和编译选项全部未改变时，才可执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -SkipCompile -SkipElaborate
```

这个命令直接执行现有 `xsim.dir/board`，不会再做耗时的 xelab。

如果只修改了 RTL/TB，但工程和 IP 没变：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare `
  -XelabMt off -XelabDebug typical
```

如果修改了 BD、XCI、仿真 fileset 或更换电脑/路径，必须重新执行第 3.2 节的完整命令。

## 4. GUI 运行

### 4.1 推荐：已有 snapshot 后直接打开 XSim GUI

先用第 3.2 节完成一次 xelab。之后执行：

```powershell
Set-Location "E:\PCIE-CPU\RTDS_test-1ch\regression\sim_xdma_rootport"
powershell -ExecutionPolicy Bypass -File .\open_xsim_gui.ps1
```

XSim GUI 打开后，在 Tcl Console 执行：

```tcl
source {E:/PCIE-CPU/RTDS_test-1ch/regression/sim_xdma_rootport/scripts/waves.tcl}
run all
```

Console 中检查与第 3.3 节相同的 PASS 里程碑。默认 WDB 保存为：

```text
logs/rtds_minimum_gui.wdb
```

这种方式不会重新 elaboration，最适合观察波形和重复运行。

### 4.2 从 Vivado 工程 GUI 做 clean 编译/展开

先关闭其他 Vivado/XSim 进程，然后从固定 2020.2 打开工程：

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  "E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.xpr"
```

在 GUI 中逐项确认：

1. `Sources` 窗口选择 `Simulation Sources`，active simulation set 为 `sim_xdma_rootport`。
2. 仿真顶层为 `board`，库为 `xil_defaultlib`。
3. 该 fileset 中能看到 `vendor/xdma_rp_2020_2`、`tb/board.sv`、wrapper、BFM 和 assertions；不能用默认 `sim_1`。
4. `Simulation Settings` 中 Simulator 为 XSim，Elaboration debug level 设为 `typical`，不要用 `all/wave`。
5. Xelab multi-threading 先设为 `off`；高配电脑稳定后再试 auto。
6. Simulation runtime 设为 `2 ms`。
7. XSim simulate additional options 加入：

   ```text
   -testplusarg TESTNAME=rtds_minimum
   ```

8. 点击 `Run Simulation → Run Behavioral Simulation`。
9. 仿真 GUI 打开后 source `waves.tcl`，再执行 `run all`。

如果 GUI 中没有 `sim_xdma_rootport`，不要手工逐个加文件。先关闭 GUI，在 PowerShell 运行第 3.2 节完整命令，至少让 audit/prepare 重新建立 fileset 和编译顺序，再打开工程。

注意：Vivado GUI 启动 behavioral simulation 仍会调用同一个 xvlog/xelab/xsim，因此不会天然比命令行更快；它的价值是查看进度、层级和波形。

## 5. 回归产物和回传清单

成功或失败后，保留：

```text
logs/audit_and_prepare.log
logs/prepare_rootport_sim.log
logs/xvlog.log
logs/xvhdl.log
logs/xelab.log
logs/simulate.log
logs/summary.json
logs/rtds_minimum.wdb
logs/address_map.txt
logs/ip_status.txt
logs/compile_order.txt
```

回传给本任务继续分析时，最少提供：

- `xelab.log`。
- `simulate.log`。
- `summary.json`。
- 如果 XSim 崩溃，提供 PowerShell 退出码、崩溃时内存占用和日志最后 200 行。
- 如果数据或协议失败，提供 WDB；WDB 很大时先提供失败时间点和 `simulate.log`，再按需传波形。

## 5.1 远端快速回归（2026-07-17 更新）

首次运行或 `board.sv`/BFM/RTL 已变化时，必须重新编译和展开：

```powershell
Set-Location C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -FastMode `
  -VivadoBin C:\Xilinx\Vivado\2020.2\bin `
  -XelabMt auto -XelabOptimize 3 `
  -XsimMaxDeltaId 10000 -WallClockTimeoutMinutes 90
```

`FastMode` 使用 `--O3 --debug off`，保留 checker/scoreboard/log，关闭分组 WDB。当前 2020.2 的原始参数必须是 `--O3`；脚本已处理，手工执行 xelab 时不要写成 `-O 3`。

只有新 snapshot 已成功生成，而且 HDL/IP/include/xelab 选项都没有变化时，才可增加：

```powershell
-SkipCompile -SkipElaborate
```

若快速模式失败，需要波形定位，应去掉 `-FastMode`，使用 `-XelabDebug typical -XelabOptimize 2` 重新展开。`debug off` 生成的 snapshot 不能凭空恢复内部波形可见性。

当日志出现 maximum delta/maxdeltaid 错误时，说明仿真卡在同一时刻的事件迭代；若仿真时间推进但 90 分钟墙钟超时，则不是同一种问题。超时日志保存在 `logs/timeout_<时间>`。本轮断点详情见 `regression/sim_xdma_rootport/logs/NEXT_DIAGNOSTIC_2026-07-17.md`。

## 5.2 最终精选信号波形回归（WaveMode）

功能 FastMode PASS 与最终波形证据是两个层次：FastMode 用于快速判断链路、DMA、Aurora、IRQ 和 scoreboard 是否通过；WaveMode 重新以 `debug=typical` 展开 snapshot，并只采集精选事务信号，生成可以复查的 WDB/WCFG。早于 CQ Host sink、FDMA 映射修复的旧 `logs/rtds_minimum.wdb` 不能作为最终波形证据。

运行前先把当前 `simulate.log`、`summary.json` 和旧 WDB 复制到日期目录，避免新运行覆盖 FastMode 证据。远端使用 Windows PowerShell 5.1 时执行。`run_xsim_detached.ps1` 只是仿真工作器，不会自行 breakaway；为允许 SSH 断开，必须通过 `launch_breakaway.ps1` 启动：

```powershell
Set-Location C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\launch_breakaway.ps1 `
  -WorkingDirectory C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717 `
  -CommandLine 'powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717\run_xsim_detached.ps1 -VivadoBin C:\Xilinx\Vivado\2020.2\bin -RebuildSnapshot -WaveMode -WallClockTimeoutMinutes 120'
```

启动命令返回并打印 `BREAKAWAY_PROCESS_PID=...` 后，才表示工作器已由 Windows 独立托管，此时可断开 SSH。`-RebuildSnapshot` 是必要的：FastMode 的 `--debug off` snapshot 没有层级追踪信息，不能在事后凭空恢复内部信号。`-WaveMode` 使用 `debug=typical`、`--O2` 和 `waves.tcl` 的语义分组；不传 `-FastMode`。重新连接后只读 `detached_status.json` 和 `logs/simulate.log`，不要再次启动第二个实例。

WaveMode 验收必须同时满足：

```text
state=completed
exit_code=0
RTDS_ROOTPORT_PASS
RTDS_LOG_COMPARE_PASS
unexpected_warnings=0
fatal_lines=0
```

并确认本轮生成的 WDB 非空、修改时间属于本轮、波形推进到约 274.094 us。最终归档至少包含：

```text
rtds_minimum.wdb
rtds_minimum.wcfg
simulate.log
summary.json
final_wave_acceptance.json
```

精选波形按 Reset/Link、RP TLP、DMA、CQ Host、FDMA、Aurora LL、IRQ、Result 分组查看；不递归加入整个 `HOST_MEMORY` 数组，数据正确性以 CQ sink 事务计数和 scoreboard 为准。建议时间窗为：0～228.49 us（复位/训练/枚举）、245.73～261.94 us（基础 H2C/C2H）、261.94～263.30 us（CPU→Aurora）、263.30～273.99 us（Aurora→CPU/IRQ/C2H）、274.094 us（PASS）。

### 5.2.1 只读打开最终 WDB/WCFG

WaveMode 完成后，在远端或已映射的工作区执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\open_final_wdb.ps1
```

该入口在本机默认调用 `D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`，只执行 `open_wave_database` 和 `open_wave_config`，不会重新编译或运行仿真。远端 Vivado 安装在 `C:\Xilinx\Vivado\2020.2\bin`，远端查看必须显式执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\open_final_wdb.ps1 `
  -VivadoBin C:\Xilinx\Vivado\2020.2\bin
```

GUI 等价操作是：启动对应机器的 Vivado 2020.2 Waveform Viewer，加载最终 `rtds_minimum.wdb`，再加载最终 `rtds_minimum.wcfg`，按上述分组和时间窗定位。

### 5.2.2 日志与波形的对应关系

日志比对忽略绝对时间戳、临时路径和许可证信息，只比较 link up/Gen3 x2、BAR/XDMA 定位、descriptor count/status、INFO_EXCH/IRQ/read-to-clear、两个 512 B scoreboard 及最终 PASS。任何新增或无法精确归类的 `ERROR/FATAL/MISMATCH/TIMEOUT` 或 warning 都必须进入报告并使验收失败。波形用于解释事务时序和地址/长度，日志与 scoreboard 才是机器可读的最终结论。

## 6. 常见失败处理

所有已知问题的编号、证据、处理状态和每日运行变化见 `docs/RTDS_test_XDMA_RootPort问题发现与处理台账.md`。遇到新现象时先登记，再决定是 DUT、testbench、Xilinx 模型还是运行环境问题。

### 6.1 `XSIM 43-3294 EXCEPTION_ACCESS_VIOLATION`

先重跑：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -SkipCompile `
  -XelabMt off -XelabDebug typical
```

若单线程仍在 native module 编译阶段崩溃，功能优先的诊断运行可改成：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -SkipCompile `
  -XelabMt off -XelabDebug off
```

`debug off` 会限制内部波形访问，只用于判断是否能完成功能快照，不能替代最终带关键波形的验收。

同时关闭占用内存的软件，确保页面文件由系统管理；将工作区放在本地 SSD。若公司策略允许，只对 `sim_xdma_rootport/work` 和 `.Xil` 设置杀毒实时扫描排除，不要扩大排除范围。

### 6.2 误跑 `dma_test0`

原因是缺少 `TESTNAME=rtds_minimum`。命令行必须由 `run_xsim.ps1` 启动，GUI 必须设置 `-testplusarg TESTNAME=rtds_minimum`。

### 6.3 只有 `usr_irq_req`，没有 `usr_irq_ack`

依次检查：

1. `RTDS_MSI_CONFIG_PASS`，即配置空间 MSI Enable 已写入，`msi_enable=1`。
2. `RTDS_XDMA_USER_IRQ_ENABLE_PASS`，即 XDMA IRQ block `0x2004[0]=1`。
3. `usr_irq_req[0]` 是否保持到 ack。
4. WDB 中 XDMA IRQ monitor 和 RP TLP 是否有消息证据。

没有 ack 时不能把 INFO_EXCH read-to-clear 当作完整 PCIe 中断闭环 PASS。

### 6.4 Aurora→FPGA 出现 `RTDS_LL_RX_NO_BACKPRESSURE`

这是设计错误而不是 BFM 随机行为。Aurora→FPGA 方向按 SERDES 连续源建模，BFM 不等待 `rx_dst_rdy`；FPGA 必须在整帧输入期间持续可接收，否则回归立即失败。
