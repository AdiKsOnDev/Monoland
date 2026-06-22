pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.services

Rectangle {
    id: root

    implicitHeight: 200
    radius: 16
    color: Colors.surfaceVariant
    clip: true
    // Hairline edge for depth (visible when there's no album art covering it)
    border.width: 1
    border.color: Qt.lighter(Colors.surfaceVariant, 1.6)
    layer.enabled: Media.trackArtUrl !== ""
    layer.effect: MultiEffect {
        maskEnabled: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        maskSource: ShaderEffectSource {
            sourceItem: Rectangle {
                width: root.width
                height: root.height
                radius: root.radius
                visible: false
            }
        }
    }

    Image {
        anchors.fill: parent
        source: Media.trackArtUrl
        fillMode: Image.PreserveAspectCrop
        visible: Media.trackArtUrl !== ""
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Media.trackArtUrl !== "" ? 0.55 : 0)
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Column {
        anchors {
            left: parent.left
            right: playPauseBtn.left
            bottom: progressBar.top
            leftMargin: 16
            rightMargin: 12
            bottomMargin: 12
        }
        spacing: 2

        Text {
            width: parent.width
            text: Media.trackTitle
            color: "white"
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 18
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: Media.trackArtist
            color: Qt.rgba(1, 1, 1, 0.75)
            font.family: "Poppins"
            font.italic: false
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
            visible: Media.trackArtist !== ""
        }
    }

    Rectangle {
        id: playPauseBtn
        width: 52
        height: 52
        radius: 999
        color: playPauseArea.pressed
            ? Qt.rgba(1, 1, 1, 0.32)
            : (playPauseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.2))
        anchors {
            right: parent.right
            rightMargin: 16
            bottom: progressBar.top
            bottomMargin: 10
        }
        scale: playPauseArea.pressed ? 0.92 : (playPauseArea.containsMouse ? 1.06 : 1.0)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: Media.isPlaying ? "󰏤" : "󰐊"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            color: "white"
        }

        MouseArea {
            id: playPauseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Media.playPause()
        }
    }

    Item {
        id: progressBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 14
        }
        height: 28

        Text {
            id: prevBtn
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: "󰒮"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: prevHover.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.6)
            scale: prevHover.containsMouse ? 1.15 : 1.0
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            MouseArea {
                id: prevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.activePlayer?.previous()
            }
        }

        Text {
            id: nextBtn
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: "󰒭"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: nextHover.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.6)
            scale: nextHover.containsMouse ? 1.15 : 1.0
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.activePlayer?.next()
            }
        }

        // Progress — slim version of the sidebar slider (split pills + playhead)
        Item {
            id: progressTrack
            anchors {
                left: prevBtn.right
                right: nextBtn.left
                leftMargin: 12
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            height: 16
            visible: Media.activePlayer?.lengthSupported ?? false

            readonly property real frac: (Media.activePlayer?.length > 0)
                ? Math.max(0, Math.min(1, progressTimer.position / Media.activePlayer.length))
                : 0
            readonly property int barH: 6
            readonly property int headW: 3
            readonly property int gap: 4
            readonly property real headX: frac * width

            // Elapsed
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: 0
                width: Math.max(0, progressTrack.headX - progressTrack.gap - progressTrack.headW / 2)
                height: progressTrack.barH
                radius: 3
                topRightRadius: 1
                bottomRightRadius: 1
                color: "white"
            }

            // Remaining
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.min(parent.width, progressTrack.headX + progressTrack.gap + progressTrack.headW / 2)
                width: Math.max(0, parent.width - x)
                height: progressTrack.barH
                radius: 3
                topLeftRadius: 1
                bottomLeftRadius: 1
                color: Qt.rgba(1, 1, 1, 0.28)
            }

            // Playhead
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: progressTrack.headW
                height: 14
                radius: 1
                color: "white"
                x: Math.max(0, Math.min(parent.width - width, progressTrack.headX - width / 2))
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (event) => {
                    const pos = (event.x / width) * Media.activePlayer.length
                    Media.activePlayer.position = pos
                    progressTimer.position = pos
                }
            }
        }
    }

    Timer {
        id: progressTimer
        property real position: Media.activePlayer?.position ?? 0
        interval: 1000
        repeat: true
        running: Media.isPlaying
        onTriggered: position = Media.activePlayer?.position ?? 0
    }
}
