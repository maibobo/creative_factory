$ErrorActionPreference = 'Stop'
$root = 'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev'
$reportDir = Join-Path $root 'reports\impl_20260920_retry'
$runDir = [System.IO.Path]::GetFullPath((Join-Path $root 'RTDS_test_DDR4_64bit.runs\synth_1'))
$rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
if (-not $runDir.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Unexpected run directory: $runDir"
}

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$statusFile = Join-Path $reportDir 'worker_status.txt'
$pidFile = Join-Path $reportDir 'worker.pid'
$oldLogDir = Join-Path $root 'reports\impl_20260920_attempt1_interrupted'
New-Item -ItemType Directory -Force -Path $oldLogDir | Out-Null

# Preserve the interrupted attempt, then remove only its stale running marker.
foreach ($name in @('runme.log', 'vivado.jou', 'vivado.pb', 'TOP.vds')) {
    $source = Join-Path $runDir $name
    if (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination $oldLogDir -Force
    }
}
$staleMarker = Join-Path $runDir '__synthesis_is_running__'
if (Test-Path -LiteralPath $staleMarker) {
    Remove-Item -LiteralPath $staleMarker -Force
}

$PID | Set-Content -LiteralPath $pidFile -Encoding ASCII
"STARTED=$(Get-Date -Format o)`r`nPID=$PID" | Set-Content -LiteralPath $statusFile -Encoding UTF8

$vivado = 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat'
$tcl = Join-Path $root 'scripts\run_synth_impl_retry_20260920.tcl'
$log = Join-Path $reportDir 'vivado.log'
$journal = Join-Path $reportDir 'vivado.jou'
$console = Join-Path $reportDir 'console.log'

try {
    & $vivado -mode batch -source $tcl -log $log -journal $journal 2>&1 |
        Tee-Object -FilePath $console
    $exitCode = $LASTEXITCODE
    "FINISHED=$(Get-Date -Format o)`r`nPID=$PID`r`nEXIT=$exitCode" |
        Set-Content -LiteralPath $statusFile -Encoding UTF8
    exit $exitCode
} catch {
    "FAILED=$(Get-Date -Format o)`r`nPID=$PID`r`nERROR=$($_.Exception.Message)" |
        Set-Content -LiteralPath $statusFile -Encoding UTF8
    throw
}
