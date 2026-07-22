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

    // Explicit assignment, not a binding: ListView adjusts currentIndex on
    // model changes, which would silently break a declarative binding
    onSelectedIndexChanged: appList.currentIndex = selectedIndex

    // Start unmapped; open()/hideTimer manage visibility around the animation
    visible: false

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
        appList.positionViewAtIndex(selectedIndex, ListView.Contain)
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

    // Surface ends at the bottom band's inner edge (plus the 1px seam) so the
    // compositor clips the slide behind the band, regardless of stacking
    margins.bottom: Frame.thickness - 1

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

    // Panel docked to the bottom frame band; fillets fuse it with the band.
    // Like caelestia's launcher, the panel height follows the result count —
    // it grows and shrinks out of the frame as you type.
    Item {
        id: plate

        readonly property int seam: 1
        // 20 search top margin + 48 search + 14 list top + 20 list bottom
        readonly property int chromeHeight: 102
        readonly property int itemHeight: 56
        readonly property int itemSpacing: 4
        readonly property int maxShown: 8
        readonly property int rowsShown: Math.max(1, Math.min(maxShown, root.filteredApps.length))

        width: 640
        height: chromeHeight + rowsShown * (itemHeight + itemSpacing) - itemSpacing
        x: (root.screen.width - width) / 2
        y: root.screen.height - Frame.thickness - height + seam

        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }

        // No shadow layer: the layered texture resamples at fractional scale
        // and shows a hairline along the edges. Flat matte matches the frame.

        // Fillets overlap 1px into the plate (x) AND 1px into the bottom band
        // (y reaches plate.height, whose last row lies inside the band) so
        // neither junction can show an AA hairline at fractional scale
        ConcaveCorner {
            corner: "bottomRight"
            x: -radius + 1; y: plate.height - radius
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "bottomLeft"
            x: plate.width - 1; y: plate.height - radius
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
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onDownPressed: root.moveSelection(1)
                        onTextChanged: root.rebuildFiltered()
                    }
                }
            }

            // Caelestia-style result list: icon + name + comment rows
            ListView {
                id: appList
                anchors {
                    top: searchBar.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 20
                    topMargin: 14
                }
                clip: true
                spacing: plate.itemSpacing

                // ScriptModel diffs values (unlike a plain array, which resets
                // the view), so add/remove/displaced transitions actually run
                // while typing
                model: ScriptModel { values: root.filteredApps }

                // Soft highlight that slides to the keyboard selection
                highlightFollowsCurrentItem: false
                highlight: Rectangle {
                    radius: 12
                    color: Colors.primaryText
                    opacity: 0.08
                    visible: root.selectedIndex >= 0
                    width: appList.width
                    height: plate.itemHeight
                    y: appList.currentItem?.y ?? 0

                    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                // Filter reflow: new rows fade in, removed ones fade out,
                // survivors slide to their new positions
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: 100 }
                }
                addDisplaced: Transition {
                    NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: 100 }
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

                WheelHandler {
                    onWheel: (event) => {
                        appList.contentY = Math.max(
                            0,
                            Math.min(
                                appList.contentHeight - appList.height,
                                appList.contentY - event.angleDelta.y * 0.8
                            )
                        )
                    }
                }

                delegate: Item {
                    id: appRow
                    required property var modelData
                    required property int index
                    width: appList.width
                    height: plate.itemHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        // Selection is shown by the sliding highlight; rows
                        // only react to hover
                        color: rowHover.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.1) : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        id: rowIcon
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        width: 36
                        height: 36

                        IconImage {
                            id: appIcon
                            anchors.fill: parent
                            source: appRow.modelData.icon !== ""
                                ? "file://" + appRow.modelData.icon
                                : ""
                            smooth: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Colors.surfaceVariant
                            visible: appIcon.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: appRow.modelData.name.length > 0
                                    ? appRow.modelData.name[0].toUpperCase()
                                    : "?"
                                color: Colors.primaryText
                                font.family: "Poppins"
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Column {
                        anchors {
                            left: rowIcon.right
                            leftMargin: 14
                            right: parent.right
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 1

                        Text {
                            width: parent.width
                            text: appRow.modelData.name
                            color: Colors.primaryText
                            font.family: "Poppins"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: appRow.modelData.comment !== "" ? appRow.modelData.comment : appRow.modelData.name
                            color: Colors.secondaryText
                            font.family: "Poppins"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = appRow.index
                            root.launchSelected()
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
        // Top result preselected so Return launches it immediately
        selectedIndex = filteredApps.length > 0 ? 0 : -1
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
                const c = parts.length > 3 ? parts[3].trim() : ""
                if (n && e) buffer.push({ "name": n, "icon": i, "exec": e, "comment": c })
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
        distance: Frame.radius + 4
        outDuration: 190
    }
}
