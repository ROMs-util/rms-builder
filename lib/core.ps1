# ---------------------------------------------
# GLOBALS & PATHS (Ecosystem Standard)
# ---------------------------------------------
$global:ROMs_ROOT       = "C:\roms"
$global:ROMs_LOGS       = "$global:ROMs_ROOT\logs"
$global:ROMs_MASTER_LOG = "$global:ROMs_LOGS\roms.log"

$global:ROMs_TEMP       = "$global:ROMs_ROOT\temp"

# Architecture Detection (PowerShell Version Aware)
$global:ROMs_ARCH = if ($PSVersionTable.PSVersion.Major -ge 6) {
    [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
} else {
    $env:PROCESSOR_ARCHITECTURE
}

# ---------------------------------------------
# LOGGING SYSTEM
# Writes timestamped log entries to console (colored by level) and master log file.
# HOW IT WORKS:
# 1. Detect JSON in message and pretty-print for readability.
# 2. Format output with timestamp, source, and level badge.
# 3. Write to $global:ROMs_MASTER_LOG with retry logic for locked files.
# 4. Output to console with color coding (INFO=White, WARN=Yellow, ERROR=Red, etc.).
# Uses global $VerboseLevel: 0=INFO/WARN/ERROR/SUCCESS, 1=+DEBUG, 2=+TRACE, 3=+RAW
# ---------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG", "TRACE", "RAW")][string]$Level = "INFO",
        [string]$Source = "Builder"
    )

    # Initialize global verbosity if not set
    if ($null -eq $global:VerboseLevel) { $global:VerboseLevel = 0 }

    if (-not (Test-Path $global:ROMs_LOGS)) {
        New-Item -ItemType Directory -Path $global:ROMs_LOGS -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # 1. DATA PREPARATION (Extract JSON once)
    $isJson = ($Message -match "^\s*\{" -or $Message -match "^\s*\[" -or $Message -match ":\s*\{" -or $Message -match ":\s*\[")
    $prefix = ""
    $jsonObj = $null
    
    if ($isJson) {
        try {
            # Extraction logic (Non-greedy prefix capture)
            if ($Message -match "(?s)(.*?):\s*([\{\[].*)") {
                $prefix = $matches[1].Trim()
                $jsonObj = $matches[2].Trim() | ConvertFrom-Json
            } else {
                $jsonObj = $Message | ConvertFrom-Json
            }
        } catch { 
            $isJson = $false # False positive or corrupt JSON
        }
    }

    # 2. FILE LOGGING (Tight Inline: One Line, One Event)
    $fileContent = if ($isJson) {
        $compactJson = $jsonObj | ConvertTo-Json -Depth 10 -Compress
        if ($prefix) { "${prefix}: $compactJson" } else { $compactJson }
    } else {
        # Flatten multi-line strings for log consistency
        ($Message -split "\r?\n" | ForEach-Object { $_.Trim() }) -join " "
    }

    $logFileLine = "[$timestamp] [$Level] [$Source] $fileContent"
    $retryCount = 0
    $success = $false
    while (-not $success -and $retryCount -lt 5) {
        try {
            $logFileLine | Out-File -FilePath $global:ROMs_MASTER_LOG -Append -Encoding utf8 -ErrorAction Stop
            $success = $true
        } catch {
            $retryCount++
            Start-Sleep -Milliseconds 50
        }
    }

    # 3. CONSOLE OUTPUT (Pretty-RAW for Humans)
    $shouldDisplay = $true
    if ($Level -eq "DEBUG" -and $global:VerboseLevel -lt 1) { $shouldDisplay = $false }
    elseif ($Level -eq "TRACE" -and $global:VerboseLevel -lt 2) { $shouldDisplay = $false }
    elseif ($Level -eq "RAW"   -and $global:VerboseLevel -lt 3) { $shouldDisplay = $false }

    if ($shouldDisplay) {
        $consoleContent = if ($isJson -and $Level -eq "RAW") {
            $prettyJson = $jsonObj | ConvertTo-Json -Depth 10
            if ($prefix) { "${prefix}:`n$prettyJson" } else { $prettyJson }
        } else {
            $Message
        }

        # DESIGN STANDARD: No timestamps at Level 0
        $consoleLine = if ($global:VerboseLevel -ge 1) { "[$timestamp] [$Level] [$Source] $consoleContent" } else { "[$Level] [$Source] $consoleContent" }
        
        $color = switch ($Level) {
            "ERROR"   { "Red" }
            "WARN"    { "Yellow" }
            "SUCCESS" { "Green" }
            "DEBUG"   { "Gray" }
            "TRACE"   { "Cyan" }
            "RAW"     { "Magenta" }
            Default   { "White" }
        }
        Write-Host $consoleLine -ForegroundColor $color
    }
}
