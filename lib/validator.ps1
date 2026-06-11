# ---------------------------------------------
# MANIFEST VALIDATION (Strict)
# Validates roms_package.json against Trinity v1.1.0 schema requirements.
# HOW IT WORKS:
# 1. Reject deprecated 'installDir' field (Name-as-Folder standard).
# 2. Check all required fields: name, version, author, architecture, commandName, executable, files.
# 3. Verify files array is not empty.
# 4. Validate dependency syntax against regex: name:^1.0.0, name:~1.0.0, etc.
# Returns $true if valid, $false otherwise.
# ---------------------------------------------
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

    # Validate Dependency Syntax (Trinity v1.1.0 Object Model)
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

        $depRegex = "^[a-z0-9-]+(?::(\^|~|>=|>|<=|<|=)?\s*\d+(?:\.\d+)?(?:\.\d+)?(?:-.+)?)?$"
        foreach ($d in $packageDeps) {
            if ($d -notmatch $depRegex) {
                Write-Log "Invalid dependency syntax: '$d'. Use 'name' or 'name:^1.2.0'." "ERROR"
                return $false
            }
        }
    }

    return $true
}

# ---------------------------------------------
# FILE INTEGRITY CHECK
# Verifies all files listed in manifest actually exist on disk.
# HOW IT WORKS:
# 1. Iterate through all files in manifest's files array.
# 2. Check if each file exists relative to project root.
# 3. Count missing files and abort build if any are absent.
# Returns $true if all files found, $false if any missing.
# ---------------------------------------------
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
