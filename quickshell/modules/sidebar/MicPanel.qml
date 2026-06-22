pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root
    anchors.fill: parent

    function appName(node) {
        return (node.properties && node.properties["application.name"])
            || node.description || node.name || "Application"
    }

    readonly property int sourceVol: Math.round((Audio.source?.audio?.volume ?? 0) * 100)

    Flickable {
        anchors.fill: parent
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 14

            Text {
                text: "Input"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 11
                font.weight: Font.SemiBold
            }

            SliderRow {
                width: col.width
                icon: Audio.micMuted ? "󰍭" : "󰍬"
                value: root.sourceVol
                onMoved: (percent) => {
                    if (Audio.source?.audio) {
                        Audio.source.audio.muted = false
                        Audio.source.audio.volume = percent / 100
                    }
                }
            }

            Text {
                text: "Recording"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 11
                font.weight: Font.SemiBold
                visible: Audio.inputStreams.length > 0
            }

            Repeater {
                model: Audio.inputStreams

                Column {
                    id: appEntry
                    required property var modelData
                    width: col.width
                    spacing: 2

                    Text {
                        text: root.appName(appEntry.modelData)
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    SliderRow {
                        width: appEntry.width
                        icon: appEntry.modelData.audio.muted ? "󰍭" : "󰍬"
                        value: Math.round((appEntry.modelData.audio.volume ?? 0) * 100)
                        onMoved: (percent) => {
                            if (appEntry.modelData.audio)
                                appEntry.modelData.audio.volume = percent / 100
                        }
                    }
                }
            }

            Text {
                width: col.width
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing is recording"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 12
                topPadding: 8
                visible: Audio.inputStreams.length === 0
            }
        }
    }
}
