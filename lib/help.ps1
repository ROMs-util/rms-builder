function Show-Help {
    param([string]$invokedAs)

    # Resolve Context
    $toolName = "builder"
    $invokedAs = if ($PSScriptRoot -notlike "*C:\roms*") { ".\$toolName.bat" } else { $toolName }

    Write-Host ""
    Write-Host "----- ${invokedAs}: Official ROMs Package Builder -----" -ForegroundColor Cyan
    Write-Host "The ecosystem gatekeeper for creating validated .rms packages from project folders."
    Write-Host ""
    
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  $invokedAs <inputPath> [options]"
    Write-Host ""

    Write-Host "ARGUMENTS:" -ForegroundColor Yellow
    Write-Host "  inputPath          The directory containing roms_package.json and assets."
    Write-Host ""

    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -out <path>        Custom output directory for the .rms file."
    Write-Host "  -v, --verbose      Show detailed logging (-v, -vv, -vvv)."
    Write-Host "  --help             Show this help menu."
    Write-Host ""

    Write-Host "CORE TASKS:" -ForegroundColor Yellow
    Write-Host "  * Strict Validation  - Refuses to build if manifest fields are missing."
    Write-Host "  * Smart Exclusion    - Automatically ignores .git, .vscode, and dev files."
    Write-Host "  * File Integrity     - Verifies all listed files exist before zipping."
    Write-Host ""

    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  Build:     $invokedAs ."
    Write-Host "  Custom:    $invokedAs C:\MyProject -out C:\Builds -vv"
    Write-Host ""
    
    Write-Host "-----------------------------------------------------"
    Write-Host ""
}
