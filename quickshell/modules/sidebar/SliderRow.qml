pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    required property string icon
    required property int value

    signal moved(int percent)

    implicitWidth: parent?.width ?? 200
    implicitHeight: 52

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 999
        color: sliderArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.3) : Colors.surfaceVariant
        border.width: 1
        border.color: sliderArea.containsMouse ? Colors.border : Qt.lighter(Colors.surfaceVariant, 1.6)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: fill
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: parent.width * Math.max(0, Math.min(1, root.value / 100))
        radius: 999
            color: Colors.fillStrong

            // Animate external/wheel changes, but track the cursor 1:1 while dragging
            Behavior on width {
                enabled: !sliderArea.pressed
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            color: fill.width > x + implicitWidth ? Colors.fillStrongText : Colors.primaryText
            z: 1

            Behavior on color { ColorAnimation { duration: 80 } }
        }

        Text {
            anchors {
                right: parent.right
                rightMargin: 14
                verticalCenter: parent.verticalCenter
            }
            text: root.value + "%"
            font.family: "Poppins"
                font.italic: false
            font.pixelSize: 13
            color: fill.width > parent.width - x ? Colors.fillStrongText : Colors.secondaryText
            z: 1

            Behavior on color { ColorAnimation { duration: 80 } }
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
