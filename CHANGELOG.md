# Changelog

## v5.0.0 (2025-10-14) - Database Sync Only (Major Refactor)

### 🎯 **Major Architecture Change**

**Breaking Change:** Plugin now only syncs database records. Photo upload handled by QField natively.

### Why This Change?

- **Root Cause:** QML cannot read local files due to security restrictions
- **Solution:** Use QField's native WebDAV upload, plugin only syncs database
- **Benefits:** Simpler, more reliable, uses QField's proven upload code

### How It Works Now

1. **QField uploads photo** → WebDAV (native feature)
2. **Photo field gets URL** → `https://webdav.com/photos/abc123.jpg`
3. **Plugin syncs database** → Updates PostgreSQL with URL

### What Changed

- ✅ **Removed file upload logic** - No longer tries to read local files
- ✅ **Simplified sync engine** - Only calls `/api/v1/photos/update`
- ✅ **Detects WebDAV URLs** - Finds photos already uploaded by QField
- ✅ **Database-only sync** - Fast and reliable

### Migration from v4.x

1. **Configure QField photo field** to upload to WebDAV
2. **Capture photos in QField** (uploads automatically)
3. **Run plugin** to sync database records

### API Endpoints Used

- `POST /api/v1/photos/update` - Update single photo record
- `POST /api/v1/photos/batch-update` - Update multiple records
- `GET /health` - Health check

---

## v4.0.2 (2025-10-14) - QML Syntax Fix

### 🐛 Fixes
- **Fixed QML syntax error:** Removed emoji characters causing parse errors
- **Line 200 fix:** Removed checkmark/cross emojis from console.log statements
- Plugin now loads correctly in QField

---

## v4.0.1 (2025-10-14) - Configuration Fix

### 🐛 Fixes
- **Removed /api/config dependency:** Plugin no longer requires `/api/config` endpoint
- **Simplified configuration:** Uses health check (`/health`) instead of config fetch
- **Better error handling:** Graceful fallback if API health check fails
- **Default values:** Uses sensible defaults for `dbTable` and `photoField`

### 🔧 Changes
- Configuration now only requires API URL and token
- Health check validates API is reachable
- Allows proceeding even if health check fails (will retry during sync)

---

## v4.0.0 (2025-10-14) - API-Based Photo Upload

### 🚀 Major Architecture Change
**Breaking Change:** Photos now upload via API instead of direct WebDAV connection.

### Why This Change?
- **Root Cause:** QML's `XMLHttpRequest` cannot read local files using `file://` URLs
- **Solution:** API handles file upload server-side, working around QML limitations
- **Benefits:** Simpler plugin code, better error handling, centralized credentials

### ✨ New Features
- **New Upload Method:** `uploadPhotoViaAPI()` in `webdav_client.js`
  - Sends photos to API endpoint using multipart/form-data
  - API handles both WebDAV upload and database update
  - Single request does everything (upload + DB update)

### 🔧 Changes
- **webdav_client.js:** Added `uploadPhotoViaAPI()` function
- **sync_engine.js:** Updated to use API-based upload, simplified workflow
- **main.qml:** Removed WebDAV credential requirements from plugin
- **Configuration:** Only API URL and token required (WebDAV credentials stored server-side)

### 📋 Migration Notes
- **API Endpoint:** Uses `/api/v1/photos/upload-and-update`
- **Server Requirements:** API must have WebDAV credentials configured in database
- **Plugin Config:** Only needs `apiUrl`, `apiToken`, `dbTable`, `photoField`

### 🐛 Fixes
- Resolved QML file access limitations
- Eliminated "file:// URL not accessible" errors
- Improved error messages and progress reporting

---

## v2.8.0 (2025-10-09) - Repository Cleanup & Simplification

### 🧹 Major Cleanup
- **Removed 26+ old release ZIP files** from root directory
- **Removed temp_check/** duplicate directory (complete copy of src/)
- **Removed 8 debug/status markdown files** from development iterations
- **Removed utility scripts** (insert_function.ps1, main_layer_function.qml)
- **Removed backup files** (main_backup.qml, main_temp.qml, main_insert.txt)
- **Consolidated dialog files** - removed test variants, kept single production version

### 📁 Simplified Structure
- Renamed `SyncDialog_Simple.qml` → `SyncDialog.qml` (now the only dialog)
- Clean `src/` directory with only production files
- Updated `.gitignore` to prevent future clutter
- Clean root directory with essential files only

### 📚 Documentation Updates
- Updated README with correct GitHub URLs
- Updated version numbers across all files
- Simplified configuration documentation
- Removed outdated server-specific URLs

### 🎯 Result
Repository is now clean, maintainable, and easy to navigate!

---

## v2.3.0 (2025-10-09) - Enhanced Layer & Photo Detection

### 🔧 Critical Fixes

**Multiple Layer Detection Strategies**
- Implemented 5 different approaches to access project layers in QField
- Added fallback mechanisms for different QField API versions
- Enhanced diagnostic logging to identify which approach works

**Layer Access Methods**:
1. `iface.project` (QGIS Desktop style)
2. `iface.mapCanvas().project()` (QField style)
3. `iface.mapCanvas().layers()` (Direct canvas access)
4. `QgsProject.instance()` (Global project instance)
5. `iface.activeLayer()` (Fallback to active layer only)

**Improved Photo Detection**:
- Enhanced feature iteration to handle both array and iterator patterns
- Added comprehensive logging for photo field values
- Better handling of empty or null photo paths
- Clearer distinction between local paths and already-synced URLs

### 🐛 Bug Fixes
- Fixed "No layers found" issue by trying multiple QField API approaches
- Improved error messages when layer access fails
- Added extensive diagnostic logging at every step
- Better handling of edge cases in feature collection access

### 📊 Diagnostic Improvements
- Console logs now show all attempted approaches
- Clear success/failure indicators for each method
- Logs show exact feature count and photo detection results
- Toast notifications provide immediate user feedback

### 🎯 What to Watch For
This version adds extensive logging to help diagnose the exact QField API:
- Check QField console logs when opening sync dialog
- Look for "GET VECTOR LAYERS" section showing which approach worked
- "UPDATE PENDING COUNT" section shows photo detection details
- Report back which "Approach" successfully found layers

---

## v2.0.0 (2025-10-07) - Token-Based Configuration

### 🎉 Major Changes

**Token-Based Authentication System**
- Users now enter a token in QField instead of hardcoding credentials in QGIS project
- Plugin fetches all configuration from API using the token
- Token stored securely in QField project settings
- Automatic configuration loading on subsequent launches

### ✨ New Features

- **Token Dialog**: Prompts users to enter their API token on first use
- **API Configuration Endpoint**: `/api/config?token={token}` fetches client configuration
- **Secure Storage**: Token saved locally, no credentials in project files
- **Auto-Reload**: Configuration automatically fetched when plugin loads
- **Better Security**: Credentials never stored in QGIS project files
- **Multi-Tenant**: Each user/client has their own token with specific configuration

### 🔧 Technical Changes

- Removed project variable-based configuration
- Added `fetchConfigurationFromAPI()` function
- Added `TokenDialog.qml` component
- Token stored using `qfProject.writeEntry()`
- Configuration fetched via XMLHttpRequest
- Proper error handling for invalid/expired tokens

### 📋 Required API Changes

**New Endpoint Required**: `GET /api/config`
- See [docs/API_ENDPOINT.md](docs/API_ENDPOINT.md) for implementation details
- Queries `api.client_config` table by token
- Returns WebDAV credentials, database config, etc.

### 🔄 Migration Guide

**From v1.x to v2.0.0**:

1. **Implement API Endpoint**:
   - Add `GET /api/config` endpoint to your FastAPI application
   - Query `api.client_config` table by token
   - Return configuration as JSON

2. **Update Plugin**:
   - Uninstall v1.x from QField
   - Install v2.0.0 from GitHub releases

3. **Configure Users**:
   - Generate tokens in `api.client_config` table
   - Distribute tokens to field users
   - Users enter token in QField when prompted

4. **Remove Project Variables** (Optional):
   - Old `render_*` variables in QGIS project no longer needed
   - Can be removed from Project → Properties → Variables

### 🐛 Bug Fixes

- Fixed duplicate `Component.onCompleted` property error
- Fixed toolbar button visibility using correct QField API
- Improved error messages for configuration issues

---

## v1.0.4 (2025-10-07) - Toolbar Fix

### 🐛 Bug Fixes
- Fixed toolbar button using correct QField API (`iface.addItemToPluginsToolbar`)
- Button now appears in plugins toolbar as expected

---

## v1.0.3 (2025-10-07) - Floating Button

### ✨ Features
- Added floating action button for better visibility
- Improved button positioning and styling

---

## v1.0.2 (2025-10-07) - QML Fix

### 🐛 Bug Fixes
- Fixed duplicate `Component.onCompleted` property error
- Merged initialization code into single block

---

## v1.0.1 (2025-10-07) - Permissions Fix

### 🐛 Bug Fixes
- Added `contents: write` permission to GitHub Actions workflow
- Fixed release creation failures

---

## v1.0.0 (2025-10-06) - Initial Release

### ✨ Features
- WebDAV photo upload
- REST API database integration
- Project variable configuration
- Progress tracking
- Error handling
- Duplicate detection
- Retry logic

### 📦 Components
- Main plugin (main.qml)
- Sync dialog (SyncDialog.qml)
- WebDAV client (webdav_client.js)
- API client (api_client.js)
- Sync engine (sync_engine.js)
- Utilities (utils.js)

---

**Repository**: https://github.com/CESMikef/qfield-render-sync-plugin
