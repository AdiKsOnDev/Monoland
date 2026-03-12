pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.services

Rectangle {
    id: root

    required property Notification notification

    signal dismissed()

    implicitWidth: parent?.width ?? 0
    implicitHeight: cardColumn.implicitHeight + 24
    color: hoverArea.containsMouse ? Qt.lighter(Colors.surfaceVariant, 1.18) : Colors.surfaceVariant
    radius: 12
    clip: true

    Behavior on color { ColorAnimation { duration: 150 } }

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

    Column {
        id: cardColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 16
            topMargin: 14
        }
        spacing: 6

        Item {
            width: parent.width
            height: 20

            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                spacing: 8

                Rectangle {
                    id: appIcon
                    width: 20
                    height: 20
                    radius: 4
                    color: root.notification.image === "" && root.notification.appIcon === ""
                        ? Colors.chipBackground
                        : "transparent"
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: root.notification.image
                        visible: root.notification.image !== ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }

                    IconImage {
                        anchors.fill: parent
                        source: root.notification.appIcon
                        visible: root.notification.image === "" && root.notification.appIcon !== ""
                        smooth: true
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.notification.appName.length > 0
                            ? root.notification.appName[0].toUpperCase()
                            : "?"
                        color: Colors.primaryText
                        font.family: "Poppins"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        visible: root.notification.image === "" && root.notification.appIcon === ""
                    }
                }

                Text {
                    text: root.notification.appName
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: timestamp
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: {
                    const arrived = Notifications.arrivalTimeFor(root.notification.id)
                    if (!arrived) return ""
                    const diffMins = Math.floor((new Date() - arrived) / 60000)
                    if (diffMins < 1) return "now"
                    if (diffMins < 60) return diffMins + "m ago"
                    const diffHours = Math.floor(diffMins / 60)
                    if (diffHours < 24) return diffHours + "h ago"
                    return Math.floor(diffHours / 24) + "d ago"
                }
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 10

                Timer {
                    interval: 60000
                    repeat: true
                    running: true
                    onTriggered: parent.text = parent.text
                }
            }
        }

        Text {
            width: parent.width
            text: root.notification.summary
            color: Colors.primaryText
            font.family: "Poppins"
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
            visible: text !== ""
        }

        Item {
            id: bodySection
            property bool expanded: false
            width: parent.width
            implicitHeight: bodyText.implicitHeight + (showMoreToggle.visible ? showMoreToggle.implicitHeight + 2 : 0)
            visible: root.notification.body !== ""

            Text {
                id: bodyText
                width: parent.width
                text: root.notification.body
                color: Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: bodySection.expanded ? 999 : 3
                elide: Text.ElideRight
            }

            Text {
                id: showMoreToggle
                anchors.top: bodyText.bottom
                anchors.topMargin: 2
                visible: bodyText.implicitHeight > bodyText.height || bodySection.expanded
                text: bodySection.expanded ? "Show less" : "Show more"
                color: showMoreHover.containsMouse ? Colors.primaryText : Colors.secondaryText
                font.family: "Poppins"
                font.pixelSize: 11
                font.weight: Font.Medium

                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: showMoreHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bodySection.expanded = !bodySection.expanded
                }
            }
        }
    }
}
