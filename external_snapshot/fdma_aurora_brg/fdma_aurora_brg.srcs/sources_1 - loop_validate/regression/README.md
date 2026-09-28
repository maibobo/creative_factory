# 回归快速使用

本目录现在有 4 个入口，推荐优先级如下：

1. `run_regression_parallel.py`：推荐日常使用。一个脚本可跑单个 testcase，也可按 `regress_list` 并行回归。
2. `run_regression.ps1`：旧 PowerShell 串行入口，保留兼容。
3. `run_regression.tcl`：Vivado batch 单用例底层入口，通常给 Python/PowerShell 调用。
4. `setup_vivado_sim.tcl`：Vivado GUI Tcl Console 调试入口，只配置一个 testcase，不做批量回归。

## verbose 怎么选

`VERBOSE` 由 testbench 的 `+VERBOSE=<0|1|2>` 控制：

- `0`：摘要级。只打印 testcase、seed、关键检查和最终 `TEST_PASS/TEST_FAIL`。推荐全量回归。
- `1`：帧/突发计划级。会打印随机计划、帧首尾数据、地址检查等。推荐单用例复现失败。
- `2`：逐握手级。会打印 FDMA、LocalLink、FIFO 等每个握手监控。只推荐定位错位、丢拍、ready/valid 边界。

建议：

- 全量回归：`--verbose 0`，list 中 `wave=0`
- 单个失败 seed 复现：`--verbose 1 --wave 0`
- 仍看不出根因：`--verbose 2 --wave 0`
- 需要看时序波形：固定同一个 seed，`--verbose 1 --wave 1`

`wave=1` 会生成完整 WDB，Aurora full-loop 用例会明显更慢，文件也会更大。
`wave=1` 是强制产物要求：若 testcase 功能通过但 WDB 缺失或为空，功能结果仍记为
`TEST_STATUS=PASS`，整条 job 会记为 `RUN_STATUS=ARTIFACT_FAIL`，并保留工程副本用于排查。

## Python 并行入口

在 Vivado Command Prompt 或普通 PowerShell 中进入本目录：

```powershell
cd "E:\gpt_doc\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression"
```

按 `regress_list` 并行跑全部展开后的 job：

```powershell
python .\run_regression_parallel.py `
  --regress-list .\regress_list `
  --verbose 0 `
  --max-parallel 2 `
  --retry-infra 2 `
  --run-dir C:\project\vivado_regress\run `
  --work-root C:\project\vivado_regress `
  --vivado "C:\Xilinx\Vivado\2020.2\bin\vivado.bat"
```

单个 testcase：

```powershell
python .\run_regression_parallel.py `
  --testcase tc_brg_tx_fifo_waterline `
  --repeat 1 `
  --wave 1 `
  --verbose 1
```

复现固定 seed：

```powershell
python .\run_regression_parallel.py `
  --testcase tc_brg_tx_fifo_waterline `
  --seed 123456 `
  --wave 1 `
  --verbose 1
```

替换工程位置：

```powershell
python .\run_regression_parallel.py `
  --project-xpr "E:\your_project\fdma_aurora_brg.xpr" `
  --loop-root "E:\your_project\fdma_aurora_brg.srcs\sources_1 - loop_validate" `
  --regress-list "E:\your_project\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\regress_list" `
  --verbose 0
```

常用参数：

- `--regress-list`：回归列表，每行 `testcase repeat wave`。
- `--testcase`：只跑一个 testcase；不能和 `--regress-list` 同时使用。
- `--repeat`：单 testcase 重复次数。
- `--seed`：固定 6 位 seed，只能配合单 testcase、`--repeat 1` 使用。
- `--wave`：单 testcase 的波形开关，`0` 不保存 WDB，`1` 保存 WDB。
- `--verbose`：`0/1/2`，含义见上文。
- `--max-parallel`：同时启动的 Vivado batch 数；`0` 表示 list 展开几个 job 就同时跑几个。建议先用 `2` 验证稳定后再加。
- `--retry-infra`：对 compile/elab/sim setup/tool 这类非 testcase 逻辑失败使用相同 seed 串行重跑的次数，默认 `2`；compare/assert/timeout/testcase fail 不会自动重跑。
- `--run-dir`：结果输出目录，保存 `regress_log.log`、`regress_log.tsv`、`regress_rpt.log`、Vivado stdout/stderr、复制出的 `simulate.log`、WDB 和 `vivado_logs/`；默认 `C:\project\vivado_regress\run`。
- `--work-root`：每个并行 job 的 Vivado 工程副本根目录，默认 `C:\project\vivado_regress`。每次运行会在其下生成 `<run-id>\jNNN_<seed>\fdma_aurora_brg`。
- `--shared-project`：不复制工程，直接共用当前 `.xpr`。只建议串行/临时调试用，并行时不推荐。
- `--keep-work`：保留每个 job 的工程副本，方便排查 Vivado 工程状态。
- `--dry-run`：只展开 job、seed 和工程副本路径，不启动 Vivado。

默认情况下，Python 会给每个并行 job 复制一份独立 Vivado 工程工作副本，避免多个 Vivado 进程同时写同一个 `.xpr`、`.sim` 和 `xsim` 目录。
工程副本目录和结果目录是分开的：

```text
run_dir       = 最终 log、报告、simulate.log、WDB、vivado_logs，默认 C:\project\vivado_regress\run
work_root     = 工程副本总根目录，默认 C:\project\vivado_regress
work_run_root = <work_root>\<run-id>
```

`--dry-run` 会打印每个 job 的 `work_project=...fdma_aurora_brg.xpr`，可先看路径是否足够短。

### WinError 206 路径过长

旧版脚本把工程副本放在 `run_dir\_work\001_<testcase>_<seed>\fdma_aurora_brg` 下。如果 `run_dir` 本来就在很深的 regression 目录中，XSim 生成目录容易接近 Windows 路径上限并触发 `WinError 206`。

新版默认将工程副本放到短路径：

```text
C:\project\vivado_regress\<run-id>\j001_123456\fdma_aurora_brg
```

如果仍遇到少数 IP 生成路径过长，可进一步缩短：

```powershell
python .\run_regression_parallel.py `
  --regress-list .\regress_list `
  --verbose 0 `
  --max-parallel 2 `
  --run-dir C:\vrl\r1 `
  --work-root C:\vrw
```

快速判断是否为工程副本路径问题，可串行临时共用原工程：

```powershell
python .\run_regression_parallel.py `
  --testcase tc_brg_tx_fifo_waterline `
  --seed 123456 `
  --wave 0 `
  --verbose 1 `
  --shared-project `
  --max-parallel 1 `
  --run-dir C:\vrl\debug
```

`--shared-project` 能跑而默认复制工程时报 206，基本就是工作副本路径过长。

结果查看：

默认结果目录为 `C:\project\vivado_regress\run`，也就是 `--run-dir` 的默认值。若手动传了 `--run-dir`，下列文件都在你指定的目录下。

- `regress_log.log`：对齐的人读表格，长字段会截断。
- `regress_log.tsv`：完整机器可解析记录，保留完整路径和错误摘要。
- `regress_rpt.log`：按 overall/testcase/abnormal/retry 汇总。
- `<testcase>_<seed>_a<N>_vivado.log`：Vivado stdout。
- `<testcase>_<seed>_a<N>_vivado.err.log`：Vivado stderr。
- `<testcase>_<seed>_a<N>_simulate.log`：XSim 仿真 log。
- `<testcase>_<seed>_a<N>_behav.wdb`：`wave=1` 时保存的波形。
- `vivado_logs/<testcase>_<seed>_a<N>/`：从工程副本复制出来的关键 Vivado/XSim 内部 `.log/.jou`。
- `failed_replay.ps1`：失败或产物异常 seed 的复现命令。
- `failed_regress_list`：只包含失败或产物异常 testcase 的回归列表。

如果从另一台电脑把结果拷回到本目录，常见会看到：

- `regression\run`：结果目录的拷贝容器；本次包里的 `regression\run\run` 对应另一台电脑上的 `C:\project\vivado_regress\run`，里面是 `regress_log.*`、`regress_rpt.log`、每个 attempt 的 Vivado/XSim log、WDB、`failed_replay.ps1` 和 `rerun_failed` 等。
- `regression\j001_167749_a1`：失败或保留现场时拷回来的单个 job 工程副本；名字表示 job #001、seed `167749`、attempt 1。里面是完整的临时 Vivado 工程、`.xpr`、`.srcs`、`.sim/.cache/.gen` 和源文件副本，用来复盘当时的工程状态，不是日常默认输出目录。

`regress_log.log` 的主要字段：

```text
STATUS KIND TEST TC ITER SEED ATT W WAVE_ST SEC FIRST_ERROR LOG
```

- `STATUS=PASS`：功能通过，且请求的产物也齐全。
- `STATUS=COMPILE_FAIL/ELAB_FAIL/SIM_SETUP_FAIL/...`：最终失败类型，不再只用笼统 `RUN_FAIL`。
- `STATUS=ARTIFACT_FAIL`：testcase 功能通过，但 `wave=1` 的 WDB 缺失、为空或复制失败。
- `TEST_STATUS` 只表示 testcase 功能结果。
- `FAIL_STAGE` 在 `regress_log.tsv` 中保留完整字段，区分 `COMPILE_FAIL`、`ELAB_FAIL`、`SIM_SETUP_FAIL`、`SIM_RUN_FAIL`、`COMPARE_FAIL`、`ASSERT_FAIL`、`TIMEOUT_FAIL`、`TEST_FAIL`、`TOOL_FAIL`、`ARTIFACT_FAIL`。
- `WAVE_STATUS` 为 `NOT_REQUESTED`、`GENERATED`、`MISSING`、`EMPTY` 或 `COPY_FAILED`。
- `FIRST_ERROR` 会记录 stderr/stdout/simulate.log 中最早匹配到的错误摘要。

`regress_rpt.log` 会汇总各类失败数量，并列出每条失败/产物异常 job 的首错、log 路径、额外 Vivado log 目录和工程副本路径。

### 自动 retry 和并发稳定性

默认 `--retry-infra 2`，首轮仍按 `--max-parallel` 并发跑；首轮结束后，只把 `COMPILE_FAIL`、`ELAB_FAIL`、`SIM_SETUP_FAIL`、`TOOL_FAIL` 用相同 seed 串行 retry，最多两次。每次 attempt 的文件名带 `_a1/_a2/_a3`，首失败现场不会被覆盖。

不会自动 retry `COMPARE_FAIL`、`ASSERT_FAIL`、`TIMEOUT_FAIL` 或普通 `TEST_FAIL`，避免把真实 testcase/RTL 逻辑问题掩盖掉。

`xsim.ini`、`launch_simulation`、仿真工作目录准备失败通常属于 `SIM_SETUP_FAIL`，这类问题更像 Vivado/XSim 并发或环境文件访问问题。建议稳定默认值使用 `--max-parallel 2`，并让 `run-dir/work-root` 位于短本地路径，例如 `C:\vrl`、`C:\vrw` 或 `C:\project\vivado_regress`；必要时把这些目录加入杀毒/实时扫描排除。

“单条用例重复 50 次”和“5 条用例重复 10 次”不保证概率相同。如果失败只和 Vivado 进程次数有关，50 个 job 的总风险接近；但当前更像并发资源/文件访问问题，实际概率主要受同时启动的 Vivado 数量、testcase 重量和磁盘/杀毒干扰影响。

### 重跑失败或异常用例

`failed_replay.ps1` 有两类命令：

1. 每条失败/异常 seed 的单独复现命令，保留原 `seed/wave/verbose/work-root/project-xpr/loop-root`，并使用 `--retry-infra 0` 复现原始失败现场。
2. 批量只重跑失败/异常 testcase 的完整命令，使用 `failed_regress_list`，会重新生成随机 seed。

在 PowerShell 中执行：

```powershell
powershell -ExecutionPolicy Bypass -File C:\project\vivado_regress\run\failed_replay.ps1
```

若 job 失败或 `ARTIFACT_FAIL`，默认会保留工程副本：

```text
<work-root>\<run-id>\jNNN_<seed>\fdma_aurora_brg
```

控制台会打印 `WORK_RETAINED=<路径>`。PASS 且产物齐全的 job 默认删除副本；传 `--keep-work` 可全部保留。

### 波形和 MON 日志定位

`VERBOSE=2` 时逐握手 monitor 日志包含：

```text
[MON][FDMA_WR][TIME=125000][PATH=<验证层次>][COMP=FDMA_WR][SRC=tc_base.sv:439] ...
```

- `TIME` 是仿真时间，可在 Vivado WDB 中跳到对应时间附近。
- `PATH` 是 `%m` 打印的 SystemVerilog 层次，用于确认是哪个 monitor/task 实例打印。
- `COMP` 是监控组件名，例如 `FDMA_WR`、`LL_RX`、`TX_FIFO_RD`。
- `SRC` 是监控打印所在源码文件和行号，便于回到代码查看触发条件。

`VERBOSE>=1` 会打印一次 ACTIVE 日志，确认 monitor 已启用；逐握手日志仍只在 `VERBOSE=2` 输出。

### Selected VCD 和 WaveDrom

`wave=1` 保存完整 WDB，适合 Vivado GUI 精查；如果只想让脚本画少量关键信号，使用 selected VCD：

```powershell
python .\run_regression_parallel.py `
  --testcase tc_brg_tx_fifo_waterline `
  --seed 123456 `
  --wave 0 `
  --verbose 2 `
  --retry-infra 0 `
  --vcd-mode selected `
  --vcd-signals .\wave_signals.tx_fifo_waterline.tcl `
  --vcd-start 1000ns `
  --vcd-stop 3000ns `
  --dump-hierarchy 1 `
  --gen-wavedrom 1 `
  --run-dir C:\vrl\tx_fifo_waterline_manual
```

输出文件名会带 attempt，避免 retry 覆盖现场：

```text
tc_brg_tx_fifo_waterline_123456_a1_hierarchy.txt
tc_brg_tx_fifo_waterline_123456_a1_signal_check.txt
tc_brg_tx_fifo_waterline_123456_a1_selected.vcd
tc_brg_tx_fifo_waterline_123456_a1_wavedrom.json
tc_brg_tx_fifo_waterline_123456_a1_wavedrom.svg
tc_brg_tx_fifo_waterline_123456_a1_wave_summary.md
```

如果只知道日志锚点，不知道具体时间窗，可以让脚本先跑一次同 seed 找 `TIME`，再复跑导出窗口 VCD：

```powershell
python .\run_regression_parallel.py `
  --testcase tc_brg_tx_fifo_waterline `
  --seed 123456 `
  --wave 0 `
  --verbose 2 `
  --retry-infra 0 `
  --vcd-mode selected `
  --vcd-signals .\wave_signals.tx_fifo_waterline.tcl `
  --vcd-anchor "[MON][TX_FIFO_WR]" `
  --vcd-pre 200ns `
  --vcd-post 400ns `
  --dump-hierarchy 1 `
  --gen-wavedrom 1 `
  --run-dir C:\vrl\tx_fifo_waterline_123456
```

这会额外产生一个 `_anchor` 日志用于定位时间点，正式图形产物仍使用 `_a1` 命名。单次波形调试建议保留 `--retry-infra 0`，避免 retry 后看错 attempt；全量回归仍可使用默认 `--retry-infra 2`。

每次 selected VCD 运行前，Tcl 会写出层次和信号匹配报告。例如当前 waterline 用例的关键层次应是：

```text
TOP      = /tc_brg_tx_fifo_waterline_top
HARNESS  = /tc_brg_tx_fifo_waterline_top/h
DUT      = /tc_brg_tx_fifo_waterline_top/h/dut
TX       = /tc_brg_tx_fifo_waterline_top/h/dut/u_fdma_aurora_brg_tx
RX       = /tc_brg_tx_fifo_waterline_top/h/dut/u_fdma_aurora_brg_rx
```

`signal_check.txt` 会列出每个 pattern 的匹配数量；如果信号路径写错，先看这个文件。

WaveDrom 相关参数：

- `--vcd-mode selected`：打开 selected VCD。
- `--vcd-signals`：指定要 dump 的信号列表。
- `--vcd-start/--vcd-stop`：手动指定仿真时间窗。
- `--vcd-anchor/--vcd-pre/--vcd-post`：按日志锚点自动计算时间窗。
- `--dump-hierarchy 1`：保存层次报告。
- `--gen-wavedrom 1`：从 selected VCD 生成 WaveDrom JSON、简易 SVG 和 summary。

如果 testcase 功能通过，但 selected VCD 或 WaveDrom 产物缺失，会记为 `ARTIFACT_FAIL`，不是 RTL/testcase 逻辑失败。完整产物路径保存在 `regress_log.tsv`。

## regress_list 格式

每行三个字段：

```text
# testcase                    repeat  wave(0|1)
tc_aurora_loop_nobp             1       0
tc_brg_tx_fifo_waterline        1       1
```

- `testcase` 必须在 `../new/tc/tc_list` 注册。
- `repeat` 是重复次数，每轮随机生成不重复的 6 位 seed。
- `wave=0` 不保存 WDB。
- `wave=1` 保存 WDB。

替换或新增用例：

1. 在 `../new/tc/tc_list` 添加 testcase 名，例如 `tc_new_case`。
2. 添加源码文件 `../new/tc/tc_new_case.sv`。
3. 文件中提供 top module：`tc_new_case_top`。
4. 在 `regress_list` 中添加：

```text
tc_new_case  1  0
```

## 单用例 Tcl Batch 入口

通常不手写调用，给 Python/PowerShell 调用即可。需要手动调用时：

```powershell
vivado.bat -mode batch -notrace `
  -source "E:\gpt_doc\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\run_regression.tcl" `
  -tclargs tc_brg_tx_fifo_waterline 123456 1 0 "E:\gpt_doc\my_regress_logs\one_tc"
```

参数顺序：

```text
testcase seed wave verbose log_dir ?project_xpr? ?loop_root? ?output_stem? ?vcd_mode? ?vcd_signal_file? ?vcd_start? ?vcd_stop? ?dump_hierarchy?
```

前 5 个参数保持旧用法兼容；`project_xpr/loop_root` 用于替换工程或让 Python 并行脚本指向独立工程副本；`output_stem` 用于 retry attempt 文件名区分，未传时仍使用旧的 `${testcase}_${seed}`；后续 VCD 参数通常由 Python 入口自动传递。

## Vivado GUI Tcl Console 调试

GUI 适合调试一个失败 seed，不适合批量并行回归。

默认配置 `tc_aurora_loop_nobp`：

```tcl
source {E:/gpt_doc/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/regression/setup_vivado_sim.tcl}
```

指定 testcase、seed、verbose、wave：

```tcl
source {E:/gpt_doc/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/regression/setup_vivado_sim.tcl} tc_brg_tx_fifo_waterline 123456 1 1
```

脚本会设置：

- `sim_1` top 为 `${testcase}_top`
- `xsim.simulate.xsim.more_options` 为 `-testplusarg SEED=<seed> -testplusarg VERBOSE=<verbose>`
- `xsim.simulate.log_all_signals` 为 `wave` 对应值

然后在 Tcl Console 执行：

```tcl
launch_simulation -simset sim_1 -mode behavioral
run all
```

不要在 GUI Tcl Console 里 `source run_regression.tcl`，因为 batch 脚本末尾会 `exit 0`。

## PowerShell 串行旧入口

旧入口仍可用：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_regression.ps1 `
  -RegressList .\regress_list_nowave_once `
  -LogVerbosity 0 `
  -RunDir "C:\project\vivado_regress\run" `
  -Vivado "C:\Xilinx\Vivado\2020.2\bin\vivado.bat"
```

区别：

- Python：推荐日常回归，支持单用例/多用例、并行、失败复现脚本，更容易改配置。
- PowerShell：保留兼容，串行流程稳定但配置扩展不如 Python 清楚。
- GUI：最适合看波形和交互调试，不适合无人值守回归。

完整结构、测试步骤、预期结果和错误定位方法见：
`../new/fdma_aurora_brg_sim_verification.md`。
