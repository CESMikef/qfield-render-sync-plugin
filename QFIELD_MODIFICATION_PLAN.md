# QField Core Modification Plan

## 🎯 Objective

Add native file upload capability to QField core so plugins can upload photos without QML security restrictions.

---

## 📋 Overview

**Repository:** https://github.com/opengisch/QField  
**License:** GPL v2+ (Open Source - we can modify!)  
**Language:** C++ (Qt/QML)  
**Our Goal:** Add `FileUploader` class that plugins can use

---

## 🔧 Implementation Plan

### Step 1: Create C++ FileUploader Class

**File:** `src/core/fileuploader.h`

```cpp
#ifndef FILEUPLOADER_H
#define FILEUPLOADER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>
#include <QHttpMultiPart>

class FileUploader : public QObject
{
    Q_OBJECT
    
public:
    explicit FileUploader(QObject *parent = nullptr);
    ~FileUploader();
    
    // Main upload method exposed to QML
    Q_INVOKABLE void uploadFile(const QString &localPath,
                                 const QString &uploadUrl,
                                 const QString &authToken,
                                 const QVariantMap &formData);
    
    // Cancel ongoing upload
    Q_INVOKABLE void cancel();
    
signals:
    void uploadProgress(int percent, const QString &status);
    void uploadComplete(bool success, const QString &error);
    void uploadStarted();
    
private slots:
    void onUploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void onUploadFinished();
    void onError(QNetworkReply::NetworkError error);
    
private:
    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    QFile *m_currentFile;
};

#endif // FILEUPLOADER_H
```

**File:** `src/core/fileuploader.cpp`

```cpp
#include "fileuploader.h"
#include <QHttpMultiPart>
#include <QHttpPart>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QDebug>

FileUploader::FileUploader(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_currentFile(nullptr)
{
}

FileUploader::~FileUploader()
{
    cancel();
}

void FileUploader::uploadFile(const QString &localPath,
                               const QString &uploadUrl,
                               const QString &authToken,
                               const QVariantMap &formData)
{
    // Cancel any ongoing upload
    cancel();
    
    emit uploadStarted();
    emit uploadProgress(0, "Preparing upload...");
    
    // Open the file
    m_currentFile = new QFile(localPath, this);
    if (!m_currentFile->open(QIODevice::ReadOnly)) {
        emit uploadComplete(false, "Cannot open file: " + localPath);
        delete m_currentFile;
        m_currentFile = nullptr;
        return;
    }
    
    emit uploadProgress(10, "Reading file...");
    
    // Create multipart form data
    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    
    // Add file part
    QHttpPart filePart;
    QFileInfo fileInfo(localPath);
    QString filename = fileInfo.fileName();
    
    filePart.setHeader(QNetworkRequest::ContentTypeHeader, 
                       QMimeDatabase().mimeTypeForFile(localPath).name());
    filePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                       QVariant(QString("form-data; name=\"file\"; filename=\"%1\"")
                               .arg(filename)));
    filePart.setBodyDevice(m_currentFile);
    m_currentFile->setParent(multiPart); // File will be deleted with multiPart
    multiPart->append(filePart);
    
    // Add additional form fields
    for (auto it = formData.constBegin(); it != formData.constEnd(); ++it) {
        QHttpPart textPart;
        textPart.setHeader(QNetworkRequest::ContentDispositionHeader,
                          QVariant(QString("form-data; name=\"%1\"").arg(it.key())));
        textPart.setBody(it.value().toString().toUtf8());
        multiPart->append(textPart);
    }
    
    emit uploadProgress(20, "Uploading to server...");
    
    // Create request
    QNetworkRequest request(uploadUrl);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(authToken).toUtf8());
    
    // Send request
    m_currentReply = m_networkManager->post(request, multiPart);
    multiPart->setParent(m_currentReply); // Delete multiPart with reply
    
    // Connect signals
    connect(m_currentReply, &QNetworkReply::uploadProgress,
            this, &FileUploader::onUploadProgress);
    connect(m_currentReply, &QNetworkReply::finished,
            this, &FileUploader::onUploadFinished);
    connect(m_currentReply, QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::error),
            this, &FileUploader::onError);
}

void FileUploader::cancel()
{
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }
    
    if (m_currentFile) {
        m_currentFile->close();
        m_currentFile->deleteLater();
        m_currentFile = nullptr;
    }
}

void FileUploader::onUploadProgress(qint64 bytesSent, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        int percent = 20 + (int)((bytesSent * 70) / bytesTotal); // 20-90%
        emit uploadProgress(percent, QString("Uploading... %1/%2 bytes")
                           .arg(bytesSent).arg(bytesTotal));
    }
}

void FileUploader::onUploadFinished()
{
    if (!m_currentReply) return;
    
    emit uploadProgress(90, "Processing response...");
    
    if (m_currentReply->error() == QNetworkReply::NoError) {
        QByteArray response = m_currentReply->readAll();
        qDebug() << "Upload successful:" << response;
        emit uploadProgress(100, "Upload complete");
        emit uploadComplete(true, QString());
    } else {
        QString error = m_currentReply->errorString();
        qDebug() << "Upload failed:" << error;
        emit uploadComplete(false, error);
    }
    
    m_currentReply->deleteLater();
    m_currentReply = nullptr;
    
    if (m_currentFile) {
        m_currentFile->close();
        m_currentFile->deleteLater();
        m_currentFile = nullptr;
    }
}

void FileUploader::onError(QNetworkReply::NetworkError error)
{
    Q_UNUSED(error)
    // Error will be handled in onUploadFinished
}
```

---

### Step 2: Register with QML Engine

**File:** `src/qml/qgismobileapp.cpp` (or wherever QML types are registered)

```cpp
#include "fileuploader.h"

// In the QML type registration function:
qmlRegisterType<FileUploader>("org.qfield", 1, 0, "FileUploader");
```

---

### Step 3: Update CMakeLists.txt

**File:** `src/core/CMakeLists.txt`

```cmake
set(QFIELD_CORE_SRCS
    # ... existing files ...
    fileuploader.cpp
    fileuploader.h
)
```

---

### Step 4: Use in Plugin

**File:** `qfield-render-sync-plugin/src/main.qml`

```qml
import org.qfield 1.0

Item {
    id: plugin
    
    // Add FileUploader instance
    FileUploader {
        id: fileUploader
        
        onUploadProgress: {
            console.log("[FileUploader] Progress: " + percent + "% - " + status)
        }
        
        onUploadComplete: {
            if (success) {
                console.log("[FileUploader] Upload successful!")
            } else {
                console.log("[FileUploader] Upload failed: " + error)
            }
        }
    }
    
    // Make it available to JavaScript
    property var uploader: fileUploader
}
```

**File:** `qfield-render-sync-plugin/src/js/webdav_client.js`

```javascript
function uploadPhotoViaAPI(localPath, globalId, table, field, apiUrl, apiToken, onProgress, onComplete) {
    try {
        // Use QField's native FileUploader instead of XMLHttpRequest
        var uploader = plugin.uploader;
        
        if (!uploader) {
            onComplete(false, 'FileUploader not available');
            return;
        }
        
        // Prepare form data
        var formData = {
            'global_id': globalId,
            'table': table,
            'field': field
        };
        
        // Set up callbacks
        var progressHandler = function(percent, status) {
            if (onProgress) onProgress(percent, status);
        };
        
        var completeHandler = function(success, error) {
            if (success) {
                onComplete(true, null);
            } else {
                onComplete(false, error);
            }
        };
        
        // Connect signals
        uploader.uploadProgress.connect(progressHandler);
        uploader.uploadComplete.connect(completeHandler);
        
        // Start upload
        var endpoint = apiUrl.replace(/\/$/, '') + '/api/v1/photos/upload-and-update';
        uploader.uploadFile(localPath, endpoint, apiToken, formData);
        
    } catch (e) {
        onComplete(false, 'Exception in uploadPhotoViaAPI: ' + e.toString());
    }
}
```

---

## 🚀 Implementation Steps

### 1. Fork QField Repository

```bash
# Fork on GitHub: https://github.com/opengisch/QField
# Then clone your fork
git clone https://github.com/CESMikef/QField.git
cd QField
git checkout -b feature/file-uploader-api
```

### 2. Add FileUploader Class

```bash
# Create files
touch src/core/fileuploader.h
touch src/core/fileuploader.cpp

# Copy the code from above into these files
```

### 3. Build QField

```bash
# Install dependencies (varies by platform)
# See: https://github.com/opengisch/QField/blob/master/doc/development.md

# Build
mkdir build
cd build
cmake ..
make
```

### 4. Test the Changes

```bash
# Run QField with your changes
./QField

# Install your plugin
# Test photo upload
```

### 5. Create Pull Request

```bash
# Commit changes
git add src/core/fileuploader.*
git commit -m "Add FileUploader API for plugins"
git push origin feature/file-uploader-api

# Create PR on GitHub
```

---

## 📝 Pull Request Description

**Title:** Add FileUploader API for plugin file upload support

**Description:**
```markdown
## Summary
Adds a native `FileUploader` class that plugins can use to upload files without QML security restrictions.

## Motivation
QML plugins cannot read local files using `XMLHttpRequest` due to security restrictions. This prevents plugins from implementing photo sync or file upload features.

## Changes
- Added `FileUploader` C++ class in `src/core/`
- Exposed to QML as `org.qfield.FileUploader`
- Supports multipart/form-data uploads
- Provides progress callbacks
- Handles authentication headers

## Usage Example
```qml
FileUploader {
    id: uploader
    onUploadComplete: {
        console.log(success ? "Success!" : "Failed: " + error)
    }
}

// In JavaScript:
uploader.uploadFile(localPath, url, token, {key: "value"})
```

## Testing
- Tested with qfield-render-sync-plugin
- Successfully uploads photos to API
- Progress reporting works correctly

## Breaking Changes
None - this is a new API addition

## Related Issues
- Enables photo sync plugins
- Solves file access limitations in QML
```

---

## ⏱️ Timeline Estimate

| Task | Time | Status |
|------|------|--------|
| Fork & setup | 1 hour | ⏳ |
| Implement FileUploader | 4 hours | ⏳ |
| Build & test locally | 2 hours | ⏳ |
| Update plugin to use it | 2 hours | ⏳ |
| Create PR | 1 hour | ⏳ |
| **Total** | **~10 hours** | |

---

## 🎯 Benefits

1. ✅ **Solves the core problem** - Native file access
2. ✅ **Reusable** - Any plugin can use it
3. ✅ **Proper implementation** - Uses Qt's networking
4. ✅ **Community contribution** - Benefits all QField users
5. ✅ **Open source** - We can do this!

---

## 📚 Resources

- **QField Repo:** https://github.com/opengisch/QField
- **Development Docs:** https://github.com/opengisch/QField/blob/master/doc/development.md
- **Qt Network:** https://doc.qt.io/qt-6/qnetworkaccessmanager.html
- **Contributing:** https://github.com/opengisch/QField/blob/master/CONTRIBUTING.md

---

## 🤝 Alternative: Coordinate with QField Team

Instead of a PR, we could:
1. Open an issue proposing this feature
2. Discuss design with maintainers
3. Get approval before implementing
4. Collaborate on implementation

This might be faster if they're receptive to the idea.

---

**Next Steps:** Would you like me to help you fork QField and start implementing this?
