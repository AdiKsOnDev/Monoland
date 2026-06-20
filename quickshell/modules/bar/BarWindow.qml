pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

PanelWindow {
    id: root

    signal archClicked()
    signal centerClicked()
    signal rightClicked()

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: barContainer.height
    // A few extra px of non-reserved space so the drop shadow can render below the bar
    implicitHeight: barContainer.height + 4
    color: "transparent"

    Rectangle {
        id: barContainer

        width: parent.width
        height: 44

        // Subtle top-lit gradient gives the bar a sense of surface depth
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Colors.background, 1.4) }
            GradientStop { position: 1.0; color: Colors.background }
        }

        // Bottom border only
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Colors.border
        }

        BarContent {
            id: barContent
            anchors.fill: parent
            onArchClicked: root.archClicked()
            onCenterClicked: root.centerClicked()
            onRightClicked: root.rightClicked()
        }
    }

    // Soft drop shadow beneath the bar for elevation
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: barContainer.bottom
        }
        height: 4
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.28) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
