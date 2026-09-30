param(
    [string]$Testcase = "tc_brg_wr_ready_stall",
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin"
)

$ErrorActionPreference = "Stop"

$directBridgeTests = @(
    "tc_brg_rd_ready_stall",
    "tc_brg_wr_ready_stall",
    "tc_brg_tx_fifo_waterline",
    "tc_brg_rx_fifo_overflow"
)
if ($directBridgeTests -notcontains $Testcase) {
    throw "This direct XSim script supports only direct bridge tests: $($directBridgeTests -join ', ')"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loopRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $loopRoot "..\..")
$sourceDir = Join-Path $loopRoot "new"
$tcDir = Join-Path $sourceDir "tc"
$harnessDir = Join-Path $sourceDir "harness"
$workDir = Join-Path $projectRoot "xsim_bridge_tc_work"
$vivadoRoot = Resolve-Path (Join-Path $VivadoBin "..")

$xvlog = Join-Path $VivadoBin "xvlog.bat"
$xelab = Join-Path $VivadoBin "xelab.bat"
$xsim = Join-Path $VivadoBin "xsim.bat"
$xpmCdc = Join-Path $vivadoRoot "data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv"
$xpmFifo = Join-Path $vivadoRoot "data\ip\xpm\xpm_fifo\hdl\xpm_fifo.sv"
$glbl = Join-Path $vivadoRoot "data\verilog\src\glbl.v"

$files = @(
    $xpmCdc,
    $xpmFifo,
    (Join-Path $sourceDir "cdc_sync.v"),
    (Join-Path $sourceDir "fdma_aurora_brg_tx.v"),
    (Join-Path $sourceDir "fdma_aurora_brg_rx.v"),
    (Join-Path $sourceDir "fdma_aurora_brg_top.v"),
    $glbl,
    (Join-Path $tcDir "tc_if.sv"),
    (Join-Path $tcDir "tc_base.sv"),
    (Join-Path $harnessDir "brg_harness.sv"),
    (Join-Path $tcDir "$Testcase.sv")
)

foreach ($tool in @($xvlog, $xelab, $xsim)) {
    if (!(Test-Path $tool)) { throw "Missing XSim tool: $tool" }
}
foreach ($file in $files) {
    if (!(Test-Path $file)) { throw "Missing source file: $file" }
}

$resolvedProjectRoot = (Resolve-Path $projectRoot).Path
$workDirParent = Split-Path -Parent $workDir
if ((Resolve-Path $workDirParent).Path -ne $resolvedProjectRoot) {
    throw "Refusing to clean unexpected work directory: $workDir"
}
if (Test-Path $workDir) {
    Remove-Item -LiteralPath $workDir -Recurse -Force
}
New-Item -ItemType Directory -Path $workDir | Out-Null

$top = "${Testcase}_top"
$snapshot = "${Testcase}_sim"
$runTcl = Join-Path $workDir "run_all.tcl"
Set-Content -Path $runTcl -Encoding ASCII -Value @"
run all
quit
"@
$runTclForXsim = $runTcl.Replace("\", "/")

Push-Location $workDir
try {
    & $xvlog -sv -work xpm $xpmCdc $xpmFifo
    if ($LASTEXITCODE -ne 0) { throw "xvlog xpm failed with exit code $LASTEXITCODE" }

    & $xvlog -sv -L xpm -work work $files[2..($files.Length - 1)]
    if ($LASTEXITCODE -ne 0) { throw "xvlog design failed with exit code $LASTEXITCODE" }

    & $xelab -debug typical -L xpm "work.$top" work.glbl -s $snapshot
    if ($LASTEXITCODE -ne 0) { throw "xelab failed with exit code $LASTEXITCODE" }

    & $xsim $snapshot --tclbatch $runTclForXsim
    if ($LASTEXITCODE -ne 0) { throw "xsim failed with exit code $LASTEXITCODE" }

    $xsimLog = Join-Path $workDir "xsim.log"
    if (!(Test-Path $xsimLog)) { throw "xsim.log was not generated" }
    $failLine = Select-String -Path $xsimLog -Pattern "failed|TEST FAIL|Error:|Fatal:" -Quiet
    if ($failLine) {
        throw "XSim reported a failure. Inspect $xsimLog"
    }
} finally {
    Pop-Location
}
