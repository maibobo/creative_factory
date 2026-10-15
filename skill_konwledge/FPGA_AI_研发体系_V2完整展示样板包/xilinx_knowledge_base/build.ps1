param(
    [switch]$Clean,
    [switch]$VerboseReport
)

$ErrorActionPreference = 'Stop'
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$kbRoot = $PSScriptRoot
$bundledPython = 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pythonExe = if (Test-Path -LiteralPath $bundledPython) { $bundledPython } else { (Get-Command python -ErrorAction Stop).Source }

$arguments = @((Join-Path $kbRoot 'tools\build_kb.py'), '--config', (Join-Path $kbRoot 'config\sources.json'))
if ($Clean) { $arguments += '--clean' }
if ($VerboseReport) { $arguments += '--verbose' }

& $pythonExe @arguments
if ($LASTEXITCODE -ne 0) { throw "Knowledge-base build failed with exit code $LASTEXITCODE" }
