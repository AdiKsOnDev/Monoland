pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import qs.services

PanelWindow {
    id: root

    required property var screen

    property bool isOpen: false
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

            Row {
                id: notifHeader
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    leftMargin: 16
                    rightMargin: 16
                }
                height: 36

                Text {
                    text: "Notifications"
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 13
                    font.weight: Font.SemiBold
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - clearAllBtn.implicitWidth
                }

                Text {
                    id: clearAllBtn
                    text: "Clear all"
                    color: clearAllHover.containsMouse ? Colors.primaryText : Colors.secondaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 150 } }

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
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180; easing.type: Easing.InCubic }
                        NumberAnimation { property: "x"; to: notifList.width; duration: 180; easing.type: Easing.InCubic }
                    }
                }

                displaced: Transition {
                    NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
                }

                delegate: NotificationCard {
                    required property var modelData
                    notification: modelData
                    width: notifList.width
                }

                Text {
                    anchors.centerIn: parent
                    visible: notifList.count === 0
                    text: "No notifications"
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 13
                }
            }
        }

        // Media player card (between controls and notifications)
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
            height: Media.hasPlayer ? 110 : 0
            radius: 10
            color: Colors.surfaceVariant
            visible: Media.hasPlayer
            clip: true

            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle {
                id: mediaArt
                width: 80
                height: 80
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                radius: 6
                visible: Media.trackArtUrl !== ""
                clip: true

                Image {
                    anchors.fill: parent
                    source: Media.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                }
            }

            Column {
                anchors {
                    left: Media.trackArtUrl !== "" ? mediaArt.right : parent.left
                    leftMargin: 14
                    right: mediaControls.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 0

                Text {
                    width: parent.width
                    text: Media.trackTitle
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: Media.trackArtist
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    visible: Media.trackArtist !== ""
                }

                Item {
                    width: parent.width
                    height: 4
                    visible: Media.activePlayer?.lengthSupported ?? false

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.border
                        radius: 2
                    }

                    Rectangle {
                        width: Media.activePlayer?.length > 0
                            ? parent.width * (mediaProgressTimer.position / Media.activePlayer.length)
                            : 0
                        height: parent.height
                        color: Colors.primaryText
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

            Row {
                id: mediaControls
                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒮"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: prevHover.containsMouse ? Colors.primaryText : Colors.secondaryText

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea { id: prevHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Media.activePlayer?.previous() }
                }

                Rectangle {
                    width: 42
                    height: 42
                    radius: 999
                    color: Colors.primaryText
                    anchors.verticalCenter: parent.verticalCenter
                    scale: playPauseArea.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: Media.isPlaying ? "󰏤" : "󰐊"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Colors.background
                    }

                    MouseArea { id: playPauseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Media.playPause() }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒭"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: nextHover.containsMouse ? Colors.primaryText : Colors.secondaryText

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea { id: nextHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Media.activePlayer?.next() }
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
                        onClicked: root.settingsRequested()
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
