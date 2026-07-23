pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.services
import qs.modules.common

// Full-height wallpaper drawer carved out of the frame's left edge (mirror of
// the notification sidebar): attached to the bar above, the left band, and the
// bottom band, with fillets on the free right edge. Wallpapers scroll as a
// vertical strip of preview cards; click applies via set-wallpaper.sh.
PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false
    property bool lightMode: false

    // Start unmapped; open()/hideTimer manage visibility around the animation
    visible: false

    function open() {
        visible = true
        isOpen = true
        wallpaperScanner.running = true
        // Escape-to-close needs active focus on the plate
        plate.forceActiveFocus()
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

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Surface starts at the left band's inner edge (plus the 1px seam) so the
    // compositor clips the slide behind the band, regardless of stacking
    margins.left: Frame.thickness - 1

    exclusiveZone: -1
    color: "transparent"
    focusable: isOpen
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Fullscreen while open so outside clicks close the drawer
    mask: Region { item: isOpen ? catcher : emptyRegion }

    Item { id: emptyRegion; width: 0; height: 0 }

    Item {
        id: catcher
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    ListModel { id: wallpapers }

    // Full-height slab: attached to the bar above, the left band, and the
    // bottom band. Only the right edge is free — fillets and shadow go there.
    Item {
        id: plate

        readonly property int seam: 1

        x: 0
        y: Frame.barHeight - seam
        width: 380
        height: parent.height - Frame.barHeight - Frame.thickness + 2 * seam

        Keys.onEscapePressed: root.close()

        // Shadow cast onto the workspace from the free right edge, continuous
        // with the frame's own shadow strips (mirror of the sidebar's)
        Rectangle {
            x: plate.width
            width: Frame.shadowSize
            height: plate.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
                GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.18) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            id: panel

            anchors.fill: parent
            color: Frame.color
            clip: true

            // Header: title + light/dark toggle
            Item {
                id: header
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                    topMargin: 16 + plate.seam
                }
                height: 44

                Column {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 1

                    Text {
                        text: "Wallpapers"
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.italic: false
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    Text {
                        text: wallpapers.count + (wallpapers.count === 1 ? " image" : " images")
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.italic: false
                        font.pixelSize: 11
                    }
                }

                // Light/dark toggle pill
                Rectangle {
                    id: lightToggle
                    width: 92
                    height: 32
                    radius: 999
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    color: root.lightMode ? Colors.fillStrong : Colors.surfaceVariant

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.lightMode ? "󰖨" : "󰖔"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: root.lightMode ? Colors.fillStrongText : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.lightMode ? "Light" : "Dark"
                            font.family: "Poppins"
                            font.italic: false
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.lightMode ? Colors.fillStrongText : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lightMode = !root.lightMode
                    }
                }
            }

            // Scrolling strip of wallpaper cards
            ListView {
                id: wallList
                anchors {
                    top: header.bottom
                    topMargin: 12
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 16
                }
                clip: true
                spacing: 12

                model: wallpapers

                delegate: Item {
                    id: wallCard
                    required property string modelData

                    width: wallList.width
                    height: Math.round(width * 0.62)

                    readonly property bool isHovered: cardArea.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Colors.surfaceVariant
                        clip: true

                        scale: wallCard.isHovered ? 1.02 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + root.wallpaperDir + "/" + wallCard.modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            // Decode downsampled — these are full-size wallpapers
                            sourceSize.width: 760
                        }

                        // Name plate along the bottom of the card
                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 34
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: 10
                                    bottomMargin: 8
                                }
                                text: wallCard.modelData.replace(/\.[^.]+$/, "")
                                color: "white"
                                font.family: "Poppins"
                                font.italic: false
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }

                        // Hover: dim + apply badge
                        Rectangle {
                            anchors.fill: parent
                            color: wallCard.isHovered ? Qt.rgba(0, 0, 0, 0.35) : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 38
                                height: 38
                                radius: 999
                                color: Colors.chipIconActive
                                visible: wallCard.isHovered

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: Colors.background
                                }
                            }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                applyProcess.command = [
                                    Quickshell.env("HOME") + "/.local/share/bin/set-wallpaper.sh",
                                    root.wallpaperDir + "/" + wallCard.modelData,
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

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: wallpapers.count === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰋩"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 36
                        color: Colors.secondaryText
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No wallpapers found"
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.italic: false
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Text {
                        width: wallList.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Add images to " + root.wallpaperDir
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.italic: false
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        // Fillets fusing the free right edge with the bar and the bottom band,
        // overlapped 1px into the plate and the frame to avoid AA seams
        ConcaveCorner {
            corner: "topLeft"
            x: plate.width - 1; y: 0
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "bottomLeft"
            x: plate.width - 1; y: plate.height - radius
            radius: Frame.radius; color: Frame.color
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
        target: plate
        shown: root.isOpen
        motion: "emerge"
        edge: "left"
        squash: 0.92
        bulge: 1.0
        distance: Frame.radius + 4
        inDuration: 320
        outDuration: 200
    }
}
