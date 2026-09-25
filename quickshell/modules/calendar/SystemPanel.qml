pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// System monitor tab: CPU and memory gauges plus load / swap / temp / cores.
Item {
    id: root

    readonly property int gap: 16

    function ringColor(frac) {
        if (frac >= 0.85) return "#e06c75"
        if (frac >= 0.6) return "#e5c07b"
        return Colors.chipIconActive
    }

    // ── Reusable circular gauge card ──
    component Gauge: Rectangle {
        id: g
        required property string label
        required property real frac        // 0..1, drives the ring
        required property string centerText
        property string subText: ""

        radius: 16
        color: Colors.chipBackground

        Text {
            id: gLabel
            anchors { top: parent.top; left: parent.left; margins: 18 }
            text: g.label
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 12
            font.weight: Font.SemiBold
        }

        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) - 90
            height: width

            Canvas {
                id: ring
                anchors.fill: parent
                antialiasing: true

                property real frac: g.frac
                property color barColor: root.ringColor(g.frac)
                property color trackColor: Colors.surfaceVariant

                onFracChanged: requestPaint()
                onBarColorChanged: requestPaint()
                Component.onCompleted: requestPaint()

                Behavior on frac { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const cx = width / 2, cy = height / 2, r = width / 2 - 8
                    ctx.lineWidth = 11
                    ctx.lineCap = "round"

                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.strokeStyle = ring.trackColor
                    ctx.stroke()

                    if (ring.frac > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, ring.frac))
                        ctx.strokeStyle = ring.barColor
                        ctx.stroke()
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: g.centerText
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.pixelSize: 34
                    font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: g.subText !== ""
                    text: g.subText
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 11
                }
            }
        }
    }

    // ── Reusable compact stat card ──
    component Stat: Rectangle {
        id: card
        required property string label
        required property string value
        property string accent: Colors.primaryText

        radius: 16
        color: Colors.chipBackground

        Column {
            anchors.centerIn: parent
            width: card.width - 24
            spacing: 3

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.value
                color: card.accent
                font.family: "Poppins"
                font.pixelSize: 24
                font.weight: Font.Bold
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: card.label
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    // Top: CPU + Memory gauges
    Item {
        id: gauges
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Math.round(root.height * 0.62)

        Gauge {
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            width: (parent.width - root.gap) / 2
            label: "CPU"
            frac: SystemStats.cpuPercent / 100
            centerText: SystemStats.cpuPercent + "%"
            subText: SystemStats.cores + " cores"
        }

        Gauge {
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            width: (parent.width - root.gap) / 2
            label: "Memory"
            frac: SystemStats.memPercent
            centerText: Math.round(SystemStats.memPercent * 100) + "%"
            subText: SystemStats.memUsedLabel + " / " + SystemStats.memTotalLabel + " GiB"
        }
    }

    // Bottom: load, swap, temperature
    Row {
        anchors {
            top: gauges.bottom
            topMargin: root.gap
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: root.gap

        Stat {
            width: (parent.width - 2 * root.gap) / 3
            height: parent.height
            label: "Load (1m)"
            value: SystemStats.load1.toFixed(2)
        }

        Stat {
            width: (parent.width - 2 * root.gap) / 3
            height: parent.height
            label: SystemStats.swapTotalKb > 0
                ? "Swap " + SystemStats.swapUsedLabel + " / " + SystemStats.swapTotalLabel + " GiB"
                : "Swap"
            value: SystemStats.swapTotalKb > 0 ? Math.round(SystemStats.swapPercent * 100) + "%" : "off"
            accent: root.ringColor(SystemStats.swapPercent)
        }

        Stat {
            width: (parent.width - 2 * root.gap) / 3
            height: parent.height
            label: "Temperature"
            value: SystemStats.tempC > 0 ? Math.round(SystemStats.tempC) + "°C" : "--"
            accent: root.ringColor(Math.max(0, (SystemStats.tempC - 40) / 50))
        }
    }
}
