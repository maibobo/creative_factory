$ErrorActionPreference = 'Stop'
$root = 'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev'
$reportDir = Join-Path $root 'reports\rootport_concurrent_20260920'
$statusFile = Join-Path $reportDir 'worker_status.txt'
$pidFile = Join-Path $reportDir 'worker.pid'
$vivado = 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat'
$tcl = Join-Path $root 'scripts\resume_rootport_v201_step2.tcl'
$log = Join-Path $reportDir 'vivado.log'
$journal = Join-Path $reportDir 'vivado.jou'
$console = Join-Path $reportDir 'console.log'

New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$PID | Set-Content -LiteralPath $pidFile -Encoding ASCII
('STARTED=' + (Get-Date -Format o) + "`r`nPID=" + $PID) |
    Set-Content -LiteralPath $statusFile -Encoding ASCII

try {
    & $vivado -mode batch -source $tcl -log $log -journal $journal 2>&1 |
        Tee-Object -FilePath $console
    $exitCode = $LASTEXITCODE
    ('FINISHED=' + (Get-Date -Format o) + "`r`nPID=" + $PID + "`r`nEXIT=" + $exitCode) |
        Set-Content -LiteralPath $statusFile -Encoding ASCII
    exit $exitCode
} catch {
    ('FAILED=' + (Get-Date -Format o) + "`r`nPID=" + $PID + "`r`nERROR=" + $_.Exception.Message) |
        Set-Content -LiteralPath $statusFile -Encoding ASCII
    throw
}
