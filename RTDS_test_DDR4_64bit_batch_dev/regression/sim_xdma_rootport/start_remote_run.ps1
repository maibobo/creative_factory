param(
    [string]$VivadoBin = "C:\Xilinx\Vivado\2020.2\bin",
    [ValidateSet("off", "auto", "2", "3", "4")]
    [string]$XelabMt = "auto"
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：在保持当前远程会话时启动后台 worker，并防止同一目录重复运行。
# 输入：VivadoBin、XelabMt；输出：remote_worker.pid 和 worker 日志。
# 逻辑阶段：检查旧 PID → 启动 remote_run_worker → 保存新 PID。
# 失败定位：PID 冲突先确认旧进程；正式断联长任务优先用 launch_breakaway.ps1。
# =============================================================================

$Root = $PSScriptRoot
$Logs = Join-Path $Root "logs"
New-Item -ItemType Directory -Path $Logs -Force | Out-Null
$PidFile = Join-Path $Logs "remote_worker.pid"

# ---------- 语义段 1：防止在同一运行目录重复启动 ----------
if (Test-Path -LiteralPath $PidFile) {
    $oldPid = (Get-Content -LiteralPath $PidFile -Raw).Trim()
    if ($oldPid -match "^\d+$" -and (Get-Process -Id ([int]$oldPid) -ErrorAction SilentlyContinue)) {
        throw "Remote regression is already running: PID=$oldPid"
    }
}

# ---------- 语义段 2：脱离 SSH 前台启动 worker ----------
$Worker = Join-Path $Root "remote_run_worker.ps1"
$SupervisorOut = Join-Path $Logs "remote_supervisor_stdout.log"
$SupervisorErr = Join-Path $Logs "remote_supervisor_stderr.log"
$arguments = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $Worker,
    "-VivadoBin", $VivadoBin,
    "-XelabMt", $XelabMt
)
$process = Start-Process -FilePath "powershell.exe" `
    -ArgumentList $arguments `
    -RedirectStandardOutput $SupervisorOut `
    -RedirectStandardError $SupervisorErr `
    -WindowStyle Hidden -PassThru
$process.Id | Set-Content -LiteralPath $PidFile -Encoding ASCII

Write-Output "REMOTE_RUN_STARTED PID=$($process.Id) MT=$XelabMt ROOT=$Root"
