# QField Render Sync - Quick Start Guide

## 5-Minute Setup

Get up and running with QField Render Sync in 5 minutes.

---

## Step 1: Configure QGIS Project (2 minutes)

In QGIS Desktop:

1. **Project → Properties → Variables**
2. **Add these 7 variables:**

```
render_webdav_url       = https://qfield-photo-storage-v3.onrender.com
render_webdav_username  = qfield
render_webdav_password  = qfield123
render_api_url          = https://ces-qgis-qfield-v1.onrender.com
render_api_token        = qwrfzf23t2345t23fef23123r
render_db_table         = design.verify_poles
render_photo_field      = photo
```

3. **File → Save Project**
4. **Plugins → QFieldSync → Push to Cloud**

✅ **Done!** Configuration will auto-sync to all mobile devices.

---

## Step 2: Install Plugin (2 minutes)

On mobile device:

1. **QField → Settings → Plugins**
2. **Install from URL** or **Install from file**
3. **Enable plugin**
4. **Restart QField**

✅ **Done!** Plugin is ready to use.

---

## Step 3: Sync Project (1 minute)

In QField:

1. **Projects → Pull from Cloud**
2. **Open project**
3. **Look for "Sync Photos" button in toolbar**

✅ **Done!** Plugin loaded with configuration.

---

## Usage

### Capture Photo
1. Open feature form
2. Take photo
3. Save feature

### Sync Photo
1. Click **"Sync Photos"** button
2. Select layer
3. Click **"Start Sync"**
4. Wait for completion

### Verify
- Photo URL appears in feature
- Photo accessible via URL
- Database updated

---

## Troubleshooting

### Button Disabled?
- Check project variables are set
- Pull latest project from cloud
- Restart QField

### Upload Fails?
- Click "Test Connections" in dialog
- Check internet connection
- Verify credentials

### No Photos to Sync?
- Capture a photo first
- Check photo field name matches config
- Verify layer is selected

---

## Need Help?

- **Full Documentation**: See [README.md](README.md)
- **Deployment Guide**: See [DEPLOYMENT.md](DEPLOYMENT.md)
- **Testing Guide**: See [TESTING.md](TESTING.md)

---

## Configuration Reference

### Project Variables (QGIS Desktop)

| Variable | Purpose | Example |
|----------|---------|---------|
| `render_webdav_url` | Photo storage server | `https://qfield-photo-storage-v3.onrender.com` |
| `render_webdav_username` | WebDAV login | `qfield` |
| `render_webdav_password` | WebDAV password | `qfield123` |
| `render_api_url` | Database API | `https://ces-qgis-qfield-v1.onrender.com` |
| `render_api_token` | API authentication | `qwrfzf23t2345t23fef23123r` |
| `render_db_table` | Database table | `design.verify_poles` |
| `render_photo_field` | Photo field name | `photo` |

### Layer Requirements

Your layer must have:
- ✅ `global_id` or `globalid` field (UUID)
- ✅ Photo field (name matches `render_photo_field`)
- ✅ `updated_at` field (optional but recommended)

---

## Tips

- **Test First**: Use "Test Connections" before syncing
- **WiFi Recommended**: Faster uploads, no data charges
- **Batch Sync**: Sync multiple photos at once
- **Check Results**: Review success/failure count after sync
- **Retry Failures**: Failed uploads can be retried

---

## Keyboard Shortcut

Press **Ctrl+Shift+S** to open sync dialog quickly.

---

## What Gets Synced?

1. **Photo File** → Render WebDAV storage
2. **Photo URL** → PostgreSQL database
3. **Local Layer** → Updated with URL

---

## What Doesn't Get Synced?

- ❌ Photos already uploaded (URLs)
- ❌ Empty photo fields
- ❌ Features without global_id

---

## Next Steps

1. ✅ Configure project variables
2. ✅ Install plugin
3. ✅ Sync project
4. ✅ Capture test photo
5. ✅ Sync test photo
6. ✅ Verify upload
7. ✅ Train team
8. ✅ Go live!

---

**Ready to start?** Follow Step 1 above! 🚀

---

**Last Updated:** 2025-10-06  
**Version:** 1.0.0
