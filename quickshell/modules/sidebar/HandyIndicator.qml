pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.services

Rectangle {
    id: root

    property string phase: "recording"
    property string elapsed: "00:00"
    property string hint: "Super + D to finish"
    property string message: ""
    property var levels: []
    readonly property bool recording: phase === "recording"
    readonly property bool failed: phase === "error"
    readonly property color mutedText: Qt.alpha(Colors.primaryText, 0.68)

    implicitWidth: 340
    implicitHeight: 126
    radius: 18
    color: Colors.background
    border.width: 1
    border.color: Colors.surfaceVariant

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.3)
        shadowBlur: 0.65
        shadowVerticalOffset: 6
        autoPaddingEnabled: true
    }

    Row {
        anchors { top: parent.top; left: parent.left; margins: 18 }
        spacing: 9

        Text {
            text: root.failed ? "󰀦" : "󰍬"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            color: root.recording ? Colors.chipIconActive : Colors.primaryText
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.recording ? "Listening" : root.failed ? "Check Handy"
                : root.phase === "starting" ? "Opening microphone" : "Transcribing"
            font.family: "Poppins"
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Colors.primaryText
        }
    }

    Text {
        anchors { top: parent.top; right: parent.right; margins: 19 }
        text: root.recording ? root.elapsed : "Handy"
        font.family: root.recording ? "JetBrains Mono" : "Poppins"
        font.pixelSize: 11
        color: root.mutedText
    }

    Item {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22; topMargin: 48 }
        height: 34

        Row {
            anchors.centerIn: parent
            height: 34
            spacing: 5
            visible: root.recording

            Repeater {
                model: 29

                Rectangle {
                    required property int index
                    readonly property int distance: Math.abs(index - 14)
                    readonly property real level: root.levels[distance] ?? 0
                    width: 4
                    height: 3 + 31 * level * (1 - distance / 21)
                    y: (34 - height) / 2
                    radius: 2
                    color: level > 0.03 ? Colors.primaryText : root.mutedText
                    opacity: 1 - distance / 24
                    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 7
            visible: !root.recording && !root.failed

            Repeater {
                model: 3

                Rectangle {
                    id: dot
                    required property int index
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Colors.primaryText
                    opacity: 0.3
                    SequentialAnimation on opacity {
                        running: root.visible && !root.recording && !root.failed
                        loops: Animation.Infinite
                        PauseAnimation { duration: 160 * dot.index }
                        NumberAnimation { to: 1; duration: 280; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.3; duration: 280; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 320 - 160 * dot.index }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width
            visible: root.failed
            text: root.message
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: "Poppins"
            font.pixelSize: 11
            color: Colors.primaryText
        }
    }

    Text {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 15 }
        text: root.recording ? root.hint : root.failed ? "See Handy for details"
            : root.phase === "starting" ? "Waiting for Handy" : "Keep your app focused"
        textFormat: Text.PlainText
        font.family: "Poppins"
        font.pixelSize: 10
        color: root.mutedText
    }
}
