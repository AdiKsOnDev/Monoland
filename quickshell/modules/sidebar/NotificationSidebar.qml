pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.services

PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false
    signal wallpaperPickerRequested()

    function toggle() {
        if (!isOpen) visible = true
        isOpen = !isOpen
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property int barHeight: 44
    readonly property int barRightEdge: screen.width

    exclusiveZone: -1
    color: "transparent"

    mask: Region { item: sidebar }

    Rectangle {
        id: sidebar

        readonly property int sidebarWidth: 504

        readonly property int margin: 16

        x: root.isOpen ? root.barRightEdge - sidebarWidth - margin : root.barRightEdge
        y: root.barHeight + margin
        width: sidebarWidth
        height: parent.height - root.barHeight - margin * 2
        radius: 16
        clip: true
        color: Colors.background

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        onXChanged: {
            if (!root.isOpen && x >= root.barRightEdge)
                root.visible = false
        }


        Timer {
            id: mediaProgressTimer
            property real position: Media.activePlayer?.position ?? 0
            interval: 1000
            repeat: true
            running: Media.isPlaying
            onTriggered: position += 1
            onRunningChanged: if (running) position = Media.activePlayer?.position ?? 0
        }

        Connections {
            target: Media.activePlayer
            function onPositionChanged() { mediaProgressTimer.position = Media.activePlayer.position }
        }

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
                        visible: notifList.count > 0
                        width: notifCountText.implicitWidth + 10
                        height: 18
                        radius: 999
                        color: Colors.surfaceVariant
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: notifCountText
                            anchors.centerIn: parent
                            text: notifList.count
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
                    visible: notifList.count > 0
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
                model: Notifications.notifications

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "x"; from: notifList.width; to: 0; duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                remove: Transition {
                    NumberAnimation { property: "x"; to: notifList.width * 1.5; duration: 250; easing.type: Easing.OutCubic }
                }

                displaced: Transition {
                    NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
                }

                delegate: NotificationCard {
                    required property var modelData
                    notification: modelData
                    width: notifList.width
                    onDismissed: modelData.dismiss()
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
        Rectangle {
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
            radius: 16
            color: Colors.surfaceVariant
            visible: Media.hasPlayer
            clip: true
            layer.enabled: true

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Album art as full card background
            Image {
                id: mediaArtImage
                anchors.fill: parent
                source: Media.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: Media.trackArtUrl !== ""
                smooth: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: mediaArtImage.width
                            height: mediaArtImage.height
                            radius: mediaCard.radius
                        }
                    }
                }
            }

            // Dark scrim over art so text stays readable
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, Media.trackArtUrl !== "" ? 0.55 : 0)

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Track info — bottom left
            Column {
                anchors {
                    left: parent.left
                    right: playPauseBtn.left
                    bottom: progressBar.top
                    leftMargin: 16
                    rightMargin: 12
                    bottomMargin: 12
                }
                spacing: 2

                Text {
                    width: parent.width
                    text: Media.trackTitle
                    color: "white"
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: Media.trackArtist
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    visible: Media.trackArtist !== ""
                }
            }

            // Play/pause — bottom right, above progress bar
            Rectangle {
                id: playPauseBtn
                width: 52
                height: 52
                radius: 999
                color: Qt.rgba(1, 1, 1, 0.2)
                anchors {
                    right: parent.right
                    rightMargin: 16
                    bottom: progressBar.top
                    bottomMargin: 10
                }
                scale: playPauseArea.pressed ? 0.92 : 1.0

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: Media.isPlaying ? "󰏤" : "󰐊"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: "white"
                }

                MouseArea {
                    id: playPauseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.playPause()
                }
            }

            // Progress bar + prev/next row at the bottom
            Item {
                id: progressBar
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 14
                }
                height: 28

                // Prev
                Text {
                    id: prevBtn
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: "󰒮"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: prevHover.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.6)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: prevHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.activePlayer?.previous()
                    }
                }

                // Next
                Text {
                    id: nextBtn
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: "󰒭"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: nextHover.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.6)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: nextHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.activePlayer?.next()
                    }
                }

                // Seek bar between prev and next
                Item {
                    anchors {
                        left: prevBtn.right
                        right: nextBtn.left
                        leftMargin: 12
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    height: 3
                    visible: Media.activePlayer?.lengthSupported ?? false

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, 0.25)
                        radius: 2
                    }

                    Rectangle {
                        width: Media.activePlayer?.length > 0
                            ? parent.width * (mediaProgressTimer.position / Media.activePlayer.length)
                            : 0
                        height: parent.height
                        color: "white"
                        radius: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (event) => {
                            const pos = (event.x / width) * Media.activePlayer.length
                            Media.activePlayer.position = pos
                            mediaProgressTimer.position = pos
                        }
                    }
                }
            }
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

                Rectangle {
                    width: 40
                    height: 40
                    radius: 999
                    color: settingsHover.containsMouse ? Colors.primaryText : Colors.surfaceVariant

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰏘"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: settingsHover.containsMouse ? Colors.background : Colors.primaryText

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
                    color: powerHover.containsMouse ? Colors.primaryText : Colors.surfaceVariant

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: powerHover.containsMouse ? Colors.background : Colors.primaryText

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: powerHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {}
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
                margins: 16
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
                    width: (parent.width - 8) / 2
                    height: 70
                    radius: 999
                    icon: Wifi.enabled ? "󰤨" : "󰤭"
                    label: "Wi-Fi"
                    sublabel: Wifi.networkName !== "" ? Wifi.networkName : (Wifi.enabled ? "On" : "Off")
                    active: Wifi.enabled
                    onClicked: Wifi.toggle()
                }

                ToggleButton {
                    width: (parent.width - 8) / 2
                    height: 70
                    radius: 999
                    icon: Bluetooth.enabled ? "󰂯" : "󰂲"
                    label: "Bluetooth"
                    sublabel: Bluetooth.connectedDeviceName !== "" ? Bluetooth.connectedDeviceName : (Bluetooth.enabled ? "On" : "Off")
                    active: Bluetooth.enabled
                    onClicked: Bluetooth.toggle()
                }

                ToggleButton {
                    width: (parent.width - 8) / 2
                    height: 70
                    radius: 999
                    icon: Audio.muted ? "󰖁" : "󰕾"
                    label: "Volume"
                    sublabel: Audio.muted ? "Muted" : Audio.volumePercent + "%"
                    active: !Audio.muted
                    onClicked: Audio.toggleMute()
                }

                ToggleButton {
                    width: (parent.width - 8) / 2
                    height: 70
                    radius: 999
                    icon: Audio.micMuted ? "󰍭" : "󰍬"
                    label: "Microphone"
                    sublabel: Audio.micMuted ? "Muted" : "Active"
                    active: !Audio.micMuted
                    onClicked: Audio.toggleMicMute()
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
    }
}
