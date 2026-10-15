param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SearchArgs
)

$ErrorActionPreference = 'Stop'
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$kbRoot = $PSScriptRoot
$bundledPython = 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pythonExe = if (Test-Path -LiteralPath $bundledPython) { $bundledPython } else { (Get-Command python -ErrorAction Stop).Source }

& $pythonExe (Join-Path $kbRoot 'tools\search_kb.py') --db (Join-Path $kbRoot 'index\xilinx_kb.sqlite3') @SearchArgs
exit $LASTEXITCODE
