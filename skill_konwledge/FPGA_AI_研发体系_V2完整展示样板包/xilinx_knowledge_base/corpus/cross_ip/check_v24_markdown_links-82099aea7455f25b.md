# check_v24_markdown_links

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\scripts\check_v24_markdown_links.ps1`
- SHA-256: `82099aea7455f25bc034b3140f069dbc93c4d15a7abf36cb0742d9c04d899570`
- Extractor: `text`
- Tags: `nvme, pcie, tcl, verification`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\scripts\check_v24_markdown_links.ps1

```powershell
[CmdletBinding()]
param(
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = Split-Path -Parent $scriptDirectory
}

$v24Sources = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'docs') `
    -Filter 'ADC_DDR_NVMe_V2.4_*.md' -File)
if ($v24Sources.Count -ne 1) {
    throw "Expected one V2.4 Markdown source, found $($v24Sources.Count)"
}
$files = @(
    (Join-Path $ProjectRoot 'README.md'),
    $v24Sources[0].FullName
)

$checked = 0
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Missing Markdown file: $file"
    }
    $text = [IO.File]::ReadAllText($file, [Text.Encoding]::UTF8)
    $matches = [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')
    foreach ($match in $matches) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?:|#)') {
            continue
        }
        $resolved = [IO.Path]::GetFullPath(
            (Join-Path (Split-Path -Parent $file) $target)
        )
        if (-not (Test-Path -LiteralPath $resolved)) {
            throw "Broken Markdown link: $file -> $target ($resolved)"
        }
        $checked++
    }
    Write-Host "MARKDOWN_FILE_PASS: $file"
}

Write-Host "V24_MARKDOWN_LINKS_PASS: $checked local links resolved"
```
