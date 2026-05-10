param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$inputPath,

    [Parameter(Mandatory = $false)]
    [string]$out,

    [Parameter(Mandatory = $false)]
    [switch]$help
)

# ---------------------------------------------
# LOAD MODULES
# ---------------------------------------------
$libPath = Join-Path $PSScriptRoot "lib"
. (Join-Path $libPath "core.ps1")
. (Join-Path $libPath "help.ps1")
. (Join-Path $libPath "validator.ps1")
. (Join-Path $libPath "bundler.ps1")

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
    $config = Get-Content $manifestPath -Raw | ConvertFrom-Json
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
