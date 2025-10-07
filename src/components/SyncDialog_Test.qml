/**
 * Minimal Test Dialog
 */

import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: testDialog
    
    modal: true
    width: 400
    height: 300
    
    property var plugin: null
    property var config: ({})
    
    Component.onCompleted: {
        console.log("[TestDialog] Loaded successfully!")
    }
    
    contentItem: Column {
        spacing: 20
        padding: 20
        
        Text {
            text: "Test Dialog Loaded!"
            font.pixelSize: 24
            font.bold: true
        }
        
        Text {
            text: "If you see this, the dialog can load."
            wrapMode: Text.WordWrap
            width: parent.width - 40
        }
        
        Button {
            text: "Close"
            onClicked: testDialog.close()
        }
    }
}
