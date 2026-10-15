# open_xsim_gui

- Category: `pcie`
- Source: `R:\pcie_07\RTDS_test-1ch\RTDS_test-1ch\regression\sim_xdma_rootport\open_xsim_gui.ps1`
- SHA-256: `e78234d7da81ea524ff7c35f6df6d80c143431e2b48dadb956fde75e1f000d0f`
- Extractor: `text`
- Tags: `pcie, root-port, verification, xdma`
- Duplicate sources:
  - none

```powershell
param(
    [string]$TestName = "rtds_minimum",
    [string]$WdbName = "rtds_minimum_gui.wdb",
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin"
)

$ErrorActionPreference = "Stop"
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
```
