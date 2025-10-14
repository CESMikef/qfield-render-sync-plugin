# v4.0.0 Deployment Instructions

**Package Created:** ✅ `qfield-render-sync-v4.0.0.zip` (30 KB)  
**Location:** `C:\Users\MikeF\Documents\GitHub\qfield-render-sync-plugin\qfield-render-sync-v4.0.0.zip`

---

## Step 1: Commit Changes to Git

Open PowerShell or Command Prompt and run:

```powershell
cd C:\Users\MikeF\Documents\GitHub\qfield-render-sync-plugin

# Check status
git status

# Add all changes
git add -A

# Commit with message
git commit -m "v4.0.0 - API-based photo upload (QML file access workaround)"

# Push to GitHub
git push origin main
```

---

## Step 2: Create GitHub Release

### Option A: Using GitHub CLI (if installed)

```powershell
gh release create v4.0.0 `
  --title "v4.0.0 - API-Based Photo Upload" `
  --notes "Major update: Photos now upload via API instead of direct WebDAV. This works around QML file access limitations." `
  qfield-render-sync-v4.0.0.zip
```

### Option B: Using GitHub Web Interface (Recommended)

1. **Go to GitHub Repository:**
   - Navigate to: https://github.com/CESMikef/qfield-render-sync-plugin

2. **Create New Release:**
   - Click "Releases" (right sidebar)
   - Click "Draft a new release"

3. **Fill in Release Details:**
   - **Tag:** `v4.0.0`
   - **Target:** `main` branch
   - **Title:** `v4.0.0 - API-Based Photo Upload`
   
4. **Release Notes:**
   ```markdown
   ## 🚀 Major Update: API-Based Photo Upload
   
   This version introduces a significant architectural change to work around QML's file access limitations.
   
   ### What's New
   - **API-Based Upload:** Photos now upload via API endpoint instead of direct WebDAV
   - **Simplified Configuration:** Only API credentials required (WebDAV credentials stored server-side)
   - **Better Error Handling:** Detailed error messages from API
   - **Single-Step Upload:** API handles both WebDAV upload and database update
   
   ### Breaking Changes
   - Configuration now requires API URL and token only
   - WebDAV credentials must be configured in API database (not in plugin)
   - See migration notes below
   
   ### Migration from v3.x
   1. Configure WebDAV credentials in API database:
      ```sql
      UPDATE api.client_config
      SET config = config || jsonb_build_object(
          'WEBDAV_URL', 'https://qfield-photo-storage.onrender.com',
          'WEBDAV_USERNAME', 'your_username',
          'WEBDAV_PASSWORD', 'your_password'
      )
      WHERE client_id = 1;
      ```
   2. Install v4.0.0 plugin
   3. Enter API token when prompted
   
   ### Installation
   Download the ZIP file and install in QField:
   1. QField → Settings → Plugins
   2. Install from ZIP file
   3. Restart QField
   
   ### Requirements
   - QField 3.0+
   - API v1.1.0+ with `/api/v1/photos/upload-and-update` endpoint
   - WebDAV credentials configured in API database
   
   ### Documentation
   - See `V4_IMPLEMENTATION_SUMMARY.md` for technical details
   - See `NEXT_SESSION_CHECKLIST.md` for setup guide
   ```

5. **Upload ZIP File:**
   - Drag and drop `qfield-render-sync-v4.0.0.zip` to the "Attach binaries" section
   - Or click "Attach binaries by dropping them here or selecting them"

6. **Publish Release:**
   - Click "Publish release"

---

## Step 3: Get Installation URL

After creating the release, the installation URL will be:

```
https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v4.0.0/qfield-render-sync-v4.0.0.zip
```

---

## Step 4: Install in QField

### Method 1: Direct URL Installation (Easiest)

1. Open QField on your device
2. Go to **Settings → Plugins**
3. Tap **"Install from URL"**
4. Enter URL:
   ```
   https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v4.0.0/qfield-render-sync-v4.0.0.zip
   ```
5. Tap **Install**
6. Restart QField

### Method 2: Manual Installation

1. Download ZIP file to your device
2. Open QField
3. Go to **Settings → Plugins**
4. Tap **"Install from file"**
5. Select the downloaded ZIP file
6. Restart QField

---

## Step 5: Configure Plugin

1. **Open QField** and load your project
2. **Tap the Sync Photos button** in the toolbar
3. **Enter your API token** when prompted
4. **Verify configuration loads** successfully

---

## Step 6: Test Upload

1. **Capture a test photo** in QField
2. **Open Render Sync dialog**
3. **Verify photo is detected**
4. **Click "Start Sync"**
5. **Watch progress messages**
6. **Verify success:**
   - Success message in QField
   - Photo in WebDAV storage
   - Database record updated

---

## Troubleshooting

### If Release Creation Fails
- Ensure you're logged into GitHub
- Check you have write access to the repository
- Verify the ZIP file exists at the specified path

### If Installation Fails
- Check QField version (requires 3.0+)
- Verify URL is correct and accessible
- Try manual installation method

### If Upload Fails
- Check API is running: https://ces-qgis-qfield-v1.onrender.com/health
- Verify API token is correct
- Confirm WebDAV credentials configured in database
- Check QField logs for detailed error messages

---

## Quick Reference

**Repository:** https://github.com/CESMikef/qfield-render-sync-plugin  
**Release URL:** https://github.com/CESMikef/qfield-render-sync-plugin/releases/tag/v4.0.0  
**Installation URL:** https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v4.0.0/qfield-render-sync-v4.0.0.zip  
**API Endpoint:** https://ces-qgis-qfield-v1.onrender.com  
**API Docs:** https://ces-qgis-qfield-v1.onrender.com/docs

---

## Next Steps After Deployment

1. ✅ Create GitHub release
2. ✅ Get installation URL
3. ⏳ Configure WebDAV credentials in database
4. ⏳ Test installation in QField
5. ⏳ Test photo upload end-to-end
6. ⏳ Update project documentation if needed

---

**Ready to deploy!** 🚀
