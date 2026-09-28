param(
    [string]$TestName = "rtds_minimum",
    [string]$WdbName = "rtds_minimum_gui.wdb",
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin"
)

$ErrorActionPreference = "Stop"

# =============================================================================
# 用途：打开已经 xelab 完成的 board snapshot，供交互调试和手工 Run All。
# 输入：TestName、WdbName、VivadoBin；输出：新的 GUI WDB 和 XSim 窗口。
# 逻辑阶段：定位 snapshot → 生成 GUI 初始化 Tcl → 启动 xsim GUI。
# 失败定位：找不到 board.sh 表示未展开；层级/波形错误看 gui_init.tcl/waves.tcl；
# 本脚本不会修复过期 snapshot，RTL/TB 改动后必须重新 xelab。
# =============================================================================

$Xsim = Join-Path $VivadoBin "xsim.bat"
if (-not (Test-Path -LiteralPath $Xsim)) {
    throw "Vivado 2020.2 XSim not found: $Xsim"
}
$Root = $PSScriptRoot
$Export = Join-Path $Root "work\export"
$Logs = Join-Path $Root "logs"

# ---------- 语义段 1：定位已完成 xelab 的 board snapshot ----------
$RunDir = Get-ChildItem -LiteralPath $Export -Recurse -Filter "board.sh" |
    Select-Object -First 1 -ExpandProperty DirectoryName
if (-not $RunDir) {
    throw "export_simulation board.sh was not found; run run_xsim.ps1 first"
}
$Snapshot = Join-Path $RunDir "xsim.dir\board"
if (-not (Test-Path -LiteralPath $Snapshot)) {
    throw "XSim board snapshot was not found; complete xelab first"
}

# ---------- 语义段 2：用正确 TESTNAME 打开 XSim GUI，不自动关闭 ----------
New-Item -ItemType Directory -Path $Logs -Force | Out-Null
$Wdb = Join-Path $Logs $WdbName
$GuiLog = Join-Path $Logs "simulate_gui.log"

Push-Location $RunDir
try {
    # ---------- 语义段 2A：兼容层选择用例并加载波形 ----------
    # 当前已实现的 GUI 入口固定为 rtds_minimum；后续增加其他
    # TESTNAME 时，应同时扩展 gui_init.tcl 的参数化选择。
    if ($TestName -ne "rtds_minimum") {
        throw "Only rtds_minimum is implemented in the Vivado 2020.2 compatibility layer"
    }
    $GuiInitXsim = (Join-Path $Root "scripts\gui_init.tcl").Replace('\', '/')
    $WdbXsim = $Wdb.Replace('\', '/')
    $GuiLogXsim = $GuiLog.Replace('\', '/')
    & $Xsim "board" "-gui" `
        "-tclbatch" $GuiInitXsim `
        "-wdb" $WdbXsim "-log" $GuiLogXsim
    if ($LASTEXITCODE -ne 0) {
        throw "XSim GUI failed ($LASTEXITCODE)"
    }
} finally {
    Pop-Location
}
