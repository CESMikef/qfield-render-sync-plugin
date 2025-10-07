/**
 * QField Render Sync Plugin
 * ==========================
 * 
 * Main entry point for the plugin.
 * Loads configuration from project variables and initializes the sync interface.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import org.qfield 1.0
import org.qgis 1.0

import "js/utils.js" as Utils
import "js/webdav_client.js" as WebDAV
import "js/api_client.js" as API
import "js/sync_engine.js" as SyncEngine

Item {
    id: plugin
    
    // Plugin metadata
    property string pluginName: "QField Render Sync"
    property string pluginVersion: "1.0.0"
    
    // Project reference
    property var qfProject: iface ? iface.project() : null
    
    // Configuration loaded from project variables
    property var config: ({})
    property bool configValid: false
    property var configErrors: []
    
    // UI state
    property bool syncInProgress: false
    
    /**
     * Initialize plugin on load
     */
    Component.onCompleted: {
        console.log("[Render Sync] Plugin loading...")
        
        // Load configuration from project variables
        loadConfiguration()
        
        // Validate configuration
        validateConfiguration()
        
        if (configValid) {
            console.log("[Render Sync] Configuration loaded successfully")
            displayToast("Render Sync plugin loaded", "success")
        } else {
            console.log("[Render Sync] Configuration incomplete: " + configErrors.join(", "))
            displayToast("Render Sync: Configuration incomplete", "warning")
        }
        
        console.log("[Render Sync] Plugin loaded v" + pluginVersion)
    }
    
    /**
     * Load configuration from project variables
     */
    function loadConfiguration() {
        if (!qfProject) {
            console.log("[Render Sync] No project available")
            return
        }
        
        config = {
            webdavUrl: qfProject.readEntry("render_sync", "webdav_url", "") || 
                       qfProject.customVariable("render_webdav_url") || "",
            webdavUsername: qfProject.readEntry("render_sync", "webdav_username", "") ||
                           qfProject.customVariable("render_webdav_username") || "",
            webdavPassword: qfProject.readEntry("render_sync", "webdav_password", "") ||
                           qfProject.customVariable("render_webdav_password") || "",
            apiUrl: qfProject.readEntry("render_sync", "api_url", "") ||
                   qfProject.customVariable("render_api_url") || "",
            apiToken: qfProject.readEntry("render_sync", "api_token", "") ||
                     qfProject.customVariable("render_api_token") || "",
            dbTable: qfProject.readEntry("render_sync", "db_table", "design.verify_poles") ||
                    qfProject.customVariable("render_db_table") || "design.verify_poles",
            photoField: qfProject.readEntry("render_sync", "photo_field", "photo") ||
                       qfProject.customVariable("render_photo_field") || "photo"
        }
        
        console.log("[Render Sync] Configuration loaded:")
        console.log("  WebDAV URL: " + (config.webdavUrl ? "✓" : "✗"))
        console.log("  WebDAV Username: " + (config.webdavUsername ? "✓" : "✗"))
        console.log("  API URL: " + (config.apiUrl ? "✓" : "✗"))
        console.log("  API Token: " + (config.apiToken ? "✓" : "✗"))
        console.log("  DB Table: " + config.dbTable)
        console.log("  Photo Field: " + config.photoField)
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
     * Open sync dialog
     */
    function openSyncDialog() {
        if (!configValid) {
            displayToast("Configuration incomplete. Missing: " + configErrors.join(", "), "error")
            return
        }
        
        if (syncInProgress) {
            displayToast("Sync already in progress", "warning")
            return
        }
        
        // Load sync dialog
        if (syncDialogLoader.status !== Loader.Ready) {
            syncDialogLoader.active = true
        }
        
        if (syncDialogLoader.item) {
            syncDialogLoader.item.open()
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
    
    // Main toolbar button
    Component.onCompleted: {
        // Create toolbar button
        var button = toolbarButtonComponent.createObject(plugin)
        
        // Add to QField toolbar (if available)
        if (iface && iface.mainWindow() && iface.mainWindow().addItemToPluginsToolbar) {
            iface.mainWindow().addItemToPluginsToolbar(button)
            console.log("[Render Sync] Toolbar button added")
        }
    }
    
    // Toolbar button component
    Component {
        id: toolbarButtonComponent
        
        Button {
            id: syncButton
            text: "Sync Photos"
            icon.source: Qt.resolvedUrl("icon.svg")
            enabled: plugin.configValid && !plugin.syncInProgress
            
            ToolTip.visible: hovered
            ToolTip.text: plugin.configValid ? 
                         "Sync photos to Render WebDAV and database" :
                         "Configuration incomplete: " + plugin.configErrors.join(", ")
            
            onClicked: {
                plugin.openSyncDialog()
            }
            
            // Visual feedback for sync in progress
            opacity: enabled ? 1.0 : 0.5
            
            // Styling
            background: Rectangle {
                color: syncButton.pressed ? "#45a049" : (syncButton.hovered ? "#4CAF50" : "#5cb85c")
                radius: 4
                border.color: "#4CAF50"
                border.width: 1
            }
            
            contentItem: Row {
                spacing: 8
                
                Image {
                    source: Qt.resolvedUrl("icon.svg")
                    width: 24
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: syncButton.text
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
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
