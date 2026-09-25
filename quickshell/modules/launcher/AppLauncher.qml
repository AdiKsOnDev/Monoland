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
    property string mode: "apps"

    readonly property var currentItems: mode === "clipboard" ? filteredClipboard : filteredApps
    readonly property bool _clipboardMonitoring: ClipboardHistory.running

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

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= currentItems.length) return
        const item = currentItems[selectedIndex]
        if (!item) return
        if (mode === "clipboard") {
            clipboardCopier.command = [clipboardScript, "copy", item.id]
            clipboardCopier.running = true
            root.close()
            return
        }
        launcher.command = ["gio", "launch", item.exec]
        launcher.running = true
        root.close()
    }

    function moveSelection(delta) {
        const count = currentItems.length
        if (count <= 0) return
        if (selectedIndex < 0) {
            selectedIndex = delta > 0 ? 0 : count - 1
        } else {
            selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + delta))
        }
        appList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function setMode(targetMode) {
        if (targetMode !== "apps" && targetMode !== "clipboard") return
        mode = targetMode
        selectedIndex = -1
        searchField.text = ""
        if (mode === "clipboard") {
            clipboardScanner.running = true
            return
        }
        appScanner.running = true
    }

    function open(targetMode) {
        hideTimer.stop()
        visible = true
        isOpen = true
        setMode(targetMode === "clipboard" ? "clipboard" : "apps")
        searchField.forceActiveFocus()
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
    // The panel height follows the result count — it grows and shrinks out of
    // the frame as you type.
    Item {
        id: plate

        readonly property int seam: 1
        // Mode tabs, search field, and list margins
        readonly property int chromeHeight: 146
        readonly property int itemHeight: 56
        readonly property int itemSpacing: 4
        readonly property int maxShown: 8
        // Empty state needs room for the centered icon + message, so reserve a
        // few rows' worth instead of collapsing to a single row.
        readonly property int rowsShown: root.currentItems.length === 0
            ? 3
            : Math.min(maxShown, root.currentItems.length)

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

            Row {
                id: modeTabs
                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: 16
                    leftMargin: 20
                }
                spacing: 6

                Repeater {
                    model: [
                        { key: "apps", icon: "󰀻", label: "Apps" },
                        { key: "clipboard", icon: "󰅌", label: "Clipboard" }
                    ]

                    Rectangle {
                        id: modeTab
                        required property var modelData
                        readonly property bool active: root.mode === modelData.key

                        width: tabLabel.implicitWidth + 34
                        height: 30
                        radius: 10
                        color: active ? Colors.fillStrong : (tabHover.containsMouse ? Colors.surfaceVariant : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            id: tabLabel
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: modeTab.modelData.icon
                                color: modeTab.active ? Colors.fillStrongText : Colors.secondaryText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                text: modeTab.modelData.label
                                color: modeTab.active ? Colors.fillStrongText : Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: tabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode(modeTab.modelData.key)
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 16
                    rightMargin: 20
                }
                width: clearLabel.implicitWidth + 22
                height: 30
                radius: 10
                visible: root.mode === "clipboard" && root.allClipboard.length > 0
                color: clearHover.containsMouse ? Colors.surfaceVariant : "transparent"

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear history"
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: clearHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clipboardClearer.running = true
                }
            }

            Rectangle {
                id: searchBar
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 20
                    topMargin: 58
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
                            text: root.mode === "clipboard" ? "Search clipboard history..." : "Search apps..."
                            color: Colors.secondaryText
                            font: parent.font
                            visible: parent.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                        }

                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: root.activateSelected()
                        Keys.onEnterPressed: root.activateSelected()
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onDownPressed: root.moveSelection(1)
                        Keys.onTabPressed: root.setMode(root.mode === "apps" ? "clipboard" : "apps")
                        Keys.onDeletePressed: root.deleteSelectedClipboardEntry()
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
                model: ScriptModel { values: root.currentItems }

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
                            source: root.mode === "apps" && appRow.modelData.icon !== ""
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
                                text: root.mode === "clipboard"
                                    ? "󰅌"
                                    : appRow.modelData.name.length > 0
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
                            rightMargin: root.mode === "clipboard" ? 50 : 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 1

                        Text {
                            width: parent.width
                            text: root.mode === "clipboard" ? appRow.modelData.preview : appRow.modelData.name
                            color: Colors.primaryText
                            font.family: "Poppins"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: root.mode === "clipboard"
                                ? "Clipboard entry"
                                : appRow.modelData.comment !== "" ? appRow.modelData.comment : appRow.modelData.name
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
                            root.activateSelected()
                        }
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        width: 32
                        height: 32
                        radius: 9
                        visible: root.mode === "clipboard" && rowHover.containsMouse
                        color: deleteHover.containsMouse ? Colors.surfaceVariant : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            color: Colors.secondaryText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: deleteHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                mouse.accepted = true
                                root.deleteClipboardEntry(appRow.modelData)
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.currentItems.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.mode === "clipboard" ? "󰅌" : "󰀻"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 36
                        color: Colors.secondaryText
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: searchField.text.length > 0
                            ? (root.mode === "clipboard" ? "No clipboard entries found" : "No apps found")
                            : (root.mode === "clipboard" ? "Clipboard history is empty" : "Loading...")
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
    property var allClipboard: []
    property var filteredClipboard: []

    readonly property string clipboardScript: Quickshell.shellDir + "/scripts/clipboard-manager.sh"

    function rebuildFiltered() {
        const query = searchField.text.toLowerCase().trim()
        if (mode === "clipboard") {
            filteredClipboard = allClipboard.filter(entry =>
                query === "" || entry.preview.toLowerCase().includes(query)
            )
            selectedIndex = filteredClipboard.length > 0 ? 0 : -1
            return
        }
        filteredApps = allApps.filter(app =>
            query === "" || app.name.toLowerCase().includes(query)
        )
        // Top result preselected so Return launches it immediately
        selectedIndex = filteredApps.length > 0 ? 0 : -1
    }

    function deleteClipboardEntry(entry) {
        if (!entry) return
        clipboardDeleter.command = [clipboardScript, "delete", entry.id, entry.preview]
        clipboardDeleter.running = true
    }

    function deleteSelectedClipboardEntry() {
        if (mode !== "clipboard") return
        if (selectedIndex < 0 || selectedIndex >= filteredClipboard.length) return
        deleteClipboardEntry(filteredClipboard[selectedIndex])
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

    Process {
        id: clipboardScanner
        command: [root.clipboardScript, "list"]
        running: false

        stdout: SplitParser {
            property var buffer: []
            onRead: (line) => {
                const separator = line.indexOf("\t")
                if (separator < 1) return
                const id = line.slice(0, separator).trim()
                const preview = line.slice(separator + 1).trim()
                if (id && preview) buffer.push({ "id": id, "preview": preview })
            }
        }

        onRunningChanged: {
            if (running) {
                clipboardScanner.stdout.buffer = []
                root.allClipboard = []
                root.filteredClipboard = []
                return
            }
            root.allClipboard = clipboardScanner.stdout.buffer
            clipboardScanner.stdout.buffer = []
            if (root.mode === "clipboard") root.rebuildFiltered()
        }
    }

    Process { id: clipboardCopier }

    Process {
        id: clipboardDeleter
        onRunningChanged: {
            if (!running && root.mode === "clipboard") clipboardScanner.running = true
        }
    }

    Process {
        id: clipboardClearer
        command: [root.clipboardScript, "clear"]
        onRunningChanged: {
            if (!running && root.mode === "clipboard") clipboardScanner.running = true
        }
    }

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
