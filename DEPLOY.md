# Quick Deployment Guide

**Status:** ✅ Ready to deploy v1.0.0  
**Date:** 2025-10-07

---

## 🚀 Deploy Now (3 Commands)

Run these commands in order:

### 1. Commit fixes
```powershell
cd c:\Users\mfenn\Documents\qfield-render-sync-plugin

git add .
git commit -m "Fix critical deployment issues - ready for v1.0.0

- Fixed function namespace issues in sync_engine.js
- Fixed Utils reference errors in api_client.js and webdav_client.js  
- Fixed ES6 syntax compatibility (const/let to var)
- Fixed QML syntax error in SyncDialog.qml
- Added initialization system for module references"
```

### 2. Push to GitHub
```powershell
git push origin main
```

### 3. Create release tag (triggers auto-build)
```powershell
git tag -a v1.0.0 -m "Release v1.0.0 - Production ready with all critical fixes"
git push origin v1.0.0
```

---

## ⏱️ What Happens Next

1. **GitHub Actions workflow starts** (1-2 minutes)
   - Checks out code
   - Packages plugin into ZIP
   - Creates GitHub Release
   - Attaches ZIP file

2. **Release is published** at:
   ```
   https://github.com/CESMikef/qfield-render-sync-plugin/releases/tag/v1.0.0
   ```

3. **Users can install** via URL:
   ```
   https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v1.0.0/qfield-render-sync-v1.0.0.zip
   ```

---

## 📱 User Installation Instructions

Share these with your field workers:

### Install in QField

1. Open **QField** app
2. Go to **☰ Menu → Settings → Plugins**
3. Tap **"Install plugin from URL"**
4. Paste:
   ```
   https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v1.0.0/qfield-render-sync-v1.0.0.zip
   ```
5. Tap **Install**
6. Enable the plugin
7. Restart QField

### Configure Token

On first launch:
1. Tap **"Sync Photos"** button
2. Enter your API token when prompted
3. Plugin will auto-load configuration from API
4. Start syncing!

---

## 🔧 Backend Configuration

Ensure your API endpoint returns config for the token:

```
GET /api/config?token={USER_TOKEN}
```

Response should include:
```json
{
  "webdav_url": "https://qfield-photo-storage-v3.onrender.com",
  "webdav_username": "qfield",
  "webdav_password": "qfield123",
  "db_table": "design.verify_poles",
  "photo_field": "photo"
}
```

---

## ✅ Pre-Deployment Checklist

Before running the commands:

- [x] All critical fixes applied
- [x] Code reviewed and tested
- [x] Version set to 1.0.0 in metadata.txt
- [x] GitHub workflow configured
- [x] Backend API ready at: https://qfield-photo-sync-api.onrender.com
- [x] WebDAV server ready
- [ ] Git repository clean (no uncommitted changes)
- [ ] Ready to deploy!

---

## 🆘 Troubleshooting

### Workflow Fails

Check the Actions tab on GitHub for error details.

### Tag Already Exists

Delete and recreate:
```powershell
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
# Then recreate as above
```

### Need to Update After Release

Create a new version:
```powershell
# Update version in src/metadata.txt to 1.0.1
git tag -a v1.0.1 -m "Release v1.0.1 - Bug fixes"
git push origin v1.0.1
```

---

## 📞 Support

- **Issues:** https://github.com/CESMikef/qfield-render-sync-plugin/issues
- **Documentation:** See `docs/` folder
- **API Docs:** https://qfield-photo-sync-api.onrender.com/docs

---

**Ready to deploy? Run the 3 commands above!** 🚀
