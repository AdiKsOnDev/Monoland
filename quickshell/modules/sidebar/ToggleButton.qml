pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Rectangle {
    id: root

    required property string icon
    required property bool active
    property string label: ""
    property string sublabel: ""

    signal clicked()

    implicitWidth: 44
    implicitHeight: 44
    radius: 999
    color: active
        ? (hoverArea.containsMouse ? Qt.lighter(Colors.primaryText, 1.1) : Colors.primaryText)
        : (hoverArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.4) : Colors.surfaceVariant)

    scale: hoverArea.pressed ? 0.96 : 1.0

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

    // Icon-only mode (no label)
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 19
        color: root.active ? Colors.background : Colors.chipIcon
        visible: root.label === ""

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Wide pill mode (with label)
    Row {
        anchors {
            left: parent.left
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }
        spacing: 10
        visible: root.label !== ""

        Rectangle {
            width: 38
            height: 38
            radius: 999
            anchors.verticalCenter: parent.verticalCenter
            color: root.active ? Qt.rgba(0, 0, 0, 0.15) : Colors.background

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: root.active ? Colors.background : Colors.chipIcon

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.label
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 13
                font.weight: Font.Bold
                color: root.active ? Colors.background : Colors.primaryText

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: root.sublabel
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 11
                color: root.active ? Qt.rgba(0,0,0,0.5) : Colors.secondaryText
                visible: root.sublabel !== ""

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
