# QField Render Sync - Deployment Guide

## Overview

This guide covers the complete deployment process for the QField Render Sync plugin, from initial setup to field testing.

## Prerequisites

### Server Infrastructure (Already Deployed)
- ✅ REST API: `https://ces-qgis-qfield-v1.onrender.com`
- ✅ WebDAV Server: `https://qfield-photo-storage-v3.onrender.com`
- ✅ PostgreSQL Database: `prod_gis`

### Required Tools
- QGIS Desktop (3.x or higher)
- QField mobile app (3.0 or higher)
- QFieldCloud account
- Text editor (for configuration)
- Git (optional, for version control)

## Deployment Steps

### Phase 1: Package Plugin

#### Step 1: Verify Plugin Files

Ensure all files are present:

```
QField-Render-Sync/
├── main.qml
├── metadata.txt
├── icon.svg
├── components/
│   └── SyncDialog.qml
├── js/
│   ├── utils.js
│   ├── webdav_client.js
│   ├── api_client.js
│   └── sync_engine.js
├── README.md
└── DEPLOYMENT.md (this file)
```

#### Step 2: Create Plugin Package

**Windows (PowerShell):**
```powershell
cd QField-Render-Sync
Compress-Archive -Path * -DestinationPath ..\qfield-render-sync-v1.0.0.zip
```

**Linux/Mac:**
```bash
cd QField-Render-Sync
zip -r ../qfield-render-sync-v1.0.0.zip *
```

#### Step 3: Host Plugin Package

**Option A: GitHub Releases**
1. Create GitHub repository
2. Create new release (v1.0.0)
3. Upload ZIP file as release asset
4. Copy download URL

**Option B: Web Server**
1. Upload ZIP to your web server
2. Note public URL
3. Ensure HTTPS access

**Option C: Local Installation**
1. Keep ZIP file for manual installation
2. Transfer to mobile device via USB/cloud

---

### Phase 2: Configure QGIS Project

#### Step 1: Open Project in QGIS Desktop

1. Launch QGIS Desktop
2. Open your field data collection project
3. Verify layers are configured correctly

#### Step 2: Add Project Variables

1. Go to **Project → Properties → Variables**
2. Click **"+"** to add each variable:

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `render_webdav_url` | `https://qfield-photo-storage-v3.onrender.com` | No trailing slash |
| `render_webdav_username` | `qfield` | Case-sensitive |
| `render_webdav_password` | `qfield123` | Keep secure |
| `render_api_url` | `https://ces-qgis-qfield-v1.onrender.com` | No trailing slash |
| `render_api_token` | `qwrfzf23t2345t23fef23123r` | CES client token |
| `render_db_table` | `design.verify_poles` | Schema.table format |
| `render_photo_field` | `photo` | Field name in layer |

**Important Notes:**
- Variable names are case-sensitive
- No spaces in variable names
- Values should not have quotes
- URLs should not have trailing slashes

#### Step 3: Verify Layer Configuration

Ensure your layer has:
- ✅ `global_id` or `globalid` field (UUID)
- ✅ Photo field (name matches `render_photo_field` variable)
- ✅ `updated_at` field (timestamp, optional but recommended)

#### Step 4: Save Project

1. Click **OK** to close Project Properties
2. **File → Save Project**
3. Verify project saved successfully

#### Step 5: Test Variables (Optional)

Open Python Console in QGIS:
```python
project = QgsProject.instance()
print("WebDAV URL:", project.customVariable('render_webdav_url'))
print("API URL:", project.customVariable('render_api_url'))
print("DB Table:", project.customVariable('render_db_table'))
```

---

### Phase 3: Upload to QFieldCloud

#### Step 1: Install QFieldSync Plugin (if not installed)

1. **Plugins → Manage and Install Plugins**
2. Search for "QFieldSync"
3. Click **Install Plugin**
4. Close plugin manager

#### Step 2: Configure QFieldSync

1. **Plugins → QFieldSync → Synchronize**
2. Select your QFieldCloud project or create new one
3. Configure layers for offline use
4. Set photo storage to "Keep original path" (important!)

#### Step 3: Push to QFieldCloud

1. Click **"Push to Cloud"**
2. Wait for upload to complete
3. Verify success message
4. Note project name/ID

#### Step 4: Verify Upload

1. Go to https://app.qfield.cloud
2. Log in to your account
3. Find your project
4. Verify project variables are included (check project settings)

---

### Phase 4: Install Plugin on Mobile

#### Method A: Install from URL (Recommended)

1. Open QField on mobile device
2. Go to **Settings → Plugins**
3. Click **"Install plugin from URL"**
4. Enter plugin URL (from Phase 1, Step 3)
5. Click **Install**
6. Wait for download and installation
7. Enable plugin (toggle switch)
8. Restart QField

#### Method B: Install from File

1. Transfer ZIP file to mobile device
2. Open QField
3. Go to **Settings → Plugins**
4. Click **"Install from file"**
5. Browse to ZIP file
6. Click **Install**
7. Enable plugin
8. Restart QField

#### Method C: Manual Installation (Advanced)

1. Connect device to computer
2. Navigate to QField plugin directory:
   - Android: `/sdcard/Android/data/ch.opengis.qfield/files/QField/plugins/`
   - iOS: Use iTunes File Sharing
3. Extract ZIP contents to `QField-Render-Sync/` folder
4. Restart QField
5. Enable plugin in settings

---

### Phase 5: Sync Project to Mobile

#### Step 1: Download Project

1. Open QField
2. Go to **Projects** tab
3. Find your project in QFieldCloud projects
4. Click **Download** icon
5. Wait for sync to complete

#### Step 2: Verify Project Variables

1. Open project in QField
2. Check if plugin loaded (look for toolbar button)
3. If button is disabled, check configuration

#### Step 3: Test Plugin

1. Click **"Sync Photos"** button
2. Dialog should open
3. Click **"Test Connections"**
4. Verify both WebDAV and API show "✓ Connected"

---

### Phase 6: Field Testing

#### Test Checklist

**1. Capture Photo**
- [ ] Open feature form
- [ ] Take photo
- [ ] Photo saved locally
- [ ] Photo field shows local path

**2. Sync Photo**
- [ ] Open Render Sync plugin
- [ ] Select layer
- [ ] Pending count shows 1
- [ ] Click "Start Sync"
- [ ] Progress bar updates
- [ ] Upload completes successfully

**3. Verify Results**
- [ ] Success message displayed
- [ ] Photo field now shows URL
- [ ] Photo accessible via URL (open in browser)
- [ ] Database updated (check PostgreSQL)
- [ ] WebDAV storage contains photo

**4. Test Error Handling**
- [ ] Test with no internet (should show error)
- [ ] Test with wrong credentials (should fail gracefully)
- [ ] Test with missing feature (should report error)

**5. Test Multiple Photos**
- [ ] Capture 5-10 photos
- [ ] Sync all at once
- [ ] Verify all uploaded
- [ ] Check progress tracking
- [ ] Verify no duplicates

---

## Configuration Management

### Updating Configuration

When you need to change settings (e.g., rotate API token):

1. **QGIS Desktop**: Update project variables
2. **Save project**
3. **Push to QFieldCloud** (Plugins → QFieldSync → Synchronize)
4. **Mobile devices**: Pull updated project
5. **Verify**: Plugin automatically uses new settings

### Token Rotation

To rotate API token:

1. Generate new token on Render
2. Update `render_api_token` in QGIS project
3. Save and push to QFieldCloud
4. All devices get new token on next sync
5. Old token can be deactivated

### Multi-Project Setup

For multiple projects with different configurations:

1. Each project has its own variables
2. Plugin reads variables from active project
3. No cross-contamination between projects
4. Easy to manage different clients/sites

---

## Troubleshooting Deployment

### Plugin Not Appearing

**Symptoms:** No toolbar button, plugin not in settings

**Solutions:**
1. Verify QField version (3.0+)
2. Check plugin files are complete
3. Reinstall plugin
4. Check QField logs for errors
5. Restart QField

### Configuration Not Loading

**Symptoms:** Button disabled, "Configuration incomplete" message

**Solutions:**
1. Verify project variables in QGIS Desktop
2. Check variable names (case-sensitive)
3. Ensure project was saved
4. Re-push to QFieldCloud
5. Pull latest project on mobile
6. Check QField logs

### Connection Test Fails

**WebDAV Connection Failed:**
- Verify WebDAV URL is correct
- Check username/password
- Test WebDAV with Cyberduck
- Ensure WebDAV service is running

**API Connection Failed:**
- Verify API URL is correct
- Check API token is valid
- Test API with curl/Postman
- Ensure API service is running (not sleeping)

### Upload Fails

**Photo Upload Failed:**
- Check internet connection
- Verify photo file exists
- Check file size (large files may timeout)
- Try again on WiFi

**Database Update Failed:**
- Verify feature exists in database
- Check global_id is correct
- Verify table name matches
- Check API logs for errors

---

## Monitoring and Maintenance

### Monitor API Usage

1. Go to Render dashboard
2. View API logs
3. Check for errors
4. Monitor request volume

### Monitor WebDAV Storage

1. Connect with Cyberduck
2. Check storage usage
3. Verify photos are uploading
4. Clean up old photos if needed

### Database Monitoring

1. Connect to PostgreSQL
2. Query photo URLs:
   ```sql
   SELECT global_id, photo, updated_at 
   FROM design.verify_poles 
   WHERE photo IS NOT NULL 
   ORDER BY updated_at DESC 
   LIMIT 10;
   ```
3. Verify recent uploads

### Regular Maintenance

- **Weekly**: Check API logs for errors
- **Monthly**: Review storage usage
- **Quarterly**: Rotate API tokens
- **As needed**: Update plugin version

---

## Rollback Procedure

If deployment fails:

1. **Revert Project Variables**
   - Remove or update incorrect variables
   - Save and push to QFieldCloud

2. **Uninstall Plugin**
   - QField → Settings → Plugins
   - Disable or uninstall plugin

3. **Restore Previous Project**
   - Revert to previous QGIS project version
   - Push to QFieldCloud

4. **Investigate Issues**
   - Check logs
   - Test connections
   - Verify configuration

---

## Production Checklist

Before going live:

- [ ] API deployed and tested
- [ ] WebDAV server running
- [ ] Database schema verified
- [ ] Project variables configured
- [ ] Plugin packaged and hosted
- [ ] Test project synced
- [ ] Plugin installed on test device
- [ ] End-to-end test completed
- [ ] Error handling verified
- [ ] Documentation reviewed
- [ ] Team trained on usage
- [ ] Backup procedures in place

---

## Support Resources

- **Plugin README**: Usage instructions
- **API Documentation**: https://ces-qgis-qfield-v1.onrender.com/docs
- **QField Documentation**: https://docs.qfield.org
- **QGIS Documentation**: https://docs.qgis.org

---

## Version History

### v1.0.0 (2025-10-06)
- Initial release
- WebDAV upload support
- REST API integration
- Project variable configuration
- Progress tracking
- Error handling

---

**Last Updated:** 2025-10-06  
**Deployment Guide Version:** 1.0.0
