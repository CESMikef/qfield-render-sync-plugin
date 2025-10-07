/**
 * REST API Client
 * ================
 * 
 * Handles communication with the Render Sync API.
 * Manages photo URL updates in PostgreSQL database.
 */

// Note: Utils functions will be available from the importing QML context

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
 * Update single photo URL in database
 * @param {string} apiUrl - API base URL
 * @param {string} token - API authentication token
 * @param {string} globalId - Feature global ID
 * @param {string} photoUrl - Photo URL
 * @param {string} table - Database table
 * @param {string} field - Photo field name
 * @param {function} callback - Callback(success, data, error)
 */
function updatePhoto(apiUrl, token, globalId, photoUrl, table, field, callback) {
    var xhr = new XMLHttpRequest();
    
    var endpoint = apiUrl.replace(/\/$/, '') + '/api/v1/photos/update';
    
    var requestData = {
        global_id: globalId,
        photo_url: photoUrl,
        table: table,
        field: field
    };
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                // Success
                try {
                    var response = JSON.parse(xhr.responseText);
                    console.log('[API] Database updated for ' + globalId);
                    callback(true, response, null);
                } catch (e) {
                    callback(false, null, 'Failed to parse response: ' + e.toString());
                }
            } else if (xhr.status === 404) {
                // Feature not found
                callback(false, null, 'Feature not found in database');
            } else if (xhr.status === 401) {
                // Authentication failed
                callback(false, null, 'Authentication failed - check API token');
            } else {
                // Other error
                var error = parseErrorMessage(xhr);
                console.log('[API] ERROR: API error: ' + error);
                callback(false, null, error);
            }
        }
    };
    
    xhr.onerror = function() {
        var error = 'Network error - cannot reach API';
        console.log('[API] ERROR: ' + error);
        callback(false, null, error);
    };
    
    xhr.ontimeout = function() {
        var error = 'API request timeout';
        console.log('[API] ERROR: ' + error);
        callback(false, null, error);
    };
    
    xhr.open('POST', endpoint, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Authorization', 'Bearer ' + token);
    xhr.timeout = 30000; // 30 seconds
    
    try {
        xhr.send(JSON.stringify(requestData));
    } catch (e) {
        callback(false, null, 'Failed to send request: ' + e.toString());
    }
}

/**
 * Batch update multiple photos
 * @param {string} apiUrl - API base URL
 * @param {string} token - API authentication token
 * @param {array} updates - Array of update objects
 * @param {function} callback - Callback(success, data, error)
 */
function batchUpdatePhotos(apiUrl, token, updates, callback) {
    var xhr = new XMLHttpRequest();
    
    var endpoint = apiUrl.replace(/\/$/, '') + '/api/v1/photos/batch-update';
    
    var requestData = {
        updates: updates
    };
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    console.log('[API] Batch update complete: ' + response.updated + ' succeeded, ' + response.failed + ' failed');
                    callback(true, response, null);
                } catch (e) {
                    callback(false, null, 'Failed to parse response: ' + e.toString());
                }
            } else {
                var error = parseErrorMessage(xhr);
                console.log('[API] ERROR: Batch update error: ' + error);
                callback(false, null, error);
            }
        }
    };
    
    xhr.onerror = function() {
        callback(false, null, 'Network error - cannot reach API');
    };
    
    xhr.ontimeout = function() {
        callback(false, null, 'Batch update timeout');
    };
    
    xhr.open('POST', endpoint, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Authorization', 'Bearer ' + token);
    xhr.timeout = 60000; // 60 seconds for batch
    
    try {
        xhr.send(JSON.stringify(requestData));
    } catch (e) {
        callback(false, null, 'Failed to send batch request: ' + e.toString());
    }
}

/**
 * Get photo status from database
 * @param {string} apiUrl - API base URL
 * @param {string} token - API authentication token
 * @param {string} globalId - Feature global ID
 * @param {string} table - Database table
 * @param {function} callback - Callback(success, data, error)
 */
function getPhotoStatus(apiUrl, token, globalId, table, callback) {
    var xhr = new XMLHttpRequest();
    
    var endpoint = apiUrl.replace(/\/$/, '') + '/api/v1/photos/status/' + 
                   encodeURIComponent(globalId) + '?table=' + encodeURIComponent(table);
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    callback(true, response, null);
                } catch (e) {
                    callback(false, null, 'Failed to parse response: ' + e.toString());
                }
            } else if (xhr.status === 404) {
                callback(false, null, 'Feature not found');
            } else {
                var error = parseErrorMessage(xhr);
                callback(false, null, error);
            }
        }
    };
    
    xhr.onerror = function() {
        callback(false, null, 'Network error');
    };
    
    xhr.ontimeout = function() {
        callback(false, null, 'Request timeout');
    };
    
    xhr.open('GET', endpoint, true);
    xhr.setRequestHeader('Authorization', 'Bearer ' + token);
    xhr.timeout = 15000; // 15 seconds
    
    try {
        xhr.send();
    } catch (e) {
        callback(false, null, 'Failed to send request: ' + e.toString());
    }
}

/**
 * Test API connection and authentication
 * @param {string} apiUrl - API base URL
 * @param {string} token - API authentication token
 * @param {function} callback - Callback(success, error)
 */
function testConnection(apiUrl, token, callback) {
    var xhr = new XMLHttpRequest();
    
    var endpoint = apiUrl.replace(/\/$/, '') + '/health';
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.status === 'ok') {
                        callback(true, null);
                    } else {
                        callback(false, 'API health check failed');
                    }
                } catch (e) {
                    callback(false, 'Invalid API response');
                }
            } else {
                var error = parseErrorMessage(xhr);
                callback(false, error);
            }
        }
    };
    
    xhr.onerror = function() {
        callback(false, 'Network error - cannot reach API');
    };
    
    xhr.ontimeout = function() {
        callback(false, 'Connection timeout');
    };
    
    xhr.open('GET', endpoint, true);
    xhr.timeout = 10000; // 10 seconds
    
    try {
        xhr.send();
    } catch (e) {
        callback(false, 'Connection error: ' + e.toString());
    }
}

/**
 * Update photo with retry logic
 * @param {string} apiUrl - API base URL
 * @param {string} token - API authentication token
 * @param {string} globalId - Feature global ID
 * @param {string} photoUrl - Photo URL
 * @param {string} table - Database table
 * @param {string} field - Photo field name
 * @param {number} maxRetries - Maximum retry attempts
 * @param {function} callback - Callback(success, data, error)
 */
function updatePhotoWithRetry(apiUrl, token, globalId, photoUrl, table, field, maxRetries, callback) {
    var attempt = 0;
    
    function tryUpdate() {
        attempt++;
        
        updatePhoto(apiUrl, token, globalId, photoUrl, table, field, function(success, data, error) {
            if (success) {
                callback(true, data, null);
            } else if (attempt < maxRetries && error.indexOf('timeout') !== -1) {
                // Retry on timeout
                console.log('[API] WARN: Retry attempt ' + attempt + ' for ' + globalId);
                setTimeout(tryUpdate, 2000 * attempt); // Exponential backoff
            } else {
                callback(false, null, error);
            }
        });
    }
    
    tryUpdate();
}
