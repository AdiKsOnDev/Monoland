pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services

// One app's notifications. Collapsed: the latest as a normal card with an expand
// control. Expanded: a single block titled by the app, with every message listed
// underneath it.
Item {
    id: group

    required property string app
    required property var items
    required property bool expanded

    signal toggleRequested()

    readonly property bool grouped: items.length > 1
    readonly property var latest: items[0]
    readonly property bool showExpanded: grouped && expanded

    // Dismiss every notification in this group
    function clearGroup() {
        const copy = items.slice()
        for (let i = 0; i < copy.length; i++) copy[i].dismiss()
    }

    implicitWidth: parent ? parent.width : 0
    implicitHeight: showExpanded ? groupBlock.implicitHeight : collapsedCard.implicitHeight
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // Collapsed: latest notification as a normal card
    NotificationCard {
        id: collapsedCard
        anchors.top: parent.top
        width: parent.width
        notification: group.latest
        groupCount: group.grouped ? group.items.length : 0
        expanded: group.expanded
        enabled: !group.showExpanded
        opacity: group.showExpanded ? 0 : 1
        onExpandToggled: group.toggleRequested()
        onDismissed: group.clearGroup()

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Expanded: a single block titled by the app, listing every message
    Rectangle {
        id: groupBlock
        anchors.top: parent.top
        width: parent.width
        implicitHeight: blockCol.implicitHeight + 28
        radius: 16
        color: Colors.surfaceVariant
        border.width: 1
        border.color: Qt.lighter(Colors.surfaceVariant, 1.6)
        enabled: group.showExpanded
        opacity: group.showExpanded ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 150 } }

        // Swipe the whole section to clear the group
        MouseArea {
            id: blockSwipe
            anchors.fill: parent
            drag.target: groupBlock
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

            onReleased: {
                if (groupBlock.x > groupBlock.width * 0.35) group.clearGroup()
                else blockSnap.start()
            }
        }

        NumberAnimation {
            id: blockSnap
            target: groupBlock
            property: "x"
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }

        Column {
            id: blockCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
                topMargin: 14
            }
            spacing: 10

            // Header: app avatar + name + count + collapse chevron
            Item {
                width: parent.width
                height: 32

                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.chipBackground
                        clip: true

                        readonly property string headerIcon: group.latest ? Notifications.iconFor(group.latest) : ""

                        IconImage {
                            anchors { fill: parent; margins: 5 }
                            source: parent.headerIcon
                            visible: parent.headerIcon !== ""
                            smooth: true
                        }
                        Text {
                            anchors.centerIn: parent
                            text: group.app.length > 0 ? group.app[0].toUpperCase() : "?"
                            color: Colors.primaryText
                            font.family: "Poppins"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            visible: parent.headerIcon === ""
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: group.app
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: hCount.implicitWidth + 10
                        height: 16
                        radius: 999
                        color: Colors.chipBackground

                        Text {
                            id: hCount
                            anchors.centerIn: parent
                            text: group.items.length
                            color: Colors.secondaryText
                            font.family: "Poppins"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }
                    }
                }

                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 30
                    height: 30
                    radius: 999
                    color: collapseHover.containsMouse ? Colors.chipBackground : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅀"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.secondaryText
                        rotation: 180
                    }

                    MouseArea {
                        id: collapseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: group.toggleRequested()
                    }
                }
            }

            // Messages
            Repeater {
                model: group.items

                Item {
                    id: msgRow
                    required property var modelData
                    width: blockCol.width
                    implicitHeight: msgCol.implicitHeight

                    Column {
                        id: msgCol
                        anchors { left: parent.left; right: parent.right }
                        spacing: 1

                        Row {
                            spacing: 5

                            Text {
                                text: msgRow.modelData.summary !== "" ? msgRow.modelData.summary : msgRow.modelData.appName
                                color: Colors.primaryText
                                font.family: "Poppins"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "·"
                                color: Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 12
                                visible: msgRow.modelData.summary !== ""
                            }
                            Text {
                                text: {
                                    const a = Notifications.arrivalTimeFor(msgRow.modelData.id)
                                    if (!a) return "now"
                                    const m = Math.floor((new Date() - a) / 60000)
                                    if (m < 1) return "now"
                                    if (m < 60) return m + "m"
                                    const h = Math.floor(m / 60)
                                    return h < 24 ? h + "h" : Math.floor(h / 24) + "d"
                                }
                                color: Colors.secondaryText
                                font.family: "Poppins"
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            width: msgCol.width
                            text: msgRow.modelData.body
                            color: Colors.secondaryText
                            font.family: "Poppins"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }
                }
            }
        }
    }
}
