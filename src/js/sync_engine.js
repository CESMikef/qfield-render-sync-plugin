.pragma library

/**
 * Sync Engine
 * ============
 * 
 * Orchestrates the complete photo sync workflow:
 * 1. Find photos with local paths
 * 2. Upload to WebDAV
 * 3. Update database via API
 * 4. Update local layer
 * 
 * Note: WebDAV and API modules must be passed as parameters to functions
 */

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
 * Validate configuration completeness
 * @param {object} config - Configuration object
 * @returns {object} - {valid: boolean, missing: array}
 */
function validateConfiguration(config) {
    // v4.0.0+: Only API credentials required (WebDAV handled server-side)
    var required = [
        'apiUrl',
        'apiToken',
        'dbTable',
        'photoField'
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
 * Find features with WebDAV URLs that need database sync
 * @param {object} layer - Vector layer
 * @param {string} photoField - Photo field name
 * @returns {array} - Array of features with WebDAV URLs
 */
function findPendingPhotos(layer, photoField) {
    if (!layer) {
        console.log('[Sync] ERROR: Layer is null');
        return [];
    }
    
    var pending = [];
    var features = layer.getFeatures();
    
    for (var i = 0; i < features.length; i++) {
        var feature = features[i];
        var photoUrl = feature.attribute(photoField);
        var globalId = feature.attribute('global_id') || feature.attribute('globalid') || feature.id().toString();
        
        // Check if photo URL exists and is a WebDAV URL (starts with http/https)
        if (photoUrl && (photoUrl.indexOf('http://') === 0 || photoUrl.indexOf('https://') === 0)) {
            pending.push({
                feature: feature,
                globalId: globalId,
                photoUrl: photoUrl
            });
        }
    }
    
    console.log('[Sync] Found ' + pending.length + ' photos with WebDAV URLs');
    return pending;
}

/**
 * Sync single photo (v5.0.0: Database sync only)
 * @param {object} photoData - Photo data object
 * @param {object} config - Configuration object
 * @param {object} layer - Vector layer
 * @param {object} webdavModule - Not used in v5.0.0
 * @param {object} apiModule - API module reference
 * @param {function} onProgress - Progress callback(percent, status)
 * @param {function} onComplete - Completion callback(success, photoUrl, error)
 */
function syncPhoto(photoData, config, layer, webdavModule, apiModule, onProgress, onComplete) {
    var globalId = photoData.globalId;
    var photoUrl = photoData.photoUrl;
    
    if (onProgress) onProgress(0, 'Syncing database...');
    
    // Update database with photo URL (photo already uploaded to WebDAV by QField)
    apiModule.updatePhoto(
        config.apiUrl,
        config.apiToken,
        globalId,
        photoUrl,
        config.dbTable,
        config.photoField,
        function(success, data, error) {
            if (success) {
                if (onProgress) onProgress(100, 'Database updated');
                console.log('[Sync] Database updated for ' + globalId);
                onComplete(true, photoUrl, null);
            } else {
                console.log('[Sync] ERROR: Database update failed: ' + error);
                onComplete(false, null, error);
            }
        }
    );
}

/**
 * Sync all pending photos
 * @param {array} pendingPhotos - Array of photo data objects
 * @param {object} config - Configuration object
 * @param {object} layer - Vector layer
 * @param {object} webdavModule - WebDAV module reference
 * @param {object} apiModule - API module reference
 * @param {function} onPhotoProgress - Progress callback(photoIndex, totalPhotos, percent, status)
 * @param {function} onPhotoComplete - Photo completion callback(photoIndex, success, error)
 * @param {function} onAllComplete - All photos completion callback(results)
 */
function syncAllPhotos(pendingPhotos, config, layer, webdavModule, apiModule, onPhotoProgress, onPhotoComplete, onAllComplete) {
    // DIAGNOSTIC: Report entry
    if (onPhotoProgress) onPhotoProgress(0, 5, 20, "[SyncEngine] syncAllPhotos called");
    
    try {
        if (onPhotoProgress) onPhotoProgress(0, 5, 21, "[SyncEngine] Checking pendingPhotos...");
        
        if (!pendingPhotos || pendingPhotos.length === 0) {
            console.log('[Sync] No photos to sync');
            if (onPhotoProgress) onPhotoProgress(0, 5, 22, "[SyncEngine] No photos to sync");
            onAllComplete({
                total: 0,
                succeeded: 0,
                failed: 0,
                errors: []
            });
            return;
        }
        
        if (onPhotoProgress) onPhotoProgress(0, 5, 23, "[SyncEngine] Photos count: " + pendingPhotos.length);
        
        var results = {
            total: pendingPhotos.length,
            succeeded: 0,
            failed: 0,
            errors: []
        };
        
        if (onPhotoProgress) onPhotoProgress(0, 5, 24, "[SyncEngine] Results object created");
        
        var currentIndex = 0;
        
        if (onPhotoProgress) onPhotoProgress(0, 5, 25, "[SyncEngine] About to define syncNext");
        
        function syncNext() {
            if (onPhotoProgress) onPhotoProgress(0, 5, 26, "[SyncEngine] syncNext called, index: " + currentIndex);
            
            if (currentIndex >= pendingPhotos.length) {
                // All photos processed
                console.log('[Sync] Sync complete: ' + results.succeeded + ' succeeded, ' + results.failed + ' failed');
                onAllComplete(results);
                return;
            }
            
            if (onPhotoProgress) onPhotoProgress(0, 5, 27, "[SyncEngine] Getting photoData...");
            var photoData = pendingPhotos[currentIndex];
            if (onPhotoProgress) onPhotoProgress(0, 5, 28, "[SyncEngine] photoData retrieved");
            
            var photoIndex = currentIndex;
        
        syncPhoto(
            photoData,
            config,
            layer,
            webdavModule,
            apiModule,
            function(percent, status) {
                if (onPhotoProgress) {
                    onPhotoProgress(photoIndex, results.total, percent, status);
                }
            },
            function(success, photoUrl, error) {
                if (success) {
                    results.succeeded++;
                } else {
                    results.failed++;
                    results.errors.push({
                        globalId: photoData.globalId,
                        error: error
                    });
                }
                
                if (onPhotoComplete) {
                    onPhotoComplete(photoIndex, success, error);
                }
                
                // Move to next photo
                currentIndex++;
                
                // Small delay between photos to prevent overwhelming the server
                // Use syncNext directly instead of setTimeout (not available in QML)
                syncNext();
            }
        );
    }
    
    if (onPhotoProgress) onPhotoProgress(0, 5, 29, "[SyncEngine] About to call syncNext()");
    
    // Start syncing
    syncNext();
    
    if (onPhotoProgress) onPhotoProgress(0, 5, 30, "[SyncEngine] syncNext() called");
    
    } catch (e) {
        if (onPhotoProgress) onPhotoProgress(0, 5, 99, "[SyncEngine] EXCEPTION: " + e.toString());
        console.log('[SyncEngine] EXCEPTION in syncAllPhotos: ' + e.toString());
        onAllComplete({
            total: 0,
            succeeded: 0,
            failed: 0,
            errors: ["Exception: " + e.toString()]
        });
    }
}

/**
 * Validate sync prerequisites
 * @param {object} config - Configuration object
 * @param {object} layer - Vector layer
 * @returns {object} - {valid: boolean, errors: array}
 */
function validateSyncPrerequisites(config, layer) {
    var errors = [];
    
    // Validate configuration
    var configValidation = validateConfiguration(config);
    if (!configValidation.valid) {
        errors.push('Missing configuration: ' + configValidation.missing.join(', '));
    }
    
    // Validate API URL
    if (config.apiUrl && !validateUrl(config.apiUrl)) {
        errors.push('Invalid API URL');
    }
    
    // Validate layer
    if (!layer) {
        errors.push('No layer selected');
    } else {
        // Check if layer has required fields
        var fields = layer.fields();
        var hasPhotoField = false;
        var hasGlobalId = false;
        
        for (var i = 0; i < fields.length; i++) {
            var fieldName = fields[i].name().toLowerCase();
            if (fieldName === config.photoField.toLowerCase()) {
                hasPhotoField = true;
            }
            if (fieldName === 'global_id' || fieldName === 'globalid') {
                hasGlobalId = true;
            }
        }
        
        if (!hasPhotoField) {
            errors.push('Layer missing photo field: ' + config.photoField);
        }
        if (!hasGlobalId) {
            errors.push('Layer missing global_id field');
        }
    }
    
    return {
        valid: errors.length === 0,
        errors: errors
    };
}

/**
 * Test all connections
 * @param {object} config - Configuration object
 * @param {object} webdavModule - WebDAV module reference
 * @param {object} apiModule - API module reference
 * @param {function} callback - Callback(results)
 */
function testConnections(config, webdavModule, apiModule, callback) {
    var results = {
        webdav: { success: false, error: null },
        api: { success: false, error: null }
    };
    
    var completed = 0;
    
    function checkComplete() {
        completed++;
        if (completed === 2) {
            callback(results);
        }
    }
    
    // Test WebDAV
    webdavModule.testConnection(
        config.webdavUrl,
        config.webdavUsername,
        config.webdavPassword,
        function(success, error) {
            results.webdav.success = success;
            results.webdav.error = error;
            checkComplete();
        }
    );
    
    // Test API
    apiModule.testConnection(
        config.apiUrl,
        config.apiToken,
        function(success, error) {
            results.api.success = success;
            results.api.error = error;
            checkComplete();
        }
    );
}

/**
 * Get sync statistics for a layer
 * @param {object} layer - Vector layer
 * @param {string} photoField - Photo field name
 * @returns {object} - Statistics object
 */
function getSyncStatistics(layer, photoField) {
    if (!layer) {
        return {
            total: 0,
            pending: 0,
            synced: 0
        };
    }
    
    var stats = {
        total: 0,
        pending: 0,
        synced: 0
    };
    
    var features = layer.getFeatures();
    
    for (var i = 0; i < features.length; i++) {
        var feature = features[i];
        var photoPath = feature.attribute(photoField);
        
        if (photoPath) {
            stats.total++;
            if (isLocalPath(photoPath)) {
                stats.pending++;
            } else {
                stats.synced++;
            }
        }
    }
    
    return stats;
}
