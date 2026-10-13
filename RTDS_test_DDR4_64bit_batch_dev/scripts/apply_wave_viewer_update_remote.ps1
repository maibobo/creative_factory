param(
    [string]$Archive = (Join-Path $env:USERPROFILE 'wave_viewer_update_20260929.zip'),
    [string]$Target = 'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev'
)

# PowerShell 5 compatible. Extract to a unique staging directory, verify every
# packaged hash, then copy into the already-verified project. A Word document
# held open by Office is saved under a new name without interrupting other files.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if (-not (Test-Path -LiteralPath $Archive -PathType Leaf)) { throw "Archive not found: $Archive" }
if (-not (Test-Path -LiteralPath $Target -PathType Container)) { throw "Target not found: $Target" }

$targetFull = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Target).Path)
$targetPrefix = $targetFull.TrimEnd('\') + '\'
$stage = Join-Path $env:TEMP ('wave_viewer_stage_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
Expand-Archive -LiteralPath $Archive -DestinationPath $stage
$manifestPath = Join-Path $stage 'evidence\local_wave_sessions\word_wave_captures\remote_sync_manifest.json'
$entries = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$copied = 0
$fallback = @()

foreach ($entry in $entries) {
    $relative = ([string]$entry.path).Replace('/', '\')
    $source = [IO.Path]::GetFullPath((Join-Path $stage $relative))
    $destination = [IO.Path]::GetFullPath((Join-Path $targetFull $relative))
    if (-not $destination.StartsWith($targetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside target: $relative"
    }
    $actualSourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSourceHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
        throw "Package hash mismatch: $relative"
    }
    $parent = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    try {
        Copy-Item -LiteralPath $source -Destination $destination -Force -ErrorAction Stop
    } catch {
        if (-not $relative.EndsWith('.docx', [StringComparison]::OrdinalIgnoreCase)) { throw }
        $alternative = Join-Path $parent ([IO.Path]::GetFileNameWithoutExtension($destination) + '_remote_20260929.docx')
        Copy-Item -LiteralPath $source -Destination $alternative -Force -ErrorAction Stop
        $destination = $alternative
        $fallback += $alternative
    }
    $actualDestinationHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualDestinationHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
        throw "Destination hash mismatch: $destination"
    }
    $copied++
}

[pscustomobject]@{
    target = $targetFull
    verified_files = $copied
    fallback_word = $fallback
    staging_directory = $stage
} | ConvertTo-Json -Compress -Depth 3
