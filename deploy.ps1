# Quick Deployment Script for v4.0.0
# Run this to commit and push changes to GitHub

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  QField Render Sync v4.0.0 - Git Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is available
try {
    git --version | Out-Null
} catch {
    Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git for Windows from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

Write-Host "Checking repository status..." -ForegroundColor Yellow
Write-Host ""

# Show status
git status

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "Do you want to commit and push these changes? (y/n)"

if ($response -ne "y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Adding all changes..." -ForegroundColor Yellow
git add -A

Write-Host "Committing changes..." -ForegroundColor Yellow
git commit -m "v4.0.0 - API-based photo upload (QML file access workaround)"

Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Changes pushed to GitHub!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to: https://github.com/CESMikef/qfield-render-sync-plugin" -ForegroundColor Gray
Write-Host "2. Click 'Releases' → 'Draft a new release'" -ForegroundColor Gray
Write-Host "3. Tag: v4.0.0" -ForegroundColor Gray
Write-Host "4. Upload: qfield-render-sync-v4.0.0.zip" -ForegroundColor Gray
Write-Host "5. Publish release" -ForegroundColor Gray
Write-Host ""
Write-Host "See DEPLOYMENT_INSTRUCTIONS.md for detailed steps." -ForegroundColor Cyan
Write-Host ""
