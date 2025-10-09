# QField Render Sync Plugin

**Mobile plugin for QField that syncs field-captured photos to WebDAV storage and PostgreSQL database.**

[![Version](https://img.shields.io/badge/version-2.8.0-blue.svg)](https://github.com/CESMikef/qfield-render-sync-plugin/releases)
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
   https://github.com/CESMikef/qfield-render-sync-plugin/releases/latest/download/qfield-render-sync-v2.8.0.zip
   ```
5. Click **Install**
6. Enable the plugin

### Manual Install

1. Download the [latest release ZIP](https://github.com/CESMikef/qfield-render-sync-plugin/releases/latest)
2. Transfer to your device
3. **QField → Settings → Plugins → Install from file**
4. Select the ZIP file
5. Enable the plugin

---

## 🚀 Quick Start

### First Time Setup

1. **Install Plugin** (see Installation above)
2. **Get Your Token** from your administrator
3. **Open QField** and load your project

### Syncing Photos

1. **Capture Photos**
   - Navigate to site in QField
   - Take photos and attach to features
   - Photos saved locally

2. **Click "Sync Photos"**
   - Tap the "Sync Photos" button in toolbar
   - Enter your API token (first time only)
   - Select the layer with photos
   - Click "Start Sync"

3. **Done!**
   - Photos upload to WebDAV server
   - Database updates with photo URLs
   - Local layer shows web URLs

---

## 📚 Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Step-by-step deployment instructions
- **[Workflow Guide](docs/WORKFLOW_GUIDE.md)** - Complete field workflow details
- **[Testing Guide](docs/TESTING.md)** - Comprehensive testing procedures

---

## 🏗️ Architecture

```
QField Mobile
    ↓
Plugin (QML/JavaScript)
    ↓
    ├─→ WebDAV Server (Photo Storage)
    │
    └─→ REST API (Database Updates)
            ↓
        PostgreSQL Database
```

Configuration is loaded from the API endpoint using a token.

---

## ⚙️ Requirements

### Server Side
- **REST API** - Backend API providing token-based configuration
- **WebDAV Server** - For photo storage
- **PostgreSQL Database** - For metadata storage

### Client Side
- **QField** - Version 3.0 or higher
- **QGIS Desktop** - For project setup (optional)
- **Internet Connection** - For photo upload and API access

---

## 🔧 Configuration

Configuration is loaded from the backend API using a token:

1. **Enter Token**: First time you click "Sync Photos", enter your API token
2. **Auto-Configuration**: Plugin fetches all settings from the API
3. **Start Syncing**: Configuration is stored for the session

**What's Configured Automatically:**
- WebDAV server URL and credentials
- API endpoint
- Database table name
- Photo field name

**No manual setup needed!** ✅ Just enter your token once per session.

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

1. **Setup**: Install plugin and get API token
2. **Field**: Open project in QField
3. **Field**: Capture photos on-site
4. **Field**: Click "Sync Photos" → Enter token → Select layer → Start Sync
5. **Result**: Photos uploaded to WebDAV, database updated with URLs

See [docs/WORKFLOW_GUIDE.md](docs/WORKFLOW_GUIDE.md) for detailed workflow.

---

## 🛠️ Development

### Project Structure

```
qfield-render-sync-plugin/
├── src/                      # Plugin source code
│   ├── main.qml             # Entry point
│   ├── metadata.txt         # Plugin metadata
│   ├── icon.svg             # Plugin icon
│   ├── components/          # UI components
│   │   ├── SyncDialog.qml   # Main sync interface
│   │   └── TokenDialog.qml  # Token configuration
│   └── js/                  # JavaScript modules
│       ├── utils.js         # Utility functions
│       ├── webdav_client.js # WebDAV upload client
│       ├── api_client.js    # REST API client
│       └── sync_engine.js   # Sync orchestration
├── docs/                    # Documentation
├── scripts/                 # Build scripts
│   └── package.ps1
└── .github/workflows/       # CI/CD
    └── release.yml
```

### Building

```powershell
cd scripts
.\package.ps1
```

This creates `qfield-render-sync-v2.8.0.zip` in the parent directory.

### Testing

See [docs/TESTING.md](docs/TESTING.md) for testing procedures.

---

## 🤝 Related Projects

- **[QField](https://qfield.org)** - Mobile GIS application
- **[QGIS](https://qgis.org)** - Desktop GIS application

---

## 📝 Changelog

### v2.8.0 (2025-10-09)
- Major repository cleanup and simplification
- Removed 26+ old release ZIP files
- Removed duplicate temp directories
- Consolidated to single production dialog
- Enhanced layer detection with multiple fallback strategies
- Improved .gitignore to prevent future clutter

### v1.0.0 (2025-10-06)
- Initial release
- WebDAV upload support
- REST API integration
- Token-based configuration
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

See [TESTING_GUIDE.md](TESTING_GUIDE.md) or [docs/TESTING.md](docs/TESTING.md) for more troubleshooting tips.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👥 Authors

Developed by **CES** for field data collection workflows.

---

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/CESMikef/qfield-render-sync-plugin/issues)

---

**Last Updated**: 2025-10-09  
**Version**: 2.8.0
