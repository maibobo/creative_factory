param(
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin",
    [switch]$NonzeroCardHi
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Resolve-Path (Join-Path $scriptDir "..\..\..")
$rtdsRtl = Join-Path $workspaceRoot "RTDS_test\RTDS_test.srcs\sources_1\new"
$bridgeRtl = Join-Path $workspaceRoot "fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new"
$vivadoRoot = Resolve-Path (Join-Path $VivadoBin "..")
$profile = if ($NonzeroCardHi) { "highaddr" } else { "base" }
$workDir = Join-Path $scriptDir "xsim_work_$profile"

$xvlog = Join-Path $VivadoBin "xvlog.bat"
$xelab = Join-Path $VivadoBin "xelab.bat"
$xsim = Join-Path $VivadoBin "xsim.bat"
$xpmCdc = Join-Path $vivadoRoot "data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv"
$xpmFifo = Join-Path $vivadoRoot "data\ip\xpm\xpm_fifo\hdl\xpm_fifo.sv"
$glbl = Join-Path $vivadoRoot "data\verilog\src\glbl.v"

$files = @(
    (Join-Path $scriptDir "rtds_test_pkg.sv"),
    (Join-Path $bridgeRtl "fdma_aurora_brg_tx.v"),
    (Join-Path $bridgeRtl "fdma_aurora_brg_rx.v"),
    (Join-Path $rtdsRtl "pcie_fdma_aurora_brg_adapter.v"),
    (Join-Path $scriptDir "xdma_rp_backend.sv"),
    (Join-Path $scriptDir "aurora_ll_peer_bfm.sv"),
    (Join-Path $scriptDir "rtds_scoreboard.sv"),
    (Join-Path $scriptDir "rtds_assertions.sv"),
    (Join-Path $scriptDir "tb_xdma_rtds_trythrough.sv"),
    $glbl
)

foreach ($file in @($xvlog, $xelab, $xsim, $xpmCdc, $xpmFifo) + $files) {
    if (!(Test-Path $file)) { throw "Missing simulation dependency: $file" }
}
if (Test-Path $workDir) { Remove-Item -LiteralPath $workDir -Recurse -Force }
New-Item -ItemType Directory -Path $workDir | Out-Null

Push-Location $workDir
try {
    & $xvlog -sv -work xpm $xpmCdc $xpmFifo
    if ($LASTEXITCODE -ne 0) { throw "XPM compile failed" }

    $defineArgs = @()
    if ($NonzeroCardHi) { $defineArgs = @("-d", "RTDS_TEST_NONZERO_CARD_HI") }
    & $xvlog -sv -L xpm -i $scriptDir @defineArgs -work work $files
    if ($LASTEXITCODE -ne 0) { throw "Testbench compile failed" }

    & $xelab -debug typical -L xpm work.tb_xdma_rtds_trythrough work.glbl -s rtds_trythrough_$profile
    if ($LASTEXITCODE -ne 0) { throw "Elaboration failed" }

    $runTcl = (Join-Path $scriptDir "run_all.tcl").Replace("\", "/")
    & $xsim "rtds_trythrough_$profile" -tclbatch $runTcl
    if ($LASTEXITCODE -ne 0) { throw "Simulation failed" }
} finally {
    Pop-Location
}
