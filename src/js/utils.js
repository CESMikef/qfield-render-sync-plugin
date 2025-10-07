.pragma library

/**
 * Utility Functions
 * =================
 * 
 * Helper functions used throughout the plugin.
 */

/**
 * Validate URL format
 * @param {string} url - URL to validate
 * @returns {boolean} - True if valid URL
 */
function validateUrl(url) {
    if (!url || typeof url !== 'string') {
        return false;
    }
    return /^https?:\/\/.+/.test(url);
}

/**
 * Get current ISO 8601 timestamp
 * @returns {string} - Formatted timestamp
 */
function formatTimestamp() {
    return new Date().toISOString();
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
 * Parse project variables into configuration object
 * @param {object} project - QGIS project object
 * @returns {object} - Configuration object
 */
function parseProjectVariables(project) {
    if (!project) {
        return null;
    }
    
    return {
        webdavUrl: project.customVariable('render_webdav_url') || '',
        webdavUsername: project.customVariable('render_webdav_username') || '',
        webdavPassword: project.customVariable('render_webdav_password') || '',
        apiUrl: project.customVariable('render_api_url') || '',
        apiToken: project.customVariable('render_api_token') || '',
        dbTable: project.customVariable('render_db_table') || 'design.verify_poles',
        photoField: project.customVariable('render_photo_field') || 'photo'
    };
}

/**
 * Validate configuration completeness
 * @param {object} config - Configuration object
 * @returns {object} - {valid: boolean, missing: array}
 */
function validateConfiguration(config) {
    var required = [
        'webdavUrl',
        'webdavUsername',
        'webdavPassword',
        'apiUrl',
        'apiToken'
    ];
    
    var missing = [];
    
    for (var i = 0; i < required.length; i++) {
        var key = required[i];
        if (!config[key] || config[key].trim() === '') {
            missing.push(key);
        }
    }
    
    return {
        valid: missing.length === 0,
        missing: missing
    };
}

/**
 * Check if path is a local file path (not a URL)
 * @param {string} path - Path to check
 * @returns {boolean} - True if local path
 */
function isLocalPath(path) {
    if (!path || typeof path !== 'string') {
        return false;
    }
    
    // Check if it's a URL
    if (/^https?:\/\//i.test(path)) {
        return false;
    }
    
    // Check if it's a local path (contains file separators or drive letters)
    return /[\/\\]/.test(path) || /^[a-zA-Z]:/.test(path);
}

/**
 * Extract file extension from path
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
 * Format bytes to human-readable size
 * @param {number} bytes - Size in bytes
 * @returns {string} - Formatted size
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    
    var k = 1024;
    var sizes = ['B', 'KB', 'MB', 'GB'];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Log message with timestamp
 * @param {string} level - Log level (INFO, WARN, ERROR)
 * @param {string} message - Log message
 */
function log(level, message) {
    var timestamp = new Date().toISOString();
    console.log('[' + timestamp + '] [' + level + '] ' + message);
}

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
 * Sleep/delay function
 * @param {number} ms - Milliseconds to wait
 * @returns {Promise} - Promise that resolves after delay
 */
function sleep(ms) {
    return new Promise(function(resolve) {
        setTimeout(resolve, ms);
    });
}
