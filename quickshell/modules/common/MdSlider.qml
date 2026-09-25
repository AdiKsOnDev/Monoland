pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// MD3 expressive slider: a tall pill groove with a bar handle, rather than the
// thin-line-plus-dot of earlier Material. The hit area spans the full height so
// the handle stays grabbable even though the groove is only 16px.
Item {
    id: root

    property int value: 0          // 0..maxValue
    property int maxValue: 100     // >100 enables a boost zone (e.g. 150)
    property bool interactive: true
    property int groove: 16
    // Handle bar height at rest and while pressed. Kept taller than the groove
    // so it stays proud of the track; scale both up alongside `groove`.
    property int handleHeight: 30
    property int handlePressedHeight: 36
    // Corner radius on the two track ends that face the handle. The outer ends
    // stay fully rounded; squaring off the inner ones is what keeps the gap
    // around the handle reading as a notch rather than two bulbous caps.
    property int notchRadius: 2

    signal moved(int percent)

    // Grow with the (pressed) handle so it is never clipped
    implicitHeight: Math.max(44, handlePressedHeight + 8)
    implicitWidth: 240
    opacity: interactive ? 1 : Md.disabledOpacity

    readonly property real _fraction: Math.max(0, Math.min(maxValue, value)) / maxValue
    // Handle travel is inset by half a handle width at each end so it never
    // overhangs the groove.
    readonly property real _travel: width - handle.width
    readonly property real _handleX: _fraction * _travel

    Rectangle {
        id: inactiveTrack
        anchors.verticalCenter: parent.verticalCenter
        x: handle.x + handle.width + 6
        width: Math.max(0, parent.width - x)
        height: root.groove
        topLeftRadius: root.notchRadius
        bottomLeftRadius: root.notchRadius
        topRightRadius: height / 2
        bottomRightRadius: height / 2
        color: Md.surfaceContainerHighest

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    Rectangle {
        id: activeTrack
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: Math.max(0, handle.x - 6)
        height: root.groove
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: root.notchRadius
        bottomRightRadius: root.notchRadius
        color: Md.primary

        Behavior on color { ColorAnimation { duration: Md.durMedium } }
    }

    // Unity (100%) mark, shown only when a boost zone exists past it
    Rectangle {
        visible: root.maxValue > 100
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: root.groove * 0.5
        radius: 1
        color: Md.surface
        opacity: 0.5
        x: (100 / root.maxValue) * root._travel + handle.width / 2 - width / 2
    }

    Rectangle {
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        x: root._handleX
        width: 4
        height: drag.pressed ? root.handlePressedHeight : root.handleHeight
        radius: width / 2
        color: Md.primary

        Behavior on height { NumberAnimation { duration: Md.durShort; easing.type: Md.easingStandard } }
        Behavior on color { ColorAnimation { duration: Md.durMedium } }
        // No Behavior on x: it must track the cursor exactly while dragging.
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function emitFor(mouseX) {
            const clamped = Math.max(0, Math.min(root._travel, mouseX - handle.width / 2))
            root.moved(Math.round((clamped / root._travel) * root.maxValue))
        }

        onPressed: (mouse) => emitFor(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) emitFor(mouse.x) }

        onWheel: (wheel) => {
            const step = wheel.angleDelta.y > 0 ? 5 : -5
            root.moved(Math.max(0, Math.min(root.maxValue, root.value + step)))
        }
    }
}
