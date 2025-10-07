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
    // Generate unique filename
    var extension = getFileExtension(localPath);
    var filename = generatePhotoFilename(globalId, extension);
    var remoteUrl = webdavUrl.replace(/\/$/, '') + '/' + filename;
    
    console.log('[WebDAV] Starting photo upload: ' + filename);
    
    // Step 1: Check if file already exists
    if (onProgress) onProgress(0, 'Checking for duplicates...');
    
    checkFileExists(remoteUrl, username, password, function(exists, error) {
        if (error) {
            console.log('[WebDAV] ERROR: Failed to check file existence: ' + error);
            onComplete(false, null, error);
            return;
        }
        
        if (exists) {
            // File already exists, skip upload
            console.log('[WebDAV] Photo already exists, skipping upload: ' + filename);
            if (onProgress) onProgress(100, 'Already uploaded');
            onComplete(true, remoteUrl, null);
            return;
        }
        
        // Step 2: Upload file
        if (onProgress) onProgress(0, 'Uploading...');
        
        uploadPhoto(
            localPath,
            remoteUrl,
            username,
            password,
            function(percent) {
                if (onProgress) onProgress(percent, 'Uploading... ' + percent + '%');
            },
            function(success, uploadError) {
                if (success) {
                    if (onProgress) onProgress(100, 'Upload complete');
                    onComplete(true, remoteUrl, null);
                } else {
                    onComplete(false, null, uploadError);
                }
            }
        );
    });
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
                var error = Utils.parseErrorMessage(xhr);
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
