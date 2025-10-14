# Critical Limitation: QML File Access

## 🚨 Problem Discovered

**Date:** October 14, 2025  
**Status:** BLOCKING ISSUE

### The Issue

QML's `XMLHttpRequest` **cannot read local files** using `file://` URLs due to security restrictions. This affects both:

1. **Direct WebDAV upload** (v3.x approach)
2. **API-based upload** (v4.x approach)

### What We Tried

#### v3.x: Direct WebDAV Upload
```javascript
// Tried to read file and upload to WebDAV
var xhr = new XMLHttpRequest();
xhr.open('GET', 'file:///path/to/photo.jpg');
xhr.send(); // FAILS - cannot access file://
```

**Result:** ❌ Cannot read local files

#### v4.0: API-Based Upload
```javascript
// Tried to read file and send to API
var fileReader = new XMLHttpRequest();
fileReader.responseType = 'arraybuffer';
fileReader.open('GET', 'file:///path/to/photo.jpg');
fileReader.send(); // STILL FAILS - same restriction
```

**Result:** ❌ Cannot read local files

### Test Results

From QField logs:
```
[10:46:45] Progress: 0/1 - 9% - Reading file...
[10:46:45] Progress: 0/5 - 30% - [SyncEngine] syncNext() called
[10:46:45] plugin.syncPhotos call completed (no exception)
```

Upload **stops at 9%** (file reading stage) and never progresses.

---

## 🔍 Root Cause

**QML Security Model:**
- QML/Qt restricts `XMLHttpRequest` from accessing local filesystem
- This is by design for security reasons
- `file://` URLs are blocked in web contexts
- No workaround exists within pure QML/JavaScript

---

## 💡 Possible Solutions

### Option 1: QField Core Integration ⭐ RECOMMENDED
**Approach:** Add native file upload capability to QField itself

**Pros:**
- Proper file access through Qt/C++ layer
- Can use Qt's networking classes
- No security restrictions
- Clean implementation

**Cons:**
- Requires QField core changes
- Not a plugin solution
- Needs QField team involvement

**Implementation:**
- Add C++ class exposed to QML
- Use `QFile` to read files
- Use `QNetworkAccessManager` for uploads
- Expose as QML API

### Option 2: Use Qt.labs.platform FileDialog
**Approach:** Let user select file through native dialog

**Pros:**
- Might bypass security restrictions
- Native file picker

**Cons:**
- Poor UX (manual file selection)
- Still may not allow reading
- Not automatic

### Option 3: Server-Side File Access
**Approach:** API accesses files from shared storage

**Pros:**
- No client-side file reading needed

**Cons:**
- Only works if API has filesystem access
- Requires shared storage (WebDAV, cloud, etc.)
- Complex setup

### Option 4: Base64 Encoding in QGIS
**Approach:** Encode photos as base64 in QGIS before syncing

**Pros:**
- Data embedded in database
- No file reading needed

**Cons:**
- Huge database size
- Performance issues
- Not practical for photos

### Option 5: QField Cloud Integration
**Approach:** Use QField Cloud's existing photo sync

**Pros:**
- Already implemented
- Works reliably

**Cons:**
- Requires QField Cloud subscription
- Not self-hosted
- Different workflow

---

## 📋 Recommendation

**Short Term:**
Use **QField Cloud** for photo synchronization until a better solution is available.

**Long Term:**
Work with QField team to add native photo upload API that plugins can use. This would require:

1. **C++ Extension Point** in QField
   ```cpp
   class QFieldFileUploader : public QObject {
       Q_OBJECT
   public:
       Q_INVOKABLE void uploadFile(const QString& localPath, 
                                    const QString& uploadUrl,
                                    const QVariantMap& headers);
   signals:
       void uploadProgress(int percent);
       void uploadComplete(bool success, const QString& error);
   };
   ```

2. **Expose to QML**
   ```qml
   FileUploader {
       id: uploader
       onUploadComplete: {
           // Handle result
       }
   }
   ```

3. **Plugin Uses It**
   ```javascript
   uploader.uploadFile(localPath, apiUrl, {
       "Authorization": "Bearer " + token
   });
   ```

---

## 🎯 Action Items

### For Plugin Development
- [ ] Document this limitation clearly
- [ ] Add error message explaining the issue
- [ ] Provide workaround instructions (use QField Cloud)
- [ ] Keep v3.x code for reference

### For QField Team
- [ ] Propose file upload API addition
- [ ] Create feature request on QField GitHub
- [ ] Discuss security implications
- [ ] Design C++/QML interface

### For Users
- [ ] Use QField Cloud for photo sync
- [ ] OR manually upload photos after field work
- [ ] OR use alternative workflow

---

## 📚 References

- **QML XMLHttpRequest:** https://doc.qt.io/qt-6/qml-qtqml-xmlhttprequest.html
- **Qt Security:** https://doc.qt.io/qt-6/security.html
- **QField Issues:** https://github.com/opengisch/QField/issues

---

## 🔄 Version History

| Version | Approach | Result |
|---------|----------|--------|
| 3.x | Direct WebDAV upload | ❌ Cannot read files |
| 4.0.0 | API-based upload | ❌ Cannot read files |
| 4.0.1 | Config simplification | ❌ Still can't read files |
| 4.0.2 | QML syntax fixes | ❌ Still can't read files |

---

**Conclusion:** This plugin approach is **not viable** without QField core changes or a different architecture that doesn't require reading local files in QML.

**Last Updated:** 2025-10-14
