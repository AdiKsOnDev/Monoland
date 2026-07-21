pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root
    anchors.fill: parent

    readonly property color phaseColor: DeepWork.onBreak
        ? Colors.accentFor(2)
        : Colors.chipIconActive

    function hoursLabel(secs) {
        const h = secs / 3600
        return (h >= 10 ? h.toFixed(0) : h.toFixed(1)) + "h"
    }

    // Small "label  [-] value [+]" stepper
    component Stepper: Item {
        id: st
        property string label: ""
        property int value: 0
        property int step: 5
        property int minimum: 5
        property int maximum: 180
        signal changed(int v)

        implicitHeight: 32

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: st.label
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 12
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6

            Rectangle {
                width: 24; height: 24; radius: 7
                anchors.verticalCenter: parent.verticalCenter
                color: decHover.containsMouse ? Colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰍴"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: Colors.primaryText
                }
                MouseArea {
                    id: decHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: st.changed(Math.max(st.minimum, st.value - st.step))
                }
            }

            Text {
                width: 46
                anchors.verticalCenter: parent.verticalCenter
                text: st.value + " min"
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 12
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                width: 24; height: 24; radius: 7
                anchors.verticalCenter: parent.verticalCenter
                color: incHover.containsMouse ? Colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐕"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: Colors.primaryText
                }
                MouseArea {
                    id: incHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: st.changed(Math.min(st.maximum, st.value + st.step))
                }
            }
        }
    }

    // ── Left: the timer ──
    Item {
        id: timerCol
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        width: Math.round(parent.width * 0.5) - 10

        Column {
            anchors.centerIn: parent
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: DeepWork.onBreak ? "Break" : (DeepWork.running ? "Deep work" : "Ready")
                color: root.phaseColor
                font.family: "Poppins"
                font.pixelSize: 14
                font.weight: Font.Bold

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 210
                height: 210

                Canvas {
                    id: ring
                    anchors.fill: parent
                    antialiasing: true

                    property real progress: DeepWork.onBreak ? DeepWork.breakProgress : DeepWork.intervalProgress
                    property color trackColor: Colors.surfaceVariant
                    property color barColor: root.phaseColor

                    onProgressChanged: requestPaint()
                    onTrackColorChanged: requestPaint()
                    onBarColorChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const cx = width / 2, cy = height / 2, r = width / 2 - 8
                        ctx.lineWidth = 10
                        ctx.lineCap = "round"

                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.strokeStyle = ring.trackColor
                        ctx.stroke()

                        if (ring.progress > 0) {
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * ring.progress)
                            ctx.strokeStyle = ring.barColor
                            ctx.stroke()
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: DeepWork.onBreak ? DeepWork.breakLabel : DeepWork.sessionLabel
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.pixelSize: DeepWork.onBreak ? 42 : 34
                        font.weight: Font.Bold
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: DeepWork.onBreak
                            ? "until back to work"
                            : "this session"
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.pixelSize: 11
                    }
                }
            }

            // Controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Rectangle {
                    width: 44; height: 44; radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: resetHover.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.4) : Colors.surfaceVariant
                    scale: resetHover.pressed ? 0.92 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Colors.primaryText
                    }
                    MouseArea {
                        id: resetHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DeepWork.reset()
                    }
                }

                Rectangle {
                    width: 60; height: 60; radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    color: playHover.pressed
                        ? Qt.darker(root.phaseColor, 1.15)
                        : (playHover.containsMouse ? Qt.lighter(root.phaseColor, 1.12) : root.phaseColor)
                    scale: playHover.pressed ? 0.94 : (playHover.containsMouse ? 1.05 : 1.0)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: DeepWork.running ? "󰏤" : "󰐊"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 24
                        color: Colors.background
                    }
                    MouseArea {
                        id: playHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DeepWork.toggle()
                    }
                }

                // Tick — bank this session into today
                Rectangle {
                    width: 44; height: 44; radius: 999
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: DeepWork.sessionSeconds > 0
                    opacity: enabled ? 1 : 0.4
                    color: tickHover.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.4) : Colors.surfaceVariant
                    scale: tickHover.pressed ? 0.92 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Colors.primaryText
                    }
                    MouseArea {
                        id: tickHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DeepWork.tick()
                    }
                }
            }

            // Config
            Column {
                width: 240
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Stepper {
                    width: parent.width
                    label: "Work for"
                    value: DeepWork.workInterval
                    step: 5
                    minimum: 5
                    onChanged: (v) => DeepWork.workInterval = v
                }

                Stepper {
                    width: parent.width
                    label: "Break for"
                    value: DeepWork.breakDuration
                    step: 1
                    minimum: 1
                    maximum: 60
                    onChanged: (v) => DeepWork.breakDuration = v
                }
            }
        }
    }

    // ── Right: the week ──
    Item {
        id: weekCol
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: Math.round(parent.width * 0.5) - 10

        readonly property int maxSecs: {
            let m = 1
            for (let i = 0; i < DeepWork.week.length; i++)
                m = Math.max(m, DeepWork.week[i].secs)
            return m
        }

        Text {
            id: weekTitle
            anchors { top: parent.top; left: parent.left }
            text: "This week"
            color: Colors.primaryText
            font.family: "Poppins"
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        Text {
            anchors { top: parent.top; right: parent.right }
            text: root.hoursLabel(DeepWork.weekSeconds) + " total"
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 12
        }

        // Bars
        Row {
            id: bars
            anchors {
                top: weekTitle.bottom
                topMargin: 20
                left: parent.left
                right: parent.right
            }
            height: 180
            spacing: 8

            Repeater {
                model: DeepWork.week

                Item {
                    id: dayCol
                    required property var modelData
                    width: (bars.width - 6 * bars.spacing) / 7
                    height: bars.height

                    readonly property real frac: dayCol.modelData.secs / weekCol.maxSecs

                    Text {
                        id: valLabel
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: bar.top; bottomMargin: 4 }
                        text: dayCol.modelData.secs > 0 ? root.hoursLabel(dayCol.modelData.secs) : ""
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        id: bar
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: dayLabel.top; bottomMargin: 8 }
                        width: parent.width - 6
                        height: Math.max(3, dayCol.frac * (parent.height - 46))
                        radius: 8
                        color: dayCol.modelData.isToday ? Colors.chipIconActive : Colors.surfaceVariant

                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        id: dayLabel
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        text: dayCol.modelData.label
                        color: dayCol.modelData.isToday ? Colors.primaryText : Colors.secondaryText
                        font.family: "Poppins"
                        font.pixelSize: 11
                        font.weight: dayCol.modelData.isToday ? Font.Bold : Font.Normal
                    }
                }
            }
        }

        // Today's banked total
        Column {
            anchors { top: bars.bottom; topMargin: 24; horizontalCenter: parent.horizontalCenter }
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.hoursLabel(DeepWork.todaySeconds)
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 34
                font.weight: Font.Bold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "banked today"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 11
            }
        }
    }
}
