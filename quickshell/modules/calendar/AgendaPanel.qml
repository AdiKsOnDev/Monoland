pragma ComponentBehavior: Bound

import QtQuick
import qs.services

Item {
    id: root

    function openAddField() {
        urlInput.visible = true
        urlField.text = ""
        urlField.forceActiveFocus()
    }

    function commitUrl() {
        const u = urlField.text.trim()
        if (u !== "") Agenda.addUrl(u)
        urlInput.visible = false
        urlField.text = ""
    }

    // Group upcoming events by day → [{ date, items: [...] }]
    readonly property var groups: {
        const evs = Agenda.events
        const map = {}
        const order = []
        for (let i = 0; i < evs.length; i++) {
            const e = evs[i]
            if (!map[e.date]) {
                map[e.date] = []
                order.push(e.date)
            }
            map[e.date].push(e)
        }
        return order.map(d => ({ date: d, items: map[d] }))
    }

    function dayLabel(iso) {
        const p = iso.split("-")
        const d = new Date(p[0], p[1] - 1, p[2])
        const today = new Date()
        today.setHours(0, 0, 0, 0)
        const diff = Math.round((d - today) / 86400000)
        if (diff === 0) return "Today"
        if (diff === 1) return "Tomorrow"
        return Qt.formatDate(d, "ddd, MMM d")
    }

    // Header
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 30

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Upcoming"
            color: Colors.primaryText
            font.family: "Poppins"
            font.pixelSize: 14
            font.weight: Font.Bold
        }

        // Add calendar-link button
        Rectangle {
            id: addBtn
            width: 26
            height: 26
            radius: 8
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            color: addHover.containsMouse ? Colors.surfaceVariant : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰐕"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: addHover.containsMouse ? Colors.primaryText : Colors.secondaryText

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: addHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openAddField()
            }
        }

        // Live / loading indicator
        Rectangle {
            anchors { right: addBtn.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            width: 7
            height: 7
            radius: 999
            visible: Agenda.configured
            color: Agenda.loading ? Colors.secondaryText : Colors.chipIconActive
            opacity: Agenda.loading ? 0.6 : 1.0
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    // Inline "paste calendar link" input
    Rectangle {
        id: urlInput
        anchors { top: header.bottom; topMargin: 6; left: parent.left; right: parent.right }
        height: visible ? 38 : 0
        visible: false
        color: Colors.surfaceVariant
        radius: 10
        clip: true

        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Row {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌹"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: Colors.secondaryText
            }

            TextInput {
                id: urlField
                width: parent.width - 28
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 12
                clip: true

                Text {
                    anchors.fill: parent
                    text: "Paste calendar link (.ics)…"
                    color: Colors.secondaryText
                    font: parent.font
                    visible: parent.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }

                Keys.onReturnPressed: root.commitUrl()
                Keys.onEscapePressed: {
                    urlInput.visible = false
                    urlField.text = ""
                }
            }
        }
    }

    // Event list
    Flickable {
        id: flick
        anchors {
            top: urlInput.visible ? urlInput.bottom : header.bottom
            topMargin: 4
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        contentHeight: listColumn.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: listColumn
            width: flick.width
            spacing: 14
            visible: root.groups.length > 0

            Repeater {
                model: root.groups

                Column {
                    id: dayGroup
                    required property var modelData
                    width: listColumn.width
                    spacing: 6

                    Text {
                        text: root.dayLabel(dayGroup.modelData.date)
                        color: Colors.secondaryText
                        font.family: "Poppins"
                        font.pixelSize: 11
                        font.weight: Font.SemiBold
                    }

                    Repeater {
                        model: dayGroup.modelData.items

                        Row {
                            id: eventRow
                            required property var modelData
                            width: dayGroup.width
                            spacing: 10

                            // Accent rail — colored by which calendar source the event came from
                            Rectangle {
                                width: 3
                                height: eventText.height
                                radius: 999
                                color: Colors.accentFor(eventRow.modelData.source)
                            }

                            // Time column
                            Text {
                                width: 46
                                anchors.verticalCenter: parent.verticalCenter
                                text: eventRow.modelData.allDay ? "all-day" : eventRow.modelData.time
                                color: Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignLeft
                            }

                            // Title + location
                            Column {
                                id: eventText
                                width: eventRow.width - 46 - 3 - 20
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: eventRow.modelData.title
                                    color: Colors.primaryText
                                    font.family: "Poppins"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: eventRow.modelData.location
                                    color: Colors.secondaryText
                                    font.family: "Poppins"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    visible: eventRow.modelData.location !== ""
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty state — configured but nothing upcoming
        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 8
            visible: Agenda.configured && root.groups.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰸗"
                color: Colors.secondaryText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 30
                opacity: 0.7
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Nothing coming up"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 13
            }
        }

        // Not-configured state — guide + button to connect a calendar
        Column {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 10
            visible: !Agenda.configured && !urlInput.visible

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰃭"
                color: Colors.secondaryText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 30
                opacity: 0.7
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Connect a calendar to see your agenda"
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 12
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: connectLabel.implicitWidth + 28
                height: 32
                radius: 999
                color: connectHover.containsMouse ? Colors.primaryText : Colors.surfaceVariant

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: connectLabel
                    anchors.centerIn: parent
                    text: "Add calendar link"
                    color: connectHover.containsMouse ? Colors.background : Colors.primaryText
                    font.family: "Poppins"
                    font.pixelSize: 12
                    font.weight: Font.Medium

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: connectHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openAddField()
                }
            }
        }
    }
}
