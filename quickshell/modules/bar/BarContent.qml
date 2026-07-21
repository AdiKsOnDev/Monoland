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

    // Shared surface tokens for a cohesive raised-card look across zones
    readonly property int surfaceRadius: 8
    readonly property color surfaceRest: Colors.chipBackground
    readonly property color surfaceHover: Qt.lighter(Colors.chipBackground, 1.6)
    readonly property color borderRest: Colors.surfaceVariant
    readonly property color borderHover: Colors.border

    Item {
        id: archLogo
        anchors {
            left: parent.left
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
        width: 34
        height: 30

        readonly property bool isHovered: archArea.containsMouse

        scale: isHovered ? 1.06 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: root.surfaceRadius
            color: archLogo.isHovered ? root.surfaceHover : root.surfaceRest
            border.width: 1
            border.color: archLogo.isHovered ? root.borderHover : root.borderRest

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: archLogo.isHovered ? Colors.chipIconActive : Colors.chipIcon

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: archArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.archClicked()
        }
    }

    Workspaces {
        anchors {
            left: archLogo.right
            leftMargin: 10
            verticalCenter: parent.verticalCenter
        }
    }

    Item {
        id: centerSection
        anchors.centerIn: parent
        width: parent.width / 3
        height: parent.height

        readonly property bool isHovered: clockArea.containsMouse

        Rectangle {
            id: clockPill
            anchors.centerIn: parent
            implicitWidth: clockText.implicitWidth + 28
            implicitHeight: 26
            radius: root.surfaceRadius
            color: centerSection.isHovered ? root.surfaceHover : root.surfaceRest
            border.width: 1
            border.color: centerSection.isHovered ? root.borderHover : root.borderRest

            scale: centerSection.isHovered ? 1.04 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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
                id: clockArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.centerClicked()
            }
        }
    }

    Item {
        id: rightSection
        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: rightRow.implicitWidth + 18
        implicitHeight: 26
        height: parent.height

        readonly property bool isHovered: rightHoverArea.containsMouse

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: (parent.height - 26) / 2
            anchors.bottomMargin: (parent.height - 26) / 2
            radius: root.surfaceRadius
            color: parent.isHovered ? root.surfaceHover : root.surfaceRest
            border.width: 1
            border.color: parent.isHovered ? root.borderHover : root.borderRest

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        Row {
            id: rightRow
            anchors.centerIn: parent
            spacing: 6

            DeepWorkChip {}
            NotificationChip {}
            StatChip {
                icon: Wifi.enabled ? "󰤨" : "󰤭"
                active: Wifi.enabled
            }
            StatChip {
                icon: Brightness.brightnessPercent > 66 ? "󰃠" : Brightness.brightnessPercent > 33 ? "󰃟" : "󰃞"
            }
            StatChip {
                icon: Audio.muted ? "󰖁" : Audio.volumePercent > 66 ? "󰕾" : Audio.volumePercent > 33 ? "󰖀" : "󰕿"
                active: !Audio.muted
            }
            StatChip {
                icon: Battery.isCharging ? "󰂄" : Battery.capacityLabel >= "66%" ? "󰁹" : Battery.capacityLabel >= "33%" ? "󰁾" : "󰁺"
                accent: Battery.isCharging ? Colors.chipIconActive : Colors.chipIcon
            }
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
