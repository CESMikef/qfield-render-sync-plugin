# QField Render Sync - Package Script
# ====================================
# 
# Creates a distributable ZIP file for the plugin.
# Run this script from the plugin directory.

param(
    [string]$Version = "1.0.0",
    [string]$OutputDir = ".."
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  QField Render Sync - Package Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get plugin directory (src folder)
$ScriptDir = $PSScriptRoot
$PluginDir = Join-Path (Split-Path $ScriptDir -Parent) "src"
$PluginName = "QField-Render-Sync"
$ZipName = "qfield-render-sync-v$Version.zip"
$OutputPath = Join-Path (Split-Path $ScriptDir -Parent) $ZipName

Write-Host "Plugin Directory: $PluginDir" -ForegroundColor Yellow
Write-Host "Output File: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Check if output file already exists
if (Test-Path $OutputPath) {
    Write-Host "Warning: Output file already exists!" -ForegroundColor Red
    $response = Read-Host "Overwrite? (y/n)"
    if ($response -ne "y") {
        Write-Host "Aborted." -ForegroundColor Red
        exit
    }
    Remove-Item $OutputPath -Force
}

# Files to include (from src directory)
$FilesToInclude = @(
    "main.qml",
    "metadata.txt",
    "icon.svg"
)

# Directories to include
$DirsToInclude = @(
    "components",
    "js"
)

Write-Host "Checking required files..." -ForegroundColor Cyan

# Check required files exist
$AllFilesExist = $true
foreach ($file in $FilesToInclude) {
    $filePath = Join-Path $PluginDir $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (MISSING)" -ForegroundColor Red
        $AllFilesExist = $false
    }
}

# Check required directories exist
foreach ($dir in $DirsToInclude) {
    $dirPath = Join-Path $PluginDir $dir
    if (Test-Path $dirPath) {
        $fileCount = (Get-ChildItem $dirPath -Recurse -File).Count
        Write-Host "  ✓ $dir/ ($fileCount files)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $dir/ (MISSING)" -ForegroundColor Red
        $AllFilesExist = $false
    }
}

if (-not $AllFilesExist) {
    Write-Host ""
    Write-Host "Error: Some required files are missing!" -ForegroundColor Red
    Write-Host "Please ensure all files are present before packaging." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Creating ZIP archive..." -ForegroundColor Cyan

# Create temporary directory for packaging
$TempDir = Join-Path $env:TEMP "qfield-render-sync-temp"
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Copy files to temp directory
foreach ($file in $FilesToInclude) {
    $source = Join-Path $PluginDir $file
    $dest = Join-Path $TempDir $file
    Copy-Item $source $dest
    Write-Host "  + $file" -ForegroundColor Gray
}

# Copy directories to temp directory
foreach ($dir in $DirsToInclude) {
    $source = Join-Path $PluginDir $dir
    $dest = Join-Path $TempDir $dir
    Copy-Item $source $dest -Recurse
    $fileCount = (Get-ChildItem $dest -Recurse -File).Count
    Write-Host "  + $dir/ ($fileCount files)" -ForegroundColor Gray
}

# Create ZIP archive
try {
    Compress-Archive -Path "$TempDir\*" -DestinationPath $OutputPath -Force
    Write-Host ""
    Write-Host "✓ Package created successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Display file info
    $zipInfo = Get-Item $OutputPath
    Write-Host "File: $($zipInfo.Name)" -ForegroundColor Cyan
    Write-Host "Size: $([math]::Round($zipInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    Write-Host "Path: $($zipInfo.FullName)" -ForegroundColor Cyan
    Write-Host ""
    
    # Calculate file counts
    $totalFiles = (Get-ChildItem $TempDir -Recurse -File).Count
    Write-Host "Contents: $totalFiles files" -ForegroundColor Cyan
    
    # List main components
    Write-Host ""
    Write-Host "Components included:" -ForegroundColor Yellow
    Write-Host "  - Main plugin (main.qml)" -ForegroundColor Gray
    Write-Host "  - UI components (components/)" -ForegroundColor Gray
    Write-Host "  - JavaScript modules (js/)" -ForegroundColor Gray
    Write-Host "  - Metadata and icon" -ForegroundColor Gray
    
} catch {
    Write-Host ""
    Write-Host "Error creating ZIP archive: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temp directory
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Next Steps:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Test the plugin:" -ForegroundColor Yellow
Write-Host "   - Install on test device" -ForegroundColor Gray
Write-Host "   - Verify all features work" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Deploy to production:" -ForegroundColor Yellow
Write-Host "   - Upload to GitHub releases, or" -ForegroundColor Gray
Write-Host "   - Host on web server, or" -ForegroundColor Gray
Write-Host "   - Distribute manually" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Configure QGIS project:" -ForegroundColor Yellow
Write-Host "   - Set project variables" -ForegroundColor Gray
Write-Host "   - Push to QFieldCloud" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Install on mobile devices:" -ForegroundColor Yellow
Write-Host "   - QField - Settings - Plugins" -ForegroundColor Gray
Write-Host "   - Install from URL or file" -ForegroundColor Gray
Write-Host ""
Write-Host "See DEPLOYMENT.md for detailed instructions." -ForegroundColor Cyan
Write-Host ""
