# QField Render Sync Plugin

## ⚠️ PROJECT DISCONTINUED

**This project has been discontinued due to fundamental technical limitations.**

[![Status](https://img.shields.io/badge/status-discontinued-red.svg)](https://github.com/CESMikef/qfield-render-sync-plugin)
[![Version](https://img.shields.io/badge/version-5.0.0-inactive.svg)](https://github.com/CESMikef/qfield-render-sync-plugin/releases)

---

## 🚫 Why Discontinued

**QML Security Restriction** prevents plugins from accessing local files for upload.

### Technical Details

**Root Cause:**
- QML/Qt restricts `XMLHttpRequest` from accessing local filesystem
- `file://` URLs are blocked in web contexts
- This is by design for security reasons
- No workaround exists within pure QML/JavaScript

**Impact:**
- Plugin cannot read photos from device storage
- Cannot upload files to WebDAV or API
- Cannot implement intended workflow

---

## 📊 Development History

### Attempted Approaches

**v1.0 - v3.x: Direct WebDAV Upload**
- Attempted to read local files and upload to WebDAV
- **Result:** ❌ Failed - QML cannot access `file://` URLs

**v4.x: API-Based Upload**
- Attempted to send files to API endpoint
- **Result:** ❌ Failed - Same QML security restriction

**v5.0.0: Database Sync Only**
- Simplified to database updates only
- **Result:** ❌ Incomplete - Cannot determine which photos need syncing without file access

---

## 🎯 Original Objective

Intended to provide:
- Automatic photo upload to WebDAV from QField
- PostgreSQL database updates via REST API
- Zero-configuration sync from mobile device

**Status:** Technically impossible within QField plugin architecture

## 📁 Repository Contents

This repository contains the development history and source code for reference purposes only.

### Key Files
- `CRITICAL_LIMITATION.md` - Detailed technical analysis of the blocking issue
- `CHANGELOG.md` - Complete version history
- `src/` - Plugin source code (non-functional)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👥 Authors

Developed by **CES** for field data collection workflows.

---

**Project Status**: Discontinued  
**Last Updated**: 2025-10-14  
**Final Version**: 5.0.0
