pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.services

Rectangle {
    id: root

    required property Notification notification

    // When >1, an inline expand chevron (+ count) is shown on the right
    property int groupCount: 0
    property bool expanded: false

    signal dismissed()
    signal expandToggled()

    readonly property string title: notification.summary !== "" ? notification.summary : notification.appName
    readonly property string body: notification.body
    readonly property bool hasImage: notification.image !== ""
    readonly property bool hasAppIcon: notification.appIcon !== ""

    implicitWidth: parent?.width ?? 0
    implicitHeight: Math.max(avatar.height, textCol.implicitHeight) + 28
    color: hoverArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.18) : Colors.surfaceVariant
    radius: 16
    clip: true
    border.width: 1
    border.color: hoverArea.containsMouse ? Colors.border : Qt.lighter(Colors.surfaceVariant, 1.6)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    MouseArea {
        id: swipeArea
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAxis
        drag.minimumX: 0
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onReleased: {
            if (root.x > root.width * 0.35)
                root.dismissed()
            else
                snapBack.start()
        }
    }

    NumberAnimation {
        id: snapBack
        target: root
        property: "x"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
    }

    // Circular avatar (contact / notification image) with a small app badge
    Item {
        id: avatar
        width: 44
        height: 44
        anchors {
            left: parent.left
            leftMargin: 16
            verticalCenter: parent.verticalCenter
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.chipBackground
            clip: true

            Image {
                anchors.fill: parent
                source: root.hasImage ? root.notification.image : ""
                visible: root.hasImage
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
            IconImage {
                anchors.fill: parent
                anchors.margins: 6
                source: !root.hasImage && root.hasAppIcon ? root.notification.appIcon : ""
                visible: !root.hasImage && root.hasAppIcon
                smooth: true
            }
            Text {
                anchors.centerIn: parent
                text: root.title.length > 0 ? root.title[0].toUpperCase() : "?"
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 18
                font.weight: Font.Bold
                visible: !root.hasImage && !root.hasAppIcon
            }
        }

        // App badge — only when the avatar is a contact image and an app icon also exists
        Rectangle {
            visible: root.hasImage && root.hasAppIcon
            width: 18
            height: 18
            radius: width / 2
            anchors { right: parent.right; bottom: parent.bottom }
            color: Colors.surfaceVariant

            IconImage {
                anchors { fill: parent; margins: 2 }
                source: root.notification.appIcon
                smooth: true
            }
        }
    }

    Column {
        id: textCol
        anchors {
            left: avatar.right
            leftMargin: 12
            right: expandBtn.visible ? expandBtn.left : parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        spacing: 3

        // Title · time · bell
        Item {
            width: parent.width
            height: titleText.implicitHeight

            Text {
                id: titleText
                anchors.left: parent.left
                text: root.title
                color: Colors.primaryText
                font.family: "Poppins"
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
                width: Math.max(0, Math.min(implicitWidth, parent.width - metaRow.width - 6))
            }

            Row {
                id: metaRow
                anchors { left: titleText.right; leftMargin: 6; verticalCenter: titleText.verticalCenter }
                spacing: 5

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "·"
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 12
                }
                Text {
                    id: timeText
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const arrived = Notifications.arrivalTimeFor(root.notification.id)
                        if (!arrived) return "now"
                        const m = Math.floor((new Date() - arrived) / 60000)
                        if (m < 1) return "now"
                        if (m < 60) return m + "m"
                        const h = Math.floor(m / 60)
                        if (h < 24) return h + "h"
                        return Math.floor(h / 24) + "d"
                    }
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 12

                    Timer {
                        interval: 60000
                        repeat: true
                        running: true
                        onTriggered: parent.text = parent.text
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰂚"
                    color: Colors.secondaryText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }

        Text {
            width: parent.width
            text: root.body
            color: Colors.secondaryText
            font.family: "Poppins"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            visible: text !== ""
        }
    }

    // Expand chevron (+ count) for grouped notifications
    Item {
        id: expandBtn
        visible: root.groupCount > 1
        width: 40
        anchors {
            right: parent.right
            rightMargin: 8
            top: parent.top
            bottom: parent.bottom
        }

        Rectangle {
            anchors.centerIn: parent
            width: chevronRow.implicitWidth + 14
            height: 30
            radius: 999
            color: expandHover.containsMouse ? Colors.chipBackground : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                id: chevronRow
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.groupCount
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰅀"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: Colors.secondaryText
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }
        }

        MouseArea {
            id: expandHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandToggled()
        }
    }
}
