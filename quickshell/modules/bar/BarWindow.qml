pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
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

    // Ignore the frame's side exclusion zones so the bar spans the full screen
    // width (otherwise layer-shell insets it and the corners show wallpaper).
    // Its own 48px reservation lives in FrameExclusions with the rest.
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
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
