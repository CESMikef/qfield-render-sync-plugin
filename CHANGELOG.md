# Changelog

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
