# 2026-07-17 断点与下次诊断入口

## 当前状态

- 已停止验证，没有本轮 XSim/Xelab 任务在运行；远端既有 `xsimk PID=18572` 属于其他任务，未操作。
- 旧的长时间运行已归档在远端 `logs/archive_run_20260717_102456`。它通过 link、BAR、MSI 配置、XDMA user IRQ enable、基础 H2C/C2H count/status 和 CPU→Aurora 512 B；基础 C2H Host 比较曾读到全 0，CPU→Aurora 随后通过，之后长时间无新里程碑。
- 现有证据不能证明一定存在真正的零时间事件风暴，也可能是 Aurora→CPU/IRQ 阶段的长周期等待。环境现已同时加入阶段日志、delta 上限和墙钟看门狗，下次可把两者区分开。

## 已完成的仿真环境修复

1. 新增 `tb/xdma_axi_activity_monitor.sv`，以真实 XDMA M_AXI 握手计数 H2C/C2H 本地数据进度和 AXI response error。
2. DMA 等待改为“本地 AXI 事件 → C2H Host 内存 sentinel/排空 → 最多 4 次 PCIe count/status 确认”，消除高频 PCIe 寄存器轮询。
3. C2H Host 目标区不再预置全 0，而是预置期望数据取反，末字节到达后再等 32 个 RP 时钟再逐字节比较。
4. `board` 显式 `timeunit/timeprecision=1ps`，增加 10 个 250 MHz 周期应为 40000 ps 的自检；全局 2 ms 超时改用 500000 个真实 `i_sys_clk` 周期。
5. Aurora→CPU 注入、IRQ 等待、H2C/C2H、CPU→Aurora 均增加唯一 `RTDS_STAGE_*` 日志，避免数小时无阶段证据。
6. `run_xsim.ps1` 增加 `FastMode`、xelab `--O3`、XSim `-maxdeltaid 10000` 和默认 90 分钟 OS 墙钟看门狗；快速入口不生成 WDB。
7. 所有新增脚本/RTL均按语义段写入中文说明；未修改生产 RTL、官方 Root Port 或官方 TPI 主逻辑。

## 本轮已有日志

- 本机新增 HDL 编译检查：`logs/xvlog_patch_check.log`，包含 `analyzing module xdma_axi_activity_monitor` 和 `analyzing module board`，无 ERROR/FATAL。
- 远端编译日志副本：`logs/xvlog_remote_2026-07-17.log`。
- 远端启动参数诊断：`logs/remote_fast_console_2026-07-17.log` 与 `logs/remote_fast_console_2026-07-17.err.log`。
- 远端最后一次未进入展开的原因是脚本曾传入文档式 `-O 3`，而 Vivado 2020.2 实际帮助只接受 `--O0..--O3`。源码已修正为 `--O3`，修正后按用户要求未再验证。

## 远端下次完整命令

```powershell
Set-Location C:\project\RTDS\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport_remote_20260717
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\run_xsim.ps1 `
  -SkipAudit -SkipPrepare -FastMode `
  -VivadoBin C:\Xilinx\Vivado\2020.2\bin `
  -XelabMt auto -XelabOptimize 3 `
  -XsimMaxDeltaId 10000 -WallClockTimeoutMinutes 90
```

这次修改了 `board.sv`，必须执行 xvlog 和 xelab，不能复用旧 snapshot。新 snapshot 成功生成且源码/参数不再变化后，后续快速重跑可加入：

```powershell
-SkipCompile -SkipElaborate
```

## 下次首先比对的关键原句

```text
INFO: [VRFC 10-311] analyzing module xdma_axi_activity_monitor
INFO: [VRFC 10-311] analyzing module board
Built simulation snapshot board
RTDS_TIMEBASE_PASS
RTDS_H2C_AXI_PASS
RTDS_C2H_HOST_DRAIN_PASS
RTDS_STAGE_BEGIN: AURORA_TO_CPU_INJECT
RTDS_USER_IRQ_ASSERT_PASS
RTDS_ROOTPORT_RESULT ... errors=0
RTDS_ROOTPORT_PASS
```

若出现 `maximum delta`/`maxdeltaid` 错误，才确认有同一仿真时刻的 delta-cycle 风暴；若模拟时间持续推进但撞到 90 分钟墙钟超时，则重点定位该阶段的模型计算量或时钟周期等待。
