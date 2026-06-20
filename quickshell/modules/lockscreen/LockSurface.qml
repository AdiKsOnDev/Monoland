pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.calendar
import qs.modules.sidebar

WlSessionLockSurface {
    id: root

    property string password: ""
    property bool authFailed: false
    property bool authPending: false

    signal passwordEdited(string p)
    signal submitted()

    color: "black"

    readonly property string avatarPath: Quickshell.env("HOME") + "/.face"
    readonly property bool hasAvatar: avatarImage.status === Image.Ready

    property string weatherTemp: "—"
    property string weatherDesc: "Loading..."
    property string uptimeLabel: "—"

    // Translucent card with a hairline edge — matches the shell's surface language
    // while staying glassy over the blurred wallpaper.
    component GlassCard: Rectangle {
        color: Qt.rgba(1, 1, 1, 0.1)
        radius: 20
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
    }

    Process {
        id: weatherFetcher
        command: ["bash", "-c", "curl -sf 'wttr.in/?format=j1'"]
        running: true
        stdout: SplitParser {
            property string buffer: ""
            onRead: (line) => buffer += line
        }
        onRunningChanged: {
            if (running) { stdout.buffer = ""; return }
            try {
                const d = JSON.parse(stdout.buffer)
                const c = d.current_condition[0]
                root.weatherTemp = c.temp_C + "°C"
                root.weatherDesc = c.weatherDesc[0].value
            } catch (e) {
                root.weatherTemp = "—"
                root.weatherDesc = "Unavailable"
            }
        }
    }

    Process {
        id: uptimeFetcher
        command: ["bash", "-c", "cat /proc/uptime"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                const secs = Math.floor(parseFloat(line.split(" ")[0]))
                const h = Math.floor(secs / 3600)
                const m = Math.floor((secs % 3600) / 60)
                root.uptimeLabel = h > 0 ? h + "h " + m + "m" : m + "m"
            }
        }
    }

    Timer {
        interval: 600000
        repeat: true
        running: true
        onTriggered: weatherFetcher.running = true
    }

    // Blurred wallpaper background
    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.local/share/monoland/current"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.8
            blurMax: 64
            saturation: -0.3
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Central widget grid
    Item {
        id: widgetGrid
        width: 1300
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -40
        }
        height: leftColumn.implicitHeight

        // Left column
        Column {
            id: leftColumn
            width: 620
            anchors.left: parent.left
            spacing: 16

            // Profile + clock + notifications card
            GlassCard {
                width: parent.width
                height: 240

                Column {
                    id: profileColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 24
                        rightMargin: 24
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 12

                    Item {
                        width: parent.width
                        height: 52

                        Row {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 14

                            Rectangle {
                                width: 52
                                height: 52
                                radius: 999
                                color: Qt.rgba(1, 1, 1, 0.2)
                                clip: true
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: avatarImage
                                    anchors.fill: parent
                                    source: "file://" + root.avatarPath
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "A"
                                    color: "white"
                                    font.family: "Poppins"
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                    visible: !root.hasAvatar
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: Quickshell.env("USER")
                                    color: "white"
                                    font.family: "Poppins"
                                    font.pixelSize: 15
                                    font.weight: Font.SemiBold
                                }

                                Text {
                                    text: Qt.formatDate(clock.date, "dddd, MMMM d")
                                    color: Qt.rgba(1, 1, 1, 0.6)
                                    font.family: "Poppins"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Row {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰂚"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: Qt.rgba(1, 1, 1, 0.6)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Notifications.notifications.values.length
                                color: Qt.rgba(1, 1, 1, 0.6)
                                font.family: "Poppins"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }
                    }

                    Text {
                        text: Qt.formatTime(clock.date, "HH:mm")
                        color: "white"
                        font.family: "Poppins"
                        font.pixelSize: 72
                        font.weight: Font.Bold
                    }

                }
            }

            // Media card — full width
            MediaCard {
                width: parent.width
                height: 200
                radius: 20
                visible: Media.hasPlayer
            }

        }

        // Right column — calendar + stats
        Column {
            anchors {
                left: leftColumn.right
                leftMargin: 16
                right: parent.right
                top: leftColumn.top
            }
            spacing: 16

            // Calendar card
            GlassCard {
                width: parent.width
                height: leftColumn.implicitHeight - 90 - 16

                Calendar {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                cellSize: 46
                todaySize: 34
                }
            }

            // Stats row: weather + battery + uptime
            Row {
                width: parent.width
                spacing: 16

                // Weather
                GlassCard {
                    width: (parent.width - 32) / 3
                    height: 90

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰖙"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: weatherTemp
                                color: "white"
                                font.family: "Poppins"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            Text {
                                text: weatherDesc
                                color: Qt.rgba(1, 1, 1, 0.6)
                                font.family: "Poppins"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // Battery
                GlassCard {
                    width: (parent.width - 32) / 3
                    height: 90

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.isCharging ? "󰂄" : Battery.capacity >= 80 ? "󰁹" : Battery.capacity >= 60 ? "󰂀" : Battery.capacity >= 40 ? "󰁾" : Battery.capacity >= 20 ? "󰁼" : "󰁺"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            color: Battery.capacity <= 20 && !Battery.isCharging ? Qt.rgba(1, 0.4, 0.4, 1) : Qt.rgba(1, 1, 1, 0.7)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: Battery.capacity + "%"
                                color: "white"
                                font.family: "Poppins"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            Text {
                                text: Battery.isCharging ? "Charging" : "Battery"
                                color: Qt.rgba(1, 1, 1, 0.6)
                                font.family: "Poppins"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // Uptime
                GlassCard {
                    width: (parent.width - 32) / 3
                    height: 90

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰔚"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: uptimeLabel
                                color: "white"
                                font.family: "Poppins"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            Text {
                                text: "Uptime"
                                color: Qt.rgba(1, 1, 1, 0.6)
                                font.family: "Poppins"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }

    // Password input — below grid
    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: widgetGrid.bottom
            topMargin: 32
        }
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Incorrect password"
            color: Qt.rgba(1, 0.4, 0.4, 1)
            font.family: "Poppins"
            font.pixelSize: 13
            opacity: root.authFailed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Rectangle {
            id: inputPill
            width: 320
            height: 52
            radius: 999
            color: Qt.rgba(1, 1, 1, 0.15)
            border.color: root.authFailed
                ? Qt.rgba(1, 0.4, 0.4, 0.8)
                : passwordField.activeFocus ? Colors.chipIconActive : Qt.rgba(1, 1, 1, 0.2)
            border.width: 1.5

            Behavior on border.color { ColorAnimation { duration: 150 } }

            SequentialAnimation {
                running: root.authFailed
                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x - 10; duration: 50 }
                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x + 10; duration: 50 }
                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x - 8;  duration: 50 }
                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x + 8;  duration: 50 }
                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x;      duration: 50 }
            }

            Row {
                anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.authPending ? "󰔟" : "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: Qt.rgba(1, 1, 1, 0.6)
                }

                TextInput {
                    id: passwordField
                    width: parent.width - 50
                    anchors.verticalCenter: parent.verticalCenter
                    color: "white"
                    font.family: "Poppins"
                    font.pixelSize: 15
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    selectionColor: Qt.rgba(1, 1, 1, 0.3)
                    enabled: !root.authPending
                    focus: true

                    Text {
                        anchors.fill: parent
                        text: "Enter password..."
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font: parent.font
                        visible: parent.text.length === 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    onTextChanged: root.passwordEdited(text)
                    Keys.onReturnPressed: { if (text.length > 0) root.submitted() }
                    Keys.onEnterPressed:  { if (text.length > 0) root.submitted() }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: passwordField.forceActiveFocus()
    }
}
