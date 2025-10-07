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
    
    width: parent ? Math.min(parent.width * 0.9, 600) : 600
    height: parent ? Math.min(parent.height * 0.8, 700) : 700
    
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
        loadLayers()
        updatePendingCount()
    }
    
    function loadLayers() {
        console.log("[SyncDialog] Loading layers...")
        layerComboBox.model.clear()
        
        if (!plugin || !plugin.qfProject) {
            console.log("[SyncDialog] No plugin or project")
            return
        }
        
        var layers = plugin.getVectorLayers()
        console.log("[SyncDialog] Found " + layers.length + " layers")
        
        for (var i = 0; i < layers.length; i++) {
            var layer = layers[i]
            layerComboBox.model.append({
                text: layer.name(),
                layer: layer
            })
        }
    }
    
    function updatePendingCount() {
        console.log("[SyncDialog] Updating pending count...")
        if (!selectedLayer) {
            pendingPhotos = []
            totalPhotos = 0
            return
        }
        
        pendingPhotos = []
        var features = selectedLayer.getFeatures()
        
        for (var i = 0; i < features.length; i++) {
            var feature = features[i]
            var photoPath = feature.attribute(config.photoField)
            
            if (photoPath && typeof photoPath === 'string') {
                if (!/^https?:\/\//i.test(photoPath) && (/[\/\\]/.test(photoPath) || /^[a-zA-Z]:/.test(photoPath))) {
                    pendingPhotos.push({
                        feature: feature,
                        globalId: feature.attribute('global_id') || feature.attribute('globalid') || feature.id().toString(),
                        localPath: photoPath
                    })
                }
            }
        }
        
        totalPhotos = pendingPhotos.length
        console.log("[SyncDialog] Found " + totalPhotos + " pending photos")
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
