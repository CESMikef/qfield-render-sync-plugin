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
    
    Component.onCompleted: {
        console.log("[SyncDialog] Simple dialog loaded")
    }
    
    onOpened: {
        console.log("[SyncDialog] Dialog opened")
        if (plugin && plugin.displayToast) {
            plugin.displayToast("Dialog opened - Loading layers...")
        }
        loadLayers()
        updatePendingCount()
    }
    
    function loadLayers() {
        console.log("[SyncDialog] Loading layers...")
        layerComboBox.model.clear()
        
        if (!plugin) {
            console.log("[SyncDialog] ERROR: No plugin reference")
            if (plugin && plugin.displayToast) {
                plugin.displayToast("ERROR: No plugin reference", "error")
            }
            return
        }
        
        try {
            var layers = plugin.getVectorLayersV2()
            console.log("[SyncDialog] Got " + layers.length + " vector layers")
            
            if (layers.length === 0) {
                console.log("[SyncDialog] WARNING: No vector layers found in project")
                layerComboBox.model.append({
                    text: "No layers found",
                    layer: null
                })
                if (plugin && plugin.displayToast) {
                    plugin.displayToast("No vector layers found in project", "warning")
                }
                return
            }
            
            for (var i = 0; i < layers.length; i++) {
                var layer = layers[i]
                var layerName = layer.name
                console.log("[SyncDialog] Adding layer:", layerName)
                layerComboBox.model.append({
                    text: layerName,
                    layer: layer
                })
            }
            
            console.log("[SyncDialog] Layer loading complete")
            if (plugin && plugin.displayToast) {
                plugin.displayToast("✅ Loaded " + layers.length + " layer(s)", "success")
            }
        } catch (e) {
            console.log("[SyncDialog] ERROR loading layers:", e)
            console.log("[SyncDialog] Stack:", e.stack)
            if (plugin && plugin.displayToast) {
                plugin.displayToast("ERROR: " + e.toString(), "error")
            }
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
