pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.modules.common

// Draws the screen frame: left/right/bottom bands plus the four concave
// fillets at the workspace-area corners. The bar is the top edge and stays
// its own window.
//
// Lives on the Top layer like the bar, so fullscreen windows naturally cover
// it — no fullscreen detection needed. It must be the LAST window mapped per
// screen (instantiated after BarWindow in Bar.qml) so the bands stack above
// the panels, letting them slide out from behind the frame. Space reservation
// is delegated to FrameExclusions — this window is fully click-through.
PanelWindow {
    id: root

    required property var screen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "monoland-frame"

    // Zero input area — clicks pass through everywhere
    mask: Region {}

    Item {
        anchors.fill: parent

        // Bands. Left/right start 1px above the bar's bottom edge — overlapping
        // the flat bar avoids an AA seam at the junction, while leaving the
        // bar's own width free for its content (the bands must not cover the
        // arch logo / chips at the bar's corners).
        Rectangle {
            x: 0; y: Frame.barHeight - 1
            width: Frame.thickness; height: root.height - (Frame.barHeight - 1)
            color: Frame.color
        }
        Rectangle {
            x: root.width - Frame.thickness; y: Frame.barHeight - 1
            width: Frame.thickness; height: root.height - (Frame.barHeight - 1)
            color: Frame.color
        }
        Rectangle {
            x: 0; y: root.height - Frame.thickness
            width: root.width; height: Frame.thickness
            color: Frame.color
        }

        // Concave fillets at the four corners of the workspace hole. Overlapped
        // 1px into the adjacent bands so the AA edges meet on solid color and
        // never leave a half-covered pixel seam at fractional scale.
        ConcaveCorner {
            corner: "topLeft"
            x: Frame.thickness - 1; y: Frame.barHeight - 1
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "topRight"
            x: root.width - Frame.thickness - Frame.radius + 1; y: Frame.barHeight - 1
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "bottomLeft"
            x: Frame.thickness - 1; y: root.height - Frame.thickness - Frame.radius + 1
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "bottomRight"
            x: root.width - Frame.thickness - Frame.radius + 1
            y: root.height - Frame.thickness - Frame.radius + 1
            radius: Frame.radius; color: Frame.color
        }
    }
}
