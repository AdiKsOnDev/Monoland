pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen

    property int popupWidth: 390
    property bool isOpen: false
    function toggle() {
        if (!isOpen) visible = true
        isOpen = !isOpen
    }

    onIsOpenChanged: {
        if (isOpen) visible = true
        else hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 340
        onTriggered: root.visible = false
    }

    // When true, the popup right-aligns to the bar's right edge instead of centering
    property bool alignRight: false

    // Exposed so callers can keep the popup open while the user hovers it
    readonly property bool isHovered: popupHoverArea.containsMouse

    // Visual Item children go into the column; non-visual objects (Timer, Connections…)
    // are accepted via data and parented to the window root.
    default property alias content: contentColumn.data

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: -1
    implicitHeight: screen.height
    color: "transparent"
    focusable: isOpen

    // Mask to a plain proxy, not `plate`: `plate` has layer.enabled (for the
    // shadow), and a layered item reports no usable region to Quickshell — which
    // collapses the window's input region and makes the popup unclickable.
    mask: Region {
        item: maskProxy
    }

    Item {
        id: maskProxy
        x: plate.x
        y: plate.y
        width: plate.width
        height: plate.height
    }

    // Overlap into the bar so the junction can never show a seam
    readonly property int seam: 1

    // The plate hangs flush from the bar (the frame's top edge) and carries the
    // box plus the concave fillets that fuse it with the frame. Reveal animates
    // the plate, so the fillets move and fade in lockstep with the panel.
    Item {
        id: plate

        width: root.popupWidth
        x: root.alignRight
            ? root.screen.width - Frame.thickness - width + root.seam
            : (parent.width - width) / 2
        y: Frame.barHeight - root.seam
        height: contentColumn.implicitHeight + 24 + root.seam

        // No shadow layer: the layered texture resamples at fractional scale
        // and shows a hairline along the edges. Flat matte matches the frame.

        Rectangle {
            id: box

            anchors.fill: parent
            clip: true

            // Flush surface: same color as the frame, square where attached
            color: Frame.color
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Frame.radius
            bottomRightRadius: root.alignRight ? 0 : Frame.radius

            MouseArea {
                id: popupHoverArea
                anchors.fill: parent
                hoverEnabled: root.visible
                propagateComposedEvents: true
                acceptedButtons: Qt.NoButton
            }

            Column {
                id: contentColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                }
                anchors.topMargin: 20 + root.seam
                spacing: 20
            }
        }

        // Concave fillets fusing the panel with the bar above. Shifted 1px into
        // the box so the fillet/box AA edges overlap solid color — edge-to-edge
        // they leave a half-covered device pixel at fractional scale (faint
        // light seam against the wallpaper).
        ConcaveCorner {
            corner: "topRight"
            x: -radius + 1; y: root.seam
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "topLeft"
            x: plate.width - 1; y: root.seam
            radius: Frame.radius; color: Frame.color
            visible: !root.alignRight
        }
    }

    Reveal {
        target: plate
        shown: root.isOpen
        motion: "emerge"
        edge: "top"
        squash: 0.94
        bulge: 1.01
        distance: 10
        outDuration: 180
    }
}
