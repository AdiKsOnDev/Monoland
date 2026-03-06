pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services

Item {
    id: root

    signal archClicked()
    signal centerClicked()
    signal rightClicked()

    // Ensures the Notifications singleton is instantiated and the server registers on startup
    readonly property var _notifications: Notifications.notifications

    Item {
        id: archButton
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: 28
        implicitHeight: 28

        readonly property bool isHovered: archHoverArea.containsMouse

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: parent.isHovered ? Colors.border : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.centerIn: parent
            text: "\uf303"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 19
            color: Colors.chipIcon
        }

        MouseArea {
            id: archHoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.archClicked()
        }
    }

    Workspaces {
        anchors {
            left: archButton.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: centerSection
        anchors.centerIn: parent
        width: parent.width / 3
        height: parent.height

        Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Colors.primaryText
            font.pixelSize: 14
            font.family: "Poppins"
            font.italic: false
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: clockText
            cursorShape: Qt.PointingHandCursor
            onClicked: root.centerClicked()
        }
    }

    Item {
        id: rightSection
        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: rightRow.implicitWidth + 16
        implicitHeight: 26
        height: parent.height

        readonly property bool isHovered: rightHoverArea.containsMouse

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: (parent.height - 26) / 2
            anchors.bottomMargin: (parent.height - 26) / 2
            radius: 6
            color: parent.isHovered ? Colors.border : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Row {
            id: rightRow
            anchors.centerIn: parent
            spacing: 6

            StatChip { icon: Wifi.enabled ? "󰤨" : "󰤭" }
            StatChip { icon: Brightness.brightnessPercent > 66 ? "󰃠" : Brightness.brightnessPercent > 33 ? "󰃟" : "󰃞" }
            StatChip { icon: Audio.muted ? "󰖁" : Audio.volumePercent > 66 ? "󰕾" : Audio.volumePercent > 33 ? "󰖀" : "󰕿" }
            StatChip { icon: Battery.isCharging ? "󰂄" : Battery.capacityLabel >= "66%" ? "󰁹" : Battery.capacityLabel >= "33%" ? "󰁾" : "󰁺" }
        }

        MouseArea {
            id: rightHoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.rightClicked()
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
