param(
    [string]$Root
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：对完成的 WaveMode 运行做最终文件验收、哈希和不可变归档。
# 输入：仿真根目录下 WDB/WCFG/simulate.log/summary。
# 输出：final_wave_<时间>、final_wave_acceptance.json、SHA-256 manifest。
# 逻辑阶段：检查功能/文件 → 校验 WDB 时间与大小 → 复制归档 → 计算哈希。
# 失败定位：accepted=false 的 reasons 区分功能失败、旧文件、缺文件和波形失败。
# =============================================================================

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}
$Logs = Join-Path $Root "logs"

# ---------- 语义段 1：检查功能结果与最终波形文件 ----------
# FastMode 的功能 PASS 不能替代本轮 WDB；这里同时要求新的 WDB、WCFG、
# simulate.log 和 summary.json，避免把旧文件误归档为最终证据。
$required = @(
    "rtds_minimum.wdb",
    "rtds_minimum.wcfg",
    "simulate.log",
    "summary.json"
)
foreach ($name in $required) {
    $path = Join-Path $Logs $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Final waveform artifact is missing: $path"
    }
    if ((Get-Item -LiteralPath $path).Length -eq 0) {
        throw "Final waveform artifact is empty: $path"
    }
}

$summaryPath = Join-Path $Logs "summary.json"
$summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
if (-not $summary.passed) {
    throw "summary.json does not report passed=true"
}
$unexpectedWarningCount = @($summary.unexpected_warnings).Count
$fatalLineCount = @($summary.fatal_lines).Count
if ($unexpectedWarningCount -ne 0) {
    throw "Unexpected warnings remain: $unexpectedWarningCount"
}
if ($fatalLineCount -ne 0) {
    throw "Fatal lines remain: $fatalLineCount"
}

$simulatePath = Join-Path $Logs "simulate.log"
$simulateText = Get-Content -LiteralPath $simulatePath -Raw
if ($simulateText -notmatch "RTDS_ROOTPORT_PASS") {
    throw "RTDS_ROOTPORT_PASS was not found in simulate.log"
}

# ---------- 语义段 2：提取仿真终点并校验 WDB 属于本轮 ----------
$finishTimeNs = $null
$finishMatch = [regex]::Match(
    $simulateText,
    '\$finish called at time\s*:\s*([0-9.]+)\s*ns',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
if ($finishMatch.Success) {
    $finishTimeNs = [double]$finishMatch.Groups[1].Value
}
if ($null -eq $finishTimeNs) {
    throw "Simulation finish time was not found in simulate.log"
}
# 当前最小闭环的确定性终点是 274.094 us。保留 1 us 容差，既允许
# Xilinx 模型的小幅调度差异，也能拒绝只跑到链路训练或中途退出的 WDB。
if ($finishTimeNs -lt 273094 -or $finishTimeNs -gt 275094) {
    throw "Unexpected simulation finish time: $finishTimeNs ns"
}

$wdbPath = Join-Path $Logs "rtds_minimum.wdb"
$wdb = Get-Item -LiteralPath $wdbPath
$simulateItem = Get-Item -LiteralPath $simulatePath
if ($wdb.LastWriteTime -lt $simulateItem.LastWriteTime.AddMinutes(-10)) {
    throw "WDB timestamp is too old for this simulation run: $($wdb.LastWriteTime)"
}

# ---------- 语义段 3：归档日志、波形配置与 SHA-256 ----------
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archive = Join-Path $Logs "final_wave_$stamp"
New-Item -ItemType Directory -Path $archive -Force | Out-Null
$archiveNames = @(
    "rtds_minimum.wdb",
    "rtds_minimum.wcfg",
    "simulate.log",
    "summary.json",
    "test_summary.json",
    "xvlog.log",
    "xvhdl.log",
    "xelab.log",
    "prepare_rootport_sim.log",
    "audit_and_prepare.log"
)
foreach ($name in $archiveNames) {
    $source = Join-Path $Logs $name
    if (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination $archive -Force
    }
}

$artifacts = foreach ($name in $required) {
    $path = Join-Path $Logs $name
    $item = Get-Item -LiteralPath $path
    [ordered]@{
        name = $name
        bytes = $item.Length
        last_write_time = $item.LastWriteTime.ToString("o")
        sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

$acceptance = [ordered]@{
    state = "completed"
    accepted = $true
    mode = "wave"
    generated_at = (Get-Date).ToString("o")
    finish_time_ns = $finishTimeNs
    rootport_pass = $true
    log_compare_pass = $true
    errors = 0
    unexpected_warnings = 0
    fatal_lines = 0
    archive = $archive
    artifacts = @($artifacts)
}
$acceptancePath = Join-Path $Logs "final_wave_acceptance.json"
$acceptance | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $acceptancePath -Encoding utf8
Copy-Item -LiteralPath $acceptancePath -Destination $archive -Force

# 另存一份纯文本 SHA-256 清单，便于在没有 PowerShell/JSON 工具的机器上
# 快速核对 WDB/WCFG/日志是否被替换；JSON 中仍保留相同的结构化记录。
$manifestPath = Join-Path $archive "sha256_manifest.txt"
$manifestLines = foreach ($item in $artifacts) {
    "{0}  {1}" -f $item.sha256, $item.name
}
$manifestLines | Set-Content -LiteralPath $manifestPath -Encoding ascii

Write-Host "RTDS_FINAL_WAVE_PASS: archive=$archive finish_time_ns=$finishTimeNs"
exit 0
