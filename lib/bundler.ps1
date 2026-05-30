function Invoke-Bundler {
    param($config, $projectRoot, $outputPath)

    $name = $config.name
    $version = $config.version
    $packageName = "$name-$version.rms"
    if ($config.architecture -and $config.architecture -ne "all") {
        $packageName = "${name}_$($config.architecture)-$version.rms"
    }

    $targetPath = Join-Path $outputPath $packageName

    Write-Log "Bundling package: $packageName" "INFO"

    # 1. Collect Files
    $pathsToPack = @()
    
    # Always include manifest
    $manifestPath = Join-Path $projectRoot "roms_package.json"
    if (Test-Path $manifestPath) {
        $pathsToPack += $manifestPath
    }

    # Add listed files with SMART EXCLUSION
    $ignoredPatterns = @(".git", ".vscode", "builder.ps1", "builder.bat", "test")

    Write-Log "Initializing smart file collection..." "DEBUG"
    foreach ($file in $config.files) {
        $skip = $false
        foreach ($pattern in $ignoredPatterns) {
            if ($file -like "*$pattern*") {
                $skip = $true
                Write-Log "Smart Exclusion: Skipping prohibited pattern [$pattern] found in '$file'" "DEBUG"
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

    # Deduplicate paths
    $uniquePaths = $pathsToPack | Select-Object -Unique

    # 2. Build the Zip (.NET Industrial Strength)
    if (Test-Path $targetPath) { 
        Write-Log "Overwriting existing package: $packageName" "TRACE"
        Remove-Item $targetPath -Force 
    }

    try {
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::Open($targetPath, [System.IO.Compression.ZipArchiveMode]::Create)
        
        foreach ($p in $uniquePaths) {
            $entryName = $p.Replace($projectRoot, "").TrimStart("\").TrimStart("/")
            
            # Capture the physical entry
            $entry = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $p, $entryName)

            # 1. Standard TRACE Header (Prefixed)
            Write-Log "Tracing compression: $entryName" "TRACE"

            # 2. Detailed Properties (Clean Passthrough for Console)
            if ($global:VerboseLevel -ge 2) {
                $props = $entry | Select-Object Archive, CompressedLength, ExternalAttributes, FullName, LastWriteTime, Length, Name
                $propString = $props | Out-String
                
                # ON-SCREEN: Clean Look (No Prefix)
                Write-Host $propString -ForegroundColor Cyan
                
                # LOG FILE: Tight-Inline Audit (One Line, One Event)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $jsonProps = $props | ConvertTo-Json -Compress
                "[$timestamp] [TRACE] [Builder] Details ($entryName): $jsonProps" | Out-File -FilePath $global:ROMs_MASTER_LOG -Append -Encoding utf8
            }
        }
        $zip.Dispose()
        Write-Log "Successfully built: $targetPath" "SUCCESS"
    } catch {
        if ($zip) { $zip.Dispose() }
        Write-Log "Failed to build package: $_" "ERROR"
        throw $_
    }
}
