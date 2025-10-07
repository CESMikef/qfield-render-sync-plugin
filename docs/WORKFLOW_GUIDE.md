# QField Render Sync - Complete Workflow Guide

## Overview

This guide walks you through the complete workflow from creating a QGIS project to capturing photos in the field and syncing them to your infrastructure.

---

## 🎯 Workflow Summary

```
1. OFFICE: Create & Configure QGIS Project
2. OFFICE: Upload Project to QFieldCloud
3. FIELD: Download Project to Mobile Device
4. FIELD: Capture Photos On-Site
5. FIELD: Sync Photos to Render & Database
6. OFFICE: View Updated Data
```

---

## Phase 1: Office Setup (Administrator)

### Step 1.1: Create QGIS Project

**Time Required:** 15-30 minutes

1. **Open QGIS Desktop**
   - Launch QGIS 3.x

2. **Create New Project**
   - File → New Project
   - Save as: `field_verification.qgs`

3. **Add Your Data Layer**
   - Layer → Add Layer → Add PostGIS Layer
   - Connect to your PostgreSQL database
   - Add table: `design.verify_poles`
   
   **Required Fields:**
   - `global_id` (UUID) - Unique identifier
   - `photo` (TEXT) - Photo field (will store URLs)
   - `updated_at` (TIMESTAMP) - Last update time
   - Other attribute fields as needed

4. **Configure Layer for QField**
   - Right-click layer → Properties
   - **Attributes Form** tab:
     - Set `global_id` widget to "Hidden" (auto-generated)
     - Set `photo` widget to "Attachment"
     - Configure other fields as needed
   
5. **Set Up Photo Capture**
   - In Attributes Form:
   - Find `photo` field
   - Widget Type: "Attachment"
   - Default path: `@project_folder + '/DCIM'`
   - Relative paths: Checked

---

### Step 1.2: Configure Plugin Settings

**Time Required:** 5 minutes

1. **Open Project Properties**
   - Project → Properties → Variables

2. **Add Configuration Variables**
   
   Click the **"+"** button and add each variable:

   | Variable Name | Value | Description |
   |--------------|-------|-------------|
   | `render_webdav_url` | `https://qfield-photo-storage-v3.onrender.com` | WebDAV server URL |
   | `render_webdav_username` | `qfield` | WebDAV username |
   | `render_webdav_password` | `qfield123` | WebDAV password |
   | `render_api_url` | `https://ces-qgis-qfield-v1.onrender.com` | REST API URL |
   | `render_api_token` | `qwrfzf23t2345t23fef23123r` | API token (CES client) |
   | `render_db_table` | `design.verify_poles` | Database table |
   | `render_photo_field` | `photo` | Photo field name |

3. **Verify Variables**
   - Check all 7 variables are entered
   - Verify no typos in variable names (case-sensitive!)
   - Click **OK**

4. **Save Project**
   - File → Save Project
   - Confirm save successful

---

### Step 1.3: Upload to QFieldCloud

**Time Required:** 5-10 minutes

1. **Install QFieldSync Plugin** (if not already installed)
   - Plugins → Manage and Install Plugins
   - Search: "QFieldSync"
   - Click Install Plugin

2. **Configure QFieldCloud**
   - Plugins → QFieldSync → Synchronize
   - Log in to QFieldCloud account
   - Create new cloud project or select existing

3. **Configure Project Settings**
   - **Project name:** `Field Verification`
   - **Layers:** Select your verification layer
   - **Offline editing:** Enable
   - **Photo storage:** Keep original path (important!)

4. **Push to Cloud**
   - Click **"Push to Cloud"**
   - Wait for upload to complete (1-5 minutes)
   - Verify success message

5. **Verify on QFieldCloud**
   - Go to https://app.qfield.cloud
   - Find your project
   - Check project appears correctly

---

## Phase 2: Mobile Setup (Field Worker)

### Step 2.1: Install QField Plugin

**Time Required:** 5 minutes (one-time setup)

1. **Open QField App**
   - Launch QField on mobile device

2. **Go to Plugin Settings**
   - Tap ☰ menu
   - Settings → Plugins

3. **Install Plugin**
   
   **Option A: From URL**
   - Tap "Install from URL"
   - Enter: `https://your-server.com/qfield-render-sync-v1.0.0.zip`
   - Tap Install
   
   **Option B: From File**
   - Transfer ZIP to device
   - Tap "Install from file"
   - Browse to ZIP file
   - Tap Install

4. **Enable Plugin**
   - Toggle switch to ON
   - Restart QField

---

### Step 2.2: Download Project

**Time Required:** 2-5 minutes

1. **Open Projects**
   - Tap ☰ menu
   - Projects

2. **Connect to QFieldCloud**
   - Tap cloud icon
   - Log in if needed

3. **Download Project**
   - Find "Field Verification" project
   - Tap download icon
   - Wait for sync (1-5 minutes)
   - Project downloads with configuration

4. **Open Project**
   - Tap project to open
   - Map loads with your layer

5. **Verify Plugin Loaded**
   - Look for **"Sync Photos"** button in toolbar
   - Button should be green (enabled)
   - If disabled, check configuration

---

## Phase 3: Field Work

### Step 3.1: Navigate to Site

**Time Required:** Varies

1. **Enable GPS**
   - Tap GPS icon
   - Allow location permissions
   - Wait for GPS lock

2. **Navigate to Feature**
   - Pan/zoom map to target location
   - Or use search if available
   - GPS shows your current position

3. **Select Feature**
   - Tap on pole/feature to verify
   - Feature highlights
   - Attribute form opens

---

### Step 3.2: Capture Photo

**Time Required:** 1-2 minutes per feature

1. **Open Feature Form**
   - Feature form displays
   - Shows all attributes

2. **Take Photo**
   - Find photo field
   - Tap camera icon
   - **Take Photo** (or choose from gallery)
   - Camera opens

3. **Capture Image**
   - Frame the subject
   - Tap shutter button
   - Review photo
   - Tap ✓ to accept (or ✗ to retake)

4. **Photo Saved Locally**
   - Photo saves to: `DCIM/photo_001.jpg`
   - Photo field shows: `DCIM/photo_001.jpg` (local path)
   - This is normal - will be synced later

5. **Fill Other Attributes**
   - Complete other fields as needed
   - Condition, notes, etc.

6. **Save Feature**
   - Tap ✓ (checkmark) to save
   - Feature saved locally
   - Form closes

7. **Repeat for More Features**
   - Continue capturing photos
   - All photos stored locally
   - Sync when ready (WiFi recommended)

---

### Step 3.3: Sync Photos to Server

**Time Required:** 30 seconds - 5 minutes (depending on photo count)

#### When to Sync

- ✅ **Best:** End of day, on WiFi
- ✅ **Good:** After capturing 5-10 photos
- ⚠️ **Caution:** On mobile data (uses data)
- ❌ **Avoid:** While capturing (wait until done)

#### Sync Process

1. **Open Sync Dialog**
   - Tap **"Sync Photos"** button in toolbar
   - Or press Ctrl+Shift+S (if keyboard)
   - Dialog opens

2. **Select Layer**
   - Layer dropdown shows available layers
   - Select: "verify_poles" (or your layer name)
   - Pending count shows: "Pending: 5" (example)

3. **Test Connections** (Optional but Recommended)
   - Tap **"Test Connections"**
   - Wait 5-10 seconds
   - Results show:
     - WebDAV: ✓ Connected
     - API: ✓ Connected
   - If errors, check internet connection

4. **Start Sync**
   - Tap **"Start Sync"** button
   - Progress bar appears
   - Status updates:
     - "Checking for duplicates..."
     - "Uploading... 45%"
     - "Updating database..."
     - "Updating local layer..."
     - "Complete"

5. **Monitor Progress**
   - Current photo: "Photo 3 of 5"
   - Progress bar: 0-100%
   - Success count updates
   - Failure count (if any)

6. **Review Results**
   - Sync completes
   - Summary shows:
     - Total: 5
     - Succeeded: 5
     - Failed: 0
   - Tap **OK**

7. **Verify Sync**
   - Open a synced feature
   - Photo field now shows:
     - `https://qfield-photo-storage-v3.onrender.com/abc123_2025-10-06.jpg`
   - Photo is now a URL (not local path)
   - Tap photo to view online

---

### Step 3.4: Sync Project Back to QFieldCloud

**Time Required:** 2-5 minutes

1. **Sync Attributes**
   - Tap ☰ menu
   - Synchronize
   - Tap **"Synchronize"**
   - Attributes upload to QFieldCloud
   - Photo URLs included

2. **Verify Sync**
   - Check sync status
   - "Sync successful" message
   - All changes uploaded

**Note:** Photos are already on Render WebDAV, not QFieldCloud!

---

## Phase 4: Office Review

### Step 4.1: Pull Updates from QFieldCloud

**Time Required:** 2-5 minutes

1. **Open QGIS Desktop**
   - Open your project

2. **Pull from Cloud**
   - Plugins → QFieldSync → Synchronize
   - Click **"Pull from Cloud"**
   - Wait for download
   - Changes applied to local project

3. **Refresh Layer**
   - Right-click layer
   - Refresh
   - New data appears

---

### Step 4.2: View Photos

**Time Required:** 1 minute per feature

1. **Open Feature**
   - Use Identify tool
   - Click on verified feature
   - Attributes display

2. **View Photo**
   - Photo field shows URL
   - Click URL
   - Photo opens in browser
   - Image loads from Render WebDAV

3. **Verify Data**
   - Check photo quality
   - Verify attributes
   - Confirm location

---

## 📊 Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    OFFICE (QGIS Desktop)                     │
│                                                              │
│  1. Create project with PostgreSQL layer                    │
│  2. Configure photo field (Attachment widget)               │
│  3. Add project variables (7 variables)                     │
│  4. Save project                                            │
│  5. Upload to QFieldCloud                                   │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  QFieldCloud    │
                  │  • Stores project│
                  │  • Syncs data   │
                  └────────┬────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE (QField App)                       │
│                                                              │
│  6. Install plugin (one-time)                               │
│  7. Download project from QFieldCloud                       │
│  8. Navigate to site (GPS)                                  │
│  9. Select feature                                          │
│  10. Take photo → Saves to DCIM/photo_001.jpg              │
│  11. Fill attributes                                        │
│  12. Save feature                                           │
│                                                              │
│  13. Open Sync Photos dialog                                │
│  14. Select layer                                           │
│  15. Click "Start Sync"                                     │
│      ├─ Upload photo to WebDAV                             │
│      ├─ Update database via API                            │
│      └─ Update local layer with URL                        │
│                                                              │
│  16. Sync project back to QFieldCloud                       │
│                                                              │
└──────────────────────────┬──────────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
            ▼                             ▼
   ┌─────────────────┐         ┌─────────────────┐
   │  Render WebDAV  │         │    REST API     │
   │  • Photo files  │         │  • Updates DB   │
   └─────────────────┘         └────────┬────────┘
                                        │
                                        ▼
                               ┌─────────────────┐
                               │   PostgreSQL    │
                               │  • Photo URLs   │
                               │  • Attributes   │
                               └─────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    OFFICE (QGIS Desktop)                     │
│                                                              │
│  17. Pull from QFieldCloud                                  │
│  18. View updated data                                      │
│  19. Click photo URLs to view images                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Daily Field Workflow (Quick Reference)

### Morning (Office)
1. ✅ Check project is up-to-date
2. ✅ Verify plugin installed on mobile
3. ✅ Sync latest project to mobile

### In Field
1. 📍 Navigate to site
2. 📸 Capture photos (stored locally)
3. ✏️ Fill attributes
4. 💾 Save features
5. 🔄 Sync photos (when on WiFi)
6. ☁️ Sync to QFieldCloud

### Evening (Office)
1. ⬇️ Pull from QFieldCloud
2. 👀 Review captured data
3. ✅ Verify photo quality
4. 📊 Generate reports

---

## ⚡ Quick Tips

### For Best Results

- **WiFi for Sync:** Sync photos on WiFi to save mobile data
- **Batch Capture:** Take multiple photos, sync once
- **Test First:** Use "Test Connections" before syncing
- **Check URLs:** After sync, verify photos show URLs not paths
- **Regular Sync:** Sync daily to avoid large backlogs

### Troubleshooting

**Photos not syncing?**
- Check internet connection
- Verify "Pending" count shows photos
- Test connections first
- Check QField logs

**Button disabled?**
- Pull latest project from cloud
- Check project variables are set
- Restart QField

**Upload fails?**
- Switch to WiFi
- Check Render services are running
- Try again later

---

## 📋 Checklists

### First-Time Setup Checklist (Administrator)

- [ ] QGIS project created
- [ ] PostgreSQL layer added
- [ ] Photo field configured (Attachment widget)
- [ ] 7 project variables added
- [ ] Project saved
- [ ] QFieldSync plugin installed
- [ ] Project uploaded to QFieldCloud
- [ ] Plugin ZIP file hosted/available
- [ ] Field workers trained

### First-Time Setup Checklist (Field Worker)

- [ ] QField app installed
- [ ] Plugin installed from URL/file
- [ ] Plugin enabled
- [ ] QFieldCloud account configured
- [ ] Project downloaded
- [ ] Plugin button visible (green)
- [ ] Test connections successful
- [ ] Training completed

### Daily Field Checklist

- [ ] Project synced to mobile
- [ ] GPS enabled
- [ ] Battery charged
- [ ] Navigate to site
- [ ] Capture photos
- [ ] Fill attributes
- [ ] Save features
- [ ] Sync photos (WiFi)
- [ ] Sync to QFieldCloud
- [ ] Verify sync successful

---

## 🎓 Training Guide

### For Field Workers (30 minutes)

1. **Introduction** (5 min)
   - Overview of workflow
   - Why we use this system

2. **Navigation** (5 min)
   - Open project
   - Use GPS
   - Find features

3. **Photo Capture** (10 min)
   - Open feature form
   - Take photo
   - Fill attributes
   - Save feature

4. **Sync Process** (10 min)
   - Open sync dialog
   - Test connections
   - Start sync
   - Review results

### For Administrators (60 minutes)

1. **Project Setup** (20 min)
   - Create QGIS project
   - Configure layers
   - Set up photo fields

2. **Plugin Configuration** (15 min)
   - Add project variables
   - Understand each setting
   - Save and test

3. **QFieldCloud** (15 min)
   - Upload project
   - Manage users
   - Monitor sync

4. **Troubleshooting** (10 min)
   - Common issues
   - Log checking
   - Support resources

---

## 📞 Support

### Common Questions

**Q: Do photos use QFieldCloud storage?**  
A: No! Photos go to Render WebDAV. Only attributes sync via QFieldCloud.

**Q: Can I sync without internet?**  
A: No. Photos need internet to upload. Capture offline, sync when online.

**Q: How much data does sync use?**  
A: Depends on photo size. 5MB photo = 5MB data. Use WiFi!

**Q: What if sync fails?**  
A: Photos stay local. Try again when connection improves.

**Q: Can I delete local photos after sync?**  
A: Yes! Once synced (URL shown), local photos can be deleted.

---

**Last Updated:** 2025-10-06  
**Workflow Guide Version:** 1.0.0
