# Start QField with Logging
# This script starts QField and captures all console output to a log file

Write-Host "Starting QField with logging enabled..." -ForegroundColor Cyan
Write-Host ""

$LogFile = "$env:USERPROFILE\Documents\qfield_debug.log"
$QFieldExe = "C:\Program Files\QField\usr\bin\qfield.exe"

# Check if QField exists
if (-not (Test-Path $QFieldExe)) {
    Write-Host "ERROR: QField not found at: $QFieldExe" -ForegroundColor Red
    Write-Host "Please update the path in this script if QField is installed elsewhere." -ForegroundColor Yellow
    exit 1
}

# Check if QField is already running
$existingProcess = Get-Process -Name "qfield" -ErrorAction SilentlyContinue
if ($existingProcess) {
    Write-Host "WARNING: QField is already running (PID: $($existingProcess.Id))" -ForegroundColor Yellow
    Write-Host "Please close QField first, then run this script again." -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Do you want to force close QField now? (y/n)"
    if ($response -eq "y") {
        Stop-Process -Name "qfield" -Force
        Write-Host "QField closed. Starting in 2 seconds..." -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        exit 1
    }
}

# Remove old log file if it exists
if (Test-Path $LogFile) {
    Write-Host "Removing old log file..." -ForegroundColor Yellow
    Remove-Item $LogFile -Force
}

Write-Host "QField executable: $QFieldExe" -ForegroundColor Green
Write-Host "Log file: $LogFile" -ForegroundColor Green
Write-Host ""
Write-Host "QField will start now. All console output will be saved to the log file." -ForegroundColor Cyan
Write-Host "You can view the log file in real-time by opening it in a text editor." -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop QField and logging." -ForegroundColor Yellow
Write-Host ""

# Set environment variables to enable QML debugging
$env:QT_LOGGING_RULES="*.debug=true;qt.*.debug=false"
$env:QT_MESSAGE_PATTERN="[%{type}] %{message}"
$env:QML_CONSOLE_OUTPUT="1"

# Start QField with logging
& $QFieldExe 2>&1 | Tee-Object -FilePath $LogFile
