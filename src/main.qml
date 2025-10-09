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

Item {
    id: plugin
    // Make plugin visible in QField
    visible: true
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    
    // Plugin metadata
    property string pluginName: "QField Render Sync"
    property string pluginVersion: "1.0.0"
    
    // Project reference
    property var qfProject: iface ? iface.project : null
    
    // Configuration loaded from API
    property var config: ({})
    property bool configValid: false
    property var configErrors: []
    property string userToken: ""
    property bool tokenConfigured: false
    
    // UI state
    property bool syncInProgress: false
    property bool loadingConfig: false
    
    /**
     * Initialize plugin on load
     */
    Component.onCompleted: {
        console.log("[Render Sync] Plugin loading...")
        
        // Show visible startup message
        displayToast("Render Sync v" + pluginVersion + " loading...")
        
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
     * Load saved token (session-based for now)
     */
    function loadSavedToken() {
        // For now, token is only stored in memory during session
        // User will need to re-enter token each time they restart QField
        userToken = ""
        tokenConfigured = false
        console.log("[Render Sync] No persistent storage - token required each session")
    }
    
    /**
     * Save token (in memory for current session)
     */
    function saveToken(token) {
        console.log("[Render Sync] Saving token for current session: " + token.substring(0, Math.min(8, token.length)) + "...")
        userToken = token
        tokenConfigured = true
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
        
        // Get API base URL from project or use default
        var apiBaseUrl = qfProject ? 
                        (qfProject.customVariable("render_api_base_url") || "https://qfield-photo-sync-api.onrender.com") :
                        "https://qfield-photo-sync-api.onrender.com"
        
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
                            console.log("[Render Sync] ✓ Configuration loaded successfully from API")
                            displayToast("✓ Configuration loaded", "success")
                        } else {
                            console.log("[Render Sync] ✗ Configuration incomplete: " + configErrors.join(", "))
                            displayToast("Configuration incomplete: " + configErrors.join(", "), "warning")
                        }
                    } catch (e) {
                        console.log("[Render Sync] ✗ Error parsing API response: " + e)
                        displayToast("Error parsing API response", "error")
                        configValid = false
                    }
                } else if (xhr.status === 401 || xhr.status === 403) {
                    console.log("[Render Sync] ✗ Invalid token (status " + xhr.status + ")")
                    displayToast("Invalid token. Please check and try again.", "error")
                    configValid = false
                    // Don't clear token automatically - let user try again
                } else if (xhr.status === 0) {
                    console.log("[Render Sync] ✗ Network error or CORS issue")
                    displayToast("Cannot connect to API. Check network or API endpoint.", "error")
                    configValid = false
                } else {
                    console.log("[Render Sync] ✗ API error: " + xhr.status + " - " + xhr.responseText)
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
        if (iface && iface.mainWindow()) {
            iface.mainWindow().displayToast(message)
        } else {
            console.log("[Render Sync] Toast: " + message)
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
        source: "components/SyncDialog_Simple.qml"  // Using simplified dialog
        
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
     * Get all vector layers
     */
    function getVectorLayers() {
        console.log("[Render Sync] getVectorLayers called")
        
        if (!qfProject) {
            console.log("[Render Sync] No project loaded")
            return []
        }
        
        var layers = []
        var mapLayers = qfProject.mapLayers()
        console.log("[Render Sync] Project has", Object.keys(mapLayers).length, "map layers")
        
        for (var layerId in mapLayers) {
            var layer = mapLayers[layerId]
            console.log("[Render Sync] Checking layer:", layer ? layer.name() : "null", "type:", layer ? layer.type() : "null")
            if (layer && layer.type() === QgsMapLayer.VectorLayer) {
                console.log("[Render Sync] Adding vector layer:", layer.name())
                layers.push(layer)
            }
        }
        
        console.log("[Render Sync] Returning", layers.length, "vector layers")
        return layers
    }
}
