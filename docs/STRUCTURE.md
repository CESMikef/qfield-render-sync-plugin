# QField Render Sync - File Structure

## Directory Tree

```
QField-Render-Sync/
│
├── main.qml                        # Plugin entry point (340 lines)
│   ├─ Configuration loader
│   ├─ Project variable reader
│   ├─ Toolbar button
│   └─ Plugin lifecycle management
│
├── metadata.txt                    # Plugin metadata
│   ├─ Name, version, author
│   ├─ QField compatibility
│   └─ Plugin description
│
├── icon.svg                        # Plugin icon (64x64)
│   └─ Camera + sync arrows design
│
├── components/                     # UI Components
│   │
│   └── SyncDialog.qml             # Main sync interface (450 lines)
│       ├─ Layer selection
│       ├─ Connection testing
│       ├─ Progress tracking
│       ├─ Results display
│       └─ Error handling
│
├── js/                            # JavaScript Modules
│   │
│   ├── utils.js                   # Utility functions (180 lines)
│   │   ├─ URL validation
│   │   ├─ Path detection
│   │   ├─ Filename sanitization
│   │   ├─ Configuration parsing
│   │   └─ Helper functions
│   │
│   ├── webdav_client.js          # WebDAV client (200 lines)
│   │   ├─ File existence check
│   │   ├─ Photo upload
│   │   ├─ Progress tracking
│   │   ├─ Duplicate prevention
│   │   └─ Connection testing
│   │
│   ├── api_client.js             # REST API client (250 lines)
│   │   ├─ Photo URL update
│   │   ├─ Batch updates
│   │   ├─ Status queries
│   │   ├─ Retry logic
│   │   └─ Connection testing
│   │
│   └── sync_engine.js            # Sync orchestration (280 lines)
│       ├─ Photo detection
│       ├─ Sync workflow
│       ├─ Batch processing
│       ├─ State management
│       └─ Validation
│
├── README.md                      # User documentation
│   ├─ Overview & features
│   ├─ Installation guide
│   ├─ Usage instructions
│   ├─ Configuration reference
│   └─ Troubleshooting
│
├── DEPLOYMENT.md                  # Deployment guide
│   ├─ Packaging instructions
│   ├─ QGIS configuration
│   ├─ QFieldCloud setup
│   ├─ Mobile installation
│   └─ Testing procedures
│
├── TESTING.md                     # Testing guide
│   ├─ Unit tests
│   ├─ Integration tests
│   ├─ UI tests
│   ├─ Field tests
│   └─ Test data
│
├── QUICKSTART.md                  # Quick start guide
│   ├─ 5-minute setup
│   ├─ Configuration steps
│   ├─ Usage examples
│   └─ Troubleshooting tips
│
├── PROJECT_SUMMARY.md             # Executive summary
│   ├─ Architecture overview
│   ├─ Implementation details
│   ├─ Performance metrics
│   ├─ Security features
│   └─ Cost analysis
│
├── STRUCTURE.md                   # This file
│   └─ Directory structure reference
│
└── package.ps1                    # Packaging script
    ├─ File validation
    ├─ ZIP creation
    └─ Deployment instructions
```

---

## File Descriptions

### Core Plugin Files

#### main.qml
**Purpose:** Plugin entry point and configuration manager  
**Size:** ~340 lines  
**Key Functions:**
- Load configuration from project variables
- Validate configuration completeness
- Create toolbar button
- Initialize sync dialog
- Handle plugin lifecycle

**Dependencies:**
- org.qfield 1.0
- org.qgis 1.0
- All JavaScript modules

---

#### metadata.txt
**Purpose:** Plugin metadata for QField  
**Format:** INI file  
**Contents:**
```ini
[general]
name=QField Render Sync
version=1.0.0
qfield_min_version=3.0
author=CES
description=Sync photos to Render WebDAV and PostgreSQL
```

---

#### icon.svg
**Purpose:** Plugin icon  
**Format:** SVG (Scalable Vector Graphics)  
**Size:** 64x64 pixels  
**Design:** Camera with sync arrows on green background

---

### UI Components

#### components/SyncDialog.qml
**Purpose:** Main user interface for photo synchronization  
**Size:** ~450 lines  
**Features:**
- Layer selection dropdown
- Pending photo count display
- Connection testing button
- Progress bar with status
- Success/failure statistics
- Error message display
- Start/cancel buttons

**State Management:**
- syncing (boolean)
- currentPhotoIndex (int)
- successCount (int)
- failureCount (int)
- errors (array)

---

### JavaScript Modules

#### js/utils.js
**Purpose:** Utility functions used throughout the plugin  
**Size:** ~180 lines  
**Functions:**
- `validateUrl(url)` - URL validation
- `isLocalPath(path)` - Local path detection
- `sanitizeFilename(name)` - Filename sanitization
- `generatePhotoFilename(id, ext)` - Unique filename generation
- `parseProjectVariables(project)` - Configuration extraction
- `validateConfiguration(config)` - Configuration validation
- `formatFileSize(bytes)` - Human-readable file sizes
- `log(level, message)` - Logging utility

---

#### js/webdav_client.js
**Purpose:** WebDAV upload client  
**Size:** ~200 lines  
**Functions:**
- `checkFileExists(url, auth, callback)` - Duplicate detection
- `uploadPhoto(local, remote, auth, progress, complete)` - Photo upload
- `uploadPhotoWithCheck(...)` - Upload with duplicate check
- `testConnection(url, auth, callback)` - Connection validation

**Features:**
- Progress tracking (0-100%)
- Timeout handling (2 minutes)
- Error recovery
- Basic authentication

---

#### js/api_client.js
**Purpose:** REST API client for database updates  
**Size:** ~250 lines  
**Functions:**
- `updatePhoto(url, token, id, photoUrl, table, field, callback)` - Single update
- `batchUpdatePhotos(url, token, updates, callback)` - Batch update
- `getPhotoStatus(url, token, id, table, callback)` - Status query
- `testConnection(url, token, callback)` - Connection validation
- `updatePhotoWithRetry(...)` - Update with retry logic

**Features:**
- Bearer token authentication
- Retry logic (3 attempts)
- Timeout handling (30 seconds)
- Error parsing

---

#### js/sync_engine.js
**Purpose:** Sync workflow orchestration  
**Size:** ~280 lines  
**Functions:**
- `findPendingPhotos(layer, field)` - Photo detection
- `syncPhoto(data, config, layer, progress, complete)` - Single photo sync
- `syncAllPhotos(photos, config, layer, callbacks)` - Batch sync
- `validateSyncPrerequisites(config, layer)` - Pre-sync validation
- `testConnections(config, callback)` - Connection testing
- `getSyncStatistics(layer, field)` - Statistics calculation

**Workflow:**
1. Find pending photos (local paths)
2. Upload to WebDAV (with duplicate check)
3. Update database via API
4. Update local layer
5. Report results

---

### Documentation Files

#### README.md
**Purpose:** Complete user documentation  
**Size:** ~500 lines  
**Sections:**
- Overview & features
- Architecture diagram
- Requirements
- Installation instructions
- Usage guide
- Configuration reference
- Troubleshooting
- Technical details

**Audience:** End users, field workers

---

#### DEPLOYMENT.md
**Purpose:** Deployment and configuration guide  
**Size:** ~600 lines  
**Sections:**
- Prerequisites
- Packaging instructions
- QGIS project configuration
- QFieldCloud setup
- Mobile installation
- Field testing
- Troubleshooting
- Production checklist

**Audience:** System administrators, IT staff

---

#### TESTING.md
**Purpose:** Comprehensive testing guide  
**Size:** ~550 lines  
**Sections:**
- Test environment setup
- Unit tests
- Integration tests
- UI tests
- Field tests
- Performance tests
- Test data
- Test reporting

**Audience:** QA testers, developers

---

#### QUICKSTART.md
**Purpose:** 5-minute setup guide  
**Size:** ~150 lines  
**Sections:**
- Quick setup steps
- Configuration reference
- Usage examples
- Troubleshooting tips

**Audience:** Users wanting quick start

---

#### PROJECT_SUMMARY.md
**Purpose:** Executive project summary  
**Size:** ~700 lines  
**Sections:**
- Executive summary
- Architecture overview
- Implementation details
- Performance metrics
- Security features
- Cost analysis
- Deployment status
- Future enhancements

**Audience:** Project managers, stakeholders

---

### Utility Files

#### package.ps1
**Purpose:** PowerShell script to create distribution ZIP  
**Size:** ~150 lines  
**Features:**
- File validation
- Automatic ZIP creation
- File count reporting
- Next steps guidance

**Usage:**
```powershell
.\package.ps1 -Version "1.0.0" -OutputDir ".."
```

---

## Code Statistics

### Lines of Code

| Component | Lines | Percentage |
|-----------|-------|------------|
| main.qml | 340 | 20% |
| SyncDialog.qml | 450 | 26% |
| utils.js | 180 | 11% |
| webdav_client.js | 200 | 12% |
| api_client.js | 250 | 15% |
| sync_engine.js | 280 | 16% |
| **Total Code** | **1,700** | **100%** |

### Documentation

| Document | Lines | Purpose |
|----------|-------|---------|
| README.md | 500 | User guide |
| DEPLOYMENT.md | 600 | Deployment |
| TESTING.md | 550 | Testing |
| QUICKSTART.md | 150 | Quick start |
| PROJECT_SUMMARY.md | 700 | Executive summary |
| STRUCTURE.md | 400 | This file |
| **Total Docs** | **2,900** | |

---

## Dependencies

### QML Imports

```qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.3
import org.qfield 1.0
import org.qgis 1.0
```

### JavaScript Imports

```javascript
.import "utils.js" as Utils
.import "webdav_client.js" as WebDAV
.import "api_client.js" as API
.import "sync_engine.js" as SyncEngine
```

### External Dependencies

- **QField 3.0+** - Mobile GIS application
- **QGIS 3.x** - Desktop GIS for configuration
- **QFieldCloud** - Project synchronization
- **Render API** - REST API for database updates
- **Render WebDAV** - Photo storage server

---

## Configuration Flow

```
QGIS Desktop
    │
    ├─ Set project variables (7 variables)
    │
    ├─ Save project
    │
    └─ Push to QFieldCloud
            │
            ▼
    QFieldCloud
            │
            ├─ Store project
            │
            └─ Sync to mobile devices
                    │
                    ▼
            QField Mobile
                    │
                    ├─ Download project
                    │
                    ├─ Load plugin (main.qml)
                    │
                    ├─ Read project variables
                    │
                    └─ Configure plugin automatically
```

---

## Data Flow

```
1. Photo Capture
   QField → Local storage → Photo field (local path)

2. Photo Sync
   Plugin → WebDAV client → Render WebDAV
                          ↓
                    Photo URL returned
                          ↓
   Plugin → API client → REST API → PostgreSQL
                          ↓
                    Database updated
                          ↓
   Plugin → Update local layer → Photo field (URL)
```

---

## Error Handling Flow

```
Operation Attempt
    │
    ├─ Success → Continue
    │
    └─ Failure
        │
        ├─ Network error → Retry (3x)
        │
        ├─ Authentication error → Report to user
        │
        ├─ Timeout → Retry with backoff
        │
        └─ Other error → Log and report
```

---

## File Sizes (Approximate)

| File | Size |
|------|------|
| main.qml | 12 KB |
| SyncDialog.qml | 16 KB |
| utils.js | 6 KB |
| webdav_client.js | 7 KB |
| api_client.js | 9 KB |
| sync_engine.js | 10 KB |
| icon.svg | 2 KB |
| metadata.txt | 1 KB |
| README.md | 25 KB |
| DEPLOYMENT.md | 30 KB |
| TESTING.md | 28 KB |
| QUICKSTART.md | 8 KB |
| PROJECT_SUMMARY.md | 35 KB |
| **Total** | **~190 KB** |

**ZIP Archive:** ~60-80 KB (compressed)

---

## Version History

### v1.0.0 (2025-10-06)
- Initial release
- WebDAV upload support
- REST API integration
- Project variable configuration
- Progress tracking
- Error handling
- Complete documentation

---

## Future Structure (Planned)

### v1.1 (Planned)
```
QField-Render-Sync/
├── ... (existing files)
├── components/
│   ├── SyncDialog.qml
│   ├── SettingsDialog.qml      # NEW: Manual settings
│   └── HistoryDialog.qml       # NEW: Upload history
├── js/
│   ├── ... (existing modules)
│   ├── offline_queue.js        # NEW: Offline queue
│   └── compression.js          # NEW: Photo compression
└── tests/
    ├── test_utils.qml          # NEW: Unit tests
    ├── test_webdav.qml         # NEW: WebDAV tests
    └── test_api.qml            # NEW: API tests
```

---

**Last Updated:** 2025-10-06  
**Version:** 1.0.0  
**Structure Version:** 1.0
