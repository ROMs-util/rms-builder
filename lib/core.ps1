# ---------------------------------------------
# GLOBALS & PATHS
# ---------------------------------------------
$script:logFile = $null

# ---------------------------------------------
# LOGGING SYSTEM
# ---------------------------------------------
function Write-Log {
    param([string]$message, [string]$level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = "White"
    
    switch ($level) {
        "ERROR"   { $color = "Red" }
        "WARNING" { $color = "Yellow" }
        "SUCCESS" { $color = "Green" }
        "DEBUG"   { $color = "Cyan" }
    }

    Write-Host "[$level] $message" -ForegroundColor $color
}
