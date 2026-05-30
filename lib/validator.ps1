function Test-Manifest {
    param($config)

    Write-Log "Validating roms_package.json..." "INFO"

    # installDir is explicitly forbidden (Standard Enforcement)
    if ($config.installDir) {
        Write-Log "Strict Validation Failed: 'installDir' is deprecated. Apps must use the 'Name-as-Folder' standard." "ERROR"
        return $false
    }
    Write-Log "Verified manifest is relocatable (No installDir)." "DEBUG"

    # Trinity v1.1.0 Required Fields
    $requiredFields = @("name", "version", "author", "architecture", "commandName", "executable", "files")
    $missing = @()

    foreach ($field in $requiredFields) {
        if (-not $config.$field) {
            $missing += $field
        }
    }

    if ($missing.Count -gt 0) {
        Write-Log "Strict Validation Failed. Missing fields: $($missing -join ', ')" "ERROR"
        return $false
    }
    Write-Log "Mandatory structural fields verified: $($requiredFields -join ', ')" "DEBUG"
    Write-Log "Architecture target identified as: $($config.architecture)" "DEBUG"

    # Verify Files Array
    if ($config.files.Count -eq 0) {
        Write-Log "Manifest 'files' array is empty. Nothing to pack." "ERROR"
        return $false
    }
    Write-Log "Found $($config.files.Count) physical assets in manifest." "DEBUG"

    # Industrial Strength: Validate Dependency Syntax (Trinity v1.1.0 Object Model)
    if ($config.dependencies) {
        # Support for new 'packages' list within dependencies object
        $packageDeps = @()
        if ($config.dependencies.packages) {
            $packageDeps = @($config.dependencies.packages)
        } elseif ($config.dependencies -is [System.Array] -or $config.dependencies -is [System.Collections.IEnumerable]) {
            # Backward compatibility for flat array (Warn but allow for now)
            Write-Log "Legacy dependency format detected. Transitioning to object model is recommended." "WARN"
            $packageDeps = @($config.dependencies)
        }

        $depRegex = "^[a-z0-9-]+(?::(\^|~|>=|>|<=|<)?\s*\d+(?:\.\d+)?(?:\.\d+)?(?:-.+)?)?$"
        foreach ($d in $packageDeps) {
            if ($d -notmatch $depRegex) {
                Write-Log "Invalid dependency syntax: '$d'. Use 'name' or 'name:^1.2.0'." "ERROR"
                return $false
            }
        }
    }

    return $true
}

function Test-FileIntegrity {
    param($config, $projectRoot)

    Write-Log "Verifying file integrity..." "INFO"
    $missingCount = 0

    foreach ($file in $config.files) {
        $fullPath = Join-Path $projectRoot $file
        if (-not (Test-Path $fullPath)) {
            Write-Log "Missing required file: $file" "ERROR"
            $missingCount++
        }
    }

    if ($missingCount -gt 0) {
        Write-Log "$missingCount files missing. Build aborted." "ERROR"
        return $false
    }

    Write-Log "All listed files verified." "SUCCESS"
    return $true
}
