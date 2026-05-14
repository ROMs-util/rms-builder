function Invoke-Bundler {
    param($config, $projectRoot, $outputPath)

    $name = $config.name
    $version = $config.version
    $packageName = "$name-$version.rms"
    $targetPath = Join-Path $outputPath $packageName
    $tempZip = Join-Path $env:TEMP "$packageName.zip"

    Write-Log "Bundling package: $packageName" "INFO"

    # 1. Collect Files
    $pathsToPack = @()
    
    # Always include manifest
    $pathsToPack += Join-Path $projectRoot "roms_package.json"

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
            # Resolve wildcards
            $resolved = Get-ChildItem -Path (Join-Path $projectRoot $file) -File -ErrorAction SilentlyContinue
            if ($resolved) {
                $pathsToPack += $resolved.FullName
            }
        }
    }

    # Deduplicate paths to prevent Compress-Archive/Zip failure
    $uniquePaths = $pathsToPack | Select-Object -Unique

    # 2. Build the Zip (.NET Industrial Strength)
    if (Test-Path $targetPath) { Remove-Item $targetPath -Force }

    try {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::Open($targetPath, [System.IO.Compression.ZipArchiveMode]::Create)
        
        foreach ($p in $uniquePaths) {
            $entryName = $p.Replace($projectRoot, "").TrimStart("\").TrimStart("/")
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $p, $entryName)
        }
        
        $zip.Dispose()
        Write-Log "Successfully built: $targetPath" "SUCCESS"
    } catch {
        if ($zip) { $zip.Dispose() }
        Write-Log "Failed to build package: $_" "ERROR"
        throw $_
    }
}
