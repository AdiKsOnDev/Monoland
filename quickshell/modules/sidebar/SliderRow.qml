pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    required property string icon
    required property int value

    signal moved(int percent)

    implicitWidth: parent?.width ?? 200
    implicitHeight: 68

    // Split-pill track: filled pill | playhead | remaining pill, with the icon
    // overlaid on the left.
    Item {
        id: track
        anchors.fill: parent

        readonly property real frac: Math.max(0, Math.min(1, root.value / 100))
        readonly property int thumbW: 4
        readonly property int gap: 5
        readonly property int pillH: 48
        readonly property int pillRadius: 8
        readonly property int innerRadius: 3   // corners adjacent to the playhead
        readonly property real headX: frac * width
        readonly property real filledWidth: Math.max(0, headX - gap - thumbW / 2)

        // Filled (elapsed) portion
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: track.filledWidth
            height: track.pillH
            radius: track.pillRadius
            topRightRadius: track.innerRadius
            bottomRightRadius: track.innerRadius
            color: Colors.primaryText

            Behavior on width {
                enabled: !sliderArea.pressed
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }
        }

        // Remaining portion
        Rectangle {
            id: remaining
            anchors.verticalCenter: parent.verticalCenter
            // Right edge pinned; only the width animates (derived from the playhead),
            // so the left edge tracks the playhead 1:1 instead of drifting.
            anchors.right: parent.right
            width: Math.max(0, parent.width - (track.headX + track.gap + track.thumbW / 2))
            height: track.pillH
            radius: track.pillRadius
            topLeftRadius: track.innerRadius
            bottomLeftRadius: track.innerRadius
            color: sliderArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.3) : Colors.surfaceVariant

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on width {
                enabled: !sliderArea.pressed
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }
        }

        // Playhead / thumb — taller than the pills, contrasting colour
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: track.thumbW
            height: track.pillH + 8
            radius: 1
            color: Colors.primaryText
            x: Math.max(0, Math.min(track.width - width, track.headX - width / 2))

            Behavior on x {
                enabled: !sliderArea.pressed
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }
        }

        // Icon overlaid on the left, coloured like toggle-pill icons:
        // the on-fill colour while over the filled pill, chipIcon over the empty track.
        Text {
            id: iconLabel
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            z: 2
            color: (x + width / 2) < track.filledWidth ? Colors.background : Colors.chipIcon

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: sliderArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (event) => root.moved(Math.round((event.x / width) * 100))
            onPositionChanged: (event) => {
                if (pressed)
                    root.moved(Math.max(0, Math.min(100, Math.round((event.x / width) * 100))))
            }
        }

        // Scroll over the slider to nudge the value in 5% steps
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                const step = event.angleDelta.y > 0 ? 5 : -5
                root.moved(Math.max(0, Math.min(100, root.value + step)))
            }
        }
    }
}
