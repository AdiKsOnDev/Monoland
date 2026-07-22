pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Deep inner shadow cast by the frame (bar included) onto the workspace:
// four gradient strips along the hole edges, doubling up in the corners for
// a natural falloff. Lives in its own Top-layer window mapped before the
// panels, so panels attached to the frame emerge above the shadow instead
// of being darkened by it (the frame bands, mapped last, still cover the
// strip ends under the fillets). Fullscreen windows cover the Top layer, so
// the shadow disappears with the rest of the frame. Gradient rects avoid the
// layered-texture hairline that ruled out MultiEffect shadows at fractional
// scale.
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
    WlrLayershell.namespace: "monoland-frame-shadow"

    mask: Region {}

    component ShadowStop0: GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
    component ShadowStop1: GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.18) }
    component ShadowStop2: GradientStop { position: 1.0; color: "transparent" }

    Item {
        anchors.fill: parent

        // Top (cast by the bar)
        Rectangle {
            x: Frame.thickness; y: Frame.barHeight
            width: root.width - 2 * Frame.thickness; height: Frame.shadowSize
            gradient: Gradient {
                ShadowStop0 {}
                ShadowStop1 {}
                ShadowStop2 {}
            }
        }

        // Bottom
        Rectangle {
            x: Frame.thickness; y: root.height - Frame.thickness - Frame.shadowSize
            width: root.width - 2 * Frame.thickness; height: Frame.shadowSize
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.18) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
            }
        }

        // Left
        Rectangle {
            x: Frame.thickness; y: Frame.barHeight
            width: Frame.shadowSize; height: root.height - Frame.barHeight - Frame.thickness
            gradient: Gradient {
                orientation: Gradient.Horizontal
                ShadowStop0 {}
                ShadowStop1 {}
                ShadowStop2 {}
            }
        }

        // Right
        Rectangle {
            x: root.width - Frame.thickness - Frame.shadowSize; y: Frame.barHeight
            width: Frame.shadowSize; height: root.height - Frame.barHeight - Frame.thickness
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.18) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
            }
        }
    }
}
