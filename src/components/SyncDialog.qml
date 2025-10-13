/**
 * Simplified Sync Dialog
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Popup {
    id: syncDialog
    
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    width: parent ? Math.min(parent.width * 0.95, 700) : 700
    height: parent ? Math.min(parent.height * 0.9, 800) : 800
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    
    property var plugin: null
    property var config: ({})
    property var selectedLayer: null
    property var pendingPhotos: []
    property bool syncing: false
    property int totalPhotos: 0
    property string debugLog: ""
    
    function addDebugLog(message) {
        var timestamp = new Date().toLocaleTimeString()
        debugLog += "[" + timestamp + "] " + message + "\n"
        console.log("[SyncDialog] " + message)
    }
    
    Component.onCompleted: {
        addDebugLog("Dialog loaded")
    }
    
    onOpened: {
        debugLog = "" // Clear previous logs
        addDebugLog("Dialog opened")
        addDebugLog("Loading layers...")
        loadLayers()
        updatePendingCount()
    }
    
    function loadLayers() {
        addDebugLog("Loading layers...")
        layerComboBox.model.clear()
        
        if (!plugin) {
            console.log("[SyncDialog] ERROR: No plugin reference")
            if (plugin && plugin.displayToast) {
                plugin.displayToast("ERROR: No plugin reference", "error")
            }
            return
        }
        
        try {
            addDebugLog("Calling plugin.getVectorLayersV2()...")
            
            // Also try to get layers directly here for debugging
            if (typeof qgisProject !== 'undefined' && qgisProject) {
                addDebugLog("qgisProject exists in dialog")
                
                // List ALL properties and methods on qgisProject
                addDebugLog("=== qgisProject properties ===")
                var props = []
                for (var prop in qgisProject) {
                    var propType = typeof qgisProject[prop]
                    props.push(prop + ":" + propType)
                    if (prop.toLowerCase().indexOf("layer") >= 0 || prop.toLowerCase().indexOf("map") >= 0) {
                        addDebugLog("  " + prop + " (" + propType + ")")
                    }
                }
                addDebugLog("Total properties: " + props.length)
                
                // Try different ways to access layers
                addDebugLog("=== Trying different methods ===")
                addDebugLog("layerTreeRoot: " + typeof qgisProject.layerTreeRoot)
                
                if (typeof qgisProject.layerTreeRoot === 'function') {
                    var root = qgisProject.layerTreeRoot()
                    addDebugLog("layerTreeRoot() returned: " + typeof root)
                    
                    if (root) {
                        addDebugLog("root.findLayers: " + typeof root.findLayers)
                        
                        if (typeof root.findLayers === 'function') {
                            var treeLayers = root.findLayers()
                            addDebugLog("findLayers() returned " + treeLayers.length + " layers")
                            
                            for (var i = 0; i < treeLayers.length; i++) {
                                var treeLayer = treeLayers[i]
                                addDebugLog("TreeLayer " + i + ": " + typeof treeLayer)
                                if (treeLayer && typeof treeLayer.layer === 'function') {
                                    var lyr = treeLayer.layer()
                                    if (lyr) {
                                        addDebugLog("  Layer: " + lyr.name + " (type: " + lyr.type + ")")
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                addDebugLog("qgisProject NOT available in dialog!")
            }
            
            var layers = plugin.getVectorLayersV2()
            addDebugLog("Got " + layers.length + " vector layers from plugin")
            
            if (layers.length === 0) {
                addDebugLog("WARNING: No vector layers found")
                layerComboBox.model.append({
                    text: "No layers found",
                    layer: null
                })
                return
            }
            
            for (var i = 0; i < layers.length; i++) {
                var layer = layers[i]
                var layerName = layer.name
                addDebugLog("Adding layer: " + layerName)
                layerComboBox.model.append({
                    text: layerName,
                    layer: layer
                })
            }
            
            addDebugLog("SUCCESS: Loaded " + layers.length + " layer(s)")
        } catch (e) {
            addDebugLog("ERROR: " + e.toString())
            addDebugLog("Stack: " + (e.stack || "No stack"))
        }
    }
    
    function updatePendingCount() {
        console.log("[SyncDialog] ========== UPDATE PENDING COUNT ==========")
        console.log("[SyncDialog] selectedLayer:", !!selectedLayer)
        
        if (!selectedLayer) {
            console.log("[SyncDialog] No layer selected")
            pendingPhotos = []
            totalPhotos = 0
            return
        }
        
        console.log("[SyncDialog] Layer name:", selectedLayer.name)
        console.log("[SyncDialog] Photo field:", config.photoField || "photo")
        
        pendingPhotos = []
        
        try {
            var features = selectedLayer.getFeatures()
            console.log("[SyncDialog] Got features, type:", typeof features)
            console.log("[SyncDialog] Features length/count:", features.length || "no length property")
            
            // Handle both array-like and iterator-like feature collections
            var featureCount = 0
            var photoFieldName = config.photoField || "photo"
            
            // Try array-style access first
            if (features.length !== undefined) {
                console.log("[SyncDialog] Processing", features.length, "features (array-style)")
                for (var i = 0; i < features.length; i++) {
                    featureCount++
                    var feature = features[i]
                    if (!feature) {
                        console.log("[SyncDialog] Feature", i, "is null, skipping")
                        continue
                    }
                    
                    var photoPath = feature.attribute(photoFieldName)
                    console.log("[SyncDialog] Feature", i, "photo path:", photoPath ? photoPath.substring(0, Math.min(50, photoPath.length)) + "..." : "null")
                    
                    if (photoPath && typeof photoPath === 'string' && photoPath.trim() !== '') {
                        // Check if it's a local path (not a URL)
                        if (!/^https?:\/\//i.test(photoPath) && (/[\/\\]/.test(photoPath) || /^[a-zA-Z]:/.test(photoPath))) {
                            console.log("[SyncDialog] ✓ Found pending photo:", photoPath)
                            pendingPhotos.push({
                                feature: feature,
                                globalId: feature.attribute('global_id') || feature.attribute('globalid') || feature.id().toString(),
                                localPath: photoPath
                            })
                        } else {
                            console.log("[SyncDialog] ✗ Already synced (URL):", photoPath.substring(0, 50))
                        }
                    }
                }
            } else {
                console.log("[SyncDialog] Features object doesn't have length property")
                console.log("[SyncDialog] Trying iterator-style access...")
                
                // Try iterator pattern
                var feature = features.next()
                while (feature) {
                    featureCount++
                    var photoPath = feature.attribute(photoFieldName)
                    
                    if (photoPath && typeof photoPath === 'string' && photoPath.trim() !== '') {
                        if (!/^https?:\/\//i.test(photoPath) && (/[\/\\]/.test(photoPath) || /^[a-zA-Z]:/.test(photoPath))) {
                            console.log("[SyncDialog] ✓ Found pending photo:", photoPath)
                            pendingPhotos.push({
                                feature: feature,
                                globalId: feature.attribute('global_id') || feature.attribute('globalid') || feature.id().toString(),
                                localPath: photoPath
                            })
                        }
                    }
                    
                    feature = features.next()
                }
            }
            
            console.log("[SyncDialog] Processed", featureCount, "features")
            console.log("[SyncDialog] Found", pendingPhotos.length, "pending photos")
            
        } catch (e) {
            console.log("[SyncDialog] ✗ ERROR getting features:", e)
            console.log("[SyncDialog] Stack:", e.stack)
            if (plugin && plugin.displayToast) {
                plugin.displayToast("Error reading layer features: " + e.toString(), "error")
            }
        }
        
        totalPhotos = pendingPhotos.length
        console.log("[SyncDialog] ========== PENDING COUNT COMPLETE ==========")
        console.log("[SyncDialog] Total pending photos:", totalPhotos)
    }
    
    function startSync() {
        console.log("[SyncDialog] Starting sync...")
        if (!selectedLayer || totalPhotos === 0) {
            console.log("[SyncDialog] No photos to sync")
            return
        }
        
        syncing = true
        plugin.syncInProgress = true
        
        plugin.syncPhotos(
            pendingPhotos,
            selectedLayer,
            function(photoIndex, total, percent, status) {
                console.log("[SyncDialog] Progress: " + photoIndex + "/" + total + " - " + percent + "%")
            },
            function(photoIndex, success, error) {
                console.log("[SyncDialog] Photo complete: " + success)
            },
            function(results) {
                console.log("[SyncDialog] All complete: " + results.succeeded + " succeeded")
                syncing = false
                plugin.syncInProgress = false
                resultText.text = "Sync Complete!\nSucceeded: " + results.succeeded + "\nFailed: " + results.failed
                resultDialog.open()
            }
        )
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Text {
            text: "Sync Photos to Render"
            font.pixelSize: 20
            font.bold: true
            Layout.fillWidth: true
        }
        
        Text {
            text: "Select Layer:"
            font.pixelSize: 14
        }
        
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
        
        Text {
            text: "Pending photos: " + totalPhotos
            font.pixelSize: 16
            font.bold: true
            color: totalPhotos > 0 ? "#FF9800" : "#4CAF50"
        }
        
        Text {
            text: "Debug Log:"
            font.pixelSize: 12
            font.bold: true
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 150
            clip: true
            
            TextArea {
                id: debugTextArea
                text: debugLog
                readOnly: true
                wrapMode: TextArea.Wrap
                font.pixelSize: 10
                font.family: "Courier New"
            }
        }
        
        Item { Layout.fillHeight: true }
        
        Button {
            text: syncing ? "Syncing..." : "Start Sync"
            Layout.fillWidth: true
            enabled: !syncing && totalPhotos > 0
            onClicked: startSync()
        }
        
        Button {
            text: "Close"
            Layout.fillWidth: true
            enabled: !syncing
            onClicked: syncDialog.close()
        }
    }
    
    Popup {
        id: resultDialog
        modal: true
        width: 400
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Text {
                id: resultText
                text: "Results"
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
