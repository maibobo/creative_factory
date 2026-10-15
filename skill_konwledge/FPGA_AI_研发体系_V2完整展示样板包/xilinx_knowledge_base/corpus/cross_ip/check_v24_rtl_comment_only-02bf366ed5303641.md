# check_v24_rtl_comment_only

- Category: `cross_ip`
- Source: `R:\nvme_adc_axi_pipeline\scripts\check_v24_rtl_comment_only.ps1`
- SHA-256: `02bf366ed53036419bcecb8e12003fd29fedfb287c40ec5d8745ae9f1cc7c63f`
- Extractor: `text`
- Tags: `nvme, pcie, tcl, verification`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\scripts\check_v24_rtl_comment_only.ps1

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
$rtlRoot = Join-Path $ProjectRoot 'rtl'

$expected = [ordered]@{
    'nvme_adc_vitis_compat_top.sv'      = '382A2B59EB7EF6F5BCBAF1B3318B6DEABE9AD65A578D55EE8E934E121AF87C4D'
    'fdma_vitis_compat_regs.sv'          = '92093355F04040EF6842BE5974F9373DB27BF0EFA2F88F87145A60F2A4A543FA'
    'adc_capture_limit_controller.sv'    = '761D864DF46E7DF07C8C6D0E16FCE743908E449DCEE588F579A801FFADA518D4'
    'nvme_adc_pipeline_top.sv'           = 'CF91FD56F78E2205B4125EA75851A6D2089B406F48749377C467436C79C8CBD1'
    'adc_channel_packer.sv'              = 'E04EABA7538E3EEA32E8EE3B3F00D4758DE48E8BFADE684CC7B0BF4EC72F333B'
    'axis_async_fifo.sv'                 = '234F0284414C2BA2130B4E6E4E7F81315907097C1B45AE0CAF8A985E4BA79671'
    'adc_ddr_segment_writer.sv'          = '5643E19DEB86AD14091348706F50826AC01E02D247E8B73C4B53844B04A65525'
    'sync_fifo.sv'                       = 'DF6476D101114526FD013A5585753305D97D8473BA58490FC5C3064136649F01'
    'segment_buffer_manager.sv'          = '8D495C1F0D599506F768FD79EE4D79F2A2F8AB288F9ED4630F1A465FEE7D2F9F'
    'nvme_request_scheduler.sv'          = 'BA4B88282A615D9A9D916D92DAA5608CB6877247FD054EEEC1823F9FF1E3EFAC'
    'nophae_dma_backend.sv'              = '7CE815AC3C827886BF8081903C7FBAD3A17C672557F27877293DEF0300F64595'
}

function Get-CommentFreeHash {
    param([Parameter(Mandatory)][string]$Path)

    $text = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    $text = $text -replace 'always_comb', 'always @*'
    $text = [regex]::Replace($text, '(?s)/\*.*?\*/', '')
    $text = [regex]::Replace($text, '(?m)//.*$', '')
    $text = [regex]::Replace($text, '\s+', '')
    $bytes = [Text.Encoding]::UTF8.GetBytes($text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

$results = foreach ($entry in $expected.GetEnumerator()) {
    $path = Join-Path $rtlRoot $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing formal-path RTL: $path"
    }
    $actual = Get-CommentFreeHash -Path $path
    if ($actual -ne $entry.Value) {
        throw "Non-comment RTL changed: $($entry.Key) expected=$($entry.Value) actual=$actual"
    }
    [pscustomobject]@{
        File = $entry.Key
        CommentFreeSha256 = $actual
        Match = $true
    }
}

$packerPath = Join-Path $rtlRoot 'adc_channel_packer.sv'
$packer = [IO.File]::ReadAllText($packerPath, [Text.Encoding]::UTF8)
if ($packer -match '\balways_comb\b') {
    throw 'adc_channel_packer.sv still contains always_comb'
}
if ($packer -notmatch '\balways\s+@\*') {
    throw 'adc_channel_packer.sv does not contain the required always @* block'
}

foreach ($entry in $expected.GetEnumerator()) {
    $path = Join-Path $rtlRoot $entry.Key
    $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    if ($text -match '263\s*bit') {
        throw "Obsolete 263 bit description remains in $($entry.Key)"
    }

    $lines = $text -split "`r?`n"
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        if ($line -notmatch '^\s*(input|output|inout|wire|reg|logic|localparam|parameter|integer|genvar)\b') {
            continue
        }
        if ($line -match '//') {
            continue
        }
        $previous = if ($index -gt 0) { $lines[$index - 1].Trim() } else { '' }
        if ($previous -notmatch '^//') {
            throw "Declaration lacks nearby semantic comment: $($entry.Key):$($index + 1)"
        }
    }
}

$results | Format-Table -AutoSize
Write-Host 'V24_RTL_COMMENT_ONLY_PASS: 11/11 comment-free hashes match'
Write-Host 'V24_COMBINATIONAL_STYLE_PASS: adc_channel_packer uses always @*'
Write-Host 'V24_COMMENT_COVERAGE_PASS: every declaration has inline or immediately preceding semantics'
Write-Host 'V24_REGRESSION_SKIPPED: per latest user instruction'
Write-Host 'V24_SYNTHESIS_SKIPPED: no synthesis or implementation invoked'
```
