param(
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin",
    [string]$WdbPath,
    [string]$WcfgPath
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：只读打开最终已验收 WDB/WCFG，不编译、不展开、不运行仿真。
# 输入：可选 VivadoBin、成对 WdbPath/WcfgPath；默认使用本机 Vivado 2020.2。
# 输出：启动 Vivado Waveform Viewer。
# 逻辑阶段：验证 Vivado → 选择 accepted final_wave_* → 校验文件 → 启动 GUI。
# 失败定位：无归档查 final_wave_acceptance.json；文件错配查显式参数；GUI 错误
# 查 scripts/open_final_wdb.tcl，而不是重新跑仿真。
# =============================================================================

$Root = $PSScriptRoot
$Logs = Join-Path $Root "logs"
$Vivado = Join-Path $VivadoBin "vivado.bat"
if (-not (Test-Path -LiteralPath $Vivado)) {
    throw "Vivado 2020.2 was not found: $Vivado"
}

# ---------- 语义段 1：检查显式参数或选择最终归档 ----------
# WDB/WCFG 必须成对提供；只传其中一个通常意味着把旧波形和新配置
# 错配，故在启动 Vivado 前直接报错。
$hasWdb = -not [string]::IsNullOrWhiteSpace($WdbPath)
$hasWcfg = -not [string]::IsNullOrWhiteSpace($WcfgPath)
if ($hasWdb -xor $hasWcfg) {
    throw "-WdbPath and -WcfgPath must be supplied together."
}

# 未指定路径时只从 final_wave_* 中挑选归档，不会误打开 logs 根目录中
if (-not $hasWdb -and -not $hasWcfg) {
    $candidate = Get-ChildItem -LiteralPath $Logs -Directory -Filter "final_wave_*" |
        Sort-Object LastWriteTime -Descending |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName "rtds_minimum.wdb")) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName "rtds_minimum.wcfg")) -and
            # final_wave_acceptance.json 是波形门禁输出；必须存在且 accepted=true，
            # 防止手工建立但尚未验收的 final_wave_* 目录被自动选中。
            (Test-Path -LiteralPath (Join-Path $_.FullName "final_wave_acceptance.json")) -and
            ((Get-Content -LiteralPath (Join-Path $_.FullName "final_wave_acceptance.json") -Raw | ConvertFrom-Json).accepted -eq $true)
        } |
        Select-Object -First 1
    if (-not $candidate) {
        throw "No accepted final_wave_* archive containing both WDB and WCFG was found."
    }
    $WdbPath = Join-Path $candidate.FullName "rtds_minimum.wdb"
    $WcfgPath = Join-Path $candidate.FullName "rtds_minimum.wcfg"
}

if (-not [IO.Path]::IsPathRooted($WdbPath)) {
    $WdbPath = Join-Path $Root $WdbPath
}
if (-not [IO.Path]::IsPathRooted($WcfgPath)) {
    $WcfgPath = Join-Path $Root $WcfgPath
}
$WdbPath = [IO.Path]::GetFullPath($WdbPath)
$WcfgPath = [IO.Path]::GetFullPath($WcfgPath)
foreach ($artifact in @($WdbPath, $WcfgPath)) {
    if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) {
        throw "Waveform artifact was not found: $artifact"
    }
    if ((Get-Item -LiteralPath $artifact).Length -eq 0) {
        throw "Waveform artifact is empty: $artifact"
    }
}

# ---------- 语义段 2：仅启动 Vivado 波形查看器 ----------
# 该入口只执行 open_wave_database/open_wave_config，不调用 run、xelab 或
# 任何综合步骤；关闭 Viewer 不会修改仿真结果。
$viewerTcl = Join-Path $Root "scripts\open_final_wdb.tcl"
Write-Host "RTDS_OPEN_WDB_COMMAND: `"$Vivado`" -mode gui -source `"$viewerTcl`" -tclargs `"$WdbPath`" `"$WcfgPath`""
& $Vivado -mode gui -source $viewerTcl -tclargs $WdbPath $WcfgPath
exit $LASTEXITCODE
