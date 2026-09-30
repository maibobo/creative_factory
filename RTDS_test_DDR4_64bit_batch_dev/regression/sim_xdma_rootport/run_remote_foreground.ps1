param(
    [string]$VivadoBin = "C:\Xilinx\Vivado\2020.2\bin",
    [ValidateSet("off", "auto", "2", "3", "4")]
    [string]$XelabMt = "auto"
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：通过 SSH 前台运行已有 snapshot 的回归，适合实时观察短任务。
# 输入：远端 VivadoBin、XelabMt；输出：前台摘要和完整远端日志。
# 逻辑阶段：准备日志 → 调 run_xsim SkipAudit/SkipPrepare → 透传退出码。
# 失败定位：SSH 断开会影响本入口；需要断联安全运行时使用 launch_breakaway。
# =============================================================================

$Root = $PSScriptRoot
$Logs = Join-Path $Root "logs"
New-Item -ItemType Directory -Path $Logs -Force | Out-Null

# ---------- 语义段 1：SSH 前台持久运行入口 ----------
# 直接用 -File 调用本脚本，避免 Windows OpenSSH 的嵌套
# -Command 引号吞掉 VivadoBin。完整 Vivado 输出只写入远端日志。
$ConsoleLog = Join-Path $Logs "remote_foreground_console.log"
Write-Output "REMOTE_FOREGROUND_CONFIG VivadoBin=<$VivadoBin> XelabMt=<$XelabMt>"
& (Join-Path $Root "run_xsim.ps1") `
    -SkipAudit -SkipPrepare `
    -VivadoBin $VivadoBin `
    -XelabMt $XelabMt *> $ConsoleLog
