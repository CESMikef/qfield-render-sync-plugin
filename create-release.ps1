# Create v4.0.0 Release with Git Tag
# This will trigger the GitHub Actions workflow

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Create v4.0.0 Release" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
$gitPath = $null
$possiblePaths = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $gitPath = $path
        break
    }
}

if (-not $gitPath) {
    # Try to find git in PATH
    try {
        $gitPath = (Get-Command git -ErrorAction Stop).Source
    } catch {
        Write-Host "ERROR: Git not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please use GitHub Desktop or run these commands manually:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  git add -A" -ForegroundColor Gray
        Write-Host "  git commit -m 'v4.0.0 - API-based photo upload'" -ForegroundColor Gray
        Write-Host "  git tag -a v4.0.0 -m 'v4.0.0 - API-Based Photo Upload'" -ForegroundColor Gray
        Write-Host "  git push origin main" -ForegroundColor Gray
        Write-Host "  git push origin v4.0.0" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}

Write-Host "Found Git at: $gitPath" -ForegroundColor Green
Write-Host ""

# Show current status
Write-Host "Current repository status:" -ForegroundColor Yellow
& $gitPath status
Write-Host ""

Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Add all changes" -ForegroundColor Gray
Write-Host "  2. Commit with message: 'v4.0.0 - API-based photo upload'" -ForegroundColor Gray
Write-Host "  3. Create tag: v4.0.0" -ForegroundColor Gray
Write-Host "  4. Push to GitHub (main branch + tag)" -ForegroundColor Gray
Write-Host "  5. Trigger GitHub Actions workflow to create release" -ForegroundColor Gray
Write-Host ""

$response = Read-Host "Continue? (y/n)"

if ($response -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Step 1: Adding all changes..." -ForegroundColor Cyan
& $gitPath add -A

Write-Host "Step 2: Committing changes..." -ForegroundColor Cyan
& $gitPath commit -m "v4.0.0 - API-based photo upload (QML file access workaround)"

Write-Host "Step 3: Creating tag v4.0.0..." -ForegroundColor Cyan
& $gitPath tag -a v4.0.0 -m "v4.0.0 - API-Based Photo Upload"

Write-Host "Step 4: Pushing to GitHub..." -ForegroundColor Cyan
& $gitPath push origin main

Write-Host "Step 5: Pushing tag to GitHub..." -ForegroundColor Cyan
& $gitPath push origin v4.0.0

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  SUCCESS!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "GitHub Actions workflow has been triggered!" -ForegroundColor Green
Write-Host ""
Write-Host "Check progress at:" -ForegroundColor Yellow
Write-Host "https://github.com/CESMikef/qfield-render-sync-plugin/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "Once complete, the release will be available at:" -ForegroundColor Yellow
Write-Host "https://github.com/CESMikef/qfield-render-sync-plugin/releases/tag/v4.0.0" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation URL:" -ForegroundColor Yellow
Write-Host "https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v4.0.0/qfield-render-sync-v4.0.0.zip" -ForegroundColor Cyan
Write-Host ""
