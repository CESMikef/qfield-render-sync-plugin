.pragma library

/**
 * File Logger for QField Desktop Debugging
 * =========================================
 * 
 * Provides file-based logging for debugging the plugin in QField Desktop.
 * Logs are written to a file on the local PC for easy review.
 * 
 * IMPORTANT: This logger requires a QML TextArea or other component to handle
 * file writing. See the integration instructions in main.qml.
 * 
 * Usage:
 *   import "js/logger.js" as Logger
 *   Logger.setFileWriter(fileWriterFunction)
 *   Logger.init("C:/Users/YourName/qfield_debug.log")
 *   Logger.log("INFO", "My message")
 *   Logger.info("Simple info message")
 *   Logger.error("Error message", errorObject)
 */

// Global state
var logFilePath = "";
var isInitialized = false;
var logBuffer = [];
var maxBufferSize = 500;
var fileWriter = null;
var logToConsole = true;

/**
 * Set the file writer function (must be called from QML context)
 * @param {function} writerFunc - Function that writes text to file
 */
function setFileWriter(writerFunc) {
    fileWriter = writerFunc;
    console.log("[Logger] File writer function registered");
}

/**
 * Initialize the logger with a file path
 * @param {string} filePath - Full path to log file (e.g., "C:/Users/YourName/qfield_debug.log")
 */
function init(filePath) {
    logFilePath = filePath || "";
    
    if (!logFilePath) {
        console.log("[Logger] No log file path provided - using console only");
        isInitialized = true;
        return;
    }
    
    try {
        // Create initial log header
        var header = "=".repeat(80) + "\n";
        header += "QField Render Sync Plugin - Debug Log\n";
        header += "Session started: " + new Date().toISOString() + "\n";
        header += "Log file: " + logFilePath + "\n";
        header += "=".repeat(80) + "\n\n";
        
        // Write header
        if (fileWriter) {
            fileWriter(logFilePath, header, false); // Overwrite mode
            console.log("[Logger] File logging initialized: " + logFilePath);
        } else {
            console.log("[Logger] WARNING: No file writer registered - logs will only go to console");
        }
        
        isInitialized = true;
        
        // Log initialization success
        log("INFO", "Logger initialized successfully", { filePath: logFilePath });
        
    } catch (e) {
        console.log("[Logger] ERROR: Failed to initialize file logging: " + e.toString());
        console.log("[Logger] Stack: " + (e.stack || "No stack trace"));
        isInitialized = true; // Still mark as initialized to use console
    }
}

/**
 * Write text to log file
 * @param {string} text - Text to write
 */
function writeToFile(text) {
    if (!fileWriter || !logFilePath) {
        return; // No file writer available
    }
    
    try {
        fileWriter(logFilePath, text, true); // Append mode
    } catch (e) {
        console.log("[Logger] File write failed: " + e.toString());
    }
}

/**
 * Format a log entry
 * @param {string} level - Log level (INFO, WARN, ERROR, DEBUG)
 * @param {string} message - Log message
 * @param {object} data - Optional data object
 * @returns {string} - Formatted log entry
 */
function formatLogEntry(level, message, data) {
    var timestamp = new Date().toISOString();
    var entry = "[" + timestamp + "] [" + level.padEnd(5) + "] " + message;
    
    if (data) {
        try {
            entry += "\n  Data: " + JSON.stringify(data, null, 2);
        } catch (e) {
            entry += "\n  Data: [Unable to stringify: " + e.toString() + "]";
        }
    }
    
    return entry + "\n";
}

/**
 * Main logging function
 * @param {string} level - Log level (INFO, WARN, ERROR, DEBUG)
 * @param {string} message - Log message
 * @param {object} data - Optional data object
 */
function log(level, message, data) {
    if (!isInitialized) {
        // Buffer logs until initialized
        logBuffer.push({ level: level, message: message, data: data });
        if (logBuffer.length > maxBufferSize) {
            logBuffer.shift(); // Remove oldest entry
        }
        console.log("[" + level + "] " + message);
        return;
    }
    
    // Flush buffer if this is first log after initialization
    if (logBuffer.length > 0) {
        var buffered = logBuffer.slice();
        logBuffer = [];
        for (var i = 0; i < buffered.length; i++) {
            log(buffered[i].level, buffered[i].message, buffered[i].data);
        }
    }
    
    var entry = formatLogEntry(level, message, data);
    
    // Always log to console
    console.log("[Render Sync] " + entry.trim());
    
    // Log to file
    if (logFilePath) {
        try {
            writeToFile(entry);
        } catch (e) {
            console.log("[Logger] Failed to write to file: " + e.toString());
        }
    }
}

/**
 * Log info message
 * @param {string} message - Log message
 * @param {object} data - Optional data object
 */
function info(message, data) {
    log("INFO", message, data);
}

/**
 * Log warning message
 * @param {string} message - Log message
 * @param {object} data - Optional data object
 */
function warn(message, data) {
    log("WARN", message, data);
}

/**
 * Log error message
 * @param {string} message - Log message
 * @param {object} data - Optional data object or error object
 */
function error(message, data) {
    // If data is an Error object, extract useful info
    if (data && typeof data === 'object') {
        if (data.message || data.stack) {
            var errorData = {
                message: data.message || data.toString(),
                stack: data.stack || "No stack trace",
                name: data.name || "Error"
            };
            log("ERROR", message, errorData);
            return;
        }
    }
    log("ERROR", message, data);
}

/**
 * Log debug message
 * @param {string} message - Log message
 * @param {object} data - Optional data object
 */
function debug(message, data) {
    log("DEBUG", message, data);
}

/**
 * Log a section separator
 * @param {string} title - Section title
 */
function section(title) {
    var separator = "=".repeat(80);
    log("INFO", "\n" + separator + "\n" + title + "\n" + separator);
}

/**
 * Log function entry
 * @param {string} functionName - Name of the function
 * @param {object} params - Function parameters
 */
function enter(functionName, params) {
    log("DEBUG", "→ ENTER: " + functionName, params);
}

/**
 * Log function exit
 * @param {string} functionName - Name of the function
 * @param {object} result - Return value or result
 */
function exit(functionName, result) {
    log("DEBUG", "← EXIT: " + functionName, result);
}

/**
 * Log HTTP request
 * @param {string} method - HTTP method
 * @param {string} url - Request URL
 * @param {object} data - Request data
 */
function httpRequest(method, url, data) {
    log("DEBUG", "HTTP " + method + " → " + url, data);
}

/**
 * Log HTTP response
 * @param {number} status - HTTP status code
 * @param {string} url - Request URL
 * @param {object} data - Response data
 */
function httpResponse(status, url, data) {
    var level = status >= 200 && status < 300 ? "DEBUG" : "WARN";
    log(level, "HTTP " + status + " ← " + url, data);
}

/**
 * Log sync progress
 * @param {number} current - Current item number
 * @param {number} total - Total items
 * @param {string} status - Status message
 */
function syncProgress(current, total, status) {
    var percent = Math.round((current / total) * 100);
    log("INFO", "Sync Progress: " + current + "/" + total + " (" + percent + "%) - " + status);
}

/**
 * Get current log file path
 * @returns {string} - Log file path
 */
function getLogFilePath() {
    return logFilePath;
}

/**
 * Check if logger is initialized
 * @returns {boolean} - True if initialized
 */
function isReady() {
    return isInitialized;
}

/**
 * Check if file writer is available
 * @returns {boolean} - True if file writer is set
 */
function hasFileWriter() {
    return fileWriter !== null;
}

/**
 * Flush any buffered logs
 */
function flush() {
    if (logBuffer.length > 0 && isInitialized) {
        var buffered = logBuffer.slice();
        logBuffer = [];
        for (var i = 0; i < buffered.length; i++) {
            log(buffered[i].level, buffered[i].message, buffered[i].data);
        }
    }
}

/**
 * String padding helper (for older JavaScript environments)
 */
if (!String.prototype.padEnd) {
    String.prototype.padEnd = function(targetLength, padString) {
        targetLength = targetLength >> 0;
        padString = String(padString || ' ');
        if (this.length > targetLength) {
            return String(this);
        }
        targetLength = targetLength - this.length;
        if (targetLength > padString.length) {
            padString += padString.repeat(targetLength / padString.length);
        }
        return String(this) + padString.slice(0, targetLength);
    };
}

/**
 * String repeat helper (for older JavaScript environments)
 */
if (!String.prototype.repeat) {
    String.prototype.repeat = function(count) {
        if (this == null) {
            throw new TypeError('can\'t convert ' + this + ' to object');
        }
        var str = '' + this;
        count = +count;
        if (count != count) {
            count = 0;
        }
        if (count < 0) {
            throw new RangeError('repeat count must be non-negative');
        }
        if (count == Infinity) {
            throw new RangeError('repeat count must be less than infinity');
        }
        count = Math.floor(count);
        if (str.length == 0 || count == 0) {
            return '';
        }
        var maxCount = str.length * count;
        count = Math.floor(Math.log(count) / Math.log(2));
        while (count) {
            str += str;
            count--;
        }
        str += str.substring(0, maxCount - str.length);
        return str;
    };
}
