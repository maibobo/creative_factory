

## 运行

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1
```

固定工具路径为 `D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`。首次运行会：

1. 仅在缺失时重建 `fifo_AURORA_DATA64` 生成物，并审计 1ch/Gen3 x2/64-bit/250 MHz 配置。
2. 建立内存中的独立 simulation fileset，导出到 `work/export`。
4. 在 `logs` 保存编译日志、仿真日志、WDB 和 `summary.json`。

## Aurora 边界约束

- FPGA→Aurora：BFM 可以施加 `tx_dst_rdy` 背压；最小闭环关闭随机背压。
- Aurora→FPGA：数据源每拍连续推进，不等待 `rx_dst_rdy`。FPGA 若撤销 ready，BFM 与断言都会立即报错，因为真实 Aurora SERDES 不能由 FPGA 数据通路向线路反压。

## 成功判据


## 快速回归与防卡死

完整 PCIe 串行模型中反复读取 descriptor count 会为每次轮询生成真实 Memory Read TLP 和 Completion。当前环境先用 `xdma_axi_activity_monitor.sv` 等待 Endpoint 本地 AXI 数据面前进；C2H 再由 `pcie_cq_host_memory_monitor.sv` 接收 RP CQ Memory Write，等待自定义 Host sink 的 sentinel 被覆盖；最后稀疏读取 count 并确认 `count=1/status=0x6`。官方 `DATA_STORE` 仅作为描述符/H2C 的 Host read 数据源，不作为 C2H 目标 RAM。

日常快速运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 -FastMode
```

`FastMode` 使用 xelab `--O3 --debug off` 和 `scripts/run_fast.tcl`，保留断言、scoreboard 和语义日志，但不生成大规模 WDB。XSim 同时使用 `-maxdeltaid 10000`；若仿真在同一时刻超过该 delta 数就明确失败。独立的 120 分钟墙钟看门狗用于仿真时间完全不能前进的情形，并把现有日志复制到 `logs/timeout_*` 后终止 XSim 进程树。


```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\launch_breakaway.ps1 `
```

`launch_breakaway.ps1` 使用 `CreateProcessW(CREATE_BREAKAWAY_FROM_JOB)` 启动工作器；只有看到其输出的 `BREAKAWAY_PROCESS_PID=...` 后才可关闭 SSH。工作器默认使用 120 分钟墙钟看门狗；WaveMode/FastMode 均将 `xelab --mt` 固定为 `off`。Vivado 2020.2 在本机的 `--mt auto` 曾于 native module 编译阶段触发 XSIM 43-3294 堆损坏，故不把该选项作为验收加速手段。`xsimk` 仍按模型自身运行，仿真可安全与 SSH 会话断开。

波形查看只读入口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\open_final_wdb.ps1
```

本机默认 Vivado 路径为 `D:\Xilinx_2020_2\Vivado\2020.2\bin`。在远端查看必须显式指定远端安装目录：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\open_final_wdb.ps1 `
  -VivadoBin C:\Xilinx\Vivado\2020.2\bin
```

它只从最近的 `logs/final_wave_*` 验收归档读取 WDB/WCFG，并调用固定 Vivado 2020.2 的 `open_wave_database`/`open_wave_config`；也可显式传入 `-WdbPath` 与 `-WcfgPath` 成对路径，不会重新编译或运行仿真。

失败定位需重新展开带波形的 snapshot：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -SkipCompile `
  -XelabMt off -XelabDebug typical -XelabOptimize 2
```

仅当 RTL/TB/IP、include、参数和 xelab 选项都未变化时，才可再加 `-SkipElaborate` 复用 snapshot。

问题、证据、修复状态和每日运行记录统一维护在
中文语义段覆盖范围、阅读顺序及明确不修改的官方/生成文件，见

## 最终最小回归基线

2026-07-23 远端 Vivado 2020.2 FastMode 回归已完成：

```text
墙钟：36 分 40 秒
仿真结束：274.094 us
```

最终证据保存在 `logs/final_remote_20260723`。其中 `summary.json` 为
`passed=true`、`unexpected_warnings=0`、`fatal_lines=0`；
`final_acceptance.json` 解释了为什么修复前的 detached 状态文件仍保留
`exit_code=1`，避免把日志门禁的历史假失败误认为 DUT 失败。

## 最终精选波形基线

2026-07-24 远端 Vivado 2020.2 WaveMode 清洁回归已完成，并已同步到本机
`logs/final_wave_20260724_123542`：

```text
墙钟：22 分 48 秒
仿真结束：274.094 us
state=completed
exit_code=0
errors=0
unexpected_warnings=0
fatal_lines=0
```

本轮 7 条 warning（simulate 6 条、prepare 1 条）全部命中精确 Xilinx
模型白名单。最终文件校验值为：

| 文件 | 大小 | SHA-256 |
|---|---:|---|
| `simulate.log` | 46,494 B | `83e3204363ffa2ce52cf6f49648fbf7157124f41b7a3a206ab59ffaa402db403` |
| `summary.json` | 1,543 B | `b1272471d299e6d18889b240c643a16b79548123f8045a41114934138bed6090` |

查看最终波形直接执行本节前面的 `open_final_wdb.ps1` 命令。脚本会检查
`final_wave_acceptance.json` 的 `accepted=true` 后自动选择该归档，不会误开
2026-07-16 的旧 WDB，也不会重新编译或运行仿真。
