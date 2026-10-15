# audit_unified_interfaces

- Category: `aurora`
- Source: `R:\aurora_64b66b_10p3125g_2020_2_verified\scripts\audit_unified_interfaces.ps1`
- SHA-256: `5c85cfbfd0894940dfca7a38e138026cec338d2ef3716d328cd997fd89931595`
- Extractor: `text`
- Tags: `10.3125g, 64b66b, aurora, verified, vivado-2020.2`
- Duplicate sources:
  - none

```powershell
param(
    [Parameter(Mandatory = $true)][string]$Root10g,
    [Parameter(Mandatory = $true)][string]$Root1g
)

$ErrorActionPreference = 'Stop'
$top10 = Join-Path $Root10g 'design\rtl\aurora_64b66b_10p3125g_design.v'
$top1 = Join-Path $Root1g 'design\rtl\aurora_8b10b_1p25g_design.v'
$exdes10 = Join-Path $Root10g 'design\rtl\aurora_64b66b_0_exdes.v'

function Get-ModuleHeader([string]$Path, [string]$ModuleName) {
    $text = [IO.File]::ReadAllText($Path)
    $match = [regex]::Match(
        $text,
        "module\s+$([regex]::Escape($ModuleName))\b[\s\S]*?\)\s*;",
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    if (-not $match.Success) { throw "Cannot find module header: $ModuleName in $Path" }
    return $match.Value
}

$header10 = Get-ModuleHeader $top10 'aurora_64b66b_10p3125g_design'
$header1 = Get-ModuleHeader $top1 'aurora_8b10b_1p25g_design'
$required = @(
    'reset', 'gt_reset', 'init_clk_in', 'gt_refclk_p', 'gt_refclk_n',
    'rxp', 'rxn', 'txp', 'txn',
    'tx_data', 'tx_rem', 'tx_sof', 'tx_eof', 'tx_valid', 'tx_ready',
    'rx_data', 'rx_rem', 'rx_sof', 'rx_eof', 'rx_valid',
    'user_clk_out', 'system_reset_out', 'channel_up', 'rx_crc_error'
)
$forbidden = @(
    'lane_up', 'hard_err', 'soft_err', 'frame_err', 'crc_valid',
    'crc_pass_fail_n', 'loopback', 'power_down', 'tx_lock',
    'pll_not_locked', 'tx_resetdone', 'rx_resetdone'
)

foreach ($entry in @(@('10G', $header10), @('1G', $header1))) {
    $name = $entry[0]
    $header = $entry[1]
    foreach ($port in $required) {
        if ($header -notmatch "\b$([regex]::Escape($port))\b") {
            throw "$name missing public port: $port"
        }
    }
    foreach ($port in $forbidden) {
        if ($header -match "\b$([regex]::Escape($port))\b") {
            throw "$name still exposes forbidden public port: $port"
        }
    }
}

$text10 = [IO.File]::ReadAllText($top10)
$text1 = [IO.File]::ReadAllText($top1)
$exdesText10 = [IO.File]::ReadAllText($exdes10)
if ($text10 -notmatch 'assign\s+rx_crc_error\s*=\s*crc_valid_i\s*&&\s*!crc_pass_fail_n_i') {
    throw '10G rx_crc_error expression mismatch'
}
if ($text1 -notmatch 'assign\s+rx_crc_error\s*=\s*crc_valid_i\s*&&\s*!crc_pass_fail_n_i') {
    throw '1G rx_crc_error expression mismatch'
}
if ($text1 -notmatch '\.loopback\s*\(3''b000\)' -or $text1 -notmatch '\.power_down\s*\(1''b0\)') {
    throw '1G fixed loopback/power_down values are missing'
}
if ($exdesText10 -notmatch 'assign\s+SYSTEM_RESET_OUT\s*=\s*system_reset_i') {
    throw '10G SYSTEM_RESET_OUT is not connected to system_reset_i'
}

$sourceXdc = 'C:\project\RTDS\aurora_8b10b_1_ex\imports\aurora_8b10b_1_exdes.xdc'
$designXdc = Join-Path $Root1g 'design\constraints\aurora_8b10b_1_exdes.xdc'
$verificationXdc = Join-Path $Root1g 'verification\imports\aurora_8b10b_1_exdes.xdc'
$hashes = @($sourceXdc, $designXdc, $verificationXdc) | ForEach-Object {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash
}
if (($hashes | Select-Object -Unique).Count -ne 1) {
    throw '1G XDC copies differ from the authoritative source'
}

$report = @(
    'PASS: unified public interface audit',
    'Required status outputs: user_clk_out, system_reset_out, channel_up, rx_crc_error',
    'Removed public diagnostics and GT startup status: PASS',
    "1G authoritative XDC SHA256: $($hashes[0])",
    '1G USER_CLK: 1.25 GHz / (4 bytes * 10 encoded bits/byte) = 31.25 MHz',
    'Synthesis/implementation/bitstream: NOT RUN (not required)'
) -join [Environment]::NewLine

foreach ($root in @($Root10g, $Root1g)) {
    $reportDir = Join-Path $root 'reports'
    [IO.Directory]::CreateDirectory($reportDir) | Out-Null
    [IO.File]::WriteAllText((Join-Path $reportDir 'unified_interface_audit.txt'), $report + [Environment]::NewLine)
}

Write-Output $report
```
