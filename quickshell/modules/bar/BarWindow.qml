pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

PanelWindow {
    id: root

    signal centerClicked()
    signal rightClicked()

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: barContainer.height
    implicitHeight: barContainer.height
    color: "transparent"

    Rectangle {
        id: barContainer

        width: parent.width
        height: 44
        color: Colors.background

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
            onCenterClicked: root.centerClicked()
            onRightClicked: root.rightClicked()
        }
    }
}
