param(
    [Parameter(Mandatory = $true)]
    [string]$SimulationLog,
    [string]$Whitelist,
    [string]$SummaryJson,
    [string[]]$AdditionalLogs = @()
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：按语义里程碑验收仿真日志，并对 warning 做精确白名单比较。
# 输入：simulate.log、白名单、可选 prepare 等附加日志。
# 逻辑阶段：读取输入 → 检查 PASS/错误词 → 提取 warning → 精确比对白名单 → 摘要。
# 失败定位：missing_milestones 查用例；fatal/error 查首个原句；unexpected_warnings
# 必须逐条处理，禁止模糊放行。
# =============================================================================

# Windows PowerShell 5.1 在 param 默认值绑定阶段可能尚未设置 $PSScriptRoot。
# 路径必须在脚本正文开始后求值，否则仿真已经 PASS 仍会被包装脚本误标为失败。
if ([string]::IsNullOrWhiteSpace($Whitelist)) {
    $Whitelist = Join-Path $PSScriptRoot "..\config\warning_whitelist.txt"
}
if ([string]::IsNullOrWhiteSpace($SummaryJson)) {
    $SummaryJson = Join-Path $PSScriptRoot "..\logs\summary.json"
}

# ---------- 语义段 1：读取仿真日志和各构建阶段日志 ----------
$lines = Get-Content -LiteralPath $SimulationLog
$logDirectory = Split-Path -Parent $SimulationLog
if ($AdditionalLogs.Count -eq 0) {
    $AdditionalLogs = @(
        "audit_and_prepare.log",
        "prepare_rootport_sim.log",
        "xvlog.log",
        "xvhdl.log",
        "xelab.log"
    ) | ForEach-Object { Join-Path $logDirectory $_ }
}

$logFiles = @($SimulationLog) + @($AdditionalLogs) |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -Unique

$patterns = Get-Content -LiteralPath $Whitelist |
    Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") }

$warningRecords = foreach ($logFile in $logFiles) {
    $phase = [IO.Path]::GetFileName($logFile)
    foreach ($line in (Get-Content -LiteralPath $logFile)) {
        if ($line -match "^(CRITICAL )?WARNING:") {
            [pscustomobject]@{ phase = $phase; line = $line }
        }
    }
}

$unexpectedWarnings = foreach ($warningRecord in $warningRecords) {
    $matched = $false
    foreach ($pattern in $patterns) {
        if ($warningRecord.line -match $pattern) { $matched = $true; break }
    }
    if (-not $matched) { "[$($warningRecord.phase)] $($warningRecord.line)" }
}

# ---------- 语义段 2：只比较语义里程碑，不比较时间戳和临时路径 ----------
$milestones = [ordered]@{
    link             = [bool]($lines -match "RTDS_LINK_PASS: Gen3 x2")
    bar              = [bool]($lines -match "RTDS_BAR_MAP:")
    msi_config       = [bool]($lines -match "RTDS_MSI_CONFIG_PASS:")
    user_irq_enable  = [bool]($lines -match "RTDS_XDMA_USER_IRQ_ENABLE_PASS:")
    base_dma         = [bool]($lines -match "RTDS_BASE_DMA_PASS: H2C\+C2H 512 bytes")
    cpu_to_aurora    = [bool]($lines -match "RTDS_CPU_TO_AURORA_PASS: 512 bytes")
    aurora_to_cpu    = [bool]($lines -match "RTDS_AURORA_TO_CPU_PASS: 512 bytes")
    result_zero      = [bool]($lines -match "RTDS_ROOTPORT_RESULT .* errors=0")
    pass_marker      = [bool]($lines -match "^RTDS_ROOTPORT_PASS$")
}

# XSim 对 `$error`/`$fatal` 的运行时前缀是 `Error:`/`Fatal:`（首字母大写）；
# `error` 搜索，避免把 XSim 回显的 Tcl 源码 `### error "..."` 误当成运行时失败。
$simulationFatalLines = $lines | Where-Object {
    (($_ -match "^(Error|Fatal):") -or
     ($_ -cmatch "\b(ERROR|FATAL|MISMATCH|TIMEOUT)\b")) -and
    $_ -notmatch "RTDS_ROOTPORT_RESULT .* errors=0"
}
$buildFatalLines = foreach ($logFile in $logFiles) {
    if ((Resolve-Path -LiteralPath $logFile).Path -eq (Resolve-Path -LiteralPath $SimulationLog).Path) {
        continue
    }
    $phase = [IO.Path]::GetFileName($logFile)
    foreach ($line in (Get-Content -LiteralPath $logFile)) {
        if ($line -match "^(ERROR:|FATAL:|RTDS_(AUDIT|PREPARE)_ERROR:)") {
            "[$phase] $line"
        }
    }
}
$fatalLines = @($simulationFatalLines) + @($buildFatalLines)

$passed = -not ($milestones.Values -contains $false) -and
          @($unexpectedWarnings).Count -eq 0 -and @($fatalLines).Count -eq 0

$summary = [ordered]@{
    log = (Resolve-Path -LiteralPath $SimulationLog).Path
    scanned_logs = @($logFiles | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
    passed = $passed
    milestones = $milestones
    warning_count = @($warningRecords).Count
    warnings_by_phase = @($warningRecords | Group-Object phase | ForEach-Object {
        [pscustomobject]@{ phase = $_.Name; count = $_.Count }
    })
    unexpected_warnings = @($unexpectedWarnings)
    fatal_lines = @($fatalLines)
}
$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $SummaryJson -Encoding UTF8

if ($passed) {
    Write-Host "RTDS_LOG_COMPARE_PASS: 语义里程碑、错误扫描和 warning 白名单均通过"
    exit 0
}

Write-Error "RTDS_LOG_COMPARE_FAIL: 请检查 $SummaryJson"
exit 1
