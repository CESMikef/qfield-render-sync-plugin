# Reinstall QField Plugin - Clean Install
# This script completely removes the old plugin and installs the new one

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QField Plugin Clean Reinstall" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop QField if running
Write-Host "Checking for running QField..." -ForegroundColor Yellow
$qfieldProcess = Get-Process -Name "qfield" -ErrorAction SilentlyContinue
if ($qfieldProcess) {
    Write-Host "QField is running. Stopping it..." -ForegroundColor Yellow
    Stop-Process -Name "qfield" -Force
    Start-Sleep -Seconds 2
    Write-Host "QField stopped." -ForegroundColor Green
} else {
    Write-Host "QField is not running." -ForegroundColor Green
}

# Find and remove old plugin files
Write-Host ""
Write-Host "Searching for old plugin installations..." -ForegroundColor Yellow

$searchPaths = @(
    "$env:APPDATA\OPENGIS.ch\QField",
    "$env:LOCALAPPDATA\QField",
    "$env:USERPROFILE\.qfield"
)

$found = $false
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Write-Host "Searching in: $path" -ForegroundColor Gray
        $pluginFiles = Get-ChildItem -Path $path -Recurse -Filter "*render*sync*" -ErrorAction SilentlyContinue
        if ($pluginFiles) {
            $found = $true
            Write-Host "Found plugin files:" -ForegroundColor Yellow
            foreach ($file in $pluginFiles) {
                Write-Host "  $($file.FullName)" -ForegroundColor Gray
            }
        }
    }
}

if (-not $found) {
    Write-Host "No old plugin files found." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Manual Steps Required" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Start QField" -ForegroundColor Yellow
Write-Host "2. Go to Settings → Plugins" -ForegroundColor Yellow
Write-Host "3. Find 'QField Render Sync' and click UNINSTALL" -ForegroundColor Yellow
Write-Host "4. Close QField completely" -ForegroundColor Yellow
Write-Host "5. Restart QField" -ForegroundColor Yellow
Write-Host "6. Go to Settings → Plugins → Install from URL" -ForegroundColor Yellow
Write-Host "7. Paste this URL:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v2.8.6/qfield-render-sync-v2.8.6.zip" -ForegroundColor Cyan
Write-Host ""
Write-Host "8. Click Install" -ForegroundColor Yellow
Write-Host "9. Enable the plugin" -ForegroundColor Yellow
Write-Host "10. Restart QField one more time" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart, you should see:" -ForegroundColor Green
Write-Host "  - Toast message: 'Render Sync v2.8.6 loaded successfully!'" -ForegroundColor Green
Write-Host ""
