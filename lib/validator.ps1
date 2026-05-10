function Test-Manifest {
    param($config)

    Write-Log "Validating roms_package.json..." "INFO"

    $requiredFields = @("name", "version", "commandName", "executable", "installDir", "files")
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

    # Verify Files Array
    if ($config.files.Count -eq 0) {
        Write-Log "Manifest 'files' array is empty. Nothing to pack." "ERROR"
        return $false
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
