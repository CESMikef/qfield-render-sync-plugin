# QField Render Sync Plugin

**Mobile plugin for QField that syncs field-captured photos to WebDAV storage and PostgreSQL database.**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/YOUR_ORG/qfield-render-sync-plugin/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![QField](https://img.shields.io/badge/QField-3.0%2B-orange.svg)](https://qfield.org)

---

## 🎯 Overview

This plugin eliminates the need to store photos in QFieldCloud by automatically syncing them to your own infrastructure:

- **📸 Automatic Upload** - Photos uploaded to WebDAV server
- **💾 Database Integration** - PostgreSQL updated via REST API
- **🔧 Zero Configuration** - Settings sync from QGIS project
- **🔄 Duplicate Prevention** - Smart detection prevents re-uploads
- **📊 Progress Tracking** - Real-time sync status

---

## 📥 Installation

### Quick Install

1. **Open QField** on your mobile device
2. Go to **Settings → Plugins**
3. Click **"Install from URL"**
4. Enter:
   ```
   https://github.com/YOUR_ORG/qfield-render-sync-plugin/releases/download/v1.0.0/qfield-render-sync-v1.0.0.zip
   ```
5. Click **Install**
6. Enable the plugin

### Manual Install

1. Download the [latest release ZIP](https://github.com/YOUR_ORG/qfield-render-sync-plugin/releases/latest)
2. Transfer to your device
3. **QField → Settings → Plugins → Install from file**
4. Select the ZIP file
5. Enable the plugin

---

## 🚀 Quick Start

### For Administrators

1. **Configure QGIS Project**
   - Open QGIS Desktop
   - Project → Properties → Variables
   - Add 7 configuration variables (see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md))

2. **Upload to QFieldCloud**
   - Save project
   - Push to QFieldCloud

3. **Done!** Configuration automatically syncs to mobile devices

### For Field Workers

1. **Download Project**
   - Pull project from QFieldCloud
   - Plugin loads automatically

2. **Capture Photos**
   - Navigate to site
   - Take photos in QField
   - Photos saved locally

3. **Sync Photos**
   - Tap "Sync Photos" button
   - Select layer
   - Click "Start Sync"
   - Photos upload to server

---

## 📚 Documentation

- **[User Guide](docs/README.md)** - Complete usage instructions
- **[Quick Start](docs/QUICKSTART.md)** - 5-minute setup guide
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Step-by-step deployment
- **[Workflow Guide](docs/WORKFLOW_GUIDE.md)** - Complete field workflow
- **[Testing Guide](docs/TESTING.md)** - Testing procedures

---

## 🏗️ Architecture

```
QField Mobile
    ↓
Plugin (QML/JavaScript)
    ↓
    ├─→ WebDAV Server (Photo Storage)
    │   https://qfield-photo-storage-v3.onrender.com
    │
    └─→ REST API (Database Updates)
        https://ces-qgis-qfield-v1.onrender.com
            ↓
        PostgreSQL Database
```

---

## ⚙️ Requirements

### Server Side
- **REST API** - [qfield-photo-sync-api](https://github.com/YOUR_ORG/qfield-photo-sync-api)
- **WebDAV Server** - For photo storage
- **PostgreSQL Database** - For metadata

### Client Side
- **QField** - Version 3.0 or higher
- **QGIS Desktop** - For project configuration
- **QFieldCloud** - For project synchronization
- **Internet Connection** - For photo upload

---

## 🔧 Configuration

All configuration is stored in QGIS project variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `render_webdav_url` | WebDAV server URL | `https://qfield-photo-storage-v3.onrender.com` |
| `render_webdav_username` | WebDAV username | `qfield` |
| `render_webdav_password` | WebDAV password | `qfield123` |
| `render_api_url` | REST API URL | `https://ces-qgis-qfield-v1.onrender.com` |
| `render_api_token` | API authentication token | `qwrfzf23t2345t23fef23123r` |
| `render_db_table` | Database table name | `design.verify_poles` |
| `render_photo_field` | Photo field name | `photo` |

**No manual configuration needed on mobile devices!** ✅

---

## 🎯 Features

### Photo Management
- ✅ Automatic upload to WebDAV
- ✅ Duplicate detection (skip existing photos)
- ✅ Progress tracking (0-100%)
- ✅ Retry logic (3 attempts)
- ✅ Timeout handling

### Database Integration
- ✅ Token-based authentication
- ✅ Multi-tenant support
- ✅ Atomic updates
- ✅ Error recovery

### User Interface
- ✅ Toolbar button
- ✅ Layer selection
- ✅ Connection testing
- ✅ Progress display
- ✅ Results summary

---

## 🔄 Workflow

1. **Office**: Configure QGIS project with variables
2. **Office**: Upload project to QFieldCloud
3. **Field**: Download project to mobile device
4. **Field**: Capture photos on-site
5. **Field**: Sync photos to server
6. **Office**: View updated data with photo URLs

See [docs/WORKFLOW_GUIDE.md](docs/WORKFLOW_GUIDE.md) for detailed workflow.

---

## 🛠️ Development

### Project Structure

```
qfield-render-sync-plugin/
├── src/                    # Plugin source code
│   ├── main.qml           # Entry point
│   ├── metadata.txt       # Plugin metadata
│   ├── icon.svg           # Plugin icon
│   ├── components/        # UI components
│   │   └── SyncDialog.qml
│   └── js/                # JavaScript modules
│       ├── utils.js
│       ├── webdav_client.js
│       ├── api_client.js
│       └── sync_engine.js
├── docs/                  # Documentation
├── scripts/               # Build scripts
└── .github/workflows/     # CI/CD
```

### Building

```powershell
cd scripts
.\package.ps1
```

This creates `qfield-render-sync-v1.0.0.zip` in the parent directory.

### Testing

See [docs/TESTING.md](docs/TESTING.md) for testing procedures.

---

## 🤝 Related Projects

- **[QField Photo Sync API](https://github.com/YOUR_ORG/qfield-photo-sync-api)** - Backend REST API
- **[QField](https://qfield.org)** - Mobile GIS application
- **[QGIS](https://qgis.org)** - Desktop GIS application

---

## 📝 Changelog

### v1.0.0 (2025-10-06)
- Initial release
- WebDAV upload support
- REST API integration
- Project variable configuration
- Progress tracking
- Error handling

---

## 🐛 Troubleshooting

### Plugin Not Loading
- Check QField version (requires 3.0+)
- Verify plugin is enabled in settings
- Check QField logs for errors

### Configuration Incomplete
- Verify all 7 project variables are set in QGIS
- Check variable names match exactly (case-sensitive)
- Pull latest project from QFieldCloud

### Upload Failures
- Test connections in sync dialog
- Check internet connection
- Verify WebDAV/API services are running
- Check credentials are correct

See [docs/README.md](docs/README.md) for more troubleshooting tips.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👥 Authors

Developed by **CES** for field data collection workflows.

---

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/YOUR_ORG/qfield-render-sync-plugin/issues)
- **API Docs**: https://ces-qgis-qfield-v1.onrender.com/docs

---

**Last Updated**: 2025-10-07  
**Version**: 1.0.0
