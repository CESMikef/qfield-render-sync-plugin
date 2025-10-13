.pragma library

/**
 * WebDAV Client
 * ==============
 * 
 * Handles photo uploads to Render WebDAV server.
 * Supports duplicate detection and progress tracking.
 */

/**
 * Create Basic Auth header value
 * @param {string} username - Username
 * @param {string} password - Password
 * @returns {string} - Base64 encoded credentials
 */
function createBasicAuth(username, password) {
    return Qt.btoa(username + ':' + password);
}

/**
 * Parse error message from response
 * @param {object} response - HTTP response object
 * @returns {string} - Error message
 */
function parseErrorMessage(response) {
    try {
        if (response.responseText) {
            var data = JSON.parse(response.responseText);
            if (data.error) return data.error;
            if (data.detail) return data.detail;
            if (data.message) return data.message;
        }
    } catch (e) {
        // Ignore JSON parse errors
    }
    
    return 'HTTP ' + response.status + ': ' + response.statusText;
}

/**
 * Get file extension from path
 * @param {string} path - File path
 * @returns {string} - File extension (without dot)
 */
function getFileExtension(path) {
    if (!path) return '';
    
    var parts = path.split('.');
    if (parts.length > 1) {
        return parts[parts.length - 1].toLowerCase();
    }
    return 'jpg'; // Default
}

/**
 * Sanitize filename for safe storage
 * @param {string} filename - Original filename
 * @returns {string} - Sanitized filename
 */
function sanitizeFilename(filename) {
    if (!filename) return '';
    
    // Remove path separators and special characters
    return filename
        .replace(/[\/\\]/g, '_')
        .replace(/[^a-zA-Z0-9._-]/g, '_')
        .replace(/_+/g, '_')
        .substring(0, 255); // Limit length
}

/**
 * Generate unique photo filename
 * @param {string} globalId - Feature global ID
 * @param {string} extension - File extension (default: jpg)
 * @returns {string} - Unique filename
 */
function generatePhotoFilename(globalId, extension) {
    extension = extension || 'jpg';
    var timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0] + '_' + 
                    new Date().toISOString().replace(/[:.]/g, '-').split('T')[1].split('Z')[0];
    var sanitizedId = sanitizeFilename(globalId);
    return sanitizedId + '_' + timestamp + '.' + extension;
}

/**
 * Check if file exists on WebDAV server
 * @param {string} url - Full WebDAV URL
 * @param {string} username - WebDAV username
 * @param {string} password - WebDAV password
 * @param {function} callback - Callback(exists, error)
 */
function checkFileExists(url, username, password, callback) {
    var xhr = new XMLHttpRequest();
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 207) {
                // File exists
                callback(true, null);
            } else if (xhr.status === 404) {
                // File doesn't exist
                callback(false, null);
            } else {
                // Error
                var error = parseErrorMessage(xhr);
                callback(false, error);
            }
        }
    };
    
    xhr.open('HEAD', url, true);
    xhr.setRequestHeader('Authorization', 'Basic ' + createBasicAuth(username, password));
    
    try {
        xhr.send();
    } catch (e) {
        callback(false, 'Network error: ' + e.toString());
    }
}

/**
 * Upload photo to WebDAV server
 * @param {string} localPath - Local file path
 * @param {string} remoteUrl - Remote WebDAV URL
 * @param {string} username - WebDAV username
 * @param {string} password - WebDAV password
 * @param {function} onProgress - Progress callback(percent)
 * @param {function} onComplete - Completion callback(success, error)
 */
function uploadPhoto(localPath, remoteUrl, username, password, onProgress, onComplete) {
    // Read local file
    var file = Qt.createQmlObject('import Qt.labs.platform 1.1; StandardPaths {}', Qt.application);
    
    var xhr = new XMLHttpRequest();
    
    // Track upload progress
    xhr.upload.onprogress = function(event) {
        if (event.lengthComputable && onProgress) {
            var percent = Math.round((event.loaded / event.total) * 100);
            onProgress(percent);
        }
    };
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 201 || xhr.status === 204) {
                // Upload successful
                console.log('[WebDAV] Photo uploaded successfully: ' + remoteUrl);
                onComplete(true, null);
            } else {
                // Upload failed
                var error = parseErrorMessage(xhr);
                console.log('[WebDAV] ERROR: Photo upload failed: ' + error);
                onComplete(false, error);
            }
        }
    };
    
    xhr.onerror = function() {
        var error = 'Network error during upload';
        console.log('[WebDAV] ERROR: ' + error);
        onComplete(false, error);
    };
    
    xhr.ontimeout = function() {
        var error = 'Upload timeout';
        console.log('[WebDAV] ERROR: ' + error);
        onComplete(false, error);
    };
    
    // Configure request
    xhr.open('PUT', remoteUrl, true);
    xhr.setRequestHeader('Authorization', 'Basic ' + createBasicAuth(username, password));
    xhr.setRequestHeader('Content-Type', 'application/octet-stream');
    xhr.timeout = 120000; // 2 minutes timeout
    
    try {
        // Read file and upload
        var fileUrl = 'file:///' + localPath.replace(/\\/g, '/');
        var fileReader = new XMLHttpRequest();
        
        fileReader.onreadystatechange = function() {
            if (fileReader.readyState === XMLHttpRequest.DONE) {
                if (fileReader.status === 200 || fileReader.status === 0) {
                    // File read successfully, now upload
                    try {
                        xhr.send(fileReader.responseText);
                    } catch (e) {
                        onComplete(false, 'Failed to send file: ' + e.toString());
                    }
                } else {
                    onComplete(false, 'Failed to read local file: ' + localPath);
                }
            }
        };
        
        fileReader.open('GET', fileUrl, true);
        fileReader.responseType = 'arraybuffer';
        fileReader.send();
        
    } catch (e) {
        onComplete(false, 'Failed to read file: ' + e.toString());
    }
}

/**
 * Upload photo with duplicate check
 * @param {string} localPath - Local file path
 * @param {string} globalId - Feature global ID
 * @param {string} webdavUrl - WebDAV base URL
 * @param {string} username - WebDAV username
 * @param {string} password - WebDAV password
 * @param {function} onProgress - Progress callback(percent, status)
 * @param {function} onComplete - Completion callback(success, photoUrl, error)
 */
function uploadPhotoWithCheck(localPath, globalId, webdavUrl, username, password, onProgress, onComplete) {
    try {
        if (onProgress) onProgress(0, 'Preparing upload...');
        
        // Generate unique filename based on the original filename to maintain consistency
        if (onProgress) onProgress(1, 'Getting file extension...');
        var extension = getFileExtension(localPath);
        
        if (onProgress) onProgress(2, 'Extracting filename...');
        // Extract original filename from path
        var pathParts = String(localPath).replace(/\\/g, '/').split('/');
        var originalFilename = pathParts[pathParts.length - 1];
        
        if (onProgress) onProgress(3, 'Generating filename...');
        // Use original filename if it exists, otherwise generate one
        var filename = originalFilename || generatePhotoFilename(globalId, extension);
        
        if (onProgress) onProgress(4, 'Building remote URL...');
        var remoteUrl = String(webdavUrl).replace(/\/$/, '') + '/' + filename;
        
        if (onProgress) onProgress(5, 'Starting upload...');
        
        // SKIP duplicate check in QField - just upload directly
        // This avoids file reading issues in QML
    
    // Try to upload using file:// URL directly
    uploadPhotoDirectly(
        localPath,
        remoteUrl,
        username,
        password,
        function(percent, status) {
            if (onProgress) onProgress(percent, status || ('Uploading... ' + percent + '%'));
        },
        function(success, uploadError) {
            if (success) {
                console.log('[WebDAV] Upload successful: ' + remoteUrl);
                if (onProgress) onProgress(100, 'Upload complete');
                onComplete(true, remoteUrl, null);
            } else {
                console.log('[WebDAV] Upload failed: ' + uploadError);
                onComplete(false, null, uploadError);
            }
        }
    );
    
    } catch (e) {
        if (onProgress) onProgress(99, 'EXCEPTION in uploadPhotoWithCheck: ' + e.toString());
        onComplete(false, null, 'Exception: ' + e.toString());
    }
}

/**
 * Upload photo directly without reading into memory
 * Uses file:// URL to let XHR handle the file reading
 */
function uploadPhotoDirectly(localPath, remoteUrl, username, password, onProgress, onComplete) {
    try {
        if (onProgress) onProgress(6, 'Creating upload request...');
        var xhr = new XMLHttpRequest();
        
        if (onProgress) onProgress(7, 'Setting up event handlers...');
        
        // QML XMLHttpRequest doesn't support xhr.upload.onprogress
        // Just use basic onreadystatechange
        
        xhr.onreadystatechange = function() {
            if (onProgress) onProgress(8, 'State changed: ' + xhr.readyState);
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 201 || xhr.status === 204) {
                console.log('[WebDAV] Photo uploaded successfully');
                onComplete(true, null);
            } else {
                var error = parseErrorMessage(xhr);
                console.log('[WebDAV] ERROR: Upload failed: ' + error);
                onComplete(false, error);
            }
        }
    };
    
    xhr.onerror = function() {
        console.log('[WebDAV] ERROR: Network error during upload');
        onComplete(false, 'Network error during upload');
    };
    
    xhr.ontimeout = function() {
        console.log('[WebDAV] ERROR: Upload timeout');
        onComplete(false, 'Upload timeout');
    };
    
    // Configure request
    xhr.open('PUT', remoteUrl, true);
    xhr.setRequestHeader('Authorization', 'Basic ' + createBasicAuth(username, password));
    xhr.setRequestHeader('Content-Type', 'image/jpeg');
    xhr.timeout = 120000; // 2 minutes
    
    try {
        // Convert Windows path to file URL
        var fileUrl = localPath;
        if (!fileUrl.startsWith('file://')) {
            fileUrl = 'file:///' + localPath.replace(/\\/g, '/');
        }
        
        // console.log('[WebDAV] Reading from: ' + fileUrl);
        if (onProgress) onProgress(5, 'Reading file...');
        
        // Try to read and upload the file
        if (onProgress) onProgress(6, 'Creating file reader...');
        var fileReader = new XMLHttpRequest();
        
        if (onProgress) onProgress(7, 'Setting response type...');
        fileReader.responseType = 'arraybuffer';
        
        if (onProgress) onProgress(8, 'Setting up file reader callbacks...');
        fileReader.onreadystatechange = function() {
            if (onProgress) onProgress(9, 'File reader state: ' + fileReader.readyState);
            if (fileReader.readyState === XMLHttpRequest.DONE) {
                if (onProgress) onProgress(10, 'File read complete, status: ' + fileReader.status);
                if (fileReader.status === 200 || fileReader.status === 0) {
                    // console.log('[WebDAV] File read successfully, uploading...');
                    if (onProgress) onProgress(15, 'Uploading to server...');
                    try {
                        xhr.send(fileReader.response);
                    } catch (e) {
                        // console.log('[WebDAV] ERROR: Failed to send: ' + e.toString());
                        onComplete(false, 'Failed to send file: ' + e.toString());
                    }
                } else {
                    // console.log('[WebDAV] ERROR: Failed to read file, status: ' + fileReader.status);
                    onComplete(false, 'Cannot read file, status: ' + fileReader.status);
                }
            }
        };
        
        fileReader.onerror = function() {
            if (onProgress) onProgress(99, 'File reader ERROR!');
            // console.log('[WebDAV] ERROR: File read error');
            onComplete(false, 'Error reading file');
        };
        
        if (onProgress) onProgress(11, 'Opening file reader...');
        fileReader.open('GET', fileUrl, true);
        
        if (onProgress) onProgress(12, 'Sending file reader request...');
        fileReader.send();
        
    } catch (e) {
        // console.log('[WebDAV] ERROR: Exception: ' + e.toString());
        onComplete(false, 'Failed to process file: ' + e.toString());
    }
    
    } catch (e) {
        if (onProgress) onProgress(99, 'EXCEPTION in uploadPhotoDirectly: ' + e.toString());
        onComplete(false, 'Exception in uploadPhotoDirectly: ' + e.toString());
    }
}

/**
 * Test WebDAV connection
 * @param {string} url - WebDAV URL
 * @param {string} username - Username
 * @param {string} password - Password
 * @param {function} callback - Callback(success, error)
 */
function testConnection(url, username, password, callback) {
    var xhr = new XMLHttpRequest();
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200 || xhr.status === 207 || xhr.status === 404) {
                // Connection successful (404 is OK for root check)
                callback(true, null);
            } else if (xhr.status === 401) {
                callback(false, 'Authentication failed - check username/password');
            } else {
                var error = parseErrorMessage(xhr);
                callback(false, error);
            }
        }
    };
    
    xhr.onerror = function() {
        callback(false, 'Network error - cannot reach server');
    };
    
    xhr.ontimeout = function() {
        callback(false, 'Connection timeout');
    };
    
    xhr.open('HEAD', url, true);
    xhr.setRequestHeader('Authorization', 'Basic ' + createBasicAuth(username, password));
    xhr.timeout = 10000; // 10 seconds
    
    try {
        xhr.send();
    } catch (e) {
        callback(false, 'Connection error: ' + e.toString());
    }
}
