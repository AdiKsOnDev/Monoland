pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// Shows the current or next upcoming event from the connected calendar(s).
// Events have no end time in the feed, so an all-day event counts through the
// day and a timed event is treated as "ongoing" for an hour after it starts.
Item {
    id: root

    implicitHeight: content.implicitHeight

    // Re-evaluate the relative labels / selected event over time
    property int nowTick: 0
    Timer { interval: 30000; repeat: true; running: true; onTriggered: root.nowTick++ }

    function parseStart(e) {
        return e.allDay ? new Date(e.date + "T00:00:00") : new Date(e.start)
    }

    readonly property var ev: {
        root.nowTick
        const now = Date.now()
        const evs = Agenda.events
        for (let i = 0; i < evs.length; i++) {
            const e = evs[i]
            const s = root.parseStart(e).getTime()
            const end = s + (e.allDay ? 86400000 : 3600000)
            if (end > now) return e
        }
        return null
    }

    readonly property bool ongoing: {
        root.nowTick
        return root.ev ? root.parseStart(root.ev).getTime() <= Date.now() : false
    }

    readonly property string relText: {
        root.nowTick
        const e = root.ev
        if (!e) return ""
        const now = new Date()
        const s = root.parseStart(e)
        if (s.getTime() <= now.getTime()) return "now"
        if (e.allDay) {
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate())
            const days = Math.round((new Date(e.date + "T00:00:00") - startOfDay) / 86400000)
            if (days <= 0) return "today"
            if (days === 1) return "tomorrow"
            return Qt.formatDate(s, "ddd")
        }
        const diffMin = Math.round((s - now) / 60000)
        if (diffMin < 60) return "in " + diffMin + "m"
        const diffH = Math.round(diffMin / 60)
        if (diffH < 24) return "in " + diffH + "h"
        return Qt.formatDate(s, "ddd")
    }

    Column {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        Text {
            text: root.ongoing ? "HAPPENING NOW" : "NEXT EVENT"
            color: root.ongoing ? Colors.chipIconActive : Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
        }

        // The event
        Item {
            width: parent.width
            implicitHeight: evCol.implicitHeight
            visible: root.ev !== null

            Rectangle {
                id: rail
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 4
                radius: 999
                color: root.ev ? Colors.accentFor(root.ev.source) : Colors.chipIconActive
            }

            Text {
                id: relLabel
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: root.relText
                color: root.ongoing ? Colors.chipIconActive : Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Column {
                id: evCol
                anchors {
                    left: rail.right
                    leftMargin: 12
                    right: relLabel.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 2

                Text {
                    width: parent.width
                    text: root.ev ? root.ev.title : ""
                    color: Colors.primaryText
                    font.family: "Poppins"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: {
                        if (!root.ev) return ""
                        const t = root.ev.allDay ? "All day" : root.ev.time
                        return root.ev.location !== "" ? t + "  ·  " + root.ev.location : t
                    }
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        // Empty / unconfigured state
        Text {
            visible: root.ev === null
            text: Agenda.configured ? "Nothing scheduled" : "No calendar connected"
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 13
        }
    }
}
