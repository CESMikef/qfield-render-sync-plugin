# Next Session Checklist

## 📋 Pre-Session Setup (5 minutes)

- [ ] Read `SESSION_NOTES_2025-10-13.md` (comprehensive overview)
- [ ] Read `PROGRESS_SUMMARY.md` (quick summary)
- [ ] Verify API is running: https://ces-qgis-qfield-v1.onrender.com/health
- [ ] Have database credentials ready

---

## 🔧 Implementation Tasks

### Task 1: Configure Database (5 minutes)

```sql
-- Connect to config database
\c prod_gis

-- Add WebDAV credentials
UPDATE api.client_config
SET config = config || jsonb_build_object(
    'WEBDAV_URL', 'https://qfield-photo-storage.onrender.com',
    'WEBDAV_USERNAME', 'your_username',
    'WEBDAV_PASSWORD', 'your_password'
)
WHERE client_id = 1;

-- Verify
SELECT 
    client_id,
    config->>'WEBDAV_URL' as webdav_url,
    config->>'WEBDAV_USERNAME' as username
FROM api.client_config
WHERE client_id = 1;
```

- [ ] Database configured
- [ ] Credentials verified

---

### Task 2: Update Plugin - webdav_client.js (30 minutes)

**File:** `src/js/webdav_client.js`

**Action:** Replace file reading logic with API upload

**Key Points:**
- Remove `uploadPhotoDirectly` function
- Add `uploadPhotoViaAPI` function
- Use FormData with multipart/form-data
- Handle API response

**Reference:** See `SESSION_NOTES_2025-10-13.md` section "What Still Needs to Be Done" → "Files to Modify" → "webdav_client.js"

- [ ] Function implemented
- [ ] Tested locally (if possible)

---

### Task 3: Update Plugin - sync_engine.js (15 minutes)

**File:** `src/js/sync_engine.js`

**Action:** Update to call new API-based upload

**Changes:**
- Replace `webdavModule.uploadPhotoWithCheck()` call
- Use `webdavModule.uploadPhotoViaAPI()` instead
- Remove separate API update step (API does both now)

- [ ] Function updated
- [ ] Imports verified

---

### Task 4: Update Plugin - main.qml (10 minutes)

**File:** `src/main.qml`

**Action:** Update configuration loading

**Changes:**
- Load `apiUrl` from project variables
- Load `apiToken` from project variables
- Remove WebDAV credential loading
- Update validation logic

- [ ] Config loading updated
- [ ] Validation updated

---

### Task 5: Update QGIS Project (5 minutes)

**Action:** Update project variables

**Add:**
```
qfield_render_sync_api_url = https://ces-qgis-qfield-v1.onrender.com
qfield_render_sync_api_token = your-token-here
qfield_render_sync_db_table = design.verify_poles
qfield_render_sync_photo_field = photo
```

**Remove:**
```
qfield_render_sync_webdav_url
qfield_render_sync_webdav_username
qfield_render_sync_webdav_password
```

- [ ] Variables updated
- [ ] Project saved
- [ ] Synced to QFieldCloud

---

### Task 6: Test API Endpoint (10 minutes)

```bash
# Test with curl
curl -X POST "https://ces-qgis-qfield-v1.onrender.com/api/v1/photos/upload-and-update" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test-photo.jpg" \
  -F "global_id=test-123" \
  -F "table=design.verify_poles" \
  -F "field=photo"
```

**Expected Response:**
```json
{
  "success": true,
  "global_id": "test-123",
  "updated_at": "2025-10-13T..."
}
```

- [ ] API responds successfully
- [ ] Photo uploaded to WebDAV
- [ ] Database record updated

---

### Task 7: Package and Deploy Plugin (10 minutes)

```powershell
# Package plugin
cd scripts
.\package.ps1 -Version "4.0.0"

# Commit and push
git add -A
git commit -m "v4.0.0 - Use API for photo upload (QML file access workaround)"
git push

# Create release
gh release create v4.0.0 `
  --title "v4.0.0 - API-Based Photo Upload" `
  --notes "Major update: Photos now upload via API instead of direct WebDAV" `
  ..\qfield-render-sync-v4.0.0.zip
```

- [ ] Plugin packaged
- [ ] Version committed
- [ ] Release created

---

### Task 8: Test in QField (30 minutes)

1. **Install Plugin**
   - [ ] Download v4.0.0 from GitHub
   - [ ] Install in QField
   - [ ] Restart QField

2. **Open Project**
   - [ ] Open project with updated variables
   - [ ] Verify plugin loads

3. **Capture Photo**
   - [ ] Capture test photo
   - [ ] Verify photo saved locally

4. **Run Sync**
   - [ ] Open Render Sync dialog
   - [ ] Verify 1 pending photo detected
   - [ ] Click "Start Sync"
   - [ ] Watch debug log

5. **Verify Success**
   - [ ] Success message shown
   - [ ] Check WebDAV storage
   - [ ] Check database record
   - [ ] Verify photo URL in database

---

## 🐛 Troubleshooting

### If API Returns 401 (Unauthorized)
- Check token is correct
- Verify token exists in `api.client_config`
- Check Authorization header format

### If API Returns 400 (Bad Request)
- Check WebDAV credentials are configured
- Verify table name includes schema
- Check all form fields are present

### If Upload Fails
- Check WebDAV server is accessible
- Verify WebDAV credentials
- Check file size (may timeout on large files)

### If Database Update Fails
- Verify global_id exists in table
- Check table name is correct
- Verify field name is correct

---

## 📊 Success Criteria

- [ ] Photo uploads from QField
- [ ] Photo appears in WebDAV storage
- [ ] Database record updated with URL
- [ ] Success message in QField
- [ ] No errors in debug log

---

## 📁 Quick Reference

### Important Files
- `SESSION_NOTES_2025-10-13.md` - Complete session notes
- `PROGRESS_SUMMARY.md` - Quick summary
- `qfield-photo-sync-api/QFIELD_INTEGRATION.md` - API integration guide

### Repositories
- Plugin: https://github.com/CESMikef/qfield-render-sync-plugin
- API: https://github.com/CESMikef/qfield-photo-sync-api

### API Endpoints
- Health: https://ces-qgis-qfield-v1.onrender.com/health
- Docs: https://ces-qgis-qfield-v1.onrender.com/docs
- Upload: https://ces-qgis-qfield-v1.onrender.com/api/v1/photos/upload-and-update

---

## ⏱️ Estimated Time

- **Setup:** 5 minutes
- **Implementation:** 1.5 hours
- **Testing:** 30 minutes
- **Total:** ~2 hours

---

**Good luck! You've got this! 🚀**
