pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.services
import qs.modules.common

PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false
    signal wallpaperPickerRequested()
    signal powerMenuRequested()

    // Start unmapped; toggle()/hideTimer manage visibility around the animation
    visible: false

    function toggle() {
        if (!isOpen) visible = true
        isOpen = !isOpen
    }

    // Right-click control panels (expand from the clicked toggle)
    property string activePanel: ""
    function openPanel(id, src) {
        const p = src.mapToItem(controlPanel, src.width / 2, src.height / 2)
        controlPanel.originX = p.x
        controlPanel.originY = p.y
        activePanel = id
    }
    function closePanel() { activePanel = "" }

    // Notifications grouped by app, with per-app expand state (Android-style)
    property var expandedApps: ({})
    function toggleGroup(app) {
        const m = Object.assign({}, expandedApps)
        m[app] = !m[app]
        expandedApps = m
    }
    readonly property var groupedNotifications: {
        const all = Notifications.notifications.values
        const map = {}
        const order = []
        for (let i = 0; i < all.length; i++) {
            const n = all[i]
            const key = n.appName || "Unknown"
            if (!map[key]) { map[key] = []; order.push(key) }
            map[key].push(n)
        }
        function at(n) {
            const t = Notifications.arrivalTimeFor(n.id)
            return t ? t.getTime() : 0
        }
        for (const k of order) map[k].sort((a, b) => at(b) - at(a))
        order.sort((a, b) => at(map[b][0]) - at(map[a][0]))
        return order.map(k => ({ app: k, items: map[k] }))
    }

    onIsOpenChanged: {
        if (isOpen) visible = true
        else { hideTimer.restart(); closePanel() }
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

    // Surface ends at the right band's inner edge (plus the 1px seam) so the
    // compositor clips the slide behind the band, regardless of stacking
    margins.right: Frame.thickness - 1

    exclusiveZone: -1
    color: "transparent"

    // Mask to a plain proxy (never a layered item — a layered item reports no
    // usable region to Quickshell, collapsing the window's input region).
    // Empty while closed so the sidebar's resting area stays click-through.
    mask: Region { item: root.isOpen ? maskProxy : emptyRegion }

    Item { id: emptyRegion; width: 0; height: 0 }

    Item {
        id: maskProxy
        x: plate.x
        y: plate.y
        width: plate.width
        height: plate.height
    }

    // Full-height slab carved out of the frame: attached to the bar above, the
    // right band, and the bottom band. Only the left edge is free, so that is
    // where the fillets go. Reveal animates the plate, fillets included.
    Item {
        id: plate

        readonly property int seam: 1

        x: root.screen.width - Frame.thickness - width + seam
        y: Frame.barHeight - seam
        width: 504
        height: parent.height - Frame.barHeight - Frame.thickness + 2 * seam

        // No shadow layer: the layered texture resamples at fractional scale
        // and shows a hairline along the edges. Flat matte matches the frame.

        // Shadow cast by the sidebar onto the workspace, continuous with the
        // frame's own shadow strips — without it, the frame shadow showing
        // through the fillet notches reads as a detached dark wedge. Drawn
        // first so the fillets and box paint over its inner edge; slides with
        // the plate.
        Rectangle {
            x: -Frame.shadowSize
            width: Frame.shadowSize
            height: plate.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.18) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
            }
        }

        Rectangle {
            id: sidebar

            anchors.fill: parent
            color: Frame.color
            clip: true

            // Notifications section (below media card)
            Item {
                id: notificationsSection
                anchors {
                    top: mediaCard.bottom
                    topMargin: 16
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                Item {
                    id: notifHeader
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: 16
                        rightMargin: 16
                    }
                    height: 44

                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 8

                        Text {
                            text: "Notifications"
                            color: Colors.primaryText
                            font.family: "Poppins"
                            font.italic: false
                            font.pixelSize: 13
                            font.weight: Font.SemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            visible: Notifications.notifications.values.length > 0
                            width: notifCountText.implicitWidth + 10
                            height: 18
                            radius: 999
                            color: Colors.surfaceVariant
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: notifCountText
                                anchors.centerIn: parent
                                text: Notifications.notifications.values.length
                                color: Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }
                    }

                    Rectangle {
                        id: clearAllBtn
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        visible: Notifications.notifications.values.length > 0
                        width: clearAllLabel.implicitWidth + 16
                        height: 28
                        radius: 999
                        color: clearAllHover.containsMouse ? Colors.surfaceVariant : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: clearAllLabel
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: clearAllHover.containsMouse ? Colors.primaryText : Colors.secondaryText
                            font.family: "Poppins"
                            font.italic: false
                            font.pixelSize: 12

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: clearAllHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.dismissAll()
                        }
                    }
                }

                ListView {
                    id: notifList
                    anchors {
                        top: notifHeader.bottom
                        topMargin: 8
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 16
                        rightMargin: 16
                        bottomMargin: 16
                    }
                    spacing: 8
                    clip: true
                    model: root.groupedNotifications

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                            NumberAnimation { property: "x"; from: 20; to: 0; duration: 280; easing.type: Easing.OutQuint }
                        }
                    }

                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
                            NumberAnimation { property: "x"; to: 28; duration: 200; easing.type: Easing.InCubic }
                        }
                    }

                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
                    }

                    delegate: NotificationGroup {
                        required property var modelData
                        width: notifList.width
                        app: modelData.app
                        items: modelData.items
                        expanded: root.expandedApps[modelData.app] ?? false
                        onToggleRequested: root.toggleGroup(modelData.app)
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: notifList.count === 0
                        spacing: 8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂚"
                            color: Colors.secondaryText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 32
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No notifications"
                            color: Colors.secondaryText
                            font.family: "Poppins"
                            font.italic: false
                            font.pixelSize: 13
                        }
                    }
                }
            }

            // Media player card
            MediaCard {
                id: mediaCard
                anchors {
                    top: controls.bottom
                    topMargin: Media.hasPlayer ? 16 : 0
                    left: parent.left
                    right: parent.right
                    leftMargin: 20
                    rightMargin: 20
                }
                height: Media.hasPlayer ? 200 : 0
                visible: Media.hasPlayer

                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }

            // Header: time/date on left, action buttons on right
            Item {
                id: sidebarHeader
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 20
                    leftMargin: 20
                    rightMargin: 20
                }
                height: 64

                Column {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    Text {
                        id: headerTime
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.italic: false
                        font.pixelSize: 32
                        font.weight: Font.Bold

                        Timer {
                            interval: 1000
                            repeat: true
                            running: true
                            triggeredOnStart: true
                            onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                    }

                    Text {
                        id: headerDate
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.italic: false
                        font.pixelSize: 12

                        Timer {
                            interval: 60000
                            repeat: true
                            running: true
                            triggeredOnStart: true
                            onTriggered: parent.text = Qt.formatDate(new Date(), "dddd, MMMM d")
                        }
                    }
                }

                Row {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 8

                    // Focus mode (Do Not Disturb) toggle
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 999
                        color: Notifications.doNotDisturb
                            ? Colors.fillStrong
                            : (focusHover.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.4) : Colors.surfaceVariant)
                        border.width: Notifications.doNotDisturb ? 0 : 1
                        border.color: Qt.lighter(Colors.surfaceVariant, 1.6)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: Notifications.doNotDisturb ? "󰂛" : "󰂚"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: Notifications.doNotDisturb ? Colors.fillStrongText : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: focusHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.doNotDisturb = !Notifications.doNotDisturb
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 999
                        color: settingsHover.containsMouse ? Colors.fillStrong : Colors.surfaceVariant
                        border.width: settingsHover.containsMouse ? 0 : 1
                        border.color: Qt.lighter(Colors.surfaceVariant, 1.6)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰏘"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: settingsHover.containsMouse ? Colors.fillStrongText : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: settingsHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wallpaperPickerRequested()
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 999
                        color: powerHover.containsMouse ? Colors.fillStrong : Colors.surfaceVariant
                        border.width: powerHover.containsMouse ? 0 : 1
                        border.color: Qt.lighter(Colors.surfaceVariant, 1.6)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                            color: powerHover.containsMouse ? Colors.fillStrongText : Colors.primaryText

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: powerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.powerMenuRequested()
                        }
                    }
                }
            }

            // Controls section (below header)
            Column {
                id: controls
                anchors {
                    top: sidebarHeader.bottom
                    left: parent.left
                    right: parent.right
                    margins: 20
                    topMargin: 16
                }
                spacing: 10

                // 2-column toggle grid
                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    ToggleButton {
                        id: wifiToggle
                        width: (parent.width - 8) / 2
                        height: 70
                        radius: 22
                        icon: Wifi.signalIcon
                        label: "Wi-Fi"
                        sublabel: Wifi.networkName !== "" ? Wifi.networkName : (Wifi.enabled ? "On" : "Off")
                        active: Wifi.enabled
                        onClicked: Wifi.toggle()
                        onExpandRequested: root.openPanel("wifi", wifiToggle)
                    }

                    ToggleButton {
                        id: btToggle
                        width: (parent.width - 8) / 2
                        height: 70
                        radius: 22
                        icon: Bluetooth.enabled ? "󰂯" : "󰂲"
                        label: "Bluetooth"
                        sublabel: Bluetooth.connectedDeviceName !== "" ? Bluetooth.connectedDeviceName : (Bluetooth.enabled ? "On" : "Off")
                        active: Bluetooth.enabled
                        onClicked: Bluetooth.toggle()
                        onExpandRequested: root.openPanel("bluetooth", btToggle)
                    }

                    ToggleButton {
                        id: volToggle
                        width: (parent.width - 8) / 2
                        height: 70
                        radius: 22
                        icon: Audio.muted ? "󰖁" : "󰕾"
                        label: "Volume"
                        sublabel: Audio.muted ? "Muted" : Audio.volumePercent + "%"
                        active: !Audio.muted
                        onExpandRequested: root.openPanel("volume", volToggle)
                        onClicked: Audio.toggleMute()
                    }

                    ToggleButton {
                        id: micToggle
                        width: (parent.width - 8) / 2
                        height: 70
                        radius: 22
                        icon: Audio.micMuted ? "󰍭" : "󰍬"
                        label: "Microphone"
                        sublabel: Audio.micMuted ? "Muted" : "Active"
                        active: !Audio.micMuted
                        onClicked: Audio.toggleMicMute()
                        onExpandRequested: root.openPanel("mic", micToggle)
                    }
                }

                // Sliders
                SliderRow {
                    icon: Audio.muted ? "󰖁" : "󰕾"
                    value: Audio.volumePercent
                    onMoved: (percent) => {
                        if (Audio.sink?.audio)
                            Audio.sink.audio.volume = percent / 100
                    }
                }

                SliderRow {
                    icon: "󰃞"
                    value: Brightness.brightnessPercent
                    onMoved: (percent) => Brightness.setBrightnessPercent(percent)
                }
            }

            // Right-click control panel (expands from the clicked toggle)
            ControlPanel {
                id: controlPanel
                anchors.fill: parent
                shown: root.activePanel !== ""
                title: root.activePanel === "wifi" ? "Wi-Fi"
                    : root.activePanel === "volume" ? "Volume"
                    : root.activePanel === "bluetooth" ? "Bluetooth"
                    : root.activePanel === "mic" ? "Microphone" : ""
                icon: root.activePanel === "wifi" ? "󰤨"
                    : root.activePanel === "volume" ? "󰕾"
                    : root.activePanel === "bluetooth" ? "󰂯"
                    : root.activePanel === "mic" ? "󰍬" : ""
                onClosed: root.closePanel()

                Loader {
                    anchors.fill: parent
                    active: root.activePanel !== ""
                    sourceComponent: root.activePanel === "wifi" ? wifiComp
                        : root.activePanel === "volume" ? volumeComp
                        : root.activePanel === "bluetooth" ? bluetoothComp
                        : root.activePanel === "mic" ? micComp : null
                }
            }

            Component { id: wifiComp; WifiPanel {} }
            Component { id: volumeComp; VolumePanel {} }
            Component { id: bluetoothComp; BluetoothPanel {} }
            Component { id: micComp; MicPanel {} }
        }

        // Fillets fusing the free left edge with the bar and the bottom band,
        // overlapped 1px into the plate to avoid AA seams
        ConcaveCorner {
            corner: "topRight"
            x: -radius + 1; y: 0
            radius: Frame.radius; color: Frame.color
        }
        ConcaveCorner {
            corner: "bottomRight"
            x: -radius + 1; y: plate.height - radius
            radius: Frame.radius; color: Frame.color
        }
    }

    Reveal {
        target: plate
        shown: root.isOpen
        motion: "emerge"
        edge: "right"
        squash: 0.92
        bulge: 1.0
        overshoot: 1.008
        distance: Frame.radius + 4
        inDuration: 320
        outDuration: 200
    }
}
