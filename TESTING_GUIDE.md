# Testing Guide - v2.1.3 with Debug Logging

## 🎯 What's New in v2.1.3

This version adds **comprehensive error logging** to help identify exactly where the plugin is failing.

Every step now logs detailed information to QField's console.

---

## 📥 Installation

1. **Uninstall previous version** (if installed):
   - QField → Settings → Plugins
   - Find "QField Render Sync"
   - Tap Uninstall

2. **Install v2.1.3:**
   ```
   https://github.com/CESMikef/qfield-render-sync-plugin/releases/download/v2.1.3/qfield-render-sync-v2.1.3.zip
   ```

3. **Restart QField**

---

## 🔍 How to Get Debug Logs

### Method 1: QField Debug Output (Recommended)

1. Open QField
2. Go to **☰ Menu → Settings → About**
3. Scroll down to **"Copy debug output"**
4. Tap to copy
5. Paste into a text file and share

### Method 2: Android Logcat (Advanced)

If you have Android debugging enabled:

```bash
adb logcat | grep "Render Sync"
```

---

## 🧪 Testing Steps

### Step 1: Plugin Loads

**Expected:**
- Plugin button appears in toolbar
- Console shows: `[Render Sync] Plugin loaded v2.1.3`

**If fails:**
- Check debug output for errors
- Look for import errors or syntax errors

---

### Step 2: Enter Token

1. Tap "Sync Photos" button
2. Token dialog should appear
3. Enter your API token
4. Tap OK

**Expected logs:**
```
[Render Sync] Saving token for current session
[Render Sync] Fetching configuration from API...
[Render Sync] API Response Status: 200
[Render Sync] ✓ Configuration loaded successfully from API
```

**If fails:**
- Check API URL is correct
- Verify token is valid
- Check network connection
- Look for HTTP error codes in logs

---

### Step 3: Open Sync Dialog

1. Tap "Sync Photos" button again

**Expected logs:**
```
[Render Sync] ========== OPEN SYNC DIALOG ==========
[Render Sync] tokenConfigured: true
[Render Sync] configValid: true
[Render Sync] syncInProgress: false
[Render Sync] Loading sync dialog...
[Render Sync] Loader status before activation: 0
[Render Sync] Loader status changed to: 1
[Render Sync] Status: Loading...
[Render Sync] Loader status changed to: 2
[Render Sync] Status: Ready - component loaded
[Render Sync] Loader onLoaded triggered
[Render Sync] Setting dialog properties...
[Render Sync] Dialog parent set successfully
[Render Sync] Sync dialog loaded successfully
[Render Sync] Attempt 1 - Loader status: 2
[Render Sync] Dialog loaded successfully, opening...
[Render Sync] Dialog opened
[SyncDialog] Component completed
[SyncDialog] Dialog opened
[SyncDialog] Initialization complete
```

**If fails at "ERROR: Failed to load component":**
- There's a syntax error in SyncDialog.qml
- Check the error string in logs
- Look for missing imports

**If fails at "Loader ready but item is null":**
- Dialog created but not properly initialized
- Check parent context issues

**If fails at "Timeout loading dialog":**
- Dialog taking too long to load
- May indicate performance issue or infinite loop

---

### Step 4: Select Layer and Detect Photos

1. Dialog should open showing layer dropdown
2. Select your layer (e.g., "verify_poles")
3. Should show "Pending: X" count

**Expected logs:**
```
[Sync] Found X photos pending upload
```

**If shows "Pending: 0" but you have photos:**
- Photos might not be local paths
- Check photo field contains file paths like `/storage/...`
- Not URLs like `https://...`

---

### Step 5: Test Connections (Optional)

1. Tap "Test Connections"

**Expected logs:**
```
WebDAV: ✓ Connected
API: ✓ Connected
```

**If fails:**
- Check WebDAV credentials
- Check API token
- Verify network connection

---

### Step 6: Start Sync

1. Tap "Start Sync"

**Expected logs:**
```
[Sync] Syncing photo for feature: {global_id}
[Sync] Starting photo upload: {filename}
[WebDAV] Photo uploaded successfully
[API] Database updated for {global_id}
[Sync] Successfully synced photo for {global_id}
```

**If fails at upload:**
```
[WebDAV] ERROR: Photo upload failed: {reason}
```
- Check WebDAV server is accessible
- Check credentials
- Check file exists locally

**If fails at database update:**
```
[API] ERROR: API error: {reason}
```
- Check API is running
- Check feature exists in database
- Check global_id matches

---

## 🐛 Common Error Patterns

### Error: "Configuration incomplete"

**Logs show:**
```
[Render Sync] Configuration invalid
[Render Sync] Config errors: webdavUrl, webdavUsername
```

**Solution:**
- API didn't return all required fields
- Check API `/api/config` endpoint response
- Verify token has access to configuration

---

### Error: "Error loading sync dialog"

**Logs show:**
```
[Render Sync] Status: ERROR - Failed to load component
[Render Sync] Error string: {syntax error details}
```

**Solution:**
- QML syntax error in SyncDialog.qml
- Check the error string for line number
- Report the full error message

---

### Error: "QField interface not ready"

**Logs show:**
```
[Render Sync] ERROR: iface or mainWindow not available
```

**Solution:**
- Plugin loaded before QField fully initialized
- Try restarting QField
- May indicate compatibility issue

---

## 📋 What to Share When Reporting Issues

1. **QField version**: Settings → About
2. **Plugin version**: 2.1.3
3. **Full debug output**: Copy from Settings → About
4. **Screenshot of error** (if visible)
5. **Steps to reproduce**
6. **Expected vs actual behavior**

---

## ✅ Success Criteria

Plugin is working correctly when:

1. ✅ Plugin loads without errors
2. ✅ Token dialog appears and saves token
3. ✅ Configuration loads from API
4. ✅ Sync dialog opens (no error message)
5. ✅ Layers are listed in dropdown
6. ✅ Pending photos are detected
7. ✅ Connection test passes
8. ✅ Photos upload successfully
9. ✅ Database updates correctly
10. ✅ Local layer shows URLs after sync

---

## 🔄 Next Steps After Testing

1. **If it works**: Great! Use it in production
2. **If it fails**: Share the debug logs
3. **Based on logs**: We'll identify the exact issue and fix it

The detailed logging in v2.1.3 will tell us exactly where the problem is!

---

**Install v2.1.3 now and share the debug output!** 📊
