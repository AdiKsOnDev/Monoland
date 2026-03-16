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
        color: Qt.rgba(1, 1, 1, 0.2)
        anchors {
            right: parent.right
            rightMargin: 16
            bottom: progressBar.top
            bottomMargin: 10
        }
        scale: playPauseArea.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

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
            Behavior on color { ColorAnimation { duration: 150 } }

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
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.activePlayer?.next()
            }
        }

        Item {
            anchors {
                left: prevBtn.right
                right: nextBtn.left
                leftMargin: 12
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            height: 3
            visible: Media.activePlayer?.lengthSupported ?? false

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, 0.25)
                radius: 2
            }

            Rectangle {
                width: Media.activePlayer?.length > 0
                    ? parent.width * (progressTimer.position / Media.activePlayer.length)
                    : 0
                height: parent.height
                color: "white"
                radius: 2
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
