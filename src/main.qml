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
        
        // Add button to QField toolbar
        if (iface && iface.addItemToPluginsToolbar) {
            iface.addItemToPluginsToolbar(syncButton)
            console.log("[Render Sync] Button added to plugins toolbar")
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
        console.log("[Render Sync] openSyncDialog called - tokenConfigured=" + tokenConfigured + ", configValid=" + configValid)
        
        if (!tokenConfigured || userToken === "") {
            console.log("[Render Sync] Opening token dialog - no token")
            openTokenDialog()
            return
        }
        
        if (!configValid) {
            console.log("[Render Sync] Opening token dialog - config invalid")
            displayToast("Configuration incomplete. Please check your token.", "error")
            openTokenDialog()
            return
        }
        
        if (syncInProgress) {
            console.log("[Render Sync] Sync already in progress")
            displayToast("Sync already in progress", "warning")
            return
        }
        
        console.log("[Render Sync] Opening sync dialog...")
        
        // Load sync dialog
        syncDialogLoader.active = true
        
        // Wait for loader to be ready
        if (syncDialogLoader.status === Loader.Ready && syncDialogLoader.item) {
            console.log("[Render Sync] Sync dialog ready, opening...")
            syncDialogLoader.item.open()
        } else {
            console.log("[Render Sync] Sync dialog not ready yet, status=" + syncDialogLoader.status)
            // Try again after a short delay
            Qt.callLater(function() {
                if (syncDialogLoader.item) {
                    console.log("[Render Sync] Sync dialog ready after delay, opening...")
                    syncDialogLoader.item.open()
                } else {
                    console.log("[Render Sync] ERROR: Sync dialog failed to load")
                    displayToast("Error loading sync dialog", "error")
                }
            })
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
        
        var results = {
            webdav: { success: false, error: null },
            api: { success: false, error: null }
        }
        
        var completed = 0
        
        function checkComplete() {
            completed++
            if (completed === 2) {
                callback(results)
            }
        }
        
        // Test WebDAV
        WebDAV.testConnection(
            config.webdavUrl,
            config.webdavUsername,
            config.webdavPassword,
            function(success, error) {
                results.webdav.success = success
                results.webdav.error = error
                checkComplete()
            }
        )
        
        // Test API
        API.testConnection(
            config.apiUrl,
            config.apiToken,
            function(success, error) {
                results.api.success = success
                results.api.error = error
                checkComplete()
            }
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
        asynchronous: true
        source: "components/SyncDialog.qml"
        
        onLoaded: {
            if (item) {
                item.plugin = plugin
                item.config = plugin.config
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
        if (!qfProject) {
            return []
        }
        
        var layers = []
        var mapLayers = qfProject.mapLayers()
        
        for (var layerId in mapLayers) {
            var layer = mapLayers[layerId]
            if (layer && layer.type() === QgsMapLayer.VectorLayer) {
                layers.push(layer)
            }
        }
        
        return layers
    }
}
