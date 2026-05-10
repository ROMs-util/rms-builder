function Show-Help {
    param([string]$invokedAs)

    # Resolve Context
    $toolName = "builder"
    $invokedAs = if ($PSScriptRoot -notlike "*C:\roms*") { ".\$toolName.bat" } else { $toolName }

    Write-Host ""
    Write-Host "----- ${invokedAs}: Official ROMs Package Builder -----" -ForegroundColor Cyan
    Write-Host "The ecosystem gatekeeper for creating validated .rms packages."
    Write-Host ""
    
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  $invokedAs [options]"
    Write-Host ""

    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -out <path>        Custom output directory for the .rms file (Default: current)."
    Write-Host "  --help             Show this menu."
    Write-Host ""

    Write-Host "CORE TASKS:" -ForegroundColor Yellow
    Write-Host "  * Strict Validation  - Refuses to build if manifest fields are missing."
    Write-Host "  * Smart Exclusion    - Automatically ignores .git, .vscode, and dev files."
    Write-Host "  * File Integrity     - Verifies all listed files exist before zipping."
    Write-Host ""

    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  Build:     $invokedAs"
    Write-Host "  Custom:    $invokedAs -out C:\Builds"
    Write-Host ""
    
    Write-Host "-----------------------------------------------------"
    Write-Host ""
}
