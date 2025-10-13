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
 * Find features with pending photo uploads
 * @param {object} layer - Vector layer
 * @param {string} photoField - Photo field name
 * @returns {array} - Array of features with local photos
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
        var photoPath = feature.attribute(photoField);
        
        if (photoPath && isLocalPath(photoPath)) {
            pending.push({
                feature: feature,
                globalId: feature.attribute('global_id') || feature.attribute('globalid') || feature.id().toString(),
                localPath: photoPath
            });
        }
    }
    
    console.log('[Sync] Found ' + pending.length + ' photos pending upload');
    return pending;
}

/**
 * Sync single photo
 * @param {object} photoData - Photo data object
 * @param {object} config - Configuration object
 * @param {object} layer - Vector layer
 * @param {object} webdavModule - WebDAV module reference
 * @param {object} apiModule - API module reference
 * @param {function} onProgress - Progress callback(percent, status)
 * @param {function} onComplete - Completion callback(success, photoUrl, error)
 */
function syncPhoto(photoData, config, layer, webdavModule, apiModule, onProgress, onComplete) {
    var globalId = photoData.globalId;
    var localPath = photoData.localPath;
    
    // Don't use console.log with globalId - it causes exceptions in QML
    // console.log('[Sync] Syncing photo for feature: ' + globalId);
    if (onProgress) onProgress(0, 'Syncing feature...');
    
    // Step 1: Upload to WebDAV
    if (onProgress) onProgress(0, 'Uploading to WebDAV...');
    
    webdavModule.uploadPhotoWithCheck(
        localPath,
        globalId,
        config.webdavUrl,
        config.webdavUsername,
        config.webdavPassword,
        function(percent, status) {
            if (onProgress) onProgress(percent * 0.7, status); // 70% for upload
        },
        function(uploadSuccess, photoUrl, uploadError) {
            if (!uploadSuccess) {
                // console.log('[Sync] ERROR: Upload failed for ' + globalId + ': ' + uploadError);
                onComplete(false, null, uploadError);
                return;
            }
            
            // Step 2: Update database via API
            if (onProgress) onProgress(70, 'Updating database...');
            
            apiModule.updatePhotoWithRetry(
                config.apiUrl,
                config.apiToken,
                globalId,
                photoUrl,
                config.dbTable,
                config.photoField,
                3, // Max retries
                function(apiSuccess, apiData, apiError) {
                    if (!apiSuccess) {
                        // console.log('[Sync] ERROR: API update failed for ' + globalId + ': ' + apiError);
                        onComplete(false, photoUrl, apiError);
                        return;
                    }
                    
                    // Step 3: Update local layer
                    if (onProgress) onProgress(90, 'Updating local layer...');
                    
                    try {
                        layer.startEditing();
                        photoData.feature.setAttribute(config.photoField, photoUrl);
                        layer.commitChanges();
                        
                        if (onProgress) onProgress(100, 'Complete');
                        // console.log('[Sync] Successfully synced photo for ' + globalId);
                        onComplete(true, photoUrl, null);
                        
                    } catch (e) {
                        var error = 'Failed to update local layer: ' + e.toString();
                        console.log('[Sync] ERROR: ' + error);
                        onComplete(false, photoUrl, error);
                    }
                }
            );
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
    
    // Validate URLs
    if (config.webdavUrl && !validateUrl(config.webdavUrl)) {
        errors.push('Invalid WebDAV URL');
    }
    
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
