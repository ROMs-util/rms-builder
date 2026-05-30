# builder.ps1 - The ROMs-util Package Builder (Router)
# Usage: builder <inputPath> [-out <path>] [flags]

# ---------------------------------------------
# ARGUMENT PARSING (Industrial Strength)
# ---------------------------------------------
# Separate Global Flags (Options) from Positional Data (Command/Path)
$flags = @($args | Where-Object { $_ -is [string] -and $_.StartsWith("-") })
[array]$data = @($args | Where-Object { -not ($_ -is [string] -and $_.StartsWith("-")) })

$inputPath = $data[0]

# Global Flag Pattern (Design Standard: $args -contains)
$help = ($flags -contains "-h") -or ($flags -contains "--help")

# Multi-Level Verbosity Parsing
$global:VerboseLevel = 0
if ($flags -contains "-vvv") { $global:VerboseLevel = 3 }
elseif ($flags -contains "-vv") { $global:VerboseLevel = 2 }
elseif ($flags -contains "-v" -or $flags -contains "--verbose") { $global:VerboseLevel = 1 }

# Legacy flag compatibility
$global:Verbose = ($global:VerboseLevel -gt 0)

# Out Parameter (Manual detection for flag pattern)
$outIdx = [array]::IndexOf($args, "-out")
if ($outIdx -lt 0) { $outIdx = [array]::IndexOf($args, "--out") }
$out = if ($outIdx -ge 0 -and $args.Count -gt ($outIdx + 1)) { $args[$outIdx + 1] } else { $null }

# ---------------------------------------------
# LOAD MODULES
# ---------------------------------------------
$libPath = Join-Path $PSScriptRoot "lib"
. (Join-Path $libPath "core.ps1")
. (Join-Path $libPath "help.ps1")
. (Join-Path $libPath "validator.ps1")
. (Join-Path $libPath "bundler.ps1")

# ---------------------------------------------
# IDENTITY DISCOVERY
# ---------------------------------------------
if ($args) { Write-Log "Raw Args: $($args -join ' ')" "RAW" }
if ($inputPath) { Write-Log "Input Path: $inputPath" "RAW" }

# ---------------------------------------------
# PRE-FLIGHT CHECKS
# ---------------------------------------------
if ($help -or -not $inputPath) {
    Show-Help
    exit 0
}

# Resolve Source Path
$projectRoot = $null
$manifestPath = $null

if (Test-Path $inputPath -PathType Leaf) {
    # Pointed directly at a JSON file
    $manifestPath = [System.IO.Path]::GetFullPath($inputPath)
    $projectRoot = Split-Path $manifestPath
} elseif (Test-Path $inputPath -PathType Container) {
    # Pointed at a folder
    $projectRoot = [System.IO.Path]::GetFullPath($inputPath)
    $manifestPath = Join-Path $projectRoot "roms_package.json"
}

if (-not $manifestPath -or -not (Test-Path $manifestPath)) {
    Write-Log "Could not find roms_package.json at: $inputPath" "ERROR"
    exit 1
}

# Resolve Output Path (Default to Project Root if not specified)
$finalOutput = $projectRoot
if ($out) {
    $finalOutput = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $out))
}

# ---------------------------------------------
# EXECUTION
# ---------------------------------------------
Write-Log "Starting ROMs Package Builder..." "DEBUG"

# 1. Load Manifest
try {
    $rawManifest = Get-Content $manifestPath -Raw
    if ($rawManifest) { Write-Log "Manifest Data ($manifestPath): $rawManifest" "RAW" }
    $config = $rawManifest | ConvertFrom-Json
} catch {
    Write-Log "Failed to parse roms_package.json: $_" "ERROR"
    exit 1
}

# 2. Strict Validation
if (-not (Test-Manifest -config $config)) { exit 1 }
if (-not (Test-FileIntegrity -config $config -projectRoot $projectRoot)) { exit 1 }

# 3. Bundle
try {
    Invoke-Bundler -config $config -projectRoot $projectRoot -outputPath $finalOutput
} catch {
    Write-Log "Build failed." "ERROR"
    exit 1
}

Write-Log "-----------------------------------------------------"
Write-Log "DONE: Package is ready inside: $finalOutput" "SUCCESS"
Write-Host ""
