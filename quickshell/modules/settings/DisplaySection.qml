pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function brightnessIcon(percent) {
        if (percent >= 75) return "󰃠"
        if (percent >= 50) return "󰃝"
        if (percent >= 25) return "󰃟"
        return "󰃞"
    }

    Column {
        id: column
        width: root.width
        spacing: 16

        MdCard {
            width: column.width
            padding: 8

            MdListItem {
                width: parent.width
                icon: root.brightnessIcon(Brightness.brightnessPercent)
                iconColor: Md.primary
                headline: "Brightness"
                supporting: Brightness.brightnessPercent + "%"
                interactive: false
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
                    value: Brightness.brightnessPercent
                    onMoved: (percent) => Brightness.setBrightnessPercent(percent)
                }
            }
        }

        MdCard {
            width: column.width
            title: "Quick levels"
            padding: 8

            Item {
                width: parent.width
                height: 60

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        // brightnessctl is clamped to a 1% floor by the service,
                        // so there is no "off" preset to offer here
                        model: [10, 25, 50, 75, 100]

                        delegate: Rectangle {
                            id: preset
                            required property int modelData

                            width: 72
                            height: 40
                            radius: Md.cornerFull

                            readonly property bool current:
                                Math.abs(Brightness.brightnessPercent - preset.modelData) <= 2

                            color: preset.current ? Md.primary
                                : presetHover.containsMouse ? Md.surfaceContainerHighest
                                : Md.surfaceContainerHigh

                            Behavior on color { ColorAnimation { duration: Md.durMedium } }

                            Text {
                                anchors.centerIn: parent
                                text: preset.modelData + "%"
                                color: preset.current ? Md.textOnPrimary : Md.textOnSurface
                                font.family: Md.fontFamily
                                font.pixelSize: Md.labelLarge
                                font.weight: Font.Medium

                                Behavior on color { ColorAnimation { duration: Md.durMedium } }
                            }

                            MouseArea {
                                id: presetHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Brightness.setBrightnessPercent(preset.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
