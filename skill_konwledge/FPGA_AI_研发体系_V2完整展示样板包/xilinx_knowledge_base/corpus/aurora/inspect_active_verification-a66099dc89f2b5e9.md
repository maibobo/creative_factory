# inspect_active_verification

- Category: `aurora`
- Source: `E:\aurora_proc\scripts\inspect_active_verification.ps1`
- SHA-256: `a66099dc89f2b5e932a76a4139a9e33b50efd1f3594dd4ba028fa7de2a266d8c`
- Extractor: `text`
- Tags: `aurora, automation, tcl`
- Duplicate sources:
  - none

```powershell
$root = 'C:\project\RTDS\aurora_8b10b_1p25g_2020_2\verification\aurora_8b10b_1p25g_ex'

Get-Date
Write-Output '--- processes ---'
foreach ($name in @('vivado', 'xsim', 'xsimk', 'xelab', 'xvlog')) {
    Get-Process -Name $name -ErrorAction SilentlyContinue |
        Select-Object Id, ProcessName, CPU, StartTime, Path
}

Write-Output '--- candidate logs ---'
Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @('simulate.log', 'elaborate.log', 'compile.log', 'xsimkernel.log') } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 12 FullName, Length, LastWriteTime

$simLogs = Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'simulate.log' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 3
foreach ($log in $simLogs) {
    Write-Output "--- $($log.FullName) ---"
    Get-Content -LiteralPath $log.FullName -Tail 100
}

Write-Output '--- current simulation artifacts ---'
$simDir = Join-Path $root 'aurora_8b10b_1p25g_ex.sim\sim_1\behav\xsim'
if (Test-Path -LiteralPath $simDir) {
    Get-ChildItem -LiteralPath $simDir -File |
        Select-Object Name, Length, LastWriteTime
}

Write-Output '--- testbench settings ---'
$tb = Join-Path $root 'imports\aurora_8b10b_1p25g_tb.v'
Select-String -LiteralPath $tb -Pattern 'SIM_MAX_TIME|CLOCKPERIOD|INIT_CLOCKPERIOD|GT_RESET_IN|Test Completed Successfully|TEST FAIL' |
    ForEach-Object { "{0}:{1}" -f $_.LineNumber, $_.Line }
```
