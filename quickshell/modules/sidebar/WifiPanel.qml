pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking
import qs.services

Item {
    id: root
    anchors.fill: parent

    // Connected first, then strongest signal
    readonly property var sorted: {
        const list = Wifi.networks.slice()
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0)
        })
        return list
    }

    property var pskNetwork: null

    function iconFor(strength) {
        if (strength >= 0.8) return "󰤨"
        if (strength >= 0.6) return "󰤥"
        if (strength >= 0.4) return "󰤢"
        if (strength >= 0.2) return "󰤟"
        return "󰤯"
    }

    // Wi-Fi enable toggle
    Rectangle {
        id: enableRow
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 46
        radius: 12
        color: Colors.chipBackground

        Text {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: Wifi.enabled ? "Wi-Fi on" : "Wi-Fi off"
            color: Colors.primaryText
            font.family: "Poppins"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Rectangle {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: 44
            height: 26
            radius: 999
            color: Wifi.enabled ? Colors.fillStrong : Colors.surfaceVariant
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 20
                height: 20
                radius: 999
                color: Wifi.enabled ? Colors.fillStrongText : Colors.chipIcon
                anchors.verticalCenter: parent.verticalCenter
                x: Wifi.enabled ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Wifi.toggle()
            }
        }
    }

    ListView {
        id: list
        anchors {
            top: enableRow.bottom
            topMargin: 10
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        spacing: 4
        model: root.sorted
        visible: Wifi.enabled

        delegate: Rectangle {
            id: netRow
            required property var modelData
            width: list.width
            height: pskActive ? 92 : 48
            radius: 12
            color: rowHover.containsMouse || pskActive ? Colors.chipBackground : "transparent"

            readonly property bool secured: modelData.security !== WifiSecurityType.Open
            readonly property bool pskActive: root.pskNetwork === modelData

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Connections {
                target: netRow.modelData
                function onRequestConnectWithPsk() {
                    root.pskNetwork = netRow.modelData
                    pskField.text = ""
                    pskField.forceActiveFocus()
                }
            }

            Item {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 48

                Text {
                    id: sig
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    text: root.iconFor(netRow.modelData.signalStrength)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: netRow.modelData.connected ? Colors.chipIconActive : Colors.chipIcon
                }

                Column {
                    anchors { left: sig.right; leftMargin: 12; right: stateIcon.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    spacing: 1

                    Text {
                        width: parent.width
                        text: netRow.modelData.name
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: netRow.modelData.connected ? "Connected"
                            : netRow.modelData.stateChanging ? "Connecting…"
                            : netRow.modelData.known ? "Saved" : ""
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                Text {
                    id: stateIcon
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    text: netRow.modelData.connected ? "󰄬" : (netRow.secured ? "󰌾" : "")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: netRow.modelData.connected ? Colors.chipIconActive : Colors.secondaryText
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (netRow.modelData.connected) netRow.modelData.disconnect()
                        else netRow.modelData.connect()
                    }
                }
            }

            // Inline password entry (shown when the network asks for a PSK)
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
                height: 36
                radius: 8
                color: Colors.surfaceVariant
                visible: netRow.pskActive

                TextInput {
                    id: pskField
                    anchors { left: parent.left; right: connectGo.left; leftMargin: 12; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.pixelSize: 13
                    echoMode: TextInput.Password
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Password…"
                        color: Colors.secondaryText
                        font: parent.font
                        visible: parent.text.length === 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    Keys.onReturnPressed: {
                        netRow.modelData.connectWithPsk(pskField.text)
                        root.pskNetwork = null
                    }
                    Keys.onEscapePressed: root.pskNetwork = null
                }

                Rectangle {
                    id: connectGo
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    width: 28
                    height: 28
                    radius: 8
                    color: goHover.containsMouse ? Colors.fillStrong : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰁕"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: goHover.containsMouse ? Colors.fillStrongText : Colors.secondaryText
                    }

                    MouseArea {
                        id: goHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            netRow.modelData.connectWithPsk(pskField.text)
                            root.pskNetwork = null
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No networks found"
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 13
        }
    }

    // Disabled state
    Text {
        anchors.centerIn: parent
        visible: !Wifi.enabled
        text: "Wi-Fi is off"
        color: Colors.secondaryText
        font.family: "Poppins"
        font.pixelSize: 13
    }
}
