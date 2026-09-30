#requires -version 5.0
[CmdletBinding()]
param(
    [ValidateSet('1g','tx','rx_fifo','ring','axi','axi_tail','regs')]
    [string]$Case = 'tx',
    [switch]$Vivado
)
$ErrorActionPreference = 'Stop'
$vivadoExe = 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat'
$root = Split-Path -Parent $PSScriptRoot
$caseDir = Join-Path $root ('evidence\local_wave_sessions\' + $Case)
$entry = Join-Path $PSScriptRoot 'open_local_wave_session.tcl'
if (-not $Vivado) {
    $html = Join-Path $caseDir ($Case + '_viewer.html')
    if (-not (Test-Path -LiteralPath $html -PathType Leaf)) { throw "Offline viewer is missing: $html" }
    $edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
    if (Test-Path -LiteralPath $edge) {
        $uri = ([System.Uri]$html).AbsoluteUri
        Start-Process -FilePath $edge -ArgumentList ('--app="' + $uri + '"')
    } else {
        Start-Process -FilePath $html
    }
    return
}
foreach ($path in @($vivadoExe, $entry, (Join-Path $caseDir ($Case + '.wdb')), (Join-Path $caseDir ($Case + '.wcfg')), (Join-Path $caseDir ('project\wave_' + $Case + '.xpr')))) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file is missing: $path" }
}
$hashList = Join-Path $caseDir 'source_hashes.json'
if (-not (Test-Path -LiteralPath $hashList)) { throw "Missing source validation manifest: $hashList" }
foreach ($source in (Get-Content -LiteralPath $hashList -Raw -Encoding UTF8 | ConvertFrom-Json)) {
    if (-not (Test-Path -LiteralPath $source.path -PathType Leaf)) { throw "Source file is missing: $($source.path)" }
    if ((Get-FileHash -LiteralPath $source.path -Algorithm SHA256).Hash -ne $source.sha256) {
        throw "Source changed since this waveform was generated: $($source.path). Rebuild the local wave sessions before comparing code and waveforms."
    }
}
# Use a separate log name for every GUI session; no PowerShell 7 syntax.
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$log = Join-Path $caseDir ('gui_' + $stamp + '.log')
$journal = Join-Path $caseDir ('gui_' + $stamp + '.jou')
& $vivadoExe -mode gui -source $entry -log $log -journal $journal -tclargs $Case
if ($LASTEXITCODE -ne 0) { throw "Vivado exited with code $LASTEXITCODE. See $log" }
