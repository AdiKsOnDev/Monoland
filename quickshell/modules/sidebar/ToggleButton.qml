pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Rectangle {
    id: root

    required property string icon
    required property bool active
    property string label: ""
    property string labelSuffix: ""
    property string sublabel: ""

    signal clicked()
    signal expandRequested()

    implicitWidth: 44
    implicitHeight: 44
    radius: 999

    // Labelled = wide card (subtle surface + coloured icon tile).
    // Unlabelled = icon-only pill that floods with the active colour.
    readonly property bool wide: label !== ""

    color: wide
        ? (hoverArea.containsMouse ? Qt.lighter(Colors.chipBackground, 1.4) : Colors.chipBackground)
        : active
            ? (hoverArea.containsMouse ? Qt.lighter(Colors.fillStrong, 1.1) : Colors.fillStrong)
            : (hoverArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.4) : Colors.surfaceVariant)

    border.width: wide ? 0 : (active ? 0 : 1)
    border.color: (!wide && hoverArea.containsMouse) ? Colors.border : Qt.lighter(Colors.surfaceVariant, 1.6)

    scale: hoverArea.pressed ? 0.97 : (hoverArea.containsMouse ? 1.02 : 1.0)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // Icon-only mode (no label)
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 19
        color: root.active ? Colors.fillStrongText : Colors.chipIcon
        visible: !root.wide

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Wide card: coloured icon tile
    Rectangle {
        id: iconTile
        visible: root.wide
        width: 48
        height: 48
        radius: 14
        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        color: root.active ? Colors.fillStrong : Colors.surfaceVariant

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 24
            color: root.active ? Colors.fillStrongText : Colors.chipIcon

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Wide card: label (+ optional dim suffix) over sublabel
    Column {
        visible: root.wide
        anchors {
            left: iconTile.right
            leftMargin: 14
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        Row {
            spacing: 6

            Text {
                id: labelText
                text: root.label
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Text {
                anchors.baseline: labelText.baseline
                text: root.labelSuffix
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 11
                font.weight: Font.Medium
                visible: root.labelSuffix !== ""
            }
        }

        Text {
            width: parent.width
            text: root.sublabel
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 12
            elide: Text.ElideRight
            visible: root.sublabel !== ""
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) root.expandRequested()
            else root.clicked()
        }
    }
}
