param(
    [string]$VivadoBin = "D:\Xilinx_2020_2\Vivado\2020.2\bin",
    [switch]$SkipProjectUpdate,
    [switch]$Gui
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$workspaceRoot = Resolve-Path (Join-Path $projectRoot "..")
$rtdsRoot = Join-Path $projectRoot "RTDS_test.srcs\sources_1\new"
$brgRoot = Join-Path $workspaceRoot "fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new"
$workDir = Join-Path $projectRoot "xsim_top_bridge_work"
$vivadoRoot = Resolve-Path (Join-Path $VivadoBin "..")

$vivado = Join-Path $VivadoBin "vivado.bat"
$xvlog = Join-Path $VivadoBin "xvlog.bat"
$xelab = Join-Path $VivadoBin "xelab.bat"
$xsim = Join-Path $VivadoBin "xsim.bat"
$xpmCdc = Join-Path $vivadoRoot "data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv"
$xpmFifo = Join-Path $vivadoRoot "data\ip\xpm\xpm_fifo\hdl\xpm_fifo.sv"
$glbl = Join-Path $vivadoRoot "data\verilog\src\glbl.v"
$projectTcl = Join-Path $scriptDir "add_fdma_aurora_brg_to_rtds_project.tcl"

$files = @(
    $xpmCdc,
    $xpmFifo,
    (Join-Path $brgRoot "cdc_sync.v"),
    (Join-Path $brgRoot "fdma_aurora_brg_tx.v"),
    (Join-Path $brgRoot "fdma_aurora_brg_rx.v"),
    (Join-Path $brgRoot "fdma_aurora_brg_top.v"),
    (Join-Path $rtdsRoot "pcie_fdma_aurora_brg_adapter.v"),
    $glbl
)

foreach ($tool in @($vivado, $xvlog, $xelab, $xsim)) {
    if (!(Test-Path $tool)) { throw "Missing Vivado/XSim tool: $tool" }
}
foreach ($file in $files) {
    if (!(Test-Path $file)) { throw "Missing source file: $file" }
}

if (!$SkipProjectUpdate) {
    & $vivado -mode batch -source $projectTcl
    if ($LASTEXITCODE -ne 0) { throw "Vivado project update failed with exit code $LASTEXITCODE" }
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

$runTcl = Join-Path $workDir "run_elab_smoke.tcl"
Set-Content -Path $runTcl -Encoding ASCII -Value @"
run 1 ns
quit
"@
$runTclForXsim = $runTcl.Replace("\", "/")

Push-Location $workDir
try {
    & $xvlog -sv -work xpm $xpmCdc $xpmFifo
    if ($LASTEXITCODE -ne 0) { throw "xvlog xpm failed with exit code $LASTEXITCODE" }

    & $xvlog -sv -L xpm -work work $files[2..($files.Length - 1)]
    if ($LASTEXITCODE -ne 0) { throw "xvlog design failed with exit code $LASTEXITCODE" }

    & $xelab -debug typical -L xpm work.pcie_fdma_aurora_brg_adapter work.glbl -s pcie_fdma_aurora_brg_adapter_elab
    if ($LASTEXITCODE -ne 0) { throw "xelab failed with exit code $LASTEXITCODE" }

    if ($Gui) {
        & $xsim pcie_fdma_aurora_brg_adapter_elab -gui
    } else {
        & $xsim pcie_fdma_aurora_brg_adapter_elab -tclbatch $runTclForXsim
    }
    if ($LASTEXITCODE -ne 0) { throw "xsim failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
