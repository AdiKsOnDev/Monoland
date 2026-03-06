pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.services

Rectangle {
    id: root

    required property Notification notification

    implicitWidth: parent?.width ?? 0
    implicitHeight: cardContent.implicitHeight + 28
    color: Colors.surfaceVariant
    radius: 12

    Row {
        id: cardContent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 16
            topMargin: 14
        }
        spacing: 12

        // App icon — image if available, letter circle as fallback
        Rectangle {
            id: appIcon
            width: 36
            height: 36
            radius: 999
            color: root.notification.image === "" && root.notification.appIcon === "" ? Colors.chipBackground : "transparent"
            clip: true

            // Inline image (e.g. profile picture) — highest priority
            Image {
                anchors.fill: parent
                source: root.notification.image
                visible: root.notification.image !== ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // Desktop entry / named app icon
            IconImage {
                anchors.fill: parent
                source: root.notification.appIcon
                visible: root.notification.image === "" && root.notification.appIcon !== ""
                smooth: true
            }

            // Letter fallback
            Text {
                anchors.centerIn: parent
                text: root.notification.appName.length > 0 ? root.notification.appName[0].toUpperCase() : "?"
                color: Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 14
                font.weight: Font.Bold
                visible: root.notification.image === "" && root.notification.appIcon === ""
            }
        }

        // Content column
        Column {
            width: parent.width - appIcon.width - parent.spacing
            spacing: 4

            // App name + timestamp + dismiss
            Row {
                width: parent.width
                spacing: 6

                Text {
                    text: root.notification.appName
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width - timestamp.implicitWidth - dismissBtn.implicitWidth - 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: timestamp
                    text: {
                        const arrived = Notifications.arrivalTimeFor(root.notification.id)
                        if (!arrived) return ""
                        const now = new Date()
                        const diffMs = now - arrived
                        const diffMins = Math.floor(diffMs / 60000)
                        if (diffMins < 1) return "now"
                        if (diffMins < 60) return diffMins + "m ago"
                        const diffHours = Math.floor(diffMins / 60)
                        if (diffHours < 24) return diffHours + "h ago"
                        return Math.floor(diffHours / 24) + "d ago"
                    }
                    color: Colors.secondaryText
                    font.family: "Poppins"
                    font.italic: false
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Timer {
                        interval: 60000
                        repeat: true
                        running: true
                        onTriggered: parent.text = parent.text
                    }
                }

                Text {
                    id: dismissBtn
                    text: "󰅖"
                    color: Colors.secondaryText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notification.dismiss()
                    }
                }
            }

            Text {
                width: parent.width
                text: root.notification.summary
                color: Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                visible: text !== ""
            }

            Text {
                width: parent.width
                text: root.notification.body
                color: Colors.secondaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                visible: text !== ""
            }
        }
    }
}
