pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// Full-cover panel that grows out of a source point (the clicked pill) and
// collapses back into it. Provides a header (back + title); children fill the
// content area below the header.
Item {
    id: panel

    property bool shown: false
    property string title: ""
    property string icon: ""
    // Expansion origin, in this panel's coordinate space (pill centre)
    property real originX: width / 2
    property real originY: height / 2

    signal closed()

    default property alias content: contentArea.data

    visible: opacity > 0.001
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    transform: Scale {
        origin.x: panel.originX
        origin.y: panel.originY
        xScale: panel.shown ? 1 : 0.12
        yScale: panel.shown ? 1 : 0.12

        Behavior on xScale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on yScale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Colors.background, 1.4) }
            GradientStop { position: 1.0; color: Colors.background }
        }
        border.width: 1
        border.color: Colors.surfaceVariant

        // Absorb clicks so they don't fall through to the sidebar beneath
        MouseArea { anchors.fill: parent }

        // Header
        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            anchors.margins: 16
            height: 36

            Rectangle {
                id: backBtn
                width: 36
                height: 36
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: backHover.containsMouse ? Colors.surfaceVariant : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: backHover.containsMouse ? Colors.primaryText : Colors.secondaryText

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: backHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.closed()
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 17
                    color: Colors.primaryText
                    visible: panel.icon !== ""
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.title
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
            }
        }

        // Content area
        Item {
            id: contentArea
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 16
                rightMargin: 16
                topMargin: 8
                bottomMargin: 16
            }
        }
    }
}
