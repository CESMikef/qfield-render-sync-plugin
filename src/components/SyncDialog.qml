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
                addDebugLog("=== Trying mapLayersByName ===")
                
                if (typeof qgisProject.mapLayersByName === 'function') {
                    addDebugLog("Trying mapLayersByName('verify_poles')...")
                    var verifyLayers = qgisProject.mapLayersByName('verify_poles')
                    addDebugLog("Result type: " + typeof verifyLayers)
                    addDebugLog("Result length: " + (verifyLayers ? verifyLayers.length : "null"))
                    
                    if (verifyLayers && verifyLayers.length > 0) {
                        for (var i = 0; i < verifyLayers.length; i++) {
                            var lyr = verifyLayers[i]
                            addDebugLog("Layer " + i + ": " + lyr.name + " (type: " + lyr.type + ")")
                        }
                    }
                }
                
                // Check dashBoard properties
                addDebugLog("=== Checking dashBoard ===")
                if (typeof dashBoard !== 'undefined' && dashBoard) {
                    addDebugLog("dashBoard exists")
                    addDebugLog("dashBoard.layerTree: " + typeof dashBoard.layerTree)
                    addDebugLog("dashBoard.activeLayer: " + typeof dashBoard.activeLayer)
                    
                    // Check layerTree methods
                    if (dashBoard.layerTree) {
                        addDebugLog("=== layerTree methods ===")
                        var ltProps = []
                        for (var ltprop in dashBoard.layerTree) {
                            var ltType = typeof dashBoard.layerTree[ltprop]
                            if (ltType === 'function' || ltprop.toLowerCase().indexOf("layer") >= 0) {
                                ltProps.push(ltprop + ":" + ltType)
                            }
                        }
                        addDebugLog("layerTree props: " + ltProps.join(", "))
                        
                        // Try findLayers
                        if (typeof dashBoard.layerTree.findLayers === 'function') {
                            addDebugLog("Calling layerTree.findLayers()...")
                            var foundLayers = dashBoard.layerTree.findLayers()
                            addDebugLog("findLayers returned: " + foundLayers.length + " layers")
                            
                            for (var i = 0; i < foundLayers.length; i++) {
                                var tl = foundLayers[i]
                                addDebugLog("TreeLayer " + i + ": " + typeof tl)
                                if (tl && typeof tl.layer === 'function') {
                                    var l = tl.layer()
                                    if (l) {
                                        addDebugLog("  -> " + l.name + " (type: " + l.type + ")")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    addDebugLog("dashBoard NOT available")
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
        console.log("[SyncDialog] Layer source:", selectedLayer.source)
        console.log("[SyncDialog] Photo field:", config.photoField || "photo")
        
        addDebugLog("Layer: " + selectedLayer.name)
        addDebugLog("Source: " + selectedLayer.source)
        
        // Try to query the layer using SQL if it's a GeoPackage
        var photoField = config.photoField || "photo"
        
        // For now, we cannot query GeoPackage from QML
        // Show message that user should click "Start Sync" to process all features
        addDebugLog("Feature counting not available in QField QML")
        addDebugLog("Click 'Start Sync' to sync all photos in layer")
        
        pendingPhotos = []
        totalPhotos = 0
    }
    
    function startSync() {
        console.log("[SyncDialog] Starting sync...")
        if (!selectedLayer) {
            console.log("[SyncDialog] No layer selected")
            addDebugLog("ERROR: No layer selected")
            return
        }
        
        addDebugLog("Starting sync for layer: " + selectedLayer.name)
        addDebugLog("This will sync ALL features with photos in the layer")
        
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
            text: totalPhotos > 0 ? ("Pending photos: " + totalPhotos) : "Photo count unavailable (click Start Sync to process all)"
            font.pixelSize: 14
            font.bold: true
            color: "#2196F3"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
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
            enabled: !syncing && selectedLayer !== null
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
