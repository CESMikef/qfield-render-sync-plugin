/**
 * Token Configuration Dialog
 * Prompts user to enter their API token
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.qfield 1.0
import Theme 1.0

Dialog {
    id: tokenDialog
    
    property var plugin: null
    
    title: qsTr("Configure API Token")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    
    width: parent ? Math.min(parent.width * 0.9, 400) : 400
    height: Math.min(implicitHeight, parent ? parent.height * 0.8 : 600)
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    
    ColumnLayout {
        width: parent.width
        spacing: 15
        
        Label {
            text: qsTr("Enter your API token to load configuration")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        Label {
            text: qsTr("Your token will be stored securely on this device.")
            font.pixelSize: 12
            color: "#666666"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        TextField {
            id: tokenInput
            placeholderText: qsTr("Enter token (e.g., qwrfzf23t2345t23fef23123r)")
            Layout.fillWidth: true
            text: plugin ? plugin.userToken : ""
            
            onAccepted: {
                tokenDialog.accept()
            }
        }
        
        Label {
            text: qsTr("Don't have a token? Contact your administrator.")
            font.pixelSize: 11
            font.italic: true
            color: "#999999"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: "#4CAF50"
                visible: plugin && plugin.configValid
            }
            
            Label {
                text: plugin && plugin.configValid ? 
                     qsTr("✓ Configuration loaded") :
                     (plugin && plugin.loadingConfig ? qsTr("Loading...") : "")
                font.pixelSize: 12
                color: "#4CAF50"
                visible: text !== ""
            }
        }
    }
    
    onAccepted: {
        var token = tokenInput.text.trim()
        if (token && token !== "" && plugin) {
            console.log("[Token Dialog] Saving token")
            plugin.saveToken(token)
            plugin.fetchConfigurationFromAPI()
        }
    }
    
    onRejected: {
        console.log("[Token Dialog] Cancelled")
    }
    
    onOpened: {
        tokenInput.forceActiveFocus()
    }
}
