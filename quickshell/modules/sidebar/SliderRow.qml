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

    // Single capsule track with the filled portion inside it, icon overlaid
    // on the left.
    Item {
        id: track
        anchors.fill: parent

        readonly property real frac: Math.max(0, Math.min(1, root.value / 100))
        readonly property int pillH: 48
        readonly property real filledWidth: frac * width

        // Track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: track.pillH
            radius: track.pillH / 2
            color: sliderArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.3) : Colors.surfaceVariant

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Filled portion — a capsule inside the track
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: track.filledWidth
            height: track.pillH
            radius: track.pillH / 2
            color: Colors.primaryText

            Behavior on width {
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
