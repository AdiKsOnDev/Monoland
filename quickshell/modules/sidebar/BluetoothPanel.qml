pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root
    anchors.fill: parent

    readonly property var sorted: {
        const list = Bluetooth.devices.slice()
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return (a.name || "").localeCompare(b.name || "")
        })
        return list
    }

    Rectangle {
        id: enableRow
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 46
        radius: 12
        color: Colors.chipBackground

        Text {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: Bluetooth.enabled ? "Bluetooth on" : "Bluetooth off"
            color: Colors.primaryText
            font.family: "Poppins"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        // Scan toggle
        Rectangle {
            id: scanBtn
            anchors { right: toggleSwitch.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: 30
            height: 30
            radius: 8
            visible: Bluetooth.enabled
            color: Bluetooth.discovering ? Colors.fillStrong : (scanHover.containsMouse ? Colors.surfaceVariant : "transparent")
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: Bluetooth.discovering ? Colors.fillStrongText : Colors.secondaryText
            }

            MouseArea {
                id: scanHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Bluetooth.setDiscovering(!Bluetooth.discovering)
            }
        }

        Rectangle {
            id: toggleSwitch
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: 44
            height: 26
            radius: 999
            color: Bluetooth.enabled ? Colors.fillStrong : Colors.surfaceVariant
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 20
                height: 20
                radius: 999
                color: Bluetooth.enabled ? Colors.fillStrongText : Colors.chipIcon
                anchors.verticalCenter: parent.verticalCenter
                x: Bluetooth.enabled ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Bluetooth.toggle()
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
        visible: Bluetooth.enabled

        delegate: Rectangle {
            id: devRow
            required property var modelData
            width: list.width
            height: 48
            radius: 12
            color: devHover.containsMouse ? Colors.chipBackground : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                id: devIcon
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                text: "󰂯"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: devRow.modelData.connected ? Colors.chipIconActive : Colors.chipIcon
            }

            Column {
                anchors { left: devIcon.right; leftMargin: 12; right: devState.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 1

                Text {
                    width: parent.width
                    text: devRow.modelData.name || "Unknown device"
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: devRow.modelData.connected ? "Connected"
                        : devRow.modelData.paired ? "Paired" : ""
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }

            Text {
                id: devState
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                text: devRow.modelData.connected ? "󰄬" : ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: Colors.chipIconActive
            }

            MouseArea {
                id: devHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (devRow.modelData.connected) devRow.modelData.disconnect()
                    else devRow.modelData.connect()
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: Bluetooth.discovering ? "Scanning…" : "No devices"
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 13
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !Bluetooth.enabled
        text: "Bluetooth is off"
        color: Colors.secondaryText
        font.family: "Poppins"
        font.pixelSize: 13
    }
}
