pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

// Metrics + appearance for the screen frame. Single source of truth consumed
// by the frame windows, the bar, and every panel that attaches to the frame.
Singleton {
    id: root

    readonly property bool enabled: true

    // Left/right/bottom band width (logical px)
    readonly property int thickness: 24
    // Top edge thickness == bar height
    readonly property int barHeight: 40
    // Concave fillet radius at frame/panel junctions
    readonly property int radius: 32

    // Reach of the inner shadow the frame casts onto the workspace
    readonly property int shadowSize: 30

    // Frame surface color; pywal-reactive via Colors
    readonly property color color: Colors.background

    // The workspace hole inside the frame, in screen-local coordinates
    function innerRect(screen) {
        return Qt.rect(thickness, barHeight,
                       screen.width - 2 * thickness,
                       screen.height - barHeight - thickness)
    }
}
