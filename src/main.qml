/**
 * QField Render Sync Plugin
 * ==========================
 * 
 * Main entry point for the plugin.
 * Loads configuration from project variables and initializes the sync interface.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.qfield 1.0
import org.qgis 1.0
import Theme 1.0

import "js/utils.js" as Utils
import "js/webdav_client.js" as WebDAV
import "js/api_client.js" as API
import "js/sync_engine.js" as SyncEngine
import "js/logger.js" as Logger

Item {
    id: plugin
    // Make plugin visible in QField
    visible: true
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    
    // Plugin metadata
    property string pluginName: "QField Render Sync"
    property string pluginVersion: "3.0.1"
    
    // QField-specific references (correct way to access QField objects)
    property var mainWindow: iface ? iface.mainWindow() : null
    property var dashBoard: iface ? iface.findItemByObjectName('dashBoard') : null
    property var mapCanvas: iface ? iface.findItemByObjectName('mapCanvas') : null
    
    // Configuration loaded from API
    property var config: ({})
    property bool configValid: false
    property var configErrors: []
    property string userToken: ""
    property bool tokenConfigured: false
    
    // UI state
    property bool syncInProgress: false
    property bool loadingConfig: false
    
    // Logging configuration
    property string logFilePath: ""
    property bool loggingEnabled: false
    
    Component.onCompleted: {
        console.log("=== QFIELD RENDER SYNC PLUGIN LOADING ===")
        console.log("Plugin version:", pluginVersion)
        console.log("Timestamp: " + new Date().toISOString())
        console.log("Testing basic console logging...")
        
        // Initialize file logging
        initializeLogging()
        
        console.log("Plugin initialization completed")
        
        // Show visible startup message
        displayToast("Render Sync v" + pluginVersion + " loading...")
        
        console.log("Proceeding with project setup...")
        
        // Check if qgisProject is available (QField's global project object)
        if (typeof qgisProject !== 'undefined' && qgisProject) {
            console.log("[Render Sync] ✓ qgisProject is available")
            displayToast("✓ Project ready")
        } else {
            console.log("[Render Sync] ⚠️ qgisProject not available at startup")
            displayToast("⚠️ Project not ready", "warning")
        }
        
        // Add button to QField toolbar
        if (iface && iface.addItemToPluginsToolbar) {
            iface.addItemToPluginsToolbar(syncButton)
            console.log("[Render Sync] Button added to plugins toolbar")
            displayToast("Render Sync: Button added to toolbar")
        } else {
            console.log("[Render Sync] ERROR: Could not add button to toolbar")
            displayToast("ERROR: Could not add toolbar button")
        }
        
        // Load saved token from settings
        loadSavedToken()
        
        if (userToken && userToken !== "") {
            // Fetch configuration from API
            fetchConfigurationFromAPI()
        } else {
            console.log("[Render Sync] No token configured")
            displayToast("Render Sync: Please configure your token", "warning")
        }
        
        console.log("[Render Sync] Plugin loaded v" + pluginVersion)
        displayToast("Render Sync v" + pluginVersion + " loaded successfully!")
    }
    
    /**
     * Initialize file logging
     */
    function initializeLogging() {
        try {
            // Set up file writer function
            Logger.setFileWriter(function(filePath, text, append) {
                fileWriter.writeToFile(filePath, text, append)
            })
            
            // Use a simple default log path (console output only in QField)
            // For QField Desktop, users can redirect console output to a file
            logFilePath = "qfield_render_sync_debug.log"
            
            // Use default log path (customVariable not available in QField)
            // logFilePath already set above
            
            // Initialize logger
            Logger.init(logFilePath)
            loggingEnabled = true
            
            Logger.info("=== QField Render Sync Plugin Started ===")
            Logger.info("Plugin version: " + pluginVersion)
            Logger.info("Log file: Console output with [FILE_LOG] tags")
            
            console.log("[Render Sync] File logging initialized (console mode)")
            
        } catch (e) {
            console.log("[Render Sync] Failed to initialize logging: " + e.toString())
            loggingEnabled = false
        }
    }
    
    /**
     * Load saved token (session-based for now)
     */
    function loadSavedToken() {
        // For now, token is only stored in memory during session
        // User will need to re-enter token each time they restart QField
        userToken = ""
        tokenConfigured = false
        Logger.info("No persistent storage - token required each session")
        console.log("[Render Sync] No persistent storage - token required each session")
    }
    
    /**
     * Save token (in memory for current session)
     */
    function saveToken(token) {
        Logger.info("Saving token for current session: " + token.substring(0, Math.min(8, token.length)) + "...")
        console.log("[Render Sync] Saving token for current session: " + token.substring(0, Math.min(8, token.length)) + "...")
        userToken = token
        tokenConfigured = true
        Logger.info("Token saved in memory")
        console.log("[Render Sync] Token saved in memory")
    }
    
    /**
     * Fetch configuration from API using token
     */
    function fetchConfigurationFromAPI() {
        if (!userToken || userToken === "") {
            console.log("[Render Sync] No token available")
            configValid = false
            return
        }
        
        loadingConfig = true
        console.log("[Render Sync] Fetching configuration from API...")
        
        // Get API base URL - use default (customVariable not available in QField)
        var apiBaseUrl = "https://qfield-photo-sync-api.onrender.com"
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiBaseUrl + "/api/config?token=" + userToken, true)
        xhr.setRequestHeader("Authorization", "Bearer " + userToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                loadingConfig = false
                
                console.log("[Render Sync] API Response Status: " + xhr.status)
                console.log("[Render Sync] API Response: " + xhr.responseText)
                
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        console.log("[Render Sync] Parsed response:", JSON.stringify(response))
                        
                        config = {
                            webdavUrl: response.webdav_url || response.DB_HOST || "",
                            webdavUsername: response.webdav_username || response.DB_USER || "",
                            webdavPassword: response.webdav_password || response.DB_PASSWORD || "",
                            apiUrl: apiBaseUrl,
                            apiToken: userToken,
                            dbTable: response.db_table || response.ALLOWED_SCHEMA || "design.verify_poles",
                            photoField: response.photo_field || "photo",
                            dbPoolSize: response.DB_POOL_SIZE || 10
                        }
                        
                        console.log("[Render Sync] Config set: webdavUrl=" + config.webdavUrl + ", dbTable=" + config.dbTable)
                        
                        validateConfiguration()
                        
                        if (configValid) {
                            console.log("[Render Sync] âœ“ Configuration loaded successfully from API")
                            displayToast("âœ“ Configuration loaded", "success")
                        } else {
                            console.log("[Render Sync] âœ— Configuration incomplete: " + configErrors.join(", "))
                            displayToast("Configuration incomplete: " + configErrors.join(", "), "warning")
                        }
                    } catch (e) {
                        console.log("[Render Sync] âœ— Error parsing API response: " + e)
                        displayToast("Error parsing API response", "error")
                        configValid = false
                    }
                } else if (xhr.status === 401 || xhr.status === 403) {
                    console.log("[Render Sync] âœ— Invalid token (status " + xhr.status + ")")
                    displayToast("Invalid token. Please check and try again.", "error")
                    configValid = false
                    // Don't clear token automatically - let user try again
                } else if (xhr.status === 0) {
                    console.log("[Render Sync] âœ— Network error or CORS issue")
                    displayToast("Cannot connect to API. Check network or API endpoint.", "error")
                    configValid = false
                } else {
                    console.log("[Render Sync] âœ— API error: " + xhr.status + " - " + xhr.responseText)
                    displayToast("API error: " + xhr.status, "error")
                    configValid = false
                }
            }
        }
        
        xhr.onerror = function() {
            loadingConfig = false
            console.log("[Render Sync] Network error fetching configuration")
            displayToast("Network error", "error")
            configValid = false
        }
        
        xhr.send()
    }
    
    /**
     * Validate configuration completeness
     */
    function validateConfiguration() {
        configErrors = []
        
        if (!config.webdavUrl || config.webdavUrl.trim() === "") {
            configErrors.push("WebDAV URL")
        }
        if (!config.webdavUsername || config.webdavUsername.trim() === "") {
            configErrors.push("WebDAV Username")
        }
        if (!config.webdavPassword || config.webdavPassword.trim() === "") {
            configErrors.push("WebDAV Password")
        }
        if (!config.apiUrl || config.apiUrl.trim() === "") {
            configErrors.push("API URL")
        }
        if (!config.apiToken || config.apiToken.trim() === "") {
            configErrors.push("API Token")
        }
        
        configValid = configErrors.length === 0
    }
    
    /**
     * Display toast notification
     */
    function displayToast(message, level) {
        // Log to console
        console.log("[Render Sync] " + message)
        
        // Show toast
        if (iface && iface.mainWindow()) {
            iface.mainWindow().displayToast(message)
        }
        
        // Also log to message bar (persistent)
        if (iface && iface.messageBar) {
            var messageLevel = 0 // Info
            if (level === "warning") messageLevel = 1
            if (level === "error") messageLevel = 2
            if (level === "success") messageLevel = 3
            
            iface.messageBar().pushMessage("Render Sync", message, messageLevel, 0) // 0 = no timeout
        }
    }
    
    /**
     * Open sync dialog or token configuration
     */
    function openSyncDialog() {
        console.log("[Render Sync] ========== OPEN SYNC DIALOG ==========")
        console.log("[Render Sync] tokenConfigured:", tokenConfigured)
        console.log("[Render Sync] configValid:", configValid)
        console.log("[Render Sync] syncInProgress:", syncInProgress)
        
        try {
            // Validate prerequisites
            if (!tokenConfigured || userToken === "") {
                console.log("[Render Sync] No token configured")
                displayToast("Please enter your API token first", "warning")
                openTokenDialog()
                return
            }
            
            if (!configValid) {
                console.log("[Render Sync] Configuration invalid")
                console.log("[Render Sync] Config errors:", configErrors.join(", "))
                displayToast("Configuration incomplete: " + configErrors.join(", "), "error")
                openTokenDialog()
                return
            }
            
            if (syncInProgress) {
                console.log("[Render Sync] Sync already in progress")
                displayToast("Sync already in progress", "warning")
                return
            }
            
            // Validate iface
            if (!iface || !iface.mainWindow()) {
                console.log("[Render Sync] ERROR: iface or mainWindow not available")
                displayToast("QField interface not ready", "error")
                return
            }
            
            console.log("[Render Sync] Loading sync dialog...")
            console.log("[Render Sync] Loader status before activation:", syncDialogLoader.status)
            
            // Activate loader
            syncDialogLoader.active = true
            
            // Wait for loading
            var maxAttempts = 10
            var attempt = 0
            
            function tryOpen() {
                attempt++
                console.log("[Render Sync] Attempt", attempt, "- Loader status:", syncDialogLoader.status)
                
                if (syncDialogLoader.status === Loader.Ready) {
                    if (syncDialogLoader.item) {
                        console.log("[Render Sync] Dialog loaded successfully, opening...")
                        displayToast("Opening sync dialog...")
                        try {
                            syncDialogLoader.item.open()
                            console.log("[Render Sync] Dialog opened")
                        } catch (e) {
                            console.log("[Render Sync] ERROR opening dialog:", e)
                            displayToast("ERROR: Cannot open dialog - " + e.toString(), "error")
                        }
                    } else {
                        console.log("[Render Sync] ERROR: Loader ready but item is null")
                        displayToast("ERROR: Dialog item is null", "error")
                    }
                } else if (syncDialogLoader.status === Loader.Error) {
                    console.log("[Render Sync] ERROR: Loader failed with error status")
                    displayToast("ERROR: Dialog failed to load - QML syntax error", "error")
                } else if (attempt < maxAttempts) {
                    // Try again
                    if (attempt === 1) {
                        displayToast("Loading dialog (attempt " + attempt + ")...")
                    }
                    Qt.callLater(tryOpen)
                } else {
                    console.log("[Render Sync] ERROR: Timeout waiting for dialog to load")
                    displayToast("ERROR: Dialog loading timeout after " + maxAttempts + " attempts", "error")
                }
            }
            
            tryOpen()
            
        } catch (e) {
            console.log("[Render Sync] EXCEPTION in openSyncDialog:", e)
            console.log("[Render Sync] Stack:", e.stack)
            displayToast("Error: " + e, "error")
        }
    }
    
    /**
     * Open token configuration dialog
     */
    function openTokenDialog() {
        if (tokenDialogLoader.status !== Loader.Ready) {
            tokenDialogLoader.active = true
        }
        
        if (tokenDialogLoader.item) {
            tokenDialogLoader.item.open()
        }
    }
    
    /**
     * Test connections
     */
    function testConnections(callback) {
        if (!configValid) {
            callback({
                webdav: { success: false, error: "Configuration incomplete" },
                api: { success: false, error: "Configuration incomplete" }
            })
            return
        }
        
        // Use SyncEngine's testConnections function
        SyncEngine.testConnections(config, WebDAV, API, callback)
    }
    
    /**
     * Sync photos (called from dialog)
     */
    function syncPhotos(pendingPhotos, layer, onPhotoProgress, onPhotoComplete, onAllComplete) {
        console.log("[Render Sync] Starting sync of " + pendingPhotos.length + " photos")
        
        // Call SyncEngine with module references
        SyncEngine.syncAllPhotos(
            pendingPhotos,
            config,
            layer,
            WebDAV,
            API,
            onPhotoProgress,
            onPhotoComplete,
            onAllComplete
        )
    }
    
    // Toolbar Button
    Button {
        id: syncButton
        text: qsTr("Sync Photos")
        enabled: !plugin.syncInProgress
        visible: true
        
        icon.source: Qt.resolvedUrl("icon.svg")
        
        display: AbstractButton.TextBesideIcon
        
        onClicked: {
            console.log("[Render Sync] Button clicked, tokenConfigured=" + plugin.tokenConfigured + ", configValid=" + plugin.configValid)
            plugin.openSyncDialog()
        }
        
        ToolTip.visible: hovered
        ToolTip.text: plugin.tokenConfigured ? 
                     (plugin.configValid ? qsTr("Sync photos to Render") : qsTr("Click to reconfigure token")) :
                     qsTr("Click to enter your API token")
    }
    
    // Token Dialog Loader
    Loader {
        id: tokenDialogLoader
        active: false
        asynchronous: true
        source: "components/TokenDialog.qml"
        
        onLoaded: {
            if (item) {
                item.plugin = plugin
                item.parent = iface.mainWindow().contentItem
            }
        }
    }
    
    // Sync Dialog Loader
    Loader {
        id: syncDialogLoader
        active: false
        asynchronous: false  // Changed to synchronous for better error messages
        source: "components/SyncDialog.qml"
        
        onLoaded: {
            console.log("[Render Sync] Loader onLoaded triggered")
            try {
                if (item) {
                    console.log("[Render Sync] Setting dialog properties...")
                    item.plugin = plugin
                    item.config = plugin.config
                    
                    if (iface && iface.mainWindow() && iface.mainWindow().contentItem) {
                        item.parent = iface.mainWindow().contentItem
                        console.log("[Render Sync] Dialog parent set successfully")
                    } else {
                        console.log("[Render Sync] WARNING: Could not set parent - iface not ready")
                    }
                    
                    console.log("[Render Sync] Sync dialog loaded successfully")
                } else {
                    console.log("[Render Sync] ERROR: onLoaded but item is null")
                }
            } catch (e) {
                console.log("[Render Sync] EXCEPTION in onLoaded:", e)
                console.log("[Render Sync] Stack:", e.stack)
            }
        }
        
        onStatusChanged: {
            console.log("[Render Sync] Loader status changed to:", status)
            if (status === Loader.Null) {
                console.log("[Render Sync] Status: Null - no source set")
            } else if (status === Loader.Ready) {
                console.log("[Render Sync] Status: Ready - component loaded")
            } else if (status === Loader.Loading) {
                console.log("[Render Sync] Status: Loading...")
            } else if (status === Loader.Error) {
                console.log("[Render Sync] Status: ERROR - Failed to load component")
                console.log("[Render Sync] Source:", source)
                if (sourceComponent) {
                    console.log("[Render Sync] Source component:", sourceComponent)
                    console.log("[Render Sync] Component status:", sourceComponent.status)
                    if (sourceComponent.errorString) {
                        console.log("[Render Sync] Error string:", sourceComponent.errorString())
                    }
                }
            }
        }
    }
    
    // Keyboard shortcut (Ctrl+Shift+S)
    Shortcut {
        sequence: "Ctrl+Shift+S"
        enabled: plugin.configValid && !plugin.syncInProgress
        onActivated: {
            plugin.openSyncDialog()
        }
    }
    
    /**
     * Get active layer
     */
    function getActiveLayer() {
        if (!iface || !iface.activeLayer()) {
            return null
        }
        return iface.activeLayer()
    }
    

    /**
     * Get all vector layers - Using correct QField API
     * Based on QField documentation at docs.qfield.org
     */
    function getVectorLayersV2() {
        console.log("[Render Sync] ========== GET VECTOR LAYERS (QField API) ==========")
        console.log("[Render Sync] Plugin version:", pluginVersion)
        displayToast("Detecting layers...")
        
        var layers = []
        
        try {
            // Use qgisProject - the global project object in QField
            if (typeof qgisProject === 'undefined' || !qgisProject) {
                console.log("[Render Sync] ERROR: qgisProject is not available")
                displayToast("ERROR: qgisProject not available", "error")
                return []
            }
            
            console.log("[Render Sync] qgisProject is available")
            displayToast("qgisProject available")
            
            // Get mapLayers - this is a QMap<QString, QgsMapLayer*> in QField
            var mapLayers = qgisProject.mapLayers()
            console.log("[Render Sync] mapLayers type:", typeof mapLayers)
            console.log("[Render Sync] mapLayers:", mapLayers)
            
            if (!mapLayers) {
                console.log("[Render Sync] ERROR: mapLayers() returned null")
                displayToast("ERROR: mapLayers null", "error")
                return []
            }
            
            displayToast("Got mapLayers")
            
            // Iterate through the map
            // In QML, QMap is exposed as a JS object with keys
            for (var layerId in mapLayers) {
                var layer = mapLayers[layerId]
                console.log("[Render Sync] Checking layer:", layerId, "Type:", typeof layer)
                
                if (layer) {
                    console.log("[Render Sync] Layer name:", layer.name)
                    console.log("[Render Sync] Layer type:", layer.type)
                    
                    // type === 0 means Vector layer in QGIS
                    if (layer.type === 0) {
                        layers.push(layer)
                        console.log("[Render Sync] ✓ Added vector layer:", layer.name)
                        displayToast("Found: " + layer.name)
                    } else {
                        console.log("[Render Sync] ✗ Skipping non-vector layer:", layer.name, "(type:", layer.type, ")")
                    }
                }
            }
            
            // Report results
            if (layers.length > 0) {
                var layerNames = []
                for (var j = 0; j < layers.length; j++) {
                    layerNames.push(layers[j].name || "Unknown")
                }
                console.log("[Render Sync] ✅ SUCCESS - Found", layers.length, "vector layers:", layerNames.join(", "))
                displayToast("SUCCESS: " + layers.length + " layer(s)!", "success")
            } else {
                console.log("[Render Sync] ⚠️ No vector layers found")
                displayToast("No vector layers found", "warning")
            }
            
        } catch (e) {
            console.log("[Render Sync] EXCEPTION:", e)
            console.log("[Render Sync] Stack:", e.stack)
            displayToast("ERROR: " + e.toString(), "error")
        }
        
        return layers
    }

    /**
     * Get all vector layers with debug information
     */
    function getVectorLayersWithDebug() {
        var debugInfo = ""
        var layers = []
        
        debugInfo += "=== GET VECTOR LAYERS ===\n"
        
        try {
            if (typeof qgisProject === 'undefined' || !qgisProject) {
                debugInfo += "ERROR: qgisProject is " + (typeof qgisProject === 'undefined' ? "undefined" : "null") + "\n"
                return { layers: [], debugInfo: debugInfo }
            }
            
            debugInfo += "âœ“ qgisProject exists\n"
            
            // Get all properties
            debugInfo += "\n=== qgisProject Properties ===\n"
            var props = []
            var layerProps = []
            
            for (var prop in qgisProject) {
                var propType = typeof qgisProject[prop]
                props.push(prop)
                
                var propLower = prop.toLowerCase()
                if (propLower.indexOf("layer") >= 0 || propLower.indexOf("map") >= 0) {
                    layerProps.push(prop + " (" + propType + ")")
                }
            }
            
            debugInfo += "Total properties: " + props.length + "\n"
            debugInfo += "\nLayer-related properties:\n"
            for (var i = 0; i < layerProps.length; i++) {
                debugInfo += "  " + layerProps[i] + "\n"
            }
            
            // Try mapLayersByName
            debugInfo += "\n=== Trying mapLayersByName() ===\n"
            if (typeof qgisProject.mapLayersByName === 'function') {
                debugInfo += "âœ“ mapLayersByName exists\n"
                // We need a layer name to test this
            } else {
                debugInfo += "âœ— mapLayersByName not available\n"
            }
            
            // Try layerTreeRoot
            debugInfo += "\n=== Trying layerTreeRoot() ===\n"
            if (typeof qgisProject.layerTreeRoot === 'function') {
                debugInfo += "âœ“ layerTreeRoot exists\n"
                try {
                    var root = qgisProject.layerTreeRoot()
                    if (root) {
                        debugInfo += "âœ“ Got layerTreeRoot\n"
                        
                        if (typeof root.children === 'function') {
                            var children = root.children()
                            debugInfo += "âœ“ layerTreeRoot has " + children.length + " children\n"
                            
                            for (var i = 0; i < children.length; i++) {
                                var child = children[i]
                                debugInfo += "  Child " + i + ": " + (child.name || "unknown") + "\n"
                                
                                if (child.layer && typeof child.layer === 'function') {
                                    var layer = child.layer()
                                    if (layer && layer.type === 0) {
                                        layers.push(layer)
                                        debugInfo += "    âœ“ Added vector layer: " + layer.name + "\n"
                                    }
                                }
                            }
                        }
                    }
                } catch (e) {
                    debugInfo += "âœ— layerTreeRoot error: " + e.toString() + "\n"
                }
            } else {
                debugInfo += "âœ— layerTreeRoot not available\n"
            }
            
            debugInfo += "\n=== RESULT ===\n"
            debugInfo += "Found " + layers.length + " vector layers\n"
            
        } catch (e) {
            debugInfo += "\nEXCEPTION: " + e.toString() + "\n"
            debugInfo += "Stack: " + e.stack + "\n"
        }
        
        return { layers: layers, debugInfo: debugInfo }
    }
    
    /**
     * Get all vector layers - QFIELD QGIS PROJECT APPROACH WITH TOAST DIAGNOSTICS
     */
    function getVectorLayers() {
        console.log("[Render Sync] ========== GET VECTOR LAYERS (QGIS PROJECT) ==========")
        
        var layers = []
        var diagnosticMessages = []
        
        try {
            // Check if qgisProject is available (QField's main project object)
            if (typeof qgisProject === 'undefined' || !qgisProject) {
                console.log("[Render Sync] qgisProject is undefined or null")
                displayToast("âŒ qgisProject is " + (typeof qgisProject === 'undefined' ? "undefined" : "null"))
                diagnosticMessages.push("qgisProject: " + (typeof qgisProject === 'undefined' ? "undefined" : "null"))
                return []
            }
            
            console.log("[Render Sync] âœ“ qgisProject exists")
            displayToast("âœ“ qgisProject exists")
            diagnosticMessages.push("qgisProject: exists")
            
            // Try multiple approaches to get layers
            var layerArray = []
            
            // Approach 1: Try mapLayers property
            try {
                var mapLayers = qgisProject.mapLayers
                console.log("[Render Sync] qgisProject.mapLayers:", typeof mapLayers, mapLayers)
                displayToast("mapLayers: " + (mapLayers === undefined ? "undefined" : mapLayers === null ? "null" : typeof mapLayers))
                
                if (mapLayers && mapLayers.length !== undefined) {
                    displayToast("âœ“ mapLayers has length: " + mapLayers.length)
                    layerArray = mapLayers
                } else if (mapLayers && typeof mapLayers.values === 'function') {
                    displayToast("âœ“ mapLayers has values()")
                    var values = mapLayers.values()
                    for (var i = 0; i < values.length; i++) {
                        layerArray.push(values[i])
                    }
                }
            } catch (e) {
                console.log("[Render Sync] mapLayers approach failed:", e)
                displayToast("mapLayers failed: " + e.toString())
            }
            
            // Approach 2: Try layerCount() and layerStore() methods
            if (layerArray.length === 0) {
                try {
                    displayToast("Trying layerCount()...")
                    var layerCount = qgisProject.layerCount()
                    console.log("[Render Sync] layerCount():", layerCount)
                    displayToast("layerCount: " + layerCount)
                    
                    if (layerCount > 0) {
                        // Try to get layers by index or other method
                        displayToast("Trying to get layers by index...")
                        for (var i = 0; i < layerCount; i++) {
                            try {
                                var layer = qgisProject.mapLayer(i)
                                if (layer) {
                                    layerArray.push(layer)
                                    displayToast("Got layer " + (i+1))
                                }
                            } catch (e2) {
                                console.log("[Render Sync] Error getting layer", i, ":", e2)
                            }
                        }
                    }
                } catch (e) {
                    console.log("[Render Sync] layerCount approach failed:", e)
                    displayToast("layerCount failed: " + e.toString())
                }
            }
            
            // Approach 3: Try mapLayersByName or other methods
            if (layerArray.length === 0) {
                displayToast("âŒ All approaches failed to get layers")
                console.log("[Render Sync] Cannot access layers from qgisProject")
                
                // Log all available properties/methods
                displayToast("Checking qgisProject properties...")
                var props = []
                var layerRelatedProps = []
                
                for (var prop in qgisProject) {
                    var propType = typeof qgisProject[prop]
                    props.push(prop + ":" + propType)
                    
                    // Look for layer-related properties
                    var propLower = prop.toLowerCase()
                    if (propLower.indexOf("layer") >= 0 || propLower.indexOf("map") >= 0) {
                        layerRelatedProps.push(prop + ":" + propType)
                    }
                }
                
                console.log("[Render Sync] qgisProject ALL properties:", props.join(", "))
                console.log("[Render Sync] Layer-related properties:", layerRelatedProps.join(", "))
                
                displayToast("qgisProject has " + props.length + " properties")
                
                // Show layer-related properties in toast messages
                if (layerRelatedProps.length > 0) {
                    displayToast("Layer-related properties found: " + layerRelatedProps.length)
                    for (var i = 0; i < Math.min(layerRelatedProps.length, 10); i++) {
                        displayToast("  " + layerRelatedProps[i])
                    }
                } else {
                    displayToast("No layer-related properties found!")
                }
                
                // Try some common QGIS methods
                displayToast("Trying common QGIS methods...")
                
                // Try mapLayersByName
                if (typeof qgisProject.mapLayersByName === 'function') {
                    displayToast("âœ“ Has mapLayersByName()")
                }
                
                // Try layerTreeRoot
                if (qgisProject.layerTreeRoot) {
                    displayToast("âœ“ Has layerTreeRoot")
                    try {
                        var root = qgisProject.layerTreeRoot()
                        if (root && typeof root.children === 'function') {
                            var children = root.children()
                            displayToast("layerTreeRoot has " + children.length + " children")
                        }
                    } catch (e) {
                        displayToast("layerTreeRoot error: " + e.toString())
                    }
                }
                
                return []
            }
            
            displayToast("Processing " + layerArray.length + " layers...")
            console.log("[Render Sync] Processing", layerArray.length, "layers")
            
            // Filter for vector layers
            for (var i = 0; i < layerArray.length; i++) {
                var layer = layerArray[i]
                console.log("[Render Sync] Processing layer", i, ":", typeof layer, layer)
                
                if (layer) {
                    var layerName = "Unknown"
                    var layerType = -1
                    
                    try {
                        layerName = layer.name || "Unknown"
                        console.log("[Render Sync] Layer name:", layerName)
                    } catch (e) {
                        console.log("[Render Sync] Error getting layer name:", e)
                    }
                    
                    try {
                        layerType = layer.type
                        console.log("[Render Sync] Layer type:", layerType, "typeof:", typeof layerType)
                    } catch (e) {
                        console.log("[Render Sync] Error getting layer type:", e)
                    }
                    
                    displayToast("Layer " + (i+1) + ": " + layerName + " (type:" + layerType + ")")
                    
                    try {
                        var toStringResult = layer.toString()
                        console.log("[Render Sync] Layer toString():", toStringResult)
                    } catch (e) {
                        console.log("[Render Sync] Error getting toString:", e)
                    }
                    
                    // Check if it's a vector layer
                    var isVector = false
                    if (layerType === 0) {
                        isVector = true
                        displayToast("âœ“ " + layerName + " is VECTOR (type=0)")
                        console.log("[Render Sync] âœ“ Vector layer by type:", layerName)
                    } else if (toStringResult && toStringResult.indexOf("QgsVectorLayer") >= 0) {
                        isVector = true
                        displayToast("âœ“ " + layerName + " is VECTOR (toString)")
                        console.log("[Render Sync] âœ“ Vector layer by toString:", layerName)
                    } else {
                        displayToast("âœ— " + layerName + " is NOT vector (type:" + layerType + ")")
                    }
                    
                    if (isVector) {
                        layers.push(layer)
                        console.log("[Render Sync] Added vector layer:", layerName)
                    } else {
                        console.log("[Render Sync] âœ— Skipping non-vector layer:", layerName, "type:", layerType)
                    }
                } else {
                    displayToast("Layer " + (i+1) + " is null/undefined")
                    console.log("[Render Sync] Layer", i, "is null/undefined")
                }
            }
            
            if (layers.length > 0) {
                var layerNames = []
                for (var j = 0; j < layers.length; j++) {
                    try {
                        layerNames.push(layers[j].name || "Unknown")
                    } catch (e) {
                        layerNames.push("Error getting name")
                    }
                }
                displayToast("âœ… SUCCESS! Found " + layers.length + " vector layer(s): " + layerNames.join(", "))
                console.log("[Render Sync] âœ“ SUCCESS - Found", layers.length, "vector layers:", layerNames.join(", "))
            } else {
                displayToast("âš ï¸ No vector layers found in " + layerArray.length + " total layers")
                console.log("[Render Sync] No vector layers found in project")
            }
            
        } catch (e) {
            displayToast("âŒ EXCEPTION: " + e.toString())
            console.log("[Render Sync] ERROR:", e)
            console.log("[Render Sync] Stack:", e.stack)
        }
        
        return layers
    }
    
    /**
     * Filter layers to return only vector layers
     */
    function filterVectorLayers(rawLayers) {
        var vectorLayers = []
        
        if (!rawLayers || rawLayers.length === 0) {
            return vectorLayers
        }
        
        for (var i = 0; i < rawLayers.length; i++) {
            var layer = rawLayers[i]
            if (layer && isVectorLayer(layer)) {
                vectorLayers.push(layer)
            }
        }
        
        return vectorLayers
    }
    
    /**
     * Check if a layer is a vector layer
     */
    function isVectorLayer(layer) {
        try {
            console.log("[Render Sync] Checking if layer is vector:", typeof layer, layer)
            
            // In QField QML, type is a property
            if (layer.type !== undefined) {
                console.log("[Render Sync] Layer has type property:", layer.type, "typeof:", typeof layer.type)
                return layer.type === 0  // QgsMapLayer.VectorLayer = 0
            } else {
                console.log("[Render Sync] Layer does not have type property")
            }
            
            // Fallback: check toString for "QgsVectorLayer"
            var layerString = layer.toString()
            console.log("[Render Sync] Layer toString():", layerString)
            var isVectorByString = layerString.indexOf("QgsVectorLayer") >= 0
            console.log("[Render Sync] Vector by string check:", isVectorByString)
            return isVectorByString
        } catch (e) {
            console.log("[Render Sync] Error checking layer type:", e)
            return false
        }
    }
    
    /**
     * Debug log all layers in a collection
     */
    function debugLogLayers(layerCollection, approachName) {
        console.log("[Render Sync] " + approachName + " - Detailed layer analysis:")
        
        if (!layerCollection || layerCollection.length === undefined) {
            console.log("[Render Sync] " + approachName + " - layerCollection is not array-like:", layerCollection)
            return
        }
        
        for (var i = 0; i < layerCollection.length; i++) {
            var layer = layerCollection[i]
            console.log("[Render Sync] " + approachName + " - Layer " + i + ":")
            debugLogSingleLayer(layer, approachName + " Layer " + i)
        }
    }
    
    /**
     * Debug log a single layer's properties
     */
    function debugLogSingleLayer(layer, context) {
        console.log("[Render Sync] " + context + " - Layer object:", typeof layer, layer)
        
        if (!layer) {
            console.log("[Render Sync] " + context + " - Layer is null/undefined")
            return
        }
        
        // Log all properties
        console.log("[Render Sync] " + context + " - All properties:")
        for (var prop in layer) {
            try {
                var value = layer[prop]
                console.log("[Render Sync]   " + prop + ":", typeof value, 
                          (typeof value === 'string' || typeof value === 'number') ? value : 
                          (value === null || value === undefined) ? value : "complex object")
            } catch (e) {
                console.log("[Render Sync]   " + prop + ": [ERROR ACCESSING]", e)
            }
        }
        
        // Check common properties
        try {
            console.log("[Render Sync] " + context + " - name:", layer.name)
        } catch (e) {
            console.log("[Render Sync] " + context + " - name: [ERROR]", e)
        }
        
        try {
            console.log("[Render Sync] " + context + " - type:", layer.type)
        } catch (e) {
            console.log("[Render Sync] " + context + " - type: [ERROR]", e)
        }
        
        try {
            console.log("[Render Sync] " + context + " - toString():", layer.toString())
        } catch (e) {
            console.log("[Render Sync] " + context + " - toString(): [ERROR]", e)
        }
        
        try {
            console.log("[Render Sync] " + context + " - isVectorLayer():", isVectorLayer(layer))
        } catch (e) {
            console.log("[Render Sync] " + context + " - isVectorLayer(): [ERROR]", e)
        }
    }
    
    // File Writer Component for Logging
    QtObject {
        id: fileWriter
        
        /**
         * Write text to a file
         * @param {string} filePath - Full path to file
         * @param {string} text - Text to write
         * @param {boolean} append - If true, append; if false, overwrite
         */
        function writeToFile(filePath, text, append) {
            try {
                // Use Qt's file I/O through XMLHttpRequest
                // Note: This is a workaround since QML doesn't have direct file I/O
                // In QField Desktop, we can use this approach
                
                var xhr = new XMLHttpRequest()
                
                // For local file writing, we need to use a different approach
                // Since XMLHttpRequest doesn't support writing to local files in most Qt environments,
                // we'll accumulate logs in memory and provide a way to export them
                
                // Store in console for now - QField Desktop will capture console output
                console.log("[FILE_LOG] " + text.trim())
                
                // Alternative: Try to use Qt.labs.platform FileDialog to save
                // But this requires user interaction, so we'll just log to console
                // Users can redirect console output to a file when running QField Desktop
                
            } catch (e) {
                console.log("[FileWriter] Error writing to file: " + e.toString())
            }
        }
    }
    
}
