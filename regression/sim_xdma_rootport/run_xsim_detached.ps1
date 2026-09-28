param(
    [string]$VivadoBin = "C:\Xilinx\Vivado\2020.2\bin",
    [int]$WallClockTimeoutMinutes = 120,
    [switch]$RebuildSnapshot,
    [switch]$ReuseWaveSnapshot,
    [switch]$WaveMode
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：执行 FastMode 或 WaveMode 回归，并用墙钟 watchdog 管理 Vivado/XSim。
# 输入：VivadoBin、重建/复用模式、WaveMode 和超时分钟数。
# 输出：detached_status.json、控制台日志、summary；WaveMode 还输出 WDB/WCFG。
# 逻辑阶段：参数互斥检查 → 组装 run_xsim → 启动/监控 → 超时回收 → 最终验收。
# 失败定位：state/exit_code 看包装层；RTDS_ROOTPORT_PASS/summary 看功能层；
# WaveMode 归档失败看 finalize_wave_run.ps1。
# =============================================================================

if ($RebuildSnapshot -and $ReuseWaveSnapshot) {
    throw "-RebuildSnapshot and -ReuseWaveSnapshot are mutually exclusive."
}
if ($WaveMode -and -not $RebuildSnapshot -and -not $ReuseWaveSnapshot) {
    throw "-WaveMode requires -RebuildSnapshot, unless the current snapshot was already built in WaveMode and -ReuseWaveSnapshot is explicit."
}
$Root = $PSScriptRoot
$Logs = Join-Path $Root "logs"
New-Item -ItemType Directory -Path $Logs -Force | Out-Null

# ---------- 语义段 1：独立运行标识 ----------
# 本脚本由 WMI/Task Scheduler 启动，不依赖发起它的 SSH 会话。
# 每次运行使用独立 console/status 文件，便于重新连接后判断是否仍在运行。
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$console = Join-Path $Logs "detached_console_$stamp.log"
$errorLog = Join-Path $Logs "detached_console_$stamp.err.log"
$statusFile = Join-Path $Logs "detached_status.json"
$pidFile = Join-Path $Logs "detached_launcher.pid"
Set-Content -LiteralPath $pidFile -Value $PID -Encoding ascii

$status = [ordered]@{
    state = "running"
    launcher_pid = $PID
    start_time = (Get-Date).ToString("o")
    end_time = $null
    exit_code = $null
    mode = if ($WaveMode) { "wave" } else { "fast" }
    console = $console
    error_log = $errorLog
}
$status | ConvertTo-Json | Set-Content -LiteralPath $statusFile -Encoding utf8

# ---------- 语义段 2：选择重建 snapshot 或只运行功能仿真 ----------
# tests.vh/board.sv/IP/xelab 参数变化时使用 -RebuildSnapshot；否则跳过
# 编译和展开。run_xsim.ps1 自身负责 maxdeltaid、墙钟超时、日志归档和语义比对。
$exitCode = 1
try {
    $runArguments = @(
        "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $Root "run_xsim.ps1"),
        "-SkipAudit",
        "-VivadoBin", $VivadoBin,
        "-XsimMaxDeltaId", "10000",
        "-WallClockTimeoutMinutes", "$WallClockTimeoutMinutes"
    )
    if (-not $WaveMode) {
        # 默认仍是已经验证过的快速回归模式，保持旧命令兼容。
        $runArguments += "-FastMode"
    }
    if ($RebuildSnapshot) {
        # RTL/testbench 变化时必须重新导出 fileset；否则新加入的 monitor 不会
        # 进入 vlog.prj，即使随后重新 xvlog/xelab 也仍会使用旧源码清单。
        if ($WaveMode) {
            # 精选波形模式保留 typical 可见性并使用 O2，避免 O3/debug off
            # 优化掉 waves.tcl 指定的内部事务与状态信号。
            # 2020.2 Windows 版 xelab --mt auto 曾在静态展开后的 native
            # module 编译阶段触发 XSIM 43-3294（堆损坏/访问冲突）。因此波形
            # 证据优先使用稳定的单线程展开；这不影响 xsimk 的运行时 CPU 利用。
            $runArguments += @(
                "-XelabMt", "off",
                "-XelabDebug", "typical",
                "-XelabOptimize", "2"
            )
        } else {
            # FastMode 也固定关闭 xelab 多线程，避免复现历史 43-3294；
            # 若需实验多线程，应在独立副本显式运行，不作为验收门禁。
            $runArguments += @("-XelabMt", "off", "-XelabOptimize", "3")
        }
    } elseif ($ReuseWaveSnapshot) {
        # 仅适用于刚刚以 WaveMode 成功生成 snapshot、但运行期 Tcl/WCFG
        # 配置失败的重试。HDL/TB、include 或 xelab 参数有变化时禁止复用。
        $runArguments += @("-SkipPrepare", "-SkipCompile", "-SkipElaborate")
    } else {
        $runArguments += @("-SkipPrepare", "-SkipCompile", "-SkipElaborate")
    }
    & powershell.exe @runArguments 1> $console 2> $errorLog
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0 -and $WaveMode) {
        # 功能比较通过后再检查 WDB/WCFG，并生成带哈希的最终证据归档。
        & powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass `
            -File (Join-Path $Root "scripts\finalize_wave_run.ps1") `
            -Root $Root 1>> $console 2>> $errorLog
        $exitCode = $LASTEXITCODE
    }
} catch {
    $_ | Out-String | Add-Content -LiteralPath $errorLog
    $exitCode = 1
} finally {
    $status.state = if ($exitCode -eq 0) { "completed" } else { "failed" }
    $status.end_time = (Get-Date).ToString("o")
    $status.exit_code = $exitCode
    $status | ConvertTo-Json | Set-Content -LiteralPath $statusFile -Encoding utf8
}

exit $exitCode
