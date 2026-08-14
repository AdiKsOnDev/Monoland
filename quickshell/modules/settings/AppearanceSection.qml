pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Flickable {
    id: root

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Rescan on open so images added since startup show up
    Component.onCompleted: Wallpapers.scan()

    readonly property var swatches: [
        { name: "Background", value: Colors.background },
        { name: "Text",       value: Colors.primaryText },
        { name: "Muted",      value: Colors.secondaryText },
        { name: "Accent",     value: Colors.chipIconActive },
    ]

    Column {
        id: column
        width: root.width
        spacing: 16

        MdCard {
            width: column.width
            title: "Palette"
            padding: 8

            Item {
                width: parent.width
                height: 84

                Row {
                    anchors.centerIn: parent
                    spacing: 14

                    Repeater {
                        model: root.swatches

                        delegate: Column {
                            id: sw
                            required property var modelData
                            spacing: 6

                            Rectangle {
                                width: 44
                                height: 44
                                radius: Md.cornerFull
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: sw.modelData.value
                                border.width: 1
                                border.color: Md.outlineVariant

                                Behavior on color { ColorAnimation { duration: Md.durMedium } }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: sw.modelData.name
                                color: Md.textOnSurfaceVariant
                                font.family: Md.fontFamily
                                font.pixelSize: Md.labelSmall
                            }
                        }
                    }

                    // Per-source accents, shown as a compact strip
                    Column {
                        spacing: 6

                        Row {
                            spacing: 6
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: Colors.accents

                                delegate: Rectangle {
                                    required property var modelData
                                    width: 20
                                    height: 44
                                    radius: Md.cornerS
                                    color: modelData
                                    border.width: 1
                                    border.color: Md.outlineVariant

                                    Behavior on color { ColorAnimation { duration: Md.durMedium } }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Colors.isLight ? "Accents · light" : "Accents · dark"
                            color: Md.textOnSurfaceVariant
                            font.family: Md.fontFamily
                            font.pixelSize: Md.labelSmall
                        }
                    }
                }
            }
        }

        MdCard {
            width: column.width
            title: "Wallpaper"
            padding: 8

            Grid {
                id: grid
                width: column.width - 16
                columns: 3
                spacing: 10

                readonly property int cellWidth:
                    Math.floor((width - spacing * (columns - 1)) / columns)

                Repeater {
                    model: Wallpapers.files

                    delegate: Rectangle {
                        id: card
                        required property var modelData

                        width: grid.cellWidth
                        height: Math.round(width * 0.62)
                        radius: Md.cornerM
                        color: Md.surfaceContainerHighest
                        clip: true

                        scale: cardHover.containsMouse ? 1.03 : 1.0

                        Behavior on scale { NumberAnimation { duration: Md.durShort; easing.type: Md.easingStandard } }

                        Image {
                            anchors.fill: parent
                            source: Wallpapers.urlFor(card.modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            // Decode downsampled — these are full-size wallpapers
                            sourceSize.width: 480
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 30
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: 8
                                    bottomMargin: 6
                                }
                                text: Wallpapers.displayName(card.modelData)
                                color: "white"
                                font.family: Md.fontFamily
                                font.pixelSize: Md.labelSmall
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cardHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.apply(card.modelData)
                        }
                    }
                }
            }

            Text {
                width: column.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: Wallpapers.scanning ? "Scanning…" : "No wallpapers in " + Wallpapers.dir
                color: Md.textOnSurfaceVariant
                font.family: Md.fontFamily
                font.pixelSize: Md.bodyMedium
                topPadding: 16
                bottomPadding: 16
                wrapMode: Text.Wrap
                visible: Wallpapers.files.length === 0
            }
        }
    }
}
