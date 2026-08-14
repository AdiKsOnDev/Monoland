pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function volumeIcon(percent, muted) {
        if (muted) return "󰖁"
        if (percent > 66) return "󰕾"
        if (percent > 33) return "󰖀"
        if (percent > 0) return "󰕿"
        return "󰖁"
    }

    Column {
        id: column
        width: root.width
        spacing: 16

        // ── Master output ────────────────────────────────────────────────
        MdCard {
            width: column.width
            padding: 8

            MdListItem {
                width: parent.width
                icon: root.volumeIcon(Audio.volumePercent, Audio.muted)
                iconColor: Audio.muted ? Md.textOnSurfaceVariant : Md.primary
                headline: "Output volume"
                supporting: Audio.muted ? "Muted" : Audio.volumePercent + "%"
                interactive: false

                MdIconButton {
                    icon: Audio.muted ? "󰖁" : "󰕾"
                    toggled: Audio.muted
                    accent: Md.error
                    onClicked: Audio.toggleMute()
                }
            }

            Item {
                width: parent.width
                height: 48

                MdSlider {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    value: Audio.volumePercent
                    interactive: Audio.sink !== null
                    onMoved: (percent) => Audio.setVolumePercent(percent)
                }
            }
        }

        // ── Output device ────────────────────────────────────────────────
        MdCard {
            width: column.width
            title: "Output device"
            padding: 8

            Repeater {
                model: Audio.outputDevices

                delegate: MdListItem {
                    id: sinkItem
                    required property var modelData
                    width: column.width - 16

                    readonly property bool isCurrent: Audio.sink === sinkItem.modelData

                    icon: sinkItem.isCurrent ? "󰓃" : "󰓄"
                    iconColor: sinkItem.isCurrent ? Md.primary : Md.textOnSurfaceVariant
                    headline: Audio.deviceName(sinkItem.modelData)
                    supporting: sinkItem.isCurrent ? "Default output" : ""
                    selected: sinkItem.isCurrent
                    onClicked: Audio.setOutputDevice(sinkItem.modelData)

                    Text {
                        text: sinkItem.isCurrent ? "󰄬" : ""
                        font.family: Md.iconFamily
                        font.pixelSize: 16
                        color: Md.primary
                        visible: text !== ""
                    }
                }
            }

            Text {
                width: column.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: "No output devices"
                color: Md.textOnSurfaceVariant
                font.family: Md.fontFamily
                font.pixelSize: Md.bodyMedium
                topPadding: 16
                bottomPadding: 16
                visible: Audio.outputDevices.length === 0
            }
        }

        // ── Per-application mixer ────────────────────────────────────────
        MdCard {
            width: column.width
            title: "Applications"
            padding: 8

            Repeater {
                model: Audio.streams

                delegate: Column {
                    id: streamEntry
                    required property var modelData
                    width: column.width - 16
                    spacing: 0

                    readonly property int percent: Math.round((modelData.audio?.volume ?? 0) * 100)

                    MdListItem {
                        width: parent.width
                        icon: root.volumeIcon(streamEntry.percent, streamEntry.modelData.audio?.muted ?? false)
                        iconColor: (streamEntry.modelData.audio?.muted ?? false) ? Md.textOnSurfaceVariant : Md.primary
                        headline: Audio.appName(streamEntry.modelData)
                        supporting: (streamEntry.modelData.audio?.muted ?? false)
                            ? "Muted"
                            : streamEntry.percent + "%"
                        interactive: false

                        MdIconButton {
                            icon: (streamEntry.modelData.audio?.muted ?? false) ? "󰖁" : "󰕾"
                            toggled: streamEntry.modelData.audio?.muted ?? false
                            accent: Md.error
                            onClicked: {
                                if (streamEntry.modelData.audio)
                                    streamEntry.modelData.audio.muted = !streamEntry.modelData.audio.muted
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 44

                        MdSlider {
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: 16
                                rightMargin: 16
                                verticalCenter: parent.verticalCenter
                            }
                            value: streamEntry.percent
                            onMoved: (percent) => {
                                if (streamEntry.modelData.audio)
                                    streamEntry.modelData.audio.volume = percent / 100
                            }
                        }
                    }
                }
            }

            Text {
                width: column.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing is playing"
                color: Md.textOnSurfaceVariant
                font.family: Md.fontFamily
                font.pixelSize: Md.bodyMedium
                topPadding: 16
                bottomPadding: 16
                visible: Audio.streams.length === 0
            }
        }
    }
}
