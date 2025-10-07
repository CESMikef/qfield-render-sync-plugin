# QField Render Sync Plugin

**Version:** 1.0.0  
**Author:** CES  
**License:** MIT

## Overview

QField Render Sync is a mobile plugin for QField that automatically syncs field-captured photos to Render WebDAV storage and updates PostgreSQL database records via a REST API. This plugin eliminates the need to store photos in QFieldCloud, giving you full control over your photo storage infrastructure.

## Features

- ✅ **Automatic Photo Upload** - Uploads photos from QField to Render WebDAV
- ✅ **Database Integration** - Updates PostgreSQL via secure REST API
- ✅ **Duplicate Prevention** - Checks for existing files before upload
- ✅ **Progress Tracking** - Real-time upload progress and status
- ✅ **Error Handling** - Graceful error handling with detailed messages
- ✅ **Project-Based Configuration** - Zero manual setup on mobile devices
- ✅ **Batch Operations** - Sync multiple photos efficiently
- ✅ **Connection Testing** - Built-in connection validation

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              QField Mobile App                       │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │    QField Render Sync Plugin               │    │
│  │                                             │    │
│  │  1. Detect local photos                    │    │
│  │  2. Upload to WebDAV ──────────────┐       │    │
│  │  3. Update database via API ───┐   │       │    │
│  │  4. Update local layer          │   │       │    │
│  └─────────────────────────────────┼───┼───────┘    │
└──────────────────────────────────────┼───┼───────────┘
                                      │   │
                                      ▼   ▼
                            ┌──────────────────┐
                            │   REST API       │
                            │  (Multi-tenant)  │
                            └────────┬─────────┘
                                     │
                                     ▼
                            ┌──────────────────┐
                            │   PostgreSQL     │
                            └──────────────────┘
                                     
                                     ▲
                                     │
                            ┌──────────────────┐
                            │  Render WebDAV   │
                            │ (Photo Storage)  │
                            └──────────────────┘
```

## Requirements

### Server Side
- **REST API**: Deployed at `https://ces-qgis-qfield-v1.onrender.com`
- **WebDAV Server**: Deployed at `https://qfield-photo-storage-v3.onrender.com`
- **PostgreSQL Database**: `prod_gis` with schema `design.verify_poles`

### Client Side
- **QField**: Version 3.0 or higher
- **QGIS Desktop**: For project configuration
- **QFieldCloud**: For project synchronization
- **Internet Connection**: Required for photo upload and sync

## Installation

### Step 1: Configure QGIS Project (Administrator)

In QGIS Desktop, before uploading to QFieldCloud:

1. Open **Project → Properties → Variables**
2. Add the following custom variables:

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `render_webdav_url` | `https://qfield-photo-storage-v3.onrender.com` | WebDAV server URL |
| `render_webdav_username` | `qfield` | WebDAV username |
| `render_webdav_password` | `qfield123` | WebDAV password |
| `render_api_url` | `https://ces-qgis-qfield-v1.onrender.com` | REST API URL |
| `render_api_token` | `qwrfzf23t2345t23fef23123r` | API authentication token |
| `render_db_table` | `design.verify_poles` | Database table name |
| `render_photo_field` | `photo` | Photo field name |

3. Save project: **File → Save Project**
4. Upload to QFieldCloud: **Plugins → QFieldSync → Synchronize → Push to Cloud**

### Step 2: Install Plugin on Mobile Device

1. Open QField on mobile device
2. Go to **Settings → Plugins**
3. Click **"Install plugin from URL"** or **"Install from file"**
4. Enter plugin URL or select plugin ZIP file
5. Click **Install**
6. Enable the plugin

### Step 3: Sync Project to Mobile

1. In QField, go to **Projects**
2. Pull project from QFieldCloud
3. Open project
4. Plugin automatically loads configuration from project variables
5. **No manual configuration needed!** ✅

## Usage

### Basic Workflow

1. **Capture Photos in Field**
   - Open feature form in QField
   - Take photo using camera
   - Photo saved locally with local path

2. **Sync Photos**
   - Click **"Sync Photos"** button in toolbar (or press Ctrl+Shift+S)
   - Select layer with photos
   - Click **"Test Connections"** to verify (optional)
   - Click **"Start Sync"**
   - Wait for upload to complete

3. **View Results**
   - Success/failure count displayed
   - Errors shown with details
   - Local layer updated with photo URLs
   - Photos accessible via URL in database

### Sync Dialog Features

- **Layer Selection** - Choose which layer to sync
- **Pending Count** - Shows how many photos need upload
- **Connection Test** - Verify WebDAV and API connectivity
- **Progress Tracking** - Real-time upload progress
- **Statistics** - View total features and pending uploads
- **Error Details** - Detailed error messages for failures

### Toolbar Button

The plugin adds a **"Sync Photos"** button to the QField toolbar:
- **Green** - Ready to sync
- **Disabled** - Configuration incomplete or sync in progress
- **Tooltip** - Shows configuration status

### Keyboard Shortcut

Press **Ctrl+Shift+S** to open the sync dialog quickly.

## Configuration

### Project Variables (Required)

All configuration is stored in QGIS project variables and automatically syncs to mobile devices:

```
render_webdav_url       - WebDAV server URL
render_webdav_username  - WebDAV username
render_webdav_password  - WebDAV password
render_api_url          - REST API base URL
render_api_token        - API authentication token
render_db_table         - Database table name
render_photo_field      - Photo field name
```

### Updating Configuration

To change settings:

1. **QGIS Desktop**: Update project variables
2. **Save project**
3. **Push to QFieldCloud**
4. **Mobile devices**: Pull updated project
5. **Done!** All devices now use new configuration

## Troubleshooting

### Plugin Not Loading

- Check QField version (requires 3.0+)
- Verify `main.qml` file exists
- Check QField logs for errors
- Reinstall plugin

### Configuration Incomplete

- Verify all project variables are set in QGIS Desktop
- Check variable names match exactly (case-sensitive)
- Ensure project was saved after adding variables
- Pull latest project version on mobile device

### Upload Failures

**WebDAV Upload Failed:**
- Test WebDAV connection in sync dialog
- Verify credentials are correct
- Check WebDAV service is running
- Ensure photo file exists locally

**API Update Failed:**
- Test API connection in sync dialog
- Verify API token is valid
- Check API service is running (not sleeping)
- Ensure feature exists in database

**Network Errors:**
- Check internet connection
- Verify firewall settings
- Try again when on WiFi

### No Photos to Upload

- Verify photos have local paths (not URLs)
- Check photo field name matches configuration
- Ensure layer is selected correctly
- Refresh layer if needed

## Technical Details

### File Structure

```
QField-Render-Sync/
├── main.qml                    # Entry point & configuration
├── metadata.txt                # Plugin metadata
├── icon.svg                    # Plugin icon
├── components/
│   └── SyncDialog.qml          # Main sync interface
├── js/
│   ├── utils.js                # Helper functions
│   ├── webdav_client.js        # WebDAV upload logic
│   ├── api_client.js           # REST API calls
│   └── sync_engine.js          # Orchestration
└── README.md                   # This file
```

### Sync Process

1. **Scan Layer** - Find features with local photo paths
2. **Check Duplicate** - HEAD request to WebDAV (skip if exists)
3. **Upload Photo** - PUT request to WebDAV with progress tracking
4. **Update Database** - POST to REST API with photo URL
5. **Update Local** - Replace local path with URL in layer
6. **Report Results** - Show success/failure statistics

### API Endpoints Used

- `GET /health` - Health check
- `POST /api/v1/photos/update` - Update single photo
- `POST /api/v1/photos/batch-update` - Batch update (future)
- `GET /api/v1/photos/status/{global_id}` - Get photo status

### Security

- **API Authentication** - Bearer token authentication
- **HTTPS Only** - All requests over secure connection
- **No Credential Storage** - Credentials in project variables only
- **Database Security** - No direct database access from mobile
- **Token Rotation** - Update token via project variables

## Performance

- **Sequential Uploads** - One photo at a time (prevents timeouts)
- **Duplicate Check** - HEAD request before upload (saves bandwidth)
- **Progress Updates** - Real-time feedback to user
- **Error Recovery** - Failed uploads can be retried
- **Timeout Handling** - 2 minutes for upload, 30 seconds for API

## Limitations

- **Internet Required** - Cannot sync offline (photos queue locally)
- **Sequential Processing** - Photos uploaded one at a time
- **File Size** - Large photos may take longer to upload
- **API Rate Limits** - 100 requests/minute per token

## Future Enhancements

### Version 1.1
- Batch parallel uploads
- Offline queue with auto-retry
- Photo compression before upload
- Network type detection (WiFi vs mobile data)

### Version 1.2
- Auto-sync on photo capture
- Background sync
- Multi-layer support
- Upload history tracking

## Support

For issues or questions:
- Check QField logs
- Review API logs on Render
- Test connections in sync dialog
- Verify configuration in project variables

## License

MIT License - Free to use and modify

## Credits

Developed by CES for field data collection workflows.

---

**Last Updated:** 2025-10-06  
**Version:** 1.0.0
