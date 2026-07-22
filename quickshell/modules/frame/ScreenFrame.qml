pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.modules.common

// Draws the screen frame: left/right/bottom bands plus the four concave
// fillets at the workspace-area corners. The bar is the top edge and stays
// its own window; the side bands run full height and paint over the bar's
// outer pixels so the top corners are seamless by construction.
//
// Overlay layer keeps the frame above lazily-created panels regardless of
// map order, so panels appear to emerge from behind it. Space reservation
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
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "monoland-frame"

    // Zero input area — clicks pass through everywhere
    mask: Region {}

    // Overlay would draw over fullscreen apps, so fade the frame away
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hasFullscreen:
        monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false

    property real frameOpacity: hasFullscreen ? 0 : 1
    visible: frameOpacity > 0.01

    Behavior on frameOpacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Item {
        anchors.fill: parent
        opacity: root.frameOpacity

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
