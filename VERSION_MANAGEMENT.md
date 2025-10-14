# Version Management Guide

## 📋 Version Numbering

This project uses **Semantic Versioning** (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR** (e.g., 4.x.x): Breaking changes, major architecture changes
- **MINOR** (e.g., x.1.x): New features, non-breaking changes
- **PATCH** (e.g., x.x.1): Bug fixes, minor improvements

---

## 🔄 Release Process Checklist

### Step 1: Determine Version Number

- **Bug fix?** → Increment PATCH (e.g., 4.0.0 → 4.0.1)
- **New feature?** → Increment MINOR (e.g., 4.0.1 → 4.1.0)
- **Breaking change?** → Increment MAJOR (e.g., 4.1.0 → 5.0.0)

### Step 2: Update Version in All Files

**Required files to update:**

1. **`src/metadata.txt`**
   ```ini
   version=X.Y.Z
   ```

2. **`src/main.qml`**
   ```javascript
   property string pluginVersion: "X.Y.Z"
   ```

3. **`CHANGELOG.md`**
   ```markdown
   ## vX.Y.Z (YYYY-MM-DD) - Brief Description
   
   ### Changes
   - List of changes
   ```

### Step 3: Package and Deploy

```powershell
# 1. Package plugin
Compress-Archive -Path "src\*" -DestinationPath "qfield-render-sync-vX.Y.Z.zip" -Force

# 2. Commit changes
git add -A
git commit -m "vX.Y.Z - Brief description"

# 3. Create tag
git tag -a vX.Y.Z -m "vX.Y.Z - Brief description"

# 4. Push to GitHub
git push origin main
git push origin vX.Y.Z
```

### Step 4: Verify Release

1. Check GitHub Actions: https://github.com/CESMikef/qfield-render-sync-plugin/actions
2. Verify release created: https://github.com/CESMikef/qfield-render-sync-plugin/releases
3. Test installation URL works

---

## 🚨 Important Rules

### ❌ NEVER Do This:
- **Don't overwrite existing tags** (use `--force`)
- **Don't skip version numbers** (e.g., 4.0.0 → 4.0.2)
- **Don't forget to update all version files**
- **Don't reuse version numbers**

### ✅ ALWAYS Do This:
- **Create new version for each release**
- **Update all version references**
- **Document changes in CHANGELOG.md**
- **Test before tagging**
- **Keep version numbers in sync**

---

## 📝 Quick Reference Commands

### Check Current Version
```powershell
# From metadata.txt
Get-Content src\metadata.txt | Select-String "version="

# From main.qml
Get-Content src\main.qml | Select-String "pluginVersion"
```

### List All Tags
```powershell
git tag -l
```

### View Latest Release
```powershell
git describe --tags --abbrev=0
```

### Delete Local Tag (if mistake)
```powershell
git tag -d vX.Y.Z
```

### Delete Remote Tag (CAREFUL!)
```powershell
# Only if absolutely necessary and release hasn't been used
git push origin --delete vX.Y.Z
```

---

## 📦 Version History

| Version | Date | Type | Description |
|---------|------|------|-------------|
| 4.0.1 | 2025-10-14 | Patch | Fix configuration (remove /api/config dependency) |
| 4.0.0 | 2025-10-14 | Major | API-based photo upload (breaking change) |
| 3.5.7 | 2025-10-13 | Patch | Debug diagnostics |
| 3.5.x | 2025-10-13 | Patch | Various debugging iterations |

---

## 🔧 Automated Version Update Script

Create `update-version.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$Description
)

Write-Host "Updating to version $NewVersion..." -ForegroundColor Cyan

# Update metadata.txt
(Get-Content src\metadata.txt) -replace 'version=.*', "version=$NewVersion" | Set-Content src\metadata.txt

# Update main.qml
(Get-Content src\main.qml) -replace 'property string pluginVersion: ".*"', "property string pluginVersion: `"$NewVersion`"" | Set-Content src\main.qml

# Add CHANGELOG entry
$date = Get-Date -Format "yyyy-MM-dd"
$entry = @"
## v$NewVersion ($date) - $Description

### Changes
- TODO: Add changes here

---

"@

$changelog = Get-Content CHANGELOG.md -Raw
$changelog = $changelog -replace '# Changelog', "# Changelog`n`n$entry"
$changelog | Set-Content CHANGELOG.md

Write-Host "✓ Version updated to $NewVersion" -ForegroundColor Green
Write-Host "✓ Don't forget to:" -ForegroundColor Yellow
Write-Host "  1. Update CHANGELOG.md with actual changes" -ForegroundColor Gray
Write-Host "  2. Review changes" -ForegroundColor Gray
Write-Host "  3. Run deployment script" -ForegroundColor Gray
```

**Usage:**
```powershell
.\update-version.ps1 -NewVersion "4.0.2" -Description "Bug fixes"
```

---

## 📚 Resources

- **Semantic Versioning:** https://semver.org/
- **GitHub Releases:** https://docs.github.com/en/repositories/releasing-projects-on-github
- **Git Tagging:** https://git-scm.com/book/en/v2/Git-Basics-Tagging

---

**Last Updated:** 2025-10-14
