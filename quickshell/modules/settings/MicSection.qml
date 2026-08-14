pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.modules.common

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Live input level, so "is my mic actually picking anything up" is
    // answerable without leaving the panel. Only monitored while visible.
    PwNodePeakMonitor {
        id: peakMonitor
        node: Audio.source
        enabled: root.visible && Audio.source !== null
    }

    Column {
        id: column
        width: root.width
        spacing: 16

        // ── Input level ──────────────────────────────────────────────────
        MdCard {
            width: column.width
            padding: 8

            MdListItem {
                width: parent.width
                icon: Audio.micMuted ? "󰍭" : "󰍬"
                iconColor: Audio.micMuted ? Md.textOnSurfaceVariant : Md.primary
                headline: "Input volume"
                supporting: Audio.micMuted ? "Muted" : Audio.micVolumePercent + "%"
                interactive: false

                MdIconButton {
                    icon: Audio.micMuted ? "󰍭" : "󰍬"
                    toggled: Audio.micMuted
                    accent: Md.error
                    onClicked: Audio.toggleMicMute()
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
                    value: Audio.micVolumePercent
                    interactive: Audio.source !== null
                    onMoved: (percent) => Audio.setMicVolumePercent(percent)
                }
            }

            // Level meter
            Item {
                width: parent.width
                height: 40

                Text {
                    id: meterLabel
                    anchors {
                        left: parent.left
                        leftMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Level"
                    color: Md.textOnSurfaceVariant
                    font.family: Md.fontFamily
                    font.pixelSize: Md.labelMedium
                }

                Rectangle {
                    id: meterTrack
                    anchors {
                        left: meterLabel.right
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    height: 8
                    radius: height / 2
                    color: Md.surfaceContainerHighest

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        // peak is linear 0..1; muted input still reports the
                        // raw signal, so zero it explicitly to match what the
                        // rest of the system hears.
                        width: parent.width * (Audio.micMuted ? 0 : Math.min(1, peakMonitor.peak))
                        color: Md.primary

                        Behavior on width { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }

        // ── Input device ─────────────────────────────────────────────────
        MdCard {
            width: column.width
            title: "Input device"
            padding: 8

            Repeater {
                model: Audio.inputDevices

                delegate: MdListItem {
                    id: srcItem
                    required property var modelData
                    width: column.width - 16

                    readonly property bool isCurrent: Audio.source === srcItem.modelData

                    icon: srcItem.isCurrent ? "󰍬" : "󰍮"
                    iconColor: srcItem.isCurrent ? Md.primary : Md.textOnSurfaceVariant
                    headline: Audio.deviceName(srcItem.modelData)
                    supporting: srcItem.isCurrent ? "Default input" : ""
                    selected: srcItem.isCurrent
                    onClicked: Audio.setInputDevice(srcItem.modelData)

                    Text {
                        text: srcItem.isCurrent ? "󰄬" : ""
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
                text: "No input devices"
                color: Md.textOnSurfaceVariant
                font.family: Md.fontFamily
                font.pixelSize: Md.bodyMedium
                topPadding: 16
                bottomPadding: 16
                visible: Audio.inputDevices.length === 0
            }
        }

        // ── Apps currently recording ─────────────────────────────────────
        MdCard {
            width: column.width
            title: "Recording"
            padding: 8

            Repeater {
                model: Audio.inputStreams

                delegate: Column {
                    id: capEntry
                    required property var modelData
                    width: column.width - 16
                    spacing: 0

                    readonly property int percent: Math.round((modelData.audio?.volume ?? 0) * 100)

                    MdListItem {
                        width: parent.width
                        icon: (capEntry.modelData.audio?.muted ?? false) ? "󰍭" : "󰍬"
                        iconColor: (capEntry.modelData.audio?.muted ?? false) ? Md.textOnSurfaceVariant : Md.primary
                        headline: Audio.appName(capEntry.modelData)
                        supporting: (capEntry.modelData.audio?.muted ?? false)
                            ? "Muted"
                            : capEntry.percent + "%"
                        interactive: false

                        MdIconButton {
                            icon: (capEntry.modelData.audio?.muted ?? false) ? "󰍭" : "󰍬"
                            toggled: capEntry.modelData.audio?.muted ?? false
                            accent: Md.error
                            onClicked: {
                                if (capEntry.modelData.audio)
                                    capEntry.modelData.audio.muted = !capEntry.modelData.audio.muted
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
                            value: capEntry.percent
                            onMoved: (percent) => {
                                if (capEntry.modelData.audio)
                                    capEntry.modelData.audio.volume = percent / 100
                            }
                        }
                    }
                }
            }

            Text {
                width: column.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: "Nothing is recording"
                color: Md.textOnSurfaceVariant
                font.family: Md.fontFamily
                font.pixelSize: Md.bodyMedium
                topPadding: 16
                bottomPadding: 16
                visible: Audio.inputStreams.length === 0
            }
        }
    }
}
