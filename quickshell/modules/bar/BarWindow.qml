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
    implicitHeight: barContainer.height
    color: "transparent"

    // Flat matte surface: the bar is the top edge of the screen frame, so it
    // must match Frame.color exactly for the side bands to fuse with it.
    Rectangle {
        id: barContainer

        width: parent.width
        height: Frame.barHeight
        color: Frame.color

        BarContent {
            id: barContent
            anchors.fill: parent
            onArchClicked: root.archClicked()
            onCenterClicked: root.centerClicked()
            onRightClicked: root.rightClicked()
        }
    }
}
