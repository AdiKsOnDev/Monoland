pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import qs.services
import qs.modules.common

FloatingWindow {
    id: root

    property bool isOpen: false
    property bool lightMode: false

    function open() {
        visible = true
        isOpen = true
        wallpaperScanner.running = true
    }

    function close() {
        isOpen = false
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 340
        onTriggered: root.visible = false
    }

    visible: false
    title: "Wallpapers"
    implicitWidth: 900
    implicitHeight: 600

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var wallpapers: ListModel { id: wallpapers }

    Rectangle {
        id: content
        anchors.fill: parent

        // Subtle top-lit gradient for surface depth
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Colors.background, 1.4) }
            GradientStop { position: 1.0; color: Colors.background }
        }

        // Header
        Item {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 24
            }
            height: 56

            Column {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                spacing: 2

                Text {
                    text: "Wallpapers"
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                Text {
                    text: root.wallpaperDir
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 11
                }
            }

            Row {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                // Light/dark toggle pill
                Rectangle {
                    id: lightToggle
                    width: 110
                    height: 36
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.lightMode ? Colors.primaryText : Colors.surfaceVariant
                    border.width: root.lightMode ? 0 : 1
                    border.color: Qt.lighter(Colors.surfaceVariant, 1.6)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.lightMode ? "󰖨" : "󰖔"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: root.lightMode ? Colors.background : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.lightMode ? "Light" : "Dark"
                            font.family: "Poppins"
                            font.italic: false
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: root.lightMode ? Colors.background : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lightMode = !root.lightMode
                    }
                }

                // Close button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeHover.containsMouse ? Colors.surfaceVariant : "transparent"
                    scale: closeHover.containsMouse ? 1.08 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.secondaryText
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }

        // Divider
        Rectangle {
            id: divider
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                leftMargin: 24
                rightMargin: 24
            }
            height: 1
            color: Colors.surfaceVariant
        }

        // Wallpaper grid
        GridView {
            id: grid
            anchors {
                top: divider.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 24
                topMargin: 20
            }
            clip: true
            cellWidth: (width - 12) / 4
            cellHeight: cellWidth * 0.6

            model: wallpapers

            delegate: Item {
                required property string modelData
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    radius: 12
                    color: Colors.surfaceVariant
                    clip: true

                    readonly property bool isHovered: hoverArea.containsMouse

                    scale: isHovered ? 1.03 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Image {
                        anchors.fill: parent
                        source: "file://" + root.wallpaperDir + "/" + parent.parent.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }

                    // Hover overlay
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: parent.isHovered ? Qt.rgba(0, 0, 0, 0.45) : "transparent"
                        border.width: parent.isHovered ? 2 : 0
                        border.color: Colors.chipIconActive

                        Behavior on color { ColorAnimation { duration: 150 } }

                        // Filename label on hover
                        Text {
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                margins: 10
                            }
                            text: parent.parent.parent.modelData.replace(/\.[^.]+$/, "")
                            color: "white"
                            font.family: "Poppins"
                            font.italic: false
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            visible: parent.parent.isHovered
                        }

                        // Apply icon on hover
                        Rectangle {
                            anchors.centerIn: parent
                            width: 40
                            height: 40
                            radius: 999
                            color: Colors.chipIconActive
                            visible: parent.parent.isHovered

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: Colors.background
                            }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            applyProcess.command = [
                                Quickshell.env("HOME") + "/.local/share/bin/set-wallpaper.sh",
                                root.wallpaperDir + "/" + parent.parent.modelData,
                                root.lightMode ? "light" : "dark"
                            ]
                            applyProcess.running = true
                            root.close()
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 999
                    color: Colors.secondaryText
                    opacity: parent.active ? 0.6 : 0.2
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                background: Item {}
            }
        }

        // Empty state
        Column {
            anchors.centerIn: parent
            spacing: 10
            visible: wallpapers.count === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰋩"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 40
                color: Colors.secondaryText
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No wallpapers found"
                color: Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Add images to " + Quickshell.env("HOME") + "/Pictures/Wallpapers"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 12
            }
        }
    }

    Process {
        id: wallpaperScanner
        command: ["bash", "-c", "ls -1 '" + root.wallpaperDir + "' 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|bmp|gif)$'"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "")
                    wallpapers.append({ modelData: line.trim() })
            }
        }

        onRunningChanged: {
            if (running) wallpapers.clear()
        }
    }

    Process {
        id: applyProcess
        running: false
    }

    Reveal {
        target: content
        shown: root.isOpen
        motion: "rise"
        // Pure slide (no fade) needs a longer travel to read as motion
        distance: 36
    }
}
