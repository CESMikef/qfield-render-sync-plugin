/**
 * Sync Dialog
 * ===========
 * 
 * Main interface for photo synchronization.
 * Allows layer selection, displays progress, and shows results.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.qfield 1.0
import org.qgis 1.0

import "../js/utils.js" as Utils
import "../js/webdav_client.js" as WebDAV
import "../js/api_client.js" as API
import "../js/sync_engine.js" as SyncEngine

Popup {
    id: syncDialog
    
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    width: parent ? Math.min(parent.width * 0.9, 600) : 600
    height: parent ? Math.min(parent.height * 0.8, 700) : 700
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    
    // Properties passed from main plugin
    property var plugin: null
    property var config: ({})
    
    // Internal state
    property var selectedLayer: null
    property var pendingPhotos: []
    property bool syncing: false
    property int currentPhotoIndex: 0
    property int totalPhotos: 0
    property int successCount: 0
    property int failureCount: 0
    property var errors: []
    
    // Header with title and close button
    header: Rectangle {
        width: parent.width
        height: 50
        color: "#4CAF50"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Label {
                text: "Sync Photos to Render"
                font.pixelSize: 18
                font.bold: true
                color: "white"
                Layout.fillWidth: true
            }
            
            Button {
                text: "×"
                font.pixelSize: 24
                flat: true
                onClicked: syncDialog.close()
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    
    // Reset state when dialog opens
    onOpened: {
        resetState()
        loadLayers()
        updatePendingCount()
    }
    
    /**
     * Reset dialog state
     */
    function resetState() {
        syncing = false
        currentPhotoIndex = 0
        totalPhotos = 0
        successCount = 0
        failureCount = 0
        errors = []
        pendingPhotos = []
    }
    
    /**
     * Load available vector layers
     */
    function loadLayers() {
        layerComboBox.model.clear()
        
        if (!plugin || !plugin.qfProject) {
            return
        }
        
        var layers = plugin.getVectorLayers()
        
        for (var i = 0; i < layers.length; i++) {
            var layer = layers[i]
            layerComboBox.model.append({
                text: layer.name(),
                layer: layer
            })
        }
        
        // Select active layer if available
        var activeLayer = plugin.getActiveLayer()
        if (activeLayer) {
            for (var j = 0; j < layerComboBox.model.count; j++) {
                if (layerComboBox.model.get(j).layer === activeLayer) {
                    layerComboBox.currentIndex = j
                    break
                }
            }
        }
    }
    
    /**
     * Update pending photo count
     */
    function updatePendingCount() {
        if (!selectedLayer) {
            pendingPhotos = []
            totalPhotos = 0
            return
        }
        
        pendingPhotos = SyncEngine.findPendingPhotos(selectedLayer, config.photoField)
        totalPhotos = pendingPhotos.length
    }
    
    /**
     * Start sync process
     */
    function startSync() {
        if (!selectedLayer || totalPhotos === 0) {
            return
        }
        
        // Validate prerequisites
        var validation = SyncEngine.validateSyncPrerequisites(config, selectedLayer)
        if (!validation.valid) {
            errorDialog.text = "Cannot start sync:\n\n" + validation.errors.join("\n")
            errorDialog.open()
            return
        }
        
        // Reset counters
        syncing = true
        currentPhotoIndex = 0
        successCount = 0
        failureCount = 0
        errors = []
        
        plugin.syncInProgress = true
        
        // Start sync
        SyncEngine.syncAllPhotos(
            pendingPhotos,
            config,
            selectedLayer,
            WebDAV,
            API,
            onPhotoProgress,
            onPhotoComplete,
            onAllComplete
        )
    }
    
    /**
     * Cancel sync
     */
    function cancelSync() {
        syncing = false
        plugin.syncInProgress = false
        resetState()
        updatePendingCount()
    }
    
    /**
     * Photo progress callback
     */
    function onPhotoProgress(photoIndex, total, percent, status) {
        currentPhotoIndex = photoIndex
        progressBar.value = percent / 100
        statusLabel.text = status
    }
    
    /**
     * Photo completion callback
     */
    function onPhotoComplete(photoIndex, success, error) {
        if (success) {
            successCount++
        } else {
            failureCount++
            if (error) {
                errors.push({
                    index: photoIndex,
                    globalId: pendingPhotos[photoIndex].globalId,
                    error: error
                })
            }
        }
    }
    
    /**
     * All photos completion callback
     */
    function onAllComplete(results) {
        syncing = false
        plugin.syncInProgress = false
        
        // Show results
        var message = "Sync Complete!\n\n"
        message += "Total: " + results.total + "\n"
        message += "Succeeded: " + results.succeeded + "\n"
        message += "Failed: " + results.failed
        
        if (results.failed > 0) {
            message += "\n\nErrors:\n"
            for (var i = 0; i < Math.min(results.errors.length, 5); i++) {
                message += "• " + results.errors[i].globalId + ": " + results.errors[i].error + "\n"
            }
            if (results.errors.length > 5) {
                message += "... and " + (results.errors.length - 5) + " more"
            }
        }
        
        resultDialog.text = message
        resultDialog.open()
        
        // Refresh pending count
        updatePendingCount()
    }
    
    // Main content
    contentItem: ColumnLayout {
        spacing: 16
        
        // Layer selection
        GroupBox {
            title: "Select Layer"
            Layout.fillWidth: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                
                ComboBox {
                    id: layerComboBox
                    Layout.fillWidth: true
                    enabled: !syncing
                    
                    model: ListModel {}
                    textRole: "text"
                    
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && model.count > 0) {
                            selectedLayer = model.get(currentIndex).layer
                            updatePendingCount()
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Photo field:"
                        font.pixelSize: 12
                    }
                    
                    Label {
                        text: config.photoField
                        font.pixelSize: 12
                        font.bold: true
                        color: "#4CAF50"
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Label {
                        text: "Pending: " + totalPhotos
                        font.pixelSize: 14
                        font.bold: true
                        color: totalPhotos > 0 ? "#FF9800" : "#4CAF50"
                    }
                }
            }
        }
        
        // Connection status
        GroupBox {
            title: "Connection Status"
            Layout.fillWidth: true
            visible: !syncing
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                
                Button {
                    id: testButton
                    text: "Test Connections"
                    Layout.fillWidth: true
                    enabled: !syncing
                    
                    onClicked: {
                        testButton.enabled = false
                        connectionStatus.text = "Testing..."
                        
                        plugin.testConnections(function(results) {
                            testButton.enabled = true
                            
                            var status = ""
                            status += "WebDAV: " + (results.webdav.success ? "✓ Connected" : "✗ " + results.webdav.error) + "\n"
                            status += "API: " + (results.api.success ? "✓ Connected" : "✗ " + results.api.error)
                            
                            connectionStatus.text = status
                        })
                    }
                }
                
                Label {
                    id: connectionStatus
                    text: "Click 'Test Connections' to verify"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
        
        // Progress section
        GroupBox {
            title: "Sync Progress"
            Layout.fillWidth: true
            visible: syncing
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                
                Label {
                    text: "Photo " + (currentPhotoIndex + 1) + " of " + totalPhotos
                    font.pixelSize: 14
                    font.bold: true
                }
                
                ProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: 0
                }
                
                Label {
                    id: statusLabel
                    text: "Initializing..."
                    font.pixelSize: 12
                    color: "#666"
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "✓ Success: " + successCount
                        color: "#4CAF50"
                        font.pixelSize: 12
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Label {
                        text: "✗ Failed: " + failureCount
                        color: "#f44336"
                        font.pixelSize: 12
                        visible: failureCount > 0
                    }
                }
            }
        }
        
        // Statistics
        GroupBox {
            title: "Statistics"
            Layout.fillWidth: true
            visible: !syncing && selectedLayer
            
            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 8
                columnSpacing: 16
                
                Label {
                    text: "Total features:"
                    font.pixelSize: 12
                }
                Label {
                    text: selectedLayer ? selectedLayer.featureCount() : "0"
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Label {
                    text: "Pending uploads:"
                    font.pixelSize: 12
                }
                Label {
                    text: totalPhotos.toString()
                    font.pixelSize: 12
                    font.bold: true
                    color: totalPhotos > 0 ? "#FF9800" : "#4CAF50"
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                text: syncing ? "Cancel" : "Start Sync"
                Layout.fillWidth: true
                enabled: !syncing ? (totalPhotos > 0) : true
                
                background: Rectangle {
                    color: parent.pressed ? (syncing ? "#c62828" : "#45a049") : 
                           (parent.hovered ? (syncing ? "#d32f2f" : "#4CAF50") : 
                           (syncing ? "#f44336" : "#5cb85c"))
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (syncing) {
                        cancelSync()
                    } else {
                        startSync()
                    }
                }
            }
            
            Button {
                text: "Close"
                enabled: !syncing
                
                onClicked: {
                    syncDialog.close()
                }
            }
        }
    }
    
    // Error dialog
    Popup {
        id: errorDialog
        property string text: ""
        
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        width: parent ? Math.min(parent.width * 0.8, 400) : 400
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        
        ColumnLayout {
            width: parent.width
            spacing: 16
            
            Label {
                text: "Sync Error"
                font.pixelSize: 18
                font.bold: true
                color: "#F44336"
                Layout.fillWidth: true
            }
            
            Label {
                text: errorDialog.text
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignRight
                onClicked: errorDialog.close()
            }
        }
    }
    
    // Result dialog
    Popup {
        id: resultDialog
        property string text: ""
        
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        width: parent ? Math.min(parent.width * 0.8, 400) : 400
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0
        
        ColumnLayout {
            width: parent.width
            spacing: 16
            
            Label {
                text: "Sync Results"
                font.pixelSize: 18
                font.bold: true
                color: "#4CAF50"
                Layout.fillWidth: true
            }
            
            Label {
                text: resultDialog.text
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignRight
                onClicked: resultDialog.close()
            }
        }
    }
}
