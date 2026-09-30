[CmdletBinding()]
param(
    # Users normally edit regress_list and do not need to change this parameter.
    [string]$RegressList,

    # VERBOSE=0: summary; 1: random plan/frame details; 2: every data handshake.
    [ValidateRange(0, 2)]
    [int]$LogVerbosity = 1,

    # Optional output directory for logs and copied WDB files.
    [string]$RunDir,

    [string]$Vivado = 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat'
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
$defaultRunDir = 'C:\project\vivado_regress\run'
$RegressList = if ([string]::IsNullOrWhiteSpace($RegressList)) {
    Join-Path $scriptDir 'regress_list'
} else {
    $RegressList
}
$loopRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$projectDir = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$tcListPath = Join-Path $loopRoot 'new\tc\tc_list'
$tclScript = Join-Path $scriptDir 'run_regression.tcl'

# Read a list while allowing blank lines and comments beginning with '#'.
function Get-ActiveLines([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "List file not found: $Path" }
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $active = ($line -replace '#.*$', '').Trim()
        if ($active) { $active }
    }
}

$validTests = @(Get-ActiveLines $tcListPath)
if ($validTests.Count -eq 0) { throw "tc_list is empty: $tcListPath" }

# regress_list format: testcase repeat_count wave(0|1)
$jobs = @()
foreach ($line in Get-ActiveLines $RegressList) {
    $fields = @($line -split '\s+')
    if ($fields.Count -ne 3) {
        throw "Invalid regress_list line '$line'; expected: testcase repeat_count wave"
    }
    $testcase = $fields[0]
    if ($validTests -notcontains $testcase) { throw "Testcase '$testcase' is not registered in tc_list" }
    $repeatCount = 0
    if (-not [int]::TryParse($fields[1], [ref]$repeatCount) -or $repeatCount -lt 1) {
        throw "Repeat count must be a positive integer: $line"
    }
    $wave = 0
    if (-not [int]::TryParse($fields[2], [ref]$wave) -or ($wave -ne 0 -and $wave -ne 1)) {
        throw "Wave must be 0 or 1: $line"
    }
    $jobs += [pscustomobject]@{ Testcase = $testcase; Repeat = $repeatCount; Wave = $wave }
}
if ($jobs.Count -eq 0) { throw "regress_list contains no runnable entries: $RegressList" }

$vivadoCommand = Get-Command $Vivado -ErrorAction SilentlyContinue
if (-not $vivadoCommand) {
    throw "Vivado executable not found: $Vivado. Use a Vivado command shell or pass -Vivado <vivado.bat>."
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDir = if ([string]::IsNullOrWhiteSpace($RunDir)) {
    $defaultRunDir
} else {
    $RunDir
}
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
$regressLog = Join-Path $runDir 'regress_log.log'
$regressRpt = Join-Path $runDir 'regress_rpt.log'
Set-Content -LiteralPath $regressLog -Encoding UTF8 `
    -Value 'STATUS TESTCASE ITERATION SEED WAVE ELAPSED_S SIM_LOG WDB'

# A regression must not reuse a seed. Seeds are decimal values 000001..999999.
$usedSeeds = New-Object 'System.Collections.Generic.HashSet[int]'
function New-UniqueSeed {
    do { $candidate = Get-Random -Minimum 1 -Maximum 1000000 }
    while (-not $usedSeeds.Add($candidate))
    return $candidate
}

$results = @()
foreach ($job in $jobs) {
    for ($iteration = 1; $iteration -le $job.Repeat; $iteration++) {
        $seedValue = New-UniqueSeed
        $seedText = $seedValue.ToString('D6')
        $tc = $job.Testcase
        $stdoutLog = Join-Path $runDir ("{0}_{1}_vivado.log" -f $tc, $seedText)
        $stderrLog = Join-Path $runDir ("{0}_{1}_vivado.err.log" -f $tc, $seedText)
        $simLog = Join-Path $runDir ("{0}_{1}_simulate.log" -f $tc, $seedText)
        $wdbPath = Join-Path $runDir ("{0}_{1}_behav.wdb" -f $tc, $seedText)
        Write-Host ("[RUN ] {0} iteration={1}/{2} seed={3} wave={4}" -f `
                    $tc, $iteration, $job.Repeat, $seedText, $job.Wave)

        $arguments = @(
            '-mode', 'batch', '-notrace',
            '-source', ('"{0}"' -f $tclScript),
            '-tclargs', $tc, $seedText, $job.Wave, $LogVerbosity, ('"{0}"' -f $runDir)
        )
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $process = Start-Process -FilePath $vivadoCommand.Source `
            -ArgumentList $arguments -WorkingDirectory $projectDir `
            -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        $timer.Stop()

        $passed = ($process.ExitCode -eq 0) -and
                  (Select-String -LiteralPath $stdoutLog -SimpleMatch "REGRESSION_PASS testcase=$tc" -Quiet)
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        $recordedWdb = if (($job.Wave -eq 1) -and (Test-Path -LiteralPath $wdbPath)) { $wdbPath } else { '-' }
        $results += [pscustomobject]@{
            Testcase = $tc; Iteration = $iteration; Seed = $seedText; Wave = $job.Wave
            Status = $status; Elapsed = [math]::Round($timer.Elapsed.TotalSeconds, 3)
            SimLog = $simLog; Wdb = $recordedWdb
        }
        Add-Content -LiteralPath $regressLog -Encoding UTF8 -Value `
            ("{0} {1} {2} {3} {4} {5:F3} {6} {7}" -f $status, $tc, $iteration,
             $seedText, $job.Wave, $timer.Elapsed.TotalSeconds, $simLog, $recordedWdb)
        Write-Host ("[{0}] {1} seed={2}" -f $status.PadRight(4), $tc, $seedText)
    }
}

# Produce a concise testcase-level report while retaining every seed in regress_log.log.
$reportLines = @("REGRESSION_TIME=$timestamp", "RUN_DIR=$runDir", '')
foreach ($group in $results | Group-Object Testcase) {
    $passCount = @($group.Group | Where-Object Status -eq 'PASS').Count
    $failCount = @($group.Group | Where-Object Status -eq 'FAIL').Count
    $reportLines += ("{0} TOTAL={1} PASS={2} FAIL={3}" -f $group.Name, $group.Count, $passCount, $failCount)
}
$totalPass = @($results | Where-Object Status -eq 'PASS').Count
$totalFail = @($results | Where-Object Status -eq 'FAIL').Count
$reportLines += ''
$reportLines += ("OVERALL TOTAL={0} PASS={1} FAIL={2}" -f $results.Count, $totalPass, $totalFail)
Set-Content -LiteralPath $regressRpt -Encoding UTF8 -Value $reportLines

$results | Format-Table Testcase,Iteration,Seed,Wave,Status,Elapsed -AutoSize
Write-Host "Run log : $regressLog"
Write-Host "Summary : $regressRpt"
if ($totalFail -ne 0) { exit 1 }
exit 0
