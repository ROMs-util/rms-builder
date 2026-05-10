function Invoke-Bundler {
    param($config, $projectRoot, $outputPath)

    $name = $config.name
    $version = $config.version
    $packageName = "$name-$version.rms"
    $targetPath = Join-Path $outputPath $packageName
    $tempZip = Join-Path $env:TEMP "$packageName.zip"

    Write-Log "Bundling package: $packageName" "INFO"

    # 1. Collect Files
    $filesToPack = @()
    
    # Always include manifest
    $filesToPack += Join-Path $projectRoot "roms_package.json"

    # Add listed files with SMART EXCLUSION
    # Note: Even if a dev accidentally lists .git in the manifest, we skip it.
    $ignoredPatterns = @(".git", ".vscode", "builder.ps1", "builder.bat", "test")

    foreach ($file in $config.files) {
        $skip = $false
        foreach ($pattern in $ignoredPatterns) {
            if ($file -like "*$pattern*") {
                $skip = $true
                Write-Log "Smart Exclusion: Skipping $file" "DEBUG"
                break
            }
        }

        if (-not $skip) {
            $filesToPack += Join-Path $projectRoot $file
        }
    }

    # 2. Build the Zip
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    if (Test-Path $targetPath) { Remove-Item $targetPath -Force }

    try {
        Compress-Archive -Path $filesToPack -DestinationPath $tempZip -ErrorAction Stop
        Move-Item $tempZip $targetPath -ErrorAction Stop
        Write-Log "Successfully built: $targetPath" "SUCCESS"
    } catch {
        Write-Log "Failed to build package: $_" "ERROR"
        throw $_
    }
}
