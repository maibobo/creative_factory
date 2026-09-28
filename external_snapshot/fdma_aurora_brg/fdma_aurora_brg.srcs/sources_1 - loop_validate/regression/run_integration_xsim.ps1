param(
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin",
    [switch]$Gui
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loopRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectRoot = Resolve-Path (Join-Path $loopRoot "..\..")
$workspaceRoot = Resolve-Path (Join-Path $loopRoot "..\..\..")
$sourceDir = Join-Path $loopRoot "new"
$integrationDir = Join-Path $sourceDir "integration"
$workDir = Join-Path $projectRoot "xsim_integration_work"
$vivadoRoot = Resolve-Path (Join-Path $VivadoBin "..")

$xvlog = Join-Path $VivadoBin "xvlog.bat"
$xelab = Join-Path $VivadoBin "xelab.bat"
$xsim = Join-Path $VivadoBin "xsim.bat"
$xpmCdc = Join-Path $vivadoRoot "data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv"
$xpmFifo = Join-Path $vivadoRoot "data\ip\xpm\xpm_fifo\hdl\xpm_fifo.sv"
$glbl = Join-Path $vivadoRoot "data\verilog\src\glbl.v"
$convDma = Join-Path $workspaceRoot "RTDS_test\RTDS_test.srcs\sources_1\new\CONV_DMA.v"

$files = @(
    $xpmCdc,
    $xpmFifo,
    (Join-Path $sourceDir "cdc_sync.v"),
    (Join-Path $sourceDir "fdma_aurora_brg_tx.v"),
    (Join-Path $sourceDir "fdma_aurora_brg_rx.v"),
    (Join-Path $sourceDir "fdma_aurora_brg_top.v"),
    (Join-Path $sourceDir "fdma_aurora_pcie_conv_dma_wrapper.v"),
    $glbl,
    $convDma,
    (Join-Path $integrationDir "axi_ram_model.sv"),
    (Join-Path $integrationDir "tb_fdma_aurora_brg_conv_dma_integration.sv")
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

    & $xelab -debug typical -L xpm work.tb_fdma_aurora_brg_conv_dma_integration work.glbl -s tb_fdma_aurora_brg_conv_dma_integration_sim
    if ($LASTEXITCODE -ne 0) { throw "xelab failed with exit code $LASTEXITCODE" }

    if ($Gui) {
        & $xsim tb_fdma_aurora_brg_conv_dma_integration_sim -gui
    } else {
        & $xsim tb_fdma_aurora_brg_conv_dma_integration_sim -tclbatch $runTclForXsim
    }
    if ($LASTEXITCODE -ne 0) { throw "xsim failed with exit code $LASTEXITCODE" }

    $xsimLog = Join-Path $workDir "xsim.log"
    if (!(Test-Path $xsimLog)) { throw "xsim.log was not generated" }
    $passLine = Select-String -Path $xsimLog -Pattern "TEST PASS: fdma_aurora_brg CONV_DMA integration" -SimpleMatch -Quiet
    $failLine = Select-String -Path $xsimLog -Pattern "TEST FAIL|Error:|Fatal:" -Quiet
    if (!$passLine -or $failLine) {
        throw "XSim did not report a clean TEST PASS. Inspect $xsimLog"
    }
} finally {
    Pop-Location
}
