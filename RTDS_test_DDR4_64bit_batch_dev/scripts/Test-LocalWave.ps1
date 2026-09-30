#requires -version 5.0
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$scripts = @('Open-LocalWave.ps1', 'Test-LocalWave.ps1')
foreach ($script in $scripts) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $script), [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { throw ($parseErrors | Out-String) }
}
foreach ($case in @('1g','tx','rx_fifo','ring','axi','axi_tail','regs')) {
    $folder = Join-Path $root ('evidence\local_wave_sessions\' + $case)
    foreach ($name in @(($case + '.wdb'), ($case + '.vcd'), ($case + '.wcfg'), ($case + '_viewer.html'), 'signals.txt', 'signals.csv', 'files.txt', 'source_hashes.json', 'signal_sources.csv', ('Open_' + $case + '.cmd'))) {
        $file = Get-Item -LiteralPath (Join-Path $folder $name)
        if ($file.Length -eq 0) { throw "Empty artifact: $($file.FullName)" }
    }
    [xml]$wave = Get-Content -LiteralPath (Join-Path $folder ($case + '.wcfg')) -Raw -Encoding UTF8
    $waveSignals = @($wave.SelectNodes('//wvobject[starts-with(@fp_name,"/")]'))
    if ($waveSignals.Count -eq 0) { throw "Empty wave list: $case" }
    foreach ($source in (Get-Content -LiteralPath (Join-Path $folder 'source_hashes.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) {
        if ((Get-FileHash -LiteralPath $source.path -Algorithm SHA256).Hash -ne $source.sha256) { throw "Source hash mismatch: $($source.path)" }
    }
    Write-Output ("ARTIFACT_PASS {0} displayed_rows={1}" -f $case, $waveSignals.Count)
}
Write-Output ("POWERSHELL_VERSION=" + $PSVersionTable.PSVersion.ToString())
Write-Output 'LOCAL_ARTIFACT_ALL_PASS'
