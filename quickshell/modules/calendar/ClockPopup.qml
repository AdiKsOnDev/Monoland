pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services

AnimatedPopup {
    id: root

    popupWidth: 720

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        width: parent.width
        height: calendarPanel.implicitHeight

        // Left panel: time, date, calendar
        Column {
            id: calendarPanel
            width: parent.width / 2 - 8
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "hh:mm")
                color: Colors.primaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 56
                font.weight: Font.SemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd, MMMM d")
                color: Colors.secondaryText
                font.family: "Poppins"
                font.italic: false
                font.pixelSize: 13
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.border
            }

            Calendar {
                width: parent.width
            }
        }

        // Vertical divider
        Rectangle {
            width: 1
            height: parent.height
            color: Colors.border
        }

        Item {
            width: parent.width / 2 - 8
            height: calendarPanel.implicitHeight

            TodoList {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 16
                }
            }
        }
    }
}
