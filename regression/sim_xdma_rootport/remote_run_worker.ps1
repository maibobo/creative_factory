param(
    [string]$VivadoBin = "C:\Xilinx\Vivado\2020.2\bin",
    [ValidateSet("off", "auto", "2", "3", "4")]
    [string]$XelabMt = "auto"
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：远端独立 PowerShell 工作器，调用 run_xsim.ps1 并记录退出码/控制台结果。
# 输入：远端 VivadoBin 和 xelab 多线程选项。
# 输出：remote_run_console/stderr.log、remote_worker_result.json。
# 逻辑阶段：准备日志 → 启动子进程 → 等待退出 → 写机器可读结果。
# 失败定位：无 console 日志查子进程启动；exit 非零先看 stderr，再看仿真 summary。
# =============================================================================

$Root = $PSScriptRoot
$Logs = Join-Path $Root "logs"
New-Item -ItemType Directory -Path $Logs -Force | Out-Null

# ---------- 语义段 1：在独立 PowerShell 进程中运行完整回归 ----------
# run_xsim.ps1 末尾会 exit，因此 worker 必须用子进程获取退出码，
# 不能在当前会话直接调用。
$RunScript = Join-Path $Root "run_xsim.ps1"
$ConsoleLog = Join-Path $Logs "remote_run_console.log"
$ErrorLog = Join-Path $Logs "remote_run_stderr.log"
$ResultJson = Join-Path $Logs "remote_worker_result.json"
$StartedAt = Get-Date

$arguments = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $RunScript,
    "-SkipAudit",
    "-SkipPrepare",
    "-VivadoBin", $VivadoBin,
    "-XelabMt", $XelabMt
)

$exitCode = 255
$failure = $null
try {
    $child = Start-Process -FilePath "powershell.exe" `
        -ArgumentList $arguments `
        -RedirectStandardOutput $ConsoleLog `
        -RedirectStandardError $ErrorLog `
        -WindowStyle Hidden -Wait -PassThru
    $exitCode = $child.ExitCode
} catch {
    $failure = $_.Exception.Message
    Add-Content -LiteralPath $ErrorLog -Value $failure
}

# ---------- 语义段 2：生成机器可读的远端完成标记 ----------
[ordered]@{
    started_at = $StartedAt.ToString("o")
    finished_at = (Get-Date).ToString("o")
    vivado_bin = $VivadoBin
    xelab_mt = $XelabMt
    exit_code = $exitCode
    failure = $failure
    console_log = $ConsoleLog
    error_log = $ErrorLog
} | ConvertTo-Json | Set-Content -LiteralPath $ResultJson -Encoding UTF8

exit $exitCode
