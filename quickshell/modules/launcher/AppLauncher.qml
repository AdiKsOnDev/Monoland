pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false
    property int selectedIndex: -1

    readonly property int columns: 4

    // color-typed so .r/.g/.b are available (Colors.primaryText is a string)
    readonly property color selectionTint: Qt.rgba(
        Qt.color(Colors.primaryText).r,
        Qt.color(Colors.primaryText).g,
        Qt.color(Colors.primaryText).b,
        0.3
    )

    function launchSelected() {
        if (selectedIndex < 0 || selectedIndex >= filteredApps.length) return
        const app = filteredApps[selectedIndex]
        if (!app) return
        launcher.command = ["gio", "launch", app.exec]
        launcher.running = true
        root.close()
    }

    function moveSelection(delta) {
        const count = filteredApps.length
        if (count <= 0) return
        if (selectedIndex < 0) {
            selectedIndex = delta > 0 ? 0 : count - 1
        } else {
            selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + delta))
        }
        appGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }

    function open() {
        visible = true
        isOpen = true
        selectedIndex = -1
        searchField.text = ""
        searchField.forceActiveFocus()
        appScanner.running = true
    }

    function close() {
        isOpen = false
        hideTimer.start()
    }

    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: -1
    color: "transparent"
    focusable: isOpen
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region { item: isOpen ? overlay : emptyRegion }

    Item { id: emptyRegion; width: 0; height: 0 }

    // Fullscreen click-catcher (no dim — the launcher grows from the frame's
    // bottom edge, caelestia-style). Also the input-mask source while open, so
    // outside clicks close it and exclusive keyboard focus stays reliable.
    Item {
        id: overlay
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Panel docked to the bottom frame band; fillets fuse it with the band
    Item {
        id: plate

        readonly property int seam: 1

        width: 640
        height: 520
        x: (root.screen.width - width) / 2
        y: root.screen.height - Frame.thickness - height + seam

        // No shadow layer: the layered texture resamples at fractional scale
        // and shows a hairline along the edges. Flat matte matches the frame.

        ConcaveCorner {
            corner: "bottomRight"
            x: -radius + 1; y: plate.height - plate.seam - radius
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "bottomLeft"
            x: plate.width - 1; y: plate.height - plate.seam - radius
            radius: Frame.radius; color: Frame.color
        }

        Rectangle {
            id: panel

            anchors.fill: parent
            color: Frame.color
            topLeftRadius: 20
            topRightRadius: 20
            bottomLeftRadius: 0
            bottomRightRadius: 0

            Rectangle {
                id: searchBar
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                    topMargin: 20
                }
                height: 48
                radius: 12
                color: Colors.surfaceVariant
                border.width: 1
                border.color: searchField.activeFocus ? Colors.border : Qt.lighter(Colors.surfaceVariant, 1.6)

                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Colors.secondaryText
                    }

                    TextInput {
                        id: searchField
                        width: parent.width - 38
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.pixelSize: 14
                        selectionColor: root.selectionTint
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Search apps..."
                            color: Colors.secondaryText
                            font: parent.font
                            visible: parent.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                        Keys.onUpPressed: root.moveSelection(-root.columns)
                        Keys.onDownPressed: root.moveSelection(root.columns)
                        Keys.onLeftPressed: root.moveSelection(-1)
                        Keys.onRightPressed: root.moveSelection(1)
                        onTextChanged: {
                            root.selectedIndex = -1
                            root.rebuildFiltered()
                        }
                    }
                }
            }

            GridView {
                id: appGrid
                anchors {
                    top: searchBar.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 20
                    topMargin: 14
                }
                clip: true
                cellWidth: (width - 8) / 4
                cellHeight: cellWidth
                model: root.filteredApps

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

                WheelHandler {
                    onWheel: (event) => {
                        appGrid.contentY = Math.max(
                            0,
                            Math.min(
                                appGrid.contentHeight - appGrid.height,
                                appGrid.contentY - event.angleDelta.y * 0.8
                            )
                        )
                    }
                }

                delegate: Item {
                    id: appTile
                    required property var modelData
                    required property int index
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    readonly property bool isSelected: root.selectedIndex === index

                    Rectangle {
                        anchors { fill: parent; margins: 4 }
                        radius: 14
                        color: appTile.isSelected
                            ? Colors.surfaceVariant
                            : tileHover.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.1) : "transparent"
                        border.width: appTile.isSelected ? 1.5 : 0
                        border.color: Colors.chipIconActive
                        scale: tileHover.pressed ? 0.94 : (tileHover.containsMouse ? 1.03 : 1.0)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            width: parent.width - 16

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 48
                                height: 48

                                IconImage {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: appTile.modelData.icon !== ""
                                        ? "file://" + appTile.modelData.icon
                                        : ""
                                    smooth: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: Colors.surfaceVariant
                                    visible: appIcon.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: appTile.modelData.name.length > 0
                                            ? appTile.modelData.name[0].toUpperCase()
                                            : "?"
                                        color: Colors.primaryText
                                        font.family: "Poppins"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: appTile.modelData.name
                                color: Colors.primaryText
                                font.family: "Poppins"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: tileHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = appTile.index
                                root.launchSelected()
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.filteredApps.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰀻"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 36
                        color: Colors.secondaryText
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: searchField.text.length > 0 ? "No apps found" : "Loading..."
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.pixelSize: 13
                    }
                }
            }
            }
    }

    property var allApps: []
    property var filteredApps: []

    function rebuildFiltered() {
        const query = searchField.text.toLowerCase().trim()
        filteredApps = allApps.filter(app =>
            query === "" || app.name.toLowerCase().includes(query)
        )
    }

    Timer {
        id: hideTimer
        interval: 300
        repeat: false
        onTriggered: root.visible = false
    }

    Process {
        id: appScanner
        command: [Quickshell.shellDir + "/scripts/list-apps.sh"]
        running: false

        stdout: SplitParser {
            property var buffer: []
            onRead: (line) => {
                const parts = line.split("\t")
                if (parts.length < 3) return
                const n = parts[0].trim()
                const i = parts[1].trim()
                const e = parts[2].trim()
                if (n && e) buffer.push({ "name": n, "icon": i, "exec": e })
            }
        }

        onRunningChanged: {
            if (running) {
                appScanner.stdout.buffer = []
                root.allApps = []
                root.filteredApps = []
                return
            }
            const entries = appScanner.stdout.buffer
            appScanner.stdout.buffer = []
            entries.sort((a, b) => {
                const aNoIcon = a.icon === ""
                const bNoIcon = b.icon === ""
                if (aNoIcon !== bNoIcon) return aNoIcon ? 1 : -1
                return a.name.localeCompare(b.name)
            })
            root.allApps = entries
            root.rebuildFiltered()
        }
    }

    Process { id: launcher }

    Reveal {
        target: plate
        shown: root.isOpen
        motion: "emerge"
        edge: "bottom"
        squash: 0.92
        bulge: 1.015
        distance: 14
        outDuration: 190
    }
}
